﻿; still todo
; listview that lists last used files when opening anew
; or menubar that lists them
; in settings option to delete all backups (or restore them)
; the option to open backup folder should also be in there (?)
; add checkbox to filter empty values next to duplicates
; figure out how to use icon for settings
; limit autohdr for columns to fixed max width (eg autohdr if < 200, else 200)
; settings usedefaultrunic -> needs runic translator function.
; queue for deletion instead of instantly deleting, then next filteredlist operation should do that
; listview headers
; option to change backcolor, font color
; font size??? adjust the controls accordingly?? (maybe with ctrl +?)
; do above ^, check in docs > gui > setfont > note at the end dialog box to pick font/color/icon
; add setting to reset to default setting

#SingleInstance Force
; temporary
tableInstance := TableFilter(1)
; tableInstance.guiCreate()
tableInstance.loadData()
#Include "LibrariesV2\BasicUtilities.ahk"
#Include "LibrariesV2\JSON.ahk"


; idea -> tablefilter handles all the actual file stuff for a database
; guiInstance is one gui instance
; tab control for multiple files in one window?
class TableFilter {

	static __New() {

	}

	__New(debug := 0) {
		this.data := {
			savePath: A_AppData "\Autohotkey\Tablefilter", 
			openFile: "", 
			data: [], 
			keys: [],
			defaultValues: Map(),
			isSaved: true, 
			isInBackup: true 
		}
		this.data.defaultValues.CaseSense := false
		this.data.defaultValues.Set("Wortart", "?", "Deutsch", "-", "Kayoogis", "-", "Tema'i", "0")
		this.guis := []
		this.menu := this.createMenu()

		this.settingsManager("Load")
		this.settings.debug := debug
		tableFilterMenu := TrayMenu.submenus["tablefilter"]
		tableFilterMenu.Add("Open GUI: ", (*) => this.guiCreate())
		tableFilterMenu.Add("Use Dark Mode", (iName, iPos, menuObj) => this.settingsHandler("Darkmode", -1, true, menuObj, iName))
		if (this.settings.darkMode)
			tableFilterMenu.Check("Use Dark Mode")
		tableFilterMenu.Add("Open Backup Folder", (*) => Run('explorer.exe "' this.data.savepath '"'))
		if (this.settings.darkMode)
			tableFilterMenu.Check("Use Dark Mode")
		A_TrayMenu.Add("Tablefilter", tableFilterMenu)
		HotIfWinactive("ahk_group TableFilterGUIs")
		;	Hotkey(this.settings.saveHotkey, (*) => this.directSave())
		HotIfWinactive()
		Hotkey(this.settings.guiHotkey, (*) => this.guiCreate())
		OnExit(this.exit.bind(this), 1)
	}

