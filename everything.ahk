/*


THIS SCRIPT IS FROM 2019 AND MADE FOR V1.1, AS WELL AS INCLUDING A LOT OF LEGACY SYNTAX 
IT MAY BE ENTIRELY UNUSABLE
everything v2.ahk IS THE CLEANED UP VERSION OF THIS





*/










;  ______________________________________________________________________________________________
;[style]			INITILIZATION	: MODES
;[style]{ ______________________________________________________________________________________________
#NoEnv ;// Compatibility for future and optimization blabla
#KeyHistory 500
#Persistent
#UseHook
SendMode Input ; // Faster
SetTitleMatchMode, 2 ;// Must Match Exact Title (1 = start with specified words, 2 = contains words, 3 = match words exactly)
; CoordMode,Mouse,Window ;// Coordinates for Click are relativ to upper left corner of active Window (Look TimeClickers hotkey/Timer for usage)
; CoordMode,ToolTip,Window ;// both this and above are the default anyway, leaving for future reference
; Thread, NoTimers	;// thread doesn't get interrupted by timers. since i now have two timers, this blocks one of them, making it fail.
#MaxHotkeysPerInterval 5000
;// this would change the standard editing program for ahk to n++, but i changed the tray menu anyway so it works.
; RegWrite REG_SZ, HKCR, AutoHotkeyScript\Shell\Edit\Command,, C:\Program Files (x86)\Notepad++\notepad++.exe `%1 
;// unnecessary usually
; DetectHiddenWindows, On
;[style]} ______________________________________________________________________________________________
;[style]							: SUB FILES
;[style]{ ______________________________________________________________________________________________

if !InStr(FileExist("script_files\everything"), "D")
	FileCreateDir, % "script_files\everything"
SetWorkingDir %A_ScriptDir%\script_files ; \everything
#Include %A_ScriptDir%\Libraries\TransparentTaskbar.ahk 
#Include %A_ScriptDir%\Libraries\HotkeyManager.ahk 
#Include %A_ScriptDir%\Libraries\WindowManager.ahk
#Include %A_ScriptDir%\Libraries\ReminderManager.ahk
#Include %A_ScriptDir%\Libraries\NeoKeyboardLayout.ahk
#Include %A_ScriptDir%\Libraries\YoutubeDLGui.ahk
#Include %A_ScriptDir%\Libraries\TextEditMenu.ahk
#Include %A_ScriptDir%\Libraries\MacroRecorder.ahk
#Include %A_ScriptDir%\Libraries\TimestampConverter.ahk
#Include %A_ScriptDir%\Libraries\DiscordClient.ahk
#Include %A_ScriptDir%\Libraries\DiscordBotCommands.ahk
#Include %A_ScriptDir%\Libraries\AltDrag.ahk
#Include %A_ScriptDir%\Libraries\MathUtilities.ahk
#Include %A_ScriptDir%\Libraries\ColorUtilities.ahk
#Include %A_ScriptDir%\Libraries\BasicUtilities.ahk

#Include %A_ScriptDir%\Libraries\JSON.ahk

;[style]} ______________________________________________________________________________________________
;[style]							: VARIABLES
;[style]{ ______________________________________________________________________________________________

;// for windows in which ctrl+ should replace scrolling cause it sucks
GroupAdd, zoomableWindows, ahk_exe Mindustry.exe
;// for windows that should be put in the corner when ctrlaltI'd
GroupAdd, cornerMusicPlayers, % "VLC media player ahk_exe vlc.exe",,, % "Wiedergabeliste"
GroupAdd, cornerMusicPlayers, % "Daum PotPlayer ahk_exe PotPlayerMini64.exe",,, % "Einstellungen"
GroupAdd, cornerMusicPlayers, % "foobar2000 ahk_exe foobar2000.exe",,, % "Scratchbox"

;[style]} ______________________________________________________________________________________________
;[style]							: STARTING FUNCTIONS
;[style]{ ______________________________________________________________________________________________
;// moved it all to functions
;// set 1337 reminder
if (DllCall("GetCommandLine", "str") == """" . A_AhkPath . """ /restart /script """ . A_scriptFullPath . """")
	SCRIPTVAR_WASRELOADED := 1
ReminderManager.initialize(0, 0, readFileIntoVar(A_WorkingDir . "\discordBot\discordBotToken.token"))
ReminderManager.setSpecificTimer("1337reminder", "", , , 13,36,50)
;ReminderManager.setSpecificTimer(,"test message", , , 0,42,0)
ReminderManager.setSpecificTimer("discordReminder", "GO SLEEP", , , 4,0,0,,,"245189840470147072")
; ReminderManager.setSpecificTimer(func, msg, multi, period, h,m,s,d,mo, target)
Menu, Timers, Add, 1337 Timer: On, doNothing
Menu, Timers, Disable, 1337 Timer: On
Menu, Timers, Check, 1337 Timer: On
;// transparent taskbar ini
TransparentTaskbar.TransparentTaskbar(1,,,50)
;// start clipboardwatcher
OnClipboardChange("clipboardTracker", 1)
;// Initialize System Cursor Files
SystemCursor("I")
;// better icon
try
	Menu, Tray, Icon, % A_Desktop "\programs\Files\Icons\Potet Think.ico",,1
;// Timer because new Thread
GroupAdd, rarReminders, ahk_class RarReminder
GroupAdd, rarReminders, Please purchase WinRAR license ahk_class #32770
SetTimer, closeWinRarNotification, -100, -100000 ; priority -100k so it doesn't interrupt
;// Initialize Internet Logging Script
internetConnectionLogger("Init", A_Desktop "\programs\programming\bat\log.txt")
;// Synchronize nextDNS IP
if (!SCRIPTVAR_WASRELOADED)
	timedTooltip(connectNextDNS(),4000)
;// Initialize LaTeX Hotstrings
LatexHotstrings(1)
;// replace the tray menu with my own
createBetterTrayMenu()
OnExit("exit")
return
	
;[style]} ______________________________________________________________________________________________
;[style]			HOTKEYS	 		: CONTROL
;[style]{ ______________________________________________________________________________________________

^+R:: ; Reload Script
reload()
return

#IfWinNotActive ahk_exe csgo.exe
^+LButton::	; Text Modification Menu
	Menu, textModify, Show
return
#IfWinActive

^U::	; Time/Date Converter
	textTimestampConverter(A_ThisHotkey)
return

^I::	; Show Hex code as Color
	hexcodeColorPreview(A_ThisHotkey)
return

^+!NumpadSub::	; Record Macro
	createMacro(A_ThisHotkey)
return

^F12:: ; Toggle Hotkey Manager
HotkeyManager("T")
return

+F11:: ; Shows a list of all Windows
WindowManager.windowManager("T")
return

^F10::	; Neokeyboard Layout
NeoKeyboardLayout.KeyboardLayoutGUI("T")
return

^F9::	; Shows Internet Connection
internetConnectionLogger("T")
return

^F8::	; Shows Reminder GUI
ReminderManager.ReminderManagerGUI("T")
return

^+K:: ; Toggle Taskbar Transparency
TransparentTaskbar.transparentTaskbar("T")
return

^+F11:: ; Gives Key History
ListLines
return

^+F10::	; YTDL GUI
YoutubeDLGui.YoutubeDLGui("T")
return

^!Numpad0::	; Toggle NumpadKeys to Move Cursor
toggleNumpadMouseMove()
return

toggleNumpadMouseMove() {
	static init
	if !(init) {
		fn := Func("moveMousePixel")
		f := fn.bind(0, 1)
		Hotkey, Numpad2, % f
		f := fn.bind(-1,0)
		Hotkey, Numpad4, % f
		f := fn.bind(1, 0)
		Hotkey, Numpad6, % f
		f := fn.bind(0,-1)
		Hotkey, Numpad8, % f
		f := Func("clickMouse").Bind("L")
		Hotkey, NumpadEnter, % f
		f := Func("clickMouse").Bind("L", 1)
		Hotkey, NumpadAdd, % f
		init := 1
		return
	}
	Hotkey, Numpad2, % "Toggle"
	Hotkey, Numpad4, % "Toggle"
	Hotkey, Numpad6, % "Toggle"
	Hotkey, Numpad8, % "Toggle"
	Hotkey, NumpadEnter, % "Toggle"
	Hotkey, NumpadAdd, % "Toggle"
}

moveMousePixel(x,y) {
	MouseMove, % x, % y,,R
}

clickMouse(b, press := 0) {
	b := SubStr(b, 1, 1)
	if (press)
		st := GetKeyState(b . "Button") ? "U" : "D"
	MouseClick, % b, , , , , % st
}


^LWin Up:: ; Replace Windows Search with EverythingSearch
	Run, % "everything.exe -newwindow", % "C:\Program Files\Everything"
	WinWaitActive, % "ahk_exe C:\Program Files\Everything\Everything.exe"
	WinGet, hwnd, ID
	WinGet, mmx, MinMax, ahk_id %hwnd%
	if (mmx == 1 || mmx == -1)
		WinRestore, ahk_id %hwnd%
	winSlowMove(hwnd,40,400,784,648,8)
	WinWaitNotActive
	WinClose
return

#IfWinActive, ahk_exe C:\Program Files\Everything\everything.exe
	^LWin Up:: ; Close EverythingSearch if its active
		WinClose, ahk_exe C:\Program Files\Everything\Everything.exe
	return
#IfWinActive 

#IfWinActive ahk_exe vlc.exe
	^D::		; VLC: Open/Close Media Playlist
		SetControlDelay -1 
		WinGet, vlcid, ID, VLC media player,, Wiedergabeliste
		WinGetPos,,,, vlcH, ahk_id %vlcid%
		controlY := vlcH - 49
		ControlSend, ahk_parent, {Esc}, ahk_id %vlcid%
		ControlClick, X222 Y%controlY%, ahk_id %vlcid%,,,, Pos NA
	return
#IfWinActive

;[style]} ______________________________________________________________________________________________
;[style]					 		: STANDARD / GAMES
;[style]{ ______________________________________________________________________________________________

^!K::	; Evaluate Shell Expression in-text
	calculateExpression("c")
return

^+!NumpadEnter::	; Launch Autoclicker
Run, % A_Desktop "\Autoclicker\AutoClickerPos.exe"
return

#IfWinActive ahk_group zoomableWindows
;[style]{----- Zoomable Windows
^+::	; Zoomable: Zoom in
Send, {WheelUp}
return

^-::	; Zoomable: Zoom out
Send, {WheelDown}
return
#IfWinActive
;[style]}-----

/*
#IfWinActive ahk_exe BTD5-Win.exe
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
#IfWinActive
*/

;[style]}-----

#IfWinActive ahk_exe bloonstd6.exe
;[style]{----- Btd6

F11:: 	; BTD6: Rebind Escape
Send, {Escape}
return


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
	Sleep, 35
	MouseMove, ax, ay, 0
return

+D::	; BTD6: deposit money right
	MouseGetPos, ax, ay
	MouseClick, L, 1425, 370
	Sleep, 35
	MouseMove, ax, ay, 0
return
*/
^,::	; BTD6: press comma
if !(presscomma)
	presscomma := Func("presskey").Bind(",")
if (presscommaToggle := !presscommaToggle)
	SetTimer, %presscomma%, 30
else
	SetTimer, %presscomma%, Off
return

^.::	; BTD6: press dot
if !(pressdot)
	pressdot := Func("presskey").Bind(".")
if (pressdotToggle := !pressdotToggle)
	SetTimer, %pressdot%, 30
else
	SetTimer, %pressdot%, Off
return

^-::	; BTD6: press minus
if !(pressminus)
	pressminus := Func("presskey").Bind("-")
if (pressminusToggle := !pressminusToggle)
	SetTimer, %pressminus%, 30
else
	SetTimer, %pressminus%, Off
return

#IfWinActive

;[style]}-----
/*

#IfWinActive ahk_exe ICBING2k.exe
;[style]{----- I can't believe its not gambling 2
^P::	; ICBING2k: Open Lootboxes
if (icbingt := !icbingt)
	SetTimer, icbint, 300
else
	SetTimer, icbint, Off
return

icbint() {
	MouseMove, 950, 860
	Sleep, 20
	ControlClick, X950 Y860, ahk_exe ICBING2k.exe
}
#IfWinActive
;[style]}-----

#IfWinActive ahk_exe Pixel Puzzles Traditional Jigsaws.exe
;[style]{----- Jigsaw Puzzles
^+P::	; Jigsaw: Fit piece
findplace_piece(59,304,1868,952)
return
#IfWinActive
;[style]}-----

#IfWinActive ahk_exe Idling to Rule the Gods.exe
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
	Sleep, 125
	CampaignSpam(camp, idlid, 3)
	BlockInput, MouseMoveOff
	SystemCursor("On")
}
return
#IfWinActive
;[style]}-----
*/
#IfWinActive ahk_class Photo_Lightweight_Viewer
;[style]{----- Fotoanzeige
^T::	; Fotoanzeige: StrgT->ShiftEsc
Send, !{Esc}
return

^W::	; Fotoanzeige: StrgW->AltF4
Send, !{F4}
return
#IfWinActive

;[style]}
;[style]} ______________________________________________________________________________________________
;[style]							: WINDOWS 
;[style]{ ______________________________________________________________________________________________

!LButton::	; Drag Window 
AltDrag.moveWindow(A_ThisHotkey)
return

!RButton::	; Resize Window 
AltDrag.resizeWindow(A_ThisHotkey)
return

!MButton::	; Toggle Max/Restore of clicked window
AltDrag.toggleMaxRestore()
return

!WheelDown::	; Scale Window Down
AltDrag.scaleWindow(-1)
return

!WheelUp::	; Scale Window Up
AltDrag.scaleWindow(1)
return

!XButton1:: ; Minimize Window
AltDrag.minimizeWindow()
return


^NumpadMult::	; Show Mouse Coordinates
if (coordtoggle := !coordtoggle)
	SetTimer, showcoords, 50
else {
	SetTimer, showcoords, Off
	Tooltip
}
return

!NumpadMult::	; Toggle Mouse Cursor Visibility
SystemCursor("T")
return

^!H::	; Make Window Circle Visible
if (toggleExp := !toggleExp) {
	MouseGetPos, xPosCircle, yPosCircle, circleWindow
	xPosCircle -= 100
	yPosCircle -= 100
	WinSet, Region, %xPosCircle%-%yPosCircle% w200 h200 E, ahk_id %circleWindow%
	WinSet, Style, -0xC00000, ahk_id %circleWindow% ; make it alwaysonTop
;	MsgBox, %xPosCircle%, %yPosCircle%, ahk_id %circleWindow%
}
else {
	WinSet, Region,, ahk_id %circleWindow%
	WinSet, Style, +0xC00000, ahk_id %circleWindow%
}
return


^!+I:: ; Center & Adjust Active Window
if WinActive("ahk_group cornerMusicPlayers")
	WinMove,,, -600, 550, 515, 550
else if WinActive("Discord ahk_exe Discord.exe")
	WinMove,,, -1497, 129, 1292, 769
else
	center_window_on_monitor(WinExist("A"), 0.8)
return

^!+H:: ; Make Active Window Transparent
if (TranspToggle:= !TranspToggle)
	WinSet, Transparent, 120, A 
else
	WinSet, Transparent, Off, A
return

^+H:: ; Make Taskbar invisible 
TransparentTaskbar.setInvisibility("T", 0)
return

;[style]} ______________________________________________________________________________________________
;[style]							: EXPERIMENTAL / TESTING / TEMPORARY
;[style]{ ______________________________________________________________________________________________
^+!F11:: ; Block keyboard input until password "password123" is typed
;blockInput(true, "password123")
RunAsAdmin()
password := "password123" 
for key in ["CTRL","SHIFT","ALT"]
	KeyWait, % key
 BlockInput,On
Input,var,C*,, % password
BlockInput,Off
return


blockInput(o := false, pw := "password123") {
	static hHook
	for i, e in ["CTRL","SHIFT","ALT"]
		KeyWait, % e
	TrayTip, % "InputBlock" , % "Your Input is blocked. Type " . pw . " to unlock it."
	if (o) {
		blockInputCallBackHook(,,, pw)
	;	hHook := DllCall("SetWindowsHookExA"
	;		, "int", 13 ; WH_KEYBOARD_LL
	;		, "Uint", RegisterCallback("blockInputCallBackHook")
	;		, "Uint", 0
	;		, "Uint", 0)
		hHook := DllCall("SetWindowsHookEx"
		, "Ptr", WH_KEYBOARD_LL:=13
		, "Ptr", RegisterCallback("blockInputCallBackHook")
		, "Uint", DllCall("GetModuleHandle", "Uint", 0, "Ptr")
		, "Uint", 0, "Ptr")	
	}
	else {
		DllCall("UnhookWindowsHookEx", "uint", hHook)
		hHook := 0
	}
}

blockInputCallBackHook(nCode := "?", wParam := "?", lParam := "?", registerpassword := 0) {
	static pw, i := 0, j := 0
	Tooltip % "Keyname: " . nCode ", " wParam "," lParama "`n" NumGet(nCode+0,,"Uint") ", " NumGet(wParam+0,,"Uint") ", " NumGet(lParam+0,,"Uint") ", " j++
	
	if (registerpassword != 0)
		pw := registerpassword
	if (!(NumGet(lParam+0, 8, "UInt") & 0x80)) {
	    if(GetKeySC(SubStr(pw, count+1, 1)) == NumGet(lParam+0, 4, "UInt")) {
	        count++
	        if(count == StrLen(pw)) {
                count := 0
                blockInput(false)
            }
	    }
		else
			count := 0
    }
	return 1
}

