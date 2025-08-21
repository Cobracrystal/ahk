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

; Technically, scaling via Alt+ScrollUp stops a bit before the *actual* max window size is reached (due to client area differences)
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
#Include "%A_LineFile%\..\..\LibrariesV2\WinUtilities.ahk"

class AltDrag {

	static __New() {
		InstallMouseHook()
		this.boolSnapping := true ; can be toggled in TrayMenu, this is the initial setting
		this.snappingRadius := 30 ; in pixels
		this.pixelCorrectionAmountLeft := 7 ; When snapping to a monitor edge, a window edge may be appear slightly shifted from its actual size.
		this.pixelCorrectionAmountTop := 0 ; This shifts the snapping edge the specified amount of pixels outwards from the monitor edge to account for that.
		this.pixelCorrectionAmountRight := 7 ; Note that this is designed for windows Explorer windows as the baseline, which have a different size from other windows.
		this.pixelCorrectionAmountBottom := 7
		this.blacklist := WinUtilities.defaultBlacklist
		this.blacklist := [
			"ahk_class MultitaskingViewFrame ahk_exe explorer.exe",
			"ahk_class Windows.UI.Core.CoreWindow",
			"ahk_class WorkerW ahk_exe explorer.exe",
			"ahk_class Shell_SecondaryTrayWnd ahk_exe explorer.exe",
			"ahk_class Shell_TrayWnd ahk_exe explorer.exe"
		]	; initial blacklist. Includes alt+tab screen, startmenu, desktop screen and taskbars (in that order).
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
		MouseGetPos(&mouseX1, &mouseY1, &wHandle)
		if ((WinUtilities.winInBlacklist(wHandle, this.blacklist) && !overrideBlacklist) || WinGetMinMax(wHandle) != 0) {
			this.sendKey(cleanHotkey)
			return
		}
		pos := WinUtilities.WinGetPosEx(wHandle)
		WinActivate(wHandle)
		while (GetKeyState(cleanHotkey, "P")) {
			MouseGetPos(&mouseX2, &mouseY2)
			nx := pos.x + mouseX2 - mouseX1
			ny := pos.y + mouseY2 - mouseY1
			if (this.boolSnapping) {
				monitor := WinUtilities.monitorGetInfoFromWindow(wHandle)
				calculateSnapping()
			}
			; WinUtilities.WinMoveEx(hwnd, nx, ny)
			DllCall("SetWindowPos", "UInt", wHandle, "UInt", 0, "Int", nx - pos.LB, "Int", ny - pos.TB, "Int", 0, "Int", 0, "Uint", 0x0005)
			DllCall("Sleep", "UInt", 5)
		}

		calculateSnapping() {
			if (abs(nx - monitor.wLeft) < this.snappingRadius)
				nx := monitor.wLeft			; left edge
			else if (abs(nx + pos.w - monitor.wRight) < this.snappingRadius)
				nx := monitor.wRight - pos.w 	; right edge
			if (abs(ny - monitor.wTop) < this.snappingRadius)
				ny := monitor.wTop				; top edge
			else if (abs(ny + pos.h - monitor.wBottom) < this.snappingRadius)
				ny := monitor.wBottom - pos.h	; bottom edge
		}
	}

