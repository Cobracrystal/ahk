;// made by Cobracrystal
;// TODO: Refreshing with F5 should a) be available with a GUI button, b) only update the ListView and not the entire GUI, and c) should be toggleable to update automatically
;// for c), just recreate honestly
;// TODO 2: PRESSING ENTER ACTIVATES IT PLEASE

;// TODO 3: Add Settings file for excluded windows, automatically form that into regex, also add DetectHiddenWindows setting

;------------------------- AUTO EXECUTE SECTION -------------------------
;// Coordinates for first creation of window, the IDs for easier menus
global windowManagerGuiPosX := 200
global windowManagerGuiPosY := 200
global TranspValue := 255
;// Add an options to launch the GUI on top of the normal Tray Menu
Menu, Tray, Add, Open Window GUI, showWindowManagerGui
Menu, Tray, NoStandard
Menu, Tray, Standard

;// creates the menu for clicking inside the window manager GUI
makeWindowGUIMenu()

;------------------------------------------------------------------------

makeWindowGUIMenu() {
	Menu, windowListSelectMenu, Add, Activate Window, activateWindow
	Menu, windowListSelectMenu, Add, Reset Window Position, resetWindowPos
	Menu, windowListSelectMenu, Add, Minimize Window, minimizeWindow
	Menu, windowListSelectMenu, Add, Maximize Window, maximizeWindow
	Menu, windowListSelectMenu, Add, Restore Window, restoreWindow
	Menu, windowListSelectMenu, Add, Close Window, closeWindow
	Menu, windowListSelectMenu, Add, Toggle Lock Status, toggleWindowTopStatus
	Menu, windowListSelectMenu, Add
	Menu, windowListSelectMenu, Add, Change Window Transparency, createWindowTransparencyMenu
	Menu, windowListSelectMenu, Add, Copy Window Title, copyWindowTitle
	Menu, windowListSelectMenu, Add, View Properties, viewWindowProperties
	Menu, windowListSelectMenu, Add, View Program Folder, viewWindowPath
}

createWindowManagerGui(windowManagerGuiPosX, windowManagerGuiPosY) {
	global windowManagerGuiHwnd
	Gui, WindowManager:New, +Border +HwndwindowManagerGuiHwnd ; +AlwaysOnTop 
	Gui, WindowManager:Add, Text,,
	Gui, WindowManager:Add, ListView, vWindowListview AltSubmit gWindowManagerGuiEvent R20 w1000, ahk_id|ahk_title|Process|mmx|xpos|ypos|width|height|ahk_class|ProcessPath
	for Index, Element in getAllWindowInfo(windows)
		LV_Add("",Element.ahk_id, Element.ahk_title, Element.process, Element.win_state, Element.xpos, Element.ypos, Element.width, Element.height, Element.ahk_class, Element.process_path)
	LV_ModifyCol()
	LV_ModifyCol(4,40)
	LV_ModifyCol(5,40)
	LV_ModifyCol(6,40)
	LV_ModifyCol(7,50)
	LV_ModifyCol(8,50)
	Gui, WindowManager:Show, x%windowManagerGuiPosX%y%windowManagerGuiPosY% Autosize, WindowList
	insertWindowInfo(windowManagerGuiHwnd, 1) ;// inserts the first row to be about the windowManager itself
	Gui, WindowManager:Submit, NoHide
}

insertWindowInfo(this_id, row) {
	WinGetPos, windowManagerGuiPosX, windowManagerGuiPosY, width, height, ahk_id %this_id%
	WinGetTitle, this_title, ahk_id %this_id%
	WinGetClass, this_class, ahk_id %this_id%
	WinGet, mmx, MinMax, ahk_id %this_id%
	WinGet, this_process, ProcessName, ahk_id %this_id%
	WinGet, this_process_path, ProcessPath, ahk_id %this_id%
	LV_Insert(row,"", this_id, this_title, this_process, mmx, windowManagerGuiPosX, windowManagerGuiPosY, width, height, this_class, this_process_path)
	Gui, WindowManager:Submit, NoHide
}

getAllWindowInfo(ByRef windows, excludedWindowsRegex := "(ZPToolBarParentWnd|NVIDIA GeForce Overlay|Microsoft Text Input Application|^$)") {
	windows := {}
	tempTitleMatchMode := A_TitleMatchMode
	SetTitleMatchMode, RegEx
	WinGet, id, List,,, %excludedWindowsRegex%
	Loop, %id%
	{
		this_id := id%A_Index%
		WinGetPos, xpos, ypos, width, height, ahk_id %this_id%
		WinGetTitle, this_title, ahk_id %this_id%
		WinGetClass, this_class, ahk_id %this_id%
		WinGet, mmx, MinMax, ahk_id %this_id%
		WinGet, this_process, ProcessName, ahk_id %this_id%
		WinGet, this_process_path, ProcessPath, ahk_id %this_id%
		windows.push({"ahk_id":this_id, "ahk_title":this_title, "process":this_process,"win_state":mmx, "xpos":xpos, "ypos":ypos, "width":width, "height":height, "ahk_class":this_class,  "process_path":this_process_path})
	}
	SetTitleMatchMode, %tempTitleMatchMode%
	return windows
}

showWindowManagerGui() {
	global windowManagerGuiHwnd ;// to access the HWND for WinExist
	if !WinExist("ahk_id" windowManagerGuiHwnd)
		createWindowManagerGui(windowManagerGuiPosX, windowManagerGuiPosY)
	else 
		WinActivate, ahk_id %windowManagerGuiHwnd%
}

WindowManagerGuiEscape(GuiHwnd) {
	WindowManagerGuiClose(GuiHwnd)
}

