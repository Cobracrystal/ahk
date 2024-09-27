/*
todo
- on gui without loaded files, have menubar showing last used files
- settings window
	- delete / restore backups, move open backup folder option there
	- all settings as per default values should be in there
	- option to reset
	- font color, background color (specifically: check docs>gui>setfont note at bottom, https://github.com/majkinetor/mm-autohotkey/tree/master/Dlg)
	- disable guis while editing settings?
	- CENTER settings window on main window (also do this for the other GUIs with settings)
- autohdr should have max. also always use max width of lv
- listview headers dark (aka font white)
- instead of only loading, allow for creation of new empty table (-> specify columns and that's it. it should also remove defaultvalues and translate etc)
; missing settings:
; button
openbackupFolder ; Open Backup Folder
; hotkey
guiHotkey ;  hotkey to open GUI (always)

; file browsing
dialogPath ;  path

; color select
darkThemeColor ;  Dark Mode Color

; dropdown menu
duplicateColumn ;  Deutsch
copyColumn ;  Runen
taggingColumn ;  Kategorie
filterCaseSense ;  for searching/filtering, 1/0/Locale
*/
#SingleInstance Force
#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\jsongo.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\TextEditMenu.ahk"

tableInstance := TableFilter(1)

; ONLY start if this script is not used as a library
if (A_ScriptFullPath == A_LineFile) {
	tableInstance.loadData()
}

class TableFilter {

	__New(debug := 0, useConfig := 1) {
		this.data := {
			savePath: TableFilter.savePath,
			openFile: "",
			data: [],
			keys: [],
			rowName: "",
			defaultValues: TableFilter.entryPlaceholderValues,
			isSaved: true
		}
		this.guis := []

		this.configManager("Load", !useConfig)
		this.config.debug := debug
		this.config.useConfig := useConfig

		this.menu := this.createMenu()
		if (A_ScriptFullPath == A_LineFile) {
			A_TrayMenu.Delete()
			A_TrayMenu.Add("TableFilter", (*) => this.guiCreate())
			A_TrayMenu.AddStandard()
		}
		else {
			(gMenu := TrayMenu.submenus["GUIs"]).Add("Open TableFilter (" this.config.guiHotkey ")", (*) => this.guiCreate())
			A_TrayMenu.Add("GUIs", gMenu)
		}
		HotIfWinactive("ahk_group TableFilterGUIs")
		Hotkey(this.config.saveHotkey, (*) => this.saveFile(this.data.openFile, false))
		HotIfWinactive()
		Hotkey(this.config.guiHotkey, (*) => this.guiCreate())
		OnExit(this.exit.bind(this), 1)
	}

	guiCreate() {
		if (!this.data.openFile && this.guis.Length == 1) {
			WinActivate(this.guis[1].hwnd)
			return 0
		}
		guiObj := Gui("+Border +Resize")
		guiObj.OnEvent("Close", this.guiClose.bind(this))
		guiObj.OnEvent("Escape", this.guiClose.bind(this))
		guiObj.OnEvent("DropFiles", this.dropFiles.bind(this))
		guiObj.OnEvent("Size", this.guiResize.bind(this))
		guiObj.SetFont("c0x000000") ; this is necessary to force font of checkboxes / groupboxes
		GroupAdd("TableFilterGUIs", "ahk_id " guiObj.hwnd)
		if (this.data.openFile) {
			SplitPath(this.data.openFile, &name)
			guiObj.Title := (this.data.isSaved ? "" : "*") . this.base.__Class " - " name
			gbox := guiObj.AddGroupBox("Section w745 h42", "Search")
			guiObj.AddButton("ys+13 xp+8 w30 h22", "Clear").OnEvent("Click", this.clearSearchBoxes.bind(this))
			for i, key in this.data.keys {
				t := guiObj.AddText("ys+16 xp+" (i == 1 ? 40 : 55), key).GetPos(, , &w)
				(ed := guiObj.AddEdit("ys+13 xp+" w + 10 " r1 w45 vEditSearchCol" i)).OnEvent("Change", this.createFilteredList.bind(this))
			}
			ed.GetPos(&ex, , &ew)
			gbox.GetPos(&gbX)
			gbox.Move(, , ex - gbX + ew + 8)
			(guiObj.CBDuplicates := guiObj.AddCheckbox("ys+6 xs+" ex - gbX + ew + 18, "Duplicates")).OnEvent("Click", this.searchDuplicates.bind(this))
			(btnSettings := guiObj.AddButton("ys+5 w50", "Settings")).OnEvent("Click", this.createSettingsGui.bind(this))
			rowKeys := this.data.keys.Clone()
			rowKeys.push("DataIndex")
			guiObj.LV := guiObj.AddListView("xs R35 w950 +Multi", rowKeys) ; LVEvent, Altsubmit
			guiObj.LV.OnNotify(-155, this.LV_Event.bind(this, "Key"))
			guiObj.LV.OnEvent("ContextMenu", this.LV_Event.bind(this, "ContextMenu"))
			guiObj.LV.OnEvent("DoubleClick", this.LV_Event.bind(this, "DoubleClick"))
			this.createFilteredList(guiObj)
			; Wortart, Deutsch, Kayoogis, Runen, Anmerkung, Kategorie, Tema'i, dataIndex (possibly). At least dataindex always last.
			if !(this.config.debug)
				guiObj.LV.ModifyCol(this.data.keys.Length + 1, "0 Integer")
			else
				guiObj.LV.ModifyCol(this.data.keys.Length + 1, "100 Integer")
			Loop (this.data.keys.Length)
				guiObj.LV.ModifyCol(A_Index, "AutoHdr")
			guiObj.topRightControls := []
			guiObj.addRowControls := []
			guiObj.fileControls := []
			guiObj.addRowControls.Push(guiObj.AddGroupBox("Section w" 10 + 95 * this.data.keys.Length + 75 " h65", "Add Row"))
			for i, e in this.data.keys {
				guiObj.addRowControls.Push(guiObj.AddText("ys+15 xs+" 10 + ((i - 1) * 95), e))
				(ed := guiObj.AddEdit("r1 w85 vEditAddRow" i, "")).OnEvent("Change", this.validValueChecker.bind(this))
				guiObj.addRowControls.Push(ed)
			}
			(btn := guiObj.AddButton("Default ys+15 xs+" 10 + 95 * this.data.keys.Length " h40 w65", "Add Row to List")).OnEvent("Click", this.addEntry.bind(this))
			guiObj.addRowControls.Push(btn)
			guiObj.LV.GetPos(, , &lvw)
			(btn := guiObj.AddButton("ys+9 xs+" lvw - 100 " w100", "Load json/xml File")).OnEvent("Click", this.loadData.bind(this, ""))
			guiObj.fileControls.Push(btn)
			(btn := guiObj.AddButton("w100", "Export to File")).OnEvent("Click", (*) => this.saveFile(this.data.openFile, true))
			guiObj.fileControls.Push(btn)
			btnSettings.Move(gbX + lvw - 50)
			btnSettings.Redraw()
			guiObj.topRightControls.Push(btnSettings)
			showString := "Center Autosize"
		} else {
			guiObj.Title := this.base.__Class " - No File Selected"
			guiObj.AddButton("x125 y100 w250 h200 Default", "Load File").OnEvent("Click", this.loadData.bind(this, ""))
			showString := "Center w500 h400"
		}
		this.toggleGuiDarkMode(guiObj, this.config.darkMode)
		this.guis.push(guiObj)
		guiObj.Show(showString)
	}

