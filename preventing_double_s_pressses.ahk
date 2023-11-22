#Usehook ; preventing loops for hotkeys that send their own keystrokes

s::
checkPrevent(A_ThisHotkey, A_PriorHotkey, A_TimeSincePriorHotkey)
return

checkPrevent(hkey, phkey, tSphkey, mode := 1) {
	static preventB := false
	if (tSphkey > 400 && mode == 1) {
		preventB := false
		SendInput s
		return
	}
    if (preventB)
		return
	; if keypress is the same as previous keypress and its less than 100ms ago, return
    if (hkey == phkey && tSphkey < 200) {
		preventB := true
		return
	}
	SendInput % hkey
}

^F10:: ; Alt+F10 turns off the s disabling
Hotkey, s, Toggle
return