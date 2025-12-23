; https://github.com/cobracrystal/ahk

#Include "%A_LineFile%\..\..\LibrariesV2\jsongo.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\ObjectUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\PrimitiveUtilities.ahk"

class TrayMenu {
	; ADD TRACKING FOR CHILD MENUS
	static __New() {
		this.menus := Map()
		this.menus.CaseSense := 0
		this.TrayMenu := A_TrayMenu
		this.menus["traymenu"] := A_TrayMenu
		this.menus[A_TrayMenu] := A_TrayMenu
	}

	static submenus[menuName] {
		set => this.menus[menuName] := value
		get {
			if (!this.menus.Has(menuName))
				this.menus[menuName] := Menu()
			return this.menus[menuName]
		}
	}
}

class BetterMenu extends Menu {
	static __New() {
		this.menus := Map()
		this.menus["traymenu"] := A_TrayMenu
		this.menus[A_TrayMenu] := A_TrayMenu
	}

	__New(menuName) {
		if (BetterMenu.menus.Has(menuName))
			this.menuObj := Menu()
		else {
			this.menuObj := Menu()
			BetterMenu[menuName] := this.menuObj
		}
	}
}

fastCopy(timeout := 1) {
	ClipboardOld := ClipboardAll()
	A_Clipboard := "" ; free clipboard so that ClipWait is more reliable
	Send("^c")
	if !ClipWait(timeout) {
		A_Clipboard := ClipboardOld
		return
	}
	text := A_Clipboard
	A_Clipboard := ClipboardOld
	return text
}

fastPrint(text) {
	ClipboardOld := ClipboardAll()
	A_Clipboard := ""
	A_Clipboard := text
	if !ClipWait(1) {
		A_Clipboard := ClipboardOld
		return 0
	}
	SendEvent("^v")
	Sleep(150)
	A_Clipboard := ClipboardOld
	return 1
}

; param method -> accept text + possible extra params
modifySelectedText(method, params*) {
	ClipboardOld := ClipboardAll()
	A_Clipboard := "" ; free clipboard so that ClipWait is more reliable
	Send("^c")
	if !ClipWait(1) {
		A_Clipboard := ClipboardOld
		return
	}
	A_Clipboard := method(A_Clipboard, params*)
	Send("^v")
	Sleep(150)
	A_Clipboard := ClipboardOld
	return 1
}

htmlDecode(str) {
	static HTMLCodes := jsongo.Parse(FileRead(A_WorkingDir "\everything\HTML_Encodings.json", "UTF-8"))
	if InStr(str, "&") {
		while (pos := RegExMatch(str, "(&.*?;)", &o, pos ?? 1) + (o ? o.Len : 0)) {
			if (HTMLCodes.Has(o[1]))
				str := StrReplace(str, o[1], HTMLCodes[o[1]])
		}
	}
	return str
}

parseHeaders(str) {
	headersAsText := RTrim(str, "`r`n")
	headers := Map()
	Loop Parse headersAsText, "`n", "`r" {
		arr := StrSplit(A_LoopField, ":")
		headers[Trim(arr[1])] := Trim(arr[2])
	}
	return headers
}

/**
 * Given a function fn, returns the largest possible value in given range where fn does not throw an error.
 * @param fn 
 * @param {Integer} lower 
 * @param {Integer} upper 
 */
tryCatchBinarySearch(fn, lower := 1, upper := 100000) {
	return binarySearch(newFn, lower, upper)
	
	newFn(param) {
		try {
			fn(param)
			return true
		}
		catch 
			return false
	}
}


ExecHelperScript(expression, wait := true, void := false) {
	input := '#Warn All, Off`n'
	input .= '#Include "*i ' A_LineFile '"`n'
	input .= '#Include "*i ' A_LineFile '\..\..\LibrariesV2\MathUtilities.ahk"`n'
	if (void || RegexMatch(expression, 'i)FileAppend\(.*,\s*\"\*\"\)') || RegExMatch(expression, 'i)MsgBox(?:AsGui)?\(.+\)') || RegexMatch(expression, 'i)print\(.*\)') || RegexMatch(expression, 'i)\.Show\(.*\)'))
		input .= expression
	else
		input .= 'print(' expression ',,false,true)'
	return ExecScript(input, wait)
}

ExecScript(input, Wait := true) {
	static shell := ComObject("WScript.Shell")
	exec := shell.Exec(A_AhkPath " /ErrorStdOut *")
	exec.StdIn.Write(strChangeEncoding(input, 'UTF-8', 'CP0'))
	exec.StdIn.Close()
	if !Wait
		return
	output := exec.StdOut.ReadAll()
	return RTrim(strChangeEncoding(output, 'CP0', 'UTF-8'), " `t`n")
}

