#NoEnv
#SingleInstance Force
#Persistent
SendMode Input
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
reloadHotkeyAsString := "^+f" ;// hotkey for reloading script. default ^+r
openWindowHotkeyAsString := "^p"
iconPath := "E:\OneDrive\Auto HotKey Scripts\icons\a-runic.ico"
; ##################################

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
	Gui, New, +Border +hwndGuiHwnd
	filterGuiArray.push(GuiHwnd)
	if (flagLoaded) {
		GroupAdd, tableFilterGUIGroup, ahk_id %GuiHwnd%
		s := "DATAINDEX"
		for index, key in keyArray
			s .= "|" . key
		createSearchBoxesinGUI(keyArray)
		Gui, Add, ListView, vLV AltSubmit gLVEvent xs R35 w950, % s
		createAddLineBoxesinGUI(keyArray)
		Gui, Add, Button, yp-1 xp+37 gAddLineToData r1 w100, Add Row to List
		createFileButtonsinGUI()
		if !(flagDebug)
			LV_ModifyCol(1, 0)
		createFilteredList()
	;//	LV_ModifyCol(2, 100)	; Wortart
		LV_ModifyCol(3, 200)	; Deutsch
		LV_ModifyCol(4, 150)	; Kayoogis
		LV_ModifyCol(5, 150)	; Runen
		LV_ModifyCol(6, 180)	; Anmerkung
		LV_ModifyCol(7, 100)	; Kategorie
		LV_ModifyCol(8, 50)		; Tema'i
	}
	else {
		Gui, Add, Button, x200 Default gLoadData r1 w100, Load XML File
		Gui, Add, ListView, vLV x7 R20 w500, % "No File Selected"
		GuiControl, Disable, LV
		GuiControl, Focus, Load XML File
		guiName := "No File selected."
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
			boxWidthArray[i] := 60
	}
	for i, e in keyArray
	{
		Gui, Add, Text, % (i==1?"Section":"ys"), % (i==1?"Filter ":" ") . keyArray[i]
		Gui, Add, Edit, % "vFilterColumn" . i . " gcreateFilteredList ys r1 w" . boxWidthArray[i]
	}
	Gui, Add, Text, ys+3, % "Duplicate Filter:"
	Gui, Add, Checkbox, gduplicateList vCheckboxDuplicates ys+3 r1 w50
}

createAddLineBoxesinGUI(keyArray, row := "") {
	global
	local boxWidthArray := []
	for i, e in keyArray
	{
		if (e == "Wortart" || e == "Tema'i")
			boxWidthArray[i] := 30
		else
			boxWidthArray[i] := 100
	}
	for i, e in keyArray
	{
		Gui, Add, Text, % (i==1?"Section":"ys"), % e
		Gui, Add, Edit, % "vNewRow" . i . " gAddLineBoxChecker r1 w" . boxWidthArray[i], % row[e]
	}
}

createFileButtonsinGUI() {
	Gui, Add, Button, ys 	xp+165  gLoadData 		 r1 w100, Load XML File
	Gui, Add, Button, ys+25 xp 		gExportToFileGUI r1 w100, Export to XML File
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
	Menu, tableFilterAddCategoryMenu, Add, % "🐕 Tiere ", tableFilterCategoryMenuHandler
	Menu, tableFilterAddCategoryMenu, Add, % "🌧️ Wetter", tableFilterCategoryMenuHandler
	Menu, tableFilterAddCategoryMenu, Add, % "🔢 Zahl", tableFilterCategoryMenuHandler
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
	Menu, tableFilterRemoveCategoryMenu, Add, % "🐕 Tiere ", tableFilterCategoryMenuHandler
	Menu, tableFilterRemoveCategoryMenu, Add, % "🌧️ Wetter", tableFilterCategoryMenuHandler
	Menu, tableFilterRemoveCategoryMenu, Add, % "All", tableFilterCategoryMenuHandler
	Menu, tableFilterRemoveCategoryMenu, Add, % "🔢 Zahl", tableFilterCategoryMenuHandler
	Menu, tableFilterSelectMenu, Add, % "Edit Selected Row", tableFilterSelectMenuHandler
	Menu, tableFilterSelectMenu, Add, % "Delete Selected Row(s)", tableFilterSelectMenuHandler
	Menu, tableFilterSelectMenu, Add, % "Add Category to Selected Row(s)", :tableFilterAddCategoryMenu
	Menu, tableFilterSelectMenu, Add, % "Remove Category from Selected Row(s)", :tableFilterRemoveCategoryMenu
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
		LV_Add("Col2", "/", "No Results Found.")
	GuiControl, +Redraw, LV
	Gui, -Disabled
}