WindowManagerGuiClose(GuiHwnd) {	
	WinGet, minimize_status, MinMax, ahk_id %GuiHwnd%
	if (minimize_status <> -1) 
		WinGetPos, windowManagerGuiPosX, windowManagerGuiPosY,,, ahk_id %GuiHwnd%
	else {
		DetectHiddenWindows, On
		WinHide, ahk_id %GuiHwnd%
		WinRestore, ahk_id %GuiHwnd%
		WinGetPos, windowManagerGuiPosX, windowManagerGuiPosY,,, ahk_id %GuiHwnd%
		DetectHiddenWindows, Off
		;// LOOK AT HOTKEYMENU MainWindowGuiClose FUNCTION FOR "PROPER" IMPLEMENTATION
	}
	Gui, WindowManager:Destroy
	return 0
}

WindowManagerGuiEvent() {
	; MsgBox, %windowID%, %A_GuiEvent%, %A_EventInfo%, %A_GuiControl%
	global WindowListview
	global windowManagerGuiHwnd
	global windowID
	Gui, ListView, WindowListview
	LV_GetText(windowID, A_EventInfo, 1)
	Switch A_GuiEvent {
		Case "RightClick": Menu, windowListSelectMenu, Show
		Case "DoubleClick": WinActivate, ahk_id %windowID%
		Case "R": return ; // double rightclick????? who tf needs or does that
		Case "Normal": return
		Case "K":	;//Key
			LV_GetText(windowID, LV_GetNext())
			RowNumberControlLaunch := LV_GetNext()
			switch A_EventInfo {
				Case "46": 	;// Del/Entf Key -> Close that window
					closeWindow()
				Case "116":	;// F5 Key -> Reload
					WinGetPos, windowManagerGuiPosX, windowManagerGuiPosY,,, ahk_id %windowManagerGuiHwnd%
					createWindowManagerGui(windowManagerGuiPosX, windowManagerGuiPosY)
				Default: return
			}
		Default: return ; //for future compatibility
	}
}

; ------------------------- MENU FUNCTIONS -------------------------

activateWindow() {
	global windowID
	WinActivate, ahk_id %windowID%
}

resetWindowPos() {
	global windowID
	WinGetPos,,, width_temp, height_temp, ahk_id %windowID%
	WinMove, ahk_id %windowID%,, A_ScreenWidth/2 - width_temp/2, A_ScreenHeight/2-height_temp/2
	WinActivate, ahk_id %windowID%
}

minimizeWindow() {
	global windowID
	WinMinimize, ahk_id %windowID%
}

maximizeWindow() {
	global windowID
	WinMaximize, ahk_id %windowID%
}

restoreWindow() {
	global windowID
	WinRestore, ahk_id %windowID%
}

closeWindow() {
	global windowID
	WinClose, ahk_id %windowID%
	LV_Delete(RowNumberControlLaunch)
}

toggleWindowTopStatus() {
	global windowID
	WinSet, AlwaysOnTop, Toggle, ahk_id %windowID%
	Menu, windowListSelectMenu, ToggleCheck, Toggle Lock Status
}

makeWindowOpaque() {
	global windowID
	WinSet, Transparent, 255, ahk_id %windowID%
}

createWindowTransparencyMenu() {
	global windowID
	global windowManagerGuiHwnd
	global TranspValue
	Gui, WindowManagerTransparencyMenu:New, +OwnerWindowManager +Border +HwndwindowManagerTransparencyMenuGuiHwnd -SysMenu
	Gui, WindowManagerTransparencyMenu:Add, Text, x32, Change Visibility
	Gui, WindowManagerTransparencyMenu:Add, Slider, x10 yp+20 vTranspValue gChangeWindowTransparency AltSubmit Range0-255 ToolTip NoTicks, %TranspValue%
	Gui, WindowManagerTransparencyMenu:Add, Button, w80 yp+30 xp+20 Default gWindowManagerTransparencyMenuGuiClose, OK
	Gui, WindowManagerTransparencyMenu:Show,, Transparency Menu
	Gui, WindowManager:+Disabled +AlwaysOnTop
}

; ------ SUBSECTION - GUI FUNCTIONS OF TRANSPARENCY GUI

WindowManagerTransparencyMenuGuiEscape(GuiHwnd) {
	WindowManagerTransparencyMenuGuiClose(GuiHwnd)
}

WindowManagerTransparencyMenuGuiClose(GuiHwnd) {
	Gui, WindowManagerTransparencyMenu:Submit
	Gui, WindowManager:-Disabled
	ChangeWindowTransparency()
	Gui, WindowManagerTransparencyMenu:Destroy
	Gui, WindowManager:-AlwaysOnTop
	return 0
}

ChangeWindowTransparency() {
	global TranspValue
	global windowID
	Gui, WindowManagerTransparencyMenu:Submit, NoHide
	WinSet, Transparent, %TranspValue%, ahk_id %windowID%
}

; --------- SUBSECTION OVER

makeWindowInvisible() {
	global windowID
	WinSet, Transparent, 0, ahk_id %windowID%
}

copyWindowTitle() {
	global windowID
	WinGetTitle, clipboard, ahk_id %windowID%
}

viewWindowProperties() {
	global windowID
	WinGet, process_path, ProcessPath, ahk_id %windowID%
	Run, properties %process_path%
}

viewWindowPath() {
	global windowID
	WinGet, process_path, ProcessPath, ahk_id %windowID%
	folder_path := RegexReplace(process_path, "(.*\\).*", "$1")
	run, explorer.exe "%folder_path%"
	
}