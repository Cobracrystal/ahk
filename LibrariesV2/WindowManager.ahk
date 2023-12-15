; https://github.com/cobracrystal/ahk
; TODO: Refreshing with F5 should 
; a) be available with a GUI button, 
; c) should be toggleable to update automatically
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
			coords: [300, 200],
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
		this.gui.AddText("ys xs+890 w110 vWindowCount", "Window Count: 0")
		this.LV := this.gui.AddListView("xs R20 w1000 -Multi", ["handle", "ahk_title", "Process", "mmx", "xpos", "ypos", "width", "height", "ahk_class", "PID", "Process Path", "Command Line"])
		this.LV.OnNotify(-155, this.onKeyPress.bind(this))
		this.LV.OnEvent("ContextMenu", this.onContextMenu.bind(this))
		this.LV.OnEvent("DoubleClick", (obj, rowN) => rowN == 0 ? 0 : WinActivate(Integer(obj.GetText(rowN, 1))))
		this.gui.AddButton("Default Hidden", "A").OnEvent("Click", (*) => (this.LV.Focused && (rowN := this.LV.GetNext()) != 0 ? WinActivate(Integer(this.LV.GetText(rowN, 1))) : 0))
		;	this.LV.OnEvent("ColClick", this.onColClick.bind(this)) ; store sorting state for refresh?
		this.guiListviewCreate(false)
		if (this.settings.darkMode)
			this.toggleGuiDarkMode(this.settings.darkMode)
		this.gui.Show(Format("x{1}y{2} Autosize", this.settings.coords[1], this.settings.coords[2]))
		this.insertWindowInfo(this.gui.Hwnd, 1) ;// inserts the first row to be about the windowManager itself
		this.LV.Focus()
	}

	static toggleGuiDarkMode(dark) {
		static WM_THEMECHANGED := 0x031A
		;// title bar dark
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
			if (ctrl.Name && SubStr(ctrl.Name, 1, 10) == "EditAddRow") {
				this.validValueChecker(ctrl)
			}
		}
		; todo: setting to make this look like this ? 
		; DllCall("uxtheme\SetWindowTheme", "ptr", _gui.LV.hwnd, "str", "Explorer", "ptr", 0)
	}

	static guiListviewCreate(redraw := true) {
		this.LV.Delete()
		for i, e in this.getAllWindowInfo(this.settings.detectHiddenWindows, this.settings.showExcludedWindows)
			this.LV.Add(, e.hwnd, e.title, e.process, e.state, e.xpos, e.ypos, e.width, e.height, e.class, e.pid, e.processPath, e.commandLine)
		Loop (this.LV.GetCount("Col"))
			this.LV.ModifyCol(A_Index, "+AutoHdr")
		Loop (5)
			this.LV.ModifyCol(A_Index + 3, "+Integer")
		this.LV.ModifyCol(1, "+Integer")
		this.LV.ModifyCol(10, "+Integer")
		if (!this.settings.getCommandLine)
			this.LV.ModifyCol(12, "0")
		this.gui["WindowCount"].Value := Format("Window Count: {:5}", (c := this.LV.GetCount()) - 1)
		if (redraw) {
			if (c + 1 > 40) ; redraw -> adjust for insertWindowInfo on first; +1 for empty space
				this.LV.Move(, , , 640)
			else if (c >= 20)
				this.LV.Move(, , , 45 + c * 17)
			else
				this.LV.Move(, , , 368)
			this.gui.Show("Autosize")
		}
	}

	static insertWindowInfo(wHandle, rowN) {
		t := this.getWindowInfo(wHandle)
		this.LV.Insert(rowN, , t.hwnd, t.title, t.process, t.state, t.xpos, t.ypos, t.width, t.height, t.class, t.pid, t.processPath, t.commandLine)
	}

	static getAllWindowInfo(getHidden := false, notExclude := false) {
		windows := []
		tMM := A_TitleMatchMode
		SetTitleMatchMode("RegEx")
		DetectHiddenWindows(getHidden)
		if (notExclude)
			wHandles := WinGetList()
		else
			wHandles := WinGetList(, , this.settings.excludeWindowsRegex)
		for i, wHandle in wHandles
			windows.push(this.getWindowInfo(wHandle))
		SetTitleMatchMode(tMM)
		return windows
	}

	static getWindowInfo(wHandle) {
		x := "", y := "", w := "", h := "", winTItle := "", winClass := "", mmx := "", processName := "", processPath := "", pid := "", cmdLine := ""
		try {
			WinGetPos(&x, &y, &w, &h, wHandle)
			winTitle := WinGetTitle(wHandle)
			winClass := WinGetClass(wHandle)
			mmx := WinGetMinMax(wHandle)
			processName := WinGetProcessName(wHandle)
			processPath := WinGetProcessPath(wHandle)
			pid := WinGetPID(wHandle)
			if (this.settings.getCommandLine)
				cmdLine := this.winmgmt("CommandLine", "Where ProcessId = " pid)[1]
			; Get-WmiObject -Query "SELECT * FROM Win32_Process WHERE ProcessID = 23944" in powershell btw
		}
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
		if (WinGetExStyle(wHandle) & 0x8)
			this.menu.Check("Toggle Lock Status")
		else
			this.menu.Uncheck("Toggle Lock Status")
		this.menu.show()
	}

	static onKeyPress(ctrlObj, lParam) {
		vKey := NumGet(lParam, 24, "ushort")
		rowN := this.LV.GetNext()
		DetectHiddenWindows(this.settings.detectHiddenWindows)
		switch vKey {
			case "46": 	;// Del/Entf Key -> Close that window
				if (!rowN)
					return
				wHandle := Integer(this.LV.GetText(rowN, 1))
				if GetKeyState("Shift") 
					WinKill(wHandle)
				else
					WinClose(wHandle)
				if (WinWaitClose(wHandle, , 0.5))
					this.LV.delete(rowN)
			case "67": ; ctrl C
				if (!rowN)
					return
				wHandle := Integer(this.LV.GetText(rowN, 1))
				if (GetKeyState("Ctrl")) {
					if !GetKeyState("Shift")
						A_Clipboard := WinGetTitle(wHandle)
					else {
						info := this.getWindowInfo(wHandle)
						if !(this.settings.getCommandLine)
							info.DeleteProp("commandLine")
						A_Clipboard := jsongo.Stringify(info, , "`t")
						; Loop(this.LV.GetCount("Col"))
						; 	str .= this.LV.GetText(rowN, A_Index) "`t"
					}
				}
			case "116":	;// F5 Key -> Reload
				this.guiListviewCreate(false)
			default:
				return
		}
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
		this.guiListviewCreate(false)
	}

	; ------------------------- MENU FUNCTIONS -------------------------

	static menuHandler(itemName, itemPos, menuObj) {
		rowN := this.LV.GetNext()
		wHandle := Integer(this.LV.GetText(rowN, 1))
		switch itemName {
			case "Activate Window":
				WinActivate(wHandle)
			case "Reset Window Position":
				mmx := WinGetMinMax(wHandle)
				WinGetPos(, , &w, &h, wHandle)
				if (mmx != 0)
					WinRestore(wHandle)
				WinMove(A_ScreenWidth / 2 - w / 2, A_ScreenHeight / 2 - h / 2, , , wHandle)
				WinActivate(wHandle)
			case "Minimize Window":
				WinMinimize(wHandle)
			case "Maximize Window":
				WinMaximize(wHandle)
			case "Restore Window":
				WinRestore(wHandle)
			case "Close Window":
				WinClose(wHandle) ;// needs a check via WinExist & question whether winkill or not.
				if WinWaitClose(wHandle, , 0.5)
					this.LV.Delete(rowN)
			case "Toggle Lock Status":
				tStyle := WinGetExStyle(wHandle)
				WinSetAlwaysOnTop(tStyle & 0x8 ? 0 : 1, wHandle) ; 0x8 is WS_EX_TOPMOST
			case "Change Window Transparency":
				this.transparencyGUI(wHandle)
			case "Copy Window Title":
				A_Clipboard := WinGetTitle(wHandle)
			case "View Properties":
				Run('properties "' WinGetProcessPath(wHandle) '"')
			case "View Program Folder":
				run('explorer.exe /select,"' . WinGetProcessPath(wHandle) . '"')
			default:
				return
		}
	}

	static transparencyGUI(wHandle) {
		tp := WinGetTransparent(wHandle)
		tp := (tp == "" ? 255 : tp)
		transparencyGUI := Gui("Border -SysMenu +Owner" this.gui.hwnd, "Transparency Menu")
		transparencyGUI.AddText("x32", "Change Transparency")
		transparencyGUI.AddSlider("x10 yp+20 AltSubmit Range0-255 NoTicks Page16 ToolTip", tp).OnEvent("Change", (obj, *) => WinSetTransparent(obj.Value, Integer(this.LV.GetText(this.LV.GetNext(), 1))))
		transparencyGUI.AddButton("w80 yp+30 xp+20 Default", "OK").OnEvent("Click", transparencyGUIClose)
		transparencyGUI.OnEvent("Escape", transparencyGUIClose)
		transparencyGUI.OnEvent("Close", transparencyGUIClose)
		this.gui.Opt("+Disabled")
		transparencyGUI.Show()

		transparencyGUIClose(*) {
			if (WinGetTransparent(wHandle := Integer(this.LV.GetText(this.LV.GetNext(), 1))) == 255)
				WinSetTransparent("Off", wHandle)
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
			if (e.state == -1)
				WinMinimize(e.hwnd)
			else if (e.state == 1)
				WinMaximize(e.hwnd)
			else
				WinMove(e.xpos, e.ypos, e.width, e.height, e.hwnd)
		}
	}
}