	guiCreate() {
		if (!this.data.openFile && this.guis.Length == 1) {
			WinActivate(this.guis[1].hwnd)
			return 0
		}
		newGui := Gui("+Border")
		newGui.OnEvent("Close", this.guiClose.bind(this))
		newGui.OnEvent("Escape", this.guiClose.bind(this))
		newGui.OnEvent("DropFiles", this.dropFiles.bind(this))
		newGui.SetFont("c0x000000") ; this is necessary to force font of checkboxes / groupboxes
		GroupAdd("TableFilterGUIs", "ahk_id " newGui.hwnd)
		if (this.data.openFile) {
			SplitPath(this.data.openFile, &name)
			newGui.Title := (this.data.isSaved ? "" : "*") this.base.__Class " - " name 
			newGui.AddGroupBox("Section w745 h42", "Search")
			for i, e in this.data.keys {
				t := newGui.AddText("ys+16 xp+" (i==1?10:55), e)
				t.GetPos(,, &w)
				newGui.AddEdit("ys+13 xp+" w+10 " r1 w45 vEditSearchCol" i).OnEvent("Change", this.createFilteredList.bind(this))
			}
			newGui.CBDuplicates := newGui.AddCheckbox("ys+13", "Find Duplicates")
			newGui.CBDuplicates.OnEvent("Click", this.searchDuplicates.bind(this))
			rowKeys := this.data.keys.Clone()
			rowKeys.push("DataIndex")
			newGui.LV := newGui.AddListView("xs R35 w950", rowKeys) ; LVEvent, Altsubmit
			newGui.LV.OnNotify(-155, this.LV_Event.bind(this, "Key"))
			newGui.LV.OnEvent("ContextMenu", this.LV_Event.bind(this, "ContextMenu"))
			newGui.LV.OnEvent("DoubleClick", this.LV_Event.bind(this, "DoubleClick"))
				this.createFilteredList(newGui, false)
				; Wortart, Deutsch, Kayoogis, Runen, Anmerkung, Kategorie, Tema'i, dataIndex (possibly). At least dataindex always last.
				if !(this.settings.debug)
					newGui.LV.ModifyCol(newGui.LV.GetCount("Col"), "0 Integer")
				else
					newGui.LV.ModifyCol(newGui.LV.GetCount("Col"), "Integer")
				Loop (newGui.LV.GetCount("Col") - 1)
					newGui.LV.ModifyCol(A_Index, "AutoHdr")
			this.createAddLineBoxesinGUI(newGui)
			newGui.AddButton("ys+9 xs+850 w100", "Load json/xml File").OnEvent("Click", this.loadData.bind(this, ""))
			newGui.AddButton("w100", "Export to File").OnEvent("Click", this.saveFile.bind(this))
			showString := "Center Autosize"
		} else {
			newGui.Title := this.base.__Class " - No File Selected" 
			newGui.AddButton("x200 y190 r1 w100", "Load File").OnEvent("Click", this.loadData.bind(this, ""))
			showString := "Center w500 h400"
		}
		if (this.settings.darkMode)
			this.toggleGuiDarkMode(newGui, 1)
		this.guis.push(newGui)
		newGui.Show(showString)
	}

	createAddLineBoxesinGUI(_gui, row := Map()) {
		_gui.AddGroupBox("Section w750 h65", "Add Row")
		for i, e in this.data.keys {
			_gui.AddText("ys+15 xs+" 10+((i-1) * 95), e)
			_gui.AddEdit("r1 w85 vEditAddRow" i, row.Has(e) ? row[e] : "").OnEvent("Change", this.validValueChecker.bind(this))
		}
		_gui.AddButton("ys+15 xs+" 10+95*this.data.keys.Length " h40 w65", "Add Row to List").OnEvent("Click", this.addEntry.bind(this))
	}

	createFilteredList(gui, *) {
		if (gui.HasProp("Gui"))
			gui := gui.Gui
		if (gui.CBDuplicates.Value) {
			this.searchDuplicates(gui.CBDuplicates)
			return
		}
		gui.Opt("+Disabled")
		gui.LV.Opt("-Redraw")
		gui.LV.Delete()
		for i, e in this.data.data {
			if (this.rowIncludeFromSearch(gui, e))
				this.addRow(gui, e, i)
		}
		if (gui.LV.GetCount() == 0)
			gui.LV.Add("", "/", "Nothing Found.")
		gui.LV.Opt("+Redraw")
		gui.Opt("-Disabled")
	}

	searchDuplicates(ctrlObj, *) {
		local gui := ctrlObj.Gui
		if !(ctrlObj.Value) {
			this.createFilteredList(gui)
			return
		}
		gui.Opt("+Disabled")
		gui.LV.Opt("-Redraw")
		gui.LV.Delete()
		filterKey := this.settings.duplicateColumn
		default := (this.data.defaultValues.Has(filterKey) ? this.data.defaultValues[filterKey] : "")
		duplicateMap := Map()
		duplicateMap.CaseSense := this.settings.filterCaseSense
		for i, row in this.data.data {
			v := row[filterKey]
			if (duplicateMap.has(v))
				duplicateMap[v].push([row, i])
			else
				duplicateMap[v] := [[row, i]]
		}
		for i, row in this.data.data {
			v := row[filterKey]
			if (v == "" || v == default)
				continue
			if (duplicateMap[v].Length > 1) {
				for _, arr in duplicateMap[v] {
					if (this.rowIncludeFromSearch(gui, arr[1]))
						this.addRow(gui, arr[1], arr[2])
				}
				duplicateMap[v] := []
			}
		}
		if (gui.LV.GetCount() == 0)
			gui.LV.Add("", "/", "Nothing Found.")
		gui.LV.Opt("+Redraw")
		gui.Opt("-Disabled")
	}

