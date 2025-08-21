#Include "%A_LineFile%\..\..\LibrariesV2\ObjectUtilities.ahk"

class WinUtilities {
	static __New() {
		this.windowCache := Map()
		this.monitorCache := Map()
	}

	static getAllWindows(getHidden := false, blacklist := this.defaultBlacklist) {
		windows := []
		dHW := A_DetectHiddenWindows
		DetectHiddenWindows(getHidden)
		wHandles := WinGetList()
		for wHandle in wHandles
			if !this.winInBlacklist(wHandle, blacklist)
				windows.push(wHandle)
		DetectHiddenWindows(dHW)
		return windows
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

	/**
	 * Whether or not the desktop is locked (concretely: we are in lockscreen)
	 * @returns {Boolean} 
	 */
	static sessionIsLocked() {
		static WTS_CURRENT_SERVER_HANDLE := 0, WTSSessionInfoEx := 25, WTS_SESSIONSTATE_LOCK := 0x00000000
		ret := false, sessionID := 0, sesInfo := 0, BytesReturned := 0
		flag1 := DllCall("ProcessIdToSessionId", "UInt", DllCall("GetCurrentProcessId", "UInt"), "UInt*", &sessionId)
		flag2 := DllCall("wtsapi32\WTSQuerySessionInformation", "Ptr", WTS_CURRENT_SERVER_HANDLE, "UInt", sessionId, "UInt", WTSSessionInfoEx, "Ptr*", &sesInfo, "Ptr*", &BytesReturned)
		if (flag1 && flag2) {
			SessionFlags := NumGet(sesInfo+0, 16, "Int")
			if (SessionFlags == WTS_SESSIONSTATE_LOCK)
				ret := true
			DllCall("wtsapi32\WTSFreeMemory", "Ptr", sesInfo)
		}
		return ret
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