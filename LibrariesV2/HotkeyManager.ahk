; https://github.com/cobracrystal/ahk
; Todo
; settings: include files or not
; create search function in main gui

#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\WinUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\Dependencies.ahk"

class HotkeyManager {
	
	static hotkeyManager(mode := "O", *) {
		mode := SubStr(mode, 1, 1)
		if (WinExist(this.gui)) {
			if (mode == "O")
				WinActivate(this.gui.hwnd)
			else {
				this.data.coords := WinUtilities.getWindowPlacement(this.gui.hwnd)
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
		this.data := { 
			coords: {x: 300, y: 135}, 
			savedHotkeysPath: A_WorkingDir "\HotkeyManager\SavedHotkeys.txt",
		}
		this.editorProfileConfig := this.Editors.vscodium
		; Tray Menu
		guiMenu := TrayMenu.submenus["GUIs"]
		guiMenu.Add("Open Hotkey Manager", this.hotkeyManager.Bind(this))
		A_TrayMenu.Add("GUIs", guiMenu)
		fileMenu := TrayMenu.submenus["Files"]
		fileMenu.Add("Edit Hotkey File", (*) => this.Editors.runEditor(this.editorProfileConfig, this.data.savedHotkeysPath))
		A_TrayMenu.Add("Files", fileMenu)
		; init class variables
	}

	static guiCreate() {
		this.gui := Gui("+Border", "Hotkey Manager")
		this.gui.OnEvent("Escape", (*) => this.hotkeyManager("Close"))
		this.gui.OnEvent("Close", (*) => this.hotkeyManager("Close"))
		OnMessage(0x0100, this.onKeyPress.bind(this))
		this.gui.AddEdit("vEditFilterHotkeys").OnEvent("Change", (ctrlObj, Info) => this.guiListviewCreate(this.tabObj.Value, false, false))
		this.data.scripts := this.getScripts(A_ScriptFullPath)
		this.data.hotkeys := this.getHotkeys()
		this.data.savedHotkeys := this.getSavedHotkeys()	
		this.data.hotstrings := this.getHotstrings()
		this.tabObj := this.gui.AddTab3("w526 h500", ["AHK Hotkeys", "Other Hotkeys", "Hotstrings", "Settings"])
		this.tabObj.UseTab(1)
			this.lv[1] := this.gui.AddListView("R25 w500 -Multi", ["Line", "Keys", "Comment", "Source"])
			this.guiListviewCreate(1, true, true)
			this.lv[1].OnEvent("DoubleClick", (obj, rowN) => rowN ? this.Editors.runEditor(this.editorProfileConfig, A_ScriptFullPath, obj.GetText(rowN, 1)) : 0)
		this.tabObj.UseTab(2)	
			this.lv[2] := this.gui.AddListView("R25 w500 -Multi",["Line", "Keys","Program","Comment"])
			this.guiListviewCreate(2, true, true)
			this.lv[2].OnEvent("DoubleClick", (obj, rowN) => rowN ? this.Editors.runEditor(this.editorProfileConfig, this.data.savedHotkeysPath, obj.GetText(rowN, 1)) : 0)
		this.tabObj.UseTab(3)
			this.lv[3] := this.gui.AddListView("R25 w500 -Multi", ["Line", "Options", "Text", "Correction", "Comment", "Source"])
			this.guiListviewCreate(3, true, true)
			this.lv[3].OnEvent("DoubleClick", (obj, rowN) => rowN && IsDigit(obj.GetText(rowN, 1)) ? this.Editors.runEditor(this.editorProfileConfig, A_ScriptFullPath, obj.GetText(rowN, 1)) : 0)
		this.tabObj.UseTab(4)
			this.gui.AddText("Section yp+10", "Command Line For Editing")
			this.editRunCmd := this.gui.AddEdit("xs w500", this.Editors.cmdStringTemplate(this.editorProfileConfig))
			this.gui.AddButton("xs w100", 'Save').OnEvent('Click', (*) => this.editorProfileConfig := this.editRunCmd.Value)
		this.tabObj.UseTab()
		this.gui.AddButton("Default Hidden", "A").OnEvent("Click", this.onEnter.bind(this))
		this.gui.Show(Format("x{1}y{2} Autosize", this.data.coords.x, this.data.coords.y))
	}

	static guiListviewCreate(num, initialCreation := false, redraw := false) {
		if (num < 1 || num > 3)
			return 0
		this.gui.Opt("+Disabled")
		this.lv[num].Opt("-Redraw")
		this.lv[num].Delete()
		search := this.gui["EditFilterHotkeys"].Value
		switch num {
			case 1:
				for i, hkey in this.data.hotkeys
					if this.isIncludedInSearch(hkey, search) {
						SplitPath(hkey.file, &fileName)
						this.lv[1].Add(,hkey.line, hkey.hotkey, hkey.comment, fileName)
					}
			case 2:
				for i, hkey in this.data.savedHotkeys
					if this.isIncludedInSearch(hkey, search)
						this.lv[2].Add(,hkey.line, hkey.hotkey, hkey.program, hkey.comment)
			case 3:
				for i, hstring in this.data.hotstrings
					if this.isIncludedInSearch(hstring, search) {
						SplitPath(hstring.file, &fileName)
						this.lv[3].Add(,hstring.line, hstring.options, hstring.hotstring, hstring.replaceString, hstring.comment, fileName)
					}
			}
		if (this.lv[num].GetCount() == 0)
			this.LV[num].Add("", "/", "Nothing Found.")
		if (redraw) {
			Loop(this.lv[num].GetCount("Col") - 1)
				this.lv[num].ModifyCol(A_Index + 1,"AutoHdr")
			this.lv[num].ModifyCol(1, 0)
		}
		if (initialCreation)
			this.lv[num].ModifyCol(1,"Integer")
		this.lv[num].Opt("+Redraw")
		this.gui.Opt("-Disabled")
		
		
	}

	static isIncludedInSearch(hkeyObj, search) {
		if search == ""
			return true
		if InStr(hkeyObj.comment, search)
			return true
		for i, str in hkeyObj.OwnProps() {
			switch i {
				case "file", "line":
					continue
				case "hotkey":
					for needle in strSplitOnWhiteSpace(Trim(search)) {
						if needle == "" 
							continue
						str := StrReplace(str, needle, '',, &replCount, 1)
						if !replCount ; if we didn't replace anything, needle didn't match
							continue 2
					}
					return true
				default:
					if InStr(str, search)
						return true
			}
			if (InStr(str, search) && i != "file")
				return true
		}
		return false
	}

	static onEnter(*) {
		ctrl := this.gui.FocusedCtrl
		switch ctrl {
			case this.lv[1], this.lv[3]:
				if (rowN := ctrl.GetNext()) {
					this.Editors.runEditor(this.editorProfileConfig, A_ScriptFullPath, ctrl.getText(rowN, 1))
				}
			case this.lv[2]:
				if (ctrl.GetNext())	
					this.Editors.runEditor(this.editorProfileConfig, this.data.savedHotkeysPath)
		}
	}

	static onKeyPress(wParam, lParam, msg, hwnd) {
		if (ctrl := GuiCtrlFromHwnd(hwnd)) {
			if (ctrl.gui == this.gui) {
				switch wParam {
					case "8":
						if (GetKeyState("Ctrl") && ctrl.hwnd == this.gui["EditFilterHotkeys"].hwnd)
							SetTimer((*) => Send("{Backspace}^{Left}^{Delete}"), -10)
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

	static getScripts(path := A_ScriptFullPath) {
		inclusions := Dependencies.asArray(path)
		inclusions.InsertAt(1, Dependencies.normalizePath(path))
		return objDoForEach(inclusions, v => {script: Dependencies.getUncommentedScript(FileRead(v, 'UTF-8')), path: v})
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
		if (IsSet(HotstringLoader)) {
			for name, e in HotstringLoader.hotstrings {
				if e.status == 1 {
					for hString in e.obj {
						hotstrings.Push({
							line: "/", 
							options: hString.Has("options") ? hString["options"] : "", 
							hotstring: hString["string"], 
							replacestring: hString["replacement"], 
							comment: "Group: " name, 
							file: e.file
						})		
					}
				}
			}
		}
		return hotstrings
	}

	static getSavedHotkeys()	{
		if !(FileExist(this.data.savedHotkeysPath)) {
			SplitPath(this.data.savedHotkeysPath,, &dir)
			if !(DirExist(dir))
				DirCreate(dir)
			FileAppend("// Add Custom Hotkeys not from the script here to show up in the Hotkey List.`n// Format is Hotkey/Hotstring:[hotkey/hotstring], [Program], [Command (optional)]", this.data.savedHotkeysPath)
			return []
		}
		savedHotkeysFull := FileRead(this.data.savedHotkeysPath, "UTF-8")
		savedHotkeys := []
		Loop Parse, savedHotkeysFull, "`n", "`r"
			if RegExMatch(A_LoopField,"^(?!\s*;|//)Hotkey:\s*(.*)\s*,\s*(.*)\s*,\s*(.*)\s*", &match)
				savedHotkeys.Push({line:A_Index, hotkey:match[1], program:match[2], comment:(match[3] == "" ? "None" : match[3])})
		return savedHotkeys
	}

	class Editors {
		
		static runEditor(editor, filePath, line?) {
			if editor is Object
				fullCmd := this.cmdString(editor, filePath, line?)
			else if editor is String {
				fullCmd := StrReplace(editor, '%PATH', filePath)
				fullCmd := StrReplace(fullCmd, '%LINE', line ?? '')
			}
			Run(fullCmd)
		}

		static cmdStringTemplate(config := this.notepad) {
			return config.exe ' ' (config.params ? config.params ' ' : '') config.path . (config.line ? config.line : '')
		}

		static cmdString(config := this.notepad, path?, line?) {
			return config.exe ' ' 
				. (config.params ? config.params ' ' : '') 
				. (IsSet(path) ? StrReplace(config.path, "%PATH", path) : '') 
				. (IsSet(line) && config.line ? StrReplace(config.line, "%LINE", line) : '')
		}

		static notepad := {
			exe: A_WinDir . '\system32\notepad.exe',
			params: '',
			path: '"%PATH"',
			line: '',
		}
		
		static notepadplusplus := {
			exe: 'Notepad++',
			params: '',
			path: '"%PATH"',
			line: ' -n%LINE',
		}
		
		static vscode := {
			exe: '"' Dependencies.normalizePath(A_AppData '\..\Local\Programs\Microsoft VS Code\Code.exe') '"',
			params: '',
			path: '-g "%PATH"',
			line: ':%LINE',
		}
		
		static vscodium := {
			exe: '"' Dependencies.normalizePath(A_AppData '\..\Local\Programs\VSCodium\VSCodium.exe') '"',
			params: '-r',
			path: '-g "%PATH"',
			line: ':%LINE',
		}
	} 
}
