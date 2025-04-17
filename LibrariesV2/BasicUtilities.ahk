; https://github.com/cobracrystal/ahk

#Requires Autohotkey v2+
#Include "%A_LineFile%\..\..\LibrariesV2\jsongo.ahk"

class TrayMenu {
	; ADD TRACKING FOR CHILD MENUS
	static __New() {
		this.menus := Map()
		this.menus.CaseSense := 0
		this.menus["traymenu"] := A_TrayMenu
		this.menus[A_TrayMenu] := A_TrayMenu
	}

	static submenus[menuName] {
		set => this.menus[menuName] := value
		get {
			if (!this.menus.Has(menuName))
				this.menus[menuName] := Menu()
			return this.menus[menuName]
		}
	}
}

class BetterMenu extends Menu {
	static __New() {
		this.menus := Map()
		this.menus["traymenu"] := A_TrayMenu
		this.menus[A_TrayMenu] := A_TrayMenu
	}

	__New(menuName) {
		if (BetterMenu.menus.Has(menuName))
			this.menuObj := Menu()
		else {
			this.menuObj := Menu()
			BetterMenu[menuName] := this.menuObj
		}
	}
}

fastCopy() {
	ClipboardOld := ClipboardAll()
	A_Clipboard := "" ; free clipboard so that ClipWait is more reliable
	Send("^c")
	if !ClipWait(1) {
		A_Clipboard := ClipboardOld
		return
	}
	text := A_Clipboard
	A_Clipboard := ClipboardOld
	return text
}

fastPrint(text) {
	ClipboardOld := ClipboardAll()
	A_Clipboard := ""
	A_Clipboard := text
	if !ClipWait(1) {
		A_Clipboard := ClipboardOld
		return 0
	}
	SendEvent("^v")
	Sleep(150)
	A_Clipboard := ClipboardOld
	return 1
}

; param method -> accept text + possible extra params
modifySelectedText(method, params*) {
	ClipboardOld := ClipboardAll()
	A_Clipboard := "" ; free clipboard so that ClipWait is more reliable
	Send("^c")
	if !ClipWait(1) {
		A_Clipboard := ClipboardOld
		return
	}
	A_Clipboard := method(A_Clipboard, params*)
	Send("^v")
	Sleep(150)
	A_Clipboard := ClipboardOld
	return 1
}

class Uri {
; stolen from https://github.com/ahkscript/libcrypt.ahk/blob/master/src/URI.ahk
	static encode(str) { ; keep ":/;?@,&=+$#."
		return this.LC_UriEncode(str)
	}

	static decode(str) {
		return this.LC_UriDecode(str)
	}

	static LC_UriEncode(uri, RE := "[0-9A-Za-z]") {
		var := Buffer(StrPut(uri, "UTF-8"), 0)
		StrPut(uri, var, "UTF-8")
		while(code := NumGet(Var, A_Index - 1, "UChar"))
			res .= RegExMatch(char := Chr(Code), RE) ? char : Format("%{:02X}", Code)
		return res
	}