	createFilteredList(guiObj, *) {
		if (guiObj is Gui.Control)
			guiObj := guiObj.Gui
		if (guiObj.CBDuplicates.Value) {
			this.searchDuplicates(guiObj.CBDuplicates)
			return
		}
		guiObj.Opt("+Disabled")
		guiObj.LV.Opt("-Redraw")
		guiObj.LV.Delete()
		for i, e in this.data.data {
			if (this.rowIncludeFromSearch(guiObj, e))
				this.addRow(guiObj, e, i)
		}
		if (guiObj.LV.GetCount() == 0)
			this.addRow(guiObj, Map(this.data.keys[1], "/", this.data.keys[2], "Nothing Found"), -1)
		guiObj.LV.Opt("+Redraw")
		guiObj.Opt("-Disabled")
	}

	searchDuplicates(ctrlObj, *) {
		guiObj := ctrlObj.Gui
		if !(ctrlObj.Value) {
			this.createFilteredList(guiObj)
			return
		}
		guiObj.Opt("+Disabled")
		guiObj.LV.Opt("-Redraw")
		guiObj.LV.Delete()
		if (objContainsValue(this.data.keys, this.config.duplicateColumn))
			filterKey := this.config.duplicateColumn
		else
			filterKey := this.data.keys[1]
		default := (this.data.defaultValues.Has(filterKey) ? this.data.defaultValues[filterKey] : "")
		duplicateMap := Map()
		duplicateMap.CaseSense := this.config.filterCaseSense
		for i, row in this.data.data {
			if (!row.Has(filterKey))
				continue
			v := row[filterKey]
			if (duplicateMap.has(v))
				duplicateMap[v].push([row, i])
			else
				duplicateMap[v] := [[row, i]]
		}
		for i, row in this.data.data {
			if (!row.Has(filterKey) || (v := row[filterKey]) == "" || v == default)
				continue
			if (duplicateMap[v].Length > 1) {
				for _, arr in duplicateMap[v] {
					if (this.rowIncludeFromSearch(guiObj, arr[1]))
						this.addRow(guiObj, arr[1], arr[2])
				}
				duplicateMap[v] := []
			}
		}
		if (guiObj.LV.GetCount() == 0)
			this.addRow(guiObj, Map(this.data.keys[1], "/", this.data.keys[2], "Nothing Found"), -1)
		guiObj.LV.Opt("+Redraw")
		guiObj.Opt("-Disabled")
	}

	rowIncludeFromSearch(guiObj, row) {
		for i, e in this.data.keys {
			v := guiObj["EditSearchCol" . i].Value
			if (v != "" && (!row.Has(e) || !InStr(row[e], v, this.config.filterCaseSense))) {
				return false
			}
		}
		return true
	}

	/**
	 * Adds given row object with specified dataIndex to specified GUI.
	 */
	addRow(gui, row, dataIndex, LVIndex?) {
		rowArr := []
		for _, key in this.data.keys
			rowArr.push(row.Has(key) ? row[key] : "")
		rowArr.push(dataIndex)
		if (IsSet(LVIndex))
			gui.LV.Insert(LVIndex, "", rowArr*)
		else
			gui.LV.Add("", rowArr*)
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
		this.dataHandler("isSaved", false)
		for _, g in this.guis
			if (this.rowIncludeFromSearch(g, newRow))
				this.addRow(g, newRow, this.data.data.Length)
		aGui.LV.Modify(aGui.LV.GetCount(), "Select Focus Vis")
	}

	editRow(n, newRow) {
		oldRow := this.data.data[n]
		this.data.data[n] := newRow
		for _, g in this.guis {
			g.Opt("+Disabled")
			flagNewRowVisible := this.rowIncludeFromSearch(g, newRow)
			if (this.rowIncludeFromSearch(g, oldRow)) {
				Loop (g.LV.GetCount()) {
					dataIndex := g.LV.GetText(A_Index, this.data.keys.Length + 1)
					if (dataIndex == n) {
						if (flagNewRowVisible) {
							rowAsArray := []
							for i, e in this.data.keys
								rowAsArray.Push(newRow.Has(e) ? newRow[e] : "")
							rowAsArray.Push(n)
							g.LV.Modify(A_Index, , rowAsArray*)
						} else {
							g.LV.Delete(n)
						}
						break
					}
				}
			} else if (flagNewRowVisible) {
				this.addRow(g, newRow, n)
			}
			g.Opt("-Disabled")
		}
		this.dataHandler("isSaved", false)
	}

