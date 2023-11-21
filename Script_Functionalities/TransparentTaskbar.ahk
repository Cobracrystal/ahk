;//original function shamelessly stolen & modified from JNizM, https://github.com/jNizM/AHK_TaskBar_SetAttr/
;//script functionality from Cobracrystal
;------------------------- AUTO EXECUTE SECTION -------------------------
;// Settings for TaskBarTransparency. look at TaskBar_SetAttr for explanation
global accent_color = 0xD0473739 ; This is literally just gray
global passive_mode := 2

;// Adds Simple Timer Menu to display if Script is active or not
Menu, Timers, Add, Taskbar Transparency Timer: Off, doNothing
Menu, Timers, Disable, 1&
Menu, Tray, Add, Timers, :Timers
Menu, Tray, NoStandard
Menu, Tray, Standard
;------------------------------------------------------------------------

updateTaskbarFunction(reset := 0, logAll := 0) {
	static init, timer, monitors, taskbarTransparency := [1,1]
	if !(init) {
		monitors := getMonitors()
		init := 1
	}
	if !(timer) {
		Menu, Timers, Rename, Taskbar Transparency Timer: Off, Taskbar Transparency Timer: On
		Menu, Timers, Check, Taskbar Transparency Timer: On
		timer := 1
	}
	try {
		if (reset) {
			taskbarTransparency := [0,0]
			Menu, Timers, Rename, Taskbar Transparency Timer: On, Taskbar Transparency Timer: Off
			Menu, Timers, Uncheck, Taskbar Transparency Timer: Off
			timer := 0
			for Index, Element in monitors
				TaskBar_SetAttr(2, Element.MonitorNumber, 0xD0473739)
		}
		else {
			if !(logAll)
				ListLines Off
			maximizedMonitors := test_maximized_window(monitors)
			for Index, Element in monitors {
				if (arrayContains(maximizedMonitors, Element.MonitorNumber)) {
					if (taskbarTransparency[Element.MonitorNumber]) {
						TaskBar_SetAttr(passive_mode, Element.MonitorNumber, accent_color)
						taskbarTransparency[Element.MonitorNumber] := 0
					}
				}
				else {
					TaskBar_SetAttr(2, Element.MonitorNumber)
					taskbarTransparency[Element.MonitorNumber] := 1
				}	
			}
			if !(log)
				ListLines On
				
		}
	} catch e {
		MsgBox % "Error: " e.Message "in " e.What
	}
}

getMonitors() {
	global MonitorPrimary
	SysGet, MonitorPrimary, MonitorPrimary
	monitors := []
	SysGet, MonitorCount, MonitorCount
	Loop, %MonitorCount%
	{
		SysGet, Monitor, Monitor, %A_Index%
		monitors.push({"MonitorNumber":A_Index, "Left":MonitorLeft, "Right":MonitorRight, "Top":MonitorTop, "Bottom":MonitorBottom})
	}
	return monitors
}

test_maximized_window(ByRef monitors) {
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
	SetTitleMatchMode, 3
	return maximizedMonitors
}

get_window_monitor_number(window_id, ByRef monitors) {
	WinGetPos, xpos, ypos, width, height, ahk_id %window_id%
	winMiddleX := xpos + width/2
	for Index, Element in monitors {
		if (winMiddleX > Element.Left && winMiddleX < Element.Right)
			return Element.MonitorNumber
	}
}

TaskBar_SetAttr(accent_state := 0, monitor := -1, gradient_color := "0x01000000") { ; 
;// 0 = off, 1 = gradient (+color), 2 = transparent (+color), 3 = blur; color -> ABGR (alpha | blue | green | red) all hex: 0xffd7a78f
    static init, hTrayWnd, hTrayWnd2, ver := DllCall("GetVersion") & 0xff < 10
    static pad := A_PtrSize = 8 ? 4 : 0, WCA_ACCENT_POLICY := 19
	global MonitorPrimary
    if !(init) {
        if (ver)
            throw Exception("Minimum support client: Windows 10", -1)
        if !(hTrayWnd := DllCall("user32\FindWindow", "str", "Shell_TrayWnd", "ptr", 0, "ptr"))
			throw Exception("Failed to get the handle", -1)
		if !(hTrayWnd2 := DllCall("user32\FindWindow", "str", "Shell_SecondaryTrayWnd", "ptr", 0, "ptr"))
			throw Exception("Failed to get the handle", -1)
        init := 1
    }

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

arrayContains(array, searchfor) {
	for Index, Element in array {
		if(Element = searchfor) {
			return 1
			break
		}
	}
	return 0
}

doNothing() {
	return
}