	static LC_UriDecode(uri) {
		pos := 1
		while(pos := RegExMatch(uri, "i)(%[\da-f]{2})+", &code, pos)) {
			var := Buffer(StrLen(code[1]) // 3, 0)
			Code := SubStr(code[1], 2)
			Loop Parse, code, "`%"
				NumPut("UChar", "0x" A_LoopField, var, A_Index - 1)
			decoded := StrGet(var, "UTF-8")
			uri := SubStr(uri, 1, pos - 1) . decoded . SubStr(uri, pos+StrLen(Code)+1)
			pos += StrLen(decoded)+1
		}
		return uri
	}
}

parseHeaders(str) {
	headersAsText := RTrim(str, "`r`n")
	headers := Map()
	Loop Parse headersAsText, "`n", "`r" {
		arr := StrSplitUTF8(A_LoopField, ":")
		headers[Trim(arr[1])] := Trim(arr[2])
	}
	return headers
}

/**
 * Counts how many times a given value is included in an Object
 * @param obj array or map
 * @param value value to check for
 * @returns {Integer} Count of how many instances of value were encountered
 */
objCountValue(obj, value) {
	if !(obj is Array || obj is Map)
		throw(Error("objCountValue does not handle type " . Type(obj)))
	count := 0
	for i, e in obj
		if (e = value)
			count++
	return count
}

objContainsValue(obj, value) {
	if !(obj is Array || obj is Map)
		throw(Error("objContains does not handle type " . Type(obj)))
	for i, e in obj
		if (e = value)
			return i
	return 0
}

/**
 * Deletes given Value from Object, either on first encounter or on all encounters. Returns count of removed values
 * @param {Array | Map} obj
 * @param value 
 * @param {Integer} removeAll 
 * @returns {Integer} count
 */
objRemoveValue(obj, value, removeAll := true) {
	if !(obj is Array || obj is Map)
		throw(Error("objRemoveValue does not handle type " . Type(obj)))
	queue := []
	for next, e in obj
		if (e = value)
			queue.push(next)
	n := queue.Length
	while (queue.Length != 0) {
		next := queue.Pop()
		if (obj is Array)
			obj.RemoveAt(next)
		else
			obj.Delete(next)
	}
	return n
}

/**
 * 
 * @param obj Object, Map, Array Value etc.
 * @param {Integer} compact Whether to use spacer value to separate objects within objects (default true)
 * @param {Integer} compress Whether to omit spaces (default false)
 * @param {String} spacer Spacer value (default newline)
 * @returns {String} 
 */
objToString(obj, compact := true, compress := false, spacer := "`n") {
	if !(obj is Object)
		return obj
	isArr := obj is Array
	isMap := obj is Map
	isObj := !(isArr || isMap)
	str := ""
	separator := (trspace := compress ? "" : A_Space)
	for key, val in (isObj ? obj.OwnProps() : obj) {
		separator := compact ? trspace : ((val??"") is Object ? spacer : trspace)
		if !(IsSet(val))
			str := RTrim(str, separator) "," separator
		else if (isArr)
			str .= objToString(val ?? "", compact, spacer) "," separator
		else
			str .= objToString(key, compact, spacer) ":" trspace objToString(val ?? "", compact, spacer) "," separator
	}
	return ( isArr ? "[" : isMap ? "Map(" : "{" ) RegExReplace(str, "," separator "$") ( isArr ? "]" : isMap ? ")" : "}" )
}

reverseArray(array) {
	arr := []
	for i, e in array
		arr.InsertAt(1, e)
	return arr
}

sortArray(arr, mode := "") {
	arr2 := []
	for i, e in arr
		str .= e . "`n"
	sortedStr := Sort(str, mode)
	Loop Parse, sortedStr, "`n" {
		if (A_LoopField == "")
			continue
		arr2.push(A_LoopField)
	}
	return arr2
}

/**
 * Given Array, returns a new Array with all duplicates removed. Order is preserved. Optionally uses a key to compare with instead of the whole element.
 * @param arr 
 * @returns {Array} 
 */
uniquesFromArray(arr, key?, isMap := 0) {
	arr2 := []
	uniques := Map()
	for i, e in arr {
		el := key ? (isMap ? e[key] : e.%key%) : e
		if !(uniques.Has(el)) {
			uniques[el] := true
			arr2.push(e)
		}
	}
	return arr2
}

/**
 * Given Array, returns an Array of Arrays, where each subarray contains all instances of a unique value in the original array.
 * @param arr 
 * @param {Integer} objType
 * @returns {Array} 
 */
duplicateIndicesFromArray(arr, key?, isMap := 0) {
	duplicates := Map()
	for i, e in arr {
		el := key ? (isMap ? e[key] : e.%key%) : e
		if (duplicates.Has(el))
			duplicates[el].push(i)
		else
			duplicates[el] := [i]
	}
	return duplicates
}

; gets a map of maps. sorts it by a key of the submap, returns it as array
; requires all contents of mapInner[key] to be of the same type (number or string)
sortObjectByKey(tmap, key, mode := "") {
	isArr := tMap is Array
	isMap := tMap is Map
	if !(tmap is Object)
		throw(ValueError("Expected Object, but got " tmap.Prototype.Name))
	isObj := !(isArr || isMap)
	arr2 := Map()
	arr3 := []
	l := isArr ? tmap.Length : isMap ? tmap.Count : ObjOwnPropCount(tmap)
	for i, e in (isObj ? tmap.OwnProps() : tmap) {
		if (!IsSet(innerIsObj))
			innerIsObj := !(e is Map || e is Array)
		tv := innerIsObj ? e.%key% : e[key]
		if (!IsSet(isString))
			isString := (tv is String)
		if (arr2.Has(tv))
			arr2[tv].push(i)
		else
			arr2[tv] := [i]
		str .= tv . "`n"
	}
	newStr := Sort(str, mode)
	strArr := StrSplit(newStr, "`n")
	strArr.Pop()
	counter := 1
	Loop (strArr.Length) {
		if (counter > strArr.Length)
			break
		el := isString ? strArr[counter] . "" : Number(strArr[counter])
		for j, f in arr2[el] {
			arr3.push({ index: f, value: isObj ? tmap.%f% : tmap[f] })
		}
		counter += arr2[el].Length
	}
	return arr3
}

reverseString(str) {
	result := ""
	for i, e in StrSplitUTF8(str)
		result := e . result
	return result
}

rotateStr(str, offset := 0) {
	offset := Mod(offset, StrLen(str))
	return SubStr(str, -1 * offset + 1) . SubStr(str, 1, -1 * offset)
}

StrSplitUTF8(str, delim := "", omit := "") {
	arr := []
	skip := false
	count := 1
	Loop Parse, str, delim, omit {
		char := A_LoopField
		if (skip) {
			skip := false
			continue
		}
		if (StrLen(A_LoopField) == 1 && Ord(A_LoopField) > 0xD7FF && Ord(A_LoopField) < 0xDC00) {
			skip := true
			arr.push(A_Loopfield . SubStr(str, count + 1, 1))
			count += 2
			continue
		}
		arr.push(A_LoopField)
		count += StrLen(A_LoopField) + StrLen(delim)
	}
	return arr
}

; only works in 2.0.9
BoundFnName(Obj) {
	Address := ObjPtr(Obj)
	n := NumGet(Address, 5 * A_PtrSize + 16, "Ptr")
	Obj := ObjFromPtrAddRef(n)
	return Obj.Name
}

replaceCharacters(text, alphMap) {
	if !(alphMap is Map)
		return text
	result := ""
	for i, e in StrSplitUTF8(text) {
		if (alphMap.Has(e))
			result .= alphMap[e]
		else
			result .= e
	}
	return result
}

/**
 * Makes a string literal for regex usage
 * @param str 
 * @returns {string} 
 */
RegExEscape(str) => "\Q" StrReplace(str, "\E", "\E\\E\Q") "\E"

/**
 * Replaces Strings in [string] from strings in [from] into strings in [to], in strict order of appearance in [from]
 * @param string String in which to replace the strings
 * @param from Array containing strings that are to be replaced in decreasing priority order
 * @param to Array containing strings that are the replacements for values in @from, in same order
 * @returns {string} 
 */
recursiveReplaceMap(string, from, to) {
	return __recursiveReplaceMap(string, from, to)

	__recursiveReplaceMap(string, from, to, __index := 1) {
		replacedString := ""
		if (__index == from.Length)
			return StrReplace(string, from[__index], to[__index])
		strArr := StrSplit(string, from[__index])
		for i, e in strArr
			replacedString .= __recursiveReplaceMap(e, from, to, __index + 1) . (i == strArr.Length ? "" : to[__index])
		return replacedString
	}
}

/**
 * Creates a map from two given arrays, the first one becoming the keys of the other
 * @param keyArray 
 * @param valueArray 
 * @returns {Map} 
 */
mapFromArrays(keyArray, valueArray) {
	if (keyArray.Length != valueArray.Length || !(keyArray is Array) || !(valueArray is Array))
		throw(Error("Expected Arrays of equal Length, got " Type(keyArray) ", " Type(valueArray)))
	newMap := Map()
	for i, e in keyArray
		newMap[e] := valueArray[i]
	return newMap
}

/**
 * Given a Map, returns an Array of Length 2 containing two Arrays, the first one containing Keys and the second containing Values. Ordering WILL be random, as Maps are not ordered.
 * @param mapObject 
 * @returns {Array}
 */
mapToArrays(mapObject) {
	if !(mapObject is Map)
		throw(TypeError("Expected Map, got " Type(mapObject)))
	arr1 := []
	arr2 := []
	for i, e in mapObject {
		arr1.Push(i)
		arr2.Push(e)
	}
	return [arr1, arr2]
}
/**
 * Given a Map, returns new Map where keys are the values of original map and vice versa
 * @param {Map} mapObject 
 * @returns {Map} 
 */
mapFlip(mapObject) {
	flippedMap := Map()
	for i, e in mapObject
		flippedMap[e] := i
	return flippedMap
}

/**
 * Given a Map, returns an equivalent Object. If given Object/Array, tries to find all Maps recursively and turns them. Does NOT convert Objects/Arrays.
 * @param objInput 
 * @param {Integer} recursive 
 * @returns {Object | Map | Array} 
 */
MapToObj(objInput, recursive := true) {
	flagIsArray := objInput is Array
	flagIsMapArray := flagIsArray || objInput is Map
	if (!(objInput is Object))
		return objInput
	objOutput := flagIsArray ? Array() : {}
	if (flagIsArray)
		objOutput.Length := objInput.Length
	for i, e in (flagIsMapArray ? objInput : objInput.OwnProps()) {
		if (flagIsArray)
			objOutput[i] := (recursive ? MapToObj(e, true) : e)
		else
			objOutput.%i% := (recursive ? MapToObj(e, true) : e)
	}
	return (objOutput)
}

/**
 * Given an object with enumerable (Own) Properties, returns equivalent Map. If given Map/Array and recursive is true, finds Objects in it and turns those.
 * @param objInput 
 * @param {Integer} recursive 
 * @returns {Object | Map | Array} 
 */
ObjToMap(objInput, recursive := true) {
	flagIsArray := objInput is Array
	flagIsMapArray := flagIsArray || objInput is Map
	flagIsObject := objInput is Object
	if (!flagIsObject)
		return objInput
	objOutput := flagIsArray ? Array() : Map()
	if (flagIsArray)
		objOutput.Length := objInput.Length
	for i, e in (flagIsMapArray ? objInput : objInput.OwnProps())
		objOutput[i] := (recursive ? ObjToMap(e, true) : e)
	return (objOutput)
}

/**
 * Extended version of DateAdd, allowing Weeks (W), Months (MO), Years (Y) for timeUnit. Returns YYYYMMDDHH24MISS timestamp
 * @param dateTime valid YYYYMMDDHH24MISS timestamp to add time to.
 * @param value Amount of time to be added.
 * @param timeUnit Time Unit can be one of the strings (or their first letter): Years, Weeks, Days, Hours, Minutes, Seconds.
 * Months / Mo is available. Adding a month will result in the same day number the next month unless that would be invalid, in which case the number of days in the current month will be added.
 * Similarly, adding years to a leap day will result in the corresponding day number of the resulting year (2024-02-29 + 1 Year -> 2025-03-01)
 * @returns {string} YYYYMMDDHH24MISS Timestamp.
 */
DateAddW(dateTime, value, timeUnit) {
	switch timeUnit, 0 {
		case "Seconds", "S", "Minutes", "M", "Hours", "H", "Days", "D":
			return DateAdd(dateTime, value, timeUnit)
		case "Weeks", "W":
			return DateAdd(dateTime, value * 7, "D")
		case "Years", "Y":
			newTime := (SubStr(dateTime, 1, 4) + value) . SubStr(dateTime, 5)
			if !IsTime(newTime) ; leap day
				newTime := SubStr(newTime, 1, 4) . SubStr(DateAdd(dateTime, 1, "D"), 5)
			return newTime
		case "Months", "Mo":
			month := Format("{:02}", Mod(SubStr(dateTime, 5, 2) + value - 1, 12) + 1)
			year := SubStr(dateTime, 1, 4) + (SubStr(dateTime, 5, 2) + value - 1) // 12
			nextMonth := Format("{:02}", Mod(month, 12) + 1)
			nextYear := year + month // 12 ; technically unnecessary since when the fuck do we have an invalid december date
			rolledOverDays := Format("{:02}", SubStr(dateTime, 7, 2) - DateDiff(nextYear . nextMonth, year . month, "D"))
			if (rolledOverDays > 0)
				return nextYear . nextMonth . rolledOverDays . SubStr(dateTime, 9)
			else
				return year . month . SubStr(dateTime, 7)
		default:
			throw(Error("Invalid Time Unit: " timeUnit))
	}
}
/*
* Given a set of time units, returns a YYYYMMDDHH24MISS timestamp
; of the earliest possible time in the future when all given parts match
* Examples: The current time is 27th December, 2023, 17:16:34
* parseTime() -> A_Now
* parseTime(2023,12) -> A_Now.
* parseTime(2023, , 27) -> A_Now.
* parseTime(2023, , 28) -> 20231228000000.
* parseTime(, 2, 29) -> 20240229000000 (next leap year).
* parseTime(2022, ...) -> 0.
* parseTime(2025, 02, 29) -> throw Error: Invalid Date
* parseTime(, 1, , , 19) -> 20240101001900
*/
parseTime(years?, months?, days?, hours?, minutes?, seconds?) {
	Now := A_Now
	local data := gap(years?, months?, days?, hours?, minutes?, seconds?)
	switch data[1] {
		case 0:
			return Now
		case 1:
			if (years == A_YYYY && data[2]) { ; why compare to current year? leap year stuff
				tStamp := parseTime(, months?, days?, hours?, minutes?, seconds?)
				return (SubStr(tStamp, 1, 4) == years) ? tStamp : 0
			}
			tStamp := (years ?? A_YYYY) tf(months ?? 1) tf(days ?? 1) tf(hours ?? 0) tf(minutes ?? 0) tf(seconds ?? 0)
			if (!IsTime(tStamp)) {
				if (!IsSet(years) && IsSet(months) && months == 2 && IsSet(days) && days == 29) ; correct leap year
					tStamp := (A_YYYY + 4 - Mod(A_YYYY, 4)) . SubStr(tStamp, 5)
				else if (!IsSet(months) && days > 29) ; correct possible month error. no need for mod, since dec has 31 days
					tStamp := SubStr(tStamp 1, 4) . tf(A_MM + 1) . SubStr(tStamp, 7)
				if (!IsTime(tStamp))
					throw(ValueError("Invalid date specified."))
			}
			if (DateDiff(tStamp, Now, "S") >= 0)
				return tStamp
			; this case is ONLY for when year is in the present AND there is no gap present (if year is in the future, datediff must be positive.)
			if (data[3] < 6) ; populate unset vars with current time before giving up
				return parseTime(years, months ?? A_MM, days ?? A_DD, hours ?? A_Hour, minutes ?? A_Min, seconds ?? A_Sec)
			return 0 ; a year in the past will never occur again
		case 2:
			if (tf(months) == A_MM && data[2]) {
				tStamp := parseTime(, , days?, hours?, minutes?, seconds?)
				return SubStr(tStamp, 5, 2) == tf(months) ? tStamp : DateAddW(tStamp, 1, "Y")
			}
			tStamp := A_YYYY tf(months) tf(days ?? 1) tf(hours ?? 0) tf(minutes ?? 0) tf(seconds ?? 0)
			if (!IsTime(tStamp)) {
				if (tf(months) == "02" && IsSet(days) && days == 29) ; leap year
					tStamp := (A_YYYY + 4 - Mod(A_YYYY, 4)) . SubStr(tStamp, 5)
				if (!IsTime(tStamp))
					throw(ValueError("Invalid date specified."))
			}
			if (DateDiff(tStamp, Now, "S") >= 0)
				return tStamp
			if (data[3] < 6)
				return parseTime(, months, days ?? A_DD, hours ?? A_Hour, minutes ?? A_Min, seconds ?? A_Sec)
			return DateAddW(tStamp, 1, "Y")
		case 3:
			if (tf(days) == A_DD && data[2]) {
				tStamp := parseTime(, , , hours?, minutes?, seconds?)
				return (SubStr(tStamp, 7, 2) == tf(days)) ? tStamp : DateAddW(tStamp, 1, "Mo")
			}
			tStamp := SubStr(Now, 1, 6) tf(days) tf(hours ?? 0) tf(minutes ?? 0) tf(seconds ?? 0)
			if (!IsTime(tStamp)) {
				if (A_MM == 02 && days == 29) ; leap year
					tStamp := (A_YYYY + 4 - Mod(A_YYYY, 4)) . SubStr(tStamp, 5)
				else if (days > 29) ; correct possible month error. no need for mod, since dec has 31 days
					tStamp := SubStr(tStamp 1, 4) . tf(A_MM + 1) . SubStr(tStamp, 7)
				if (!IsTime(tStamp))
					throw(ValueError("Invalid date specified."))
			}
			if (DateDiff(tStamp, Now, "S") >= 0)
				return tStamp
			if (data[3] < 6)
				return parseTime(, , days, hours ?? A_Hour, minutes ?? A_Min, seconds ?? A_Sec)
			return DateAddW(tStamp, 1, "Mo")
		case 4:
			if (tf(hours) == A_Hour && data[2]) {
				tStamp := parseTime(, , , , minutes?, seconds?)
				return (SubStr(tStamp, 9, 2) == tf(hours)) ? tStamp : DateAddW(tStamp, 1, "D")
			}
			tStamp := SubStr(Now, 1, 8) tf(hours) tf(minutes ?? 0) tf(seconds ?? 0)
			if (DateDiff(tStamp, Now, "S") >= 0)
				return tStamp
			if (data[3] < 6)
				return parseTime(, , , hours, minutes ?? A_Min, seconds ?? A_Sec)
			return DateAddW(tStamp, 1, "D")
		case 5:
			if (tf(minutes) == A_Min) {
				tStamp := parseTime(, , , , , seconds?)
				return SubStr(tStamp, 11, 2) == tf(minutes) ? tStamp : 0
			}
			tStamp := SubStr(Now, 1, 10) . tf(minutes) . tf(seconds ?? 0)
			if (DateDiff(tStamp, Now, "S") >= 0)
				return tStamp
			if (data[3] < 6)
				return parseTime(, , , , minutes, seconds ?? A_Sec)
			return DateAddW(tStamp, 1, "H")
		case 6:
			tStamp := SubStr(Now, 1, 12) . tf(seconds)
			if (DateDiff(tStamp, Now, "S") >= 0)
				return tStamp
			return DateAddW(tStamp, 1, "M")
	}
	tf(n) => Format("{:02}", n)

	; returns first given var, last given var before the first gap and whether there is a gap at all.
	gap(y?, mo?, d?, h?, m?, s?) {
		mapA := Map(1, y?, 2, mo?, 3, d?, 4, h?, 5, m?, 6, s?), first := 0, last := 0
		for i, e in mapA {
			if (A_Index == 1)
				first := i
			last := i
			if (first + A_Index - 1 != i)
				return [first, true, last]
		}
		return [first, false, last]
	}
}

enumerateDay(day) {
	d := Substr(day, 1, 2)
	switch d {
		case "mo":
			day := 2
		case "di", "tu":
			day := 3
		case "mi", "we":
			day := 4
		case "do", "th":
			day := 5
		case "fr":
			day := 6
		case "sa":
			day := 7
		case "so", "su":
			day := 1
		default:
			return -1
	}
	return A_DD - A_WDAY + day
}

ExecScript(expression, Wait := true) {
	input := '#Warn All, Off`n'
	input .= '#Include "*i ' A_LineFile '"`n'
	input .= '#Include "*i ' A_LineFile '\..\..\LibrariesV2\MathUtilities.ahk"`n'
	if (RegexMatch(expression, 'i)FileAppend\(.*,\s*\"\*\"\)') || RegExMatch(expression, 'i)MsgBox\(.+\)'))
		input .= expression
	else if (RegexMatch(expression, 'i)print\(.*\)'))
		input .= RegexReplace(expression, "print\((.*)?\)", 'FileAppend(objToString($1), "*")')
	else
		input .= 'FileAppend(objToString(' . expression . '), "*")'
	shell := ComObject("WScript.Shell")
	exec := shell.Exec(A_AhkPath " /ErrorStdOut *")
	exec.StdIn.Write(input)
	exec.StdIn.Close()
	if Wait
		return exec.StdOut.ReadAll()
}

cmdRet(sCmd, callBackFuncObj := "", encoding := '') {
	; encoding := "CP" . DllCall("GetOEMCP", "UInt") ; CP0 -> Ansi, CP850 Western European Ansi.
	static HANDLE_FLAG_INHERIT := 0x1, CREATE_NO_WINDOW := 0x08000000, STARTF_USESTDHANDLES := 0x100, ptrsize := A_PtrSize
	if (encoding == '')
		encoding := "CP" . DllCall('GetOEMCP', 'UInt')
	DllCall("CreatePipe", "PtrP", &hPipeRead := 0, "PtrP", &hPipeWrite := 0, "Ptr", 0, "UInt", 0)
	DllCall("SetHandleInformation", "Ptr", hPipeWrite, "UInt", HANDLE_FLAG_INHERIT, "UInt", HANDLE_FLAG_INHERIT)

	STARTUPINFO := Buffer(size := ptrsize * 4 + 4 * 8 + ptrsize * 5, 0)
	NumPut("UInt", size, STARTUPINFO)
	NumPut("UInt", STARTF_USESTDHANDLES, STARTUPINFO, ptrsize * 4 + 4 * 7)
	NumPut("Ptr", hPipeWrite, "Ptr", hPipeWrite, STARTUPINFO, ptrsize * 4 + 4 * 8 + ptrsize * 3)

	PROCESS_INFORMATION := Buffer(ptrsize * 2 + 4 * 2, 0)
	if !DllCall("CreateProcess", "Ptr", 0, "Str", sCmd, "Ptr", 0, "Ptr", 0, "UInt", true, "UInt", CREATE_NO_WINDOW,
		"Ptr", 0, "Ptr", 0, "Ptr", STARTUPINFO, "Ptr", PROCESS_INFORMATION) {
		DllCall("CloseHandle", "Ptr", hPipeRead)
		DllCall("CloseHandle", "Ptr", hPipeWrite)
		throw(OSError("CreateProcess has failed"))
	}
	DllCall("CloseHandle", "Ptr", hPipeWrite)
	sTemp := Buffer(4096)
	while DllCall("ReadFile", "Ptr", hPipeRead, "Ptr", sTemp, "UInt", 4096, "UIntP", &nSize := 0, "UInt", 0) {
		sOutput .= stdOut := StrGet(sTemp, nSize, encoding)
		if (callBackFuncObj)
			callBackFuncObj(stdOut)
	}
	DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, "Ptr"))
	DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, ptrsize, "Ptr"))
	DllCall("CloseHandle", "Ptr", hPipeRead)
	return sOutput
}

