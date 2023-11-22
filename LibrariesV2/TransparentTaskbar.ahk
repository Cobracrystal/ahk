; https://github.com/cobracrystal/ahk
; taskbar_Setattr by https://github.com/jNizM/AHK_TaskBar_SetAttr/

#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\ColorUtilities.ahk"

class TransparentTaskbar {
	
	static transparentTaskbar(mode := 0, newPeriod := -1, debug := 0, *) {
		; mode = 0 (turn off), 1 (turn on), -1 or T[...] (toggle)
		this.logStatus := debug
		if (!this.init)
			this.initialize()
		if (SubStr(mode, 1, 1) == "T" || mode == -1)
			mode := !this.onOffStatus
		if (mode == 1) {
			SetTimer(this.taskbar_timer, (newPeriod == -1 ? this.period : (this.period := newPeriod)))
			TrayMenu.submenus["Timers"].Check("Taskbar Transparency Timer")
			this.onOffStatus := true
		}
		else if (mode == 0) {
			SetTimer(this.taskbar_timer, 0)
			this.reset()
			TrayMenu.submenus["Timers"].Uncheck("Taskbar Transparency Timer")
			this.onOffStatus := false
		}
		else
			MsgBox("Invalid mode specified for Transparency manager function.")
	}

	static __New() {
		timerMenu := TrayMenu.submenus["Timers"]
		timerMenu.Add("Taskbar Transparency Timer", this.transparentTaskbar.Bind(this, -1, -1, 0))
		A_TrayMenu.Add("Timers", timerMenu)
		this.taskbar_timer := this.updateTaskbarTimer.Bind(this)
		this.period := 200
		this.isLocked := false
		this.blacklist := "(Program Manager|NVIDIA GeForce Overlay|^$)"
		this.logStatus := 0
		this.taskbar_accent_color := 0x202020 ; the gray of the taskbar when turning off
		this.taskbar_accent_transparency := 0xE0
		this.taskbar_maximized_color := 0x393747 ; color when window is maximized
		this.taskbar_maximized_transparency := 0xD0
		this.taskbar_maximized_mode := 2 ; mode when window is max
		this.taskbar_RGB_mode := true ; if max_mode is 1 / 2, this overwrites maximized_color
		this.RGB_color_intensity := 0x70 ; if max_mode is 1 / 2, this overwrites maximized_color
		this.RGB_rotate_duration := 4 ; this * period * 63 is duration per cycle on average, very inconsistently.
		this.rgbTransparency := 0xD0
		r := this.RGB_color_intensity * 0x010000, g := this.RGB_color_intensity * 0x000100, b := this.RGB_color_intensity * 0x000001
		; this.gradient := rainbowArr(round(this.RGB_rotate_duration*63), this.RGB_color_intensity)
		this.gradient := colorGradientArr(round(this.RGB_rotate_duration*63), r, r|g//2, r|g, g, g|b, g//2|b, b, b|r//2, b|r, b//2|r, r)

		this.onOffStatus := false
		this.taskbarTransparency := [-1,-1]
		this.trayHandles := Map()
		this.monitors := this.getMonitors()
		this.initialize()
	}
	
	static initialize() {
		try {
			DetectHiddenWindows(1)
			mP := MonitorGetPrimary()
			tHWND := WinGetID("ahk_class Shell_TrayWnd")
			this.trayHandles[mP] := tHWND ; DllCall("user32\FindWindow", "str", "Shell_TrayWnd", "ptr", 0, "ptr")
			hSecondaryTray := WinGetList("ahk_class Shell_SecondaryTrayWnd")
			for i, e in hSecondaryTray
				this.trayHandles[this.get_window_monitor_number(e)] := e
		}
		this.init := true
	}
	
	static reset() {
		this.taskbarTransparency := [-1,-1]
		try for i, e in this.monitors
			this.TaskBar_SetAttr(1, e.MonitorNumber, this.taskbar_accent_color, this.taskbar_accent_transparency)
		catch Error
			return
	}
	
	static updateTaskbarTimer(override := false) {
		static index := 0
		ListLines(this.logStatus)
		if (this.sessionIsLocked()) {
			if (!this.isLocked) {
				this.isLocked := true
				SetTimer(this.taskbar_timer, 400)
			}
			return
		}
		else if (this.isLocked) {
			this.isLocked := false
			SetTimer(this.taskbar_timer, this.period)
		}
		try {
			maximizedMonitors := this.getMaximizedMonitors()
			for i, el in this.monitors {
				if (maximizedMonitors[el.MonitorNumber]) {
					if (this.taskbar_RGB_mode) {
						this.TaskBar_SetAttr(this.taskbar_maximized_mode, el.MonitorNumber, this.gradient[index+1], this.rgbTransparency)
						this.taskbarTransparency[el.MonitorNumber] := 0
						index := mod(index + 1, round(this.RGB_rotate_duration*63))
					}
					else if (this.taskbarTransparency[el.MonitorNumber]) {
						this.TaskBar_SetAttr(this.taskbar_maximized_mode, el.MonitorNumber, this.taskbar_maximized_color, this.taskbar_maximized_transparency)
						this.taskbarTransparency[el.MonitorNumber] := 0
					}
					else if (override) {
						this.TaskBar_SetAttr(1, el.MonitorNumber, 0x222222, 0x01) ; fix the accented color being wrong
						this.TaskBar_SetAttr(this.taskbar_maximized_mode, el.MonitorNumber, this.taskbar_maximized_color)
					}
				}
				else {
					if (override)
						this.TaskBar_SetAttr(1, el.MonitorNumber, 0x222222, 0x01) ; fix
					this.TaskBar_SetAttr(2, el.MonitorNumber, 0x000000, 0x01)
					this.taskbarTransparency[el.MonitorNumber] := 1
				}
			}
		} catch Error as e {
			ListLines(1)
			MsgBox("Error: " e.Message " in " e.What "`nTaskbar Transparency has been turned off.")
			this.transparentTaskbar(0)
			this.init := 0
		}
	}
	
	static getMonitors() {
		monitors := []
		Loop(MonitorGetCount())
		{
			MonitorGet(A_Index, &mLeft, &mTop, &mRight, &mBottom)
			monitors.push({MonitorNumber:A_Index, Left:mLeft, Right:mRight, Top:mTop, Bottom:mBottom})
		}
		return monitors
	}

	static getMaximizedMonitors() {
		SetTitleMatchMode("RegEx")
		DetectHiddenWindows(0)
		id := WinGetList(,,this.blacklist)
		maximizedMonitors := [0, 0]
		for i, e in id
			try	{
				if (WinExist("ahk_id " . e) && WinGetMinMax("ahk_id " . e) == 1)
				maximizedMonitors[this.get_window_monitor_number(e)] := 1
			}
		return maximizedMonitors
	}

	static get_window_monitor_number(window_id) {
		WinGetPos(&xpos, &ypos, &width, &height, "ahk_id " . window_id)
		winMiddleX := xpos + width/2
		for i, e in this.monitors
			if (winMiddleX > e.Left && winMiddleX < e.Right)
				return e.MonitorNumber
	}

	static TaskBar_SetAttr(accent_state := 0, monitor := -1, gradient_RGB := 0xFF8000, gradient_alpha := 0x80) {
		; 0 = off, 1 = gradient (+color), 2 = transparent (+color), 3 = blur; color -> ABGR (alpha | blue | green | red) all hex: 0xffd7a78f
		static pad := A_PtrSize == 8 ? 4 : 0, WCA_ACCENT_POLICY := 19
		if (accent_state < 0) || (accent_state > 3)
			throw Error("Bad state value passed in.`nValue must be 0-3.")
		if (!this.trayHandles.Has(monitor))
			throw Error("Attempted to set transparency/blur on monitor that doesn't exist.",-1)
		if (gradient_alpha > 0xFF || gradient_RGB > 0xFFFFFF)
			throw Error("Bad Alpha/RGB value passed in.`nMust be between 0x00 and 0xFF`nGot: " gradient_alpha ", " gradient_RGB)
		gradient_ABGR := (gradient_alpha << 24) | (gradient_RGB << 16 & 0xFF0000) | (gradient_RGB & 0xFF00) | (gradient_RGB >> 16 & 0xFF)
		ACCENT_POLICY := Buffer(16, 0)
		NumPut("int", (accent_state > 0 && accent_state < 4) ? 2 : 0, ACCENT_POLICY, 0)
		if (accent_state == 1 || accent_state == 2)
			NumPut("int", gradient_ABGR, ACCENT_POLICY, 8)
		WINCOMPATTRDATA := Buffer(4 + pad + A_PtrSize + 4 + pad, 0)
		NumPut("int", WCA_ACCENT_POLICY, WINCOMPATTRDATA, 0)
		NumPut("ptr", ACCENT_POLICY.Ptr, WINCOMPATTRDATA, 4 + pad)
		NumPut("uint", ACCENT_POLICY.Size, WINCOMPATTRDATA, 4 + pad + A_PtrSize)
		if !(DllCall("user32\SetWindowCompositionAttribute", "ptr", this.trayHandles[monitor], "ptr", WINCOMPATTRDATA))
			throw Error("Failed to set transparency/blur", -1)
		return true
	}
	
	static setInvisibility(mode := 0, taskbarMode := 0) {
		; mode = 0 (turn off), 1 (turn on), T[...] (toggle)
		; taskbarMode = 0 (primary), 1 (secondary), 2 (all)
		if (!this.init) {
			this.initialize()
		}
		mp := MonitorGetPrimary()
		if (SubStr(mode, 1, 1) == "T") {
			mode := (WinGetTransparent("ahk_id " . this.trayHandles[mp]) == "" ? 1 : 0)
		}
		if (mode == 1) {
			if (!taskbarMode || taskbarMode == 2)
				WinSetTransparent(0, "ahk_id " this.trayHandles[mp])
			if (taskbarMode) {
				for i, e in this.trayHandles
					if (i != mp)
						WinSetTransparent(0, "ahk_id " this.trayHandles[i])
			}
		}
		else if (mode == 0) {
			if (!taskbarMode || taskbarMode == 2) {
				WinSetTransparent("Off", "ahk_id " this.trayHandles[mp])
			}
			if (taskbarMode) {
				for i, e in this.trayHandles
					if (i != mp)
						WinSetTransparent("Off", "ahk_id " this.trayHandles[i])
			}
			this.updateTaskbarTimer(true)
		}
	}

	; En-/Disables Windows Setting 'Only show Taskbar when hovering over it with Mouse'. mode = 0 -> Off, 1 -> On
	static hideShowTaskbar(mode := 0) {
		static ABM_SETSTATE := 0xA, ABS_AUTOHIDE := 0x1, ABS_ALWAYSONTOP := 0x2
		APPBARDATA := Buffer(size := 2*A_PtrSize + 2*4 + 16 + A_PtrSize, 0)
		NumPut("UInt", size, APPBARDATA)
		NumPut("Ptr", WinExist("ahk_class Shell_SecondaryTrayWnd"), APPBARDATA, A_PtrSize)
		NumPut("UInt", mode ? ABS_AUTOHIDE : ABS_ALWAYSONTOP, APPBARDATA, size - A_PtrSize)
		DllCall("Shell32\SHAppBarMessage", "UInt", ABM_SETSTATE, "Ptr", APPBARDATA)
	}

	static sessionIsLocked() {
		static WTS_CURRENT_SERVER_HANDLE := 0, WTSSessionInfoEx := 25, WTS_SESSIONSTATE_LOCK := 0x00000000
		ret := false, sessionID := 0, sesInfo := 0, BytesReturned := 0
		flag1 := DllCall("ProcessIdToSessionId", "UInt", DllCall("GetCurrentProcessId", "UInt"), "UInt*", &sessionId)
		flag2 := DllCall("wtsapi32\WTSQuerySessionInformation", "Ptr", WTS_CURRENT_SERVER_HANDLE, "UInt", sessionId, "UInt", WTSSessionInfoEx, "Ptr*", &sesInfo, "Ptr*", &BytesReturned)
		if (flag1 && flag2) {
			SessionFlags := NumGet(sesInfo+0, 16, "Int")
			if (SessionFlags == WTS_SESSIONSTATE_LOCK)
				ret := true
			DllCall("wtsapi32\WTSFreeMemory", "Ptr", sesInfo)
		}
		return ret
	}
}
