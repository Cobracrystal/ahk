;// made by Cobracrystal
;// TODO: Refreshing with F5 should a) be available with a GUI button, c) should be toggleable to update automatically
;// TODO 3: Add Settings file for excluded windows, automatically form that into regex
#Include %A_ScriptDir%\Libraries\BasicUtilities.ahk

;------------------------- AUTO EXECUTE SECTION -------------------------
;// Add an options to launch the GUI on top of the normal Tray Menu
;// creates the menu for clicking inside the window manager GUI
WindowManager.initialize()

; WindowManager.windowManager("T")
; settingcheckboxhandler switches both checkboxes when clicking any

class WindowManager {
	static windowID
	static controls
	static settings
	; ------------------------ MAIN FUNCTION
	windowManager(mode := "O") {
		mode := SubStr(mode, 1, 1)
		if (WinExist("ahk_id " . this.controls.guiMain.handle)) {
			if (mode == "O") ; if gui exists and mode = open, activate window
				WinActivate, % "ahk_id " . this.controls.guiMain.handle
			else {	; if gui exists and mode = close/toggle, close
				this.controls.guiMain.coords := windowGetCoordinates(this.controls.guiMain.handle)
				Gui, WindowManager:Destroy
				this.controls.guiMain.handle  := ""
			}
		}
		else if (mode != "C") ; if gui doesn't exist and mode = open/toggle, create
			this.guiCreate() 
	}

	;------------------------------------------------------------------------

	initialize() {
		; Tray Menu
		tObj := this.windowManager.Bind(this)
		Menu, GUIS, Add, Open Window GUI, % tObj
		Menu, Tray, Add, GUIs, :GUIS
		Menu, Tray, NoStandard
		Menu, Tray, Standard
		; window menu
		tObj := this.windowListSelectMenuHandler.Bind(this)
		Menu, windowListSelectMenu, Add, Activate Window, % tObj
		Menu, windowListSelectMenu, Add, Reset Window Position, % tObj
		Menu, windowListSelectMenu, Add, Minimize Window, % tObj
		Menu, windowListSelectMenu, Add, Maximize Window, % tObj
		Menu, windowListSelectMenu, Add, Restore Window, % tObj
		Menu, windowListSelectMenu, Add, Close Window, % tObj
		Menu, windowListSelectMenu, Add, Toggle Lock Status, % tObj
		Menu, windowListSelectMenu, Add
		Menu, windowListSelectMenu, Add, Change Window Transparency, % tObj
		Menu, windowListSelectMenu, Add, Copy Window Title, % tObj
		Menu, windowListSelectMenu, Add, View Properties, % tObj
		Menu, windowListSelectMenu, Add, View Program Folder, % tObj
		; init class variables
		; this format is necessary to establish objects.
		this.controls := { 	"guiMain": {"text": "WindowList", "coords": [200, 200], "handle":""}
							, "checkboxShowHiddenWindows": {"text": "Detect Hidden Windows?", "handle":""}
							, "checkboxShowExcludedWindows": {"text": "Show Excluded Windows?", "handle":""}
							, "listviewWindows": {"text": "handle|ahk_title|Process|mmx|xpos|ypos|width|height|ahk_class|Process Path", "handle":""}
							, "textWindowCount": {"text": "Window Count: 1", "handle":""}
							, "transparencySubGUI": {"text": "Transparency Menu", "slider":{"content":0, "handle":""}}}
		this.settings := { "showExcludedWindows" : 0
							, "DetectHiddenWindows" : 0}
	}

