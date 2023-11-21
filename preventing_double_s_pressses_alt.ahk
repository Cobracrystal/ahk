#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
#Usehook ; preventing loops for hotkeys that send their own keystrokes

preventB := false

s::
    if (A_TimeSincePriorHotkey > 400) {
		preventB := false
		SendInput s
		return
	}
    if (preventB)
		return
	; if keypress is the same as previous keypress and its less than 100ms ago, return
    if (A_ThisHotkey == A_PriorHotkey && A_TimeSincePriorHotkey < 200) {
		preventB := true
		return
	}
	SendInput s
return

^F10:: ; Alt+F10 turns off the s disabling
Hotkey, s, Toggle
return