; still todo
; listview that lists last used files when opening anew
; or menubar that lists them
; in settings option to delete all backups (or restore them)
; the option to open backup folder should also be in there (?)
; add checkbox to filter empty values next to duplicates
; figure out how to use icon for settings
; limit autohdr for columns to fixed max width (eg autohdr if < 200, else 200)
; settings usedefaultrunic -> needs runic translator function.
; instead of tooltip and disabled gui, use actual progress window (like magicbox example) to display duplicate progress (also makes escape as interruption clearer)
; while checkbox duplicates is checked, normal searching should still take that into account
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
		tableFilterMenu.Add("Use Dark Mode", (iName, iPos, menuObj) => (menuObj.ToggleCheck("Use Darkmode"), this.settingHandler("Darkmode", -1)))
		tableFilterMenu.Add("Open Backup Folder", (*) => Run('explorer.exe "' this.data.savepath '"'))
		if (this.settings.darkMode)
			tableFilterMenu.Check("Use Dark Mode")
		A_TrayMenu.Add("Tablefilter", tableFilterMenu)
		HotIfWinactive("ahk_group TableFilterGUIs")
		;	Hotkey(this.settings.saveHotkey, (*) => this.directSave())
		HotIfWinactive()
		Hotkey(this.settings.guiHotkey, (*) => this.guiCreate())
		OnExit(this.exit, 1)
	}

	guiCreate() {
		if (!this.data.openFile && this.guis.Length == 1) {
			WinActivate(this.guis[1].hwnd)
			return 0
		}
		newGui := Gui("+Border", this.base.__Class . " - " . (this.data.openFile ? SubStr(this.data.openFile, RegexMatch(this.data.openFile, "\\[^\\]*\.[^\\]+$") + 1) : "Select file"))
		newGui.OnEvent("Close", this.guiClose.bind(this))
		newGui.OnEvent("Escape", this.guiClose.bind(this))
		newGui.OnEvent("DropFiles", this.dropFiles.bind(this))
		GroupAdd("TableFilterGUIs", "ahk_id " newGui.hwnd)
		if (this.data.openFile) {
			newGui.AddGroupBox("Section w745 h42", "Search")
			for i, e in this.data.keys {
				t := newGui.AddText("ys+16 xp+" (i==1?10:55), e)
				t.GetPos(,, &w)
				newGui.AddEdit("ys+13 xp+" w+10 " r1 w45 vEditSearchCol" i).OnEvent("Change", this.createFilteredList.bind(this))
			}
			newGui.AddCheckbox("ys+13", "Find Duplicates").OnEvent("Click", this.searchDuplicates.bind(this))
			rowKeys := this.data.keys.Clone()
			rowKeys.push("DataIndex")
			newGui.LV := newGui.AddListView("xs R35 w950", rowKeys) ; LVEvent, Altsubmit
				this.createFilteredList(newGui, false)
				; Wortart, Deutsch, Kayoogis, Runen, Anmerkung, Kategorie, Tema'i, dataIndex (possibly). At least dataindex always last.
				if !(this.settings.debug)
					newGui.LV.ModifyCol(newGui.LV.GetCount("Col"), "0 Integer")
				else
					newGui.LV.ModifyCol(newGui.LV.GetCount("Col"), "Integer")
				Loop (newGui.LV.GetCount("Col") - 1)
					newGui.LV.ModifyCol(A_Index, "AutoHdr")
			this.createAddLineBoxesinGUI(newGui)
			newGui.AddButton("ys+9 xp+160 w100", "Load json/xml File").OnEvent("Click", (*) => this.loadData())
			newGui.AddButton("w100", "Export to File").OnEvent("Click", (*) => this.exportFile())
			showString := "Center Autosize"
		} else {
			newGui.AddButton("x200 y190 r1 w100", "Load File").OnEvent("Click", this.loadData.bind(this, ""))
			showString := "Center w500 h400"
		}
		if (this.settings.darkMode)
			this.settingsHandler("darkmode", -1)
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
			this.createFilteredList(ctrlObj.Gui)
			return
		}
		gui.LV.Opt("-Redraw")
		gui.LV.Delete()
		duplArr := []
		filterKey := this.settings.duplicateColumn
		total := (this.data.data.Length * (this.data.data.Length-1))/2
		gui.Opt("+Disabled")
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
			if (v == "" || v == this.data.defaultValues[filterKey])
				continue
			if (duplicateMap[v].Length > 1) {
				for _, arr in duplicateMap[v] {
					if (this.rowIncludeFromSearch(gui, arr[1]))
						this.addRow(gui, arr[1], arr[2])
				}
				duplicateMap[v] := []
			}
		}
		gui.Opt("-Disabled")
		gui.LV.Opt("+Redraw")
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
						row[e] := this.data.defaultValues[0]
				}
			}
			if (i == 1)
				row[e] := Format("{:U}", row[e])
			row[e] := Trim(row[e])
		}
	}

	editRow() {

	}

	editRowFromMenu() {

	}

	removeSelectedRow() {

	}

	databaseitemremove() {

	}

	editSelectedRow() {

	}

	exportToFileGUI() {

	}

	updateGUIs() {

	}

	updateGUISettings() {

	}

	updateGUIColors() {

	}

	toggleDarkMode() {

	}

	validValueChecker(ctrlObj, *) {
		newFont := (this.settings.darkMode ? "c0xFFFFFF" : "cDefault Norm")
		switch Integer(SubStr(ctrlObj.Name, -1)) {
			case 1: ; 1 -> Wortart
				if (!RegexMatch(ctrlObj.Value, "i)^[?nvaspg]?$"))
					newFont := "cRed Bold"
			case 3: ; 3 -> Kayoogis
				if (RegexMatch(ctrlObj.Value, "i)[cjqwx]"))
					newFont := "cBlue Bold"
			case 4: ; Runen
				if (RegexMatch(ctrlObj.Value, "i)[a-z]"))
					newFont := "cRed Bold"
			case 7: ; Tema'i
				if (!RegexMatch(ctrlObj.Value, "i)^[01]?$"))
					newFont := "cRed Bold"
			default:
				return
		}
		ctrlObj.SetFont(newFont)
	}

	lvEvent() {

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

	directSave() {
		; use merged save function, this is stupid
	}

	loadData(file := "", guiObj := {}, *) {
		if (guiObj.HasOwnProp("Gui"))
			guiObj := guiObj.gui
		if (!this.data.isSaved) && (MsgBox("You have unsaved Changes in " this.data.openFile "`nSave Changes before loading " (file ? file : "a new File") "?", "Tablefilter", "0x3 Owner" guiObj.hwnd) != "OK")
			return
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
		this.settingsHandler("lastUsedFile", file)
		this.loadFile(file)
		; add option for tab controls here (aka supporting multiple files)

		; now, update gui or all guis with the new data. ????
		if (this.settings.useBackups) {
			; update backup function
		}
		for i, e in this.guis
			e.Destroy()
		while(this.guis.Length > 0)
			this.guiClose(this.guis.pop())
		this.guiCreate()
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

	exportFile() {

	}


	backupIterator() {
		; instead of a timer or something, this should save the current time once and on every change this gets called, and if enough time has passed -> backup is made
	}

	deleteExtraBackups() {

	}

	debugShowDatabaseEntry() {

	}



	settingsHandler(setting := "", value := "", save := true) {
		switch setting, 0 {
			case "darkmode":
				this.settings.darkMode := (value == -1 ? !this.settings.darkMode : value)
			case "lastUsedFile":
				this.settings.lastUsedFile := value
			case "isSaved":
				this.data.isSaved := (value == -1 ? !this.data.isSaved : value)
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

	exit(*) {

	}


	class guiInstance {

	}

	static getDefaultSettings() {
		settings := {
			debug: false,
			darkMode: true,
			darkThemeColor: 0x36393F,
			simpleSaving: true,
			autoSaving: true,
			useBackups: true,
			backupAmount: 4, ; amount of files to be kept
			backupInterval: 15, ; in minutes
			useDefaultValues: true,
			useDefaultRunic: true,
			duplicateColumn: "Deutsch", ; maybe use index instead? as in, 2/3/4
			filterCaseSense: false,
			saveHotkey: "^s", ; IS THIS NECESSARY THO?????
			guiHotkey: "^p",
			lastUsedFile: ""
		}
		return settings
	}
}