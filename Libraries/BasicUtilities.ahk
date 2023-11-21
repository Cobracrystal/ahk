fastCopy() {
	ClipboardOld := ClipboardAll
	Clipboard := "" 
	Send ^c
	ClipWait 0.5
	if ErrorLevel 
		return
	text := Clipboard
	Clipboard := ClipboardOld
	return text
}

arrayContains(array, searchfor) {
	for Index, Element in array {
		if(Element = searchfor) {
			return 1
			break
		}
	}
	return 0
}

fastPrint(text) {
	ClipboardOld := ClipboardAll
	Clipboard := ""
	Clipboard := text
	ClipWait 1
	if ErrorLevel
		return
	Send ^v
	Sleep, 50
	Clipboard := ClipboardOld
}

doNothing() {
	return
}