	rowIncludeFromSearch(gui, row) {
		for i, e in this.data.keys {
			v := gui["EditSearchCol" . i].Value
			if (v != "" && (!row.Has(e) || !InStr(row[e], v, this.settings.filterCaseSense))) {
				return false
			}
		}
		return true
	}

	addRow(gui, row, index) {
		rowArr := []
		for _, key in this.data.keys
			rowArr.push(row.Has(key) ? row[key] : "")
		rowArr.push(index)
		gui.LV.Add("",rowArr*)
	}

	addEntry(ctrlObj, *) {
		newRow := Map()
		aGui := ctrlObj.Gui
		for i, key in this.data.keys {
			newRow[key] := aGui["EditAddRow" i].Value
			aGui["EditAddRow" i].Value := ""
		}
		this.cleanRowData(newRow)		
		this.data.data.push(newRow)
		this.settingsHandler("isSaved", false, false)
		this.settingsHandler("isInBackup", false, false)
		for _, g in this.guis
			if (this.rowIncludeFromSearch(g, newRow))
				this.addRow(g, newRow, this.data.data.Length)
		aGui.LV.Modify(aGui.LV.GetCount(), "Select Focus Vis")
	}

	editRow() {
		; this should combine editRowFromMenu AND editSelectedRow ANd editRow (if it exists)
	}

	removeSelectedRows() {
		; note the plural

	}

	databaseitemremove() {

	}

	cleanRowData(row) { ; row is a map and this operates onto the object
		for i, e in this.data.keys {
			if (this.settings.useDefaultValues && (!row.Has(e) || row[e] == "")) {
				switch e, 0 {
					case "Wortart": ; 1 -> Wortart
						row[e] := this.data.defaultValues[e]
					case "Deutsch", "Kayoogis": ; 2,3 -> Deutsch, Kayoogis
						row[e] := this.data.defaultValues[e]
					case "Runen": ; Runen
						if (this.settings.useDefaultRunic)
							row[e] := "" ; todo
					case "Tema'i": ; Tema'i
						row[e] := this.data.defaultValues[e]
				}
			}
			if (i == 1)
				row[e] := Format("{:U}", row[e])
			row[e] := Trim(row[e])
		}
	}
	
	validValueChecker(ctrlObj, *) {
		newFont := (this.settings.darkMode ? "c0xFFFFFF Norm" : "cDefault Norm")
		switch this.data.keys[Integer(SubStr(ctrlObj.Name, -1))] {
			case "Wortart":
				if (!RegexMatch(ctrlObj.Value, "i)^[?nvaspg]?$"))
					newFont := "cRed Bold"
			case "Kayoogis":
				if (RegexMatch(ctrlObj.Value, "i)[cjqwx]"))
					newFont := "cBlue Bold"
			case "Runen":
				if (RegexMatch(ctrlObj.Value, "i)[a-z]"))
					newFont := "cRed Bold"
			case "Tema'i":
				if (!RegexMatch(ctrlObj.Value, "i)^[01]?$"))
					newFont := "cRed Bold"
			default:
				return
		}
		ctrlObj.SetFont(newFont)
	}

	toggleDarkMode(newValue, menuObj, iName) {
		if (newValue)
			menuObj.Check(iName)
		else
			menuObj.Uncheck(iName)
		for _, g in this.guis {
			this.toggleGuiDarkMode(g, newValue)
		}
		; todo: if editline or settings gui exists, those also need to be darkmoded
	}
		