^!+K:: ; Tiles Windows Vertically
shell := ComObjCreate("Shell.Application")
MsgBox, 1, ConfirmDialog, Tile Windows Vertically?, 10
IfMsgBox Ok
	shell.tileWindowsVertically()
tileCurrentWindows()
return


;[style]} ______________________________________________________________________________________________
;[style]			FUNCTIONS		: GUI / WINDOW CONTROL
;[style]{ ______________________________________________________________________________________________

showcoords() {
	CoordMode, Mouse, Screen
	MouseGetPos, ttx, tty, ttWin
	PixelGetColor, ttc, ttx, tty
	WinGetTitle, ttWinT, % "ahk_id " . ttWin 
	WinGetClass, ttWinCl, % "ahk_id " . ttWin
	Tooltip, % ttx ", " tty ", " ttc "`n" ttWinT "`n" ttWinCl
}

GetSharexHotkeys(ByRef ShareXKeys)	{ ; // experimental technically
	ShareXKeys := {}
	Loop {
		if(A_Index>2)
			loopvar := 104+2*A_Index
		else
			loopvar := 14+2*A_Index
		ControlGetText, Hotkey, WindowsForms10.BUTTON.app.0.14a68c4_r10_ad%loopvar%, ShareX - Hotkey-Einstellungen
		if (Hotkey = "")
			break
		ShareXKeys.push({"Key":Hotkey})
	}
	return ShareXKeys
}

tileCurrentWindows() { ; // why am i doing this 

;//	WHAT WE NEED TO DO:
;//	GET ALL CURRENTLY NOT MINIMIZED OR HIDDEN WINDOWS via WinGet:
;//	SO WINGET ALL WINDOWS ( just call getwindowinfo , also useful for coordinates later!)
;//	FILTER THIS LIST FOR HIDDEN WINDOWS! HOW? I HAVE NO IDEA!

	
}

TVClose(hwnd,HeightStep:=100,WidthStep:=100) { ; //Credit @ tmplinshi,Improved and Modified by AfterLemon, Modified for this script by me
	WinDelay:=A_WinDelay
	SetWinDelay,-1
	WinGetPos,x,y,w,h,ahk_id %hwnd%
	WinGet,S,Style,ahk_id %hwnd%
	Step:=(h-3)/HeightStep
	Step2:=(w-3)/WidthStep
	Loop,% HeightStep
		WinMove,ahk_id %hwnd%,,,% y:=y+(Step/2),,% h:=h-Step
	WinSet,Style,-0xC00000,ahk_id %hwnd%
	WinSet,Redraw,,ahk_id %hwnd%
	Loop,% WidthStep
		WinMove,ahk_id %hwnd%,,% x:=x+(Step2/2),,% w:=w-Step2
	WinClose,ahk_id %hwnd%
	SetWinDelay,%WinDelay%
}

winSlowMove(hwnd, endX := "", endY := "", endW := "", endH := "", speed := 1) {
	WinDelay:=A_WinDelay
	SetWinDelay,-1
	WinGet, mmx, MinMax, ahk_id %hwnd%
	if (mmx == 1 || mmx == -1)
		return
	if (endX == "" && endY == "" && endW == "" && endH == "")
		return
	WinGetPos, iniX, iniY, iniW, iniH, ahk_id %hwnd%
	if (speed == 0) {
		WinMove, ahk_id %hwnd%,, %endX%, %endY%, %endW%, %endH%
	} else {
		iter := Ceil(((endX != "" ? Abs(iniX-endX) : 0)+(endY != "" ? Abs(iniY-endY) : 0)+(endW != "" ? Abs(iniW-endW) : 0)+(endH != "" ? Abs(iniH-endH) : 0))/(speed))
		tX := (endX != "" ? (endX-iniX) : 0)
		tY := (endY != "" ? (endY-iniY) : 0)
		tW := (endW != "" ? (endW-iniW) : 0)
		tH := (endH != "" ? (endH-iniH) : 0)
		Loop % iter
		{
			sT := (1-cos(A_Index/iter*3.1415926))/2
			WinMove, ahk_id %hwnd%,, iniX+tX*sT, iniY+tY*sT, iniW+tW*sT, iniH+tH*sT
		}
	}
	SetWinDelay, %WinDelay%
}

center_window_on_monitor(hwnd, size_percentage := 0.714286) {
	VarSetCapacity(monitorInfo, 40), NumPut(40, monitorInfo)
	monitorHandle := DllCall("MonitorFromWindow", "Ptr", hwnd, "UInt", 0x2)
	DllCall("GetMonitorInfo", "Ptr", monitorHandle, "Ptr", &monitorInfo)
	
	workLeft      := NumGet(monitorInfo, 20, "Int") ; Left
	workTop       := NumGet(monitorInfo, 24, "Int") ; Top
	workRight     := NumGet(monitorInfo, 28, "Int") ; Right
	workBottom    := NumGet(monitorInfo, 32, "Int") ; Bottom
	WinRestore, ahk_id %hwnd%
	WinMove, ahk_id %hwnd%,, workLeft + (workRight - workLeft) * (1 - size_percentage) / 2 ; // left edge of screen + half the width of it - half the width of the window, to center it.
				 , workTop + (workBottom - workTop) * (1 - size_percentage) / 2  ; // same as above but with top bottom
				 , (workRight - workLeft) * size_percentage	; // width
				 , (workBottom - workTop) * size_percentage	; // height
}

SystemCursor(OnOff=1) {   ;// stolen from https://www.autohotkey.com/boards/viewtopic.php?t=6167 
	;// INIT = "I"/"Init", OFF = 0/"Off", TOGGLE = -1/"T"/"Toggle", ON = 1 
    static AndMask, XorMask, $, h_cursor
        ,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13 ; system cursors
        , b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12,b13   ; blank cursors
        , h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13   ; handles of default cursors
    if (OnOff = "Init" or OnOff = "I" or $ = "")       ; init when requested or at first call
    {
        $ = h                                          ; active default cursors
        VarSetCapacity( h_cursor,4444, 1 )
        VarSetCapacity( AndMask, 32*4, 0xFF )
        VarSetCapacity( XorMask, 32*4, 0 )
        system_cursors = 32512,32513,32514,32515,32516,32642,32643,32644,32645,32646,32648,32649,32650
        StringSplit c, system_cursors, `,
        Loop %c0%
        {
            h_cursor   := DllCall( "LoadCursor", "Ptr",0, "Ptr",c%A_Index% )
            h%A_Index% := DllCall( "CopyImage", "Ptr",h_cursor, "UInt",2, "Int",0, "Int",0, "UInt",0 )
            b%A_Index% := DllCall( "CreateCursor", "Ptr",0, "Int",0, "Int",0
                , "Int",32, "Int",32, "Ptr",&AndMask, "Ptr",&XorMask )
        }
    }
    if (OnOff = 0 or OnOff = "Off" or $ = "h" and (OnOff < 0 or OnOff = "Toggle" or OnOff = "T"))
        $ = b  ; use blank cursors
    else
        $ = h  ; use the saved cursors

    Loop %c0%
    {
        h_cursor := DllCall( "CopyImage", "Ptr",%$%%A_Index%, "UInt",2, "Int",0, "Int",0, "UInt",0 )
        DllCall( "SetSystemCursor", "Ptr",h_cursor, "UInt",c%A_Index% )
    }
}

;[style]} ______________________________________________________________________________________________
;[style]							: STANDARD
;[style]{ ______________________________________________________________________________________________

;// moved to own scripts
runAsAdmin() {
	Loop, %0%  ; For each parameter:
	{
		param := %A_Index%  ; Fetch the contents of the variable whose name is contained in A_Index.
		params .= A_Space . param
	}
	ShellExecute := A_IsUnicode ? "shell32\ShellExecute":"shell32\ShellExecuteA"

	if not A_IsAdmin
	{
		If A_IsCompiled
			DllCall(ShellExecute, uint, 0, str, "RunAs", str, A_ScriptFullPath, str, params , str, A_WorkingDir, int, 1)
		Else
			DllCall(ShellExecute, uint, 0, str, "RunAs", str, A_AhkPath, str, """" . A_ScriptFullPath . """" . A_Space . params, str, A_WorkingDir, int, 1)
		ExitApp
	}
}
	
connectNextDNS() {
	whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	whr.Open("GET", "https://link-ip.nextdns.io/8b77eb/e2c727ac3ea569ce", true)
	whr.Send()
	whr.WaitForResponse()
	return whr.ResponseText
}

clipboardTracker(type) {
	try {
		if (type == 1) {
			if (StrLen(Clipboard) < 200) {
				if (RegexMatch(Clipboard, "youtube\.com\/shorts\/([0-9a-zA-Z\_\-]+)")) {
					Clipboard := RegexReplace(Clipboard, "youtube\.com\/shorts\/([0-9a-zA-Z\_\-]+)", "youtube.com/watch?v=$1")
				}
				else if (RegexMatch(Clipboard, "(?:https:\/\/)?(?:www\.)?reddit\.com\/media\?url=https%3A%2F%2F(?:i|preview)\.redd\.it%2F(.*)\.([^\s?%]*)[\?|%]?\S*")) {
					Clipboard := RegexReplace(Clipboard, "(?:https:\/\/)?(?:www\.)?reddit\.com\/media\?url=https%3A%2F%2F(?:i|preview)\.redd\.it%2F(.*)\.([^\s?%]*)[\?|%]?\S*", "https://i.redd.it/$1.$2")
				}
				else if (RegexMatch(Clipboard, "(?:https:\/\/)?(?:www\.)?preview\.redd\.it\/(.*)\.([^\s?%]*)[\?|%]?\S*")) {
					Clipboard := RegexReplace(Clipboard, "(?:https:\/\/)?(?:www\.)?preview\.redd\.it\/(.*)\.([^\s?%]*)[\?|%]?\S*", "https://i.redd.it/$1.$2")
				}
			}
		}
	} catch e {
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
		DetectHiddenWindows, 1
		if (WinExist("INTERNET_LOGGER"))
			WinGet, internetConsolePID, PID, % "INTERNET_LOGGER"
		else {
			Run, % ComSpec .  " /c ""title INTERNET_LOGGER && mode con: cols=65 lines=10 && powershell " A_Desktop "\programs\programming\bat\internetLogger.ps1 -path """ . logFile . """""",,Hide, internetConsolePID
			WinWait, % "INTERNET_LOGGER"
			WinSet, AlwaysOnTop,1, % "INTERNET_LOGGER"
		}
		DetectHiddenWindows, 0
		logFOobj := Func("openFile").Bind(logFile,"notepad++")
		Menu, Files, Add, Open Internet Log, % logFOobj
		Menu, Tray, Add, Files, :Files
		Menu, Tray, NoStandard
		Menu, Tray, Standard
	}
	else {
		if (mode == "T")
			mode := (WinExist("INTERNET_LOGGER") ? "C" : "O")
		if (mode == "C")
			WinHide, % "ahk_pid " . internetConsolePID
		else if (mode == "O")
			WinShow, % "ahk_pid " . internetConsolePID
	}
	return
}

openFile(filePath, program := "notepad") {
	Run, % program . " """ . filePath . """"
	return
}

;[style]}______________________________________________________________________________________________
;[style]							: MENU
;[style]{ ______________________________________________________________________________________________

;// AHK SCRIPT TRAY MENU

createBetterTrayMenu() {
	Menu, Tray, Add 
	Menu, Tray, Add, Open Recent Lines, trayMenuHandler
	Menu, Tray, Add, Help, trayMenuHandler
	Menu, Tray, Add
	Menu, Tray, Add, Window Spy, trayMenuHandler
	Menu, Tray, Add, Reload this Script, trayMenuHandler
	Menu, Tray, Add, Edit in Notepad++, trayMenuHandler
	Menu, Tray, Add
	Menu, Tray, Add, Pause Script, trayMenuHandler
	Menu, pauseSuspendMenu, Add, Suspend Hotkeys, trayMenuHandler
	Menu, pauseSuspendMenu, Add, Suspend Reload, trayMenuHandler
	Menu, Tray, Add, Suspend/Stop, :pauseSuspendMenu 
	Menu, Tray, Add, Exit, trayMenuHandler
	Menu, Tray, NoStandard
	Menu, Tray, Default, Open Recent Lines
}

trayMenuHandler(menuLabel) {
	switch menuLabel {
		case "Open Recent Lines":
			ListLines
			return
		case "Help":
			str := RegexReplace(A_AhkPath, "[^\\]+\.exe$", "AutoHotkey.chm")
			Run, %str%
			WinWait, AutoHotkey Help
			center_window_on_monitor(WinActive("AutoHotkey Help"), 0.8)
			return
		case "Window Spy":
			if !WinExist("Window Spy") {
				str := RegexReplace(A_AhkPath, "[^\\]+\.exe$", "WindowSpy.ahk")
				Run, %str%
			}
			else
				WinActivate, Window Spy
			return
		case "Reload this Script":
			reload()
		case "Edit in Notepad++":
			try {
				Run, Notepad++ %A_ScriptFullPath%
			} catch e {
				try {
					str := A_ProgramFiles . "\Notepad++\notepad++.exe " . A_ScriptFullPath
					Run, %str%
				} catch f {
					MsgBox, Could not find Notepad++ on your machine. Launching notepad.
					str := A_WinDir . "\system32\notepad.exe " . A_ScriptFullPath
					Run, %str%
				}
			}
			return
		case "Pause Script":
			Menu, Tray, ToggleCheck, Pause Script
			Pause
			return
		case "Suspend Hotkeys":
			Menu, pauseSuspendMenu, ToggleCheck, Suspend Hotkeys
			Suspend, Toggle
			if (A_IsSuspended)
				Menu, Tray, Icon, % A_Desktop "\programs\Files\Icons\Potet Think Warn.ico"
			else
				Menu, Tray, Icon, % A_Desktop "\programs\Files\Icons\Potet Think.ico"
			return
		case "Suspend Reload":
			Menu, pauseSuspendMenu, ToggleCheck, Suspend Reload
			Hotkey, ^+R, Toggle
			return
		case "Exit":
			exit()
	}
}

reload() {
	SystemCursor("On")
	Reload
}


exit() {
	SystemCursor("On")
	ExitApp
}


;[style]} ______________________________________________________________________________________________
;[style]							: GAMES / SIMPLE TIMERS
;[style]{ ______________________________________________________________________________________________

;	----- BTD6 -----
;[style]{	----------------
placeUpgradeTowerFromPause(towerHotkey, firstPath, secondPath := -1) {
	togglepause()
	placetowerAndSelect(towerHotkey)
	upgradeSelectedTower(firstPath[1], firstPath[2], firstPath[3])
	if (secondPath != -1)
		upgradeSelectedTower(secondPath[1], secondPath[2], secondPath[3])
	pauseFromSelect()
}

placeUpgradeTower(towerHotkey, firstPath, secondPath := -1) {
	placetowerAndSelect(towerHotkey)
	upgradeSelectedTower(firstPath[1], firstPath[2], firstPath[3])
	if (secondPath != -1)
		upgradeSelectedTower(secondPath[1], secondPath[2], secondPath[3])
}

togglepause() {
	Send, {Escape}
	Sleep, 100 ; 100
}

pauseFromSelect() {
	Send, {Escape}
	Sleep, 50 ; 50
	Send, {Escape}
}

selectSellTower() {
	MouseClick, Left
	Sleep, 50 ; 50
	Send, {Backspace}
	Sleep, 50 ; 50
}

selectTower() {
	MouseClick, Left
	Sleep, 50 ; 50
}

placetowerAndSelect(towerHotkey) {
	Send, %towerHotkey%
	Sleep, 100
	MouseClick, Left
	Sleep, 100
	MouseClick, Left
	Sleep, 100
}

upgradeSelectedTower(loop1, loop2, loop3) {
	Loop, %loop1% {
		SendRaw `,
		Sleep, 25	; 25	
	}
	Loop, %loop2% {
		SendRaw .
		Sleep, 25		
	}
	Loop, %loop3% {
		SendRaw -
		Sleep, 25		
	}
}

presskey(key) {
	Send, %key%
}

;[style]} -----