cmdRetAsync(sCmd, &returnValue, callBackFuncObj := "", timePerCheck := 50, finishCallBackFuncObj := "", encoding := '') {
	; encoding := "CP" . DllCall("GetOEMCP", "UInt") ; CP0 -> Ansi, CP850 Western European Ansi.
	static HANDLE_FLAG_INHERIT := 0x1, CREATE_NO_WINDOW := 0x08000000, STARTF_USESTDHANDLES := 0x100, ptrsize := A_PtrSize
	if (encoding == '')
		encoding := "CP" . DllCall('GetOEMCP', 'UInt')
	DllCall("CreatePipe", "PtrP", &hPipeRead := 0, "PtrP", &hPipeWrite := 0, "Ptr", 0, "UInt", 0)
	DllCall("SetHandleInformation", "Ptr", hPipeWrite, "UInt", HANDLE_FLAG_INHERIT, "UInt", HANDLE_FLAG_INHERIT)

	STARTUPINFO := Buffer(size := ptrsize * 4 + 4 * 8 + ptrsize * 5, 0)
	NumPut("UInt", size, STARTUPINFO)
	NumPut("UInt", STARTF_USESTDHANDLES, STARTUPINFO, ptrsize * 4 + 4 * 7)
	NumPut("Ptr", hPipeWrite, "Ptr", hPipeWrite, STARTUPINFO, ptrsize * 4 + 4 * 8 + ptrsize * 3)

	PROCESS_INFORMATION := Buffer(ptrsize * 2 + 4 * 2, 0)
	if !DllCall("CreateProcess", "Ptr", 0, "Str", sCmd, "Ptr", 0, "Ptr", 0, "UInt", true, "UInt", CREATE_NO_WINDOW,
		"Ptr", 0, "Ptr", 0, "Ptr", STARTUPINFO, "Ptr", PROCESS_INFORMATION) {
		DllCall("CloseHandle", "Ptr", hPipeRead)
		DllCall("CloseHandle", "Ptr", hPipeWrite)
		throw(OSError("CreateProcess has failed"))
	}
	DllCall("CloseHandle", "Ptr", hPipeWrite)
	sTemp := Buffer(4096)
	SetTimer(readFileCheck, timePerCheck)
	return 1

	readFileCheck() {
		if (DllCall("ReadFile", "Ptr", hPipeRead, "Ptr", sTemp, "UInt", 4096, "UIntP", &nSize := 0, "UInt", 0)) {
			returnValue .= stdOut := StrGet(sTemp, nSize, encoding)
			if (callBackFuncObj)
				callBackFuncObj(stdOut)
		}
		else {
			SetTimer(readFileCheck, 0)
			closeHandle()
		}
	}

	closeHandle() {
		DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, "Ptr"))
		DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, ptrsize, "Ptr"))
		DllCall("CloseHandle", "Ptr", hPipeRead)
		if (finishCallBackFuncObj)
			finishCallBackFuncObj()
	}
}

