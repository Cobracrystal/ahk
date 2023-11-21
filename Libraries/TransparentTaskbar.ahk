;//original function shamelessly stolen & modified from JNizM, https://github.com/jNizM/AHK_TaskBar_SetAttr/
;//script functionality from Cobracrystal
;------------------------- AUTO EXECUTE SECTION -------------------------
#Include %A_ScriptDir%\Libraries\BasicUtilities.ahk
#Include %A_ScriptDir%\Libraries\ColorUtilities.ahk


TransparentTaskbar.initialize()




; TODO: CHECK VLC MAX/ MIN MODE
; REPRODUCE: Start video in fullscreen, have song after it, it automatically resizes to song but mmx stays



class TransparentTaskbar {
	;// Settings for TaskBarTransparency. look at TaskBar_SetAttr for explanation
	; SET THESE VIA initialize(a,b,c,d,...) METHOD.
	static blacklist ; windows that do not cause change in taskbar despite maximizing (eg: desktop.)
	static logStatus ; whether or not this is logged in line overview. Default false
	static taskbar_accent_color ; the gray of the taskbar when turning off
	static taskbar_maximized_color ; color when window is maximized
	static taskbar_maximized_mode ; mode when window is max
	static taskbar_RGB_mode ; if max_mode is 1 / 2, this overwrites maximized_color
	static RGB_color_intensity ; if max_mode is 1 / 2, this overwrites maximized_color
	static RGB_rotate_duration ; this * period/25, in seconds on average
	; internal use only
	static onOffStatus := false, init := false, gradient, monitors, taskbarTransparency := [-1,-1], trayHandles := []
	
	transparentTaskbar(mode := 0, itemPosUNUSED := 0, menuNameUNUSED := 0, newPeriod := 200, debug := 0) {
		static timerObj
		if (!this.initialized)
			this.initialize()
		; mode = 0 (turn off), 1 (turn on), T[...] (toggle)
		if (!this.init) {
			this.initSoft()
		}
		if (SubStr(mode, 1, 1) == "T")
			mode := !this.onOffStatus
		if (mode == 1) {
			timerObj := this.updateTaskbarTimer.Bind(this)
			SetTimer, % timerObj, % newPeriod
			Menu, Timers, Check, Taskbar Transparency Timer
			this.onOffStatus := true
		}
		else if (mode == 0) {
			SetTimer, % timerObj, Off
			this.reset()
			Menu, Timers, Uncheck, Taskbar Transparency Timer
			this.onOffStatus := false
		}
		else
			MsgBox % "Invalid mode specified for Transparency manager function."
		return
	}

	initialize(tbAccentC := "0xE0202020", tbMaximC := "0xD0473739", tbMaximM := 2, tbRGBM := false, rbRGBI := "0x80", tbRGBrotD := 4, logStatus := 0, blacklist := "(Program Manager|NVIDIA GeForce Overlay|^$)") {
		tObj := this.transparentTaskbar.Bind(this)
		Menu, Timers, Add, Taskbar Transparency Timer, % tObj
		Menu, Tray, Add, Timers, :Timers
		Menu, Tray, NoStandard
		Menu, Tray, Standard
		
		this.blacklist := blacklist
		this.logStatus := logStatus
		this.taskbar_accent_color := tbAccentC ; the gray of the taskbar when turning off
		this.taskbar_maximized_color := tbMaximC ; color when window is maximized
		this.taskbar_maximized_mode := tbMaximM ; mode when window is max
		this.taskbar_RGB_mode := tbRGBM ; if max_mode is 1 / 2, this overwrites maximized_color
		this.RGB_color_intensity := rbRGBI ; if max_mode is 1 / 2, this overwrites maximized_color
		this.RGB_rotate_duration := tbRGBrotD ; this * period * 63 is duration per cycle on average, very inconsistently.
		if (this.taskbar_RGB_mode) {
			r := this.RGB_color_intensity * 0x010000
			g := this.RGB_color_intensity * 0x000100
			b := this.RGB_color_intensity * 0x000001
			this.gradient := colorGradientArr(round(this.RGB_rotate_duration*63), r, r|g/2, r|g, g, g|b, g/2|b, b, b|r, r)
		}
		this.initialized := true
	}
	