cmdRet(sCmd, callBackFuncObj?, encoding := "CP" . DllCall("GetOEMCP", "UInt")) {
	; encoding := "CP" . DllCall("GetOEMCP", "UInt") ; CP0 -> Ansi. Example: CP850 Western European Ansi.
	static HANDLE_FLAG_INHERIT := 0x1, CREATE_NO_WINDOW := 0x08000000, STARTF_USESTDHANDLES := 0x100, ptrsize := A_PtrSize

	DllCall("CreatePipe", "PtrP", &hPipeRead := 0, "PtrP", &hPipeWrite := 0, "Ptr", 0, "UInt", 0)
	DllCall("SetHandleInformation", "Ptr", hPipeWrite, "UInt", HANDLE_FLAG_INHERIT, "UInt", HANDLE_FLAG_INHERIT)

	STARTUPINFO := Buffer(size := ptrsize * 4 + 4 * 8 + ptrsize * 5, 0)
	NumPut("UInt", size, STARTUPINFO)
	NumPut("UInt", STARTF_USESTDHANDLES, STARTUPINFO, ptrsize * 4 + 4 * 7)
	NumPut("Ptr", hPipeWrite, "Ptr", hPipeWrite, STARTUPINFO, ptrsize * 4 + 4 * 8 + ptrsize * 3)

	PROCESS_INFORMATION := Buffer(ptrsize * 2 + 4 * 2, 0)
	if !DllCall("CreateProcess", "Ptr", 0, "Str", sCmd, "Ptr", 0, "Ptr", 0, "UInt", true, "UInt", CREATE_NO_WINDOW,
		"Ptr", 0, "Ptr", 0, "Ptr", STARTUPINFO, "Ptr", PROCESS_INFORMATION) {
		DllCall("CloseHandle", "Ptr", hPipeRead)
		DllCall("CloseHandle", "Ptr", hPipeWrite)
		throw(OSError("CreateProcess has failed"))
	}
	DllCall("CloseHandle", "Ptr", hPipeWrite)
	sTemp := Buffer(4096)
	sOutput := ""
	while DllCall("ReadFile", "Ptr", hPipeRead, "Ptr", sTemp, "UInt", 4096, "UIntP", &nSize := 0, "UInt", 0) {
		sOutput .= stdOut := StrGet(sTemp, nSize, encoding)
		if (IsSet(callBackFuncObj))
			callBackFuncObj(stdOut)
	}
	DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, "Ptr"))
	DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, ptrsize, "Ptr"))
	DllCall("CloseHandle", "Ptr", hPipeRead)
	return sOutput
}


cmdRetVoid(sCmd, finishCallBack?, encoding := "CP" . DllCall('GetOEMCP', 'UInt'), checkReturnInterval := 100) => cmdRetAsync(sCmd, unset, encoding, checkReturnInterval, finishCallBack?)

/**
 * Runs specified command in a command line interface without waiting for return value. optionally calls functions with return values
 * @param sCmd Command to run. If the Run equivalent was Run(A_Comspec " /c ping 8.8.8.8"), use sCmd = "ping 8.8.8.8" here.
 * @param callBackFuncObj Func Object accepting one parameter that will be called with the next line of console output every interval
 * @param {String} encoding String encoding. Defaults to your local codepage (eg western CP850). Else specify UTF-8 etc
 * @param {Integer} timePerCheck Time between each read of the console output
 * @param finishCallBack Func object to be called with the full output when the console is done
 * @returns {Integer} returns true if everything worked.
 */
cmdRetAsync(sCmd, callBackFuncObj?, encoding := "CP" . DllCall('GetOEMCP', 'UInt'), timePerCheck := 50, finishCallBack?, timeout?) {
	; encoding := "CP" . DllCall("GetOEMCP", "UInt") ; CP0 -> Ansi, CP850 Western European Ansi.
	static HANDLE_FLAG_INHERIT := 0x1, CREATE_NO_WINDOW := 0x08000000, STARTF_USESTDHANDLES := 0x100, ptrsize := A_PtrSize
	DllCall("CreatePipe", "PtrP", &hPipeRead := 0, "PtrP", &hPipeWrite := 0, "Ptr", 0, "UInt", 0)
	DllCall("SetHandleInformation", "Ptr", hPipeWrite, "UInt", HANDLE_FLAG_INHERIT, "UInt", HANDLE_FLAG_INHERIT)

	fullOutput := ""
	STARTUPINFO := Buffer(size := ptrsize * 4 + 4 * 8 + ptrsize * 5, 0)
	NumPut("UInt", size, STARTUPINFO)
	NumPut("UInt", STARTF_USESTDHANDLES, STARTUPINFO, ptrsize * 4 + 4 * 7)
	NumPut("Ptr", hPipeWrite, "Ptr", hPipeWrite, STARTUPINFO, ptrsize * 4 + 4 * 8 + ptrsize * 3)

	PROCESS_INFORMATION := Buffer(ptrsize * 2 + 4 * 2, 0)
	if !DllCall("CreateProcess", "Ptr", 0, "Str", sCmd, "Ptr", 0, "Ptr", 0, "UInt", true, "UInt", CREATE_NO_WINDOW,
		"Ptr", 0, "Ptr", 0, "Ptr", STARTUPINFO, "Ptr", PROCESS_INFORMATION) {
		DllCall("CloseHandle", "Ptr", hPipeRead)
		DllCall("CloseHandle", "Ptr", hPipeWrite)
		throw(OSError("CreateProcess has failed"))
	}
	DllCall("CloseHandle", "Ptr", hPipeWrite)
	sTemp := Buffer(4096)
	SetTimer(readFileCheck, timePerCheck)
	if IsSet(timeout)
		SetTimer(closeHandle, -timeout)
	return 1

	readFileCheck() {
		if (DllCall("ReadFile", "Ptr", hPipeRead, "Ptr", sTemp, "UInt", 4096, "UIntP", &nSize := 0, "UInt", 0)) {
			fullOutput .= stdOut := StrGet(sTemp, nSize, encoding)
			if (IsSet(callBackFuncObj))
				callBackFuncObj(stdOut)
		} else {
			SetTimer(readFileCheck, 0)
			closeHandle(1)
		}
	}

	closeHandle(success := -1) {
		SetTimer(closeHandle, 0)
		SetTimer(readFileCheck, 0)
		DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, "Ptr"))
		DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, ptrsize, "Ptr"))
		DllCall("CloseHandle", "Ptr", hPipeRead)
		if (IsSet(finishCallBack))
			finishCallBack(fullOutput, success)
	}
}

