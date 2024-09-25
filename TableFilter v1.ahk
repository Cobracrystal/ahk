#NoEnv
#SingleInstance Force
#Persistent
SendMode Input
StringCaseSense, Locale
filterGuiArray := []	;// this is to manage all GUI windows correctly
appDataPath := A_Appdata . "\Autohotkey\TableFilter"
if !(FileExist(appDataPath))
	FileCreateDir, % appDataPath
IniRead, darkModeToggle, % appDataPath . "\TableFilter.ini", Settings, DarkMode, 0
;// ######### SETTINGS #######################
darkThemeColor := 0x36393F ;// color for dark theme, discord grey (0x36393F) is default.
flagSimpleSaving := 1 ;// saves automatically to currently opened file
flagAutoSaving := 1	;// automatically save when exiting/closing the program/GUI
flagUseBackups := 1	;// create backups or not. Backups are not automatically deleted.
settingBackupAmount := 4 ;// corresponds to 1 hour of backups (if default interval)
settingBackupInterval := 15 ;// in minutes
flagDebug := 0 ;// debug, duh
flagUseDefaultValues := 1 ;// replace newly added empty entries with ?,-,etc
duplicateFilter := "Deutsch" ;// default value to search in duplicateList for
saveHotkeyAsString := "^s" ;// hotkey for quicksaving. default ^s
reloadHotkeyAsString := "^+g" ;// hotkey for reloading script. default ^+r
openWindowHotkeyAsString := "#o" ;// hotkey for opening new GUI. default #o
iconPath := "G:\OneDrive\Auto HotKey Scripts\icons\a-runic.ico"
; ################################## F2 = Edit / F5 = Reload / Del = Löschen

;// MENU
createTrayMenu(darkModeToggle, iconPath)
;// functions etc
OnExit("CustomExit")	;// custom exit so that i can show a "you have unsaved changes" dialog
Suspend	;// disable hotkey until data is loaded, so that there doesn't happen any bullshit
loadData()
Suspend ;// enable hotkeys again
Hotkey, IfWinActive, ahk_group tableFilterGUIGroup
Hotkey, %saveHotkeyAsString%, directSave
Hotkey, IfWinActive
if (reloadHotkeyAsString)
	Hotkey, %reloadHotkeyAsString%, reloadScript
Hotkey, %openWindowHotkeyAsString%, createMainGUI
createGUIRowMenu()
return

;// more todo:
; actionChain to restore, formatted: 1 -> added line, 2 -> inserted line, 3 -> deleted line, ctrl+Z able
; better dark mode
; adjust LV width based on width of columns. Allow resizing of windows. (PREVENT IT FROM GOING TOO WIDE)
; dropdown menu for categories (steal from windowmanager?)
;// done:


;// gui creation functions

createMainGUI() {
	global keyArray, guiName, filterGuiArray
	global flagLoaded, darkModeToggle, flagDebug
	global AddButton1
	Gui, New, +Border +hwndGuiHwnd +Resize
	filterGuiArray.push(GuiHwnd)
	if (flagLoaded) {
		GroupAdd, tableFilterGUIGroup, ahk_id %GuiHwnd%
		s := "ID"
		for index, key in keyArray
			s .= "|" . key
		createSearchBoxesinGUI(keyArray)
		Gui, Add, ListView, vLV AltSubmit gLVEvent xs R35 w950, % s
		createAddLineBoxesinGUI(keyArray)
		Gui, Add, Button, yp-1 xp+115 vAddButton1 Default gAddLineToData r1 w100, Eintrag hinzufügen
		createFileButtonsinGUI()
		; if !(flagDebug)
			; LV_ModifyCol(1, 0)	;// setzt die ID-Zeile auf Breite 0, sodass sie versteckt wird
		createFilteredList()
		LV_ModifyCol(1, "Integer")
		for i, e in keyArray
			LV_ModifyCol(i, "AutoHdr")
	}
	else {
		Gui, Add, Button, x200 Default gLoadData r1 w100, XML-Datei laden
		Gui, Add, ListView, vLV x7 R20 w500, % "Keine Datei gewählt"
		GuiControl, Disable, LV
		GuiControl, Focus, XML-Datei laden
		guiName := "Keine Datei gewählt."
	}
	if (darkModeToggle)
		toggleGuiDarkMode(GuiHwnd)
	Gui, Show, Center Autosize, %guiName%
	if (darkModeToggle)
		toggleGuiDarkMode(GuiHwnd)
}

createSearchBoxesinGUI(keyArray) {
	global
	local boxWidthArray := []
	for i, e in keyArray
	{
		if (e == "Wortart" || e == "Tema'i")
			boxWidthArray[i] := 30
		else
			boxWidthArray[i] := 75
	}
	Gui, Add, Button, % "Section w30 R1 gClearSearchBoxes", % "Clear"
	for i, e in keyArray
	{
		Gui, Add, Text, % "ys", % (i==1?"Filter: ":" ") . keyArray[i]
		Gui, Add, Edit, % "vFilterColumn" . i . " gcreateFilteredList ys r1 w" . boxWidthArray[i]
	}
	Gui, Add, Text, ys+3, % "Dupes:"
	Gui, Add, Checkbox, gduplicateList vCheckboxDuplicates ys+3 r1 w50
}