execShell(command) {
	shell := ComObject("WScript.Shell")
	exec := shell.Exec(A_Comspec " /C " command)
	return exec.StdOut.ReadAll()
}

menu_RemoveSpace(menuHandle, applyToSubMenus := true) {
	; http://msdn.microsoft.com/en-us/library/ff468864(v=vs.85).aspx
	static MIsize := (4 * 4) + (A_PtrSize * 3)
	MI := Buffer(MIsize, 0)
	Numput("UInt", MIsize, MI, 0)
	NumPut("UInt", 0x00000010, MI, 4) ; MIM_STYLE = 0x00000010
	DllCall("User32.dll\GetMenuInfo", "Ptr", menuHandle, "Ptr", MI, "UInt")
	if (applyToSubMenus)
		NumPut("UInt", 0x80000010, MI, 4) ; MIM_APPLYTOSUBMENUS = 0x80000000| MIM_STYLE : 0x00000010
	NumPut("UInt", NumGet(MI, 8, "UINT") | 0x80000000, MI, 8) ; MNS_NOCHECK = 0x80000000
	DllCall("User32.dll\SetMenuInfo", "Ptr", menuHandle, "Ptr", MI, "UInt")
	return true
}

windowGetCoordinates(wHandle) {
	dhw := A_DetectHiddenWindows
	DetectHiddenWindows(1)
	minimize_status := WinGetMinMax(wHandle)
	NumPut("Uint", 44, pos := Buffer(44, 0))
	DllCall("GetWindowPlacement", "uint", wHandle, "uint", pos.ptr)
	mmx := NumGet(pos, 8, "int")
	x := NumGet(pos, 28, "int")
	y := NumGet(pos, 32, "int")
	w := NumGet(pos, 36, "int") - x
	h := NumGet(pos, 40, "int") - y
	pos := Buffer(16)
	DllCall("GetClientRect", "uint", wHandle, "uint", pos.ptr)
	cw := NumGet(pos, 8, "int")
	ch := NumGet(pos, 12, "int")
	DetectHiddenWindows(dhw)
	return [x, y, w, h, cw, ch, mmx]
}