execShell(command) {
	shell := ComObject("WScript.Shell")
	exec := shell.Exec(A_Comspec " /C " command)
	return exec.StdOut.ReadAll()
}

menu_RemoveSpace(menuHandle, applyToSubMenus := true) {
	; http://msdn.microsoft.com/en-us/library/ff468864(v=vs.85).aspx
	static MIsize := (4 * 4) + (A_PtrSize * 3)
	MI := Buffer(MIsize, 0)
	Numput("UInt", MIsize, MI, 0)
	NumPut("UInt", 0x00000010, MI, 4) ; MIM_STYLE = 0x00000010
	DllCall("User32.dll\GetMenuInfo", "Ptr", menuHandle, "Ptr", MI, "UInt")
	if (applyToSubMenus)
		NumPut("UInt", 0x80000010, MI, 4) ; MIM_APPLYTOSUBMENUS = 0x80000000| MIM_STYLE : 0x00000010
	NumPut("UInt", NumGet(MI, 8, "UINT") | 0x80000000, MI, 8) ; MNS_NOCHECK = 0x80000000
	DllCall("User32.dll\SetMenuInfo", "Ptr", menuHandle, "Ptr", MI, "UInt")
	return true
}

/**
 * Opens Color picking Window
 * @param Color 
 * @param {Integer} hGui 
 * @returns {Integer} 
 */
colorDialog(initialColor := 0, hwnd := 0, disp := false, startingColors*) {
	static p := A_PtrSize
	disp := disp ? 0x3 : 0x1 ; init disp / 0x3 = full panel / 0x1 = basic panel

	if (startingColors.Length > 16)
		throw(Error("Too many custom colors.  The maximum allowed values is 16."))

	Loop (16 - startingColors.Length)
		startingColors.Push(0) ; fill out custColorObj to 16 values

	CUSTOM := Buffer(16 * 4, 0) ; init custom colors obj
	CHOOSECOLOR := Buffer((p == 4) ? 36 : 72, 0) ; init dialog

	for i, e in startingColors
		NumPut("UInt", format_argb(e), CUSTOM, (i-1) * 4)

	NumPut("UInt", CHOOSECOLOR.size, CHOOSECOLOR, 0)             ; lStructSize
	NumPut("UPtr", hwnd, CHOOSECOLOR, p)             ; hwndOwner
	NumPut("UInt", format_argb(initialColor), CHOOSECOLOR, 3 * p)         ; rgbResult
	NumPut("UPtr", CUSTOM.ptr, CHOOSECOLOR, 4 * p)         ; lpCustColors
	NumPut("UInt", disp, CHOOSECOLOR, 5 * p)         ; Flags

	if !DllCall("comdlg32\ChooseColor", "UPtr", CHOOSECOLOR.ptr, "UInt")
		return -1
	return format_argb(NumGet(CHOOSECOLOR, 3 * A_PtrSize, "UInt"))
}
; typedef struct tagCHOOSECOLORW {  offset      size    (x86/x64)
; DWORD        lStructSize;       |0      |   4
; HWND         hwndOwner;         |4 / 8  |   8 /16
; HWND         hInstance;         |8 /16  |   12/24
; COLORREF     rgbResult;         |12/24  |   16/28
; COLORREF     *lpCustColors;     |16/28  |   20/32
; DWORD        Flags;             |20/32  |   24/36
; LPARAM       lCustData;         |24/40  |   28/48 <-- padding for x64
; LPCCHOOKPROC lpfnHook;          |28/48  |   32/56
; LPCWSTR      lpTemplateName;    |32/56  |   36/64
; LPEDITMENU   lpEditInfo;        |36/64  |   40/72
; } CHOOSECOLORW, *LPCHOOSECOLORW;
; https://github.com/cobracrystal/ahk

