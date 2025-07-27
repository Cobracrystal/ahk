; https://github.com/cobracrystal/ahk
; TODO 3: Add Settings for excluded windows (with editable list, like in PATH native settings)
; add option to resize and position windows, including multiple windows. make inputbox gui for xywh for that.
; fix spread windows
; add "show system info" somewhere in settings to show monitor sizes etc
; needs to check if window is in admin mode, else most commands fail (eg winsettransparent). Also add button for that in settings
; cache command lines to reuse
; add general updates
#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"
#Include "*i %A_LineFile%\..\..\LibrariesV2\CustomWindowFunctions.ahk"
; Usage (if including this file as a library):
; ^+F11::WindowManager.windowManager("T")

/*
hotkeys: (only active within window)
F5 to refresh view
Enter to activate
Del to close window
ctrl+d to focus list view
ctrl+f to focus search
shift+del to forcefully close window (skipping warnings etc)
ctrl+C to copy identifier
ctrl+alt+c to copy title only
ctrl+shift+c to copy all window data in json format
ctrl+shift+alt+c to copy hwnd
*/

class WindowManager {
	static windowManager(mode := "O", *) {
		mode := SubStr(mode, 1, 1)
		if (WinExist(this.gui)) {
			if (mode == "O")
				WinActivate(this.gui.hwnd)
			else {
				this.data.coords := windowGetCoordinates(this.gui.hwnd)
				this.gui.destroy()
				this.gui := 0
			}
		}
		else if (mode != "C")
			this.guiCreate()
	}

	;------------------------------------------------------------------------

	static __New() {
		this.customFunctions := ["vlcMinimalViewingMode"]
		this.gui := 0
		this.settingsGui := 0
		this.data := {
			coords: {x: 300, y: 200, cw: 1018, ch: 410, mmx: 0},
			currentWinInfo: [],
		}
		; window menu
		HotIfWinactive("Window Manager ahk_class AutoHotkeyGUI")
		Hotkey("^f", (*) => (this.gui["EditFilterWindows"].Focus()))
		Hotkey("^d", (*) => (this.LV.Focus()))
		Hotkey("^BackSpace", (*) => Send("^{Left}^{Delete}"))
		HotIfWinactive()
		this.config := this.defaultConfig
		this.menus := this.buildContextMenu()
		try Hotkey(this.config.guiHotkey, this.windowManager.bind(this, "T"))
		menuText := "Open Window Manager (" this.config.guiHotkey ")"
		if (A_LineFile == A_ScriptFullPath) {
			A_TrayMenu.Insert("1&", menuText, this.windowManager.Bind(this))
			A_TrayMenu.Default := menuText
		} else {
			subMenu := TrayMenu.submenus["GUIs"]
			subMenu.Add(menuText, this.windowManager.Bind(this))
			A_TrayMenu.Insert("1&", "GUIs", subMenu)
		}
	}

	static guiCreate() {
		static LVS_EX_DOUBLEBUFFER := 0x10000
		static LVWidth := 1000
		this.gui := Gui("+OwnDialogs +Resize", "Window Manager")
		this.gui.OnEvent("Close", (*) => this.windowManager("Close"))
		this.gui.OnEvent("Escape", (*) => this.windowManager("Close"))
		this.gui.OnEvent("Size", this.onResize.bind(this))
		this.gui.SetFont("c0x000000") ; this is necessary to force font of checkboxes / groupboxes
		this.gui.AddCheckbox("Section R1.45 vCBHiddenWindows Checked" . this.config.detectHiddenWindows, "Show Hidden Windows?").OnEvent("Click", this.configGuiHandler.bind(this))
		this.gui.AddCheckbox("ys R1.45 vCBExcludedWindows Checked" . !this.config.useBlacklist, "Show Excluded Windows?").OnEvent("Click", this.configGuiHandler.bind(this))
		this.gui.AddCheckbox("ys R1.45 vCBGetCommandLine Checked" . this.config.getCommandLine, "Show Command Lines? (Slow)").OnEvent("Click", this.configGuiHandler.bind(this))
		this.gui.AddEdit("ys vEditFilterWindows").OnEvent("Change", this.guiListviewCreate.bind(this, false, false, false))
		this.gui.AddText("ys+2 0x200 R1.45 xs+" LVWidth-160 " w100 vWindowCount", "Window Count: 0")
		this.gui.AddButton("xs+" LVWidth-50 " ys w50 vBTNSettings", "Settings").OnEvent("Click", this.createSettingsGui.bind(this))
		this.LV := this.gui.AddListView("xs R20 w1000 +Multi", ["#z", "handle", "ahk_title", "Process", "mmx", "xpos", "ypos", "width", "height", "ahk_class", "PID", "Process Path", "Command Line"])
		this.LV.Opt("+LV" LVS_EX_DOUBLEBUFFER)
		this.LV.OnNotify(-155, this.LV_Event.bind(this, "Key"))
		this.LV.OnEvent("ContextMenu", this.LV_Event.bind(this, "ContextMenu"))
		this.LV.OnEvent("DoubleClick", this.LV_Event.bind(this, "DoubleClick"))
		this.gui.AddButton("Default Hidden", "A").OnEvent("Click", this.activateButton.bind(this))
		this.guiListviewCreate(true, true)
		this.applyColorScheme(this.gui)
		; this.gui.show("Autosize")
		this.gui.Show(Format("x{1}y{2}w{3}h{4} {5}", this.data.coords.x, this.data.coords.y, this.data.coords.cw, this.data.coords.ch, this.data.coords.mmx == 1 ? "Maximize" : "Restore"))
		this.LV.Focus()
	}


