#InstallMouseHook
/*
;// Recommended Hotkeys:
;  Alt + Left Button	: Drag to move a window.
;  Alt + Right Button	: Drag to resize a window.
;  Alt + Middle Button	: Toggle Max/Restore state of a window.

;// Method to use when including this script:
; call with parameter A_ThisHotkey to easily check for holding down the corresponding key.
!LButton::
moveWindow(A_ThisHotkey)
return

!RButton::	; Resize Window 
resizeWindow(A_ThisHotkey)
return

!MButton::	; Toggle Max/Restore of clicked window
toggleMaxRestore()
return


*/
AltDrag.initialize()

class AltDrag {
	static boolSnapping
	static blacklist
	static monitors
	static minMaxSystem
	
	initialize(snap := true) {
		this.boolSnapping := snap
		this.monitors := []
		this.blacklist := ["ahk_class MultitaskingViewFrame ahk_exe explorer.exe"
			, "ahk_class Windows.UI.Core.CoreWindow"
			, "ahk_class WorkerW ahk_exe explorer.exe"
			, "ahk_class Shell_SecondaryTrayWnd ahk_exe explorer.exe"
			, "ahk_class Shell_TrayWnd ahk_exe explorer.exe"]
		tFunc := this.snappingToggle
		SysGet, vMinX, 34 ;SM_CXMINTRACK := 34
		SysGet, vMinY, 35 ;SM_CYMINTRACK := 35
		SysGet, vMaxX, 59 ;SM_CXMAXTRACK := 59
		SysGet, vMaxY, 60 ;SM_CYMAXTRACK := 60
		this.minMaxSystem := {"minX":vMinX,"minY":vMinY,"maxX":vMaxX,"maxY":vMaxY}
		Menu, Tray, Add, Enable Snapping, % tFunc
		Menu, Tray, ToggleCheck, Enable Snapping
		Menu, Tray, NoStandard
		Menu, Tray, Standard
	}
	
	moveWindow(hotkey := "LButton") {
		SetWinDelay, 3
		CoordMode, Mouse, Screen
		cleanHotkey := RegexReplace(hotkey, "#|!|\^|\+|<|>|\$|~", "")
		MouseGetPos, mouseX1, mouseY1, winID
		;// abort if maximized/minimized or blacklist
		if (this.winInBlacklist(winID) || this.winIsMinmax(winID)) {
			this.sendKey(cleanHotkey)
			return
		}
		WinGetPos, winX1, winY1,winW,winH, % "ahk_id " . winID
		WinActivate, % "ahk_id " . winID
		if (this.boolSnapping)
			VarSetCapacity(monitorInfo, 40), NumPut(40, monitorInfo)
		while GetKeyState(cleanHotkey, "P") {
			MouseGetPos, mouseX2, mouseY2
			nx := winX1 + mouseX2 - mouseX1
			ny := winY1 + mouseY2 - mouseY1
			if (this.boolSnapping) {
				crtmonitorhandle := DllCall("MonitorFromWindow", "Ptr", winID, "UInt", 0x2)
				if (crtmonitorhandle != mHandle) {
					mHandle := crtmonitorHandle
					if (!this.monitors[mHandle]) {
						DllCall("GetMonitorInfo", "Ptr", mHandle, "Ptr", &monitorInfo)
						this.monitors[mHandle] := { "left":NumGet(monitorInfo, 20, "Int") ,"top":NumGet(monitorInfo, 24, "Int")
														,"right":NumGet(monitorInfo, 28, "Int")	,"bottom":NumGet(monitorInfo, 32, "Int") }
					}
				}
				; adjust snapping options here
				; last two variables are radius of snapping and correction error for windows.
				; ~> 30 pixels from edge of screen, it snaps to it, and it adjusts its position by 7 pixels
				; adjusting position is necessary since windows desktop/visual display of window
				; is slightly larger than what it should be.
				this.calculateSnapping(nx,ny,winW,winH,mHandle,30,7)
			}
			DllCall("SetWindowPos","UInt",winID,"UInt",0,"Int",nx,"Int", ny, "Int", 0, "Int", 0,"Uint",0x0005)
			DllCall("Sleep","UInt",5)
		}
	}
	