colorGradientArr(amount, colors*) {
	sColors := [], gradient := []
	if (amount < colors.Length-2)
		return 0
	else if (amount == colors.Length-2)
		return colors
	for index, color in colors
		sColors.push({r:(color & 0xFF0000) >> 16, g: (color & 0xFF00) >> 8, b:color & 0xFF})
	; first color given, format with 6 padded 0s in case of black
	gradient.push(format("0x{:06X}", colors[1]))
	; amount of color gradients to perform
	segments := colors.Length-1
	Loop(amount) {
		; current gradient segment we are in
		segment := floor((A_Index/(amount+1))*segments)+1
		; percentage progress in the current gradient segment as decimal
		segProgress := ((A_Index/(amount+1)*segments)-segment+1)
		; RGB obtained via percentage * (end of gradient - start of gradient), then adding current RGB value again.
		r := round((segProgress * (sColors[segment+1].r-sColors[segment].r))+sColors[segment].r)
		g := round((segProgress * (sColors[segment+1].g-sColors[segment].g))+sColors[segment].g)
		b := round((segProgress * (sColors[segment+1].b-sColors[segment].b))+sColors[segment].b)
		gradient.Push(format("0x{1:02X}{2:02X}{3:02X}", r, g, b))
	}
	; last color given, same as first
	gradient.Push(format("0x{:06X}", colors[-1]))
	; return array of amount+2 colors
	return gradient
}

