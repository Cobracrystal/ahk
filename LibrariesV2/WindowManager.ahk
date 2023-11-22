;// made by Cobracrystal
;// TODO: Refreshing with F5 should a) be available with a GUI button, c) should be toggleable to update automatically
;// TODO 3: Add Settings file for excluded windows, automatically form that into regex
#Include %A_ScriptDir%\LibrariesV2\BasicUtilities.ahk

;------------------------- AUTO EXECUTE SECTION -------------------------
;// Add an options to launch the GUI on top of the normal Tray Menu
;// creates the menu for clicking inside the window manager GUI


; WindowManager.windowManager("T")
; settingcheckboxhandler switches both checkboxes when clicking any

class WindowManager {
	; ------------------------ MAIN FUNCTION
	static windowManager(mode := "O", *) {
		mode := SubStr(mode, 1, 1)
		if (WinExist(this.gui.obj.hwnd)) {
			if (mode == "O") ; if gui exists and mode = open, activate window
				WinActivate(this.gui.obj.hwnd)
			else {	; if gui exists and mode = close/toggle, close
				this.gui.coords := windowGetCoordinates(this.gui.obj.hwnd)
				this.gui.destroy()
				this.gui.obj := -1
			}
		}
		else if (mode != "C") ; if gui doesn't exist and mode = open/toggle, create
			this.guiCreate() 
	}

	;------------------------------------------------------------------------

	static __New() {
		; Tray Menu
		guiMenu := TrayMenu.submenus["GUIs"]
		guiMenu.Add("Open Window Manager", this.windowManager.Bind(this))
		A_TrayMenu.Add("GUIs", guiMenu)
		; window menu
		windowListSelectMenu := Menu()
		windowListSelectMenu.Add("Activate Window", this.windowListSelectMenuHandler.Bind(this))
		windowListSelectMenu.Add("Reset Window Position", this.windowListSelectMenuHandler.Bind(this))
		windowListSelectMenu.Add("Minimize Window", this.windowListSelectMenuHandler.Bind(this))
		windowListSelectMenu.Add("Maximize Window", this.windowListSelectMenuHandler.Bind(this))
		windowListSelectMenu.Add("Restore Window", this.windowListSelectMenuHandler.Bind(this))
		windowListSelectMenu.Add("Close Window", this.windowListSelectMenuHandler.Bind(this))
		windowListSelectMenu.Add("Toggle Lock Status", this.windowListSelectMenuHandler.Bind(this))
		windowListSelectMenu.Add()
		windowListSelectMenu.Add("Change Window Transparency", this.windowListSelectMenuHandler.Bind(this))
		windowListSelectMenu.Add("Copy Window Title", this.windowListSelectMenuHandler.Bind(this))
		windowListSelectMenu.Add("View Properties", this.windowListSelectMenuHandler.Bind(this))
		windowListSelectMenu.Add("View Program Folder", this.windowListSelectMenuHandler.Bind(this))
		this.menu := windowListSelectMenu
		A_TrayMenu.Add("WindowList", windowListSelectMenu)
		; init class variables
		; this format is necessary to establish objects.
		this.windowID := 0
		this.gui := {coords: [200, 200], object: -1, text: "Window Manager"}
		this.controls := { transparencySubGUI: {text: "Transparency Menu", slider:{content:0, handle:""}}}
		this.settings := { showExcludedWindows : 0
							, DetectHiddenWindows : 0}
	}

