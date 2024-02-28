; https://github.com/cobracrystal/ahk
; Todo
; settings: include files or not
; create search function in main gui

#Include "%A_LineFile%\..\..\Libraries"
#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"

class HotkeyManager {
	
	static hotkeyManager(mode := "O", *) {
		mode := SubStr(mode, 1, 1)
		if (WinExist(this.gui)) {
			if (mode == "O")
				WinActivate(this.gui.hwnd)
			else {
				this.data.coords := windowGetCoordinates(this.gui.hwnd)
				this.gui.destroy()
				this.gui := -1
				this.LV := [-1,-1,-1]
			}
		}
		else if (mode != "C")
			this.guiCreate()
	}

	static __New() {
		this.gui := -1
		this.LV := [-1,-1,-1]
		this.data := { coords: [300, 135], savedHotkeysPath: A_WorkingDir "\HotkeyManager\SavedHotkeys.txt", thisScript:""}
		; Tray Menu
		guiMenu := TrayMenu.submenus["GUIs"]
		guiMenu.Add("Open Hotkey Manager", this.hotkeyManager.Bind(this))
		A_TrayMenu.Add("GUIs", guiMenu)
		fileMenu := TrayMenu.submenus["Files"]
		fileMenu.Add("Edit Hotkey File", (*) => tryEditTextFile("Notepad++", this.data.savedHotkeysPath))
		A_TrayMenu.Add("Files", fileMenu)
		; init class variables
	}

	static guiCreate() {
		this.gui := Gui("+Border", "Hotkey Manager")
		this.gui.OnEvent("Escape", (*) => this.hotkeyManager("Close"))
		this.gui.OnEvent("Close", (*) => this.hotkeyManager("Close"))
		OnMessage(0x0100, this.onKeyPress.bind(this))
		this.gui.AddEdit("vEditFilterHotkeys").OnEvent("Change", (ctrlObj, Info) => this.guiListviewCreate(this.tabObj.Value, false, false))
		this.data.scripts := this.getFullScript(A_ScriptFullPath)
		this.data.hotkeys := this.getHotkeys()
		this.data.savedHotkeys := this.getSavedHotkeys()	
		this.data.hotstrings := this.getHotstrings()	
		this.tabObj := this.gui.AddTab3("w526 h500", ["AHK Hotkeys", "Other Hotkeys", "Hotstrings", "Settings"])
		this.tabObj.UseTab(1)
			this.lv[1] := this.gui.AddListView("R25 w500 -Multi", ["Line", "Keys", "Comment", "Source"])
			this.guiListviewCreate(1, true, true)
			this.lv[1].OnEvent("DoubleClick", (obj, rowN) => rowN ? tryEditTextFile('Notepad++', '"' A_ScriptFullPath '" -n' obj.GetText(rowN, 1)) : 0)
		this.tabObj.UseTab(2)	
			this.lv[2] := this.gui.AddListView("R25 w500 -Multi",["Keys","Program","Comment"])
			this.guiListviewCreate(2, true, true)
			this.lv[2].OnEvent("DoubleClick", (obj, rowN) => rowN ? tryEditTextFile("Notepad++", this.data.savedHotkeysPath) : 0)
		this.tabObj.UseTab(3)
			this.lv[3] := this.gui.AddListView("R25 w500 -Multi", ["Line", "Options", "Text", "Correction", "Comment", "Source"])
			this.guiListviewCreate(3, true, true)
			this.lv[3].OnEvent("DoubleClick", (obj, rowN) => rowN ? tryEditTextFile('Notepad++', '"' A_ScriptFullPath '" -n' obj.GetText(rowN, 1)) : 0)
		this.tabObj.UseTab(4)
		this.gui.AddText(,"SETTINGS HERE LATER")
		this.tabObj.UseTab()
		this.gui.AddButton("Default Hidden", "A").OnEvent("Click", this.onEnter.bind(this))
		this.gui.Show(Format("x{1}y{2} Autosize", this.data.coords[1], this.data.coords[2]))
	}

	static guiListviewCreate(num, first := false, redraw := false) {
		if (num < 1 || num > 3)
			return 0
		this.gui.Opt("+Disabled")
		this.lv[num].Opt("-Redraw")
		this.lv[num].Delete()
		switch num {
			case 1:
				for i, e in this.data.hotkeys {
					if (this.isIncludedInSearch(e)) {
						SplitPath(e.file, &fileName)
						this.lv[1].Add(,e.line, e.hotkey, e.comment, fileName)
					}
				}
			case 2:
				for i, e in this.data.savedHotkeys
					if (this.isIncludedInSearch(e))
						this.lv[2].Add(,e.hotkey, e.program, e.comment)
			case 3:
				for i, e in this.data.hotstrings {
					if (this.isIncludedInSearch(e)) {
						SplitPath(e.file, &fileName)
						this.lv[3].Add(,e.line, e.options, e.hotstring, e.replaceString, e.comment, fileName)
					}
				}
		}
		if (this.lv[num].GetCount() == 0)
			this.LV[num].Add("", "/", "Nothing Found.")
		if (first) {
			if (num != 2)
				this.lv[num].ModifyCol(1,"Integer")
		}
		if (redraw) {
			Loop(this.lv[num].GetCount("Col"))
				this.lv[num].ModifyCol(A_Index,"AutoHdr")
		}
		this.lv[num].Opt("+Redraw")
		this.gui.Opt("-Disabled")
	}

