;// made by Cobracrystal
;------------------------- AUTO EXECUTE SECTION -------------------------
#Include %A_ScriptDir%\LibrariesV2\BasicUtilities.ahk

;// Add two options on top of the normal Tray Menu


;------------------------------------------------------------------------

; RIDICULOUSLY COMPLICATED TODO:
; A) MAKE FUNCTION THAT REMOVES /* */ COMMENTS WHILE KEEPING LINECOUNT
; B) CHECK ALL INCLUDED FILES FOR HOTKEYS
; C) CREATE SEARCH FUNCTION IN MAIN GUI
; D) SETTINGS TAB TO SAVE STYLE
; E) ; BINDING GUI CLOSE FUNCTIONS INSIDE A CLASS !!!! MAKE ALL THIS INTO ONE CLASS https://www.autohotkey.com/boards/viewtopic.php?t=64337 

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
			}
		}
		else if (mode != "C")
			this.guiCreate()
	}

	static __New() {
		this.gui := -1
		this.LV := [-1,-1,-1]
		this.data := { coords: [300, 135], savedHotkeysPath: A_WorkingDir "\HotkeyManager\SavedHotkeys.txt" }
		; Tray Menu
		guiMenu := TrayMenu.submenus["GUIs"]
		guiMenu.Add("Open Hotkey Manager", this.hotkeyManager.Bind(this))
		A_TrayMenu.Add("GUIs", guiMenu)
		fileMenu := TrayMenu.submenus["Files"]
		fileMenu.Add("Edit Hotkey File", (*) => tryEditTextFile(tryEditTextFile(this.data.savedHotkeysPath)))
		A_TrayMenu.Add("Files", fileMenu)
		; init class variables
	}

	static guiCreate() {
		this.gui := Gui("+Border", "Hotkey Manager")
		this.gui.OnEvent("Escape", (*) => this.hotkeyManager("Close"))
		this.gui.OnEvent("Close", (*) => this.hotkeyManager("Close"))
		script := this.getFullScript()
		tabObj := this.gui.AddTab3("w526 h500", ["AHK Hotkeys", "Other Hotkeys", "Hotstrings", "Settings"])
		tabObj.UseTab(1)
			this.lv[1] := this.gui.AddListView("R25 w500 -Multi", ["Line", "Keys", "Comment"])
			for i, e in this.getHotkeys(script)
				this.lv[1].Add(,e.line, e.hotkey, e.comment)
			Loop(this.lv[1].GetCount("Col"))
				this.lv[1].ModifyCol(A_Index,"AutoHdr")
			this.lv[1].ModifyCol(1,"Integer")
			this.lv[1].OnEvent("DoubleClick", (obj, rowN) => rowN ? tryEditTextFile(A_ScriptFullPath '" "-n' obj.GetText(rowN, 1)) : 0)
		tabObj.UseTab(2)	
			this.lv[2] := this.gui.AddListView("R25 w500 -Multi",["Keys","Program","Comment"])
			for i, e in this.getSavedHotkeys()	
				this.lv[2].Add(,e.hotkey, e.program, e.comment)
			Loop(this.lv[2].GetCount("Col"))
				this.lv[2].ModifyCol(A_Index,"AutoHdr")
			this.lv[2].OnEvent("DoubleClick", (obj, rowN) => rowN ? tryEditTextFile(this.data.savedHotkeysPath) : 0)
		tabObj.UseTab(3)
			this.lv[3] := this.gui.AddListView("R25 w500 -Multi", ["Line", "Options", "Text", "Correction", "Comment"])
			for i, e in this.getHotstrings(script)
				this.lv[3].Add(,e.line, e.options, e.hotstring, e.replaceString, e.comment)
			Loop(this.lv[3].GetCount("Col"))
				this.lv[3].ModifyCol(A_Index,"AutoHdr")
			this.lv[3].ModifyCol(1,"Integer")
			this.lv[3].OnEvent("DoubleClick", (obj, rowN) => rowN ? tryEditTextFile(A_ScriptFullPath '" "-n' obj.GetText(rowN, 1)) : 0)
		tabObj.UseTab(4)
		this.gui.AddText(,"SETTINGS HERE LATER")
		tabObj.UseTab()
		this.gui.AddButton("Default Hidden", "A").OnEvent("Click", this.onKeyPress.bind(this))
		this.gui.Show(Format("x{1}y{2} Autosize", this.data.coords[1], this.data.coords[2]))
	}
	; -------- LOADING IN DATA

	static onKeyPress(*) {
		ctrl := this.gui.FocusedCtrl
		switch ctrl {
			case this.lv[1], this.lv[3]:
				if (rowN := ctrl.GetNext())
					tryEditTextFile(A_ScriptFullPath '" "-n' ctrl.GetText(rowN, 1))
			case this.lv[2]:
				if (ctrl.GetNext())
					tryEditTextFile(this.data.savedHotkeysPath)
		}
	}

	static getFullScript() {
		script := FileOpen(A_ScriptFullPath, "r", "UTF-8").Read()
		flagCom := false
		flagMult := false
		cleanScript := ""
		Loop Parse, script, "`n", "`r"
		{
			if (flagCom) {
				if (RegExMatch(A_Loopfield, "^\s*\*\/"))
					flagCom := false
				cleanScript .= "`n"
			}
			else if (RegExMatch(A_Loopfield, "^\s*\/\*")) {
				flagCom := true
				cleanScript .= "`n"
			}
			else if (flagMult) {
				if (RegExMatch(A_Loopfield, "^\s*\)"))
					flagMult := false
				cleanScript .= "`n"
			}
			else if (RegExMatch(A_Loopfield, "^\s*\(")) {
				flagMult := true
				cleanScript .= "`n"
			}
			else
				cleanScript .= A_LoopField . "`n"
		}
		return cleanScript
	;	return := RegExReplace(script, "ms`a)^\s*\/\*.*?^\s*\*\/\s*|^\s*\(.*?^\s*\)\s*") 
	}

	static getHotkeys(script)	{
		hotkeys := []
		hotkeyModifiers := [  {mod:"+", replacement:"Shift"}, {mod:"<^>!", replacement:"AltGr"}
							, {mod:"^", replacement:"Ctrl"}	, {mod:"!", replacement:"Alt"}
							, {mod:"#", replacement:"Win"}  , {mod:"<", replacement:"Left"}
							, {mod:">",	replacement:"Right"}]
		Loop Parse, script, "`n", "`r" { ; loop parse > strsplit for memory
			if !(InStr(A_LoopField, "::")) ; skip non-hotkeys
				continue
			StrReplace(SubStr(A_Loopfield, 1, InStr(A_Loopfield, "::")), "`"",,, &count)
			if (count > 1) ; skip strings containing two quotes before ::
				continue
			; matches duo keys, modifier keys, modifie*d* leys, numeric value hotkeys, virtual key code hkeys and gets comment after
			if RegExMatch(A_LoopField,"^((?!(?:;|:.*:.*::|(?!.*\s&\s|^\s*[\^+!#<>~*$]*`").*`".*::)).*)::{?(?:.*;)?\s*(.*)", &match)	{
				comment := match[2]
				hkey := LTrim(match[1])
				if (InStr(hkey, " & ")) { ; if duo hotkey, modifiers are impossible so push
					hotkeys.push({line:A_Index, hotkey:hkey, comment:comment})
					continue
				}
				if (StrLen(hkey) == 1) { ; single key can't be a modifier ~> symbol is hotkey
					hotkeys.push({line:A_Index, hotkey:hkey, comment:comment})
					continue
				}
				if (hkey == "<^>!") { ; altgr = leftCtrl + RightAlt, but on its own LeftCtrl + excl mark
					hotkeys.push({line:A_Index, hotkey:"Left Ctrl + !", comment:comment})
					continue
				}
				hk := SubStr(hkey, 1, -1)
				for i, e in hotkeyModifiers ; order in array important, shift must be first to ensure no "+" replacements
					hk := StrReplace(hk, e.mod, e.replacement . (e.mod != "<" && e.mod != ">" ? " + " : " "))
				hotkeys.Push({line:A_Index, hotkey:hk . SubStr(hkey, -1), comment:comment})
			}
		}
		return hotkeys
	}

	static getHotstrings(script) {
		Hotstrings := []
		Loop Parse, script, "`n", "`r" {
			if (RegExMatch(A_LoopField,"i)^\s*:([0-9\*\?BCKOPRSIEZ]*?):(.*?):`:(.*)\;?\s*(.*)", &match) || RegexMatch(A_LoopField, "i)^\s*(?:HotString|Hotstring)\(\`":([0-9\*\?BCKOPRSIEZ]*?):(.*?)\`",\`"(?:(.*)\`"),.*?\)\s*\;?\s*(.*)", &match))	{
				;// EXPLANATION: start of line : [possible modifiers only once]:[string]:(escape char):(seconds string)[check for spaces][comment] OR ALTERNATIVELY
				;// HotString(" (<- escaped via "" which turns into ", and that escaped via \ so \"" = ")[modifiers]:[string]","[replacement]", [variable which we don't need])
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
				Hotstrings.Push({line:A_Index, options:modifiers, hotstring:hString, replacestring:rString, comment:match[4]})
			}
		}
		return Hotstrings
	}

	static getSavedHotkeys()	{
		if 	!(FileExist(this.data.savedHotkeysPath)) {
			if !(DirExist(A_WorkingDir "\HotkeyManager"))
				DirCreate("HotkeyManager")
			FileAppend("// Add Custom Hotkeys not from the script here to show up in the Hotkey List.`n// Format is Hotkey/Hotstring:[hotkey/hotstring], [Program], [Command (optional)]", this.data.savedHotkeysPath)
			return []
		}
		savedHotkeysFull := FileOpen(this.data.savedHotkeysPath, "r", "UTF-8").Read()
		savedHotkeys := []
		Loop Parse, savedHotkeysFull, "`n", "`r"
			if RegExMatch(A_LoopField,"^(?!\s*;|//)Hotkey:\s*(.*)\s*,\s*(.*)\s*,\s*(.*)\s*", &match)
				savedHotkeys.Push({hotkey:match[1], program:match[2], comment:(match[3] == "" ? "None" : match[3])})
		return savedHotkeys
	}
}