	guiCreate() {
		Gui, WindowManager:New, % "+Border +HwndguiHandle +Label" . this.__Class . ".__on"
		gHandle := this.settingCheckboxHandler.Bind(this)
		Gui, WindowManager:Add, Checkbox, Section HwndcHandle, % this.controls.checkboxShowHiddenWindows.text
			this.controls.checkboxShowHiddenWindows.handle := cHandle
			GuiControl, +g, % cHandle, % gHandle
		Gui, WindowManager:Add, Checkbox, ys HwndcHandle, % this.controls.checkboxShowExcludedWindows.text
			this.controls.checkboxShowExcludedWindows.handle := cHandle
			GuiControl, +g, % cHandle, % gHandle
		Gui, WindowManager:Add, Text, ys xs+900 w100 HwndcHandle, % this.controls.textWindowCount.text
			this.controls.textWindowCount.handle := cHandle
		Gui, WindowManager:Submit, NoHide
		Gui, WindowManager:Add, ListView, xs HwndcHandle AltSubmit R20 w1000 -Multi, % this.controls.listviewWindows.text
			this.controls.listviewWindows.handle := cHandle
			gHandle := this.guiEventHandler.Bind(this)
			GuiControl, +g, % cHandle, % gHandle
			GuiControl, Focus, % cHandle
		this.guiListviewCreate(0)
		Gui, WindowManager:Show, % Format("x{1}y{2} Autosize", this.controls.guiMain.coords[1], this.controls.guiMain.coords[2]), % this.controls.guiMain.text
		this.insertWindowInfo(guiHandle, 1) ;// inserts the first row to be about the windowManager itself
		Gui, WindowManager:Add, Button, HwndcHandle Default Hidden, Ok
			gHandle := this.guiButtonOk.Bind(this)
			GuiControl, +g, % cHandle, % gHandle
		this.controls.guiMain.handle := guiHandle
	}

	guiListviewCreate(exists := 0) {
		DetectHiddenWindows, % this.settings.DetectHiddenWindows
		if (!this.settings.showExcludedWindows)
			excludeWindowRegex := "(ZPToolBarParentWnd|Default IME|MSCTFIME UI|NVIDIA GeForce Overlay|Microsoft Text Input Application|^$)"
		for i, e in this.getAllWindowInfo(excludeWindowRegex)
			LV_Add("",e.ahk_id, e.ahk_title, e.process, e.win_state, e.xpos, e.ypos, e.width, e.height, e.ahk_class, e.process_path)
		Loop, 10
			LV_ModifyCol(A_Index, "AutoHdr")
		Loop 5
			LV_ModifyCol(A_Index+3, "Integer")
		if (LV_GetCount() > 40)
			GuiControl, WindowManager:Move, % this.controls.listviewWindows.handle, h640
		else if (LV_GetCount() >= 20)
			GuiControl, WindowManager:Move, % this.controls.listviewWindows.handle, % "h" . (45+(LV_GetCount()+!exists)*17)
		else
			GuiControl, WindowManager:Move, % this.controls.listviewWindows.handle, h368
		GuiControl, WindowManager:, % this.controls.textWindowCount.handle, % Format("Window Count: {:5}", "" . LV_GetCount() + !exists)
		
		if (exists)
			Gui, WindowManager:Show, Autosize
	}

	refreshGuiListview() {
		Gui, WindowManager:Default
		Gui, Listview, % this.controls.listviewWindows.handle
		LV_Delete()
		this.guiListviewCreate(1)
	}

	insertWindowInfo(this_id, row) {
		WinGetPos, x, y, width, height, % "ahk_id " . this_id
		WinGetTitle, this_title, % "ahk_id " . this_id
		WinGetClass, this_class, % "ahk_id " . this_id
		WinGet, mmx, MinMax, % "ahk_id " . this_id
		WinGet, this_process, ProcessName, % "ahk_id " . this_id
		WinGet, this_process_path, ProcessPath, % "ahk_id " . this_id
		LV_Insert(row,"", this_id, this_title, this_process, mmx, x, y, width, height, this_class, this_process_path)
		Gui, WindowManager:Submit, NoHide
	}

	getAllWindowInfo(excludedWindowsRegex) {
		windows := {}
		SetTitleMatchMode, RegEx
		WinGet, id, List,,, %excludedWindowsRegex%
		Loop, %id%
		{
			this_id := id%A_Index%
			WinGetPos, xpos, ypos, width, height, % "ahk_id " . this_id
			WinGetTitle, this_title, % "ahk_id " . this_id
			WinGetClass, this_class, % "ahk_id " . this_id
			WinGet, mmx, MinMax, % "ahk_id " . this_id
			WinGet, this_process, ProcessName, % "ahk_id " . this_id
			WinGet, this_process_path, ProcessPath, % "ahk_id " . this_id
			windows.push({"ahk_id":this_id, "ahk_title":this_title, "process":this_process,"win_state":mmx
						, "xpos":xpos, "ypos":ypos, "width":width, "height":height, "ahk_class":this_class
						,  "process_path":this_process_path})
		}
		return windows
	}