GetWindowPlacement(hwnd) {
	DllCall("User32.dll\GetWindowPlacement", "Ptr", hwnd, "Ptr", WP := Buffer(44))
	Lo := NumGet(WP, 28, "Int")        ; X coordinate of the upper-left corner of the window in its original restored state
	To := NumGet(WP, 32, "Int")        ; Y coordinate of the upper-left corner of the window in its original restored state
	Wo := NumGet(WP, 36, "Int") - Lo   ; Width of the window in its original restored state
	Ho := NumGet(WP, 40, "Int") - To   ; Height of the window in its original restored state

	mmx := NumGet(WP, 8, "Int") ; ShowCMD
	flags := NumGet(WP, 4, "Int")  ; flags
	MinX := NumGet(WP, 12, "Int")
	MinY := NumGet(WP, 16, "Int")
	MaxX := NumGet(WP, 20, "Int")
	MaxY := NumGet(WP, 24, "Int")

	return { X: Lo, Y: to, W: Wo, H: Ho, mmx: mmx, flags: flags, MinX: MinX, MinY: MinY, MaxX: MaxX, MaxY: MaxY }
}

SetWindowPlacement(hwnd := "", X := "", Y := "", W := "", H := "", action := 9) {
	DllCall("User32.dll\GetWindowPlacement", "Ptr", hwnd, "Ptr", WP := Buffer(44))
	Lo := NumGet(WP, 28, "Int")        ; X coordinate of the upper-left corner of the window in its original restored state
	To := NumGet(WP, 32, "Int")        ; Y coordinate of the upper-left corner of the window in its original restored state
	Wo := NumGet(WP, 36, "Int") - Lo   ; Width of the window in its original restored state
	Ho := NumGet(WP, 40, "Int") - To   ; Height of the window in its original restored state
	L := X = "" ? Lo : X               ; X coordinate of the upper-left corner of the window in its new restored state
	T := Y = "" ? To : Y               ; Y coordinate of the upper-left corner of the window in its new restored state
	R := L + (W = "" ? Wo : W)         ; X coordinate of the bottom-right corner of the window in its new restored state
	B := T + (H = "" ? Ho : H)         ; Y coordinate of the bottom-right corner of the window in its new restored state

	NumPut("UInt", action, WP, 8)
	NumPut("UInt", L, WP, 28)
	NumPut("UInt", T, WP, 32)
	NumPut("UInt", R, WP, 36)
	NumPut("UInt", B, WP, 40)

	Return DllCall("User32.dll\SetWindowPlacement", "Ptr", hwnd, "Ptr", WP)
}

/**
 * Opens Color picking Window
 * @param Color 
 * @param {Integer} hGui 
 * @returns {Integer} 
 */
