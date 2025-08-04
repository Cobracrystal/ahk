; this is to a certain extend based on https://github.com/JoyHak/QuickSwitch 
class FolderSwitch {

	static __New() {
		this.dataPath := A_WorkingDir "\FolderDialogSwitch\paths.txt"
	}

	static showMenu() {
		hwnd := WinActive("A")
		wClass := WinGetClass(hwnd)
		if (wClass == "#32770" && fileDialogFunc := this.getFileDialog(hwnd, &editId)) {
			fn := this.selector.bind(this, fileDialogFunc)
			try {
				ControlFocus("ToolbarWindow321", hwnd)
				ControlSend("{end}{space}", editId)
				Sleep 100
			}
		} else { ; check if we are in explorer
			if (wClass == "CabinetWClass" && WinGetProcessName(hwnd) == "explorer.exe")
				fn := this.selector.bind(this, this.navigateExplorer.bind(this, hwnd))
			else
				fn := this.selector.bind(this, (path => Run('explorer.exe "' path '"')))
		}
		m := Menu()
		if (!FileExist(this.dataPath))
			FileAppend("// Add Paths here, one per line`n" A_WorkingDir, this.dataPath, "UTF-8")
		f := Trim(FileRead(this.dataPath, "UTF-8"), "`n`r`t ")
		this.paths := []
		loop parse f, "`n", "`r"
			if (A_LoopField != "" && !RegExMatch(A_LoopField, "^\s*(;|\/\/)"))
				this.paths.push(A_LoopField)
		if !this.paths.Length
			return
		for i, e in this.paths
			m.add("&" i " " e, fn)
		m.show()
	}

	static selector(fn, menuItemName, menuItemPos, menuObj) {
		path := this.paths[menuItemPos]
		fn(path)
	}

	static navigateExplorer(hwnd, path) {
		if shell := this.getExplorerShell(hwnd)
			shell.Navigate(path)
	}

	static getExplorerShell(hwnd) {
		static objShell := ComObject("Shell.Application")
		for e in objShell.Windows
			if e.hwnd == hwnd
				return e
		return 0
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
		} until (_focus == this.sysListViewPrepCtrl)

		ControlSend("{Home}", this.sysListViewPrepCtrl, hwnd)
		Loop (attempts) {
			Sleep(15)
			ControlSend("^{Space}", this.sysListViewPrepCtrl, hwnd)
			_focus := ControlGetFocus(hwnd)
		} until !_focus

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