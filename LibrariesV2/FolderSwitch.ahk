#Include "%A_LineFile%\..\..\LibrariesV2\WinUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\ObjectUtilities.ahk"

; this is largely based on https://github.com/JoyHak/QuickSwitch, but kept much simpler to avoid the messy clutter of that project.
class FolderSwitch {

	static __New() {
		this.dataPath := A_WorkingDir "\FolderDialogSwitch\paths.txt"
		this.recentPaths := []
	}

	static showMenu() {
		hwnd := WinActive("A")
		wClass := WinGetClass(hwnd)
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
		savedPaths := []
		f := Trim(FileRead(this.dataPath, "UTF-8"), "`n`r`t ")
		loop parse f, "`n", "`r"
			if (A_LoopField != "" && !RegExMatch(A_LoopField, "^\s*(;|\/\/)"))
				savedPaths.push(Trim(A_LoopField))
		openedPaths := objDoForEach(ShellWrapper.getExplorerIEObjects(), e => ShellWrapper.getExplorerSelfPath(e))
		paths := objGetUniques(arrayMerge(savedPaths, openedPaths), , false)
		if paths.Length > savedPaths.Length ; if at least one openedPaths entry was unique, add separator
			paths.InsertAt(savedPaths.Length + 1, "")
		this.paths := objGetUniques(arrayMerge(paths, this.recentPaths), , false)
		if this.paths.Length > paths.Length ; same as above
			this.paths.InsertAt(paths.Length + 1, "")
		; update recentPaths
		this.recentPaths.InsertAt(1, openedPaths*)
		cutOff := this.recentPaths.Length - 10
		if cutOff > 0 ; keep only 10 maximum recent paths
			this.recentPaths.RemoveAt(-cutOff, cutOff)
		c := 1
		for e in this.paths
			switchMenu.add(e == "" ? unset : "&" c++ " " e, e == "" ? unset : fn)
		switchMenu.add()
		switchMenu.add("&s " this.dataPath, this.selector.bind(this, (path) => Run(path)))
		switchMenu.show()
	}

	static selector(fn, menuItemName, menuItemPos, menuObj) {
		if menuItempos <= this.paths.length
			path := this.paths[menuItemPos]
		else
			path := this.dataPath
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