duplicateList() {
	global LV, data, keyArray, CheckboxDuplicates, abortDuplicateflag, duplicateFilter
	Gui, Submit, NoHide
	if !(CheckboxDuplicates) {
		createFilteredList()
		return
	}
	GuiControl, -Redraw, LV
	LV_Delete()
	duplArr := []
	abortDuplicateflag := 0
	if (duplicateFilter)
		col := duplicateFilter
	else
		col := keyArray[1]
	h := WinActive("A")
	total := (data.Count() * (data.Count()-1))/2
	Gui, +Disabled
	Loop % data.Count()
	{
		i := A_Index
		row := data[i]
		rowVal := row[col]
		if (WinActive("ahk_id" . h)) {
			if (abortDuplicateflag == 1)
				break
			crt := (2*data.count()-i+1)*i/2
			ToolTip, % "Loading: " . Format("{1:i}", crt/total*100) . "%"
		}
		else
			ToolTip
		flag := 1
		if (rowVal == "-" || rowVal == " " || arrayContains(duplArr, rowVal))
			continue
		Loop % data.Count() - i
		{
			row2 := data[i+A_Index]
			if (rowVal == row2[col]) {
				if (flag) {
					listViewAddRow(row, keyArray)
					duplarr.push(rowVal)
					flag := 0
				}
				listViewAddRow(row2, keyArray)
			}
		}
	}
	Gui, -Disabled
	GuiControl, +Redraw, LV
	if (abortDuplicateflag == 1) {
		GuiControl,,CheckboxDuplicates, 0
		createFilteredList()
	}
	abortDuplicateflag := -1
	ToolTip
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
		debugShowDataBaseEntry(data.Count(), keyArray)
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
		if (flagUseDefault && e == "")
			switch keyArray[i] {
				case "Wortart":
					e := "?"
				case "Deutsch":
					e := "-"
				case "Kayoogis":
					e := "-"
				case "Runen":
					if (flagUseRunic)
						e := ReplaceChars(r["Kayoogis"], "abdefghiklmnoprstuvyz", "ᚫᛒᛞᛖᚠᚷᚻᛁᚲᛚᛗᚾᛟᛈᚱᛋᛏᚢᚹᛃᛉ")
				case "Tema'i":
					e := "0"
				default:
			}
		if (keyArray[i] == "Wortart")	;// make first column be uppercase
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
	createAddLineBoxesinGUI(keyArray, r)
	Gui, Add, Button, r2 w100 ys+5, Confirm Edit
	fObj := Func("editRowFromMenu").Bind(hw, editLineHWND, trueIndex)
	GuiControl, +g, Confirm Edit, % fObj
	WinGetPos, x, y, w, h, ahk_id %hw%
	if (darkModeToggle)
		toggleGuiDarkMode(editLineHWND)
	Gui, Show, % "x" . x + 50 . " y" . y + h/2-50, EditLineGUITitleThatIsInvisibleSoNooneWillSeeThatILikeJobot
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
	FileSelectFile, exportPath, S24, % folderPath . "\\" . newDefaultFile, % "Export Table as XML File", *.xml
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
			title .= "* - Unsaved Changes"
		for i, guiHwnd in filterGuiArray
			Gui, %guiHwnd%:Show, NoActivate, % title
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
	hw := WinExist("EditLineGUITitleThatIsInvisibleSoNooneWillSeeThatILikeJobot")
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

GuiEscape(GuiHwnd) {
	global filterGuiArray, CheckboxDuplicates, abortDuplicateflag, editLineGUIOwnerHwnd
	Gui, %GuiHwnd%:Submit, NoHide
	WinGetTitle, t, ahk_id %GuiHwnd%
	if (t == "EditLineGUITitleThatIsInvisibleSoNooneWillSeeThatILikeJobot") {
		Gui, %editLineGUIOwnerHwnd%:-Disabled
		Gui, %GuiHwnd%:Destroy
		return
	}
	if (CheckboxDuplicates && abortDuplicateflag == 0) {
		abortDuplicateflag := 1
		return
	}
	GuiClose(GuiHwnd)
}

GuiClose(GuiHwnd) {	;// note, this is in decimal, not hexadecimal.
	global filterGuiArray, flagAutoSaving, flagHasUnsavedChanges
	arrayDeleteValue(filterGuiArray, Format("0x{:x}", GuiHwnd))
	if (flagAutoSaving && flagHasUnsavedChanges) {
		ToolTip % "Saving..."
		directSave()
		ToolTip % "Saving finished."
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
	switch keyArray[SubStr(guiControlVar, 7)] {	;// switches based on keyArray words.
		case "Wortart":
			if (!RegexMatch(%guiControlVar%, "^[?NnVvAaSsPpGg]?$"))
				Gui, Font, % "cRed Bold"
		case "Kayoogis":
			if (RegexMatch(%guiControlVar%, "[cjqwx]"))
				Gui, Font, % "cRed Bold"
		case "Runen":
			if (RegexMatch(%guiControlVar%, "[A-Za-z]"))
				Gui, Font, % "cRed Bold"
		case "Tema'i":
			if !(RegexMatch(%guiControlVar%, "^[01]?$"))
				Gui, Font, % "cRed Bold"
		default:
			return
	}
	GuiControl, Font, %guiControlVar%
	Gui, Font, % (darkModeToggle?"c0xFFFFFF":"cDefault") . " Norm"
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
				default: return
			}
		default: return
	}
}

