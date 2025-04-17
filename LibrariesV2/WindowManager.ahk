; https://github.com/cobracrystal/ahk
; TODO 3: Add Settings for excluded windows (with editable list, like in PATH native settings), automatically form that into regex
; needs to check if window is in admin mode, else most commands fail (eg winsettransparent). Also add button for that in settings
; add rightclick menu option to show command line only for this window
; add search that allows default ahk syntax via "wintitle ahk_exe test.exe"
#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\jsongo.ahk"

; Usage:
; ^+F11::WindowManager.windowManager("T")

/*
hotkeys: 
F5 to refresh view
Enter to activate
Del to close window
shift+del to forcefully close window (skipping warnings etc)
ctrl+C to copy window title
ctrl+shift+c to copy all window data in json format
*/

class WindowManager {
	static windowManager(mode := "O", *) {
		mode := SubStr(mode, 1, 1)
		if (WinExist(this.gui)) {
			if (mode == "O")
				WinActivate(this.gui.hwnd)
			else {
				this.settings.coords := windowGetCoordinates(this.gui.hwnd)
				this.settings.coords[7] := (this.settings.coords[7] == 3 ? 1 : (this.settings.coords[7] == 2 ? -1 : 0))
				this.gui.destroy()
				this.gui := -1
			}
		}
		else if (mode != "C")
			this.guiCreate()
	}

	;------------------------------------------------------------------------

	static __New() {
		; Tray Menu
		guiMenu := TrayMenu.submenus["GUIs"]
		guiMenu.Add("Open Window Manager", this.windowManager.Bind(this))
		A_TrayMenu.Add("GUIs", guiMenu)
		; window menu
		winMenu := Menu()
		winMenu.Add("Activate Window", this.menuHandler.Bind(this))
		winMenu.Add("Reset Window Position", this.menuHandler.Bind(this))
		winMenu.Add("Minimize Window", this.menuHandler.Bind(this))
		winMenu.Add("Maximize Window", this.menuHandler.Bind(this))
		winMenu.Add("Borderless Fullscreen", this.menuHandler.Bind(this))
		winMenu.Add("Restore Window", this.menuHandler.Bind(this))
		winMenu.Add("Close Window", this.menuHandler.Bind(this))
		winMenu.Add("Toggle Lock Status", this.menuHandler.Bind(this))
		winMenu.Add()
		winMenu.Add("Change Window Transparency", this.menuHandler.Bind(this))
		winMenu.Add("Copy Window Title", this.menuHandler.Bind(this))
		winMenu.Add("View Properties", this.menuHandler.Bind(this))
		winMenu.Add("View Program Folder", this.menuHandler.Bind(this))
		this.menu := winMenu
		; init class variables
		this.gui := -1
		this.settings := {
			coords: [300, 200, 1022, 432, 1000, 400, 0],
			showExcludedWindows: 0,
			detectHiddenWindows: 0,
			getCommandLine: 0,
			darkMode: 1,
			darkThemeColor: SubStr("c0x002b36", 2),
			darkThemeFontColor: SubStr("c0x109698",2),
			excludeWindowsRegex: "i)(?:ZPToolBarParentWnd|Default IME|MSCTFIME UI|NVIDIA GeForce Overlay|Microsoft Text Input Application|Program Manager|^$)"
		}
	}