	__onEscape() { 
		; this custom label set receives its first parameter onto 'this', not the function itself
		; then, we cannot call this.windowManager as 'this' doesn't refer to the class. 
		; We'd need to bind this to the associated func object, but that isn't possible.
		WindowManager.windowManager("Close")
	}

	__onClose() {
		WindowManager.windowManager("Close")
	}
	
	__onContextMenu(ctrlHwnd := 0, eventinfo := 0, isRightclick := 0, x := 0, y := 0) {
		Gui, ListView, % WindowManager.controls.listviewWindows.handle
		LV_GetText(wHandle, eventinfo, 1)
		WindowManager.windowID := wHandle
		WindowManager.listviewWindows.selectedRowN := LV_GetNext()
		WinGet, tStyle, ExStyle, % "ahk_id " . wHandle
		Menu, windowListSelectMenu, % (tStyle & 0x8 ? "Check" : "Uncheck"), Toggle Lock Status
		Menu, windowListSelectMenu, Show
	}

	guiEventHandler(ctrlHwnd:=0, guiEvent:=0, eventInfo:=0, errLvl:=0) {
		Gui, ListView, % this.controls.listviewWindows.handle
		DetectHiddenWindows, % this.settings.DetectHiddenWindows
	;	Tooltip % ctrlHwnd ", " guiEvent ", " eventInfo
		if (guiEvent != "K" && guiEvent != "ColClick" && guiEvent != "S" && eventInfo != 0) {
			this.controls.listviewWindows.selectedRowN := eventInfo
			LV_GetText(wHandle, eventInfo, 1)
			this.windowID := wHandle
		}
		if (guiEvent == "DoubleClick")
			WinActivate, % "ahk_id " . this.windowID
		else if (guiEvent == "K") {
			this.controls.listviewWindows.selectedRowN := LV_GetNext()
			LV_GetText(wHandle, this.controls.listviewWindows.selectedRowN, 1)
			this.windowID := wHandle
			switch eventInfo {
				case "46": 	;// Del/Entf Key -> Close that window
					WinClose, % "ahk_id " . this.windowID	;// winkill possibly overkill. add setting?
					WinWaitClose, % "ahk_id " . this.windowID, , 0.5
					if !ErrorLevel
						LV_Delete(this.controls.listviewWindows.selectedRowN)
				case "67":
					if (GetKeyState("Ctrl"))
						WinGetTitle, clipboard, % "ahk_id " . this.windowID
				case "116":	;// F5 Key -> Reload
					this.refreshGuiListview()
				default: return
			}
		}
	}

	settingCheckboxHandler(controlhandle := 0, b := 0, c := 0) {
		Gui, WindowManager:Submit, NoHide
		controlhandle := Format("0x{:x}",controlhandle)
		if (controlhandle == this.controls.checkboxShowHiddenWindows.handle)
			this.settings.DetectHiddenWindows := !this.settings.DetectHiddenWindows
		else if (controlhandle == this.controls.checkboxShowExcludedWindows.handle)
			this.settings.showExcludedWindows := !this.settings.showExcludedWindows
		this.refreshGuiListview()
	}


	guiButtonOk() {
		DetectHiddenWindows, % this.settings.DetectHiddenWindows
		GuiControlGet, focused_control, Focus
		GuiControlGet, listviewHwnd, Hwnd, % this.controls.listviewWindows.handle
		if (listviewHwnd != this.controls.listviewWindows.handle)
			return
		WinActivate, % "ahk_id " . this.windowID
	}
	; ------------------------- MENU FUNCTIONS -------------------------
		