tableFilterSelectMenuHandler(ItemName) {
	switch ItemName {
		case "Edit Selected Row":
			editSelectedRow(1)
		case "Delete Selected Row(s)":
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
		r := data[trueN].clone() ; NECESSARY, ELSE IT ALREADY AFFECTS DATAINDEX
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
		editrow(trueN, r) something like this
	}
}

toggleSettingDarkmode() {
	global darkModeToggle, appDataPath
	if (darkModeToggle)
		darkModeToggle := 0
	else
		darkModeToggle := 1
	Menu, Tray, ToggleCheck, Use Darkmode
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
	FileSelectFile, path, 3, % defaultPath, % "Load File", *.xml
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
	rawData := StrReplace(rawData, "_x0027_", "'")
    Loop, Parse, rawData, `n, `r
	{
        if (A_Index == 1) {
			if !RegExMatch(A_LoopField,"xml") {
				MsgBox, % "Specified File does not seem to be xml file."
				return 0
			}
			xmlString := A_LoopField . "`r`n"
        }
		if (A_Index == 2) {
			if RegExMatch(A_LoopField, "O)xsi:noNamespaceSchemaLocation=""(.*?)""", m)
				name := m.Value(1)
			else
				name := "Database"
			xmlString .= A_LoopField . "`r`n"
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
    return database
}

loadData() {
	global data, xmlString, metaData, keyArray, loadedFilePath, guiName, filterGuiArray
	global flagLoaded, flagHasUnsavedChanges, flagSimpleSaving, flagUseBackups, settingBackupInterval
	if (flagHasUnsavedChanges) {
		MsgBox, 1,, % "You have unsaved Changes. Do you still want to load a new file?"
		IfMsgBox, Cancel
			return
	}
	loadedFilePath := getDataPath(filterGuiArray) ;// GUI to select a file to load
	if !(loadedFilePath) 	;// if user exits, its blank. then don't do anything.
		return
	if !(FileExist(loadedFilePath)) {
		msgbox % "File could not be found."
		return
	}
	data := loadfile(loadedFilePath)
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
	xmlFileAsString := xmlString
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
	Menu, Tray, Add, % "Open GUI: " . openWindowHotkeyAsString, trayMenuHandler ;// a button to create another window
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
	Menu, Tray, Default, % "Open GUI: " . openWindowHotkeyAsString
	if (darkModeToggle)
		Menu, Tray, Check, Use Darkmode
	try	;// we dont want an error on icon loading.
		Menu, Tray, Icon, %iconPath%,,1
}

trayMenuHandler(menuLabel) {
	global darkModeToggle, appDataPath, reloadHotkeyAsString, openWindowHotkeyAsString
	switch menuLabel {
		case "Open GUI: " . openWindowHotkeyAsString:
			createMainGUI()
		case "Use Darkmode":
			darkModeToggle := !darkModeToggle
			Menu, Tray, ToggleCheck, Use Darkmode
			IniWrite, % darkModeToggle, % appDataPath . "\TableFilter.ini", Settings, DarkMode
			updateGUIColors(darkModeToggle)
		case "Open Backup Folder":
			run, explorer.exe "%appDataPath%"
		case "Open Recent Lines":
			ListLines
		case "Help":
			Run, % RegexReplace(A_AhkPath, "AutoHotkey.exe$", "AutoHotkey.chm")
		case "Reload":
			Reload
		case "Edit Script":
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
		case "Exit":
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