	static applyColorScheme(guiObj?) {
		bgColor := this.config.colorTheme ? (this.config.colorTheme == 2 ? this.config.customThemeColor : this.colors.DARK) : "0xFFFFFF"
		dark := isDark(bgColor)
		fontColor := this.config.colorTheme == 2 ? this.config.customThemeFontColor : (dark ? "0xFFFFFF" : "0x000000")
		if (!IsSet(guiObj)) {
			this.applyColorScheme(this.gui)
			this.applyColorScheme(this.settingsGui)
			return
		}
		this.toggleGuiColorScheme(guiObj, dark, bgColor, fontColor)
		if (this.settingsGui == guiObj) {
			for ctrlName in ["editCustomThemeColor", "editCustomThemeFontColor"] {
				guiObj.%ctrlName%.Opt("+Background" this.config.customThemeColor)
				guiObj.%ctrlName%.SetFont('c' this.config.customThemeFontColor)
			}
		}
	}

	static toggleGuiColorScheme(guiObj, dark, color, fontColor) {
		static WM_THEMECHANGED := 0x031A
		;// title bar dark
		if (VerCompare(A_OSVersion, "10.0.17763")) {
			attr := 19
			if (VerCompare(A_OSVersion, "10.0.18985"))
				attr := 20
			DllCall("dwmapi\DwmSetWindowAttribute", "ptr", guiObj.hwnd, "int", attr, "int*", (dark ? true : false), "int", 4)
		}
		guiObj.BackColor := color
		font := 'c' . fontColor
		guiObj.SetFont(font)
		for cHandle, ctrl in guiObj {
			if (ctrl is Gui.Hotkey || ctrl is Gui.Slider)
				continue
			ctrl.Opt("+Background" color)
			ctrl.SetFont(font)
			if (ctrl is Gui.Button || ctrl is Gui.ListView)
				DllCall("uxtheme\SetWindowTheme", "ptr", ctrl.hwnd, "str", (dark ? "DarkMode_Explorer" : ""), "ptr", 0)
			if (ctrl is Gui.DDL)
				DllCall("uxtheme\SetWindowTheme", "Ptr", ctrl.hWnd, "Str", (dark ? "DarkMode_CFD" : "CFD"), "Ptr", 0)
			ctrl.Redraw()
		}
		return
	}

	static guiListviewCreate(resize := false, firstCall := false, update := true, *) {
		this.gui.Opt("+Disabled")
		this.LV.Opt("-Redraw")
		wHandles := [], lastRow := 0
		focusedRow := this.LV.GetNext(0, "F")
		focusedHandle := focusedRow ? Integer(this.LV.GetText(focusedRow, 2)) : 0
		Loop {
			lastRow := this.LV.GetNext(lastRow)
			if (lastRow == 0)
				break
			wHandles.push(Integer(this.LV.GetText(lastRow, 2)))
		}
		this.LV.Delete()
		if (update) {
			this.data.currentWinInfo := this.getAllWindowInfo(this.config.detectHiddenWindows, this.config.useBlacklist)
			if (firstCall)
				this.data.currentWinInfo.InsertAt(1, this.getWindowInfo(this.gui.Hwnd))
		}
		for i, win in this.data.currentWinInfo
			if (this.isIncludedInSearch(win)) {
				options := ""
				if (objRemoveValue(wHandles, win.hwnd, 1))
					options .= "Select"
				if (win.hwnd == focusedHandle)
					options .= " Focus"
				this.LV.Add(options, i, this.config.formatWindowHandles ? Format("0x{:06X}", win.hwnd) : win.hwnd, 
					win.title, win.process, win.state, win.xpos, win.ypos, win.width, win.height, win.class, win.pid, win.processPath, win.commandLine)
			}
		this.gui["WindowCount"].Value := Format("Window Count: {:4}", this.LV.GetCount())
		if (firstCall)
			for i in [1, 2, 5, 6, 7, 8, 9, 11]
				this.LV.ModifyCol(i, "+Integer")
		if (resize) {
			Loop (this.LV.GetCount("Col"))
				this.LV.ModifyCol(A_Index, "+AutoHdr")
		}
		this.LV.Opt("+Redraw")
		this.gui.Opt("-Disabled")
	}

	static isIncludedInSearch(win) {
		static aliases := Map(
			"hwnd",			["handle", "id", "hwnd", "ahk_id"],
			"title",		["title", "ahk_title"],
			"process",		["process", "ahk_process"],
			"state",		["mmx", "state", "ahk_state"],
			"xpos",			["x", "xpos", "ahk_x"],
			"ypos",			["y", "ypos", "ahk_y"],
			"width",		["w", "width", "ahk_w"],
			"height",		["h", "height", "ahk_h"],
			"class",		["class", "ahk_class"],
			"pid",			["pid", "processID", "ahk_pid"],
			"processPath",	["processPath", "path", "ahk_exe"],
			"commandLine",	["command", "cmdl", "cmd", "commandLine", "ahk_cmd"]
		)
		search := this.gui["EditFilterWindows"].Value
		if (search == "")
			return true
		tagMap := Map()
		for value, keys in aliases
			for key in keys
				tagMap[key] := value
		
		searches := Map()
		for tag, tagMapped in tagMap {
			flagAHKSyntax := (SubStr(tag, 1, 4) == "ahk_")
			RegexMatch(search, "(?:^|\s)" tag . (flagAHKSyntax ? "(?::|\s+)" : ":") . "([^\s]+)", &o)
			if (o) {
				searches[tagMapped] := o[1]
				search := RegExReplace(search, "\s*" tag . (flagAHKSyntax ? "(?::|\s+)" : ":") . "[^\s]+")
			}
		}
		freeSearch := search
		flagInclude := true
		for tag, s in searches
			if (!InStr(win.%tag%, s, this.config.filterCaseSense))
				return false
		if freeSearch == ""
			return true
		for i, e in win.OwnProps()
			if (InStr(e, freeSearch, this.config.filterCaseSense))
				return true
		return false
	}