	initSoft() {
		this.monitors := this.getMonitors()
		try {
			Sysget, mP, MonitorPrimary
			WinGet, tHWND, ID, % "ahk_class Shell_TrayWnd"
			this.trayHandles[mP] := tHWND ; DllCall("user32\FindWindow", "str", "Shell_TrayWnd", "ptr", 0, "ptr")
			WinGet, hSecondaryTray, List, % "ahk_class Shell_SecondaryTrayWnd"
			Loop % hSecondaryTray
				this.trayHandles[this.get_window_monitor_number(hSecondaryTray%A_Index%)] := hSecondaryTray%A_Index%
		}
		this.init := true
	}
	
	reset() {
		this.init := false
		this.taskbarTransparency := [-1,-1]
		try for i, e in this.monitors
			this.TaskBar_SetAttr(1, e.MonitorNumber, this.taskbar_accent_color)
		catch e
			return
	}
	
	updateTaskbarTimer(override := false) {
		static index := 0, s := 0,
		ListLines % this.logStatus
		if (this.sessionIsLocked())
			return
		else try {
			maximizedMonitors := this.getMaximizedMonitors()
		;	s := !s ; rendering transp taskbar while locked out causes problems when same color is used
			for i, el in this.monitors {
				if (arrayContains(maximizedMonitors, el.MonitorNumber)) {
					if (this.taskbar_RGB_mode) {
						tColor := changeColorFormat(this.gradient[index+1], true, "0xD0")
						index := mod(index + 1, round(this.RGB_rotate_duration*63))
						this.TaskBar_SetAttr(this.taskbar_maximized_mode, el.MonitorNumber, tColor)
						this.taskbarTransparency[el.MonitorNumber] := 0
					}
					else if (this.taskbarTransparency[el.MonitorNumber]) {
						this.TaskBar_SetAttr(this.taskbar_maximized_mode, el.MonitorNumber, this.taskbar_maximized_color)
						this.taskbarTransparency[el.MonitorNumber] := 0
					}
					else if (override) {
						this.TaskBar_SetAttr(1, el.MonitorNumber, "0x01222222") ; fix the accented color being wrong
						this.TaskBar_SetAttr(this.taskbar_maximized_mode, el.MonitorNumber, this.taskbar_maximized_color)
					}
				}
				else {
					if (override)
						this.TaskBar_SetAttr(1, el.MonitorNumber, "0x01222222") ; fix
					this.TaskBar_SetAttr(2, el.MonitorNumber, "0x0100000" . s)
					this.taskbarTransparency[el.MonitorNumber] := 1
				}
			}
		} catch e {
			ListLines On
			MsgBox % "Error: " e.Message " in " e.What "`nTaskbar Transparency has been turned off."
			this.transparentTaskbar(0)
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

	getMaximizedMonitors() {
		SetTitleMatchMode, RegEx
		WinGet, id, List,,, % this.blacklist
		maximizedMonitors := []
		Loop, %id%
		{
			this_id := id%A_Index%
			WinGet, mmx, MinMax, % "ahk_id " . this_id
			if (mmx = 1) {
				maximizedMonitor := this.get_window_monitor_number(this_id)
				if !arrayContains(maximizedMonitors, maximizedMonitor)
					maximizedMonitors.push(maximizedMonitor)
			}
		}
		return maximizedMonitors
	}

	get_window_monitor_number(window_id) {
		WinGetPos, xpos, ypos, width, height, % "ahk_id " . window_id
		winMiddleX := xpos + width/2
		for i, e in this.monitors {
			if (winMiddleX > e.Left && winMiddleX < e.Right)
				return e.MonitorNumber
		}
	}

	TaskBar_SetAttr(accent_state := 0, monitor := -1, gradient_color := "0x01000000") {
	; 0 = off, 1 = gradient (+color), 2 = transparent (+color), 3 = blur; color -> ABGR (alpha | blue | green | red) all hex: 0xffd7a78f
		static pad := A_PtrSize = 8 ? 4 : 0, WCA_ACCENT_POLICY := 19
		if !(this.trayHandles[monitor])
			throw Exception("Attempted to set transparency/blur on monitor that doesn't exist.",-1)
		accent_size := VarSetCapacity(ACCENT_POLICY, 16, 0)
		NumPut((accent_state > 0 && accent_state < 4) ? accent_state : 0, ACCENT_POLICY, 0, "int")
		if (accent_state >= 1) && (accent_state <= 2) && (RegExMatch(gradient_color, "0x[[:xdigit:]]{8}"))
			NumPut(gradient_color, ACCENT_POLICY, 8, "int")
		VarSetCapacity(WINCOMPATTRDATA, 4 + pad + A_PtrSize + 4 + pad, 0)
		&& NumPut(WCA_ACCENT_POLICY, WINCOMPATTRDATA, 0, "int")
		&& NumPut(&ACCENT_POLICY, WINCOMPATTRDATA, 4 + pad, "ptr")
		&& NumPut(accent_size, WINCOMPATTRDATA, 4 + pad + A_PtrSize, "uint")
		if !(DllCall("user32\SetWindowCompositionAttribute", "ptr", this.trayHandles[monitor], "ptr", &WINCOMPATTRDATA))
			throw Exception("Failed to set transparency/blur", -1)
		return true
	}
	
	setInvisibility(mode := 0, tMode := 0) {
		; mode = 0 (turn off), 1 (turn on), T[...] (toggle)
		; tmode = 0 (primary), 1 (secondary), 2 (all)
		if (!this.init) {
			this.initSoft()
		}
		SysGet, mp, MonitorPrimary
		if (SubStr(mode, 1, 1) == "T") {
			WinGet, tV, Transparent, % "ahk_id " . this.trayHandles[mp]
			mode := (tV == "" ? 1 : 0)
		}
		if (mode == 1) {
			if (!tMode || tMode == 2)
				WinSet, Transparent, 0, % "ahk_id " . this.trayHandles[mp]
			if (tMode) {
				for i, e in this.trayHandles
					if (i != mp)
						WinSet, Transparent, 0, % "ahk_id " . this.trayHandles[i]
			}
		}
		else if (mode == 0) {
			if (!tMode || tMode == 2) {
				WinSet, Transparent, Off, % "ahk_id " . this.trayHandles[mp]
			}
			if (tMode) {
				for i, e in this.trayHandles
					if (i != mp)
						WinSet, Transparent, Off, % "ahk_id " . this.trayHandles[i]
			}
			this.updateTaskbarTimer(true)
		}
	}

	sessionIsLocked() {
		static WTS_CURRENT_SERVER_HANDLE := 0, WTSSessionInfoEx := 25, WTS_SESSIONSTATE_LOCK := 0x00000000
		ret := false
		if (DllCall("ProcessIdToSessionId", "UInt", DllCall("GetCurrentProcessId", "UInt"), "UInt*", sessionId) && DllCall("wtsapi32\WTSQuerySessionInformation", "Ptr", WTS_CURRENT_SERVER_HANDLE, "UInt", sessionId, "UInt", WTSSessionInfoEx, "Ptr*", sesInfo, "Ptr*", BytesReturned)) {
			SessionFlags := NumGet(sesInfo+0, 16, "Int")
			ret := SessionFlags == WTS_SESSIONSTATE_LOCK
			DllCall("wtsapi32\WTSFreeMemory", "Ptr", sesInfo)
		}
		return ret
	}
}