	static isIncludedInSearch(hkeyObj) {
		search := this.gui["EditFilterHotkeys"].Value
		if (search == "")
			return true
		for i, e in hkeyObj.OwnProps()
			if (InStr(e, search) && i != "file")
				return true
		return false 
	}

	static onEnter(*) {
		ctrl := this.gui.FocusedCtrl
		switch ctrl {
			case this.lv[1], this.lv[3]:
				if (rowN := ctrl.GetNext()) {
					tryEditTextFile('Notepad++', '"' A_ScriptFullPath '" -n' ctrl.GetText(rowN, 1))
				}
			case this.lv[2]:
				if (ctrl.GetNext())
					tryEditTextFile("Notepad++", this.data.savedHotkeysPath)
		}
	}

	static onKeyPress(wParam, lParam, msg, hwnd) {
		if (ctrl := GuiCtrlFromHwnd(hwnd)) {
			if (ctrl.gui == this.gui) {
				switch wParam {
					case "70": ; ctrl F
						if (GetKeyState("Ctrl")) {
							this.gui["EditFilterHotkeys"].Focus()
						}
					case "116":	;// F5 Key -> Reload
						this.guiListviewCreate(this.tabObj.Value, false, false)
					default:
						return
				}
			}
		}
	}

	static getFullScript(path := A_ScriptFullPath) {
		stack := [normalizePath(path)], scripts := []
		for i, p in stack {
			script := FileRead(p, "UTF-8")
			flagComment := false
			cleanScript := ""
			Loop Parse, script, "`n", "`r"
			{
				line := A_LoopField
				if (flagComment) {
					if (!RegExMatch(line, "^\s*\*\/")) {
						cleanScript .= "`n"
						continue
					}
					flagComment := false
					; if the comment ends, then there cannot be a new /* on the same line. Then, the rest is at worst a comment with ; 
					line := RegExReplace(line, "^\s*\*\/")
				}
				if (RegExMatch(line, "^\s*\/\*")) { ; /* comments MUST be at start of line
					if (!RegexMatch(line, "^\s*\/*.*\*\/\h*$")) ; these lines are ENTIRELY comments regardless. /* */ [text] is the same as ; [text]
						flagComment := true
					cleanScript .= "`n"
					continue
				}
				if (InStr(line, "#Include") && RegexMatch(line, "^\s*#Include")) {
					path := this.getIncludePath(line, p) ; keep track of include working directory. THIS IS PER FILE.)
					if (path && !objContainsValue(stack, path))
						stack.push(path)
				}
				cleanScript .= line . "`n"
			}
			scripts.push({path:p, script:cleanScript})
		}
		return scripts
	;	return RegExReplace(script, "ms`a)(?:^\s*\/\*.*?\*\/\s*\v|^\s*\/\*(?!.*\*\/\s*\v).*)")
		; ^this works but it doesn't keep line numbers intact for obvious reasons
	}

	static getIncludePath(line, from := A_ScriptFullPath) {
		static currentWorkingDirectory := A_ScriptDir
		RegexMatch(line, '^\s*#Include (?<quot>"|`')?(?<path>.*)(?P=quot)', &m)
		path := m["path"]
		for i, e in ["A_AhkPath", "A_AppData", "A_AppDataCommon", "A_ComputerName", "A_ComSpec", "A_Desktop", "A_DesktopCommon", "A_IsCompiled", "A_MyDocuments", "A_ProgramFiles", "A_Programs", "A_ProgramsCommon", "A_ScriptDir", "A_ScriptFullPath", "A_ScriptName", "A_Space", "A_StartMenu", "A_StartMenuCommon", "A_Startup", "A_StartupCommon", "A_Tab", "A_Temp", "A_UserName", "A_WinDir"]
			path := StrReplace(path, "%" e "%", %e%)
		path := StrReplace(path, "%A_LineFile%", from)
		path := StrReplace(path, "``;", ";")
		if (!RegexMatch(path, "i)^[a-z]:\\"))
			path := currentWorkingDirectory . (SubStr(path, 1, 1) == "\" ? "" : "\") . path
		path := normalizePath(path)
		if (InStr(FileGetAttrib(path), "D")) {
			currentWorkingDirectory := (SubStr(path, -1) == "\" ? SubStr(path, 1, -1) : path)
			return ""
		}
		return path
	}

	static getHotkeys()	{
		hotkeys := []
		hotkeyModifiers := [
			{mod:"+", replacement:"Shift"}, 
			{mod:"<^>!", replacement:"AltGr"},
			{mod:"^", replacement:"Ctrl"},
			{mod:"!", replacement:"Alt"},
			{mod:"#", replacement:"Win"}, 
			{mod:"<", replacement:"Left"},
			{mod:">",	replacement:"Right"}
		]
		for i, e in this.data.scripts {
			script := e.script
			SplitPath(e.path, &fileName)
			Loop Parse, script, "`n", "`r" { ; loop parse > strsplit for memory
				if !(InStr(A_Loopfield, "::")) ; skip non-hotkeys. Hotkey(asd) is ignored.
					continue
				if (InStr(A_LoopField, ";") && !(InStr(SubStr(A_LoopField, 1, RegexMatch(A_LoopField, "\s;")), "::")))
					continue
				StrReplace(SubStr(A_Loopfield, 1, InStr(A_Loopfield, "::")), "`"",,, &count)
				if (count > 1) ; skip strings containing > 1 quotes before ::
					continue
				; matches duo keys, modifier keys, modifie*d* leys, numeric value hotkeys, virtual key code hkeys and gets comment after
				if RegExMatch(A_LoopField,"^((?!(?:\s*;|:.*:.*::|(?!.*\s&\s|^\s*[\^+!#<>~*$]*`").*`".*::)).*)::\s*{?(?:.*;)?\s*(.*)", &match)	{
					comment := match[2]
					hkey := LTrim(match[1])
					obj := {line:A_Index, comment:comment, file:e.path}
					; single key can't be a modifier ~> symbol is hotkey
					; if duo hotkey, modifiers are impossible so push
					if (InStr(hkey, " & ") || StrLen(hkey) == 1)
						obj.hotkey := hkey
					else if (hkey == "<^>!") ; altgr = leftCtrl + RightAlt, but on its own LeftCtrl + excl mark
						obj.hotkey := "Left Ctrl + !"
					else {
						hk := SubStr(hkey, 1, -1)
						for i, e in hotkeyModifiers ; order in array important, shift must be first to ensure no "+" replacements
							hk := StrReplace(hk, e.mod, e.replacement . (e.mod != "<" && e.mod != ">" ? " + " : " "))
						obj.hotkey := hk . SubStr(hkey, -1)
					}
					hotkeys.Push(obj)
				}
			}
		}
		return hotkeys
	}

	static getHotstrings() {
		hotstrings := []
		for i, e in this.data.scripts {
			script := e.script
			Loop Parse, script, "`n", "`r" {
				if (!InStr(A_LoopField, "::"))
					continue
				if (RegExMatch(A_LoopField,'i)^\s*:([0-9\*\?XBCKOPRSIEZ]*?):(.*?)::(.*)`;?\s*(.*)', &match) || RegexMatch(A_LoopField, 'i)^\s*Hotstring\(\":([0-9\*\?BCKOPRSIEZ]*?):(.*?)\",\"(?:(.*)\"),.*?\)\s*`;?\s*(.*)', &match))	{
					; start of line : [possible modifiers only once]:[string]:(escape char):(seconds string)[check for spaces][comment] OR ALTERNATIVELY
					; HotString(" (<- escaped via "" which turns into ", and that escaped via \ so \"" = ")[modifiers]:[string]","[replacement]", [variable which we don't need])
					modifiers := match[1]
					hString := match[2]
					rString := match[3]
					comment := match[4]
					if RegExMatch(hString,"({:}|{!})")	{
						hString := StrReplace(hString, "{:}", ":",,, -1)
						hString := StrReplace(hString, "{!}", "!",,, -1)
					}
					if RegExMatch(rString,"({:}|{!}||{Space})")	{
						rString := StrReplace(rString, "{:}", ":",,, -1)
						rString := StrReplace(rString, "{!}", "!",,, -1)
						rString := StrReplace(rString, "{Space}", " ",,, -1)
					}
					if RegexMatch(modifiers, ".*b0.*")
						rString := hString . rString
					hotstrings.Push({line:A_Index, options:modifiers, hotstring:hString, replacestring:rString, comment:match[4], file:e.path})
				}
			}
		}
		return hotstrings
	}

	static getSavedHotkeys()	{
		if 	!(FileExist(this.data.savedHotkeysPath)) {
			if !(DirExist(A_WorkingDir "\HotkeyManager"))
				DirCreate("HotkeyManager")
			FileAppend("// Add Custom Hotkeys not from the script here to show up in the Hotkey List.`n// Format is Hotkey/Hotstring:[hotkey/hotstring], [Program], [Command (optional)]", this.data.savedHotkeysPath)
			return []
		}
		savedHotkeysFull := FileRead(this.data.savedHotkeysPath, "UTF-8")
		savedHotkeys := []
		Loop Parse, savedHotkeysFull, "`n", "`r"
			if RegExMatch(A_LoopField,"^(?!\s*;|//)Hotkey:\s*(.*)\s*,\s*(.*)\s*,\s*(.*)\s*", &match)
				savedHotkeys.Push({hotkey:match[1], program:match[2], comment:(match[3] == "" ? "None" : match[3])})
		return savedHotkeys
	}
}
