#Include "WinUtilities.ahk"
#Include "ObjectUtilities.ahk"
#Include "PrimitiveUtilities.ahk"

; this is largely based on https://github.com/JoyHak/QuickSwitch, but kept much simpler to avoid the messy clutter of that project.
class FolderSwitch {

	static __New() {
		this.dataPath := A_WorkingDir "\FolderDialogSwitch\paths.txt"
		this.recentPaths := []
	}

	static showMenu() {
		hwnd := WinActive("A")
		try wClass := WinGetClass(hwnd)
		catch as e
			return
		clipboard := Trim(A_Clipboard, "`n`r`t '`"")
		if !(attr := FileExist(clipboard))
			clipboardPathArr := []
		else if InStr(attr, "D")
			clipboardPathArr := [clipboard]
		else {
			SplitPath(clipboard, &name, &dir)
			clipboardPathArr := [dir]
		}
		if (wClass == "#32770" && fileDialogFunc := this.getFileDialog(hwnd, &editId))
			flagContext := 0
		else { ; check if we are in explorer
			if (wClass == "CabinetWClass" && WinGetProcessName(hwnd) == "explorer.exe")
				flagContext := 1
			else
				flagContext := 2
		}
		switch flagContext {
			case 0:
				fn := this.selector.bind(this, fileDialogFunc)
				try {
					ControlFocus("ToolbarWindow321", hwnd)
					ControlSend("{end}{space}", editId)
					Sleep 100
				}
			case 1:
				curPath := ShellWrapper.getExplorerSelfPath(ShellWrapper.getExplorerIEObject(hwnd))
				fn := this.selector.bind(this, ObjBindMethod(ShellWrapper, "navigateExplorer", hwnd))
			case 2:
				fn := this.selector.bind(this, this.selectOrLaunch.bind(this))
		}
		switchMenu := Menu()
		if (!FileExist(this.dataPath))
			FileAppend("// Add Paths here, one per line`n" A_WorkingDir, this.dataPath, "UTF-8")
		allPaths := {
			clipboard: clipboardPathArr, ; sorted in priority
			saved: objFilter(objDoForEach(strSplitOnNewLine(FileRead(this.dataPath, "UTF-8")), v=>Trim(v)), v => v != "" && !RegexMatch(v, "^(;|\/\/)")),
			open: objDoForEach(ShellWrapper.getExplorerIEObjects(), e => ShellWrapper.getExplorerSelfPath(e)),
			recent: this.recentPaths,
		}
		uniqueCombined := objGetUniques(arrayMerge(allPaths.clipboard, allPaths.saved))
		allPaths.saved := arraySlice(uniqueCombined, allPaths.clipboard.Length + 1)
		uniqueCombined2 := objGetUniques(arrayMerge(uniqueCombined, allPaths.open))
		allPaths.open := arraySlice(uniqueCombined2, uniqueCombined.Length + 1)
		uniqueCombined3 := objGetUniques(arrayMerge(uniqueCombined2, allPaths.recent))
		allPaths.recent := arraySlice(uniqueCombined3, uniqueCombined2.Length + 1)

		this.paths := allPaths
		; update recentPaths
		this.recentPaths := arrayMerge(allPaths.clipboard, allPaths.open, allPaths.recent)
		cutOff := this.recentPaths.Length - 10
		if cutOff > 0 ; keep only most recent 10 paths
			this.recentPaths.RemoveAt(-cutOff, cutOff) ; removes the last [cutoff] elements
		for i, path in this.paths.saved
			switchMenu.add("&" i " " path, fn)
		if this.paths.saved.Length > 0
			switchMenu.Add()
		for i, path in this.paths.open
			switchMenu.add("&t" i " " path, fn)
		if this.paths.open.Length > 0
			switchMenu.Add()
		for i, path in this.paths.recent
			switchMenu.add("&r" i " " path, fn)
		if this.paths.recent.Length > 0
			switchMenu.Add()
		; need for loop so it doesn't add nothing if its empty
		for path in this.paths.clipboard {
			switchMenu.add("&c " path, fn)
			switchMenu.Add()
		}
		switchMenu.add("&s " this.dataPath, this.selector.bind(this, (path) => Run(path)))
		switchMenu.show()
	}

	static selector(fn, menuItemName, menuItemPos, menuObj) {
		switch SubStr(menuItemName, 2, 1) {
			case "c":
				path := this.paths.clipboard[1]
			case "s":
				path := this.dataPath
			case "t":
				id := SubStr(StrSplit(menuItemName, ' ')[1], 3)
				path := this.paths.open[Integer(id)]
			case "r":
				id := SubStr(StrSplit(menuItemName, ' ')[1], 3)
				path := this.paths.recent[Integer(id)]
			default: 
				id := SubStr(StrSplit(menuItemName, ' ')[1], 2)
				path := this.paths.saved[Integer(id)]
		}
		try fn(path)
	}

	static selectOrLaunch(path) {
		arr := ShellWrapper.getExplorerIEObjects()
		if index := objContainsValue(arr, path, v => ShellWrapper.getExplorerSelfPath(v))
			WinActivate(arr[index].hwnd)
		else
			ShellWrapper.Explore(path)
	}

	static feedDialogSYSTREEVIEW(hwnd, editHwnd, path, attempts := 3) {
		_fileName := ControlGetText(editHwnd)
		Loop (attempts) {
			ControlFocus(editHwnd)
			ControlSetText(path, editHwnd)
			_path := ControlGetText(editHwnd)
			if (_path = path) {
				ControlSend("{Enter}", editHwnd)
				ControlFocus(editHwnd)
				ControlSetText(_fileName, editHwnd)
				return true
			}
		}
		return false
	}

	static feedDialogSYSLISTVIEW(hwnd, editHwnd, path, attempts := 3) {
		Loop (attempts) {
			Sleep(15)
			ControlFocus(this.sysListViewPrepCtrl, hwnd)
			_focus := ControlGetFocus(hwnd)
		}
		until (_focus == this.sysListViewPrepCtrl)

		ControlSend("{Home}", this.sysListViewPrepCtrl, hwnd)
		Loop (attempts) {
			Sleep(15)
			ControlSend("^{Space}", this.sysListViewPrepCtrl, hwnd)
			_focus := ControlGetFocus(hwnd)
		}
		until !_focus

		return this.feedDialogSYSTREEVIEW(hwnd, editHwnd, path, attempts)
	}

	static getFileDialog(hwnd, &editHwnd := 0) {
		try
			editHwnd := ControlGetHwnd("Edit1", hwnd)
		catch
			return false

		flag := 0
		for e in WinGetControls(hwnd) {
			if (this.classes.Has(e))
				flag |= this.classes[e]
		}

		if (flag & 8 && flag & 16)
			return this.feedDialogSYSTREEVIEW.bind(this, hwnd, editHwnd)

		if (flag & 1) {
			if (flag & 4) {
				if (flag & 8)
					return this.feedDialogSYSTREEVIEW.bind(this, hwnd, editHwnd)
				else
					return this.feedDialogSYSLISTVIEW.bind(this, hwnd, editHwnd)
			}
			if (flag & 8)
				return this.feedDialogSYSLISTVIEW.bind(this, hwnd, editHwnd)
		}

		if (flag & 2)
			return this.feedDialogSYSTREEVIEW.bind(this, hwnd, editHwnd)
		return false
	}

	static sysListViewPrepCtrl => "SysListView321"

	static classes => Map(
		"SysListView321", 1,
		"SysTreeView321", 2,
		"SysHeader321", 4,
		"ToolbarWindow321", 8,
		"DirectUIHWND1", 16
	)
}
