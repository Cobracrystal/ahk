#NoEnv
#KeyHistory 500
#Persistent
SendMode Input ; // Faster
SetTitleMatchMode, 3 ;// Must Match Exact Title
Thread, NoTimers	;// Any hotkey or menu has priority over timers. So that the custom tray menu doesn't collide with taskbarTransparencyTimer

if !InStr(FileExist("everything"), "D") ;// For the Savedhotkeys.txt file being created by the hotkey manager. Also more clean in general.
	FileCreateDir, everything
SetWorkingDir %A_ScriptDir%\everything
#Include %A_ScriptDir%\Script_Functionalities\TransparentTaskbar.ahk 
#Include %A_ScriptDir%\Script_Functionalities\HotkeyMenu.ahk 
#Include %A_ScriptDir%\Script_Functionalities\WindowManager.ahk
#Include %A_ScriptDir%\Script_Functionalities\TextEditMenu.ahk
#Include %A_ScriptDir%\Script_Functionalities\MacroRecorder.ahk


; These are available settings aka global variables to avoid editing the library files. Set to the default.

;//Window Manager
windowManagerGuiPosX := 200
windowManagerGuiPosY := 200
;//Hotkey Manager
hotkeyManagerGuiPosX := 530
hotkeyManagerGuiPosY := 35		
;//Taskbar Transparency
accent_color = 0xD0473739 		; This is literally just gray
passive_mode := 2	
;// global variable to set a timer with a function easily
taskBarTimer := Func("updateTaskbarFunction")			

updateTaskbarFunction(0, 1)
SetTimer, %taskBarTimer%, 200

return
; ---- END OF AUTOEXECUTE SECION

^1:: ; Toggle Hotkey Manager
if !WinExist("ahk_id" hotkeyManagerGuiHwnd)
	createHotkeyManagerGui(hotkeyManagerGuiPosX, hotkeyManagerGuiPosY)
else
	HotkeyManagerGuiClose(hotkeyManagerGuiHwnd)
return

^2:: ; Shows a list of all Windows in the Window Manager
if !WinExist("ahk_id" windowManagerGuiHwnd) 
	createWindowManagerGui(windowManagerGuiPosX, windowManagerGuiPosY)
else
	WindowManagerGuiClose(windowManagerGuiHwnd)
return

^3::	; Record Macro
	createMacro(A_ThisHotkey)
return

^4:: ; Toggle Taskbar Transparency Timer
if (TranspToggle := !TranspToggle) {
	SetTimer, %taskBarTimer%, Off
	updateTaskbarFunction(1) ; // 1 -> resets taskbar to normal
}
else
	SetTimer, %taskBarTimer%, 200
return


^+LButton::	; Text Modification Menu
	Menu, textModify, Show
return

; -----------
; Example hotkey and hotstring for the hotkey manager:

^5::	; Shows a message box
MsgBox, % "you pressed Ctrl+K"
return

:*:btw::by the way:


;} ----------------------------------------------------------------------------------------------------
;	EVERYTHING HERE WAS ADDED AFTERWARDS OR MODIFIED AUTOMATICALLY
; ---------------------------------------------------------------------------------------------------- 