	static resizeWindow(overrideBlacklist := false) {
		cleanHotkey := RegexReplace(A_ThisHotkey, "#|!|\^|\+|<|>|\$|~", "")
		SetWinDelay(-1)
		CoordMode("Mouse", "Screen")
		MouseGetPos(&mouseX1, &mouseY1, &wHandle)
		if ((WinUtilities.winInBlacklist(wHandle, this.blacklist) && !overrideBlacklist) || WinGetMinMax(wHandle) != 0) {
			return this.sendKey(cleanHotkey)
		}
		WinGetPos(&winX, &winY, &winW, &winH, wHandle)
		WinActivate(wHandle)
		; corner from which direction to resize
		resizeLeft := (mouseX1 < winX + winW / 2)
		resizeUp := (mouseY1 < winY + winH / 2)
		limits := WinUtilities.getMinMaxResizeCoords(wHandle)
		while GetKeyState(cleanHotkey, "P") {
			MouseGetPos(&mouseX2, &mouseY2)
			diffX := mouseX2 - mouseX1
			diffY := mouseY2 - mouseY1
			nx := winX, ny := winY
			if resizeLeft
				nx += clamp(diffX, winW - limits.maxW, winW - limits.minW)
			if resizeUp
				ny += clamp(diffY, winH - limits.maxH, winH - limits.minH)
			nw := clamp(resizeLeft ? winW - diffX : winW + diffX, limits.minW, limits.maxW)
			nh := clamp(resizeUp ? winH - diffY : winH + diffY, limits.minH, limits.maxH)
			;	if (nw == wLimit.minW && nh == wLimit.minH)
			;		continue ; THIS CAUSES JUMPS (or stucks) BECAUSE IT DOESN'T UPDATE THE VERY LAST RESIZE IT NEEDS TO. CHECK PREVIOUS SIZE?
			;	tooltip % "x: " nx "`ny: " ny "`nw: " nw "`nh: " nh "`nlimX " wLimit.minW "`nlimY " wLimit.minH
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
		if ((WinUtilities.winInBlacklist(wHandle, this.blacklist) && !overrideBlacklist) || mmx != 0) {
			return this.sendKey(cleanHotkey)
		}
		WinGetPos(&winX, &winY, &winW, &winH, wHandle)
		monitor := WinUtilities.monitorGetInfoFromWindow(wHandle)
		xChange := floor((monitor.wRight - monitor.wLeft) * (scale_factor - 1))
		yChange := floor(winH * xChange / winW)
		wLimit := WinUtilities.getMinMaxResizeCoords(wHandle)
		if (direction == 1) {
			nx := winX - xChange, ny := winY - yChange
			if ((nw := winW + 2 * xChange) >= wLimit.maxW || (nh := winH + 2 * yChange) >= wLimit.maxH)
				return
		}
		else {
			nx := winX + xChange, ny := winY + yChange
			if ((nw := winW - 2 * xChange) <= wLimit.minW || (nh := winH - 2 * yChange) <= wLimit.minH)
				return
		}
		;	tooltip % "x: " nx "`ny: " ny "`nw: " nw "`nh: " nh "`nxCh: " xChange "`nyCh: " yChange "`nminW: " wLimit.minW "`nminH: " wLimit.minH "`nmaxW: " wLimit.maxW "`nmaxH: " wLimit.maxH
		DllCall("SetWindowPos", "UInt", wHandle, "UInt", 0, "Int", nx, "Int", ny, "Int", nw, "Int", nh, "Uint", 0x0004)
	}

	static minimizeWindow(overrideBlacklist := false) {
		MouseGetPos(, , &wHandle)
		if (WinUtilities.winInBlacklist(wHandle, this.blacklist) && !overrideBlacklist)
			return
		WinMinimize(wHandle)
	}

	static maximizeWindow(overrideBlacklist := false) {
		MouseGetPos(, , &wHandle)
		if (WinUtilities.winInBlacklist(wHandle, this.blacklist) && !overrideBlacklist)
			return
		WinMaximize(wHandle)
	}

	static toggleMaxRestore(overrideBlacklist := false) {
		MouseGetPos(, , &wHandle)
		if (WinUtilities.winInBlacklist(wHandle, this.blacklist) && !overrideBlacklist)
			return
		win_mmx := WinGetMinMax(wHandle)
		if (win_mmx)
			WinRestore(wHandle)
		else {
			if (WinUtilities.isBorderlessFullscreen(wHandle))
				WinUtilities.resetWindowPosition(wHandle, 5/7)
			else
				WinMaximize(wHandle)
		}
	}

	static borderlessFullscreenWindow(wHandle := WinExist('A'), overrideBlacklist := false) {
		if (WinUtilities.winInBlacklist(wHandle, this.blacklist) && !overrideBlacklist)
			return
		if (WinGetMinMax(wHandle))
			WinRestore(wHandle)
		WinUtilities.borderlessFullscreenWindow(wHandle)
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