createAddLineBoxesinGUI(keyArray, row := "") {
	global
	local boxWidthArray := []
	for i, e in keyArray
	{
		Gui, Add, Text, % "vNewRowText" . i . " " . (i==1?"Section":"ys"), % e
		Gui, Add, Edit, % "vNewRow" . i . " gAddLineBoxChecker r1 w100", % row[e]
	}
}

createFileButtonsinGUI() {
	global
	Gui, Add, Button, % "ys xp+165 vFileButton1 gLoadData Default r1 w140", XML-Datei laden
	Gui, Add, Button, % "ys+25 xp vFileButton2 gExportToFileGUI r1 w140", Export als XML-Datei
}

createGUIRowMenu() {
	Menu, tableFilterAddCategoryMenu, Add, % "👨‍👩‍👧 Familie", tableFilterCategoryMenuHandler
	Menu, tableFilterAddCategoryMenu, Add, % "🖌️ Farbe", tableFilterCategoryMenuHandler
	Menu, tableFilterAddCategoryMenu, Add, % "⛰️ Geographie", tableFilterCategoryMenuHandler
	Menu, tableFilterAddCategoryMenu, Add, % "💎 Geologie", tableFilterCategoryMenuHandler
	Menu, tableFilterAddCategoryMenu, Add, % "🌟 Gestirne", tableFilterCategoryMenuHandler
	Menu, tableFilterAddCategoryMenu, Add, % "💥 Magie", tableFilterCategoryMenuHandler
	Menu, tableFilterAddCategoryMenu, Add, % "🍗 Nahrung", tableFilterCategoryMenuHandler
	Menu, tableFilterAddCategoryMenu, Add, % "👕 Kleidung", tableFilterCategoryMenuHandler
	Menu, tableFilterAddCategoryMenu, Add, % "🖐️ Körper", tableFilterCategoryMenuHandler
	Menu, tableFilterAddCategoryMenu, Add, % "🏘️ Orte", tableFilterCategoryMenuHandler
	Menu, tableFilterAddCategoryMenu, Add, % "🌲 Pflanzen", tableFilterCategoryMenuHandler
	Menu, tableFilterAddCategoryMenu, Add, % "🐕 Tiere", tableFilterCategoryMenuHandler
	Menu, tableFilterAddCategoryMenu, Add, % "🌧️ Wetter", tableFilterCategoryMenuHandler
	Menu, tableFilterAddCategoryMenu, Add, % "🔢 Zahl", tableFilterCategoryMenuHandler
	Menu, tableFilterRemoveCategoryMenu, Add, % "[ALL]", tableFilterCategoryMenuHandler
	Menu, tableFilterRemoveCategoryMenu, Add, % "👨‍👩‍👧 Familie", tableFilterCategoryMenuHandler
	Menu, tableFilterRemoveCategoryMenu, Add, % "🖌️ Farbe", tableFilterCategoryMenuHandler
	Menu, tableFilterRemoveCategoryMenu, Add, % "⛰️ Geographie", tableFilterCategoryMenuHandler
	Menu, tableFilterRemoveCategoryMenu, Add, % "💎 Geologie", tableFilterCategoryMenuHandler
	Menu, tableFilterRemoveCategoryMenu, Add, % "🌟 Gestirne", tableFilterCategoryMenuHandler
	Menu, tableFilterRemoveCategoryMenu, Add, % "💥 Magie", tableFilterCategoryMenuHandler
	Menu, tableFilterRemoveCategoryMenu, Add, % "🍗 Nahrung", tableFilterCategoryMenuHandler
	Menu, tableFilterRemoveCategoryMenu, Add, % "👕 Kleidung", tableFilterCategoryMenuHandler
	Menu, tableFilterRemoveCategoryMenu, Add, % "🖐️ Körper", tableFilterCategoryMenuHandler
	Menu, tableFilterRemoveCategoryMenu, Add, % "🏘️ Orte", tableFilterCategoryMenuHandler
	Menu, tableFilterRemoveCategoryMenu, Add, % "🌲 Pflanzen", tableFilterCategoryMenuHandler
	Menu, tableFilterRemoveCategoryMenu, Add, % "🐕 Tiere", tableFilterCategoryMenuHandler
	Menu, tableFilterRemoveCategoryMenu, Add, % "🌧️ Wetter", tableFilterCategoryMenuHandler
	Menu, tableFilterRemoveCategoryMenu, Add, % "🔢 Zahl", tableFilterCategoryMenuHandler
	Menu, tableFilterSelectMenu, Add, % "[F2]   🖊️ Edit", tableFilterSelectMenuHandler
	Menu, tableFilterSelectMenu, Add, % "[Entf] 🗑️ Delete", tableFilterSelectMenuHandler
	Menu, tableFilterSelectMenu, Add, % "➕ Add Category", :tableFilterAddCategoryMenu
	Menu, tableFilterSelectMenu, Add, % "➖ Remove Category", :tableFilterRemoveCategoryMenu
}

;// GUI manipulation

createFilteredList() {
	global LV, data, keyArray
	Gui, Submit, NoHide
	Gui, +Disabled
	GuiControl, -Redraw, LV
	LV_Delete()
	for i, row in data
		if (filterTableRow(row, keyArray))
			listViewAddRow(row, keyArray)
	if (LV_GetCount() == 0)
		LV_Add("Col2", "/", "Nichts gefunden.")
	GuiControl, +Redraw, LV
	Gui, -Disabled
}

