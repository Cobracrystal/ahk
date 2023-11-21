#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#persistent
hkk := "a^!+k"
t := "20220228133700" ; 28.2.22 1337
msgbox % ldom(t)
return

Gui, uwu:new
Gui, uwu:show, w500 h500 center
return

uwuGuiClose() {	;// Close GUI
	MsgBox, 1, Delete macro?, % "Close GUI and delete recording?"
	IfMsgBox OK
		Gui, uwu:Destroy
	else 
		return true
}

LDOM(DateStr) { ; get the last day of the month - by Laszlo / SKAN
   DateStr := SubStr(DateStr, 1, 6) ; get the YYYYMM part
   DateStr += 31, Days ; jump into the next month
   DateStr := SubStr(DateStr, 1, 6) ; get the YYYYMM part
   DateStr += -1, Days ; jump to the last day of the previous month
   return SubStr(DateStr, 7, 2) ; return the DD part
}

test(hkey) {
	errorExplain := "Error Code :	Description`n0		Hotkey already exists within the script`n2		Key Name is not recognized or unsupported`n3		Unsupported Prefix key.`n98		Limit of hotkeys is reached. (32762)`n99		Ran out of memory."
	Hotkey, % hkey,, UseErrorLevel
	if (ErrorLevel == 5 || ErrorLevel == 6) {
		Hotkey, % hkey, s, UseErrorLevel
		if (ErrorLevel) {
			MsgBox, 0, % "Problem while adding", % "Error encountered in (Hotkey): Error Code " . ErrorLevel . "`n`n" . errorExplain
			return
		}
		Hotkey, % hkey, Off
	}
	else {	
		MsgBox, 0, % "Problem while adding", % "Error encountered in (Hotkey): Error Code " . ErrorLevel . "`n`n" . errorExplain
		return
	}
}

s(hkk := "") {
	Hotkey, % hkk,, UseErrorLevel
	msgbox % ErrorLevel
	if !ErrorLevel
		Hotkey, % hkk,,On
}


#IfWinActive ahk_exe notepad.exe
^!+k::
msgbox % A_ThisHotkey
return
#IfWinActive

!p::
s(hkk)
return


^+R::
reload
return