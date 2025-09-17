; https://github.com/cobracrystal/ahk
; taskbar_Setattr by https://github.com/jNizM/AHK_TaskBar_SetAttr/

#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\ObjectUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\WinUtilities.ahk"

class TransparentTaskbar {
	
	/**
	 * @param {Integer} mode 0/"Off", 1/"On", -1/"Toggle"
	 */
	static setTimer(mode := 0) {
		if !this.verifyMonitorData(false)
			try this.setMonitorData()
		switch mode {
			case 0, "Off":
				SetTimer(this.timer, 0)
				try this.setTaskbarsToMode(2, 0)
				TrayMenu.submenus["Timers"].Uncheck("Taskbar Transparency Timer")
				this.data.isRunning := false
			case 1, "On":
				SetTimer(this.timer, this.config.period)
				TrayMenu.submenus["Timers"].Check("Taskbar Transparency Timer")
				this.data.isRunning := true
			case -1, "Toggle", "T":
				return this.setTimer(!this.data.isRunning)
		}
	}

	/**
	 * Set modes used by this class
	 * @param {Integer} mode1 The mode of the taskbar while a window on a monitor is maximized.
	 * @param {Integer} mode2 The mode of the taskbar while no window on a monitor is maximized.
	 * 
	 * Mode Values are **0 (Off), 1 (Gradient), 2 (transparent), 3 (blur), 4 (RGB)**
	 * @param {Integer?} period A period to set 
	 */
	static setMode(maximizedMode := 0, normalMode := 0, period?) {
		if IsSet(period) {
			this.config.period := period
			if this.data.isRunning
				SetTimer(this.timer, this.config.period)
		}
		if !isClamped(maximizedMode, 0, 4) || !isClamped(normalMode, 0, 4)
			throw ValueError("setMode requires modeWhileMax and normalMode to be of values [0,1,2,3,4]. Got " maximizedMode ", " normalMode " instead")
		this.config.normalMode := normalMode
		this.config.maximizedMode := maximizedMode
	}

	static __New() {
		timerMenu := TrayMenu.submenus["Timers"]
		timerMenu.Add("Taskbar Transparency Timer", (*) => this.setTimer(-1))
		A_TrayMenu.Add("Timers", timerMenu)
		this.timer := this.updateTaskbarTimer.Bind(this)
		this.data := {
			isRunning: false,
			isLocked: false
		}
		this.config := {
			period: 200,
			periodWhileLocked: 400,
			periodOnRetry: 1000,
			listLines: 0,
			alwaysUpdate: true, ; this is a crook because opening the start menu resets the taskbar
			maximizedMode: 3,
			maximizedColor: 0x393747,
			maximizedTransparency: 0xD0,
			normalMode: 2,
			normalColor: 0x000000,
			normalTransparency: 0x01,
			offMode: 1, ; the "default" mode of the taskbar cannot be set with DWMSetcompositionattribute, so this is the closest approximation
			offColor: 0x202020,
			offTransparency: 0xE0,
			RGBColorIntensity: 0x70,
			RGBTransparency: 0xD0,
			RGBColorDetail: 255 ; amount of colors to cycle through. Increasing this will increase cycle length
		}
		this.RGB_Gradient := rainbowArr(this.config.RGBColorDetail, this.config.RGBColorIntensity)
		; contains monitors + .isMaximized, .trayHandle, .isUpdated 
	}
	
