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

/* ; <- uncomment the /* if you intend to use it as a standalone script
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
; */
#Include "%A_LineFile%\..\..\LibrariesV2\WinUtilities.ahk"

class AltDrag {

	static __New() {
		InstallMouseHook()
		; note:
		; snapping can be toggled (both at once) in the tray menu.
		; snapping to window edges includes all windows (that are actual windows on the desktop)
		; with a window behind another, that can cause snapping to windows which aren't visible
		; aligning windows is only possible when resizing in the corresponding corner of the window
		this.snapToMonitorEdges := true
		this.snapToWindowEdges := true
		this.snapToAlignWindows := true
		this.snapOnlyWhileHoldingModifierKey := true ; snaps to edges/windows while holding alt (or other modifier)
		this.snappingRadius := 30 ; in pixels
		this.aligningRadius := 30
		this.blacklist := WinUtilities.defaultBlacklist
		this.modifierKeyList := Map('#', "LWin", '!', "Alt", '^', 'Control', '+', 'Shift')
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
		RegExMatch(A_ThisHotkey, "((?:#|!|\^|\+|<|>|\$|~)+)(.*)", &hkeyMatch)
		cleanHotkey := hkeyMatch[2]
		modifier := RegExReplace(hkeyMatch[1], "\$|~|<|>")
		modSymbol := this.modifierKeyList.Has(modifier) ? this.modifierKeyList[modifier] : 'Alt'
		SetWinDelay(3)
		CoordMode("Mouse", "Screen")
		MouseGetPos(&mouseX1, &mouseY1, &wHandle)
		if ((WinUtilities.winInBlacklist(wHandle, this.blacklist) && !overrideBlacklist) || WinGetMinMax(wHandle) != 0)
			return this.sendKey(cleanHotkey)
		pos := WinUtilities.WinGetPosEx(wHandle)
		curWindowPositions := this.getWindowRects(wHandle)
		WinActivate(wHandle)
		while (GetKeyState(cleanHotkey, "P")) {
			MouseGetPos(&mouseX2, &mouseY2)
			nx := pos.x + mouseX2 - mouseX1
			ny := pos.y + mouseY2 - mouseY1
			if !this.snapOnlyWhileHoldingModifierKey || GetKeyState(modSymbol) {
				if this.snapToWindowEdges
					calculateWindowSnapping()
				if this.snapToMonitorEdges
					calculateMonitorSnapping()
			}
			; WinUtilities.WinMoveEx(hwnd, nx, ny)
			DllCall("SetWindowPos", "UInt", wHandle, "UInt", 0, "Int", nx - pos.LB, "Int", ny - pos.TB, "Int", 0, "Int", 0, "Uint", 0x0005)
			DllCall("Sleep", "UInt", 5)
		}

		calculateMonitorSnapping() {
			monitor := WinUtilities.monitorGetInfoFromWindow(wHandle)
			if (abs(nx - monitor.wLeft) < this.snappingRadius)
				nx := monitor.wLeft			; left edge
			else if (abs(nx + pos.w - monitor.wRight) < this.snappingRadius)
				nx := monitor.wRight - pos.w 	; right edge
			if (abs(ny - monitor.wTop) < this.snappingRadius)
				ny := monitor.wTop				; top edge
			else if (abs(ny + pos.h - monitor.wBottom) < this.snappingRadius)
				ny := monitor.wBottom - pos.h	; bottom edge
		}

		calculateWindowSnapping() {
			; win := { x: L, y: T, w: R - L, h: B - T, LB: leftBorder, TB: topBorder, RB: rightBorder, BB: bottomBorder}
			for i, win in arrayInReverse(curWindowPositions) { ; iterate backwards so that the prioritized snap is highest in z-order (and lowest in array)
				; check whether the windows are even near each other -> must vertically overlap to have horizontal snap
				if (isClamped(ny, win.y, win.y2) || isClamped(win.y, ny, ny + pos.h)) {
					if (isSnap := (abs(nx - win.x2) < this.snappingRadius)) ; left edge of moving window to right edge of desktop window
						nx := win.x2		; left edge
					else if (isSnap |= (abs(nx + pos.w - win.x) < this.snappingRadius)) ; right edge to left edge
						nx := win.x - pos.w 	; right edge
					if (this.snapToAlignWindows && isSnap) {
						if (abs(ny - win.y) < this.aligningRadius)
							ny := win.y
						else if (abs(ny + pos.h - win.y2) < this.aligningRadius)
							ny := win.y2 - pos.h
					}
				}
				if (isClamped(nx, win.x, win.x2) || isClamped(win.x, nx, nx + pos.w)) {
					if (isSnap := (abs(ny - win.y2) < this.snappingRadius)) ; top edge to bottom edge
						ny := win.y2 ; top edge
					else if (isSnap |= (abs(ny + pos.h - win.y) < this.snappingRadius))
						ny := win.y - pos.h	; bottom edge
					if (this.snapToAlignWindows && isSnap) {
						if (abs(nx - win.x) < this.aligningRadius)
							nx := win.x
						else if (abs(ny + pos.x - win.x2) < this.aligningRadius)
							nx := win.x2 - pos.x
					}
				}
			}
		}
	}

