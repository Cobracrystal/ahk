; https://github.com/cobracrystal/ahk
/*
;---'Traditional' Hotkeys:
;  Alt + Left Button	: Drag to move a window.
;  Alt + Right Button	: Drag to resize a window.
;  Alt + Middle Button	: Click to switch Max/Restore state of a window.
;--- & Non-Traditional
;  Alt + Middle Button	: Scroll to scale a window.
;  Alt + X4 Button		: Click to minimize a window.
;  Alt + X5 Button		: Click to make window enter borderless fullscreen

*/

 ; <- uncomment this if you intend to use it as a standalone script
; Drag Window
!LButton::{
	AltDrag.moveWindow()
}

; Resize Window
!RButton::{
	AltDrag.resizeWindow()
}

; Toggle Max/Restore of clicked window
!MButton::{
	AltDrag.toggleMaxRestore()
}

; Scale Window Down
!WheelDown::{
	AltDrag.scaleWindow(-1)
}

; Scale Window Up
!WheelUp::{
	AltDrag.scaleWindow(1)
}

; Minimize Window
!XButton1::{
	AltDrag.minimizeWindow()
}

; Make Window Borderless Fullscreen
!XButton2::{
	AltDrag.borderlessFullscreenWindow()
}


class AltDrag {

	static __New() {
		InstallMouseHook()
		this.boolSnapping := true ; can be toggled in TrayMenu, this is the initial setting
		this.snappingRadius := 30 ; in pixels
		this.pixelCorrectionAmountLeft := 7 ; When snapping to a monitor edge, a window edge may be appear slightly shifted from its actual size.
		this.pixelCorrectionAmountTop := 0 ; This shifts the snapping edge the specified amount of pixels outwards from the monitor edge to account for that.
		this.pixelCorrectionAmountRight := 7 ; Note that this is designed for windows Explorer windows as the baseline, which have a different size from other windows.
		this.pixelCorrectionAmountBottom := 7
		this.blacklist := [
			"ahk_class MultitaskingViewFrame ahk_exe explorer.exe",
			"ahk_class Windows.UI.Core.CoreWindow",
			"ahk_class WorkerW ahk_exe explorer.exe",
			"ahk_class Shell_SecondaryTrayWnd ahk_exe explorer.exe",
			"ahk_class Shell_TrayWnd ahk_exe explorer.exe"
		]	; initial blacklist. Includes alt+tab screen, startmenu, desktop screen and taskbars (in that order).
		this.monitors := Map()
		this.minMaxSystem := { minX: SysGet(34), minY: SysGet(35), maxX: SysGet(59), maxY: SysGet(60) }
		A_TrayMenu.Add("Enable Snapping", this.snappingToggle)
		A_TrayMenu.ToggleCheck("Enable Snapping")
	}

	/**
	 * Add any ahk window identifier to exclude from all operations.
	 * @param {Array | String} blacklistEntries Array of, or singular, ahk window identifier(s) to use in blacklist.
	 */
	static addBlacklist(blacklistEntries) {
		if blacklistEntries is Array
			for i, e in blacklistEntries
				this.blacklist.Push(e)
		else
			this.blacklist.Push(blacklistEntries)
	}

	static moveWindow(overrideBlacklist := false) {
		cleanHotkey := RegexReplace(A_ThisHotkey, "#|!|\^|\+|<|>|\$|~", "")
		SetWinDelay(3)
		CoordMode("Mouse", "Screen")
		MouseGetPos(&mouseX1, &mouseY1, &hwnd)
		if ((this.winInBlacklist(hwnd) && !overrideBlacklist) || WinGetMinMax(hwnd) != 0) {
			this.sendKey(cleanHotkey)
			return
		}
		pos := this.WinGetPosEx(hwnd)
		WinActivate(hwnd)
		while (GetKeyState(cleanHotkey, "P")) {
			MouseGetPos(&mouseX2, &mouseY2)
			nx := pos.x + mouseX2 - mouseX1
			ny := pos.y + mouseY2 - mouseY1
			if (this.boolSnapping) {
				mHandle := DllCall("MonitorFromWindow", "Ptr", hwnd, "UInt", 0x2, "Ptr")
				if (!this.monitors.Has(mHandle)) ; this should only call once
					this.monitors[mHandle] := this.monitorGetWorkArea(mHandle)
				calculateSnapping()
			}
			; WinUtilities.WinMoveEx(hwnd, nx, ny)
			DllCall("SetWindowPos", "UInt", hwnd, "UInt", 0, "Int", nx - pos.LB, "Int", ny - pos.TB, "Int", 0, "Int", 0, "Uint", 0x0005)
			DllCall("Sleep", "UInt", 5)
		}

		calculateSnapping() {
			if (abs(nx - this.monitors[mHandle].left) < this.snappingRadius)
				nx := this.monitors[mHandle].left			; left edge
			else if (abs(nx + pos.w - this.monitors[mHandle].right) < this.snappingRadius)
				nx := this.monitors[mHandle].right - pos.w 	; right edge
			if (abs(ny - this.monitors[mHandle].top) < this.snappingRadius)
				ny := this.monitors[mHandle].top				; top edge
			else if (abs(ny + pos.h - this.monitors[mHandle].bottom) < this.snappingRadius)
				ny := this.monitors[mHandle].bottom - pos.h	; bottom edge
		}
	}

