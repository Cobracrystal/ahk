/************************************************************************
 * @description A class for dynamic MsgBox-style GUIs
 * @author github.com/cobracrystal
 * @date 2026/07/20
 * @version 0.9.0
 ***********************************************************************/

class MsgBoxAsGui {
	; button choices
	static MB_BUTTON_TEXT := [
		["OK"],
		["OK", "Cancel"],
		["Abort", "Retry", "Ignore"],
		["Yes", "No", "Cancel"],
		["Yes", "No"],
		["Retry", "Cancel"],
		["Cancel", "Retry", "Continue"]
	]
	; icons
	static DEFAULT_ICONS := Map(
		"x", 0x5E, "MB_ICONHANDERROR", 0x5E,
		"?", 0x5F, "MB_ICONQUESTION", 0x5F,
		"!", 0x50, "MB_ICONEXCLAMATION", 0x50,
		"i", 0x4D, "MB_ICONASTERISKINFO", 0x4D
	)
	static ICON_SOUNDS := Map(
		this.DEFAULT_ICONS["MB_ICONHANDERROR"], "*16",
		this.DEFAULT_ICONS["MB_ICONQUESTION"], "*32",
		this.DEFAULT_ICONS["MB_ICONEXCLAMATION"], "*48",
		this.DEFAULT_ICONS["MB_ICONASTERISKINFO"], "*64"
	)
	static BUTTON_STYLE_ALIASES := Map(
		'OK', 						0, 'O',		0,
		'OKCancel', 				1, 'O/C', 	1, 'OC', 1,
		'AbortRetryIgnore', 		2, 'A/R/I', 2, 'ARI', 2,
		'YesNoCancel', 				3, 'Y/N/C', 3, 'YNC', 3,
		'YesNo', 					4, 'Y/N', 	4, 'YN', 4,
		'RetryCancel', 				5, 'R/C', 	5, 'RC', 5,
		'CancelTryAgainContinue', 	6, 'C/T/C', 6, 'CTC', 6,
	)
	static MB_FONTNAME := 0, MB_FONTSIZE := 0, MB_FONTWEIGHT := 0, MB_FONTISITALIC := 0
	static MB_HASFONTINFORMATION := this.getMsgBoxFontInfo(&MB_FONTNAME, &MB_FONTSIZE, &MB_FONTWEIGHT, &MB_FONTISITALIC)