	; this throws an error if a taskbar is missing. that's intended
	; it also overwrites prevstate and isMaximized. that's also intended
	static setMonitorData() {
		this.monitorData := WinUtilities.monitorGetAll(false) ; don't cache, otherwise we will edit it
		DHW := A_DetectHiddenWindows
		DetectHiddenWindows(1)
		try {
			primaryMHandle := WinUtilities.monitorGetHandleFromWindow(hwnd := WinGetID("ahk_class Shell_TrayWnd"))
			this.monitorData[primaryMHandle].trayHandle := hwnd
			secondaryTrayHandles := WinGetList("ahk_class Shell_SecondaryTrayWnd")
			for trayHandle in secondaryTrayHandles {
				mHandle := WinUtilities.monitorGetHandleFromWindow(trayHandle)
				this.monitorData[mHandle].trayHandle := trayHandle
			}
		} catch as e {
			throw TargetError("Could not retrieve Taskbar objects or handles.")
		}
		this.monitorData := objFilter(this.monitorData, (k, v) => v.HasOwnProp("trayHandle"))
		for mHandle, mon in this.monitorData {
			mon.prevState := -1
			mon.isMaximized := 0
		}
		DetectHiddenWindows(DHW)
		return 1
	}

	static verifyMonitorData(strict := true) {
		if !this.HasOwnProp("monitorData") || this.monitorData.Count == 0
			return 0
		if strict
			for mHandle, mon in this.monitorData
				if !WinExist(mon.trayHandle)
					return 0
		return 1
	}

	static retry() {
		try this.setTaskbarsToMode(2, 0)
		try this.setMonitorData()
		if (this.verifyMonitorData()) {
			try {
				this.updateTaskbars()
				SetTimer(, 0) ; turns itself off
				this.setTimer(1)
			}
		}
	}
	
	static updateTaskbarTimer() {
		ListLines(this.config.listLines)
		if (WinUtilities.sessionIsLocked()) { ; if we are on lockscreen, slow the timer to avoid a lot of checks
			if (!this.data.isLocked) {
				this.data.isLocked := true
				SetTimer(this.timer, this.config.periodWhileLocked)
			}
			return 0
		} else if (this.data.isLocked) { ; user has logged in, reenable the fast timer
			this.data.isLocked := false
			SetTimer(this.timer, this.config.period)
		}
		try
			this.updateTaskbars(this.config.alwaysUpdate)
		catch Error as e {
			ListLines(1)
			this.setTimer(0)
			timedTooltip("Couldnt apply mode to Taskbar. Hibernating until new Taskbar is found")
			SetTimer(this.retry.bind(this), this.config.periodOnRetry)
		}
	}

	static updateTaskbars(override := false) {
		static index := 1
		this.updateMaximizedMonitors()
		for mHandle, mon in this.monitorData {
			if (mon.isMaximized) {
				if (this.config.maximizedMode == this.modes.RGB) {
					this.TaskBar_SetAttr(this.modes.TRANSPARENT, mon.trayHandle, this.RGB_Gradient[index], this.config.RGBTransparency)
					index := mod(index, this.config.RGBColorDetail) + 1
				} else if (override || mon.prevState != mon.isMaximized) {
					this.TaskBar_SetAttr(this.config.maximizedMode, mon.trayHandle, this.config.maximizedColor, this.config.maximizedTransparency)
				}
			} else {
				if (override || mon.prevState != mon.isMaximized)
					this.TaskBar_SetAttr(this.config.normalMode, mon.trayHandle, this.config.normalColor, this.config.normalTransparency)
			}
		}
	}

	static updateMaximizedMonitors() {
		maximizedMonitors := Map() ; map for .has
		for mHandle, mon in this.monitorData
			mon.prevState := mon.isMaximized
		try for win in WinUtilities.getAllWindows()
			try if WinGetMinMax(win) == 1
				maximizedMonitors[WinUtilities.monitorGetHandleFromWindow(win)] := true
		for mHandle, mon in this.monitorData
			mon.isMaximized := maximizedMonitors.has(mHandle) ; ? 1 : 0
	}
	