	editRowGui(guiObj) {
		rowN := guiObj.LV.GetNext(0, "F") ;// next row
		if !(rowN)
			return
		guiObj.Opt("+Disabled")
		dataIndex := guiObj.LV.GetText(rowN, this.data.keys.Length + 1)
		row := this.data.data[dataIndex]
		editorGui := Gui("-Border -SysMenu +Owner" guiObj.Hwnd)
		editorGui.dataIndex := dataIndex
		editorGui.parent := guiObj
		if (!guiObj.HasOwnProp("children"))
			guiObj.children := []
		guiObj.children.push(editorGui)
		editorGui.OnEvent("Escape", editRowGuiEscape)
		editorGui.OnEvent("Close", editRowGuiEscape)
		editorGui.SetFont("c0x000000") ; this is necessary to force font of checkboxes / groupboxes
		editorGui.AddGroupBox("Section w" 10 + 95 * this.data.keys.Length + 75 " h65", "Edit Row")
		for i, e in this.data.keys {
			editorGui.AddText("ys+15 xs+" 10 + ((i - 1) * 95), e)
			editorGui.AddEdit("r1 w85 vEditAddRow" i, row.Has(e) ? row[e] : "").OnEvent("Change", this.validValueChecker.bind(this))
		}
		editorGui.AddButton("Default ys+15 xs+" 10 + 95 * this.data.keys.Length " h40 w65", "Save Row").OnEvent("Click", editRowGuiFinish.bind(this))
		this.toggleGuiDarkMode(editorGui, this.config.darkMode)
		editorGui.Show()
		return

		editRowGuiFinish(this, guiCtrl, *) {
			newRow := Map()
			for i, key in this.data.keys
				newRow[key] := guiCtrl.gui["EditAddRow" i].Value
			this.cleanRowData(newRow)
			this.editRow(guiCtrl.gui.dataIndex, newRow)
			parent := guiCtrl.gui.parent
			objRemoveValue(parent.children, guiCtrl.gui)
			parent.Opt("-Disabled")
			guiCtrl.gui.Destroy()
			WinActivate(parent)
			for i, g in this.guis
				g.Opt("-Disabled")
			objRemoveValue(guiObj.parent.children, guiObj)
			guiObj.Destroy()
		}

		editRowGuiEscape(guiObj) {
			guiObj.parent.Opt("-Disabled")
			guiObj.Destroy()
		}
	}

	removeSelectedRows(gui) {
		rows := []
		gui.Opt("+Disabled")
		Loop {
			rowN := gui.LV.GetNext(rowN ?? 0) ;// next row
			if !(rowN)
				break
			rows.push(gui.LV.GetText(rowN, this.data.keys.Length + 1))
		}
		if (!rows.Length)
			return
		sortedRows := sortArray(rows, "R N")
		for _, g in this.guis {
			g.Opt("+Disabled")
			rowsInLV := [], indexToRemove := []
			for j, n in sortedRows
				if (this.rowIncludeFromSearch(g, this.data.data[n]))
					rowsInLV.push(n)
			Loop (g.LV.GetCount()) {
				rowN := A_Index
				dataIndex := g.LV.GetText(rowN, this.data.keys.Length + 1)
				for j, n in rowsInLV {
					if (dataIndex == n) {
						indexToRemove.push(rowN)
						rowsInLV.RemoveAt(j)
						continue 2 ; continue outer to skip rest. its not harmful though, just break works fine (but is slower)
					}
				}
				offset := 0
				for j, n in sortedRows {
					if (dataIndex > n) {
						offset := sortedRows.Length - j + 1
						break
					}
				}
				if (offset)
					g.LV.Modify(rowN, "Col" . this.data.keys.Length + 1, dataIndex - offset)
			}
			; we don't need to queue them if we do -Redraw at the start.
			g.LV.Opt("-Redraw")
			for k, rowN in indexToRemove
				g.LV.Delete(indexToRemove[indexToRemove.Length - k + 1]) ; backwards to avoid fucking up the list
			g.LV.Opt("+Redraw")
			g.Opt("-Disabled")
		}
		for i, e in sortedRows
			this.data.data.RemoveAt(e)
		this.dataHandler("isSaved", false)
	}

	cleanRowData(row) { ; row is a map and thus operates onto the object
		for i, e in this.data.keys {
			if (this.config.useDefaultValues && (row[e] == "") && this.data.defaultValues.Has(e)) {
				row[e] := this.data.defaultValues[e]
				switch e { ; yea this isn't generic but who cares. Just edit these whenever.
					case "Runen": ; Runen
						if (this.config.autoTranslateRunic && IsSet(TextEditMenu) && IsObject(TextEditMenu) && TextEditMenu.HasMethod("runify"))
							row[e] := TextEditMenu.runify(row["Kayoogis"], "DE")
						else row[e] := ""
				}
			}
			if (this.config.formatValues) {
				switch e {
					case "Wortart":
						row[e] := Format("{:U}", row[e])
				}
			}
			row[e] := Trim(row[e])
		}
	}


