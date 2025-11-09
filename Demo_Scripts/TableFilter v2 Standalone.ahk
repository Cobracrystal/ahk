/*
todo
- on gui without loaded files, have menubar showing last used files
- settings window
	- delete / restore backups
- autohdr should have max. also always use max width of lv
- instead of only loading, allow for creation of new empty table (-> specify columns and that's it. it should also remove defaultvalues and translate etc)
- add option to duplicate row, inserting it directly after
	- alternatively, add empty row directly after
anti-todo-list
fix window title bar not changing instantly when toggling darkmode. just click tab to another window and back to change.
fix listview headers not being dark. requires custom font drawing so that the text in them is still readable.
fix dark mode for DDL/Dropdownlist via custom intercept function
*/
#Requires AutoHotkey >=v2.0 
#SingleInstance Force
; https://github.com/cobracrystal/ahk

tableInstance := TableFilter()

; ONLY start if this script is not used as a library
if (A_ScriptFullPath == A_LineFile) {
	tableInstance.loadData()
}


class TableFilter {

	__New(debug?, useConfig?) {
		this.data := {
			appdataPath: TableFilter.appdataPath,
			openFile: "",
			data: [],
			keys: [],
			rowName: "",
			defaultValues: TableFilter.entryPlaceholderValues,
			; darkModeCallbackWindowProc: CallbackCreate(this.darkThemeWindowProcRedraw.bind(this)),
			isSaved: true
		}
		this.guis := []
			
		if (IsSet(useConfig) && useConfig == 0)
			this.config := TableFilter.defaultConfig
		else
			this.configManager("Load")
		this.config.debug := debug ?? this.config.debug
		this.config.useConfig := useConfig ?? this.config.useConfig ; if a config uses this, it will only load once and not save.

		if (A_ScriptFullPath == A_LineFile) {
			TrayMenu.TrayMenu.Insert("1&", "TableFilter", (*) => this.guiCreate())
			TrayMenu.TrayMenu.Default := "TableFilter"
		}
		else {
			(gMenu := TrayMenu.submenus["GUIs"]).Add("Open TableFilter (" this.config.guiHotkey ")", (*) => this.guiCreate())
			A_TrayMenu.Add("GUIs", gMenu)
		}
		HotIfWinactive("ahk_group TableFilterGUIs")
		Hotkey(this.config.saveHotkey, (*) => this.saveFile(this.data.openFile, false))
		HotIfWinactive()
		Hotkey(this.config.guiHotkey, this.guiCreate.bind(this))
		OnExit(this.exit.bind(this), 1)
	}

	guiCreate(*) {
		static LVN_KEYDOWN := -155
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
			guiObj.LV.OnNotify(LVN_KEYDOWN, this.LV_Event.bind(this, "Key"))
			guiObj.LV.OnEvent("ContextMenu", this.LV_Event.bind(this, "ContextMenu"))
			guiObj.LV.OnEvent("DoubleClick", this.LV_Event.bind(this, "DoubleClick"))
			this.createFilteredList(guiObj)
			; Wortart, Deutsch, Kayoogis, Runen, Anmerkung, Kategorie, Tema'i, dataIndex (possibly). At least dataindex always last.
			guiObj.LV.ModifyCol(this.data.keys.Length + 1, this.config.debug ? "100 Integer" : "0 Integer")
			Loop (this.data.keys.Length)
				guiObj.LV.ModifyCol(A_Index, "AutoHdr")
			guiObj.topRightControls := []
			guiObj.addRowControls := []
			guiObj.fileControls := []
			guiObj.addRowControls.Push(guiObj.AddGroupBox("Section w" 10 + 95 * this.data.keys.Length + 75 " h65", "Add Row"))
			for i, e in this.data.keys {
				guiObj.addRowControls.Push(guiObj.AddText("ys+15 xs+" 10 + ((i - 1) * 95), e))
				if (e == this.config.taggingColumn)
					ed := guiObj.AddDropDownList("w85 vDropdownTaggingColumn", TableFilter.wordCategories)
				else
					(ed := guiObj.AddEdit("r1 w85 vEditAddRow" i, "")).OnEvent("Change", this.validValueChecker.bind(this))
				guiObj.addRowControls.Push(ed)
			}
			(btn := guiObj.AddButton("ys+15 xs+" 10 + 95 * this.data.keys.Length " h40 w65", "Add Row to List")).OnEvent("Click", this.addEntry.bind(this))
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
		this.applyColorScheme(guiObj)
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
		try {
			filterKey := this.data.keys[this.config.duplicateColumn > this.data.keys.Length ? 1 : this.config.duplicateColumn]
			default := (this.data.defaultValues.Has(filterKey) ? this.data.defaultValues[filterKey] : "")
			duplicateMap := Map()
			duplicateMap.CaseSense := this.config.filterCaseSense ? 1 : "Locale"
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
		} catch Error as e {
			MsgBox("An unexpected Error has occured.`nSpecifically: " e.Message "`nTry Resetting your settings")
		}
		guiObj.LV.Opt("+Redraw")
		guiObj.Opt("-Disabled")
	}

	rowIncludeFromSearch(guiObj, row) {
		for i, e in this.data.keys {
			v := guiObj["EditSearchCol" . i].Value
			if (v != "" && (!row.Has(e) || !InStr(row[e], v, this.config.filterCaseSense ? 1 : "Locale"))) {
				return false
			}
		}
		return true
	}

	/**
	 * Adds given row object with specified dataIndex to specified GUI.
	 */
	addRow(guiObj, row, dataIndex, LVIndex?) {
		rowArr := []
		for _, key in this.data.keys
			rowArr.push(row.Has(key) ? row[key] : "")
		rowArr.push(dataIndex)
		if (IsSet(LVIndex))
			guiObj.LV.Insert(LVIndex, "", rowArr*)
		else
			guiObj.LV.Add("", rowArr*)
	}

	addEntry(ctrlObj, *) {
		newRow := Map()
		aGui := ctrlObj.Gui
		for i, key in this.data.keys {
			if (key == this.config.taggingColumn) {
				newRow[key] := aGui["DropdownTaggingColumn"].Text
				aGui["DropdownTaggingColumn"].Text := ""
			}
			else {
				newRow[key] := aGui["EditAddRow" i].Value
				aGui["EditAddRow" i].Value := ""
			}
		}
		this.cleanRowData(newRow)
		this.data.data.push(newRow)
		this.dataHandler("isSaved", false)
		for _, g in this.guis
			if (this.rowIncludeFromSearch(g, newRow))
				this.addRow(g, newRow, this.data.data.Length)
		aGui.LV.Modify(aGui.LV.GetCount(), "Select Focus Vis")
	}

	editRow(dataIndex, newRow) {
		oldRow := this.data.data[dataIndex]
		this.data.data[dataIndex] := newRow
		for _, g in this.guis {
			g.Opt("+Disabled")
			flagNewRowVisible := this.rowIncludeFromSearch(g, newRow)
			if (this.rowIncludeFromSearch(g, oldRow)) {
				Loop (g.LV.GetCount()) { ; this looks inefficient but it really isn't.
					n := g.LV.GetText(A_Index, this.data.keys.Length + 1)
					if (n == dataIndex) {
						if (flagNewRowVisible || this.config.remainIncludedOnModify) {
							rowAsArray := []
							for i, e in this.data.keys
								rowAsArray.Push(newRow.Has(e) ? newRow[e] : "")
							rowAsArray.Push(dataIndex)
							g.LV.Modify(A_Index, , rowAsArray*)
						} else
							g.LV.Delete(A_Index)
						break
					}
				}
			}
			else if (flagNewRowVisible) {
				this.addRow(g, newRow, dataIndex)
			}
			g.Opt("-Disabled")
		}
		this.dataHandler("isSaved", false)
	}

	editRowGui(editorGuiObj) {
		rowN := editorGuiObj.LV.GetNext(0, "F") ;// next row
		if !(rowN)
			return
		editorGuiObj.Opt("+Disabled")
		dataIndex := editorGuiObj.LV.GetText(rowN, this.data.keys.Length + 1)
		row := this.data.data[dataIndex]
		editorGui := Gui("-Border -SysMenu +Owner" editorGuiObj.Hwnd)
		editorGui.dataIndex := dataIndex
		if (!editorGuiObj.HasOwnProp("children"))
			editorGuiObj.children := []
		editorGuiObj.children.push(editorGui)
		editorGui.OnEvent("Escape", editRowGuiEscape)
		editorGui.OnEvent("Close", editRowGuiEscape)
		editorGui.SetFont("c0x000000") ; this is necessary to force font of checkboxes / groupboxes
		editorGui.AddGroupBox("Section w" 10 + 95 * this.data.keys.Length + 75 " h65", "Edit Row")
		for i, e in this.data.keys {
			editorGui.AddText("ys+15 xs+" 10 + ((i - 1) * 95), e)
			editorGui.AddEdit("r1 w85 vEditAddRow" i, row.Has(e) ? row[e] : "").OnEvent("Change", this.validValueChecker.bind(this))
		}
		editorGui.AddButton("Default ys+15 xs+" 10 + 95 * this.data.keys.Length " h40 w65", "Save Row").OnEvent("Click", editRowGuiFinish.bind(this))
		editorGui.parent := editorGuiObj
		editorGuiObj.GetPos(&gx, &gy, &gw, &gh)
		this.applyColorScheme(editorGui)
		editorGui.Show(Format("x{1}y{2} Autosize", gx + (gw - 111 - 95 * this.data.keys.Length) // 2, gy + (gh - 83) // 2))
		return

		editRowGuiFinish(this, guiCtrl, *) {
			newRow := Map()
			editorGuiObj := guiCtrl.gui
			for i, key in this.data.keys
				newRow[key] := editorGuiObj["EditAddRow" i].Value
			this.cleanRowData(newRow)
			this.editRow(editorGuiObj.dataIndex, newRow)
			for i, g in this.guis
				g.Opt("-Disabled")
			parentHwnd := editorGuiObj.parent.Hwnd
			objRemoveValue(editorGuiObj.parent.children, editorGuiObj)
			editorGuiObj.Destroy()
			WinActivate(parentHwnd)
		}

		editRowGuiEscape(guiObj) {
			guiObj.parent.Opt("-Disabled")
			guiObj.Destroy()
		}
	}

	removeSelectedRows(guiObj) {
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
		; reverse numerical sorting
		sortedRows := arrayBasicSort(rows, "R N")
		for _, g in this.guis {
			g.Opt("+Disabled")
			rowsInLV := [], indexToRemove := []
			; find all rows that show up in LV of g
			for j, n in sortedRows
				if (this.rowIncludeFromSearch(g, this.data.data[n]))
					rowsInLV.push(n)
			; loop over all rows in LV
			Loop (g.LV.GetCount()) {
				rowN := A_Index
				dataIndex := g.LV.GetText(rowN, this.data.keys.Length + 1)
				for j, n in rowsInLV {
					; if current row in LV is to be deleted, mark it and remove it from rows to be checked. this ensures LV-order
					if (dataIndex == n) {
						indexToRemove.push(rowN)
						rowsInLV.RemoveAt(j)
						continue 2 ; continue outer to skip rest. its not harmful though, just break works fine (but is slower)
					}
				}
				; if row is not to be removed, ensure that its dataindex is updated.
				offset := 0
				for j, matchIndex in sortedRows {
					if (dataIndex > matchIndex) {
						offset := sortedRows.Length - j + 1 ; eg sortedRows is 16 7 4 3 2 1, dataIndex is 5: offset should be 4, because 5 > (4,3,2,1). Thus offset = Length of sortedrows - (amount of indices in sortedrows larger than 5)
						break
					}
				}
				if (offset)
					g.LV.Modify(rowN, "Col" . this.data.keys.Length + 1, dataIndex - offset)
			}
			; we don't really need to queue them if we do -Redraw at the start, but this works fine.
			g.LV.Opt("-Redraw")
			for k, rowN in indexToRemove
				g.LV.Delete(indexToRemove[indexToRemove.Length - k + 1]) ; backwards to avoid fucking up the list
			g.LV.Opt("+Redraw")
			g.Opt("-Disabled")
		}
		for i, dataIndex in sortedRows
			this.data.data.RemoveAt(dataIndex)
		this.dataHandler("isSaved", false)
	}

	cloneSelectedRow(guiObj) {
		rows := []
		guiObj.Opt("+Disabled")
		rowN := guiObj.LV.GetNext(0, "F")
		dataIndex := guiObj.LV.GetText(rowN, this.data.keys.Length + 1)
		clonedRow := this.data.data[dataIndex].Clone()
		for _, g in this.guis {
			g.Opt("+Disabled")
			g.LV.Opt("-Redraw")
			posOfRow := 0
			Loop (g.LV.GetCount()) { ; update dataindex
				n := g.LV.GetText(A_Index, this.data.keys.Length + 1)
				if (dataIndex == n)
					posOfRow := A_Index
				else if (n > dataIndex)
					g.LV.Modify(A_Index, "Col" . this.data.keys.Length + 1, n + 1)
			}
			if (posOfRow && this.rowIncludeFromSearch(g, clonedRow))
				this.addRow(g, clonedRow, dataIndex + 1, posOfRow + 1)
			g.LV.Opt("+Redraw")
			g.Opt("-Disabled")
		}
		this.data.data.InsertAt(dataIndex + 1, clonedRow)
		this.dataHandler("isSaved", false)
	}

	cleanRowData(row) { ; row is a map and thus operates onto the object
		for i, e in this.data.keys {
			if (this.config.useDefaultValues && (row[e] == "") && this.data.defaultValues.Has(e))
				row[e] := this.data.defaultValues[e]
			if (e == "Runen" && (row[e] == "") && this.config.autoTranslateRunic && IsSet(TextEditMenu) && IsObject(TextEditMenu))
				row[e] := TextEditMenu.runify(row["Kayoogis"], "DE")
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
		color := this.config.colorTheme ? this.config.colorTheme == 2 ? this.config.customThemeColor : TableFilter.darkModeColor : 0xFFFFFF
		newFont := (isDark(color) ? "c0xFFFFFF" : "c0x000000") . " Norm"
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

	applyColorScheme(guiObj) {
		color := this.config.colorTheme ? this.config.colorTheme == 2 ? this.config.customThemeColor : TableFilter.darkModeColor : "0xFFFFFF"
		dark := isDark(color)
		fontColor := dark ? "0xFFFFFF" : "0x000000"
		this.toggleGuiColorScheme(guiObj, dark, color, fontColor)
		if (guiObj.HasOwnProp("children"))
			for i, g in guiObj.children
				if (g is Gui)
					this.applyColorScheme(g)
		if (guiObj.HasOwnProp("editCustomThemeColor")) {
			ctrl := guiObj.editCustomThemeColor
			ctrl.Opt("+Background" this.config.customThemeColor)
			ctrl.SetFont(isDark(this.config.customThemeColor) ? "c0xFFFFFF" : "c0x000000")
		}
	}

	toggleGuiColorScheme(guiObj, dark, color, fontColor) {
		;// title bar dark
		if (VerCompare(A_OSVersion, "10.0.17763")) {
			attr := 19
			if (VerCompare(A_OSVersion, "10.0.18985"))
				attr := 20
			DllCall("dwmapi\DwmSetWindowAttribute", "ptr", guiObj.hwnd, "int", attr, "int*", (dark ? true : false), "int", 4)
		}
		guiObj.BackColor := color
		font := "c" . fontColor
		guiObj.SetFont(font)
		for cHandle, ctrl in guiObj {
			if (ctrl is Gui.Hotkey)
				continue
			ctrl.Opt("+Background" color)
			ctrl.SetFont(font)
			if (ctrl is Gui.Button)
				DllCall("uxtheme\SetWindowTheme", "ptr", ctrl.hwnd, "str", (dark ? "DarkMode_Explorer" : ""), "ptr", 0)
			if (ctrl is Gui.DDL)
				DllCall("uxtheme\SetWindowTheme", "Ptr", ctrl.hWnd, "Str", (dark ? "DarkMode_CFD" : "CFD"), "Ptr", 0)
			if (ctrl is Gui.ListView) {
				listviewDarkmode(ctrl, dark, color, fontColor)
				; and https://www.autohotkey.com/board/topic/76897-ahk-u64-issue-colored-text-in-listview-headers/
				; maybe https://www.autohotkey.com/boards/viewtopic.php?t=87318
				; full customization control: https://www.autohotkey.com/boards/viewtopic.php?t=115952
			}
			if (ctrl.Name && SubStr(ctrl.Name, 1, 10) == "EditAddRow")
				this.validValueChecker(ctrl)
			ctrl.Redraw()
		}
		return

		listviewDarkmode(lv, dark, color, fontColor) {
			static LVM_GETHEADER := 0x101F
			static LVS_EX_DOUBLEBUFFER := 0x10000
			static WM_NOTIFY := 0x4E
			static WM_THEMECHANGED := 0x031A
			; prevent other changes to UI on darkmode
			;	OnMessage(WM_THEMECHANGED, themechangeIntercept.bind(lv.hwnd))
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

	; darkThemeWindowProcRedraw(hwnd, uMsg, wParam, lParam) {
	; 	Critical()
	; 	static WM_CTLCOLOREDIT    := 0x0133
	; 	static WM_CTLCOLORLISTBOX := 0x0134
	; 	static WM_CTLCOLORBTN     := 0x0135
	; 	static WM_CTLCOLORSTATIC  := 0x0138
	; 	static DC_BRUSH           := 18

	; 	color := this.config.colorTheme ? this.config.colorTheme == 2 ? this.config.customThemeColor : TableFilter.darkModeColor : "0xFFFFFF"
	; 	dark := isDark(color)
		
	; 	if (dark) {
	; 		switch uMsg{
	; 			case WM_CTLCOLOREDIT, WM_CTLCOLORLISTBOX:
	; 			{
	; 				DllCall("gdi32\SetTextColor", "Ptr", wParam, "UInt", DarkColors["Font"])
	; 				DllCall("gdi32\SetBkColor", "Ptr", wParam, "UInt", DarkColors["Controls"])
	; 				DllCall("gdi32\SetDCBrushColor", "Ptr", wParam, "UInt", DarkColors["Controls"], "UInt")
	; 				return DllCall("gdi32\GetStockObject", "Int", DC_BRUSH, "Ptr")
	; 			}
	; 			case WM_CTLCOLORBTN:
	; 			{
	; 				DllCall("gdi32\SetDCBrushColor", "Ptr", wParam, "UInt", DarkColors["Background"], "UInt")
	; 				return DllCall("gdi32\GetStockObject", "Int", DC_BRUSH, "Ptr")
	; 			}
	; 			case WM_CTLCOLORSTATIC:
	; 			{
	; 				DllCall("gdi32\SetTextColor", "Ptr", wParam, "UInt", DarkColors["Font"])
	; 				DllCall("gdi32\SetBkColor", "Ptr", wParam, "UInt", DarkColors["Background"])
	; 				return TextBackgroundBrush
	; 			}
	; 		}
	; 	}
	; 	return DllCall("user32\CallWindowProc", "Ptr", this.data.darkModeCallbackWindowProc, "Ptr", hwnd, "UInt", uMsg, "Ptr", wParam, "Ptr", lParam)
	; }

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
						if !(GetKeyState("Ctrl"))
							return
						if ((rowN := guiObj.LV.GetNext()) == 0)
							return
						if (GetKeyState("Shift"))
							A_Clipboard := jsongo.Stringify(this.data.data[guiObj.LV.GetText(rowN, this.data.keys.Length + 1)], , A_Tab)
						else {
							col := this.config.copyColumn > this.data.keys.Length ? 1 : this.config.copyColumn
							A_Clipboard := guiObj.LV.GetText(rowN, col)
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

	buildContextMenu() {
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
		if (objContainsValue(this.data.keys, this.config.taggingColumn)) {
			tMenu.Add("➕ Add Category to Selected Row(s)", aMenu)
			tMenu.Add("➖ Remove Category from Selected Row(s)", rMenu)
		}
		tMenu.Add("📃 Clone Selected Row", this.cMenuHandler.bind(this))
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
			case "📃 Clone Selected Row":
				this.cloneSelectedRow(g)
			case "Show Data Entry":
				n := g.LV.GetText(rowN, this.data.keys.Length + 1)
				this.debugShowDatabaseEntry(g, n, rowN)
			case "Show Config":
				MsgBoxAsGui(jsongo.Stringify(this.config, , A_Tab),"TableFilter Config",,,,, g.Hwnd, 1)
			case "Show Internal Data":
				smallData := {}
				for i, e in this.data.OwnProps()
					smallData.%i% := (i == "data" ? "NOT SHOWN" : e)
				MsgBoxAsGui(jsongo.Stringify(smallData, , A_Tab),,,,,, g.Hwnd, 1)
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
		for i, index in rows {
			row := this.data.data[index].Clone()
			curCategories := row.Has(this.config.taggingColumn) ? row[this.config.taggingColumn] : ""
			if (tagState)
				curCategories .= "," tag
			else {
				; why not just set as empty string? might contain other stuff (or unknown categories)
				if (tag == "All")
					curCategories := ""
				else
					curCategories := StrReplace(curCategories, tag)
			}
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
		try {
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
	}

	guiClose(guiObj) {
		if (!this.data.isSaved) {
			guiObj.Opt("+Disabled")
			if (this.config.autoSaving)
				this.saveFile(this.data.openFile, false)
			else {
				res := MsgBox("Do you want to save the Changes in " this.data.openFile " before closing?", this.base.__Class, "0x3 Owner" A_ScriptHwnd)
				if (res == "Cancel") {
					guiObj.Opt("-Disabled")
					return 1
				}
				if (res == "No") {
					guiObj.Opt("-Disabled")
					return 0
				}
				if (res == "Yes")
					this.saveFile(this.data.openFile, false)
			}
			guiObj.Opt("-Disabled")
		}
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
				res := MsgBox("Do you want to save the Changes in " this.data.openFile " before loading " (filePath ? filePath : "a new File") "?", this.base.__Class, "0x3 Owner" A_ScriptHwnd)
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
		this.menu := this.buildContextMenu()
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
				table := jsongo.Parse(fileAsStr)
				keys := table["keys"]
				data := table["data"]
				; this is just correction
				for i, e in data
					for j, f in e
						if !(objContainsValue(keys, j))
							keys.push(j)
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
						t[nameUnescape(j)] := unescape(f)
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
		if (fExt == "json") {
			tObj := {
				keys: this.data.keys,
				data: this.data.data
			}
			fileAsStr := jsongo.Stringify(tObj)
		}
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
		backupPath := Format("{1}\Backups\Backup_{2}_{3}.{4}",
			this.data.appdataPath,
			fName,
			doInitialBackup ? "Original" : FormatTime(A_Now, "yyyy.MM.dd-HH.mm.ss"),
		fExt
		)
		if (!Instr(FileExist(this.data.appdataPath "\Backups"), "D"))
			DirCreate(this.data.appdataPath "\Backups")
		this.saveFile(backupPath, false)
		this.deleteExcessBackups()
	}

	deleteExcessBackups(filePath := "") {
		if (!filePath)
			filePath := this.data.openFile
		SplitPath(filePath, , , &fExt, &fName)
		backupPath := this.data.appdataPath "\Backups\Backup_" fName "_*." fExt
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
				throw(Error("Bad setting: " . option))
		}
	}

	configGuiHandler(ctrl, *) {
		switch ctrl.Name {
			case "CBDebug":
				this.config.debug := ctrl.Value
				this.menu := this.buildContextMenu()
				for i, g in this.guis
					g.LV.ModifyCol(this.data.keys.Length + 1, this.config.debug ? "100 Integer" : "0 Integer")
			case "CBAutoSaving":
				this.config.autoSaving := ctrl.Value
			case "CBUseBackups":
				SetTimer(this.backupIterator.bind(this), 0)
				if (this.config.useBackups := ctrl.Value) {
					this.backupIterator(1)
					SetTimer(this.backupIterator.bind(this), this.config.backupInterval * 60000)
				}
			case "CBUseDefaultValues":
				this.config.useDefaultValues := ctrl.Value
			case "CBAutoTranslateRunic":
				this.config.autoTranslateRunic := ctrl.Value
			case "CBFormatValues":
				this.config.formatValues := ctrl.Value
			case "CBUseCustomDialogPath":
				this.config.useCustomDialogPath := ctrl.Value
			case "CBFilterCaseSense":
				this.config.filterCaseSense := ctrl.Value
			case "CBRemainIncludedOnModify":
				this.config.remainIncludedOnModify := ctrl.Value
			case "ButtonDialogPath":
				if (this.config.customDialogPath)
					path := this.config.customDialogPath
				else
					SplitPath(this.config.lastUsedFile, , &path)
				newPath := FileSelect("D3", path, "Please select a folder")
				if (newPath != "") {
					this.config.customDialogPath := newPath
					ctrl.gui.editDialogPath.Value := newPath
				}
			case "EditCustomThemeColor":
				color := ctrl.Value
				if (!InStr(color, "0x"))
					color := "0x" . color
				if (!RegExMatch(color, "^0x[[:xdigit:]]{1,6}$"))
					return
				color := Format("0x{1:06X}", color)
				this.config.customThemeColor := color
				ctrl.Opt("+Background" this.config.customThemeColor)
				ctrl.SetFont(isDark(this.config.customThemeColor) ? "c0xFFFFFF" : "c0x000000")
				if (this.config.colorTheme == 2) {
					for i, g in this.guis
						this.applyColorScheme(g)
				}
			case "ButtonCustomThemeColor":
				color := colorDialog(this.config.customThemeColor, ctrl.gui.hwnd, true)
				if (color == -1)
					return
				this.config.customThemeColor := Format("0x{1:06X}", color)
				ctrl.gui.editCustomThemeColor.Text := Format("0x{1:06X}", this.config.customThemeColor)
				if (this.config.colorTheme == 2) {
					for i, g in this.guis
						this.applyColorScheme(g)
				} else {
					ctrl.gui.editCustomThemeColor.Opt("+Background" this.config.customThemeColor)
					ctrl.gui.editCustomThemeColor.SetFont(isDark(this.config.customThemeColor) ? "c0xFFFFFF" : "c0x000000")
				}
			case "HotkeyOpenGui":
				hkey := ctrl.Value
				if (RegExReplace(hkey, "\!|\^|\+") == "" || hkey == this.config.guiHotkey)
					return
				try
					Hotkey(hkey, this.guiCreate.bind(this))
				catch Error {
					MsgBox("Specified Hotkey already in use (or a different error occured. Try a different one)")
					return
				}
				Hotkey(hkey, "Off")
				TrayMenu.submenus["GUIs"].Rename("Open TableFilter (" this.config.guiHotkey ")", "Open TableFilter (" hkey ")")
				this.config.guiHotkey := hkey
			case "DDLColorTheme":
				this.config.colorTheme := ctrl.Value - 1 ; ctrl is 1, 2, 3, we want 0, 1, 2
				for i, g in this.guis
					this.applyColorScheme(g)
			case "DDLCopyColumn":
				this.config.copyColumn := ctrl.Value
			case "DDLDuplicateColumn":
				this.config.duplicateColumn := ctrl.Value
			case "DDLTaggingColumn":
				this.config.taggingColumn := ctrl.Text
				this.menu := this.buildContextMenu()
			default:
				return
				; throw (Error("This setting doesn't exist (yet): " . ctrl.Name))
		}
		if (this.config.useConfig)
			this.configManager("Save")
	}

	createSettingsGui(guiObj, *) {
		static WM_LBUTTONDOWN := 0x0201
		if (guiObj is Gui.Control)
			guiObj := guiObj.gui
		for i, g in this.guis
			g.Opt("+Disabled")
		Hotkey(this.config.guiHotkey, "Off")
		settingsGui := Gui("+Border +OwnDialogs +Owner" guiObj.Hwnd, "Settings")
		settingsGui.OnEvent("Escape", settingsGUIClose)
		settingsGui.OnEvent("Close", settingsGUIClose)
		settingsGui.SetFont("c0x000000") ; this is necessary to force font of checkboxes / groupboxes
		settingsGui.AddText("Center Section", "Settings for YoutubeDL Gui")

		; color theme
		settingsGui.AddText("xs 0x200 R1.45", "GUI Color Theme:")
		settingsGui.AddDropDownList("vDDLColorTheme xs+225 yp r7 w160 Choose" . this.config.colorTheme + 1, ["Light Theme", "Dark Theme", "Custom Theme"]).OnEvent("Change", this.configGuiHandler.bind(this))
		; custom theme color
		settingsGui.AddText("xs 0x200 R1.45", "Custom theme color:")
		settingsGui.editCustomThemeColor := settingsGui.AddEdit("xs+225 yp vEditCustomThemeColor w70 Center", Format("0x{1:06X}", this.config.customThemeColor))
		settingsGui.editCustomThemeColor.OnEvent("Change", this.configGuiHandler.bind(this))
		settingsGui.editCustomThemeColor.OnEvent("LoseFocus", (ctrl, *) => ctrl.Value := this.config.customThemeColor)
		settingsGui.AddButton("xs+300 yp-1 vButtonCustomThemeColor w86", "Pick Color").OnEvent("Click", this.configGuiHandler.bind(this))
		; hotkey to open GUI
		settingsGui.AddText("xs 0x200 R1.45", "Hotkey to open main GUI:")
		settingsGui.AddHotkey("xs+210 yp vHotkeyOpenGui w175", this.config.guiHotkey).OnEvent("Change", this.configGuiHandler.bind(this))
		; autosaving + backups
		settingsGui.AddCheckbox("xs vCBAutoSaving Checked" this.config.autoSaving, "Autosave when exiting").OnEvent("Click", this.configGuiHandler.bind(this))
		settingsGui.AddCheckbox("xs vCBUseBackups Checked" this.config.useBackups, "Backup opened files in %APPDATA%\Autohotkey\Tablefilter\Backups").OnEvent("Click", this.configGuiHandler.bind(this))
		; custom dialog path
		settingsGui.AddCheckbox("xs vCBUseCustomDialogPath Checked" this.config.useCustomDialogPath, "Always open dialogs in directory set below. Uses last used file otherwise.").OnEvent("Click", this.configGuiHandler.bind(this))
		settingsGui.AddText("xs 0x200 R1.45", "Dialog Path:")
		settingsGui.editDialogPath := settingsGui.AddEdit("xs+70 yp r1 w250 -Multi Readonly", this.config.customDialogPath)
		settingsGui.AddButton("vButtonDialogPath yp-1 xs+325 w60", "Browse...").OnEvent("Click", this.configGuiHandler.bind(this))
		; default values, auto runic, autoformat values
		settingsGui.AddCheckbox("xs vCBUseDefaultValues Checked" this.config.useDefaultValues, "Insert placeholder values into empty fields when editing rows").OnEvent("Click", this.configGuiHandler.bind(this))
		settingsGui.AddCheckbox("xs vCBAutoTranslateRunic Checked" this.config.autoTranslateRunic, "Automatically translate Kayoogis into runes").OnEvent("Click", this.configGuiHandler.bind(this))
		settingsGui.AddCheckbox("xs vCBFormatValues Checked" this.config.formatValues, "Format first row to uppercase").OnEvent("Click", this.configGuiHandler.bind(this))
		; case sense in filter, remain included in search when editing even if edited doesn't match search
		settingsGui.AddCheckbox("xs vCBFilterCaseSense Checked" this.config.filterCaseSense, "Case-sensitive search").OnEvent("Click", this.configGuiHandler.bind(this))
		settingsGui.AddCheckbox("xs vCBRemainIncludedOnModify Checked" this.config.remainIncludedOnModify, "Always show newly edited entries in current search").OnEvent("Click", this.configGuiHandler.bind(this))
		; duplicate filter column
		settingsGui.AddText("xs 0x200 R1.45", "Column to search duplicates in:")
		settingsGui.dropdownDuplicateColumn := settingsGui.AddDropDownList("vDDLDuplicateColumn xs+260 yp r7 w125 Choose" . this.config.duplicateColumn, this.data.keys).OnEvent("Change", this.configGuiHandler.bind(this))
		; tagging column
		settingsGui.AddText("xs 0x200 R1.45", "Column to `"tag`" from context menu:")
		settingsGui.AddDropDownList("vDDLTaggingColumn xs+260 yp r7 w125 Choose" . objContainsValue(this.data.keys, this.config.taggingColumn), this.data.keys).OnEvent("Change", this.configGuiHandler.bind(this))
		; copy column
		settingsGui.AddText("xs 0x200 R1.45", "Column to copy when pressing Ctrl+C:")
		settingsGui.AddDropDownList("vDDLCopyColumn xs+260 yp r7 w125 Choose" . this.config.copyColumn, this.data.keys).OnEvent("Change", this.configGuiHandler.bind(this))
		settingsGui.AddText("xs 0x200 R1.45", "(Press Ctrl+Shift+C to copy all contents of the selected row)")
		; debug
		settingsGui.AddCheckbox("xs vCBDebug Checked" this.config.debug, "Debugging mode").OnEvent("Click", this.configGuiHandler.bind(this))
		; reset settings + backup folder
		settingsGui.AddButton("xs", "Reset Settings").OnEvent("Click", resetSettings)
		settingsGui.AddButton("xs+261 yp w125", "Open Backup Folder").OnEvent("Click", (*) => Run('explorer.exe "' this.data.appdataPath "\Backups" '"'))
		if (!guiObj.HasOwnProp("children"))
			guiObj.children := []
		guiObj.children.push(settingsGui)
		settingsGui.parent := guiObj
		guiObj.GetPos(&gx, &gy)
		this.applyColorScheme(settingsGui)
		settingsGui.Show(Format("x{1}y{2} Autosize", gx + 100, gy + 60))
		return

		resetSettings(guiCtrl, *) {
			if (MsgBox("Are you sure? This will reset all settings to their default values.", "Reset Settings", "0x1 Owner" settingsGUI.Hwnd) == "Cancel")
				return
			useConfig := this.config.useConfig
			lastUsedFile := this.config.lastUsedFile
			this.config := TableFilter.defaultConfig
			this.config.useConfig := useConfig
			if (FileExist(lastUsedFile))
				this.config.lastUsedFile := lastUsedFile
			parent := guiCtrl.Gui.Parent
			settingsGUIClose(guiCtrl.Gui)
			this.createSettingsGui(parent)
			for i, g in this.guis {
				this.applyColorScheme(g)
				g.CBDuplicates.Value := 0
				this.clearSearchBoxes(g)
				this.createFilteredList(g)
			}
			if (this.config.useConfig)
				this.configManager("Save")
		}

		settingsGUIClose(guiObj) {
			for i, g in this.guis
				g.Opt("-Disabled")
			Hotkey(this.config.guiHotkey, "On")
			parentHwnd := guiObj.parent.Hwnd
			objRemoveValue(guiObj.parent.children, guiObj)
			guiObj.Destroy()
			WinActivate(parentHwnd)
		}
	}

	configManager(mode := "Save") {
		mode := Substr(mode, 1, 1)
		if (!Instr(FileExist(this.data.appdataPath), "D"))
			DirCreate(this.data.appdataPath)
		configPath := this.data.appdataPath "\config.json"
		if (mode == "S") {
			f := FileOpen(configPath, "w", "UTF-8")
			f.Write(jsongo.Stringify(this.config, , "`t"))
			f.Close()
			return 1
		}
		else if (mode == "L") {
			this.config := {}, config := Map()
			if (FileExist(configPath))
				try config := jsongo.Parse(FileRead(configPath, "UTF-8"))
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

	exit(exitReason, exitCode, *) {
		if (!this.data.isSaved) {
			if (this.config.autoSaving)
				this.saveFile(this.data.openFile, false)
			else {
				res := MsgBox("Do you want to save the Changes in " this.data.openFile " before exiting?", this.base.__Class, "0x3 Owner" A_ScriptHwnd)
				if (res == "Cancel")
					return 1
				if (res == "No")
					return 0
				if (res == "Yes")
					this.saveFile(this.data.openFile, false)
			}
		}
	}

	; ALL OF THESE CAN BE CHANGED THROUGH THE SETTINGS GUI. DO NOT EDIT HERE.
	static defaultConfig => {
		debug: false, ; whether to enable various debugging options
		useConfig: true, ; whether to load the config. do not edit this, it will disable settings from saving
		colorTheme: 1, ; 0 = white, 1 = dark, 2 = custom
		customThemeColor: "0x1E1E1E", ; custom Theme Color, set to dark mode by default
		autoSaving: false, ; whether to automatically save without dialog when closing/exiting
		useBackups: true, ; whether to automatically backup the open file, in conjunction with next two
		backupAmount: 4, ; amount of files to be kept
		backupInterval: 15, ; in minutes
		useDefaultValues: false, ; whether to insert values for empty fields
		autoTranslateRunic: false, ; whether to autotranslate kayoogis->runic
		formatValues: false, ; whether to format values (eg Uppercase word Type abbreviations)
		filterCaseSense: true, ; for searching/filtering, 0 or 1 (where 0 == "Locale", nonlocale is more performant but pointless.)
		duplicateColumn: 2, ; Deutsch
		copyColumn: 4, ; Runen
		taggingColumn: "", ; Kategorie
		remainIncludedOnModify: true, ; Whether edited entries should be removed after editing if their new values are not included in the current search filter.
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

	; simply edit categories here. note that the config to tag columns has to be enabled for this to work.
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

	; note that these only apply to columns with the specified names in the left. to add other columns, add their names here.
	; yes, not using column IDs / numbers is intentional.
	static entryPlaceholderValues => Map(
		"Wortart", "?",
		"Deutsch", "-",
		"Kayoogis", "-",
		"Runen", "-",
		"Tema'i", 0
	)

	static appdataPath => A_AppData "\Autohotkey\Tablefilter"
	static darkModeColor => "0x1E1E1E"
}


/**
 * @author GroggyOtter <groggyotter@gmail.com>
 * @version 1.0
 * @see https://github.com/GroggyOtter/jsongo_AHKv2
 * @license GNU
 * @classdesc Library for conversion of JSON text to AHK object and vice versa
 * 
 * @property {number} escape_slash     - If true, adds the optional escape character to forward slashes
 * @property {number} escape_backslash - If true, backslash is encoded as `\\` otherwise it is encoded as `\u005C`
 * @property {number} inline_arrays    - If true, arrays containing only strings/numbers are kept on 1 line
 * @property {number} extract_objects  - If true, attempts to extract literal objects instead of erroring
 * @property {number} extract_all      - If true, attempts to extract all object types instead of erroring
 * @property {number} silent_error     - If true, error popups are supressed and are instead written to the .error_log property
 * @property {number} error_log        - Stores error messages when an error occurs and the .silent_error property is true
 */


class jsongo {
    #Requires AutoHotkey 2.0.2+
    static version := '1.0'
    
    ; === User Options ===
    /** If true, adds the optional escape character to forward slashes */
    static escape_slash := 1
    /** If true, backslash is encoded as `\\` otherwise it is encoded as `\u005C` */
    ,escape_backslash   := 1    
    /** If true, arrays containing only strings/numbers are kept on 1 line */
    ,inline_arrays      := 0
    /** If true, attempts to extract literal objects instead of erroring */
    ,extract_objects    := 1
    /** If true, attempts to extract all object types instead of erroring */
    ,extract_all        := 1
    /** If true, error popups are supressed and are instead written to the .error_log property */
    ,silent_error       := 0
    /** Stores error messages when an error occurs and the .silent_error property is true */
    ,error_log          := ''
    
    ; === User Methods ===
    /**
     * Converts a string of JSON text into an AHK object
     * @param {[`String`](https://www.autohotkey.com/docs/v2/lib/String.htm)} jtxt JSON string to convert into an AHK [object](https://www.autohotkey.com/docs/v2/lib/Object.htm)  
     * @param {[`Function Object`](https://www.autohotkey.com/docs/v2/misc/Functor.htm)} [reviver=''] [optional] Reference to a reviver function.  
     * A reviver function receives each key:value pair before being added to the object and must have at least 3 parameters.  
     * @returns {([`Map`](https://www.autohotkey.com/docs/v2/lib/Map.htm)|[`Array`](https://www.autohotkey.com/docs/v2/lib/Array.htm)|[`String`](https://www.autohotkey.com/docs/v2/Objects.htm#primitive))} Return type is based on JSON text input.  
     * On failure, an error message is thrown or an empty string is returned if `.silent_error` is true
     * @access public
     * @method
     * @Example 
     * txt := '{"a":1, "b":2}'
     * obj := jsongo.Parse(txt)
     * MsgBox(obj['b']) ; Shows 2
     */
    static Parse(jtxt, reviver:='') => this._Parse(jtxt, reviver)
    
    /**
     * Converts a string of JSON text into an AHK object
     * @param {([`Map`](https://www.autohotkey.com/docs/v2/lib/Map.htm)|[`Array`](https://www.autohotkey.com/docs/v2/lib/Array.htm))} base_item - A map or array to convert into JSON format.  
     * If the `.extract_objects` property is true, literal objects are also accepted.  
     * If the `.extract_all` property or the `extract_all` parameter are true, all object types are accepted.  
     * @param {[`Function Object`](https://www.autohotkey.com/docs/v2/misc/Functor.htm)} [replacer=''] - [optional] Reference to a replacer function.  
     * A replacer function receives each key:value pair before being added to the JSON string.  
     * The function must have at least 3 parameters to receive the key, the value, and the removal variable.  
     * @param {([`String`](https://www.autohotkey.com/docs/v2/Objects.htm#primitive)|[`Number`](https://www.autohotkey.com/docs/v2/Objects.htm#primitive))} [spacer=''] - Defines the character set used to indent each level of the JSON tree.  
     * Number indicates the number of spaces to use for each indent.  
     * String indiciates the characters to use. `` `t `` would be 1 tab for each indent level.  
     * If omitted or an empty string is passed in, the JSON string will export as a single line of text.  
     * @param {[`Number`](https://www.autohotkey.com/docs/v2/Objects.htm#primitive)} [extract_all=0] - If true, `base_item` can be any object type instead of throwing an error.
     * @returns {[`String`](https://www.autohotkey.com/docs/v2/Objects.htm#primitive)} Return JSON string
     * On failure, an error message is thrown or an empty string is returned if `.silent_error` is true
     * @access public
     * @method
     * @Example 
     * obj := Map('a', [1,2,3], 'b', [4,5,6])
     * json := jsongo.Stringify(obj, , 4)
     * MsgBox(json)
     */
    static Stringify(base_item, replacer:='', spacer:='', extract_all:=0) => this._Stringify(base_item, replacer, spacer, extract_all)
    
    /** @access private */
    static _Parse(jtxt, reviver:='') {
        local hex
        this.error_log := '', if_rev := (reviver is Func && reviver.MaxParams > 2) ? 1 : 0, xval := 1, xobj := 2, xarr := 3, xkey := 4, xstr := 5, xend := 6, xcln := 7, xeof := 8, xerr := 9, null := '', str_flag := Chr(5), tmp_q := Chr(6), tmp_bs:= Chr(7), expect := xval, json := [], path := [json], key := '', is_key:= 0, remove := jsongo.JSON_Remove(), fn := A_ThisFunc
        loop 31
            (A_Index > 13 || A_Index < 9 || A_Index = 11 || A_Index = 12) && (i := InStr(jtxt, Chr(A_Index), 1)) ? err(21, i, 'Character number: 9, 10, 13 or anything higher than 31.', A_Index) : 0
        for k, esc in [['\u005C', tmp_bs], ['\\', tmp_bs], ['\"',tmp_q], ['"',str_flag], [tmp_q,'"'], ['\/','/'], ['\b','`b'], ['\f','`f'], ['\n','`n'], ['\r','`r'], ['\t','`t']]
            this.replace_if_exist(&jtxt, esc[1], esc[2])
        i := 0
        while (i := InStr(jtxt, '\u', 1, ++i))
            IsNumber('0x' (hex := SubStr(jtxt, i+2, 4))) ? jtxt := StrReplace(jtxt, '\u' hex, Chr(('0x' hex)), 1) : err(22, i+2, '\u0000 to \uFFFF', '\u' hex)
        (i := InStr(jtxt, '\', 1)) ? err(23, i+1, '\b \f \n \r \t \" \\ \/ \u', '\' SubStr(jtxt, i+1, 1)) : jtxt := StrReplace(jtxt, tmp_bs, '\', 1)
        jlength := StrLen(jtxt) + 1, ji := 1
        
        while (ji < jlength) {
            if InStr(' `t`n`r', (char := SubStr(jtxt, ji, 1)), 1)
                ji++
            else switch expect {
                case xval:
                    v:
                    (char == '{') ? (o := Map(), (path[path.Length] is Array) ? path[path.Length].Push(o) : path[path.Length][key] := o, path.Push(o), expect := xobj, ji++)
                    : (char == '[') ? (a := [], (path[path.Length] is Array) ? path[path.Length].Push(a) : path[path.Length][key] := a, path.Push(a), expect := xarr, ji++)
                    : (char == str_flag) ? (end := InStr(jtxt, str_flag, 1, ji+1)) ? is_key ? (is_key := 0, key := SubStr(jtxt, ji+1, end-ji-1), expect := xcln, ji := end+1) : (rev(SubStr(jtxt, ji+1, end-ji-1)), expect := xend, ji := end+1) : err(24, ji, '"', SubStr(jtxt, ji))
                    : InStr('-0123456789', char, 1) ? RegExMatch(jtxt, '(-?(?:0|[123456789]\d*)(?:\.\d+)?(?:[eE][-+]?\d+)?)', &match, ji) ? (rev(Number(match[])), expect := xend, ji := match.Pos + match.Len ) : err(25, ji, , SubStr(jtxt, ji))
                    : (char == 't') ? (SubStr(jtxt, ji, 4) == 'true')  ? (rev(true) , ji+=4, expect := xend) : err(26, ji + tfn_idx('true', SubStr(jtxt, ji, 4)), 'true' , SubStr(jtxt, ji, 4))
                    : (char == 'f') ? (SubStr(jtxt, ji, 5) == 'false') ? (rev(false), ji+=5, expect := xend) : err(27, ji + tfn_idx('false', SubStr(jtxt, ji, 5)), 'false', SubStr(jtxt, ji, 5))
                    : (char == 'n') ? (SubStr(jtxt, ji, 4) == 'null')  ? (rev(null) , ji+=4, expect := xend) : err(28, ji + tfn_idx('null', SubStr(jtxt, ji, 4)), 'null' , SubStr(jtxt, ji, 4))
                    : err(29, ji, '`n`tArray: [ `n`tObject: { `n`tString: " `n`tNumber: -0123456789 `n`ttrue/false/null: tfn ', char)
                case xarr: if (char == ']')
                        path_pop(&char), expect := (path.Length = 1) ? xeof : xend, ji++
                    else goto('v')
                case xobj: 
                    switch char {
                        case str_flag: goto((is_key := 1) ? 'v' : 'v')
                        case '}': path_pop(&char), expect := (path.Length = 1) ? xeof : xend, ji++
                        default: err(31, ji, '"}', char)
                    }
                case xkey: if (char == str_flag)
                        goto((is_key := 1) ? 'v' : 'v')
                    else err(32, ji, '"', char)
                case xcln: (char == ':') ? (expect := xval, ji++) : err(33, ji, ':', char)
                case xend: (char == ',') ? (ji++, expect := (path[path.Length] is Array) ? xval : xkey)
                    : (char == '}') ? (ji++, (path[path.Length] is Map)   ? path_pop(&char) : err(34, ji, ']', char), (path.Length = 1) ? expect := xeof : 0)
                    : (char == ']') ? (ji++, (path[path.Length] is Array) ? path_pop(&char) : err(35, ji, '}', char), (path.Length = 1) ? expect := xeof : 0)
                    : err(36, ji, '`nEnd of array: ]`nEnd of object: }`nNext value: ,`nWhitespace: [Space] [Tab] [Linefeed] [Carriage Return]', char)
                case xeof: err(40, ji, 'End of JSON', char)
                case xerr: return ''
            }
        }
        
        return (path.Length != 1) ? err(37, ji, 'Size: 1', 'Actual size: ' path.Length) : json[1]
        
        path_pop(&char) => (path.Length > 1) ? path.Pop() : err(38, ji, 'Size > 0', 'Actual size: ' path.Length-1)
        rev(value) => (path[path.Length] is Array) ? (if_rev ? value := reviver((path[path.Length].Length), value, remove) : 0, (value == remove) ? '' : path[path.Length].Push(value) ) : (if_rev ? value := reviver(key, value, remove) : 0, (value == remove) ? '' : path[path.Length][key] := value )
        err(msg_num, idx, ex:='', rcv:='') => (clip := '`n',  offset := 50,  clip := 'Error Location:`n', clip .= (idx > 1) ? SubStr(jtxt, 1, idx-1) : '',  (StrLen(clip) > offset) ? clip := SubStr(clip, (offset * -1)) : 0,  clip .= '>>>' SubStr(jtxt, idx, 1) '<<<',  post_clip := (idx < StrLen(jtxt)) ? SubStr(jtxt, ji+1) : '',  clip .= (StrLen(post_clip) > offset) ? SubStr(post_clip, 1, offset) : post_clip,  clip := StrReplace(clip, str_flag, '"'),  this.error(msg_num, fn, ex, rcv, clip), expect := xerr)
        tfn_idx(a, b) {
            loop StrLen(a)
                if SubStr(a, A_Index, 1) !== SubStr(b, A_Index, 1)
                    Return A_Index-1
        }
    }
    
    /** @access private */
    static _Stringify(base_item, replacer, spacer, extract_all) {
        switch Type(replacer) {
            case 'Func': if_rep := (replacer.MaxParams > 2) ? 1 : 0
            case 'Array':
                if_rep := 2, omit := Map(), omit.Default := 0
                for i, v in replacer
                    omit[v] := 1
            default: if_rep := 0
        }
        
        switch Type(spacer) {
            case 'String': _ind := spacer, lf := (spacer == '') ? '' : '`n'
                if (spacer == '')
                    _ind := lf := '', cln := ':'
                else _ind := spacer, lf := '`n', cln := ': '
            case 'Integer','Float','Number':
                lf := '`n', cln := ': ', _ind := ''
                loop Floor(spacer)
                    _ind .= ' '
            default: _ind := lf := '', cln := ':'
        }
        
        this.error_log := '', extract_all := (extract_all) ?  1 : this.extract_all ? 1 : 0, remove := jsongo.JSON_Remove(), value_types := 'String Number Array Map', value_types .= extract_all ? ' AnyObject' : this.extract_objects ? ' LiteralObject' : '', fn := A_ThisFunc
        
        (if_rep = 1) ? base_item := replacer('', base_item, remove) : 0
        if (base_item = remove)
            return ''
        else jtxt := extract_data(base_item)
        
        loop 33
            switch A_Index {
                case 9,10,13: continue
                case  8: this.replace_if_exist(&jtxt, Chr(A_Index), '\b')
                case 12: this.replace_if_exist(&jtxt, Chr(A_Index), '\f')
                case 32: (this.escape_slash) ? this.replace_if_exist(&jtxt, '/', '\/') : 0
                case 33: (this.escape_backslash) ? this.replace_if_exist(&jtxt, '\u005C', '\\') : 0 
                default: this.replace_if_exist(&jtxt, Chr(A_Index), Format('\u{:04X}', A_Index))
            }
        
        return jtxt
        
        extract_data(item, ind:='') {
            switch Type(item) {
                case 'String': return '"' encode(&item) '"'
                case 'Integer','Float': return item
                case 'Array':
                    str := '['
                    if (ila := this.inline_arrays ?  1 : 0)
                        for i, v in item
                            InStr('String|Float|Integer', Type(v), 1) ? 1 : ila := ''
                        until (!ila)
                    for i, v in item
                        (if_rep = 2 && omit[i]) ? '' : (if_rep = 1 && (v := replacer(i, v, remove)) = remove) ? '' : str .= (ila ? extract_data(v, ind _ind) ', ' : lf ind _ind extract_data(v, ind _ind) ',')
                    return ((str := RTrim(str, ', ')) == '[') ? '[]' : str (ila ? '' : lf ind) ']'
                case 'Map':
                    str := '{'
                    for k, v in item
                        (if_rep = 2 && omit[k]) ? '' : (if_rep = 1 && (v := replacer(k, v, remove)) = remove) ? '' : str .= lf ind _ind (k is String ? '"' encode(&k) '"' cln : err(11, 'String', Type(k))) extract_data(v, ind _ind) ','
                    return ((str := RTrim(str, ',')) == '{') ? '{}' : str lf ind '}'
                case 'Object':
                    (this.extract_objects) ? 1 : err(12, value_types, Type(item))
                    Object:
                    str := '{'
                    for k, v in item.OwnProps()
                        (if_rep = 2 && omit[k]) ? '' : (if_rep = 1 && (v := replacer(k, v, remove)) = remove) ? '' : str .= lf ind _ind (k is String ? '"' encode(&k) '"' cln : err(11, 'String', Type(k))) extract_data(v, ind _ind) ','
                    return ((str := RTrim(str, ',')) == '{') ? '{}' : str lf ind '}'
                case 'VarRef','ComValue','ComObjArray','ComObject','ComValueRef': return err(15, 'These are not of type "Object":`nVarRef ComValue ComObjArray ComObject and ComValueRef', Type(item))
                default:
                    !extract_all ? err(13, value_types, Type(item)) : 0
                    goto('Object')
            }
        }
        
        encode(&str) => (this.replace_if_exist(&str ,  '\', '\u005C'), this.replace_if_exist(&str,  '"', '\"'), this.replace_if_exist(&str, '`t', '\t'), this.replace_if_exist(&str, '`n', '\n'), this.replace_if_exist(&str, '`r', '\r')) ? str : str
        err(msg_num, ex:='', rcv:='') => this.error(msg_num, fn, ex, rcv)
    }

    /** @access private */
    class JSON_Remove {
    }
    /** @access private */
    static replace_if_exist(&txt, find, replace) => (InStr(txt, find, 1) ? txt := StrReplace(txt, find, replace, 1) : 0)
    /** @access private */
    static error(msg_num, fn, ex:='', rcv:='', extra:='') {
        err_map := Map(11,'Stringify error: Object keys must be strings.'  ,12,'Stringify error: Literal objects are not extracted unless:`n-The extract_objects property is set to true`n-The extract_all property is set to true`n-The extract_all parameter is set to true.'  ,13,'Stringify error: Invalid object found.`nTo extract all objects:`n-Set the extract_all property to true`n-Set the extract_all parameter to true.'  ,14,'Stringify error: Invalid value was returned from Replacer() function.`nReplacer functions should always return a string or the "remove" value passed into the 3rd parameter.'  ,15,'Stringify error: Invalid object encountered.'  ,21,'Parse error: Forbidden character found.`nThe first 32 ASCII chars are forbidden in JSON text`nTab, linefeed, and carriage return may appear as whitespace.'  ,22,'Parse error: Invalid hex found in unicode escape.`nUnicode escapes must be in the format \u#### where #### is a hex value between 0000 and FFFF.`nHex values are not case sensitive.'  ,23,'Parse error: Invalid escape character found.'  ,24,'Parse error: Could not find end of string'  ,25,'Parse error: Invalid number found.'  ,26,'Parse error: Invalid `'true`' value.'  ,27,'Parse error: Invalid `'false`' value.'  ,28,'Parse error: Invalid `'null`' value.'  ,29,'Parse error: Invalid value encountered.'  ,31,'Parse error: Invalid object item.'  ,32,'Parse error: Invalid object key.`nObject values must have a string for a key name.'  ,33,'Parse error: Invalid key:value separator.`nAll keys must be separated from their values with a colon.'  ,34,'Parse error: Invalid end of array.'  ,35,'Parse error: Invalid end of object.'  ,36,'Parse error: Invalid end of value.'  ,37,'Parse error: JSON has objects/arrays that have not been terminated.'  ,38,'Parse error: Cannot remove an object/array that does not exist.`nThis error is usually thrown when there are extra closing brackets (array)/curly braces (object) in the JSON string.'  ,39,'Parse error: Invalid whitespace character found in string.`nTabs, linefeeds, and carriage returns must be escaped as \t \n \r (respectively).'  ,40,'Characters appears after JSON has ended.' )
        msg := err_map[msg_num], (ex != '') ? msg .= '`nEXPECTED: ' ex : 0, (rcv != '') ? msg .= '`nRECEIVED: ' rcv : 0
        if !this.silent_error
            throw(Error(msg, fn, extra))
        this.error_log := 'JSON ERROR`n`nTimestamp:`n' A_Now '`n`nMessage:`n' msg '`n`nFunction:`n' fn '()' (extra = '' ? '' : '`n`nExtra:`n') extra '`n'
        return ''
    }
}

/**
 * Given a string HayStack and a string SearchText, returns the amount of times SearchText is found within HayStack
 * @param HayStack 
 * @param SearchText 
 * @param {Integer} CaseSense 
 */
strCountStr(HayStack, SearchText, CaseSense := false) {
	StrReplace(HayStack, SearchText,,CaseSense, &count)
	return count
}

/**
 * Just like InStr, but SearchTexts may be an array of strings which are all searched for.
 * Other Notable difference: Occurence may be 0 to return array of ALL indices that were found
 * @param HayStack 
 * @param SearchTexts 
 * @param CaseSense 
 * @param {Integer} StartPos 
 * @param {Integer} Occurence 
 */
stringssInStr(HayStack, SearchTexts, CaseSense, StartPos := 1, Occurence := 1) {
	throw Error("Not implemented")
}

strReverse(str) {
	result := ""
	for i, e in StrSplitUTF8(str)
		result := e . result
	return result
}

strRotate(str, offset := 0) {
	offset := Mod(offset, StrLen(str))
	return SubStr(str, -1 * offset + 1) . SubStr(str, 1, -1 * offset)
}

strMultiply(str, count) {
	return StrReplace(Format("{:0" count "}",''), '0', str)
}

strFill(str, width, alignRight := true, char := A_Space) {
	s := strMultiply(char, width - StrLen(str))
	if alignRight
		return s . str
	return str . s
}

strDoPerChar(text, fn := (e => e . " ")) {
	result := ""
	for i, e in StrSplitUTF8(text)
		result .= fn(e)
	return RTrim(result)
}

strRemoveConsecutiveDuplicates(str, delim := "`n") {
	pos := 0
	str2 := ""
	loop parse str, delim, "" {
		pos += StrLen(A_LoopField) + 1
		if (lastField == A_LoopField)
			continue
		str2 .= A_LoopField . SubStr(str, pos, 1) 
		lastField := A_LoopField
	}
	return str2
}

replaceCharacters(text, replacer) {
	if !(replacer is Map || replacer is Func)
		return text
	result := ""
	isMap := replacer is Map
	for i, e in StrSplitUTF8(text) {
		if (isMap)
			result .= (replacer.Has(e) ? replacer[e] : e)
		else
			result .= replacer(e)
	}
	return result
}

strChangeEncoding(str, encoding) {
	buf := Buffer(StrPut(str, encoding))
	StrPut(str, buf, encoding)
	return StrGet(buf, "UTF-16")
}

/**
 * Makes a string literal for regex usage
 * @param str 
 * @returns {string} 
 */
RegExEscape(str) => "\Q" StrReplace(str, "\E", "\E\\E\Q") "\E"

/**
 * StrReplace but from and to can be arrays containing multiple values which will be replaced in order, while guaranteeing that they will not replace themselves.
 * @param string String in which to replace the strings
 * @param from Array containing strings that are to be replaced in decreasing priority order
 * @param to Array containing strings that are the replacements for values in @from, in same order
 * @returns {string} 
 * @example StrMultiReplace("abcd", ["a", "b"], ["b", "r"]) => "rrcd" ; since a->b->r 
 * @example StrIndependentMultiReplace("abcd", ["a", "b"], ["b", "r"]) => "brcd" ; Replaced values independent of each other.
 */
StrIndependentMultiReplace(text, from, to) {
	return __recursiveReplaceMap(text, from, to)

	__recursiveReplaceMap(text, from, to, __index := 1) {
		replacedString := ""
		if (__index == from.Length)
			return StrReplace(text, from[__index], to[__index])
		strArr := StrSplit(text, from[__index])
		for i, e in strArr
			replacedString .= __recursiveReplaceMap(e, from, to, __index + 1) . (i == strArr.Length ? "" : to[__index])
		return replacedString
	}
}

StrMultiReplace(text, from, to, caseSense := true, &outputvarCount := 0, limit := -1) {
	Loop(from.Length) {
		text := StrReplace(text, from[A_Index], to[A_Index], caseSense, &repl, limit)
		limit -= repl
		outputvarCount += repl
	}
	return text
}

strSimilarity(s1, s2) => 1 - strDistanceNormalizedLevenshtein(s1, s2)

strDistanceNormalizedLevenshtein(s1, s2) {
	len := Max(StrLen(s1), StrLen(s2))
	if !len
		return 0
	return strDistanceLevenshtein(s1, s2) / len
}

strDistanceLevenshtein(s1, s2, limit := 2**31-1) {
	if (s1 == s2)
		return 0
	len1 := StrLen(s1)
	len2 := StrLen(s2)
	if !(len1)
		return len2
	if !(len2)
		return len1
	v0 := [], v1 := []
	v0.Capacity := v0.Length := v1.Capacity := v1.Length := len2+1
	Loop(len2+1)
		v0[A_Index] := A_Index-1
	Loop(len1) {
		v1[1] := minv1 := i := A_Index
		Loop(len2) {
			cost := SubStr(s1, i, 1) != SubStr(s2, A_Index, 1)
			v1[A_Index + 1] := Min(v1[A_Index] + 1, v0[A_Index+1] + 1, v0[A_Index] + cost) ; min of ins, del, sub
			minv1 := Min(minv1, v1[A_Index+1])
		}
		if (minv1 >= limit)
			return limit
		temp := v0
		v0 := v1
		v1 := temp
	}
	return v0.Pop()
}

strDistanceWeightedLevenshtein(s1, s2, limit := 1e+307, insertionCost := (char) => 1.0, deletionCost := (char) => 1.0, substitutionCost := (char1, char2) => 1.0) {
	if (s1 == s2)
		return 0
	len1 := StrLen(s1)
	len2 := StrLen(s2)
	if !(len1)
		return len2
	if !(len2)
		return len1
	v0 := [], v1 := []
	v0.Capacity := v0.Length := v1.Capacity := v1.Length := len2+1
	v0[1] := 0
	Loop(len2)
		v0[A_Index + 1] := v0[A_Index] + insertionCost(SubStr(s2, A_Index, 1))
	Loop(len1) {
		i := A_Index
		char1 := SubStr(s1, i, 1)
		costDel := deletionCost(char1)
		v1[1] := minv1 := v0[1] + costDel
		Loop(len2) {
			char2 := SubStr(s2, A_Index, 1)
			costSub := char1 != char2 ? substitutionCost(char1, char2) : 0
			costIns := insertionCost(char2)
			v1[A_Index+1] := Min(v1[A_Index] + costIns, v0[A_Index+1] + costDel, v0[A_Index] + costSub)
			minv1 := Min(minv1, v1[A_Index+1])
		}
		if (minv1 >= limit)
			return limit
		temp := v0
		v0 := v1
		v1 := temp
	}
	return v0.Pop()
}

strDistanceSIFT(s1, s2, maxOffset := 5, maxDistance?) {
	if (s1 == s2)
		return 0
	tl1 := StrLen(s1)
	tl2 := StrLen(s2)
	if !(tl1)
		return tl2
	if !(tl2)
		return tl1
	t1 := StrSplit(s1)
	t2 := StrSplit(s2)
	c1 := c2 := 1 ; Cursors
	lcss := 0 ; Largest common subsequence
	lcs := 0 ; Largest common substring
	trans := 0 ; Number of transpositions
	offsets := [] ; Offset pair array

	while (c1 <= tl1 && c2 <= tl2) {
		if t1[c1] == t2[c2] {
			lcs += 1
			while(offsets.Length) {
				if (c1 <= offsets[1][1] || c2 <= offsets[1][2]) {
					trans++
					break
				} else {
					offsets.RemoveAt(1)
				}
			}
			offsets.push([c1, c2])
		} else {
			lcss += lcs
			lcs := 0
			if(c1 !== c2) {
				c1 := c2 := Min(c1, c2)
			}
			Loop(maxOffset) {
				i := A_Index - 1
				if(c1 + i <= tl1 && t1[c1+i] == t2[c2]) {
					c1 += i - 1
					c2 -= 1
					break
				}
				if(c2 + i <= tl2 && t1[c1] == t2[c2+i]) {
					c1 -= 1
					c2 += i - 1
					break
				}
			}
		}
		c1++
		c2++

		if(IsSet(maxDistance)) {
			distance := Max(c1, c2) - 1 - (lcss - trans / 2)
			if(distance >= maxDistance)
				return Round(distance)
		}
	}
	lcss += lcs
	return Round(Max(tl1, tl2) - (lcss - trans/2))
}

/**
 * This is ONLY appropriate where the difference in strings is one mismatched run of addition (and even then pretty bad)
 * @param s1 
 * @param s2 
 * @param {Integer} maxOffset 
 * @returns {Array | Primitive} 
 */
strDifferenceSIFT(s1, s2, maxOffset := 5) {
	if (s1 == s2)
		return []
	tl1 := StrLen(s1)
	tl2 := StrLen(s2)
	t1 := StrSplit(s1)
	t2 := StrSplit(s2)
	c1 := c2 := 1 ; Cursors
	lcs := 0 ; Largest common substring
	lcss := 0 ; Largest common subsequence
	trans := 0 ; Number of transpositions
	offsets := [] ; Offset pair array

	mismatches := []
	mismatchStart := mismatchStart1 := mismatchStart2 := -1
	while (c1 <= tl1 && c2 <= tl2) {
		if t1[c1] == t2[c2] {
			lcs += 1
			if (mismatchStart != -1) {
				m1len := c1 - mismatchStart1
				m2len := c2 - mismatchStart2
				if (m1len >= 0 && m2len >= 0)
					mismatches.push({
						index1: mismatchStart1,
						length1: m1len,
						str1: SubStr(s1, mismatchStart1, m1len),
						index2: mismatchStart2,
						length2: m2len,
						str2: SubStr(s2, mismatchStart2, m2len),
					})
				mismatchStart := mismatchStart1 := mismatchStart2 := -1
			}
			while(offsets.Length) {
				if (c1 <= offsets[1][1] || c2 <= offsets[1][2]) {
					trans++
					break
				} else {
					offsets.RemoveAt(1)
				}
			}
			offsets.push([c1, c2])
		} else {
			if (mismatchStart == -1) {
				mismatchStart := Max(c1, c2)
				mismatchStart1 := c1
				mismatchStart2 := c2
			}
			lcss += lcs
			lcs := 0
			if(c1 !== c2) {
				c1 := c2 := Min(c1, c2)
			}
			Loop(maxOffset) {
				i := A_Index - 1
				if(c1 + i <= tl1 && t1[c1+i] == t2[c2]) {
					c1 += i - 1
					c2 -= 1
					break
				}
				if(c2 + i <= tl2 && t1[c1] == t2[c2+i]) {
					c1 -= 1
					c2 += i - 1
					break
				}
			}
		}
		c1++
		c2++

		if(IsSet(maxDistance)) {
			distance := Max(c1, c2) - 1 - (lcss - trans /2)
			if(distance >= maxDistance) 
				return Round(distance)
		}
	}
	if (mismatchStart >= 0) {
		m1len := c1 - mismatchStart1
		m2len := c2 - mismatchStart2
		mismatches.push({
			index1: mismatchStart1,
			length1: m1len,
			str1: SubStr(s1, mismatchStart1, m1len),
			index2: mismatchStart2,
			length2: m2len,
			str2: SubStr(s2, mismatchStart2, m2len),
		})
	}
	if (c1 < tl1 || c2 < tl2) {
		mismatches.push({
			index1: c1,
			length1: Max(tl1 - c1 + 1),
			str1: SubStr(s1, c1),
			index2: c2,
			length2: Max(0, tl2 - c2 + 1),
			str2: SubStr(s2, c2),
		})
	}
	return mismatches
}

strLimitToDiffs(str1, str2, maxOffset := 5, radius := 10, fillChar := "#", separator := " ... ") {
	s1 := s2 := ""
	diffs := strDifferenceSIFT(str1, str2, maxOffset)
	for i, diff in diffs {
		c1 := strGetContext(str1, diff.index1, diff.index1 + diff.length1, radius, &rs1, &re1)
		c2 := strGetContext(str2, diff.index2, diff.index2 + diff.length2, radius, &rs2, &re2)
		if (i == 1) {
			s1 := (rs1 ? "" : LTrim(separator, " `t`r`n"))
			s2 := (rs2 ? "" : LTrim(separator, " `t`r`n"))
		}
		if (diff.length1 > diff.length2) {
			s1 .= c1[1] strfill(diff.str1, diff.length1,, fillChar) c1[2] separator
			s2 .= c2[1] strfill(diff.str2, diff.length1,, fillChar) c2[2] separator
		} else {
			s1 .= c1[1] strfill(diff.str1, diff.length2,, fillChar) c1[2] separator
			s2 .= c2[1] strfill(diff.str2, diff.length2,, fillChar) c2[2] separator
		}
	}
	s1 := re1 ? SubStr(s1, 1, -1 * StrLen(separator)) : RTrim(s1, " `t`r`n")
	s2 := re2 ? SubStr(s2, 1, -1 * StrLen(separator)) : RTrim(s2, " `t`r`n")
	return [s1, s2]
}

strGetContext(str, startIndex, endIndex := startIndex, radius := 15, &reachedStart?, &reachedEnd?) {
	befLen := Min(radius, startIndex - 1)
	befStart := Max(1, startIndex - radius)
	afterLen := Min(radius, StrLen(str) - endIndex + 1)
	afterStart := endIndex
	reachedStart := (befStart == 1)
	reachedEnd := (afterLen != radius)
	return [SubStr(str, befStart, befLen), SubStr(str, afterStart, afterLen)]
}

/**
 * Behaves exactly as strsplit except that if it is called without a delim and thus parses char by char, doesn't split unicode characters in two.
 * @param str 
 * @param {String} delim 
 * @param {String} omit If omit and withDelim are both nonzero values, it will lead to unexpected behaviour.
 * @param {Integer} withDelim 
 * @returns {Array} 
 */
StrSplitUTF8(str, delim := "", omit := "", withDelim := false) {
	arr := []
	skip := false
	count := 0
	Loop Parse, str, delim, omit {
		char := A_LoopField
		if (skip) {
			skip := false
			continue
		}
		if (StrLen(A_LoopField) == 1 && Ord(A_LoopField) > 0xD7FF && Ord(A_LoopField) < 0xDC00) {
			arr.push(A_Loopfield . SubStr(str, count + 1, 1) . (withDelim ? SubStr(str, count+2, 1): ''))
			skip := true
			count += 2
			continue
		}
		count += StrLen(A_LoopField) + 1
		arr.push(A_LoopField . (withDelim ? SubStr(str, count, 1) : ''))
	}
	return arr
}

StrLenUTF8(str) {
	RegExReplace(str, "s).", "", &i) ; yes this is actually the fastest way to do so.
	return i
}

strMaxCharsPerLine(str, maxCharsPerLine) {
	nStr := ""
	loops := strCountStr(str, '`n') + 1
	Loop Parse str, "`n", "`r" {
		line := A_LoopField
		fWidthLines := ""
		fWidthLine := ""
		pos := 0
		Loop Parse line, " `t" {
			word := A_LoopField
			pos += StrLen(word) + 1
			wLen := StrLen(word)
			if (StrLen(fWidthLine) + wLen <= maxCharsPerLine)
				fWidthLine .= word . SubStr(line, pos, 1)
			else {
				if (fWidthLine != "")
					fWidthLines .= fWidthLine '`n'
				if (wLen <= maxCharsPerLine)
					fWidthLine := word . SubStr(line, pos, 1)
				else {
					Loop(iters := wLen//maxCharsPerLine)
						fWidthLines .= SubStr(word, (A_Index - 1) * maxCharsPerLine + 1, maxCharsPerLine) . "`n"
					if (wLen > iters * maxCharsPerLine)
						fWidthLine := SubStr(word, iters * maxCharsPerLine + 1)
				}
			}
		}
		fWidthLines := ( fWidthLine == "" ? SubStr(fWidthLines, 1, StrLen(fWidthLines) - 1) : fWidthLines . fWidthLine)
		nStr .= fWidthLines . (A_Index == loops ? '' : '`n')
	}
	return nStr
}

strGetSplitLen(str, delim, omit := '') {
	lens := []
	Loop Parse, str, delim, omit
		lens.push(StrLen(A_LoopField))
	return lens
}

/**
 * Given a string str and a number of splits, returns an array containing all possible splits of str with [splits] partitions  
 * @param str the string to split
 * @param {Integer} splits amount of parts to split the string into
 * @returns {Array} 
 * @example ?????
 */
strSplitRecursive(str, splits := StrLen(str)) {
	if (splits == 1)
		return [[str]]
	else if (StrLen(str) == splits)
		return [StrSplit(str)]
	arr := []
	Loop(StrLen(str) - splits + 1) {
		cur := SubStr(str, 1, A_Index)
		a := strSplitRecursive(SubStr(str, A_Index + 1), splits - 1)
		for i, e in a
			a[i].insertat(1, cur)
		arr.push(a*)
	}
	return arr
}

class Uri {
; stolen from https://github.com/ahkscript/libcrypt.ahk/blob/master/src/URI.ahk
	static encode(str) { ; keep ":/;?@,&=+$#."
		return this.LC_UriEncode(str)
	}

	static decode(str) {
		return this.LC_UriDecode(str)
	}

	static LC_UriEncode(uri, RE := "[0-9A-Za-z]") {
		var := Buffer(StrPut(uri, "UTF-8"), 0)
		StrPut(uri, var, "UTF-8")
		while(code := NumGet(Var, A_Index - 1, "UChar"))
			res .= RegExMatch(char := Chr(Code), RE) ? char : Format("%{:02X}", Code)
		return res
	}

	static LC_UriDecode(uri) {
		pos := 1
		while(pos := RegExMatch(uri, "i)(%[\da-f]{2})+", &code, pos)) {
			var := Buffer(StrLen(code[1]) // 3, 0)
			Code := SubStr(code[1], 2)
			Loop Parse, code, "`%"
				NumPut("UChar", "0x" A_LoopField, var, A_Index - 1)
			decoded := StrGet(var, "UTF-8")
			uri := SubStr(uri, 1, pos - 1) . decoded . SubStr(uri, pos+StrLen(Code)+1)
			pos += StrLen(decoded)+1
		}
		return uri
	}
}

/**
 * Rounds a number to its nth place while also trimming 0, . and transforming to integer if needed
 * @param num 
 * @param {Integer} precision 
 * @returns {Integer | Number} 
 */
numRoundProper(num, precision := 12) {
	if (!IsNumber(num))
		return num
	if (IsInteger(num) || Round(num) == num)
		return Integer(num)
	else
		return Number(RTrim(Round(num, precision), "0."))
}

intMax() {
	return 2**63-1
}

clamp(n, minimum, maximum) => Max(minimum, Min(n, maximum))
isClamped(n, minimum, maximum) => (n <= maximum && n >= minimum)
hex(n) => Format("0x{:X}", n)
oct(n) => Format("{:o}", n)

/**
 * Counts how many times a given value is included in an Object
 * @param obj array or map
 * @param value value to check for
 * @returns {Integer} Count of how many instances of value were encountered
 */
objCountValue(obj, value, conditional := (itKey,itVal,setVal) => (itVal = setVal)) {
	isArrLike := (obj is Array || obj is Map)
	if !(isArrLike || IsObject(obj))
		throw(TypeError("objCountValue does not handle type " . Type(obj)))
	count := 0
	for i, e in objGetEnumerator(obj)
		if conditional(i, e, value)
			count++
	return count
}

/**
 * Checks whether obj contains given value and returns index if found, else 0
 * @param obj 
 * @param value 
 * @param {Func} comparator 
 * @returns {Integer} 
 */
objContainsValue(obj, value, fn := (v => v)) {
	isArrLike := (obj is Array || obj is Map)
	if !(isArrLike || IsObject(obj))
		throw(TypeError("objContainsValue does not handle type " . Type(obj)))
	for i, v in objGetEnumerator(obj)
		if fn(v) == value
			return i
	return 0
}

/**
 * Checks whether obj contains given value and returns index if found, else 0
 * @param obj 
 * @param value 
 * @param {Func} comparator 
 * @returns {Integer} 
 */
objContainsMatch(obj, match := (itKey,itVal) => (true), retAllMatches := 0) {
	isArrLike := (obj is Array || obj is Map)
	if !(isArrLike || IsObject(obj))
		throw(TypeError("objContainsMatch does not handle type " . Type(obj)))
	if retAllMatches {
		arr := []
		for i, e in objGetEnumerator(obj)
			if (match(i, e))
				arr.push(i)
		return arr
	}
	for i, e in objGetEnumerator(obj)
		if (match(i, e))
			return i
	return 0
}

/**
 * Returns ObjOwnPropCount if obj is Object, else .Length or .Count for Array/Map
 * @param obj 
 * @returns {Integer} 
 */
objGetValueCount(obj, recursive := false) {
	if !recursive
		return obj is Map ? obj.Count : (obj is Array ? obj.Length : ObjOwnPropCount(obj))
	return objCollect(obj, (b, e?) => b + (IsSet(e) && IsObject(e) ? objGetValueCount(e, true) : 1), 0)
}

objGetRandomValue(obj) {
	isArrLike := (obj is Array || obj is Map)
	isArr := obj is Array
	if !(isArrLike || IsObject(obj))
		throw(TypeError("objGetRandomValue does not handle type " . Type(obj)))
	r := Random(1, objGetValueCount(obj))
	if isArr
		return obj[r]
	for i, e in isArrLike ? obj : obj.ownprops()
		if A_Index == r
			return e
}

/**
 * Returns a deep copy of a given object.
 * @param obj A .Clone()-able object
 * @returns {Object} A deep clone of the given object
 */
objClone(obj) {
	isArrLike := (obj is Array || obj is Map)
	if !(IsObject(obj))
		return obj
	copy := obj.Clone()
	for i, e in objGetEnumerator(obj)
		isArrLike ? copy[i] := objClone(e) : copy.%i% := objClone(e)
	return copy
}

/**
 * Merges obj2 into obj1 or creates a new object if desired. Prefers obj1 keys over obj2 unless specified.
 * This only works for Maps and Objects. For merging arrays, use arrayMerge instead.
 * @param obj1 
 * @param obj2 
 * @param {Integer} createNew 
 * @param {Integer} overwriteIdenticalKeys 
 * @returns {Any} 
 */
objMerge(obj1, obj2, createNew := false, overwriteIdenticalKeys := false) {
	if (Type(obj1) != Type(obj2))
		throw(TypeError("obj1 and obj2 are not of equal type, instead " Type(obj1) ", " Type(obj2)))
	isMap := obj1 is Map
	obj := createNew ? objClone(obj1) : obj1
	for key, val in objGetEnumerator(obj2) {
		if (isMap) {
			if !obj.Has(key) || overwriteIdenticalKeys
				obj[key] := val
		}
		else if (!obj.HasOwnProp(key) || overwriteIdenticalKeys)
			obj.%key% := val
	}
	return obj
}

/**
 * Deletes given Value from Object {limit} times. Returns count of removed values
 * @param {Array | Map} obj
 * @param value the value to remove
 * @param {Integer} limit if 0, removes all
 * @returns {Integer} count
 */
objRemoveValue(obj, value := "", limit := 0, conditional := ((itKey, itVal, val) => (itVal = val)), emptyValue?) {
	isArrLike := ((isArr := obj is Array) || obj is Map)
	if !(isArrLike || IsObject(obj))
		throw(TypeError("objRemoveValue does not handle type " . Type(obj)))
	queue := []
	count := 0
	for i, e in objGetEnumerator(obj)
		if conditional(i, e, value) {
			if (!limit || count++ < limit)
				queue.push(i)
			else
				break
		}
	n := queue.Length
	if (IsSet(emptyValue)) {
		for e in queue
			isArrLike ? obj[e] := emptyValue : obj.%e% := emptyValue
	} else {
		while (queue.Length != 0)
			isArrLike ? (isArr ? obj.RemoveAt(queue.Pop()) : obj.Delete(queue.Pop())) : obj.DeleteProp(queue.Pop())
	}
	return n
}

/**
 * Deletes given Value from Object, either on first encounter or on all encounters. Returns count of removed values
 * @param obj 
 * @param values 
 * @param {Integer} limit 
 * @param {(iterator, value) => Number} comparator 
 * @param emptyValue If this is set, all encountered values are not removed, but instead replaced by this value.
 * @returns {Integer} 
 */
objRemoveValues(obj, values, limit := 0, conditional := ((itKey,itVal,setVal) => (itVal = setVal)), emptyValue?) {
	isArrLike := ((isArr := obj is Array) || obj is Map)
	if !(isArrLike || IsObject(obj))
		throw(TypeError("objRemoveValues does not handle type " . Type(obj)))
	queue := []
	count := 0
	for i, e in objGetEnumerator(obj)
		for f in values
			if conditional(i, e, f) {
				if (!limit || count++ < limit)
					queue.push(i)
				else
					break
			}
	n := queue.Length
	if (IsSet(emptyValue)) {
		for e in queue
			isArrLike ? obj[e] := emptyValue : obj.%e% := emptyValue
	} else {
		while (queue.Length != 0)
			isArrLike ? (isArr ? obj.RemoveAt(queue.Pop()) : obj.Delete(queue.Pop())) : obj.DeleteProp(queue.Pop())
	}
	return n
}

/**
 * Creates a new object containing only values matching filter.
 * @param obj 
 * @param {(k, v) => Boolean} filter 
 * @returns {Integer} 
 */
objFilter(obj, filter := (k, v) => (true)) {
	isArrLike := ((isArr := obj is Array) || obj is Map)
	if !(isArrLike || IsObject(obj))
		throw(TypeError("objRemoveValue does not handle type " . Type(obj)))
	clone := %Type(obj)%()
	if isArr
		clone.Capacity := obj.Length
	if isArr {
		for i, e in obj
			if filter(i, e)
				clone.push(e)
	} else if isArrLike {
		for i, e in obj
			if filter(i, e)
				clone[i] := e
	} else {
		for i, e in ObjOwnProps(obj)
			if filter(i, e)
				clone.%i% := e
	}
	return clone
}

objDoForEach(obj, fn := (v) => toString(v), conditional := (itKey?, itVal?) => true, useKeys := false) {
	isArrLike := (obj is Array || obj is Map)
	isMap := (obj is Map)
	if !(isArrLike || IsObject(obj))
		throw(TypeError("objDoForEach does not handle type " . Type(obj)))
	clone := %Type(obj)%()
	if (isArrLike && !isMap)
		clone.Length := clone.Capacity := obj.Length
	for i, e in objGetEnumerator(obj) {
		t := useKeys ? i : e
		v := conditional(i, e?) ? fn(t?) : t
		isArrLike ? clone[i] := v : clone.%i% := v
	}
	return clone
}

objGetMinimum(obj) => objCollect(obj, (a,b) => Min(a,b))
objGetMaximum(obj) => objCollect(obj, (a,b) => Max(a,b))
objGetSum(obj) => objCollect(obj, (a,b) => (a+b))
objGetAverage(obj) => objGetSum(obj) / objGetValueCount(obj)
objGetProd(obj) => objCollect(obj, (b,i) => b*i)

/**
 * 
 * @param obj 
 * @param {Func} fn function responsible for collecting objects. Equivalent to fn(fn(....fn(fn(base,obj[1]),obj[2])...,obj[n-1]),obj[n])
 * @param {Any} initialBase Initial value of the base on which fn operates. If not given, first element in object becomes base. Set this if fn operators onto properties or items of enumerable values.
 * @param {Any} value Optional Value to check conditional upon
 * @param {Func} conditional Optional Comparator to determine which values to include in collection.
 * @returns {Any} Collected Value
 */
objCollect(obj, fn := ((base, e) => (base . ", " . toString(e))), initialBase?, conditional := (itKey?, itVal?) => true, useKeys := false) {
	isArrLike := (obj is Array || obj is Map)
	if !(isArrLike || IsObject(obj))
		throw(TypeError("objForEach does not handle type " . Type(obj)))
	if (IsSet(initialBase))
		base := initialBase
	for i, e in objGetEnumerator(obj)
		if (conditional(i, e?))
			base := IsSet(base) ? (useKeys ? fn(base, i?) : fn(base, e?)) : e
	return base ?? ""
}

objFlatten(obj, fn := (e => e), keys := false) {
	arr := []
	for key, e in objGetEnumerator(obj)
		arr.push(keys ? fn(key) : fn(e))
	return arr
}

/**
 * 
 * @param obj 
 * @param {(a) => void} fn Function to get value to compare for duplications. Ie for [{x:1,y:5},{x:4,y:5}] specify (a) => (a.y) to get entries where y is the same
 * @param {Integer} caseSense Whether comparison is case-sense strict or not
 * @param {Integer} grouped Determines whether to group indices by their value
 * @returns {Array} If grouped, array of arrays of indices of duplicate values, sorted alphanumerically by value. Otherwise, sorted array of indices of duplicate values
 */
objGetDuplicates(obj, fn := (a => a), caseSense := true, grouped := false) {
	isArrLike := (obj is Array || obj is Map)
	if !(isArrLike || IsObject(obj))
		throw(TypeError("objForEach does not handle type " . Type(obj)))
	duplicateMap := Map()
	counterMap := Map()
	duplicateIndices := []
	duplicateMap.CaseSense := caseSense
	for i, e in objGetEnumerator(obj) {
		v := fn(e)
		if (duplicateMap.Has(v)) {
			duplicateMap[v].push(i)
			counterMap[v] := 1
		}
		else
			duplicateMap[v] := [i]
	}
	if grouped {
		for i, e in duplicateMap
			if e.Length > 1
				duplicateIndices.push(e)
	}
	else
		for i, e in objGetEnumerator(obj) {
			v := fn(e)
			if (duplicateMap[v].Length > 1)
				duplicateIndices.push(duplicateMap[v][counterMap[v]++])
		}
	return duplicateIndices
}

/**
 * 
 * @param obj Object to search duplicates in
 * @param {(a) => (a)} fn Function to get value to compare for duplications. Ie for [{x:1,y:5},{x:4,y:5}] specify (a) => (a.y) to get entries where y is the same
 * @returns {Object} CLONE of obj without duplicates
 */
objRemoveDuplicates(obj, fn := (a => a), caseSense := true) {
	isArrLike := (obj is Array || obj is Map)
	isMap := (obj is Map)
	if !(isArrLike || IsObject(obj))
		throw(TypeError("objForEach does not handle type " . Type(obj)))
	duplicateMap := Map()
	duplicateMap.CaseSense := caseSense
	for i, e in objGetEnumerator(obj) {
		v := fn(e)
		if (duplicateMap.Has(v))
			duplicateMap[v]++
		else
			duplicateMap[v] := 1
	}
	clone := %Type(obj)%()
	for i, e in objGetEnumerator(obj) {
		v := fn(e)
		if (duplicateMap[v] == 1)
			isArrLike ? (isMap ? clone[i] := e : clone.push(e)) : clone.%i% := e
	}
	return clone
}

objGetUniques(obj, fn := (a => a), caseSense := true) {
	isArrLike := (obj is Array || obj is Map)
	isMap := (obj is Map)
	if !(isArrLike || IsObject(obj))
		throw(TypeError("objForEach does not handle type " . Type(obj)))
	uniques := Map()
	uniques.CaseSense := caseSense
	clone := %Type(obj)%()
	for i, e in objGetEnumerator(obj) {
		if !IsSet(e)
			continue
		v := fn(e)
		if !(uniques.Has(v)) {
			uniques[v] := true
			isArrLike ? (isMap ? clone[i] := e : clone.push(e)) : clone.%i% := e
		}
	}
	return clone
}

/**
 * Given two objects, returns a clone of obj2 where all values that are also present in obj1 are deleted
 * @param obj1 
 * @param obj2 
 * @param {(a) => void} fn 
 * @param {Integer} caseSense 
 */
objGetComparedUniques(obj1, obj2, fn := (a => a), caseSense := true) {
	isArrLike := (obj2 is Array || obj2 is Map)
	isMap := (obj2 is Map)
	if !(isArrLike || IsObject(obj2))
		throw(TypeError("objForEach does not handle type " . Type(obj2)))
	appeared := Map()
	appeared.CaseSense := caseSense
	clone := %Type(obj2)%()
	for i, e in objGetEnumerator(obj1)
		appeared[fn(e)] := true
	for i, e in objGetEnumerator(obj2) {
		v := fn(e)
		if !(appeared.Has(v)) {
			isArrLike ? (isMap ? clone[i] := e : clone.push(e)) : clone.%i% := e
		}
	}
	return clone
}

/**
 * Returns true if obj1 and obj2 share the same keys and values and type, 0 otherwise. Does not check for inherited values or Prototype values being different.
 * ```
 * obj1 := {x: 1, y: Map(1,2)}
 * obj2 := {x: 1, y: Map(1,2)}
 * objCompare(obj1, obj2) == true
 * obj2.y.CaseSense := "Off"
 * objCompare(obj1, obj2) == false
 * objCompare(Number.Prototype, 5) == true
 * ```
 * @param obj1 
 * @param obj2 
 */
objCompare(obj1, obj2) {
	if (Type(obj1) != Type(obj2))
		return 0
	if !(IsObject(obj1))
		return (obj1 == obj2)
	isObj := !(obj1 is Array || obj1 is Map)
	isMap := (obj1 is Map)
	count1 := isObj ? ObjOwnPropCount(obj1) : (isMap ? obj1.Count : obj1.Length)
	count2 := isObj ? ObjOwnPropCount(obj2) : (isMap ? obj2.Count : obj2.Length)
	if (count1 != count2)
		return 0
	for i, j, e, f in objZip(obj1, obj2) {
		if (i != j)
			return 0
		if !objCompare(e, f)
			return 0
	}
	return 1
}

objEnumIf(obj, conditional := (e?) => IsSet(e?)) {
	objEnum := objGetEnumerator(obj, true)
	index := 1
	return _enumerate

	_enumerate(&i, &j:= -1, &e := -1) {
		flag2Var := !IsSet(j)
		flag3Var := !IsSet(e)
		flagNotAtEnd := flag2Var ? objEnum(&k, &f) : objEnum(&_, &f)
		if flagNotAtEnd {
			while(!conditional(f) && flagNotAtEnd)
				flagNotAtEnd := flag2Var ? objEnum(&k, &f) : objEnum(&_, &f)
			flag3Var ? (i := index++, j := k, e := f) : flag2Var ? (i := k, j := f) : i := f
		}
		return flagNotAtEnd
	}
}

/**
 * Zips two objects as a combined enumerator. Can accept 2-4 parameters. 
 * @param obj1 Object 1
 * @param obj2 Object 2 (Must be of same Type as Object 1)
 * @param {Integer} stopAtAnyEnd Whether to stop enumerating on encountering ANY end in the objects or whether to stop after ALL ends have been reached (will return unset for ended objects)
 * @returns {Enumerator} Func(&i, &j, &n := -1, &m := -1) Accepts up to 4 parameters. 
 * If two params are given, enumerates both objects values.
 * If three params are given, enumerates the total index and both objects values.
 * If four params are given, enumerates respective key and value of both objects: i = obj1Index, j = obj2Index, n = obj1Value, m = obj2Value
 */
objZip(obj1, obj2, stopAtAnyEnd := true) {
	if (Type(obj1) != Type(obj2))
		throw(TypeError("obj1 and obj2 are not of equal type, instead " Type(obj1) ", " Type(obj2)))
	obj1Enum := objGetEnumerator(obj1, true)
	obj2Enum := objGetEnumerator(obj2, true)
	index := 1
	return (&i, &j, &n := -1, &m := -1) => (
		flag3Var := !IsSet(n), ; if for-loop passes n to this function, then it is unset. otherwise it is set.
		flag4Var := !IsSet(m),
		flagObj1End := flag4Var ? obj1Enum(&i, &n) : (flag3Var ? (i := index++, obj1Enum(&_, &j)) : obj1Enum(&_, &i)),
		flagObj2End := flag4Var ? obj2Enum(&j, &m) : (flag3Var ? obj2Enum(&_, &n) 				  : obj2Enum(&_, &j)),
		stopAtAnyEnd ? flagObj1End && flagObj2End : flagObj1End || flagObj2End
	)
}

/**
 * Zips any amount of objects into a combined enumerator, where each enumerated value is an array containing the currently enumerated value for each object..
 * @param objects Variadic amount of objects. Need not be of the same type.
 * @returns {Enumerator} Func(&i, &e := -1, &f := -1) Accepts up to 3 Parameters.
 * If only 1 Parameter is given, enumerates values in all objects simultaneously and gives an array of these values.
 * If two are given, enumerates index and all values.
 * If three are given, enumerates index, an array of the current keys for all objects and an array of corresponding values. 
 */
objZipAsArray(objects*) {
	len := objects.Length
	index := 1
	enums := []
	for o in objects
		enums.push(objGetEnumerator(o, true))
	return (&i, &e := -1, &v := -1) => (
		flag2Var := !IsSet(e), ; if for-loop passes n to this function, then it is unset. otherwise it is set.
		flag3Var := !IsSet(v),
		arrVals := [], arrVals.Capacity := len,
		flag3Var ? (arrKeys := [], arrKeys.Capacity := len) : 0,
		arrResult := flag3Var ? objDoForEach(enums, (en) => (flag := en(&l, &r), arrKeys.push(l?), arrVals.push(r?), flag)) : objDoForEach(enums, (en) => (flag := en(&_, &r), arrVals.push(r?), flag)),
		flagIsAtEnd := objCollect(arrResult, (a, b) => a || b),
		flag2Var ? (i := index++, flag3Var ? (e := arrKeys, v := arrVals) : e := arrVals) : i := arrVals,
		flagIsAtEnd
	)
}

/**
 * Enumerates given objects one after another. 
 * @param objects Variadic chain of objects, can be mixed between obj/arr/map etc.
 * @returns {Enumerator} Func(&i, &j := -1, &e := -1). Accepts up to 3 parameters. 
 * If only 1 parameter is given, enumerates values. 
 * If two are given, enumerates total index and values. 
 * If three are given, enumerates total index, the current objects' index/key and values.
 */
objChain(objects*) {
	enums := []
	for o in objects
		enums.push(objGetEnumerator(o, true))
	len := enums.Length
	index := 1
	objIndex := 1
	return (&i, &j := -1, &e := -1) => (
		flag2Var := !IsSet(j),
		flag3Var := !IsSet(e),
		enum := enums[objIndex],
		flagReachedObjEnd := !(flag2Var ? (i := index++, flag3Var ? enum(&j,&e) : enum(&_, &j)) : enum(&_, &i)),
		flagReachedObjEnd ? objIndex++ : 0,
		flagLastObjEnd := objIndex > len,
		flagReachedObjEnd && !flagLastObjEnd ? enum := enums[objIndex] : 0,
		flagReachedObjEnd && !flagLastObjEnd ? (flag2Var ? (flag3Var ? enum(&j,&e) : enum(&_, &j)) : enum(&_, &i)) : 0,
		!flagLastObjEnd
	)
}

objGetEnumerator(obj, getEnumFunction := false, numberParams?) {
	enum := (obj is Array || obj is Map || obj is ComValue) ? obj : ObjOwnProps(obj)
	if !getEnumFunction
		return enum
	try
		enum := enum.__Enum(numberParams?)
	return enum
}

objGetBaseChain(obj) {
	base := obj
	arr := [base]
	while (base)
		arr.push(base := ObjGetBase(base))
	return arr
}

objGetClassObject(obj) {
	loop((cNames := StrSplit(obj.__Class, ".")).Length) ; if className is eg. Gui.Control, we can't do %Gui.Control%, instead do %Gui%.%Control%
		classObj := A_Index == 1 ? %cNames[1]% : classObj.%cNames[A_Index]%
	return classObj
}


; Aliases for shorthand options
ToStringNoBases(obj, detailedFunctions := false)	=>	toString(obj, , false, , , , true, detailedFunctions, true, false)
ToStringFull(obj, detailedFunctions := false)	=>	toString(obj, , false, , , , true, detailedFunctions, true, true)
ToStringClass(obj, detailedFunctions := false)	=>	toString(obj, , false, , , , true, detailedFunctions, false, false)
/**
 * Return a json-like representation of the given variable, with selectable level of detail.
 * @param {Any} obj Any Value.
 * @param {Integer} [compact] If true, returned String will not contain newlines of any kind. Otherwise, obj will be expanded by its inner values, with the level of expansion set by compress
 * @param {Integer} [compress] If true, returned String will not contain spaces (or indent) and objects with only primitive values or only one inner value will not be expanded.
 * @param {Integer} [strEscape] If true, will escape any values with quotation marks (with the exception of pure numbers). If not set, is false only when obj is an instance and the other flags are false or not set
 * @param {Integer} [anyAsObj] If true, all objects will be printed in the form of { key: value, ... }. Note that if either withInheritedProps or withClassOrPrototype are set to true, then this will default to true, since it is not feasible to put both enumerated values in map form (Map("key", "value")) and properties (Map().CaseSense: "On") or Array Form ([1,2,3]) and properties (Array().Length) in the same object.
 * @param {String} [spacer] String used to indent nested objects (if not compressed)
 * @param {Boolean} [withInheritedProps] Whether to print Values of Properties that are not OwnProps, but inherited from class- or Prototype-Objects. If not set, automaticaly chosen depending on if obj has any values to print and if it is an instance of a class
 * @param {Boolean} [detailedFunctions] Whether to print functions as "Name": "Func" or whether to print Func properties such as MinParams, IsVariadic etc.
 * @param {Boolean} [withClassOrPrototype] Whether to print the class object of an instance, and the Prototype of a class Object
 * @param {Boolean} [withBases] Whether to print the .Base property. If true,any object will have its Base Chain printed up to Any.Prototype. Does NOT print class.Prototype.base, instead only class.base.Prototype (to avoid printing duplicate information), and furthermore does not print Class.Prototype, Object.Prototype, Any.Prototype at all (since they are included in the base chain anyway, since Any.Base == Class.Prototype)
 * @returns {String} The string representing the object
 */
toString(obj, compact := false, compress := true, strEscape := false, mapAsObj := true, spacer := "`t", withInheritedProps?, detailedFunctions?, withClassOrPrototype?, withBases?) {
	if obj is VarRef || obj is ComValue {
		return "{}"
	} else if IsObject(obj) {
		origin := obj
		flagFirstIsInstance := (Type(obj) != "Prototype" && Type(obj) != "Class" && Type(objgetbase(obj)) == "Prototype") ; equivalent to line below
		; if obj is an instance of a class, and it isnt enumerable, and it doesn't have any own props, then try getting inheritables
		flagIncludeInheritedProps :=	withInheritedProps		?? (flagFirstIsInstance && !obj.HasMethod("__Enum") && ObjOwnPropCount(obj) == 0)
		flagDetailedFunctions := 		detailedFunctions		?? !flagFirstIsInstance ; (flagFirstIsInstance && Type(obj) != "Func" ? 0 : 1)
		flagIncludeClassOrPrototype := 	withClassOrPrototype	?? !flagFirstIsInstance
		flagWithBases := 				withBases 				?? !flagFirstIsInstance
		strEscape := 					strEscape				?? (!flagFirstIsInstance || flagIncludeClassOrPrototype || flagWithBases)
		overrideAsObj := (flagIncludeClassOrPrototype || flagIncludeInheritedProps)
	}
	encounteredObjs := Map() ; to avoid self-reference loops
	return _toString(obj, 0)

	_toString(obj, indentLevel, flagOverrideStrEscape := false, flagIsOwnPropDescObject := false) {
		static escapes := [["\", "\\"], ['"', '\"'], ["`n", "\n"], ["`r", "\r"], ["`t", "\t"]]
		qt := strEscape || flagOverrideStrEscape ? '"' : ''
		if !(IsObject(obj)) { ; if obj is Primitive, no need for the entire rest.
			if (obj is Number)
				return String(obj)
			if (IsNumber(obj))
				return qt obj qt
			if (strEscape || flagOverrideStrEscape) {
				for e in escapes
					obj := StrReplace(obj, e[1], e[2])
				return qt String(obj) qt
			}
			return obj
		}
		if (encounteredObjs.Has(ObjPtr(obj)))
			return "{}"
		encounteredObjs[ObjPtr(obj)] := true
		; for very small objects, this may be excessive to do, but it would be very messy otherwise
		objType := Type(obj)
		flagIsMap := obj is Map
		flagIsArr := obj is Array
		flagIsObj := ((!flagIsArr && !flagIsMap) || objType == "Prototype" ? 1 : 0)
		flagIsInstance := (objType != "Prototype" && objType != "Class" && Type(ObjGetBase(obj)) == "Prototype") ; we could also check whether obj doesn't have the proprety Prototype, but that relies on the object not being Primitive/Any
		indent := (compress || compact)  ? '' : strMultiply(spacer, indentLevel)
		trspace := compress ? "" : A_Space
		separator := (compact || compress) ? trspace : '`n' indent . spacer
		sep2 := (compact || compress) ? trspace : '`n' indent
		count := objGetValueCount(obj, false)
		className := obj.__Class
		str := ""
		if (flagIsInstance) {
			if (obj.HasMethod("__Enum")) ; enumerate own properties
				for k, v in obj
					strFromCurrentEnums(k, v?, true)
			; get OwnProps and inherited Properties (depending on the flag)
			; Ignores .Prototype and .__Class (Prototype later and .__Class is present multiple times)
			strFromAllProperties(flagIncludeInheritedProps ? -1 : 0)
			; now, add .__Class for the current object
			if (flagIncludeClassOrPrototype && !flagIsOwnPropDescObject)
				strFromCurrentEnums("__Class", className)
			if (flagWithBases && obj == origin)
				strFromCurrentEnums("Base", obj.base)
			; this would get the class object from an instance. why would we need this?
			; if !(flagIsOwnPropDescObject || flagIsBadFunction || !flagIncludeClassOrPrototype)
			;	strFromCurrentEnums("Class_Object", objGetClassObject(obj))
		} else {
			for k in ObjOwnProps(obj) {
				if (!flagIncludeClassOrPrototype && k == "Prototype")
					continue
				if (obj.HasMethod("GetOwnPropDesc") && (propertyObject := obj.GetOwnPropDesc(k)).HasMethod("Get") && (propertyObject.get.MinParams > 1 || objType == "Prototype"))
					strFromCurrentEnums(k, propertyObject,, true) ; cannot get obj.%k% since it requires parameters. If we don't have getownpropdesc, there will not be issues (unless this is a primitive value with a property that requires params ?)
				else if (k == "Prototype" && (obj.Prototype.__Class == "Class" || obj.Prototype.__Class == "Object" || obj.Prototype.__Class == "Any"))
					strFromCurrentEnums(k, obj.Prototype.__Class ".Prototype")
				else
					strFromCurrentEnums(k, (!flagDetailedFunctions && Type(obj.%k%) == "Func") ? Type(obj.%k%) : obj.%k%)
			}
			; non-prototypes (class objects) should get their base. for class.prototype, object.prototype we need their base since there isn't a way to get it otherwise. any.prototype is empty and is also enumerated above.
			flagIsGoodPrototype := (objType == "Prototype" && (className == "Class" || className == "Object"))
			if (flagWithBases) {
				if (objType != "Prototype" || (flagIsGoodPrototype))
					strFromCurrentEnums("Base", ObjGetBase(obj))
				else if className != "Any" ; we are a bad prototype and only get a String base. If we are Any.Prototype, we get no base at all. D:
					strFromCurrentEnums("Base", obj.base.__Class ".Prototype")
			}
		}
		wrapper := overrideAsObj ? ["{", "}"] : ( flagIsArr ? ["[", "]"] : ( mapAsObj ? ["{", "}"] : ["Map(", ")"]))
		return (wrapper[1] . (str == '' ? '' : separator) . RegExReplace(str, "," separator "$") . (str == '' ? '' : sep2) . wrapper[2])

		strFromCurrentEnums(k, v?, overrStrEscape?, isOwnPropDescObject?) {
			if (!compact && compress)
				separator := sep2 := isSimple(v?) ? trspace : '`n'
			if !(IsSet(v)) ; must be array, obj/map keys cannot be unset
				str := RTrim(str, separator) "," separator
			else if (overrideAsObj || flagIsObj || (mapAsObj && flagIsMap))
				str .= _toString(k ?? "", indentLevel + 1, true) (flagIsMap && !mapAsObj ? "," : ":") trspace _toString(v ?? "", indentLevel + 1,, isOwnPropDescObject?) "," separator
			else
				str .= _toString(v ?? "", indentLevel + 1, flagOverrideStrEscape?) "," separator
		}

		strFromAllProperties(maxDepth := -1) {
			base := obj
			depth := 0 ; maxDepth == -1 -> get all properties, maxDepth == 0 -> get only own, == n -> get own and n level deep
			while (base) {
				if (!base || base.__Class == "Any")
					break
				for k in ObjOwnProps(base) {
					if (k == "__Class" || k == "Prototype")
						continue
					propdesc := base.GetOwnPropDesc(k)
					flag := propdesc.HasProp("Value") || (propdesc.HasMethod("get") && propdesc.get.MinParams < 2) ; 1 or 0 because class Methods have (this)
					if flag
						strFromCurrentEnums(k, (!flagDetailedFunctions && Type(obj.%k%) == "Func") ? Type(obj.%k%) : obj.%k%)
				}
				if (maxDepth == depth++)
					break
				base := ObjGetBase(base)
			}
		}

		isSimple(v?) {
			if !IsSet(v)
				return 1
			if !IsObject(v)
				return 1
			if count == 1 && objGetValueCount(v) < 2
				return 1
			return 0
		}
	}
}

varsToString(vars*) => toString(vars,0,1,0)

; Unreliable, may only work in ahk versions around ~2.0.9
BoundFnName(Obj) {
	Address := ObjPtr(Obj)
	n := NumGet(Address, 5 * A_PtrSize + 16, "Ptr")
	Obj := ObjFromPtrAddRef(n)
	return Obj.Name
}

range(startEnd, end?, step?, inclusive := true) {
	start := IsSet(end) ? startEnd : 1
	end := end ?? startEnd
	step := step ?? 1
	index := 1
	return (&n, &m := -1) => (
		!IsSet(m) ? 
			(n := index++, m := start, start := numRoundProper(start + step), inclusive ? m <= end : m < end) : 
			(n := start, start := numRoundProper(start + step), inclusive ? n <= end : n < end)
	)
}

rangeAsArr(startEnd, end?, step?, inclusive := true) {
	local arr := []
	arr.Capacity := Floor(Abs((end ?? 0) - startEnd) * 1/step) + inclusive
	for e in range(startEnd, end?, step?, inclusive)
		arr.push(e)
	return arr
}

arrayMerge(arrs*) {
	ret := []
	len := 0
	for arr in arrs
		len += arr.length
	ret.Capacity := len
	for arr in arrs
		ret.push(arr*)
	return ret
}

arrayMergeSorted(arr1, arr2) {
	ret := []
	p1 := 1, p2 := 1
	l1 := arr1.Length, l2 := arr2.Length
	while(p1 <= l1 && p2 <= l2) {
		if (arr1[p1] < arr2[p2])
			ret.push(arr1[p1++])
		else
			ret.push(arr2[p2++])
	}
	while(p1 <= l1)
		ret.push(arr1[p1++])
	while(p2 <= l2)
		ret.push(arr2[p2++])
	return ret
}

arrayIsSorted(arr, downwards := false) {
	if downwards {
		Loop(arr.Length - 1)
			if arr[A_Index] < arr[A_Index + 1]
				return false
		return true
	}
	Loop(arr.Length - 1)
		if arr[A_Index] > arr[A_Index + 1]
			return false
	return true
}

/**
 * For an array subset whose values are all contained in arr, and a value contained in arr, inserts the value in the position defined through the ordering in set.
 * @param arr 
 * @param subarr 
 * @param compareValue 
 * @param insertValue 
 * @param {(itVal, compVal) => Number} comparator 
 * @returns {Integer} Index of the inserted element
 */
arrayInsertSorted(arr, subarr, compareValue, insertValue := compareValue, transformer := (itVal => itVal)) {
	next := 1
	for i, e in arr {
		if (transformer(e) == compareValue || next > subarr.Length) {
			subarr.InsertAt(next, insertValue)
			break
		}
		if transformer(e) == transformer(subarr[next])
			next++
	}
	return next
}

arraySlice(arr, from := 1, to := arr.Length) {
	arr2 := []
	to := to > arr.Length ? arr.Length : to
	arr2.Capacity := to - from + 1
	Loop(to - from + 1)
		arr2.push(arr[from + A_Index - 1])
	return arr2
}

arrayFunctionMask(arr, maskFunc := (a) => (IsSet(a)), keepEmpty := true) {
	arr2 := []
	if keepEmpty
		arr2.Length := arr.Length
	for i, e in arr {
		if (maskFunc(e)) {
			if keepEmpty 
				arr2[i] := e
			else
				arr2.push(e)
		}
	}
	return arr2
}

arrayMask(arr, mask, keepEmpty := true) {
	if arr.Length != mask.Length
		throw Error("Invalid mask given")
	arr2 := []
	if (keepEmpty)
		arr2.Length := arr.Length
	for i, e in mask {
		if (e) {
			if (keepEmpty)
				arr2[i] := arr[i]
			else
				arr2.push(arr[i])
		}
	}
	return arr2
}

arrayIgnoreIndex(arr, index) {
	arr2 := arr.Clone()
	arr2.RemoveAt(index)
	return arr2
}

arrayIgnoreIndices(arr, indices*) {
	arr2 := arr.Clone()
	for i, e in arraySort(indices, "N R")
		arr2.RemoveAt(e)
	return arr2
}

arrayReverse(arr) {
	arr2 := []
	for i, e in arr
		arr2.InsertAt(1, e)
	return arr2
}

/**
 * Enumerates an array backwards
 * @param arr 
 */
arrayInReverse(arr) {
	index := arr.Length
	if !index
		return (*) => false
	flagEnd := false
	return (&i, &e := -1) => (
		IsSet(e) ? i := arr[index] : (i := index, e := arr[index]),
		index > 1 ? (index--, 1) : (flagEnd ? 0 : flagEnd := 1)
	)
}

arraySort(arr, fn := (a => a), sortMode := "") {
	sortedArr := []
	indexMap := Map()
	counterMap := Map()
	if arr.Length == 0
		return sortedArr
	for i, e in arr {
		v := String(fn(e))
		if (indexMap.Has(v))
			indexMap[v].push(i)
		else {
			indexMap[v] := [i]
			counterMap[v] := 1
		}
		str .= v . "╦"
	}
	sortMode := RegExReplace(sortMode, "D.")
	valArr := StrSplit(Sort(SubStr(str, 1, -1), sortMode . " D╦"), "╦")
	for v in valArr
		sortedArr.push(arr[indexMap[v][counterMap[v]++]])
	return sortedArr
}

arrayBasicSort(arr, sortMode := "") => objBasicSort(arr, sortMode)

arrayContainsArray(arr, subArray, comparator := (arrVal,subArrVal) => (arrVal == subArrVal)) {
	sequenceIndex := 1
	if !subArray.length
		return 1
	firstEl := subArray[sequenceIndex]
	for i, e in arr {
		if comparator(firstEl, e) {
			seqStart := i - 1
			for j, k in subArray
				if !comparator(arr[seqStart + j], k)
					return 0
			return seqStart + 1
		}
	}
	return 0
}

/**
 * Sorts an object directly, returning the sorted Values Note that this converts everything to strings.
 * @param obj Given object
 * @param {String} sortMode
 * @returns {Array} 
 */
objBasicSort(obj, sortMode := "") {
	if !objGetValueCount(obj)
		return []
	for e in objGetEnumerator(obj)
		str .= e . "╦"
	sortMode := RegExReplace(sortMode, "D.")
	newStr := Sort(SubStr(str, 1, -1), sortMode . " D╦")
	return StrSplit(newStr, "╦")
}
objSortNumerically(obj, sortMode := "N") => objDoForEach(objBasicSort(obj, sortMode), (e => Number(e)))


objSort(obj, fn := (a => a), sortMode := "", noKeys := true) {
	isArrLike := obj is Array || obj is Map
	sortedArr := []
	sortedArr.Capacity := objGetValueCount(obj)
	indexMap := Map()
	counterMap := Map()
	if objGetValueCount(obj) == 0
		return sortedArr
	for i, e in objGetEnumerator(obj) {
		v := String(fn(e))
		if (indexMap.Has(v))
			indexMap[v].push(i)
		else {
			indexMap[v] := [i]
			counterMap[v] := 1
		}
		str .= v . "╦"
	}
	sortMode := RegExReplace(sortMode, "D.")
	valArr := StrSplit(Sort(SubStr(str, 1, -1), sortMode . " D╦"), "╦")
	if noKeys {
		if isArrLike
			for v in valArr
				sortedArr.push(obj[indexMap[v][counterMap[v]++]])
		else
			for v in valArr
				sortedArr.push(obj.%indexMap[v][counterMap[v]++]%)
	} else if isArrLike {
		for v in valArr {
			key := indexMap[v][counterMap[v]++]
			sortedArr.push({ key: key, value: obj[key]})
		}
	} else {
		for v in valArr {
			key := indexMap[v][counterMap[v]++]
			sortedArr.push({ key: key, value: obj.%key% })
		}
	}
	return sortedArr
}


/**
 * Creates a map from two given arrays, the first one becoming the keys of the other
 * @param keyArray 
 * @param valueArray 
 * @returns {Map} 
 */
mapFromArrays(keyArray, valueArray) {
	if (!(keyArray is Array) || !(valueArray is Array))
		throw(TypeError("mapFromArrays expected Arrays, got " Type(keyArray) ", " Type(valueArray)))
	else if (keyArray.Length != valueArray.Length)
		throw(ValueError("mapFromArrays expected Arrays of equal Length, got Lengths " keyArray.Length ", " valueArray.Length))
	newMap := Map()
	for k, v in objZip(keyArray, valueArray)
		newMap[k] := v
	return newMap
}

/**
 * Given a Map, returns an Array of Length 2 containing two Arrays, the first one containing Keys and the second containing Values. Ordering WILL be random, as Maps are not ordered.
 * @param mapObject 
 * @returns {Array}
 */
mapToArrays(mapObject) {
	if !(mapObject is Map)
		throw(TypeError("Expected Map, got " Type(mapObject)))
	arr1 := []
	arr2 := []
	for i, e in mapObject {
		arr1.Push(i)
		arr2.Push(e)
	}
	return [arr1, arr2]
}
/**
 * Given a Map, returns new Map where keys are the values of original map and vice versa
 * @param {Map} mapObject 
 * @returns {Map} 
 */
mapFlip(mapObject) {
	flippedMap := Map()
	for i, e in mapObject
		flippedMap[e] := i
	return flippedMap
}

/**
 * Given a Map, returns an equivalent Object. If given Object/Array, tries to find all Maps recursively and turns them. Does NOT convert Objects/Arrays.
 * @param objInput 
 * @param {Integer} recursive 
 * @returns {Object | Map | Array} 
 */
MapToObj(obj, recursive := true) {
	flagIsArray := obj is Array
	flagIsMapArray := flagIsArray || obj is Map
	if (!(obj is Object))
		return obj
	objOutput := flagIsArray ? Array() : {}
	if (flagIsArray)
		objOutput.Length := obj.Length
	for i, e in objGetEnumerator(obj) {
		if (flagIsArray)
			objOutput[i] := (recursive ? MapToObj(e, true) : e)
		else
			objOutput.%i% := (recursive ? MapToObj(e, true) : e)
	}
	return (objOutput)
}

/**
 * Given an object with enumerable (Own) Properties, returns equivalent Map. If given Map/Array and recursive is true, finds Objects in it and turns those.
 * @param objInput 
 * @param {Integer} recursive 
 * @returns {Object | Map | Array} 
 */
objToMap(obj, recursive := true) {
	if (!IsObject(obj))
		return obj
	flagisArr := obj is Array
	clone := flagisArr ? [] : Map()
	if (flagisArr)
		clone.Capacity := obj.Length, clone.Length := obj.Length
	for i, e in objGetEnumerator(obj)
		clone[i] := (recursive ? objToMap(e, true) : e)
	return clone
}

objToArrays(obj) => mapToArrays(objToMap(obj, false))
objFromArrays(keyArray, valueArray) => MapToObj(mapFromArrays(keyArray, valueArray), false)

/**
 * Extended version of DateAdd, allowing Weeks (W), Months (MO), Years (Y) for timeUnit. Returns YYYYMMDDHH24MISS timestamp
 * @param dateTime valid YYYYMMDDHH24MISS timestamp to add time to.
 * @param amount Amount of time to be added.
 * @param timeUnit Time Unit can be one of the strings (or their first letter): Years, Weeks, Days, Hours, Minutes, Seconds.
 * 
 * Months / Mo is available. Adding a month will result in the same day number the next month unless that would be invalid, in which case the number of days in the current month will be added.
 * 
 * Similarly, adding years to a leap day will result in the corresponding day number of the resulting year (2024-02-29 + 1 Year -> 2025-03-01)
 * @returns {string} YYYYMMDDHH24MISS Timestamp.
 */
DateAddW(dateTime, amount, timeUnit) {
	timeUnit := validateTimeUnit(timeUnit)
	if (amount == 0)
		return dateTime
	switch timeUnit {
		case "Seconds", "Minutes", "Hours", "Days":
			return DateAdd(dateTime, amount, timeUnit)
		case "Weeks":
			return DateAdd(dateTime, amount * 7, "D")
		case "Months":
			curMonth := parseTime(dateTime, "Mo")
			newMonth := Mod(curMonth + amount, 12)
			newMonth := Format("{:02}", (newMonth > 0 ? newMonth : 12 + newMonth))
			nextMonth := Format("{:02}", Mod(newMonth, 12) + 1)
			newYear := parseTime(dateTime, "Y") + Floor((curMonth + amount - 1) / 12)
			newTime := newYear . newMonth . SubStr(dateTime, 7)
			if (!IsTime(newTime)) {
				newDay := parseTime(dateTime, "D") - DateDiff(newYear . nextMonth, newYear . newMonth, "D")
				newTime := newYear . nextMonth . Format("{:02}", newDay) . SubStr(dateTime, 9)
			}
			return newTime
		case "Years":
			newYear := (parseTime(dateTime, "Y") + amount)
			newTime := newYear . SubStr(dateTime, 5)
			if !IsTime(newTime) ; leap day
				newTime := newYear . SubStr(DateAdd(dateTime, 1, "D"), 5)
			return newTime
		default:
			throw(ValueError("Invalid Time Unit: " timeUnit))
	}
}

DateDiffW(dateTime1, dateTime2, timeUnit) {
	timeUnit := validateTimeUnit(timeUnit)
	switch timeUnit, 0 {
		case "Seconds", "Minutes", "Days":
			diff := DateDiff(dateTime1, dateTime2, timeUnit)
		case "Weeks":
			diff := DateDiff(dateTime1, dateTime2, "Days") // 7
		case "Months":
			yDiff := parseTime(dateTime1, "Y") - parseTime(dateTime2, "Y")
			diff := 12 * yDiff + parseTime(dateTime1, "Mo") - parseTime(dateTime2, "Mo")
			newDate := DateAddW(dateTime2, diff, "Months")
			if DateDiff(dateTime1, newDate, "Seconds") >= 0
				diff--
		case "Years":
			diff := parseTime(dateTime1, "Y") - parseTime(dateTime2, "Y")
			if DateDiff(dateTime1, DateAddW(dateTime2, diff, "Years"), "Seconds") >= 0
				diff--
	}
	return diff
}

/*
* Given a set of time units, returns a YYYYMMDDHH24MISS timestamp
; of the earliest possible time in the future when all given parts match
* Examples: The current time is 27th December, 2023, 17:16:34
* parseTime() -> A_Now
* parseTime(2023,12) -> A_Now.
* parseTime(2023, , 27) -> A_Now.
* parseTime(2023, , 28) -> 20231228000000.
* parseTime(, 2, 29) -> 20240229000000 (next leap year).
* parseTime(2022, ...) -> 0.
* parseTime(2025, 02, 29) -> throw Error: Invalid Date
* parseTime(, 1, , , 19) -> 20240101001900
*/
nextMatchingTime(years?, months?, days?, hours?, minutes?, seconds?) {
	Now := A_Now
	local paramInfo := gap(years?, months?, days?, hours?, minutes?, seconds?)
	switch paramInfo.first {
		case 0:
			return Now
		case 1:
			if (years == A_Year && paramInfo.gap) { ; why compare to current year? leap year stuff
				tStamp := nextMatchingTime(, months?, days?, hours?, minutes?, seconds?)
				return (parseTime(tStamp, "Y") == years) ? tStamp : 0
			}
			tStamp := (years ?? A_Year) tf(months ?? 1) tf(days ?? 1) tf(hours ?? 0) tf(minutes ?? 0) tf(seconds ?? 0)
			if (!IsTime(tStamp)) {
				if (!IsSet(years) && IsSet(months) && months == 2 && IsSet(days) && days == 29) ; correct leap year
					tStamp := (A_Year + 4 - Mod(A_Year, 4)) . SubStr(tStamp, 5)
				else if (!IsSet(months) && days > 29) ; correct possible month error. no need for mod, since dec has 31 days
					tStamp := SubStr(tStamp 1, 4) . tf(A_MM + 1) . SubStr(tStamp, 7)
				if (!IsTime(tStamp))
					throw(ValueError("Invalid date specified."))
			}
			if (DateDiff(tStamp, Now, "S") >= 0)
				return tStamp
			; this case is ONLY for when year is in the present AND there is no gap present (if year is in the future, datediff must be positive.)
			if (paramInfo.after < 6) ; populate unset vars with current time before giving up
				return nextMatchingTime(years, months ?? A_MM, days ?? A_DD, hours ?? A_Hour, minutes ?? A_Min, seconds ?? A_Sec)
			return 0 ; a year in the past will never occur again
		case 2:
			if (tf(months) == A_MM && paramInfo.gap) {
				tStamp := nextMatchingTime(, , days?, hours?, minutes?, seconds?)
				return parseTime(tStamp, "Mo") == tf(months) ? tStamp : DateAddW(tStamp, 1, "Y")
			}
			tStamp := A_Year tf(months) tf(days ?? 1) tf(hours ?? 0) tf(minutes ?? 0) tf(seconds ?? 0)
			if (!IsTime(tStamp)) {
				if (tf(months) == "02" && IsSet(days) && days == 29) ; leap year
					tStamp := (A_Year + 4 - Mod(A_Year, 4)) . SubStr(tStamp, 5)
				if (!IsTime(tStamp))
					throw(ValueError("Invalid date specified."))
			}
			if (DateDiff(tStamp, Now, "S") >= 0)
				return tStamp
			if (paramInfo.after < 6)
				return nextMatchingTime(, months, days ?? A_DD, hours ?? A_Hour, minutes ?? A_Min, seconds ?? A_Sec)
			return DateAddW(tStamp, 1, "Y")
		case 3:
			if (days == A_DD && paramInfo.gap) {
				tStamp := nextMatchingTime(, , , hours?, minutes?, seconds?)
				return (parseTime(tStamp, "D") == days) ? tStamp : DateAddW(tStamp, 1, "Mo")
			}
			tStamp := SubStr(Now, 1, 6) tf(days) tf(hours ?? 0) tf(minutes ?? 0) tf(seconds ?? 0)
			if (!IsTime(tStamp)) {
				if (A_MM == 02 && days == 29) ; leap year
					tStamp := (A_Year + 4 - Mod(A_Year, 4)) . SubStr(tStamp, 5)
				else if (days > 29) ; correct possible month error. no need for mod, since dec has 31 days
					tStamp := SubStr(tStamp 1, 4) . tf(A_MM + 1) . SubStr(tStamp, 7)
				if (!IsTime(tStamp))
					throw(ValueError("Invalid date specified."))
			}
			if (DateDiff(tStamp, Now, "S") >= 0)
				return tStamp
			if (paramInfo.after < 6)
				return nextMatchingTime(, , days, hours ?? A_Hour, minutes ?? A_Min, seconds ?? A_Sec)
			return DateAddW(tStamp, 1, "Mo")
		case 4:
			if (tf(hours) == A_Hour && paramInfo.gap) {
				tStamp := nextMatchingTime(, , , , minutes?, seconds?)
				return (parseTime(tStamp, "H") == tf(hours)) ? tStamp : DateAddW(tStamp, 1, "D")
			}
			tStamp := SubStr(Now, 1, 8) tf(hours) tf(minutes ?? 0) tf(seconds ?? 0)
			if (DateDiff(tStamp, Now, "S") >= 0)
				return tStamp
			if (paramInfo.after < 6)
				return nextMatchingTime(, , , hours, minutes ?? A_Min, seconds ?? A_Sec)
			return DateAddW(tStamp, 1, "D")
		case 5:
			if (tf(minutes) == A_Min) {
				tStamp := nextMatchingTime(, , , , , seconds?)
				return parseTime(tStamp, "M") == tf(minutes) ? tStamp : 0
			}
			tStamp := SubStr(Now, 1, 10) . tf(minutes) . tf(seconds ?? 0)
			if (DateDiff(tStamp, Now, "S") >= 0)
				return tStamp
			if (paramInfo.after < 6)
				return nextMatchingTime(, , , , minutes, seconds ?? A_Sec)
			return DateAddW(tStamp, 1, "H")
		case 6:
			tStamp := SubStr(Now, 1, 12) . tf(seconds)
			if (DateDiff(tStamp, Now, "S") >= 0)
				return tStamp
			return DateAddW(tStamp, 1, "M")
	}
	tf(n) => Format("{:02}", n)

	gap(y?, mo?, d?, h?, m?, s?) {
		mapA := Map(1, y?, 2, mo?, 3, d?, 4, h?, 5, m?, 6, s?)
		first := 0, last := 0
		for i, e in mapA {
			if (A_Index == 1)
				first := i
			last := i
			if (first + A_Index - 1 != i)
				return { first: first, after: last, gap: true }
		}
		return {first: first, after: last, gap: false}
	}
}

/**
 * Given a timestamp and a time interval, adds time interval to [time] until the new timestamp is in the future. If [time] is already in the future, returns it.
 * @param time 
 * @param intervalAmount 
 * @param intervalUnit 
 */
getNextPeriodicTimestamp(time, intervalLength, intervalUnit) {
	if (!IsTime(time))
		throw(ValueError("Invalid Timestamp"))
	intervalUnit := validateTimeUnit(intervalUnit)
	Now := A_Now
	secsDiff := DateDiff(Now, time, "Seconds")
	if secsDiff < 0
		return time
	if intervalLength <= 0
		throw ValueError("Huh")
	switch intervalUnit, 0 {
		case "Seconds", "Minutes", "Hours", "Days", "Weeks":
			intervalLengthSecs := convertToSeconds(intervalLength, intervalUnit)
			secsSinceLastInterval := Mod(secsDiff, intervalLengthSecs)
			secsSinceLastInterval := secsSinceLastInterval > 0 ? secsSinceLastInterval : intervalLengthSecs 
			time := DateAddW(time, secsDiff + intervalLengthSecs - secsSinceLastInterval, "Seconds")
			if (DateDiff(time, Now, "Seconds") < 0)
				time := DateAddW(time, intervalLength, "Seconds")
		case "Months", "Years":
			unitDiff := parseTime(Now, intervalUnit) - parseTime(time, intervalUnit)
			if (intervalUnit == "Months")
				unitDiff += (parseTime(Now, "Years") - parseTime(time, "Years")) * 12
			unitsSinceLastInterval := Mod(unitDiff, intervalLength)
			unitsSinceLastInterval := unitsSinceLastInterval > 0 ? unitsSinceLastInterval : intervalLength
			time := DateAddW(time, unitDiff + intervalLength - unitsSinceLastInterval, intervalUnit)
			if (DateDiff(time, Now, "Seconds") < 0)
				time := DateAddW(time, intervalLength, intervalUnit)
	}
	return time
}

/**
 * Given a timestamp and a unit, returns that value for the respective unit
 * @param time 
 * @param timeUnit
 * @returns {Integer}
 */
parseTime(time, timeUnit) {
	if (!IsTime(time))
		throw(ValueError("Invalid Timestamp"))
	timeUnit := validateTimeUnit(timeUnit)
	switch timeUnit {
		case "Seconds":
			return Integer(FormatTime(time, "s"))
		case "Minutes":
			return Integer(FormatTime(time, "m"))
		case "Hours":
			return Integer(FormatTime(time, "H"))
		case "Days":
			return Integer(FormatTime(time, "d"))
		case "Months":
			return Integer(FormatTime(time, "M"))
		case "Years":
			return Integer(FormatTime(time, "yyyy"))
		case "Weeks":
			return Integer(SubStr(FormatTime(time, "YWeek"), 5, 2))
		case "YDay":
			return Integer(FormatTime(time, "YDay"))
	}
}

enumerateDay(day) { ; sunday == 1 because WDay uses 1 for sunday.
	d := Substr(day, 1, 2)
	switch d, 0 {
		case "mo":
			day := 2
		case "di", "tu":
			day := 3
		case "mi", "we":
			day := 4
		case "do", "th":
			day := 5
		case "fr":
			day := 6
		case "sa":
			day := 7
		case "so", "su":
			day := 1
		default:
			return -1
	}
	return A_DD - A_WDAY + day
}

validateTimeUnit(timeUnit) {
	switch timeUnit, 0 {
		case "S", "Sec", "Secs", "Second", "Seconds":
			timeUnit := "Seconds"
		case "M", "Min", "Mins", "Minute", "Minutes":
			timeUnit := "Minutes"
		case "H", "Hr", "Hrs", "Hour", "Hours":
			timeUnit := "Hours"
		case "D", "Day", "Days":
			timeUnit := "Days"
		case "W", "Wk", "Wks", "Week", "Weeks":
			timeUnit := "Weeks"
		case "Mo", "Month", "Months":
			timeUnit := "Months"
		case "Y", "A", "Yr", "Yrs", "Year", "Years":
			timeUnit := "Years"
		case "YDay":
			timeUnit := "YDay"
		default:
			throw(Error("Invalid Period Unit: " . timeUnit))
	}
	return timeUnit
}

convertToSeconds(amount, unit) {
	if (amount < 0)
		return -1 * DateDiffW(DateAddW("1601", amount * -1, unit), "1601", "Seconds")
	return DateDiffW(DateAddW("1601", amount, unit), "1601", "Seconds")	
}

randomTime(timestamp1 := "16010101000000", timestamp2 := A_Now) {
	r := Random(0, DateDiff(timestamp2, timestamp1, "Seconds"))
	return DateAdd(timestamp1, r, "Seconds")
}

class WinUtilities {
	static __New() {
		this.windowCache := Map()
		this.monitorCache := Map()
	}
	
	static getAllWindowInfo(getHidden := false, blacklist := this.defaultBlacklist, getCommandLine := false) {
		windows := []
		dHW := A_DetectHiddenWindows
		DetectHiddenWindows(getHidden)
		wHandles := WinGetList()
		for wHandle in wHandles {
			if !this.winInBlacklist(wHandle, blacklist) {
				windows.push(this.getWindowInfo(wHandle, getCommandLine))
			}
		}
		DetectHiddenWindows(dHW)
		return windows
	}

	static winInBlacklist(wHandle, blacklist := this.defaultBlacklist) {
		for e in blacklist
			if ((e != "" && WinExist(e " ahk_id " wHandle)) || (e == "" && WinGetTitle(wHandle) == ""))
				return 1
		return 0
	}

	/**
	 * Gets window Info and optionally updates the cache with unchanging information.
	 * @param hwnd 
	 * @param {Integer} getCommandline 
	 * @param {Integer} updateCache 
	 * @returns {Object | Any} An object of the following form
	 * @example 
	 * obj := {
	 *		hwnd ; window handle (STATIC)
	 *		title ; window title
	 *		class ; ahk_class (STATIC)
	 *		state ; mmx: 1 maximized, 0 restored, -1 minimized 
	 *		minX, minY, maxX, maxY ; x and y position while the window is min-/maximized (STATIC)
	 *		minW, minH, maxW, maxH ; min-/maximum width and height to which the window can be resized (STATIC)
	 *		xpos, ypos, width, height ; the current x, y, w, h values of the window
	 *		res_xpos, res_ypos, res_width, res_height ; x, y, w, h of the window if it were restored
	 *		clientxpos, clientypos, clientwidth, clientheight ; x, y, w, h of the client area of the window
	 *		flags ; behaviour of the window while minimized (STATIC)
	 *		pid ; process ID (STATIC)
	 *		process ; process name (STATIC)
	 *		processPath ; process path (STATIC)
	 *		commandLine ; command line (if requested, otherwise blank) (STATIC)
	 *		triedCommandline ; whether getWindowInfo tried retrieving the command line. This is relevant for caching.
	 * }
	 */
	static getWindowInfo(hwnd, getCommandline := false, updateCache := true) {
		x := y := w := h := cx := cy := cw := ch := rx := ry := rw := rh := minX := minY := maxX := maxY := ""
		flags := mmx := winTitle := ""
		if !WinExist(hwnd) {
			return {}
		}
		try	winTitle := WinGetTitle(hwnd)
		try	WinGetPos(&x, &y, &w, &h, hwnd)
		try {
			wInfo := this.getWindowPlacement(hwnd) ; why duplicate data? getwindowplacement can throw an error
			rx := wInfo.x, ry := wInfo.y, rw := wInfo.w, rh := wInfo.h
			mmx := wInfo.mmx, flags := wInfo.flags
			minX := wInfo.minX, minY := wInfo.minY, maxX := wInfo.maxX, maxY := wInfo.maxY
		}
		try WinGetClientPos(&cx, &cy, &cw, &ch, hwnd)
		info := {
			title: winTitle,
			state: mmx,
			flags: flags,

			xpos: x, ypos: y,
			width: w, height: h,
			res_xpos: rx, res_ypos: ry,
			res_width: rw, res_height: rh,

			clientxpos: cx, clientypos: cy,
			clientwidth: cw, clientheight: ch,

			minX: minX, minY: minY,
			maxX: maxX, maxY: maxY
		}
		if !updateCache
			cacheObj := info
		else {
			cacheObj := this.updateSingleCache(hwnd, getCommandline)
			objMerge(cacheObj, info, false, true)
		}
		return cacheObj
	}

	static updateCache(getHidden := false, blacklist := this.defaultBlacklist, getCommandLine := false) {
		dHW := A_DetectHiddenWindows
		DetectHiddenWindows(getHidden)
		wHandles := WinGetList()
		for i, wHandle in wHandles {
			for e in blacklist
				if ((e != "" && WinExist(e " ahk_id " wHandle)) || (e == "" && WinGetTitle(wHandle) == ""))
					continue 2
			this.updateSingleCache(wHandle, getCommandLine)
		}
		DetectHiddenWindows(dHW)
	}

	static updateSingleCache(hwnd, getCommandLine) {
		winClass := processName := processPath := pid := cmdLine := ""
		minW := minH := maxW := maxH := ""
		triedCommandline := false
		if (this.windowCache.Has(hwnd)) {
			if getCommandLine && !this.windowCache[hwnd].triedCommandline {
				try this.windowCache[hwnd].commandLine := this.winmgmt("CommandLine", "Where ProcessId = " this.windowCache[hwnd].pid)[1]
				this.windowCache[hwnd].triedCommandline := true
			}
		} 
		else {
			try	winClass := WinGetClass(hwnd)
			try	processName := WinGetProcessName(hwnd)
			try	processPath := WinGetProcessPath(hwnd)
			try	pid := WinGetPID(hwnd)
			try minMax := WinUtilities.getMinMaxResizeCoords(hwnd)
			try minW := minMax.minW, minH := minMax.minH, maxW := minMax.maxW, maxH := minMax.maxH
			if (getCommandLine) {
				try cmdLine := this.winmgmt("CommandLine", "Where ProcessId = " pid)[1]
				triedCommandline := true
			}
			this.windowCache[hwnd] := {
				hwnd: hwnd, class: winClass, process: processName, processPath: processPath, 
				pid: pid, minW: minW, minH: minH, maxW: maxW, maxH: MaxH,
				commandLine: cmdLine, triedCommandline: triedCommandline
			}
		}
		return this.windowCache[hwnd]
	}

	static winmgmt(selector?, selection?, d := "Win32_Process", m := "winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2") {
		local i, s := []
		for i in ComObjGet(m).ExecQuery("Select " . (selector ?? "*") . " from " . d . (IsSet(selection) ? " " . selection : ""))
			s.push(i.%selector%)
		return (s.length > 0 ? s : [""])
	}

	static isVisible(wHandle) {
		return WinGetStyle(wHandle) & this.STYLES.WS_VISIBLE
	}

	static isBorderlessFullscreen(wHandle) {
		WinGetPos(&x, &y, &w, &h, wHandle)
		WinGetClientPos(&cx, &cy, &cw, &ch, wHandle)
		mHandle := DllCall("MonitorFromWindow", "Ptr", wHandle, "UInt", 0x2, "Ptr")
		mon := this.monitorGetInfo(mHandle)
		if (mon.left == cx && mon.top == cy && mon.right == mon.left + cw && mon.bottom == mon.top + ch)
			return true
		else 
			return false
	}

	static borderlessFullscreenWindow(wHandle) {
		WinGetPos(&x, &y, &w, &h, wHandle)
		WinGetClientPos(&cx, &cy, &cw, &ch, wHandle)
		mHandle := DllCall("MonitorFromWindow", "Ptr", wHandle, "UInt", 0x2, "Ptr")
		monitor := this.monitorGetInfo(mHandle)
		WinMove(
			monitor.left + (x - cx),
			monitor.top + (y - cy),
			monitor.right - monitor.left + (w - cw),
			monitor.bottom - monitor.top + (h - ch),
			wHandle
		)
		WinGetPos(&x, &y, &w, &h, wHandle)
		WinGetClientPos(&cx, &cy, &cw, &ch, wHandle)
		monitor := this.monitorGetInfoFromWindow(wHandle)
		WinMove(
			monitor.left + (x - cx),
			monitor.top + (y - cy),
			monitor.right - monitor.left + (w - cw),
			monitor.bottom - monitor.top + (h - ch),
			wHandle
		)
	}

	/**
	 * Originally written by https://www.autohotkey.com/boards/viewtopic.php?f=6&t=3392
	 */
	static WinGetPosEx(hwnd) {
		static S_OK := 0x0
		static DWMWA_EXTENDED_FRAME_BOUNDS := 9
		rect := Buffer(16, 0)
		rectExt := Buffer(24, 0)
		DllCall("GetWindowRect", "Ptr", hwnd, "Ptr", rect)
		try 
			DWMRC := DllCall("dwmapi\DwmGetWindowAttribute", "Ptr",  hwnd, "UInt", DWMWA_EXTENDED_FRAME_BOUNDS, "Ptr", rectExt, "UInt", 16, "UInt")
		catch
			return 0
		L := NumGet(rectExt,  0, "Int")
		T := NumGet(rectExt,  4, "Int")
		R := NumGet(rectExt,  8, "Int")
		B := NumGet(rectExt, 12, "Int")
		leftBorder		:= L - NumGet(rect,  0, "Int")
		topBorder		:= T - NumGet(rect,  4, "Int")
		rightBorder		:= 	   NumGet(rect,  8, "Int") - R
		bottomBorder	:= 	   NumGet(rect, 12, "Int") - B
		return { x: L, y: T, w: R - L, h: B - T, LB: leftBorder, TB: topBorder, RB: rightBorder, BB: bottomBorder}
	}

	static WinMoveEx(hwnd, x?, y?, width?, height?) {
		if pos := this.WinGetPosEx(hwnd) {
			if IsSet(x)
				x -= pos.LB
			if IsSet(y)
				y -= pos.TB
			if IsSet(width)
				width += pos.LB + pos.RB
			if IsSet(height)
				height += pos.TB + pos.BB
		}
		WinMove(x?, y?, Width?, Height?, hwnd)
	}


	/**
	 * Retrieves coordinates of window of restored state even if it is maximized or minimized
	 * @param hwnd 
	 * @returns {Object} 
	 */
	static getWindowPlacement(hwnd, withClientPos := false) {
		NumPut("Uint", 44, pos := Buffer(44, 0))
		DllCall("GetWindowPlacement", "Ptr", hwnd, "Ptr", pos)
		flags := NumGet(pos, 4, "Int")  ; flags on behaviour while minimized (irrelevant)
		mmx   := NumGet(pos, 8, "Int") ; ShowCMD
		; see https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-showwindow
		switch mmx {
			case 0, 1, 4, 5, 7, 8, 9, 10:
				mmx := 0
			case 2, 6, 11:
				mmx := -1
			case 3:
				mmx := 1
		}
		; coordinates of top left corner when window is in corresponding state
		minimizedX := NumGet(pos, 12, "Int")
		minimizedY := NumGet(pos, 16, "Int")
		maximizedX := NumGet(pos, 20, "Int")
		maximizedY := NumGet(pos, 24, "Int")
		
		x := NumGet(pos, 28, "Int")        ; X coordinate of the upper-left corner of the window in its original restored state
		y := NumGet(pos, 32, "Int")        ; Y coordinate of the upper-left corner of the window in its original restored state
		w := NumGet(pos, 36, "Int") - x   ; Width of the window in its original restored state
		h := NumGet(pos, 40, "Int") - y   ; Height of the window in its original restored state
		placementData := { x: x, y: y, w: w, h: h, mmx: mmx, flags: flags, minX: minimizedX, minY: minimizedY, maxX: maximizedX, maxY: maximizedY }
		if withClientPos {
			cpl := this.getWindowClientPlacement(hwnd)
			placementData.cw := cpl.cw
			placementData.ch := cpl.ch
		}
		return placementData
	}

	static getWindowClientPlacement(hwnd) {
		clientRect := Buffer(16)
		DllCall("GetClientRect", "uint", hwnd, "Ptr", clientRect)
		; 0, 4 (top and left) are 0.
		return { cw: NumGet(clientRect, 8, "int"), ch: NumGet(clientRect, 12, "int") }
	}
	
	static setWindowPlacement(hwnd := "", x := "", y := "", w := "", h := "", action := 9) {
		NumPut("Uint", 44, pos := Buffer(44, 0))
		DllCall("User32.dll\GetWindowPlacement", "Ptr", hwnd, "Ptr", pos)
		rx := NumGet(pos, 28, "Int")
		rt := NumGet(pos, 32, "Int")
		rw := NumGet(pos, 36, "Int") - rx
		rh := NumGet(pos, 40, "Int") - rt
		left := x = "" ? rx : x
		top := y = "" ? rt : y
		right := left + (w = "" ? rw : w)
		bot := top + (h = "" ? rh : h)

		NumPut("UInt", action, pos, 8)
		NumPut("UInt", left, pos, 28)
		NumPut("UInt", top, pos, 32)
		NumPut("UInt", right, pos, 36)
		NumPut("UInt", bot, pos, 40)

		return DllCall("User32.dll\SetWindowPlacement", "Ptr", hwnd, "Ptr", pos)
	}

	static getMinMaxResizeCoords(hwnd) {
		static WM_GETMINMAXINFO := 0x24
		static SM_CXMINTRACK := 34, SM_CYMINTRACK := 35, SM_CXMAXTRACK := 59, SM_CYMAXTRACK := 60
		static sysMinWidth := SysGet(SM_CXMINTRACK), sysMinHeight := SysGet(SM_CYMINTRACK)
		static sysMaxWidth := SysGet(SM_CXMAXTRACK), sysMaxHeight := SysGet(SM_CYMAXTRACK)
		MINMAXINFO := Buffer(40, 0)
		SendMessage(WM_GETMINMAXINFO, , MINMAXINFO, , hwnd)
		minWidth  := NumGet(MINMAXINFO, 24, "Int")
		minHeight := NumGet(MINMAXINFO, 28, "Int")
		maxWidth  := NumGet(MINMAXINFO, 32, "Int")
		maxHeight := NumGet(MINMAXINFO, 36, "Int")
		
		minWidth  := Max(minWidth, sysMinWidth)
		minHeight := Max(minHeight, sysMinHeight)
		maxWidth  := Max(maxWidth, sysMaxWidth)
		maxHeight := Max(maxHeight, sysMaxHeight)
		return { minW: minWidth, minH: minHeight, maxW: maxWidth, maxH: maxHeight }
	}

	static resetWindowPosition(wHandle := Winexist("A"), sizePercentage?, monitorNum?) {
		if (IsSet(monitorNum)) {
			MonitorGetWorkArea(monitorNum, &left, &top, &right, &bot)
		} else {
			monitor := this.monitorGetInfoFromWindow(wHandle)
			left := monitor.wLeft, right := monitor.wRight, top := monitor.wTop, bot := monitor.wBottom
		}
		mWidth := right - left, mHeight := bot - top
		WinRestore(wHandle)
		WinGetPos(&x, &y, &w, &h, wHandle)
		if (IsSet(sizePercentage))
			WinMove(
				left + mWidth / 2 * (1 - sizePercentage), ; left edge of screen + half the width of it - half the width of the window, to center it.
				top + mHeight / 2 * (1 - sizePercentage),  ; same as above but with top bottom
				mWidth * sizePercentage,
				mHeight * sizePercentage,
				wHandle
			)
		else
			WinMove(
				left + mWidth / 2 - w / 2, 
				top + mHeight / 2 - h / 2, , , wHandle
			)
	}

	static monitorGetAll(cache := true) {
		static callback := CallbackCreate(enumProc, 'Fast')
		monitors := Map()
		if !DllCall("EnumDisplayMonitors", "Ptr", 0, "Ptr", 0, "Ptr", callback, "Ptr", 0)
			return 0
		if cache
			for mHandle, monitor in monitors
				if !this.monitorCache.Has(mHandle)
					this.monitorCache[mHandle] := monitor
		return monitors

		enumProc(monitorHandle, HDC, PRECT, *) {
			monitors[monitorHandle] := this.monitorGetInfo(monitorHandle, false)
			return true
		}
	}

	static monitorGetHandleFromWindow(wHandle) => DllCall("MonitorFromWindow", "Ptr", wHandle, "UInt", 0x2, "Ptr")

	static monitorGetInfoFromWindow(wHandle, cache := true) {
		monitorHandle := this.monitorGetHandleFromWindow(wHandle)
		return this.monitorGetInfo(monitorHandle, cache)
	}

	static monitorGetHandleFromPoint(x?, y?) {
		static MONITOR_DEFAULTTONULL := 0x0
		point := Buffer(8, 0)
		if IsSet(x) || !IsSet(y) {
			DllCall("GetCursorPos", "Ptr", point)
			x := x ?? NumGet(point, 0, "Int")
			y := y ?? NumGet(point, 4, "Int")
		}
		NumPut("Int", x, "Int", y, point)
		return DllCall("MonitorFromPoint", "Ptr", point, "UInt", MONITOR_DEFAULTTONULL, "Ptr")
	}

	static monitorGetInfoFromPoint(x?, y?, cache := true) {
		if !(monitorHandle := this.monitorGetHandleFromPoint(x?, y?))
			return 0
		return this.monitorGetInfo(monitorHandle, cache)
	}

	static monitorGetHandleFromRect(x,y,w,h) {
		static MONITOR_DEFAULTTONULL := 0x0
		rect := Buffer(16, 0)
		NumPut("Int", x, "Int", y, "Int", x+w, "Int", y+h, rect)
		return DllCall("MonitorFromRect", "Ptr", rect, "UInt", MONITOR_DEFAULTTONULL, "Uptr")
	}

	static monitorGetInfoFromRect(x, y, w, h, cache := true) {
		if !(monitorHandle := this.monitorGetHandleFromRect(x,y,w,h))
			return 0
		return this.monitorGetInfo(monitorHandle, cache)
	}

	static monitorGetInfo(monitorHandle, cache := true) {
		if cache && this.monitorCache.Has(monitorHandle)
			return this.monitorCache[monitorHandle]
		NumPut("Uint", 40 + 64, monitorInfo := Buffer(40 + 64))
		DllCall("GetMonitorInfo", "Ptr", monitorHandle, "Ptr", monitorInfo)
		monitor := {
			left:		NumGet(monitorInfo, 4, "Int"),
			top:		NumGet(monitorInfo, 8, "Int"),
			right:		NumGet(monitorInfo, 12, "Int"),
			bottom:		NumGet(monitorInfo, 16, "Int"),
			wLeft:		NumGet(monitorInfo, 20, "Int"),
			wTop:		NumGet(monitorInfo, 24, "Int"),
			wRight:		NumGet(monitorInfo, 28, "Int"),
			wBottom:	NumGet(monitorInfo, 32, "Int"),
			primary:	NumGet(monitorInfo, 36, "UInt"), ; flag can be MONITORINFOF_PRIMARY (1) or not (0)
			name:		name := StrGet(monitorInfo.Ptr + 40),
			num:		RegExReplace(name, ".*(\d+)$", "$1")
		}
		if cache
			this.monitorCache[monitorHandle] := monitor
		return monitor
	}

	static monitorIsPrimary(monitorHandle, useCache := true) => this.monitorGetInfo(monitorHandle, useCache).flag

	static defaultBlacklist => [
		"",
		"NVIDIA GeForce Overlay",
		"ahk_class MultitaskingViewFrame ahk_exe explorer.exe",
		"ahk_class Windows.UI.Core.CoreWindow",
		"ahk_class WorkerW ahk_exe explorer.exe",
		"ahk_class Progman ahk_exe explorer.exe",
		"ahk_class Shell_TrayWnd ahk_exe explorer.exe",
		"ahk_class Shell_SecondaryTrayWnd ahk_exe explorer.exe",
		; "Microsoft Text Input Application",
		; "Default IME",
		; "MSCTFIME UI"
	]

	static STYLES := {
		WS_OVERLAPPED: 0x00000000,
		WS_POPUP: 0x80000000,
		WS_CHILD: 0x40000000,
		WS_MINIMIZE: 0x20000000,
		WS_VISIBLE: 0x10000000,
		WS_DISABLED: 0x08000000,
		WS_CLIPSIBLINGS: 0x04000000,
		WS_CLIPCHILDREN: 0x02000000,
		WS_MAXIMIZE: 0x01000000,
		WS_CAPTION: 0x00C00000,
		WS_BORDER: 0x00800000,
		WS_DLGFRAME: 0x00400000,
		WS_VSCROLL: 0x00200000,
		WS_HSCROLL: 0x00100000,
		WS_SYSMENU: 0x00080000,
		WS_THICKFRAME: 0x00040000,
		WS_GROUP: 0x00020000,
		WS_TABSTOP: 0x00010000,
		WS_MINIMIZEBOX: 0x00020000,
		WS_MAXIMIZEBOX: 0x00010000,
		WS_TILED: 0x00000000,
		WS_ICONIC: 0x20000000,
		WS_SIZEBOX: 0x00040000,
		WS_OVERLAPPEDWINDOW: 0x00CF0000,
		WS_POPUPWINDOW: 0x80880000,
		WS_CHILDWINDOW: 0x40000000,
		WS_TILEDWINDOW: 0x00CF0000,
		WS_ACTIVECAPTION: 0x00000001,
		WS_GT: 0x00030000 
	}

	static EXSTYLES := {
		WS_EX_DLGMODALFRAME: 0x00000001,
		WS_EX_NOPARENTNOTIFY: 0x00000004,
		WS_EX_TOPMOST: 0x00000008,
		WS_EX_ACCEPTFILES: 0x00000010,
		WS_EX_TRANSPARENT: 0x00000020,
		WS_EX_MDICHILD: 0x00000040,
		WS_EX_TOOLWINDOW: 0x00000080,
		WS_EX_WINDOWEDGE: 0x00000100,
		WS_EX_CLIENTEDGE: 0x00000200,
		WS_EX_CONTEXTHELP: 0x00000400,
		WS_EX_RIGHT: 0x00001000,
		WS_EX_LEFT: 0x00000000,
		WS_EX_RTLREADING: 0x00002000,
		WS_EX_LTRREADING: 0x00000000,
		WS_EX_LEFTSCROLLBAR: 0x00004000,
		WS_EX_CONTROLPARENT: 0x00010000,
		WS_EX_STATICEDGE: 0x00020000,
		WS_EX_APPWINDOW: 0x00040000,
		WS_EX_OVERLAPPEDWINDOW: 0x00000300,
		WS_EX_PALETTEWINDOW: 0x00000188,
		WS_EX_LAYERED: 0x00080000,
		WS_EX_NOINHERITLAYOUT: 0x00100000,
		WS_EX_NOREDIRECTIONBITMAP: 0x00200000,
		WS_EX_LAYOUTRTL: 0x00400000,
		WS_EX_COMPOSITED: 0x02000000,
		WS_EX_NOACTIVATE: 0x08000000 
	}
}

class ShellWrapper {
	static shell := ComObject("Shell.Application")
	
	static IEObjectGetLocationURL(IEObject) {
		; https://learn.microsoft.com/en-us/previous-versions/windows/internet-explorer/ie-developer/platform-apis/aa752084(v=vs.85)
		; formatted file:///c:/users....
		return IEObject.LocationURL
	}

	static getExplorerSelfPath(IEObject) {
		; https://learn.microsoft.com/en-us/previous-versions/windows/internet-explorer/ie-developer/platform-apis/aa752084(v=vs.85)
		return IEObject.document.folder.self.path
	}

	static getExplorerIEObject(hwnd) {
		for e in this.shell.Windows()
			if e.hwnd == hwnd
				return e
		return 0
	}

	static getExplorerIEObjects() {
		return objFlatten(this.shell.windows(),, true)
	}

	static Explore(path) {
		this.shell.Explore(path)
	}

	static navigateExplorer(hwnd, path) {
		if shell := this.getExplorerIEObject(hwnd)
			shell.Navigate(path)
	}
}
; given two folders, compares files and removes duplicates based on size + name, keeping files in folder 1

/**
 * Gets Specified Files in a folder as an array of filenames (if short) or array of objects with all their associated data
 * @param folder Path to a folder
 * @param {String} filePattern Filepattern to filter for. By default all files are included
 * @param {String} mode F,D,R (Include Files, Include Directories, Recursive.) Defaults to Files no folders no recursive
 * @param {Integer} getMode 0 = all fileinfo, 1 = only name, 2 = only full path, 3 = name, ext, namenoext, size, dir
 * @returns {Array} Array containing objects of the following type:
 * 
 * obj := { name, nameNoExt, ext, path, shortPath shortName dir, attrib, size, sizeKB, sizeMB, timeModified, timeCreated, timeAccessed }
 */
getFolderAsArr(folder, filePattern := "*", mode := 'FDR', getMode := 3, sortedBy := "name") => getFilesAsArr(folder "\" filePattern, mode, getMode, sortedBy)

getFilesAsArr(filePattern := "*", mode := 'FDR', getMode := 3, sortedBy := "name") {
	files := []
	loop files filePattern, mode {
		switch getMode {
			case 0:
				SplitPath(A_LoopFileFullPath,,,, &nameNoExt)
				files.push({
					name:			A_LoopFileName,
					nameNoExt:		nameNoExt,
					ext:			A_LoopFileExt,
					path:			A_LoopFileFullPath,
					shortPath:		A_LoopFileShortPath,
					shortName:		A_LoopFileShortName,
					dir:			A_LoopFileDir,
					attrib:			A_LoopFileAttrib,
					size:			A_LoopFileSize,
					sizeKB:			A_LoopFileSizeKB,
					sizeMB:			A_LoopFileSizeMB,
					timeModified:	A_LoopFileTimeModified,
					timeCreated:	A_LoopFileTimeCreated,
					timeAccessed:	A_LoopFileTimeAccessed
				})
			case 1:
				files.push(A_LoopFileName)
			case 2:
				files.push(A_LoopFileFullPath)
			case 3:
				SplitPath(A_LoopFileFullPath,,,, &nameNoExt)
				files.push({
					name: A_LoopFileName,
					dir: A_LoopFileDir,
					ext: A_LoopFileExt,
					nameNoExt: nameNoExt,
					size: A_LoopFileSize,
				})
		}
	}
	sorted := arraySort(files, getMode == 1 || getMode == 2 ? unset : a => a.%sortedBy%)
	return sorted
}

getFileInfo(filePath, getMode := 0) {
	path := filePath,
	size := FileGetSize(filePath)
	sizeKB := FileGetSize(filePath, "K")
	sizeMB := FileGetSize(filePath, "M")
	timeCreated := FileGetTime(filePath, 'C')
	timeModified := FileGetTime(filePath, 'M')
	timeAccessed := FileGetTime(filePath, 'A')
	attrib := FileGetAttrib(filePath)
	SplitPath(filePath, &name, &dir, &ext, &nameNoExt)
	if getMode == 0
		return {
			name:			name,
			nameNoExt:		nameNoExt,
			ext:			ext,
			path:			path,
			dir:			dir,
			attrib:			attrib,
			size:			size,
			sizeKB:			sizeKB,
			sizeMB:			sizeMB,
			timeModified:	timeModified,
			timeCreated:	timeCreated,
			timeAccessed:	timeAccessed
		}
	else
		return {
			name: A_LoopFileName,
			dir: A_LoopFileDir,
			ext: A_LoopFileExt,
			nameNoExt: nameNoExt,
			size: A_LoopFileSize,
		}
}

removeDupes(folder1, folder2) {
	count := 0
	loop files folder1 "\*", "R" {
		fName := A_LoopFileName
		fSize := A_LoopFileSize
		if (FileExist(folder2 "\" fName) && fSize == FileGetSize(folder2 "\" fName)) {
			FileDelete(folder2 "\" fName)
			count++
		}
	}
	return count
}

getFileDupes(recursive := true, caseSense := false, bySize := false, byName := true, byExt := true, grouped := true, folders*) {
	fileList := []
	mode := recursive ? 'FDR' : 'FD'
	for folder in folders
		fileList.push(getFolderAsArr(folder, , mode , 3)*)
	switch {
		case bySize && byName && byExt:
			fn := (a => (a.size "|" a.name))
		case bySize && byName && !byExt:
			fn := (a => (a.size "|" a.nameNoExt))
		case bySize && !byName && byExt:
			fn := (a => (a.size . "|" a.ext))
		case bySize && !byName && !byExt:
			fn := (a => (a.size))
		case !bySize && byName && byExt:
			fn := (a => (a.name))
		case !bySize && byName && !byExt:
			fn := (a => (a.nameNoExt))
		case !bySize && !byName && byExt:
			fn := (a => (a.ext))
		case !bySize && !byName && !byExt:
			throw(ValueError("You must compare by something"))
	}
	indices := objGetDuplicates(fileList, fn, caseSense, grouped)
	dupes := []
	for e in indices {
		if grouped
			for f in e
				dupes.push(fileList[f])
		else
			dupes.push(fileList[e])
	}
	return dupes
}

getMetadataFolder(folder, metadata := []) {
	data := []
	loop files folder . "\*", '' {
		fileData := FGP.List(A_LoopFileFullPath)
		fObj := Map()
		for e in metadata
			if fileData.has(e)
				fObj[e] := fileData[e]
		fObj["filename"] := A_LoopFileName
		data.push(fObj)
	}
	return data
}

strContainsIllegalChar(str) {
	static charMap := Map("\", "-", "/", "⧸", ":", "", "*", "＊", "?", ".", '"', "'", "<", "(", ">", ")", "|", "-")
	for i, e in charMap
		if InStr(str, i)
			return 1
	return 0
}

strReplaceIllegalChars(str, &replaceCount) {
	static charMap := Map("\", "-", "/", "⧸", ":", "", "*", "＊", "?", ".", '"', "'", "<", "(", ">", ")", "|", "-")
	total := 0
	for i, e in charMap {
		str := StrReplace(str, i, e,, &count)
		total += count
	}
	replaceCount := total
	return str
}

/**
 * Compares items in folders. optionally recursive. returns items present in folder 1 that are not present in folder 2
 * @param folder1 
 * @param folder2 
 * @returns {Map} 
 */
compareFolders(folder1, folder2, recursive := false) {
	f1exists := Map()
	changes := Map()
	loop files folder1 "\*", recursive ? 'FDR' : 'FD' {
		if !FileExist(folder2 "\" A_LoopFilename)
			changes[A_LoopFileName] := true
	}
	return changes
}

class FGP {

	static PropTable {
		get {
			if !this.HasOwnProp("_Proptable")
				this._Proptable := this.Init()
			return this._Proptable
		}
	}

	/*  FGP_Init()
	*		Gets an object containing all of the property numbers that have corresponding names.
	*		Used to initialize the other functions.
	*	Returns
	*		An object with the following format:
	*			PropTable.Name["PropName"]	:= PropNum
	*			PropTable.Num[PropNum]		:= "PropName"
	*/
	static Init() {
		if (!IsSet(PropTable)) {
			;PropTable := {Name:={},Num:={} }
			;PropTable := {{},{}}
			PropTable := { Name: Map(), Num: Map() }
			Gap := 0
			oShell := ComObject("Shell.Application")
			oFolder := oShell.NameSpace(0)
			while (Gap < 11) {
				if (PropName := oFolder.GetDetailsOf(0, A_Index - 1)) {
					PropTable.Name[PropName] := A_Index - 1
					PropTable.Num[A_Index - 1] := PropName
					;PropTable.Num.InsertAt( A_Index - 1 , PropName )
					Gap := 0
				}
				else {
					Gap++
				}
			}
		}
		return PropTable
	}


	/*  FGP_List(FilePath)
	*		Gets all of a file's non-blank properties.
	*	Parameters
	*		FilePath	- The full path of a file.
	*	Returns
	*		An object with the following format:
	*			PropList.CSV				:= "PropNum,PropName,PropVal`r`n..."
	*			PropList.Name["PropName"]	:= PropVal
	*			PropList.Num[PropNum]		:= PropVal
	*/
	static List(FilePath, asNums := false) {
		SplitPath(FilePath, &FileName, &DirPath)
		oShell := ComObject("Shell.Application")
		oFolder := oShell.NameSpace(DirPath)
		oFolderItem := oFolder.ParseName(FileName)
		PropList := Map()
		for PropNum, PropName in this.PropTable.Num
			if (PropVal := oFolder.GetDetailsOf(oFolderItem, PropNum))
				PropList[asNums ? PropNum : PropName] := PropVal
		return PropList
	}


	/*  FGP_Name(PropNum)
	*		Gets a property name based on the property number.
	*	Parameters
	*		PropNum		- The property number.
	*	Returns
	*		If succesful the file property name is returned. Otherwise:
	*		-1			- The property number does not have an associated name.
	*/
	static Name(PropNum) {
		if (this.PropTable.Num[PropNum] != "")
			return this.PropTable.Num[PropNum]
		return -1
	}


	/*  FGP_Num(PropName)
	*		Gets a property number based on the property name.
	*	Parameters
	*		PropName	- The property name.
	*	Returns
	*		If succesful the file property number is returned. Otherwise:
	*		-1			- The property name does not have an associated number.
	*/
	static Num(PropName) {
		if (this.PropTable.Name[PropName] != "")
			return this.PropTable.Name[PropName]
		return -1
	}


	/*  FGP_Value(FilePath, Property)
	*		Gets a file property value.
	*	Parameters
	*		FilePath	- The full path of a file.
	*		Property	- Either the name or number of a property.
	*	Returns
	*		If succesful the file property value is returned. Otherwise:
	*		0			- The property is blank.
	*		-1			- The property name or number is not valid.
	*/
	static Value(FilePath, Property) {
		if ((PropNum := this.PropTable.Name.Has(Property) ? this.PropTable.Name[Property] : this.PropTable.Num[Property] ? Property : "") != "") {
			SplitPath(FilePath, &FileName, &DirPath)
			oShell := ComObject("Shell.Application")
			oFolder := oShell.NameSpace(DirPath)
			oFolderItem := oFolder.ParseName(FileName)
			if (PropVal := oFolder.GetDetailsOf(oFolderItem, PropNum))
				return PropVal
			return 0
		}
		return -1
	}
}

class unicodeData {
	
	; https://unicode-org.github.io/icu-docs/apidoc/released/icu4c/uchar_8h.html#a46c049f7988a44e14d221f68e2e63db2

	; Alias of lookup
	static charFromName(name, nameChoice := this.UCharNameChoice.U_UNICODE_CHAR_NAME, default?) => this.lookup(name, nameChoice, default?)
	; Look up character by name. If a character with the given name is found, return the corresponding character. If not found, KeyError is raised. 
	static lookup(name, nameChoice := this.UCharNameChoice.U_UNICODE_CHAR_NAME, default?) {
		this.verifyVersion()
		errorCode := 0
		nameBuf := Buffer(StrPut(name, "UTF-8"))
		StrPut(name, nameBuf, "UTF-8")
		codePoint := DllCall("icuuc\u_charFromName", "int", nameChoice, "Ptr", nameBuf, "int*", &errorCode)
		switch errorCode {
			case this.UErrorCode.U_ZERO_ERROR:
				return Chr(codePoint)
			case this.UErrorCode.U_ILLEGAL_CHAR_FOUND:
				if (IsSet(default))
					return default
				throw ValueError("Invalid name given: " name)
			default:
				throw(OSError("u_charName returned Error " errorCode))
		}
	}

	; Returns the name assigned to the character char as a string.
	static charName(char, nameChoice := this.UCharNameChoice.U_UNICODE_CHAR_NAME) {
		this.verifyVersion()
		name := Buffer(512)
		errorCode := 0
		length := DllCall("icuuc\u_charName", "uchar", Ord(char), "int", nameChoice, "Ptr", name, "int", name.Size, "int*", &errorCode)
		switch errorCode {
			case this.UErrorCode.U_ZERO_ERROR:
				return StrGet(name, length, "UTF-8")
			default:
				throw(OSError("u_charName returned Error " errorCode))
		}
	}

	; Returns the general category (UCharCategory) value for the code point
	static charType(char) {
		this.verifyVersion()
		charType := DllCall("icuuc\u_charType", "uchar", Ord(char))
		return charType
	}
	
	; The version of the Unicode database used in this module. 
	static unidata_version => 0


	; Returns the decimal value assigned to the character char as integer. If no such value is defined, default is returned, or, if not given, ValueError is raised. 
	static decimal(char, default?) => 0


	; Returns the digit value assigned to the character char as integer. If no such value is defined, default is returned, or, if not given, ValueError is raised. 
	static digit(char, default?) => 0


	; Returns the numeric value assigned to the character char as float. If no such value is defined, default is returned, or, if not given, ValueError is raised. 
	static numeric(char, default?) => 0


	; Returns the general category assigned to the character char as string. 
	static category(char) => 0


	; Returns the bidirectional class assigned to the character char as string. If no such value is defined, an empty string is returned. 
	static bidirectional(char) => 0


	; Returns the canonical combining class assigned to the character char as integer. Returns 0 if no combining class is defined. 
	static combining(char) => 0


	; Returns the east asian width assigned to the character char as string. 
	static east_asian_width(char) => 0


	; Returns the mirrored property assigned to the character char as integer. Returns 1 if the character has been identified as a “mirrored” character in bidirectional text, 0 otherwise. 
	static mirrored(char) {
		this.verifyVersion()
		codePoint := DllCall("icuuc\u_charMirror", "uchar", Ord(char))
		return Chr(codePoint)
	}

	static pairedBracket(char) {
		this.verifyVersion()
		codePoint := DllCall("icuuc\u_getBidiPairedBracket", "uchar", Ord(char))
		return Chr(codePoint)
	}

	static enumCharNames(start, limit, fn, context, nameChoice) => 0

	; Returns the character decomposition mapping assigned to the character char as string. An empty string is returned in case no such mapping is defined. 
	static decomposition(char) => 0


	; Return the normal form form for the Unicode string unistr. Valid values for form are "C", "KC", "D", and "KD". 
	; The Unicode standard defines various normalization forms of a Unicode string, based on the definition of canonical equivalence and compatibility equivalence. In Unicode, several characters can be expressed in various way. For example, the character U+00C7 (LATIN CAPITAL LETTER C WITH CEDILLA) can also be expressed as the sequence U+0043 (LATIN CAPITAL LETTER C) U+0327 (COMBINING CEDILLA). 
	; For each character, there are two normal forms: normal form C and normal form D. Normal form D (NFD) is also known as canonical decomposition, and translates each character into its decomposed form. Normal form C (NFC) first applies a canonical decomposition, then composes pre-combined characters again. 
	; In addition to these two forms, there are two additional normal forms based on compatibility equivalence. In Unicode, certain characters are supported which normally would be unified with other characters. For example, U+2160 (ROMAN NUMERAL ONE) is really the same thing as U+0049 (LATIN CAPITAL LETTER I). However, it is supported in Unicode for compatibility with existing character sets (e.g. gb2312). 
	; The normal form KD (NFKD) will apply the compatibility decomposition, i.e. replace all compatibility characters with their equivalents. The normal form KC (NFKC) first applies the compatibility decomposition, followed by the canonical composition. 
	; Even if two unicode strings are normalized and look the same to a human reader, if one has combining characters and the other doesn’t, they may not compare equal. 
	static normalize(normForm, unistr) {
		normForm := this._getNormalizationFormFromStr(normForm)
		cwDstLength := DllCall("NormalizeString", "uint", normForm, "Str", unistr, "int", -1, "Ptr", 0, "int", 0)
		VarSetStrCapacity(&lpDstString, cwDstLength)
		writtenWChars := DllCall("NormalizeString", "int", normForm, "Str", unistr, "int", -1, "Str", &lpDstString, "int", cwDstLength)
		return lpDstString
	}


	; Return whether the Unicode string unistr is in the normal form form. Valid values for form are "C", "KC", "D", and "KD". 
	static is_normalized(normForm, uniStr) {
		normForm := this._getNormalizationFormFromStr(normForm)
		lpString := Buffer(StrPut(uniStr))
		cwLength := StrLen(uniStr)
		StrPut(uniStr, lpString)
		return DllCall("IsNormalizedString", "int", normForm, "Ptr", lpString, "int",  cwLength)
	}

	static verifyVersion() {
		if !(VerCompare(A_OSVersion, "10.0.16299"))
			throw(OSError("This function only works in windows build >= 1709"))
	}

	static _getNormalizationFormFromStr(uniStr) {
		switch unistr {
			case "C":
				return this.Normalization.NFC
			case "D":
				return this.Normalization.NFD
			case "KC":
				return this.Normalization.NFKC
			case "KD":
				return this.Normalization.NFKD
			default:
				throw ValueError("Invalid Normalization String given: " uniStr)
		}
	}

	class Wrapper {		
		; Check a binary Unicode property for a code point. Properties are listed in unicodeData.UProperty
		; Property must be UCHAR_BINARY_START<=whichUProperty<UCHAR_BINARY_LIMIT.
		static hasBinaryProperty(char, whichUProperty) {
			this.verifyVersion()
			if (whichUProperty is String)
				whichUProperty := unicodeData.UProperty.%whichUProperty%
			return DllCall("icuuc\u_hasBinaryProperty", "uchar", Ord(char), "int", whichUProperty, "char")
		}
		
		;  	Returns true if the property is true for the string. 
		static stringHasBinaryProperty(str, length, whichUProperty) {
			this.verifyVersion()
			strBuf := Buffer(StrPut(str, "UTF-8"))
			StrPut(str, strBuf, "UTF-8")
			if (whichUProperty is String)
				whichUProperty := unicodeData.UProperty.%whichUProperty%
			return DllCall("icuuc\u_stringHasBinaryProperty", "Ptr", strBuf, "int", length, "int", whichUProperty, "char")
		}
		
		;  	Returns a frozen USet for a binary property. 
		static getBinaryPropertySet(whichUProperty) {
			this.verifyVersion()
			errorCode := 0
			if (whichUProperty is String)
				whichUProperty := unicodeData.UProperty.%whichUProperty%
			ret := DllCall("icuuc\u_getBinaryPropertySet", "int", whichUProperty, "int*", &errorCode)
			switch errorCode {
				case unicodeData.UErrorCode.U_ZERO_ERROR:
					return "NOT IMPLEMENTED, ITS A USET"
				default:
					throw(OSError("getBinaryPropertySet returned Error " errorCode))
			}
		}
		
		;  	Check if a code point has the Alphabetic Unicode property. 
		static isUAlphabetic(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isUAlphabetic", "uchar", Ord(char), "char")
		}
		
		;  	Check if a code point has the Lowercase Unicode property. 
		static isULowercase(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isULowercase", "uchar", Ord(char), "char")
		}
		
		;  	Check if a code point has the Uppercase Unicode property. 
		static isUUppercase(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isUUppercase", "uchar", Ord(char), "char")
		}
		
		;  	Check if a code point has the White_Space Unicode property. 
		static isUWhiteSpace(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isUWhiteSpace", "uchar", Ord(char), "char")
		}
		
		;  	Get the property value for an enumerated or integer Unicode property for a code point. 
		static getIntPropertyValue(char, whichUProperty) {
			this.verifyVersion()
			if (whichUProperty is String)
				whichUProperty := unicodeData.UProperty.%whichUProperty%
			return DllCall("icuuc\u_getIntPropertyValue", "uchar", Ord(char), "int", whichUProperty)
		}
		
		;  	Get the minimum value for an enumerated/integer/binary Unicode property. 
		static getIntPropertyMinValue(whichUProperty) {
			this.verifyVersion()
			if (whichUProperty is String)
				whichUProperty := unicodeData.UProperty.%whichUProperty%
			return DllCall("icuuc\u_getIntPropertyMinValue", "int", whichUProperty)
		}
		
		;  	Get the maximum value for an enumerated/integer/binary Unicode property. 
		static getIntPropertyMaxValue(whichUProperty) {
			this.verifyVersion()
			if (whichUProperty is String)
				whichUProperty := unicodeData.UProperty.%whichUProperty%
			return DllCall("icuuc\u_getIntPropertyMaxValue", "int", whichUProperty)
		}
		
		;  	Returns an immutable UCPMap for an enumerated/catalog/int-valued property. 
		static getIntPropertyMap(whichUProperty) {
			this.verifyVersion()
			errorCode := 0
			if (whichUProperty is String)
				whichUProperty := unicodeData.UProperty.%whichUProperty%
			ret := DllCall("icuuc\u_getIntPropertyMap", "int", whichUProperty, "int*", &errorCode)
			switch errorCode {
				case unicodeData.UErrorCode.U_ZERO_ERROR:
					return "NOT IMPLEMENTED, IS UCPMAP"
				default:
					throw(OSError("getIntPropertyMap returned Error " errorCode))
			}
		}
		
		;  	Get the numeric value for a Unicode code point as defined in the Unicode Character Database. 
		static getNumericValue(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_getNumericValue", "uchar", Ord(char), "double")
		}
		
		;  	Determines whether the specified code point has the general category "Ll" (lowercase letter) => 0. 
		static islower(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_islower", "uchar", Ord(char), "char")
		}
		
		;  	Determines whether the specified code point has the general category "Lu" (uppercase letter) => 0. 
		static isupper(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isupper", "uchar", Ord(char), "char")
		}
		
		;  	Determines whether the specified code point is a titlecase letter. 
		static istitle(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_istitle", "uchar", Ord(char), "char")
		}
		
		;  	Determines whether the specified code point is a digit character according to Java. 
		static isdigit(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isdigit", "uchar", Ord(char), "char")
		}
		
		;  	Determines whether the specified code point is a letter character. 
		static isalpha(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isalpha", "uchar", Ord(char), "char")
		}
		
		;  	Determines whether the specified code point is an alphanumeric character (letter or digit) => 0 according to Java. 
		static isalnum(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isalnum", "uchar", Ord(char), "char")
		}
		
		;  	Determines whether the specified code point is a hexadecimal digit. 
		static isxdigit(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isxdigit", "uchar", Ord(char), "char")
		}
		
		;  	Determines whether the specified code point is a punctuation character. 
		static ispunct(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_ispunct", "uchar", Ord(char), "char")
		}
		
		;  	Determines whether the specified code point is a "graphic" character (printable, excluding spaces) => 0. 
		static isgraph(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isgraph", "uchar", Ord(char), "char")
		}
		
		;  	Determines whether the specified code point is a "blank" or "horizontal space", a character that visibly separates words on a line. 
		static isblank(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isblank", "uchar", Ord(char), "char")
		}
		
		;  	Determines whether the specified code point is "defined", which usually means that it is assigned a character. 
		static isdefined(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isdefined", "uchar", Ord(char), "char")
		}
		
		;  	Determines if the specified character is a space character or not. 
		static isspace(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isspace", "uchar", Ord(char), "char")
		}
		
		;  	Determine if the specified code point is a space character according to Java. 
		static isJavaSpaceChar(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isJavaSpaceChar", "uchar", Ord(char), "char")
		}
		
		;  	Determines if the specified code point is a whitespace character according to Java/ICU. 
		static isWhitespace(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isWhitespace", "uchar", Ord(char), "char")
		}
		
		;  	Determines whether the specified code point is a control character (as defined by this function) => 0. 
		static iscntrl(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_iscntrl", "uchar", Ord(char), "char")
		}
		
		;  	Determines whether the specified code point is an ISO control code. 
		static isISOControl(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isISOControl", "uchar", Ord(char), "char")
		}
		
		;  	Determines whether the specified code point is a printable character. 
		static isprint(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isprint", "uchar", Ord(char), "char")
		}
		
		;  	Non-standard: Determines whether the specified code point is a base character. 
		static isbase(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isbase", "uchar", Ord(char), "char")
		}
		
		;  	Returns the bidirectional category value for the code point, which is used in the Unicode bidirectional algorithm (UAX #9 http://www.unicode.org/reports/tr9/). 
		; See UCharDirection Enum
		static charDirection(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_charDirection", "uchar", Ord(char))
		}
		
		;  	Determines whether the code point has the Bidi_Mirrored property. 
		static isMirrored(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isMirrored", "uchar", Ord(char), "char")
		}
		
		;  	Maps the specified character to a "mirror-image" character. 
		static charMirror(char) {
			this.verifyVersion()
			codePoint := DllCall("icuuc\u_charMirror", "uchar", Ord(char))
			return Chr(codePoint)
		}
		
		;  	Maps the specified character to its paired bracket character. 
		static getBidiPairedBracket(char) {
			this.verifyVersion()
			codePoint := DllCall("icuuc\u_getBidiPairedBracket", "uchar", Ord(char))
			return Chr(codePoint)
		}
		
		;  	Returns the general category value for the code point. 
		static charType(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_charType", "uchar", Ord(char), "char")
		}
		
		;  	Enumerate efficiently all code points with their Unicode general categories. 
		; static enumCharTypes(UCharEnumTypeRange *enumRange, const void *context) {
		; 	this.verifyVersion()
		; 	ret := DllCall("icuuc\u_enumCharTypes")
		; }
		
		;  	Returns the combining class of the code point as specified in UnicodeData.txt. 
		static getCombiningClass(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_getCombiningClass", "uchar", Ord(char), "uchar")
		}
		
		;  	Returns the decimal digit value of a decimal digit character. 
		static charDigitValue(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_charDigitValue", "uchar", Ord(char))
		}
		
		; 	Returns the Unicode allocation block that contains the character. 
		static ublock_getCode(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_ublock_getCode ", "uchar", Ord(char))
		}

		;  	Retrieve the name of a Unicode character. 
		static charName(char, nameChoice := unicodeData.UCharNameChoice.U_UNICODE_CHAR_NAME) {
			this.verifyVersion()
			name := Buffer(512)
			errorCode := 0
			length := DllCall("icuuc\u_charName", "uchar", Ord(char), "int", nameChoice, "Ptr", name, "int", name.Size, "int*", &errorCode)
			switch errorCode {
				case unicodeData.UErrorCode.U_ZERO_ERROR:
					return StrGet(name, length, "UTF-8")
				default:
					throw(OSError("u_charName returned Error " errorCode))
			}
		}
		
		;  	Returns an empty string. 
		static getISOComment(char) {
			this.verifyVersion()
			errorCode := 0
			dest := Buffer(512)
			DllCall("icuuc\u_getISOComment", "uchar", Ord(char), "Ptr", dest, "int", dest.Size, "int*", &errorCode)
			switch errorCode {
				case unicodeData.UErrorCode.U_ZERO_ERROR:
					return StrGet(dest,, "UTF-8")
				default:
					throw(OSError("u_getISOComment returned Error " errorCode))
			}
		}
		
		;  	Find a Unicode character by its name and return its code point value. 
		static charFromName(name, nameChoice := unicodeData.UCharNameChoice.U_UNICODE_CHAR_NAME) {
			this.verifyVersion()
			errorCode := 0
			nameBuf := Buffer(StrPut(name, "UTF-8"))
			StrPut(name, nameBuf, "UTF-8")
			codePoint := DllCall("icuuc\u_charFromName", "int", nameChoice, "Ptr", name, "int*", &errorCode)
			switch errorCode {
				case unicodeData.UErrorCode.U_ZERO_ERROR:
					return Chr(codePoint)
				default:
					throw(OSError("u_charName returned Error " errorCode))
			}
		}
		
		;  	Enumerate all assigned Unicode characters between the start and limit code points (start inclusive, limit exclusive) => 0 and call a function for each, passing the code point value and the character name. 
		; static enumCharNames(start, limit, UEnumCharNamesFn *fn, void *context, nameChoice := unicodeData.UCharNameChoice.U_UNICODE_CHAR_NAME) {
		; 	this.verifyVersion()
		; 	errorCode := 0
		; 	ret := DllCall("icuuc\u_enumCharNames", "uchar", Ord(start), "uchar", Ord(limit),,, "int", nameChoice, "int*", &errorCode)
		; 	switch errorCode {
				
		; 	}
		; }
		
		;  	Return the Unicode name for a given property, as given in the Unicode database file PropertyAliases.txt. 
		static getPropertyName(whichUProperty, nameChoice := unicodeData.UPropertyNameChoice.U_LONG_PROPERTY_NAME) {
			this.verifyVersion()
			if (whichUProperty is String)
				whichUProperty := unicodeData.UProperty.%whichUProperty%
			name := DllCall("icuuc\u_getPropertyName", "int", whichUProperty, "int", nameChoice)
			return StrGet(name,, "UTF-8")
		}
		
		;  	Return the UProperty enum for a given property name, as specified in the Unicode database file PropertyAliases.txt. 
		; static getPropertyEnum(alias) {
		; 	this.verifyVersion()
		; 	aliasBuf := Buffer(StrPut(alias, "UTF-8"))
		; 	StrPut(alias, aliasBuf, "UTF-8")
		; 	ret := DllCall("icuuc\u_getPropertyEnum", "Ptr", aliasBuf)
		; }
		
		;  	Return the Unicode name for a given property value, as given in the Unicode database file PropertyValueAliases.txt. 
		static getPropertyValueName(whichUProperty, value, nameChoice := unicodeData.UPropertyNameChoice.U_LONG_PROPERTY_NAME) {
			this.verifyVersion()
			if (whichUProperty is String)
				whichUProperty := unicodeData.UProperty.%whichUProperty%
			ret := DllCall("icuuc\u_getPropertyValueName", "int", whichUProperty, "int", value, "int", nameChoice)
			return StrGet(ret,, "UTF-8")
		}
		
		;  	Return the property value integer for a given value name, as specified in the Unicode database file PropertyValueAliases.txt. 
		; static getPropertyValueEnum(whichUProperty, alias) {
		; 	this.verifyVersion()
		; 	aliasBuf := Buffer(StrPut(alias, "UTF-8"))
		; 	StrPut(alias, aliasBuf, "UTF-8")
		; 	if (whichUProperty is String)
		; 		whichUProperty := unicodeData.UProperty.%whichUProperty%
		; 	ret := DllCall("icuuc\u_getPropertyValueEnum", "int", whichUProperty, "Ptr", aliasBuf)
		; }
		
		;  	Determines if the specified character is permissible as the first character in an identifier according to UAX #31 Unicode Identifier and Pattern Syntax. 
		static isIDStart(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isIDStart", "uchar", Ord(char), "char")
		}
		
		;  	Determines if the specified character is permissible as a non-initial character of an identifier according to UAX #31 Unicode Identifier and Pattern Syntax. 
		static isIDPart(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isIDPart", "uchar", Ord(char), "char")
		}
		
		;  	Does the set of Identifier_Type values code point c contain the given type? 
		; can't find UIDentifierType enum values 
		; static hasIDType(char, type := unicodeData.UIdentifierType) {
		; 	this.verifyVersion()
		; 	return DllCall("icuuc\u_hasIDType", "uchar", Ord(char))
		; }
		
		;  	Writes code point c's Identifier_Type as a list of UIdentifierType values to the output types array and returns the number of types. 
		; can't find UIDentifierType enum values 
		; static getIDTypes(char, UIdentifierType *types, int32_t capacity) {
		; 	this.verifyVersion()
		; 	errorCode := 0
		; 	ret := DllCall("icuuc\u_getIDTypes", "uchar", Ord(char), "int*", &errorCode)
		; 	switch errorCode {
				
		; 	}
		; }
		
		;  	Determines if the specified character should be regarded as an ignorable character in an identifier, according to Java. 
		static isIDIgnorable(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isIDIgnorable", "uchar", Ord(char), "char")
		}
		
		;  	Determines if the specified character is permissible as the first character in a Java identifier. 
		static isJavaIDStart(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isJavaIDStart", "uchar", Ord(char), "char")
		}
		
		;  	Determines if the specified character is permissible in a Java identifier. 
		static isJavaIDPart(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isJavaIDPart", "uchar", Ord(char), "char")
		}
		
		;  	The given character is mapped to its lowercase equivalent according to UnicodeData.txt; if the character has no lowercase equivalent, the character itself is returned. 
		static tolower(char) {
			this.verifyVersion()
			codePoint := DllCall("icuuc\u_tolower", "uchar", Ord(char))
			return Chr(codePoint)
		}
		
		;  	The given character is mapped to its uppercase equivalent according to UnicodeData.txt; if the character has no uppercase equivalent, the character itself is returned. 
		static toupper(char) {
			this.verifyVersion()
			codePoint := DllCall("icuuc\u_toupper", "uchar", Ord(char))
			return Chr(codePoint)
		}
		
		;  	The given character is mapped to its titlecase equivalent according to UnicodeData.txt; if none is defined, the character itself is returned. 
		static totitle(char) {
			this.verifyVersion()
			codePoint := DllCall("icuuc\u_totitle", "uchar", Ord(char))
			return Chr(codePoint)
		}
		
		;  	The given character is mapped to its case folding equivalent according to UnicodeData.txt and CaseFolding.txt; if the character has no case folding equivalent, the character itself is returned. 
		; options are either U_FOLD_CASE_DEFAULT == 0 or U_FOLD_CASE_EXCLUDE_SPECIAL_I == 1
		static foldCase(char, options := unicodeData.FoldOption.U_FOLD_CASE_DEFAULT) {
			this.verifyVersion()
			codePoint := DllCall("icuuc\u_foldCase", "uchar", Ord(char), "int", options)
			return Chr(codePoint)
		}
		
		;  	Returns the decimal digit value of the code point in the specified radix. 
		static digit(char, radix) {
			this.verifyVersion()
			return DllCall("icuuc\u_digit", "uchar", Ord(char), "char", radix) ; int8 == char
		}
		
		;  	Determines the character representation for a specific digit in the specified radix. 
		static forDigit(digit, radix) {
			this.verifyVersion()
			if !(isClamped(radix, 2, 36) && isClamped(digit, 0, radix-1))
				throw(ValueError("Radix must be between 2 and 36 and digit between 0 and radix, given " radix ", " digit))
			codePoint := DllCall("icuuc\u_forDigit", "int", digit, "char", radix)
			return Chr(codePoint)
		}
		
		;  	Get the "age" of the code point. 
		static charAge(char) {
			this.verifyVersion()
			versionArray := Buffer(4)
			DllCall("icuuc\u_charAge", "uchar", Ord(char), "Ptr", versionArray)
			return [NumGet(versionArray, 0, "uchar"), NumGet(versionArray, 1, "uchar"), NumGet(versionArray, 2, "uchar"), NumGet(versionArray, 3, "uchar")]
		}
		
		;  	Gets the Unicode version information. 
		static getUnicodeVersion() {
			this.verifyVersion()
			versionArray := Buffer(4)
			DllCall("icuuc\u_getUnicodeVersion", "Ptr", versionArray)
			return [NumGet(versionArray, 0, "uchar"), NumGet(versionArray, 1, "uchar"), NumGet(versionArray, 2, "uchar"), NumGet(versionArray, 3, "uchar")]
		}
		
		;  	Get the FC_NFKC_Closure property string for a character. 
		static getFC_NFKC_Closure(char) {
			this.verifyVersion()
			errorCode := 0
			dest := Buffer(512)
			length := DllCall("icuuc\u_getFC_NFKC_Closure", "uchar", Ord(char), "Ptr", dest, "int", dest.Size, "int*", &errorCode)
			switch errorCode {
				case unicodeData.UErrorCode.U_ZERO_ERROR:
					return StrGet(dest, length, "UTF-8")
				default:
					throw(OSError("getFC_NFKC_Closure returned Error " errorCode))
			}
		}

		; alias
		static verifyVersion() => unicodeData.verifyVersion()

		
	}
	
	static Normalization => {
		NFC: 0x1, ; Unicode normalization form C, canonical composition. Transforms each decomposed grouping, consisting of a base character plus combining characters, to the canonical precomposed equivalent. For example, A + ¨ becomes Ä.
		NFD: 0x2, ; Unicode normalization form D, canonical decomposition. Transforms each precomposed character to its canonical decomposed equivalent. For example, Ä becomes A + ¨.
		NFKC: 0x5, ; Unicode normalization form KC, compatibility composition. Transforms each base plus combining characters to the canonical precomposed equivalent and all compatibility characters to their equivalents. For example, the ligature ﬁ becomes f + i; similarly, A + ¨ + ﬁ + n becomes Ä + f + i + n.
		NFKD: 0x6 ; Unicode normalization form KD, compatibility decomposition. Transforms each precomposed character to its canonical decomposed equivalent and all compatibility characters to their equivalents. For example, Ä + ﬁ + n becomes A + ¨ + f + i + n.
	}

	static FoldOption => {
		U_FOLD_CASE_DEFAULT: 0,
		U_FOLD_CASE_EXCLUDE_SPECIAL_I: 1
	}

	static U_NO_NUMERIC_VALUE => -123456789.0
	
	static UIdentifierStatus => {}

	static UIdentifierType => {}

	static UIndicConjunctBreak => {}

	static UNumericType => {
		U_NT_NONE: 0,
		U_NT_DECIMAL: 1,
		U_NT_DIGIT: 2,
		U_NT_NUMERIC: 3,
		U_NT_COUNT: 4
	}

	static UHangulSyllableType => {
		U_HST_NOT_APPLICABLE: 0,
		U_HST_LEADING_JAMO: 1,
		U_HST_VOWEL_JAMO: 2,
		U_HST_TRAILING_JAMO: 3,
		U_HST_LV_SYLLABLE: 4,
		U_HST_LVT_SYLLABLE: 5,
		U_HST_COUNT: 6
	}

	static UIndicPositionalCategory => {
		U_INPC_NA: 0,
		U_INPC_BOTTOM: 1,
		U_INPC_BOTTOM_AND_LEFT: 2,
		U_INPC_BOTTOM_AND_RIGHT: 3,
		U_INPC_LEFT: 4,
		U_INPC_LEFT_AND_RIGHT: 5,
		U_INPC_OVERSTRUCK: 6,
		U_INPC_RIGHT: 7,
		U_INPC_TOP: 8,
		U_INPC_TOP_AND_BOTTOM: 9,
		U_INPC_TOP_AND_BOTTOM_AND_RIGHT: 10,
		U_INPC_TOP_AND_LEFT: 11,
		U_INPC_TOP_AND_LEFT_AND_RIGHT: 12,
		U_INPC_TOP_AND_RIGHT: 13,
		U_INPC_VISUAL_ORDER_LEFT: 14,
		U_INPC_TOP_AND_BOTTOM_AND_LEFT: 15
	}

	static UIndicSyllabicCategory => {
		U_INSC_OTHER: 0,
		U_INSC_AVAGRAHA: 1,
		U_INSC_BINDU: 2,
		U_INSC_BRAHMI_JOINING_NUMBER: 3,
		U_INSC_CANTILLATION_MARK: 4,
		U_INSC_CONSONANT: 5,
		U_INSC_CONSONANT_DEAD: 6,
		U_INSC_CONSONANT_FINAL: 7,
		U_INSC_CONSONANT_HEAD_LETTER: 8,
		U_INSC_CONSONANT_INITIAL_POSTFIXED: 9,
		U_INSC_CONSONANT_KILLER: 10,
		U_INSC_CONSONANT_MEDIAL: 11,
		U_INSC_CONSONANT_PLACEHOLDER: 12,
		U_INSC_CONSONANT_PRECEDING_REPHA: 13,
		U_INSC_CONSONANT_PREFIXED: 14,
		U_INSC_CONSONANT_SUBJOINED: 15,
		U_INSC_CONSONANT_SUCCEEDING_REPHA: 16,
		U_INSC_CONSONANT_WITH_STACKER: 17,
		U_INSC_GEMINATION_MARK: 18,
		U_INSC_INVISIBLE_STACKER: 19,
		U_INSC_JOINER: 20,
		U_INSC_MODIFYING_LETTER: 21,
		U_INSC_NON_JOINER: 22,
		U_INSC_NUKTA: 23,
		U_INSC_NUMBER: 24,
		U_INSC_NUMBER_JOINER: 25,
		U_INSC_PURE_KILLER: 26,
		U_INSC_REGISTER_SHIFTER: 27,
		U_INSC_SYLLABLE_MODIFIER: 28,
		U_INSC_TONE_LETTER: 29,
		U_INSC_TONE_MARK: 30,
		U_INSC_VIRAMA: 31,
		U_INSC_VISARGA: 32,
		U_INSC_VOWEL: 33,
		U_INSC_VOWEL_DEPENDENT: 34,
		U_INSC_VOWEL_INDEPENDENT: 35
	}

	static UVerticalOrientation => {
		U_VO_ROTATED: 0,
		U_VO_TRANSFORMED_ROTATED: 1,
		U_VO_TRANSFORMED_UPRIGHT: 2,
		U_VO_UPRIGHT: 3
	}

	static ULineBreak => {
		U_LB_UNKNOWN: 0,
		U_LB_AMBIGUOUS: 1,
		U_LB_ALPHABETIC: 2,
		U_LB_BREAK_BOTH: 3,
		U_LB_BREAK_AFTER: 4,
		U_LB_BREAK_BEFORE: 5,
		U_LB_MANDATORY_BREAK: 6,
		U_LB_CONTINGENT_BREAK: 7,
		U_LB_CLOSE_PUNCTUATION: 8,
		U_LB_COMBINING_MARK: 9,
		U_LB_CARRIAGE_RETURN: 10,
		U_LB_EXCLAMATION: 11,
		U_LB_GLUE: 12,
		U_LB_HYPHEN: 13,
		U_LB_IDEOGRAPHIC: 14,
		U_LB_INSEPARABLE: 15,
		U_LB_INSEPERABLE: 15,
		U_LB_INFIX_NUMERIC: 16,
		U_LB_LINE_FEED: 17,
		U_LB_NONSTARTER: 18,
		U_LB_NUMERIC: 19,
		U_LB_OPEN_PUNCTUATION: 20,
		U_LB_POSTFIX_NUMERIC: 21,
		U_LB_PREFIX_NUMERIC: 22,
		U_LB_QUOTATION: 23,
		U_LB_COMPLEX_CONTEXT: 24,
		U_LB_SURROGATE: 25,
		U_LB_SPACE: 26,
		U_LB_BREAK_SYMBOLS: 27,
		U_LB_ZWSPACE: 28,
		U_LB_NEXT_LINE: 29,
		U_LB_WORD_JOINER: 30,
		U_LB_H2: 31,
		U_LB_H3: 32,
		U_LB_JL: 33,
		U_LB_JT: 34,
		U_LB_JV: 35,
		U_LB_CLOSE_PARENTHESIS: 36,
		U_LB_CONDITIONAL_JAPANESE_STARTER: 37,
		U_LB_HEBREW_LETTER: 38,
		U_LB_REGIONAL_INDICATOR: 39,
		U_LB_E_BASE: 40,
		U_LB_E_MODIFIER: 41,
		U_LB_ZWJ: 42,
		U_LB_COUNT: 40
	}
	
	static USentenceBreak => {
		U_SB_OTHER: 0,
		U_SB_ATERM: 1,
		U_SB_CLOSE: 2,
		U_SB_FORMAT: 3,
		U_SB_LOWER: 4,
		U_SB_NUMERIC: 5,
		U_SB_OLETTER: 6,
		U_SB_SEP: 7,
		U_SB_SP: 8,
		U_SB_STERM: 9,
		U_SB_UPPER: 10,
		U_SB_CR: 11,
		U_SB_EXTEND: 12,
		U_SB_LF: 13,
		U_SB_SCONTINUE: 14,
		U_SB_COUNT: 15
	}

	static UWordBreakValues => {
		U_WB_OTHER: 0,
		U_WB_ALETTER: 1,
		U_WB_FORMAT: 2,
		U_WB_KATAKANA: 3,
		U_WB_MIDLETTER: 4,
		U_WB_MIDNUM: 5,
		U_WB_NUMERIC: 6,
		U_WB_EXTENDNUMLET: 7,
		U_WB_CR: 8,
		U_WB_EXTEND: 9,
		U_WB_LF: 10,
		U_WB_MIDNUMLET: 11,
		U_WB_NEWLINE: 12,
		U_WB_REGIONAL_INDICATOR: 13,
		U_WB_HEBREW_LETTER: 14,
		U_WB_SINGLE_QUOTE: 15,
		U_WB_DOUBLE_QUOTE: 16,
		U_WB_E_BASE: 17,
		U_WB_E_BASE_GAZ: 18,
		U_WB_E_MODIFIER: 19,
		U_WB_GLUE_AFTER_ZWJ: 20,
		U_WB_ZWJ: 21,
		U_WB_WSEGSPACE: 22,
		U_WB_COUNT: 17
	}

	static UGraphemeClusterBreak => {
		U_GCB_OTHER: 0,
		U_GCB_CONTROL: 1,
		U_GCB_CR: 2,
		U_GCB_EXTEND: 3,
		U_GCB_L: 4,
		U_GCB_LF: 5,
		U_GCB_LV: 6,
		U_GCB_LVT: 7,
		U_GCB_T: 8,
		U_GCB_V: 9,
		U_GCB_SPACING_MARK: 10,
		U_GCB_PREPEND: 11,
		U_GCB_REGIONAL_INDICATOR: 12,
		U_GCB_E_BASE: 13,
		U_GCB_E_BASE_GAZ: 14,
		U_GCB_E_MODIFIER: 15,
		U_GCB_GLUE_AFTER_ZWJ: 16,
		U_GCB_ZWJ: 17,
		U_GCB_COUNT: 13
	}

	static UJoiningType => {
		U_JT_NON_JOINING: 0,
		U_JT_JOIN_CAUSING: 1,
		U_JT_DUAL_JOINING: 2,
		U_JT_LEFT_JOINING: 3,
		U_JT_RIGHT_JOINING: 4,
		U_JT_TRANSPARENT: 5,
		U_JT_COUNT: 6
	}

	static UDecompositionType => {
		U_DT_NONE: 0,
		U_DT_CANONICAL: 1,
		U_DT_COMPAT: 2,
		U_DT_CIRCLE: 3,
		U_DT_FINAL: 4,
		U_DT_FONT: 5,
		U_DT_FRACTION: 6,
		U_DT_INITIAL: 7,
		U_DT_ISOLATED: 8,
		U_DT_MEDIAL: 9,
		U_DT_NARROW: 10,
		U_DT_NOBREAK: 11,
		U_DT_SMALL: 12,
		U_DT_SQUARE: 13,
		U_DT_SUB: 14,
		U_DT_SUPER: 15,
		U_DT_VERTICAL: 16,
		U_DT_WIDE: 17,
		U_DT_COUNT: 18
	}

	static UPropertyNameChoice => {
		U_SHORT_PROPERTY_NAME: 0,
		U_LONG_PROPERTY_NAME: 1,
		U_PROPERTY_NAME_CHOICE_COUNT: 2
	}

	static UCharNameChoice => {
		U_UNICODE_CHAR_NAME: 0x0,
		U_UNICODE_10_CHAR_NAME: 0x1,
		U_EXTENDED_CHAR_NAME: 0x2,
		U_CHAR_NAME_ALIAS: 0x3,
		U_CHAR_NAME_CHOICE_COUNT: 0x4
	}

	static UEastAsianWidth => {
		U_EA_NEUTRAL: 0, 
		U_EA_AMBIGUOUS: 1, 
		U_EA_HALFWIDTH: 2, 
		U_EA_FULLWIDTH: 3,
		U_EA_NARROW: 4,
		U_EA_WIDE: 5,
		U_EA_COUNT: 6
	}

	static UBlockCode => {	
		UBLOCK_NO_BLOCK: 0,
		UBLOCK_BASIC_LATIN: 1,
		UBLOCK_LATIN_1_SUPPLEMENT: 2,
		UBLOCK_LATIN_EXTENDED_A: 3,
		UBLOCK_LATIN_EXTENDED_B: 4,
		UBLOCK_IPA_EXTENSIONS: 5,
		UBLOCK_SPACING_MODIFIER_LETTERS: 6,
		UBLOCK_COMBINING_DIACRITICAL_MARKS: 7,
		UBLOCK_GREEK: 8,
		UBLOCK_CYRILLIC: 9,
		UBLOCK_ARMENIAN: 10,
		UBLOCK_HEBREW: 11,
		UBLOCK_ARABIC: 12,
		UBLOCK_SYRIAC: 13,
		UBLOCK_THAANA: 14,
		UBLOCK_DEVANAGARI: 15,
		UBLOCK_BENGALI: 16,
		UBLOCK_GURMUKHI: 17,
		UBLOCK_GUJARATI: 18,
		UBLOCK_ORIYA: 19,
		UBLOCK_TAMIL: 20,
		UBLOCK_TELUGU: 21,
		UBLOCK_KANNADA: 22,
		UBLOCK_MALAYALAM: 23,
		UBLOCK_SINHALA: 24,
		UBLOCK_THAI: 25,
		UBLOCK_LAO: 26,
		UBLOCK_TIBETAN: 27,
		UBLOCK_MYANMAR: 28,
		UBLOCK_GEORGIAN: 29,
		UBLOCK_HANGUL_JAMO: 30,
		UBLOCK_ETHIOPIC: 31,
		UBLOCK_CHEROKEE: 32,
		UBLOCK_UNIFIED_CANADIAN_ABORIGINAL_SYLLABICS: 33,
		UBLOCK_OGHAM: 34,
		UBLOCK_RUNIC: 35,
		UBLOCK_KHMER: 36,
		UBLOCK_MONGOLIAN: 37,
		UBLOCK_LATIN_EXTENDED_ADDITIONAL: 38,
		UBLOCK_GREEK_EXTENDED: 39,
		UBLOCK_GENERAL_PUNCTUATION: 40,
		UBLOCK_SUPERSCRIPTS_AND_SUBSCRIPTS: 41,
		UBLOCK_CURRENCY_SYMBOLS: 42,
		UBLOCK_COMBINING_MARKS_FOR_SYMBOLS: 43,
		UBLOCK_LETTERLIKE_SYMBOLS: 44,
		UBLOCK_NUMBER_FORMS: 45,
		UBLOCK_ARROWS: 46,
		UBLOCK_MATHEMATICAL_OPERATORS: 47,
		UBLOCK_MISCELLANEOUS_TECHNICAL: 48,
		UBLOCK_CONTROL_PICTURES: 49,
		UBLOCK_OPTICAL_CHARACTER_RECOGNITION: 50,
		UBLOCK_ENCLOSED_ALPHANUMERICS: 51,
		UBLOCK_BOX_DRAWING: 52,
		UBLOCK_BLOCK_ELEMENTS: 53,
		UBLOCK_GEOMETRIC_SHAPES: 54,
		UBLOCK_MISCELLANEOUS_SYMBOLS: 55,
		UBLOCK_DINGBATS: 56,
		UBLOCK_BRAILLE_PATTERNS: 57,
		UBLOCK_CJK_RADICALS_SUPPLEMENT: 58,
		UBLOCK_KANGXI_RADICALS: 59,
		UBLOCK_IDEOGRAPHIC_DESCRIPTION_CHARACTERS: 60,
		UBLOCK_CJK_SYMBOLS_AND_PUNCTUATION: 61,
		UBLOCK_HIRAGANA: 62,
		UBLOCK_KATAKANA: 63,
		UBLOCK_BOPOMOFO: 64,
		UBLOCK_HANGUL_COMPATIBILITY_JAMO: 65,
		UBLOCK_KANBUN: 66,
		UBLOCK_BOPOMOFO_EXTENDED: 67,
		UBLOCK_ENCLOSED_CJK_LETTERS_AND_MONTHS: 68,
		UBLOCK_CJK_COMPATIBILITY: 69,
		UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_A: 70,
		UBLOCK_CJK_UNIFIED_IDEOGRAPHS: 71,
		UBLOCK_YI_SYLLABLES: 72,
		UBLOCK_YI_RADICALS: 73,
		UBLOCK_HANGUL_SYLLABLES: 74,
		UBLOCK_HIGH_SURROGATES: 75,
		UBLOCK_HIGH_PRIVATE_USE_SURROGATES: 76,
		UBLOCK_LOW_SURROGATES: 77,
		UBLOCK_PRIVATE_USE_AREA: 78,
		UBLOCK_PRIVATE_USE: 78,
		UBLOCK_CJK_COMPATIBILITY_IDEOGRAPHS: 79,
		UBLOCK_ALPHABETIC_PRESENTATION_FORMS: 80,
		UBLOCK_ARABIC_PRESENTATION_FORMS_A: 81,
		UBLOCK_COMBINING_HALF_MARKS: 82,
		UBLOCK_CJK_COMPATIBILITY_FORMS: 83,
		UBLOCK_SMALL_FORM_VARIANTS: 84,
		UBLOCK_ARABIC_PRESENTATION_FORMS_B: 85,
		UBLOCK_SPECIALS: 86,
		UBLOCK_HALFWIDTH_AND_FULLWIDTH_FORMS: 87,
		UBLOCK_OLD_ITALIC: 88,
		UBLOCK_GOTHIC: 89,
		UBLOCK_DESERET: 90,
		UBLOCK_BYZANTINE_MUSICAL_SYMBOLS: 91,
		UBLOCK_MUSICAL_SYMBOLS: 92,
		UBLOCK_MATHEMATICAL_ALPHANUMERIC_SYMBOLS: 93,
		UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_B: 94,
		UBLOCK_CJK_COMPATIBILITY_IDEOGRAPHS_SUPPLEMENT: 95,
		UBLOCK_TAGS: 96,
		UBLOCK_CYRILLIC_SUPPLEMENT: 97,
		UBLOCK_CYRILLIC_SUPPLEMENTARY: 97,
		UBLOCK_TAGALOG: 98,
		UBLOCK_HANUNOO: 99,
		UBLOCK_BUHID: 100,
		UBLOCK_TAGBANWA: 101,
		UBLOCK_MISCELLANEOUS_MATHEMATICAL_SYMBOLS_A: 102,
		UBLOCK_SUPPLEMENTAL_ARROWS_A: 103,
		UBLOCK_SUPPLEMENTAL_ARROWS_B: 104,
		UBLOCK_MISCELLANEOUS_MATHEMATICAL_SYMBOLS_B: 105,
		UBLOCK_SUPPLEMENTAL_MATHEMATICAL_OPERATORS: 106,
		UBLOCK_KATAKANA_PHONETIC_EXTENSIONS: 107,
		UBLOCK_VARIATION_SELECTORS: 108,
		UBLOCK_SUPPLEMENTARY_PRIVATE_USE_AREA_A: 109,
		UBLOCK_SUPPLEMENTARY_PRIVATE_USE_AREA_B: 110,
		UBLOCK_LIMBU: 111,
		UBLOCK_TAI_LE: 112,
		UBLOCK_KHMER_SYMBOLS: 113,
		UBLOCK_PHONETIC_EXTENSIONS: 114,
		UBLOCK_MISCELLANEOUS_SYMBOLS_AND_ARROWS: 115,
		UBLOCK_YIJING_HEXAGRAM_SYMBOLS: 116,
		UBLOCK_LINEAR_B_SYLLABARY: 117,
		UBLOCK_LINEAR_B_IDEOGRAMS: 118,
		UBLOCK_AEGEAN_NUMBERS: 119,
		UBLOCK_UGARITIC: 120,
		UBLOCK_SHAVIAN: 121,
		UBLOCK_OSMANYA: 122,
		UBLOCK_CYPRIOT_SYLLABARY: 123,
		UBLOCK_TAI_XUAN_JING_SYMBOLS: 124,
		UBLOCK_VARIATION_SELECTORS_SUPPLEMENT: 125,
		UBLOCK_ANCIENT_GREEK_MUSICAL_NOTATION: 126,
		UBLOCK_ANCIENT_GREEK_NUMBERS: 127,
		UBLOCK_ARABIC_SUPPLEMENT: 128,
		UBLOCK_BUGINESE: 129,
		UBLOCK_CJK_STROKES: 130,
		UBLOCK_COMBINING_DIACRITICAL_MARKS_SUPPLEMENT: 131,
		UBLOCK_COPTIC: 132,
		UBLOCK_ETHIOPIC_EXTENDED: 133,
		UBLOCK_ETHIOPIC_SUPPLEMENT: 134,
		UBLOCK_GEORGIAN_SUPPLEMENT: 135,
		UBLOCK_GLAGOLITIC: 136,
		UBLOCK_KHAROSHTHI: 137,
		UBLOCK_MODIFIER_TONE_LETTERS: 138,
		UBLOCK_NEW_TAI_LUE: 139,
		UBLOCK_OLD_PERSIAN: 140,
		UBLOCK_PHONETIC_EXTENSIONS_SUPPLEMENT: 141,
		UBLOCK_SUPPLEMENTAL_PUNCTUATION: 142,
		UBLOCK_SYLOTI_NAGRI: 143,
		UBLOCK_TIFINAGH: 144,
		UBLOCK_VERTICAL_FORMS: 145,
		UBLOCK_NKO: 146,
		UBLOCK_BALINESE: 147,
		UBLOCK_LATIN_EXTENDED_C: 148,
		UBLOCK_LATIN_EXTENDED_D: 149,
		UBLOCK_PHAGS_PA: 150,
		UBLOCK_PHOENICIAN: 151,
		UBLOCK_CUNEIFORM: 152,
		UBLOCK_CUNEIFORM_NUMBERS_AND_PUNCTUATION: 153,
		UBLOCK_COUNTING_ROD_NUMERALS: 154,
		UBLOCK_SUNDANESE: 155,
		UBLOCK_LEPCHA: 156,
		UBLOCK_OL_CHIKI: 157,
		UBLOCK_CYRILLIC_EXTENDED_A: 158,
		UBLOCK_VAI: 159,
		UBLOCK_CYRILLIC_EXTENDED_B: 160,
		UBLOCK_SAURASHTRA: 161,
		UBLOCK_KAYAH_LI: 162,
		UBLOCK_REJANG: 163,
		UBLOCK_CHAM: 164,
		UBLOCK_ANCIENT_SYMBOLS: 165,
		UBLOCK_PHAISTOS_DISC: 166,
		UBLOCK_LYCIAN: 167,
		UBLOCK_CARIAN: 168,
		UBLOCK_LYDIAN: 169,
		UBLOCK_MAHJONG_TILES: 170,
		UBLOCK_DOMINO_TILES: 171,
		UBLOCK_SAMARITAN: 172,
		UBLOCK_UNIFIED_CANADIAN_ABORIGINAL_SYLLABICS_EXTENDED: 173,
		UBLOCK_TAI_THAM: 174,
		UBLOCK_VEDIC_EXTENSIONS: 175,
		UBLOCK_LISU: 176,
		UBLOCK_BAMUM: 177,
		UBLOCK_COMMON_INDIC_NUMBER_FORMS: 178,
		UBLOCK_DEVANAGARI_EXTENDED: 179,
		UBLOCK_HANGUL_JAMO_EXTENDED_A: 180,
		UBLOCK_JAVANESE: 181,
		UBLOCK_MYANMAR_EXTENDED_A: 182,
		UBLOCK_TAI_VIET: 183,
		UBLOCK_MEETEI_MAYEK: 184,
		UBLOCK_HANGUL_JAMO_EXTENDED_B: 185,
		UBLOCK_IMPERIAL_ARAMAIC: 186,
		UBLOCK_OLD_SOUTH_ARABIAN: 187,
		UBLOCK_AVESTAN: 188,
		UBLOCK_INSCRIPTIONAL_PARTHIAN: 189,
		UBLOCK_INSCRIPTIONAL_PAHLAVI: 190,
		UBLOCK_OLD_TURKIC: 191,
		UBLOCK_RUMI_NUMERAL_SYMBOLS: 192,
		UBLOCK_KAITHI: 193,
		UBLOCK_EGYPTIAN_HIEROGLYPHS: 194,
		UBLOCK_ENCLOSED_ALPHANUMERIC_SUPPLEMENT: 195,
		UBLOCK_ENCLOSED_IDEOGRAPHIC_SUPPLEMENT: 196,
		UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_C: 197,
		UBLOCK_MANDAIC: 198,
		UBLOCK_BATAK: 199,
		UBLOCK_ETHIOPIC_EXTENDED_A: 200,
		UBLOCK_BRAHMI: 201,
		UBLOCK_BAMUM_SUPPLEMENT: 202,
		UBLOCK_KANA_SUPPLEMENT: 203,
		UBLOCK_PLAYING_CARDS: 204,
		UBLOCK_MISCELLANEOUS_SYMBOLS_AND_PICTOGRAPHS: 205,
		UBLOCK_EMOTICONS: 206,
		UBLOCK_TRANSPORT_AND_MAP_SYMBOLS: 207,
		UBLOCK_ALCHEMICAL_SYMBOLS: 208,
		UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_D: 209,
		UBLOCK_ARABIC_EXTENDED_A: 210,
		UBLOCK_ARABIC_MATHEMATICAL_ALPHABETIC_SYMBOLS: 211,
		UBLOCK_CHAKMA: 212,
		UBLOCK_MEETEI_MAYEK_EXTENSIONS: 213,
		UBLOCK_MEROITIC_CURSIVE: 214,
		UBLOCK_MEROITIC_HIEROGLYPHS: 215,
		UBLOCK_MIAO: 216,
		UBLOCK_SHARADA: 217,
		UBLOCK_SORA_SOMPENG: 218,
		UBLOCK_SUNDANESE_SUPPLEMENT: 219,
		UBLOCK_TAKRI: 220,
		UBLOCK_BASSA_VAH: 221,
		UBLOCK_CAUCASIAN_ALBANIAN: 222,
		UBLOCK_COPTIC_EPACT_NUMBERS: 223,
		UBLOCK_COMBINING_DIACRITICAL_MARKS_EXTENDED: 224,
		UBLOCK_DUPLOYAN: 225,
		UBLOCK_ELBASAN: 226,
		UBLOCK_GEOMETRIC_SHAPES_EXTENDED: 227,
		UBLOCK_GRANTHA: 228,
		UBLOCK_KHOJKI: 229,
		UBLOCK_KHUDAWADI: 230,
		UBLOCK_LATIN_EXTENDED_E: 231,
		UBLOCK_LINEAR_A: 232,
		UBLOCK_MAHAJANI: 233,
		UBLOCK_MANICHAEAN: 234,
		UBLOCK_MENDE_KIKAKUI: 235,
		UBLOCK_MODI: 236,
		UBLOCK_MRO: 237,
		UBLOCK_MYANMAR_EXTENDED_B: 238,
		UBLOCK_NABATAEAN: 239,
		UBLOCK_OLD_NORTH_ARABIAN: 240,
		UBLOCK_OLD_PERMIC: 241,
		UBLOCK_ORNAMENTAL_DINGBATS: 242,
		UBLOCK_PAHAWH_HMONG: 243,
		UBLOCK_PALMYRENE: 244,
		UBLOCK_PAU_CIN_HAU: 245,
		UBLOCK_PSALTER_PAHLAVI: 246,
		UBLOCK_SHORTHAND_FORMAT_CONTROLS: 247,
		UBLOCK_SIDDHAM: 248,
		UBLOCK_SINHALA_ARCHAIC_NUMBERS: 249,
		UBLOCK_SUPPLEMENTAL_ARROWS_C: 250,
		UBLOCK_TIRHUTA: 251,
		UBLOCK_WARANG_CITI: 252,
		UBLOCK_AHOM: 253,
		UBLOCK_ANATOLIAN_HIEROGLYPHS: 254,
		UBLOCK_CHEROKEE_SUPPLEMENT: 255,
		UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_E: 256,
		UBLOCK_EARLY_DYNASTIC_CUNEIFORM: 257,
		UBLOCK_HATRAN: 258,
		UBLOCK_MULTANI: 259,
		UBLOCK_OLD_HUNGARIAN: 260,
		UBLOCK_SUPPLEMENTAL_SYMBOLS_AND_PICTOGRAPHS: 261,
		UBLOCK_SUTTON_SIGNWRITING: 262,
		UBLOCK_ADLAM: 263,
		UBLOCK_BHAIKSUKI: 264,
		UBLOCK_CYRILLIC_EXTENDED_C: 265,
		UBLOCK_GLAGOLITIC_SUPPLEMENT: 266,
		UBLOCK_IDEOGRAPHIC_SYMBOLS_AND_PUNCTUATION: 267,
		UBLOCK_MARCHEN: 268,
		UBLOCK_MONGOLIAN_SUPPLEMENT: 269,
		UBLOCK_NEWA: 270,
		UBLOCK_OSAGE: 271,
		UBLOCK_TANGUT: 272,
		UBLOCK_TANGUT_COMPONENTS: 273,
		UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_F: 274,
		UBLOCK_KANA_EXTENDED_A: 275,
		UBLOCK_MASARAM_GONDI: 276,
		UBLOCK_NUSHU: 277,
		UBLOCK_SOYOMBO: 278,
		UBLOCK_SYRIAC_SUPPLEMENT: 279,
		UBLOCK_ZANABAZAR_SQUARE: 280,
		UBLOCK_CHESS_SYMBOLS: 281,
		UBLOCK_DOGRA: 282,
		UBLOCK_GEORGIAN_EXTENDED: 283,
		UBLOCK_GUNJALA_GONDI: 284,
		UBLOCK_HANIFI_ROHINGYA: 285,
		UBLOCK_INDIC_SIYAQ_NUMBERS: 286,
		UBLOCK_MAKASAR: 287,
		UBLOCK_MAYAN_NUMERALS: 288,
		UBLOCK_MEDEFAIDRIN: 289,
		UBLOCK_OLD_SOGDIAN: 290,
		UBLOCK_SOGDIAN: 291,
		UBLOCK_EGYPTIAN_HIEROGLYPH_FORMAT_CONTROLS: 292,
		UBLOCK_ELYMAIC: 293,
		UBLOCK_NANDINAGARI: 294,
		UBLOCK_NYIAKENG_PUACHUE_HMONG: 295,
		UBLOCK_OTTOMAN_SIYAQ_NUMBERS: 296,
		UBLOCK_SMALL_KANA_EXTENSION: 297,
		UBLOCK_SYMBOLS_AND_PICTOGRAPHS_EXTENDED_A: 298,
		UBLOCK_TAMIL_SUPPLEMENT: 299,
		UBLOCK_WANCHO: 300,
		UBLOCK_CHORASMIAN: 301,
		UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_G: 302,
		UBLOCK_DIVES_AKURU: 303,
		UBLOCK_KHITAN_SMALL_SCRIPT: 304,
		UBLOCK_LISU_SUPPLEMENT: 305,
		UBLOCK_SYMBOLS_FOR_LEGACY_COMPUTING: 306,
		UBLOCK_TANGUT_SUPPLEMENT: 307,
		UBLOCK_YEZIDI: 308,
		UBLOCK_ARABIC_EXTENDED_B: 309,
		UBLOCK_CYPRO_MINOAN: 310,
		UBLOCK_ETHIOPIC_EXTENDED_B: 311,
		UBLOCK_KANA_EXTENDED_B: 312,
		UBLOCK_LATIN_EXTENDED_F: 313,
		UBLOCK_LATIN_EXTENDED_G: 314,
		UBLOCK_OLD_UYGHUR: 315,
		UBLOCK_TANGSA: 316,
		UBLOCK_TOTO: 317,
		UBLOCK_UNIFIED_CANADIAN_ABORIGINAL_SYLLABICS_EXTENDED_A: 318,
		UBLOCK_VITHKUQI: 319,
		UBLOCK_ZNAMENNY_MUSICAL_NOTATION: 320,
		UBLOCK_ARABIC_EXTENDED_C: 321,
		UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_H: 322,
		UBLOCK_CYRILLIC_EXTENDED_D: 323,
		UBLOCK_DEVANAGARI_EXTENDED_A: 324,
		UBLOCK_KAKTOVIK_NUMERALS: 325,
		UBLOCK_KAWI: 326,
		UBLOCK_NAG_MUNDARI: 327,
		UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_I: 328,
		UBLOCK_EGYPTIAN_HIEROGLYPHS_EXTENDED_A: 329,
		UBLOCK_GARAY: 330,
		UBLOCK_GURUNG_KHEMA: 331,
		UBLOCK_KIRAT_RAI: 332,
		UBLOCK_MYANMAR_EXTENDED_C: 333,
		UBLOCK_OL_ONAL: 334,
		UBLOCK_SUNUWAR: 335,
		UBLOCK_SYMBOLS_FOR_LEGACY_COMPUTING_SUPPLEMENT: 336,
		UBLOCK_TODHRI: 337,
		UBLOCK_TULU_TIGALARI: 338,
		UBLOCK_COUNT: 339,
		UBLOCK_INVALID_CODE: -1
	}

	static UBidiPairedBracketType => {
		U_BPT_NONE: 0, 
		U_BPT_OPEN: 1, 
		U_BPT_CLOSE: 2, 
		U_BPT_COUNT: 3 
	}

	static UCharDirection => {	
		U_LEFT_TO_RIGHT: 0,
		U_RIGHT_TO_LEFT: 1,
		U_EUROPEAN_NUMBER: 2,
		U_EUROPEAN_NUMBER_SEPARATOR: 3,
		U_EUROPEAN_NUMBER_TERMINATOR: 4,
		U_ARABIC_NUMBER: 5,
		U_COMMON_NUMBER_SEPARATOR: 6,
		U_BLOCK_SEPARATOR: 7,
		U_SEGMENT_SEPARATOR: 8,
		U_WHITE_SPACE_NEUTRAL: 9,
		U_OTHER_NEUTRAL: 10,
		U_LEFT_TO_RIGHT_EMBEDDING: 11,
		U_LEFT_TO_RIGHT_OVERRIDE: 12,
		U_RIGHT_TO_LEFT_ARABIC: 13,
		U_RIGHT_TO_LEFT_EMBEDDING: 14,
		U_RIGHT_TO_LEFT_OVERRIDE: 15,
		U_POP_DIRECTIONAL_FORMAT: 16,
		U_DIR_NON_SPACING_MARK: 17,
		U_BOUNDARY_NEUTRAL: 18,
		U_FIRST_STRONG_ISOLATE: 19,
		U_LEFT_TO_RIGHT_ISOLATE: 20,
		U_RIGHT_TO_LEFT_ISOLATE: 21,
		U_POP_DIRECTIONAL_ISOLATE: 22,
		U_CHAR_DIRECTION_COUNT: 23
	}

	static UCharCategory => {
		U_UNASSIGNED: 0,
		U_GENERAL_OTHER_TYPES: 0,
		U_UPPERCASE_LETTER: 1,
		U_LOWERCASE_LETTER: 2,
		U_TITLECASE_LETTER: 3,
		U_MODIFIER_LETTER: 4,
		U_OTHER_LETTER: 5,
		U_NON_SPACING_MARK: 6,
		U_ENCLOSING_MARK: 7,
		U_COMBINING_SPACING_MARK: 8,
		U_DECIMAL_DIGIT_NUMBER: 9,
		U_LETTER_NUMBER: 10,
		U_OTHER_NUMBER: 11,
		U_SPACE_SEPARATOR: 12,
		U_LINE_SEPARATOR: 13,
		U_PARAGRAPH_SEPARATOR: 14,
		U_CONTROL_CHAR: 15,
		U_FORMAT_CHAR: 16,
		U_PRIVATE_USE_CHAR: 17,
		U_SURROGATE: 18,
		U_DASH_PUNCTUATION: 19,
		U_START_PUNCTUATION: 20,
		U_END_PUNCTUATION: 21,
		U_CONNECTOR_PUNCTUATION: 22,
		U_OTHER_PUNCTUATION: 23,
		U_MATH_SYMBOL: 24,
		U_CURRENCY_SYMBOL: 25,
		U_MODIFIER_SYMBOL: 26,
		U_OTHER_SYMBOL: 27,
		U_INITIAL_PUNCTUATION: 28,
		U_FINAL_PUNCTUATION: 29,
		U_CHAR_CATEGORY_COUNT: 30
	}

	static UProperty => {
		UCHAR_ALPHABETIC: 0,
		UCHAR_BINARY_START: 0,
		UCHAR_ASCII_HEX_DIGIT: 1,
		UCHAR_BIDI_CONTROL: 2,
		UCHAR_BIDI_MIRRORED: 3,
		UCHAR_DASH: 4,
		UCHAR_DEFAULT_IGNORABLE_CODE_POINT: 5,
		UCHAR_DEPRECATED: 6,
		UCHAR_DIACRITIC: 7,
		UCHAR_EXTENDER: 8,
		UCHAR_FULL_COMPOSITION_EXCLUSION: 9,
		UCHAR_GRAPHEME_BASE: 10,
		UCHAR_GRAPHEME_EXTEND: 11,
		UCHAR_GRAPHEME_LINK: 12,
		UCHAR_HEX_DIGIT: 13,
		UCHAR_HYPHEN: 14,
		UCHAR_ID_CONTINUE: 15,
		UCHAR_ID_START: 16,
		UCHAR_IDEOGRAPHIC: 17,
		UCHAR_IDS_BINARY_OPERATOR: 18,
		UCHAR_IDS_TRINARY_OPERATOR: 19,
		UCHAR_JOIN_CONTROL: 20,
		UCHAR_LOGICAL_ORDER_EXCEPTION: 21,
		UCHAR_LOWERCASE: 22,
		UCHAR_MATH: 23,
		UCHAR_NONCHARACTER_CODE_POINT: 24,
		UCHAR_QUOTATION_MARK: 25,
		UCHAR_RADICAL: 26,
		UCHAR_SOFT_DOTTED: 27,
		UCHAR_TERMINAL_PUNCTUATION: 28,
		UCHAR_UNIFIED_IDEOGRAPH: 29,
		UCHAR_UPPERCASE: 30,
		UCHAR_WHITE_SPACE: 31,
		UCHAR_XID_CONTINUE: 32,
		UCHAR_XID_START: 33,
		UCHAR_CASE_SENSITIVE: 34,
		UCHAR_S_TERM: 35,
		UCHAR_VARIATION_SELECTOR: 36,
		UCHAR_NFD_INERT: 37,
		UCHAR_NFKD_INERT: 38,
		UCHAR_NFC_INERT: 39,
		UCHAR_NFKC_INERT: 40,
		UCHAR_SEGMENT_STARTER: 41,
		UCHAR_PATTERN_SYNTAX: 42,
		UCHAR_PATTERN_WHITE_SPACE: 43,
		UCHAR_POSIX_ALNUM: 44,
		UCHAR_POSIX_BLANK: 45,
		UCHAR_POSIX_GRAPH: 46,
		UCHAR_POSIX_PRINT: 47,
		UCHAR_POSIX_XDIGIT: 48,
		UCHAR_CASED: 49,
		UCHAR_CASE_IGNORABLE: 50,
		UCHAR_CHANGES_WHEN_LOWERCASED: 51,
		UCHAR_CHANGES_WHEN_UPPERCASED: 52,
		UCHAR_CHANGES_WHEN_TITLECASED: 53,
		UCHAR_CHANGES_WHEN_CASEFOLDED: 54,
		UCHAR_CHANGES_WHEN_CASEMAPPED: 55,
		UCHAR_CHANGES_WHEN_NFKC_CASEFOLDED: 56,
		UCHAR_EMOJI: 57,
		UCHAR_EMOJI_PRESENTATION: 58,
		UCHAR_EMOJI_MODIFIER: 59,
		UCHAR_EMOJI_MODIFIER_BASE: 60,
		UCHAR_EMOJI_COMPONENT: 61,
		UCHAR_REGIONAL_INDICATOR: 62,
		UCHAR_PREPENDED_CONCATENATION_MARK: 63,
		UCHAR_EXTENDED_PICTOGRAPHIC: 64,
		UCHAR_BASIC_EMOJI: 65,
		UCHAR_EMOJI_KEYCAP_SEQUENCE: 66,
		UCHAR_RGI_EMOJI_MODIFIER_SEQUENCE: 67,
		UCHAR_RGI_EMOJI_FLAG_SEQUENCE: 68,
		UCHAR_RGI_EMOJI_TAG_SEQUENCE: 69,
		UCHAR_RGI_EMOJI_ZWJ_SEQUENCE: 70,
		UCHAR_RGI_EMOJI: 71,
		UCHAR_IDS_UNARY_OPERATOR: 72,
		UCHAR_ID_COMPAT_MATH_START: 73,
		UCHAR_ID_COMPAT_MATH_CONTINUE: 74,
		UCHAR_MODIFIER_COMBINING_MARK: 75,
		UCHAR_BINARY_LIMIT: 76,
		UCHAR_BIDI_CLASS: 0x1000,
		UCHAR_INT_START: 0x1000,
		UCHAR_BLOCK: 0x1001,
		UCHAR_CANONICAL_COMBINING_CLASS: 0x1002,
		UCHAR_DECOMPOSITION_TYPE: 0x1003,
		UCHAR_EAST_ASIAN_WIDTH: 0x1004,
		UCHAR_GENERAL_CATEGORY: 0x1005,
		UCHAR_JOINING_GROUP: 0x1006,
		UCHAR_JOINING_TYPE: 0x1007,
		UCHAR_LINE_BREAK: 0x1008,
		UCHAR_NUMERIC_TYPE: 0x1009,
		UCHAR_SCRIPT: 0x100A,
		UCHAR_HANGUL_SYLLABLE_TYPE: 0x100B,
		UCHAR_NFD_QUICK_CHECK: 0x100C,
		UCHAR_NFKD_QUICK_CHECK: 0x100D,
		UCHAR_NFC_QUICK_CHECK: 0x100E,
		UCHAR_NFKC_QUICK_CHECK: 0x100F,
		UCHAR_LEAD_CANONICAL_COMBINING_CLASS: 0x1010,
		UCHAR_TRAIL_CANONICAL_COMBINING_CLASS: 0x1011,
		UCHAR_GRAPHEME_CLUSTER_BREAK: 0x1012,
		UCHAR_SENTENCE_BREAK: 0x1013,
		UCHAR_WORD_BREAK: 0x1014,
		UCHAR_BIDI_PAIRED_BRACKET_TYPE: 0x1015,
		UCHAR_INDIC_POSITIONAL_CATEGORY: 0x1016,
		UCHAR_INDIC_SYLLABIC_CATEGORY: 0x1017,
		UCHAR_VERTICAL_ORIENTATION: 0x1018,
		UCHAR_IDENTIFIER_STATUS: 0x1019,
		UCHAR_INDIC_CONJUNCT_BREAK: 0x101A,
		UCHAR_INT_LIMIT: 0x101B,
		UCHAR_GENERAL_CATEGORY_MASK: 0x2000,
		UCHAR_MASK_START: 0x2000,
		UCHAR_MASK_LIMIT: 0x2001,
		UCHAR_NUMERIC_VALUE: 0x3000,
		UCHAR_DOUBLE_START: 0x3000,
		UCHAR_DOUBLE_LIMIT: 0x3001,
		UCHAR_AGE: 0x4000,
		UCHAR_STRING_START: 0x4000,
		UCHAR_BIDI_MIRRORING_GLYPH: 0x4001,
		UCHAR_CASE_FOLDING: 0x4002,
		UCHAR_ISO_COMMENT: 0x4003,
		UCHAR_LOWERCASE_MAPPING: 0x4004,
		UCHAR_NAME: 0x4005,
		UCHAR_SIMPLE_CASE_FOLDING: 0x4006,
		UCHAR_SIMPLE_LOWERCASE_MAPPING: 0x4007,
		UCHAR_SIMPLE_TITLECASE_MAPPING: 0x4008,
		UCHAR_SIMPLE_UPPERCASE_MAPPING: 0x4009,
		UCHAR_TITLECASE_MAPPING: 0x400A,
		UCHAR_UNICODE_1_NAME: 0x400B,
		UCHAR_UPPERCASE_MAPPING: 0x400C,
		UCHAR_BIDI_PAIRED_BRACKET: 0x400D,
		UCHAR_STRING_LIMIT: 0x400E,
		UCHAR_SCRIPT_EXTENSIONS: 0x7000,
		UCHAR_OTHER_PROPERTY_START: 0x7000,
		UCHAR_IDENTIFIER_TYPE: 0x7001,
		UCHAR_OTHER_PROPERTY_LIMIT: 0x7002,
		UCHAR_INVALID_CODE:  -1
	}

	static UErrorCode => {
		U_USING_FALLBACK_WARNING:	-128,
		U_ERROR_WARNING_START:	-128,
		U_USING_DEFAULT_WARNING:	-127,
		U_SAFECLONE_ALLOCATED_WARNING:	-126,
		U_STATE_OLD_WARNING:	-125,
		U_STRING_NOT_TERMINATED_WARNING:	-124,
		U_SORT_KEY_TOO_SHORT_WARNING:	-123,
		U_AMBIGUOUS_ALIAS_WARNING:	-122,
		U_DIFFERENT_UCA_VERSION:	-121,
		U_PLUGIN_CHANGED_LEVEL_WARNING:	-120,
		U_ZERO_ERROR:	0,
		U_ILLEGAL_ARGUMENT_ERROR:	1,
		U_MISSING_RESOURCE_ERROR:	2,
		U_INVALID_FORMAT_ERROR:	3,
		U_FILE_ACCESS_ERROR:	4,
		U_INTERNAL_PROGRAM_ERROR:	5,
		U_MESSAGE_PARSE_ERROR:	6,
		U_MEMORY_ALLOCATION_ERROR:	7,
		U_INDEX_OUTOFBOUNDS_ERROR:	8,
		U_PARSE_ERROR:	9,
		U_INVALID_CHAR_FOUND:	10,
		U_TRUNCATED_CHAR_FOUND:	11,
		U_ILLEGAL_CHAR_FOUND:	12,
		U_INVALID_TABLE_FORMAT:	13,
		U_INVALID_TABLE_FILE:	14,
		U_BUFFER_OVERFLOW_ERROR:	15,
		U_UNSUPPORTED_ERROR:	16,
		U_RESOURCE_TYPE_MISMATCH:	17,
		U_ILLEGAL_ESCAPE_SEQUENCE:	18,
		U_UNSUPPORTED_ESCAPE_SEQUENCE:	19,
		U_NO_SPACE_AVAILABLE:	20,
		U_CE_NOT_FOUND_ERROR:	21,
		U_PRIMARY_TOO_LONG_ERROR:	22,
		U_STATE_TOO_OLD_ERROR:	23,
		U_TOO_MANY_ALIASES_ERROR:	24,
		U_ENUM_OUT_OF_SYNC_ERROR:	25,
		U_INVARIANT_CONVERSION_ERROR:	26,
		U_INVALID_STATE_ERROR:	27,
		U_COLLATOR_VERSION_MISMATCH:	28,
		U_USELESS_COLLATOR_ERROR:	29,
		U_NO_WRITE_PERMISSION:	30,
		U_INPUT_TOO_LONG_ERROR:	31,
		U_BAD_VARIABLE_DEFINITION:	65536,
		U_PARSE_ERROR_START:	65536,
		U_MALFORMED_RULE:	65537,
		U_MALFORMED_SET:	65538,
		U_MALFORMED_SYMBOL_REFERENCE:	65539,
		U_MALFORMED_UNICODE_ESCAPE:	65540,
		U_MALFORMED_VARIABLE_DEFINITION:	65541,
		U_MALFORMED_VARIABLE_REFERENCE:	65542,
		U_MISMATCHED_SEGMENT_DELIMITERS:	65543,
		U_MISPLACED_ANCHOR_START:	65544,
		U_MISPLACED_CURSOR_OFFSET:	65545,
		U_MISPLACED_QUANTIFIER:	65546,
		U_MISSING_OPERATOR:	65547,
		U_MISSING_SEGMENT_CLOSE:	65548,
		U_MULTIPLE_ANTE_CONTEXTS:	65549,
		U_MULTIPLE_CURSORS:	65550,
		U_MULTIPLE_POST_CONTEXTS:	65551,
		U_TRAILING_BACKSLASH:	65552,
		U_UNDEFINED_SEGMENT_REFERENCE:	65553,
		U_UNDEFINED_VARIABLE:	65554,
		U_UNQUOTED_SPECIAL:	65555,
		U_UNTERMINATED_QUOTE:	65556,
		U_RULE_MASK_ERROR:	65557,
		U_MISPLACED_COMPOUND_FILTER:	65558,
		U_MULTIPLE_COMPOUND_FILTERS:	65559,
		U_INVALID_RBT_SYNTAX:	65560,
		U_INVALID_PROPERTY_PATTERN:	65561,
		U_MALFORMED_PRAGMA:	65562,
		U_UNCLOSED_SEGMENT:	65563,
		U_ILLEGAL_CHAR_IN_SEGMENT:	65564,
		U_VARIABLE_RANGE_EXHAUSTED:	65565,
		U_VARIABLE_RANGE_OVERLAP:	65566,
		U_ILLEGAL_CHARACTER:	65567,
		U_INTERNAL_TRANSLITERATOR_ERROR:	65568,
		U_INVALID_ID:	65569,
		U_INVALID_FUNCTION:	65570,
		U_UNEXPECTED_TOKEN:	65792,
		U_FMT_PARSE_ERROR_START:	65792,
		U_MULTIPLE_DECIMAL_SEPARATORS:	65793,
		U_MULTIPLE_DECIMAL_SEPERATORS:	65793,
		U_MULTIPLE_EXPONENTIAL_SYMBOLS:	65794,
		U_MALFORMED_EXPONENTIAL_PATTERN:	65795,
		U_MULTIPLE_PERCENT_SYMBOLS:	65796,
		U_MULTIPLE_PERMILL_SYMBOLS:	65797,
		U_MULTIPLE_PAD_SPECIFIERS:	65798,
		U_PATTERN_SYNTAX_ERROR:	65799,
		U_ILLEGAL_PAD_POSITION:	65800,
		U_UNMATCHED_BRACES:	65801,
		U_UNSUPPORTED_PROPERTY:	65802,
		U_UNSUPPORTED_ATTRIBUTE:	65803,
		U_ARGUMENT_TYPE_MISMATCH:	65804,
		U_DUPLICATE_KEYWORD:	65805,
		U_UNDEFINED_KEYWORD:	65806,
		U_DEFAULT_KEYWORD_MISSING:	65807,
		U_DECIMAL_NUMBER_SYNTAX_ERROR:	65808,
		U_FORMAT_INEXACT_ERROR:	65809,
		U_NUMBER_ARG_OUTOFBOUNDS_ERROR:	65810,
		U_NUMBER_SKELETON_SYNTAX_ERROR:	65811,
		U_BRK_INTERNAL_ERROR:	66048,
		U_BRK_ERROR_START:	66048,
		U_BRK_HEX_DIGITS_EXPECTED:	66049,
		U_BRK_SEMICOLON_EXPECTED:	66050,
		U_BRK_RULE_SYNTAX:	66051,
		U_BRK_UNCLOSED_SET:	66052,
		U_BRK_ASSIGN_ERROR:	66053,
		U_BRK_VARIABLE_REDFINITION:	66054,
		U_BRK_MISMATCHED_PAREN:	66055,
		U_BRK_NEW_LINE_IN_QUOTED_STRING:	66056,
		U_BRK_UNDEFINED_VARIABLE:	66057,
		U_BRK_INIT_ERROR:	66058,
		U_BRK_RULE_EMPTY_SET:	66059,
		U_BRK_UNRECOGNIZED_OPTION:	66060,
		U_BRK_MALFORMED_RULE_TAG:	66061,
		U_REGEX_INTERNAL_ERROR:	66304,
		U_REGEX_ERROR_START:	66304,
		U_REGEX_RULE_SYNTAX:	66305,
		U_REGEX_INVALID_STATE:	66306,
		U_REGEX_BAD_ESCAPE_SEQUENCE:	66307,
		U_REGEX_PROPERTY_SYNTAX:	66308,
		U_REGEX_UNIMPLEMENTED:	66309,
		U_REGEX_MISMATCHED_PAREN:	66310,
		U_REGEX_NUMBER_TOO_BIG:	66311,
		U_REGEX_BAD_INTERVAL:	66312,
		U_REGEX_MAX_LT_MIN:	66313,
		U_REGEX_INVALID_BACK_REF:	66314,
		U_REGEX_INVALID_FLAG:	66315,
		U_REGEX_LOOK_BEHIND_LIMIT:	66316,
		U_REGEX_SET_CONTAINS_STRING:	66317,
		U_REGEX_MISSING_CLOSE_BRACKET:	66319,
		U_REGEX_INVALID_RANGE:	66320,
		U_REGEX_STACK_OVERFLOW:	66321,
		U_REGEX_TIME_OUT:	66322,
		U_REGEX_STOPPED_BY_CALLER:	66323,
		U_REGEX_PATTERN_TOO_BIG:	66324,
		U_REGEX_INVALID_CAPTURE_GROUP_NAME:	66325,
		U_IDNA_PROHIBITED_ERROR:	66560,
		U_IDNA_ERROR_START:	66560,
		U_IDNA_UNASSIGNED_ERROR:	66561,
		U_IDNA_CHECK_BIDI_ERROR:	66562,
		U_IDNA_STD3_ASCII_RULES_ERROR:	66563,
		U_IDNA_ACE_PREFIX_ERROR:	66564,
		U_IDNA_VERIFICATION_ERROR:	66565,
		U_IDNA_LABEL_TOO_LONG_ERROR:	66566,
		U_IDNA_ZERO_LENGTH_LABEL_ERROR:	66567,
		U_IDNA_DOMAIN_NAME_TOO_LONG_ERROR:	66568,
		U_STRINGPREP_PROHIBITED_ERROR:	66560,
		U_STRINGPREP_UNASSIGNED_ERROR:	66561,
		U_STRINGPREP_CHECK_BIDI_ERROR:	66562,
		U_PLUGIN_ERROR_START:	66816,
		U_PLUGIN_TOO_HIGH:	66816,
		U_PLUGIN_DIDNT_SET_LEVEL:	66817,
		U_ERROR_WARNING_LIMIT:	-119,
		U_STANDARD_ERROR_LIMIT:	31,
		U_PARSE_ERROR_LIMIT:	65571,
		U_FMT_PARSE_ERROR_LIMIT:	65810,
		U_BRK_ERROR_LIMIT:	66062,
		U_REGEX_ERROR_LIMIT:	66326,
		U_IDNA_ERROR_LIMIT:	66569,
		U_PLUGIN_ERROR_LIMIT:	66818,
		U_ERROR_LIMIT:	66818
	}
}

class TrayMenu {
	; ADD TRACKING FOR CHILD MENUS
	static __New() {
		this.menus := Map()
		this.menus.CaseSense := 0
		this.TrayMenu := A_TrayMenu
		this.menus["traymenu"] := A_TrayMenu
		this.menus[A_TrayMenu] := A_TrayMenu
	}

	static submenus[menuName] {
		set => this.menus[menuName] := value
		get {
			if (!this.menus.Has(menuName))
				this.menus[menuName] := Menu()
			return this.menus[menuName]
		}
	}
}

class BetterMenu extends Menu {
	static __New() {
		this.menus := Map()
		this.menus["traymenu"] := A_TrayMenu
		this.menus[A_TrayMenu] := A_TrayMenu
	}

	__New(menuName) {
		if (BetterMenu.menus.Has(menuName))
			this.menuObj := Menu()
		else {
			this.menuObj := Menu()
			BetterMenu[menuName] := this.menuObj
		}
	}
}

fastCopy(timeout := 1) {
	ClipboardOld := ClipboardAll()
	A_Clipboard := "" ; free clipboard so that ClipWait is more reliable
	Send("^c")
	if !ClipWait(timeout) {
		A_Clipboard := ClipboardOld
		return
	}
	text := A_Clipboard
	A_Clipboard := ClipboardOld
	return text
}

fastPrint(text) {
	ClipboardOld := ClipboardAll()
	A_Clipboard := ""
	A_Clipboard := text
	if !ClipWait(1) {
		A_Clipboard := ClipboardOld
		return 0
	}
	SendEvent("^v")
	Sleep(150)
	A_Clipboard := ClipboardOld
	return 1
}

; param method -> accept text + possible extra params
modifySelectedText(method, params*) {
	ClipboardOld := ClipboardAll()
	A_Clipboard := "" ; free clipboard so that ClipWait is more reliable
	Send("^c")
	if !ClipWait(1) {
		A_Clipboard := ClipboardOld
		return
	}
	A_Clipboard := method(A_Clipboard, params*)
	Send("^v")
	Sleep(150)
	A_Clipboard := ClipboardOld
	return 1
}

htmlDecode(str) {
	static HTMLCodes := jsongo.Parse(FileRead(A_WorkingDir "\everything\HTML_Encodings.json", "UTF-8"))
	if InStr(str, "&") {
		while (pos := RegExMatch(str, "(&.*?;)", &o, pos ?? 1) + (o ? o.Len : 0)) {
			if (HTMLCodes.Has(o[1]))
				str := StrReplace(str, o[1], HTMLCodes[o[1]])
		}
	}
	return str
}

parseHeaders(str) {
	headersAsText := RTrim(str, "`r`n")
	headers := Map()
	Loop Parse headersAsText, "`n", "`r" {
		arr := StrSplitUTF8(A_LoopField, ":")
		headers[Trim(arr[1])] := Trim(arr[2])
	}
	return headers
}

/**
 * Given a function fn, returns the largest possible value in given range where fn does not throw an error.
 * @param fn 
 * @param {Integer} lower 
 * @param {Integer} upper 
 */
tryCatchBinarySearch(fn, lower := 1, upper := 100000) {
	return binarySearch(newFn, lower, upper)
	
	newFn(param) {
		try {
			fn(param)
			return true
		}
		catch 
			return false
	}
}

/**
 * Given a function fn, returns the largest possible value in given range where fn returns true.
 * @param fn 
 * @param {Integer} lower 
 * @param {Integer} upper 
 */
binarySearch(fn, lower := 0, upper := 100000) {
	n := lower + (upper - lower)//2
	while(true) {
		if (Abs(lower - upper) <= 1)
			break
		if (fn(n))
			lower := n
		else
			upper := n
		n := lower + (upper - lower)//2
	}
	return n
}

ExecHelperScript(expression, wait := true, void := false) {
	input := '#Warn All, Off`n'
	input .= '#Include "*i ' A_LineFile '"`n'
	input .= '#Include "*i ' A_LineFile '\..\..\LibrariesV2\MathUtilities.ahk"`n'
	if (void || RegexMatch(expression, 'i)FileAppend\(.*,\s*\"\*\"\)') || RegExMatch(expression, 'i)MsgBox(?:AsGui)?\(.+\)') || RegexMatch(expression, 'i)print\(.*\)') || RegexMatch(expression, 'i)\.Show\(.*\)'))
		input .= expression
	else
		input .= 'print(' expression ',,false,true)'
	return ExecScript(input, wait)
}

ExecScript(input, Wait := true) {
	static shell := ComObject("WScript.Shell")
	exec := shell.Exec(A_AhkPath " /ErrorStdOut *")
	strConvBuf := Buffer(StrPut(input, "UTF-8"))
	StrPut(input, strConvBuf, "UTF-8")
	exec.StdIn.Write(StrGet(strConvBuf, "CP0"))
	exec.StdIn.Close()
	if !Wait
		return
	output := exec.StdOut.ReadAll()
	buf := Buffer(StrPut(output, "CP0"))
	StrPut(output, buf, "CP0")
	return RTrim(StrGet(buf, "UTF-8"), " `t`n")
}

cmdRet(sCmd, callBackFuncObj?, encoding := "CP" . DllCall("GetOEMCP", "UInt")) {
	; encoding := "CP" . DllCall("GetOEMCP", "UInt") ; CP0 -> Ansi, CP850 Western European Ansi.
	static HANDLE_FLAG_INHERIT := 0x1, CREATE_NO_WINDOW := 0x08000000, STARTF_USESTDHANDLES := 0x100, ptrsize := A_PtrSize

	DllCall("CreatePipe", "PtrP", &hPipeRead := 0, "PtrP", &hPipeWrite := 0, "Ptr", 0, "UInt", 0)
	DllCall("SetHandleInformation", "Ptr", hPipeWrite, "UInt", HANDLE_FLAG_INHERIT, "UInt", HANDLE_FLAG_INHERIT)

	STARTUPINFO := Buffer(size := ptrsize * 4 + 4 * 8 + ptrsize * 5, 0)
	NumPut("UInt", size, STARTUPINFO)
	NumPut("UInt", STARTF_USESTDHANDLES, STARTUPINFO, ptrsize * 4 + 4 * 7)
	NumPut("Ptr", hPipeWrite, "Ptr", hPipeWrite, STARTUPINFO, ptrsize * 4 + 4 * 8 + ptrsize * 3)

	PROCESS_INFORMATION := Buffer(ptrsize * 2 + 4 * 2, 0)
	if !DllCall("CreateProcess", "Ptr", 0, "Str", sCmd, "Ptr", 0, "Ptr", 0, "UInt", true, "UInt", CREATE_NO_WINDOW,
		"Ptr", 0, "Ptr", 0, "Ptr", STARTUPINFO, "Ptr", PROCESS_INFORMATION) {
		DllCall("CloseHandle", "Ptr", hPipeRead)
		DllCall("CloseHandle", "Ptr", hPipeWrite)
		throw(OSError("CreateProcess has failed"))
	}
	DllCall("CloseHandle", "Ptr", hPipeWrite)
	sTemp := Buffer(4096)
	sOutput := ""
	while DllCall("ReadFile", "Ptr", hPipeRead, "Ptr", sTemp, "UInt", 4096, "UIntP", &nSize := 0, "UInt", 0) {
		sOutput .= stdOut := StrGet(sTemp, nSize, encoding)
		if (IsSet(callBackFuncObj))
			callBackFuncObj(stdOut)
	}
	DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, "Ptr"))
	DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, ptrsize, "Ptr"))
	DllCall("CloseHandle", "Ptr", hPipeRead)
	return sOutput
}


cmdRetVoid(sCmd, finishCallBack?, encoding := "CP" . DllCall('GetOEMCP', 'UInt'), checkReturnInterval := 100) => cmdRetAsync(sCmd, unset, encoding, checkReturnInterval, finishCallBack?)

/**
 * Runs specified command in a command line interface without waiting for return value. optionally calls functions with return values
 * @param sCmd Command to run. If the Run equivalent was Run(A_Comspec " /c ping 8.8.8.8"), use sCmd = "ping 8.8.8.8" here.
 * @param callBackFuncObj Func Object accepting one parameter that will be called with the next line of console output every interval
 * @param {String} encoding String encoding. Defaults to your local codepage (eg western CP850). Else specify UTF-8 etc
 * @param {Integer} timePerCheck Time between each read of the console output
 * @param finishCallBack Func object to be called with the full output when the console is done
 * @returns {Integer} returns true if everything worked.
 */
cmdRetAsync(sCmd, callBackFuncObj?, encoding := "CP" . DllCall('GetOEMCP', 'UInt'), timePerCheck := 50, finishCallBack?, timeout?) {
	; encoding := "CP" . DllCall("GetOEMCP", "UInt") ; CP0 -> Ansi, CP850 Western European Ansi.
	static HANDLE_FLAG_INHERIT := 0x1, CREATE_NO_WINDOW := 0x08000000, STARTF_USESTDHANDLES := 0x100, ptrsize := A_PtrSize
	DllCall("CreatePipe", "PtrP", &hPipeRead := 0, "PtrP", &hPipeWrite := 0, "Ptr", 0, "UInt", 0)
	DllCall("SetHandleInformation", "Ptr", hPipeWrite, "UInt", HANDLE_FLAG_INHERIT, "UInt", HANDLE_FLAG_INHERIT)

	fullOutput := ""
	STARTUPINFO := Buffer(size := ptrsize * 4 + 4 * 8 + ptrsize * 5, 0)
	NumPut("UInt", size, STARTUPINFO)
	NumPut("UInt", STARTF_USESTDHANDLES, STARTUPINFO, ptrsize * 4 + 4 * 7)
	NumPut("Ptr", hPipeWrite, "Ptr", hPipeWrite, STARTUPINFO, ptrsize * 4 + 4 * 8 + ptrsize * 3)

	PROCESS_INFORMATION := Buffer(ptrsize * 2 + 4 * 2, 0)
	if !DllCall("CreateProcess", "Ptr", 0, "Str", sCmd, "Ptr", 0, "Ptr", 0, "UInt", true, "UInt", CREATE_NO_WINDOW,
		"Ptr", 0, "Ptr", 0, "Ptr", STARTUPINFO, "Ptr", PROCESS_INFORMATION) {
		DllCall("CloseHandle", "Ptr", hPipeRead)
		DllCall("CloseHandle", "Ptr", hPipeWrite)
		throw(OSError("CreateProcess has failed"))
	}
	DllCall("CloseHandle", "Ptr", hPipeWrite)
	sTemp := Buffer(4096)
	SetTimer(readFileCheck, timePerCheck)
	if IsSet(timeout)
		SetTimer(closeHandle, -1 * timeout)
	return 1

	readFileCheck() {
		if (DllCall("ReadFile", "Ptr", hPipeRead, "Ptr", sTemp, "UInt", 4096, "UIntP", &nSize := 0, "UInt", 0)) {
			fullOutput .= stdOut := StrGet(sTemp, nSize, encoding)
			if (IsSet(callBackFuncObj))
				callBackFuncObj(stdOut)
		} else {
			SetTimer(readFileCheck, 0)
			closeHandle(1)
		}
	}

	closeHandle(success := -1) {
		SetTimer(closeHandle, 0)
		SetTimer(readFileCheck, 0)
		DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, "Ptr"))
		DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, ptrsize, "Ptr"))
		DllCall("CloseHandle", "Ptr", hPipeRead)
		if (IsSet(finishCallBack))
			finishCallBack(fullOutput, success)
	}
}

execShell(command) {
	shell := ComObject("WScript.Shell")
	exec := shell.Exec(A_Comspec " /C " command)
	return exec.StdOut.ReadAll()
}

menu_RemoveSpace(menuHandle, applyToSubMenus := true) {
	; http://msdn.microsoft.com/en-us/library/ff468864(v=vs.85).aspx
	static MIsize := (4 * 4) + (A_PtrSize * 3)
	MI := Buffer(MIsize, 0)
	Numput("UInt", MIsize, MI, 0)
	NumPut("UInt", 0x00000010, MI, 4) ; MIM_STYLE = 0x00000010
	DllCall("User32.dll\GetMenuInfo", "Ptr", menuHandle, "Ptr", MI, "UInt")
	if (applyToSubMenus)
		NumPut("UInt", 0x80000010, MI, 4) ; MIM_APPLYTOSUBMENUS = 0x80000000| MIM_STYLE : 0x00000010
	NumPut("UInt", NumGet(MI, 8, "UINT") | 0x80000000, MI, 8) ; MNS_NOCHECK = 0x80000000
	DllCall("User32.dll\SetMenuInfo", "Ptr", menuHandle, "Ptr", MI, "UInt")
	return true
}


/**
 * Opens Color picking Window
 * @param Color 
 * @param {Integer} hGui 
 * @returns {Integer} 
 */
colorDialog(initialColor := 0, hwnd := 0, disp := false, startingColors*) {
	static p := A_PtrSize
	disp := disp ? 0x3 : 0x1 ; init disp / 0x3 = full panel / 0x1 = basic panel

	if (startingColors.Length > 16)
		throw(Error("Too many custom colors.  The maximum allowed values is 16."))

	Loop (16 - startingColors.Length)
		startingColors.Push(0) ; fill out custColorObj to 16 values

	CUSTOM := Buffer(16 * 4, 0) ; init custom colors obj
	CHOOSECOLOR := Buffer((p == 4) ? 36 : 72, 0) ; init dialog

	for i, e in startingColors
		NumPut("UInt", format_argb(e), CUSTOM, (i-1) * 4)

	NumPut("UInt", CHOOSECOLOR.size, CHOOSECOLOR, 0)             ; lStructSize
	NumPut("UPtr", hwnd, CHOOSECOLOR, p)             ; hwndOwner
	NumPut("UInt", format_argb(initialColor), CHOOSECOLOR, 3 * p)         ; rgbResult
	NumPut("UPtr", CUSTOM.ptr, CHOOSECOLOR, 4 * p)         ; lpCustColors
	NumPut("UInt", disp, CHOOSECOLOR, 5 * p)         ; Flags

	if !DllCall("comdlg32\ChooseColor", "UPtr", CHOOSECOLOR.ptr, "UInt")
		return -1
	return format_argb(NumGet(CHOOSECOLOR, 3 * A_PtrSize, "UInt"))
}
; typedef struct tagCHOOSECOLORW {  offset      size    (x86/x64)
; DWORD        lStructSize;       |0      |   4
; HWND         hwndOwner;         |4 / 8  |   8 /16
; HWND         hInstance;         |8 /16  |   12/24
; COLORREF     rgbResult;         |12/24  |   16/28
; COLORREF     *lpCustColors;     |16/28  |   20/32
; DWORD        Flags;             |20/32  |   24/36
; LPARAM       lCustData;         |24/40  |   28/48 <-- padding for x64
; LPCCHOOKPROC lpfnHook;          |28/48  |   32/56
; LPCWSTR      lpTemplateName;    |32/56  |   36/64
; LPEDITMENU   lpEditInfo;        |36/64  |   40/72
; } CHOOSECOLORW, *LPCHOOSECOLORW;
; https://github.com/cobracrystal/ahk

colorGradientArr(amount, colors*) {
	sColors := [], gradient := []
	if (amount < colors.Length-2)
		return 0
	else if (amount == colors.Length-2)
		return colors
	for index, color in colors
		sColors.push({r:(color & 0xFF0000) >> 16, g: (color & 0xFF00) >> 8, b:color & 0xFF})
	; first color given, format with 6 padded 0s in case of black
	gradient.push(format("0x{:06X}", colors[1]))
	; amount of color gradients to perform
	segments := colors.Length-1
	Loop(amount) {
		; current gradient segment we are in
		segment := floor((A_Index/(amount+1))*segments)+1
		; percentage progress in the current gradient segment as decimal
		segProgress := ((A_Index/(amount+1)*segments)-segment+1)
		; RGB obtained via percentage * (end of gradient - start of gradient), then adding current RGB value again.
		r := round((segProgress * (sColors[segment+1].r-sColors[segment].r))+sColors[segment].r)
		g := round((segProgress * (sColors[segment+1].g-sColors[segment].g))+sColors[segment].g)
		b := round((segProgress * (sColors[segment+1].b-sColors[segment].b))+sColors[segment].b)
		gradient.Push(format("0x{1:02X}{2:02X}{3:02X}", r, g, b))
	}
	; last color given, same as first
	gradient.Push(format("0x{:06X}", colors[-1]))
	; return array of amount+2 colors
	return gradient
}

rainbowArr(num, intensity := 0xFF) {
	if (num < 7)
		throw(ValueError("Invalid num"))
	if (intensity < 0 || intensity > 255)
		throw(ValueError("Invalid Intensity"))
	intensity := format("{:#x}", intensity)
	r := intensity * 0x010000
	g := intensity * 0x000100
	b := intensity * 0x000001
	return colorGradientArr(num-2, r, r|g//2, r|g, g, g|b, g//2|b, b, b|r, r)
}

/**
 * calculates brightness as per Rec 709 Television coefficients.
 * @param color standard RGB color
 * @returns {Number} Value between 0-255. 0-127 is dark, above is bright
 */
getBrightness(color) {
	color := Integer(color)
	r := (color & 0xFF0000) >> 16
	g := (color & 0xFF00) >> 8
	b := (color & 0xFF)
	return 0.2126 * r + 0.7152 * g + 0.0722 * b
}

isDark(color) {
	return getBrightness(color) < 128
}

/**
 * given color in (A)RGB/(A)BGR format, reverse formats and add or remove alpha value. set alpha to -1 to remove
 * @param {Integer} clr 
 * @param {Integer} reverse 
 * @param {Integer} alpha 
 */
format_argb(color, reverse := true, alpha?) {
	color := Integer(color)
	if (reverse)
		color := (color & 0xFF) << 16 | (color & 0xFF00) | ((color & 0xFF0000) >> 16)
	;	clr := (clr >> 16 & 0xFF) | (clr & 0xFF00) | (clr << 16 & 0xFF0000) ; equivalent to above
	clrAlpha := IsSet(alpha) ? (alpha == -1 ? 0 : alpha): (color & 0xFF000000) >> 24
	return (clrAlpha << 24 | color)
}

; 0xFF00F9
colorPreviewGUI(color) {
	if (!RegexMatch(color, "(?:0x)?[[:xdigit:]]{1,6}"))
		return
	CoordMode("Mouse")
	MouseGetPos(&x, &y)
	colorPreview := Gui("+AlwaysOnTop +LastFound +ToolWindow -Caption")
	colorPreview.BackColor := color
	colorPreview.Show("x" . x-30 . " y" . y-30 . "w50 h50 NoActivate")
	SetTimer((*) => colorPreview.Destroy(), -1500)
}

timedTooltip(text := "", durationMS := 1000, x?, y?, whichTooltip?) {
	ToolTip(text, x?, y?, whichTooltip?)
	SetTimer(IsSet(whichTooltip) ? stopTooltip.bind(whichTooltip) : stopTooltip, -1 * durationMS)

	stopTooltip(whichTooltip?) {
		ToolTip(, , , whichTooltip?)
	}
}


; parse options string into the msgboxasgui options
; MsgBoxAsGuiO(text := "Press OK to continue", title := A_ScriptName, options := "0", funcObj?) {

; 	MsgBoxAsGui(text, title, buttonStyle, defaultButton, wait, funcObj?, owner?, addCopyButton, buttonNames, icon?, timeout?, maxCharsVisible?, maxTextWidth)
; 	/*
;     Icon
; 	static Error      => 0x10
; 	static Question   => 0x20
; 	static Warning    => 0x30
; 	static Info       => 0x40

;     static Default2       => 0x100
;     static Default3       => 0x200
;     static Default4       => 0x300

;     static SystemModal    => 0x1000
;     static TaskModal      => 0x2000
;     static AlwaysOnTop    => 0x40000

;     static HelpButton     => 0x4000
;     static RightJustified => 0x80000
;     static RightToLeft    => 0x100000
; 	*/
; }

MsgBoxAsGui(text := "Press OK to continue", title := A_ScriptName, buttonStyle := 0, defaultButton := 1, wait := false, funcObj?, owner?, addCopyButton := 0, buttonNames := [], icon?, timeout?, maxCharsVisible?, maxTextWidth?) {
	; button choices
	static MB_BUTTON_TEXT := [
		["OK"],
		["OK", "Cancel"],
		["Abort", "Retry", "Ignore"],
		["Yes", "No", "Cancel"],
		["Yes", "No"],
		["Retry", "Cancel"],
		["Cancel", "Retry", "Continue"]
	]
	; icons
	static DEFAULT_ICONS := Map(
		"x", 0x5E, "MB_ICONHANDERROR", 0x5E,
		"?", 0x5F, "MB_ICONQUESTION", 0x5F,
		"!", 0x50, "MB_ICONEXCLAMATION", 0x50,
		"i", 0x4D, "MB_ICONASTERISKINFO", 0x4D
	)
	static ICON_SOUNDS := Map(
		DEFAULT_ICONS["MB_ICONHANDERROR"], "*16",
		DEFAULT_ICONS["MB_ICONQUESTION"], "*32",
		DEFAULT_ICONS["MB_ICONEXCLAMATION"], "*48",
		DEFAULT_ICONS["MB_ICONASTERISKINFO"], "*64"
	)
	static MB_FONTNAME, MB_FONTSIZE, MB_FONTWEIGHT, MB_FONTISITALIC
	static MB_HASFONTINFORMATION := getMsgBoxFontInfo(&MB_FONTNAME, &MB_FONTSIZE, &MB_FONTWEIGHT, &MB_FONTISITALIC)

	static gap := 26			; Spacing above and below text in top area of the Gui
	static buttonMargin := 12	; Left Gui margin
	static rightMargin := 8		; Space between right side of button and next button / gui edge
	static buttonWidth := 88	; Width of OK button
	static buttonHeight := 26	; Height of OK button
	static buttonOffset := 30	; Offset between the right side of text and right edge of button
	static buttonSpace := buttonWidth + rightMargin
	static leftMargin := 20
	static minGuiWidth := 138	; Minimum width of Gui
	static minTextWidth := 400
	static SS_WHITERECT := 0x0006	; Gui option for white rectangle (http://ahkscript.org/boards/viewtopic.php?p=20053#p20053)
	static NecessaryStyle := 0x94C80000
	static SS_NOPREFIX := 0x80 ; no ampersand nonsense
	
	static WM_KEYDOWN := 0x0100
	static WM_RBUTTONDOWN := 0x0204
	
	if (buttonNames.Length == 0) {
		if !(MB_BUTTON_TEXT.Has(buttonStyle + 1)) ; offset since this is not 0-indexed
			throw Error("Invalid button Style")
		buttonNames := MB_BUTTON_TEXT[buttonStyle + 1]
	}
	retValue := ""
	totalButtonWidth := buttonSpace * (buttonNames.Length + (addCopyButton ? 1 : 0))
	ownerStr := IsSet(owner) ? "+Owner" owner : ''
	guiFontOptions := MB_HASFONTINFORMATION ? "S" MB_FONTSIZE " W" MB_FONTWEIGHT (MB_FONTISITALIC ? " italic" : "") : ""
	mbGui := Gui("+ToolWindow -Resize -MinimizeBox -MaximizeBox " ownerStr, title)
	mbGui.OnEvent("Close", finalEvent.bind(0))
	mbGui.Opt("+" hex(NecessaryStyle))
	mbGui.Opt("-ToolWindow")
	if (buttonStyle == 2 || buttonStyle == 4) ; if cancel is not present in option, close and escape have no effect. user must select an option.
		mbGui.Opt("-SysMenu")
	mbGui.SetFont(guiFontOptions, MB_FONTNAME)
	if IsObject(text)
		text := toString(text, 0, 0, true)
	if !IsSet(maxTextWidth) {
		maxTextWidth := Max(minTextWidth, totalButtonWidth)
		lens := strGetSplitLen(IsSet(maxCharsVisible) ? SubStr(text, 1, maxCharsVisible) : text, "`n")
		minim := min(lens*), maxim := max(lens*), avg := objGetSum(lens) / lens.Length
		if (2 * avg > maxim && maxim < 1500)
			maxTextWidth := Max(minTextWidth, maxim)
		if StrLen(text) > 10000 && !IsSet(maxCharsVisible)
			maxTextWidth := 1500
	}
	ctrlText := textCtrlAdjustSize(maxTextWidth,, IsSet(maxCharsVisible) ? SubStr(text, 1, maxCharsVisible) : text,, guiFontOptions, MB_FONTNAME)
	mbGui.AddText("x0 y0 vWhiteBoxTop " SS_WHITERECT, ctrlText)
	if (IsSet(icon)) {
		iconPath := icon is Array ? icon[2] : "imageres.dll"
		icon := (icon is Array ? icon[1] : icon)
		icon := DEFAULT_ICONS.Has(icon) ? DEFAULT_ICONS[icon] : icon
		mbGui.AddPicture(Format("x{} y{} w{} h{} Icon{} BackgroundTrans", leftMargin, gap-9, 32, 32, icon), iconPath)
		ICON_SOUNDS.Has(icon) ? SoundPlay(ICON_SOUNDS[icon], 0) : 0
	}
	mbGui.AddText("x" leftMargin + (IsSet(icon) ? 32 + buttonMargin : 0) " y" gap " BackgroundTrans " SS_NOPREFIX " vTextBox", ctrlText)
	mbGui["TextBox"].GetPos(&TBx, &TBy, &TBw, &TBh)
	guiWidth := buttonMargin + buttonOffset + Max(TBw, totalButtonWidth) + 1
	guiWidth := Max(guiWidth, minGuiWidth)
	whiteBoxHeight := TBy + TBh + gap
	mbGui["WhiteBoxTop"].Move(0, 0, guiWidth, whiteBoxHeight)
	buttonX := guiWidth - totalButtonWidth ; the buttons are right-aligned
	buttonY := whiteBoxHeight + buttonMargin
	for i, e in buttonNames
		btn := mbGui.AddButton(Format("vButton{} x{} y{} w{} h{}", i, buttonX + (i-1) * buttonSpace, buttonY, buttonWidth, buttonHeight), e).OnEvent("Click", finalEvent.bind(i))
	if (addCopyButton)
		btn := mbGui.AddButton(Format("vButton0 x{} y{} w{} h{}", buttonX + buttonNames.Length * buttonSpace, buttonY, buttonWidth, buttonHeight), "Copy").OnEvent("Click", (guiCtrl, infoObj) => (A_Clipboard := text))
	defaultButton := defaultButton == "Copy" ? 0 : defaultButton
	mbGui["Button" defaultButton].Focus()
	guiHeight := whiteBoxHeight + buttonHeight + 2 * buttonMargin
	if (buttonStyle != 2 && buttonStyle != 4)
		mbGui.OnEvent("Escape", finalEvent.bind(0))
	mbGui.OnEvent("Close", finalEvent.bind(0))
	OnMessage(WM_KEYDOWN, guiNotify)
	OnMessage(WM_RBUTTONDOWN, guiNotify)
	mbGui.Show("Center w" guiWidth " h" guiHeight)
	if IsSet(timeout)
		SetTimer(timeoutFObj := finalEvent.bind(-1), -1000 * timeout)
	if (wait) {
		WinWait(hwnd := mbGui.hwnd)
		WinWaitClose(hwnd)
		mbGui := 0
		OnMessage(WM_KEYDOWN, guiNotify, 0) ; unregister
		OnMessage(WM_RBUTTONDOWN, guiNotify, 0)
		return retValue
	}
	return mbGui

	finalEvent(buttonNumber, *) {
		mbGui.Destroy()
		mbGui := 0
		OnMessage(WM_KEYDOWN, guiNotify, 0) ; unregister
		OnMessage(WM_RBUTTONDOWN, guiNotify, 0)
		if (IsSet(timeout))
			SetTimer(timeoutFObj, 0)
		retValue := buttonNumber == -1 ? "Timeout" : buttonNumber == 0 ? "Cancel" : buttonNames[buttonNumber]
		if (IsSet(funcObj))
			funcObj(retValue)
	}

	guiNotify(wParam, lParam, msg, hwnd) {
		if (!mbGui) {
			OnMessage(WM_KEYDOWN, guiNotify, 0) ; unregister
			OnMessage(WM_RBUTTONDOWN, guiNotify, 0)
		} else if ((ctrl := GuiCtrlFromHwnd(hwnd)) && (ctrl.gui.hwnd == mbGui.hwnd)) || (hwnd == mbGui.hwnd) {
			if (msg == WM_KEYDOWN) && (wParam == 67) && GetKeyState("Ctrl") {
				A_Clipboard := text
				return 0 ; prevents sound
			} else if !ctrl {
				m := Menu()
				m.Add("Select Text", guiContextMenu)
				m.show()
			}
		}
	}

	guiContextMenu(itemName, itemPos, menuObj) {
		miniGui := Gui("+ToolWindow -Resize -MinimizeBox -MaximizeBox +Owner" mbGui.hwnd, "Select and Copy")
		miniGui.Opt("+" hex(NecessaryStyle))
		miniGui.Opt("-ToolWindow")
		miniGui.OnEvent("Escape", (*) => miniGui.destroy())
		miniGui.OnEvent("Close", (*) => miniGui.destroy())
		miniGui.MarginX := miniGui.MarginY := 2
		miniGui.SetFont(guiFontOptions, MB_FONTNAME)
		miniGui.AddEdit("-E0x200 ReadOnly w" guiWidth " h" whiteBoxHeight, text)
		miniGui.show()
	}
}



getMsgBoxFontInfo(&name := "", &size := 0, &weight := 0, &isItalic := 0) {
	; SystemParametersInfo constant for retrieving the metrics associated with the nonclient area of nonminimized windows
	static SPI_GETNONCLIENTMETRICS := 0x0029

	static NCM_Size        := 40 + 5 * 92   ; Size of NONCLIENTMETRICS structure (not including iPaddedBorderWidth)
	static MsgFont_Offset  := 40 + 4 * 92   ; Offset for lfMessageFont in NONCLIENTMETRICS structure
	static Size_Offset     := 0    ; Offset for cbSize in NONCLIENTMETRICS structure

	static Height_Offset   := 0    ; Offset for lfHeight in LOGFONT structure
	static Weight_Offset   := 16   ; Offset for lfWeight in LOGFONT structure
	static Italic_Offset   := 20   ; Offset for lfItalic in LOGFONT structure
	static FaceName_Offset := 28   ; Offset for lfFaceName in LOGFONT structure
	static FACESIZE        := 32   ; Size of lfFaceName array in LOGFONT structure
	; Maximum number of characters in font name string

	NCM := Buffer(NCM_Size, 0)
	NumPut("UInt", NCM_Size, NCM, Size_Offset)   ; Set the cbSize element of the NCM structure
	; Get the system parameters and store them in the NONCLIENTMETRICS structure (NCM)
	if !DllCall("SystemParametersInfo", "UInt", SPI_GETNONCLIENTMETRICS, "UInt", NCM_Size, "Ptr", NCM.Ptr, "UInt", 0)                        ; Don't update the user profile
		return false                               ; Return false
	name   := StrGet(NCM.Ptr + MsgFont_Offset + FaceName_Offset, FACESIZE)          ; Get the font name
	height := NumGet(NCM.Ptr + MsgFont_Offset + Height_Offset, "Int")               ; Get the font height
	size   := DllCall("MulDiv", "Int", -Height, "Int", 72, "Int", A_ScreenDPI)   ; Convert the font height to the font size in points
	; Reference: http://stackoverflow.com/questions/2944149/converting-logfont-height-to-font-size-in-points
	weight   := NumGet(NCM.Ptr + MsgFont_Offset + Weight_Offset, "Int")             ; Get the font weight (400 is normal and 700 is bold)
	isItalic := NumGet(NCM.Ptr + MsgFont_Offset + Italic_Offset, "UChar")           ; Get the italic state of the font
	return true
}


textCtrlAdjustSize(width, textCtrl?, str?, onlyCalculate := false, fontOptions?, fontName?) {
	if (!IsSet(textCtrl) && !IsSet(str))
		throw Error("Both textCtrl and str were not set")
	if (!IsSet(str))
		str := textCtrl.Value
	else if (!IsSet(textCtrl)) {
		local temp := Gui()
		temp.SetFont(fontOptions ?? unset, fontName ?? unset)
		textCtrl := temp.AddText()
		onlyCalculate := true
	}
	fixedWidthStr := ""
	loop parse str, "`n", "`r" {
		fixedWidthLine := ""
		fullLine := A_LoopField
		pos := 0
		loop parse fullLine, " `t" {
			line := A_LoopField
			lLen := StrLen(A_LoopField)
			pos += lLen + 1
			strWidth := guiGetTextSize(textCtrl, fixedWidthLine . line)
			if (pos > 65535)
				break
			if (strWidth[1] <= width)
				fixedWidthLine .= line . substr(fullLine, pos, 1)
			else { ; reached max width, begin new line
				fixedWidthStr .= (fixedWidthStr ? '`n' : '') . fixedWidthLine
				if (guiGetTextSize(textCtrl, line)[1] <= width) {
					fixedWidthLine := line . substr(fullLine, pos, 1)
				} else { ; A_Loopfield is by itself wider than width
					fixedWidthLine := fixedWidthWord := linePart := ""
					loop parse line { ; thus iterate char by char
						curWidth := guiGetTextSize(textCtrl, linePart . A_LoopField)
						if (curWidth[1] <= width) ; reached max width, begin new line
							linePart .= A_LoopField
						else {
							fixedWidthWord .= '`n' linePart
							linePart := A_LoopField
						}
					}
					fixedWidthStr .= (fixedWidthStr == "" ? SubStr(fixedWidthWord, 2) : fixedWidthWord) . (linePart == "" ? '' : '`n' linePart)
				}
			}
		}
		fixedWidthStr .= (fixedWidthStr ? '`n' : '') fixedWidthLine . substr(fullLine, pos, 1)
	}
	if (!onlyCalculate) {
		textCtrl.Move(,,guiGetTextSize(textCtrl, fixedWidthStr)*)
		textCtrl.Value := fixedWidthStr
	}
	return fixedWidthStr
}

guiGetTextSize(txtCtrlObj, str) {
	static WM_GETFONT := 0x0031
	static DT_CALCRECT := 0x400
	DC := DllCall("GetDC", "Ptr", txtCtrlObj.Hwnd, "Ptr")
	hFont := SendMessage(WM_GETFONT,,, txtCtrlObj)
	hOldObj := DllCall("SelectObject", "Ptr", DC, "Ptr", hFont, "Ptr")
	height := DllCall("DrawText", "Ptr", DC, "Str", str, "Int", -1, "Ptr", rect := Buffer(16, 0), "UInt", DT_CALCRECT)
	width := NumGet(rect, 8, "Int") - NumGet(rect, "Int")
	DllCall("SelectObject", "Ptr", DC, "Ptr", hOldObj, "Ptr")
	DllCall("ReleaseDC", "Ptr", txtCtrlObj.Hwnd, "Ptr", DC)
	return [width, height]
}

scrollbarGetPosition(ctrlHwnd) {
	static SIF_RANGE := 0x01
	static SIF_PAGE := 0x02
	static SIF_POS := 0x04
	static SIF_TRACKPOS := 0x10
	static SIF_ALL := (SIF_RANGE | SIF_PAGE | SIF_POS | SIF_TRACKPOS)
	static SB_HORZ := 0
	static SB_VERT := 1
	static SB_CTL := 2
	static SB_BOTH := 3
	static SB_BOTTOM := 7
	static WM_VSCROLL := 0x115
	
	NumPut("UInt", 28, ScrollInfo := Buffer(28, 0))
	NumPut("UInt", SIF_ALL, ScrollInfo, 4)
	DllCall("GetScrollInfo", "uint", ctrlHwnd, "int", SB_VERT, "Ptr", ScrollInfo)
	nMin := NumGet(ScrollInfo, 8, "int")
	nMax := NumGet(ScrollInfo, 12, "int")
	nPage := NumGet(ScrollInfo, 16, "uint")
	curPos := NumGet(ScrollInfo, 20, "uint")
	return curPos ? curPos / (nMax - nPage + 1 - nMin) : 0
}

structRectCreate(x1, y1, x2, y2) {
	NumPut("UInt", x1, "UInt", y1, "UInt", x2, "UInt", y2, llrectA := Buffer(16, 0), 0)
	return llrectA
}

structRectGet(rect) {
	x1 := NumGet(rect, 0, "int")
	y1 := NumGet(rect, 4, "int")
	x2 := NumGet(rect, 8, "int")
	y2 := NumGet(rect, 12, "int")
	return [x1, y1, x2, y2]
}

class DataListView { ; this is (mostly) based on Pulover's LV_Rows class, ignoring LV_EX. See https://github.com/Pulover/Class_LV_Rows
	
	__New(LV) {
		this.LV := LV
		this.Base := LV ; !!!!!!!!!!!!!!!!!!!!
		this.rowData := {}
		this.headers := []
		return this
	}
	
	Add(Options?, Cols*) => this.LV.Add(options?, cols*)
	Insert(RowNumber , Options?, Cols*)  => this.LV.Insert(RowNumber , Options?, Cols*) 
	Modify(RowNumber, Options?, NewCols*)  => this.LV.Modify(RowNumber, Options?, NewCols*) 
	Delete(RowNumber?) => this.LV.Delete(rowNumber?)
	
	InsertCol(ColumnNumber, Options?, ColumnTitle?)  => this.LV.InsertCol(ColumnNumber, Options?, ColumnTitle?) 
	ModifyCol(ColumnNumber?, Options?, ColumnTitle?)  => this.LV.ModifyCol(ColumnNumber?, Options?, ColumnTitle?) 
	DeleteCol(ColumnNumber) => this.LV.DeleteCol(ColumnNumber)
	
	GetCount(Mode?)  => this.LV.GetCount(Mode?) 
	GetNext(StartingRowNumber?, RowType?)  => this.LV.GetNext(StartingRowNumber?, RowType?) 
	GetText(RowNumber, ColumnNumber?) => this.LV.GetText(RowNumber, ColumnNumber?)
	
	SetImageList(ImageListID, IconType?)  => this.LV.SetImageList(ImageListID, IconType?)

	OnEvent(EventName, Callback, AddRemove?) => (this.LV.OnEvent(EventName, Callback, AddRemove?), this)

	Rows() {
		; enumerator
		index := 1
		return (&n) => (
			; this.rowData ; enumerate this
			index++
			true 
		)
	}

	Copy() {
		return 0
	}

	Cut() {
		return 0
	}

	Paste() {
		return 0
	}

	Duplicate() {
		return 0
	}

	; Delete() {
	; 	return 0
	; }

	MoveUp() {
		return 0
	}

	MoveDown() {
		return 0
	}

	Drag() {
		return 0
	}
}

base64Encode(str, encoding := "UTF-8") {
	static CRYPT_STRING_BASE64 := 0x00000001
	static CRYPT_STRING_NOCRLF := 0x40000000

	binary := Buffer(StrPut(str, encoding))
	StrPut(str, binary, encoding)
	if !(DllCall("crypt32\CryptBinaryToStringW", "Ptr", binary, "UInt", binary.Size - 1, "UInt", (CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF), "Ptr", 0, "UInt*", &size := 0))
		throw(OSError())
	base64 := Buffer(size << 1, 0)
	if !(DllCall("crypt32\CryptBinaryToStringW", "Ptr", binary, "UInt", binary.Size - 1, "UInt", (CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF), "Ptr", base64, "UInt*", size))
		throw(OSError())
	return StrGet(base64)
}

base64Decode(base64, encoding := "UTF-8") {
	static CRYPT_STRING_BASE64 := 0x00000001

	if !(DllCall("crypt32\CryptStringToBinaryW", "Str", base64, "UInt", 0, "UInt", CRYPT_STRING_BASE64, "Ptr", 0, "UInt*", &size := 0, "Ptr", 0, "Ptr", 0))
		throw(OSError())
	str := Buffer(size)
	if !(DllCall("crypt32\CryptStringToBinaryW", "Str", base64, "UInt", 0, "UInt", CRYPT_STRING_BASE64, "Ptr", str, "UInt*", size, "Ptr", 0, "Ptr", 0))
		throw(OSError())
	return StrGet(str, "UTF-8")
}

sendRequest(url := "https://icanhazip.com/", method := "GET", encoding := "UTF-8", async := false, callBackFuncObj := "") {
	if (async) {
		if (callBackFuncObj == "")
			throw(ValueError("No callback function provided for async request."))
		whr := ComObject("Msxml2.XMLHTTP")
		whr.Open(method, url, true)
		whr.OnReadyStateChange := callBackFuncObj
		whr.Send()
	}
	else
		whr := ComObject("WinHttp.WinHttpRequest.5.1")
	whr.Open(method, url, true)
	whr.Send()
	whr.WaitForResponse()
	if !(whr.ResponseBody)
		return ""
	arr := whr.ResponseBody
	pData := NumGet(ComObjValue(arr) + 8 + A_PtrSize, 0, "UPtr")
	length := (arr.MaxIndex() - arr.MinIndex()) + 1
	return Trim(StrGet(pData, length, encoding), "`n`r`t ")
}

/**
 * Given a path, removes any backtracking of paths through \..\ to create a unique absolute path.
 * @param path Path to normalize
 * @returns {string} A normalized Path (if valid) or an empty string if the path could not be resolved.
 */
normalizePath(path) {
	path := StrMultiReplace(path, ["\\", "/"], ["\", "\"]) ; ignore \\, /->\
	while InStr(path, "\.\") ; \.\ does nothing since . is current file
		path := StrReplace(path, "\.\", "\")
	if (SubStr(path, -2) == "\.")
		path := SubStr(path, 1, -2)
	path := Trim(path, " `t\")
	pathArr := StrSplit(path, "\")
	i := 1
	while(i <= pathArr.Length) {
		if (pathArr[i] != "..")
			i++
		else {
			patharr.RemoveAt(i)
			if i > 2 ; pathArr[1] is the drive. C:\..\Users\..\..\Users => C:\Users
				pathArr.RemoveAt(--i)
		}
	}
	return objCollect(pathArr, (b, e) => b "\" e)
}

tryEditTextFile(editor := A_WinDir . "\system32\notepad.exe", params := "", *) {
	if (InStr(editor, A_Space) && SubStr(editor, 1, 1) != '"' && SubStr(editor, -1, 1) != '"')
		editor := '"' editor '"'
	try
		Run(editor ' ' params)
	catch
		try Run(A_WinDir . '\system32\notepad.exe ' . params)
	; Run('"' A_ProgramFiles . '\Notepad++\notepad++.exe" "' . path '"')
	; Run('Notepad++ "' . path '"')
}


doNothing(*) {
	return
}

; class ExGui {

; 	__New(debug := 0, useTrayMenu := 0, name := "ExGUI") {

; 		this.settingsManager("Load")
; 		this.settings.debug := debug

; 		this.menu := this.createMenu()
; 		if (useTrayMenu) {
; 			tableFilterMenu := TrayMenu.submenus["tablefilter"]
; 			tableFilterMenu.Add("Open GUI", (*) => this.guiCreate())
; 			tableFilterMenu.Add("Use Dark Mode", (iName, iPos, menuObj) => this.settingsHandler("Darkmode", -1, true, menuObj, iName))
; 			if (this.settings.darkMode)
; 				tableFilterMenu.Check("Use Dark Mode")
; 		}
; 		A_TrayMenu.Add("ExGUI", tableFilterMenu)
; 	}

; 	guiCreate() {
; 		newGui := Gui("+Border")
; 		newGui.OnEvent("Close", this.guiClose.bind(this))
; 		newGui.OnEvent("Escape", this.guiClose.bind(this))
; 		newGui.OnEvent("DropFiles", this.dropFiles.bind(this))
; 		newGui.SetFont("c0x000000") ; this is necessary to force font of checkboxes / groupboxes
; 		newGui.Show("AutoSize")
; 	}

; 	toggleGuiDarkMode(_gui, dark) {
; 		static WM_THEMECHANGED := 0x031A
; 		;// title bar dark
; 		if (VerCompare(A_OSVersion, "10.0.17763")) {
; 			attr := 19
; 			if (VerCompare(A_OSVersion, "10.0.18985")) {
; 				attr := 20
; 			}
; 			DllCall("dwmapi\DwmSetWindowAttribute", "ptr", _gui.hwnd, "int", attr, "int*", dark ? true : false, "int", 4)
; 		}
; 		_gui.BackColor := (dark ? this.settings.darkThemeColor : "Default") ; "" <-> "Default" <-> 0xFFFFFF
; 		font := (dark ? "c" this.settings.darkThemeFontColor : "cDefault")
; 		_gui.SetFont(font)
; 		for cHandle, ctrl in _gui {
; 			ctrl.Opt(dark ? "+Background" this.settings.darkThemeColor : "-Background")
; 			ctrl.SetFont(font)
; 			if (ctrl is Gui.Button || ctrl is Gui.ListView) {
; 				; todo: listview headers dark -> https://www.autohotkey.com/boards/viewtopic.php?t=115952
; 				; and https://www.autohotkey.com/board/topic/76897-ahk-u64-issue-colored-text-in-listview-headers/
; 				; maybe https://www.autohotkey.com/boards/viewtopic.php?t=87318
; 				DllCall("uxtheme\SetWindowTheme", "ptr", ctrl.hwnd, "str", (dark ? "DarkMode_Explorer" : ""), "ptr", 0)
; 			}
; 			if (ctrl.Name && SubStr(ctrl.Name, 1, 10) == "EditAddRow") {
; 				this.validValueChecker(ctrl)
; 			}
; 		}
; 		; todo: setting to make this look like this ?
; 		; DllCall("uxtheme\SetWindowTheme", "ptr", _gui.LV.hwnd, "str", "Explorer", "ptr", 0)
; 	}

; 	guiClose(guiObj) {
; 		objRemoveValue(this.guis, guiObj)
; 		guiObj.Destroy()
; 	}

; 	dropFiles(gui, ctrlObj, fileArr, x, y) {
; 		if (fileArr.Length > 1)
; 			return
; 		this.loadData(fileArr[1], gui)
; 	}

; 	settingsHandler(setting := "", value := "", save := true, extra*) {
; 		switch setting, 0 {
; 			case "darkmode":
; 				this.settings.darkMode := (value == -1 ? !this.settings.darkMode : value)
; 				this.toggleDarkMode(this.settings.darkMode, extra*)
; 			default:
; 				throw(Error("uhhh setting: " . setting))
; 		}
; 		if (save)
; 			this.settingsManager("Save")
; 	}


; 	static getDefaultSettings() {
; 		settings := {
; 			debug: false,
; 			darkMode: true,
; 			darkThemeColor: "0x1E1E1E",
; 			darkThemeFontColor: "0xFFFFFF"
; 		}
; 		return settings
; 	}
; }


print(value, options?, putNewline := true, compress := false, compact := false, strEscape := true) {
	if IsObject(value) { 
		value := toString(value, compact, compress, strEscape)	
	}
	if (putNewline == true || (putNewline == -1 && InStr(value, '`n')))
		finalChar := '`n'
	else
		finalChar := ''
	try 
		FileAppend(value . finalChar, "*", options ?? "UTF-8")
	catch Error 
		MsgBoxAsGui(value,,,,,,,1)
	return value
}

/**
 * tiles given or all windows
 * @param windowArray array of window HWNDs to be tiled
 * @param {Integer} tilingMode 0 or 1, vertical or horizontal
 * @param tileArea Area in which windows will be tiled. Given in the form [x1, y1, x2, y2]
 * @param {Integer} hwndParent HWND of parent window of the windows to be tiled
 * @returns {Integer} Count of tiled windows 
 */
tileWindows(windowArray?, tilingMode := 0x0000, tileArea?, hwndParent := 0)  {
	static MDITILE_VERTICAL 	:= 0x0000
	static MDITILE_HORIZONTAL 	:= 0x0001
	static MDITILE_SKIPDISABLED := 0x0002
	static MDITILE_ZORDER 		:= 0x0004
	flagTileArea := IsSet(tileArea)
	if (flagTileArea)
		lpRect := structRectCreate(tileArea*)
	else
		lpRect := 0
	flagCustomWindows := IsSet(windowArray) && windowArray is Array
	if (flagCustomWindows) {
		cKids := windowArray.Length
		lpKids := Buffer(windowArray.Length * 4) ; sizeof(int) == 4
		for i, hwnd in windowArray
			NumPut("Int", hwnd, lpKids, 4 * (i-1))
	}
	else {
		cKids := 0
		lpKids := 0
	}
	return DllCall("TileWindows", 
		"Int", hwndParent, 
		"UInt", tilingMode, 
		"UInt", flagTileArea ? lpRect.Ptr : 0, 
		"Int", cKids, 
		"Int", flagCustomWindows ? lpKids.Ptr : 0
	)
}
; https://github.com/cobracrystal/ahk

class TextEditMenu {

	static __New() {
		if (FileExist(A_WorkingDir "\TextEditMenu\dictionary.json"))
			this.dictionaryPath := A_WorkingDir "\TextEditMenu\dictionary.json"
		else if (FileExist(A_LineFile "\..\..\script_files\TextEditMenu\dictionary.json"))
			this.dictionaryPath := A_LineFile "\..\..\script_files\TextEditMenu\dictionary.json"
		else
			this.dictionaryPath := A_ScriptFullPath . "\..\script_files\TextEditMenu\dictionary.json"
		this.dictionary := Map()
		if !(FileExist(this.dictionaryPath)) {
			SplitPath(this.dictionaryPath, , &dir)
			if !(DirExist(dir))
				DirCreate(dir)
			this.dictionary := this.generateDictionary()
			FileAppend(jsongo.Stringify(this.dictionary,,"`t"), this.dictionaryPath, "UTF-8")
		}
		else
			this.dictionary := jsongo.Parse(FileRead(this.dictionaryPath, "UTF-8"))
		replFN := (alphTo) => modifySelectedText(this.replaceCharacters.bind(this), "mixed", alphTo)
		caseMenu := Menu()
		caseMenu.Add("Random Case", (*) => modifySelectedText(this.randomCase.bind(this)))
		caseMenu.Add("All Uppercase", (*) => modifySelectedText((t) => Format("{:U}", StrReplace(t, "ß", "ẞ"))))
		caseMenu.Add("All Lowercase", (*) => modifySelectedText((t) => Format("{:L}", StrReplace(t, "ẞ", "ß"))))
		caseMenu.Add("Proper Capitals", (*) => modifySelectedText((t) => Format("{:T}", t)))
		fontMenu := Menu()
		fontMenu.Add("Serif Standard", (*) => replFN("serif"))
		fontMenu.Default := "Serif Standard"
		fontMenu.Add("Superscript", (*) => replFN("superscript"))
		fontMenu.Add("Small Capitals", (*) => replFN("smallcapitals"))
		; fontMenu.Add("Italics", (*) => replFN("italic")) ; PERSISTING ITALIC/BOLD ie mathSf -> Italic MathSf instead of SerifItalic
		; fontMenu.Add("Bold", (*) => replFN("bold"))
		fontMenu.Add("𝐁𝐨𝐥𝐝 𝐒𝐞𝐫𝐢𝐟", (*) => replFN("serifBold"))
		fontMenu.Add("𝐼𝑡𝑎𝑙𝑖𝑐 𝑆𝑒𝑟𝑖𝑓", (*) => replFN("serifItalic"))
		fontMenu.Add("𝑩𝒐𝒍𝒅 𝑰𝒕𝒂𝒍𝒊𝒄 𝑺𝒆𝒓𝒊𝒇",	(*) => replFN("serifBoldItalic"))
		fontMenu.Add("𝖬𝖺𝗍𝗁𝖲𝖥", (*) => replFN("mathSF"))
		fontMenu.Add("𝗕𝗼𝗹𝗱 𝗠𝗮𝘁𝗵𝗦𝗙", (*) => replFN("mathSFBold"))
		fontMenu.Add("𝘐𝘵𝘢𝘭𝘪𝘤 𝘔𝘢𝘵𝘩𝘚𝘍", (*) => replFN("mathSFItalic"))
		fontMenu.Add("𝘽𝙤𝙡𝙙 𝙄𝙩𝙖𝙡𝙞𝙘 𝙈𝙖𝙩𝙝𝙎𝙁", (*) => replFN("mathSFBoldItalic"))
		fontMenu.Add("𝙼𝚘𝚗𝚘𝚜𝚙𝚊𝚌𝚎", (*) => replFN("monospace"))
		fontMenu.Add("Ｗｉｄｅｓｐａｃｅ", (*) => replFN("widespace"))
		fontMenu.Add("𝕄𝕒𝕥𝕙𝔹𝔹", (*) => replFN("mathBB"))
		fontMenu.Add("ℳ𝒶𝓉𝒽𝒞𝒶𝓁", (*) => replFN("mathCal"))
		fontMenu.Add("𝓑𝓸𝓵𝓭 𝓜𝓪𝓽𝓱𝓒𝓪𝓵", (*) => replFN("mathCalBold"))
		fontMenu.Add("𝔐𝔞𝔱𝔥𝔉𝔯𝔞𝔨", (*) => replFN("mathFraktur"))
		fontMenu.Add("𝕭𝖔𝖑𝖉 𝕸𝖆𝖙𝖍𝕱𝖗𝖆𝖐", (*) => replFN("mathFrakturBold"))
		fontMenu.Add("丂卄闩尺尸 丂⼕尺讠尸〸", (*) => replFN("sharpscript"))
		runeMenu := Menu()
		runeMenu.Add("Runify (DE)", (*) => modifySelectedText(this.runify.bind(this), "DE"))
		runeMenu.Add("Runify (EN)", (*) => modifySelectedText(this.runify.bind(this), "EN"))
		runeMenu.Add("Derunify (DE)", (*) => modifySelectedText(this.derunify.bind(this), "DE"))
		runeMenu.Add("Derunify (EN)", (*) => modifySelectedText(this.derunify.bind(this), "EN"))
		textModifyMenu := Menu()
		textModifyMenu.Add("Letter Case", caseMenu)
		textModifyMenu.Add("Font", fontMenu)
		textModifyMenu.Add("Runes", runeMenu)
		textModifyMenu.Add("Reverse", (*) => modifySelectedText(strReverse))
		textModifyMenu.Add("Mirror", (*) => modifySelectedText(this.mirror.bind(this)))
		textModifyMenu.Add("Flip", (*) => modifySelectedText(this.flip.bind(this)))
		textModifyMenu.Add("Spaced Text", (*) => modifySelectedText(strDoPerChar, " "))
		textModifyMenu.Add("Add Zalgo", (*) => modifySelectedText(this.zalgo.bind(this), 5))
		textModifyMenu.Add("Get Char Names", (*) => MsgBoxAsGui(objCollect(objDoForEach(StrSplitUTF8(fastCopy()), e => e " | " unicodeData.charName(e)), (b,e) => (b . "`n" . e)), "Character Names",,,,,,1))
		;	menu_RemoveSpace(textModifyMenu.Handle) ; this also decreases vertical spacing.
		this.menu := textModifyMenu
	}

	static showMenu() => this.menu.show()

	static randomCase(text) {
		result := ""
		c := ""
		for i, e in StrSplitUTF8(text) {
			caseFormat := Random(0, 1)
			if (caseFormat)
				c := Format("{:U}", e)
			else
				c := Format("{:L}", e)
			if (e = "i")
				c := "i"
			else if (e = "l")
				c := "L"
			else if (e == "ß" || e == "ẞ")
				c := (caseFormat ? "ß" : "ẞ")
			result := result . c
		}
		return result 
	}

	; works one character at a time
	static replaceCharacters(text, alphNameFrom, alphnameTo) {
		serif := ""
		result := ""
		foundAlphabets := [] ; TODO: COLLECT ENCOUNTERED ALPHABETS. THEN, IF alphnameTo is "SWAP" AND ALPHABETS ARE EXACTLY TWO, SWAP THEM. USE FOR MIRROR, FLIP ETC.
		if (alphNameFrom == "mixed") {
			for i, e in StrSplitUTF8(text) {
				serifSymbol := e
				if !(objContainsValue(this.dictionary["otherAlphabet"]["serif"], e))
					for alphName, alphMap in this.dictionary["fromAlphabet"] {
						if (alphMap.Has(e)) {
							serifSymbol := alphMap[e]
							break
						}
					}
				serif .= serifSymbol
			}
		}
		else if (alphNameFrom != "serif") {
			if !(this.dictionary["fromAlphabet"].Has(alphNameFrom))
				return text
			alph := this.dictionary["fromAlphabet"][alphNameFrom]
			for i, e in StrSplitUTF8(text) {
				if (alph.Has(e))
					serif .= alph[e]
				else
					serif .= e
			}
		}
		else
			serif := text
		if !(this.dictionary["toAlphabet"].Has(alphnameTo))
			return serif
		return replaceCharacters(serif, this.dictionary["toAlphabet"][alphnameTo])
	}

	static mirror(text) => this.replaceCharacters(strReverse(text), "mixed", "mirror")

	static flip(text) => this.replaceCharacters(strReverse(text), "mixed", "upsidedown")

	static zalgo(str, intensity) {
		len := this.dictionary["otherAlphabet"]["zalgo"].length
		newStr := ""
		for i, e in StrSplitUTF8(str) {
			newStr .= e
			Loop (intensity)
				newStr .= this.dictionary["otherAlphabet"]["zalgo"][Random(1, len)]
		}
		return newStr
	}

	static runify(text, language) {
		runicStr := Format("{:L}", StrReplace(text, "ẞ", "ß"))
		for needle, repl in this.dictionary["otherAlphabet"]["runes"]["to"][language]["multichar"]
			runicStr := StrReplace(runicStr, needle, repl, 0)
		for needle, repl in this.dictionary["otherAlphabet"]["runes"]["to"]["global"]["multichar"]
			runicStr := StrReplace(runicStr, needle, repl, 0)
		runicStr := replaceCharacters(runicStr, this.dictionary["otherAlphabet"]["runes"]["to"][language]["singlechar"])
		runicStr := replaceCharacters(runicStr, this.dictionary["otherAlphabet"]["runes"]["to"]["global"]["singlechar"])
		return runicStr
	}

	static derunify(text, language) {
		latinStr := text
		for needle, repl in this.dictionary["otherAlphabet"]["runes"]["from"][language]["multichar"]
			latinStr := StrReplace(latinStr, needle, repl, 0)
		for needle, repl in this.dictionary["otherAlphabet"]["runes"]["from"]["global"]["multichar"]
			latinStr := StrReplace(latinStr, needle, repl, 0)
		for needle, repl in this.dictionary["otherAlphabet"]["runes"]["from"]["extra"]["multichar"]
			latinStr := StrReplace(latinStr, needle, repl, 0)
		latinStr := replaceCharacters(latinStr, this.dictionary["otherAlphabet"]["runes"]["from"][language]["singlechar"])
		latinStr := replaceCharacters(latinStr, this.dictionary["otherAlphabet"]["runes"]["from"]["global"]["singlechar"])
		latinStr := replaceCharacters(latinStr, this.dictionary["otherAlphabet"]["runes"]["from"]["extra"]["singlechar"])
		return latinStr
	}

	static generateDictionary() {
		toAlphabet := Map()
		fromAlphabet := Map()
		serif := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
		toStrings := Map(
			"serifItalic", "𝑎𝑏𝑐𝑑𝑒𝑓𝑔ℎ𝑖𝑗𝑘𝑙𝑚𝑛𝑜𝑝𝑞𝑟𝑠𝑡𝑢𝑣𝑤𝑥𝑦𝑧𝐴𝐵𝐶𝐷𝐸𝐹𝐺𝐻𝐼𝐽𝐾𝐿𝑀𝑁𝑂𝑃𝑄𝑅𝑆𝑇𝑈𝑉𝑊𝑋𝑌𝑍0123456789",
			"serifBold", "𝐚𝐛𝐜𝐝𝐞𝐟𝐠𝐡𝐢𝐣𝐤𝐥𝐦𝐧𝐨𝐩𝐪𝐫𝐬𝐭𝐮𝐯𝐰𝐱𝐲𝐳𝐀𝐁𝐂𝐃𝐄𝐅𝐆𝐇𝐈𝐉𝐊𝐋𝐌𝐍𝐎𝐏𝐐𝐑𝐒𝐓𝐔𝐕𝐖𝐗𝐘𝐙𝟎𝟏𝟐𝟑𝟒𝟓𝟔𝟕𝟖𝟗",
			"serifBoldItalic", "𝒂𝒃𝒄𝒅𝒆𝒇𝒈𝒉𝒊𝒋𝒌𝒍𝒎𝒏𝒐𝒑𝒒𝒓𝒔𝒕𝒖𝒗𝒘𝒙𝒚𝒛𝑨𝑩𝑪𝑫𝑬𝑭𝑮𝑯𝑰𝑱𝑲𝑳𝑴𝑵𝑶𝑷𝑸𝑹𝑺𝑻𝑼𝑽𝑾𝑿𝒀𝒁𝟎𝟏𝟐𝟑𝟒𝟓𝟔𝟕𝟖𝟗",
			"mathSF", "𝖺𝖻𝖼𝖽𝖾𝖿𝗀𝗁𝗂𝗃𝗄𝗅𝗆𝗇𝗈𝗉𝗊𝗋𝗌𝗍𝗎𝗏𝗐𝗑𝗒𝗓𝖠𝖡𝖢𝖣𝖤𝖥𝖦𝖧𝖨𝖩𝖪𝖫𝖬𝖭𝖮𝖯𝖰𝖱𝖲𝖳𝖴𝖵𝖶𝖷𝖸𝖹𝟢𝟣𝟤𝟥𝟦𝟧𝟨𝟩𝟪𝟫", ; SF = Sans Serif
			"mathSFBold", "𝗮𝗯𝗰𝗱𝗲𝗳𝗴𝗵𝗶𝗷𝗸𝗹𝗺𝗻𝗼𝗽𝗾𝗿𝘀𝘁𝘂𝘃𝘄𝘅𝘆𝘇𝗔𝗕𝗖𝗗𝗘𝗙𝗚𝗛𝗜𝗝𝗞𝗟𝗠𝗡𝗢𝗣𝗤𝗥𝗦𝗧𝗨𝗩𝗪𝗫𝗬𝗭𝟬𝟭𝟮𝟯𝟰𝟱𝟲𝟳𝟴𝟵",
			"mathSFItalic", "𝘢𝘣𝘤𝘥𝘦𝘧𝘨𝘩𝘪𝘫𝘬𝘭𝘮𝘯𝘰𝘱𝘲𝘳𝘴𝘵𝘶𝘷𝘸𝘹𝘺𝘻𝘈𝘉𝘊𝘋𝘌𝘍𝘎𝘏𝘐𝘑𝘒𝘓𝘔𝘕𝘖𝘗𝘘𝘙𝘚𝘛𝘜𝘝𝘞𝘟𝘠𝘡𝟢𝟣𝟤𝟥𝟦𝟧𝟨𝟩𝟪𝟫",
			"mathSFBoldItalic", "𝙖𝙗𝙘𝙙𝙚𝙛𝙜𝙝𝙞𝙟𝙠𝙡𝙢𝙣𝙤𝙥𝙦𝙧𝙨𝙩𝙪𝙫𝙬𝙭𝙮𝙯𝘼𝘽𝘾𝘿𝙀𝙁𝙂𝙃𝙄𝙅𝙆𝙇𝙈𝙉𝙊𝙋𝙌𝙍𝙎𝙏𝙐𝙑𝙒𝙓𝙔𝙕𝟬𝟭𝟮𝟯𝟰𝟱𝟲𝟳𝟴𝟵",
			"mathCal", "𝒶𝒷𝒸𝒹𝑒𝒻ℊ𝒽𝒾𝒿𝓀𝓁𝓂𝓃ℴ𝓅𝓆𝓇𝓈𝓉𝓊𝓋𝓌𝓍𝓎𝓏𝒜ℬ𝒞𝒟ℰℱ𝒢ℋℐ𝒥𝒦ℒℳ𝒩𝒪𝒫𝒬ℛ𝒮𝒯𝒰𝒱𝒲𝒳𝒴𝒵𝟢𝟣𝟤𝟥𝟦𝟧𝟨𝟩𝟪𝟫", ; Cal = Calligraphy
			"mathCalBold", "𝓪𝓫𝓬𝓭𝓮𝓯𝓰𝓱𝓲𝓳𝓴𝓵𝓶𝓷𝓸𝓹𝓺𝓻𝓼𝓽𝓾𝓿𝔀𝔁𝔂𝔃𝓐𝓑𝓒𝓓𝓔𝓕𝓖𝓗𝓘𝓙𝓚𝓛𝓜𝓝𝓞𝓟𝓠𝓡𝓢𝓣𝓤𝓥𝓦𝓧𝓨𝓩𝟬𝟭𝟮𝟯𝟰𝟱𝟲𝟳𝟴𝟵",
			"mathFraktur", "𝔞𝔟𝔠𝔡𝔢𝔣𝔤𝔥𝔦𝔧𝔨𝔩𝔪𝔫𝔬𝔭𝔮𝔯𝔰𝔱𝔲𝔳𝔴𝔵𝔶𝔷𝔄𝔅ℭ𝔇𝔈𝔉𝔊ℌℑ𝔍𝔎𝔏𝔐𝔑𝔒𝔓𝔔ℜ𝔖𝔗𝔘𝔙𝔚𝔛𝔜ℨ𝟢𝟣𝟤𝟥𝟦𝟧𝟨𝟩𝟪𝟫",
			"mathFrakturBold", "𝖆𝖇𝖈𝖉𝖊𝖋𝖌𝖍𝖎𝖏𝖐𝖑𝖒𝖓𝖔𝖕𝖖𝖗𝖘𝖙𝖚𝖛𝖜𝖝𝖞𝖟𝕬𝕭𝕮𝕯𝕰𝕱𝕲𝕳𝕴𝕵𝕶𝕷𝕸𝕹𝕺𝕻𝕼𝕽𝕾𝕿𝖀𝖁𝖂𝖃𝖄𝖅𝟬𝟭𝟮𝟯𝟰𝟱𝟲𝟳𝟴𝟵",
			"monospace", "𝚊𝚋𝚌𝚍𝚎𝚏𝚐𝚑𝚒𝚓𝚔𝚕𝚖𝚗𝚘𝚙𝚚𝚛𝚜𝚝𝚞𝚟𝚠𝚡𝚢𝚣𝙰𝙱𝙲𝙳𝙴𝙵𝙶𝙷𝙸𝙹𝙺𝙻𝙼𝙽𝙾𝙿𝚀𝚁𝚂𝚃𝚄𝚅𝚆𝚇𝚈𝚉𝟶𝟷𝟸𝟹𝟺𝟻𝟼𝟽𝟾𝟿", ; TT = monospace
			"widespace", "ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ０１２３４５６７８９",
			"mathBB", "𝕒𝕓𝕔𝕕𝕖𝕗𝕘𝕙𝕚𝕛𝕜𝕝𝕞𝕟𝕠𝕡𝕢𝕣𝕤𝕥𝕦𝕧𝕨𝕩𝕪𝕫𝔸𝔹ℂ𝔻𝔼𝔽𝔾ℍ𝕀𝕁𝕂𝕃𝕄ℕ𝕆ℙℚℝ𝕊𝕋𝕌𝕍𝕎𝕏𝕐ℤ𝟘𝟙𝟚𝟛𝟜𝟝𝟞𝟟𝟠𝟡", ; BB = Blackboard
			"superscript", "ᵃᵇᶜᵈᵉᶠᵍʰᶦʲᵏˡᵐⁿᵒᵖᵠʳˢᵗᵘᵛʷˣʸᶻᴬᴮᶜᴰᴱᶠᴳᴴᴵᴶᴷᴸᴹᴺᴼᴾᵠᴿˢᵀᵁⱽᵂˣʸᶻ⁰¹²³⁴⁵⁶⁷⁸⁹",
			"smallCapitals", "ᴀʙᴄᴅᴇғɢʜɪᴊᴋʟᴍɴᴏᴘǫʀsᴛᴜᴠᴡxʏᴢᴀʙᴄᴅᴇғɢʜɪᴊᴋʟᴍɴᴏᴘǫʀsᴛᴜᴠᴡxʏᴢ0123456789",
			"mirror", "ɒdɔbɘʇϱʜiįʞlmnoqpɿƨɈυvwxγzAઘƆႧƎᆿӘHIႱʞ⅃MИOԳϘЯƧTUVWXYZ0ƖςƐμटმ٢8୧",
			"upsidedown", "ɐqɔpǝⅎƃɥᴉɾʞʅɯuodbɹsʇnʌʍxʎz∀ꓭϽᗡƎᖵ⅁HIᒋꓘ⅂ꟽNOԀꝹꓤSꓕՈɅϺX⅄Z0⇂↊↋ᔭ59𝘓86",
			"sharpscript", "闩⻏⼕ᗪ🝗ﾁᎶ卄讠丿长㇄爪𝓝ㄖ尸Ɋ尺丂〸ㄩᐯ山〤丫Ⲍ闩乃⼕ᗪ㠪千Ꮆ廾工丿长㇄爪𝓝龱尸Ɋ尺丂ㄒㄩᐯ山乂ㄚ乙0丨己㇌丩567〥9"
		)
		; [small letters] [CAPITAL LETTERS] [NUMBERS]
		; https://milde.users.sourceforge.net/LUCR/Math/unimathsymbols.pdf
		; https://en.wikipedia.org/wiki/Mathematical_Alphanumeric_Symbols
		for i, e in toStrings {
			toAlphabet[i] := mapFromArrays(StrSplitUTF8(serif), StrSplitUTF8(e))
			fromAlphabet[i] := mapFromArrays(StrSplitUTF8(e), StrSplitUTF8(serif))
		}
		otherAlphabet := Map()
		otherAlphabet["zalgo"] := ["̾", "̿", "̀", "́", "͂", "̓", "̈́", "ͅ", "͆", "͇", "͈", "͉", "͊", "͋", "͌", "͍", "͎", "͏", "͐", "͑", "͒", "͓", "͔", "͕", "͖", "͗", "͘", "͙", "͚", "͛", "͜", "͝", "͞", "͟", "͠", "͡", "͢", "ͣ", "ͤ", "ͥ", "ͦ", "ͧ", "ͨ", "ͩ", "ͪ", "ͫ", "ͬ", "ͭ", "ͮ"]
		otherAlphabet["serif"] := StrSplitUTF8(serif)
		; RUNES
		runes := Map("to", Map( "DE", Map("multichar", Map(), "singlechar", Map()), 
								"EN", Map("multichar", Map(), "singlechar", Map()),
								"global", Map("multichar", Map(), "singlechar", Map())),
					"from", Map("DE", Map("multichar", Map(), "singlechar", Map()), 
								"EN", Map("multichar", Map(), "singlechar", Map()), 
								"extra", Map("multichar", Map(), "singlechar", Map()),
								"global", Map("multichar", Map(), "singlechar", Map())))
		latinBidirectional := ["a","b","d","e","f","g","h","i","l","m","n","o","p","r","s","t","u","v","x","z","ch","sh","th","ei","ng"]
		runesBidirectional := ["ᚫ","ᛒ","ᛞ","ᛖ","ᚠ","ᚷ","ᚻ","ᛁ","ᛚ","ᛗ","ᚾ","ᛟ","ᛈ","ᚱ","ᛋ","ᛏ","ᚢ","ᚹ","ᚲᛋ","ᛉ","ᚳ","ᛪ","ᚦ","ᛇ","ᛝ"]
		for i, letter in latinBidirectional {
			rune := runesBidirectional[i]
			runes["to"]["global"][(StrLen(letter) > 1 ? "multichar" : "singlechar")][letter] := rune
			runes["from"]["global"][(StrLen(rune) > 1 ? "multichar" : "singlechar")][rune] := letter
		}
		translateOneDirectional1 := ["c","k","j","y"], translateOneDirectional2 := ["ᚲ","ᚲ","ᛃ","ᛃ"]
		for i, letter in translateOneDirectional1 {
			runes["to"]["global"]["singlechar"][letter] := translateOneDirectional2[i]
		}
		translateCircular1 := ["ä","ö","ü","ß"], translateCircular2 := ["ᚨᛖ","ᛟᛖ","ᚢᛖ","ᛋᛋ"], translateCircular3 := ["ae","oe","ue","ss"]
		for i, letter in translateCircular1 {
			runes["to"]["global"]["singlechar"][letter] := translateCircular2[i]
			runes["from"]["global"]["multichar"][translateCircular2[i]] := translateCircular3[i]
		}
		translateLanguageLatin := ["q", "w"], translateLanguageRunicDE := ["ᚲᚹ","ᚹ"], translateLanguageRunicEN := ["ᚲᚢ","ᚢ"]
		for i, letter in translateLanguageLatin {
			runes["to"]["DE"]["singlechar"][letter] := translateLanguageRunicDE[i]
			runes["to"]["EN"]["singlechar"][letter] := translateLanguageRunicEN[i]
		}
		translateLanguageRunes := ["ᚲ","ᛃ","ᚲᚹ","ᚲᚢ"], translateLanguageLatinDE := ["k","j","q","ku"], translateLanguageLatinEN := ["c","y","cv","q"]
		for i, rune in translateLanguageRunes {
			runes["from"]["DE"][(StrLen(rune) > 1 ? "multichar" : "singlechar")][rune] := translateLanguageLatinDE[i]
			runes["from"]["EN"][(StrLen(rune) > 1 ? "multichar" : "singlechar")][rune] := translateLanguageLatinEN[i]
		}
		runesExtra := ["ᚠ","ᚡ","ᚢ","ᚣ","ᚤ","ᚥ","ᚧ","ᚨ","ᚩ","ᚪ","ᚫ","ᚬ","ᚭ","ᚮ","ᚯ","ᚰ","ᚱ","ᚲ","ᚳ","ᚴ","ᚵ","ᚶ","ᚷ","ᚸ","ᚹ","ᚺ","ᚻ","ᚼ","ᚽ","ᚾ","ᚿ","ᛀ","ᛁ","ᛂ","ᛃ","ᛄ","ᛅ","ᛆ","ᛇ","ᛈ","ᛉ","ᛊ","ᛋ","ᛌ","ᛍ","ᛎ","ᛏ","ᛐ","ᛑ","ᛒ","ᛓ","ᛔ","ᛕ","ᛖ","ᛗ","ᛘ","ᛙ","ᛚ","ᛛ","ᛜ","ᛝ","ᛞ","ᛟ","ᛠ","ᛡ","ᛢ","ᛣ","ᛤ","ᛥ","ᛦ","ᛧ","ᛨ","ᛩ","ᛪ"]
		latinExtra := ["f","v","u","y","y","w","th","a","o","a","a","o","o","o","ö","o","r","k","ch","k","g","eng","g","g","v","h","h","h","h","n","n","n","i","e","y","j","a","a","ei","p","z","s","s","s","c","z","t","t","d","b","b","p","p","e","m","m","m","l","l","ng","ng","d","o","ea","io","qu","ch","k","st","r","y","rr","qu","sch"]
		for i, e in runesExtra {
			runes["from"]["extra"]["singlechar"][e] := latinExtra[i]
		}
		otherAlphabet["runes"] := runes
		dictionary := Map("toAlphabet", toAlphabet, "fromAlphabet", fromAlphabet, "otherAlphabet", otherAlphabet)
		return dictionary
	}
}

