; https://github.com/cobracrystal/ahk

#Requires Autohotkey v2+

class TrayMenu {

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
	SendEvent("^v")
	Sleep(150)
	A_Clipboard := ClipboardOld
	return 1
}

objContainsValue(obj, value) {
	if !(obj is Array || obj is Map)
		throw Error("objContains does not handle type " . obj.base.__Class)
	for i, e in obj
		if (e = value)
			return i
	return 0
}

objRemoveValue(obj, value) {
	if !(obj is Array || obj is Map)
		throw Error("objRemoveValue does not handle type " . obj.base.__Class)
	for i, e in obj {
		if (e = value) {
			if (obj is Array)
				obj.RemoveAt(i)
			else 
				obj.Delete(i)
			return 1
		}
	}
	return 0
}

objRemoveValues(obj, removeAll := 1, values*) {
	if !(obj is Array || obj is Map)
		throw Error("objRemoveValues does not handle type " . obj.base.__Class)
	toRemove := []
	for i, e in obj {
		for j, f in values {
			if (e = f) {
				toRemove.push(i)
				if (!removeAll)
					break
			}
		}
	}
	while (toRemove.Length > 0) {
		nE := toRemove.Pop()
		if (obj is Array)
			obj.RemoveAt(nE)
		else
			obj.Delete(nE)
	}
	return 1
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
	Sort(str, mode)
	Loop Parse, str, "`n" {
		if (A_LoopField == "")
			continue
		arr2.push(A_LoopField)
	}
	return arr2
}

; gets a map of maps. sorts it by a key of the submap, returns it as array
; requires all contents of mapInner[key] to be of the same type (number or string)
sortObjectByKey(tmap, key, mode := "") {
	isArr := tMap is Array
	isMap := tMap is Map 
	if !(tmap is Object)
		throw ValueError("Expected Object, but got " tmap.Prototype.Name)
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
	Loop(strArr.Length) {
		if (counter > strArr.Length)
			break
		el := isString ? strArr[counter] . "" : Number(strArr[counter])
		for j, f in arr2[el] {
			arr3.push({index:f, value: isObj ? tmap.%f% : tmap[f]})
		}
		counter += arr2[el].Length
	}
	return arr3
}

