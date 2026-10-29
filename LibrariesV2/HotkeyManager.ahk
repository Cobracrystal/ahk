; https://github.com/cobracrystal/ahk
; Todo
; settings: include files or not
; create search function in main gui

#Include "BasicUtilities.ahk"
#Include "WinUtilities.ahk"
#Include "FileUtilities.ahk"
#Include "Dependencies.ahk"

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
				this.lv := [-1,-1]
			}
		}
		else if (mode != "C")
			this.guiCreate()
	}

	static __New() {
		this.gui := -1
		this.lv := [-1,-1]
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
		this.gui := Gui("+Border +Resize", "Hotkey Manager")
		this.gui.OnEvent("Escape", (*) => this.hotkeyManager("Close"))
		this.gui.OnEvent("Close", (*) => this.hotkeyManager("Close"))
		this.gui.OnEvent("Size", this.onResize.bind(this))
		OnMessage(0x0100, this.onKeyPress.bind(this))
		this.gui.AddEdit("vEditFilterHotkeys").OnEvent("Change", (ctrlObj, Info) => this.guiListviewCreate(this.tabObj.Value, false, false))
		this.data.scripts := this.getScripts(A_ScriptFullPath)
		this.data.hotkeys := this.getHotkeys()
		this.data.savedHotkeys := this.getSavedHotkeys()	
		this.data.hotstrings := this.getHotstrings()
		this.tabObj := this.gui.AddTab3("w625 h725", ["Hotkeys", "Hotstrings", "Settings"])
		this.tabObj.UseTab(1)
			this.lv[1] := this.gui.AddListView("w500 h675 -Multi", ["ID", "Line", "Keys", "Source", "Comment"])
			this.guiListviewCreate(1, true, true)
			this.lv[1].OnEvent("DoubleClick", this.onEnter.bind(this))
		this.tabObj.UseTab(2)
			this.lv[2] := this.gui.AddListView("w500 h675 -Multi", ["ID", "Line", "Options", "Text", "Correction", "Comment", "Source"])
			this.guiListviewCreate(2, true, true)
			this.lv[2].OnEvent("DoubleClick", this.onEnter.bind(this))
		this.tabObj.UseTab(3)
			this.gui.AddText("Section yp+10", "Command Line For Editing")
			this.editRunCmd := this.gui.AddEdit("xs w500", this.Editors.cmdStringTemplate(this.editorProfileConfig))
			this.gui.AddButton("xs w100", 'Save').OnEvent('Click', (*) => this.editorProfileConfig := this.editRunCmd.Value)
		this.tabObj.UseTab()
		this.gui.AddButton("Default Hidden", "A").OnEvent("Click", this.onEnter.bind(this))
		this.gui.Show(Format("x{1}y{2} Autosize", this.data.coords.x, this.data.coords.y))
	}

	static guiListviewCreate(tabNum, initialCreation := false, redraw := false) {
		this.gui.Opt("+Disabled")
		this.lv[tabNum].Opt("-Redraw")
		this.lv[tabNum].Delete()
		search := this.gui["EditFilterHotkeys"].Value
		switch tabNum {
			case 1:
				for i, hkey in this.data.hotkeys
					if this.isIncludedInSearch(hkey, search)
						this.lv[1].Add(,i,hkey.line, hkey.hotkey, PathGetFileName(hkey.source), hkey.comment)
				for i, hkey in this.data.savedHotkeys
					if this.isIncludedInSearch(hkey, search)
						this.lv[1].Add(,this.data.hotkeys.Length+i,hkey.line, hkey.hotkey, hkey.source, hkey.comment)
			case 2:
				for i, hstring in this.data.hotstrings
					if this.isIncludedInSearch(hstring, search)
						this.lv[2].Add(,i,hstring.line, hstring.options, hstring.hotstring, hstring.replaceString, hstring.comment, PathGetFileName(hstring.source))
			}
		if (this.lv[tabNum].GetCount() == 0)
			this.lv[tabNum].Add("", "/", "Nothing Found.")
		if (redraw) {
			Loop(this.lv[tabNum].GetCount("Col") - 2)
				this.lv[tabNum].ModifyCol(A_Index + 2,"AutoHdr")
			this.lv[tabNum].ModifyCol(2, 0)
		}
		this.lv[tabNum].ModifyCol(1, 0)
		if (initialCreation)
			this.lv[tabNum].ModifyCol(2,"Integer")
		this.lv[tabNum].Opt("+Redraw")
		this.gui.Opt("-Disabled")
	}

	static isIncludedInSearch(hkeyObj, search) {
		if search == ""
			return true
		if InStr(hkeyObj.comment, search)
			return true
		for i, str in hkeyObj.OwnProps() {
			switch i {
				case "source":
					if hkeyObj.type == this.enum.customHotkey || hkeyObj.type == this.enum.customHotstring {
						if InStr(str, search)
							return true
					} else {
						continue
					}
				case "hotkey":
					for needle in strSplitOnWhiteSpace(Trim(search)) {
						if needle == "" 
							continue
						str := StrReplace(str, needle, '',, &replCount, 1)
						if !replCount ; if we didn't replace anything, needle didn't match
							continue 2
					}
					return true
				case "hotstring", "options", "replacestring":
					if InStr(str, search)
						return true
				default: ; line, type
					continue
			}
		}
		return false
	}

	static onEnter(*) {
		ctrl := this.gui.FocusedCtrl
		rowN := ctrl.GetNext()
		if !rowN
			return
		id := ctrl.GetText(rowN, 1)
		line := ctrl.GetText(rowN, 2)
		switch ctrl {
			case this.lv[1]:
				if id <= this.data.hotkeys.Length
					this.Editors.runEditor(this.editorProfileConfig, this.data.hotkeys[id].source, line)
				else
					this.Editors.runEditor(this.editorProfileConfig, this.data.savedHotkeysPath, line)
			case this.lv[2]:
				if !IsDigit(rowN)
					return
				this.Editors.runEditor(this.editorProfileConfig, this.data.hotstrings[id].source, line)

		}
	}

	static onKeyPress(wParam, lParam, msg, hwnd) {
		if (ctrl := GuiCtrlFromHwnd(hwnd)) {
			if (ctrl.gui == this.gui) {
				switch wParam {
					case "8": ; ctrl backspace
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

	static onResize(g, mmx, w, h) {
		if (mmx == -1) ; minimized
			return
		this.tabObj.Move(,,w-20,h-39)
		for lv in this.lv
			lv.Move(,,w-50,h-86)
		/*
		initial values:
		546 539 gui
		526 500 tab
		500 453 lv
		*/
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
					obj := {line:A_Index, comment:comment, source:e.path, type: this.enum.ahkHotkey}
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
					hotstrings.Push({line:A_Index, options:modifiers, hotstring:hString, replacestring:rString, comment:match[4], source:e.path, type: this.enum.ahkHotstring})
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
							source: e.file,
							type: this.enum.hotstringLoaderHotstring
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
				savedHotkeys.Push({line:A_Index, hotkey:match[1], source:match[2], comment:(match[3] == "" ? "None" : match[3]), type: this.enum.customHotkey})
		return savedHotkeys
	}

	static enum := {
		ahkHotkey: 0,
		customHotkey: 1,
		ahkHotstring: 2,
		customHotstring: 3,
		hotstringLoaderHotstring: 4
	}

	class Editors {
		
		static runEditor(editor, filePath, line?) {
			if editor is Object
				fullCmd := this.cmdString(editor, filePath, line?)
			else if editor is String {
				fullCmd := StrReplace(editor, '%PATH', filePath)
				fullCmd := StrReplace(fullCmd, '%LINE', line ?? '')
			}
			print fullCmd
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
