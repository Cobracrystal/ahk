#NoEnv
#SingleInstance Force
#Persistent
SendMode Input
;// ######### SETTINGS #######################
settingDarkThemeColor := 0x36393F ;// color for dark theme, discord grey (0x36393F) is default.
settingflagSimpleSaving := 1 ;// saves automatically to currently opened file
settingflagAutoSaving := 1	;// automatically save when exiting/closing the program/GUI
settingflagUseBackups := 1	;// create backups or not. Backups are not automatically deleted.
settingBackupAmount := 4 ;// corresponds to 1 hour of backups (if default interval)
settingBackupInterval := 15 ;// in minutes
settingflagDebug := 0 ;// debug, duh
settingflagUseDefaultValues := 1 ;// replace newly added empty entries with ?,-,etc
settingDuplicateFilter := "Deutsch" ;// default value to search in duplicateList for
settingHotkeyAsStringSave := "^s" ;// hotkey for quicksaving. default ^s
settingHotkeyAsStringReload := "^+f" ;// hotkey for reloading script. default ^+r
settingHotkeyAsStringGUI := "^p"
settingIconPath := "E:\OneDrive\Auto HotKey Scripts\icons\a-runic.ico"

; ##################################

table := new TableFilter()
table.loadData()
table.createMainGUI()

;// MENU
createTrayMenu(table.getDarkMode(), iconPath)
;// functions etc
OnExit("CustomExit")	;// custom exit so that i can show a "you have unsaved changes" dialog
Hotkey, %reloadHotkeyAsString%, reloadScript 
return

;// gui creation functions

class TableFilter {
	static instance := false
	static appDataPath := A_Appdata . "\Autohotkey\TableFilter"
	localFlagLoaded := false
	localFlagAbortDuplicate := false
	localFlagUseDarkMode := false
	localFlagHasUnsavedChanges := false
	data := {}
	keyArray := []
	guiName := ""
	guiArray := []
	
	__New() {
		if !(this.instance) {
			if !(FileExist(appDataPath))
				FileCreateDir, % appDataPath
			IniRead, localFlagUseDarkMode, % appDataPath . "\TableFilter.ini", Settings, DarkMode, 0
			Hotkey, IfWinActive, ahk_group tableFilterGUIGroup
			Hotkey, %settingHotkeyAsStringSave%, base.saveToDefaultFile()
			Hotkey, IfWinActive
			Hotkey, %settingHotkeyAsStringGUI%, base.createGUI()
			this.instance := true
		}
	}
	
	getFlagUseDarkmode() {
		return this.localFlagUseDarkMode
	}
	setFlagUseDarkmode(aDarkmode) {
		this.localFlagUseDarkMode := aDarkmode
		IniWrite, % aDarkmode, % appDataPath . "\TableFilter.ini", Settings, DarkMode
	;	updateGUIColors(aDarkmode)	
	}
	getFlagHasUnsavedChanges() {
		return this.localFlagHasUnsavedChanges
	}
	setFlagHasUnsavedChanges(aUnsaved) {
		return (this.localFlagHasUnsavedChanges := aUnsaved)
	}
	
	saveToDefaultFile() {
		return 0
	}
	
	createGUI() {
		gui := new GUI(guiName)
		keyArray.push(gui)
		gui.show()
	}
	
	class GUI {
		LV := ""
		checkboxDuplicates := false
		hwnd := ""
	}
}

;// generic functions

getKeyPos(arr, key) {
	for i, e in arr
		if (key == e)
			return i
	return 0
}

arrayContains(array, searchfor) {
	for i, Element in array {
		if(Element == searchfor) {
			return 1
			break
		}
	}
	return 0
}

arraySort(arr, options) {
	if	!isObject(arr)
		return 0
	newArr := []
	for i, item in arr
		list .=	item . "`n"
	list :=	Trim(list,"`n")
	Sort, list, % options
	Loop, parse, list, `n, `r
		newArr.push(A_LoopField)
	return newArr
}

arrayDeleteValue(ByRef arr, val) {
	l := arr.Count()
	for i, e in arr
		if (arr[l-i+1] == val)
			arr.RemoveAt(l-i+1)
}

