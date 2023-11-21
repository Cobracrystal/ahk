;//original function shamelessly stolen & modified from JNizM, https://github.com/jNizM/AHK_TaskBar_SetAttr/
;//script functionality from Cobracrystal
;------------------------- AUTO EXECUTE SECTION -------------------------
#Include %A_ScriptDir%\Libraries\BasicUtilities.ahk
#Include %A_ScriptDir%\Libraries\ColorUtilities.ahk

;// Settings for TaskBarTransparency. look at TaskBar_SetAttr for explanation
global taskbar_accent_color := "0xE0202020" ; the gray of the taskbar when turning off
global taskbar_maximized_color := "0xD0473739" ; color when window is maximized
global taskbar_maximized_mode := 2 ; mode when window is max
global taskbar_RGB_mode := false ; if max_mode is 1 / 2, this overwrites maximized_color

;// Adds Simple Timer Menu to display if Script is active or not
Menu, Timers, Add, Taskbar Transparency Timer, taskbarTranspManager
Menu, Tray, Add, Timers, :Timers
Menu, Tray, NoStandard
Menu, Tray, Standard
;------------------------------------------------------------------------

taskbarTranspManager(mode := 0, itemPosUNUSED := 0, menuNameUNUSED := 0, newPeriod := 200, debug := 0) {
	; mode = 0 (turn off), 1 (turn on), T[...] (toggle)
	static onOffStatus := 0
	if (SubStr(mode, 1, 1) == "T")
		mode := !onOffStatus
	if (mode == 1) {
		SetTimer, updateTaskbarTimer, % newPeriod
		Menu, Timers, Check, Taskbar Transparency Timer
		onOffStatus := 1
	}
	else if (mode == 0) {
		SetTimer, updateTaskbarTimer, Off
		updateTaskbarTimer(1, 1)
		Menu, Timers, Uncheck, Taskbar Transparency Timer
		onOffStatus := 0
	}
	else
		MsgBox % "Invalid mode specified for Transparency manager function."
	return
}

updateTaskbarTimer(reset := 0, logAll := 0) {
	static init, monitors, taskbarTransparency := [-1,-1] ; if(-1) == true -> initial coloring
	static s:=0, gradient, rgb_rotate_duration, gradientIndex := 0
	ListLines % logAll
	if !(init) {
		if (taskbar_RGB_mode) {
			rgb_rotate_duration := 8 ; this * period/25, in seconds on average
			color_intensity := 0x80
			r := color_intensity * 0x010000
			g := color_intensity * 0x000100
			b := color_intensity * 0x000001
			gradient := colorGradientArr(round(rgb_rotate_duration*63), r, r|g/2, r|g, g, g|b, g/2|b, b, b|r, r)
		}		
		monitors := getMonitors()
		init := 1
	}
	if (sessionIsLocked())
		return
	if (reset) {
		try {
			init := 0
			taskbarTransparency := [0,0]
			for i, e in monitors
				TaskBar_SetAttr(1, e.MonitorNumber, taskbar_accent_color)
		} catch e
			return
	}
	else try {
		maximizedMonitors := getMaximizedMonitors(monitors)
		s := !s ; rendering transp taskbar while locked out causes problems when same color is used
		for i, el in monitors {
			if (arrayContains(maximizedMonitors, el.MonitorNumber)) {
				if (taskbar_RGB_mode) {
					tColor := changeColorFormat(gradient[gradientIndex+1], true, "0xD0")
					gradientIndex := mod(gradientIndex + 1, round(rgb_rotate_duration*63))
					TaskBar_SetAttr(taskbar_maximized_mode, el.MonitorNumber, tColor)
					taskbarTransparency[el.MonitorNumber] := 0
				}
				else if (taskbarTransparency[el.MonitorNumber]) {
					TaskBar_SetAttr(taskbar_maximized_mode, el.MonitorNumber, taskbar_maximized_color)
					taskbarTransparency[el.MonitorNumber] := 0
				}
			}
			else {
				TaskBar_SetAttr(2, el.MonitorNumber, "0x0100000" . s)
				taskbarTransparency[el.MonitorNumber] := 1
			}
		}
	} catch e {
		ListLines On
		MsgBox % "Error: " e.Message " in " e.What "`nTaskbar Transparency has been turned off."
		taskbarTranspManager(0)
	}
}

getMonitors() {
	monitors := []
	SysGet, MonitorCount, MonitorCount
	Loop, %MonitorCount%
	{
		SysGet, Monitor, Monitor, %A_Index%
		monitors.push({"MonitorNumber":A_Index, "Left":MonitorLeft, "Right":MonitorRight, "Top":MonitorTop, "Bottom":MonitorBottom})
	}
	return monitors
}