colorDialog(initialColor := 0, hwnd := 0, disp := false, startingColors*) {
	static p := A_PtrSize
	disp := disp ? 0x3 : 0x1 ; init disp / 0x3 = full panel / 0x1 = basic panel

	if (startingColors.Length > 16)
		throw(Error("Too many custom colors.  The maximum allowed values is 16."))

	Loop (16 - startingColors.Length)
		startingColors.Push(0) ; fill out custColorObj to 16 values

	CUSTOM := Buffer(16 * 4, 0) ; init custom colors obj
	CHOOSECOLOR := Buffer((p == 4) ? 36 : 72, 0) ; init dialog

	for i, e in startingColors
		NumPut("UInt", format_argb(e), CUSTOM, (i-1) * 4)

	NumPut("UInt", CHOOSECOLOR.size, CHOOSECOLOR, 0)             ; lStructSize
	NumPut("UPtr", hwnd, CHOOSECOLOR, p)             ; hwndOwner
	NumPut("UInt", format_argb(initialColor), CHOOSECOLOR, 3 * p)         ; rgbResult
	NumPut("UPtr", CUSTOM.ptr, CHOOSECOLOR, 4 * p)         ; lpCustColors
	NumPut("UInt", disp, CHOOSECOLOR, 5 * p)         ; Flags

	if !DllCall("comdlg32\ChooseColor", "UPtr", CHOOSECOLOR.ptr, "UInt")
		return -1
	return format_argb(NumGet(CHOOSECOLOR, 3 * A_PtrSize, "UInt"))
}
; typedef struct tagCHOOSECOLORW {  offset      size    (x86/x64)
; DWORD        lStructSize;       |0      |   4
; HWND         hwndOwner;         |4 / 8  |   8 /16
; HWND         hInstance;         |8 /16  |   12/24
; COLORREF     rgbResult;         |12/24  |   16/28
; COLORREF     *lpCustColors;     |16/28  |   20/32
; DWORD        Flags;             |20/32  |   24/36
; LPARAM       lCustData;         |24/40  |   28/48 <-- padding for x64
; LPCCHOOKPROC lpfnHook;          |28/48  |   32/56
; LPCWSTR      lpTemplateName;    |32/56  |   36/64
; LPEDITMENU   lpEditInfo;        |36/64  |   40/72
; } CHOOSECOLORW, *LPCHOOSECOLORW;
; https://github.com/cobracrystal/ahk

colorGradientArr(amount, colors*) {
	sColors := [], gradient := []
	if (amount < colors.Length-2)
		return 0
	else if (amount == colors.Length-2)
		return colors
	for index, color in colors
		sColors.push({r:(color & 0xFF0000) >> 16, g: (color & 0xFF00) >> 8, b:color & 0xFF})
	; first color given, format with 6 padded 0s in case of black
	gradient.push(format("0x{:06X}", colors[1]))
	; amount of color gradients to perform
	segments := colors.Length-1
	Loop(amount) {
		; current gradient segment we are in
		segment := floor((A_Index/(amount+1))*segments)+1
		; percentage progress in the current gradient segment as decimal
		segProgress := ((A_Index/(amount+1)*segments)-segment+1)
		; RGB obtained via percentage * (end of gradient - start of gradient), then adding current RGB value again.
		r := round((segProgress * (sColors[segment+1].r-sColors[segment].r))+sColors[segment].r)
		g := round((segProgress * (sColors[segment+1].g-sColors[segment].g))+sColors[segment].g)
		b := round((segProgress * (sColors[segment+1].b-sColors[segment].b))+sColors[segment].b)
		gradient.Push(format("0x{1:02X}{2:02X}{3:02X}", r, g, b))
	}
	; last color given, same as first
	gradient.Push(format("0x{:06X}", colors[colors.Length]))
	; return array of amount+2 colors
	return gradient
}

