#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Include %A_ScriptDir%\Libraries\WinHook.ahk
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
registerTransparentTaskbar()
return

^k::
msgbox % flushtext
return

; tldr use this : https://www.autohotkey.com/boards/viewtopic.php?t=59149

; FAILURE: 	a) oneventhook currently doesn't work at all. 
; 			b) can't detect maximize -> restore and vice versa despite resizing eventhooks.
				; possible solution: https://stackoverflow.com/questions/1295999/event-when-a-window-gets-maximized-un-maximized
				; winspector spy? how do i utilize wm_syscommand and sc_maximize

; possible todo: delete closed windows from winArray.
registerTransparentTaskbar() {
	; shellhookstuff
	WinHook.Shell.Add("onWindowHookEvent",,,,1) ; Window Created
	WinHook.Shell.Add("onWindowHookEvent",,,,2) ; Window Destroyed

	onWindowHook(,,1)
}

onWindowHookEvent(winHWND, winTitle, winClass, winExe, winEvent) {
	if (winEvent == 1) {
		WinGet, vPID, PID, ahk_id %winHWND%
		EH1 := WinHook.Event.Add(0x0016, 0x0016, "onEventHookEvent", vPID)
		EH2 := WinHook.Event.Add(0x0017, 0x0017, "onEventHookEvent", vPID)
		EH4 := WinHook.Event.Add(0x000B, 0x000B, "onEventHookEvent", vPID)
	}
	onWindowHook(winHWND, winEvent)
}

onEventHookEvent(hWinEventHook, event, hwnd, idOBject, idChild, dwEventThread, dwmsEventTime) {
	onWindowHook(hwnd, event)
}

onWindowHook(winID := "?", event := 0, startStopContinue := -1) {
	global flushtext
	static init
	static windowArray
	static monitors
	static operate
	flushtext .= winID . ", " . event . " `n" 
	if (startStopContinue != -1)
		operate := startStopContinue
	if !(init) {
		monitors := getMonitors()
		windowArray := getWindowArray(monitors)
		for i, e in monitors
		{
			if !(searchForMaximizedWindows(windowArray, i)) {
				mainfunc(1, i)
				monitors[A_Index]["TransparentTaskbar"] := 1
			}
		}
		init := 1
		operate := 1
		return
	}
	if !(operate)
		return
	if (winID == "?")
		return
	; get window stats (mmx & monitor number)
	WinGet, mmx, MinMax, ahk_id winID
	if (mmx != -1 && event != 2)
		monitorNumber := get_window_monitor_number(winID, monitors)
	; test 
	if (mmx == 1 && monitors[monitorNumber]["TransparentTaskbar"] == 1) ; window is maximized, taskbar is transparent -> switch
		mainfunc(0, monitorNumber)
	else if (mmx != 1 && windowArray[winID]) { ; window is not maximized and existed before 
		if !(monitorNumber)
			monitorNumber := windowArray[winID] ; get monitor number based on fact that it existed before if we don't have one
		if (windowArray[winID]["mmx"] == 1 && monitors[monitorNumber]["TransparentTaskbar"] == 0) { ; is the taskbar opaque and was the window maximized before?
			if !(searchForMaximizedWindows(windowArray, windowArray[winID]["monitor"])) { ; does the monitor contain another maximized window?
				; there are no maximized windows on this monitor
				mainfunc(1, monitorNumber)
			}
		}
	}
	entry := {"monitor":monitorNumber, "mmx":mmx} ; monitorNumber is only a number if mmx=1
	windowArray[winID] := entry
}

getWindowArray(monitors) {
	SetTitleMatchMode, RegEx
	WinGet, id, List,,, (Program Manager|NVIDIA GeForce Overlay|^$)
	windowArray := {}
	Loop, %id%
	{
		this_id := id%A_Index%
		WinGet, mmx, MinMax, ahk_id %this_id%
		WinGet, vPID, PID, ahk_id %this_id%
		if (mmx != -1)
			monitorNumber := get_window_monitor_number(this_id, monitors)
		t := {"mmx":mmx, "monitor":monitorNumber}
		EH1 := WinHook.Event.Add(0x0016, 0x0016, "onEventHookEvent", vPID)
		EH2 := WinHook.Event.Add(0x0017, 0x0017, "onEventHookEvent", vPID)
		EH4 := WinHook.Event.Add(0x000B, 0x000B, "onEventHookEvent", vPID)
		windowArray[this_id] := t
	}
	SetTitleMatchMode, 3
	return windowArray
}

getMonitors() {
	monitors := []
	SysGet, MonitorCount, MonitorCount
	Loop, %MonitorCount%
	{
		SysGet, Monitor, Monitor, %A_Index%
		monitors[A_Index] := {"MonitorNumber":A_Index, "Left":MonitorLeft, "Right":MonitorRight, "Top":MonitorTop, "Bottom":MonitorBottom, "TransparentTaskbar":0}
	}
	return monitors
}

get_window_monitor_number(window_id, monitors) {
	WinGetPos, xpos, ypos, width, height, ahk_id %window_id%
	winMiddleX := xpos + width/2
	for i, e in monitors
		if (winMiddleX > e.Left && winMiddleX < e.Right)
			return e.MonitorNumber
}

searchForMaximizedWindows(winArr, monN) {
	for i, e in winArr 
	{
		if (e.mmx == 1 && e.monitor == monN)
			return 1
	}
	return 0
}

mainfunc(transp, monitorNumber) {
	msgbox % "Transparency on Monitor " . monitorNumber . " is now " . transp
}

^+r::
reload
return