ReplaceChars(Text, Chars, ReplaceChars) {
	ReplacedText := Text
	Loop, parse, Text, 
	{
		Index := A_Index
		Char := A_LoopField
		Loop, parse, Chars,
		{
			if (A_LoopField = Char) {
				ReplacedText := SubStr(ReplacedText, 1, Index-1) . SubStr(ReplaceChars, A_Index, 1) . SubStr(ReplacedText, Index+1)
				break
			}
		}
	}
	return ReplacedText
}

;// ahk script functions
createTrayMenu(darkModeToggle, iconPath) {
	Menu, Tray, Add, Open GUI, trayMenuHandler ;// a button to create another window
	Menu, Tray, Add, Use Darkmode, trayMenuHandler
	Menu, Tray, Add, Open Backup Folder, trayMenuHandler
	Menu, Tray, Add 
	Menu, Tray, Add, Open Recent Lines, trayMenuHandler
	Menu, Tray, Add, Help, trayMenuHandler
	Menu, Tray, Add
	Menu, Tray, Add, Reload, trayMenuHandler
	Menu, Tray, Add, Edit Script, trayMenuHandler
	Menu, Tray, Add
	Menu, pauseSuspendMenu, Add, Suspend Hotkeys, trayMenuHandler
	Menu, pauseSuspendMenu, Add, Suspend Reload, trayMenuHandler
	Menu, Tray, Add, Suspend/Stop, :pauseSuspendMenu 
	Menu, Tray, Add, Exit, trayMenuHandler
	Menu, Tray, NoStandard
	Menu, Tray, Default, Open GUI
	if (darkModeToggle)
		Menu, Tray, Check, Use Darkmode
	try	;// we dont want an error on icon loading.
		Menu, Tray, Icon, %iconPath%,,1
}

trayMenuHandler(menuLabel) {
	global table
	global reloadHotkeyAsString
	switch menuLabel {
		case "Open GUI":
			table.createGUI()
		case "Use Darkmode":
			Menu, Tray, ToggleCheck, Use Darkmode
			table.setFlagUseDarkmode(!table.getFlagUseDarkmode())
		case "Open Backup Folder":
			run, % "explorer.exe """ . table.getAppdataPath . """"
		case "Open Recent Lines":
			ListLines
		case "Help":
			Run, % RegexReplace(A_AhkPath, "AutoHotkey.exe$", "AutoHotkey.chm")
		case "Reload":
			Reload
		case "Edit Script":
			try
				Run, % A_ProgramFiles . "\Notepad++\notepad++.exe " . A_ScriptFullPath
			catch e
				Run, notepad %A_ScriptFullPath%
		case "Suspend Hotkeys":
			Menu, pauseSuspendMenu, ToggleCheck, Suspend Hotkeys
			Suspend, Toggle
		case "Suspend Reload":
			Menu, pauseSuspendMenu, ToggleCheck, Suspend Reload
			Hotkey, %reloadHotkeyAsString%, Toggle
		case "Exit":
			ExitApp
		default:
	}
}

CustomExit(ExitReason, ExitCode) {
	global table
	global settingflagAutoSaving
	if !(arrayContains(["LogOff", "Shutdown", "Error"], ExitReason)) {
		if (table.getFlagHasUnsavedChanges()) {
			if (settingflagAutoSaving)
				table.saveToDefaultFile()
			else if (ExitReason != Reload) {
				MsgBox, 1,, % "You have unsaved Changes. Do you still want to exit?"
				IfMsgBox, Cancel
					return 1
			}
		}
	}
}

;// debug functions

debugShowDataBaseEntry(n, keyArray) {
	global data
	row := data[n]
	s := "n: " . n . "`n" . keyArray[1] . ": " . row[keyArray[1]] . "`n" . keyArray[2] . ": " . row[keyArray[2]] . "`n" . keyArray[3] . ": " . row[keyArray[3]] . "`n" . keyArray[4] . ": " . row[keyArray[4]] . "`n" . keyArray[5] . ": " . row[keyArray[5]] . "`n" . keyArray[6] . ": " . row[keyArray[6]] . "`n" . keyArray[7] . ": " . row[keyArray[7]] . "`n" . "Index: " . row["index"]
	msgbox % s
}

reloadScript() {
	Reload
	return
}