	toggleGuiDarkMode(_gui, dark) {
		static WM_THEMECHANGED := 0x031A
		;// title bar dark
		if (VerCompare(A_OSVersion, "10.0.17763")) {
			attr := 19
			if (VerCompare(A_OSVersion, "10.0.18985")) {
				attr := 20
			}
			if (dark)
				DllCall("dwmapi\DwmSetWindowAttribute", "ptr", _gui.hwnd, "int", attr, "int*", true, "int", 4)
			else
				DllCall("dwmapi\DwmSetWindowAttribute", "ptr", _gui.hwnd, "int", attr, "int*", false, "int", 4)
		}
		_gui.BackColor := (dark ? this.settings.darkThemeColor : "Default") ; "" <-> "Default" <-> 0xFFFFFF
		font := (dark ? "c0xFFFFFF" : "cDefault")
		_gui.SetFont(font)
		for cHandle, ctrl in _gui {
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

	LV_Event(eventType, guiCtrl, lParam, *) {
		local gui := guiCtrl.Gui
		switch eventType, 0 {
			case "Key":
				vKey := NumGet(lParam, 24, "ushort")
				switch vKey {
					case 46: ; DEL key
						this.removeSelectedRows()
					case 67: ; C key
						if ((rowN := gui.LV.GetNext()) == 0)
							return
						if (GetKeyState("Ctrl")) {
							col := objContainsValue(this.data.keys, this.settings.copyColumn)
							A_Clipboard := (col ? gui.LV.GetText(rowN, col) : gui.LV.GetText(0))
						}
					case 116: ; F5 key
						this.createFilteredList(gui)
				}
			case "ContextMenu":
				this.menu.Show()
			case "DoubleClick":
				return ; todo
		}
	}


	createMenu() {
		aMenu := Menu()
		aMenu.Add("👨‍👩‍👧 Familie", this.cMenuHandler.bind(this))
		aMenu.Add("🖌️ Farbe", this.cMenuHandler.bind(this))
		aMenu.Add("⛰️ Geographie", this.cMenuHandler.bind(this))
		aMenu.Add("💎 Geologie", this.cMenuHandler.bind(this))
		aMenu.Add("🌟 Gestirne", this.cMenuHandler.bind(this))
		aMenu.Add("💥 Magie", this.cMenuHandler.bind(this))
		aMenu.Add("🍗 Nahrung", this.cMenuHandler.bind(this))
		aMenu.Add("👕 Kleidung", this.cMenuHandler.bind(this))
		aMenu.Add("🖐️ Körper", this.cMenuHandler.bind(this))
		aMenu.Add("🏘️ Orte", this.cMenuHandler.bind(this))
		aMenu.Add("🌲 Pflanzen", this.cMenuHandler.bind(this))
		aMenu.Add("🐕 Tiere ", this.cMenuHandler.bind(this))
		aMenu.Add("🌧️ Wetter", this.cMenuHandler.bind(this))
		aMenu.Add("🔢 Zahl", this.cMenuHandler.bind(this))
		rMenu := Menu()
		rMenu.Add("👨‍👩‍👧 Familie", this.cMenuHandler.bind(this))
		rMenu.Add("🖌️ Farbe", this.cMenuHandler.bind(this))
		rMenu.Add("⛰️ Geographie", this.cMenuHandler.bind(this))
		rMenu.Add("💎 Geologie", this.cMenuHandler.bind(this))
		rMenu.Add("🌟 Gestirne", this.cMenuHandler.bind(this))
		rMenu.Add("💥 Magie", this.cMenuHandler.bind(this))
		rMenu.Add("🍗 Nahrung", this.cMenuHandler.bind(this))
		rMenu.Add("👕 Kleidung", this.cMenuHandler.bind(this))
		rMenu.Add("🖐️ Körper", this.cMenuHandler.bind(this))
		rMenu.Add("🏘️ Orte", this.cMenuHandler.bind(this))
		rMenu.Add("🌲 Pflanzen", this.cMenuHandler.bind(this))
		rMenu.Add("🐕 Tiere ", this.cMenuHandler.bind(this))
		rMenu.Add("🌧️ Wetter", this.cMenuHandler.bind(this))
		rMenu.Add("All", this.cMenuHandler.bind(this))
		rMenu.Add("🔢 Zahl", this.cMenuHandler.bind(this))
		tMenu := Menu()
		tMenu.Add("Edit Selected Row", this.cMenuHandler.bind(this))
		tMenu.Add("Delete Selected Row(s)", this.cMenuHandler.bind(this))
		tMenu.Add("Add Category to Selected Row(s)", aMenu)
		tMenu.Add("Remove Category from Selected Row(s)", rMenu)
		return tMenu
	}


	cMenuHandler(itemName, itemPos, menuObj) {
		; this should handle both menus
	}

	guiClose(guiObj) {
		objRemoveValue(this.guis, guiObj)
		guiObj.Destroy()
	}

	dropFiles(gui, ctrlObj, fileArr, x, y) {
		if (fileArr.Length > 1)
			return
		this.loadData(fileArr[1], gui)
	}

	loadData(file := "", guiObj := {}, *) {
		if (guiObj.HasOwnProp("Gui"))
			guiObj := guiObj.gui
		if (!this.data.isSaved) {
			res := MsgBox("You have unsaved Changes in " this.data.openFile "`nSave Changes before loading " (file ? file : "a new File") "?", this.base.__Class, "0x3 Owner" A_ScriptHwnd)
			if (res == "Cancel")
				return
			else if (res == "Yes")
				this.saveFile()
		}
		if (file == "") {
			path := this.settings.lastUsedFile ? this.settings.lastUsedFile : A_ScriptDir
			for i, e in this.guis
				e.Opt("+Disabled")
			file := FileSelect("3", path, "Load File", "Data (*.xml; *.json)")
			for i, e in this.guis
				e.Opt("-Disabled")
			if (!file)
				return
		}
		this.loadFile(file)
		; add option for tab controls here (aka supporting multiple files)

		while(this.guis.Length > 0)
			this.guiClose(this.guis.pop())
		; now, update gui or all guis with the new data. ????
		if (this.settings.useBackups) {
			; update backup function
		}
		this.guiCreate()
		this.settingsHandler("lastUsedFile", file)
		this.settingsHandler("isSaved", true, false)
	}

	loadFile(path) {
		SplitPath(path, , , &ext, &fileName)
		this.data.openFile := path
		fileAsStr := FileRead(path, "UTF-8")
		lastSeenKey := ""
		if (ext = "json") {
			data := JSON.Load(fileAsStr)
			keys := []
			for i, e in data {
				for j, f in e {
					if !(objContainsValue(keys, j)) {
						keys.InsertAt(objContainsValue(keys, lastSeenKey) + 1, j)
					}
					lastSeenKey := j
				}
			}
		}
		else if (ext = "xml") {
			Loop Parse, fileAsStr, "`n", "`r" {
				if (RegexMatch(A_Loopfield, "^\s*<\?") || RegexMatch(A_LoopField, "^\s*<dataroot"))
					continue
				if(RegexMatch(A_LoopField, "^\s*<(.*?)>\s*$", &m)) {
					rowName := m[1]
					break
				}
			}
			rawData := []
			data := []
			keys := []
			count := 1
			fileAsStr := StrReplace(fileAsStr, "<" rowName ">", "¶")
			Loop Parse, fileAsStr, "¶" {
				row := Map()
				flag := 0
				Loop Parse, A_LoopField, "`n", "`r" {
					if RegexMatch(A_LoopField, "<(.*?)>([\s\S]*?)<\/\1>", &m) {
						key := m[1]
						row[key] := m[2]
						if !(objContainsValue(keys, key)) {
							keys.InsertAt(objContainsValue(keys, lastSeenKey)+1, key)
						}
						lastSeenKey := key
					}
				}
				if (row.Count > 0)
					rawData.Push(row)
			}
			data.Length := rawData.Length
			encode := Map("&apos", "'", "&amp", "&", "&quot", '"', "&gt", ">", "&lt", "<", "_x0027_", "'")
			for i, e in rawData {
				t := Map()
				for j, f in e {
					s1 := j
					s2 := f
					for k, g in encode {
						s1 := StrReplace(s1, k, g)
						s2 := StrReplace(s2, k, g)
					}
					t[s1] := s2
				}
				data[i] := t
			}
			for i, e in keys {
				for j, k in encode {
					keys[i] := StrReplace(keys[i], j, k)
				}
			}
		}
		this.data.keys := keys
		this.data.data := data
	}

	saveFile(*) {
		; THIS SHOULD COMBINE directsave AND exportFile AND exportToFileGUI
	}

	backupIterator() {
		; instead of a timer or something, this should save the current time once and on every change this gets called, and if enough time has passed -> backup is made
	}

	deleteExtraBackups() {

	}

	debugShowDatabaseEntry() {

	}

	settingsHandler(setting := "", value := "", save := true, extra*) {
		switch setting, 0 {
			case "darkmode":
				this.settings.darkMode := (value == -1 ? !this.settings.darkMode : value)
				this.toggleDarkMode(this.settings.darkMode, extra*)
			case "lastUsedFile":
				this.settings.lastUsedFile := value
			case "isSaved":
				this.data.isSaved := (value == -1 ? !this.data.isSaved : value)
				for _, g in this.guis {
					if (this.data.isSaved && SubStr(g.Title, 1, 1) == "*")
						g.Title := SubStr(g.Title, 2)
					else if (!this.data.isSaved && SubStr(g.Title, 1, 1) != "*")
						g.Title := "*" . g.Title
				}
			case "isInBackup":
				this.data.isInBackup := (value == -1 ? !this.data.isInBackup : value)
			default:
				throw Error("uhhh setting: " . setting)
		}
		if (save)
			this.settingsManager("Save")
	}

	settingsManager(mode := "Save") {
		mode := Substr(mode, 1, 1)
		if (!Instr(FileExist(this.data.savePath), "D"))
			DirCreate(this.data.savePath)
		if (mode == "S") {
			f := FileOpen(this.data.savePath . "\settings.json", "w", "UTF-8")
			f.Write(JSON.Dump(this.settings))
			f.Close()
			return 1
		}
		else if (mode == "L") {
			this.settings := {}
			if (FileExist(this.data.savePath "\settings.json")) {
				try this.settings := JSON.Load(FileRead(this.data.savePath "\settings.json", "UTF-8"), , false)
			}
			; populate remaining settings with default values
			for i, e in Tablefilter.getDefaultSettings().OwnProps() {
				if !(this.settings.HasOwnProp(i))
					this.settings.%i% := e
			}
			return 1
		}
		return 0
	}

	;// GUI functions

	editRowGuiEscape() {
		; todo
		; Gui, %editLineGUIOwnerHwnd%:-Disabled
		; Gui, %GuiHwnd%:Destroy
		; return
	}

	exit(exitReason, exitCode, *) {
		if (exitReason == "Logoff" || exitReason == "Shutdown") {
			if (!this.data.isSaved) {
				res := MsgBox("You have unsaved Changes in " this.data.openFile "`nSave Changes before loading " (file ? file : "a new File") "?", this.base.__Class, "0x3 Owner" A_ScriptHwnd)
				if (res == "Cancel")
					return 1
				else if (res == "No")
					return 0
				else if (res == "Yes") {
					this.saveFile()
				}
			}
		}
	}

	static getDefaultSettings() {
		settings := {
			debug: false,
			darkMode: true,
			darkThemeColor: "0x1E1E1E",
			simpleSaving: true,
			autoSaving: true,
			useBackups: true,
			backupAmount: 4, ; amount of files to be kept
			backupInterval: 15, ; in minutes
			useDefaultValues: true,
			useDefaultRunic: true,
			duplicateColumn: "Deutsch",
			copyColumn: "Runen",
			filterCaseSense: false,
			saveHotkey: "^s", ; IS THIS NECESSARY THO?????
			guiHotkey: "^p",
			lastUsedFile: ""
		}
		return settings
	}
}