	windowListSelectMenuHandler(itemName) {
		DetectHiddenWindows, % this.settings.DetectHiddenWindows
		switch itemName {
			case "Activate Window":
				WinActivate, % "ahk_id " . this.windowID
			case "Reset Window Position":
				WinGetPos,,, width_temp, height_temp, % "ahk_id " . this.windowID
				WinMove, % "ahk_id " . this.windowID,, A_ScreenWidth/2 - width_temp/2, A_ScreenHeight/2-height_temp/2
				WinActivate, % "ahk_id " . this.windowID
			case "Minimize Window":
				WinMinimize, % "ahk_id " . this.windowID
			case "Maximize Window":
				WinMaximize, % "ahk_id " . this.windowID
			case "Restore Window":
				WinRestore, % "ahk_id " . this.windowID
			case "Close Window":
				WinClose, % "ahk_id " . this.windowID	;// needs a check via WinExist & question whether winkill or not.
				WinWaitClose, % "ahk_id " . this.windowID, , 0.5
				if !ErrorLevel
					LV_Delete(this.controls.listviewWindows.selectedRowN)
			case "Toggle Lock Status":
				WinGet, tStyle, ExStyle, % "ahk_id " . this.windowID
				WinSet, AlwaysOnTop, % (tStyle & 0x8 ? "Off" : "On" ) , % "ahk_id " . this.windowID ; 0x8 is WS_EX_TOPMOST, & bitwise AND
				Menu, windowListSelectMenu, % (tStyle & 0x8 ? "Uncheck" : "Check" ) , Toggle Lock Status
			case "Change Window Transparency":
				this.transparencySubGUIcreate()
			case "Copy Window Title":
				WinGetTitle, clipboard, % "ahk_id " . this.windowID
			case "View Properties":
				WinGet, process_path, ProcessPath, % "ahk_id " . this.windowID
				Run, properties %process_path%
			case "View Program Folder":
				WinGet, process_path, ProcessPath, % "ahk_id " . this.windowID
				run, % "explorer.exe /select,""" . process_path . """"
			default:
				return
		}
	}
	
	transparencySubGUIcreate() {
		DetectHiddenWindows % this.settings.DetectHiddenWindows
		WinGet, transparency, Transparent, % "ahk_id " . this.windowID
		if (transparency == "")
			transparency := 255
		this.controls.transparencySubGUI.slider.content := transparency
		Gui, windowTransparencyManager:New, % "+OwnerWindowManager +Border -SysMenu +Label" . this.__Class . ".__transparencySubGUIon"
		Gui, windowTransparencyManager:Add, Text, x32, Change Visibility
		
		Gui, windowTransparencyManager:Add, Slider, x10 yp+20 HwndcHandle AltSubmit Range0-255 ToolTip NoTicks, % this.controls.transparencySubGUI.slider.content
			this.controls.transparencySubGUI.slider.handle := cHandle
			gHandle := this.transparencySubGUIhandler.bind(this)
			GuiControl, +g, % cHandle, % gHandle
		Gui, windowTransparencyManager:Add, Button, w80 yp+30 xp+20 HwndcHandle Default, OK
			gHandle := this.transparencySubGUIClose.Bind(this)
			GuiControl, +g, % cHandle, % gHandle
		Gui, windowTransparencyManager:Show,, % this.controls.transparencySubGUI.text
		Gui, WindowManager:+Disabled +AlwaysOnTop
	}
	
	transparencySubGUIClose() {
		Gui, windowTransparencyManager:Destroy
		Gui, WindowManager:-Disabled
		Gui, WindowManager:-AlwaysOnTop
	}
	
	transparencySubGUIhandler() {
		GuiControlGet, transparency,, % this.controls.transparencySubGUI.slider.handle
		this.controls.transparencySubGUI.slider.content := transparency
		DetectHiddenWindows, % this.settings.DetectHiddenWindows
		WinSet, Transparent, % (transparency == 255 ? "Off" : transparency), % "ahk_id " . this.windowID
	}
		
	; ------ SUBSECTION - GUI FUNCTIONS OF TRANSPARENCY GUI

	__transparencySubGUIonEscape() {
		WindowManager.transparencySubGUIClose()
	}

	__transparencySubGUIonClose() {
		WindowManager.transparencySubGUIClose()
	}
}