	resizeWindow(hotkey := "RButton") {
		SetWinDelay, -1
		CoordMode, Mouse, Screen
		cleanHotkey := RegexReplace(hotkey, "#|!|\^|\+|<|>|\$|~", "")
		;// abort if max/min or on blacklist
		MouseGetPos, mouseX1, mouseY1, winID
		if (this.winInBlacklist(winID) || this.winIsMinmax(winID)) {
			this.sendKey(cleanHotkey)
			return
		}
		WinGetPos, winX, winY, winW, winH, % "ahk_id " . winID
		WinActivate, % "ahk_id " . winID
		; direction from which direction to resize
		resizeLeft := (mouseX1 < winX + winW/2)
		resizeUp := (mouseY1 < winY + winH/2)
	;	VarSetCapacity(windowInfo, 16)
		while GetKeyState(cleanHotkey, "P") {
			MouseGetPos, mouseX2, mouseY2
			wLimit := this.winMinMaxSize(winID)
			diffX := mouseX2 - mouseX1
			diffY := mouseY2 - mouseY1
			nx := (resizeLeft ? winX + Max(Min(diffX, winW-wLimit.minX),winW-wLimit.maxX) : winX)
			ny := (resizeUp ? winY + Max(Min(diffY, winH-wLimit.minY),winH-wLimit.maxY) : winY)
			nw := Min(Max((resizeLeft ? winW - diffX : winW + diffX), wLimit.minX), wLimit.MaxX)
			nh := Min(Max((resizeUp ? winH - diffY : winH + diffY), wLimit.minY), wLimit.MaxY)
		;	if (nw == wLimit.minX && nh == wLimit.minY)
		;		continue ; THIS CAUSES JUMPS (or stucks) BECAUSE IT DOESN'T UPDATE THE VERY LAST RESIZE IT NEEDS TO. CHECK PREVIOUS SIZE?
		;	tooltip % "x: " nx "`ny: " ny "`nw: " nw "`nh: " nh "`nlimX " wLimit.minX "`nlimY " wLimit.minY
			DllCall("SetWindowPos","UInt",winID,"UInt",0,"Int",nx,"Int", ny, "Int", nw, "Int", nh,"Uint",0x0004)
			DllCall("Sleep","UInt",5)
		}
	}
	
	scaleWindow(direction := 1, scale_factor := 1.05) {
		; scale factor NOT exponential, its dependant on monitor size
		SetWinDelay, -1
		CoordMode, Mouse, Screen
		winID := WinExist("A")
		WinGet, mmx, MinMax, % "ahk_id " . winID
		if (this.winInBlacklist(winID) || mmx == -1) {
			return
		}
		WinGetPos, winX, winY, winW, winH, % "ahk_id " . winID
		mHandle := DllCall("MonitorFromWindow", "Ptr", winID, "UInt", 0x2)
		if (!this.monitors[mHandle]) {
			VarSetCapacity(monitorInfo, 40), NumPut(40, monitorInfo)
			DllCall("GetMonitorInfo", "Ptr", mHandle, "Ptr", &monitorInfo)
			this.monitors[mHandle] := { "left":NumGet(monitorInfo, 20, "Int") ,"top":NumGet(monitorInfo, 24, "Int")
										,"right":NumGet(monitorInfo, 28, "Int")	,"bottom":NumGet(monitorInfo, 32, "Int") }
		}
		xChange := floor((this.monitors[mHandle].right - this.monitors[mHandle].left)/2 * (scale_factor-1))
		yChange := floor(winH * xChange/winW)
		wLimit := this.winMinMaxSize(winID)
		if (direction == 1) {
			nx := winX - xChange, ny := winY - yChange
			if ((nw := winW + 2 * xChange) >= wLimit.maxX || (nh := winH + 2*yChange) >= wLimit.maxY)
				return
		}
		else {
			nx := winX + xChange, ny := winY + yChange
			if ((nw := winW - 2 * xChange) <= wLimit.minX || (nh := winH - 2 * yChange) <= wLimit.minY)
				return
		}
	;	tooltip % "x: " nx "`ny: " ny "`nw: " nw "`nh: " nh "`nxCh: " xChange "`nyCh: " yChange "`nminX: " wLimit.minX "`nminY: " wLimit.minY "`nmaxX: " wLimit.maxX "`nmaxY: " wLimit.maxY
		DllCall("SetWindowPos","UInt",winID,"UInt",0,"Int",nx,"Int", ny, "Int", nw, "Int", nh,"Uint",0x0004)
	}
	
