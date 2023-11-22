#Requires Autohotkey 2.0

class TrayMenu {

	static __New() {
		this.menus := Map()
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

	static hasSubmenu(Menu, subMenu) {
		h := Menu.Handle

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

arrayContains(array, t) {
	for index, element in array
		if(element = t)
			return index
	return 0
}

keyArrayContains(array, key, value) {
	for i, e in array
		if (e[key] == value)
			return i
	return 0		
}

arrayRemove(&array, t, removeAll := 1) {
	for i, e in array
		if (i != A_Index)
			throw TypeError("This function does not handle key-pair object.")
	toRemove := []
	for index, element in array
	{
		if (element = t) {
			toRemove.push(index)
			if (!removeAll)
				break
		}
	}
	Loop {
		tV := toRemove.pop()
		if (tV == "")
			break
		array.removeAt(tV)
	}
}

reverseArray(array) { ; linear array, gives weird stuff with assoc
	arr := []
	for i, e in array
		arr[array.Count() - i + 1] := e
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

sortKeyArray(keyArr, key, mode := "") {
	arr2 := {}
	arr3 := {}
	l := keyArr.Count()
	for i, el in keyArr
	{
		arr2[el[key] . ""] := i ; IF el[key] OCCURS TWICE, IT OVERWRITES A VALUE (EG count = 1231 for two usernames -> only last one gets taken)
		str .= el[key] . "`n"
	}
	newStr := Sort(str, mode)
	strArr := StrSplit(newStr, "`n")
	strArr.Pop()
	for i, e in strArr
	{
		arr3.push(keyArr[arr2[e . ""]])
	}
	return arr3
}


reverseString(str) {
	result := ""
	Loop Parse, str 
	{
		result := A_LoopField . result 
	}
	return result
}

rotateStr(str, offset:=0) {
	offset := Mod(offset,StrLen(str))
	return SubStr(str, -1*offset+1) . SubStr(str, 1, -1*offset)
}

ReplaceChars(Text, Chars, ReplaceChars) {
	ReplacedText := Text
	Loop Parse, Text
	{
		Index := A_Index
		Char := A_LoopField
		Loop Parse, Chars
		{
			if (A_LoopField = Char) {
				ReplacedText := SubStr(ReplacedText, 1, Index-1) . SubStr(ReplaceChars, A_Index, 1) . SubStr(ReplacedText, Index+1)
				break
			}
		}
	}
	return ReplacedText
}

recursiveReplaceMap(string, &from, to, index := 1) { ; why not map/keyarray? because maps aren't ordered, and this replaces in priority (in fact its impossible to replace properly at all without priority)
	replacedString := ""
	if (index == from.Count())
		return StrReplace(string, from[index], to[index])
	strArr := StrSplit(string, from[index])
	for i, e in strArr
		replacedString .= recursiveReplaceMap(e, &from, to, index + 1) . (i == strArr.Count() ? "" : to[index])
	return replacedString
}

ExecScript(expression, Wait:=true) {
	input := '#Warn All, Off`nFileAppend(' . expression . ', "*")'
    shell := ComObject("WScript.Shell")
    exec := shell.Exec("AutoHotkey.exe /ErrorStdOut *")
    exec.StdIn.Write(input)
    exec.StdIn.Close()
    if Wait
        return exec.StdOut.ReadAll()
}

cmdRet(sCmd, callBackFuncObj := "", encoding := "CP0") {
	; encoding := "CP" . DllCall("GetOEMCP", "UInt") ; CP0 -> Ansi, CP850 Western European Ansi.
	static HANDLE_FLAG_INHERIT := 0x00000001, flags := HANDLE_FLAG_INHERIT
		, STARTF_USESTDHANDLES := 0x100, CREATE_NO_WINDOW := 0x08000000
	hPipeRead := unset,	hPipeWrite := unset
	DllCall("CreatePipe", "PtrP", hPipeRead, "PtrP", hPipeWrite, "Ptr", 0, "UInt", 0)
	DllCall("SetHandleInformation", "Ptr", hPipeWrite, "UInt", flags, "UInt", HANDLE_FLAG_INHERIT)

	STARTUPINFO := Buffer(siSize := A_PtrSize*4 + 4*8 + A_PtrSize*5, 0)
	NumPut("Uint", siSize, STARTUPINFO)
	NumPut(STARTF_USESTDHANDLES, STARTUPINFO, A_PtrSize*4 + 4*7)
	NumPut(hPipeWrite          , STARTUPINFO, A_PtrSize*4 + 4*8 + A_PtrSize*3)
	NumPut(hPipeWrite          , STARTUPINFO, A_PtrSize*4 + 4*8 + A_PtrSize*4)

	PROCESS_INFORMATION := Buffer(A_PtrSize*2 + 4*2, 0)

	if !DllCall("CreateProcess", "Ptr", 0, "Str", sCmd, "Ptr", 0, "Ptr", 0, "UInt", true, "UInt", CREATE_NO_WINDOW
		, "Ptr", 0, "Ptr", 0, "Ptr", &STARTUPINFO, "Ptr", &PROCESS_INFORMATION)	{
		DllCall("CloseHandle", "Ptr", hPipeRead)
		DllCall("CloseHandle", "Ptr", hPipeWrite)
		throw Error("CreateProcess has failed")
	}
	DllCall("CloseHandle", "Ptr", hPipeWrite)
	sTemp := buffer(4096)
	nSize := 0
	while DllCall("ReadFile", "Ptr", hPipeRead, "Ptr", sTemp, "UInt", 4096, "UIntP", nSize, "UInt", 0) {
		; add potential fallback! (via static variable check or something like that.)
		stdOut := StrGet(sTemp, nSize, encoding)
		sOutput .= stdOut
		if (callBackFuncObj)
			callBackFuncObj.call(stdOut)
	}
	DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION,0, "Uint"))
	DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, A_PtrSize, "Uint"))
	DllCall("CloseHandle", "Ptr", hPipeRead)
	return sOutput
}

execShell(command) {
    shell := ComObject("WScript.Shell")
    exec := shell.Exec(A_Comspec " /C " command)
    return exec.StdOut.ReadAll()
}

windowGetCoordinates(windowHWND, detectHidden := false) {
	DetectHiddenWindows(detectHidden)
	minimize_status := WinGetMinMax(windowHWND)
	if (minimize_status != -1) 
		WinGetPos(&x, &y,,, windowHWND)
	else {
		NumPut("Uint", 44, pos := Buffer(44, 0))
		DllCall("GetWindowPlacement", "uint", windowHWND, "uint", pos)
		x := NumGet(pos, 28, "int")
		y := NumGet(pos, 32, "int")
	}
	return [x,y]
}

timedTooltip(text := "", durationMS := 1000, x?, y?, whichTooltip?) {
	ToolTip(text, x?, y?, whichTooltip?)
	SetTimer(stopTooltip, -1 * durationMS)

	stopTooltip() {
		ToolTip(,,,whichTooltip?)
	}
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


doNothing(*) {
	return
}