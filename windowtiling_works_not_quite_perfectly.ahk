#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


create_windows_gui() {
	Gui, windows:New, +Border +ReSize
	Gui, windows:Add, Text,,
	Gui, windows:Add, ListView, R20 w1000, ahk_id|ahk_title|mmx|xpos|ypos|width|height
	for Index, Element in get_window_info(windows)
		LV_Add("",Element.ahk_id, Element.ahk_title, Element.win_state, Element.xpos, Element.ypos, Element.width, Element.height)
	LV_ModifyCol()
	Gui, windows:Show, x200y200 Autosize, windoof
}

get_window_info(ByRef windows) {
	SetTitleMatchMode, RegEx
	WinGet, id, List,,, (Program Manager|ZPToolBarParentWnd|NVIDIA GeForce Overlay|Microsoft Text Input Application)
	windows := {}
	Loop, %id%
	{
		this_id := id%A_Index%
		WinGetPos, xpos, ypos, width, height, ahk_id %this_id%
		WinGetTitle, this_title, ahk_id %this_id%
		WinGet, mmx, MinMax, ahk_id %this_id%
		if (this_title != "" && mmx != -1)
			windows.push({"ahk_id":this_id, "ahk_title":this_title, "win_state":mmx, "xpos":xpos, "ypos":ypos, "width":width, "height":height})
	}
	SetTitleMatchMode, 3
	return windows
}


^9:: ; Show le GUI
if(ShowWindows := !ShowWindows) 
	create_windows_gui()
else
	Gui, windows:Destroy
return

^+R:: ; Reload
Reload
return

^0:: ; Tile Windows and back (hopefully)
if(TileWindows := !TileWindows) {
	windowcoords = get_window_info(windows)
	shell := ComObjCreate("Shell.Application")
	MsgBox, 1, ConfirmDialog, Tile Windows Vertically?, 10
	IfMsgBox Ok
		shell.TileVertically()
	}
else {
	for Index, Element in windowcoords {
		WinMove, ahk_id Element.ahk_id,, Element.xpos, Element.ypos, Element.width, Element.height
		if (Element.win_state = 1)
			WinMaximize, ahk_id Element.ahk_id
			
		}
	}
return

windowsGuiEscape:
ShowWindows := !ShowWindows
Gui, windows:Destroy
















