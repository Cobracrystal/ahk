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
	static settingShowExcludedWindows
	static settingDetectHiddenWindows
	; ------------------------ MAIN FUNCTION
	
	windowManager(mode := "O") {
		mode := SubStr(mode, 1, 1)
		if (WinExist("ahk_id " . this.controls.guiMain.handle)) {
			if (mode == "O") 
				WinActivate, % "ahk_id " . this.controls.guiMain.handle
			else {	; if gui does exist and mode = close/toggle, close
				this.controls.guiMain.coords := windowGetCoordinates(this.controls.guiMain.handle)
				Gui, WindowManager:Destroy
				this.controls.guiMain.handle  := ""
			}
		}
		else if (mode != "C") ; if gui doesn't exist and mode = open/toggle, create
			this.guiCreate() 
		return
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
		this.controls := { 	"guiMain": {"text": "WindowList"}
							, "checkboxShowHiddenWindows": {"text": "Detect Hidden Windows?"}
							, "checkboxShowExcludedWindows": {"text": "Show Excluded Windows?"}
							, "listviewWindows": {"text": "handle|ahk_title|Process|mmx|xpos|ypos|width|height|ahk_class|Process Path"}
							, "transparencySubGUI": {"text": "Transparency Menu"}}
		this.controls.guiMain.coords := [200, 200]
		this.controls.transparencySubGUI.transparencyValues := []
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
		DetectHiddenWindows, % this.settingDetectHiddenWindows
		if (!this.settingShowExcludedWindows)
			excludeWindowRegex := "(ZPToolBarParentWnd|Default IME|MSCTFIME UI|NVIDIA GeForce Overlay|Microsoft Text Input Application|^$)"
		for Index, Element in this.getAllWindowInfo(excludeWindowRegex)
			LV_Add("",Element.ahk_id, Element.ahk_title, Element.process, Element.win_state, Element.xpos, Element.ypos, Element.width, Element.height, Element.ahk_class, Element.process_path)
		Loop, 10
			A_Index<4||A_Index>8 ? LV_ModifyCol(A_Index) : (A_Index<=6 ? LV_ModifyCol(A_Index, 40) : LV_ModifyCol(A_Index, 50))
		if (LV_GetCount() > 40)
			GuiControl, WindowManager:Move, % this.controls.listviewWindows.handle, h640
		else if (LV_GetCount() >= 20)
			GuiControl, WindowManager:Move, % this.controls.listviewWindows.handle, % "h" . (45+(LV_GetCount()+!ex)*17)
		else
			GuiControl, WindowManager:Move, % this.controls.listviewWindows.handle, h368
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
		; explanation: this custom label set receives its first parameter onto 'this', not the function itself
		; then, we cannot call this.windowManager as 'this' doesn't refer to the class. 
		; We'd need to bind this to the associated func object, but that isn't possible.
		WindowManager.windowManager("Close")
	}

	__onClose() {
		WindowManager.windowManager("Close")
	}
	
	__onContextMenu(ctrlHwnd := 0, eventinfo := 0, isRightclick := 0, x := 0, y := 0) {
		Gui, ListView, % this.controls.listviewWindows.handle
		LV_GetText(wHandle, eventinfo, 1)
		WindowManager.windowID := wHandle
		WindowManager.listviewWindows.selectedRowN := LV_GetNext()
		Menu, windowListSelectMenu, Show
	}

	guiEventHandler(ctrlHwnd:=0, guiEvent:=0, eventInfo:=0, errLvl:=0) {
		Gui, ListView, % this.controls.listviewWindows.handle
		DetectHiddenWindows, % this.settingDetectHiddenWindows
	;	Tooltip % ctrlHwnd ", " guiEvent ", " eventInfo
		if (guiEvent != "K" && guiEvent != "ColClick" && guiEvent != "S" && eventInfo != 0) {
			this.listviewWindows.selectedRowN := eventInfo
			LV_GetText(wHandle, eventInfo, 1)
			this.windowID := wHandle
		}
		if (guiEvent == "DoubleClick")
			WinActivate, % "ahk_id " . this.windowID
		else if (guiEvent == "K") {
			this.listviewWindows.selectedRowN := LV_GetNext()
			LV_GetText(wHandle, this.listviewWindows.selectedRowN, 1)
			this.windowID := wHandle
			switch eventInfo {
				case "46": 	;// Del/Entf Key -> Close that window
					WinClose, % "ahk_id " . this.windowID	;// needs a check via WinExist & question whether to use winkill to shoot the process or not.
					WinWaitClose, % "ahk_id " . this.windowID, , 0.5
					if !ErrorLevel
						LV_Delete(this.listviewWindows.selectedRowN)
				case "116":	;// F5 Key -> Reload // only reload the listview, the other controls are unnecessary
					this.refreshGuiListview()
				default: return
			}
		}
	}

	settingCheckboxHandler(controlhandle := 0, b := 0, c := 0) {
		Gui, WindowManager:Submit, NoHide
		controlhandle := Format("0x{:x}",controlhandle)
		if (controlhandle == this.controls.checkboxShowHiddenWindows.handle)
			this.settingDetectHiddenWindows := !this.settingDetectHiddenWindows
		else if (controlhandle == this.controls.checkboxShowExcludedWindows.handle)
			this.settingShowExcludedWindows := !this.settingShowExcludedWindows
		this.refreshGuiListview()
	}


	guiButtonOk() {
		GuiControlGet, focused_control, Focus
		GuiControlGet, listviewHwnd, Hwnd, % this.controls.listviewWindows.handle
		if (listviewHwnd != this.controls.listviewWindows.handle)
			return
		DetectHiddenWindows, % this.settingDetectHiddenWindows
		WinActivate, % "ahk_id " . this.windowID
	}
	; ------------------------- MENU FUNCTIONS -------------------------
		
	windowListSelectMenuHandler(itemName) {
		DetectHiddenWindows, % this.settingDetectHiddenWindows
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
					LV_Delete(this.listviewWindows.selectedRowN)
			case "Toggle Lock Status":
				WinSet, AlwaysOnTop, Toggle, % "ahk_id " . this.windowID
				Menu, windowListSelectMenu, ToggleCheck, Toggle Lock Status
			case "Change Window Transparency":
				this.transparencySubGUIcreate()
			case "Copy Window Title":
				WinGetTitle, clipboard, % "ahk_id " . this.windowID
			case "View Properties":
				WinGet, process_path, ProcessPath, % "ahk_id " . this.windowID
				Run, properties %process_path%
			case "View Program Folder":
				WinGet, process_path, ProcessPath, % "ahk_id " . this.windowID
				folder_path := RegexReplace(process_path, "(.*\\).*", "$1")
				run, explorer.exe "%folder_path%"
			default:
				return
		}
	}
	
	transparencySubGUIcreate() {
		for i, e in this.controls.transparencySubGUI.transparencyValues
			if (e.windowID == this.windowID) {
				transparency := e.transparency
				flag := 1
			}
		if !(flag) {
			WinGet, transparency, Transparent, % "ahk_id " . this.windowID
			if (transparency == "")
				transparency := 255
			this.controls.transparencySubGUI.transparencyValues.push({"windowID":this.windowID,"transparency":transparency})
		}
		this.controls.transparencySubGUI.currentTransparency := transparency
		Gui, windowTransparencyManager:New, % "+OwnerWindowManager +Border -SysMenu +Label" . this.__Class . ".__transparencySubGUIon"
		Gui, windowTransparencyManager:Add, Text, x32, Change Visibility
		this.transparencySubGUIhandlerFunction(,,,,1)
		Gui, windowTransparencyManager:Add, Button, w80 yp+30 xp+20 HwndcHandle Default, OK
			gHandle := this.transparencySubGUIhandlerFunction.Bind(this,,,,, -1)
			GuiControl, +g, % cHandle, % gHandle
		Gui, windowTransparencyManager:Show,, % this.controls.transparencySubGUI.text
		Gui, WindowManager:+Disabled +AlwaysOnTop
	}
	
	transparencySubGUIClose(transparency) {
		Gui, windowTransparencyManager:Submit
		for i, e in this.controls.transparencySubGUI.TransparencyValues
			if (e.windowID == this.windowID)
				this.controls.transparencySubGUI.TransparencyValues[i].transparency := transparency
		this.changeWindowTransparency(transparency)
		Gui, windowTransparencyManager:Destroy
		Gui, WindowManager:-Disabled
		Gui, WindowManager:-AlwaysOnTop
	}
	
	transparencySubGUIhandlerFunction(ctrlHwnd := 0, guiEvent := 0, eventinfo := 0, errLevel := 0, worker := 0) {
		static TransparencyValue
		switch worker {
			case 0:
				Gui, windowTransparencyManager:Submit, NoHide
				this.controls.transparencySubGUI.currentTransparency := TransparencyValue
				this.changeWindowTransparency(TransparencyValue)
			case 1:
				Gui, windowTransparencyManager:Add, Slider, x10 yp+20 HwndcHandle vTransparencyValue AltSubmit Range0-255 ToolTip NoTicks, % this.controls.transparencySubGUI.currentTransparency
				gHandle := this.transparencySubGUIhandlerFunction.bind(this)
				GuiControl, +g, % cHandle, % gHandle
			case -1:
				this.transparencySubGUIClose(TransparencyValue)
			default: 
				return
		}
	}

	
	; ------ SUBSECTION - GUI FUNCTIONS OF TRANSPARENCY GUI

	__transparencySubGUIonEscape() {
		WindowManager.transparencySubGUIhandlerFunction(,,,,-1)
	}

	__transparencySubGUIonClose() {
		WindowManager.transparencySubGUIhandlerFunction(,,,,-1)
	}

	changeWindowTransparency(transparency) {
		DetectHiddenWindows, % this.settingDetectHiddenWindows
		WinSet, Transparent, % (transparency == 255 ? "Off" : transparency), % "ahk_id " . this.windowID
	}
}
