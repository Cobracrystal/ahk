#Usehook ; preventing loops for hotkeys that send their own keystrokes
#SingleInstance Force
global keyList := [
	"RButton"
]

for i, key in keyList {
	Hotkey(key, ((*) => checkPrevent(A_ThisHotkey, A_PriorHotkey, A_TimeSincePriorHotkey)))
}
return
; LButton::{
; 	checkPrevent(A_ThisHotkey, A_PriorHotkey, A_TimeSincePriorHotkey)
; }

checkPrevent(hkey, phkey, tSphkey, mode := 1) {
	static preventB := false
	tSphkey := tSphkey ? tSphkey : -1 
	if (tSphkey > 400 && mode == 1) {
		preventB := false
		Send(InStr(hkey, "Button") ? "{" hkey "}" : hkey)
		return
	}
    if (preventB)
		return
	; if keypress is the same as previous keypress and its less than 100ms ago, return
    if (hkey == phkey && tSphkey < 200 && !GetKeyState("Control", "P")) {
		preventB := true
		return
	}
	Send(InStr(hkey, "Button") ? "{" hkey "}" : hkey)
}

; Alt+F10 turns off the s disabling
^F10::{
	for j, k in keyList
		Hotkey(k, "Toggle")
}