	static guiCreate() {
		winManager := Gui("+Border +OwnDialogs", this.gui.text)
		winManager.OnEvent("Close", this.guiClose.bind(this))
		winManager.OnEvent("Escape", this.guiClose.bind(this))
		winManager.OnEvent("ContextMenu", this.onContextMenu.bind(this))
		
		winManager.AddCheckbox("Section vCheckboxHiddenWindows", "Show Hidden Windows?").OnEvent("Click", this.settingCheckboxHandler.bind(this))
		winManager.AddCheckbox("ys vCheckboxExcludedWindows", "Show Excluded Windows?").OnEvent("Click", this.settingCheckboxHandler.bind(this))
		winManager.Submit(0) ; 0 = nohide
		this.gui.lv := winManager.AddListView("xs R20 w1000 -Multi", ["handle", "ahk_title", "Process", "mmx", "xpos", "ypos", "width", "height", "ahk_class", "Process Path", "Command Line"])
		this.gui.lv.OnNotify()
		this.gui.lv.OnEvent()
		this.gui.lv.OnEvent()
		AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
		; TODO: ADD EVENTS FOR CLICK, DOUBLECLICK ETC (CHECK DOCS). ALSO CONTEXTMENU. OnNotify needs -155, offset 24 (test.ahk), blabla. split the functions
		this.guiListviewCreate()
		winManager.Show(Format("x{1}y{2} Autosize", this.gui.coords[1], this.gui.coords[2]))
		this.gui.lv.Focus()
		this.insertWindowInfo(winManager.Hwnd, 1) ;// inserts the first row to be about the windowManager itself
		
		winManager.AddButton("Default Hidden vButtonDefault", "A").OnEvent("Click", (*) => (this.gui.lv.Focused ? WinActivate(this.windowID) : false))
		this.gui.obj := winManager
	}

	static guiListviewCreate() {
		DetectHiddenWindows(this.settings.DetectHiddenWindows)
		if (!this.settings.showExcludedWindows)
			excludeWindowRegex := "(ZPToolBarParentWnd|Default IME|MSCTFIME UI|NVIDIA GeForce Overlay|Microsoft Text Input Application|^$)"
		for Index, Element in this.getAllWindowInfo(excludeWindowRegex)
			LV_Add("",Element.ahk_id, Element.ahk_title, Element.process, Element.win_state, Element.xpos, Element.ypos, Element.width, Element.height, Element.ahk_class, Element.process_path)
		Loop, 10
			LV_ModifyCol(A_Index, "AutoHdr")
		Loop, 5
			LV_ModifyCol(A_Index+3, "Integer")
		if (LV_GetCount() > 40)
			GuiControl, WindowManager:Move, % this.controls.listviewWindows.handle, h640
		else if (LV_GetCount() >= 20)
			GuiControl, WindowManager:Move, % this.controls.listviewWindows.handle, % "h" . (45+(LV_GetCount()+!ex)*17)
		else
			GuiControl, WindowManager:Move, % this.controls.listviewWindows.handle, h368	
	}

	static refreshGuiListview() {
		Gui, WindowManager:Default
		Gui, Listview, % this.controls.listviewWindows.handle
		LV_Delete()
		this.guiListviewCreate()
		Gui, WindowManager:Show, Autosize
	}

	static insertWindowInfo(this_id, row) {
		WinGetPos(&x,&y,&w,&h,this_id)
		title := WinGetTitle(this_id)
		tclass := WinGetClass(this_id)
		mmx := WinGetMinMax(this_id)
		process := WinGetProcessName(this_id)
		processPath := WinGetProcessPath(this_id)
		LV_Insert(row,"", this_id, title, this_process, mmx, x, y, w, h, tclass, this_process_path)
		Gui, WindowManager:Submit, NoHide
	}

