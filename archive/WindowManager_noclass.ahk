;// made by Cobracrystal
;// TODO: Refreshing with F5 should a) be available with a GUI button, c) should be toggleable to update automatically
;// TODO 3: Add Settings file for excluded windows, automatically form that into regex
#Include %A_ScriptDir%\Libraries\BasicUtilities.ahk

;------------------------- AUTO EXECUTE SECTION -------------------------
;// Coordinates for first creation of window, the IDs for easier menus
;// Add an options to launch the GUI on top of the normal Tray Menu
Menu, GUIS, Add, Open Window GUI, WindowManager
Menu, Tray, Add, GUIs, :GUIS
Menu, Tray, NoStandard
Menu, Tray, Standard

;// creates the menu for clicking inside the window manager GUI
makeWindowGUIMenu()

; ------------------------ MAIN FUNCTION
WindowManager(mode := "O") {
	static guiHWND, guiCoords := [200, 200]
	mode := SubStr(mode, 1, 1)
	if (WinExist("ahk_id" . guiHWND)) {
		if (mode == "O") 
			WinActivate, ahk_id %guiHWND%
		else {	; if gui does exist and mode = close/toggle, close
			guiCoords := windowGetCoordinates(guiHWND)
			Gui, WindowManager:Destroy
		}
	}
	else {
		if (mode != "C") ; if gui doesn't exist and mode = open/toggle, create
			guiHWND := windowManagerGuiCreate(guiCoords[1], guiCoords[2]) 
	}
	return
}



;------------------------------------------------------------------------

makeWindowGUIMenu() {
	Menu, windowListSelectMenu, Add, Activate Window, windowListSelectMenuHandler
	Menu, windowListSelectMenu, Add, Reset Window Position, windowListSelectMenuHandler
	Menu, windowListSelectMenu, Add, Minimize Window, windowListSelectMenuHandler
	Menu, windowListSelectMenu, Add, Maximize Window, windowListSelectMenuHandler
	Menu, windowListSelectMenu, Add, Restore Window, windowListSelectMenuHandler
	Menu, windowListSelectMenu, Add, Close Window, windowListSelectMenuHandler
	Menu, windowListSelectMenu, Add, Toggle Lock Status, windowListSelectMenuHandler
	Menu, windowListSelectMenu, Add
	Menu, windowListSelectMenu, Add, Change Window Transparency, windowListSelectMenuHandler
	Menu, windowListSelectMenu, Add, Copy Window Title, windowListSelectMenuHandler
	Menu, windowListSelectMenu, Add, View Properties, windowListSelectMenuHandler
	Menu, windowListSelectMenu, Add, View Program Folder, windowListSelectMenuHandler
}

windowManagerGuiCreate(guiX, guiY) {
	Gui, WindowManager:New, +Border +HwndguiHWND ; +AlwaysOnTop
	Gui, WindowManager:Add, Checkbox, Section vSettingDetectHiddenWindows gSettingCheckboxHandler, Detect Hidden Windows?
	Gui, WindowManager:Add, Checkbox, ys vSettingShowExcludedWindows gSettingCheckboxHandler, Show Excluded Windows?
	Gui, WindowManager:Submit, NoHide
	Gui, WindowManager:Add, ListView, xs vWindowListview AltSubmit gWindowManagerGuiEvent R20 w1000 -Multi, handle|ahk_title|Process|mmx|xpos|ypos|width|height|ahk_class|Process Path
	createGuiListview(0)
	Gui, WindowManager:Show, x%guiX%y%guiY% Autosize, WindowList
	insertWindowInfo(guiHWND, 1) ;// inserts the first row to be about the windowManager itself
	Gui, WindowManager:Add, Button, Hidden Default gButtonEnter, ok
	return guiHWND
}