rainbowArr(num, intensity := 0xFF) {
	if (num < 7)
		throw(Error("Invalid num"))
	if (intensity < 0 || intensity > 255)
		throw(Error("Invalid Intensity"))
	intensity := format("{:#x}", intensity)
	r := intensity * 0x010000
	g := intensity * 0x000100
	b := intensity * 0x000001
	return colorGradientArr(num-2, r, r|g//2, r|g, g, g|b, g//2|b, b, b|r, r)
}

/**
 * calculates brightness as per Rec 709 Television coefficients.
 * @param color standard RGB color
 * @returns {Number} Value between 0-255. 0-127 is dark, above is bright
 */
getBrightness(color) {
	color := Integer(color)
	r := (color & 0xFF0000) >> 16
	g := (color & 0xFF00) >> 8
	b := (color & 0xFF)
	return 0.2126 * r + 0.7152 * g + 0.0722 * b
}

isDark(color) {
	return getBrightness(color) < 128
}

/**
 * given color in (A)RGB/(A)BGR format, reverse formats and add or remove alpha value. set alpha to -1 to remove
 * @param {Integer} clr 
 * @param {Integer} reverse 
 * @param {Integer} alpha 
 */
format_argb(color, reverse := true, alpha?) {
	color := Integer(color)
	if (reverse)
		color := (color & 0xFF) << 16 | (color & 0xFF00) | ((color & 0xFF0000) >> 16)
	;	clr := (clr >> 16 & 0xFF) | (clr & 0xFF00) | (clr << 16 & 0xFF0000) ; equivalent to above
	clrAlpha := IsSet(alpha) ? (alpha == -1 ? 0 : alpha): (color & 0xFF000000) >> 24
	return (clrAlpha << 24 | color)
}

; 0xFF00F9
colorPreviewGUI(color) {
	if (!RegexMatch(color, "i)(?:0x)?[0-9A-F]{6}"))
		return
	CoordMode("Mouse")
	MouseGetPos(&x, &y)
	colorPreview := Gui("+AlwaysOnTop +LastFound +ToolWindow -Caption")
	colorPreview.BackColor := color
	colorPreview.Show("x" . x-30 . " y" . y-30 . "w50 h50 NoActivate")
	SetTimer((*) => colorPreview.Destroy(), -1500)
}

timedTooltip(text := "", durationMS := 1000, x?, y?, whichTooltip?) {
	ToolTip(text, x?, y?, whichTooltip?)
	SetTimer(stopTooltip, -1 * durationMS)

	stopTooltip() {
		ToolTip(, , , whichTooltip?)
	}
}

useIfSet(value, default := unset) {
	return IsSet(value) ? value : default
}

MsgBoxAsGui(text := "Press OK to continue", funcObj := 0, title := A_ScriptName, buttonStyle := 0, defaultButton := 1, icon := 0, owner := 0, timeout := 0) {
	static MB_OK 						:= 0
	static MB_OKCANCEL 					:= 1
	static MB_ABORTRETRYIGNORE 			:= 2
	static MB_YESNOCANCEL 				:= 3
	static MB_YESNO 					:= 4
	static MB_RETRYCANCEL 				:= 5
	static MB_CANCELRETRYCONTINUE 		:= 6
	static MB_TEXT_MAP := Map(
		MB_OK,					["OK"],
		MB_OKCANCEL,			["OK", "Cancel"],
		MB_ABORTRETRYIGNORE,	["Abort", "Retry", "Ignore"],
		MB_YESNOCANCEL,			["Yes", "No", "Cancel"],
		MB_YESNO,				["Yes", "No"],
		MB_RETRYCANCEL,			["Retry", "Cancel"],
		MB_CANCELRETRYCONTINUE,	["Cancel", "Retry", "Continue"]
	)

	static MB_ICONHANDERROR				:= 16
	static MB_ICONQUESTION 				:= 32
	static MB_ICONEXCLAMATION 			:= 48
	static MB_ICONASTERISKINFO 			:= 64

	static MB_FONTNAME
	static MB_FONTSIZE
	static MB_FONTWEIGHT
	static MB_FONTISITALIC
	static MB_HASFONTINFORMATION := getMsgBoxFontInfo(&MB_FONTNAME, &MB_FONTSIZE, &MB_FONTWEIGHT, &MB_FONTISITALIC)

	static gap := 26			; Spacing above and below text in top area of the Gui
	static leftMargin := 12		; Left Gui margin
	static rightMargin := 8		; Space between right side of button and right Gui edge
	static buttonWidth := 88	; Width of OK button
	static buttonHeight := 26	; Height of OK button
	static buttonOffset := 30	; Offset between the right side of text and right edge of button
	static minGuiWidth := 138	; Minimum width of Gui
	static SS_WHITERECT := 0x0006	; Gui option for white rectangle (http://ahkscript.org/boards/viewtopic.php?p=20053#p20053)

	bottomGap := leftMargin
	BottomHeight := buttonHeight + 2 * bottomGap
	gStr := ""
	if !(MB_TEXT_MAP.Has(buttonStyle))
		throw Error("Invalid button Style")
	if (owner)
		gStr := "+Owner" owner
	guiFontOptions := MB_HASFONTINFORMATION ? "S" MB_FONTSIZE " W" MB_FONTWEIGHT ( MB_FONTISITALIC ? " italic" : "") : ""
	mbgui := Gui("+ToolWindow -Resize -MinimizeBox -MaximizeBox " gStr, title)
	mbgui.Opt("+0x94C80000")
	mbgui.Opt("-ToolWindow")
	mbgui.SetFont(guiFontOptions, MB_FONTNAME)
	mbgui.AddText("x0 y0 vWhiteBoxTop " SS_WHITERECT, text)
	mbgui.AddText("x" leftMargin " y" gap " BackgroundTrans vTextBox", text)
	mbGui["TextBox"].GetPos(&TBx, &TBy, &TBw, &TBh)
	guiWidth := leftMargin + TBw - buttonOffset + (buttonWidth + rightMargin) * MB_TEXT_MAP[buttonStyle].Length + 1
	guiWidth := (guiWidth < minGuiWidth ? minGuiWidth : guiWidth)
	whiteBoxHeight := TBy + TBh + gap
	mbGui["WhiteBoxTop"].Move(0, 0, guiWidth, whiteBoxHeight)
	buttonX := guiWidth - (rightMargin + buttonWidth) * MB_TEXT_MAP[buttonStyle].Length
	buttonY := whiteBoxHeight + bottomGap
	for i, e in MB_TEXT_MAP[buttonStyle]
		mbgui.AddButton("vButton" i " x" (buttonX + (i-1) * (buttonWidth + rightMargin)) " y" buttonY " w" buttonWidth " h" buttonHeight, e).OnEvent("Click", buttonEvent.bind(buttonStyle, i))
	mbGui["Button" defaultButton].Focus()
	guiHeight := whiteBoxHeight + BottomHeight
	mbGui.OnEvent("Escape", (*) => mbgui.Destroy())
	mbGui.OnEvent("Close", (*) => mbgui.Destroy())
	mbgui.Show("Center w" guiWidth " h" guiHeight)
	return mbgui

	buttonEvent(buttonStyle, buttonNumber, buttonCtrl, info) {
		mbgui.Destroy()
		if (funcObj)
			funcObj(MB_TEXT_MAP[buttonStyle][buttonNumber])
	}

	getMsgBoxFontInfo(&name := "", &size := 0, &weight := 0, &isItalic := 0) {
		; SystemParametersInfo constant for retrieving the metrics associated with the nonclient area of nonminimized windows
		static SPI_GETNONCLIENTMETRICS := 0x0029

		static NCM_Size        := 40 + 5 * 92   ; Size of NONCLIENTMETRICS structure (not including iPaddedBorderWidth)
		static MsgFont_Offset  := 40 + 4 * 92   ; Offset for lfMessageFont in NONCLIENTMETRICS structure
		static Size_Offset     := 0    ; Offset for cbSize in NONCLIENTMETRICS structure

		static Height_Offset   := 0    ; Offset for lfHeight in LOGFONT structure
		static Weight_Offset   := 16   ; Offset for lfWeight in LOGFONT structure
		static Italic_Offset   := 20   ; Offset for lfItalic in LOGFONT structure
		static FaceName_Offset := 28   ; Offset for lfFaceName in LOGFONT structure
		static FACESIZE        := 32   ; Size of lfFaceName array in LOGFONT structure
		; Maximum number of characters in font name string

		NCM := Buffer(NCM_Size, 0)
		NumPut("UInt", NCM_Size, NCM, Size_Offset)   ; Set the cbSize element of the NCM structure
		; Get the system parameters and store them in the NONCLIENTMETRICS structure (NCM)
		if !DllCall("SystemParametersInfo", "UInt", SPI_GETNONCLIENTMETRICS, "UInt", NCM_Size, "Ptr", NCM.Ptr, "UInt", 0)                        ; Don't update the user profile
			return false                               ; Return false
		name   := StrGet(NCM.Ptr + MsgFont_Offset + FaceName_Offset, FACESIZE)          ; Get the font name
		height := NumGet(NCM.Ptr + MsgFont_Offset + Height_Offset, "Int")               ; Get the font height
		size   := DllCall("MulDiv", "Int", -Height, "Int", 72, "Int", A_ScreenDPI)   ; Convert the font height to the font size in points
		; Reference: http://stackoverflow.com/questions/2944149/converting-logfont-height-to-font-size-in-points
		weight   := NumGet(NCM.Ptr + MsgFont_Offset + Weight_Offset, "Int")             ; Get the font weight (400 is normal and 700 is bold)
		isItalic := NumGet(NCM.Ptr + MsgFont_Offset + Italic_Offset, "UChar")           ; Get the italic state of the font
		return true
	}
}


base64Encode(str, encoding := "UTF-8") {
	static CRYPT_STRING_BASE64 := 0x00000001
	static CRYPT_STRING_NOCRLF := 0x40000000

	binary := Buffer(StrPut(str, encoding))
	StrPut(str, binary, encoding)
	if !(DllCall("crypt32\CryptBinaryToStringW", "Ptr", binary, "UInt", binary.Size - 1, "UInt", (CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF), "Ptr", 0, "UInt*", &size := 0))
		throw(OSError())
	base64 := Buffer(size << 1, 0)
	if !(DllCall("crypt32\CryptBinaryToStringW", "Ptr", binary, "UInt", binary.Size - 1, "UInt", (CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF), "Ptr", base64, "UInt*", size))
		throw(OSError())
	return StrGet(base64)
}

base64Decode(base64, encoding := "UTF-8") {
	static CRYPT_STRING_BASE64 := 0x00000001

	if !(DllCall("crypt32\CryptStringToBinaryW", "Str", base64, "UInt", 0, "UInt", CRYPT_STRING_BASE64, "Ptr", 0, "UInt*", &size := 0, "Ptr", 0, "Ptr", 0))
		throw(OSError())
	str := Buffer(size)
	if !(DllCall("crypt32\CryptStringToBinaryW", "Str", base64, "UInt", 0, "UInt", CRYPT_STRING_BASE64, "Ptr", str, "UInt*", size, "Ptr", 0, "Ptr", 0))
		throw(OSError())
	return StrGet(str, "UTF-8")
}

sendRequest(url := "https://icanhazip.com/", method := "GET", encoding := "UTF-8", async := false, callBackFuncObj := "") {
	if (async) {
		if (callBackFuncObj == "")
			throw(ValueError("No callback function provided for async request."))
		whr := ComObject("Msxml2.XMLHTTP")
		whr.Open(method, url, true)
		whr.OnReadyStateChange := callBackFuncObj
	whr.Send()
	}
	else
		whr := ComObject("WinHttp.WinHttpRequest.5.1")
	whr.Open(method, url, true)
	whr.Send()
	whr.WaitForResponse()
	arr := whr.ResponseBody
	if !(arr)
		return ""
	pData := NumGet(ComObjValue(arr) + 8 + A_PtrSize, 0, "UPtr")
	length := (arr.MaxIndex() - arr.MinIndex()) + 1
	return Trim(StrGet(pData, length, encoding), "`n`r`t ")
}

/**
 * Given a path, removes any backtracking of paths through \..\ to create a unique absolute path.
 * @param path Path to normalize
 * @returns {string} A normalized Path (if valid) or an empty string if the path could not be resolved.
 */
normalizePath(path) {	; ONLY ABSOLUTE PATHS
	path := StrReplace(path, "\\", "\")
	path := StrReplace(path, "/", "\")
	if (!RegexMatch(path, "i)^[a-z]:\\") || RegexMatch(path, "i)^[a-z]:\\\.\.\\"))
		return ""
	path := StrReplace(path, "\.\", "\")
	if (SubStr(path, -2) == "\.")
		path := SubStr(path, 1, -2)
	Loop {
		path := RegexReplace(path, "\\(?!\.\.\\)[^\\]+?\\\.\.(?:\\|$)", "\", &rCount)
		if (rCount == 0)
			break
	}
	if (InStr(path, "\..\") || SubStr(path, -3) == "\..")
		return ""
	return path
}

tryEditTextFile(editor := A_WinDir . "\system32\notepad.exe", params := "", *) {
	if (InStr(editor, A_Space) && SubStr(editor, 1, 1) != '"' && SubStr(editor, -1, 1) != '"')
		editor := '"' editor '"'
	try
		Run(editor ' ' params)
	catch
		try Run(A_WinDir . '\system32\notepad.exe ' . params)
	; Run('"' A_ProgramFiles . '\Notepad++\notepad++.exe" "' . path '"')
	; Run('Notepad++ "' . path '"')
}


doNothing(*) {
	return
}

; class ExGui {

; 	__New(debug := 0, useTrayMenu := 0, name := "ExGUI") {

; 		this.settingsManager("Load")
; 		this.settings.debug := debug

; 		this.menu := this.createMenu()
; 		if (useTrayMenu) {
; 			tableFilterMenu := TrayMenu.submenus["tablefilter"]
; 			tableFilterMenu.Add("Open GUI", (*) => this.guiCreate())
; 			tableFilterMenu.Add("Use Dark Mode", (iName, iPos, menuObj) => this.settingsHandler("Darkmode", -1, true, menuObj, iName))
; 			if (this.settings.darkMode)
; 				tableFilterMenu.Check("Use Dark Mode")
; 		}
; 		A_TrayMenu.Add("ExGUI", tableFilterMenu)
; 	}

; 	guiCreate() {
; 		newGui := Gui("+Border")
; 		newGui.OnEvent("Close", this.guiClose.bind(this))
; 		newGui.OnEvent("Escape", this.guiClose.bind(this))
; 		newGui.OnEvent("DropFiles", this.dropFiles.bind(this))
; 		newGui.SetFont("c0x000000") ; this is necessary to force font of checkboxes / groupboxes
; 		newGui.Show("AutoSize")
; 	}

; 	toggleGuiDarkMode(_gui, dark) {
; 		static WM_THEMECHANGED := 0x031A
; 		;// title bar dark
; 		if (VerCompare(A_OSVersion, "10.0.17763")) {
; 			attr := 19
; 			if (VerCompare(A_OSVersion, "10.0.18985")) {
; 				attr := 20
; 			}
; 			if (dark)
; 				DllCall("dwmapi\DwmSetWindowAttribute", "ptr", _gui.hwnd, "int", attr, "int*", true, "int", 4)
; 			else
; 				DllCall("dwmapi\DwmSetWindowAttribute", "ptr", _gui.hwnd, "int", attr, "int*", false, "int", 4)
; 		}
; 		_gui.BackColor := (dark ? this.settings.darkThemeColor : "Default") ; "" <-> "Default" <-> 0xFFFFFF
; 		font := (dark ? "c" this.settings.darkThemeFontColor : "cDefault")
; 		_gui.SetFont(font)
; 		for cHandle, ctrl in _gui {
; 			ctrl.Opt(dark ? "+Background" this.settings.darkThemeColor : "-Background")
; 			ctrl.SetFont(font)
; 			if (ctrl is Gui.Button || ctrl is Gui.ListView) {
; 				; todo: listview headers dark -> https://www.autohotkey.com/boards/viewtopic.php?t=115952
; 				; and https://www.autohotkey.com/board/topic/76897-ahk-u64-issue-colored-text-in-listview-headers/
; 				; maybe https://www.autohotkey.com/boards/viewtopic.php?t=87318
; 				DllCall("uxtheme\SetWindowTheme", "ptr", ctrl.hwnd, "str", (dark ? "DarkMode_Explorer" : ""), "ptr", 0)
; 			}
; 			if (ctrl.Name && SubStr(ctrl.Name, 1, 10) == "EditAddRow") {
; 				this.validValueChecker(ctrl)
; 			}
; 		}
; 		; todo: setting to make this look like this ?
; 		; DllCall("uxtheme\SetWindowTheme", "ptr", _gui.LV.hwnd, "str", "Explorer", "ptr", 0)
; 	}

; 	guiClose(guiObj) {
; 		objRemoveValue(this.guis, guiObj)
; 		guiObj.Destroy()
; 	}

; 	dropFiles(gui, ctrlObj, fileArr, x, y) {
; 		if (fileArr.Length > 1)
; 			return
; 		this.loadData(fileArr[1], gui)
; 	}

; 	settingsHandler(setting := "", value := "", save := true, extra*) {
; 		switch setting, 0 {
; 			case "darkmode":
; 				this.settings.darkMode := (value == -1 ? !this.settings.darkMode : value)
; 				this.toggleDarkMode(this.settings.darkMode, extra*)
; 			default:
; 				throw(Error("uhhh setting: " . setting))
; 		}
; 		if (save)
; 			this.settingsManager("Save")
; 	}


; 	static getDefaultSettings() {
; 		settings := {
; 			debug: false,
; 			darkMode: true,
; 			darkThemeColor: "0x1E1E1E",
; 			darkThemeFontColor: "0xFFFFFF"
; 		}
; 		return settings
; 	}
; }

