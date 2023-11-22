; still todo
; listview that lists last used files when opening anew
; or menubar that lists them
; in settings option to delete all backups (or restore them)
; the option to open backup folder should also be in there (?)

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
		this.data := { savePath: A_AppData "\Autohotkey\Tablefilter", openFile: "", data: [], keys: [], isSaved: true }
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
		newGui := Gui("+Border", this.base.__Class . " - " . (this.data.openFile ? SubStr(this.data.openFile, RegexMatch(this.data.openFile, "\\[^\\]*\.[^\\]+$") + 1) : "Select file."))
		newGui.OnEvent("Close", this.guiClose.bind(this))
		newGui.OnEvent("Escape", this.guiClose.bind(this))
		newGui.OnEvent("DropFiles", this.dropFiles.bind(this))
		GroupAdd("TableFilterGUIs", "ahk_id " newGui.hwnd)
		if (this.data.openFile) {
			;	this.createSearchBoxesinGUI()
			rowKeys := this.data.keys.Clone()
			rowKeys.push("DataIndex")
			newGui.LV := newGui.AddListView("R35 w950", rowKeys) ; LVEvent, Altsubmit
			;	this.createAddLineBoxesinGUI()
			newGui.AddButton("r1 w100", "Add Row to List").OnEvent("Click", (*) => this.addLineToData())
			;	this.createFileButtonsinGUI()
			this.createFilteredList(newGui, false)
			; Wortart, Deutsch, Kayoogis, Runen, Anmerkung, Kategorie, Tema'i, dataIndex (possibly). At least dataindex always last.
			if !(this.settings.debug)
				newGui.LV.ModifyCol(newGui.LV.GetCount("Col"), "0 Integer")
			else
				newGui.LV.ModifyCol(newGui.LV.GetCount("Col"), "Integer")
			Loop (newGui.LV.GetCount("Col") - 1)
				newGui.LV.ModifyCol(A_Index, "AutoHdr")
				; this needs to do autohdr within a limit (as in, autohdr if <200 width else limit to 200. Possible how?)
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

	createSearchBoxesInGUI() {

	}

	createAddLineBoxesinGUI() {

	}

	createFileButtonsinGUI() {

	}

	createFilteredList(_gui, isExist := false) {
		if (isExist) {
			_gui.Opt("+Disabled")
			_gui.LV.Opt("-Redraw")
			_gui.LV.Delete()
		}
		count := 1
		for i, e in this.data.data {
			if (this.filterTableRow(e)) {
				row2 := []
				for _, key in this.data.keys
					row2.push(e.Has(key) ? e[key] : "")
				row2.push(count)
				_gui.LV.Add("",row2*)
			}
			count++
		}
		if (isExist) {
			if (_gui.LV.GetCount() == 0)
				_gui.LV.Add("Col2", "/", "No Results Found.")
			_gui.LV.Opt("+Redraw")
			_gui.Opt("-Disabled")
		}
	}

	listViewAddRow(row) {

	}

	searchDuplicates() {

	}

	filterTableRow(row) {
		return true
	}

	addRow() {

	}

	addLineToData() {

	}

	trimRowValues() {

	}

	editRow() {

	}

	editRowFromMenu() {

	}

	removeSelectedRow() {

	}

	databaseitemremove() {

	}

	databaseiteminsert() {

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

	addLineBoxChecker() {

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
			duplicateColumn: "Deutsch",
			saveHotkey: "^s", ; IS THIS NECESSARY THO?????
			guiHotkey: "^p",
			lastUsedFile: ""
		}
		return settings
	}
}