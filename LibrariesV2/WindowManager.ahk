; https://github.com/cobracrystal/ahk
; TODO 3: Add Settings for excluded windows (with editable list, like in PATH native settings), automatically form that into regex
; needs to check if window is in admin mode, else most commands fail (eg winsettransparent). Also add button for that in settings
; add rightclick menu option to show command line only for this window
; add search that allows default ahk syntax via "wintitle ahk_exe test.exe"
#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\jsongo.ahk"
#Include "*i A_LineFile%\..\..\LibrariesV2\CustomWindowFunctions.ahk"
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
				this.settings.coords.mmx := (this.settings.coords.mmx == 3 ? 1 : (this.settings.coords.mmx == 2 ? -1 : 0))
				this.gui.destroy()
				this.gui := -1
			}
		}
		else if (mode != "C")
			this.guiCreate()
	}

	;------------------------------------------------------------------------

	static __New() {
		CUSTOM_FUNCTIONS := [vlcMinimalViewingMode]
		; Tray Menu
		guiMenu := TrayMenu.submenus["GUIs"]
		guiMenu.Add("Open Window Manager", this.windowManager.Bind(this))
		A_TrayMenu.Add("GUIs", guiMenu)
		; window menu
		this.menus := {}
		this.menus.menu := Menu()
		this.menus.subMenu := Menu()
		this.menus.customFunctions := Map()
		for cFunc in CUSTOM_FUNCTIONS ; define custom function map
			this.menus.customFunctions[cFunc.Name] := cFunc
		this.menus.MenuFunctionNames := [
			"Activate Window", "Reset Window Position", "Minimize Window", "Maximize Window",
			"Borderless Fullscreen", "Restore Window", "Close Window",
			0,
			"Copy Window Title", "View Properties", "View Program Folder"
		]
		this.menus.SubMenuFunctionNames := [
			"Change Window Transparency", "Move Windows to Monitor 1", "Move Windows to Monitor 2", "Spread Windows on all Screens", "Spread Windows per Screen"]
		this.menus.subMenuToggles := [
			["Toggle Window Lock", "Set Window Lock", "Remove Window Lock"],
			["Toggle Title Bar", "Add Title Bar", "Remove Title Bar"],
			["Toggle Visibility", "Hide Window", "Show Window"]
		]
		handler := this.menuHandler.Bind(this)
		for toggle in this.menus.subMenuToggles {
			toggleMenu := Menu()
			toggleMenu.Add(toggle[1], handler)
			toggleMenu.Add(toggle[2], handler)
			toggleMenu.Add(toggle[3], handler)
			toggleMenu.Default := toggle[1]
			this.menus.submenu.Add(toggle[1], toggleMenu)
		}
		for fName in this.menus.SubMenuFunctionNames ; add submenu standard functions
			this.menus.submenu.Add(fName, handler)
		this.menus.submenu.Add() ; add submenu separator
		for fName, cFunc in this.menus.customFunctions ; add submenu custom functions
			this.menus.submenu.Add(fName, handler)
		for fName in this.menus.MenuFunctionNames ; add menu functions
			this.menus.menu.Add(fName ? fName : unset, fName ? handler : unset)
		this.menus.menu.Insert(objContainsValue(this.menus.MenuFunctionNames, 0) . "&", "Other Options", this.menus.submenu)
		HotIfWinactive("Window Manager ahk_class AutoHotkeyGUI")
		Hotkey("^f", (*) => (this.gui["EditFilterWindows"].Focus()))
		Hotkey("^d", (*) => (this.LV.Focus()))
		Hotkey("^BackSpace", (*) => Send("^+{Left}{Delete}"))
		HotIfWinactive()
		; init class variables
		this.gui := -1
		this.settings := {
			coords: {x: 300, y: 200, w: 1022, h: 432, mmx: 0},
			excludeWindows: 1,
			detectHiddenWindows: 0,
			getCommandLine: 0,
			darkMode: 1,
			darkThemeColor: "0x002b36",
			darkThemeFontColor: "0x109698",
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
		this.gui.AddCheckbox("ys vCheckboxExcludedWindows Checked" . !this.settings.excludeWindows, "Show Excluded Windows?").OnEvent("Click", this.settingCheckboxHandler.bind(this))
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
		this.gui.Show(Format("x{1}y{2}w{3}h{4} {5}", this.settings.coords.x, this.settings.coords.y, this.settings.coords.w - 2 - 14, this.settings.coords.h - 32 - 7, this.settings.coords.mmx == 1 ? "Maximize" : "Restore"))
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
			DllCall("dwmapi\DwmSetWindowAttribute", "ptr", this.gui.hwnd, "int", attr, "int*", dark ? true : false, "int", 4)
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
	}

	static guiListviewCreate(redraw := false, firstCall := false, guiCtrl := false, *) {
		this.gui.Opt("+Disabled")
		this.LV.Opt("-Redraw")
		this.LV.Delete()
		static winInfo := []
		if (!guiCtrl) {
			winInfo := this.getAllWindowInfo(this.settings.detectHiddenWindows, this.settings.excludeWindows)
			if (firstCall)
				winInfo.InsertAt(1, this.getWindowInfo(this.gui.Hwnd))
		}
		for i, win in winInfo
			if (this.isIncludedInSearch(win))
				this.LV.Add(, win.hwnd, win.title, win.process, win.state, win.xpos, win.ypos, win.width, win.height, win.class, win.pid, win.processPath, win.commandLine)
		this.gui["WindowCount"].Value := Format("Window Count: {:5}", this.LV.GetCount())
		if (firstCall)
			for i in [1, 4, 5, 6, 7, 8, 10]
				this.LV.ModifyCol(i, "+Integer")
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
		tags := ["handle", "title", "process", "mmx", "x", "xpos", "y", "ypos", "w", "width", "h", "height", "class", "pid", "path", "cmd", "command", "commandline"]
		tagMap := Map(
			"handle", "hwnd", "title", "title",	"process", "process", "mmx", "state",
			"x", "xpos", "xpos", "xpos", "y", "ypos", "ypos", "ypos", "w", "width", "width", "width", "h", "height", "height", "height",
			"class", "class", "pid", "pid", "path", "processPath", "cmd", "commandLine", "command", "commandLine", "commandline", "commandLine"
		)
		searches := Map()
		for tag in tags {
			RegexMatch(search, "(?:^|\s)" tag . ":([^\s]+)", &o)
			if (o) {
				searches[tag] := o[1]
				search := RegExReplace(search, "\s*" tag . ":[^\s]+\s*")
			}
		}
		freeSearch := search
		flagInclude := true
		for tag, search in searches
			if (tagMap.Has(tag) && !InStr(win.%tagMap[tag]%, search))
				return false
		if freeSearch == ""
			return true
		for i, e in win.OwnProps()
			if (InStr(e, freeSearch))
				return true
		return false
	}

	static getAllWindowInfo(getHidden := false, exclude := true) {
		windows := []
		tMM := A_TitleMatchMode
		dHW := A_DetectHiddenWindows
		SetTitleMatchMode("RegEx")
		DetectHiddenWindows(getHidden)
		if (exclude)
			wHandles := WinGetList(, , this.settings.excludeWindowsRegex)
		else
			wHandles := WinGetList()
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
		if (WinGetExStyle(wHandle) & this.windowExStyles.WS_EX_TOPMOST)
			this.menus.submenu.Check("Toggle Window Lock")
		else
			this.menus.submenu.Uncheck("Toggle Window Lock")
		if (WinGetStyle(wHandle) & this.windowStyles.WS_CAPTION)
			this.menus.submenu.Check("Toggle Title Bar")
		else
			this.menus.submenu.Uncheck("Toggle Title Bar")
		if (WinGetStyle(wHandle) & this.windowStyles.WS_VISIBLE)
			this.menus.submenu.Check("Toggle Visibility")
		else
			this.menus.submenu.Uncheck("Toggle Visibility")
		this.menus.menu.show()
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
				rWH := reverseArray(wHandles)
				for i, wHandle in rWH {
					try {
						if (flagKill ?? false)
							WinKill(wHandle)
						else
							WinClose(wHandle)
					}
				}
				for i, wHandle in rWH
					if WinWaitClose(wHandle, , 0.5)
						try this.LV.Delete(rowNums[rowNums.Length - i + 1])
			case "65": ; ctrl A
				if (!GetKeyState("Ctrl"))
					return
				guiRowIndex := 0
				if !GetKeyState("Shift")
					Loop(this.LV.GetCount())
						if (this.LV.GetText(A_Index, 1) == this.gui.Hwnd) {
							guiRowIndex := A_Index
							break
						}
				if (guiRowIndex)
					this.LV.Modify(guiRowIndex, "-Select")
				Loop this.LV.GetCount()
					if (A_Index != guiRowIndex)
						this.LV.Modify(A_Index, "+Select")
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
			case "116":	; F5 Key -> Refresh LV
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
				this.settings.excludeWindows := !this.settings.excludeWindows
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
		for i, cFunc in rowNums
			wHandles.push(Integer(this.LV.GetText(cFunc, 1)))
		basicTasks := Map(
			"Reset Window Position", resetWindowPosition,
			"Minimize Window", WinMinimize,
			"Maximize Window", WinMaximize,
			"Restore Window", WinRestore,
			"Move Windows to Monitor 1", resetWindowPosition.bind(,,1),
			"Move Windows to Monitor 2", resetWindowPosition.bind(,,2),
			"Toggle Window Lock", (wHandle) => (WinSetAlwaysOnTop(WinGetExStyle(wHandle) & 0x8 ? 0 : 1, wHandle)),
			"Set Window Lock", WinSetAlwaysOnTop.bind(true),
			"Remove Window Lock", WinSetAlwaysOnTop.bind(false),
			"Toggle Title Bar", (wHandle) => (WinSetStyle((WinGetStyle(wHandle) & this.windowStyles.WS_CAPTION ? "-" : "+" ) . this.windowStyles.WS_CAPTION, wHandle)),
			"Add Title Bar", WinSetStyle.bind("+" this.windowStyles.WS_CAPTION),
			"Remove Title Bar", WinSetStyle.bind("-" this.windowStyles.WS_CAPTION),
			"Toggle Visibility", (wHandle) => (WinGetStyle(wHandle) & this.windowStyles.WS_VISIBLE ? WinHide(wHandle) : WinShow(wHandle)),
			"Show Window", WinShow,
			"Hide Window", WinHide,
			"View Properties", (wHandle) => (Run('properties "' WinGetProcessPath(wHandle) '"')),
			"View Program Folder", (wHandle) => (Run('explorer.exe /select,"' . WinGetProcessPath(wHandle) . '"'))
		)
		if (basicTasks.Has(itemName))
			for i, wHandle in wHandles
				try basicTasks[itemName](wHandle)
		switch itemName {
			case "Activate Window":
				for i, wHandle in reverseArray(wHandles)
					try WinActivate(wHandle)
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
			case "Close Window":
				if(wHandles.Length > 1 && MsgBox("Are you sure you want to close " wHandles.Length " windows at once?", "Confirmation Prompt", 0x1) == "Cancel")
					return
				for i, wHandle in reverseArray(wHandles) {
					try WinClose(wHandle)
					if WinWaitClose(wHandle, , 0.5)
						this.LV.Delete(rowNums[rowNums.Length - i + 1])
				}
			case "Copy Window Title":
				for i, wHandle in wHandles
					str .= (WinExist(wHandle) ? WinGetTitle(wHandle) : "") . (i == wHandles.Length ? "" : "`n")
				A_Clipboard := str
			case "Change Window Transparency":
				this.transparencyGUI(wHandles)
			; this.winSubMenu.Add("Spread Windows on all Screens", this.menuHandler.Bind(this))
			; this.winSubMenu.Add("Spread Windows per Screen", this.menuHandler.Bind(this))
			case "Spread Windows":
				return
			default: ; custom functions
				if (this.menus.customFunctions.Has(itemName))
					for i, wHandle in wHandles
						try this.menus.customFunctions[itemName](wHandle)
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