	static gap := 26			; Spacing above and below text in top area of the Gui
	static buttonMargin := 12	; Left Gui margin
	static rightMargin := 8		; Space between right side of button and next button / gui edge
	static buttonWidth := 88	; Width of OK button
	static buttonHeight := 26	; Height of OK button
	static buttonOffset := 30	; Offset between the right side of text and right edge of button
	static buttonSpace := this.buttonWidth + this.rightMargin
	static leftMargin := 20
	static minGuiWidth := 138	; Minimum width of Gui
	static minTextWidth := 400
	static SS_WHITERECT := 0x0006	; Gui option for white rectangle (http://ahkscript.org/boards/viewtopic.php?p=20053#p20053)
	static NecessaryStyle := 0x94C80000
	static SS_NOPREFIX := 0x80 ; no ampersand nonsense
	
	static WM_KEYDOWN := 0x0100
	static WM_RBUTTONDOWN := 0x0204
	
	static INSTANCES := Map()

	/**
	 * Launches a MsgBox from a config object
	 * @param {Object} config May contain any of the following keys. 
	 * 
	 * 	text: "Press OK to continue",
	 * 	title: A_ScriptName,
	 * 	buttonStyle: 0,
	 * 	defaultButton: 1,
	 * 	wait: false,
	 * 	funcObj: unset,
	 * 	owner: unset,
	 * 	addCopyButton: false,
	 * 	buttonNames: [],
	 * 	icon: unset,
	 * 	timeout: unset,
	 * 	maxCharsVisible: unset,
	 * 	maxTextWidth: unset
	 * @returns {Object} 
	 */
	static fromConfig(config) {
		return this(
			config.HasOwnProp("text") ? config.text : unset,
			config.HasOwnProp("title") ? config.title : unset,
			config.HasOwnProp("buttonStyle") ? config.buttonStyle : unset,
			config.HasOwnProp("defaultButton") ? config.defaultButton : unset,
			config.HasOwnProp("wait") ? config.wait : unset,
			config.HasOwnProp("funcObj") ? config.funcObj : unset,
			config.HasOwnProp("owner") ? config.owner : unset,
			config.HasOwnProp("addCopyButton") ? config.addCopyButton : unset,
			config.HasOwnProp("buttonNames") ? config.buttonNames : unset,
			config.HasOwnProp("icon") ? config.icon : unset,
			config.HasOwnProp("timeout") ? config.timeout : unset,
			config.HasOwnProp("maxCharsVisible") ? config.maxCharsVisible : unset,
			config.HasOwnProp("maxTextWidth") ? config.maxTextWidth : unset
		)
	}

	/**
	 * Creates a custom MsgBox with the given options creates as a GUI, thus not interrupting any threads. Autosupports a right click menu & Ctrl C for copying.
	 * @param {String} text The text to display. Control visible text via maxCharsVisible and maxTextWidth. Maximum is 32768 characters.
	 * @param {String} title The title to display.
	 * @param {Integer|String} buttonStyle Button Style. May be 1,2,3,4,5,6 or any values defined in MsgBoxAsGui.BUTTON_STYLE_ALIASES. If both buttonNames and this option are set, buttonNames takes precedence
	 * @param {Integer} defaultButton The number of the button which will be activated when pressing Enter. 1-Indexed.
	 * @param {Integer} wait Whether the Call will return immediately or wait until the user has closed the MsgBox by closing it directly or selecting an option. This option uses WinWaitClose. While usually the class instance object is returned, if this option is set to true, the result is returned instead.
	 * @param {Func} funcObj A function to be called when the GUI is closed through any means. Must have one parameter with which the result (the name of the button, ie "Yes", "Cancel") is returned. If the GUI is closed, it is called with the value "Cancel".
	 * @param {Integer} owner HWND of the owner of the msgbox.
	 * @param {Integer} addCopyButton Whether to add an extra button that, when clicked, copies the msgbox contents.
	 * @param {Array} buttonNames An array of custom button names.
	 * @param icon 
	 * @param timeout 
	 * @param maxCharsVisible 
	 * @param maxTextWidth 
	 * @returns {String | Class Instance} 
	 */
	static Call(text := "Press OK to continue", title := A_ScriptName, buttonStyle := 0, defaultButton := 1, wait := false, funcObj?, owner?, addCopyButton := false, buttonNames := [], icon?, timeout?, maxCharsVisible?, maxTextWidth?) {
		this := super()
		if MsgBoxAsGui.BUTTON_STYLE_ALIASES.Has(buttonStyle)
			buttonStyle := MsgBoxAsGui.BUTTON_STYLE_ALIASES[buttonStyle]
		if (buttonNames.Length == 0) {
			if !(MsgBoxAsGui.MB_BUTTON_TEXT.Has(buttonStyle + 1)) ; offset since this is not 0-indexed
				throw Error("Invalid button Style")
			this.buttonNames := MsgBoxAsGui.MB_BUTTON_TEXT[buttonStyle + 1]
		} else {
			this.buttonNames := buttonNames
		}
		this.result := ""
		this.text := text
		this.funcObj := funcObj ?? 0
		this.timeout := timeout ?? -1
		totalButtonWidth := MsgBoxAsGui.buttonSpace * (this.buttonNames.Length + (addCopyButton ? 1 : 0))
		ownerStr := IsSet(owner) ? "+Owner" owner : ''
		this.guiFontOptions := MsgBoxAsGui.MB_HASFONTINFORMATION ? "S" MsgBoxAsGui.MB_FONTSIZE " W" MsgBoxAsGui.MB_FONTWEIGHT (MsgBoxAsGui.MB_FONTISITALIC ? " italic" : "") : ""
		this.gui := Gui("+ToolWindow -Resize -MinimizeBox -MaximizeBox " ownerStr, title)
		this.hwnd := this.gui.Hwnd
		MsgBoxAsGui.INSTANCES[this.hwnd] := this
		this.gui.OnEvent("Close", this.finalEvent.bind(this, 0))
		this.gui.Opt("+" Format("0x{:X}", MsgBoxAsGui.NecessaryStyle))
		this.gui.Opt("-ToolWindow")
		if (buttonStyle == 2 || buttonStyle == 4) ; if cancel is not present in option, close and escape have no effect. user must select an option.
			this.gui.Opt("-SysMenu")
		this.gui.SetFont(this.guiFontOptions, MsgBoxAsGui.MB_FONTNAME)
		visibleText := IsSet(maxCharsVisible) ? SubStr(this.text, 1, maxCharsVisible) : this.text
		if !IsSet(maxTextWidth) {
			maxTextWidth := Max(MsgBoxAsGui.minTextWidth, totalButtonWidth)
			lens := [], lenSum := 0 ; this is strGetSplitLen w/out using primutils dependency
			Loop Parse, visibleText, '`n'
				lens.push(StrLen(A_LoopField)), lenSum += StrLen(A_LoopField)
			if lenSum == 0
				minim := maxim := avg := StrLen(visibleText)
			else
				minim := min(lens*), maxim := max(lens*), avg := lenSum / lens.Length
			if (2 * avg > maxim && maxim < 1500)
				maxTextWidth := Max(MsgBoxAsGui.minTextWidth, maxim)
			if StrLen(this.text) > 10000 && !IsSet(maxCharsVisible)
				maxTextWidth := 1500
		}
		if (StrLen(this.text) > 32768 && (!IsSet(maxCharsVisible) || (IsSet(maxCharsVisible) && maxCharsVisible > 32768)))
			maxCharsVisible := 32768
		ctrlText := MsgBoxAsGui.textCtrlAdjustSize(maxTextWidth,, visibleText,, this.guiFontOptions, MsgBoxAsGui.MB_FONTNAME)
		
		try this.gui.AddText("x0 y0 vWhiteBoxTop " MsgBoxAsGui.SS_WHITERECT, ctrlText)
		; catch as e
		; msgbox(strlen(ctrltext)) 
		if (IsSet(icon)) {
			iconPath := icon is Array ? icon[2] : "imageres.dll"
			icon := (icon is Array ? icon[1] : icon)
			icon := MsgBoxAsGui.DEFAULT_ICONS.Has(icon) ? MsgBoxAsGui.DEFAULT_ICONS[icon] : icon
			this.gui.AddPicture(Format("x{} y{} w{} h{} Icon{} BackgroundTrans", MsgBoxAsGui.leftMargin, MsgBoxAsGui.gap-9, 32, 32, icon), iconPath)
			MsgBoxAsGui.ICON_SOUNDS.Has(icon) ? SoundPlay(MsgBoxAsGui.ICON_SOUNDS[icon], 0) : 0
		}
		this.gui.AddText(Format("x{1} y{2} BackgroundTrans {3} vTextBox",
			MsgBoxAsGui.leftMargin + (IsSet(icon) ? 32 + MsgBoxAsGui.buttonMargin : 0),
			MsgBoxAsGui.gap,
			MsgBoxAsGui.SS_NOPREFIX,
		), ctrlText)
		this.gui["TextBox"].GetPos(&TBx, &TBy, &TBw, &TBh)
		this.guiWidth := MsgBoxAsGui.buttonMargin + MsgBoxAsGui.buttonOffset + Max(TBw, totalButtonWidth) + 1
		this.guiWidth := Max(this.guiWidth, MsgBoxAsGui.minGuiWidth)
		this.whiteBoxHeight := TBy + TBh + MsgBoxAsGui.gap
		this.gui["WhiteBoxTop"].Move(0, 0, this.guiWidth, this.whiteBoxHeight)
		buttonX := this.guiWidth - totalButtonWidth ; the buttons are right-aligned
		buttonY := this.whiteBoxHeight + MsgBoxAsGui.buttonMargin
		for i, name in this.buttonNames
			btn := this.gui.AddButton(
				Format("vButton{} x{} y{} w{} h{}", 
					i, 
					buttonX + (i-1) * MsgBoxAsGui.buttonSpace, 
					buttonY, MsgBoxAsGui.buttonWidth, 
					MsgBoxAsGui.buttonHeight
				), name
			).OnEvent("Click", this.finalEvent.bind(this, i))
		if (addCopyButton)
			btn := this.gui.AddButton(
				Format("vButton0 x{} y{} w{} h{}", 
					buttonX + this.buttonNames.Length * MsgBoxAsGui.buttonSpace, 
					buttonY, 
					MsgBoxAsGui.buttonWidth, 
					MsgBoxAsGui.buttonHeight
				), "Copy"
			).OnEvent("Click", (guiCtrl, infoObj) => (A_Clipboard := this.text))
		defaultButton := defaultButton == "Copy" ? 0 : defaultButton
		this.gui["Button" defaultButton].Focus()
		this.guiHeight := this.whiteBoxHeight + MsgBoxAsGui.buttonHeight + 2 * MsgBoxAsGui.buttonMargin
		if (buttonStyle != 2 && buttonStyle != 4)
			this.gui.OnEvent("Escape", this.finalEvent.bind(this, 0))
		this.gui.OnEvent("Close", this.finalEvent.bind(this, 0))
		this.notifyRegister := this.guiNotify.Bind(this)
		OnMessage(MsgBoxAsGui.WM_KEYDOWN, this.notifyRegister)
		OnMessage(MsgBoxAsGui.WM_RBUTTONDOWN, this.notifyRegister)
		this.gui.Show(Format(
			"Center w{} h{}", this.guiWidth, this.guiHeight
		))
		if this.timeout > 0
			SetTimer(this.timeoutFObj := this.finalEvent.bind(this, -1), -1000 * this.timeout)
		if (wait) {
			WinWait(this.hwnd)
			WinWaitClose(this.hwnd)
			this.gui := 0
			this.cleanup()
			return this.result
		}
		return this
	}
	
	finalEvent(buttonNumber, *) {
		this.gui.Destroy()
		this.gui := 0
		if (this.timeout > 0)
			SetTimer(this.timeoutFObj, 0)
		this.cleanup()
		this.result := buttonNumber == -1 ? "Timeout" : buttonNumber == 0 ? "Cancel" : this.buttonNames[buttonNumber]
		if (this.funcObj)
			this.funcObj.Call(this.result)
	}

	cleanup() {
		OnMessage(MsgBoxAsGui.WM_KEYDOWN, this.notifyRegister, 0) ; unregister
		OnMessage(MsgBoxAsGui.WM_RBUTTONDOWN, this.notifyRegister, 0)
		if MsgBoxAsGui.INSTANCES.Has(this.hwnd) {
			MsgBoxAsGui.INSTANCES.Delete(this.hwnd)
		}
	}

	guiNotify(wParam, lParam, msg, hwnd) {
		if (!this.gui)
			this.cleanup()
		else if (hwnd == this.hwnd && msg == MsgBoxAsGui.WM_RBUTTONDOWN) {
			m := Menu()
			m.Add("Select Text", this.guiContextMenu.Bind(this))
			m.show()
		} 
		else if (
			(hwnd == this.hwnd || ( (ctrl := GuiCtrlFromHwnd(hwnd)) && ctrl.gui.hwnd == this.hwnd)) 
			&& msg == MsgBoxAsGui.WM_KEYDOWN && (wParam == 67) && GetKeyState("Ctrl")
		) {
			A_Clipboard := this.text
			return 0 ; prevents sound
		}
	}

	guiContextMenu(itemName, itemPos, menuObj) {
		miniGui := Gui(Format(
			"+ToolWindow -Resize -MinimizeBox -MaximizeBox +Owner{}", this.hwnd
		), "Select and Copy")
		miniGui.Opt("+" Format("0x{:X}", MsgBoxAsGui.NecessaryStyle))
		miniGui.Opt("-ToolWindow")
		miniGui.OnEvent("Escape", (*) => miniGui.destroy())
		miniGui.OnEvent("Close", (*) => miniGui.destroy())
		miniGui.MarginX := miniGui.MarginY := 2
		miniGui.SetFont(this.guiFontOptions, MsgBoxAsGui.MB_FONTNAME)
		miniGui.AddEdit(Format(
			"-E0x200 ReadOnly w{} h{}", this.guiWidth, this.whiteBoxHeight
		), this.text)
		miniGui.show()
	}

	; necessary override since default .Bind requires this to be passed as a parameter
	static Bind(params*) {
		return ObjBindMethod(this,, params*)
	}

	; creates a bound func object with the given config applied.
	; can be cal
	/**
	 * Creates a Bound Func with the given config bound. Can be called only with another optional config, which causes it to call this() with the bound config supplemented by the given config.
	 * If the new config supplied on call contains values already defined in the bound config, the new config values are taken.
	 * @param config 
	 * @returns {BoundFunc} 
	 */
	static BindMergableConfig(config) {
		return fn.bind(config.Clone())

		fn(oldConfig, newConfig?) {
			if IsSet(newConfig) {
				for name, value in newConfig.OwnProps()
					oldConfig.%name% := value
			}
			return MsgBoxAsGui.fromConfig(oldConfig)
		}
	}

	static BindConfig(config) {
		return ObjBindMethod(
			this, , 
			config.HasOwnProp("text") ? config.text : unset,
			config.HasOwnProp("title") ? config.title : unset,
			config.HasOwnProp("buttonStyle") ? config.buttonStyle : unset,
			config.HasOwnProp("defaultButton") ? config.defaultButton : unset,
			config.HasOwnProp("wait") ? config.wait : unset,
			config.HasOwnProp("funcObj") ? config.funcObj : unset,
			config.HasOwnProp("owner") ? config.owner : unset,
			config.HasOwnProp("addCopyButton") ? config.addCopyButton : unset,
			config.HasOwnProp("buttonNames") ? config.buttonNames : unset,
			config.HasOwnProp("icon") ? config.icon : unset,
			config.HasOwnProp("timeout") ? config.timeout : unset,
			config.HasOwnProp("maxCharsVisible") ? config.maxCharsVisible : unset,
			config.HasOwnProp("maxTextWidth") ? config.maxTextWidth : unset
		)
	}

	
	static getMsgBoxFontInfo(&name := "", &size := 0, &weight := 0, &isItalic := 0) {
		; SystemParametersInfo constant for retrieving the metrics associated with the nonclient area of nonminimized windows
		static SPI_GETNONCLIENTMETRICS := 0x0029

		static NCM_Size        := 40 + 5 * 92   ; Size of NONCLIENTMETRICS structure (not including iPaddedBorderWidth)
		static MsgFont_Offset  := 40 + 4 * 92   ; Offset for lfMessageFont in NONCLIENTMETRICS structure
		static Size_Offset     := 0    ; Offset for cbSize in NONCLIENTMETRICS structure

		static Height_Offset   := 0    ; Offset for lfHeight in LOGFONT structure
		static Weight_Offset   := 16   ; Offset for lfWeight in LOGFONT structure
		static Italic_Offset   := 20   ; Offset for lfItalic in LOGFONT structure
		static FaceName_Offset := 28   ; Offset for lfFaceName in LOGFONT structure
		static FACESIZE        := 32   ; Size of lfFaceName array in LOGFONT structure
		; Maximum number of characters in font name string

		NCM := Buffer(NCM_Size, 0)
		NumPut("UInt", NCM_Size, NCM, Size_Offset)   ; Set the cbSize element of the NCM structure
		; Get the system parameters and store them in the NONCLIENTMETRICS structure (NCM)
		if !DllCall("SystemParametersInfo", "UInt", SPI_GETNONCLIENTMETRICS, "UInt", NCM_Size, "Ptr", NCM.Ptr, "UInt", 0)                        ; Don't update the user profile
			return false
		name   := StrGet(NCM.Ptr + MsgFont_Offset + FaceName_Offset, FACESIZE)          ; Get the font name
		height := NumGet(NCM.Ptr + MsgFont_Offset + Height_Offset, "Int")               ; Get the font height
		size   := DllCall("MulDiv", "Int", -Height, "Int", 72, "Int", A_ScreenDPI)   ; Convert the font height to the font size in points
		; Reference: http://stackoverflow.com/questions/2944149/converting-logfont-height-to-font-size-in-points
		weight   := NumGet(NCM.Ptr + MsgFont_Offset + Weight_Offset, "Int")             ; Get the font weight (400 is normal and 700 is bold)
		isItalic := NumGet(NCM.Ptr + MsgFont_Offset + Italic_Offset, "UChar")           ; Get the italic state of the font
		return true
	}
	
	static textCtrlAdjustSize(width, textCtrl?, str?, onlyCalculate := false, fontOptions?, fontName?) {
		if (!IsSet(textCtrl) && !IsSet(str))
			throw Error("Both textCtrl and str were not set")
		if (!IsSet(str))
			str := textCtrl.Value
		else if (!IsSet(textCtrl)) {
			local temp := Gui()
			temp.SetFont(fontOptions ?? unset, fontName ?? unset)
			textCtrl := temp.AddText()
			onlyCalculate := true
		}
		fixedWidthStr := ""
		loop parse str, "`n", "`r" {
			fixedWidthLine := ""
			fullLine := A_LoopField
			pos := 0
			loop parse fullLine, " `t" {
				line := A_LoopField
				lLen := StrLen(A_LoopField)
				pos += lLen + 1
				strWidth := this.guiGetTextSize(textCtrl, fixedWidthLine . line)
				if (pos > 65535)
					break
				if (strWidth[1] <= width)
					fixedWidthLine .= line . substr(fullLine, pos, 1)
				else { ; reached max width, begin new line
					fixedWidthStr .= (fixedWidthStr ? '`n' : '') . fixedWidthLine
					if (this.guiGetTextSize(textCtrl, line)[1] <= width) {
						fixedWidthLine := line . substr(fullLine, pos, 1)
					} else { ; A_Loopfield is by itself wider than width
						fixedWidthLine := fixedWidthWord := linePart := ""
						loop parse line { ; thus iterate char by char
							curWidth := this.guiGetTextSize(textCtrl, linePart . A_LoopField)
							if (curWidth[1] <= width) ; reached max width, begin new line
								linePart .= A_LoopField
							else {
								fixedWidthWord .= '`n' linePart
								linePart := A_LoopField
							}
						}
						fixedWidthStr .= (fixedWidthStr == "" ? SubStr(fixedWidthWord, 2) : fixedWidthWord) . (linePart == "" ? '' : '`n' linePart)
					}
				}
			}
			fixedWidthStr .= (fixedWidthStr ? '`n' : '') fixedWidthLine . substr(fullLine, pos, 1)
		}
		if (!onlyCalculate) {
			textCtrl.Move(,,this.guiGetTextSize(textCtrl, fixedWidthStr)*)
			textCtrl.Value := fixedWidthStr
		}
		return fixedWidthStr
	}

	static guiGetTextSize(txtCtrlObj, str) {
		static WM_GETFONT := 0x0031
		static DT_CALCRECT := 0x400
		DC := DllCall("GetDC", "Ptr", txtCtrlObj.Hwnd, "Ptr")
		hFont := SendMessage(WM_GETFONT,,, txtCtrlObj)
		hOldObj := DllCall("SelectObject", "Ptr", DC, "Ptr", hFont, "Ptr")
		height := DllCall("DrawText", "Ptr", DC, "Str", str, "Int", -1, "Ptr", rect := Buffer(16, 0), "UInt", DT_CALCRECT)
		width := NumGet(rect, 8, "Int") - NumGet(rect, "Int")
		DllCall("SelectObject", "Ptr", DC, "Ptr", hOldObj, "Ptr")
		DllCall("ReleaseDC", "Ptr", txtCtrlObj.Hwnd, "Ptr", DC)
		return [width, height]
	}

	; this does not serve any function, it exists solely so the ahk lexer by thqby stops complaining. In fact the nonstatic ones don't even do anything since __New() is overwritten
	static guiNotify := 0
	static finalEvent := 0
	static cleanup := 0
	static timeout := 0
	static timeoutFObj := 0
	static buttonNames := 0
	static funcObj := 0
	static notifyRegister := 0
	static hwnd := 0
	result := ""
	text := ""
	funcObj := 0
	timeout := -1
	timeoutFObj := 0
	hwnd := 0
	notifyRegister := 0
	buttonNames := []
	guiWidth := -1
	guiFontOptions := ""
	whiteBoxHeight := -1
}

; TODO: Better documentation
; TODO: Add option for AlwaysOnTop, SystemModal/TaskModal, Help Button (by supplying a function to run when that Help button is clicked), Right-justified/right-to-left
; TODO: Add a parser for regular MsgBox-style option strings to convert into config opjects (and supply those to the constructor)