	static getAllWindowInfo(getHidden := false, useBlacklist := true) {
		windows := []
		tMM := A_TitleMatchMode
		dHW := A_DetectHiddenWindows
		DetectHiddenWindows(getHidden)
			wHandles := WinGetList()
		for i, wHandle in wHandles {
			if useBlacklist
				for e in this.config.blacklist
					if ((e != "" && WinExist(e " ahk_id " wHandle)) || (e == "" && WinGetTitle(wHandle) == ""))
						continue 2
			windows.push(this.getWindowInfo(wHandle))
		}
		SetTitleMatchMode(tMM)
		DetectHiddenWindows(dHW)
		return windows
	}

	static getWindowInfo(wHandle) {
		x := "", y := "", w := "", h := "", winTItle := "", winClass := "", mmx := "", processName := "", processPath := "", pid := "", cmdLine := ""
		if !WinExist(wHandle)
			return {}
		try	WinGetPos(&x, &y, &w, &h, wHandle)
		try	winTitle := WinGetTitle(wHandle)
		try	winClass := WinGetClass(wHandle)
		try	mmx := WinGetMinMax(wHandle)
		try	processName := WinGetProcessName(wHandle)
		try	processPath := WinGetProcessPath(wHandle)
		try	pid := WinGetPID(wHandle)
			if (this.config.getCommandLine)
				try cmdLine := this.winmgmt("CommandLine", "Where ProcessId = " pid)[1]
			; Get-WmiObject -Query "SELECT * FROM Win32_Process WHERE ProcessID = [PID]" in powershell btw
		return {
			hwnd: wHandle,
			title: winTitle,
			process: processName,
			class: winClass,
			processPath: processPath,
			state: mmx,
			xpos: x,
			ypos: y,
			width: w,
			height: h,
			pid: pid,
			commandLine: cmdLine
		}
	}

	static borderlessFullscreenWindow(wHandle) {
		WinGetPos(&x, &y, &w, &h, wHandle)
		WinGetClientPos(&cx, &cy, &cw, &ch, wHandle)
		mHandle := DllCall("MonitorFromWindow", "Ptr", wHandle, "UInt", 0x2, "Ptr")
		NumPut("Uint", 40, monitorInfo := Buffer(40))
		DllCall("GetMonitorInfo", "Ptr", mHandle, "Ptr", monitorInfo)
		monitor := {
			left: NumGet(monitorInfo, 4, "Int"),
			top: NumGet(monitorInfo, 8, "Int"),
			right: NumGet(monitorInfo, 12, "Int"),
			bottom: NumGet(monitorInfo, 16, "Int")
		}
		WinMove(
			monitor.left + (x - cx),
			monitor.top + (y - cy),
			monitor.right - monitor.left + (w - cw),
			monitor.bottom - monitor.top + (h - ch),
			wHandle
		)
	}

	static isBorderlessFullscreen(wHandle) {
		WinGetPos(&x, &y, &w, &h, wHandle)
		WinGetClientPos(&cx, &cy, &cw, &ch, wHandle)
		mHandle := DllCall("MonitorFromWindow", "Ptr", wHandle, "UInt", 0x2, "Ptr")
		NumPut("Uint", 40, monitorInfo := Buffer(40))
		DllCall("GetMonitorInfo", "Ptr", mHandle, "Ptr", monitorInfo)
			monLeft := NumGet(monitorInfo, 4, "Int"),
			monTop := NumGet(monitorInfo, 8, "Int"),
			monRight := NumGet(monitorInfo, 12, "Int"),
			monBottom := NumGet(monitorInfo, 16, "Int")
		if (monLeft == cx && monTop == cy && monRight == monLeft + cw && monBottom == monTop + ch)
			return true
		else 
			return false
	}

	static winmgmt(v, w, d := "Win32_Process", m := "winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2") {
		local i, s := []
		for i in ComObjGet(m).ExecQuery("Select " . (IsSet(v) ? v : "*") . " from " . d . (IsSet(w) ? " " . w : ""))
			s.push(i.%v%)
		return (s.length > 0 ? s : [""])
	}

	static onResize(g, mmx, w, h) {
		if (mmx == -1) ; minimized
			return
		this.lv.getpos(,,&lvw, &lvh)
		this.LV.Move(,,w-18,h-42)
		this.lv.getpos(,,&lvnw, &lvnh)
		deltaX := lvnw - lvw
		for ctrlName in ["WindowCount", "BTNSettings"] {
			this.gui[ctrlName].GetPos(&ox)
			this.gui[ctrlName].Move(ox+deltaX)
			this.gui[ctrlName].Redraw()
		}
	}

