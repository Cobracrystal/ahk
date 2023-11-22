;// TODO: EDIT THE TRAY MENU TO BE SHORTER / HAVE SUBMENUS
;// TODO: FIX BUG WITH TRANSPARENT TASKBAR TIMER NOT DETECTING SEAMLESS FULLSCREEN
;  ______________________________________________________________________________________________
;[style]			INITILIZATION	: MODES
;[style]{ ______________________________________________________________________________________________
#Requires AutoHotkey v2.0
#SingleInstance Force
KeyHistory(500)
Persistent()
#UseHook
SendMode("Input") ; // Faster
SetTitleMatchMode(2) ;// Must Match Exact Title (1 = start with specified words, 2 = contains words, 3 = match words exactly)
; CoordMode,Mouse,Window ;// Coordinates for Click are relativ to upper left corner of active Window (Look TimeClickers hotkey/Timer for usage)
; CoordMode,ToolTip,Window ;// both this and above are the default anyway, leaving for future reference
; Thread, NoTimers	;// thread doesn't get interrupted by timers. since i now have two timers, this blocks one of them, making it fail.
;// this would change the standard editing program for ahk to n++, but i changed the tray menu anyway so it works.
; RegWrite REG_SZ, HKCR, AutoHotkeyScript\Shell\Edit\Command,, C:\Program Files (x86)\Notepad++\notepad++.exe `%1 
;// unnecessary usually
; DetectHiddenWindows, On
;[style]} ______________________________________________________________________________________________
;[style]							: SUB FILES
;[style]{ ______________________________________________________________________________________________
if !InStr(FileExist("script_files\everything"), "D")
	DirCreate("script_files\everything")
SetWorkingDir(A_ScriptDir . "\script_files")
A_TrayMenu.Delete()

#Include "%A_ScriptDir%\LibrariesV2"
#Include "TransparentTaskbar.ahk"
#Include "HotkeyManager.ahk"
#Include "WindowManager.ahk"
; #Include "ReminderManager.ahk"
#Include "NeoKeyboardLayout.ahk"
; #Include "YoutubeDLGui.ahk"
#Include "TextEditMenu.ahk"
#Include "MacroRecorder.ahk"
#Include "TimestampConverter.ahk"
#Include "DiscordClient.ahk"
#Include "DiscordBotCommands.ahk"
#Include "AltDrag.ahk"
#Include "MathUtilities.ahk"
#Include "ColorUtilities.ahk"
#Include "BasicUtilities.ahk"
#Include "HotstringLoader.ahk"

#Include "JSON.ahk"

;[style]} ______________________________________________________________________________________________
;[style]							: VARIABLES
;[style]{ ______________________________________________________________________________________________

;// for windows in which ctrl+ should replace scrolling cause it sucks
GroupAdd("zoomableWindows", "ahk_exe Mindustry.exe")
;// for windows that should be put in the corner when ctrlaltI'd
GroupAdd("cornerMusicPlayers", "VLC media player ahk_exe vlc.exe",, "Wiedergabeliste")
GroupAdd("cornerMusicPlayers", "Daum PotPlayer ahk_exe PotPlayerMini64.exe",, "Einstellungen")
GroupAdd("cornerMusicPlayers", "foobar2000 ahk_exe foobar2000.exe",, "Scratchbox")

;[style]} ______________________________________________________________________________________________
;[style]							: STARTING FUNCTIONS
;[style]{ ______________________________________________________________________________________________
InstallKeybdHook(true, true)
; Check if script is reloaded
SCRIPTVAR_WASRELOADED := (DllCall("GetCommandLine", "str") == '"' . A_AhkPath . '" /restart /script "' . A_scriptFullPath . '"' ? true : false)
;// set 1337 reminder
; 	ReminderManager.initialize(0, 0, readFileIntoVar(A_WorkingDir . "\discordBot\discordBotToken.token"))
; 	ReminderManager.setSpecificTimer("1337reminder", "", , , 13,36,50)
;ReminderManager.setSpecificTimer(,"test message", , , 0,42,0)
; 	ReminderManager.setSpecificTimer("discordReminder", "GO SLEEP", , , 4,0,0,,,"245189840470147072")
; ReminderManager.setSpecificTimer(func, msg, multi, period, h,m,s,d,mo, target)
/*
Menu, Timers, Add, 1337 Timer: On, doNothing
Menu, Timers, Disable, 1337 Timer: On
Menu, Timers, Check, 1337 Timer: On
*/
;// transparent taskbar ini
TransparentTaskbar.TransparentTaskbar(1,50)
;// start clipboardwatcher
OnClipboardChange(clipboardTracker, 1)
;// better icon
TraySetIcon("C:\Users\Simon\Desktop\programs\Files\Icons\Potet Think.ico",,true)
;// Timer because new Thread
GroupAdd("rarReminders", "ahk_class RarReminder")
GroupAdd("rarReminders", "Please purchase WinRAR license ahk_class #32770")
SetTimer(closeWinRarNotification, -100, -100000) ; priority -100k so it doesn't interrupt
;// Initialize Internet Logging Script
internetConnectionLogger("Init", "C:\Users\Simon\Desktop\programs\programming\bat\log.txt")
;// Synchronize nextDNS IP
if (!SCRIPTVAR_WASRELOADED)
	timedTooltip(connectNextDNS(),4000)
;// Initialize LaTeX Hotstrings
LatexHotstrings(1)
;// replace the tray menu with my own
createBetterTrayMenu()
OnExit(customExit)
return
	
;[style]} ______________________________________________________________________________________________
;[style]			HOTKEYS	 		: CONTROL
;[style]{ ______________________________________________________________________________________________

#SuspendExempt true
^+R:: { ; Reload Script
	Reload()
}
#SuspendExempt false

#HotIf !WinActive("ahk_exe csgo.exe")
^+LButton::{	; Text Modification Menu
	textModifyMenu.Show()
}
#HotIf

^U::{	; Time/Date Converter
	textTimestampConverter(A_ThisHotkey)
}

^I::{	; Show Hex code as Color
	hexcodeColorPreview(A_ThisHotkey)
}


^+!NumpadSub::{	; Record Macro
	MacroRecorder.createMacro(A_ThisHotkey)
}

^F12::{ ; Toggle Hotkey Manager
	HotkeyManager.hotkeyManager("T")
}

^F11::{ ; Shows a list of all Windows
	WindowManager.windowManager("T")
}

^F10::{	; Neokeyboard Layout
	NeoKeyboardLayout.KeyboardLayoutGUI("T")
}

^F9::{	; Shows Internet Connection
	internetConnectionLogger("T")
}

; ^F8::{	; Shows Reminder GUI
; 	ReminderManager.ReminderManagerGUI("T")
; }

^+K::{ ; Toggle Taskbar Transparency
	TransparentTaskbar.transparentTaskbar("T")
}

^+F11::{ ; Gives Key History
	ListLines()
}

; ^+F10::{	; YTDL GUI
; 	YoutubeDLGui.YoutubeDLGui("T")
; }

^!Numpad0::{	; Toggle NumpadKeys to Move Cursor
	toggleNumpadMouseMove()
}

toggleNumpadMouseMove() {
	static init := 0
	if !(init) {
		Hotkey("Numpad2", moveMousePixel.bind(0, 1))
		Hotkey("Numpad4", moveMousePixel.bind(-1,0))
		Hotkey("Numpad6", moveMousePixel.bind(1, 0))
		Hotkey("Numpad8", moveMousePixel.bind(0,-1))
		Hotkey("NumpadEnter", clickMouse.Bind("L",0))
		Hotkey("NumpadAdd", clickMouse.Bind("L", 1))
		init := 1
		return
	}
	Hotkey("Numpad2", "Toggle")
	Hotkey("Numpad4", "Toggle")
	Hotkey("Numpad6", "Toggle")
	Hotkey("Numpad8", "Toggle")
	Hotkey("NumpadEnter", "Toggle")
	Hotkey("NumpadAdd", "Toggle")
}

moveMousePixel(x,y, *) {
	MouseMove(x,y,0,"R")
}

clickMouse(b, press := 0, *) {
	b := SubStr(b, 1, 1)
	if (press)
		st := GetKeyState(b . "Button") ? "U" : "D"
	MouseClick(b,,,,,st?)
}


^LWin Up::{ ; Replace Windows Search with EverythingSearch
	Run("everything.exe -newwindow", "C:\Program Files\Everything")
	WinWaitActive("ahk_exe C:\Program Files\Everything\Everything.exe")
	hwnd := WinGetID()
	mmx := WinGetMinMax()
	if (mmx == 1 || mmx == -1)
		WinRestore()
	winSlowMove(hwnd,40,400,784,648,8)
	WinWaitNotActive("ahk_id " hwnd)
	try WinClose("ahk_id" hwnd)
}

#HotIf WinActive("ahk_exe C:\Program Files\Everything\everything.exe")
	^LWin Up::{ ; Close EverythingSearch if its active
		WinClose("ahk_exe C:\Program Files\Everything\Everything.exe")
	}
#HotIf

#HotIf WinActive("ahk_exe vlc.exe")
	^D::{		; VLC: Open/Close Media Playlist
		SetControlDelay(-1) 
		vlcid := WinGetID("VLC media player ahk_exe vlc.exe",,"Wiedergabeliste")
		WinGetClientPos(,,,&vlcH,"ahk_id " . vlcid)
		controlY := vlcH - 40
		ControlSend("{Esc}",, "ahk_id " vlcid)
		ControlClick("X212 Y" controlY, "ahk_id " vlcid,,,, "Pos NA")
	}
#HotIf

~CapsLock::{ ; display capslock state
	timedTooltip(GetKeyState("CapsLock", "T"))
;	SetCapsLockState(!GetKeyState("CapsLock", "T"))
}


;[style]} ______________________________________________________________________________________________
;[style]					 		: STANDARD / GAMES
;[style]{ ______________________________________________________________________________________________

^!K::{	; Evaluate Shell Expression in-text
	calculateExpression("c")
}

^+!NumpadEnter::{	; Launch Autoclicker
	Run("C:\Users\Simon\Desktop\Autoclicker\AutoClickerPos.exe")
}

#HotIf WinActive("ahk_group zoomableWindows")
;[style]{----- Zoomable Windows
^+::{	; Zoomable: Zoom in
	Send("{WheelUp}")
}

^-::{	; Zoomable: Zoom out
	Send("{WheelDown}")
}
#HotIf
;[style]}-----

/*
#HotIf WinActive("ahk_exe BTD5-Win.exe")
;[style]{----- Btd5
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

;[style]}-----

#HotIf WinActive("ahk_exe bloonstd6.exe")
;[style]{----- Btd6

F11::{ 	; BTD6: Rebind Escape
	Send("{Escape}")
}


; deprecated pause unpause shenanigans
; ^1::	; BTD6: 203 bomb
; placeUpgradeTower("e", [0,0,3], [2,0,0])
; return

; ^f::
; placeUpgradeTower("f", [0,2,0], [3,0,0])
; return

; ^0::	; BTD6: sell tower
; togglepause()
; selectSellTower()
; togglepause()
; return
/*
^D::	; BTD6: deposit money left
	MouseGetPos, ax, ay
	MouseClick, L, 205, 375
	Sleep(35)
	MouseMove, ax, ay, 0
return

+D::	; BTD6: deposit money right
	MouseGetPos, ax, ay
	MouseClick, L, 1425, 370
	Sleep(35)
	MouseMove, ax, ay, 0
return
*/
^,::{	; BTD6: press comma
	static toggle := 0
	if !(presscomma)
		presscomma := Send.Bind(",")
	if (toggle := !toggle)
		SetTimer(presscomma, 30)
	else
		SetTimer(presscomma, 0)
}

^.::{	; BTD6: press dot
	static toggle := 0
	if !(pressdot)
		pressdot := Send.Bind(".")
	if (toggle := !toggle)
		SetTimer(pressdot, 30)
	else
		SetTimer(pressdot, 0)
}

^-::{	; BTD6: press minus
	static toggle := 0
	if !(pressminus)
		pressminus := Send.Bind("-")
	if (toggle := !toggle)
		SetTimer(pressminus, 30)
	else
		SetTimer(pressminus, 0)
}

#HotIf

;[style]}-----
/*

#HotIf WinActive("ahk_exe ICBING2k.exe")
;[style]{----- I can't believe its not gambling 2
^P::	; ICBING2k: Open Lootboxes
if (icbingt := !icbingt)
	SetTimer, icbint, 300
else
	SetTimer, icbint, Off
return

icbint() {
	MouseMove, 950, 860
	Sleep(20)
	ControlClick, X950 Y860, ahk_exe ICBING2k.exe
}
#HotIf
;[style]}-----

#HotIf WinActive("ahk_exe Pixel Puzzles Traditional Jigsaws.exe")
;[style]{----- Jigsaw Puzzles
^+P::	; Jigsaw: Fit piece
findplace_piece(59,304,1868,952)
return
#HotIf
;[style]}-----

#HotIf WinActive("ahk_exe Idling to Rule the Gods.exe")
;[style]{----- ITRTG

^+!Ä::	; ITRTG: dungeonspam
if (dungeonspam := !dungeonspam)
	SetTimer, dungeonspam, 200
else
	SetTimer, dungeonspam, Off
return

^+!Ü::	; ITRTG: campaignspam
if (campaignspam := !campaignspam) {
	if !(WinExist("ahk_exe Idling to Rule the Gods.exe")) {
		campaignspam := 0
		return
	}
	camp := determineCampaign()
	if (camp = -1) {
		campaignspam := 0
		return
	}
	WinGet, idlid, ID, ahk_exe Idling to Rule the Gods.exe
	cspamvar := Func("CampaignSpam").Bind(camp, idlid, 1)
;	CampaignSpam(camp, idlid, 2)
	BlockInput, MouseMove
	SystemCursor("Off")
	SetTimer, %cspamvar%, 50
}
else {
	SetTimer, %cspamvar%, Off
	Sleep(125)
	CampaignSpam(camp, idlid, 3)
	BlockInput, MouseMoveOff
	SystemCursor("On")
}
return
#HotIf
;[style]}-----
*/
#HotIf WinActive("ahk_class Photo_Lightweight_Viewer")
;[style]{----- Fotoanzeige
^T::{	; Fotoanzeige: StrgT->ShiftEsc
	Send("!{Esc}")
}

^W::{	; Fotoanzeige: StrgW->AltF4
	Send("!{F4}")
}
#HotIf

;[style]}
;[style]} ______________________________________________________________________________________________
;[style]							: WINDOWS 
;[style]{ ______________________________________________________________________________________________

!LButton::{	; Drag Window 
	AltDrag.moveWindow(A_ThisHotkey)
}

!RButton::{	; Resize Window 
	AltDrag.resizeWindow(A_ThisHotkey)
}

!MButton::{	; Toggle Max/Restore of clicked window
	AltDrag.toggleMaxRestore()
}

!WheelDown::{	; Scale Window Down
	AltDrag.scaleWindow(-1)
}

!WheelUp::{	; Scale Window Up
	AltDrag.scaleWindow(1)
}

^NumpadMult::{	; Show Mouse Coordinates
	static toggle := false
	if (toggle := !toggle)
		SetTimer(showcoords, 50)
	else {
		SetTimer(showcoords, 0)
		Tooltip()
	}
}

^!H::{	; Make Window Circle Visible
	static toggle := false, circleWindow
	if (toggle := !toggle) {
		MouseGetPos(&xPosCircle, &yPosCircle, &circleWindow)
		xPosCircle -= 100
		yPosCircle -= 100
		WinSetRegion(xPosCircle "-" yPosCircle " w200 h200 E", "ahk_id " circleWindow)
		WinSetStyle("-0xC00000", "ahk_id " circleWindow) ; make it alwaysonTop
		;	MsgBox, %xPosCircle%, %yPosCircle%, ahk_id %circleWindow%
	}
	else {
		WinSetRegion(,"ahk_id " circleWindow)
		WinSetStyle("+0xC00000", "ahk_id " circleWindow)
	}
}


^!+I::{ ; Center & Adjust Active Window
	if WinActive("ahk_group cornerMusicPlayers")
		WinMove(-600, 550, 515, 550)
	else if WinActive("Discord ahk_exe Discord.exe")
		WinMove(-1497, 129, 1292, 769)
	else
		center_window_on_monitor(WinExist("A"), 0.8)
}

^!+H::{ ; Make Active Window Transparent
	static toggle := false
	if (toggle:= !toggle)
		WinSetTransparent(120, "A") 
	else
		WinSetTransparent("Off", "A")
}

^+H::{ ; Make Taskbar invisible 
	TransparentTaskbar.setInvisibility("T", 0)
}

<^>!M::{		; Minimizes Active Window
	static toggle := false, winToggleID
	if (toggle := !toggle) {
		winToggleID := WinGetID("A")
		WinMinimize(winToggleID)
	}
	else {
		mmx := WinGetMinMax(winToggleID)
		if (WinActive(winToggleID) && mmx != -1) {
			WinMinimize(winToggleID)
			toggle := !toggle
		}
		else
			WinRestore(winToggleID)
	}
}

;[style]} ______________________________________________________________________________________________
;[style]							: EXPERIMENTAL / TESTING / TEMPORARY
;[style]{ ______________________________________________________________________________________________
^+!F11::{ ; Block keyboard input until password "password123" is typed
	;blockInput(true, "password123")
	RunAsAdmin()
	password := "password123" 
	for key in ["CTRL","SHIFT","ALT"]
		KeyWait(key)
	BlockInput(1)
	hook := InputHook("C*",,password)
	hook.Start()
	hook.Wait()
	BlockInput(0)
}


;[style]} ______________________________________________________________________________________________
;[style]			FUNCTIONS		: GUI / WINDOW CONTROL
;[style]{ ______________________________________________________________________________________________

showcoords() {
	CoordMode("Mouse", "Screen")
	MouseGetPos(&ttx, &tty, &ttWin)
	ttc := PixelGetColor(ttx, tty)
	ttWinT := WinGetTitle("ahk_id " . ttWin)
	Tooltip(ttx ", " tty ", " ttc "`n" ttWinT)
}