duplicateList() {
	global LV, data, keyArray, CheckboxDuplicates, duplicateFilter
	Gui, Submit, NoHide
	if !(CheckboxDuplicates) {
		createFilteredList()
		return
	}
	GuiControl, -Redraw, LV
	LV_Delete()
	if (duplicateFilter)
		col := duplicateFilter
	else
		col := keyArray[1]
	duplicates := {}
	Gui, +Disabled
	for i, row in data {
		value := row[col]
		if (duplicates[value])
			duplicates[value].push(row)
		else
			duplicates[value] := [row]
	}
	for i, row in data {
		value := row[col]
		if (value == "-" || value == " " || value == "")
			continue
		if (duplicates[value].Count() > 1) {
			for i, dRow in duplicates[value] {
				listViewAddRow(dRow, keyArray)
			}
			duplicates[value] := {}
		}
	}
	Gui, -Disabled
	GuiControl, +Redraw, LV
}

filterTableRow(row, keyArray) {
	global
	local searches := []
	for i, e in keyArray
		searches.push(FilterColumn%i%)
	for index, term in searches
	{
		if (term == "×") {
			if (row[keyArray[index]] != "")
				return 0
		}
		else if (term != "")
			if !(InStr(row[keyArray[index]], term))
				return 0
	}
	return 1
}

listViewAddRow(row, keyArray) {
	row2 := [row["index"]]
	for i, e in keyArray
		row2.push(row[keyArray[i]])
	LV_Add("",row2*)
}

;// database manipulation

addLineToData() {
	global 
;//	global data, keyArray, LV, filterGuiArray, flagUseDefaultValues, newRow1-n
	local newRowArr, newRow, tGuiHwnd
	Gui, Submit, NoHide
	newRowArr := []
	for i, e in keyArray
	{
		newRowArr[i] := NewRow%i%
		GuiControl,, NewRow%i%
	}
	newRow := trimRowValues(data.Count()+1, newRowArr, flagUseDefaultValues, 1, keyArray)
	dataBaseItemInsert(data.Count()+1,newRow)
	if (flagDebug)
		debugShowDataBaseEntry()
	tGuiHwnd := A_Gui
	updateGUIsettings(,true, false)
	for i, h in filterGuiArray
	{
		Gui, %h%:Default
		Gui, Submit, NoHide
		if (filterTableRow(newRow, keyArray)) {
			listViewAddRow(newRow, keyArray)
			if (h==tGuiHwnd)
				LV_Modify(LV_GetCount(),"Select Focus Vis")
		}
	}
}

trimRowValues(index, valArr, flagUseDefault, flagUseRunic, keyArray) {
	r := {}
	r["index"] := index
	for i, e in valArr
	{
		if (e == "" && flagUseDefault)
			switch i {
				case 1:
					e := "?"
				case 2,3:
					e := "-"
				case 4:
					if (flagUseRunic)
						e := ReplaceChars(r[keyArray[3]], "abdefghiklmnoprstuvyz", "ᚫᛒᛞᛖᚠᚷᚻᛁᚲᛚᛗᚾᛟᛈᚱᛋᛏᚢᚹᛃᛉ")
				case 6:
					e := "0"
				default:
			}
		if (i == 1)	;// make first column be uppercase
			e := Format("{:U}", e)
		r[keyArray[i]] := Trim(e)
	}
	return r
}

editRow(trueIndex, newRow) {
	global data, keyArray, filterGuiArray
	oldRow := data[trueIndex]
	data[trueIndex] := newRow
	updateGUIsettings(,true, false)
	for i, h in filterGuiArray
	{
		Gui, %h%:Default
		Gui, Submit, NoHide
		localFlagOld := filterTableRow(oldRow, keyArray)
		localFlagNew := filterTableRow(newRow, keyArray)
		if (localFlagOld)
			Loop % LV_GetCount()
			{
				LV_GetText(tempTrueInd, A_Index, 1)
				if (tempTrueInd == trueIndex) {
					if (!localFlagNew) {
						LV_Delete(A_Index)
						break
					}
					else {
						newRowTemp := [newRow["index"]]
						for i, e in keyArray
							newRowTemp.push(newRow[keyArray[i]])
						LV_Modify(A_Index,"", newRowTemp*)
						break
					}
				}
			}
		if (!localFlagOld && localFlagNew)
			listViewAddRow(newRow, keyArray)
	}
}

editRowFromMenu(mainWinHwnd, editLineHWND, trueIndex) {
	global
	local newRowArr, newRow
	Gui, %editLineHWND%:Default
	Gui, %editLineHWND%:Submit, NoHide
	newRowArr := []
	for i, e in keyArray
		newRowArr[i] := NewRow%i%
	newRow := trimRowValues(trueIndex, newRowArr, flagUseDefaultValues, 0, keyArray)
	editRow(trueIndex, newRow)
	Gui, %mainWinHwnd%:-Disabled
	Gui, %editLineHWND%:Destroy
	WinActivate, ahk_id %mainWinHwnd%
}