	validValueChecker(ctrlObj, *) {
		newFont := (this.config.darkMode ? "c0xFFFFFF Norm" : "cDefault Norm")
		switch this.data.keys[Integer(SubStr(ctrlObj.Name, -1))] {
			case "Wortart":
				if (!RegexMatch(ctrlObj.Value, "i)^[?nvaspg]?$"))
					newFont := "cRed Bold"
			case "Kayoogis":
				if (RegexMatch(ctrlObj.Value, "i)[cjqwx]"))
					newFont := "cYellow Bold"
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

	toggleGuiDarkMode(guiObj, dark) {
		;// title bar dark
		if (VerCompare(A_OSVersion, "10.0.17763")) {
			attr := 19
			if (VerCompare(A_OSVersion, "10.0.18985")) {
				attr := 20
			}
			if (dark)
				DllCall("dwmapi\DwmSetWindowAttribute", "ptr", guiObj.hwnd, "int", attr, "int*", true, "int", 4)
			else
				DllCall("dwmapi\DwmSetWindowAttribute", "ptr", guiObj.hwnd, "int", attr, "int*", false, "int", 4)
		}
		guiObj.BackColor := (dark ? this.config.darkThemeColor : "Default") ; "" <-> "Default" <-> 0xFFFFFF
		font := (dark ? "c0xFFFFFF" : "cDefault")
		guiObj.SetFont(font)
		for cHandle, ctrl in guiObj {
			ctrl.Opt(dark ? "+Background" this.config.darkThemeColor : "-Background")
			ctrl.SetFont(font)
			if (ctrl is Gui.Button)
				DllCall("uxtheme\SetWindowTheme", "ptr", ctrl.hwnd, "str", (dark ? "DarkMode_Explorer" : ""), "ptr", 0)
			if (ctrl is Gui.ListView) {
				listviewDarkmode(ctrl, dark)
				; and https://www.autohotkey.com/board/topic/76897-ahk-u64-issue-colored-text-in-listview-headers/
				; maybe https://www.autohotkey.com/boards/viewtopic.php?t=87318
				; full customization control: https://www.autohotkey.com/boards/viewtopic.php?t=115952
			}
			if (ctrl.Name && SubStr(ctrl.Name, 1, 10) == "EditAddRow") {
				this.validValueChecker(ctrl)
			}
		}
		if (guiObj.HasOwnProp("children"))
			for i, g in guiObj.children
				if (g is Gui)
					this.toggleGuiDarkMode(g, dark)
		return

		listviewDarkmode(lv, dark) {
			static LVM_GETHEADER := 0x101F
			static LVS_EX_DOUBLEBUFFER := 0x10000
			static WM_NOTIFY := 0x4E
			static WM_THEMECHANGED := 0x031A
			; prevent other changes to UI on darkmode
			OnMessage(WM_THEMECHANGED, themechangeIntercept.bind(lv.hwnd))
			; header dark (CURRENTLY DOESN'T WORK)
			lv.header := SendMessage(LVM_GETHEADER, 0, 0, lv.hwnd)
			;	OnMessage(WM_NOTIFY, On_NM_CUSTOMDRAW.bind(lv)) ; header text white
			; reduce flickering
			lv.Opt("+LV" LVS_EX_DOUBLEBUFFER)
			;	DllCall("uxtheme\SetWindowTheme", "ptr", lv.header, "str", (dark ? "DarkMode_ItemsView" : ""), "ptr", 0)
			; hide focus dots
			; SendMessage(WM_CHANGEUISTATE, (UIS_SET << 8) | UISF_HIDEFOCUS, 0, ctrl.hwnd)
			DllCall("uxtheme\SetWindowTheme", "ptr", lv.hwnd, "str", (dark ? "DarkMode_Explorer" : ""), "ptr", 0)
			return

			themechangeIntercept(checkHWND, wParam, lParam, msg, hwnd) {
				if (hwnd == checkHWND)
					return 0
			}

			On_NM_CUSTOMDRAW(LV, wParam, lParam, msg, hwnd) {
				static NM_CUSTOMDRAW := -12
				static CDRF_DODEFAULT := 0x00000
				static CDRF_NEWFONT := 0x00002
				static CDRF_NOTIFYITEMDRAW := 0x00020
				static CDRF_NOTIFYSUBITEMDRAW := 0x00020
				static CDDS_PREPAINT := 0x00001
				static CDDS_ITEMPREPAINT := 0x10001
				static CDDS_SUBITEM := 0x20000
				static offsetHWND := 0
				static offsetMsgCode := (2 * A_PtrSize)
				static offsetDrawstage := offsetMsgCode + A_PtrSize
				static offsetHDC := offsetDrawstage + 8
				static offsetItemspec := offsetHDC + 16 + A_PtrSize

				; Get sending control's HWND
				ctrlHwnd := NumGet(lParam, offsetHWND, "Ptr")
				if (LV.Header == ctrlHwnd && (NumGet(lParam + 0, offsetMsgCode, "Int") == NM_CUSTOMDRAW)) {
					drawStage := NumGet(lParam, offsetDrawstage, "Int")
					; -------------------------------------------------------------------------------------------------------------
					item := NumGet(lParam, offsetItemspec, "Ptr") ; for testing
					LV.Modify(LV.Add("", NumGet(lParam + 0, offsetMsgCode, "Int"), drawStage, item), "Vis")	 ; for testing; -------------------------------------------------------------------------------------------------------------
					switch drawStage {
						case CDDS_PREPAINT:
							return CDRF_NOTIFYITEMDRAW
						case CDDS_ITEMPREPAINT:
							HDC := NumGet(lParam, offsetHDC, "UPtr")
							DllCall("SetTextColor", "Ptr", HDC, "UInt", 0xFFFFFF)
							return CDRF_NEWFONT
					}
					return CDRF_DODEFAULT
				}
			}
		}
	}

	clearSearchBoxes(guiObj, *) {
		if (guiObj is Gui.Control)
			guiObj := guiObj.gui
		for i, e in this.data.keys {
			ctrl := guiObj["EditSearchCol" i]
			ctrl.OnEvent("Change", this.createFilteredList.bind(this), 0)
			ctrl.Value := ""
			ctrl.OnEvent("Change", this.createFilteredList.bind(this))
		}
		this.createFilteredList(guiObj)
	}

	LV_Event(eventType, guiCtrl, lParam, *) {
		guiObj := guiCtrl.Gui
		switch eventType, 0 {
			case "Key":
				vKey := NumGet(lParam, 24, "ushort")
				switch vKey {
					case 46: ; DEL key
						this.removeSelectedRows(guiObj)
					case 67: ; C key
						if ((rowN := guiObj.LV.GetNext()) == 0)
							return
						if (GetKeyState("Ctrl")) {
							col := objContainsValue(this.data.keys, this.config.copyColumn)
							A_Clipboard := (col ? guiObj.LV.GetText(rowN, col) : guiObj.LV.GetText(0))
						}
					case 113: ; F2 key
						this.editRowGui(guiObj)
					case 116: ; F5 key
						this.createFilteredList(guiObj)
				}
			case "ContextMenu":
				this.menu.launcherGuiObj := guiObj
				this.menu.Show()
			case "DoubleClick":
				this.editRowGui(guiObj)
			default:
				return
		}
	}

	createMenu() {
		aMenu := Menu()
		for i, c in TableFilter.wordCategories
			aMenu.Add(c, this.cMenuHandler.bind(this, , , , 1))
		rMenu := Menu()
		for i, c in TableFilter.wordCategories
			rMenu.Add(c, this.cMenuHandler.bind(this, , , , 0))
		rMenu.Add("All", this.cMenuHandler.bind(this, , , , 0))
		tMenu := Menu()
		tMenu.Add("[F2] 🖊️ Edit Selected Row", this.cMenuHandler.bind(this))
		tMenu.Add("[Del] 🗑️ Delete Selected Row(s)", this.cMenuHandler.bind(this))
		if (this.config.taggingColumn) {
			tMenu.Add("➕ Add Category to Selected Row(s)", aMenu)
			tMenu.Add("➖ Remove Category from Selected Row(s)", rMenu)
		}
		if (this.config.debug) {
			tMenu.Add("Show Data Entry", this.cMenuHandler.bind(this))
			tMenu.Add("Show Config", this.cMenuHandler.bind(this))
			tMenu.Add("Show Internal Data", this.cMenuHandler.bind(this))
		}
		return tMenu
	}

	cMenuHandler(itemName, itemPos, menuObj, extra?) {
		g := this.menu.launcherGuiObj
		if ((rowN := g.LV.GetNext()) == 0)
			return
		switch itemName {
			case "[F2] 🖊️ Edit Selected Row":
				this.editRowGui(g)
			case "[Del] 🗑️ Delete Selected Row(s)":
				this.removeSelectedRows(g)
			case "Show Data Entry":
				n := g.LV.GetText(rowN, this.data.keys.Length + 1)
				this.debugShowDatabaseEntry(g, n, rowN)
			case "Show Config":
				MsgBox(jsongo.Stringify(this.config, , A_Tab), , "Owner" g.Hwnd)
			case "Show Internal Data":
				smallData := {}
				for i, e in this.data.OwnProps()
					smallData.%i% := (i == "data" ? "NOT SHOWN" : e)
				MsgBox(jsongo.Stringify(smallData, , A_Tab), , "Owner" g.Hwnd)
			default:
				if (IsSet(extra))
					this.rowTagger(itemName, g, extra)
		}
	}

	rowTagger(tag, guiObj, tagState) {
		rows := []
		guiObj.Opt("+Disabled")
		Loop {
			rowN := guiObj.LV.GetNext(rowN ?? 0) ;// next row
			if !(rowN)
				break
			rows.push(guiObj.LV.GetText(rowN, this.data.keys.Length + 1))
		}
		if (!rows.Length)
			return
		c := TableFilter.wordCategories
		for i, index in rows {
			row := this.data.data[index].Clone()
			curCategories := row.Has(this.config.taggingColumn) ? row[this.config.taggingColumn] : ""
			if (tagState)
				curCategories .= "," tag
			else
				curCategories := (tag == "All" ? "" : StrReplace(curCategories, tag))
			row[this.config.taggingColumn] := Trim(Sort(curCategories, "P3 U D,"), ", ")
			this.editRow(index, row)
		}
	}

	guiResize(guiObj, minMax, nw, nh) {
		Critical("Off")
		if !(this.data.openFile) {
			for i, ctrl in guiObj {
				ctrl.Move(nw // 4, nh // 4, nw // 2, nh // 2)
				ctrl.Redraw()
			}
			return
		}
		guiObj.LV.GetPos(, , &lvw, &lvh)
		guiObj.LV.Move(, , nw - 20, nh - 131)
		guiObj.LV.GetPos(, , &lvnw, &lvnh)
		deltaW := lvnw - lvw
		deltaH := lvnh - lvh
		for index, ctrl in guiObj.topRightControls {
			ctrl.GetPos(&cx, &cy)
			ctrl.Move(cx + deltaW)
			ctrl.Redraw()
		}
		for jndex, ctrl in guiObj.addRowControls {
			ctrl.GetPos(, &cy)
			ctrl.Move(, cy + deltaH)
			ctrl.Redraw()
		}
		for kndex, ctrl in guiObj.fileControls {
			ctrl.GetPos(&cx, &cy)
			ctrl.Move(cx + deltaW, cy + deltaH)
			ctrl.Redraw()
		}
	}

	guiClose(guiObj) {
		objRemoveValue(this.guis, guiObj)
		guiObj.Destroy()
	}

	dropFiles(guiObj, ctrlObj, fileArr, x, y) {
		if (fileArr.Length > 1)
			return
		this.loadData(fileArr[1])
	}

	loadData(filePath := "", *) {
		if (!this.data.isSaved) {
			if (this.config.autoSaving)
				this.saveFile(this.data.openFile, false)
			else {
				res := MsgBox("You have unsaved Changes in " this.data.openFile "`nSave Changes before loading " (filePath ? filePath : "a new File") "?", this.base.__Class, "0x3 Owner" A_ScriptHwnd)
				if (res == "Cancel")
					return
				else if (res == "Yes")
					this.saveFile(this.data.openFile, false)
			}
		}
		if (filePath == "") {
			if (this.config.useCustomDialogPath)
				path := this.config.customDialogPath
			else if (this.config.lastUsedFile)
				path := this.config.lastUsedFile
			else
				path := A_ScriptDir
			for i, g in this.guis
				g.Opt("+Disabled")
			filePath := FileSelect("3", path, "Load File", "Data (*.xml; *.json)")
			for i, g in this.guis
				g.Opt("-Disabled")
			if (!filePath)
				return
		}
		loadFile(filePath)
		this.dataHandler("openFile", filePath)
		; add option for tab controls here (aka supporting multiple files)

		while (this.guis.Length > 0)
			this.guiClose(this.guis.pop())
		; now, update gui or all guis with the new data. ????
		if (this.config.useBackups) {
			; update backup function
			SetTimer(this.backupIterator.bind(this), 0)
			this.backupIterator(1)
			SetTimer(this.backupIterator.bind(this), this.config.backupInterval * 60000)
		}
		this.guiCreate()
		this.dataHandler("lastUsedFile", filePath)
		this.dataHandler("isSaved", true)

		loadFile(path) {
			SplitPath(path, , , &ext)
			fileAsStr := FileRead(path, "UTF-8")
			lastSeenKey := ""
			if (ext = "json") {
				data := jsongo.Parse(fileAsStr)
				keys := []
				for i, e in data {
					for j, f in e { ; todo: this messes up the order of the keys btw in case of json. custom parse??
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
					if (RegexMatch(A_LoopField, "^\s*<(.*?)>\s*$", &m)) {
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
					field := A_LoopField
					Loop Parse, field, "`n", "`r" {
						if RegexMatch(A_LoopField, "<(.*?)>([\s\S]*?)<\/\1>", &m) {
							key := m[1]
							row[key] := m[2]
							if !(objContainsValue(keys, key)) {
								keys.InsertAt(objContainsValue(keys, lastSeenKey) + 1, key)
							}
							lastSeenKey := key
						}
					}
					if (row.Count > 0 || InStr(field, "</" rowName ">"))
						rawData.Push(row)
				}
				data.Length := rawData.Length
				for i, e in rawData {
					t := Map()
					for j, f in e
						t[unescape(j)] := unescape(f)
					data[i] := t
				}
				for i, e in keys
					keys[i] := nameUnescape(e)
			}
			this.data.keys := keys
			this.data.data := data
			this.data.rowName := rowName ?? "Table"

			unescape(t) { ; ORDER NECESSARY, AMP LAST.
				t := StrReplace(t, "&apos;", "'")
				t := StrReplace(t, "&quot;", '"')
				t := StrReplace(t, "&gt;", ">")
				t := StrReplace(t, "&lt;", "<")
				t := StrReplace(t, "&amp;", "&")
				return t
			}

			nameUnescape(t) {
				for i, e in TableFilter.sharepointEscapeCodes
					t := StrReplace(t, e, i)
				return t
			}
		}
	}

	saveFile(filePath := "", dialog := 0) {
		if (filePath == "" || dialog) { ; overwrites loaded file.
			dialog := true
			for i, g in this.guis
				g.Opt("+Disabled")
			SplitPath(filePath ? filePath : this.data.openFile, &fName)
			filePath := this.config.useCustomDialogPath ? this.config.customDialogPath "\" fName : (this.config.lastUsedFile ? this.config.lastUsedFile : A_ScriptDir "\" fName)
			filePath := FileSelect("S16", filePath, "Save File", "Data (*.xml; *.json)")
			for i, g in this.guis
				g.Opt("-Disabled")
			if (!filePath)
				return
		}
		SplitPath(filePath, &fName, &fDir, &fExt)
		if (fExt == "json")
			fileAsStr := jsongo.Stringify(this.data.data)
		else
			fileAsStr := exportAsXML()
		fObj := FileOpen(filePath, "w", "UTF-8")
		fObj.Write(fileAsStr)
		fObj.Close()
		this.dataHandler("isSaved", true)
		if (dialog) {
			this.dataHandler("lastUsedFile", filePath)
			this.dataHandler("openFile", filePath)
		}
		return

		exportAsXML() {
			xmlFileAsString := '<?xml version="1.0" encoding="UTF-8"?>`n<dataroot generated="' FormatTime(, "yyyy-MM-ddTHH:mm:ss") '">`n'
			keysEsc := []
			for i, k in this.data.keys
				keysEsc.Push(escapeName(k))
			xmlFileAsString .= Format("<{1}>`n", this.data.rowName)
			for i, key in this.data.keys ; first entry should contain all keys in order
				xmlFileAsString .= Format("<{1}>{2}</{3}>`n", keysEsc[i], this.data.data[1].has(key) ? escape(this.data.data[1][key]) : "", keysEsc[i])
			xmlFileAsString .= Format("</{1}>`n", this.data.rowName)
			Loop (this.data.data.Length - 1) {
				dataIndex := A_Index + 1
				row := this.data.data[dataIndex]
				s := Format("<{1}>`n", this.data.rowName)
				for i, key in this.data.keys
					if (row.Has(key))
						s .= Format("<{1}>{2}</{3}>`n", keysEsc[i], escape(row[key]), keysEsc[i])
				s .= Format("</{1}>`n", this.data.rowName)
				xmlFileAsString .= s
			}
			xmlFileAsString .= "</dataroot>"
			return xmlFileAsString

			escape(t) {
				t := StrReplace(t, "&", "&amp;")
				t := StrReplace(t, "'", "&apos;")
				t := StrReplace(t, '"', "&quot;")
				t := StrReplace(t, ">", "&gt;")
				t := StrReplace(t, "<", "&lt;")
				return t
			}

			escapeName(t) {
				for i, e in TableFilter.sharepointEscapeCodes
					t := StrReplace(t, i, e)
				return t
			}
		}
	}

	backupIterator(doInitialBackup := 0) {
		; instead of a timer or something, this should save the current time once and on every change this gets called, and if enough time has passed -> backup is made
		SplitPath(this.data.openFile, , , &fExt, &fName)
		backupPath := Format("{1}\Backup_{2}_{3}.{4}",
			this.data.savePath,
			fName,
			doInitialBackup ? "Original" : FormatTime(A_Now, "yyyy.MM.dd-HH.mm.ss"),
			fExt
		)
		this.saveFile(backupPath, false)
		this.deleteExcessBackups()
	}

	deleteExcessBackups(filePath := "") {
		if (!filePath)
			filePath := this.data.openFile
		SplitPath(filePath, , , &fExt, &fName)
		backupPath := this.data.savePath "\Backup_" fName "_*." fExt
		i := 0, oldestBackupTime := 0
		Loop Files backupPath {
			if !(InStr(A_LoopFileName, "Original")) {
				i++
				if (!oldestBackupTime || oldestBackupTime > A_LoopFileTimeCreated) {
					oldestBackupTime := A_LoopFileTimeCreated
					oldestBackup := A_LoopFileFullPath
				}
			}
		}
		if (i > this.config.backupAmount) {
			FileDelete(oldestBackup)
			this.deleteExcessBackups() ; in the event that there's multiple excess backups.
		}
	}

	debugShowDatabaseEntry(guiObj, n, rowN) {
		row := this.data.data[n]
		s := jsongo.Stringify(this.data.data[n], , A_Tab)
		msgbox(s "`nDatabase Index: " n "`nRow Number: " rowN, , "Owner" guiObj.Hwnd)
	}

	dataHandler(option, value) {
		switch option {
			case "openFile":
				this.data.openFile := value
				SplitPath(this.data.openFile, &name)
				for _, g in this.guis
					g.Title := (this.data.isSaved ? "" : "*") . this.base.__Class " - " name
			case "isSaved":
				this.data.isSaved := value
				for _, g in this.guis {
					if (this.data.isSaved && SubStr(g.Title, 1, 1) == "*")
						g.Title := SubStr(g.Title, 2)
					else if (!this.data.isSaved && SubStr(g.Title, 1, 1) != "*")
						g.Title := "*" . g.Title
				}
				save := false
			case "lastUsedFile":
				this.config.lastUsedFile := value
				if (this.config.useConfig)
					this.configManager("Save")
			default:
				throw (Error("Bad setting: " . option))
		}
	}

	configGuiHandler(ctrl, *) {
		switch ctrl.Name {
			case "CBDebug":
				this.config.debug := !this.config.debug
				this.menu := this.createMenu()
			case "CBDarkMode":
				this.config.darkMode := !this.config.darkMode
				for _, g in this.guis
					this.toggleGuiDarkMode(g, this.config.darkMode)
			case "CBAutoSaving":
				this.config.autoSaving := !this.config.autoSaving
			case "CBUseBackups":
				SetTimer(this.backupIterator.bind(this), 0)
				if (this.config.useBackups := !this.config.useBackups) {
					this.backupIterator(1)
					SetTimer(this.backupIterator.bind(this), this.config.backupInterval * 60000)
				}
			case "CBUseDefaultValues":
				this.config.useDefaultValues := !this.config.useDefaultValues
			case "CBAutoTranslateRunic":
				this.config.autoTranslateRunic := !this.config.autoTranslateRunic
			case "CBFormatValues":
				this.config.formatValues := !this.config.formatValues
			case "CBUseCustomDialogPath":
				this.config.useCustomDialogPath := !this.config.useCustomDialogPath
			case "ButtonDialogPath":
				if (this.config.customDialogPath)
					path := this.config.customDialogPath
				else
					SplitPath(this.config.lastUsedFile, , &path)
				newPath := FileSelect("D3", path, "Please select a folder")
				if (newPath != "")
					this.config.customDialogPath := newPath
			default:
				return
				; throw (Error("This setting doesn't exist (yet): " . ctrl.Name))
		}
		if (this.config.useConfig)
			this.configManager("Save")
	}

	createSettingsGui(guiObj, *) {
		if (guiObj is Gui.Control)
			guiObj := guiObj.gui
		for i, g in this.guis
			g.Opt("+Disabled")
		settingsGui := Gui("+Border +OwnDialogs +Owner" guiObj.Hwnd, "Settings")
		settingsGui.OnEvent("Escape", settingsGUIClose)
		settingsGui.OnEvent("Close", settingsGUIClose)
		settingsGui.SetFont("c0x000000") ; this is necessary to force font of checkboxes / groupboxes
		settingsGui.AddText("Center Section", "Settings for YoutubeDL Gui")

		settingsGui.AddCheckbox("vCBDebug Checked" this.config.debug, "Debugging mode").OnEvent("Click", this.configGuiHandler.bind(this))
		settingsGui.AddCheckbox("vCBDarkMode Checked" this.config.darkMode, "Dark mode").OnEvent("Click", this.configGuiHandler.bind(this))
		settingsGui.AddCheckbox("vCBAutoSaving Checked" this.config.autoSaving, "Autosave when exiting").OnEvent("Click", this.configGuiHandler.bind(this))
		settingsGui.AddCheckbox("vCBUseBackups Checked" this.config.useBackups, "Backup opened files regularly in %APPDATA%\Autohotkey\Tablefilter").OnEvent("Click", this.configGuiHandler.bind(this))
		settingsGui.AddCheckbox("vCBUseDefaultValues Checked" this.config.useDefaultValues, "Insert placeholder values into empty fields when editing rows").OnEvent("Click", this.configGuiHandler.bind(this))
		settingsGui.AddCheckbox("vCBAutoTranslateRunic Checked" this.config.autoTranslateRunic, "Automatically translate Kayoogis into runes").OnEvent("Click", this.configGuiHandler.bind(this))
		settingsGui.AddCheckbox("vCBFormatValues Checked" this.config.formatValues, "Format values").OnEvent("Click", this.configGuiHandler.bind(this))

		settingsGui.AddCheckbox("vCBUseCustomDialogPath Checked" this.config.useCustomDialogPath, "whether to always open dialogs in custom directory. Otherwise, uses Last Used File").OnEvent("Click", this.configGuiHandler.bind(this))

		settingsGui.AddText("xs 0x200 R1.45", "Dialog Path:")
		settingsGui.editDialogPath := settingsGui.AddEdit("xp+70 yp r1 w250 -Multi Readonly", this.config.customDialogPath)
		settingsGui.AddButton("vButtonDialogPath yp-1 xp+255", "Browse...").OnEvent("Click", this.configGuiHandler.bind(this))

		settingsGui.AddButton("xs-1", "Reset Settings").OnEvent("Click", resetSettings)
		if (!guiObj.HasOwnProp("children"))
			guiObj.children := []
		guiObj.children.push(settingsGui)
		settingsGui.parent := guiObj
		guiObj.GetPos(&gx, &gy)
		this.toggleGuiDarkMode(settingsGui, this.config.darkMode)
		settingsGui.Show(Format("x{1}y{2} Autosize", gx + 100, gy + 60))
		return

		resetSettings(guiCtrl, *) {
			if (MsgBox("Are you sure? This will reset all settings to their default values.", "Reset Settings", "0x1 Owner" settingsGUI.Hwnd) == "Cancel")
				return
			this.config := TableFilter.defaultConfig
			parent := guiCtrl.Gui.Parent
			settingsGUIClose(guiCtrl.Gui)
			this.createSettingsGui(parent)
			for i, g in this.guis {
				this.toggleGuiDarkMode(g, this.config.darkMode)
				g.CBDuplicates.Value := 0
				this.clearSearchBoxes(g)
				this.createFilteredList(g)
			}
			this.configManager("Save")
		}

		settingsGUIClose(guiObj) {
			for i, g in this.guis
				g.Opt("-Disabled")
			parentHwnd := guiObj.parent.Hwnd
			objRemoveValue(guiObj.parent.children, guiObj)
			guiObj.Destroy()
			WinActivate(parentHwnd)
		}
	}

	configManager(mode := "Save", reset := false) {
		mode := Substr(mode, 1, 1)
		if (!Instr(FileExist(this.data.savePath), "D"))
			DirCreate(this.data.savePath)
		if (mode == "S") {
			f := FileOpen(this.data.savePath . "\config.json", "w", "UTF-8")
			f.Write(jsongo.Stringify(this.config, , "`t"))
			f.Close()
			return 1
		}
		else if (mode == "L") {
			this.config := {}, config := Map()
			if (FileExist(this.data.savePath "\config.json") && !reset) {
				try config := jsongo.Parse(FileRead(this.data.savePath "\config.json", "UTF-8"))
			}
			; remove unused config values
			for i, e in config
				if (TableFilter.defaultConfig.HasOwnProp(i))
					this.config.%i% := e
			; populate unset config values with defaults
			for i, e in TableFilter.defaultConfig.OwnProps()
				if !(this.config.HasOwnProp(i))
					this.config.%i% := e
			return 1
		}
		return 0
	}

	;// GUI functions

	exit(exitReason, exitCode, *) {
		if (exitReason == "Logoff" || exitReason == "Shutdown") {
			if (!this.data.isSaved) {
				if (this.config.autoSaving)
					this.saveFile(this.data.openFile, false)
				else {
					res := MsgBox("You have unsaved Changes in " this.data.openFile "`nSave Changes and shutdown?", this.base.__Class, "0x3 Owner" A_ScriptHwnd)
					if (res == "Cancel")
						return 1
					else if (res == "No")
						return 0
					else if (res == "Yes") {
						this.saveFile(this.data.openFile, false)
					}
				}
			}
		}
	}

	static defaultConfig => {
		debug: false, ; whether to enable various debugging options
		useConfig: true, ; whether to load the config. do not edit this
		darkMode: true, ; enable dark mode
		darkThemeColor: "0x1E1E1E", ; dark mode color
		autoSaving: false, ; whether to automatically save without dialog when closing/exiting
		useBackups: true, ; whether to automatically backup the open file, in conjunction with next two
		backupAmount: 4, ; amount of files to be kept
		backupInterval: 15, ; in minutes
		useDefaultValues: true, ; whether to insert values for empty fields
		autoTranslateRunic: true, ; whether to autotranslate kayoogis->runic
		formatValues: true, ; whether to format values (eg Uppercase word Type abbreviations)
		duplicateColumn: "", ; Deutsch
		copyColumn: "", ; Runen
		taggingColumn: "", ; Kategorie
		filterCaseSense: "Locale", ; for searching/filtering, 1/0/Locale
		saveHotkey: "^s", ; hotkey to save (only inside gui)
		guiHotkey: "^p", ; hotkey to open GUI (always)
		useCustomDialogPath: false, ; whether to always open dialogs in custom directory. Otherwise, uses Last Used File
		customDialogPath: "", ; path in which load/save dialogs should be opened if above option is checked
		lastUsedFile: "" ; path
	}

	static sharepointEscapeCodes => Map(
		"~", "_x007e_",
		"!", "_x0021_",
		"@", "_x0040_",
		"#", "_x0023_",
		"$", "_x0024_",
		"%", "_x0025_",
		"^", "_x005e_",
		"&", "_x0026_",
		"*", "_x002a_",
		"(", "_x0028_",
		")", "_x0029_",
		"+", "_x002b_",
		"-", "_x002d_",
		"=", "_x003d_",
		"{", "_x007b_",
		"}", "_x007d_",
		":", "_x003a_",
		"`"", "_x0022_",
		"|", "_x007c_",
		";", "_x003b_",
		"'", "_x0027_",
		"\", "_x005c_",
		"<", "_x003c_",
		">", "_x003e_",
		"?", "_x003f_",
		",", "_x002c_",
		".", "_x002e_",
		"/", "_x002f_",
		"``", "_x0060_",
		" ", "_x0020_"
	)

	static wordCategories => [
		"👨‍👩‍👧 Familie",
		"🖌️ Farbe",
		"⛰️ Geographie",
		"💎 Geologie",
		"🌟 Gestirne",
		"💥 Magie",
		"🍗 Nahrung",
		"👕 Kleidung",
		"🖐️ Körper",
		"🏘️ Orte",
		"🌲 Pflanzen",
		"🐕 Tiere",
		"🌧️ Wetter",
		"🔢 Zahl"
	]

	static entryPlaceholderValues => Map(
		"Wortart", "?",
		"Deutsch", "-",
		"Kayoogis", "-",
		"Runen", "-", ; this is technically a placeholder placeholder value
		"Tema'i", 0
	)

	static savePath => A_AppData "\Autohotkey\Tablefilter"
}