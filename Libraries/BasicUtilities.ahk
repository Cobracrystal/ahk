fastCopy() {
	ClipboardOld := ClipboardAll
	Clipboard := "" ; free clipboard so that ClipWait is more reliable
	Send ^c
	ClipWait 1
	if ErrorLevel {
		Clipboard := ClipboardOld
		return
	}
	text := Clipboard
	Clipboard := ClipboardOld
	return text
}

fastPrint(text) {
	ClipboardOld := ClipboardAll
	Clipboard := ""
	Clipboard := text
	ClipWait 1 ; in the event of "text" being very large, prevent script from sending before windows has fully registered it
	if ErrorLevel {
		Clipboard := ClipboardOld
		return 0
	}
	SendEvent ^v
	Sleep, 150
	Clipboard := ClipboardOld
	VarSetCapacity(ClipboardOld, 0)
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

arrayRemove(ByRef array, t, removeAll := 1) {
	for i, e in array
		if (i != A_Index)
			throw Exception("This function does not handle key-pair object.")
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
	arr2 := {}
	for i, e in arr
		str .= e . "`n"
	Sort, str, % mode
	Loop, Parse, str, `n
		(A_LoopField == "" ? continue : arr2.push(A_Loopfield))
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
	Sort, str, % mode
	strArr := StrSplit(str, "`n")
	strArr.Pop()
	for i, e in strArr
	{
		arr3.push(keyArr[arr2[e . ""]])
	}
	return arr3
}


reverseString(text) {
	result := ""
	Loop, Parse, text 
	{
		result := A_LoopField . result 
	}
	return result
}

ReplaceChars(Text, Chars, ReplaceChars) {
	ReplacedText := Text
	Loop, parse, Text, 
	{
		Index := A_Index
		Char := A_LoopField
		Loop, parse, Chars,
		{
			if (A_LoopField = Char) {
				ReplacedText := SubStr(ReplacedText, 1, Index-1) . SubStr(ReplaceChars, A_Index, 1) . SubStr(ReplacedText, Index+1)
				break
			}
		}
	}
	return ReplacedText
}

recursiveReplaceMap(string, ByRef from, to, index := 1) { ; why not map/keyarray? because maps aren't ordered, and this replaces in priority (in fact its impossible to replace properly at all without priority)
	replacedString := ""
	if (index == from.Count())
		return StrReplace(string, from[index], to[index])
	strArr := StrSplit(string, from[index])
	for i, e in strArr
		replacedString .= recursiveReplaceMap(e, from, to, index + 1) . (i == strArr.Count() ? "" : to[index])
	return replacedString
}

ExecScript(expression, Wait:=true) {
	input := "FileAppend % (" . expression . "), *"
    shell := ComObjCreate("WScript.Shell")
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

	DllCall("CreatePipe", "PtrP", hPipeRead, "PtrP", hPipeWrite, "Ptr", 0, "UInt", 0)
	DllCall("SetHandleInformation", "Ptr", hPipeWrite, "UInt", flags, "UInt", HANDLE_FLAG_INHERIT)

	VarSetCapacity(STARTUPINFO , siSize :=    A_PtrSize*4 + 4*8 + A_PtrSize*5, 0)
	NumPut(siSize              , STARTUPINFO)
	NumPut(STARTF_USESTDHANDLES, STARTUPINFO, A_PtrSize*4 + 4*7)
	NumPut(hPipeWrite          , STARTUPINFO, A_PtrSize*4 + 4*8 + A_PtrSize*3)
	NumPut(hPipeWrite          , STARTUPINFO, A_PtrSize*4 + 4*8 + A_PtrSize*4)

	VarSetCapacity(PROCESS_INFORMATION, A_PtrSize*2 + 4*2, 0)

	if !DllCall("CreateProcess", "Ptr", 0, "Str", sCmd, "Ptr", 0, "Ptr", 0, "UInt", true, "UInt", CREATE_NO_WINDOW
		, "Ptr", 0, "Ptr", 0, "Ptr", &STARTUPINFO, "Ptr", &PROCESS_INFORMATION)	{
		DllCall("CloseHandle", "Ptr", hPipeRead)
		DllCall("CloseHandle", "Ptr", hPipeWrite)
		throw Exception("CreateProcess has failed")
	}
	DllCall("CloseHandle", "Ptr", hPipeWrite)
	VarSetCapacity(sTemp, 4096), nSize := 0
	while DllCall("ReadFile", "Ptr", hPipeRead, "Ptr", &sTemp, "UInt", 4096, "UIntP", nSize, "UInt", 0) {
		; add potential fallback! (via static variable check or something like that.)
		stdOut := StrGet(&sTemp, nSize, encoding)
		sOutput .= stdOut
		if (callBackFuncObj)
			callBackFuncObj.call(stdOut)
	}
	DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION))
	DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, A_PtrSize))
	DllCall("CloseHandle", "Ptr", hPipeRead)
	return sOutput
}

execShell(command) {
    shell := ComObjCreate("WScript.Shell")
    exec := shell.Exec(ComSpec " /C " command)
    return exec.StdOut.ReadAll()
}

readFileIntoVar(path, encoding := "UTF-8") {
	dataFile := FileOpen(path, "r", encoding)
	return dataFile.Read()
}