removeSelectedRows(launchedFromMenu := 0) {
	global data, filterGuiArray, keyArray, menuCreatingGUIHwnd
	if (launchedFromMenu)
		Gui, %menuCreatingGUIHwnd%:Default
	selectedRows := {}
	selectedDataRows := {}
	Loop
	{
		rowN := LV_GetNext(rowN) ;// next row
		if !(rowN)
			break
		selectedRows.push(rowN)
		LV_GetText(trueN, rowN, 1) ;// retrieve trueIndex
		selectedDataRows.push(trueN)
	}
	if !(selectedRows.Count())
		return
	selectedDataRowsSorted := arraySort(selectedDataRows, "N R")
	selectedRowsSorted := arraySort(selectedRows, "N R")
	for i, h in filterGuiArray
	{
		Gui, %h%:Default
		Gui, Submit, NoHide
		for j, n in selectedDataRowsSorted
			if (filterTableRow(data[n], keyArray)) {
				Loop % LV_GetCount()
				{
					LV_GetText(trueIndex, A_Index, 1)
					if (trueIndex == n) {
						LV_Delete(A_Index)
						break
					}
				}
			}
		Loop % LV_GetCount()
		{
			c := 0
			LV_GetText(trueIndex, A_Index, 1)
			for i, n in selectedDataRowsSorted
				if (trueIndex > n)
					c++
			LV_Modify(A_Index, "Col1", trueIndex-c)
		}
	}
	for i, n in selectedDataRowsSorted
		dataBaseItemRemove(n)
	updateGUIsettings(,true, false)
}

dataBaseItemRemove(n) {
	global data
	data.removeAt(n)
	l := data.Count()
	for i, r in data
	{
		if (l-i+1 < n)
			break
		data[l-i+1]["index"]--
	}
}

dataBaseItemInsert(n, r) {
	global data
	data.insertAt(n, r)
	l := data.Count()
	for i, r in data
	{
		if (l-i < n)	;// no +1 because i want it to stop at n, not after n
			break
		data[l-i+1]["index"]++
	}
	data[n]["index"] := n
}

;// GUI functions

editSelectedRow(launchedFromMenu := 0) {
	global data, keyArray, filterGuiArray, darkModeToggle, editLineGUIOwnerHwnd, menuCreatingGUIHwnd
	if (launchedFromMenu)
		hw := menuCreatingGUIHwnd
	else
		hw := A_Gui
	Gui, %hw%:Default
	editLineGUIOwnerHwnd := hw
	rowN := LV_GetNext(0,"F")
	if !(rowN)
		return
	Gui, %hw%:+Disabled
	LV_GetText(trueIndex, rowN, 1)
	r := data[trueIndex]
	Gui, New, -Border -SysMenu +Owner%hw% +HwndeditLineHWND
	Gui, %editLineHWND%:Default
	createAddLineBoxesinGUI(keyArray, r)
	Gui, Add, Button, r2 w100 ys+5, Speichern
	fObj := Func("editRowFromMenu").Bind(hw, editLineHWND, trueIndex)
	GuiControl, +g, Speichern, % fObj
	WinGetPos, x, y, w, h, ahk_id %hw%
	if (darkModeToggle)
		toggleGuiDarkMode(editLineHWND)
	Gui, Show, % "x" . x + 50 . " y" . y + h/2-50, hiddenEditLineGUITitle
	if (darkModeToggle)
		toggleGuiDarkMode(editLineHWND)
	for i, e in keyArray
	{
		AddLineBoxChecker("NewRow" . i, "", "", "ManualCall")
	}
}

ExportToFileGUI() {
	global loadedFilePath, filterGuiArray
	folderPath := RegexReplace(loadedFilePath, "\\[^\\\n]*\.xml$")
	fileName := SubStr(loadedFilePath, StrLen(folderPath)+2, -4) ;// gives filename without extension
	if (RegexMatch(fileName, "O)(.*?)([0-9]{14})", m)) {
		if m.Value(2) is date
			fileName := m.Value(1)
	}
	newDefaultFile := fileName . A_Now . ".xml"
	for i, e in filterGuiArray
		Gui, %e%:+Disabled
	FileSelectFile, exportPath, S24, % folderPath . "\\" . newDefaultFile, % "Tabelle als XML-Datei exportieren", *.xml
	for i, e in filterGuiArray
		Gui, %e%:-Disabled
	if !(exportPath)
		return
	exportAsXMLFile(exportPath, 0)
}

updateGUIs(filterGuiArray) {
	for i, guihwnd in filterGuiArray
	{
		if (guihwnd == "")	;// this should not happen, theorethically
			continue
		Gui, %guihwnd%:+Disabled
	}
	for i, guihwnd in filterGuiArray
	{
		if (guihwnd == "")	
			continue
		Gui, %guihwnd%:Default
		createFilteredList()
		GuiControl,,CheckboxDuplicates, 0
		Gui, %guihwnd%:-Disabled
	}
}

updateGUIsettings(filePath := -1, unsaved := -1, backupped := -1) {
	global flagHasUnsavedChanges, lsFilePath, guiName, filterGuiArray, flagHasBackup
	if (filePath != -1)
		lsFilePath := filePath
	if (unsaved != -1) {
		flagHasUnsavedChanges := unsaved
		title := guiName
		if (unsaved)
			title .= "* - Ungespeicherte Änderungen"
		for i, guiHwnd in filterGuiArray
			Gui, %guiHwnd%:Show, NA, % title
	}
	if (backupped != -1)
		flagHasBackup := backupped
}