	static LV_Event(eventType, LVObj, param, *) {
		switch eventType {
			case "Key":
				vKey := NumGet(param, 24, "ushort")
				rowNFocused := this.LV.GetNext(0,"F")
				rowNums := []
				wHandles := []
				Loop {
					nextRow := this.LV.GetNext(A_Index == 1 ? 0 : rowNums[rowNums.Length])
					if (nextRow == 0)
						break
					rowNums.push(nextRow)
				}
				if (rowNums.Length == 0 && vKey != "65" && vKey != "116")
					return
				for e in rowNums
					wHandles.push(Integer(this.LV.GetText(e, 2)))
				DetectHiddenWindows(this.config.detectHiddenWindows)
				switch vKey {
					case "46": 	;// Del/Entf Key -> Close that window
						cFunction := GetKeyState("Shift") ? WinKill : WinClose
						if(wHandles.Length > 1 && MsgBoxAsGui("Are you sure you want to close " wHandles.Length " windows at once?", "Confirmation Prompt", 0x1,,1) == "Cancel")
							return
						for i, wHandle in arrayInReverse(wHandles)
							try cFunction(wHandle)
						for i, wHandle in arrayInReverse(wHandles)
							if WinWaitClose(wHandle, , 0.5) {
								try this.LV.Delete(rowNums[rowNums.Length - i + 1])
								try objRemoveValue(this.data.currentWinInfo, wHandle,, (it, itV, wHandle) => (itV.hwnd == wHandle))
							}
					case "65": ; ctrl A
						if (!GetKeyState("Ctrl"))
							return
						guiRowIndex := 0
						if !GetKeyState("Shift")
							Loop(this.LV.GetCount())
								if (Integer(this.LV.GetText(A_Index, 2)) == this.gui.Hwnd) {
									guiRowIndex := A_Index
									break
								}
						if (guiRowIndex)
							this.LV.Modify(guiRowIndex, "-Select")
						Loop this.LV.GetCount()
							if (A_Index != guiRowIndex)
								this.LV.Modify(A_Index, "+Select")
					case "67": ; ctrl C
						if (GetKeyState("Ctrl") && GetKeyState("Alt") && GetKeyState("Shift")) {
							for rowN in rowNums
								str .= this.LV.GetText(rowN, 2) "`n"
							A_Clipboard := RTrim(str, "`n")
						}
						else if (GetKeyState("Ctrl") && GetKeyState("Shift")) { ; ctrl shift C to get all info
							wInfoArray := []
							for rowN in rowNums {
								wInfoArray.Push({
									hwnd: 	 this.LV.GetText(rowN, 2),
									title: 	 this.LV.GetText(rowN, 3),
									process: this.LV.GetText(rowN, 4),
									state: 	 this.LV.GetText(rowN, 5),
									xpos: 	 this.LV.GetText(rowN, 6),
									ypos: 	 this.LV.GetText(rowN, 7),
									width: 	 this.LV.GetText(rowN, 8),
									height:  this.LV.GetText(rowN, 9),
									class: 	 this.LV.GetText(rowN, 10),
									pid: 	 this.LV.GetText(rowN, 11),
									processPath: this.LV.GetText(rowN, 12),
									commandLine: this.config.getCommandLine ? this.LV.GetText(rowN, 13) : unset
								})
							}
							A_Clipboard := objToString(wInfoArray, false, false)
						} else if (GetKeyState("Ctrl") && GetKeyState("Alt")) { ; ctrl + alt C to get title only
							for rowN in rowNums
								str .= this.LV.GetText(rowN, 3) "`n"
							A_Clipboard := Trim(str, "`n")
						} else if (GetKeyState("Ctrl")) { ; ctrl C to get identifier
							for rowN in rowNums
								str .= this.LV.GetText(rowN, 3) " ahk_exe " this.LV.GetText(rowN, 4) " ahk_class " this.LV.GetText(rowN, 10) . "`n"
							A_Clipboard := Trim(str, "`n")
						}
					case "77":
						for rowN in rowNums
							WinMaximize(Integer(this.LV.GetText(rowN, 2)))
					case "116":	; F5 Key -> Refresh LV
						this.guiListviewCreate()
				}
			case "ContextMenu":
				rowN := param
				if (rowN == 0 || rowN > this.LV.GetCount())
					return
				wHandle := Integer(this.LV.GetText(rowN, 2))
				if (!WinExist(wHandle)) {
					this.LV.Delete(rowN)
					return
				}
				style := WinGetStyle(wHandle)
				exStyle := WinGetExStyle(wHandle)
				if (exStyle & this.windowExStyles.WS_EX_TOPMOST)
					this.menus.submenu.Check("Toggle Window Lock")
				else
					this.menus.submenu.Uncheck("Toggle Window Lock")
				if (style & this.windowStyles.WS_CAPTION)
					this.menus.submenu.Check("Toggle Title Bar")
				else
					this.menus.submenu.Uncheck("Toggle Title Bar")
				if (style & this.windowStyles.WS_VISIBLE)
					this.menus.submenu.Check("Toggle Visibility")
				else
					this.menus.submenu.Uncheck("Toggle Visibility")
				this.menus.menu.show()
			case "DoubleClick":
				rowN := param
				if (rowN != 0)
					WinActivate(Integer(LVObj.GetText(rowN, 2)))
			default:
				return
		}
	}

	static activateButton(*) {
		if (!this.LV.Focused)
			return
		wHandles := [], lastRow := 0
		Loop {
			lastRow := this.LV.GetNext(lastRow)
			if (lastRow == 0)
				break
			wHandles.push(Integer(this.LV.GetText(lastRow, 2)))
		}
		if (wHandles.Length == 0)
			return
		for wHandle in arrayInReverse(wHandles)
			try WinActivate(wHandle)
	}

