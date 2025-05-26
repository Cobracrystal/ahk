#Requires AutoHotkey >=v2.0
#SingleInstance Force
Persistent()
GroupAdd("lockWindows", "Rounds ahk_exe Rounds.exe")
GroupAdd("lockWindows", "ROUNDS ahk_exe ROUNDS.exe")
GroupAdd("lockWindows", "Brawlhalla ahk_exe Brawlhalla.exe")
TraySetIcon("HICON: " Base64toHICON(getBase64PNG()), , true)
HotIfWinActive("ahk_group lockWindows")
Hotkey("$~Alt", (*) => clipCursor(false))
Hotkey("$Alt Up", (*) => clipCursor(true, "ahk_group lockWindows"))
Hotkey("!LButton", (*) => clickWhileAlted())
HotIfWinActive()
DllCall("RegisterShellHookWindow", "Ptr", A_ScriptHwnd) 
msgnum := DllCall("RegisterWindowMessage", "Str", "SHELLHOOK") 
OnMessage(msgnum, ShellMessage)
if (WinExist("ahk_exe r5apex.exe") || WinExist("ahk_exe r5apex_dx12.exe"))
	ExitApp()

while true {
	hwnd := WinWaitActive("ahk_group lockWindows")
	clipCursor(true, hwnd)
	WinWaitNotActive(hwnd)
	clipCursor(false)
}

ShellMessage(wParam, lParam, msg, hwnd) {
	static HSHELL_WINDOWCREATED := 0x1
	static HSHELL_WINDOWACTIVATED := 0x4
	static HSHELL_RUDEAPPACTIVATED := 0x8004
	try 
		if (wParam == HSHELL_WINDOWCREATED || wParam == HSHELL_WINDOWACTIVATED || wParam == HSHELL_RUDEAPPACTIVATED)
			if ((pname := WinGetProcessName(lParam)) == "r5apex.exe" || pname == "r5apex_dx12.exe")
				ExitApp()
}

clickWhileAlted() {
	MouseGetPos(,,&hoverwin)
	WinActivate(hoverwin)
}

clipCursor(mode := true, window := "A") {
	if (!mode) {
		TraySetIcon("HICON: " Base64toHICON(getBase64PNG()), , true)
		return !DllCall("ClipCursor", "Ptr", 0)
	}
	TraySetIcon("HICON: " Base64toHICON(getBase64PNG2()), , true)
	WinGetClientPos(&wx, &wy, &ww, &wh, WinExist(window))
	NumPut("UInt", wx, "UInt", wy, "UInt", wx + ww, "UInt", wy + wh, llrectA := Buffer(16, 0), 0)
	return DllCall("ClipCursor", "Ptr", llrectA)
}

*Capslock:: {
	Send("{Capslock down}")
	KeyWait("Capslock", "P")
	SetCapslockState(0)
	Send("{Capslock up}")
}

*Numlock:: {
	Send("{Numlock down}")
	KeyWait("Numlock", "P")
	SetNumlockState(1)
	Send("{Numlock up}")
}

Base64toHICON(Base64PNG, height := 16) {
    nBytes := StrLen(RTrim(Base64PNG, '='))*3//4
    if DllCall('Crypt32\CryptStringToBinary', 'Str', Base64PNG, 'UInt', StrLen(Base64PNG), 'UInt', 1, 'Ptr', buf := Buffer(nBytes, 0), 'UIntP', &nBytes, 'Ptr', 0, 'Ptr', 0)
        return DllCall('CreateIconFromResourceEx', 'Ptr', buf, 'UInt', nBytes, 'UInt', true, 'UInt', 0x30000, 'Int', height, 'Int', height, 'UInt', 0)
    return 0
}

getBase64PNG() {
	static base64PNG := '
	(
		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
	)'
	return base64PNG
}

getBase64PNG2() {
	static base64PNG := '
	(
		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
	)'
	return base64PNG
}