;	----- NGU  -----
;[style]{	----------------

;[style]}	----- 

;	-- Geometry Arena --
;[style]{	--------------------


;[style]}	-----

;   -- Jigsaw Puzzles --
;[style]{  --------------------

findplace_piece(x,y,x2,y2) {
	SendMode Event
	MouseClickDrag, Left,,,x,y
	Loop % (x2-x)/78 + 1
	{
		xp := A_Index
		Loop % (y2-y)/78
		{
			MouseClickDrag, Left,,,0,78,,R
			Sleep,10
		}
		MouseClickDrag, Left,,,x+xp*78,y
		Sleep,10
	} 
	SendMode Input
}

;[style]}  -----

;	-- ITRTG --
;[style]{	-----------

CampaignSpam(campaign, idlid, mode := 0) { ;// mode 0: permanently restart, mode 1: permanently Select -> Auto, mode 2: prepare for mode 0, mode 3: end mode 0
		Critical
		sleepTime := 9
		if (campaign = -1 || !campaign)
			return
		y := 209+campaign*76
		yt := y+50
		if (mode = 0) {
			StupiClick(1070, y+50, idlid, sleepTime)
			Sleep, %sleepTime%
			StupiClick(1270, 820, idlid, sleepTime)
			Sleep, %sleepTime%
		}
		if (mode = 1 || mode = 2) {
			StupiClick(1250, y, idlid, sleepTime)
			Sleep, %sleepTime%
			StupiClick(1260, 400, idlid, sleepTime)
			Sleep, %sleepTime%
		}
		if (mode = 1 || mode = 3) {
			StupiClick(1260, y+50, idlid, sleepTime)
			Sleep, %sleepTime%
		}
		StupiClick(940, 935, idlid, sleepTime)
}

StupiClick(x, y, id, sleepTime) {
	;// this function exists for poorly designed interfaces that check coordinates for buttonclicking
	WinGetPos, xca, yca,,, A
	WinGetPos, xit, yit,,, ahk_id %id%
	MouseMove, xit-xca+x, yit-yca+y,0
	Sleep, 25 ; %sleepTime%
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
	Sleep, 50
	MouseClick, Left, 1730, 990
	Sleep, 50
	MouseClick, Left, 1300, x
	Sleep, 500
	MouseClick, Left, 1715, 280
}
;[style]}----

