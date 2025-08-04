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
		x := y := w := h := cx := cy := cw := ch := rx := ry := rw := rh := flags := mmx := winTitle := ""
		if !WinExist(wHandle) {
			return {}
		}
		try	winTitle := WinGetTitle(wHandle)
		try	WinGetPos(&x, &y, &w, &h, wHandle)
		try {
			wInfo := this.getWindowPlacement(wHandle)
			rx := wInfo.x, ry := wInfo.y, rw := wInfo.w, rh := wInfo.h, flags := wInfo.flags
		}
		try WinGetClientPos(&cx, &cy, &cw, &ch, wHandle)
		try	mmx := WinGetMinMax(wHandle)
		info := {
			title: winTitle,
			state: mmx,
			flags: flags,
			xpos: x, ypos: y,
			width: w, height: h,
			res_xpos: rx, res_ypos: ry,
			res_width: rw, res_height: rh,
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
	
	static getWindowPlacement(hwnd) {
		DllCall("User32.dll\GetWindowPlacement", "Ptr", hwnd, "Ptr", WP := Buffer(44))
		flags := NumGet(WP, 4, "Int")  ; flags
		mmx := NumGet(WP, 8, "Int") ; ShowCMD

		MinX := NumGet(WP, 12, "Int")
		MinY := NumGet(WP, 16, "Int")
		MaxX := NumGet(WP, 20, "Int")
		MaxY := NumGet(WP, 24, "Int")
		
		x := NumGet(WP, 28, "Int")        ; X coordinate of the upper-left corner of the window in its original restored state
		y := NumGet(WP, 32, "Int")        ; Y coordinate of the upper-left corner of the window in its original restored state
		w := NumGet(WP, 36, "Int") - x   ; Width of the window in its original restored state
		h := NumGet(WP, 40, "Int") - y   ; Height of the window in its original restored state
		

		return { x: x, y: y, w: w, h: h, mmx: mmx, flags: flags, minX: MinX, minY: MinY, maxX: MaxX, maxY: MaxY }
	}

	static setWindowPlacement(hwnd := "", X := "", Y := "", W := "", H := "", action := 9) {
		DllCall("User32.dll\GetWindowPlacement", "Ptr", hwnd, "Ptr", WP := Buffer(44))
		Lo := NumGet(WP, 28, "Int")        ; X coordinate of the upper-left corner of the window in its original restored state
		To := NumGet(WP, 32, "Int")        ; Y coordinate of the upper-left corner of the window in its original restored state
		Wo := NumGet(WP, 36, "Int") - Lo   ; Width of the window in its original restored state
		Ho := NumGet(WP, 40, "Int") - To   ; Height of the window in its original restored state
		L := X = "" ? Lo : X               ; X coordinate of the upper-left corner of the window in its new restored state
		T := Y = "" ? To : Y               ; Y coordinate of the upper-left corner of the window in its new restored state
		R := L + (W = "" ? Wo : W)         ; X coordinate of the bottom-right corner of the window in its new restored state
		B := T + (H = "" ? Ho : H)         ; Y coordinate of the bottom-right corner of the window in its new restored state

		NumPut("UInt", action, WP, 8)
		NumPut("UInt", L, WP, 28)
		NumPut("UInt", T, WP, 32)
		NumPut("UInt", R, WP, 36)
		NumPut("UInt", B, WP, 40)

		Return DllCall("User32.dll\SetWindowPlacement", "Ptr", hwnd, "Ptr", WP)
	}

	static getMonitors() {
		monitors := []
		Loop(MonitorGetCount())
		{
			MonitorGet(A_Index, &mLeft, &mTop, &mRight, &mBottom)
			monitors.push({MonitorNumber:A_Index, Left:mLeft, Right:mRight, Top:mTop, Bottom:mBottom})
		}
		return monitors
	}

	static windowGetCoordinates(wHandle) {
		dhw := A_DetectHiddenWindows
		DetectHiddenWindows(1)
		minimize_status := WinGetMinMax(wHandle)
		NumPut("Uint", 44, pos := Buffer(44, 0))
		DllCall("GetWindowPlacement", "uint", wHandle, "uint", pos.ptr)
		mmx := NumGet(pos, 8, "int")
		x := NumGet(pos, 28, "int")
		y := NumGet(pos, 32, "int")
		w := NumGet(pos, 36, "int") - x
		h := NumGet(pos, 40, "int") - y
		pos := Buffer(16)
		DllCall("GetClientRect", "uint", wHandle, "uint", pos.ptr)
		cw := NumGet(pos, 8, "int")
		ch := NumGet(pos, 12, "int")
		DetectHiddenWindows(dhw)
		return {x: x, y: y, w: w, h: h, cw: cw, ch: ch, mmx: (mmx == 3 ? 1 : (mmx == 2 ? -1 : 0))}
	}

	static resetWindowPosition(wHandle := Winexist("A"), sizePercentage?, monitorNum?) {
		NumPut("Uint", 40, monitorInfo := Buffer(40))
		if (IsSet(monitorNum)) {
			MonitorGetWorkArea(monitorNum, &monLeft, &monTop, &monRight, &monBottom)
		} else {
			monitorHandle := DllCall("MonitorFromWindow", "Ptr", wHandle, "UInt", 0x2, "Ptr")
			DllCall("GetMonitorInfo", "Ptr", monitorHandle, "Ptr", monitorInfo)
				monLeft := NumGet(monitorInfo, 20, "Int") ; Left
				monTop := NumGet(monitorInfo, 24, "Int") ; Top
				monRight := NumGet(monitorInfo, 28, "Int") ; Right
				monBottom := NumGet(monitorInfo, 32, "Int") ; Bottom
		}
		WinRestore(wHandle)
		WinGetPos(&x, &y, &w, &h, wHandle)
		if (IsSet(sizePercentage))
			WinMove(
				monLeft + (monRight - monLeft) * (1 - sizePercentage) / 2, ; left edge of screen + half the width of it - half the width of the window, to center it.
				monTop + (monBottom - monTop) * (1 - sizePercentage) / 2,  ; same as above but with top bottom
				(monRight - monLeft) * sizePercentage,	; width
				(monBottom - monTop) * sizePercentage,	; height
				wHandle
			)
		else
			WinMove(
				monLeft + (monRight - monLeft) / 2 - w / 2, 
				monTop + (monBottom - monTop) / 2 - h / 2, , , wHandle
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