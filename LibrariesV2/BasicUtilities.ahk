; https://github.com/cobracrystal/ahk

#Requires Autohotkey 2.0

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
}

objRemoveValues(obj, removeAll := 1, values*) {
	if !(obj is Array || obj is Map)
		throw Error("objContains does not handle type " . obj.base.__Class)
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
}

reverseArray(array) { ; linear array, gives weird stuff with assoc
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

sortMap(map, key, mode := "") {
	arr2 := Map()
	arr3 := []
	l := map.Count()
	for i, e in map
	{
		arr2[e[key]] := i ; IF el[key] OCCURS TWICE, IT OVERWRITES A VALUE (EG count = 1231 for two usernames -> only last one gets taken)
		str .= e[key] . "`n"
	}
	newStr := Sort(str, mode)
	strArr := StrSplit(newStr, "`n")
	strArr.Pop()
	for i, e in strArr
		arr3.push(map[arr2[e]])
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

; @from array containing strings that are to be replaced in decreasing priority order
; @to array containing strings that are the replacements for values in @from, in same order
recursiveReplaceMap(string, &from, to, index := 1) {
	replacedString := ""
	if (index == from.Count)
		return StrReplace(string, from[index], to[index])
	strArr := StrSplit(string, from[index])
	for i, e in strArr
		replacedString .= recursiveReplaceMap(e, &from, to, index + 1) . (i == strArr.Count ? "" : to[index])
	return replacedString
}

/*
* Extended version of DateAdd, allowing Weeks (W), Months (MO), Years (Y) for timeUnit. Returns YYYYMMDDHH24MISS timestamp
* @param periodUnit Time Unit can be one of the strings (or their first letter): Years, Weeks, Days, Hours, Minutes, Seconds NOT months because that's bad
* Remark: Adding years to a leap day will result in the corresponding day number of the resulting year (29-02-2024 + 1 Year -> 30-01-2025)
* Similarly, if a resulting month does not have as many days as the starting one, the result will be rolled over (31-10-2024 + 1 Month -> 01-12-2024)
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
* Given a set of time parts, returns a YYYYMMDDHH24MISS timestamp of the earlist possible time in the future when all given parts match
* If given time units with a gap, it will assume default values for units between (given month = 10, hours = 16, it will find the next instance of YEAR-10-01-16-00-00).
* Breaks if given >30 days or a leap date
*/
parseTime(years?, months?, days?, hours?, minutes?, seconds?) {
	Now := A_Now
	data := gap(years?, months?, days?, hours?, minutes?, seconds?)
	switch data[1] {
		case 0:
			return Now
		case 1:
			if (years == A_YYYY && data[2])
				return parseTime(, months?, days?, hours?, minutes?, seconds?)
			tStamp := (years ?? A_YYYY) tf(months ?? 1) tf(days ?? 1) tf(hours ?? 0) tf(minutes ?? 0) tf(seconds ?? 0)
			if (!IsTime(tStamp)) {
				if (!IsSet(years) && IsSet(months) && months == 2 && IsSet(days) && days == 29) ; correct leap year
					tStamp := (A_YYYY + 4 - Mod(A_YYYY, 4)) . SubStr(tStamp, 5)
				else if (!IsSet(months) && days > 29) ; correct possible month error. no need for mod, since dec has 31 days
					tStamp := SubStr(tStamp 1, 4) . tf(A_MM+1) . SubStr(tStamp, 7)
				if (!IsTime(tStamp))
					throw Error("Invalid date specified.")
			}
			if (DateDiff(tStamp, Now, "S") > 0)
				return tStamp
			return 0 ; a year in the past will never occur again
		case 2:
			if (months == A_MM && data[2])
				return parseTime(,,days?,hours?, minutes?, seconds?)
			tStamp := A_YYYY tf(months) tf(days ?? 1) tf(hours ?? 0) tf(minutes ?? 0) tf(seconds ?? 0)
			if (!IsTime(tStamp)) {
				if (months == 2 && IsSet(days) && days == 29) ; leap year
					tStamp := (A_YYYY + 4 - Mod(A_YYYY, 4)) . SubStr(tStamp, 5)
				if (!IsTime(tStamp))
					throw Error("Invalid date specified.")
			}
			if (DateDiff(tStamp, Now, "S") >= 0)
				return tStamp
			return DateAddW(tStamp, 1, "Y")
		case 3:
			if (days == A_DD && data[2])
				return parseTime(,,,hours?, minutes?, seconds?)
			tStamp := SubStr(Now, 1, 6) tf(days) tf(hours ?? 0) tf(minutes ?? 0) tf(seconds ?? 0)
			if (!IsTime(tStamp)) {
				if (A_MM == 02 && days == 29) ; leap year
					tStamp := (A_YYYY + 4 - Mod(A_YYYY, 4)) . SubStr(tStamp, 5)
				else if (days > 29) ; correct possible month error. no need for mod, since dec has 31 days
					tStamp := SubStr(tStamp 1, 4) . tf(A_MM+1) . SubStr(tStamp, 7)
				if (!IsTime(tStamp))
					throw Error("Invalid date specified.")
			}
			if (DateDiff(tStamp, Now, "S") >= 0)
				return tStamp
			return DateAddW(tStamp, 1, "Mo")
		case 4:
			if (hours == A_Hour && data[2])
				return parseTime(,,,,,seconds?)
			tStamp := SubStr(Now, 1, 8) tf(hours) tf(minutes ?? 0) tf(seconds ?? 0)
			if (DateDiff(tStamp, Now, "S") >= 0)
				return tStamp
			return DateAddW(tStamp, 1, "D")
		case 5:
			if (minutes == A_Min && !IsSet(seconds))
				return Now
			tStamp := SubStr(Now, 1, 10) . tf(minutes) . tf(seconds ?? 0)
			if (DateDiff(tStamp, Now, "S") >= 0)
				return tStamp
			return DateAddW(tStamp, 1, "H")
		case 6:
			tStamp := SubStr(Now, 1, 12) . tf(seconds)
			if (DateDiff(tStamp, Now, "S") >= 0)
				return SubStr(Now, 1, 12) . tf(seconds)
			return DateAddW(SubStr(Now, 1, 12) . tf(seconds), 1, "M")
	}
	tf(n) => Format("{:02}", n)

	gap(y?, mo?, d?, h?, m?, s?) {
		mapA := Map(1, y?, 2, mo?, 3, d?, 4, h?, 5, m?, 6, s?),	first := 0
		for i, e in mapA {
			if (A_Index == 1)
				first := i
			if (first+A_Index-1 != i)
				return [first, true]
		}
		return [first, false]
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
	DetectHiddenWindows(1)
	minimize_status := WinGetMinMax(wHandle)
	if (minimize_status != -1)
		WinGetPos(&x, &y, , , wHandle)
	else {
		NumPut("Uint", 44, pos := Buffer(44, 0))
		DllCall("GetWindowPlacement", "uint", wHandle, "uint", pos)
		x := NumGet(pos, 28, "int")
		y := NumGet(pos, 32, "int")
	}
	return [x, y]
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

normalizePath(path) {	; ONLY ABSOLUTE PATHS
	path := StrReplace(path, "/", "\")
	path := StrReplace(path, "\\", "\")
	if (!RegexMatch(path, "i)^[a-z]:\\") || RegexMatch(path, "i)^[a-z]:\\\.\."))
		return ""
	Loop {
		path := RegexReplace(path, "\\(?!\.\.\\)[^\\]+?\\\.\.\\", "\", &rCount)
		if (rCount == 0)
			break
	}
	if (InStr(path, "\..\"))
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

