; this file exists only to list functions used in windows managers context menu
; all functions should be of the form functionName(windowHandle), and should return true on success, false on failure

vlcMinimalViewingMode(wHandle) {
	if WinGetProcessName(wHandle) != "vlc.exe"
		return 0
	WinActivate(wHandle)
	Sleep(100)
	Send("!a")
	Sleep(100)
	Send("!a")
	Sleep(100)
	Send("m")
	Sleep(100)
	WinSetStyle("-0x40000", wHandle)
	return 1
}