; ###########################################################################
; ############################# INITIALIZATION ##############################
; ###########################################################################
#Requires AutoHotkey v2+
#SingleInstance Force
KeyHistory(500)
#UseHook
InstallKeybdHook(true, true)
; Set Correct Working Dir
if !InStr(FileExist(A_ScriptDir "\script_files\everything"), "D")
	DirCreate("script_files\everything")
SetWorkingDir(A_ScriptDir . "\script_files")

OnExit(customExit)
OnClipboardChange(clipboardTracker, 1)
Hotstring("EndChars", "-()[]{}:;`'`"/\,.?!" . A_Space . A_Tab)

SCRIPTVAR_WASRELOADED := (InStr(DllCall("GetCommandLine", "str"), "/restart") ? true : false)

; Delete Tray Menu Items before including files that may modify them
A_TrayMenu.Delete()

#Include "%A_ScriptDir%\LibrariesV2"
#Include "TransparentTaskbar.ahk"
#Include "HotkeyManager.ahk"
#Include "WindowManager.ahk"
#Include "ReminderManager.ahk"
#Include "NeoKeyboardLayout.ahk"
#Include "YoutubeDLGui.ahk"
#Include "TextEditMenu.ahk"
#Include "MacroRecorder.ahk"
#Include "TimestampConverter.ahk"
#Include "DiscordClient.ahk"
#Include "AltDrag.ahk"
#Include "MathUtilities.ahk"
#Include "BasicUtilities.ahk"
#Include "HotstringLoader.ahk"
#Include "TableFilter v2.ahk"
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
; GroupAdd("instantCloseWindows", "Unbenannt - Editor ahk_exe notepad.exe")
youtubeDL := YoutubeDLGui()
reminders := ReminderManager(, , token := Trim(FileRead(A_WorkingDir . "\discordBot\discordBotToken.token", "UTF-8")))
try reminders.importReminders(A_WorkingDir . "\Reminders\reminders.json")
; reminders.setPeriodicTimerOn(parseTime(, , , 3, 30, 0), 1, "Days", "Its 3:30, Go Sleep", reminders.discordReminder.bind(0, token, "CHANNELID"))
; reminders.exportReminders(A_WorkingDir . "\Reminders\reminders2.json")
; Launch Transparent Taskbar at 50ms frequency
if (StrCompare(A_OSVersion, "10.0.22000") < 0)
	TransparentTaskbar.TransparentTaskbar(1, 50)
; Start keeping track of desktop window changes
DesktopState.enable(60000)
; import custom blacklist into AltDrag
AltDrag.addBlacklist([
	"Satisfactory ahk_class UnrealWindow",
	"DriveBeyondHorizons ahk_exe DriveBeyondHorizons-Win64-Shipping.exe"
])
; Start Loop to close winrar popups
SetTimer(closeWinRarNotification, -100, -1000) ; priority -100k so it doesn't interrupt
; Initialize Internet Logging Script
internetConnectionLogger("Init")
; Load LaTeX Hotstrings

try HotstringLoader.load(FileRead(A_WorkingDir "\everything\LatexHotstrings.json", "UTF-8"), "LaTeX",,,false)
; loadTableAsHotstrings(A_WorkingDir "\TableFilter\Kayoogis.json")
; replace the tray menu with my own
customTrayMenu()
; Synchronize nextDNS IP
if (!SCRIPTVAR_WASRELOADED)
	connectNextDNS()
; use suspendexempt for the reload hotkey. (and others) TODO!
return

; ###########################################################################
; ############################# CONTROL HOTKEYS #############################
; ###########################################################################

#SuspendExempt true
^+R:: { ; Reload Script
	Reload()
}
 
^+!S::{	; Suspend All Other Hotkeys
	TrayMenu.submenus["SuspendMenu"].ToggleCheck("Suspend Hotkeys")
	Suspend(-1) ; async bad, no postmessage
	if (A_IsSuspended)
		TraySetIcon(A_WorkingDir "\everything\Icons\Potet Think Warn.ico", , true)
	else
		TraySetIcon(A_WorkingDir "\everything\Icons\Potet Think.ico", , true)
}

#SuspendExempt false

#HotIf !WinActive("ahk_exe csgo.exe") && !WinActive("Satisfactory ahk_class UnrealWindow")
^+LButton:: {	; Text Modification Menu
	TextEditMenu.ShowMenu()
}
#HotIf

^U:: {	; Time/Date Converter
	textTimestampConverter()
}

^I:: {	; Show Hex code as Color
	colorPreviewGUI(fastCopy())
}

^!+NumpadSub:: {	; Record Macro
	MacroRecorder.createMacro(A_ThisHotkey)
}

^F12:: { ; Toggle Hotkey Manager
	HotkeyManager.hotkeyManager("T")
}

^F11:: { ; Shows a list of all Windows
	WindowManager.windowManager("T")
}

^F10:: {	; Neokeyboard Layout
	NeoKeyboardLayout.KeyboardLayoutGUI("T")
}

^F9:: {	; Shows Internet Connection
	internetConnectionLogger("T")
}

^F8:: {	; Shows Reminder GUI
	reminders.ReminderManagerGUI("T")
}

^+K:: { ; Toggle Taskbar Transparency
	TransparentTaskbar.transparentTaskbar("T")
}

^+F11:: { ; Gives Key History
	DetectHiddenWindows(1)
	KeyHistory()
	;	PostMessage(0x111, 65409,,, A_ScriptHwnd) ; this works too???
}

^+F10:: {	; YTDL GUI
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

; Evaluate Shell Expression in-text
^!K:: calculateExpression("p")

; ###########################################################################
; ################### HOTKEYS RELATED TO SPECIFIC PROGRAMS ##################
; ###########################################################################

^!+NumpadEnter:: {	; Launch Autoclicker
	Run(A_Desktop "\Autoclicker\AutoClickerPos.exe")
}

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

#HotIf WinActive("ahk_group zoomableWindows")

^+:: {	; Zoomable: Zoom in
	Send("{WheelUp}")
}

^-:: {	; Zoomable: Zoom out
	Send("{WheelDown}")
}
#HotIf

#HotIf WinActive("Minecraft ahk_exe javaw.exe")
^z::y ; MC: ctrl z -> y
^y::z ; MC: ctrl y -> z
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

F11:: { 	; BTD6: Rebind Escape
	Send("{Escape}")
}

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

#HotIf WinActive("ahk_class Photo_Lightweight_Viewer")
; ----- Fotoanzeige
^T:: {	; Fotoanzeige: StrgT->ShiftEsc
	Send("!{Esc}")
}

^W:: {	; Fotoanzeige: StrgW->AltF4
	Send("!{F4}")
}
#HotIf

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
	AltDrag.scaleWindow(,-1)
}

!WheelUp:: {	; Scale Window Up
	AltDrag.scaleWindow(,1)
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

^NumpadDiv:: {	; Show Mouse Coordinates
	static toggle := false
	if (toggle := !toggle)
		SetTimer(showcoords, 50)
	else {
		SetTimer(showcoords, 0)
		Tooltip()
	}
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

^!+K:: { ; Tiles Windows Vertically
	static windowInfo, tileState := false
	if (tileState := !tileState) {
		windowInfo := WindowManager.getAllWindowInfo(0, 0)
		shell := ComObject("Shell.Application")
		if (MsgBox("Tile Windows Vertically?", "Confirm Dialog", 0x1) == "OK")
			shell.TileVertically()
	}
	else {
		for i, win in windowInfo {
			if (win.state != -1)
				WinMove(win.xpos, win.ypos, win.width, win.height, win.hwnd)
			if (win.state == 1)
				WinMaximize(win.hwnd)
		}
	}
}

^!+L:: { ; save / restore desktop state
	DesktopState.restore()
}


^!+I:: { ; Center & Adjust Active Window
	if WinActive("ahk_group cornerMusicPlayers")
		WinMove(-600, 550, 515, 550)
	else if WinActive("Discord ahk_exe Discord.exe")
		WinMove(-1497, 129, 1292, 769)
	else
		AltDrag.resetWindowPosition()
}

^!+H:: { ; Make Active Window Transparent
	static toggle := false
	WinSetTransparent((toggle := !toggle) ? 120 : "Off", "A")
}

^+H:: { ; Make Taskbar invisible
	TransparentTaskbar.setInvisibility("T", 0)
}

^+F9:: { ; Show/Hide Taskbar
	static hide := false
	TransparentTaskbar.hideShowTaskbar(hide := !hide)
}

; ###########################################################################
; ######################## DESKTOP-RELATED FUNCTIONS ########################
; ###########################################################################

toggleNumpadMouseMove() {
	static init := 0
	if !(init) {
		Hotkey("Numpad1", moveMousePixel.bind(-1, 1))
		Hotkey("Numpad2", moveMousePixel.bind(0, 1))
		Hotkey("Numpad3", moveMousePixel.bind(1, 1))
		Hotkey("Numpad4", moveMousePixel.bind(-1, 0))
		Hotkey("Numpad6", moveMousePixel.bind(1, 0))
		Hotkey("Numpad7", moveMousePixel.bind(-1, -1))
		Hotkey("Numpad8", moveMousePixel.bind(0, -1))
		Hotkey("Numpad9", moveMousePixel.bind(1, -1))
		Hotkey("NumpadEnter", clickMouse.Bind("L", 0))
		Hotkey("NumpadAdd", clickMouse.Bind("L", 1))
		init := 1
		return
	}
	Hotkey("Numpad1", "Toggle")
	Hotkey("Numpad2", "Toggle")
	Hotkey("Numpad3", "Toggle")
	Hotkey("Numpad4", "Toggle")
	Hotkey("Numpad6", "Toggle")
	Hotkey("Numpad7", "Toggle")
	Hotkey("Numpad8", "Toggle")
	Hotkey("Numpad9", "Toggle")
	Hotkey("NumpadEnter", "Toggle")
	Hotkey("NumpadAdd", "Toggle")
}

moveMousePixel(x, y, *) {
	MouseMove(x, y, 0, "R")
}

clickMouse(b, press := 0, *) {
	b := SubStr(b, 1, 1)
	if (press)
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
	try {
		whr := ComObject("WinHttp.WinHttpRequest.5.1")
		whr.Open("GET", "https://link-ip.nextdns.io/" . FileRead(A_WorkingDir "\everything\nextDNS_Link.id"), true)
		whr.Send()
		whr.WaitForResponse()
	} catch as e {
		Msgbox("Could not connect to NextDNS. Error:`n" e.What "`n" e.Extra)
		return ""
	}
	return whr.ResponseText
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
		WinWait("ahk_pid " internetConsolePID)
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

clipboardTracker(type) {
	try {
		if (type == 1) {
			if (StrLen(A_Clipboard) < 200) {
				if (RegexMatch(A_Clipboard, "youtube\.com\/shorts\/([0-9a-zA-Z\_\-]+)")) {
					A_Clipboard := RegexReplace(A_Clipboard, "youtube\.com\/shorts\/([0-9a-zA-Z\_\-]+)", "youtube.com/watch?v=$1")
				}
				else if (RegexMatch(A_Clipboard, "(?:youtube\.com\/watch\?v=|youtu\.be\/)([0-9a-zA-Z\_\-]+)(&t=[0-9]+s?)?&(?:pp|si|sl)=\S*")) {
					A_Clipboard := RegexReplace(A_Clipboard, "(?:youtube\.com\/watch\?v=|youtu\.be\/)([0-9a-zA-Z\_\-]+)(&t=[0-9]+s?)?&(?:pp|si|sl)=\S*", "youtube.com/watch?v=$1$2")
				}
				else if (RegexMatch(A_Clipboard, "(?:https:\/\/)?(?:www\.)?reddit\.com\/media\?url=https%3A%2F%2F(?:i|preview)\.redd\.it%2F(.*)\.([^\s?%]*)[\?|%]?\S*")) {
					A_Clipboard := RegexReplace(A_Clipboard, "(?:https:\/\/)?(?:www\.)?reddit\.com\/media\?url=https%3A%2F%2F(?:i|preview)\.redd\.it%2F(.*)\.([^\s?%]*)[\?|%]?\S*", "https://i.redd.it/$1.$2")
				}
				else if (RegexMatch(A_Clipboard, "(?:https:\/\/)?(?:www\.)?preview\.redd\.it\/(.*)\.([^\s?%]*)[\?|%]?\S*")) {
					A_Clipboard := RegexReplace(A_Clipboard, "(?:https:\/\/)?(?:www\.)?preview\.redd\.it\/(.*)\.([^\s?%]*)[\?|%]?\S*", "https://i.redd.it/$1.$2")
				}
			}
		}
	} catch Error as e {
		timedTooltip("tried modifying clipboard, but failed")
	}
}

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
	TraySetIcon(A_WorkingDir "\everything\Icons\Potet Think.ico", , true)
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
			center_window_on_monitor(hwnd, 0.8)
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
; ############################ END OF SCRIPT ################################
; ###########################################################################
#HotIf ; DON'T REMOVE THIS, THE AUTOMATIC HOTKEYS SHOULD ALWAYS BE ACTIVE

sierpinskiCoords(x, y, width, height, depth) {
	; height := Integer(Round(sqrt(3)/2 * width))
	if (depth == 0)
		return Format("{}-{} {}-{} {}-{} {}-{} ", x, y, x + width // 2, y + height, x - width // 2, y + height, x, y)
	str := sierpinskiCoords(x, y, width // 2, height // 2, depth - 1) . x "-" y " "
	str .= sierpinskiCoords(x + width // 4, y + height // 2, width // 2, height // 2, depth - 1) . x "-" y " "
	str .= sierpinskiCoords(x - width // 4, y + height // 2, width // 2, height // 2, depth - 1) . x "-" y " "
	return str
}

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
			arr2.push(SubStr(str1, 1, -1 * i) . str2Arr[n - i + 1] . SubStr(e, n - i + 2))
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


^!+Ä:: {	; Reload other script
	DetectHiddenWindows("On")
	PostMessage(0x111, 65303, , , A_ScriptHwnd)
}


; ^m:: { ; Get Permutations
;	A_Clipboard := getAllPermutations("12345", "abcde")
; }

; ^l:: { ; Make colorful Text
;	text := fastCopy()
;	text := makeTextAnsiColorful(text)
;	fastPrint(text)
; }

; #HotIf WinActive("doujinshi and manga - Vivaldi")
; ß:: { ; Vivaldi: Toggle Website Override
; 	Hotkey("w", "Toggle")
; 	Hotkey("a", "Toggle")
; 	Hotkey("s", "Toggle")
; 	Hotkey("d", "Toggle")
; 	Hotkey("Right", "Toggle")
; }
; Right:: {	; Vivaldi: Website Override Right
; 	Send("{Right}")
; 	Send("{Home}")
; }
; w:: {	; Vivaldi: Website Override Up
; 	Send("{PgUp}")
; }
; a:: {	; Vivaldi: Website Override Left
; 	Send("{Left}")
; }
; s:: {	; Vivaldi: Website Override Down
; 	Send("{PgDn}")
; }
; d:: {	; Vivaldi: Website Override Right
; 	Send("{Right}")
; 	Send("{Home}")
; }
; #HotIf

^NumpadSub:: { ; Clip mouse to active windows' client area
	static toggle := 0
	if (toggle := !toggle)
		clipCursor(1)
	else
		clipCursor(0)
}

clipCursor(mode := true, window := "A") {
	WinGetClientPos(&wx, &wy, &ww, &wh, WinExist(window))
	if (!mode)
		return !DllCall("ClipCursor", "Ptr", 0)
	NumPut("UInt", wx, "UInt", wy, "UInt", wx + ww, "UInt", wy + wh, llrectA := Buffer(16, 0), 0)
	return DllCall("ClipCursor", "Ptr", llrectA)
}


#HotIf WinActive("ahk_exe javaw.exe")
^ö:: {	; MC: Spam shift Key
	static toggle := 0
	static timer := ((*) => (Send("{Shift Down}"), Sleep(10), Send("{Shift Up}")))
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

; Numpad5::{
; 	newGui := Gui()
; 	retValue := ""
; 	editControl := newGui.AddEdit("ReadOnly w500 R30")
; 	newGui.Show("AutoSize")
; 	cmdRetAsync("ping 8.8.8.8", &retValue, intermediate, finished)
; 	return 0
; 	intermediate(curValue) {
; 		editControl.Value := editControl.Value . "`n" . curValue
; 	}

; 	finished() {
; 		editControl.Value := editControl.Value . "`nPOGGERS WE ARE DONE"
; 	}
; }


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

#HotIf !WinExist("ahk_exe AutoClickerPos.exe")
Numpad5::{
	static timer := Click.Bind("L")
	static toggle := 0
	if (toggle := !toggle)
		SetTimer(timer, 20)
	else
		SetTimer(timer, 0)
}
#HotIf

#HotIf WinActive("ahk_exe Revolution Idle.exe")
b::{
	MouseGetPos(&x, &y)
	Click(1432, 1013, "L")
	Sleep(50)
	MouseMove(x, y, 0)
}
#HotIf