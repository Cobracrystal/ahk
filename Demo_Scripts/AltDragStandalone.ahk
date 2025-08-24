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
#Include ..\LibrariesV2\BasicUtilities.ahk
 ; <- uncomment the /* if you intend to use it as a standalone script
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
		this.modifierKeyList := Map('#', "LWin", '!', "Alt", '^', 'Control', '+', 'Shift')
		this.blacklist := [
			"",
			"NVIDIA GeForce Overlay",
			"ahk_class MultitaskingViewFrame ahk_exe explorer.exe",
			"ahk_class Windows.UI.Core.CoreWindow",
			"ahk_class WorkerW ahk_exe explorer.exe",
			"ahk_class Progman ahk_exe explorer.exe",
			"ahk_class Shell_TrayWnd ahk_exe explorer.exe",
			"ahk_class Shell_SecondaryTrayWnd ahk_exe explorer.exe"
		]
		A_TrayMenu.Add("Enable Snapping", this.snappingToggle)
		A_TrayMenu.ToggleCheck("Enable Snapping")
		this.monitors := Map()
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
		if ((this.winInBlacklist(wHandle) && !overrideBlacklist) || WinGetMinMax(wHandle) != 0)
			return this.sendKey(cleanHotkey)
		pos := this.WinGetPosEx(wHandle)
		curWindowPositions := this.getWindowRects(wHandle)
		print(curWindowPositions)
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
			DllCall("SetWindowPos", "UInt", wHandle, "UInt", 0, "Int", nx - pos.LB, "Int", ny - pos.TB, "Int", 0, "Int", 0, "Uint", 0x0005)
			DllCall("Sleep", "UInt", 5)
		}

		calculateMonitorSnapping() {
			monitor := this.monitorGetInfoFromWindow(wHandle)
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
			Loop(curWindowPositions.Length) {
				win := curWindowPositions[-A_Index] ; iterate backwards so that the prioritized snap is highest in z-order (and lowest in array)
				; check whether the windows are even near each other -> must vertically overlap to have horizontal snap
				if (this.isClamped(ny, win.y, win.y2) || this.isClamped(win.y, ny, ny + pos.h)) {
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
				if (this.isClamped(nx, win.x, win.x2) || this.isClamped(win.x, nx, nx + pos.w)) {
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
		if ((this.winInBlacklist(wHandle) && !overrideBlacklist) || WinGetMinMax(wHandle) != 0)
			return this.sendKey(cleanHotkey)
		pos := this.WinGetPosEx(wHandle)
		curWindowPositions := this.getWindowRects(wHandle)
		WinActivate(wHandle)
		resizeLeft := (mouseX1 < pos.x + pos.w / 2)
		resizeUp := (mouseY1 < pos.y + pos.h / 2)
		limits := this.getMinMaxResizeCoords(wHandle)
		while GetKeyState(cleanHotkey, "P") {
			MouseGetPos(&mouseX2, &mouseY2)
			diffX := mouseX2 - mouseX1
			diffY := mouseY2 - mouseY1
			nx := pos.x
			ny := pos.y
			if resizeLeft
				nx += this.clamp(diffX, pos.w - limits.maxW, pos.w - limits.minW)
			if resizeUp
				ny += this.clamp(diffY, pos.h - limits.maxH, pos.h - limits.minH)
			nw := this.clamp(resizeLeft ? pos.w - diffX : pos.w + diffX, limits.minW, limits.maxW)
			nh := this.clamp(resizeUp ? pos.h - diffY : pos.h + diffY, limits.minH, limits.maxH)
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
			monitor := this.monitorGetInfoFromWindow(wHandle)
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
			Loop(curWindowPositions.Length) {
				win := curWindowPositions[-A_Index]
				if (this.isClamped(ny, win.y, win.y2) || this.isClamped(win.y, ny, ny + nh)) {
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
				if (this.isClamped(nx, win.x, win.x2) || this.isClamped(win.x, nx, nx + nw)) {
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
		if ((this.winInBlacklist(wHandle) && !overrideBlacklist) || mmx != 0) {
			return this.sendKey(cleanHotkey)
		}
		WinGetPos(&winX, &winY, &winW, &winH, wHandle)
		monitor := this.monitorGetInfoFromWindow(wHandle)
		xChange := floor((monitor.wRight - monitor.wLeft) * (scale_factor - 1))
		yChange := floor(winH * xChange / winW)
		wLimit := this.getMinMaxResizeCoords(wHandle)
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
		else {
			if (this.isBorderlessFullscreen(wHandle))
				this.resetWindowPosition(wHandle, 5/7)
			else
				WinMaximize(wHandle)
		}
	}

	static borderlessFullscreenWindow(wHandle := WinExist("A"), overrideBlacklist := false) {
		if (this.winInBlacklist(wHandle) && !overrideBlacklist)
			return
		if (WinGetMinMax(wHandle))
			WinRestore(wHandle)
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

	/**
	 * Restores and moves the specified window in the middle of the primary monitor
	 * @param wHandle Numeric Window Handle, uses active window by default
	 * @param sizePercentage The percentage of the total monitor size that the window will occupy
	 */
	static resetWindowPosition(wHandle := Winexist("A"), sizePercentage := 5/7) {
		monitor := this.monitorGetInfoFromWindow(wHandle)
		WinRestore(wHandle)
		mWidth := monitor.right - monitor.left, mHeight := monitor.bot - monitor.top
		WinMove(
			monitor.left + mWidth / 2 * (1 - sizePercentage), ; left edge of screen + half the width of it - half the width of the window, to center it.
			monitor.top + mHeight / 2 * (1 - sizePercentage),  ; same as above but with top bottom
			mWidth * sizePercentage,
			mHeight * sizePercentage,
			wHandle
		)
	}

	static getWindowRects(exceptForwHandle) {
		curWindowPositions := []
		for i, wHandle in WinGetList() {
			if WinGetMinMax(wHandle) != 0 || this.winInBlacklist(wHandle) || wHandle == exceptForwHandle
				continue
			v := this.WinGetPosEx(wHandle)
			v.title := WinGetTitle(wHandle)
			v.hwnd := wHandle
			v.x2 := v.x + v.w
			v.y2 := v.y + v.h
			curWindowPositions.push(v)
		}
		return curWindowPositions
	}

	static winInBlacklist(wHandle) {
		for e in this.blacklist
			if ((e != "" && WinExist(e " ahk_id " wHandle)) || (e == "" && WinGetTitle(wHandle) == ""))
				return 1
		return 0
	}

	static monitorGetInfoFromWindow(wHandle, cache := true) {
		monitorHandle := DllCall("MonitorFromWindow", "Ptr", wHandle, "UInt", 0x2, "Ptr")
		if cache {
			if !this.monitors.Has(monitorHandle) 
				this.monitors[monitorHandle] := this.monitorGetInfo(monitorHandle)
			return this.monitors[monitorHandle]
		}
		return this.monitorGetInfo(monitorHandle)
	}

	static monitorGetInfo(monitorHandle) {
		NumPut("Uint", 40, monitorInfo := Buffer(40))
		DllCall("GetMonitorInfo", "Ptr", monitorHandle, "Ptr", monitorInfo)
		return {
			left:		NumGet(monitorInfo, 4, "Int"),
			top:		NumGet(monitorInfo, 8, "Int"),
			right:		NumGet(monitorInfo, 12, "Int"),
			bottom:		NumGet(monitorInfo, 16, "Int"),
			wLeft:		NumGet(monitorInfo, 20, "Int"),
			wTop:		NumGet(monitorInfo, 24, "Int"),
			wRight:		NumGet(monitorInfo, 28, "Int"),
			wBottom:	NumGet(monitorInfo, 32, "Int"),
			flag:		NumGet(monitorInfo, 36, "UInt") ; flag can be MONITORINFOF_PRIMARY or not
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
		AltDrag.snapToMonitorEdges := !AltDrag.snapToMonitorEdges
		AltDrag.snapToWindowEdges := !AltDrag.snapToWindowEdges
		A_TrayMenu.ToggleCheck("Enable Snapping")
	}

	static clamp(n, minimum, maximum) => Max(minimum, Min(n, maximum))
	static isClamped(n, minimum, maximum) => (n <= maximum && n >= minimum)

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