closeWinRarNotification() {
	Loop {
		WinWait, ahk_group rarReminders
		WinClose, ahk_group rarReminders
	}
}

;[style]} ______________________________________________________________________________________________
;[style]			HOTSTRINGS		: HOTKEYS FOR HOTSTRINGS
;[style]{ ______________________________________________________________________________________________

^+!F12:: ; Toggles LaTeX Hotstrings
LatexHotstrings()
return

LatexHotstrings(OnOffToggle := -1) {
	static trayInit := 0
	if (!trayInit) {
		Menu, Tray, Add, Enable LaTeX Hotstrings, LatexHotstrings
		Menu, Tray, NoStandard
		Menu, Tray, Standard
		trayInit := 1
	}
	if (OnOffToggle = "Enable LaTeX Hotstrings") ;// menu identifier is given to function upon clicking menu.
		OnOffToggle := -1
	Menu, Tray, ToggleCheck, Enable LaTeX Hotstrings
	Hotkey, IfWinNotActive, Online LaTeX Editor Overleaf - Mozilla Firefox ahk_exe firefox.exe
	HotString(":o?:\infty","∞", OnOffToggle)
	HotString(":o?:\sqrt","√", OnOffToggle)
	HotString(":o?:\leftrightarrow","↔", OnOffToggle)
	HotString(":o?:\leftarrow","←", OnOffToggle)
	HotString(":o?:\rightarrow","→", OnOffToggle)
	HotString(":o?:\uparrow","↑", OnOffToggle)
	HotString(":o?:\downarrow","↓", OnOffToggle)
	HotString(":o?:\plusminus","±", OnOffToggle)
	HotString(":o?:\times","×", OnOffToggle)
	HotString(":o?:\divide","÷", OnOffToggle)
	HotString(":o?:\emptyset","ø", OnOffToggle)
	HotString(":o?:\neq","≠", OnOffToggle)
	HotString(":o?:\leq","≤", OnOffToggle)
	HotString(":o?:\geq","≥", OnOffToggle)
	HotString(":o?:\approx","≈", OnOffToggle)
	HotString(":o?:\identity","≡", OnOffToggle)
	HotString(":o?:\cong","≅", OnOffToggle)
	HotString(":o?:\sum","∑", OnOffToggle)
	HotString(":o?:\prod","∏", OnOffToggle)
	HotString(":o?:\int","∫", OnOffToggle)
	HotString(":o?:\vert","⊥", OnOffToggle)
	HotString(":o?:\in","∈", OnOffToggle)
	HotString(":o?:\notin","∉", OnOffToggle)
	HotString(":o?:\block","█", OnOffToggle)
	HotString(":o?:\square","▢", OnOffToggle)
	HotString(":o?:\rectangle","□", OnOffToggle)
	HotString(":o?:\checkmark","▣", OnOffToggle)
	HotString(":o?:\exists","∃", OnOffToggle)
	HotString(":o?:\forall","∀", OnOffToggle)
	HotString(":o?:\cap","∩", OnOffToggle)
	HotString(":o?:\cup","∪", OnOffToggle)
	HotString(":o?:\vee","∨", OnOffToggle)
	HotString(":o?:\wedge","∧", OnOffToggle)
	HotString(":o?:\neg","¬", OnOffToggle)
	HotString(":o?:\notin","∉", OnOffToggle)
	HotString(":o?:\cdot","·", OnOffToggle)
	HotString(":o?:\proportional","∝", OnOffToggle)
	HotString(":o?:\longdash","–", OnOffToggle)
	
		; // GREEK LETTERS
	HotString(":o?:\alpha","α", OnOffToggle)
	HotString(":o?:\beta","β", OnOffToggle)
	HotString(":o?:\gamma","γ", OnOffToggle)
	HotString(":o?:\delta","δ", OnOffToggle)
	HotString(":o?:\epsilon","ε", OnOffToggle)
	HotString(":o?:\zeta","ζ", OnOffToggle)
	HotString(":o?:\eta","η", OnOffToggle)
	HotString(":o?:\theta","θ", OnOffToggle)
	HotString(":o?:\iota","ι", OnOffToggle)
	HotString(":o?:\kappa","κ", OnOffToggle)
	HotString(":o?:\lambda","λ", OnOffToggle)
	HotString(":o?:\mu","μ", OnOffToggle)
	HotString(":o?:\vu","ν", OnOffToggle)
	HotString(":o?:\xi","ξ", OnOffToggle)
	HotString(":o?:\pi","π", OnOffToggle)
	HotString(":o?:\rho","ρ", OnOffToggle)
	HotString(":o?:\omicron","ο", OnOffToggle)
	HotString(":o?:\sigma","σ", OnOffToggle)
	HotString(":o?:\ssigma","ς", OnOffToggle)
	HotString(":o?:\tau","τ", OnOffToggle)
	HotString(":o?:\upsilon","υ", OnOffToggle)
	HotString(":o?:\phi","φ", OnOffToggle)
	HotString(":o?:\chi","χ", OnOffToggle)
	HotString(":o?:\psi","ψ", OnOffToggle)
	HotString(":o?:\omega","ω", OnOffToggle)
		; //  ˢᵘᵖᵉʳˢᶜʳᶦᵖᵗ & ₛᵤᵦₛ𝒸ᵣᵢₚₜ (i have no idea why the t formats here)
	HotString(":o?:^0","⁰", OnOffToggle)
	HotString(":o?:^1","¹", OnOffToggle)
	HotString(":o?:^2","²", OnOffToggle)
	HotString(":o?:^3","³", OnOffToggle)
	HotString(":o?:^4","⁴", OnOffToggle)
	HotString(":o?:^5","⁵", OnOffToggle)
	HotString(":o?:^6","⁶", OnOffToggle)
	HotString(":o?:^7","⁷", OnOffToggle)
	HotString(":o?:^8","⁸", OnOffToggle)
	HotString(":o?:^9","⁹", OnOffToggle)
	HotString(":o?:^x","ˣ", OnOffToggle)
	HotString(":o?:^y","ʸ", OnOffToggle)
	HotString(":o?:^i","ᶦ", OnOffToggle)
	HotString(":o?:^t","ᵗ", OnOffToggle)
	HotString(":o?:^f","ᶠ", OnOffToggle)

	HotString(":o?:_0","₀", OnOffToggle)
	HotString(":o?:_1","₁", OnOffToggle)
	HotString(":o?:_2","₂", OnOffToggle)
	HotString(":o?:_3","₃", OnOffToggle)
	HotString(":o?:_4","₄", OnOffToggle)
	HotString(":o?:_5","₅", OnOffToggle)
	HotString(":o?:_6","₆", OnOffToggle)
	HotString(":o?:_7","₇", OnOffToggle)
	HotString(":o?:_8","₈", OnOffToggle)
	HotString(":o?:_9","₉", OnOffToggle)
	HotString(":o?:\_x","ₓ", OnOffToggle)
	HotString(":o?:\_y","ᵧ", OnOffToggle)
	HotString(":o?:\_i","ᵢ", OnOffToggle)
	HotString(":o?:\_t","ₜ", OnOffToggle)
	
	HotString(":o?:\#f","𝒻", OnOffToggle)
	Hotkey, IfWinActive
}

;[style]} ______________________________________________________________________________________________
;[style]							: ACTUAL HOTSTRINGS
;[style]{ ______________________________________________________________________________________________

;						: EXPANSION	: COMPLICATED STRINGS
;[style]{ --------------------------------
:*:@potet::
fastPrint("<@245189840470147072>")
return 
:*:@burny::
fastPrint("<@318350925183844355>")
return
:*:@Y::
fastPrint("<@354316862735253505>")
return
:*:@zyntha::
fastPrint("<@330811222939271170>")
return
:*:@astro::
fastPrint("<@193734142704353280>")
return
:*:@rein::
fastPrint("<@315661562398638080>")
return
::from:me::
fastPrint("from:245189840470147072 ")
return


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
#IfWinActive	; DON'T REMOVE THIS, THE AUTOMATIC HOTKEYS SHOULD ALWAYS BE ACTIVE



^+!Ä::	; Reload other script
PostMessage, 0x111, 65303,,, ahk_id 0x408f2
return

/*

^m::
clipboard := getAllPermutations("12345", "abcde")
return

^b::
clipboard := genRegexForExcludingWords("www.", "")
return

*/

getAllPermutations(str1, str2) {
	if (StrLen(str1) != StrLen(str2))
		return
	n := StrLen(str1)
	str2Arr := StrSplit(str2)
	arr := [str1]
	Loop % n
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

genRegexForExcludingWords(str1, str2, opt:=0) {
	temp := "(?:[^\W{}]|-)"
	gRegex := "(?i)^[^#\n]*\b"
	n := StrLen(str1)
	if (StrLen(str1) != StrLen(str2))
	{
		if (n > StrLen(str2))
			n := StrLen(swapVars(str1, str2))
		m := StrLen(str2)
		gRegex .= Format("(?:{}|{}{}", word(1,n-1), (n==m-1 ? "" : word(n+1,m-1) . "|"), word(m+1,0))
		Loop % n
			gRegex .= Format("|(?:{}{}{})", word(A_Index-1), Format(temp, SubStr(str1,A_Index,1)), word(n-A_Index))
		Loop % m
			gRegex .= Format("|(?:{}{}{})", word(A_Index-1), Format(temp, SubStr(str2,A_Index,1)), word(m-A_Index))
		return gRegex . ")\b"
	}
	gRegex .= Format("(?:{}|{}",word(1,n-1),word(n+1,0))
	Loop % n {
		arrB := []
		arrB[i := A_Index] := Format(temp, SubStr(str1,i,1))
		arrB[Mod(i,n)+1] := Format(temp, SubStr(str2, Mod(i,n)+1, 1))
		Loop % n
			strH .= ( arrB[A_Index] ? arrB[A_Index] : word(1) )
		gRegex .= "|(?:" . strH . ")"
		strH := ""
	}
	return gRegex . ")\b"
}

swapVars(byref v1, byref v2) {
	v3 := v1
	v1 := v2
	v2 := v3
	return v1
}

word(n:=1,m:=-1,flag:=0) {
	str := "[\w-]"
	if (flag) {
		Loop % (n<=0 ? 0 : n)
			strH .= str
		return strH
	}
	if (m == 0)
		return str . (n==1 ? "+" : (n==0 ? "*" : "{" n ",}"))
	if (m != -1 && n > m)
		return ""
	if (n==m || m==-1)
		return (n==0 ? "" : str . (n==1 ? "" : "{" n "}"))
	if (n<m)
		return str . (m==1 ? "?" : "{" n "," m "}")
	return "????????????????????????????"
}

rotateStr(str, offset:=0) {
	if (offset > StrLen(str))
		offset := Mod(offset,StrLen(str))
	return SubStr(str, -1*offset+1) . SubStr(str, 1, -1*offset)
}

clickloop(rows, columns, rHeight, cWidth) {
	MouseGetPos, initialX, initialY
	Loop % rows {
		i := A_Index - 1
		Loop % columns {
			j := A_Index - 1
			MouseClick, L, initialX+j*cWidth, initialY+i*rHeight
			Sleep, 10
		}
	}
	return
}


counter(a) {
	j := 0
	for i, e in a
		if e > 0
			j++
	return j
}

sieve(n) {
	arr := []
	Loop % n
		arr.push(A_Index)
	for i, e in arr
	{
		if (e == 0 || e == 1)
			continue
		Loop % n//e
			arr[(A_Index+1) * e] := 0
	}
	return arr
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
	HttpObj := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	HttpObj.Open(method, url, true)
	HttpObj.Send()
	return Trim(httpobj.ResponseText, "`n`r`t ")
}

makeTextAnsiColorful(str) {
	tStr := ""
	Loop, Parse, str
	{
		Random, clr, 30, 38
		if (A_Loopfield != " ")
			tStr .= "`[" . clr . "m" . A_Loopfield
		else 
			tStr .= A_Loopfield
	}
	return tStr
}

/*
^k::
sdfio := A_WorkingDir "\everything\LatexHotstrings_ahk2.json"
sdfio2 := A_WorkingDir "\everything\Smalltest.json"
obj := JSON.Load(readFileIntoVar(sdfio))
str := JSON.Dump(obj)
FileOpen(sdfio2, "w", "UTF-8").Write(str)
return

*/