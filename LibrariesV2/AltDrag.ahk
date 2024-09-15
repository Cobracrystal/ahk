; https://github.com/cobracrystal/ahk
/*
;---'Traditional' Hotkeys:
;  Alt + Left Button	: Drag to move a window.
;  Alt + Right Button	: Drag to resize a window.
;  Alt + Middle Button	: Click to switch Max/Restore state of a window.
;--- & Semi-Traditional
;  Alt + Middle Button	: Scroll to scale a window.
;  Alt + X4 Button		: Click to minimize a window.

; Drag Window
!LButton::{
	AltDrag.moveWindow(A_ThisHotkey)
}

; Resize Window
!RButton::{
	AltDrag.resizeWindow(A_ThisHotkey)
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
*/

class AltDrag {

	static __New() {
		InstallMouseHook()
		this.boolSnapping := true
		this.monitors := Map()
		this.blacklist := [
			"ahk_class MultitaskingViewFrame ahk_exe explorer.exe",
			"ahk_class Windows.UI.Core.CoreWindow",
			"ahk_class WorkerW ahk_exe explorer.exe",
			"ahk_class Shell_SecondaryTrayWnd ahk_exe explorer.exe",
			"ahk_class Shell_TrayWnd ahk_exe explorer.exe"
		]
		this.minMaxSystem := { minX: SysGet(34), minY: SysGet(35), maxX: SysGet(59), maxY: SysGet(60) }
		A_TrayMenu.Add("Enable Snapping", this.snappingToggle)
		A_TrayMenu.ToggleCheck("Enable Snapping")
	}

	static addBlacklist(arr) {
		if arr is Array
			for i, e in arr
				this.blacklist.Push(e)
		else
			this.blacklist.Push(arr)
	}

	static moveWindow(hotkey := "LButton") {
		SetWinDelay(3)
		CoordMode("Mouse", "Screen")
		cleanHotkey := RegexReplace(hotkey, "#|!|\^|\+|<|>|\$|~", "")
		MouseGetPos(&mouseX1, &mouseY1, &winID)
		; abort if maximized/minimized or blacklist
		if (this.winInBlacklist(winID) || WinGetMinMax(winID) != 0) {
			this.sendKey(cleanHotkey)
			return
		}
		WinGetPos(&winX1, &winY1, &winW, &winH, "ahk_id " . winID)
		WinActivate("ahk_id " . winID)
		while (GetKeyState(cleanHotkey, "P")) {
			MouseGetPos(&mouseX2, &mouseY2)
			nx := winX1 + mouseX2 - mouseX1
			ny := winY1 + mouseY2 - mouseY1
			if (this.boolSnapping) {
				mHandle := DllCall("MonitorFromWindow", "Ptr", winID, "UInt", 0x2, "Ptr")
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
				this.calculateSnapping(&nx, &ny, winW, winH, mHandle, 30, 7)
			}
			DllCall("SetWindowPos", "UInt", winID, "UInt", 0, "Int", nx, "Int", ny, "Int", 0, "Int", 0, "Uint", 0x0005)
			DllCall("Sleep", "UInt", 5)
		}
	}

