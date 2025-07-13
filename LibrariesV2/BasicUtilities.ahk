; https://github.com/cobracrystal/ahk

#Include "%A_LineFile%\..\..\LibrariesV2\jsongo.ahk"

class TrayMenu {
	; ADD TRACKING FOR CHILD MENUS
	static __New() {
		this.menus := Map()
		this.menus.CaseSense := 0
		this.TrayMenu := A_TrayMenu
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

fastCopy(timeout := 1) {
	ClipboardOld := ClipboardAll()
	A_Clipboard := "" ; free clipboard so that ClipWait is more reliable
	Send("^c")
	if !ClipWait(timeout) {
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

htmlDecode(str) {
	static HTMLCodes := jsongo.Parse(FileRead(A_WorkingDir "\everything\HTML_Encodings.json", "UTF-8"))
	if InStr(str, "&") {
		while (pos := RegExMatch(str, "(&.*?;)", &o, pos ?? 1) + (o ? o.Len : 0)) {
			if (HTMLCodes.Has(o[1]))
				str := StrReplace(str, o[1], HTMLCodes[o[1]])
		}
	}
	return str
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
objCountValue(obj, value, comparator := (itKey,itVal,setVal) => (itVal = setVal)) {
	isArrLike := (obj is Array || obj is Map)
	if !(isArrLike || obj is Object)
		throw(TypeError("objCountValue does not handle type " . Type(obj)))
	count := 0
	for i, e in (isArrLike ? obj : obj.OwnProps())
		if (comparator(i, e, value))
			count++
	return count
}

/**
 * Checks whether obj contains given value and returns index if found, else 0
 * @param obj 
 * @param value 
 * @param {Func} comparator 
 * @returns {Integer} 
 */
objContainsValue(obj, value, comparator := (itKey,itVal,setVal) => (itVal = setVal)) {
	isArrLike := (obj is Array || obj is Map)
	if !(isArrLike || obj is Object)
		throw(TypeError("objContainsValue does not handle type " . Type(obj)))
	for i, e in (isArrLike ? obj : obj.OwnProps())
		if (comparator(i, e, value))
			return i
	return 0
}

/**
 * Returns a deep copy of a given object.
 * @param obj A .Clone()-able object
 * @returns {Object} A deep clone of the given object
 */
objClone(obj) {
	isArrLike := (obj is Array || obj is Map)
	if !(obj is Object)
		return obj
	copy := obj.Clone()
	for i, e in (isArrLike ? obj : obj.OwnProps())
		isArrLike ? copy[i] := objClone(e) : copy.%i% := objClone(e)
	return copy
}

/**
 * Deletes given Value from Object {limit} times. Returns count of removed values
 * @param {Array | Map} obj
 * @param value the value to remove
 * @param {Integer} limit if 0, removes all
 * @returns {Integer} count
 */
objRemoveValue(obj, value := "", limit := 0, comparator := ((itKey, itVal, val) => (itVal = val)), emptyValue?) {
	isArrLike := ((isArr := obj is Array) || obj is Map)
	if !(isArrLike || obj is Object)
		throw(TypeError("objRemoveValue does not handle type " . Type(obj)))
	queue := []
	count := 0
	for i, e in (isArrLike ? obj : obj.OwnProps())
		if (comparator(i, e, value)) {
			if (!limit || count++ < limit)
				queue.push(i)
			else
				break
		}
	n := queue.Length
	if (IsSet(emptyValue)) {
		for e in queue
			isArrLike ? obj[e] := emptyValue : obj.%e% := emptyValue
	} else {
		while (queue.Length != 0)
			isArrLike ? (isArr ? obj.RemoveAt(queue.Pop()) : obj.Delete(queue.Pop())) : obj.DeleteProp(queue.Pop())
	}
	return n
}

/**
 * Deletes given Value from Object, either on first encounter or on all encounters. Returns count of removed values
 * @param obj 
 * @param values 
 * @param {Integer} limit 
 * @param {(iterator, value) => Number} comparator 
 * @param emptyValue If this is set, all encountered values are not removed, but instead replaced by this value.
 * @returns {Integer} 
 */
objRemoveValues(obj, values, limit := 0, comparator := ((itKey,itVal,setVal) => (itVal = setVal)), emptyValue?) {
	isArrLike := ((isArr := obj is Array) || obj is Map)
	if !(isArrLike || obj is Object)
		throw(TypeError("objRemoveValues does not handle type " . Type(obj)))
	queue := []
	count := 0
	for i, e in (isArrLike ? obj : obj.OwnProps())
		for f in values
			if (comparator(i, e, f)) {
				if (!limit || count++ < limit)
					queue.push(i)
				else
					break
			}
	n := queue.Length
	if (IsSet(emptyValue)) {
		for e in queue
			isArrLike ? obj[e] := emptyValue : obj.%e% := emptyValue
	} else {
		while (queue.Length != 0)
			isArrLike ? (isArr ? obj.RemoveAt(queue.Pop()) : obj.Delete(queue.Pop())) : obj.DeleteProp(queue.Pop())
	}
	return n
}

objDoForEach(obj, fn := ((e) => (objToString(e))), value := 0, conditional := ((itKey, itVal, setVal) => (true))) {
	isArrLike := (obj is Array || obj is Map)
	isMap := (obj is Map)
	if !(isArrLike || obj is Object)
		throw(TypeError("objDoForEach does not handle type " . Type(obj)))
	clone := %Type(obj)%()
	for i, e in (isArrLike ? obj : obj.OwnProps())
		if (conditional(i, e, value))
			(isArrLike ? (isMap ? clone[i] := fn(e) : clone.push(fn(e))) : clone.%i% := fn(e))
	return clone
}

objGetMinimum(obj) => objCollect(obj, (a,b) => Min(a,b))
objGetMaximum(obj) => objCollect(obj, (a,b) => Max(a,b))
objGetAverage(obj) => objCollect(obj, (a,b) => (a+b)) / (obj is Array ? obj.Length : obj.Count)

/**
 * 
 * @param obj 
 * @param {Func} fn function responsible for collecting objects. Equivalent to fn(fn(....fn(fn(base,obj[1]),obj[2])...,obj[n-1]),obj[n])
 * @param {Any} initialBase Initial value of the base on which fn operates. If not given, first element in object becomes base. Set this if fn operators onto properties or items of enumerable values.
 * @param {Any} value Optional Value to check conditional upon
 * @param {Func} conditional Optional Comparator to determine which values to include in collection.
 * @returns {Any} Collected Value
 */
objCollect(obj, fn := ((base, iterator) => (base . objToString(iterator))), initialBase?, value := 0, conditional := ((itKey, itVal, setVal) => (true))) {
	isArrLike := (obj is Array || obj is Map)
	if !(isArrLike || obj is Object)
		throw(TypeError("objForEach does not handle type " . Type(obj)))
	if (IsSet(initialBase))
		base := initialBase
	for i, e in (isArrLike ? obj : obj.OwnProps())
		if (conditional(i, e, value))
			base := IsSet(base) ? fn(base, e) : e
	return base ?? ""
}

/**
 * 
 * @param obj Object to search duplicates in
 * @param {(a) => (a)} fn Function to get value to compare for duplications. Ie for [{x:1,y:5},{x:4,y:5}] specify (a) => (a.y) to get entries where y is the same
 * @returns {Array} Array of indices of duplicates in ascending order
 */
objGetDuplicates(obj, fn := (a => a), caseSense := true) {
	isArrLike := (obj is Array || obj is Map)
	if !(isArrLike || obj is Object)
		throw(TypeError("objForEach does not handle type " . Type(obj)))
	duplicateMap := Map()
	counterMap := Map()
	duplicateIndices := []
	duplicateMap.CaseSense := caseSense
	for i, e in (isArrLike ? obj : obj.OwnProps()) {
		v := fn(e)
		if (duplicateMap.Has(v)) {
			duplicateMap[v].push([i, e])
			counterMap[v] := 1
		}
		else
			duplicateMap[v] := [[i, e]]
	}
	for i, e in (isArrLike ? obj : obj.OwnProps()) {
		v := fn(e)
		if (duplicateMap[v].Length > 1)
			duplicateIndices.push(duplicateMap[v][counterMap[v]++][1])
	}
	return duplicateIndices
}

/**
 * 
 * @param obj Object to search duplicates in
 * @param {(a) => (a)} fn Function to get value to compare for duplications. Ie for [{x:1,y:5},{x:4,y:5}] specify (a) => (a.y) to get entries where y is the same
 * @returns {Object} CLONE of obj without duplicates
 */
objRemoveDuplicates(obj, fn := (a => a), caseSense := true) {
	isArrLike := (obj is Array || obj is Map)
	isMap := (obj is Map)
	if !(isArrLike || obj is Object)
		throw(TypeError("objForEach does not handle type " . Type(obj)))
	duplicateMap := Map()
	duplicateIndices := []
	duplicateMap.CaseSense := caseSense
	for i, e in (isArrLike ? obj : obj.OwnProps()) {
		v := fn(e)
		if (duplicateMap.Has(v))
			duplicateMap[v].push([i, e])
		else
			duplicateMap[v] := [[i, e]]
	}
	clone := %Type(obj)%()
	for i, e in (isArrLike ? obj : obj.OwnProps()) {
		v := fn(e)
		if (duplicateMap[v].Length == 1)
			isArrLike ? (isMap ? clone[i] := e : clone.push(e)) : clone.%i% := e
	}
	return clone
}

/**
 * Returns true if obj1 and obj2 share the same keys and primitive values, 0 otherwise.
 * objCompare([1,2], [1,2]) => true
 * objCompare({x: 1, y: Map(1,2)}, {x: 1, y: Map(1,2)}) => true
 * objCompare(Number, {__Prototypex: 1, y: Map(1,2)}) => true
 * @param obj1 
 * @param obj2 
 */
objCompare(obj1, obj2) {
	if (Type(obj1) != Type(obj2))
		return 0
	if !(IsObject(obj1))
		return (obj1 == obj2)
	isObj := !(obj1 is Array || obj1 is Map)
	isMap := (obj1 is Map)
	count1 := isObj ? ObjOwnPropCount(obj1) : (isMap ? obj1.Count : obj1.Length)
	count2 := isObj ? ObjOwnPropCount(obj2) : (isMap ? obj2.Count : obj2.Length)
	if (count1 != count2)
		return 0
	for i, j, e, f in objZip(obj1, obj2) {
		if (i != j)
			return 0
		if !objCompare(e, f)
			return 0
	}
	return 1
}

objZip(obj1, obj2, stopAtAnyEnd := true) {
	if (Type(obj1) != Type(obj2))
		throw(TypeError("obj1 and obj2 are not of equal type, instead " Type(obj1) ", " Type(obj2)))
	if (obj1 is Array || obj1 is Map)
		obj1Enum := obj1, obj2Enum := obj2
	else
		obj1Enum := obj1.OwnProps(), obj2Enum := obj2.OwnProps()
	index := 1
	try obj1Enum := obj1Enum.__Enum(2)
	try obj2Enum := obj2Enum.__Enum(2)
	return (&i, &j, &n := -1, &m := -1) => (
		flagN := !IsSet(n), ; if for-loop passes n to this function, then it is unset. otherwise it is set.
		flagM := !IsSet(m),
		flagN ? (flagM ? flag1 := obj1Enum(&i, &n)	: i := index++ )			 : flag1 := obj1Enum(&_, &i),
		flagN ? (flagM ? flag2 := obj2Enum(&j, &m)	: flag1 := obj1Enum(&_, &j)) : flag2 := obj2Enum(&_, &j),
		flagN ? (flagM ? 0 							: flag2 := obj2Enum(&_, &n)) : 0,
		stopAtAnyEnd ? flag1 && flag2 : flag1 || flag2
	)
}

/**
 * Return a json-like representation of the given object, without altering (escaping) the data itself.
 * @param obj Object, Map, Array Value etc.
 * @param {Integer} compact Whether to use spacer value and use newline to separate nested objects (default false)
 * @param {Integer} compress Whether to omit spaces and minimize the string length (default true)
 * @param {String} spacer Value used to indent nested objects (if not compact)
 * @param {String} strEscape Whether to escape strings with quotes (JSON Style) 
 * @returns {String} 
 */
objToString(obj, compact := false, compress := true, strEscape := false, mapAsObject := true, spacer := "`t") {
	return _objToString(obj, 0)

	_objToString(obj, indentLevel) {
		static escapes := [["\", "\\"], ['"', '\"'], ["`n", "\n"], ["`t", "\t"]]
		qt := strEscape ? '"' : ''
		if !(IsObject(obj)) {
			if (obj is Number)
				return String(obj)
			if (IsNumber(obj))
				return qt obj qt
			if (strEscape) {
				for e in escapes
					obj := StrReplace(obj, e[1], e[2])
				return qt String(obj) qt
			}
			return obj
		}
		isArr := obj is Array
		isMap := obj is Map
		isObj := !(isArr || isMap)
		str := ""
		indent := (compress || compact)  ? '' : strMultiply(spacer, indentLevel + 1)
		trspace := compress ? "" : A_Space
		separator := (!compact && !compress ? '`n' indent : trspace)
		count := isObj ? ObjOwnPropCount(obj) : (isMap ? obj.Count : obj.Length)
		if (Type(obj) == "Prototype")
			return _objToString({}, indentLevel + 1)
		for key, val in (isObj ? obj.OwnProps() : obj) {
			if (!compact && compress)
				separator := (val??"") is Object && count > 1 ? '`n' : trspace
			if !(IsSet(val))
				str := RTrim(str, separator) "," separator
			else if (isArr || (isMap && !mapAsObject))
				str .= _objToString(val ?? "", indentLevel + 1) "," separator
			else
				str .= _objToString(key ?? "", indentLevel + 1) ":" trspace _objToString(val ?? "", indentLevel + 1) "," separator
		}
		sep2 := !compact && !compress ? '`n' strMultiply(spacer, indentLevel) : separator
		return ( isArr ? "[" : (isMap && !mapAsObject) ? "Map(" : "{" ) (str == '' ? '' : separator) RegExReplace(str, "," separator "$") (str == '' ? '' : sep2) ( isArr ? "]" : (isMap && !mapAsObject) ? ")" : "}" )
	}
}

range(startEnd, end?, step?, inclusive := true) {
	start := IsSet(end) ? startEnd : 1
	end := end ?? startEnd
	step := step ?? 1
	index := 1
	return (&n, &m := -1) => (
		!IsSet(m) ? 
			(n := index++, m := start, start := roundProper(start + step), inclusive ? m <= end : m < end) : 
			(n := start, start := roundProper(start + step), inclusive ? n <= end : n < end)
	)
}

rangeA(startEnd, end?, step?, inclusive := true) {
	a := []
	for e in range(startEnd, end?, step?, inclusive)
		a.push(e)
	return a
}

/**
 * Given a function fn, returns the largest possible value in given range where fn does not throw an error.
 * @param fn 
 * @param {Integer} lower 
 * @param {Integer} upper 
 */
tryCatchBinarySearch(fn, lower := 1, upper := 100000) {
	return binarySearch(newFn, lower, upper)
	
	newFn(param) {
		try {
			fn(param)
			return true
		}
		catch 
			return false
	}
}

/**
 * Given a function fn, returns the largest possible value in given range where fn returns true.
 * @param fn 
 * @param {Integer} lower 
 * @param {Integer} upper 
 */
binarySearch(fn, lower := 0, upper := 100000) {
	n := lower + (upper - lower)//2
	while(true) {
		if (Abs(lower - upper) <= 1)
			break
		if (fn(n))
			lower := n
		else
			upper := n
		n := lower + (upper - lower)//2
	}
	return n
}

arrayMerge(array1, array2) {
	arr2 := []
	arr2.push(array1*)
	arr2.push(array2*)
	return arr2
}

arraySlice(arr, from := 1, to := arr.Length) {
	arr2 := []
	to := to > arr.Length ? arr.Length : to
	Loop(to) {
		i := from + A_Index - 1
		arr2.push(arr[i])
	}
	return arr2
}

arrayFunctionMask(arr, maskFunc := (a) => (IsSet(a)), keepEmpty := true) {
	arr2 := []
	if keepEmpty
		arr2.Length := arr.Lenght
	for i, e in arr {
		if (maskFunc(e)) {
			if keepEmpty 
				arr2[i] := e
			else
				arr2.push(e)
		}
	}
	return arr2
}

arrayMask(arr, mask, keepEmpty := true) {
	if arr.Length != mask.Length
		throw Error("Invalid mask given")
	arr2 := []
	if (keepEmpty)
		arr2.Length := arr.Length
	for i, e in mask {
		if (e) {
			if (keepEmpty)
				arr2[i] := arr[i]
			else
				arr2.push(arr[i])
		}
	}
	return arr2
}

arrayIgnoreIndex(arr, index) {
	arr2 := arr.Clone()
	arr2.RemoveAt(index)
	return arr2
}

arrayIgnoreIndices(arr, indices*) {
	arr2 := arr.Clone()
	for i, e in arraySort(indices, "N R")
		arr2.RemoveAt(e)
	return arr2
}

arrayReverse(arr) {
	arr2 := []
	for i, e in arr
		arr2.InsertAt(1, e)
	return arr2
}

arraySort(arr, mode := "") {
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
arrayUniques(arr, fn := (v => v)) {
	arr2 := []
	uniques := Map()
	for i, e in arr {
		el := fn(e)
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
arrayDuplicateIndices(arr, key?, isMap := 0) {
	duplicates := Map()
	for i, e in arr {
		el := key ? (isMap ? e[key] : e.%key%) : e
		if (duplicates.Has(el))
			duplicates[el].push(i)
		else
			duplicates[el] := [i]
	}
	for i, e in duplicates
		if e.Length == 1
			duplicates.Delete(i)
	return duplicates
}

/**
 * Given an enumerable object whos values itself are objects, sorts it by value of the inner objects key.
 * @param tObj Object, Array or Map to be used for sorting. tObj must contain Objects which itself have accessable values (that of key)
 * @param key key whos matching value will be used for sorting
 * @param {String} mode Sorting mode. equivalent to sorting options in Sort [String]
 * @returns {Array} The sorted array, where each entry in the array is an object with the original index as property .index and value as .value
 */
objSortByKey(tObj, key, mode := "") {
	isArr := tObj is Array
	isMap := tObj is Map
	if !(tObj is Object)
		throw(TypeError("Expected Object, but got " tObj.Prototype.Name))
	isObj := !(isArr || isMap)
	indexMap := Map()
	retArr := []
	l := isArr ? tObj.Length : isMap ? tObj.Count : ObjOwnPropCount(tObj)
	removeDuplicates := InStr(mode, "U")
	if !l
		return []
	for i, sortKey in (isObj ? tObj.OwnProps() : tObj) {
		if (!IsSet(innerIsObj))
			innerIsObj := !(sortKey is Map || sortKey is Array)
		tv := innerIsObj ? sortKey.%key% : sortKey[key]
		if (!IsSet(isString))
			isString := (tv is String)
		if (indexMap.Has(tv) && !removeDuplicates)
			indexMap[tv].push(i)
		else
			indexMap[tv] := [i]
		str .= tv . "`n"
	}
	newStr := Sort(IsSet(str) ? SubStr(str, 1, -1) : "", removeDuplicates ? mode : mode . ' U')
	strArr := StrSplit(newStr, "`n")
	for sortKey in strArr
		for index in indexMap[isString ? String(sortKey) : Number(sortKey)]
			retArr.push({ index: index, value: isObj ? tObj.%index% : tObj[index] })
	return retArr
}

strReverse(str) {
	result := ""
	for i, e in StrSplitUTF8(str)
		result := e . result
	return result
}

strRotate(str, offset := 0) {
	offset := Mod(offset, StrLen(str))
	return SubStr(str, -1 * offset + 1) . SubStr(str, 1, -1 * offset)
}

strMultiply(str, count) {
	s := ""
	Loop(count)
		s .= str
	return s
}

strUniqueSubstrings(str, delim := " `t") {
	return objCollect(arrayUniques(StrSplitUTF8(str, delim,,true), v => Substr(v,1,-1)))
}

strRemoveConsecutiveDuplicates(str, delim := "`n") {
	pos := 0
	str2 := ""
	loop parse str, delim, "" {
		pos += StrLen(A_LoopField) + 1
		if (lastField == A_LoopField)
			continue
		str2 .= A_LoopField . SubStr(str, pos, 1) 
		lastField := A_LoopField
	}
	return str2
}

/**
 * Behaves exactly as strsplit except that if it is called without a delim and thus parses char by char, doesn't split unicode characters in two.
 * @param str 
 * @param {String} delim 
 * @param {String} omit 
 * @param {Integer} withDelim 
 * @returns {Array} 
 */
StrSplitUTF8(str, delim := "", omit := "", withDelim := false) {
	arr := []
	skip := false
	count := 0
	Loop Parse, str, delim, omit {
		char := A_LoopField
		if (skip) {
			skip := false
			continue
		}
		if (StrLen(A_LoopField) == 1 && Ord(A_LoopField) > 0xD7FF && Ord(A_LoopField) < 0xDC00) {
			arr.push(A_Loopfield . SubStr(str, count + 1, 1) . (withDelim ? SubStr(str, count+2, 1): ''))
			skip := true
			count += 2
			continue
		}
		count += StrLen(A_LoopField) + 1
		arr.push(A_LoopField . (withDelim ? SubStr(str, count, 1) : ''))
	}
	return arr
}

strMaxCharsPerLine(str, maxCharsPerLine) {
	nStr := ""
	loops := strCountStr(str, '`n') + 1
	Loop Parse str, "`n", "`r" {
		line := A_LoopField
		fWidthLines := ""
		fWidthLine := ""
		pos := 0
		Loop Parse line, " `t" {
			word := A_LoopField
			pos += StrLen(word) + 1
			wLen := StrLen(word)
			if (StrLen(fWidthLine) + wLen <= maxCharsPerLine)
				fWidthLine .= word . SubStr(line, pos, 1)
			else {
				if (fWidthLine != "")
					fWidthLines .= fWidthLine '`n'
				if (wLen <= maxCharsPerLine)
					fWidthLine := word . SubStr(line, pos, 1)
				else {
					Loop(iters := wLen//maxCharsPerLine)
						fWidthLines .= SubStr(word, (A_Index - 1) * maxCharsPerLine + 1, maxCharsPerLine) . "`n"
					if (wLen > iters * maxCharsPerLine)
						fWidthLine := SubStr(word, iters * maxCharsPerLine + 1)
				}
			}
		}
		fWidthLines := ( fWidthLine == "" ? SubStr(fWidthLines, 1, StrLen(fWidthLines) - 1) : fWidthLines . fWidthLine)
		nStr .= fWidthLines . (A_Index == loops ? '' : '`n')
	}
	return nStr
}

; only works in 2.0.9
BoundFnName(Obj) {
	Address := ObjPtr(Obj)
	n := NumGet(Address, 5 * A_PtrSize + 16, "Ptr")
	Obj := ObjFromPtrAddRef(n)
	return Obj.Name
}

replaceCharacters(text, replacer) {
	if !(replacer is Map || replacer is Func)
		return text
	result := ""
	isMap := replacer is Map
	for i, e in StrSplitUTF8(text) {
		if (isMap)
			result .= (replacer.Has(e) ? replacer[e] : e)
		else
			result .= replacer(e)
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
strRecursiveReplace(text, from, to) {
	return __recursiveReplaceMap(text, from, to)

	__recursiveReplaceMap(text, from, to, __index := 1) {
		replacedString := ""
		if (__index == from.Length)
			return StrReplace(text, from[__index], to[__index])
		strArr := StrSplit(text, from[__index])
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
	if (!(keyArray is Array) || !(valueArray is Array))
		throw(TypeError("mapFromArrays expected Arrays, got " Type(keyArray) ", " Type(valueArray)))
	else if (keyArray.Length != valueArray.Length)
		throw(ValueError("mapFromArrays expected Arrays of equal Length, got Lengths " keyArray.Length ", " valueArray.Length))
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
			throw(ValueError("Invalid Time Unit: " timeUnit))
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

ExecScript(expression, Wait := true, void := false) {
	input := '#Warn All, Off`n'
	input .= '#Include "*i ' A_LineFile '"`n'
	input .= '#Include "*i ' A_LineFile '\..\..\LibrariesV2\MathUtilities.ahk"`n'
	input .= '#Include "*i ' A_LineFile '\..\..\LibrariesV2\FileUtilities.ahk"`n'
	if (void || RegexMatch(expression, 'i)FileAppend\(.*,\s*\"\*\"\)') || RegExMatch(expression, 'i)MsgBox(?:AsGui)?\(.+\)') || RegexMatch(expression, 'i)print\(.*\)') || RegexMatch(expression, 'i)\.Show\(.*\)'))
		input .= expression
	else
		input .= 'print(' expression ',,false)'
	shell := ComObject("WScript.Shell")
	exec := shell.Exec(A_AhkPath " /ErrorStdOut *")
	exec.StdIn.Write(input)
	exec.StdIn.Close()
	if Wait
		return RTrim(exec.StdOut.ReadAll(), " `t`n")
}

cmdRet(sCmd, callBackFuncObj := "", encoding := 'UTF-8') {
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

cmdRetAsync(sCmd, &returnValue, callBackFuncObj := "", timePerCheck := 50, finishCallBackFuncObj := "", encoding := 'UTF-8') {
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

getMonitors() {
	monitors := []
	Loop(MonitorGetCount())
	{
		MonitorGet(A_Index, &mLeft, &mTop, &mRight, &mBottom)
		monitors.push({MonitorNumber:A_Index, Left:mLeft, Right:mRight, Top:mTop, Bottom:mBottom})
	}
	return monitors
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
	return {x: x, y: y, w: w, h: h, cw: cw, ch: ch, mmx: (mmx == 3 ? 1 : (mmx == 2 ? -1 : 0))}
}

resetWindowPosition(wHandle := Winexist("A"), sizePercentage?, monitorNum?) {
	NumPut("Uint", 40, monitorInfo := Buffer(40))
	if (IsSet(monitorNum)) {
		MonitorGetWorkArea(monitorNum, &monLeft, &monTop, &monRight, &monBottom)
	} else {
		monitorHandle := DllCall("MonitorFromWindow", "Ptr", wHandle, "UInt", 0x2, "Ptr")
		DllCall("GetMonitorInfo", "Ptr", monitorHandle, "Ptr", monitorInfo)
			monLeft := NumGet(monitorInfo, 20, "Int") ; Left
			monTop := NumGet(monitorInfo, 24, "Int") ; Top
			monRight := NumGet(monitorInfo, 28, "Int") ; Right
			monBottom := NumGet(monitorInfo, 32, "Int") ; Bottom
	}
	WinRestore(wHandle)
	WinGetPos(&x, &y, &w, &h, wHandle)
	if (IsSet(sizePercentage))
		WinMove(
			monLeft + (monRight - monLeft) * (1 - sizePercentage) / 2, ; left edge of screen + half the width of it - half the width of the window, to center it.
			monTop + (monBottom - monTop) * (1 - sizePercentage) / 2,  ; same as above but with top bottom
			(monRight - monLeft) * sizePercentage,	; width
			(monBottom - monTop) * sizePercentage,	; height
			wHandle
		)
	else
		WinMove(
			monLeft + (monRight - monLeft) / 2 - w / 2, 
			monTop + (monBottom - monTop) / 2 - h / 2, , , wHandle
		)
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
		throw(ValueError("Invalid num"))
	if (intensity < 0 || intensity > 255)
		throw(ValueError("Invalid Intensity"))
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
	if (!RegexMatch(color, "(?:0x)?[[:xdigit:]]{1,6}"))
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
	SetTimer(IsSet(whichTooltip) ? stopTooltip.bind(whichTooltip) : stopTooltip, -1 * durationMS)

	stopTooltip(whichTooltip?) {
		ToolTip(, , , whichTooltip?)
	}
}

MsgBoxAsGui(text := "Press OK to continue", title := A_ScriptName, buttonStyle := 0, defaultButton := 1, wait := false, funcObj := 0, owner := 0, addCopyButton := 0, buttonNames := [], icon := 0, timeout := 0, maxCharsVisible?, maxTextWidth := 400) {
	static MB_OK 						:= 0
	static MB_OKCANCEL 					:= 1
	static MB_ABORTRETRYIGNORE 			:= 2
	static MB_YESNOCANCEL 				:= 3
	static MB_YESNO 					:= 4
	static MB_RETRYCANCEL 				:= 5
	static MB_CANCELRETRYCONTINUE 		:= 6
	static MB_CUSTOM4BTNS				:= 7
	static MB_CUSTOM5BTNS				:= 8
	static MB_CUSTOM6BTNS				:= 9
	static MB_TEXT_MAP := Map(
		MB_OK,					["OK"],
		MB_OKCANCEL,			["OK", "Cancel"],
		MB_ABORTRETRYIGNORE,	["Abort", "Retry", "Ignore"],
		MB_YESNOCANCEL,			["Yes", "No", "Cancel"],
		MB_YESNO,				["Yes", "No"],
		MB_RETRYCANCEL,			["Retry", "Cancel"],
		MB_CANCELRETRYCONTINUE,	["Cancel", "Retry", "Continue"],
		MB_CUSTOM4BTNS,	[1,2,3,4],
		MB_CUSTOM5BTNS,	[1,2,3,4,5],
		MB_CUSTOM6BTNS,	[1,2,3,4,5,6]
	)

	/*
    Icon
	static Error      => 0x10
	static Question   => 0x20
	static Warning    => 0x30
	static Info       => 0x40

    static Default2       => 0x100
    static Default3       => 0x200
    static Default4       => 0x300

    static SystemModal    => 0x1000
    static TaskModal      => 0x2000
    static AlwaysOnTop    => 0x40000

    static HelpButton     => 0x4000
    static RightJustified => 0x80000
    static RightToLeft    => 0x100000
	*/

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
	static retValue := ""

	bottomGap := leftMargin
	BottomHeight := buttonHeight + 2 * bottomGap
	if !(MB_TEXT_MAP.Has(buttonStyle))
		throw Error("Invalid button Style")
	if (buttonNames.Length == 0)
		buttonNames := MB_TEXT_MAP[buttonStyle]
	else if (MB_TEXT_MAP[buttonStyle].Length != buttonNames.Length)
		throw Error("Invalid Button Names for given Button Style")
	gStr := owner ? "+Owner" owner : ''
	guiFontOptions := MB_HASFONTINFORMATION ? "S" MB_FONTSIZE " W" MB_FONTWEIGHT (MB_FONTISITALIC ? " italic" : "") : ""
	mbgui := Gui("+ToolWindow -Resize -MinimizeBox -MaximizeBox " gStr, title)
	mbgui.Opt("+0x94C80000")
	mbgui.Opt("-ToolWindow")
	if (buttonStyle == 2 || buttonStyle == 4)
		mbgui.Opt("-SysMenu")
	mbgui.SetFont(guiFontOptions, MB_FONTNAME)
	maxTextWidth := (StrLen(text) > 10000 && !IsSet(maxCharsVisible) && maxTextWidth < 1500) ? 1500 : maxTextWidth
	nText := textCtrlAdjustSize(maxTextWidth,, IsSet(maxCharsVisible) ? SubStr(text, 1, maxCharsVisible) : text,, guiFontOptions, MB_FONTNAME)
	mbgui.AddText("x0 y0 vWhiteBoxTop " SS_WHITERECT, nText)
	mbgui.AddText("x" leftMargin " y" gap " BackgroundTrans vTextBox", nText)
	mbGui["TextBox"].GetPos(&TBx, &TBy, &TBw, &TBh)
	guiWidth := leftMargin + buttonOffset + Max(TBw, (buttonWidth + rightMargin) * (buttonNames.Length + (addCopyButton ? 1 : 0))) + 1
	guiWidth := (guiWidth < minGuiWidth ? minGuiWidth : guiWidth)
	whiteBoxHeight := TBy + TBh + gap
	mbGui["WhiteBoxTop"].Move(0, 0, guiWidth, whiteBoxHeight)
	buttonX := guiWidth - (rightMargin + buttonWidth) * (buttonNames.Length + (addCopyButton ? 1 : 0))
	buttonY := whiteBoxHeight + bottomGap
	for i, e in buttonNames
		mbgui.AddButton(Format("vButton{} x{} y{} w{} h{}", i, buttonX + (i-1) * (buttonWidth + rightMargin), buttonY, buttonWidth, buttonHeight), e).OnEvent("Click", finalEvent.bind(buttonStyle, i))
	if (addCopyButton)
		mbgui.AddButton(Format("vButton0 x{} y{} w{} h{}", buttonX + buttonNames.Length * (buttonWidth + rightMargin), buttonY, buttonWidth, buttonHeight), "Copy").OnEvent("Click", (guiCtrl, infoObj) => (A_Clipboard := text))
	mbGui["Button" defaultButton].Focus()
	guiHeight := whiteBoxHeight + BottomHeight
	if (buttonStyle != 2 && buttonStyle != 4)
		mbGui.OnEvent("Escape", (*) => finalEvent(buttonStyle, 0, 0, 0))
	mbGui.OnEvent("Close", (*) => finalEvent(buttonStyle, 0, 0, 0))
	mbgui.Show("Center w" guiWidth " h" guiHeight)
	if (wait) {
		WinWait(hwnd := mbgui.hwnd)
		WinWaitClose(hwnd)
		return retValue
	}
	return mbgui

	finalEvent(buttonStyle, buttonNumber, buttonCtrl, info) {
		mbgui.Destroy()
		retValue := buttonStyle == 0 ? "OK" : (buttonNumber == 0 ? "Cancel" : buttonNames[buttonNumber])
		if (funcObj)
			funcObj(retValue)
	}
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


textCtrlAdjustSize(width, textCtrl?, str?, onlyCalculate := false, fontOptions?, fontName?) {
	if (!IsSet(textCtrl) && !IsSet(str))
		throw Error("Both textCtrl and str were not set")
	if (!IsSet(str))
		str := textCtrl.Value
	else if (!IsSet(textCtrl)) {
		local temp := Gui()
		temp.SetFont(fontOptions ?? unset, fontName ?? unset)
		textCtrl := temp.AddText()
		onlyCalculate := true
	}
	fixedWidthStr := ""
	fixedWidthLine := ""
	pos := 0
	loop parse str, " `t" {
		line := A_LoopField
		lLen := StrLen(A_LoopField)
		pos += lLen + 1
		strWidth := guiGetTextSize(textCtrl, fixedWidthLine . line)
		if (pos > 65535)
			break
		if (strWidth[1] <= width)
			fixedWidthLine .= line . substr(str, pos, 1)
		else { ; reached max width, begin new line
			fixedWidthLine := SubStr(fixedWidthLine, 1, -1)
			if (guiGetTextSize(textCtrl, line)[1] <= width) {
				fixedWidthStr .= (fixedWidthStr ? '`n' : '') fixedWidthLine . substr(str, pos, 1) 
				fixedWidthLine := ""
			}
			else { ; A_Loopfield is by itself wider than width
				fixedWidthWord := ""
				linePart := ""
				loop parse line { ; thus iterate char by char
					curWidth := guiGetTextSize(textCtrl, linePart . A_LoopField)
					if (curWidth[1] <= width) ; reached max width, begin new line
						linePart .= A_LoopField
					else {
						fixedWidthWord .= '`n' linePart
						linePart := A_LoopField
					}
				}
				fixedWidthStr .= (fixedWidthStr == "" ? SubStr(fixedWidthWord, 2) : fixedWidthWord) . (linePart == "" ? '' : '`n' linePart)
			}
		}
	}
	fixedWidthStr .= (fixedWidthStr ? '`n' : '') fixedWidthLine . substr(str, pos, 1)
	if (!onlyCalculate) {
		textCtrl.Move(,,guiGetTextSize(textCtrl, fixedWidthStr)*)
		textCtrl.Value := fixedWidthStr
	}
	return fixedWidthStr
}

guiGetTextSize(txtCtrlObj, str) {
	static WM_GETFONT := 0x0031
	static DT_CALCRECT := 0x400
	DC := DllCall("GetDC", "Ptr", txtCtrlObj.Hwnd, "Ptr")
	hFont := SendMessage(WM_GETFONT,,, txtCtrlObj)
	hOldObj := DllCall("SelectObject", "Ptr", DC, "Ptr", hFont, "Ptr")
	height := DllCall("DrawText", "Ptr", DC, "Str", str, "Int", -1, "Ptr", rect := Buffer(16, 0), "UInt", DT_CALCRECT)
	width := NumGet(rect, 8, "Int") - NumGet(rect, "Int")
	DllCall("SelectObject", "Ptr", DC, "Ptr", hOldObj, "Ptr")
	DllCall("ReleaseDC", "Ptr", txtCtrlObj.Hwnd, "Ptr", DC)
	return [width, height]
}

scrollbarGetPosition(ctrlHwnd) {
	static SIF_RANGE := 0x01
	static SIF_PAGE := 0x02
	static SIF_POS := 0x04
	static SIF_TRACKPOS := 0x10
	static SIF_ALL := (SIF_RANGE | SIF_PAGE | SIF_POS | SIF_TRACKPOS)
	static SB_HORZ := 0
	static SB_VERT := 1
	static SB_CTL := 2
	static SB_BOTH := 3
	static SB_BOTTOM := 7
	static WM_VSCROLL := 0x115
	
	NumPut("UInt", 28, ScrollInfo := Buffer(28, 0))
	NumPut("UInt", SIF_ALL, ScrollInfo, 4)
	DllCall("GetScrollInfo", "uint", ctrlHwnd, "int", SB_VERT, "Ptr", ScrollInfo)
	nMin := NumGet(ScrollInfo, 8, "int")
	nMax := NumGet(ScrollInfo, 12, "int")
	nPage := NumGet(ScrollInfo, 16, "uint")
	curPos := NumGet(ScrollInfo, 20, "uint")
	return curPos ? curPos / (nMax - nPage + 1 - nMin) : 0
}

structRectCreate(x1, y1, x2, y2) {
	NumPut("UInt", x1, "UInt", y1, "UInt", x2, "UInt", y2, llrectA := Buffer(16, 0), 0)
	return llrectA
}

structRectGet(rect) {
	x1 := NumGet(rect, 0, "int")
	y1 := NumGet(rect, 4, "int")
	x2 := NumGet(rect, 8, "int")
	y2 := NumGet(rect, 12, "int")
	return [x1, y1, x2, y2]
}

class DataListView { ; this is (mostly) based on Pulover's LV_Rows class, ignoring LV_EX. See https://github.com/Pulover/Class_LV_Rows
	
	__New(LV) {
		this.LV := LV
		this.Base := LV ; !!!!!!!!!!!!!!!!!!!!
		this.rowData := {}
		this.headers := []
		return this
	}
	
	Add(Options?, Cols*) => this.LV.Add(options?, cols*)
	Insert(RowNumber , Options?, Cols*)  => this.LV.Insert(RowNumber , Options?, Cols*) 
	Modify(RowNumber, Options?, NewCols*)  => this.LV.Modify(RowNumber, Options?, NewCols*) 
	Delete(RowNumber?) => this.LV.Delete(rowNumber?)
	
	InsertCol(ColumnNumber, Options?, ColumnTitle?)  => this.LV.InsertCol(ColumnNumber, Options?, ColumnTitle?) 
	ModifyCol(ColumnNumber?, Options?, ColumnTitle?)  => this.LV.ModifyCol(ColumnNumber?, Options?, ColumnTitle?) 
	DeleteCol(ColumnNumber) => this.LV.DeleteCol(ColumnNumber)
	
	GetCount(Mode?)  => this.LV.GetCount(Mode?) 
	GetNext(StartingRowNumber?, RowType?)  => this.LV.GetNext(StartingRowNumber?, RowType?) 
	GetText(RowNumber, ColumnNumber?) => this.LV.GetText(RowNumber, ColumnNumber?)
	
	SetImageList(ImageListID, IconType?)  => this.LV.SetImageList(ImageListID, IconType?)

	OnEvent(EventName, Callback, AddRemove?) => (this.LV.OnEvent(EventName, Callback, AddRemove?), this)

	Rows() {
		; enumerator
		index := 1
		return (&n) => (
			; this.rowData ; enumerate this
			index++
			true 
		)
	}

	Copy() {
		return 0
	}

	Cut() {
		return 0
	}

	Paste() {
		return 0
	}

	Duplicate() {
		return 0
	}

	; Delete() {
	; 	return 0
	; }

	MoveUp() {
		return 0
	}

	MoveDown() {
		return 0
	}

	Drag() {
		return 0
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
	if !(whr.ResponseBody)
		return ""
	arr := whr.ResponseBody
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
; 			DllCall("dwmapi\DwmSetWindowAttribute", "ptr", _gui.hwnd, "int", attr, "int*", dark ? true : false, "int", 4)
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

splitRecursive(n, splits := StrLen(n)) {
	if (splits == 1)
		return [[n]]
	else if (StrLen(n) == splits)
		return [StrSplit(n)]
	arr := []
	Loop(StrLen(n) - splits + 1) {
		cur := SubStr(n, 1, A_Index)
		a := splitRecursive(SubStr(n, A_Index + 1), splits - 1)
		for i, e in a
			a[i].insertat(1, cur)
		arr.push(a*)
	}
	return arr
}

strCountStr(HayStack, SearchText, CaseSense := false) {
	StrReplace(HayStack, SearchText,,CaseSense, &count)
	return count
}

roundProper(num, precision := 12) {
	if (!IsNumber(num))
		return num
	if (IsInteger(num) || Round(num) == num)
		return Integer(num)
	else
		return Number(RTrim(Round(num, precision), "0."))
}

print(msg, options?, putNewline := true, compact := false, compress := true, strEscape := true, spacer := "`t") {
	if !(msg is String)
		msg := objToString(msg, compact, compress, strEscape, spacer)
	if (putNewline == true || putNewline == -1 && InStr(msg, '`n'))
		finalChar := '`n'
	else
		finalChar := ''
	try 
		FileAppend(msg . finalChar, "*", options ?? "UTF-8")
	catch Error 
		MsgBoxAsGui(msg,,,,,,,1)
}

/**
 * tiles given or all windows
 * @param windowArray array of window HWNDs to be tiled
 * @param {Integer} tilingMode 0 or 1, vertical or horizontal
 * @param tileArea Area in which windows will be tiled. Given in the form [x1, y1, x2, y2]
 * @param {Integer} hwndParent HWND of parent window of the windows to be tiled
 * @returns {Integer} Count of tiled windows 
 */
tileWindows(windowArray?, tilingMode := 0x0000, tileArea?, hwndParent := 0)  {
	static MDITILE_VERTICAL 	:= 0x0000
	static MDITILE_HORIZONTAL 	:= 0x0001
	static MDITILE_SKIPDISABLED := 0x0002
	static MDITILE_ZORDER 		:= 0x0004
	flagTileArea := IsSet(tileArea)
	if (flagTileArea)
		lpRect := structRectCreate(tileArea*)
	else
		lpRect := 0
	flagCustomWindows := IsSet(windowArray) && windowArray is Array
	if (flagCustomWindows) {
		cKids := windowArray.Length
		lpKids := Buffer(windowArray.Length * 4) ; sizeof(int) == 4
		for i, hwnd in windowArray
			NumPut("Int", hwnd, lpKids, 4 * (i-1))
	}
	else {
		cKids := 0
		lpKids := 0
	}
	return DllCall("TileWindows", 
		"Int", hwndParent, 
		"UInt", tilingMode, 
		"UInt", flagTileArea ? lpRect.Ptr : 0, 
		"Int", cKids, 
		"Int", flagCustomWindows ? lpKids.Ptr : 0
	)
}