	; ------------------------- MENU FUNCTIONS -------------------------

	static menuHandler(itemName, itemPos?, menuObj?) {
		rowNFocused := this.LV.GetNext(0,"F")
		rowNums := []
		wHandles := []
		Loop {
			nextRow := this.LV.GetNext(A_Index == 1 ? 0 : rowNums[rowNums.Length])
			if (nextRow == 0)
				break
			rowNums.push(nextRow)
		}
		for i, cFunc in rowNums
			wHandles.push(Integer(this.LV.GetText(cFunc, 2)))
		static basicTasks := Map(
			"Reset Window Position", resetWindowPosition,
			"Minimize Window", 		WinMinimize,
			"Maximize Window", 		WinMaximize,
			"Restore Window", 		(wHandle) => this.isBorderlessFullscreen(wHandle) ? resetWindowPosition(wHandle, 5/7) : WinRestore(wHandle),
			"Move Windows to Monitor 1", resetWindowPosition.bind(,,1),
			"Move Windows to Monitor 2", resetWindowPosition.bind(,,2),
			"Toggle Window Lock", 	(wHandle) => (WinSetAlwaysOnTop(WinGetExStyle(wHandle) & 0x8 ? 0 : 1, wHandle)),
			"Set Window Lock", 		WinSetAlwaysOnTop.bind(true),
			"Remove Window Lock", 	WinSetAlwaysOnTop.bind(false),
			"Toggle Title Bar",		WinSetStyle.bind('^' this.windowStyles.WS_CAPTION),
			"Add Title Bar", 		WinSetStyle.bind("+" this.windowStyles.WS_CAPTION),
			"Remove Title Bar", 	WinSetStyle.bind("-" this.windowStyles.WS_CAPTION),
			"Toggle Visibility", 	(wHandle) => (WinGetStyle(wHandle) & this.windowStyles.WS_VISIBLE ? WinHide(wHandle) : WinShow(wHandle)),
			"Show Window", 			WinShow,
			"Hide Window", 			WinHide,
			"View Command Line", 	(wHandle) => (MsgBoxAsGui(this.winmgmt("CommandLine", "Where ProcessId = " . WinGetPID(wHandle))[1],,,,,,this.gui.hwnd,1)),
			"View Properties", 		(wHandle) => (Run('properties "' WinGetProcessPath(wHandle) '"')),
			"View Program Folder", 	(wHandle) => (Run('explorer.exe /select,"' . WinGetProcessPath(wHandle) . '"'))
		)
		if (basicTasks.Has(itemName)) {
			for wHandle in wHandles
				try basicTasks[itemName](wHandle)
		} else switch itemName {
			case "Activate Window":
				for wHandle in arrayInReverse(wHandles)
					try WinActivate(wHandle)
			case "Borderless Fullscreen":
				for wHandle in wHandles
					this.borderlessFullscreenWindow(wHandle)
			case "Close Window":
				if(wHandles.Length > 1 && MsgBoxAsGui("Are you sure you want to close " wHandles.Length " windows at once?", "Confirmation Prompt", 0x1,,1) == "Cancel")
					return
				rWH := arrayInReverse(wHandles)
				for wHandle in rWH
					try WinClose(wHandle)
				for i, wHandle in rWH
					if WinWaitClose(wHandle, , 0.5) {
						try this.LV.Delete(rowNums[rowNums.Length - i + 1])
						try objRemoveValue(this.data.currentWinInfo, wHandle,, (it, itVal, wHandle) => (itVal.hwnd == wHandle))
					}
			case "Copy Window Title":
				for i, wHandle in wHandles
					str .= (WinExist(wHandle) ? WinGetTitle(wHandle) : "") . (i == wHandles.Length ? "" : "`n")
				A_Clipboard := str
			case "View Window Text":
				for i, wHandle in wHandles {
					ctrls := WinGetControlsHwnd(wHandle)
					text .= "=== " WinGetTitle(wHandle) " ===`n"
					for i, ctrlHwnd in ctrls {
						if (ControlGetText(ctrlHwnd) != "")
							text .= "--- " ControlGetClassNN(ctrlHwnd) " ---: " ControlGetText(ctrlHwnd) "`n"
					}
				}
				MsgBoxAsGui(text,,,0,,,this.gui.hwnd,true)
			case "Change Window Transparency":
				this.transparencyGUI(wHandles)
			; this.winSubMenu.Add("Spread Windows on all Screens", this.menuHandler.Bind(this))
			; this.winSubMenu.Add("Spread Windows per Screen", this.menuHandler.Bind(this))
			case "Spread Windows":
				tileWindows(wHandles)
			default: ; custom functions
				if (this.menus.customFunctions.Has(itemName))
					for i, wHandle in wHandles
						try this.menus.customFunctions[itemName](wHandle)
		}
		; this.guiListviewCreate()
	}