	static guiCreate() {
		this.gui := Gui("+OwnDialogs +Resize", "Window Manager")
		this.gui.OnEvent("Close", (*) => this.windowManager("Close"))
		this.gui.OnEvent("Escape", (*) => this.windowManager("Close"))
		this.gui.OnEvent("Size", this.onResize.bind(this))
		this.gui.SetFont("c0x000000") ; this is necessary to force font of checkboxes / groupboxes
		this.gui.AddCheckbox("Section vCheckboxHiddenWindows Checked" . this.settings.detectHiddenWindows, "Show Hidden Windows?").OnEvent("Click", this.settingCheckboxHandler.bind(this))
		this.gui.AddCheckbox("ys vCheckboxExcludedWindows Checked" . this.settings.showExcludedWindows, "Show Excluded Windows?").OnEvent("Click", this.settingCheckboxHandler.bind(this))
		this.gui.AddCheckbox("ys vCheckboxGetCommandLine Checked" . this.settings.getCommandLine, "Show Command Lines? (Slow)").OnEvent("Click", this.settingCheckboxHandler.bind(this))
		this.gui.AddEdit("ys vEditFilterWindows").OnEvent("Change", this.guiListviewCreate.bind(this, false, false))
		this.gui.AddText("ys xs+890 w110 vWindowCount", "Window Count: 0")
		this.LV := this.gui.AddListView("xs R20 w1000 +Multi", ["handle", "ahk_title", "Process", "mmx", "xpos", "ypos", "width", "height", "ahk_class", "PID", "Process Path", "Command Line"])
		this.LV.OnNotify(-155, this.onKeyPress.bind(this))
		this.LV.OnEvent("ContextMenu", this.onContextMenu.bind(this))
		this.LV.OnEvent("DoubleClick", (obj, rowN) => rowN == 0 ? 0 : WinActivate(Integer(obj.GetText(rowN, 1))))
		this.gui.AddButton("Default Hidden", "A").OnEvent("Click", this.activateButton.bind(this))
		;	this.LV.OnEvent("ColClick", this.onColClick.bind(this)) ; store sorting state for refresh?
		this.guiListviewCreate(true, true)
		if (this.settings.darkMode)
			this.toggleGuiDarkMode(this.settings.darkMode)
		this.insertWindowInfo(this.gui.Hwnd, 1) ;// inserts the first row to be about the windowManager itself
		this.gui.Show(Format("x{1}y{2}w{3}h{4} {5}", this.settings.coords[1], this.settings.coords[2], this.settings.coords[3] - 2 - 14, this.settings.coords[4] - 32 - 7, this.settings.coords[7] == 1 ? "Maximize" : "Restore"))
		this.LV.Focus()
	}

	; this function was frankenstein'd by combining things from a variety of different people that are too numerous to name
	static toggleGuiDarkMode(dark) {
		static WM_THEMECHANGED := 0x031A
		; // title bar dark
		if (VerCompare(A_OSVersion, "10.0.17763")) {
			attr := 19
			if (VerCompare(A_OSVersion, "10.0.18985")) {
				attr := 20
			}
			if (dark)
				DllCall("dwmapi\DwmSetWindowAttribute", "ptr", this.gui.hwnd, "int", attr, "int*", true, "int", 4)
			else
				DllCall("dwmapi\DwmSetWindowAttribute", "ptr", this.gui.hwnd, "int", attr, "int*", false, "int", 4)
		}
		this.gui.BackColor := (dark ? this.settings.darkThemeColor : "Default") ; "" <-> "Default" <-> 0xFFFFFF
		font := (dark ? "c" this.settings.darkThemeFontColor : "cDefault")
		this.gui.SetFont(font)
		for cHandle, ctrl in this.gui {
			ctrl.Opt(dark ? "+Background" this.settings.darkThemeColor : "-Background")
			ctrl.SetFont(font)
			if (ctrl is Gui.Button || ctrl is Gui.ListView) {
				; todo: listview headers dark -> https://www.autohotkey.com/boards/viewtopic.php?t=115952
				; and https://www.autohotkey.com/board/topic/76897-ahk-u64-issue-colored-text-in-listview-headers/
				; maybe https://www.autohotkey.com/boards/viewtopic.php?t=87318
				DllCall("uxtheme\SetWindowTheme", "ptr", ctrl.hwnd, "str", (dark ? "DarkMode_Explorer" : ""), "ptr", 0)
			}
		}
		; todo: setting to make this look like this ? 
		; DllCall("uxtheme\SetWindowTheme", "ptr", this.LV.hwnd, "str", "Explorer", "ptr", 0)
	}

	static guiListviewCreate(redraw := false, first := false, guiCtrl := false, *) {
		this.gui.Opt("+Disabled")
		this.LV.Opt("-Redraw")
		this.LV.Delete()
		static winInfo := []
		if (!guiCtrl)
			winInfo := this.getAllWindowInfo(this.settings.detectHiddenWindows, this.settings.showExcludedWindows)
		for i, win in winInfo
			if (this.isIncludedInSearch(win))
				this.LV.Add(, win.hwnd, win.title, win.process, win.state, win.xpos, win.ypos, win.width, win.height, win.class, win.pid, win.processPath, win.commandLine)
		this.gui["WindowCount"].Value := Format("Window Count: {:5}", this.LV.GetCount() + (first ? 1 : 0))
		if (this.LV.GetCount() == 0)
			this.LV.Add("", "/", "Nothing Found.")
		if (first) {
			Loop (5)
				this.LV.ModifyCol(A_Index + 3, "+Integer")
			this.LV.ModifyCol(1, "+Integer")
			this.LV.ModifyCol(10, "+Integer")
		}
		if (redraw) {
			Loop (this.LV.GetCount("Col"))
				this.LV.ModifyCol(A_Index, "+AutoHdr")
		}
		this.LV.Opt("+Redraw")
		this.gui.Opt("-Disabled")
	}