createGuiListview(ex := 0) {
	global SettingShowExcludedWindows
	global SettingDetectHiddenWindows
	if (SettingDetectHiddenWindows)
		DetectHiddenWindows, On
	if (SettingShowExcludedWindows)
		excludeWindowRegex := ""
	else 
		excludeWindowRegex := "(ZPToolBarParentWnd|Default IME|MSCTFIME UI|NVIDIA GeForce Overlay|Microsoft Text Input Application|^$)"
	for Index, Element in getAllWindowInfo(excludeWindowRegex)
		LV_Add("",Element.ahk_id, Element.ahk_title, Element.process, Element.win_state, Element.xpos, Element.ypos, Element.width, Element.height, Element.ahk_class, Element.process_path)
	Loop, 10
		A_Index<4||A_Index>8 ? LV_ModifyCol(A_Index) : (A_Index<=6 ? LV_ModifyCol(A_Index, 40) : LV_ModifyCol(A_Index, 50))
	if (LV_GetCount() > 40)
		GuiControl, Move, WindowListView, h640
	else if (LV_GetCount() >= 20)
		GuiControl, Move, WindowListView, % "h" . (45+(LV_GetCount()+!ex)*17)
	else
		GuiControl, Move, WindowListView, h368
	if (ex)
		Gui, WindowManager:Show, Autosize
}

refreshGuiListview() {
	Gui, WindowManager:Default
	Gui, Listview, WindowListview
	LV_Delete()
	createGuiListview(1)
}

insertWindowInfo(this_id, row) {
	WinGetPos, x, y, width, height, ahk_id %this_id%
	WinGetTitle, this_title, ahk_id %this_id%
	WinGetClass, this_class, ahk_id %this_id%
	WinGet, mmx, MinMax, ahk_id %this_id%
	WinGet, this_process, ProcessName, ahk_id %this_id%
	WinGet, this_process_path, ProcessPath, ahk_id %this_id%
	LV_Insert(row,"", this_id, this_title, this_process, mmx, x, y, width, height, this_class, this_process_path)
	Gui, WindowManager:Submit, NoHide
}

