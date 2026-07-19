; https://github.com/cobracrystal/ahk

#Include "External\jsongo.ahk"
#Include "ObjectUtilities.ahk"
#Include "PrimitiveUtilities.ahk"

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
	input .= '#Include "' A_LineFile '\.."`n'
	input .= '#Include "*i BasicUtilities.ahk"`n'
	input .= '#Include "*i MathUtilities.ahk"`n'
	if (void || RegexMatch(expression, 'i)FileAppend\(.*,\s*\"\*\"\)') || RegExMatch(expression, 'i)MsgBox(?:AsGui)?\(.+\)') || RegexMatch(expression, 'i)print(?:\(.*\)|\s+.*)') || RegexMatch(expression, 'i)\.Show\(.*\)') || RegexMatch(expression, 'i)A_Clipboard\s*.?='))
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

runAsAdmin(scriptFile := A_ScriptFullPath) {
	params := ""
	for i, e in A_Args  ; For each parameter:
		params .= A_Space . e
	if !A_IsAdmin
	{
		if A_IsCompiled
			v := DllCall("shell32\ShellExecute", "uint", 0, "str", "RunAs", "str", scriptFile, "str", params, "str", A_WorkingDir, "int", 1)
		else
			v := DllCall("shell32\ShellExecute", "uint", 0, "str", "RunAs", "str", A_AhkPath, "str", '"' . scriptFile . '"' . A_Space . params, "str", A_WorkingDir, "int", 1)
		if (v <= 32)
			return false
		return true
	}
	return true
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

timedTooltip(text := "", durationMS := 1000, x?, y?, whichTooltip?) {
	ToolTip(text, x?, y?, whichTooltip?)
	SetTimer(IsSet(whichTooltip) ? stopTooltip.bind(whichTooltip) : stopTooltip, -durationMS)

	stopTooltip(whichTooltip?) {
		ToolTip(, , , whichTooltip?)
	}
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

sendRequest(url := "https://icanhazip.com/", method := "GET", encoding := "UTF-8", async := false, callBackFuncObj := "", headers?) {
	defaultHeaders := Map()
	defaultHeaders.CaseSense := 0
	defaultHeaders.Set(
		"User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:146.0) Gecko/20100101 Firefox/146.0",
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
		if IsSet(headers) {
			for i, e in headers
				defaultHeaders[i] := e
		}
		for i, e in defaultHeaders
			whr.setRequestHeader(i, e)
		whr.OnReadyStateChange := callBackFuncObj
		whr.Send()
		return whr
	}
	whr := ComObject("WinHttp.WinHttpRequest.5.1")
	whr.Open(method, url, true)
	if IsSet(headers) {
		for i, e in headers
			defaultHeaders[i] := e
	}
	for i, e in defaultHeaders
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

/**
 * Prints text to console
 * @param value What to print. May be object. May have .tostring() method.
 * @param options option string for FileAppend (ie custom encoding)
 * @param {Integer} putNewline Whether to put a final newline
 * @param {Integer} compress Whether to compress a given object via toString
 * @param {Integer} compact Whether to compact a given object via toString
 * @param {Integer} strEscape Whether to escape strings in a given object via toString
 * @param {Integer} fallbackGui 0,1,2: Whether to use a gui if no console is available, or whether to force use the gui (2)
 * @param {Integer} trimEmptyLines Whether to ignore empty lines when printing. Will still print if value is entirely empty
 * @returns {String} 
 */
print(value, options?, putNewline := true, compress := true, compact := false, strEscape := true, fallbackGui := true, trimEmptyLines := true) {
	static guiPrinterInstance := 0
	static lastValue := ""
	if IsObject(value) {
		if value.HasMethod("toString") {
			try value := value.toString()
		} else {
			value := toString(value, compact, compress, strEscape)
		}
	}
	if (putNewline == true || (putNewline == -1 && InStr(value, '`n')))
		finalChar := '`n'
	else
		finalChar := ''
	if trimEmptyLines
		value := RegExReplace(value, "\n\s*$", "")
	if !IsSpace(value)
		lastValue := value
	if fallbackGui == 2 {
		if !WinExist(guiPrinterInstance) {
			guiPrinterInstance := createFallbackGui()
			updateFallbackGui(guiPrinterInstance, "", 1)
		}
		updateFallbackGui(guiPrinterInstance, value . finalChar)
		return value
	}
	try 
		FileAppend(value . finalChar, "*", options ?? "UTF-8")
	catch Error {
		if fallbackGui {
			if !WinExist(guiPrinterInstance) {
				guiPrinterInstance := createFallbackGui()
				updateFallbackGui(guiPrinterInstance, "", 1)
			}
			updateFallbackGui(guiPrinterInstance, value . finalChar)
			; MsgBoxAsGui.fromConfig({
			; 	text: str,
			; 	addCopyButton: true
			; })
		}
	}
	return value

	createFallbackGui() {
		g := Gui('+Resize', 'Printer')
		g.MarginX := g.MarginY := 0
		g.SetFont('s12', 'Calibri')
		g.AddText('Section x10 y10 w80 vPrints', 'Prints:    0')
		g.AddText('x+5 yp w100 R1 vEmptyLines Hidden', '(0 Empty)')
		cEdit := g.AddEdit('xm ys+30 w600 h400 vEdit ReadOnly')
		cEdit.GetPos(, &y := unset)
		g.AddButton("ys-7 x194 R1 w200", "Copy Full Output").OnEvent("Click", copyAll.bind(g))
		g.AddButton("ys-7 x398 R1 w200", "Copy Last Output").OnEvent("Click", copyValue.bind(g))
		g.OnEvent('Size', (o, m, w, h) => cEdit.Move(, , w, h - y))
		g.OnEvent('Escape', (*) => guiPrinterInstance := 0)
		g.OnEvent('Close', (*) => guiPrinterInstance := 0)
		g.show()
		return g
	}

	copyValue(g,*) => A_Clipboard := lastValue
	copyAll(g,*) => A_Clipboard := g["Edit"].Value

	updateFallbackGui(g, line, reset := 0) {
		static fullOutput := ""
		if reset {
			fullOutput := ""
			g["Prints"].Value := 0
			return
		}
		if IsSpace(line) {
			RegExMatch(g["EmptyLines"].Value, "(\d+)", &o)
			g["EmptyLines"].Value := Format("({} Empty)", Integer(o[1]) + 1)
			if o[1] == "0"
				g["EmptyLines"].Opt("-Hidden")
		}
		fullOutput .= line
		RegExMatch(g["Prints"].Value, "(\d+)", &o)
		g["Prints"].Value := Format("Prints:  {:3}", Integer(o[1]) + 1)
		g["Edit"].Value := fullOutput
	}

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