SelectFolderEx(StartingFolder := "", Prompt := "", OwnerHwnd := 0, OkBtnLabel := "") {
   Static OsVersion := DllCall("GetVersion", "UChar")
        , IID_IShellItem := 0
        , InitIID := VarSetCapacity(IID_IShellItem, 16, 0)
                  & DllCall("Ole32.dll\IIDFromString", "WStr", "{43826d1e-e718-42ee-bc55-a1e261c37bfe}", "Ptr", &IID_IShellItem)
        , Show := A_PtrSize * 3
        , SetOptions := A_PtrSize * 9
        , SetFolder := A_PtrSize * 12
        , SetTitle := A_PtrSize * 17
        , SetOkButtonLabel := A_PtrSize * 18
        , GetResult := A_PtrSize * 20
   SelectedFolder := ""
   If (OsVersion < 6) { ; IFileDialog requires Win Vista+, so revert to FileSelectFolder
      FileSelectFolder, SelectedFolder, *%StartingFolder%, 3, %Prompt%
      Return SelectedFolder
   }
   OwnerHwnd := DllCall("IsWindow", "Ptr", OwnerHwnd, "UInt") ? OwnerHwnd : 0
   If !(FileDialog := ComObjCreate("{DC1C5A9C-E88A-4dde-A5A1-60F82A20AEF7}", "{42f85136-db7e-439c-85f1-e4075d135fc8}"))
      Return ""
   VTBL := NumGet(FileDialog + 0, "UPtr")
   ; FOS_CREATEPROMPT | FOS_NOCHANGEDIR | FOS_PICKFOLDERS
   DllCall(NumGet(VTBL + SetOptions, "UPtr"), "Ptr", FileDialog, "UInt", 0x00002028, "UInt")
   If (StartingFolder <> "")
      If !DllCall("Shell32.dll\SHCreateItemFromParsingName", "WStr", StartingFolder, "Ptr", 0, "Ptr", &IID_IShellItem, "PtrP", FolderItem)
         DllCall(NumGet(VTBL + SetFolder, "UPtr"), "Ptr", FileDialog, "Ptr", FolderItem, "UInt")
   If (Prompt <> "")
      DllCall(NumGet(VTBL + SetTitle, "UPtr"), "Ptr", FileDialog, "WStr", Prompt, "UInt")
   If (OkBtnLabel <> "")
      DllCall(NumGet(VTBL + SetOkButtonLabel, "UPtr"), "Ptr", FileDialog, "WStr", OkBtnLabel, "UInt")
   If !DllCall(NumGet(VTBL + Show, "UPtr"), "Ptr", FileDialog, "Ptr", OwnerHwnd, "UInt") {
      If !DllCall(NumGet(VTBL + GetResult, "UPtr"), "Ptr", FileDialog, "PtrP", ShellItem, "UInt") {
         GetDisplayName := NumGet(NumGet(ShellItem + 0, "UPtr"), A_PtrSize * 5, "UPtr")
         If !DllCall(GetDisplayName, "Ptr", ShellItem, "UInt", 0x80028000, "PtrP", StrPtr) ; SIGDN_DESKTOPABSOLUTEPARSING
            SelectedFolder := StrGet(StrPtr, "UTF-16"), DllCall("Ole32.dll\CoTaskMemFree", "Ptr", StrPtr)
         ObjRelease(ShellItem)
   }  }
   If (FolderItem)
      ObjRelease(FolderItem)
   ObjRelease(FileDialog)
   return SelectedFolder
}

windowGetCoordinates(windowHWND) {
	WinGet, minimize_status, MinMax, ahk_id %windowHWND%
	if (minimize_status != -1) 
		WinGetPos, x, y,,, ahk_id %windowHWND%
	else {
		VarSetCapacity(pos, 44, 0)
		NumPut(44, pos)
		DllCall("GetWindowPlacement", "uint", windowHWND, "uint", &pos)
		x := NumGet(pos, 28, "int")
		y := NumGet(pos, 32, "int")
	}
	return [x,y]
}

timedTooltip(text := "", durationMS := 1000, x := "", y := "", whichTooltip := 1) {
	if (durationMS == -1 || !durationMS)
		Tooltip
	else {
		Tooltip, % text, % x, % y, % whichTooltip
		fn := Func("timedTooltip").Bind(,-1,,,whichTooltip)
		SetTimer, % fn, % "-" . durationMS
	}
}

normalizePath(path) {	; ONLY ABSOLUTE PATHS
	path := StrReplace(path, "/", "\")
	path := StrReplace(path, "\\", "\")
	if (!RegexMatch(path, "i)^[a-z]:\\") || RegexMatch(path, "i)^[a-z]:\\\.\."))
		return ""
	Loop {
		path := RegexReplace(path, "\\(?!\.\.\\)[^\\]+?\\\.\.\\", "\", rCount)
		if (rCount == 0)
			break
	}
	if (InStr(path, "\..\"))
		return ""
	return path
}

formatTimeFunc(timestamp := "", formatString := "") {
	FormatTime, outputvar, % timestamp, % formatString
	return outputvar
}

sortFunc(varS, formatString := "") {
	Sort, varS, % formatString
	return varS
}

doNothing() {
	return
}

