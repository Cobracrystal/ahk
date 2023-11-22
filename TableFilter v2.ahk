; still todo
; listview that lists last used files when opening anew
; or menubar that lists them
; in settings option to delete all backups (or restore them)
; the option to open backup folder should also be in there (?)

#SingleInstance Force
; temporary
tableInstance := TableFilter()
tableInstance.guiCreate()
#Include "LibrariesV2\BasicUtilities.ahk"
#Include "LibrariesV2\JSON.ahk"


; idea -> tablefilter handles all the actual file stuff for a database
; guiInstance is one gui instance
; tab control for multiple files in one window?
class TableFilter {

	static __New() {

	}

	__New() {
		this.data := { savePath: A_AppData "\Autohotkey\Tablefilter", openFile: "", filename: "", ext: "", data: {}, keys: [], isSaved: true }
		this.guis := []
		this.menu := this.createMenu()

		this.settingsManager("Load")
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
		obj := Gui("+Border", this.base.__Class . SubStr(this.data.openFile, RegexMatch(this.data.openFile, "\\[^\\]*\.[^\\]+$") + 1))
		obj.OnEvent("Close", this.guiClose.bind(this))
		obj.OnEvent("Escape", this.guiClose.bind(this))
		obj.OnEvent("DropFiles", this.dropFiles.bind(this))
		GroupAdd("TableFilterGUIs", "ahk_id " obj.hwnd)
		if (this.data.openFile) {
			;	this.createSearchBoxesinGUI(this.data.keys)
			LV := obj.AddListView("xs R35 w950", this.data.keys) ; LVEvent, Altsubmit
			;	this.createAddLineBoxesinGUI(this.data.keys)
			obj.AddButton("yp-1 xp+37 r1 w100", "Add Row to List").OnEvent("Click", (*) => this.addLineToData())
			;	this.createFileButtonsinGUI()
			this.createFilteredList()
			; Wortart, Deutsch, Kayoogis, Runen, Anmerkung, Kategorie, Tema'i, dataIndex (possibly). At least dataindex always last.
			if !(this.settings.debug)
				LV.ModifyCol(LV.GetCount("Col"), 0)
			Loop (LV.GetCount("Col") - 1)
				LV.ModifyCol(A_Index, "AutoHdr")
			showString := "Center AutoSize"
		} else {
			obj.AddButton("x200 y190 r1 w100", "Load File").OnEvent("Click", this.loadData.bind(this, ""))
			showString := "Center w500 h400"
		}
		if (this.settings.darkMode)
			this.settingsHandler("darkmode", -1)
		this.guis.push(obj)
		obj.Show(showString)
	}

	createSearchBoxesInGUI() {

	}

	createAddLineBoxesinGUI() {

	}

	createFileButtonsinGUI() {

	}

	createFilteredList() {

	}

	searchDuplicates() {

	}

	filterTableRow() {

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

	guiClose(obj) {
		objRemoveValues(this.guis, , obj)
		obj.Destroy()
	}

	dropFiles(gui, ctrlObj, fileArr, x, y) {
		if (fileArr.Length > 1)
			return
		if (!this.data.isSaved)
			if (MsgBox("You have unsaved Changes. Load " fileArr[1] " anyway?") != "Ok")
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
		this.loadFile(path)
		; add option for tab controls here (aka supporting multiple files)

		; now, update gui or all guis with the new data. ????
		xmlString := data.Pop()
		metaData := data.Pop()
		keyArrLenOld := keyArray.Count()
		keyArray := data.Pop()
		guiName := SubStr(loadedFilePath, RegexMatch(loadedFilePath, "\\[^\\\n]*\.xml$")+1) . " - " . metaData.RowName
		if (flagUseBackups) {
			updateGUIsettings(,,false)
			SetTimer, backupIterator, Off
			backupIterator(1)
			SetTimer, backupIterator, % settingBackupInterval * 60000
			updateGUIsettings(,,true)
		}
		if (flagSimpleSaving)
			updateGUIsettings(loadedFilePath, false)
		else
			updateGUIsettings("",false)
		if (flagLoaded) && (keyArrLenOld == keyArray.Count()) {	;// true only if we have GUI windows and a database already + new & old have same key lengths.
			tHwnd := A_Gui
			if (filterGuiArray.Count() > 3) {
				Msgbox, 4, % "Open File", % "You have " . filterGuiArray.Count() . "GUI Windows Open. Loading a new file now will take some time to update. Close windows?"
				IfMsgBox No
				{
					updateGUIs(filterGuiArray)
					WinActivate, ahk_id %tHwnd%
				}
				else {
					while (filterGuiArray.Count() > 0) { ;// no for-loop here because the index shifts with every iteration. backwards for loop would be possible, but eh.
						guiHwnd := filterGuiArray.Pop()
						if (guiHwnd != tHwnd)
							GuiClose(guiHwnd)
					}
					Gui, %tHwnd%:Default
					GuiControl,,CheckboxDuplicates, 0
					createFilteredList()
				}
			}
			else {
				updateGUIs(filterGuiArray)
				WinActivate, ahk_id %tHwnd%
			}
		}
		else {
			while (filterGuiArray.Count() > 0)	;// no for-loop here because the index shifts with every iteration. backwards for loop would be possible, but eh.
				GuiClose(filterGuiArray.Pop())
			flagLoaded := true
			createMainGUI()
		}
		}
	}

	loadFile(path) {
		SplitPath(path, , , &ext, &fileName)
		this.data.fileName := fileName
		this.data.ext := ext
		this.data.openFile := path
		fileAsStr := FileRead(path, "UTF-8")
		if (ext = "json") {
			this.data.data := JSON.Load(fileAsStr)
			keys := []
			for i, e in this.data.data {
				for j, f in e {
					if !(objContainsValue(keys, j)) {
						keys.InsertAt(objContainsValue(keys, lastSeenKey) + 1, j)
					}
					lastSeenKey := j
				}
			}
			this.data.keys := keys
		} 
		else if (ext = "xml") {
			xmlString := ""
			Loop Parse, fileAsStr, "`n", "`r" {
				if(RegexMatch(A_LoopField, "^\s*<(.*?)>\s*$", &m)) {
					rowName := m[1]
					break
				}
			}
			data := []
			keys := []
			count := 1
			fileAsStr := StrReplace(fileAsStr, "<" rowName ">", "¶")
			Loop Parse, fileAsStr, "¶" {
				o := Map()
				flag := 0
				Loop Parse, A_LoopField, "`n", "`r" {
					if RegexMatch(A_LoopField, "O)<(.*?)>([\s\S]*?)<\/\1>", &m) {
						key := m[1]
						o[key] := m[2]
						if !(objContainsValue(keys, key)) {
							keys.InsertAt(objContainsValue(keys, lastSeenKey)+1, key)
						}
						lastSeenKey := key
					}
				}
				if (o.Count > 0)
					data.Push(o)
			}
			cleanData := []
			cleanData.Length := data.Length
			encode := Map("&apos", "'", "&amp", "&", "&quot", '"', "&gt", ">", "&lt", "<", "_x0027_", "'")
			for i, e in data {
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
				cleanData[i] := t
			}
			for i, e in keys {
				for j, k in encode {
					keys[i] := StrReplace(keys[i], j, k)
				}
			}
			this.data.data := cleanData
			this.data.keys := keys
		}
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