	static getAllWindowInfo(excludedWindowsRegex) {
		windows := {}
		SetTitleMatchMode, RegEx
		WinGet, id, List,,, %excludedWindowsRegex%
		Loop(id) {
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

	static guiClose(guiObj) {
		WindowManager.windowManager("Close")
	}
	
	static onContextMenu(guiObj, ctrlHwnd, eventinfo, isRightclick, x, y) {
		Gui, ListView, % WindowManager.controls.listviewWindows.handle
		LV_GetText(wHandle, eventinfo, 1)
		this.windowID := wHandle
		this.listviewWindows.selectedRowN := LV_GetNext()
		if (WinGetExStyle(wHandle) & 0x8)
			this.menu.Check("Toggle Lock Status")
		else
			this.menu.Uncheck("Toggle Lock Status")
		this.menu.show()
	}

	static guiEventHandler(ctrlHwnd:=0, guiEvent:=0, eventInfo:=0, errLvl:=0) {
		Gui, ListView, % this.controls.listviewWindows.handle
		DetectHiddenWindows(this.settings.DetectHiddenWindows)
	;	Tooltip % ctrlHwnd ", " guiEvent ", " eventInfo
		if (guiEvent != "K" && guiEvent != "ColClick" && guiEvent != "S" && eventInfo != 0) {
			this.controls.listviewWindows.selectedRowN := eventInfo
			LV_GetText(wHandle, eventInfo, 1)
			this.windowID := wHandle
		}
		if (guiEvent == "DoubleClick")
			WinActivate(this.windowID)
		else if (guiEvent == "K") {
			this.controls.listviewWindows.selectedRowN := LV_GetNext()
			LV_GetText(wHandle, this.controls.listviewWindows.selectedRowN, 1)
			this.windowID := wHandle
			switch eventInfo {
				case "46": 	;// Del/Entf Key -> Close that window
					WinClose(this.windowID) ;// winkill possibly overkill. add setting?
					WinWaitClose(this.windowID, , 0.5)
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

	static settingCheckboxHandler(guiCtrlObj, *) {
		switch guiCtrlObj.Name {
			case "CheckboxHiddenWindows":
				this.settings.DetectHiddenWindows := !this.settings.DetectHiddenWindows
			case "checkboxExcludedWindows":
				this.settings.showExcludedWindows := !this.settings.showExcludedWindows
		}
		this.refreshGuiListview()
	}


	static guiButtonOk() {
		if (this.gui.lv.Focused)
			WinActivate(this.windowID)
	; }
	; ------------------------- MENU FUNCTIONS -------------------------
		
	static windowListSelectMenuHandler(itemName) {
		DetectHiddenWindows(this.settings.DetectHiddenWindows)
		switch itemName {
			case "Activate Window":
				WinActivate(this.windowID)
			case "Reset Window Position":
				WinGetPos(,,&w,&h,this.windowID)
				WinMove(this.windowID,, A_ScreenWidth/2 - w/2, A_ScreenHeight/2-h/2)
				WinActivate(this.windowID)
			case "Minimize Window":
				WinMinimize(this.windowID)
			case "Maximize Window":
				WinMaximize(this.windowID)
			case "Restore Window":
				WinRestore(this.windowID)
			case "Close Window":
				WinClose(this.windowID) ;// needs a check via WinExist & question whether winkill or not.
				if WinWaitClose(this.windowID, , 0.5)
					LV_Delete(this.controls.listviewWindows.selectedRowN)
			case "Toggle Lock Status":
				tStyle := WinGetExStyle(this.windowID)
				WinSetAlwaysOnTop(tStyle & 0x8 ? 1 : 0, this.windowID) ; 0x8 is WS_EX_TOPMOST, & bitwise AND
				Menu, windowListSelectMenu, % (tStyle & 0x8 ? "Uncheck" : "Check" ) , Toggle Lock Status
			case "Change Window Transparency":
				this.transparencySubGUIcreate()
			case "Copy Window Title":
				A_Clipboard := WinGetTitle(this.windowID)
			case "View Properties":
				Run('properties"' WinGetProcessPath(this.windowID) '"')
			case "View Program Folder":
				run('explorer.exe /select,"' . WinGetProcessPath(this.windowID) . '"')
			default:
				return
		}
	}
	
	static transparencySubGUIcreate() {
		DetectHiddenWindows(this.settings.DetectHiddenWindows)
		transparency := WinGetTransparent(this.windowID)
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
	
	static transparencySubGUIClose() {
		Gui, windowTransparencyManager:Destroy
		Gui, WindowManager:-Disabled
		Gui, WindowManager:-AlwaysOnTop
	}
	
	static transparencySubGUIhandler() {
		GuiControlGet, transparency,, % this.controls.transparencySubGUI.slider.handle
		this.controls.transparencySubGUI.slider.content := transparency
		DetectHiddenWindows(this.settings.DetectHiddenWindows)
		WinSetTransparent(transparency == 255 ? "Off" : transparency,this.windowID)
	}
		
	; ------ SUBSECTION - GUI FUNCTIONS OF TRANSPARENCY GUI

	static __transparencySubGUIonEscape() {
		WindowManager.transparencySubGUIClose()
	}

	static __transparencySubGUIonClose() {
		WindowManager.transparencySubGUIClose()
	}
}