	static resizeWindow(overrideBlacklist := false) {
		RegExMatch(A_ThisHotkey, "((?:#|!|\^|\+|<|>|\$|~)+)(.*)", &hkeyMatch)
		cleanHotkey := hkeyMatch[2]
		modifier := RegExReplace(hkeyMatch[1], "\$|~|<|>")
		modSymbol := this.modifierKeyList.Has(modifier) ? this.modifierKeyList[modifier] : 'Alt'
		SetWinDelay(-1)
		CoordMode("Mouse", "Screen")
		MouseGetPos(&mouseX1, &mouseY1, &wHandle)
		if ((WinUtilities.winInBlacklist(wHandle, this.blacklist) && !overrideBlacklist) || WinGetMinMax(wHandle) != 0)
			return this.sendKey(cleanHotkey)
		pos := WinUtilities.WinGetPosEx(wHandle)
		curWindowPositions := this.getWindowRects(wHandle)
		WinActivate(wHandle)
		resizeLeft := (mouseX1 < pos.x + pos.w / 2)
		resizeUp := (mouseY1 < pos.y + pos.h / 2)
		limits := WinUtilities.getMinMaxResizeCoords(wHandle)
		while GetKeyState(cleanHotkey, "P") {
			MouseGetPos(&mouseX2, &mouseY2)
			diffX := mouseX2 - mouseX1
			diffY := mouseY2 - mouseY1
			nx := pos.x
			ny := pos.y
			if resizeLeft
				nx += clamp(diffX, pos.w - limits.maxW, pos.w - limits.minW)
			if resizeUp
				ny += clamp(diffY, pos.h - limits.maxH, pos.h - limits.minH)
			nw := clamp(resizeLeft ? pos.w - diffX : pos.w + diffX, limits.minW, limits.maxW)
			nh := clamp(resizeUp ? pos.h - diffY : pos.h + diffY, limits.minH, limits.maxH)
			if !this.snapOnlyWhileHoldingModifierKey || GetKeyState(modSymbol) {
				if this.snapToWindowEdges
					calculateWindowSnapping()
				if this.snapToMonitorEdges
					calculateMonitorSnapping()
			}
			DllCall("SetWindowPos", "UInt", wHandle, "UInt", 0, "Int", nx - pos.LB, "Int", ny - pos.TB, "Int", nw + pos.LB + pos.RB, "Int", nh + pos.TB + pos.BB, "Uint", 0x0004)
			DllCall("Sleep", "UInt", 5)
		}

		calculateMonitorSnapping() {
			monitor := WinUtilities.monitorGetInfoFromWindow(wHandle)
			if (resizeLeft && abs(nx - monitor.wLeft) < this.snappingRadius) {
				nw := nw + nx - monitor.wLeft
				nx := monitor.wLeft
			} else if (abs(nx + nw - monitor.wRight) < this.snappingRadius)
				nw := monitor.wRight - nx
			if (resizeUp && abs(ny - monitor.wTop) < this.snappingRadius) {
				nh := nh + ny - monitor.wTop
				ny := monitor.wTop				; top edge
			} else if (abs(ny + nh - monitor.wBottom) < this.snappingRadius)
				nh := monitor.wBottom - ny
		}

		calculateWindowSnapping() {
			for i, win in arrayInReverse(curWindowPositions) {
				if (isClamped(ny, win.y, win.y2) || isClamped(win.y, ny, ny + nh)) {
					if (isSnap := (resizeLeft && isSnap := (abs(nx - win.x2) < this.snappingRadius))) { ; left edge of moving window to right edge of desktop window
						nw := nw + nx - win.x2
						nx := win.x2
					} else if (isSnap |= (abs(nx + nw - win.x) < this.snappingRadius)) { ; right edge to left edge
						nw := win.x - nx
					}
					if (this.snapToAlignWindows && isSnap) {
						if (resizeUp && abs(ny - win.y) < this.aligningRadius) {
							nh := nh + ny - win.y
							ny := win.y
						} else if (abs(ny + nh - win.y2) < this.aligningRadius) {
							nh := win.y2 - ny
						}
					}
				}
				if (isClamped(nx, win.x, win.x2) || isClamped(win.x, nx, nx + nw)) {
					if (isSnap := (resizeUp && (abs(ny - win.y2) < this.snappingRadius))) { ; top edge to bottom edge
						nh := nh + ny - win.y2
						ny := win.y2
					} else if (isSnap |= (abs(ny + nh - win.y) < this.snappingRadius)) {
						nh := win.y - ny
					}
					if (this.snapToAlignWindows && isSnap) {
						if (resizeLeft && abs(nx - win.x) < this.aligningRadius) {
							nw := nw + nx - win.x
							nx := win.x
						} else if (abs(nx + nw - win.x2) < this.aligningRadius) {
							nw := win.x2 - nx
						}
					}
				}
			}
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
		AltDrag.snapToMonitorEdges := !AltDrag.snapToMonitorEdges
		AltDrag.snapToWindowEdges := !AltDrag.snapToWindowEdges
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

	static getWindowRects(exceptForwHandle) {
		curWindowPositions := []
		for i, v in WinUtilities.getBasicInfo() {
			if v.state != 0 || v.hwnd == exceptForwHandle
				continue
			v.x2 := v.x + v.w
			v.y2 := v.y + v.h
			curWindowPositions.push(v)	
		}
		return curWindowPositions
	}
}