	; 0 = off, 1 = gradient (+color), 2 = transparent (+color), 3 = blur; color -> ABGR (alpha | blue | green | red) all hex: 0xffd7a78f
	static setTaskbarsToMode(targets := 2, mode := this.config.offMode, color := this.config.offColor, transparency := this.config.offTransparency) {
		if targets is Array {
			for e in targets
				this.TaskBar_SetAttr(mode, e, color, transparency)
		} else for i, e in this.monitorData {
			if targets == 2 || (targets == 1 && e.isMaximized)
				this.TaskBar_SetAttr(mode, e.trayHandle, color, transparency)
			else if (targets == 0 && !e.isMaximized)
				this.TaskBar_SetAttr(mode, e.trayHandle, color, transparency)
		}
	}

	; 0 = off, 1 = gradient (+color), 2 = transparent (+color), 3 = blur; color -> ABGR (alpha | blue | green | red) all hex: 0xffd7a78f
	static TaskBar_SetAttr(accent_state, trayHandle, gradient_RGB := 0xFF8000, gradient_alpha := 0x80) {
		static pad := A_PtrSize == 8 ? 4 : 0
		static WCA_ACCENT_POLICY := 19
		if (accent_state < 0) || (accent_state > 3)
			throw(Error("Bad state value passed in.`nValue must be 0-3."))
		gradient_ABGR := (gradient_alpha << 24) | (gradient_RGB << 16 & 0xFF0000) | (gradient_RGB & 0xFF00) | (gradient_RGB >> 16 & 0xFF)
		if (!isClamped(gradient_ABGR, 0x00000000, 0xFFFFFFFF))
			throw(Error("Bad Alpha/RGB value passed in.`nMust be between 0x00 and 0xFF`nGot: " gradient_alpha ", " gradient_RGB))
		ACCENT_POLICY := Buffer(16, 0)
		NumPut("int", accent_state != 0 ? 2 : 0, ACCENT_POLICY)
		if (accent_state == 1 || accent_state == 2)
			NumPut("int", gradient_ABGR, ACCENT_POLICY, 8)
		WINCOMPATTRDATA := Buffer(4 + pad + A_PtrSize + 4 + pad, 0)
		NumPut("int", WCA_ACCENT_POLICY, WINCOMPATTRDATA)
		NumPut("ptr", ACCENT_POLICY.Ptr, WINCOMPATTRDATA, 4 + pad)
		NumPut("uint", ACCENT_POLICY.Size, WINCOMPATTRDATA, 4 + pad + A_PtrSize)
		if !(DllCall("user32\SetWindowCompositionAttribute", "ptr", trayHandle, "ptr", WINCOMPATTRDATA))
			throw(Error("Failed to set transparency/blur", -1))
		return true
	}

	/**
	 * Shows or hides corresponding taskbars
	 * @param {Integer} mode 0 (turn off), 1 (turn on), T[...] (toggle)
	 * @param {Integer} taskbarMode 0 (primary), 1 (secondary), 2 (all)
	 */
	static setInvisibility(mode := 0, taskbarMode := 0) {
		if !this.verifyMonitorData()
			this.setMonitorData()
		relevantHandles := []
		switch taskbarMode {
			case 0:
				for h, v in this.monitorData
					if v.primary
						relevantHandles.push(v.trayHandle)
			case 1:
				for h, v in this.monitorData
					if !v.primary
						relevantHandles.push(v.trayHandle)
			case 2:
				relevantHandles := objFlatten(this.monitorData, v => v.trayHandle)
		}
		mode := SubStr(mode, 1, 1)
		switch mode {
			case 0:
				fn := WinShow
			case 1:
				fn := WinHide
			case -1, "T":
				if WinUtilities.isVisible(relevantHandles[1]) {
					fn := WinHide
					mode := 1
				}
				else {
					fn := WinShow
					mode := 0
				}
		}
		for e in relevantHandles
			fn(e)
		if mode == 0
			this.setTaskbarsToMode(relevantHandles, this.config.offMode, this.config.offColor, this.config.offTransparency)
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

	static modes => {
		OFF: 0,
		GRADIENT: 1,
		TRANSPARENT: 2,
		BLUR: 3,
		RGB: 4
	}
}
