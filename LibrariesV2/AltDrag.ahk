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

/* ; <- uncomment this if you intend to use it as a standalone script
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
*/

class AltDrag {

	static __New() {
		InstallMouseHook()
		this.boolSnapping := true ; can be toggled in TrayMenu, this is the initial setting
		this.snappingRadius := 30 ; in pixels
		this.pixelCorrectionAmountLeft := 7 ; When snapping to a monitor edge,
		this.pixelCorrectionAmountTop := 0 ; the monitor border might be visually slightly different from its actual size.
		this.pixelCorrectionAmountRight := 7 ; This shifts the window edge outwards from the monitor edge to account
		this.pixelCorrectionAmountBottom := 7 ; for that
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
	 * @param {Array | String} blacklist Array of, or singular, ahk window identifier(s) to use in blacklist.
	 */
	static addBlacklist(blacklist) {
		if blacklist is Array
			for i, e in blacklist
				this.blacklist.Push(e)
		else
			this.blacklist.Push(blacklist)
	}

	static moveWindow(overrideBlacklist := false) {
		cleanHotkey := RegexReplace(A_ThisHotkey, "#|!|\^|\+|<|>|\$|~", "")
		SetWinDelay(3)
		CoordMode("Mouse", "Screen")
		MouseGetPos(&mouseX1, &mouseY1, &wHandle)
		if ((this.winInBlacklist(wHandle) && !overrideBlacklist) || WinGetMinMax(wHandle) != 0) {
			this.sendKey(cleanHotkey)
			return
		}
		WinGetPos(&winX1, &winY1, &winW, &winH, "ahk_id " . wHandle)
		WinActivate("ahk_id " . wHandle)
		while (GetKeyState(cleanHotkey, "P")) {
			MouseGetPos(&mouseX2, &mouseY2)
			nx := winX1 + mouseX2 - mouseX1
			ny := winY1 + mouseY2 - mouseY1
			if (this.boolSnapping) {
				mHandle := DllCall("MonitorFromWindow", "Ptr", wHandle, "UInt", 0x2, "Ptr")
				if (!this.monitors.Has(mHandle)) {
					NumPut("Uint", 40, monitorInfo := Buffer(40))
					DllCall("GetMonitorInfo", "Ptr", mHandle, "Ptr", monitorInfo)
					this.monitors[mHandle] := {
						left: NumGet(monitorInfo, 20, "Int"),
						top: NumGet(monitorInfo, 24, "Int"),
						right: NumGet(monitorInfo, 28, "Int"),
						bottom: NumGet(monitorInfo, 32, "Int")
					}
				}
				this.calculateSnapping(&nx, &ny, winW, winH, mHandle)
			}
			DllCall("SetWindowPos", "UInt", wHandle, "UInt", 0, "Int", nx, "Int", ny, "Int", 0, "Int", 0, "Uint", 0x0005)
			DllCall("Sleep", "UInt", 5)
		}
	}

	static resizeWindow(overrideBlacklist := false) {
		cleanHotkey := RegexReplace(A_ThisHotkey, "#|!|\^|\+|<|>|\$|~", "")
		SetWinDelay(-1)
		CoordMode("Mouse", "Screen")
		; abort if max/min or on blacklist
		MouseGetPos(&mouseX1, &mouseY1, &wHandle)
		if ((this.winInBlacklist(wHandle) && !overrideBlacklist) || WinGetMinMax(wHandle) != 0) {
			return this.sendKey(cleanHotkey)
		}
		WinGetPos(&winX, &winY, &winW, &winH, wHandle)
		WinActivate(wHandle)
		; direction from which direction to resize
		resizeLeft := (mouseX1 < winX + winW / 2)
		resizeUp := (mouseY1 < winY + winH / 2)
		wLimit := this.winMinMaxSize(wHandle)
		while GetKeyState(cleanHotkey, "P") {
			MouseGetPos(&mouseX2, &mouseY2)
			diffX := mouseX2 - mouseX1
			diffY := mouseY2 - mouseY1
			nx := (resizeLeft ? winX + Max(Min(diffX, winW - wLimit.minX), winW - wLimit.maxX) : winX)
			ny := (resizeUp ? winY + Max(Min(diffY, winH - wLimit.minY), winH - wLimit.maxY) : winY)
			nw := Min(Max((resizeLeft ? winW - diffX : winW + diffX), wLimit.minX), wLimit.MaxX)
			nh := Min(Max((resizeUp ? winH - diffY : winH + diffY), wLimit.minY), wLimit.MaxY)
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
	 * @param {Integer} overrideBlacklist Whether to trigger the function regardless if the window is blacklisted or not.
	 */
	static scaleWindow(direction := 1, scale_factor := 1.025, overrideBlacklist := false) {
		cleanHotkey := RegexReplace(A_ThisHotkey, "#|!|\^|\+|<|>|\$|~", "")
		SetWinDelay(-1)
		CoordMode("Mouse", "Screen")
		wHandle := WinExist("A")
		mmx := WinGetMinMax("ahk_id " . wHandle)
		if ((this.winInBlacklist(wHandle) && !overrideBlacklist) || mmx != 0) {
			return this.sendKey(cleanHotkey)
		}
		WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " . wHandle)
		mHandle := DllCall("MonitorFromWindow", "Ptr", wHandle, "UInt", 0x2, "Ptr")
		if (!this.monitors.Has(mHandle)) {
			NumPut("Uint", 40, mI := Buffer(40))
			DllCall("GetMonitorInfo", "Ptr", mHandle, "Ptr", mI)
			this.monitors[mHandle] := { left: NumGet(mI, 20, "Int"), top: NumGet(mI, 24, "Int"), right: NumGet(mI, 28, "Int"), bottom: NumGet(mI, 32, "Int") }
		}
		xChange := floor((this.monitors[mHandle].right - this.monitors[mHandle].left) * (scale_factor - 1))
		yChange := floor(winH * xChange / winW)
		wLimit := this.winMinMaxSize(wHandle)
		if (direction == 1) {
			nx := winX - xChange, ny := winY - yChange
			if ((nw := winW + 2 * xChange) >= wLimit.maxX || (nh := winH + 2 * yChange) >= wLimit.maxY)
				return
		}
		else {
			nx := winX + xChange, ny := winY + yChange
			if ((nw := winW - 2 * xChange) <= wLimit.minX || (nh := winH - 2 * yChange) <= wLimit.minY)
				return
		}
		;	tooltip % "x: " nx "`ny: " ny "`nw: " nw "`nh: " nh "`nxCh: " xChange "`nyCh: " yChange "`nminX: " wLimit.minX "`nminY: " wLimit.minY "`nmaxX: " wLimit.maxX "`nmaxY: " wLimit.maxY
		DllCall("SetWindowPos", "UInt", wHandle, "UInt", 0, "Int", nx, "Int", ny, "Int", nw, "Int", nh, "Uint", 0x0004)
	}

	static minimizeWindow(overrideBlacklist := false) {
		wHandle := WinExist("A")
		if (this.winInBlacklist(wHandle) && !overrideBlacklist)
			return
		WinMinimize("ahk_id " . wHandle)
	}

	static maximizeWindow(overrideBlacklist := false) {
		wHandle := WinExist("A")
		if (this.winInBlacklist(wHandle) && !overrideBlacklist)
			return
		WinMaximize("ahk_id " . wHandle)
	}

	static toggleMaxRestore(overrideBlacklist := false) {
		MouseGetPos(, , &win_id)
		if (this.winInBlacklist(win_id) && !overrideBlacklist)
			return
		win_mmx := WinGetMinMax("ahk_id " win_id)
		if (win_mmx)
			WinRestore("ahk_id " . win_id)
		else
			WinMaximize("ahk_id " . win_id)
	}

	static borderlessFullscreenWindow(overrideBlacklist := false) {
		MouseGetPos(, , &wHandle)
		if (this.winInBlacklist(wHandle) && !overrideBlacklist)
			return
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

	static calculateSnapping(&x, &y, w, h, mHandle) {
		if (abs(x - this.monitors[mHandle].left) < this.snappingRadius)
			x := this.monitors[mHandle].left - this.pixelCorrectionAmountLeft			; snap to left edge of screen
		else if (abs(x + w - this.monitors[mHandle].right) < this.snappingRadius)
			x := this.monitors[mHandle].right - w + this.pixelCorrectionAmountRight 	; snap to right edge of screen
		if (abs(y - this.monitors[mHandle].top) < this.snappingRadius)
			y := this.monitors[mHandle].top	- this.pixelCorrectionAmountTop				; snap to top edge of screen
		else if (abs(y + h - this.monitors[mHandle].bottom) < this.snappingRadius)
			y := this.monitors[mHandle].bottom - h + this.pixelCorrectionAmountBottom	; snap to bottom edge of screen
	}

	static winInBlacklist(wHandle) {
		for i, e in this.blacklist
			if WinExist(e . " ahk_id " . wHandle)
				return 1
		return 0
	}

	static winMinMaxSize(wHandle) {
		MINMAXINFO := Buffer(40, 0)
		SendMessage(0x24, , MINMAXINFO, , "ahk_id " . wHandle) ;WM_GETMINMAXINFO := 0x24
		vMinX := Max(NumGet(MINMAXINFO, 24, "Int"), this.minMaxSystem.minX)
		vMinY := Max(NumGet(MINMAXINFO, 28, "Int"), this.minMaxSystem.minY)
		vMaxX := (NumGet(MINMAXINFO, 32, "Int") == 0 ? this.minMaxSystem.MaxX : NumGet(MINMAXINFO, 32, "Int"))
		vMaxY := (NumGet(MINMAXINFO, 36, "Int") == 0 ? this.minMaxSystem.MaxY : NumGet(MINMAXINFO, 36, "Int"))
		return { minX: vMinX, minY: vMinY, maxX: vMaxX, maxY: vMaxY }
	}

	static windowBlacklistedOrMaximized(wHandle) {
		winmmx := WinGetMinMax("ahk_id " . wHandle)
		if (winmmx)
			return 1
		for i, e in this.blacklist
			if WinExist(e . " ahk_id " . wHandle)
				return 1
		return 0
	}

	static snappingToggle(*) {
		AltDrag.boolSnapping := !AltDrag.boolSnapping
		A_TrayMenu.ToggleCheck("Enable Snapping")
	}

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