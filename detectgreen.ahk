#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


return

j::
MouseGetPos, xx, yy
if (toggle := !toggle)
	SetTimer, detectGreen, 1
else
	SetTimer, detectGreen, Off
return



detectGreen:
	PixelGetColor, c, xx, yy
	if (c = "0x569928")
		Click
return