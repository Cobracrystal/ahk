; ###########################################################################
; ############################# INITIALIZATION ##############################
; ###########################################################################
#Requires AutoHotkey 2
#SingleInstance Force
#UseHook
KeyHistory(500)
InstallKeybdHook(true, true)
; Set Correct Working Dir
if !InStr(FileExist(A_ScriptDir "\script_files\everything"), "D")
	DirCreate("script_files\everything")
SetWorkingDir(A_ScriptDir . "\script_files")
TraySetIcon(A_WorkingDir "\everything\Icons\Potet Think.ico", , true)
OnExit(customExit)
Hotstring("EndChars", "-()[]{}:;`'`"/\,.?!" . A_Space . A_Tab)

GLOBALVAR_WASRELOADED := (InStr(DllCall("GetCommandLine", "str"), "/restart") ? true : false)

; Delete Tray Menu Items before including files that may modify them
A_TrayMenu.Delete()

#Include "%A_ScriptDir%\LibrariesV2"
#Include "TransparentTaskbar.ahk"
#Include "HotkeyManager.ahk"
#Include "WindowManager.ahk"
#Include "ReminderManager.ahk"
#Include "YoutubeDLGui.ahk"
#Include "SongDownloader.ahk"
#Include "TextEditMenu.ahk"
#Include "MacroRecorder.ahk"
#Include "TimestampConverter.ahk"
#Include "FolderSwitch.ahk"
#Include "AltDrag.ahk"
#Include "MathUtilities.ahk"
#Include "BasicUtilities.ahk"
#Include "HotstringLoader.ahk"
#Include "TableFilter v2.ahk"
#Include "openDTU.ahk"
#Include "DiscordClient.ahk"
; #Include "%A_ScriptDir%\not_mine_or_examples\AquaHotkey\AquaHotkey.ahk"
; #Include "jsongo.ahk"
; for windows in which ctrl+ should replace scrolling
GroupAdd("zoomableWindows", "ahk_exe Mindustry.exe")
; for windows that should be put in the corner when ctrlaltI'd
GroupAdd("cornerMusicPlayers", "VLC media player ahk_exe vlc.exe", , "Wiedergabeliste")
GroupAdd("cornerMusicPlayers", "Daum PotPlayer ahk_exe PotPlayerMini64.exe", , "Einstellungen")
GroupAdd("cornerMusicPlayers", "foobar2000 ahk_exe foobar2000.exe", , "Scratchbox")
; for windows that i don't want to see
GroupAdd("instantCloseWindows", "ahk_class RarReminder")
GroupAdd("instantCloseWindows", "Please purchase WinRAR license ahk_class #32770")
GroupAdd("instantCloseWindows", "pCloud Promо ahk_exe pCloud.exe") ; THE SECOND O IS CYRILLIC
GroupAdd("nonMenuWindows", "ahk_exe cs2.exe")
GroupAdd("nonMenuWindows", "Satisfactory ahk_class UnrealWindow")
GroupAdd("nonMenuWindows", "Little Witch Nobeta ahk_exe LittleWitchNobeta.exe")
remInst := ReminderManager(, , token := Trim(FileRead(A_WorkingDir . "\discordBot\discordBotToken.token", "UTF-8")))
try remInst.importReminders(A_WorkingDir . "\Reminders\reminders.json", GLOBALVAR_WASRELOADED, remInst.discordReminder.bind(remInst, "245189840470147072"))
; reminders.setPeriodicTimerOn(parseTime(, , , 3, 30, 0), 1, "Days", "Its 3:30, Go Sleep", remInst.discordReminder.bind(0, token, "CHANNELID"))
; reminders.exportReminders(A_WorkingDir . "\Reminders\reminders2.json")
; Launch Transparent Taskbar at 50ms frequency
if (StrCompare(A_OSVersion, "10.0.22000") < 0) {
	TransparentTaskbar.setMode(4, 2, 50)
	TransparentTaskbar.setTimer(1)
}
; Start keeping track of desktop window changes
WindowManager.DesktopState.enable(60000)
; import custom blacklist into AltDrag
AltDrag.addBlacklist([
	"Satisfactory ahk_class UnrealWindow",
	"DriveBeyondHorizons ahk_exe DriveBeyondHorizons-Win64-Shipping.exe",
	"Minecraft ahk_exe javaw.exe",
	"Terraria Terraria.exe",
	"Leaf Blower Revolution",
	"Split Fiction SplitFiction.exe"
])
; Start Loop to close winrar popups
SetTimer(closeWinRarNotification, -100, -1000) ; priority -100k so it doesn't interrupt
; Initialize Internet Logging Script
internetConnectionLogger("Init")
openDTUScript("Init")
openDTUman := openDTU("http://192.168.178.48", 80, "admin", FileRead(A_Desktop "\programs\Files\openDTUAuth.pw"))
; Load LaTeX Hotstrings
; TODO: ADD WINDOW OPTION FOR HOTSTRINGLOADER. IE GIVEN AHK CRITERIA IT ADDS HOTIF BEFORE REGISTERING THEM (makes editing harder tho)
try HotstringLoader.load(A_WorkingDir "\everything\LatexHotstrings.json", "LaTeX",,,false)
expressionCalculator.setWolframAlphaToken(FileRead(A_WorkingDir "\everything\wolframalphaQueries.token", "UTF-8"))
; loadTableAsHotstrings(A_WorkingDir "\TableFilter\Kayoogis.json")
; replace the tray menu with my own
customTrayMenu()
; Synchronize nextDNS IP
if (!GLOBALVAR_WASRELOADED)
	connectNextDNS()
; ###########################################################################
; ############################# CONTROL HOTKEYS #############################
; ###########################################################################

#SuspendExempt true
^+R:: { ; Reload Script
	Reload()
}

; ^!+Ä:: {	; Reload other script
; 	DetectHiddenWindows("On")
; 	PostMessage(0x111, 65303, , , A_ScriptHwnd)
; }
 
^+!S::{	; Suspend All Other Hotkeys
	TrayMenu.submenus["SuspendMenu"].ToggleCheck("Suspend Hotkeys")
	Suspend(-1) ; async bad, no postmessage
	if (A_IsSuspended)
		TraySetIcon(A_WorkingDir "\everything\Icons\Potet Think Warn.ico", , true)
	else
		TraySetIcon(A_WorkingDir "\everything\Icons\Potet Think.ico", , true)
}

#SuspendExempt false

#HotIf !WinActive("ahk_group nonMenuWindows")
^+LButton:: {	; Text Modification Menu
	TextEditMenu.ShowMenu()
}
#HotIf

^U:: {	; Time/Date Converter
	TimestampConverter.textTimestampConverter()
}

^q:: {
	FolderSwitch.showMenu()
}


^!I:: {	; Show Hex code as Color
	colorPreviewGUI(fastCopy())
}

^!+NumpadSub:: {	; Record Macro
	MacroRecorder.createMacro(A_ThisHotkey)
}

#g::Run("notepad.exe")

^F12:: { ; Toggle Hotkey Manager
	HotkeyManager.hotkeyManager("T")
}

^F11:: { ; Shows a list of all Windows
	WindowManager.windowManager("T") ; this is actually decorative and only for hotkeymanager
}

^F10::{	; Shows DTU Script
	openDTUScript("T")
}

^F9:: {	; Shows Internet Connection
	internetConnectionLogger("T")
}

^F8:: {	; Shows Reminder GUI
	remInst.ReminderManagerGUI("T")
}

^+K:: { ; Toggle Taskbar Transparency
	TransparentTaskbar.setTimer("T")
}

^+F11:: { ; Gives Key History
	DetectHiddenWindows(1)
	KeyHistory()
	;	PostMessage(0x111, 65409,,, A_ScriptHwnd) ; this works too???
}

^+F10:: {	; YTDL GUI
	static youtubeDL := YoutubeDLGui()
	youtubeDL.YoutubeDLGui("T")
}

^!Numpad0:: {	; Toggle NumpadKeys to Move Cursor
	toggleNumpadMouseMove()
}

^!+F11:: { ; Block keyboard input until password "password123" is typed
	if !(runAsAdmin())
		return
	password := "password123"
	for key in ["CTRL", "SHIFT", "ALT"]
		KeyWait(key)
	BlockInput(1)
	hook := InputHook("C*", , password)
	hook.Start()
	hook.Wait()
	BlockInput(0)
}

^!K:: { 	; Evaluate Shell Expression in-text
	expressionCalculator.calculateExpression("p")
}
; ###########################################################################
; ######################### DESKTOP-RELATED HOTKEYS #########################
; ###########################################################################

!LButton:: {	; Drag Window
	AltDrag.moveWindow()
}

!RButton:: {	; Resize Window
	AltDrag.resizeWindow()
}

!MButton:: {	; Toggle Max/Restore of clicked window
	AltDrag.toggleMaxRestore()
}

!WheelDown:: {	; Scale Window Down
	AltDrag.scaleWindow(-1)
}

!WheelUp:: {	; Scale Window Up
	AltDrag.scaleWindow(1)
}

!XButton1:: {	; Minimize Window
	AltDrag.minimizeWindow()
}

^!XButton1:: {	; Minimize Window (no blacklist)
	AltDrag.minimizeWindow(true)
}

!XButton2:: {	; Borderless Fullscreen Window
	AltDrag.borderlessFullscreenWindow()
}

^NumpadSub:: { ; Clip mouse to active windows client area
	static toggle := 0
	if (toggle := !toggle)
		clipCursor(1)
	else
		clipCursor(0)
}

^NumpadDiv:: {	; Show Mouse Coordinates
	static toggle := false
	if (toggle := !toggle)
		SetTimer(showcoords, 50)
	else {
		SetTimer(showcoords, 0)
		Tooltip()
	}
}

Alt & Capslock::{
	m := Menu()
	windows := WinUtilities.getAllWindowInfo()
	for e in windows
		m.Add("&" e.title, (i,p,m) => WinActivate(windows[p]))
	m.show()
}

^!H:: {	; Change Window Shape
	static toggle := false, shapedWindow, depth := 5
	if (toggle := !toggle) {
		MouseGetPos(&xPosCircle, &yPosCircle, &shapedWindow)
		WinGetPos(&x, &y, &w, &h, shapedWindow)
		; xPosCircle -= 100
		; yPosCircle -= 100
		;	WinSetRegion(xPosCircle "-" yPosCircle " w200 h200 E", circleWindow)
		;	duoRect := "200-200 1500-200 1500-900 200-900 200-550 850-200 1500-550 850-900 200-550"
		str := sierpinskiCoords(w // 2, 50, w - 50, h - 60, depth := Mod(depth + 1, 6))
		WinSetStyle("-0xC00000", shapedWindow)
		WinSetAlwaysOnTop(1, shapedWindow)
		WinSetRegion(str, shapedWindow)
	}
	else {
		WinSetRegion(, shapedWindow)
		WinSetStyle("+0xC00000", shapedWindow)
		WinSetAlwaysOnTop(0, shapedWindow)
	}
}

^!+J:: { ; Tiles Windows Vertically
	static windowInfo, tileState := false
	if (tileState := !tileState) {
		WindowManager.DesktopState.save("TilingState")
		shell := ComObject("Shell.Application")
		switch MsgBoxAsGui("Tile Windows?", "Confirm Dialog", 0x7, 4, true,,,, ["Vertically", "Horizontally", "Cascade", "No"]) {
			case "Vertically":
				list := WinUtilities.getAllWindowInfo()
				objRemoveValue(list,,,(key,a,b) => (WinGetMinMax(a) == -1))
				; msgbox(ToString(list, false))
				; Loop(list.Length) {
				; 	a := 5
				; }
				; algorithm: for the number of windows we have, calculate the best integer multiplication (eg for 27: 7x4)
				; then try both orientations (eg 7x4, 4x7), and choose the one where the calculated width/height ratio for the windows
				; is smaller (as in, more quadratic).
				; then, for the final column, extend the height so that the windows fit in anyway
				shell.TileVertically()
			case "Horizontally":
				shell.TileHorizontally()
			case "Cascade":
				shell.CascadeWindows()
			case "No":
				return
		}
	}
	else if MsgBoxAsGui("Restore Previous State?", "Confirm Dialog", 0x1,,true) == "OK"
		WindowManager.DesktopState.restore("TilingState")
}

^!+L:: { ; save / restore desktop state
	WindowManager.DesktopState.restore()
}


^!+I:: { ; Center & Adjust Active Window
	if WinActive("ahk_group cornerMusicPlayers")
		WinMove(-600, 550, 515, 550)
	else if WinActive("Discord ahk_exe Discord.exe")
		WinMove(-1497, 129, 1292, 769)
	else
		WinUtilities.resetWindowPosition(,5/7)
}

^!+H:: { ; Make Active Window Transparent
	static toggle := false
	WinSetTransparent((toggle := !toggle) ? 120 : "Off", "A")
}

^+H:: { ; Make Taskbar invisible
	TransparentTaskbar.setInvisibility("T", 0)
}

^+!K:: { ; Show/Hide Taskbar
	static hide := false
	TransparentTaskbar.hideShowTaskbar(hide := !hide)
}

; ###########################################################################
; ######################## DESKTOP-RELATED FUNCTIONS ########################
; ###########################################################################

toggleNumpadMouseMove() {
	static init := 0
	static keyMap := { 
		moveKeys: Map("Numpad1", [-1,1], "Numpad2", [0,1], "Numpad3", [1,1], "Numpad4", [-1,0], "Numpad6", [1,0], "Numpad7", [-1,-1], "Numpad8", [0,-1], "Numpad9", [1,-1]), 
		clickKeys: Map("Numpad5", ["L", 0], "NumpadEnter", ["L", 0], "NumpadAdd", ["L", 1], "NumpadSub", ["R", 0], "NumpadMult", ["M", 0], "NumpadDiv", ["M", 1])
	}
	if !(init) {
		for i, e in keyMap.moveKeys
			Hotkey("*" i, moveMousePixel.bind(e*))
		for i, e in keyMap.clickKeys
			Hotkey("*" i, clickMouse.bind(e*))
		init := 1
		return
	}
	for i, e in keyMap.moveKeys
		Hotkey("*" i, "Toggle")
	for i, e in keyMap.clickKeys
		Hotkey("*" i, "Toggle")
}

moveMousePixel(x, y, *) {
	MouseMove(x, y, 0, "R")
}

clickMouse(b, hold := 0, *) {
	b := SubStr(b, 1, 1)
	if (hold)
		st := GetKeyState(b . "Button") ? "U" : "D"
	MouseClick(b, , , , , st?)
}

closeWinRarNotification() {
	Loop {
		WinWait("ahk_group instantCloseWindows")
		WinClose("ahk_group instantCloseWindows")
	}
}

showcoords() {
	CoordMode("Mouse", "Screen")
	try {
		MouseGetPos(&ttx, &tty, &ttWin)
		ttc := PixelGetColor(ttx, tty)
		ttWinT := WinGetTitle(ttWin)
		Tooltip(ttx ", " tty ", " ttc "`n" ttWinT)
	}
}

winSlowMove(hwnd, endX := "", endY := "", endW := "", endH := "", speed := 1) {
	WinDelay := A_WinDelay
	SetWinDelay(-1)
	mmx := WinGetMinMax(hwnd)
	if (mmx == 1 || mmx == -1)
		return
	if (endX == "" && endY == "" && endW == "" && endH == "")
		return
	WinGetPos(&iniX, &iniY, &iniW, &iniH, hwnd)
	if (speed == 0) {
		WinMove(endX, endY, endW, endH, hwnd)
	} else {
		iter := Ceil(((endX != "" ? Abs(iniX - endX) : 0) + (endY != "" ? Abs(iniY - endY) : 0) + (endW != "" ? Abs(iniW - endW) : 0) + (endH != "" ? Abs(iniH - endH) : 0)) / (speed))
		tX := (endX != "" ? (endX - iniX) : 0)
		tY := (endY != "" ? (endY - iniY) : 0)
		tW := (endW != "" ? (endW - iniW) : 0)
		tH := (endH != "" ? (endH - iniH) : 0)
		Loop (iter)
		{
			sT := (1 - cos(A_Index / iter * 3.1415926)) / 2
			try WinMove(iniX + tX * sT, iniY + tY * sT, iniW + tW * sT, iniH + tH * sT, hwnd)
			catch
				break
		}
	}
	SetWinDelay(WinDelay)
}

slowClose(wHandle, HeightStep := 100, WidthStep := 100) {
	WinGetPos(&x, &y, &w, &h, wHandle)
	Step := (h - 3) / HeightStep
	Step2 := (w - 3) / WidthStep
	Loop (heightStep)
		WinMove(, y := y + (Step / 2), , h := h - Step, wHandle)
	WinSetStyle("-0xC00000", wHandle)
	WinRedraw(wHandle)
	Loop (WidthStep)
		WinMove(x := x + (Step2 / 2), , w := w - Step2, , wHandle)
	WinClose(wHandle)
}

sierpinskiCoords(x, y, width, height, depth) {
	; height := Integer(Round(sqrt(3)/2 * width))
	if (depth == 0)
		return Format("{}-{} {}-{} {}-{} {}-{} ", x, y, x + width // 2, y + height, x - width // 2, y + height, x, y)
	str := sierpinskiCoords(x, y, width // 2, height // 2, depth - 1) . x "-" y " "
	str .= sierpinskiCoords(x + width // 4, y + height // 2, width // 2, height // 2, depth - 1) . x "-" y " "
	str .= sierpinskiCoords(x - width // 4, y + height // 2, width // 2, height // 2, depth - 1) . x "-" y " "
	return str
}

clipCursor(mode := true, window := "A") {
	WinGetClientPos(&wx, &wy, &ww, &wh, WinExist(window))
	if (!mode)
		return !DllCall("ClipCursor", "Ptr", 0)
	NumPut("UInt", wx, "UInt", wy, "UInt", wx + ww, "UInt", wy + wh, llrectA := Buffer(16, 0), 0)
	return DllCall("ClipCursor", "Ptr", llrectA)
}

; ###########################################################################
; ########################## OS-RELATED FUNCTIONS ###########################
; ###########################################################################

runAsAdmin() {
	params := ""
	for i, e in A_Args  ; For each parameter:
		params .= A_Space . e
	if !A_IsAdmin
	{
		if A_IsCompiled
			v := DllCall("shell32\ShellExecute", "uint", 0, "str", "RunAs", "str", A_ScriptFullPath, "str", params, "str", A_WorkingDir, "int", 1)
		else
			v := DllCall("shell32\ShellExecute", "uint", 0, "str", "RunAs", "str", A_AhkPath, "str", '"' . A_ScriptFullPath . '"' . A_Space . params, "str", A_WorkingDir, "int", 1)
		if (v <= 32)
			return false
		return true
	}
	return true
}

connectNextDNS() {
	try 
		return sendRequest("https://link-ip.nextdns.io/" FileRead(A_WorkingDir "\everything\nextDNS_Link.id"))
	catch as e
		return "Could not connect to NextDNS. Error:`n" e.What "`n" e.Extra
}

internetConnectionLogger(mode := "T") {
	static internetConsolePID
	static logfile := A_WorkingDir "\everything\connectionlog.txt"
	DetectHiddenWindows(1)
	flagExist := WinExist("INTERNET_LOGGER ahk_exe cmd.exe")
	DetectHiddenWindows(0)
	flagVisible := WinExist("INTERNET_LOGGER ahk_exe cmd.exe")
	mode := SubStr(mode, 1, 1)
	if (mode == "T")
		mode := (flagVisible ? "C" : "O")
	if (mode == "C" && flagExist) {
		WinHide("ahk_pid " . internetConsolePID)
		return
	}
	DetectHiddenWindows(1)
	if (flagExist)
		internetConsolePID := WinGetPID("ahk_id " flagExist)
	else {
		str := A_ComSpec . ' /c "pwsh ' A_WorkingDir '\everything\internetLogger.ps1 -path "' . logFile . '""'
		Run(str, , "Hide", &internetConsolePID)
		if !(WinWait("ahk_pid " internetConsolePID, , 1))
			return
		WinSetAlwaysOnTop(1, "ahk_pid " internetConsolePID)
		WinSetStyle(-0x70000, "ahk_pid " internetConsolePID)
	}
	fileMenu := TrayMenu.submenus["Files"]
	fileMenu.Add("Open Internet Log", tryEditTextFile.bind("notepad++", '"' logFile '"'))
	A_TrayMenu.Add("Files", fileMenu)
	DetectHiddenWindows(0)
	if (mode == "O")
		WinShow("ahk_pid " . internetConsolePID)
	return
}

openDTUScript(mode := "T") {
	static consolePID
	static dtuConsoleTitle := "openDTU NetZero"
	static dtuDirectory := A_Desktop "\programs\programming\Python\openDTU\openDTU"
	static dtuScript := "openDTU-NetZeroInput.py"
	static consoleString := Format('{} /c "title={} && mode con: cols=80 lines=16 && cd "{}" && python {}"', 
			A_ComSpec, 
			dtuConsoleTitle, 
			dtuDirectory, 
			dtuScript
		)
	DetectHiddenWindows(1)
	flagExist := WinExist(dtuConsoleTitle " ahk_exe cmd.exe")
	DetectHiddenWindows(0)
	flagVisible := WinExist(dtuConsoleTitle " ahk_exe cmd.exe")
	mode := SubStr(mode, 1, 1)
	if (mode == "T")
		mode := (flagVisible ? "C" : "O")
	if (mode == "C" && flagExist) {
		WinHide("ahk_pid " . consolePID)
		return
	}
	DetectHiddenWindows(1)
	if (flagExist)
		consolePID := WinGetPID("ahk_id " flagExist)
	else {
		Run(consoleString, , "Hide", &consolePID)
		if !(WinWait("ahk_pid " consolePID, , 2))
			return
		WinSetAlwaysOnTop(1, "ahk_pid " consolePID)
		WinSetStyle(-0x70000, "ahk_pid " consolePID)
	}
	DetectHiddenWindows(0)
	if (mode == "O")
		WinShow("ahk_pid " . consolePID)
	return
}

; ^j:: { ; this doesn't work
;	static init := false
;	if (!init) {
;		SystemCursor("I")
;		init := true
;	}
;	SystemCursor(-1)
; }

; doesn't work right now
SystemCursor(mode := 1) {   ;// stolen from https://www.autohotkey.com/boards/viewtopic.php?t=6167
	;// INIT = "I"/"Init", OFF = 0/"Off", TOGGLE = -1/"T"/"Toggle", ON = 1
	static AndMask, XorMask, h_cursor, c := [], b := [], h := [], flag := true
	; c = system cursors, b = blank cursors, h = handles of default cursors
	if (SubStr(mode, 1, 1) = "I" || c.Length == 0) {       ; init when requested or at first call
		h_cursor := Buffer(4444, 1)
		andMask := Buffer(32 * 4, 0xFF)
		XOrMask := Buffer(32 * 4, 0)
		system_cursors := [32512, 32513, 32514, 32515, 32516, 32642, 32643, 32644, 32645, 32646, 32648, 32649, 32650]
		for i, e in system_cursors {
			h_cursor := DllCall("LoadCursor", "Ptr", 0, "Ptr", e)
			h.push(DllCall("CopyImage", "Ptr", h_cursor, "UInt", 2, "Int", 0, "Int", 0, "UInt", 0))
			b.push(DllCall("CreateCursor", "Ptr", 0, "Int", 0, "Int", 0, "Int", 32, "Int", 32, "Ptr", andMask, "Ptr", XorMask))
		}
	}
	if (mode == 0 || (flag && mode == -1))
		c := b, flag := false  ; use blank cursors
	else
		c := h, flag := true  ; use the saved cursors
	for i, e in c {
		h_cursor := DllCall("CopyImage", "Ptr", e, "UInt", 2, "Int", 0, "Int", 0, "UInt", 0)
		DllCall("SetSystemCursor", "Ptr", h_cursor, "UInt", e)
	}
}

getSelfIp() {
	return cmdRet("dig @resolver4.opendns.com myip.opendns.com +short")
}

; ###########################################################################
; ############################# META FUNCTIONS ##############################
; ###########################################################################

; clipboardTracker(type) {
; 	try {
; 		if (type == 1) {
; 			if (StrLen(A_Clipboard) < 200) {
; 				if (RegexMatch(A_Clipboard, "youtube\.com\/shorts\/([0-9a-zA-Z\_\-]+)")) {
; 					A_Clipboard := RegexReplace(A_Clipboard, "youtube\.com\/shorts\/([0-9a-zA-Z\_\-]+)", "youtube.com/watch?v=$1")
; 				}
; 				else if (RegexMatch(A_Clipboard, "(?:youtube\.com\/watch\?v=|youtu\.be\/)([0-9a-zA-Z\_\-]+)(&t=[0-9]+s?)?&(?:pp|si|sl)=\S*")) {
; 					A_Clipboard := RegexReplace(A_Clipboard, "(?:youtube\.com\/watch\?v=|youtu\.be\/)([0-9a-zA-Z\_\-]+)(&t=[0-9]+s?)?&(?:pp|si|sl)=\S*", "youtube.com/watch?v=$1$2")
; 				}
; 				else if (RegexMatch(A_Clipboard, "(?:https:\/\/)?(?:www\.)?reddit\.com\/media\?url=https%3A%2F%2F(?:i|preview)\.redd\.it%2F(.*)\.([^\s?%]*)[\?|%]?\S*")) {
; 					A_Clipboard := RegexReplace(A_Clipboard, "(?:https:\/\/)?(?:www\.)?reddit\.com\/media\?url=https%3A%2F%2F(?:i|preview)\.redd\.it%2F(.*)\.([^\s?%]*)[\?|%]?\S*", "https://i.redd.it/$1.$2")
; 				}
; 				else if (RegexMatch(A_Clipboard, "(?:https:\/\/)?(?:www\.)?preview\.redd\.it\/(.*)\.([^\s?%]*)[\?|%]?\S*")) {
; 					A_Clipboard := RegexReplace(A_Clipboard, "(?:https:\/\/)?(?:www\.)?preview\.redd\.it\/(.*)\.([^\s?%]*)[\?|%]?\S*", "https://i.redd.it/$1.$2")
; 				}
; 			}
; 		}
; 	} catch Error as e {
; 		timedTooltip("tried modifying clipboard, but failed")
; 	}
; }

customTrayMenu() {
	suspendMenu := TrayMenu.submenus["SuspendMenu"]
	suspendMenu.Add("Suspend Hotkeys", trayMenuHandler)
	suspendMenu.Add("Suspend Reload", trayMenuHandler)
	suspendMenu.Default := "Suspend Reload"
	A_TrayMenu.Add("Open Recent Lines", trayMenuHandler)
	A_TrayMenu.Add("Help", trayMenuHandler)
	A_TrayMenu.Add()
	A_TrayMenu.Add("Window Spy", trayMenuHandler)
	A_TrayMenu.Add("Reload this Script", trayMenuHandler)
	A_TrayMenu.Add("Edit Script", trayMenuHandler)
	A_TrayMenu.Add()
	A_TrayMenu.Add("Pause Script", trayMenuHandler)
	A_TrayMenu.Add("Suspend/Stop", suspendMenu)
	A_TrayMenu.Add("Exit", trayMenuHandler)
	A_TrayMenu.Default := "Open Recent Lines"
}

trayMenuHandler(itemName, *) {
	suspendMenu := TrayMenu.submenus["SuspendMenu"]
	DetectHiddenWindows(1)
	switch itemName {
		case "Open Recent Lines":
			ListLines()
		case "Help":
			PostMessage(0x111, 65411, , , A_ScriptHwnd)
			tMM := A_TitleMatchMode
			SetTitleMatchMode("RegEx")
			hwnd := WinWait("AutoHotkey (?:v2)? Help ahk_exe hh\.exe")
			SetTitleMatchMode(tMM)
			WinUtilities.resetWindowPosition(hwnd, 0.8)
		case "Window Spy":
			PostMessage(0x111, 65402, , , A_ScriptHwnd)
		case "Reload this Script":
			Reload()
		case "Edit Script":
			; Edit()
			PostMessage(0x111, 65401, , , A_ScriptHwnd)
		case "Pause Script":
			Pause(-1)
			A_TrayMenu.ToggleCheck("Pause Script")
		case "Suspend Hotkeys":
			suspendMenu.ToggleCheck("Suspend Hotkeys")
			Suspend(-1) ; async bad, no postmessage
			if (A_IsSuspended)
				TraySetIcon(A_WorkingDir "\everything\Icons\Potet Think Warn.ico", , true)
			else
				TraySetIcon(A_WorkingDir "\everything\Icons\Potet Think.ico", , true)
		case "Suspend Reload":
			suspendMenu.ToggleCheck("Suspend Reload")
			Hotkey("^+R", "Toggle")
		case "Exit":
			ExitApp()
	}
}

customExit(ExitReason, ExitCode) {
	global openDTUman
	if (ExitReason == "Shutdown" || ExitReason == "Logoff") {
		DetectHiddenWindows(1)
		id := WinExist("openDTU NetZero ahk_exe cmd.exe")
		if (id)
			WinKill(id)
		main_inverter := openDTUman.getInverterList()["inverter"][1]["serial"]
		openDTUman.setInverterLimitConfig(main_inverter, {limit_type:1, limit_value:20})
	}
	ExitApp() ; this is technically unnecessary.
}


; ###########################################################################
; ############################### HOTSTRINGS ################################
; ###########################################################################

^!+F12:: { ; Toggles LaTeX Hotstrings
	HotstringLoader.switchHotstringState("Latex", "T")
}

^!F11:: {	; Toggle Rune Hotstrings
	HotstringLoader.switchHotstringState("Kayoogis", "T")
}

; LONG STRINGS
#HotIf WinActive("ahk_exe Discord.exe")
:X*:@potet:: fastPrint("<@245189840470147072>")
:X*:@burny:: fastPrint("<@318350925183844355>")
:X*:@Y:: fastPrint("<@354316862735253505>")
:X*:@zyntha:: fastPrint("<@330811222939271170>")
:X*:@astro:: fastPrint("<@193734142704353280>")
:X*:@rein:: fastPrint("<@315661562398638080>")
:X:from:me:: fastPrint("from:245189840470147072 ")
#HotIf

^::Send("{Text}^")
´::Send("{Text}´")
`::Send("{Text}``")

^^:: { ; Toggle ^, `, ´ Hotkeys
	for e in ["^", "´", "``"]
		Hotkey(e, "Toggle")
}

:*?:=/=::≠
:*?:+-::±
:*?:~=::≈
:*:\disap::ಠ_ಠ
:*:\checkmark::▣

; ENGLISH AUTOCORRECT
:*:yall::y'all
:*:dont::don't
:*:wont::won't
:*:didnt::didn't
:*:itll::it'll
:*:theres::there's
:*:thats::that's
:*:isnt::isn't
:*:everyones::everyone's
:*:aint::ain't
:*:mustve::must've
:*:thatll::that'll
:*:theyd::they'd
:*:youve::you've
:*:youd::you'd
:*:theyll::they'll
:*:youll::you'll
:*:theyre::they're
:*:youre::you're
:*:doesnt::doesn't
:*:shouldve::should've
:*:couldnt::couldn't
:*:shouldnt::shouldn't
:*:couldnt::couldn't
:*:wouldve::would've
:*:couldve::could've
:*:theyve::they've
:*:arent::aren't
:*:cant::can't
:*:Ive::I've
:*:weve::we've
; :*:!!!!::{!}{!}{!}1{!}111{!}one1{!}{!}eleven{!}{!}
; :*b0:**::**{left 2} ; bold in markdown
; :*b0:__::__{left 2} ; underlined in markdown

; ###########################################################################
; ################### HOTKEYS RELATED TO SPECIFIC PROGRAMS ##################
; ###########################################################################

*^LWin Up:: { ; Open Everything Search Window
	static searchString := "Everything ahk_exe Everything.exe ahk_class EVERYTHING"
	state := GetKeyState("Shift")
	move := true, list := []
	if (WinExist(searchString)) {
		move := false
		list := WinGetList(searchString)
	}
	Run('"C:\Program Files\Everything\Everything.exe" -newwindow')
	Loop {
		if (WinGetCount(searchString) == list.Length) {
			Sleep(50)
			continue
		}
		list2 := WinGetList(searchString)
		for i, e in list2 {
			if (!objContainsValue(list, e))
				hwnd := e
		}
		if (IsSet(hwnd)) ; if we found the window, good
			break
		return 0 ; give up else, we probably interfered and closed the window or something
	}
	WinActivate(hwnd)
	WinMoveTop(hwnd)
	mmx := WinGetMinMax(hwnd)
	if (mmx == 1 || mmx == -1)
		WinRestore(hwnd)
	if (move)
		winSlowMove(hwnd, 40, 400, 784, 648, 8)
	if (state)
		return
	WinWaitNotActive(hwnd)
	try WinClose(hwnd)
}

#HotIf !WinExist("ahk_exe AutoClickerPos.exe")
^Numpad5::{	; Toggle Autoclicker
	static timer := Click.Bind("L")
	static toggle := 0
	if (toggle := !toggle)
		SetTimer(timer, 20)
	else
		SetTimer(timer, 0)
}
#HotIf

#HotIf WinActive("ahk_exe vlc.exe")
^D:: {		; VLC: Open/Close Media Playlist
	SetControlDelay(-1)
	vlcid := WinGetID("VLC media player ahk_exe vlc.exe", , "Wiedergabeliste")
	WinGetClientPos(, , , &vlcH, vlcid)
	controlY := vlcH - 40
	ControlSend("{Esc}", , vlcid)
	ControlClick("X212 Y" controlY, vlcid, , , , "Pos NA")
}
#HotIf

#HotIf WinActive("Mozilla Firefox ahk_exe firefox.exe")
^D:: {		; Firefox: Expand Tab Sidebar
	ControlClick("X70 Y20", WinExist("Mozilla Firefox ahk_exe firefox.exe"), , , , "Pos NA")
}
#HotIf

#HotIf WinActive("ahk_group zoomableWindows")
^+::WheelUp ; Zoomable: Zoom in
^-::WheelDown
#HotIf

#HotIf WinActive("ahk_class Photo_Lightweight_Viewer")
^T::!Esc ; Fotoanzeige: StrgT->ShiftEsc
^W::!F4	; Fotoanzeige: StrgW->AltF4
#HotIf

#HotIf WinActive("ahk_exe firefox.exe")
^h::^+h ; Firefox: Ctrl H -> Ctrl Shift H
#HotIf

#HotIf WinActive("Minecraft ahk_exe javaw.exe")
^z::y ; MC: ctrl z -> y
^y::z ; MC: ctrl y -> z
^ö:: {	; MC: Spam shift Key
	static toggle := 0
	static timer := ((*) => (Send("{Shift Down}"), Sleep(10), Send("{Shift Up}")))
	if (toggle := !toggle)
		SetTimer(timer, 20)
	else
		SetTimer(timer, 0)
}
#HotIf

/*
#HotIf WinActive("ahk_exe BTD5-Win.exe")
r::w	; BTD5: Send w
z::e	; BTD5: Send e
w::r	; BTD5: Send r
d::t	; BTD5: Send t
e::y	; BTD5: Send y
t::a	; BTD5: Send a
y::s	; BTD5: Send s
c::d	; BTD5: Send d
v::f	; BTD5: Send f
s::g	; BTD5: Send g
a::h	; BTD5: Send h
k::c	; BTD5: Send c
h::v	; BTD5: Send v
n::b	; BTD5: Send b
m::n 	; BTD5: Send n
j::m 	; BTD5: Send m
b::j	; BTD5: Send j
x::k	; BTD5: Send k
f::;	; BTD5: Send Semicolon
ö::z	; BTD5: Send z
ä::x	; BTD5: Send x

-::.	; BTD5: Send .

Left::	; BTD5: MouseLeft
MouseMove, -1,0,,R
return

Right::	; BTD5: MouseRight
MouseMove, 1,0,,R
return

Up::	; BTD5: MouseUp
MouseMove, 0,-1,,R
return

Down::	; BTD5: MouseDown
MouseMove, 0,1,,R
return
#HotIf
*/


#HotIf WinActive("ahk_exe bloonstd6.exe")

F11::Escape	; BTD6: Rebind Escape

^,:: {	; BTD6: press comma
	static toggle := 0
	if !(presscomma)
		presscomma := Send.Bind(",")
	if (toggle := !toggle)
		SetTimer(presscomma, 30)
	else
		SetTimer(presscomma, 0)
}

^.:: {	; BTD6: press dot
	static toggle := 0
	if !(pressdot)
		pressdot := Send.Bind(".")
	if (toggle := !toggle)
		SetTimer(pressdot, 30)
	else
		SetTimer(pressdot, 0)
}

^-:: {	; BTD6: press minus
	static toggle := 0
	if !(pressminus)
		pressminus := Send.Bind("-")
	if (toggle := !toggle)
		SetTimer(pressminus, 30)
	else
		SetTimer(pressminus, 0)
}
#HotIf


#HotIf WinActive("HoloCure ahk_exe HoloCure.exe")
^ö:: {	; Holocure: Spam shift Key
	static toggle := 0
	static timer := ((*) => (Send("{Space Down}"), Sleep(10), Send("{Space Up}")))
	if (toggle := !toggle)
		SetTimer(timer, 20)
	else
		SetTimer(timer, 0)
}
#HotIf

#HotIf WinActive("ahk_exe Skul.exe")
+:: {	; Skul: Spam l
	static sTimer := Send.Bind("l")
	static toggle := false
	SetTimer(sTimer, toggle := !toggle ? 50 : 0)
}
#HotIf

#HotIf WinActive('ahk_exe Terraria.exe')
^ä::{	; Terrari: W Down
	Send("{w down}")
}
#HotIf

; ###########################################################################
; ############################ END OF SCRIPT ################################
; ###########################################################################
#HotIf ; DON'T REMOVE THIS, THE AUTOMATIC HOTKEYS SHOULD ALWAYS BE ACTIVE


getAllPermutations(str1, str2) {
	if (StrLen(str1) != StrLen(str2))
		return
	n := StrLen(str1)
	str2Arr := StrSplit(str2)
	arr := [str1]
	Loop (n)
	{
		i := A_Index
		arr2 := []
		for j, e in arr
			arr2.push(SubStr(str1, 1, -i) . str2Arr[n - i + 1] . SubStr(e, n - i + 2))
		arr.push(arr2*)
	}
	for i, e in arr
		out .= e "`n"
	return out
}

clickloop(rows, columns, rHeight, cWidth) {
	MouseGetPos(&initialX, &initialY)
	Loop (rows) {
		i := A_Index - 1
		Loop (columns) {
			j := A_Index - 1
			MouseClick("L", initialX + j * cWidth, initialY + i * rHeight)
			Sleep(10)
		}
	}
	return
}

makeTextAnsiColorful(str) {
	tStr := ""
	Loop Parse, str
	{
		if (A_Loopfield != " ")
			tStr .= "`[" . Random(30, 38) . "m" . A_Loopfield
		else
			tStr .= A_Loopfield
	}
	return tStr
}

loadTableAsHotstrings(filePath) {
	static str := "Deutsch"
	static repl := "Kayoogis"
	static options := ""
	SplitPath(filePath, &fname, , &ext)
	if (ext != "json")
		return

	jsonasstr := FileRead(filePath)
	table := jsongo.Parse(jsonasstr)
	data := table["data"]
	if !data.Length
		return
	hotstrings := []
	for i, row in data {
		if (row.Has(str) && row.Has(repl) && row[str] != "" && row[repl] != "" && row[str] != "-" && row[repl] != "-") {
			hotstringasObj := Map()
			hotstringasObj["string"] := row[str]
			hotstringasObj["replacement"] := row[repl]
			hotstringasObj["options"] := options
			hotstrings.push(hotstringasObj)
		}
	}
	hotstringsAsJsonStr := jsongo.Stringify(hotstrings, , "`t")
	try HotstringLoader.load(hotstringsAsJsonStr, "Kayoogis", , , , true)
}

^+d::{ ; Download currently copied link through yt-dlp as a song
	SongDownloader.download(A_Clipboard)
}

^+!d::{	; Run download script for list of links to image/video sites
	static turnSelfOff := toggleDLKeys.bind(0)
	try {
		toggleDLKeys()
		SetTimer(turnSelfOff, -300000)
	} catch {
		Hotkey("XButton1", (*) => (SetTimer(turnSelfOff, -300000), Run(A_WorkingDir "\..\Demo_Scripts\download.ahk")))
		Hotkey("XButton2", (*) => Run('"' A_WorkingDir '\..\Demo_Scripts\download.ahk" --open-folder'))
	}
	if (RegExMatch(A_Clipboard, "\.(?:png|jpeg|jpg|webp|mp4|gif|mov)"))
		Run(A_WorkingDir "\..\Demo_Scripts\download.ahk")

	toggleDLKeys(mode := -1) {
		mode := (mode == -1 ? "Toggle" : (mode == 0 ? "Off" : "On"))
		Hotkey("XButton1", mode)
		Hotkey("XButton2", mode)
	}
}



^F6::{	; Controller Test
	Loop 16 {
		if (GetKeyState(A_Index "JoyName")) {
			conIndex := A_Index
			break
		}
	}
	if !IsSet(conIndex)
		throw Error("No Controller Found")
	g := Gui()
	ed := g.AddEdit("w300 R20 ReadOnly")
	g.show()
	g.OnEvent("Close", (*) => (SetTimer(updategui, 0), g.Destroy()))
	g.OnEvent("Escape", (*) => (SetTimer(updategui, 0), g.Destroy()))
	conBtns := GetKeyState(conIndex "JoyButtons")
	conName := GetKeyState(conIndex "JoyName")
	conInfo := GetKeyState(conIndex "JoyInfo")
	SetTimer(updategui, 100)

	updategui() {
		btnsActive := ""
		conSticks := ""
		Loop conBtns
			btnsActive .= GetKeyState(conIndex "Joy" A_Index) ? " " A_Index : ""
		conArr := StrSplit(conInfo)
		objRemoveValues(conArr, ["D"])
		conArr.InsertAt(1, "X", "Y")
		for i, e in conArr
			conSticks .= (e == "P" ? "POV" : e) . Round(GetKeyState(conIndex "Joy" (e == "P" ? "POV" : e))) " "
		ed.Value := Format("Controller Name: {} (#{})`nCon Info: {}`nAxis: {}`nButtons Down: {}", conName, conIndex, conInfo, conSticks, btnsActive)
	}
}

^+WheelUp::{
	MouseGetPos(,,&hwnd)
	WinSetVolume("+5", hwnd)
}

^+WheelDown::{
	MouseGetPos(,,&hwnd)
	WinSetVolume("-5", hwnd)
}

WinSetVolume(level, target?) {
    appName := WinGetProcessName(target ?? WinExist() || "A")
    GUID := Buffer(16)
    DllCall("ole32\CLSIDFromString", "Str", "{77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F}", "Ptr", GUID)
    IMMDeviceEnumerator := ComObject("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")
    ComCall(4, IMMDeviceEnumerator, "UInt", 0, "UInt", 1, "Ptr*", &IMMDevice := 0)
    ComCall(3, IMMDevice, "Ptr", GUID, "UInt", 23, "Ptr", 0, "Ptr*", &IAudioSessionManager2 := 0)
    ObjRelease(IMMDevice)
    ComCall(5, IAudioSessionManager2, "Ptr*", &IAudioSessionEnumerator := 0)
    ObjRelease(IAudioSessionManager2)
    ComCall(3, IAudioSessionEnumerator, "UInt*", &sessionCount := 0)
    loop sessionCount {
        ComCall(4, IAudioSessionEnumerator, "Int", A_Index - 1, "Ptr*", &IAudioSessionControl := 0)
        IAudioSessionControl2 := ComObjQuery(IAudioSessionControl, "{BFB7FF88-7239-4FC9-8FA2-07C950BE9C6D}")
        ObjRelease(IAudioSessionControl)
        ComCall(14, IAudioSessionControl2, "UInt*", &pid := 0)

        if (!pid || ProcessGetName(pid) != appName)
            continue

        ISimpleAudioVolume := ComObjQuery(IAudioSessionControl2, "{87CE5498-68D6-44E5-9215-6DA47EF883D8}")
        ComCall(6, ISimpleAudioVolume, "Int*", &muted := 0)
        if muted || level = 0
            ComCall(5, ISimpleAudioVolume, "Int", !muted, "Ptr", 0)

        if level {
            ComCall(4, ISimpleAudioVolume, "Float*", &levelOld := 0)

            if (level ~= "^[-+]")
                levelNew := clamp(levelOld + (level / 100), 0, 1)
            else
                levelNew := clamp(level / 100, 0, 1)

            if (levelNew != levelOld)
                ComCall(3, ISimpleAudioVolume, "Float", levelNew, "Ptr", 0)
        }
        break
    }
    ObjRelease IAudioSessionEnumerator
    return (IsSet(levelNew) ? Round(levelNew * 100) : -1)
}

#HotIf WinActive("GT: New Horizons")
^!q::@ ; GTNH: Fix Ctrl Alt
^!+::~ ; GTNH: Fix Ctrl Alt
^!7::`{ ; GTNH: Fix Ctrl Alt
^!8::[ ; GTNH: Fix Ctrl Alt
^!9::] ; GTNH: Fix Ctrl Alt
^!0::} ; GTNH: Fix Ctrl Alt
#HotIf

#HotIf WinActive("Revolution Idle")
^q::{ ; trash item under cursor
	MouseGetPos(&x, &y)
	Send("{LButton Down}")
	Sleep(30)
	MouseMove(767, 700)
	Sleep(30)
	Send("{LButton Up}")
	Sleep(30)
	MouseMove(x, y)
}
^Numpad2::bigLoop()
^Numpad3::{
	Loop(5)
		spawnAndIncrease()
}

bigLoop() {
	Loop {
		clickAutospawn()
		Sleep(50)
		doRefinePrestige()
		Sleep(50)
		Loop(5) {
			spawnAndIncrease("150")
			Sleep(50)
		}
		doPolishPrestige()
		Sleep(50)
		Loop(5) {
			spawnAndIncrease("150")
			Sleep(50)
		}
		clickAutoSpawn()
		Sleep(7000)
	}
}

openPolishMenu() {
	static polish := [1050, 1000]
	MouseClick("L", polish*)
}

closePolishMenu() {
	static polishexit := [1555, 255]
	MouseClick("L", polishexit*)
}

doPolishPrestige() {
	static polishPrestige := [1178, 362]
	static polishPrestigeConfirm := [1180, 640]
	static swordlvlup := [1420, 896]
	openPolishMenu()
	sleep(75)
	MouseClick("L", polishPrestige*)
	Sleep(75)
	MouseClick("L", polishPrestigeConfirm*)
	Sleep(75)
	loop(3) {
		MouseClick("L", swordlvlup*)
		Sleep(30)
	}
	Sleep(75)
	closePolishMenu()
}

clickAutospawn() {
	static autospawn := [800, 840]
	MouseClick('L', autospawn*)
}

spawnAndIncrease(num := "999") {
	static spawn := [675, 990]
	static spawnlvl := [740, 898]
	MouseClick("L", spawn*)
	Sleep(75)
	MouseClick("L", spawnlvl*)
	Sleep(75)
	Send(num)
}

doRefinePrestige() {
	static refinePrestige := [1450, 410]
	static refinePrestigeConfirm := [1200, 650]
	openRefineMenu()
	Sleep(75)
	MouseClick('L', refinePrestige*)
	Sleep(75)
	MouseClick('L', refinePrestigeConfirm*)
	Sleep(75)
	closeRefineMenu()
}
openRefineMenu() {
	static refine := [1441, 991]
	MouseClick('L', refine*)
}
closeRefineMenu() {
	static refineClose := [62, 260]
	MouseClick('L', refineClose*)
}
#HotIf