updateGUIColors(dark) {
	global filterGuiArray
	for i, e in filterGuiArray
	{
		Gui, %e%:Default
		toggleGuiDarkMode(e, dark)
	}
	hw := WinExist("hiddenEditLineGUITitle")
	if (hw) {
		Gui, %hw%:Default
		toggleGuiDarkMode(hw, dark)
	}
}

toggleGuiDarkMode(hwnd, dark := 1) {
	global darkThemeColor
	;// First, Menus dark
	if (!init) {
		static uxtheme := DllCall("GetModuleHandle", "str", "uxtheme", "ptr")
		static SetPreferredAppMode := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 135, "ptr")
		static FlushMenuThemes := DllCall("GetProcAddress", "ptr", uxtheme, "ptr", 136, "ptr")
		init := 1
	}
	DllCall(SetPreferredAppMode, "int", dark) ; Dark
	DllCall(FlushMenuThemes)
	;// Then, title bar dark
	if (A_OSVersion >= "10.0.17763" && SubStr(A_OSVersion, 1, 3) == "10.") {
		attr := 19
		if (A_OSVersion >= "10.0.18985") {
			attr := 20
		}
		if (dark)
			DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "int", attr, "int*", true, "int", 4)
		else
			DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "int", attr, "int*", false, "int", 4)
	}
	;// then, GUI itself Dark.
	if (dark) 
		Gui, %hwnd%:Color, %darkThemeColor%, %darkThemeColor%
	else
		Gui, %hwnd%:Color, Default, Default
	;// then, GUI controls dark.
	WinGet, controlListStr, ControlList, ahk_id %hwnd%
	for i, control in StrSplit(controlListStr, "`n") 
	{
		ControlGet, controlHwnd, HWND, , %control%, ahk_id %hwnd%
		if (dark) {
			GuiControl, +Background%darkThemeColor%,%control%
			Gui,Font, c0xFFFFFF
			GuiControl, Font, %controlHwnd%
		}
		else {
			GuiControl, +BackgroundDefault,%control%
			Gui,Font, cDefault
			GuiControl, Font, %controlHwnd%
		}
	}
}

GuiSize(GuiHwnd) {
	global
;	global filterGuiArray, keyArray
	WinGetTitle, t, % "ahk_id " GuiHwnd
	if (t == "hiddenEditLineGUITitle")
		return
	Gui, %GuiHwnd%:Default
	GuiControlGet, lvArr, Pos, LV 
	GuiControl, Move, LV, % "w" A_GuiWidth-20 "h" A_GuiHeight -100
	GuiControlGet, lvArrA, Pos, LV 
	delta := lvArrAH - lvArrH
	GuiControlGet, fb1, Pos, % "FileButton1" 
	GuiControlGet, fb2, Pos, % "FileButton2"
	GuiControl, Move, % "FileButton1", % "y" fb1Y + delta
	GuiControl, Move, % "FileButton2", % "y" fb2Y + delta
	for i, e in keyArray
	{
		GuiControlGet, NR, Pos, % "NewRowText" i
		GuiControl, Move, % "NewRowText" i, % "y" NRY + delta
		GuiControlGet, NR, Pos, % "NewRow" i 
		GuiControl, Move, % "NewRow" i, % "y" NRY + delta
	}
	GuiControlGet, AB, Pos, % "AddButton1"
	GuiControl, Move, % "AddButton1", % "y" ABY + delta
}

GuiEscape(GuiHwnd) {
	global filterGuiArray, editLineGUIOwnerHwnd
	Gui, %GuiHwnd%:Submit, NoHide
	WinGetTitle, t, ahk_id %GuiHwnd%
	if (t == "hiddenEditLineGUITitle") {
		Gui, %editLineGUIOwnerHwnd%:-Disabled
		Gui, %GuiHwnd%:Destroy
		return
	}
	GuiClose(GuiHwnd)
}

GuiClose(GuiHwnd) {	;// note, this is in decimal, not hexadecimal.
	global filterGuiArray, flagAutoSaving, flagHasUnsavedChanges
	arrayDeleteValue(filterGuiArray, Format("0x{:x}", GuiHwnd))
	if (flagAutoSaving && flagHasUnsavedChanges) {
		ToolTip % "Speichern..."
		directSave()
		ToolTip % "Gespeichert."
	}
	Gui, %GuiHwnd%:Destroy
	SetTimer, timedToolTip, -700
	return
}


AddLineBoxChecker(guiControlHwnd, guiEvent, eventInfo, errLevel := "") {
	global
	local guiControlVar
	Gui, Submit, Nohide
	if (errLevel == "ManualCall")
		guiControlVar := guiControlHwnd
	else
		guiControlVar := A_GuiControl
	switch guiControlVar {
		case "NewRow1":
			if (!RegexMatch(NewRow1, "^[?NnVvAaSsPpGg]?$"))
				Gui, Font, % "cRed Bold"
		case "NewRow3":
			if (RegexMatch(NewRow3, "[cjqwxöäüß]"))
				Gui, Font, % "cRed Bold"
		case "NewRow4":
			;// if (!RegexMatch(NewRow4, "[ᚫᛒᛞᛖᚠᚷᚻᛁᚲᛚᛗᚾᛟᛈᚱᛋᛏᚢᚹᛃᛉᛝᛜᚳᛄᚦᛣᛪᛨᛇ]")) : i dont have all runes, and special symbols, so no
			if (RegexMatch(NewRow4, "[A-Za-z]"))
				Gui, Font, % "cRed Bold"
		case "NewRow6":
			if !(RegexMatch(NewRow6, "^[01]?$"))
				Gui, Font, % "cRed Bold"
		default:
			return
	}
	GuiControl, Font, %guiControlVar%
	Gui, Font, % (darkModeToggle?"c0xFFFFFF":"cDefault") . " Norm"
}

