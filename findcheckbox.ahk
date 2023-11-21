#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%/checkboxfiles  ; Ensures a consistent starting directory.


global checkboxX
global checkboxY
global middleX = 971
global middleY = 596
global topcornerX
global topcornerY
global clickCount

#IfWinActive Checkboxes - Mozilla Firefox
^+ü::
Loop {
	ImageSearch, checkboxX, checkboxY, 10, 140, 1910, 1030, checkbox.png
	topcornerX := checkboxX - 69
	topcornerY := checkboxY - 69
	Loop 50 {
		ImageSearch, checkboxX, checkboxY, topcornerX, topcornerY, topcornerX + 150, topcornerY + 150, checkbox.png
		if ErrorLevel
			break
		checkboxX += 5
		checkboxY += 5
		ControlClick, X%checkboxX% Y%checkboxY%, Checkboxes - Mozilla Firefox
		clickCount++
		topcornerX := checkboxX - 75
		topcornerY := checkboxY - 75
		Sleep, 50
	}
}
return
#IfWinActive

^+ä::
MsgBox, Clickcount = %clickCount%
return

^+r::
Reload
return