reverseString(str) {
	result := ""
	Loop Parse, str
		result := A_LoopField . result
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
			arr.push(A_Loopfield . SubStr(str, count+1, 1))
			count += 2
			continue
		}
		arr.push(A_LoopField)
		count += StrLen(A_LoopField) + StrLen(delim)
	}
	return arr
}

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
	Loop Parse, text {
		if (alphMap.Has(A_LoopField))
			result .= alphMap[A_LoopField]
		else
			result .= A_Loopfield
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
 * 
 * @param string String in which to replace the strings
 * @param from Array containing strings that are to be replaced in decreasing priority order
 * @param to Array containing strings that are the replacements for values in @from, in same order
 * @param {number} index Internally used only
 * @returns {string} 
 */
recursiveReplaceMap(string, &from, to, __index := 1) {
	replacedString := ""
	if (__index == from.Count)
		return StrReplace(string, from[__index], to[__index])
	strArr := StrSplit(string, from[__index])
	for i, e in strArr
		replacedString .= recursiveReplaceMap(e, &from, to, __index + 1) . (i == strArr.Count ? "" : to[__index])
	return replacedString
}

MapToObj(mapInput, recursive := true) {
	flag := mapInput is Map
	flagObj := !(mapInput is Map || mapInput is Array)
	flagAny := !(mapInput is Object)
	if (flagAny)
		return mapInput
	objI := {}
	objE := flagObj ? {} : flag ? Map() : Array()
	if (objE is Array)
		objE.Length := mapInput.Length
	for i, e in (flagObj ? mapInput.OwnProps() : mapInput) {
		if (recursive)
			f := MapToObj(e, true)
		if (flag)
			objI.%i% := f ?? e
		if (!flag && recursive) {
			(flagObj ? objE.%i% := f : objE[i] := f)
		}
	}
	return (flag ? objI : recursive ? objE : mapInput)
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
			return DateAdd(dateTime, value*7, "D")
		case "Years", "Y":
			newTime := (SubStr(dateTime, 1, 4)+value) . SubStr(dateTime, 5)
			if !IsTime(newTime) ; leap day
				newTime := SubStr(newTime, 1, 4) . SubStr(DateAdd(dateTime, 1, "D"), 5)
			return newTime
		case "Months", "Mo":
			month := Format("{:02}", Mod(SubStr(dateTime, 5, 2) + value - 1, 12) + 1)
			year := SubStr(dateTime, 1, 4) + (SubStr(dateTime, 5, 2) + value - 1)//12
			nextMonth := Format("{:02}", Mod(month, 12) + 1)
			nextYear := year + month//12 ; technically unnecessary since when the fuck do we have an invalid december date
			rolledOverDays := Format("{:02}", SubStr(dateTime, 7, 2) - DateDiff(nextYear . nextMonth, year . month, "D"))
			if (rolledOverDays > 0)
				return nextYear . nextMonth . rolledOverDays . SubStr(dateTime, 9)
			else
				return year . month . SubStr(dateTime, 7)
		default:
			throw Error("Invalid Time Unit: " timeUnit)
	}
}
/*
* Given a set of time units, returns a YYYYMMDDHH24MISS timestamp of the earlist possible time in the future when all given parts match
* Examples: The current time is 27th December, 2023, 17:16:34
* parseTime() => A_Now
* parseTime(2023,12) => A_Now.
* parseTime(2023, , 27) => A_Now.
* parseTime(2023, , 28) => 20231228000000.
* parseTime(, 2, 29) => 20240229000000 (next leap year).
* parseTime(2022, ...) => 0.
* parseTime(2025, 02, 29) => throw Error: Invalid Date 
* parseTime(, 1, , , 19) => 20240101001900
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
					tStamp := SubStr(tStamp 1, 4) . tf(A_MM+1) . SubStr(tStamp, 7)
				if (!IsTime(tStamp))
					throw ValueError("Invalid date specified.")
			}
			if (DateDiff(tStamp, Now, "S") >= 0)
				return tStamp
			; this case is ONLY for when year is in the present AND there is no gap present (if year is in the future, datediff must be positive.)
			if (data[3] < 6) ; populate unset vars with current time before giving up
				return parseTime(years, months ?? A_MM, days ?? A_DD, hours ?? A_Hour, minutes ?? A_Min, seconds ?? A_Sec)
			return 0 ; a year in the past will never occur again
		case 2:
			if (months == A_MM && data[2]) {
				tStamp := parseTime(,, days?, hours?, minutes?, seconds?)
				return SubStr(tStamp, 5, 2) == months ? tStamp : DateAddW(tStamp, 1, "Y")
			}
			tStamp := A_YYYY tf(months) tf(days ?? 1) tf(hours ?? 0) tf(minutes ?? 0) tf(seconds ?? 0)
			if (!IsTime(tStamp)) {
				if (months == 2 && IsSet(days) && days == 29) ; leap year
					tStamp := (A_YYYY + 4 - Mod(A_YYYY, 4)) . SubStr(tStamp, 5)
				if (!IsTime(tStamp))
					throw ValueError("Invalid date specified.")
			}
			if (DateDiff(tStamp, Now, "S") >= 0)
				return tStamp
			if (data[3] < 6)
				return parseTime(, months, days ?? A_DD, hours ?? A_Hour, minutes ?? A_Min, seconds ?? A_Sec)
			return DateAddW(tStamp, 1, "Y")
		case 3:
			if (days == A_DD && data[2]) {
				tStamp := parseTime(,,, hours?, minutes?, seconds?)
				return (SubStr(tStamp, 7, 2) == days) ? tStamp : DateAddW(tStamp, 1, "Mo")
			}
			tStamp := SubStr(Now, 1, 6) tf(days) tf(hours ?? 0) tf(minutes ?? 0) tf(seconds ?? 0)
			if (!IsTime(tStamp)) {
				if (A_MM == 02 && days == 29) ; leap year
					tStamp := (A_YYYY + 4 - Mod(A_YYYY, 4)) . SubStr(tStamp, 5)
				else if (days > 29) ; correct possible month error. no need for mod, since dec has 31 days
					tStamp := SubStr(tStamp 1, 4) . tf(A_MM+1) . SubStr(tStamp, 7)
				if (!IsTime(tStamp))
					throw ValueError("Invalid date specified.")
			}
			if (DateDiff(tStamp, Now, "S") >= 0)
				return tStamp
			if (data[3] < 6)
				return parseTime(,, days, hours ?? A_Hour, minutes ?? A_Min, seconds ?? A_Sec)
			return DateAddW(tStamp, 1, "Mo")
		case 4:
			if (hours == A_Hour && data[2]) {
				tStamp := parseTime(,,,, minutes?, seconds?)
				return (SubStr(tStamp, 9, 2) == hours) ? tStamp : DateAddW(tStamp, 1, "D")
			}
			tStamp := SubStr(Now, 1, 8) tf(hours) tf(minutes ?? 0) tf(seconds ?? 0)
			if (DateDiff(tStamp, Now, "S") >= 0)
				return tStamp
			if (data[3] < 6)
				return parseTime(,,, hours, minutes ?? A_Min, seconds ?? A_Sec)
			return DateAddW(tStamp, 1, "D")
		case 5:
			if (minutes == A_Min) {
				tStamp := parseTime(,,,,, seconds?)
					return SubStr(tStamp, 11, 2) == minutes ? tStamp : 0
			}
			tStamp := SubStr(Now, 1, 10) . tf(minutes) . tf(seconds ?? 0)
			if (DateDiff(tStamp, Now, "S") >= 0)
				return tStamp
			if (data[3] < 6)
				return parseTime(,,,, minutes, seconds ?? A_Sec)
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
		mapA := Map(1, y?, 2, mo?, 3, d?, 4, h?, 5, m?, 6, s?),	first := 0, last := 0
		for i, e in mapA {
			if (A_Index == 1)
				first := i
			last := i
			if (first+A_Index-1 != i)
				return [first, true, last]
		}
		return [first, false, last]
	}
}

enumerateDay(day) {
	d := Substr(day,1,2)
	switch d {
		case "mo":
			day := 2
		case "di","tu":
			day := 3
		case "mi","we":
			day := 4
		case "do","th":
			day := 5
		case "fr":
			day := 6
		case "sa":
			day := 7
		case "so","su":
			day := 1
		default:
			return -1
	}
	return A_DD - A_WDAY + day
}

ExecScript(expression, Wait := true) {
	input := '#Warn All, Off`nFileAppend(' . expression . ', "*")'
	shell := ComObject("WScript.Shell")
	exec := shell.Exec("AutoHotkey.exe /ErrorStdOut *")
	exec.StdIn.Write(input)
	exec.StdIn.Close()
	if Wait
		return exec.StdOut.ReadAll()
}

cmdRet(sCmd, callBackFuncObj := "", encoding := '') {
	; encoding := "CP" . DllCall("GetOEMCP", "UInt") ; CP0 -> Ansi, CP850 Western European Ansi.
	static HANDLE_FLAG_INHERIT := 0x1, CREATE_NO_WINDOW := 0x08000000, STARTF_USESTDHANDLES := 0x100
    if (encoding == '')
		encoding := "CP" . DllCall('GetOEMCP', 'UInt')
	DllCall("CreatePipe", "PtrP", &hPipeRead := 0, "PtrP", &hPipeWrite := 0, "Ptr", 0, "UInt", 0)
	DllCall("SetHandleInformation", "Ptr", hPipeWrite, "UInt", HANDLE_FLAG_INHERIT, "UInt", HANDLE_FLAG_INHERIT)

	STARTUPINFO := Buffer(size := A_PtrSize * 4 + 4 * 8 + A_PtrSize * 5, 0)
	NumPut("UInt", size, STARTUPINFO)
	NumPut("UInt", STARTF_USESTDHANDLES, STARTUPINFO, A_PtrSize * 4 + 4 * 7)
	NumPut("Ptr", hPipeWrite, "Ptr", hPipeWrite, STARTUPINFO, A_PtrSize * 4 + 4 * 8 + A_PtrSize * 3)

	PROCESS_INFORMATION := Buffer(A_PtrSize * 2 + 4 * 2, 0)
	if !DllCall("CreateProcess", "Ptr", 0, "Str", sCmd, "Ptr", 0, "Ptr", 0, "UInt", true, "UInt", CREATE_NO_WINDOW,
		"Ptr", 0, "Ptr", 0, "Ptr", STARTUPINFO, "Ptr", PROCESS_INFORMATION) {
		DllCall("CloseHandle", "Ptr", hPipeRead)
		DllCall("CloseHandle", "Ptr", hPipeWrite)
		throw OSError("CreateProcess has failed")
	}
	DllCall("CloseHandle", "Ptr", hPipeWrite)
	sTemp := Buffer(4096)
	while DllCall("ReadFile", "Ptr", hPipeRead, "Ptr", sTemp, "UInt", 4096, "UIntP", &nSize := 0, "UInt", 0) {
		sOutput .= stdOut := StrGet(sTemp, nSize, encoding)
		if (callBackFuncObj)
			callBackFuncObj(stdOut)
	}
	DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, "Ptr"))
	DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, A_PtrSize, "Ptr"))
	DllCall("CloseHandle", "Ptr", hPipeRead)
	return sOutput
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

	CMD := NumGet(WP, 8, "Int") ; ShowCMD
	flags := NumGet(WP, 4, "Int")  ; flags
	MinX := NumGet(WP, 12, "Int")
	MinY := NumGet(WP, 16, "Int")
	MaxX := NumGet(WP, 20, "Int")
	MaxY := NumGet(WP, 24, "Int")        

	return { X: Lo, Y: to, W: Wo, H: Ho , cmd: CMD, flags: flags, MinX: MinX, MinY: MinY, MaxX: MaxX, MaxY: MaxY }
}

SetWindowPlacement(hwnd:="", X:="", Y:="", W:="", H:="", action := 9) {        
	DllCall("User32.dll\GetWindowPlacement", "Ptr", hwnd, "Ptr", WP := Buffer(44))
	Lo := NumGet(WP, 28, "Int")        ; X coordinate of the upper-left corner of the window in its original restored state
	To := NumGet(WP, 32, "Int")        ; Y coordinate of the upper-left corner of the window in its original restored state
	Wo := NumGet(WP, 36, "Int") - Lo   ; Width of the window in its original restored state
	Ho := NumGet(WP, 40, "Int") - To   ; Height of the window in its original restored state
	L := X = "" ? Lo : X               ; X coordinate of the upper-left corner of the window in its new restored state
	T := Y = "" ? To : Y               ; Y coordinate of the upper-left corner of the window in its new restored state
	R := L + (W = "" ? Wo : W)         ; X coordinate of the bottom-right corner of the window in its new restored state
	B := T + (H = "" ? Ho : H)         ; Y coordinate of the bottom-right corner of the window in its new restored state

	NumPut("UInt",action,WP,8)
	NumPut("UInt",L,WP,28)
	NumPut("UInt",T,WP,32)
	NumPut("UInt",R,WP,36)
	NumPut("UInt",B,WP,40)
	
	Return DllCall("User32.dll\SetWindowPlacement", "Ptr", hwnd, "Ptr", WP)
}

timedTooltip(text := "", durationMS := 1000, x?, y?, whichTooltip?) {
	ToolTip(text, x?, y?, whichTooltip?)
	SetTimer(stopTooltip, -1 * durationMS)

	stopTooltip() {
		ToolTip(, , , whichTooltip?)
	}
}

sendRequest(url := "https://icanhazip.com/", method := "GET") {
	HttpObj := ComObject("WinHttp.WinHttpRequest.5.1")
	HttpObj.Open(method, url)
	HttpObj.Send()
	return Trim(httpobj.ResponseText, "`n`r`t ")
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

class ExGui {

	__New(debug := 0, useTrayMenu := 0, name := "ExGUI") {

		this.settingsManager("Load")
		this.settings.debug := debug

		this.menu := this.createMenu()
		if (useTrayMenu) {
			tableFilterMenu := TrayMenu.submenus["tablefilter"]
			tableFilterMenu.Add("Open GUI", (*) => this.guiCreate())
			tableFilterMenu.Add("Use Dark Mode", (iName, iPos, menuObj) => this.settingsHandler("Darkmode", -1, true, menuObj, iName))
			if (this.settings.darkMode)
				tableFilterMenu.Check("Use Dark Mode")
		}
		A_TrayMenu.Add("ExGUI", tableFilterMenu)
	}

	guiCreate() {
		newGui := Gui("+Border")
		newGui.OnEvent("Close", this.guiClose.bind(this))
		newGui.OnEvent("Escape", this.guiClose.bind(this))
		newGui.OnEvent("DropFiles", this.dropFiles.bind(this))
		newGui.SetFont("c0x000000") ; this is necessary to force font of checkboxes / groupboxes
		newGui.Show("AutoSize")
	}
		
	toggleGuiDarkMode(_gui, dark) {
		static WM_THEMECHANGED := 0x031A
		;// title bar dark
		if (VerCompare(A_OSVersion, "10.0.17763")) {
			attr := 19
			if (VerCompare(A_OSVersion, "10.0.18985")) {
				attr := 20
			}
			if (dark)
				DllCall("dwmapi\DwmSetWindowAttribute", "ptr", _gui.hwnd, "int", attr, "int*", true, "int", 4)
			else
				DllCall("dwmapi\DwmSetWindowAttribute", "ptr", _gui.hwnd, "int", attr, "int*", false, "int", 4)
		}
		_gui.BackColor := (dark ? this.settings.darkThemeColor : "Default") ; "" <-> "Default" <-> 0xFFFFFF
		font := (dark ? "c" this.settings.darkThemeFontColor : "cDefault")
		_gui.SetFont(font)
		for cHandle, ctrl in _gui {
			ctrl.Opt(dark ? "+Background" this.settings.darkThemeColor : "-Background")
			ctrl.SetFont(font)
			if (ctrl is Gui.Button || ctrl is Gui.ListView) {
				; todo: listview headers dark -> https://www.autohotkey.com/boards/viewtopic.php?t=115952
				; and https://www.autohotkey.com/board/topic/76897-ahk-u64-issue-colored-text-in-listview-headers/
				; maybe https://www.autohotkey.com/boards/viewtopic.php?t=87318
				DllCall("uxtheme\SetWindowTheme", "ptr", ctrl.hwnd, "str", (dark ? "DarkMode_Explorer" : ""), "ptr", 0)
			}
			if (ctrl.Name && SubStr(ctrl.Name, 1, 10) == "EditAddRow") {
				this.validValueChecker(ctrl)
			}
		}
		; todo: setting to make this look like this ? 
		; DllCall("uxtheme\SetWindowTheme", "ptr", _gui.LV.hwnd, "str", "Explorer", "ptr", 0)
	}

	guiClose(guiObj) {
		objRemoveValue(this.guis, guiObj)
		guiObj.Destroy()
	}

	dropFiles(gui, ctrlObj, fileArr, x, y) {
		if (fileArr.Length > 1)
			return
		this.loadData(fileArr[1], gui)
	}

	settingsHandler(setting := "", value := "", save := true, extra*) {
		switch setting, 0 {
			case "darkmode":
				this.settings.darkMode := (value == -1 ? !this.settings.darkMode : value)
				this.toggleDarkMode(this.settings.darkMode, extra*)
			default:
				throw Error("uhhh setting: " . setting)
		}
		if (save)
			this.settingsManager("Save")
	}


	static getDefaultSettings() {
		settings := {
			debug: false,
			darkMode: true,
			darkThemeColor: "0x1E1E1E",
			darkThemeFontColor: "0xFFFFFF"
		}
		return settings
	}
}