clearSearchBoxes() {
	global
	for i, e in keyArray {
		GuiControl, -g, % "FilterColumn" i
		GuiControl, , % "FilterColumn" i, % "" 
		gHandle := Func("createFilteredList")
		GuiControl, +g, % "FilterColumn" i, % gHandle
	}
	createFilteredList()
}

;// menu functions

LVEvent() {
	global menuCreatingGUIHwnd
	menuCreatingGUIHwnd := A_Gui
	switch A_GuiEvent {
		case "RightClick":
			Menu, tableFilterSelectMenu, Show
		case "DoubleClick":
			editSelectedRow()
		case "K":	;//Key
			switch A_EventInfo {
				case "46": 	;// Del/Entf Key -> Remove Line from database
					removeSelectedRows()
				case "113":	;// F2 -> edit
					editSelectedRow()
				case "116":	;// F5 -> Reload
					createFilteredList()
				case "220": ;// Ü -> Debug
					debugShowDataBaseEntry()
				default: return
			}
		default: return
	}
}

tableFilterSelectMenuHandler(ItemName) {
	switch ItemName {
		case "[F2]   🖊️ Edit":
			editSelectedRow(1)
		case "[Entf] 🗑️ Delete":
			removeSelectedRows(1)
	}
}

tableFilterCategoryMenuHandler(ItemName, ItemPos, MenuName) {
	global data, keyArray, filterGuiArray, menuCreatingGUIHwnd
	category := ItemName
	hw := menuCreatingGUIHwnd
	Gui, %hw%:Default
	editLineGUIOwnerHwnd := hw
	selectedDataRows := {}
	Loop
	{
		rowN := LV_GetNext(rowN) ;// next row
		if !(rowN)
			break
		LV_GetText(trueN, rowN, 1) ;// retrieve trueIndex
		selectedDataRows.push(trueN)
	}
	if !(selectedDataRows.Count())
		return
	for index, trueN in selectedDataRows
	{
		r := data[trueN].clone() ; NECESSARY, ELSE IT ALREADY AFFECTS ID
		curCategories := r["Kategorie"]
		if (MenuName == "tableFilterAddCategoryMenu") {
			if (curCategories) {
				curCategories .= "," . category
				Sort, curCategories, P3 U D, 
				r["Kategorie"] := curCategories
			}
			else {
				r["Kategorie"] := category
			}
		}
		else { ; Menu is remove
			if (ItemName == "All" || !curCategories)
				curCategories := ""
			else {
				Sort, curCategories, P3 U D, 
				curCategories := StrReplace(curCategories, ItemName)
				curCategories := StrReplace(curCategories, ",,")
				curCategories := Trim(curCategories, ", ")
			}
			r["Kategorie"] := curCategories
		}
		editrow(trueN, r) ; something like this
	}
}

toggleSettingDarkmode() {
	global darkModeToggle, appDataPath
	if (darkModeToggle)
		darkModeToggle := 0
	else
		darkModeToggle := 1
	Menu, Tray, ToggleCheck, Darkmode nutzen
	IniWrite, % darkModeToggle, % appDataPath . "\TableFilter.ini", Settings, DarkMode
	updateGUIColors(darkModeToggle)
}

timedToolTip() {
	ToolTip
}

;// loading and saving data

getDataPath(filterGuiArray) {
	defaultPath := getLastUsedFile()
	if !(defaultPath)
		defaultPath := A_ScriptDir
	for i, e in filterGuiArray
		Gui, %e%:+Disabled
	FileSelectFile, path, 3, % defaultPath, % "Datei laden", *.xml
	for i, e in filterGuiArray
		Gui, %e%:-Disabled
	if (path)
		updateLastUsedFile(path)
	return path
}