	static resizeWindow(overrideBlacklist := false) {
		cleanHotkey := RegexReplace(A_ThisHotkey, "#|!|\^|\+|<|>|\$|~", "")
		SetWinDelay(-1)
		CoordMode("Mouse", "Screen")
		MouseGetPos(&mouseX1, &mouseY1, &wHandle)
		if ((this.winInBlacklist(wHandle) && !overrideBlacklist) || WinGetMinMax(wHandle) != 0) {
			return this.sendKey(cleanHotkey)
		}
		WinGetPos(&winX, &winY, &winW, &winH, wHandle)
		WinActivate(wHandle)
		; corner from which direction to resize
		resizeLeft := (mouseX1 < winX + winW / 2)
		resizeUp := (mouseY1 < winY + winH / 2)
		limits := this.getMinMaxResizeCoords(wHandle)
		while GetKeyState(cleanHotkey, "P") {
			MouseGetPos(&mouseX2, &mouseY2)
			diffX := mouseX2 - mouseX1
			diffY := mouseY2 - mouseY1
			if resizeLeft
				winX += this.clamp(diffX, winW - limits.maxW, winW - limits.minW)
			if resizeUp
				winY += this.clamp(diffY, winH - limits.maxH, winH - limits.minH)
			nx := winX, ny := winY
			nw := this.clamp(resizeLeft ? winW - diffX : winW + diffX, limits.minW, limits.maxW)
			nh := this.clamp(resizeUp ? winH - diffY : winH + diffY, limits.minH, limits.maxH)
			;	if (nw == wLimit.minX && nh == wLimit.minY)
			;		continue ; THIS CAUSES JUMPS (or stucks) BECAUSE IT DOESN'T UPDATE THE VERY LAST RESIZE IT NEEDS TO. CHECK PREVIOUS SIZE?
			;	tooltip % "x: " nx "`ny: " ny "`nw: " nw "`nh: " nh "`nlimX " wLimit.minX "`nlimY " wLimit.minY
			DllCall("SetWindowPos", "UInt", wHandle, "UInt", 0, "Int", nx, "Int", ny, "Int", nw, "Int", nh, "Uint", 0x0004)
			DllCall("Sleep", "UInt", 5)
		}
	}

	/**
	 * In- or decreases window size.
	 * @param {Integer} direction Whether to scale up or down. If 1, scales the window larger, if -1 (or any other value), smaller.
	 * @param {Float} scale_factor Amount by which to increase window size per function trigger. NOT exponential. eg if scale factor is 1.05, window increases by 5% of monitor width every function call.
	 * @param {Integer} wHandle The window handle upon which to operate. If not given, assumes the window over which mouse is hovering.
	 * @param {Integer} overrideBlacklist Whether to trigger the function regardless if the window is blacklisted or not.
	 */
	static scaleWindow(direction := 1, scale_factor := 1.025, wHandle := 0, overrideBlacklist := false) {
		cleanHotkey := RegexReplace(A_ThisHotkey, "#|!|\^|\+|<|>|\$|~", "")
		SetWinDelay(-1)
		CoordMode("Mouse", "Screen")
		if (!wHandle)
			MouseGetPos(,,&wHandle)
		mmx := WinGetMinMax(wHandle)
		if ((this.winInBlacklist(wHandle) && !overrideBlacklist) || mmx != 0) {
			return this.sendKey(cleanHotkey)
		}
		WinGetPos(&winX, &winY, &winW, &winH, wHandle)
		mHandle := DllCall("MonitorFromWindow", "Ptr", wHandle, "UInt", 0x2, "Ptr")
		if (!this.monitors.Has(mHandle))
			this.monitors[mHandle] := this.monitorGetWorkArea(mHandle)
		xChange := floor((this.monitors[mHandle].right - this.monitors[mHandle].left) * (scale_factor - 1))
		yChange := floor(winH * xChange / winW)
		wLimit := this.getMinMaxResizeCoords(wHandle)
		if (direction == 1) {
			nx := winX - xChange, ny := winY - yChange
			if ((nw := winW + 2 * xChange) >= wLimit.maxH || (nh := winH + 2 * yChange) >= wLimit.maxH)
				return
		}
		else {
			nx := winX + xChange, ny := winY + yChange
			if ((nw := winW - 2 * xChange) <= wLimit.minW || (nh := winH - 2 * yChange) <= wLimit.minH)
				return
		}
		;	tooltip % "x: " nx "`ny: " ny "`nw: " nw "`nh: " nh "`nxCh: " xChange "`nyCh: " yChange "`nminX: " wLimit.minX "`nminY: " wLimit.minY "`nmaxX: " wLimit.maxX "`nmaxY: " wLimit.maxY
		DllCall("SetWindowPos", "UInt", wHandle, "UInt", 0, "Int", nx, "Int", ny, "Int", nw, "Int", nh, "Uint", 0x0004)
	}