	static isIncludedInSearch(win) {
		search := this.gui["EditFilterWindows"].Value
		if (search == "")
			return true
		for i, e in win.OwnProps()
			if (InStr(e, search))
				return true
		return false
	}

	static insertWindowInfo(wHandle, rowN) {
		t := this.getWindowInfo(wHandle) 
		this.LV.Insert(rowN, , t.hwnd, t.title, t.process, this.settings.coords[7], this.settings.coords[1], this.settings.coords[2], this.settings.coords[3], this.settings.coords[4], t.class, t.pid, t.processPath, t.commandLine)
	}

	static getAllWindowInfo(getHidden := false, notExclude := false) {
		windows := []
		tMM := A_TitleMatchMode
		dHW := A_DetectHiddenWindows
		SetTitleMatchMode("RegEx")
		DetectHiddenWindows(getHidden)
		if (notExclude)
			wHandles := WinGetList()
		else
			wHandles := WinGetList(, , this.settings.excludeWindowsRegex)
		for i, wHandle in wHandles
			windows.push(this.getWindowInfo(wHandle))
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
			if (this.settings.getCommandLine)
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

	static winmgmt(v, w, d := "Win32_Process", m := "winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2") {
		local i, s := []
		for i in ComObjGet(m).ExecQuery("Select " . (IsSet(v) ? v : "*") . " from " . d . (IsSet(w) ? " " . w : ""))
			s.push(i.%v%)
		return (s.length > 0 ? s : [""])
	}

	static onResize(gui, mmx, w, h) {
		if (mmx == -1) ; minimized
			return
		this.LV.Move(,,w-20,h-35)
		this.gui["WindowCount"].Move(w-111)
	}

	static onContextMenu(ctrlObj, rowN, isRightclick, x, y) {
		if (rowN == 0)
			return
		wHandle := Integer(ctrlObj.GetText(rowN, 1))
		if (!WinExist(wHandle)) {
			this.LV.Delete(rowN)
			return
		}
		if (WinGetExStyle(wHandle) & 0x8)
			this.menu.Check("Toggle Lock Status")
		else
			this.menu.Uncheck("Toggle Lock Status")
		this.menu.show()
	}

	static onKeyPress(ctrlObj, lParam) {
		vKey := NumGet(lParam, 24, "ushort")
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
		for i, e in rowNums
			wHandles.push(Integer(this.LV.GetText(e, 1)))
		DetectHiddenWindows(this.settings.detectHiddenWindows)
		switch vKey {
			case "46": 	;// Del/Entf Key -> Close that window
				if (GetKeyState("Shift"))
					flagKill := true
				if(wHandles.Length > 1 && MsgBox("Are you sure you want to close " wHandles.Length " windows at once?", "Confirmation Prompt", 0x1) == "Cancel")
					return
				for i, wHandle in reverseArray(wHandles) {
					try {
						if (flagKill ?? false)
							WinKill(wHandle)
						else
							WinClose(wHandle)
					}
					if WinWaitClose(wHandle, , 0.5)
						try this.LV.Delete(rowNums[rowNums.Length - i + 1])
				}
			case "65": ; ctrl A
				if (!GetKeyState("Ctrl"))
					return
				offset := GetKeyState("Shift") ? 0 : 1
				if (offset)
					this.LV.Modify(1, "-Select")
				Loop this.LV.GetCount() - offset
					this.LV.Modify(A_Index + offset, "+Select")
			case "67": ; ctrl C
				if (!GetKeyState("Ctrl"))
					return
				if !GetKeyState("Shift") {
					for i, wHandle in wHandles
						str .= (WinExist(wHandle) ? WinGetTitle(wHandle) : "") . (i == wHandles.Length ? "" : "`n")
					A_Clipboard := str
				}
				else {
					wInfoArray := []
					for i, wHandle in wHandles {
						wInfo := this.getWindowInfo(wHandle)
						if !(this.settings.getCommandLine)
							wInfo.DeleteProp("commandLine")
						wInfoArray.push(wInfo)
					}
					A_Clipboard := jsongo.Stringify(wInfoArray, , "`t")
					; Loop(this.LV.GetCount("Col"))
					; 	str .= this.LV.GetText(rowN, A_Index) "`t"
				}
			case "116":	;// F5 Key -> Refresh LV
				this.guiListviewCreate()
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
			wHandles.push(Integer(this.LV.GetText(lastRow, 1)))
		}
		if (wHandles.Length == 0)
			return
		for i, wHandle in reverseArray(wHandles)
			try WinActivate(wHandle)
	}
	

	static settingCheckboxHandler(guiCtrlObj, *) {
		switch guiCtrlObj.Name {
			case "CheckboxHiddenWindows":
				this.settings.detectHiddenWindows := !this.settings.detectHiddenWindows
			case "CheckboxExcludedWindows":
				this.settings.showExcludedWindows := !this.settings.showExcludedWindows
			case "CheckboxGetCommandLine":
				this.settings.getCommandLine := !this.settings.getCommandLine
				if (this.settings.getCommandLine)
					this.LV.ModifyCol(12, "0")
			default:
				return
		}
		this.guiListviewCreate(true)
	}

	; ------------------------- MENU FUNCTIONS -------------------------

	static menuHandler(itemName, itemPos, menuObj) {
		rowNFocused := this.LV.GetNext(0,"F")
		rowNums := []
		wHandles := []
		Loop {
			nextRow := this.LV.GetNext(A_Index == 1 ? 0 : rowNums[rowNums.Length])
			if (nextRow == 0)
				break
			rowNums.push(nextRow)
		}
		for i, e in rowNums
			wHandles.push(Integer(this.LV.GetText(e, 1)))
		switch itemName {
			case "Activate Window":
				for i, wHandle in reverseArray(wHandles)
					try WinActivate(wHandle)
			case "Reset Window Position":
				for i, wHandle in wHandles {
					try {
						mmx := WinGetMinMax(wHandle)
						WinGetPos(, , &w, &h, wHandle)
						WinRestore(wHandle)
						WinMove(A_ScreenWidth / 2 - w / 2, A_ScreenHeight / 2 - h / 2, , , wHandle)
						WinActivate(wHandle)
					}
				}
			case "Minimize Window":
				for i, wHandle in wHandles
					try WinMinimize(wHandle)
			case "Maximize Window":
				for i, wHandle in wHandles
					try WinMaximize(wHandle)
			case "Borderless Fullscreen":
				for i, wHandle in wHandles {
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
			case "Restore Window":
				for i, wHandle in wHandles
					try WinRestore(wHandle)
			case "Close Window":
				if(wHandles.Length > 1 && MsgBox("Are you sure you want to close " wHandles.Length " windows at once?", "Confirmation Prompt", 0x1) == "Cancel")
					return
				for i, wHandle in reverseArray(wHandles) {
					try WinClose(wHandle)
					if WinWaitClose(wHandle, , 0.5)
						this.LV.Delete(rowNums[rowNums.Length - i + 1])
				}
			case "Toggle Lock Status":
				for i, wHandle in reverseArray(wHandles) {
					try {
						tStyle := WinGetExStyle(wHandle)
						WinSetAlwaysOnTop(tStyle & 0x8 ? 0 : 1, wHandle) ; 0x8 is WS_EX_TOPMOST
					}
				}
			case "Change Window Transparency":
				this.transparencyGUI(wHandles)
			case "Copy Window Title":
				for i, wHandle in wHandles
					str .= (WinExist(wHandle) ? WinGetTitle(wHandle) : "") . (i == wHandles.Length ? "" : "`n")
				A_Clipboard := str
			case "View Properties":
				for i, wHandle in wHandles
					try Run('properties "' WinGetProcessPath(wHandle) '"')
			case "View Program Folder":
				for i, wHandle in wHandles
					try Run('explorer.exe /select,"' . WinGetProcessPath(wHandle) . '"')
			default:
				return
		}
	}

	static transparencyGUI(wHandles) {
		tp := WinGetTransparent(wHandles[1])
		tp := (tp == "" ? 255 : tp)
		transparencyGUI := Gui("Border -SysMenu +Owner" this.gui.hwnd, "Transparency Menu")
		transparencyGUI.AddText("x32", "Change Transparency")
		transparencyGUI.AddSlider("x10 yp+20 AltSubmit Range0-255 NoTicks Page16 ToolTip", tp).OnEvent("Change", (obj, *) => (changeTransparency(obj.Value)))
		transparencyGUI.AddButton("w80 yp+30 xp+20 Default", "OK").OnEvent("Click", transparencyGUIClose)
		transparencyGUI.OnEvent("Escape", transparencyGUIClose)
		transparencyGUI.OnEvent("Close", transparencyGUIClose)
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
}

class DesktopState {
	static __New() {
		this.timer := this.save.bind(this)
	}

	static enable(period := 60000) {
		this.prevState := []
		this.save()
		SetTimer(this.timer, period)
	}

	static disable() {
		SetTimer(this.timer, 0)
	}

	static save() {
		this.prevState := WindowManager.getAllWindowInfo(0, 0)
	}

	static restore() {
		for i, e in this.prevState {
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
			msgbox(logString)
	}
}