getAllWindowInfo(excludedWindowsRegex) {
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

WindowManagerGuiEscape(GuiHwnd) {
	WindowManager("Close")
}

windowManagerGuiClose(GuiHwnd) {
	WindowManager("Close")
}

WindowManagerGuiEvent() {
	; MsgBox, %windowID%, %A_GuiEvent%, %A_EventInfo%, %A_GuiControl%
	global WindowListview
	global windowID
	global SettingDetectHiddenWindows
	Gui, ListView, WindowListview
	LV_GetText(windowID, A_EventInfo, 1)
	if (SettingDetectHiddenWindows)
		DetectHiddenWindows, On
	Switch A_GuiEvent {
		Case "RightClick": Menu, windowListSelectMenu, Show
		Case "DoubleClick": WinActivate, ahk_id %windowID%
		Case "R": return ; // double rightclick????? who tf needs or does that
		Case "Normal": return
		Case "K":	;//Key
			LV_GetText(windowID, LV_GetNext())
			RowNumberControlLaunch := LV_GetNext()
			switch A_EventInfo {
				case "46": 	;// Del/Entf Key -> Close that window
					WinClose, ahk_id %windowID%	;// needs a check via WinExist & question whether to use winkill to shoot the process or not.
					LV_Delete(RowNumberControlLaunch)
				case "116":	;// F5 Key -> Reload // only reload the listview, the other controls are unnecessary
					refreshGuiListview()
				default: return
			}
		default: return ; //for future compatibility since for some fucking reason they decide to add more guiEvent cases all the time
	}
}

SettingCheckboxHandler() {
	Gui, WindowManager:Submit, NoHide
	refreshGuiListview()
}


ButtonEnter() {
	global windowID
	global SettingDetectHiddenWindows
	GuiControlGet, FocusedControl, FocusV
	if (FocusedControl != "WindowListview")
		return
	if (SettingDetectHiddenWindows)
		DetectHiddenWindows, On
	WinActivate, ahk_id %windowID%
}
; ------------------------- MENU FUNCTIONS -------------------------
	
windowListSelectMenuHandler(ItemName) {
	global windowID
	global SettingDetectHiddenWindows
	if (SettingDetectHiddenWindows)
		DetectHiddenWindows, On
	switch ItemName {
		case "Activate Window":
			WinActivate, ahk_id %windowID%
		case "Reset Window Position":
			WinGetPos,,, width_temp, height_temp, ahk_id %windowID%
			WinMove, ahk_id %windowID%,, A_ScreenWidth/2 - width_temp/2, A_ScreenHeight/2-height_temp/2
			WinActivate, ahk_id %windowID%
		case "Minimize Window":
			WinMinimize, ahk_id %windowID%
		case "Maximize Window":
			WinMaximize, ahk_id %windowID%
		case "Restore Window":
			WinRestore, ahk_id %windowID%
		case "Close Window":
			WinClose, ahk_id %windowID%	;// needs a check via WinExist & question whether winkill or not.
			LV_Delete(RowNumberControlLaunch)
		case "Toggle Lock Status":
			WinSet, AlwaysOnTop, Toggle, ahk_id %windowID%
			Menu, windowListSelectMenu, ToggleCheck, Toggle Lock Status
		case "Change Window Transparency":
			windowTransparencyManager(windowID, SettingDetectHiddenWindows)
		case "Copy Window Title":
			WinGetTitle, clipboard, ahk_id %windowID%
		case "View Properties":
			WinGet, process_path, ProcessPath, ahk_id %windowID%
			Run, properties %process_path%
		case "View Program Folder":
			; MsgBox, % A_DetectHiddenWindows
			WinGet, process_path, ProcessPath, ahk_id %windowID%
			folder_path := RegexReplace(process_path, "(.*\\).*", "$1")
			run, explorer.exe "%folder_path%"
		default:
			return
	}
}

windowTransparencyManager(windowID, SettingDetectHiddenWindows, mode := 0) {
	static winID, TransparencyValues := []
	global transpValue
	if (mode == 0) {
		winID := windowID
		transpValue := 255
		for i, e in TransparencyValues
			if (e.windowID == windowID) {
				transpValue := e.transpValue
				found := 1
			}
		if !(found)
			TransparencyValues.push({"windowID":windowID,"transpValue":255})
		createWindowTransparencyGui(windowID, settingHidden)
	}
	else {
		Gui, windowTransparencyManager:Submit
		Gui, WindowManager:-Disabled
		ChangeWindowTransparency(winID, settingHidden)
		for i, e in TransparencyValues
		{
			if (e.windowID == winID) {
				TransparencyValues[i].transpValue := transpValue
			}
		}
		Gui, windowTransparencyManager:Destroy
		Gui, WindowManager:-AlwaysOnTop
	}
}


createWindowTransparencyGui(windowID, settingHidden) {
	global transpValue
	Gui, windowTransparencyManager:New, +OwnerWindowManager +Border -SysMenu
	Gui, windowTransparencyManager:Add, Text, x32, Change Visibility
	fObj := Func("changeWindowTransparency").Bind(windowID, settingHidden)
	Gui, windowTransparencyManager:Add, Slider, x10 yp+20 vTranspValue AltSubmit Range0-255 ToolTip NoTicks, % transpValue
	GuiControl, +g, TranspValue, % fObj
	Gui, windowTransparencyManager:Add, Button, w80 yp+30 xp+20 Default gwindowTransparencyManagerGuiClose, OK
	Gui, windowTransparencyManager:Show,, Transparency Menu
	Gui, WindowManager:+Disabled +AlwaysOnTop
}

; ------ SUBSECTION - GUI FUNCTIONS OF TRANSPARENCY GUI

windowTransparencyManagerGuiEscape(GuiHwnd) {
	windowTransparencyManager(0, 0, 1)
}

windowTransparencyManagerGuiClose(GuiHwnd) {
	windowTransparencyManager(0, 0, 1)
}

ChangeWindowTransparency(winID, settingHidden) {
	global TranspValue
	if (settingHidden)
		DetectHiddenWindows, On
	Gui, windowTransparencyManager:Submit, NoHide
	WinSet, Transparent, % (TranspValue == 255 ? "Off" : TranspValue), ahk_id %winID%
}