	minimizeWindow() {
		winID := WinExist("A")
		if (this.winInBlacklist(winID))
			return
		WinMinimize, % "ahk_id " . winID
	}
	
	calculateSnapping(byref x, byref y, w, h, mHandle, radius, edgeWidthPixels) {
		if (abs(x-this.monitors[mHandle].left) < radius)
			x := this.monitors[mHandle].left-edgeWidthPixels		;// snap to left edge of screen + adjustment of window Client area to actual window
		else if (abs(x+w-this.monitors[mHandle].right) < radius)
			x := this.monitors[mHandle].right-w+edgeWidthPixels 	;// snap to right edge of screen
		if (abs(y-this.monitors[mHandle].top) < radius)
			y := this.monitors[mHandle].top					;// snap to top edge of screen
		else if (abs(y+h-this.monitors[mHandle].bottom) < radius)
			y := this.monitors[mHandle].bottom-h+edgeWidthPixels	;// snap to bottom edge of screen
	}
	
	winInBlacklist(winID) {
		for i, e in this.blacklist
			if WinExist(e . " ahk_id " . winID)
				return 1
		return 0
	}
	
	winIsMinmax(winID) {
		WinGet, winmmx, MinMax, % "ahk_id " . winID
		return (winmmx ? 1 : 0)
	}
	
	winMinMaxSize(winID) {
		VarSetCapacity(MINMAXINFO, 40, 0)
		SendMessage, 0x24,, % &MINMAXINFO,, % "ahk_id " . winID ;WM_GETMINMAXINFO := 0x24
	;	TODO: CHECK IF WINDOW THAT SPECIFIES vMINX TO BE SMALLER THAN SYSTEM_MINX CAN ACTUALLY RESIZE SMALLER OR NOT. 
		vMinX := Max(NumGet(MINMAXINFO, 24, "Int"), this.minMaxSystem.minX)
		vMinY := Max(NumGet(MINMAXINFO, 28, "Int"), this.minMaxSystem.minY)
		vMaxX := (NumGet(MINMAXINFO, 32, "Int") == 0 ? this.minMaxSystem.MaxX : NumGet(MINMAXINFO, 32, "Int"))
		vMaxY := (NumGet(MINMAXINFO, 36, "Int") == 0 ? this.minMaxSystem.MaxY : NumGet(MINMAXINFO, 36, "Int"))
		return {"minX":vMinX,"minY":vMinY,"maxX":vMaxX,"maxY":vMaxY}
	}
	
	windowBlacklistedOrMaximized(winID) {
		WinGet, winmmx, MinMax, % "ahk_id " . winID
		if (winmmx)
			return 1
		for i, e in this.blacklist
			if WinExist(e . " ahk_id " . winID)
				return 1
		return 0
	}

	toggleMaxRestore() {
		MouseGetPos,,,win_id
		WinGet,win_mmx,MinMax,ahk_id %win_id%
		if (win_mmx)
			WinRestore, % "ahk_id " . win_id
		else
			WinMaximize, % "ahk_id " . win_id
	}
		
	snappingToggle() {
		this.boolSnapping := !this.boolSnapping
		Menu, Tray, ToggleCheck, Enable Snapping
	}

	sendKey(hotkey) {
		if (hotkey = "LButton" || hotkey = "RButton" || hotkey = "MButton") {
			hhL := SubStr(hotkey,1,1)
			Click, down, %hhL%
			Loop {
				if (!GetKeyState(hotkey, "P")) {
					Click, up, %hhL%
					return
				}
			}
		}
		else
			Send, {Blind}%hotkey%
		return
	}
}