	static transparencyGUI(wHandles) {
		tp := WinGetTransparent(wHandles[1])
		tp := (tp == "" ? 255 : tp)
		transparencyGUI := Gui("Border -SysMenu +Owner" this.gui.hwnd, "Transparency Menu")
		transparencyGUI.AddText("x10 w120 Center", "Change Transparency")
		transparencyGUI.AddSlider("x10 yp+20 AltSubmit Range0-255 NoTicks Page16 ToolTip", tp).OnEvent("Change", (obj, *) => (changeTransparency(obj.Value)))
		transparencyGUI.AddButton("x30 yp+30 w80 Default", "OK").OnEvent("Click", transparencyGUIClose)
		transparencyGUI.OnEvent("Escape", transparencyGUIClose)
		transparencyGUI.OnEvent("Close", transparencyGUIClose)
		this.applyColorScheme(transparencyGUI)
		this.gui.Opt("+Disabled")
		transparencyGUI.Show()

		changeTransparency(n) {
			for i, e in wHandles
				WinSetTransparent(n, e)
		}

		transparencyGUIClose(*) {
			for i, e in wHandles
			if (WinGetTransparent(e) == 255)
				WinSetTransparent("Off", e)
			this.gui.Opt("-Disabled")
			transparencyGUI.Destroy()
		}
	}

	static createSettingsGui(*) {
		this.gui.Opt("+Disabled")
		Hotkey(this.config.guiHotkey, "Off")
		sGui := Gui("+Border +OwnDialogs +Owner" this.gui.hwnd, "Settings")
		sGui.OnEvent("Escape", settingsGUIClose)
		sGui.OnEvent("Close", settingsGUIClose)
		sGui.SetFont("c0x000000") ; this is necessary to force font of checkboxes / groupboxes
		handler := this.configGuiHandler.bind(this)
		sGui.AddText("Center Section", "Settings for Window Manager")
		; color theme
		sGui.AddText("xs 0x200 R1.45", "GUI Color Theme:")
		sGui.AddDropDownList("vDDLColorTheme xs+260 yp r7 w125 Choose" . this.config.colorTheme + 1, ["Light Theme", "Dark Theme", "Custom Theme"]).OnEvent("Change", handler)
		; custom theme color
		sGui.AddText("xs 0x200 R1.45", "Custom theme color:")
		sGui.editCustomThemeColor := sGui.AddEdit("xs+225 yp vEditCustomThemeColor w70 Center", Format("0x{1:06X}", this.config.customThemeColor))
		sGui.editCustomThemeColor.OnEvent("Change", handler)
		sGui.editCustomThemeColor.OnEvent("LoseFocus", (ctrl, *) => ctrl.Value := this.config.customThemeColor)
		sGui.AddButton("xs+300 yp-1 vButtonCustomThemeColor w86", "Pick Color").OnEvent("Click", handler)
		; custom font color
		sGui.AddText("xs 0x200 R1.45", "Custom font color:")
		sGui.editCustomThemeFontColor := sGui.AddEdit("xs+225 yp vEditCustomThemeFontColor w70 Center", Format("0x{1:06X}", this.config.customThemeFontColor))
		sGui.editCustomThemeFontColor.OnEvent("Change", handler)
		sGui.editCustomThemeFontColor.OnEvent("LoseFocus", (ctrl, *) => ctrl.Value := this.config.customThemeFontColor)
		sGui.AddButton("xs+300 yp-1 vButtonCustomThemeFontColor w86", "Pick Color").OnEvent("Click", handler)
		
		; main hotkey
		sGui.AddText("xs R1.45", "Hotkey to open GUI:")
		sGui.AddHotkey("xs+210 yp vHotkeyOpenGui w175", this.config.guiHotkey).OnEvent("Change", handler)
		; filter case sense
		sGui.AddCheckbox("xs vCBFilterCaseSense Checked" this.config.filterCaseSense, "Case-sensitive search").OnEvent("Click", handler)
		; show HWNDs as Hex
		sGui.AddCheckbox("xs vCBFormatWindowHandles Checked" this.config.formatWindowHandles, "Display HWNDs as Hex Values").OnEvent("Click", handler)
		; pause updates while focused
		; update interval
		; blacklist (as a listview? idk)
		; debug
		sGui.AddCheckbox("xs vCBDebug Checked" this.config.debug, "Debugging mode").OnEvent("Click", handler)
		; reset settings
		sGui.AddButton("xs", "Reset Settings").OnEvent("Click", resetSettings)
		; hotkey (and general info)
		sGui.AddButton("xs+260 yp w125", "Help and Info").OnEvent("Click", tinyHotkeyInfoGui)
		this.settingsGui := sGui
		this.gui.GetPos(&gx, &gy)
		this.applyColorScheme(sGui)
		sGui.Show(Format("x{1}y{2} Autosize", gx + 100, gy + 60))
		return

		; updateInterval: 1000, ; in milliseconds, how often to update all info in the window
		; pauseUpdatesWhileFocused: true, ; whether to suspend updates while user has keyboard focus on a row
		; getCommandLine: 0,
		; blacklist: [
		; 	"Default IME",
		; 	"MSCTFIME UI",
		; 	"NVIDIA GeForce Overlay",
		; 	"Microsoft Text Input Application",
		; 	"Program Manager",
		; 	""
		; ]
		resetSettings(*) {
			if (MsgBoxAsGui("Are you sure? This will reset all settings to their default values.", "Reset Settings", 0x1, 2, true,, sGui.Hwnd) == "Cancel")
				return
			useConfig := this.config.useConfig
			this.config := this.defaultConfig
			this.config.useConfig := useConfig
			settingsGUIClose()
			this.createSettingsGui()
			this.applyColorScheme()
			if (this.config.useConfig)
				this.configManager("Save")
		}

		settingsGUIClose(*) {
			this.gui.Opt("-Disabled")
			Hotkey(this.config.guiHotkey, "On")
			this.settingsGui.Destroy()
			this.settingsGui := 0
			WinActivate(this.gui)
		}

		tinyHotkeyInfoGui(*) {
			MsgBoxAsGui("poggies")
		}
	}

