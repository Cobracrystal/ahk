#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
#Usehook ; preventing loops for hotkeys that send their own keystrokes


s::
    ; if keypress is the same as previous keypress and its less than 100ms ago, return
    if (A_ThisHotkey == A_PriorHotkey && A_TimeSincePriorHotkey < 200) 
	    return
	; else, send s
	else
		SendInput s
return

^F10:: ; Alt+F10 turns off the s disabling
Hotkey, s, Toggle
return