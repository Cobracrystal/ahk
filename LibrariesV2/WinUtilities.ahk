#Include "%A_LineFile%\..\..\LibrariesV2\ObjectUtilities.ahk"

class WinUtilities {
	static __New() {
		this.windowCache := Map()
	}
	
	static getAllWindowInfo(getHidden := false, blacklist := this.defaultBlacklist, getCommandLine := false) {
		windows := []
		dHW := A_DetectHiddenWindows
		DetectHiddenWindows(getHidden)
		wHandles := WinGetList()
		for i, wHandle in wHandles {
			for e in blacklist
				if ((e != "" && WinExist(e " ahk_id " wHandle)) || (e == "" && WinGetTitle(wHandle) == ""))
					continue 2
			windows.push(this.getWindowInfo(wHandle, getCommandLine))
		}
		DetectHiddenWindows(dHW)
		return windows
	}

	static getWindowInfo(wHandle, getCommandline := false, updateCache := true) {
		x := y := w := h := winTitle := mmx := ""
		if !WinExist(wHandle) {
			return {}
		}
		try	winTitle := WinGetTitle(wHandle)
		try	WinGetPos(&x, &y, &w, &h, wHandle)
		try WinGetClientPos(&cx, &cy, &cw, &ch, wHandle)
		try	mmx := WinGetMinMax(wHandle)
		info := {
			title: winTitle,
			state: mmx,
			xpos: x, ypos: y,
			width: w, height: h,
			clientxpos: cx, clientypos: cy,
			clientwidth: cw, clientheight: ch
		}
		if !updateCache
			cacheObj := info
		else {
			cacheObj := this.updateSingleCache(wHandle, getCommandline)
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

	static updateSingleCache(wHandle, getCommandLine) {
		winClass := processName := processPath := pid := cmdLine := ""
		triedCommandline := false
		if (this.windowCache.Has(wHandle)) {
			if getCommandLine && !this.windowCache[wHandle].triedCommandline {
				try this.windowCache[wHandle].commandLine := this.winmgmt("CommandLine", "Where ProcessId = " this.windowCache[wHandle].pid)[1]
				this.windowCache[wHandle].triedCommandline := true
			}
		} 
		else {
			try	winClass := WinGetClass(wHandle)
			try	processName := WinGetProcessName(wHandle)
			try	processPath := WinGetProcessPath(wHandle)
			try	pid := WinGetPID(wHandle)
			if (getCommandLine) {
				try cmdLine := this.winmgmt("CommandLine", "Where ProcessId = " pid)[1]
				triedCommandline := true
			}
					; Get-WmiObject -Query "SELECT * FROM Win32_Process WHERE ProcessID = [PID]" in powershell btw
			this.windowCache[wHandle] := {
				hwnd: wHandle, class: winClass, process: processName, processPath: processPath, pid: pid, commandLine: cmdLine, triedCommandline: triedCommandline
			}
		}
		return this.windowCache[wHandle]
	}

	static winmgmt(selector?, selection?, d := "Win32_Process", m := "winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2") {
		local i, s := []
		for i in ComObjGet(m).ExecQuery("Select " . (selector ?? "*") . " from " . d . (IsSet(selection) ? " " . selection : ""))
			s.push(i.%selector%)
		return (s.length > 0 ? s : [""])
	}

	static isVisible(wHandle) {
		return WinGetStyle(wHandle) & this.windowStyles.WS_VISIBLE
	}

	static isBorderlessFullscreen(wHandle) {
		WinGetPos(&x, &y, &w, &h, wHandle)
		WinGetClientPos(&cx, &cy, &cw, &ch, wHandle)
		mHandle := DllCall("MonitorFromWindow", "Ptr", wHandle, "UInt", 0x2, "Ptr")
		NumPut("Uint", 40, monitorInfo := Buffer(40))
		DllCall("GetMonitorInfo", "Ptr", mHandle, "Ptr", monitorInfo)
			monLeft := NumGet(monitorInfo, 4, "Int"),
			monTop := NumGet(monitorInfo, 8, "Int"),
			monRight := NumGet(monitorInfo, 12, "Int"),
			monBottom := NumGet(monitorInfo, 16, "Int")
		if (monLeft == cx && monTop == cy && monRight == monLeft + cw && monBottom == monTop + ch)
			return true
		else 
			return false
	}

	static borderlessFullscreenWindow(wHandle) {
		WinGetPos(&x, &y, &w, &h, wHandle)
		WinGetClientPos(&cx, &cy, &cw, &ch, wHandle)
		mHandle := DllCall("MonitorFromWindow", "Ptr", wHandle, "UInt", 0x2, "Ptr")
		NumPut("Uint", 40, monitorInfo := Buffer(40))
		DllCall("GetMonitorInfo", "Ptr", mHandle, "Ptr", monitorInfo)
		monitor := {
			left: NumGet(monitorInfo, 4, "Int"),
			top: NumGet(monitorInfo, 8, "Int"),
			right: NumGet(monitorInfo, 12, "Int"),
			bottom: NumGet(monitorInfo, 16, "Int")
		}
		WinMove(
			monitor.left + (x - cx),
			monitor.top + (y - cy),
			monitor.right - monitor.left + (w - cw),
			monitor.bottom - monitor.top + (h - ch),
			wHandle
		)
	}

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

	static windowStyles => {
		WS_BORDER: 0x800000,
		WS_POPUP: 0x80000000,
		WS_CAPTION: 0xC00000,
		WS_CLIPSIBLINGS: 0x4000000,
		WS_DISABLED: 0x8000000,
		WS_DLGFRAME: 0x400000,
		WS_GROUP: 0x20000,
		WS_HSCROLL: 0x100000,
		WS_MAXIMIZE: 0x1000000,
		WS_MAXIMIZEBOX: 0x10000,
		WS_MINIMIZE: 0x20000000,
		WS_MINIMIZEBOX: 0x20000,
		WS_OVERLAPPED: 0x0,
		WS_OVERLAPPEDWINDOW: 0xCF0000,
		WS_POPUPWINDOW: 0x80880000,
		WS_SIZEBOX: 0x40000, ; thin title bar
		WS_SYSMENU: 0x80000,
		WS_TABSTOP: 0x10000,
		WS_THICKFRAME: 0x40000,
		WS_VSCROLL: 0x200000,
		WS_VISIBLE: 0x10000000,
		WS_CHILD: 0x40000000
	}

	static windowExStyles => {
		WS_EX_TOPMOST: 0x8
	}
}