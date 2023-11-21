fastCopy() {
	ClipboardOld := ClipboardAll
	Clipboard := "" 
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
	ClipWait 1
	if ErrorLevel {
		Clipboard := ClipboardOld
		return
	}
	Send ^v
	Sleep, 50
	Clipboard := ClipboardOld
}

arrayContains(array, t) {
	for index, element in array
		if(element = t)
			return A_Index
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

ExecScript(expression, Wait:=true) {
	input := "FileAppend % (" . expression . "), *"
    shell := ComObjCreate("WScript.Shell")
    exec := shell.Exec("AutoHotkey.exe /ErrorStdOut *")
    exec.StdIn.Write(input)
    exec.StdIn.Close()
    if Wait
        return exec.StdOut.ReadAll()
}

readFileIntoVar(path, encoding := "UTF-8") {
		dataFile := FileOpen(path, "r", encoding)
		return dataFile.Read()
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

doNothing() {
	return
}