winSlowMove(hwnd, endX := "", endY := "", endW := "", endH := "", speed := 1) {
	WinDelay:=A_WinDelay
	SetWinDelay(-1)
	mmx := WinGetMinMax("ahk_id " hwnd)
	if (mmx == 1 || mmx == -1)
		return
	if (endX == "" && endY == "" && endW == "" && endH == "")
		return
	WinGetPos(&iniX, &iniY, &iniW, &iniH, "ahk_id " hwnd)
	if (speed == 0) {
		WinMove(endX, endY, endW, endH, "ahk_id " hwnd)
	} else {
		iter := Ceil(((endX != "" ? Abs(iniX-endX) : 0)+(endY != "" ? Abs(iniY-endY) : 0)+(endW != "" ? Abs(iniW-endW) : 0)+(endH != "" ? Abs(iniH-endH) : 0))/(speed))
		tX := (endX != "" ? (endX-iniX) : 0)
		tY := (endY != "" ? (endY-iniY) : 0)
		tW := (endW != "" ? (endW-iniW) : 0)
		tH := (endH != "" ? (endH-iniH) : 0)
		Loop(iter)
		{
			sT := (1-cos(A_Index/iter*3.1415926))/2
			WinMove(iniX+tX*sT, iniY+tY*sT, iniW+tW*sT, iniH+tH*sT, "ahk_id " hwnd)
		}
	}
	SetWinDelay(WinDelay)
}

