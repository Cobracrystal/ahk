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
		clipboard := Trim(A_Clipboard, "`n`r`t '`"")
		if !(attr := FileExist(clipboard))
			clipboardPaths := []
		else if InStr(attr, "D")
			clipboardPaths := [clipboard]
		else {
			SplitPath(clipboard, &name, &dir)
			clipboardPaths := [dir]
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
		paths_saved := []
		f := Trim(FileRead(this.dataPath, "UTF-8"), "`n`r`t ")
		loop parse f, "`n", "`r"
			if (A_LoopField != "" && !RegExMatch(A_LoopField, "^\s*(;|\/\/)"))
				paths_saved.push(Trim(A_LoopField))
		paths_open := objDoForEach(ShellWrapper.getExplorerIEObjects(), e => ShellWrapper.getExplorerSelfPath(e))
		separatorIndices := []
		menuPaths := paths_saved ; init 
		for i, pathArr in [paths_open, this.recentPaths, clipboardPaths] {
			uniquePaths := objGetUniques(arrayMerge(menuPaths, pathArr), , false)
			if uniquePaths.Length > menuPaths.Length ; same as above
				separatorIndices.push(menuPaths.Length)
			menuPaths := uniquePaths
		}
		for i, index in separatorIndices
			menuPaths.InsertAt(index + i, "")
		this.paths := menuPaths
		; update recentPaths
		this.recentPaths := objGetUniques(arrayMerge(this.recentPaths, paths_open, clipboardPaths))
		cutOff := this.recentPaths.Length - 15
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