rainbowArr(num, intensity := 0xFF) {
	if (num < 7)
		throw(ValueError("Invalid num"))
	if (intensity < 0 || intensity > 255)
		throw(ValueError("Invalid Intensity"))
	intensity := format("{:#x}", intensity)
	r := intensity * 0x010000
	g := intensity * 0x000100
	b := intensity * 0x000001
	return colorGradientArr(num-2, r, r|g//2, r|g, g, g|b, g//2|b, b, b|r//2, b|r, b//2|r, r)
}

/**
 * calculates brightness as per Rec 709 Television coefficients.
 * @param color standard RGB color
 * @returns {Number} Value between 0-255. 0-127 is dark, above is bright
 */
getBrightness(color) {
	color := Integer(color)
	r := (color & 0xFF0000) >> 16
	g := (color & 0xFF00) >> 8
	b := (color & 0xFF)
	return 0.2126 * r + 0.7152 * g + 0.0722 * b
}

isDark(color) {
	return getBrightness(color) < 128
}

/**
 * given color in (A)RGB/(A)BGR format, reverse formats and add or remove alpha value. set alpha to -1 to remove
 * @param {Integer} clr 
 * @param {Integer} reverse 
 * @param {Integer} alpha 
 */
format_argb(color, reverse := true, alpha?) {
	color := Integer(color)
	if (reverse)
		color := (color & 0xFF) << 16 | (color & 0xFF00) | ((color & 0xFF0000) >> 16)
	;	clr := (clr >> 16 & 0xFF) | (clr & 0xFF00) | (clr << 16 & 0xFF0000) ; equivalent to above
	clrAlpha := IsSet(alpha) ? (alpha == -1 ? 0 : alpha): (color & 0xFF000000) >> 24
	return (clrAlpha << 24 | color)
}

; 0xFF00F9
colorPreviewGUI(color) {
	if (!RegexMatch(color, "(?:0x)?[[:xdigit:]]{1,6}"))
		return
	CoordMode("Mouse")
	MouseGetPos(&x, &y)
	colorPreview := Gui("+AlwaysOnTop +LastFound +ToolWindow -Caption")
	colorPreview.BackColor := color
	colorPreview.Show("x" . x-30 . " y" . y-30 . "w50 h50 NoActivate")
	SetTimer((*) => colorPreview.Destroy(), -1500)
}

timedTooltip(text := "", durationMS := 1000, x?, y?, whichTooltip?) {
	ToolTip(text, x?, y?, whichTooltip?)
	SetTimer(IsSet(whichTooltip) ? stopTooltip.bind(whichTooltip) : stopTooltip, -durationMS)

	stopTooltip(whichTooltip?) {
		ToolTip(, , , whichTooltip?)
	}
}


; parse options string into the msgboxasgui options
; MsgBoxAsGuiO(text := "Press OK to continue", title := A_ScriptName, options := "0", funcObj?) {

; 	MsgBoxAsGui(text, title, buttonStyle, defaultButton, wait, funcObj?, owner?, addCopyButton, buttonNames, icon?, timeout?, maxCharsVisible?, maxTextWidth)
; 	/*
;     Icon
; 	static Error      => 0x10
; 	static Question   => 0x20
; 	static Warning    => 0x30
; 	static Info       => 0x40

;     static Default2       => 0x100
;     static Default3       => 0x200
;     static Default4       => 0x300

;     static SystemModal    => 0x1000
;     static TaskModal      => 0x2000
;     static AlwaysOnTop    => 0x40000

;     static HelpButton     => 0x4000
;     static RightJustified => 0x80000
;     static RightToLeft    => 0x100000
; 	*/
; }

MsgBoxAsGui(text := "Press OK to continue", title := A_ScriptName, buttonStyle := 0, defaultButton := 1, wait := false, funcObj?, owner?, addCopyButton := 0, buttonNames := [], icon?, timeout?, maxCharsVisible?, maxTextWidth?) {
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
		DEFAULT_ICONS["MB_ICONHANDERROR"], "*16",
		DEFAULT_ICONS["MB_ICONQUESTION"], "*32",
		DEFAULT_ICONS["MB_ICONEXCLAMATION"], "*48",
		DEFAULT_ICONS["MB_ICONASTERISKINFO"], "*64"
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
	static MB_FONTNAME, MB_FONTSIZE, MB_FONTWEIGHT, MB_FONTISITALIC
	static MB_HASFONTINFORMATION := getMsgBoxFontInfo(&MB_FONTNAME, &MB_FONTSIZE, &MB_FONTWEIGHT, &MB_FONTISITALIC)

	static gap := 26			; Spacing above and below text in top area of the Gui
	static buttonMargin := 12	; Left Gui margin
	static rightMargin := 8		; Space between right side of button and next button / gui edge
	static buttonWidth := 88	; Width of OK button
	static buttonHeight := 26	; Height of OK button
	static buttonOffset := 30	; Offset between the right side of text and right edge of button
	static buttonSpace := buttonWidth + rightMargin
	static leftMargin := 20
	static minGuiWidth := 138	; Minimum width of Gui
	static minTextWidth := 400
	static SS_WHITERECT := 0x0006	; Gui option for white rectangle (http://ahkscript.org/boards/viewtopic.php?p=20053#p20053)
	static NecessaryStyle := 0x94C80000
	static SS_NOPREFIX := 0x80 ; no ampersand nonsense
	
	static WM_KEYDOWN := 0x0100
	static WM_RBUTTONDOWN := 0x0204
	
	if BUTTON_STYLE_ALIASES.Has(buttonStyle)
		buttonStyle := BUTTON_STYLE_ALIASES[buttonStyle]
	if (buttonNames.Length == 0) {
		if !(MB_BUTTON_TEXT.Has(buttonStyle + 1)) ; offset since this is not 0-indexed
			throw Error("Invalid button Style")
		buttonNames := MB_BUTTON_TEXT[buttonStyle + 1]
	}
	retValue := ""
	totalButtonWidth := buttonSpace * (buttonNames.Length + (addCopyButton ? 1 : 0))
	ownerStr := IsSet(owner) ? "+Owner" owner : ''
	guiFontOptions := MB_HASFONTINFORMATION ? "S" MB_FONTSIZE " W" MB_FONTWEIGHT (MB_FONTISITALIC ? " italic" : "") : ""
	mbGui := Gui("+ToolWindow -Resize -MinimizeBox -MaximizeBox " ownerStr, title)
	mbGui.OnEvent("Close", finalEvent.bind(0))
	mbGui.Opt("+" Format("0x{:X}", NecessaryStyle))
	mbGui.Opt("-ToolWindow")
	if (buttonStyle == 2 || buttonStyle == 4) ; if cancel is not present in option, close and escape have no effect. user must select an option.
		mbGui.Opt("-SysMenu")
	mbGui.SetFont(guiFontOptions, MB_FONTNAME)
	if IsObject(text)
		text := toString(text, 0, 0, true)
	if !IsSet(maxTextWidth) {
		maxTextWidth := Max(minTextWidth, totalButtonWidth)
		lens := strGetSplitLen(IsSet(maxCharsVisible) ? SubStr(text, 1, maxCharsVisible) : text, "`n")
		minim := min(lens*), maxim := max(lens*), avg := objGetAverage(lens)
		if (2 * avg > maxim && maxim < 1500)
			maxTextWidth := Max(minTextWidth, maxim)
		if StrLen(text) > 10000 && !IsSet(maxCharsVisible)
			maxTextWidth := 1500
	}
	ctrlText := textCtrlAdjustSize(maxTextWidth,, IsSet(maxCharsVisible) ? SubStr(text, 1, maxCharsVisible) : text,, guiFontOptions, MB_FONTNAME)
	mbGui.AddText("x0 y0 vWhiteBoxTop " SS_WHITERECT, ctrlText)
	if (IsSet(icon)) {
		iconPath := icon is Array ? icon[2] : "imageres.dll"
		icon := (icon is Array ? icon[1] : icon)
		icon := DEFAULT_ICONS.Has(icon) ? DEFAULT_ICONS[icon] : icon
		mbGui.AddPicture(Format("x{} y{} w{} h{} Icon{} BackgroundTrans", leftMargin, gap-9, 32, 32, icon), iconPath)
		ICON_SOUNDS.Has(icon) ? SoundPlay(ICON_SOUNDS[icon], 0) : 0
	}
	mbGui.AddText("x" leftMargin + (IsSet(icon) ? 32 + buttonMargin : 0) " y" gap " BackgroundTrans " SS_NOPREFIX " vTextBox", ctrlText)
	mbGui["TextBox"].GetPos(&TBx, &TBy, &TBw, &TBh)
	guiWidth := buttonMargin + buttonOffset + Max(TBw, totalButtonWidth) + 1
	guiWidth := Max(guiWidth, minGuiWidth)
	whiteBoxHeight := TBy + TBh + gap
	mbGui["WhiteBoxTop"].Move(0, 0, guiWidth, whiteBoxHeight)
	buttonX := guiWidth - totalButtonWidth ; the buttons are right-aligned
	buttonY := whiteBoxHeight + buttonMargin
	for i, e in buttonNames
		btn := mbGui.AddButton(Format("vButton{} x{} y{} w{} h{}", i, buttonX + (i-1) * buttonSpace, buttonY, buttonWidth, buttonHeight), e).OnEvent("Click", finalEvent.bind(i))
	if (addCopyButton)
		btn := mbGui.AddButton(Format("vButton0 x{} y{} w{} h{}", buttonX + buttonNames.Length * buttonSpace, buttonY, buttonWidth, buttonHeight), "Copy").OnEvent("Click", (guiCtrl, infoObj) => (A_Clipboard := text))
	defaultButton := defaultButton == "Copy" ? 0 : defaultButton
	mbGui["Button" defaultButton].Focus()
	guiHeight := whiteBoxHeight + buttonHeight + 2 * buttonMargin
	if (buttonStyle != 2 && buttonStyle != 4)
		mbGui.OnEvent("Escape", finalEvent.bind(0))
	mbGui.OnEvent("Close", finalEvent.bind(0))
	OnMessage(WM_KEYDOWN, guiNotify)
	OnMessage(WM_RBUTTONDOWN, guiNotify)
	mbGui.Show("Center w" guiWidth " h" guiHeight)
	if IsSet(timeout)
		SetTimer(timeoutFObj := finalEvent.bind(-1), -1000 * timeout)
	if (wait) {
		WinWait(hwnd := mbGui.hwnd)
		WinWaitClose(hwnd)
		mbGui := 0
		OnMessage(WM_KEYDOWN, guiNotify, 0) ; unregister
		OnMessage(WM_RBUTTONDOWN, guiNotify, 0)
		return retValue
	}
	return mbGui

	finalEvent(buttonNumber, *) {
		mbGui.Destroy()
		mbGui := 0
		OnMessage(WM_KEYDOWN, guiNotify, 0) ; unregister
		OnMessage(WM_RBUTTONDOWN, guiNotify, 0)
		if (IsSet(timeout))
			SetTimer(timeoutFObj, 0)
		retValue := buttonNumber == -1 ? "Timeout" : buttonNumber == 0 ? "Cancel" : buttonNames[buttonNumber]
		if (IsSet(funcObj))
			funcObj(retValue)
	}

	guiNotify(wParam, lParam, msg, hwnd) {
		if (!mbGui) {
			OnMessage(WM_KEYDOWN, guiNotify, 0) ; unregister
			OnMessage(WM_RBUTTONDOWN, guiNotify, 0)
		} else if ((ctrl := GuiCtrlFromHwnd(hwnd)) && (ctrl.gui.hwnd == mbGui.hwnd)) || (hwnd == mbGui.hwnd) {
			if (msg == WM_KEYDOWN) && (wParam == 67) && GetKeyState("Ctrl") {
				A_Clipboard := text
				return 0 ; prevents sound
			} else if !ctrl {
				m := Menu()
				m.Add("Select Text", guiContextMenu)
				m.show()
			}
		}
	}

	guiContextMenu(itemName, itemPos, menuObj) {
		miniGui := Gui("+ToolWindow -Resize -MinimizeBox -MaximizeBox +Owner" mbGui.hwnd, "Select and Copy")
		miniGui.Opt("+" Format("0x{:X}", NecessaryStyle))
		miniGui.Opt("-ToolWindow")
		miniGui.OnEvent("Escape", (*) => miniGui.destroy())
		miniGui.OnEvent("Close", (*) => miniGui.destroy())
		miniGui.MarginX := miniGui.MarginY := 2
		miniGui.SetFont(guiFontOptions, MB_FONTNAME)
		miniGui.AddEdit("-E0x200 ReadOnly w" guiWidth " h" whiteBoxHeight, text)
		miniGui.show()
	}
}



getMsgBoxFontInfo(&name := "", &size := 0, &weight := 0, &isItalic := 0) {
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
		return false                               ; Return false
	name   := StrGet(NCM.Ptr + MsgFont_Offset + FaceName_Offset, FACESIZE)          ; Get the font name
	height := NumGet(NCM.Ptr + MsgFont_Offset + Height_Offset, "Int")               ; Get the font height
	size   := DllCall("MulDiv", "Int", -Height, "Int", 72, "Int", A_ScreenDPI)   ; Convert the font height to the font size in points
	; Reference: http://stackoverflow.com/questions/2944149/converting-logfont-height-to-font-size-in-points
	weight   := NumGet(NCM.Ptr + MsgFont_Offset + Weight_Offset, "Int")             ; Get the font weight (400 is normal and 700 is bold)
	isItalic := NumGet(NCM.Ptr + MsgFont_Offset + Italic_Offset, "UChar")           ; Get the italic state of the font
	return true
}


textCtrlAdjustSize(width, textCtrl?, str?, onlyCalculate := false, fontOptions?, fontName?) {
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
			strWidth := guiGetTextSize(textCtrl, fixedWidthLine . line)
			if (pos > 65535)
				break
			if (strWidth[1] <= width)
				fixedWidthLine .= line . substr(fullLine, pos, 1)
			else { ; reached max width, begin new line
				fixedWidthStr .= (fixedWidthStr ? '`n' : '') . fixedWidthLine
				if (guiGetTextSize(textCtrl, line)[1] <= width) {
					fixedWidthLine := line . substr(fullLine, pos, 1)
				} else { ; A_Loopfield is by itself wider than width
					fixedWidthLine := fixedWidthWord := linePart := ""
					loop parse line { ; thus iterate char by char
						curWidth := guiGetTextSize(textCtrl, linePart . A_LoopField)
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
		textCtrl.Move(,,guiGetTextSize(textCtrl, fixedWidthStr)*)
		textCtrl.Value := fixedWidthStr
	}
	return fixedWidthStr
}

guiGetTextSize(txtCtrlObj, str) {
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

scrollbarGetPosition(ctrlHwnd) {
	static SIF_RANGE := 0x01
	static SIF_PAGE := 0x02
	static SIF_POS := 0x04
	static SIF_TRACKPOS := 0x10
	static SIF_ALL := (SIF_RANGE | SIF_PAGE | SIF_POS | SIF_TRACKPOS)
	static SB_HORZ := 0
	static SB_VERT := 1
	static SB_CTL := 2
	static SB_BOTH := 3
	static SB_BOTTOM := 7
	static WM_VSCROLL := 0x115
	
	NumPut("UInt", 28, ScrollInfo := Buffer(28, 0))
	NumPut("UInt", SIF_ALL, ScrollInfo, 4)
	DllCall("GetScrollInfo", "uint", ctrlHwnd, "int", SB_VERT, "Ptr", ScrollInfo)
	nMin := NumGet(ScrollInfo, 8, "int")
	nMax := NumGet(ScrollInfo, 12, "int")
	nPage := NumGet(ScrollInfo, 16, "uint")
	curPos := NumGet(ScrollInfo, 20, "uint")
	return curPos ? curPos / (nMax - nPage + 1 - nMin) : 0
}

structRectCreate(x1, y1, x2, y2) {
	NumPut("UInt", x1, "UInt", y1, "UInt", x2, "UInt", y2, llrectA := Buffer(16, 0), 0)
	return llrectA
}

structRectGet(rect) {
	x1 := NumGet(rect, 0, "int")
	y1 := NumGet(rect, 4, "int")
	x2 := NumGet(rect, 8, "int")
	y2 := NumGet(rect, 12, "int")
	return [x1, y1, x2, y2]
}

base64Encode(str, encoding := "UTF-8") {
	static CRYPT_STRING_BASE64 := 0x00000001
	static CRYPT_STRING_NOCRLF := 0x40000000

	binary := strBuffer(str, encoding)
	if !(DllCall("crypt32\CryptBinaryToStringW", "Ptr", binary, "UInt", binary.Size - 1, "UInt", (CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF), "Ptr", 0, "UInt*", &size := 0))
		throw(OSError())
	base64 := Buffer(size << 1, 0)
	if !(DllCall("crypt32\CryptBinaryToStringW", "Ptr", binary, "UInt", binary.Size - 1, "UInt", (CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF), "Ptr", base64, "UInt*", size))
		throw(OSError())
	return StrGet(base64)
}

base64Decode(base64, encoding := "UTF-8") {
	static CRYPT_STRING_BASE64 := 0x00000001

	if !(DllCall("crypt32\CryptStringToBinaryW", "Str", base64, "UInt", 0, "UInt", CRYPT_STRING_BASE64, "Ptr", 0, "UInt*", &size := 0, "Ptr", 0, "Ptr", 0))
		throw(OSError())
	str := Buffer(size)
	if !(DllCall("crypt32\CryptStringToBinaryW", "Str", base64, "UInt", 0, "UInt", CRYPT_STRING_BASE64, "Ptr", str, "UInt*", size, "Ptr", 0, "Ptr", 0))
		throw(OSError())
	return StrGet(str, "UTF-8")
}

sendRequest(url := "https://icanhazip.com/", method := "GET", encoding := "UTF-8", async := false, callBackFuncObj := "", customHeaders?) {
	static defaultHeaders := Map(
		"User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0 Safari/537.36",
		"Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
		"Accept-Language", "en-US,en;q=0.9",
		"Connection", "keep-alive",
		"Upgrade-Insecure-Requests", "1"
	)
	if (async) {
		if (callBackFuncObj == "")
			throw(ValueError("No callback function provided for async request."))
		whr := ComObject("Msxml2.XMLHTTP")
		whr.Open(method, url, true)
		for i, e in defaultHeaders
			whr.setRequestHeader(i, e)
		if IsSet(customHeaders)
			for i, e in customHeaders
				whr.setRequestHeader(i, e)
		whr.OnReadyStateChange := callBackFuncObj
		whr.Send()
	}
	else
		whr := ComObject("WinHttp.WinHttpRequest.5.1")
	whr.Open(method, url, true)
	for i, e in defaultHeaders
		whr.setRequestHeader(i, e)
	if IsSet(customHeaders)
		for i, e in customHeaders
			whr.setRequestHeader(i, e)
	whr.Send()
	whr.WaitForResponse()
	if !(whr.ResponseBody)
		return ""
	arr := whr.ResponseBody
	pData := NumGet(ComObjValue(arr) + 8 + A_PtrSize, 0, "UPtr")
	length := (arr.MaxIndex() - arr.MinIndex()) + 1
	return Trim(StrGet(pData, length, encoding), "`n`r`t ")
}

tryEditTextFile(editor := A_WinDir . "\system32\notepad.exe", params := "", *) {
	if (InStr(editor, A_Space) && SubStr(editor, 1, 1) != '"' && SubStr(editor, -1, 1) != '"')
		editor := '"' editor '"'
	try
		Run(editor ' ' params)
	catch
		try Run(A_WinDir . '\system32\notepad.exe ' . params)
	; Run('"' A_ProgramFiles . '\Notepad++\notepad++.exe" "' . path '"')
	; Run('Notepad++ "' . path '"')
}

; returns a microseconds-precise float representing to seconds elapsed since start of the system
QPC() {
	static Freq := 0, init := DllCall("QueryPerformanceFrequency", "Int64P", &Freq)
	DllCall("QueryPerformanceCounter", "Int64P", &count := 0)
	Return count / freq
}

doNothing(*) {
	return
}

printAlign(value, width := 128, padChar := ' ') => print(strFill(IsObject(value) ? toString(value) : value, width,,padChar),,,,,,0)
pretty(value, options?, fallbackMsgbox := true) => print(value, options?, true, false, false, true, fallbackMsgbox)

print(value, options?, putNewline := true, compress := true, compact := false, strEscape := true, fallbackMsgbox := true) {
	if IsObject(value)
		value := toString(value, compact, compress, strEscape)
	if (putNewline == true || (putNewline == -1 && InStr(value, '`n')))
		finalChar := '`n'
	else
		finalChar := ''
	try 
		FileAppend(value . finalChar, "*", options ?? "UTF-8")
	catch Error 
		if fallbackMsgbox
			MsgBoxAsGui(value,,,,,,,1)
	return value . finalChar
}

/**
 * tiles given or all windows
 * @param windowArray array of window HWNDs to be tiled
 * @param {Integer} tilingMode 0 or 1, vertical or horizontal
 * @param tileArea Area in which windows will be tiled. Given in the form [x1, y1, x2, y2]
 * @param {Integer} hwndParent HWND of parent window of the windows to be tiled
 * @returns {Integer} Count of tiled windows 
 */
tileWindows(windowArray?, tilingMode := 0x0000, tileArea?, hwndParent := 0)  {
	static MDITILE_VERTICAL 	:= 0x0000
	static MDITILE_HORIZONTAL 	:= 0x0001
	static MDITILE_SKIPDISABLED := 0x0002
	static MDITILE_ZORDER 		:= 0x0004
	flagTileArea := IsSet(tileArea)
	if (flagTileArea)
		lpRect := structRectCreate(tileArea*)
	else
		lpRect := 0
	flagCustomWindows := IsSet(windowArray) && windowArray is Array
	if (flagCustomWindows) {
		cKids := windowArray.Length
		lpKids := Buffer(windowArray.Length * 4) ; sizeof(int) == 4
		for i, hwnd in windowArray
			NumPut("Int", hwnd, lpKids, 4 * (i-1))
	}
	else {
		cKids := 0
		lpKids := 0
	}
	return DllCall("TileWindows", 
		"Int", hwndParent, 
		"UInt", tilingMode, 
		"UInt", flagTileArea ? lpRect.Ptr : 0, 
		"Int", cKids, 
		"Int", flagCustomWindows ? lpKids.Ptr : 0
	)
}