loadfile(dataPath) {
	if 	!(FileExist(dataPath))
		return 0
	dataFile := FileOpen(dataPath, "r", "UTF-8")
	rawData := dataFile.Read()
	database := {}
	xmlString := ""
	rawData := StrReplace(rawData, "&apos;", "'")
	rawData := StrReplace(rawData, "&quot;", """")
	rawData := StrReplace(rawData, "&gt;", ">")
	rawData := StrReplace(rawData, "&lt;", "<")
	rawData := StrReplace(rawData, "&amp;", "&")
	rawData := StrReplace(rawData, "_x0027_", "'")
	Loop, Parse, rawData, `n, `r
	{
        if (A_Index == 1) {
			if !RegExMatch(A_LoopField,"xml") {
				MsgBox, % "Diese Datei scheint keine XML-Datei zu sein."
				return 0
			}
			xmlString := A_LoopField . "`r`n"
        }
		if (A_Index == 2) {
			if RegExMatch(A_LoopField, "O)xsi:noNamespaceSchemaLocation=""(.*?)""", m)
				name := m.Value(1)
			else
				name := "Database"
			xmlStringOffice := A_LoopField . "`r`n"
		}
		if (A_Index == 3) {
			RegexMatch(A_LoopField, "O)<(.*?)>", m)
			rowName := m.Value(1)
			regex := "O)<" . rowName . ">([\s\S]*?)<\/" . rowName . ">"
			if !RegexMatch(rawData, regex, m)
				return
			}
		if (A_Index > 3)
			break
	}
	keyArray := []
	str := "<" . rowName . ">"
	count := 1
	rawData := StrReplace(rawData, str, "¤")
	Loop, Parse, rawData, ¤
	{
		o := {}
		flag := 0
		Loop, Parse, A_LoopField, `n, `r
		{
			if RegexMatch(A_LoopField, "O)<(.*?)>([\s\S]*?)<\/\1>", m) {
				key := m.Value(1)
				val := m.Value(2)
				o[key] := val
				if !(arrayContains(keyArray, key)) { ;// this stores the keys
					pos := arrayContains(keyArray, prevkey)
					keyArray.InsertAt(pos+1, key) ;// this sorts the columns correctly.
				}
				prevkey := key
				flag := 1
			}
		}
		if (flag) {
			o["index"] := count
			database.Push(o)
			count++
		}
	}
	for i, e in keyArray
		keyArray[i] := StrReplace(e, "_x0027_", "'")
	database.Push(keyArray)
	database.Push({"Name":name, "RowName":rowName})
	database.Push(xmlString)
	database.Push(xmlStringOffice)
    return database
}

loadData() {
	global data, xmlString, xmlStringOffice, metaData, keyArray, loadedFilePath, guiName, filterGuiArray
	global flagLoaded, flagHasUnsavedChanges, flagSimpleSaving, flagUseBackups, settingBackupInterval
	if (flagHasUnsavedChanges) {
		MsgBox, 1,, % "Ungespeicherte Änderungen. Trotzdem neue Datei laden?"
		IfMsgBox, Cancel
			return
	}
	loadedFilePath := getDataPath(filterGuiArray) ;// GUI to select a file to load
	if !(loadedFilePath) 	;// if user exits, its blank. then don't do anything.
		return
	if !(FileExist(loadedFilePath)) {
		msgbox % "Datei nicht gefunden."
		return
	}
	data := loadfile(loadedFilePath)
	xmlStringOffice := data.Pop()
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
			Msgbox, 4, % "Datei öffnen?", % "Es sind " . filterGuiArray.Count() . " Fenster geöffnet. Das Laden einer neuen Datei wird etwas Zeit brauchen. Fenster vorher schließen?"
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

directSave() {
	global flagHasUnsavedChanges, lsFilePath
	if (flagHasUnsavedChanges) {
		if (lsFilePath)
			exportAsXMLFile(lsFilePath)
		else
			ExportToFileGUI()
	}
}

exportAsXMLFile(filePath, localFlagUpdateLastUsedFile := 1, localFlagUpdateUnsaved := 1, localFlagUpdateBackupped := 0) {
	global data, xmlString, metaData, keyArray
	FormatTime, ftime, , yyyy-MM-ddTHH:mm:ss
	xmlFileAsString .= xmlString . "<dataroot generated=""" ftime """>`r`n"
	keyArrAlphanum := []
	for i, e in keyArray
		keyArrAlphanum[i] := StrReplace(e, "'", "_x0027_")
	for Index, Element in data
	{
		s := "<" . metaData.rowName . ">`r`n"
		for i, elm in keyArray
		{
			if (Element[elm] != ""||Index=1) {
				t := Element[elm]
				t := StrReplace(t, "&", "&amp;")
				t := StrReplace(t, "'", "&apos;")
				t := StrReplace(t, """", "&quot;")
				t := StrReplace(t, ">", "&gt;")
				t := StrReplace(t, "<", "&lt;")
				s .= "<" . keyArrAlphanum[i] . ">" . t . "</" . keyArrAlphanum[i] . ">`r`n"
			}
		}
		s .= "</" . metaData.rowName . ">`r`n"
		xmlFileAsString .= s
	}
	xmlFileAsString .= "</dataroot>"
	fileObj := FileOpen(filePath, "w", "UTF-8")
	fileObj.Write(xmlFileAsString)
	if (localFlagUpdateLastUsedFile) {
		updateLastUsedFile(filePath)
		updateGUIsettings(filePath)
	}
	if (localFlagUpdateUnsaved)
		updateGUIsettings(, false)
	if (localFlagUpdateBackupped)
		updateGUIsettings(,,true)
}

updateLastUsedFile(filePath) {
	global appDataPath
	IniWrite, % filePath, % appDataPath . "\TableFilter.ini", Logs, LastUsedFile
}

getLastUsedFile() {
	global appDataPath
	IniRead, luFilePath, % appDataPath . "\TableFilter.ini", Logs, LastUsedFile, %A_Space%
	return luFilePath
}

backupIterator(origBackup := 0) {
	global flagHasBackup, appDataPath, loadedFilePath, settingBackupAmount
	if (flagHasBackup)
		return
	if (!RegexMatch(loadedFilePath, "O)\\?([^\\\n]*)\.xml$", o))
		return
	fileName := o.Value(1)
	pathFileNameGeneric := appDataPath . "\\" . fileName . "_Backup_"
	FormatTime, timeStr,, dd.MM.yyyy-HH.mm.ss
	exportAsXMLFile(pathFileNameGeneric . (origBackup?"Original":timeStr) . ".xml", 0, 0, 1)
	deleteExcessBackups(appDataPath, pathFileNameGeneric, settingBackupAmount)
}