	static resizeWindow(hotkey := "RButton") {
		SetWinDelay(-1)
		CoordMode("Mouse", "Screen")
		cleanHotkey := RegexReplace(hotkey, "#|!|\^|\+|<|>|\$|~", "")
		; abort if max/min or on blacklist
		MouseGetPos(&mouseX1, &mouseY1, &wHandle)
		if (this.winInBlacklist(wHandle) || WinGetMinMax(wHandle) != 0) {
			this.sendKey(cleanHotkey)
			return
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

	static scaleWindow(direction := 1, scale_factor := 1.05) {
		; scale factor NOT exponential, its dependant on monitor size
		cleanHotkey := "{Middle Up}"
		SetWinDelay(-1)
		CoordMode("Mouse", "Screen")
		wHandle := WinExist("A")
		mmx := WinGetMinMax("ahk_id " . wHandle)
		if (this.winInBlacklist(wHandle) || mmx != 0) {
			return
		}
		WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " . wHandle)
		mHandle := DllCall("MonitorFromWindow", "Ptr", wHandle, "UInt", 0x2, "Ptr")
		if (!this.monitors.Has(mHandle)) {
			NumPut("Uint", 40, mI := Buffer(40))
			DllCall("GetMonitorInfo", "Ptr", mHandle, "Ptr", mI)
			this.monitors[mHandle] := { left: NumGet(mI, 20, "Int"), top: NumGet(mI, 24, "Int"), right: NumGet(mI, 28, "Int"), bottom: NumGet(mI, 32, "Int") }
		}
		xChange := floor((this.monitors[mHandle].right - this.monitors[mHandle].left) / 2 * (scale_factor - 1))
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

	static minimizeWindow() {
		winID := WinExist("A")
		if (this.winInBlacklist(winID))
			return
		WinMinimize("ahk_id " . winID)
	}

	; * radius -> radius in pixels in which windows will snap to points
	; * edgeWidthPixels -> desktop and window size is slightly incorrect, shifting by ~7 pixels / window border is necessary
	static calculateSnapping(&x, &y, w, h, mHandle, radius, edgeWidthPixels) {
		if (abs(x - this.monitors[mHandle].left) < radius)
			x := this.monitors[mHandle].left - edgeWidthPixels		; snap to left edge of screen + adjustment of window Client area to actual window
		else if (abs(x + w - this.monitors[mHandle].right) < radius)
			x := this.monitors[mHandle].right - w + edgeWidthPixels 	; snap to right edge of screen
		if (abs(y - this.monitors[mHandle].top) < radius)
			y := this.monitors[mHandle].top					; snap to top edge of screen
		else if (abs(y + h - this.monitors[mHandle].bottom) < radius)
			y := this.monitors[mHandle].bottom - h + edgeWidthPixels	; snap to bottom edge of screen
	}

	static winInBlacklist(winID) {
		for i, e in this.blacklist
			if WinExist(e . " ahk_id " . winID)
				return 1
		return 0
	}

	static winMinMaxSize(winID) {
		MINMAXINFO := Buffer(40, 0)
		SendMessage(0x24, , MINMAXINFO, , "ahk_id " . winID) ;WM_GETMINMAXINFO := 0x24
		vMinX := Max(NumGet(MINMAXINFO, 24, "Int"), this.minMaxSystem.minX)
		vMinY := Max(NumGet(MINMAXINFO, 28, "Int"), this.minMaxSystem.minY)
		vMaxX := (NumGet(MINMAXINFO, 32, "Int") == 0 ? this.minMaxSystem.MaxX : NumGet(MINMAXINFO, 32, "Int"))
		vMaxY := (NumGet(MINMAXINFO, 36, "Int") == 0 ? this.minMaxSystem.MaxY : NumGet(MINMAXINFO, 36, "Int"))
		return { minX: vMinX, minY: vMinY, maxX: vMaxX, maxY: vMaxY }
	}

	static windowBlacklistedOrMaximized(winID) {
		winmmx := WinGetMinMax("ahk_id " . winID)
		if (winmmx)
			return 1
		for i, e in this.blacklist
			if WinExist(e . " ahk_id " . winID)
				return 1
		return 0
	}

	static toggleMaxRestore() {
		MouseGetPos(, , &win_id)
		win_mmx := WinGetMinMax("ahk_id " win_id)
		if (win_mmx)
			WinRestore("ahk_id " . win_id)
		else
			WinMaximize("ahk_id " . win_id)
	}

	static snappingToggle(*) {
		AltDrag.boolSnapping := !AltDrag.boolSnapping
		A_TrayMenu.ToggleCheck("Enable Snapping")
	}

	static sendKey(hkey) {
		if (hkey = "LButton" || hkey = "RButton" || hkey = "MButton") {
			hhL := SubStr(hkey, 1, 1)
			Click("Down " . hhL)
			Hotkey("*" hkey " Up", this.sendClickUp.bind(this, hhL), "On")
			; while(GetKeyState(hkey, "P"))
			;	continue
			; Click("Up " hhL)
		}
		else
			Send("{Blind}" . hkey)
		return
	}

	static sendClickUp(hhL, hkey) {
		Click("Up " . hhL)
		Hotkey(hkey, "Off")
	}
}