center_window_on_monitor(hwnd, size_percentage := 0.714286) {
	NumPut("Uint", 40, monitorInfo := Buffer(40))
	monitorHandle := DllCall("MonitorFromWindow", "Ptr", hwnd, "UInt", 0x2, "Ptr")
	DllCall("GetMonitorInfo", "Ptr", monitorHandle, "Ptr", monitorInfo)
	
	workLeft      := NumGet(monitorInfo, 20, "Int") ; Left
	workTop       := NumGet(monitorInfo, 24, "Int") ; Top
	workRight     := NumGet(monitorInfo, 28, "Int") ; Right
	workBottom    := NumGet(monitorInfo, 32, "Int") ; Bottom
	WinRestore("ahk_id " hwnd)
	WinMove(workLeft + (workRight - workLeft) * (1 - size_percentage) / 2 ; // left edge of screen + half the width of it - half the width of the window, to center it.
				 , workTop + (workBottom - workTop) * (1 - size_percentage) / 2  ; // same as above but with top bottom
				 , (workRight - workLeft) * size_percentage	; // width
				 , (workBottom - workTop) * size_percentage	; // height
				 , "ahk_id " hwnd)
}

;[style]} ______________________________________________________________________________________________
;[style]							: STANDARD
;[style]{ ______________________________________________________________________________________________

;// moved to own scripts
runAsAdmin() {
	params := ""
	for i, e in A_Args  ; For each parameter:
		params .= A_Space . e
	if !A_IsAdmin
	{
		if A_IsCompiled
			DllCall("shell32\ShellExecute", "uint", 0, "str", "RunAs", "str", A_ScriptFullPath, "str", params , "str", A_WorkingDir, "int", 1)
		else
			DllCall("shell32\ShellExecute", "uint", 0, "str", "RunAs", "str", A_AhkPath, "str", '"' . A_ScriptFullPath . '"' . A_Space . params, "str", A_WorkingDir, "int", 1)
		ExitApp()
	}
}
	
connectNextDNS() {
	whr := ComObject("WinHttp.WinHttpRequest.5.1")
	whr.Open("GET", "https://link-ip.nextdns.io/8b77eb/e2c727ac3ea569ce", true)
	whr.Send()
	whr.WaitForResponse()
	return whr.ResponseText
}

clipboardTracker(type) {
	try {
		if (type == 1) {
			if (StrLen(A_Clipboard) < 200) {
				if (RegexMatch(A_Clipboard, "youtube\.com\/shorts\/([0-9a-zA-Z\_\-]+)")) {
					A_Clipboard := RegexReplace(A_Clipboard, "youtube\.com\/shorts\/([0-9a-zA-Z\_\-]+)", "youtube.com/watch?v=$1")
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

internetConnectionLogger(mode := "T", path := "") {
	static internetConsolePID
	static logFile
	mode := SubStr(mode, 1, 1)
	if (mode == "I") {
		if (path)
			logFile := path
		DetectHiddenWindows(1)
		if (WinExist("INTERNET_LOGGER"))
			internetConsolePID := WinGetPID("INTERNET_LOGGER")
		else {
			Run(A_ComSpec .  ' /c "title INTERNET_LOGGER && mode con: cols=65 lines=10 && powershell C:\Users\Simon\Desktop\programs\programming\bat\internetLogger.ps1 -path "' . logFile . '""',,"Hide", &internetConsolePID)
			WinWait("INTERNET_LOGGER")
			WinSetAlwaysOnTop(1, "INTERNET_LOGGER")
		}
		DetectHiddenWindows(0)
		fileMenu := TrayMenu.submenus["Files"]
		fileMenu.Add("Open Internet Log", openFile.Bind(logFile, "notepad++"))
		A_TrayMenu.Add("Files", fileMenu)
	}
	else {
		if (mode == "T")
			mode := (WinExist("INTERNET_LOGGER") ? "C" : "O")
		if (mode == "C")
			WinHide("ahk_pid " . internetConsolePID)
		else if (mode == "O")
			WinShow("ahk_pid " . internetConsolePID)
	}
	return
}

openFile(filePath, program := "notepad", *) {
	Run(program . ' "' . filePath . '"')
}

;[style]}______________________________________________________________________________________________
;[style]							: MENU
;[style]{ ______________________________________________________________________________________________

;// AHK SCRIPT TRAY MENU

createBetterTrayMenu() {
	suspendMenu := Menu()
	TrayMenu.submenus["SuspendMenu"] := suspendMenu
	suspendMenu.Add("Suspend Hotkeys", trayMenuHandler)
	suspendMenu.Add("Suspend Reload", trayMenuHandler)
	suspendMenu.Default := "Suspend Reload"
	A_TrayMenu.Add("Open Recent Lines", trayMenuHandler)
	A_TrayMenu.Add("Help", trayMenuHandler)
	A_TrayMenu.Add()
	A_TrayMenu.Add("Window Spy", trayMenuHandler)
	A_TrayMenu.Add("Reload this Script", trayMenuHandler)
	A_TrayMenu.Add("Edit in Notepad++", trayMenuHandler)
	A_TrayMenu.Add()
	A_TrayMenu.Add("Pause Script", trayMenuHandler)
	A_TrayMenu.Add("Suspend/Stop", suspendMenu)
	A_TrayMenu.Add("Exit", trayMenuHandler)
	A_TrayMenu.Default := "Open Recent Lines"
}

trayMenuHandler(itemName, *) {
	suspendMenu := TrayMenu.submenus["SuspendMenu"]
	switch itemName {
		case "Open Recent Lines":
			ListLines()
		case "Help":
			str := RegexReplace(A_AhkPath, "[^\\]+\.exe$", "AutoHotkey.chm")
			Run(str)
			WinWait("AutoHotkey v2 Help")
			center_window_on_monitor(WinExist("AutoHotkey v2 Help"), 0.8)
		case "Window Spy":
			if !WinExist("Window Spy") {
				str := RegexReplace(A_AhkPath, "v2\\[^\\]+.exe$", "WindowSpy.ahk")
				Run(str)
			}
			else
				WinActivate("Window Spy")
		case "Reload this Script":
			Reload()
		case "Edit in Notepad++":
			tryEditTextFile(A_ScriptFullPath)
		case "Pause Script":
			A_TrayMenu.ToggleCheck("Pause Script")
			Pause(-1)
		case "Suspend Hotkeys":
			suspendMenu.ToggleCheck("Suspend Hotkeys")
			Suspend(-1)
			if (A_IsSuspended)
				TraySetIcon("C:\Users\Simon\Desktop\programs\Files\Icons\Potet Think Warn.ico",, true)
			else
				TraySetIcon("C:\Users\Simon\Desktop\programs\Files\Icons\Potet Think.ico",, true)
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


;[style]} ______________________________________________________________________________________________
;[style]							: GAMES / SIMPLE TIMERS
;[style]{ ______________________________________________________________________________________________

;	----- BTD6 -----
;[style]{	----------------


;[style]} -----

;	----- NGU  -----
;[style]{	----------------

;[style]}	----- 

;	-- Geometry Arena --
;[style]{	--------------------


;[style]}	-----

;   -- Jigsaw Puzzles --
;[style]{  --------------------
/*


findplace_piece(x,y,x2,y2) {
	SendMode Event
	MouseClickDrag, Left,,,x,y
	Loop % (x2-x)/78 + 1
	{
		xp := A_Index
		Loop % (y2-y)/78
		{
			MouseClickDrag, Left,,,0,78,,R
			Sleep(10)
		}
		MouseClickDrag, Left,,,x+xp*78,y
		Sleep(10)
	} 
	SendMode Input
}
*/
;[style]}  -----

;	-- ITRTG --
;[style]{	-----------
/*


CampaignSpam(campaign, idlid, mode := 0) { ;// mode 0: permanently restart, mode 1: permanently Select -> Auto, mode 2: prepare for mode 0, mode 3: end mode 0
		Critical
		sleepTime := 9
		if (campaign = -1 || !campaign)
			return
		y := 209+campaign*76
		yt := y+50
		if (mode = 0) {
			StupiClick(1070, y+50, idlid, sleepTime)
			Sleep(sleepTime)
			StupiClick(1270, 820, idlid, sleepTime)
			Sleep(sleepTime)
		}
		if (mode = 1 || mode = 2) {
			StupiClick(1250, y, idlid, sleepTime)
			Sleep(sleepTime)
			StupiClick(1260, 400, idlid, sleepTime)
			Sleep(sleepTime)
		}
		if (mode = 1 || mode = 3) {
			StupiClick(1260, y+50, idlid, sleepTime)
			Sleep(sleepTime)
		}
		StupiClick(940, 935, idlid, sleepTime)
}

StupiClick(x, y, id, sleepTime) {
	;// this function exists for poorly designed interfaces that check coordinates for buttonclicking
	WinGetPos, xca, yca,,, A
	WinGetPos, xit, yit,,, ahk_id %id%
	MouseMove, xit-xca+x, yit-yca+y,0
	Sleep(25) ; %sleepTime%
	ControlClick, x%x% y%y%, ahk_id %id%,,,, NA
}

determineCampaign(y := -1) {
	if (y = -1)
		MouseGetPos,,y, win
	WinGet, t_win, ID, ahk_exe Idling to Rule the Gods.exe
	if (win != t_win)
		InputBox, d, Campaign, Enter the Campaign Number:`n1 - Growth`, 2 - Divinity`, 3 - Food`, 4 - Item`n5 - Level`, 6 - Multiplier`, 7 - God Power`nNote: This will make your mouse virtually inaccessible during this hotkey
	else 
		d := Ceil((y - 247) / 76)
	if (d < 1) or (d > 7)
		return -1
	return d
}

dungeonspam() {
	x := 320 + 80*   2	;//newbie: 400, scrapyard: 480, water temple: 560, volcano: 640, mountain: 720, forest: 800
	MouseClick, Left, 1130, x
	Sleep(50)
	MouseClick, Left, 1730, 990
	Sleep(50)
	MouseClick, Left, 1300, x
	Sleep(500)
	MouseClick, Left, 1715, 280
}
*/
;[style]}----

closeWinRarNotification() {
	Loop {
		WinWait("ahk_group rarReminders")
		WinClose("ahk_group rarReminders")
	}
}

;[style]} ______________________________________________________________________________________________
;[style]			HOTSTRINGS		: HOTKEYS FOR HOTSTRINGS
;[style]{ ______________________________________________________________________________________________

^+!F12::{ ; Toggles LaTeX Hotstrings
	LatexHotstrings()
}

;[style]} ______________________________________________________________________________________________
;[style]							: ACTUAL HOTSTRINGS
;[style]{ ______________________________________________________________________________________________

;						: EXPANSION	: COMPLICATED STRINGS
;[style]{ --------------------------------
:*:@potet::{
	fastPrint("<@245189840470147072>")
}
:*:@burny::{
	fastPrint("<@318350925183844355>")
}
:*:@Y::{
	fastPrint("<@354316862735253505>")
}
:*:@zyntha::{
	fastPrint("<@330811222939271170>")
}
:*:@astro::{
	fastPrint("<@193734142704353280>")
}
:*:@rein::{
	fastPrint("<@315661562398638080>")
}
::from:me::{
	fastPrint("from:245189840470147072 ")
}


;[style]} 
;									: SPECIAL SYMBOLS / LaTeX
;[style]{ --------------------------------

; // all of these can be toggled via ctrl alt shift F12, remember to add those to the list.


; // other stuff, not toggleable
:*?:=/=::≠
:*?:+-::±
:*?:~=::≈
:*:\ß::ẞ
:*:\disap::ಠ_ಠ 

;[style]}
;						: AUTOCORRECT	: ENGLISH
;[style]{ --------------------------------
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
;[style]}
; 						: OTHER
;[style]{ --------------------------------

; :*:!!!!::{!}{!}{!}1{!}111{!}one1{!}{!}eleven{!}{!}
; :*b0:**::**{left 2} ; bold in markdown
; :*b0:__::__{left 2} ; underlined in markdown

;[style]}

;[style]} ______________________________________________________________________________________________
;[style]			DEPRECATED : HOTKEYS
;[style]{ ______________________________________________________________________________________________


;[style]} ______________________________________________________________________________________________
;[style]			DEPRECATED : FUNCTIONS
;[style]{ ______________________________________________________________________________________________ 


;[style]} ______________________________________________________________________________________________
;[style]			EVERYTHING HERE WAS ADDED AFTERWARDS OR_ MODIFIED AUTOMATICALLY
#HotIf ; DON'T REMOVE THIS, THE AUTOMATIC HOTKEYS SHOULD ALWAYS BE ACTIVE



^+!Ä::{	; Reload other script
	PostMessage(0x111, 65303,,"ahk_id " 0x408f2)
}



^m::{ ; Get Permutations
	A_Clipboard := getAllPermutations("12345", "abcde")
}


getAllPermutations(str1, str2) {
	if (StrLen(str1) != StrLen(str2))
		return
	n := StrLen(str1)
	str2Arr := StrSplit(str2)
	arr := [str1]
	Loop(n)
	{
		i := A_Index
		arr2 := []
		for j, e in arr
			arr2.push(SubStr(str1, 1, -1 * i) . str2Arr[n-i+1] . SubStr(e, n-i+2))
		arr.push(arr2*)
	}
	for i, e in arr
		out .= e "`n"
	return out
}

clickloop(rows, columns, rHeight, cWidth) {
	MouseGetPos(&initialX, &initialY)
	Loop(rows) {
		i := A_Index - 1
		Loop(columns) {
			j := A_Index - 1
			MouseClick("L", initialX+j*cWidth, initialY+i*rHeight)
			Sleep(10)
		}
	}
	return
}


arrToString(array, separator := ",", elementConditionRegex := ".*") {
	; NEED TO CHECK WHETHER OR NOT a) IS KEYARRAY or b) NESTED ARRAY. FIX b BY RECURSIVELY CALLING arrToString for e (and also regexmatching that), BY CHECKING IF array is just string at start.
	str := "["
	for i, e in array
		if (RegexMatch(e, elementConditionRegex))
			str .= e . separator
	return SubStr(str, 1, -1) . "]"
}

sendRequest(url := "https://icanhazip.com/", method := "GET") {
	HttpObj := ComObject("WinHttp.WinHttpRequest.5.1")
	HttpObj.Open(method, url)
	HttpObj.Send()
	return Trim(httpobj.ResponseText, "`n`r`t ")
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

^l::{ ; Make colorful Text
	text := fastCopy()
	text := makeTextAnsiColorful(text)
	fastPrint(text)
}


^+F10::{ ; Show/Hide Taskbar
	static hide := false
	HideShowTaskbar(hide := !hide)
}

HideShowTaskbar(action) {
   static ABM_SETSTATE := 0xA, ABS_AUTOHIDE := 0x1, ABS_ALWAYSONTOP := 0x2
   APPBARDATA := Buffer(size := 2*A_PtrSize + 2*4 + 16 + A_PtrSize, 0)
   NumPut("Uint", size, APPBARDATA)
   NumPut("Ptr", WinExist("ahk_class Shell_TrayWnd"), APPBARDATA, A_PtrSize)
   NumPut("Uint", action ? ABS_AUTOHIDE : ABS_ALWAYSONTOP, APPBARDATA, size - A_PtrSize)
   DllCall("Shell32\SHAppBarMessage", "UInt", ABM_SETSTATE, "Ptr", APPBARDATA)
}




^O::{ ; Load Latex Hotstrings
	HotstringLoader.load(A_WorkingDir . "\everything\LatexHotstrings_ahk2.json", "LatexHotstrings")
}

