; still todo


#SingleInstance Force
; temporary
tableInstance := TableFilter()

; Ordering:

#Include "LibrariesV2\BasicUtilities.ahk"
#Include "LibrariesV2\JSON.ahk"


; idea -> tablefilter handles all the actual file stuff for a database
; guiInstance is one gui instance
class TableFilter {
	
	static __New() {

	}

	__New() {
		this.data := {savePath: A_AppData "\Autohotkey\Tablefilter", openFile:"", data: {}, keys:[]}
		this.guis := []
		this.menu := this.createMenu()

		this.settings := this.settingsManager("Load")
		tableFilterMenu := TrayMenu.submenus["tablefilter"]
		tableFilterMenu.Add("Open GUI: ", (*) => this.guiCreate())
		tableFilterMenu.Add("Use Dark Mode", (iName, iPos, menuObj) => (menuObj.ToggleCheck("Use Darkmode"), this.settingHandler("Darkmode", -1)))
		tableFilterMenu.Add("Open Backup Folder", (*) => Run('explorer.exe "' this.data.savepath '"'))
		if (this.settings.darkMode)
			tableFilterMenu.Check("Use Dark Mode")
		A_TrayMenu.Add("Tablefilter", tableFilterMenu)
		HotIfWinactive("ahk_group TableFilterGUIs")
		Hotkey(this.settings.saveHotkey, (*) => this.directSave())
		HotIfWinactive()
		Hotkey(this.settings.guiHotkey, (*) => this.createMainGUI())
		OnExit(this.exit, 1)
	}

	guiCreate() {
		if (!this.data.openFile) {
			if (this.guis.Length > 1)
				throw Error("placeholder 0x89234")
			WinActivate(this.guis[1].hwnd)
			return 0
		}
		obj := Gui("+Border", SubStr(this.data.openFile, RegexMatch(this.data.openFile, "\\[^\\]*\.[^\\]+$")+1))
		obj.OnEvent("Close", this.guiClose.bind(this))
		obj.OnEvent("Escape", this.guiClose.bind(this))
		obj.OnEvent("DropFiles", this.dropFiles.bind(this))
		GroupAdd("TableFilterGUIs", "ahk_id " obj.hwnd)
		s := "DATAINDEX"
		this.createSearchBoxesinGUI(this.data.keys)
		LV := obj.AddListView("xs R35 w950", this.data.keys) ; LVEvent, Altsubmit
		this.createAddLineBoxesinGUI(this.data.keys)
		obj.AddButton("yp-1 xp+37 r1 w100", "Add Row to List").OnEvent("Click", (*) => this.addLineToData())
		this.createFileButtonsinGUI()
		this.createFilteredList()
		; Wortart, Deutsch, Kayoogis, Runen, Anmerkung, Kategorie, Tema'i, dataIndex (possibly). At least dataindex always last.
		if !(this.settings.debug)
			LV.ModifyCol(LV.GetCount("Col"), 0)
		Loop(LV.GetCount("Col") - 1)
			LV.ModifyCol(A_Index, "AutoHdr")
		if (this.settings.darkMode)
			this.settingsHandler("darkmode", -1)
		this.guis.push({gui:obj, lv:LV})
		obj.Show("Center Autosize")
	}

	createSearchBoxesInGUI() {

	}

	createAddLineBoxesinGUI() {

	}

	createFileButtonsinGUI() {

	}

	createFilteredList() {

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

	guiClose() {

	}

	dropFiles() {
		; 
	}

	directSave() {

	}

	settingHandler(setting, mode := -1) {
		switch setting, 0 {
			case "darkmode":
				return
		}
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
		settings := { debug: false
			, darkMode: true
			, darkThemeColor: 0x36393F
			, simpleSaving: true
			, autoSaving: true
			, useBackups: true
			, backupAmount: 4 ; amount of files to be kept
			, backupInterval: 15 ; in minutes
			, useDefaultValues: true
			, duplicateColumn: "Deutsch"
			, ytdlPath: ""
			, saveHotkey: "^s" ; IS THIS NECESSARY THO?????
			, guiHotkey: "^p"}
		return settings
	}
}