#NoEnv
#KeyHistory 500
#Persistent
SendMode Input ; // Faster
SetTitleMatchMode, 3 ;// Must Match Exact Title
Thread, NoTimers	;// Any hotkey or menu has priority over timers. So that the custom tray menu doesn't collide with taskbarTransparencyTimer

if !InStr(FileExist("script_files"), "D")
	FileCreateDir, script_files
SetWorkingDir %A_ScriptDir%\everything
#Include %A_ScriptDir%\Libraries\TransparentTaskbar.ahk 
#Include %A_ScriptDir%\Libraries\HotkeyMenu.ahk 
#Include %A_ScriptDir%\Libraries\WindowManager.ahk
#Include %A_ScriptDir%\Libraries\TextEditMenu.ahk
#Include %A_ScriptDir%\Libraries\MacroRecorder.ahk
#Include %A_ScriptDir%\Libraries\TimestampConversion.ahk



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

^5::	; Can convert timestamps and dates
	textTimestampConverter()
return

^+LButton::	; Text Modification Menu
	Menu, textModify, Show
return

; -----------
; Example hotkey and hotstring for the hotkey manager:

^0::	; Shows a message box
MsgBox, % "you pressed Ctrl+K"
return

:*:btw::by the way:


;} ----------------------------------------------------------------------------------------------------
;	EVERYTHING HERE WAS ADDED AFTERWARDS OR MODIFIED AUTOMATICALLY
; ---------------------------------------------------------------------------------------------------- 
