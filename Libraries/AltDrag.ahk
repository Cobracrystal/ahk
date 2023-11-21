;// Recommended Hotkeys:
;// Alt + Left Button	: Drag to move a window.
;// Alt + Right Button	: Drag to resize a window.
;// Alt + Middle Button	: Toggle Max/Restore state of a window.

blacklist := ["ahk_class MultitaskingViewFrame ahk_exe explorer.exe"
			, "ahk_class Windows.UI.Core.CoreWindow"
			, "ahk_class WorkerW ahk_exe explorer.exe"
			, "ahk_class Shell_SecondaryTrayWindow ahk_exe explorer.exe"
			, "ahk_class Shell_TrayWindow ahk_exe explorer.exe"]

;// add program to blacklist by adding any window title criteria for it in the array, separated by commas
Menu, Tray, Add, Enable Snapping, snappingToggle
Menu, Tray, ToggleCheck, Enable Snapping
Menu, Tray, NoStandard
Menu, Tray, Standard
;// Programmumschaltung ahk_class MultitaskingViewFrame



moveWindow(hotkey := "LButton") {
	global disableSnapping
	SetWinDelay, 2
	CoordMode, Mouse, Screen
	hotkey := RegexReplace(hotkey, "#|!|\^|\+|<|>|\$|~", "")
	MouseGetPos, mouseX1, mouseY1, winID
	;// abort if maximized/minimized or blacklist
	if (windowBlacklistedOrMaximized(winID))
		sendKey(hotkey)
	else {
		WinGetPos, winX1, winY1,winW,winH,ahk_id %winID%
		WinActivate, ahk_id %winID%
		if (!disableSnapping)
			VarSetCapacity(monitorInfo, 40), NumPut(40, monitorInfo)
		Loop {
			;// get physical state of hotkey, break if released
			if (!GetKeyState(hotkey, "P"))
				break
			;// calculate offset and move window by initial win pos + offset of mouse
			MouseGetPos, mouseX2, mouseY2
			nx := winX1 + mouseX2 - mouseX1
			ny := winY1 + mouseY2 - mouseY1
			;// if snapping is enabled, replace coordinates with snapped ones.
			if (!disableSnapping) {
				crtmonitorhandle := DllCall("MonitorFromWindow", "Ptr", winID, "UInt", 0x2)
				if (crtmonitorhandle != monitorHandle) {
					monitorHandle := crtmonitorHandle
					DllCall("GetMonitorInfo", "Ptr", monitorHandle, "Ptr", &monitorInfo)
					workLeft	:= NumGet(monitorInfo, 20, "Int") ; Left
					workTop		:= NumGet(monitorInfo, 24, "Int") ; Top
					workRight	:= NumGet(monitorInfo, 28, "Int") ; Right
					workBottom	:= NumGet(monitorInfo, 32, "Int") ; Bottom
				}
				r := calculateSnapping(nx,ny,winW,winH,workLeft,workTop,workRight,workBottom,30,7)	;// adjust snapping options here, last two variables are radius of snapping and correction error for windows.
				nx := r[1]
				ny := r[2]
			}
			WinMove, ahk_id %winID%,, nx, ny
		}
	}
}

snappingToggle() {
	global disableSnapping
	disableSnapping := !disableSnapping
	Menu, Tray, ToggleCheck, Enable Snapping
}

calculateSnapping(x,y,w,h,workLeft,workTop,workRight,workBottom,radius,edgeWidthPixels) {
	if (abs(x-workLeft) < radius)
		x := workLeft-edgeWidthPixels		;// snap to left edge of screen + adjustment of window Client area to actual window
	else if (abs(x+w-workRight) < radius)
		x := workRight-w+edgeWidthPixels 	;// snap to right edge of screen
	if (abs(y-workTop) < radius)
		y := workTop						;// snap to top edge of screen
	else if (abs(y+h-workBottom) < radius)
		y := workBottom-h+edgeWidthPixels	;// snap to bottom edge of screen
	; MsgBox, % x . ", " . y
	return [x,y]
}

resizeWindow(hotkey := "RButton") {
	SetWinDelay, 2
	CoordMode, Mouse, Screen
	hotkey := RegexReplace(hotkey, "#|!|\^|\+|<|>|\$|~", "")
	;// abort if max/min or on blacklist
	MouseGetPos, mouseX1, mouseY1, winID
	if (windowBlacklistedOrMaximized(winID))
		sendKey(hotkey)
	else {
		WinGetPos, winX, winY, winW, winH, ahk_id %winID%
		WinActivate, ahk_id %winID%
		;// resize from left or right
		if (mouseX1 < winX + winW/2)
			resizeLeft := 1
		else
			resizeLeft := -1
		;// resize from top or bottom
		if (mouseY1 < winY + winH/2)
			resizeUp := 1
		else
			resizeUp := -1
		Loop {
			if (!GetKeyState(hotkey, "P"))
				break
			MouseGetPos, mouseX2, mouseY2
			WinGetPos, winX, winY, winW, winH, ahk_id %winID%
			WinMove, ahk_id %winID%,, winX + (resizeLeft+1)/2 * (mouseX2 - mouseX1)
									, winY + (resizeUp+1)/2 * (mouseY2 - mouseY1)
									, winW - resizeLeft * (mouseX2 - mouseX1)
									, winH - resizeUp * (mouseY2 - mouseY1)
			mouseX1 := mouseX2
			mouseY1 := mouseY2
		}
	}
}


toggleMaxRestore() {
	MouseGetPos,,,win_id
    WinGet,win_mmx,MinMax,ahk_id %win_id%
	;// restore if max/minimized
    if (win_mmx)
        WinRestore,ahk_id %win_id%
    else
        WinMaximize,ahk_id %win_id%
}

windowBlacklistedOrMaximized(winID) {
	global blacklist
	WinGet, winmmx, MinMax, ahk_id %winID%
	if (winmmx)
		return 1
	for index, element in blacklist
		if WinExist(element . " ahk_id " . winID)
			return 1
	return 0
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