getMaximizedMonitors(monitors) {
	SetTitleMatchMode, RegEx
	WinGet, id, List,,, (Program Manager|NVIDIA GeForce Overlay|^$)
	maximizedMonitors := []
	Loop, %id%
	{
		this_id := id%A_Index%
		WinGet, mmx, MinMax, ahk_id %this_id%
		if (mmx = 1) {
			maximizedMonitor := get_window_monitor_number(this_id, monitors)
			maximizedMonitors.push(maximizedMonitor)
		}
	}
	return maximizedMonitors
}

get_window_monitor_number(window_id, monitors) {
	WinGetPos, xpos, ypos, width, height, ahk_id %window_id%
	winMiddleX := xpos + width/2
	for i, e in monitors {
		if (winMiddleX > e.Left && winMiddleX < e.Right)
			return e.MonitorNumber
	}
}

TaskBar_SetAttr(accent_state := 0, monitor := -1, gradient_color := "0x01000000") { ; 
;// 0 = off, 1 = gradient (+color), 2 = transparent (+color), 3 = blur; color -> ABGR (alpha | blue | green | red) all hex: 0xffd7a78f
    static init, monitorPrimary, hTrayWnd, hTrayWnd2, hStartWnd
    static pad := A_PtrSize = 8 ? 4 : 0, WCA_ACCENT_POLICY := 19
    if !(init) {
        if !(hTrayWnd := DllCall("user32\FindWindow", "str", "Shell_TrayWnd", "ptr", 0, "ptr"))
			throw Exception("Failed to get the handle", -1)
		if !(hTrayWnd2 := DllCall("user32\FindWindow", "str", "Shell_SecondaryTrayWnd", "ptr", 0, "ptr"))
			throw Exception("Failed to get the handle", -1)
		SysGet, monitorPrimary, MonitorPrimary
        init := 1
    }
	if (monitor == -1)
		throw Exception("Attempted to set transparency on monitor that doesn't exist.",-1)
    accent_size := VarSetCapacity(ACCENT_POLICY, 16, 0)
    NumPut((accent_state > 0 && accent_state < 4) ? accent_state : 0, ACCENT_POLICY, 0, "int")

    if (accent_state >= 1) && (accent_state <= 2) && (RegExMatch(gradient_color, "0x[[:xdigit:]]{8}"))
        NumPut(gradient_color, ACCENT_POLICY, 8, "int")

    VarSetCapacity(WINCOMPATTRDATA, 4 + pad + A_PtrSize + 4 + pad, 0)
    && NumPut(WCA_ACCENT_POLICY, WINCOMPATTRDATA, 0, "int")
    && NumPut(&ACCENT_POLICY, WINCOMPATTRDATA, 4 + pad, "ptr")
    && NumPut(accent_size, WINCOMPATTRDATA, 4 + pad + A_PtrSize, "uint")
    if (monitor = MonitorPrimary) {
		if !(DllCall("user32\SetWindowCompositionAttribute", "ptr", hTrayWnd, "ptr", &WINCOMPATTRDATA)) {
			init := 0
			throw Exception("Failed to set transparency / blur", -1)
		}
	}
	else if !(DllCall("user32\SetWindowCompositionAttribute", "ptr", hTrayWnd2, "ptr", &WINCOMPATTRDATA)){
		init := 0
		throw Exception("Failed to set transparency / blur", -1)
	}
	return true
}

sessionIsLocked() {
	static WTS_CURRENT_SERVER_HANDLE := 0, WTSSessionInfoEx := 25, WTS_SESSIONSTATE_LOCK := 0x00000000, WTS_SESSIONSTATE_UNLOCK := 0x00000001 ;, WTS_SESSIONSTATE_UNKNOWN := 0xFFFFFFFF
	ret := false
	if (DllCall("ProcessIdToSessionId", "UInt", DllCall("GetCurrentProcessId", "UInt"), "UInt*", sessionId) && DllCall("wtsapi32\WTSQuerySessionInformation", "Ptr", WTS_CURRENT_SERVER_HANDLE, "UInt", sessionId, "UInt", WTSSessionInfoEx, "Ptr*", sesInfo, "Ptr*", BytesReturned)) {
		SessionFlags := NumGet(sesInfo+0, 16, "Int")
		; "Windows Server 2008 R2 and Windows 7: Due to a code defect, the usage of the WTS_SESSIONSTATE_LOCK and WTS_SESSIONSTATE_UNLOCK flags is reversed."
		ret := SessionFlags == WTS_SESSIONSTATE_LOCK
		DllCall("wtsapi32\WTSFreeMemory", "Ptr", sesInfo)
	}

	return ret
}