	static configGuiHandler(ctrl, *) {
		switch ctrl.Name {
			case "DDLColorTheme":
				this.config.colorTheme := ctrl.Value - 1 ; ctrl is 1, 2, 3, we want 0, 1, 2
				this.applyColorScheme()
			case "CBDebug":
				this.config.debug := ctrl.Value
				this.menus := this.buildContextMenu()
			case "CBFilterCaseSense":
				this.config.filterCaseSense := ctrl.Value
				if (this.gui["EditFilterWindows"].Value != "")
					this.guiListviewCreate(false, false, false)
			case "CBFormatWindowHandles":
				this.config.formatWindowHandles := !this.config.formatWindowHandles
				this.guiListviewCreate(true)
			case "CBHiddenWindows":
				this.config.detectHiddenWindows := !this.config.detectHiddenWindows
				this.guiListviewCreate(true)
			case "CBExcludedWindows":
				this.config.useBlacklist := !this.config.useBlacklist
				this.guiListviewCreate(true)
			case "CBGetCommandLine":
				this.config.getCommandLine := !this.config.getCommandLine
				if (this.config.getCommandLine)
					this.LV.ModifyCol(13, "0")
				this.guiListviewCreate(true)
			case "EditCustomThemeColor", "EditCustomThemeFontColor":
				property := SubStr(ctrl.Name, 5)
				color := ctrl.Value
				if (!InStr(color, "0x"))
					color := "0x" . color
				if (!RegExMatch(color, "^0x[[:xdigit:]]{1,6}$"))
					return
				color := Format("0x{1:06X}", color)
				this.config.%property% := color
				ctrl.Opt("+Background" this.config.%property%)
				ctrl.SetFont(isDark(this.config.%property%) ? "c0xFFFFFF" : "c0x000000")
				if (this.config.colorTheme == 2)
					this.applyColorScheme()
			case "ButtonCustomThemeColor", "ButtonCustomThemeFontColor":
				property := SubStr(ctrl.Name, 7)
				editName := "edit" . property
				color := colorDialog(this.config.%property%, ctrl.gui.hwnd, true, this.colors.DARK, this.config.customThemeColor, this.config.customThemeFontColor)
				if (color == -1)
					return
				this.config.%property% := Format("0x{1:06X}", color)
				ctrl.gui.%editName%.Text := Format("0x{1:06X}", this.config.%property%)
				if (this.config.colorTheme == 2)
					this.applyColorScheme()
				else {
					ctrl.gui.%editName%.Opt("+Background" this.config.%property%)
					ctrl.gui.%editName%.SetFont(isDark(this.config.%property%) ? "c0xFFFFFF" : "c0x000000")
				}
			case "HotkeyOpenGui":
				hkey := ctrl.Value
				if (RegExReplace(hkey, "\!|\^|\+") == "" || hkey == this.config.guiHotkey)
					return
				try
					Hotkey(hkey, this.guiCreate.bind(this))
				catch Error {
					MsgBox("Specified Hotkey already in use (or a different error occured. Try a different one)")
					return
				}
				Hotkey(hkey, "Off")
				if (A_LineFile == A_ScriptFullPath)
					A_TrayMenu.Rename("Open Window Manager (" this.config.guiHotkey ")", "Open Window manager (" hkey ")")
				else
					TrayMenu.submenus["GUIs"].Rename("Open Window Manager (" this.config.guiHotkey ")", "Open Window Manager (" hkey ")")
				this.config.guiHotkey := hkey
			default:
				return
				; throw (Error("This setting doesn't exist (yet): " . ctrl.Name))
		}
		if (this.config.useConfig)
			this.configManager("Save")
	}

	static configManager(mode := "Save") {
		mode := Substr(mode, 1, 1)
		if (!Instr(FileExist(this.appdataPath), "D"))
			DirCreate(this.appdataPath)
		configPath := this.appdataPath "\config.json"
		if (mode == "S") {
			f := FileOpen(configPath, "w", "UTF-8")
			f.Write(jsongo.Stringify(this.config, , "`t"))
			f.Close()
			return 1
		}
		else if (mode == "L") {
			this.config := {}, config := Map()
			if (FileExist(configPath))
				try config := jsongo.Parse(FileRead(configPath, "UTF-8"))
			; remove unused config values
			for i, e in config
				if (this.defaultConfig.HasOwnProp(i))
					this.config.%i% := e
			; populate unset config values with defaults
			for i, e in this.defaultConfig.OwnProps()
				if !(this.config.HasOwnProp(i))
					this.config.%i% := e
			return 1
		}
		return 0
	}
	