deleteExcessBackups(appDataPath, pathFileNameGeneric, allowedBackupsCount) {
	Loop, Files, % pathFileNameGeneric . "*.xml" 
	{
		if (InStr(A_LoopFileName, "Original"))
			continue
		else {
			j++
			if (!oldestBackupTime || oldestBackupTime > A_LoopFileTimeCreated) {
				oldestBackupTime := A_LoopFileTimeCreated
				oldestBackup := A_LoopFileName
			}
		}
	}
	if (j > allowedBackupsCount) {
		FileDelete, % appDataPath . "\\" . oldestBackup
		deleteExcessBackups(appDataPath, pathFileNameGeneric, allowedBackupsCount)
	}
}

;// generic functions

arrayContains(array, key) {
	for i, e in array
		if(e == key)
			return i
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
	global openWindowHotkeyAsString
	Menu, Tray, Add, % "GUI öffnen: " . openWindowHotkeyAsString, trayMenuHandler ;// a button to create another window
	Menu, Tray, Add, % "Darkmode nutzen", trayMenuHandler
	Menu, Tray, Add, % "Backup-Ordner öffnen", trayMenuHandler
	Menu, Tray, Add 
	Menu, Tray, Add, % "Letzte Zeilen öffnen", trayMenuHandler
	Menu, Tray, Add, % "Hilfe", trayMenuHandler
	Menu, Tray, Add
	Menu, Tray, Add, % "Neu laden", trayMenuHandler
	Menu, Tray, Add, % "Script bearbeiten", trayMenuHandler
	Menu, Tray, Add
	Menu, pauseSuspendMenu, Add, Suspend Hotkeys, trayMenuHandler
	Menu, pauseSuspendMenu, Add, Suspend Reload, trayMenuHandler
	Menu, Tray, Add, Suspend/Stop, :pauseSuspendMenu 
	Menu, Tray, Add, % "Beenden", trayMenuHandler
	Menu, Tray, NoStandard
	Menu, Tray, Default, % "GUI öffnen: " . openWindowHotkeyAsString
	if (darkModeToggle)
		Menu, Tray, Check, % "Darkmode nutzen"
	try	;// we dont want an error on icon loading.
		Menu, Tray, Icon, %iconPath%,,1
}

trayMenuHandler(menuLabel) {
	global darkModeToggle, appDataPath, reloadHotkeyAsString, openWindowHotkeyAsString
	switch menuLabel {
		case "GUI öffnen: " . openWindowHotkeyAsString:
			createMainGUI()
		case "Darkmode nutzen":
			darkModeToggle := !darkModeToggle
			Menu, Tray, ToggleCheck, Darkmode nutzen
			IniWrite, % darkModeToggle, % appDataPath . "\TableFilter.ini", Settings, DarkMode
			updateGUIColors(darkModeToggle)
		case "Backup-Ordner öffnen":
			run, explorer.exe "%appDataPath%"
		case "Letzte Zeilen öffnen":
			ListLines
		case "Hilfe":
			Run, % RegexReplace(A_AhkPath, "AutoHotkey.exe$", "AutoHotkey.chm")
		case "Neu laden":
			Reload
		case "Script bearbeiten":
			try
				Run, % A_ProgramFiles . "\Notepad++\notepad++.exe """ . A_ScriptFullPath . """"
			catch e
				Run, notepad %A_ScriptFullPath%
		case "Suspend Hotkeys":
			Menu, pauseSuspendMenu, ToggleCheck, Suspend Hotkeys
			Suspend, Toggle
		case "Suspend Reload":
			Menu, pauseSuspendMenu, ToggleCheck, Suspend Reload
			Hotkey, %reloadHotkeyAsString%, Toggle
		case "Beenden":
			ExitApp
		default:
	}
}

CustomExit(ExitReason, ExitCode) {
	global flagHasUnsavedChanges, flagAutoSaving
	if !(arrayContains([LogOff, Shutdown, Error], ExitReason)) {
		if (flagHasUnsavedChanges) {
			if (flagAutoSaving)
				directSave()
			else if (ExitReason != Reload) {
				MsgBox, 1,, % "Es gibt ungespeicherte Änderungen. Trotzdem beenden?"
				IfMsgBox, Cancel
					return 1
			}
		}
	}
}

;// debug functions

debugShowDataBaseEntry() {
	global
	hw := menuCreatingGUIHwnd
	Gui, %hw%:Default
	rowN := LV_GetNext(0,"F")
	if !(rowN)
		return
	LV_GetText(trueIndex, rowN, 1)
	row := data[trueIndex]
	s := "n: " . trueIndex . "`n" . keyArray[1] . ": " . row[keyArray[1]] . "`n" . keyArray[2] . ": " . row[keyArray[2]] . "`n" . keyArray[3] . ": " . row[keyArray[3]] . "`n" . keyArray[4] . ": " . row[keyArray[4]] . "`n" . keyArray[5] . ": " . row[keyArray[5]] . "`n" . keyArray[6] . ": " . row[keyArray[6]] . "`n" . keyArray[7] . ": " . row[keyArray[7]] . "`n" . "Index: " . row["index"]
	msgbox % s
}

reloadScript() {
	Reload
	return
}

