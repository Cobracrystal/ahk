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

arrayContains(array, t) {
	for index, element in array
		if (element = t)
			return index
	return 0
}

mapContains(array, key, value) {
	for i, e in array
		if (e[key] == value)
			return i
	return 0
}

arrayRemove(&array, t, removeAll := 1) {
	for i, e in array
		if (i != A_Index)
			throw TypeError("This function does not handle objects/Maps.")
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

ExecScript(expression, Wait := true) {
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
	hPipeRead := unset, hPipeWrite := unset
	DllCall("CreatePipe", "PtrP", hPipeRead, "PtrP", hPipeWrite, "Ptr", 0, "UInt", 0)
	DllCall("SetHandleInformation", "Ptr", hPipeWrite, "UInt", flags, "UInt", HANDLE_FLAG_INHERIT)

	STARTUPINFO := Buffer(siSize := A_PtrSize * 4 + 4 * 8 + A_PtrSize * 5, 0)
	NumPut("Uint", siSize, STARTUPINFO)
	NumPut(STARTF_USESTDHANDLES, STARTUPINFO, A_PtrSize * 4 + 4 * 7)
	NumPut(hPipeWrite, STARTUPINFO, A_PtrSize * 4 + 4 * 8 + A_PtrSize * 3)
	NumPut(hPipeWrite, STARTUPINFO, A_PtrSize * 4 + 4 * 8 + A_PtrSize * 4)

	PROCESS_INFORMATION := Buffer(A_PtrSize * 2 + 4 * 2, 0)

	if !DllCall("CreateProcess", "Ptr", 0, "Str", sCmd, "Ptr", 0, "Ptr", 0, "UInt", true, "UInt", CREATE_NO_WINDOW
		, "Ptr", 0, "Ptr", 0, "Ptr", &STARTUPINFO, "Ptr", &PROCESS_INFORMATION) {
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
	DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, 0, "Uint"))
	DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, A_PtrSize, "Uint"))
	DllCall("CloseHandle", "Ptr", hPipeRead)
	return sOutput
}

execShell(command) {
	shell := ComObject("WScript.Shell")
	exec := shell.Exec(A_Comspec " /C " command)
	return exec.StdOut.ReadAll()
}

selectFolderEx(startingFolder := "", Prompt := "", OwnerHwnd := 0, OkBtnLabel := "") {
	static osVersion := DllCall("GetVersion", "UChar")
	static IID_IShellItem := Buffer(16, 0)
		, Show := A_PtrSize * 3
		, SetOptions := A_PtrSize * 9
		, SetFolder := A_PtrSize * 12
		, SetTitle := A_PtrSize * 17
		, SetOkButtonLabel := A_PtrSize * 18
		, GetResult := A_PtrSize * 20
	DllCall("Ole32.dll\IIDFromString", "WStr", "{43826d1e-e718-42ee-bc55-a1e261c37bfe}", "Ptr", IID_IShellItem)
	selectedFolder := "", folderItem := 0, shellItem := 0, StrPtrVar := 0
	OwnerHwnd := DllCall("IsWindow", "Ptr", OwnerHwnd, "UInt") ? OwnerHwnd : 0
	if !(FileDialog := ComObject("{DC1C5A9C-E88A-4dde-A5A1-60F82A20AEF7}", "{42f85136-db7e-439c-85f1-e4075d135fc8}"))
		Return ""
	VTBL := NumGet(FileDialog.ptr, "UPtr")
	; FOS_CREATEPROMPT | FOS_NOCHANGEDIR | FOS_PICKFOLDERS
	DllCall(NumGet(VTBL + SetOptions, "UPtr"), "Ptr", FileDialog, "UInt", 0x00002028, "UInt")
	if (startingFolder != "")
		if !DllCall("Shell32.dll\SHCreateItemFromParsingName", "WStr", startingFolder, "Ptr", 0, "Ptr", IID_IShellItem, "PtrP", &folderItem)
			DllCall(NumGet(VTBL + SetFolder, "UPtr"), "Ptr", FileDialog, "Ptr", folderItem, "UInt")
	if (Prompt != "")
		DllCall(NumGet(VTBL + SetTitle, "UPtr"), "Ptr", FileDialog, "WStr", Prompt, "UInt")
	if (OkBtnLabel != "")
		DllCall(NumGet(VTBL + SetOkButtonLabel, "UPtr"), "Ptr", FileDialog, "WStr", OkBtnLabel, "UInt")
	if !DllCall(NumGet(VTBL + Show, "UPtr"), "Ptr", FileDialog, "Ptr", OwnerHwnd, "UInt") {
		if !DllCall(NumGet(VTBL + GetResult, "UPtr"), "Ptr", FileDialog, "PtrP", &ShellItem, "UInt") {
			GetDisplayName := NumGet(NumGet(ShellItem + 0, "UPtr"), A_PtrSize * 5, "UPtr")
			if !DllCall(GetDisplayName, "Ptr", ShellItem, "UInt", 0x80028000, "PtrP", &StrPtrVar) ; SIGDN_DESKTOPABSOLUTEPARSING
				selectedFolder := StrGet(StrPtrVar, "UTF-16"), DllCall("Ole32.dll\CoTaskMemFree", "Ptr", StrPtrVar)
		;	ObjRelease(shellItem)
		}
	}
;	if (folderItem)
;	   ObjRelease(folderItem)
;	ObjRelease(FileDialog.Ptr)
	return selectedFolder
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

tryEditTextFile(path := A_ScriptFullPath) {
	try
		Run('Notepad++ "' . path '"')
	catch Error {
		try
			Run(A_ProgramFiles . '\Notepad++\notepad++.exe "' . path '"')
		catch Error
			Run(A_WinDir . '\system32\notepad.exe "' . path '"')
	}
}


doNothing(*) {
	return
}