	static minimizeWindow(overrideBlacklist := false) {
		MouseGetPos(, , &wHandle)
		if (this.winInBlacklist(wHandle) && !overrideBlacklist)
			return
		WinMinimize(wHandle)
	}

	static maximizeWindow(overrideBlacklist := false) {
		MouseGetPos(, , &wHandle)
		if (this.winInBlacklist(wHandle) && !overrideBlacklist)
			return
		WinMaximize(wHandle)
	}

	static toggleMaxRestore(overrideBlacklist := false) {
		MouseGetPos(, , &wHandle)
		if (this.winInBlacklist(wHandle) && !overrideBlacklist)
			return
		win_mmx := WinGetMinMax(wHandle)
		if (win_mmx)
			WinRestore(wHandle)
		else
			WinMaximize(wHandle)
	}

	static borderlessFullscreenWindow(wHandle := WinExist("A"), overrideBlacklist := false) {
		if (this.winInBlacklist(wHandle) && !overrideBlacklist)
			return
		if (WinGetMinMax(wHandle))
			WinRestore(wHandle)
		WinGetPos(&x, &y, &w, &h, wHandle)
		WinGetClientPos(&cx, &cy, &cw, &ch, wHandle)
		mHandle := DllCall("MonitorFromWindow", "Ptr", wHandle, "UInt", 0x2, "Ptr")
		monitor := this.monitorGetWorkArea(mHandle)
		WinMove(
			monitor.left + (x - cx),
			monitor.top + (y - cy),
			monitor.right - monitor.left + (w - cw),
			monitor.bottom - monitor.top + (h - ch),
			wHandle
		)
	}

	/**
	 * Restores and moves the specified window in the middle of the primary monitor
	 * @param wHandle Numeric Window Handle, uses active window by default
	 * @param sizePercentage The percentage of the total monitor size that the window will occupy
	 */
	static resetWindowPosition(wHandle := Winexist("A"), sizePercentage := 5/7) {
		monitorHandle := DllCall("MonitorFromWindow", "Ptr", wHandle, "UInt", 0x2, "Ptr")
		mon := this.monitorGetWorkArea(monitorHandle)
		WinRestore(wHandle)
		mWidth := mon.right - mon.left, mHeight := mon.bot - mon.top
		WinMove(
			mon.left + mWidth / 2 * (1 - sizePercentage), ; left edge of screen + half the width of it - half the width of the window, to center it.
			mon.top + mHeight / 2 * (1 - sizePercentage),  ; same as above but with top bottom
			mWidth * sizePercentage,
			mHeight * sizePercentage,
			wHandle
		)
	}

	static winInBlacklist(wHandle) {
		for i, e in this.blacklist
			if WinExist(e . " ahk_id " . wHandle)
				return 1
		return 0
	}

	static monitorGetWorkArea(monitorHandle) {
		NumPut("Uint", 40, monitorInfo := Buffer(40))
		DllCall("GetMonitorInfo", "Ptr", monitorHandle, "Ptr", monitorInfo)
		return {
			left: NumGet(monitorInfo, 20, "Int"),
			top: NumGet(monitorInfo, 24, "Int"),
			right: NumGet(monitorInfo, 28, "Int"),
			bottom: NumGet(monitorInfo, 32, "Int")
		}
	}

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
		maxWidth  := maxWidth == 0 ? sysMaxWidth : maxWidth
		maxHeight := maxHeight == 0 ? sysMaxHeight : maxHeight
		return { minW: minWidth, minH: minHeight, maxW: maxWidth, maxH: maxHeight }
	}

	static snappingToggle(*) {
		AltDrag.boolSnapping := !AltDrag.boolSnapping
		A_TrayMenu.ToggleCheck("Enable Snapping")
	}

	static clamp(n, minimum, maximum) => Max(minimum, Min(n, maximum))

	static sendKey(hkey) {
		if (!hkey)
			return
		if (hkey = "WheelDown" || hkey = "WheelUp")
			hkey := "{" hkey "}"
		if (hkey = "LButton" || hkey = "RButton" || hkey = "MButton") {
			hhL := SubStr(hkey, 1, 1)
			Click("Down " . hhL)
			Hotkey("*" hkey " Up", this.sendClickUp.bind(this, hhL), "On")
			; while(GetKeyState(hkey, "P"))
			;	continue
			; Click("Up " hhL)
		} else
			Send("{Blind}" . hkey)
		return 0
	}

	static sendClickUp(hhL, hkey) {
		Click("Up " . hhL)
		Hotkey(hkey, "Off")
	}
}