	static buildContextMenu() {
		menus := {}
		menus.menu := Menu()
		menus.subMenu := Menu()
		menus.customFunctions := Map()
		for cFunc in this.customFunctions ; define custom function map
			menus.customFunctions[cFunc] := %cFunc%
		menus.MenuFunctionNames := [
			"Activate Window", "Reset Window Position", "Minimize Window", "Maximize Window",
			"Borderless Fullscreen", "Restore Window", "Close Window",
			0,
			"Copy Window Title", "View Command Line", "View Window Text", "View Properties", "View Program Folder"
		]
		menus.subMenuFunctionNames := [
			"Change Window Transparency", "Move Windows to Monitor 1", "Move Windows to Monitor 2", "Move Windows to Position", "Spread Windows", "Spread Windows on all Screens", "Spread Windows per Screen"]
		menus.subMenuToggles := [
			["Toggle Window Lock", "Set Window Lock", "Remove Window Lock"],
			["Toggle Title Bar", "Add Title Bar", "Remove Title Bar"],
			["Toggle Visibility", "Hide Window", "Show Window"]
		]
		handler := this.menuHandler.Bind(this)
		for toggle in menus.subMenuToggles {
			toggleMenu := Menu()
			toggleMenu.Add(toggle[1], handler)
			toggleMenu.Add(toggle[2], handler)
			toggleMenu.Add(toggle[3], handler)
			toggleMenu.Default := toggle[1]
			menus.submenu.Add(toggle[1], toggleMenu)
		}
		for fName in menus.subMenuFunctionNames ; add submenu standard functions
			menus.submenu.Add(fName, handler)
		menus.submenu.Add() ; add submenu separator
		for fName, cFunc in menus.customFunctions ; add submenu custom functions
			menus.submenu.Add(fName, handler)
		for fName in menus.MenuFunctionNames ; add menu functions
			menus.menu.Add(fName ? fName : unset, fName ? handler : unset)
		menus.menu.Insert(objContainsValue(menus.MenuFunctionNames, 0) . "&", "Other Options", menus.submenu)
		if (this.config.debug) {
			menus.menu.add()
			; add debug options here
		}
		return menus
	}

	static defaultConfig => {
		useConfig: true,
		debug: false,
		guiHotkey: "^F11", ; hotkey to open GUI (always)
		colorTheme: 2, ; 0 = white, 1 = dark, 2 = custom
		customThemeColor: "0x002b36",
		customThemeFontColor: "0x109698",
		filterCaseSense: false, ; for searching/filtering, 
		formatWindowHandles: true,
		updateInterval: 1000, ; in milliseconds, how often to update all info in the window
		pauseUpdatesWhileFocused: true, ; whether to suspend updates while user has keyboard focus on a row
		getCommandLine: 0,
		detectHiddenWindows: 0,
		useBlacklist: 1,
		blacklist: [
			"",
			"NVIDIA GeForce Overlay",
			"ahk_class MultitaskingViewFrame ahk_exe explorer.exe",
			"ahk_class Windows.UI.Core.CoreWindow",
			"ahk_class WorkerW ahk_exe explorer.exe",
			"ahk_class Progman ahk_exe explorer.exe",
			"ahk_class Shell_TrayWnd ahk_exe explorer.exe",
			"ahk_class Shell_SecondaryTrayWnd ahk_exe explorer.exe",
			; "Microsoft Text Input Application",
			; "Default IME",
			; "MSCTFIME UI"
		]
	}

	static windowStyles => {
		WS_BORDER: 0x800000,
		WS_POPUP: 0x80000000,
		WS_CAPTION: 0xC00000,
		WS_CLIPSIBLINGS: 0x4000000,
		WS_DISABLED: 0x8000000,
		WS_DLGFRAME: 0x400000,
		WS_GROUP: 0x20000,
		WS_HSCROLL: 0x100000,
		WS_MAXIMIZE: 0x1000000,
		WS_MAXIMIZEBOX: 0x10000,
		WS_MINIMIZE: 0x20000000,
		WS_MINIMIZEBOX: 0x20000,
		WS_OVERLAPPED: 0x0,
		WS_OVERLAPPEDWINDOW: 0xCF0000,
		WS_POPUPWINDOW: 0x80880000,
		WS_SIZEBOX: 0x40000,
		WS_SYSMENU: 0x80000,
		WS_TABSTOP: 0x10000,
		WS_THICKFRAME: 0x40000,
		WS_VSCROLL: 0x200000,
		WS_VISIBLE: 0x10000000,
		WS_CHILD: 0x40000000
	}

	static windowExStyles => {
		WS_EX_TOPMOST: 0x8
	}
	
	static appdataPath => A_AppData "\Autohotkey\WindowManager"
	static colors => {
		DARK: "0x1E1E1E",
		BLACK: "0x000000",
		WHITE: "0xFFFFFF"
	}
}

class DesktopState {
	static __New() {
		this.timer := this.save.bind(this)
		this.prevState := []
		this.customStates := Map()
	}

	static enable(period := 20000) {
		this.save()
		SetTimer(this.timer, period)
	}

	static disable() {
		SetTimer(this.timer, 0)
	}

	static save(custom?) {
		if (IsSet(custom))
			this.customStates[custom] := WindowManager.getAllWindowInfo(0, 1)
		else
			this.prevState := WindowManager.getAllWindowInfo(0, 1)
	}

	static restore(custom?) {
		for i, e in (IsSet(custom) ? this.customStates[custom] : this.prevState) {
			if (!WinExist(e.hwnd))
				continue
			try {
				if (e.state == -1)
					WinMinimize(e.hwnd)
				else if (e.state == 1)
					WinMaximize(e.hwnd)
				else
					WinMove(e.xpos, e.ypos, e.width, e.height, e.hwnd)
			}
			catch OSError as err {
				logString .= "Failed updating hwnd " e.hwnd ": " WinGetTitle(e.hwnd) . " with reason `"" err.Message "`" in function " err.What "`n"
			}
		}
		if (IsSet(logString))
			MsgBoxAsGui(logString)
	}
}