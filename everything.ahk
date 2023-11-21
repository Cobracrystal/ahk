;// TODO: EDIT THE TRAY MENU TO BE SHORTER / HAVE SUBMENUS
;// TODO: FIX BUG WITH TRANSPARENT TASKBAR TIMER NOT DETECTING SEAMLESS FULLSCREEN
;  ______________________________________________________________________________________________
;[style]			INITILIZATION	: MODES
;[style]{ ______________________________________________________________________________________________
#NoEnv ;// Compatibility for future and optimization blabla
#KeyHistory 500
#Persistent
SendMode Input ; // Faster
SetTitleMatchMode, 3 ;// Must Match Exact Title (1 = start with specified words, 2 = contains words, 3 = match words exactly)
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
SetWorkingDir %A_ScriptDir%\script_files\everything
#Include %A_ScriptDir%\Libraries\TransparentTaskbar.ahk 
#Include %A_ScriptDir%\Libraries\HotkeyManager.ahk 
#Include %A_ScriptDir%\Libraries\WindowManagerClass.ahk
#Include %A_ScriptDir%\Libraries\ReminderManager.ahk
#Include %A_ScriptDir%\Libraries\TextEditMenu.ahk
#Include %A_ScriptDir%\Libraries\MacroRecorder.ahk
#Include %A_ScriptDir%\Libraries\TimestampConverter.ahk
#Include %A_ScriptDir%\Libraries\DiscordClient.ahk
#Include %A_ScriptDir%\Libraries\DiscordBotCommands.ahk
#Include %A_ScriptDir%\Libraries\AltDrag.ahk
#Include %A_ScriptDir%\Libraries\MathUtilities.ahk
#Include %A_ScriptDir%\Libraries\ColorUtilities.ahk
#Include %A_ScriptDir%\Libraries\BasicUtilities.ahk

;[style]} ______________________________________________________________________________________________
;[style]							: VARIABLES
;[style]{ ______________________________________________________________________________________________

;// These are technically available settings so i don't have to edit the library files. Since i made
;// the libraries, i obviously don't need them since the standard setting is my preference.

;//Window Manager
;// windowManagerGuiPosX := 200
;// windowManagerGuiPosY := 200
;//Hotkey Manager
;// hotkeyManagerGuiPosX := -530
;// hotkeyManagerGuiPosY := 35		
;//Taskbar Transparency
;// accent_color = 0xD0473739 		; This is literally just gray
;// passive_mode := 2	
;// for windows in which ctrl+ should replace scrolling cause it sucks
GroupAdd, zoomableWindows, ahk_exe Mindustry.exe
GroupAdd, zoomableWindows, ahk_exe placeholder.exe 
;// for windows that should be put in the corner when ctrlaltI'd
GroupAdd, cornerMusicPlayers, % "VLC media player ahk_exe vlc.exe",,, % "Wiedergabeliste"
GroupAdd, cornerMusicPlayers, % "Daum PotPlayer ahk_exe PotPlayerMini64.exe",,, % "Einstellungen"

;[style]} ______________________________________________________________________________________________
;[style]							: STARTING FUNCTIONS
;[style]{ ______________________________________________________________________________________________
;// moved it all to functions
;// set 1337 reminder
reminderHandler := new ReminderManager(0, 0, readFileIntoVar(A_ScriptDir . "\script_files\discordBotToken.token"))
reminderHandler.setSpecificTimer("1337reminder", "", , , 13,36,50)
;reminderHandler.setSpecificTimer(,"2337", , , 23,36,52)
reminderHandler.setSpecificTimer("discordReminder", "2337", , , 23,36,48,,,,"245189840470147072")
; reminderHandler.setSpecificTimer(func, msg, multi, period, h,m,s,d,mo, debug, target)
Menu, Timers, Add, 1337 Timer: On, doNothing
Menu, Timers, Disable, 1337 Timer: On
Menu, Timers, Check, 1337 Timer: On
;// transparent taskbar ini
taskbarTranspManager(1,,,50)
;// start clipboardwatcher
OnClipboardChange("clipboardTracker", 1)
;// Initialize System Cursor Files
SystemCursor("I")
;// better icon
Menu, Tray, Icon, % "C:\Users\Simon\Desktop\programs\other\Cursor Files\Icons\Potet Think.ico",,1
;// Timer because new Thread
GroupAdd, rarReminders, ahk_class RarReminder
GroupAdd, rarReminders, Please purchase WinRAR license ahk_class #32770
SetTimer, closeWinRarNotification, -100, -100000 ; priority -100k so it doesn't interrupt
;// Initialize LaTeX Hotstrings
LatexHotstrings(1)
;// replace the tray menu with my own
createBetterTrayMenu()
OnExit("exit")
return
	
;[style]} ______________________________________________________________________________________________
;[style]			HOTKEYS	 		: CONTROL‎
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

^F11:: ; Shows a list of all Windows
WindowManager.windowManager("T")
; windowManager("T")
return

^F10::	; Shows Reminder GUI
if !WinExist("ahk_id " . reminderManagerGuiHwnd) 
	reminderManagerGuiHwnd := reminderHandler.guiCreate(reminderManagerGuiPosX, reminderManagerGuiPosY)
else
	reminderHandler.guiClose(reminderManagerGuiHwnd)
return

^+F11:: ; Gives Key History
ListLines
return

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
	^D::		; VLC : Open/Close Media Playlist
		SetControlDelay -1 
		WinGet, vlcid, ID, VLC media player,, Wiedergabeliste
		WinGetPos,,,, vlcH, ahk_id %vlcid%
		controlY := vlcH - 49
		ControlSend, ahk_parent, {Esc}, ahk_id %vlcid%
		ControlClick, X222 Y%controlY%, ahk_id %vlcid%,,,, Pos NA
	return
#IfWinActive

;[style]} ______________________________________________________________________________________________
;[style]					 		: STANDARD‎ / GAMES
;[style]{ ______________________________________________________________________________________________

^!K::	; Evaluate Shell Expression in-text
	calculateExpression()
return

^+!NumpadEnter::	; Launch Autoclicker
Run, C:\Users\Simon\Desktop\Autoclicker\AutoClickerPos.exe
return

^Numpad0::	; hold down leftclick
if (mousetoggle := !mousetoggle) 
	Click, down
else 
	Click, up
return


;[style]{----- Discord Bots

^+0::	; toggle tatsu automation
if (tatsuToggle := !tatsuToggle) {
	tatsuTrainingCookies()
	tatsuFish()
}
else {
	tatsuTrainingCookies(0)
	tatsuFish(0)
}
return

;[style]}-----

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

;[style]}-----

#IfWinActive ahk_exe bloonstd6.exe
;[style]{----- Btd6
^I::	; BTD6: Fullsend Race
Loop, 90 {
	SendRaw, ^
	Sleep, 25
}
return

F11:: 	; BTD6: Rebind Escape
Send, {Escape}
return

RShift::	; BTD6: Rebind Sell
Send, {Backspace}
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

^C::	; BTD6: Pirate Lord Micro
Loop, 10 {
	Send, c
	Sleep, 50
	MouseClick, L, 885, 530
	Sleep, 50
	MouseClick, L, 885, 530
	Sleep, 75
	Loop, 10 {
		Send, .
		Sleep, 30
	}
	Send, 1
	Sleep, 50
	Send, {Backspace}
	Sleep, 50
}
return

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

Left::	; BTD6: MouseLeft
MouseMove, -1,0,,R
return

Right::	; BTD6: MouseRight
MouseMove, 1,0,,R
return

Up::	; BTD6: MouseUp
MouseMove, 0,-1,,R
return

Down::	; BTD6: MouseDown
MouseMove, 0,1,,R
return

#IfWinActive

;[style]}-----

#IfWinActive ahk_exe javaw.exe
;[style]{----- Minecraft
^+!Q::	; MC: Drop all
Sleep, 300
Loop, 100 {
	Send, Q
	Sleep, 20
}
return
#IfWinActive 
;[style]}----- 

#IfWinActive ahk_exe Geometry Arena.exe
;[style]{----- Geometry Arena

^Numpad6:: 		; Geometry Arena: Combine Artifacts
if (!WinExist("ahk_exe Geometry Arena.exe"))
WinActivate, ahk_exe Geometry Arena.exe
row := 1
column := 9
MouseClick, L, 90+column*70, 295+row*70
Loop {
	WinActivate, ahk_exe Geometry Arena.exe
	ImageSearch, resultX, resultY, 840, 475, 1150, 810, GeometryArenaStartWith.png
	Sleep, 25
	if (ErrorLevel = 0) {
		if (column = 9) {
			if (row = 9)
				break
			row += 1
			column = 0
		}
		else
			column += 1
		Send, G
		Sleep, 25
		MouseClick, L, 90+column*70, 295+row*70
	}
	else {
		Send, X
		Sleep, 25
		Send, G
		Sleep, 25
		MouseClick, L
	}
	Sleep, 5
		
}
return

#IfWinActive
;[style]}-----

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

#IfWinActive ahk_exe Patrick's Parabox.exe
;[style]{----- Patrick's Parabox
z::y	; Patrick's Parabox: Rebind z->y
#IfWinActive
;[style]}

;[style]} ______________________________________________________________________________________________
;[style]							: WINDOWS 
;[style]{ ______________________________________________________________________________________________

!LButton::	; Drag Window 
moveWindow(A_ThisHotkey)
return

!RButton::	; Resize Window 
resizeWindow(A_ThisHotkey)
return

!MButton::	; Toggle Max/Restore of clicked window
toggleMaxRestore()
return

^NumpadMult::	; Show Mouse Coordinates
if (coordtoggle := !coordtoggle)
	SetTimer, showcoords, 50
else {
	SetTimer, showcoords, Off
	Tooltip
}
return

+NumpadMult::	; Displays Title and ahk info of active window
if (winstattoggle := !winstattoggle)
	SetTimer, windowDisplayTooltip, 50
else {
	SetTimer, windowDisplayTooltip, Off
	ToolTip
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
	WinMove,,, -600, 600, 514, 482
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
if (TranspToggle2 := !TranspToggle2) {
	WinSet, Transparent, 0, ahk_class Shell_TrayWnd
	; WinSet, Transparent, 0, ahk_class Shell_SecondaryTrayWnd
}
else {
	WinSet, Transparent, Off, ahk_class Shell_TrayWnd
	; WinSet, Transparent, Off, ahk_class Shell_SecondaryTrayWnd
}
return

^+K:: ; Toggle Taskbar Transparency
taskbarTranspManager("Toggle")
return

<^>!M::		; Minimizes Active Window
if (togglewinmin := !togglewinmin) {
	WinGet, winToggleID, ID, A
	WinMinimize, ahk_id %winToggleID%
}
else {
	WinGet, mmx, MinMax, ahk_id %winToggleID%
	if (WinActive("ahk_id " . winToggleID) && mmx != -1) {
		WinMinimize, ahk_id %winToggleID%
		togglewinmin := !togglewinmin
	}
	else
		WinRestore, ahk_id %winToggleID%
}
return

#IfWinActive ahk_class Photo_Lightweight_Viewer
^T::	; Fotoanzeige: StrgT->ShiftEsc
Send, !{Esc}
return

^W::	; Fotoanzeige: StrgW->AltF4
Send, !{F4}
return
#IfWinActive
;[style]} ______________________________________________________________________________________________
;[style]							: EXPERIMENTAL / TESTING / TEMPORARY
;[style]{ ______________________________________________________________________________________________
^+!F11:: ; Block screen input until password "password" is typed
password := "password" 
keys=CTRL|SHIFT|ALT
Loop, Parse,keys,|
	KeyWait, %A_LoopField%
BlockInput,On
Input,var,C*,,%password%
BlockInput,Off
return

^!+K:: ; Tiles Windows Vertically
shell := ComObjCreate("Shell.Application")
MsgBox, 1, ConfirmDialog, Tile Windows Vertically?, 10
IfMsgBox Ok
	shell.tileWindowsVertically()
tileCurrentWindows()
return

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

;[style]} ______________________________________________________________________________________________
;[style]			FUNCTIONS		: GUI‎ / WINDOW‎ CONTROL‎
;[style]{ ______________________________________________________________________________________________

windowDisplayTooltip() {
	ahk_Wid := WinExist("A")
	WinGet, winPName, ProcessName, ahk_id %ahk_Wid%
	WinGet, winPPath, ProcessPath, ahk_id %ahk_Wid%
	WinGetTitle, winTitle, ahk_id %ahk_Wid% 
	WinGetClass, winClass, ahk_id %ahk_Wid% 
	ToolTip, % winTitle . ", " . winClass . ", " . winPName . ", " . winPPath
}

showcoords() {		
	MouseGetPos, ttx, tty
	PixelGetColor, ttc, ttx, tty
	Tooltip, %ttx%`, %tty%`, %ttc%
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
;[style]							: STANDARD‎
;[style]{ ______________________________________________________________________________________________

;// moved to own scripts

clipboardTracker(type) {
	if (type == 1) {
		if (Clipboard.Length() < 100 && RegexMatch(Clipboard, "youtube\.com\/shorts\/([0-9a-zA-Z\_\-]+)")) {
			tClip := RegexReplace(Clipboard, "youtube\.com\/shorts\/([0-9a-zA-Z\_\-]+)", "youtube.com/watch?v=$1")
			Clipboard := tClip
		}
	}
}

;[style]}______________________________________________________________________________________________
;[style]							: MENU‎
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
			str := RegexReplace(A_AhkPath, "AutoHotkey.exe$", "AutoHotkey.chm")
			Run, %str%
			WinWait, AutoHotkey Help
			center_window_on_monitor(WinActive("AutoHotkey Help"), 0.8)
			return
		case "Window Spy":
			if !WinExist("Window Spy") {
				str := RegexReplace(A_AhkPath, "AutoHotkey.exe$", "WindowSpy.ahk")
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
				Menu, Tray, Icon, % "C:\Users\Simon\Desktop\programs\other\Cursor Files\Icons\Potet Think Warn.ico"
			else
				Menu, Tray, Icon, % "C:\Users\Simon\Desktop\programs\other\Cursor Files\Icons\Potet Think.ico"
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
;[style]							: GUI‎ CONTROL‎
;[style]{ ______________________________________________________________________________________________
;// Since i only have like 2 GUIs and those are very large, they're all in their respective library files now.




;[style]} ______________________________________________________________________________________________
;[style]			HOTSTRINGS		: HOTKEYS‎ FOR‎ HOTSTRINGS
;[style]{ ______________________________________________________________________________________________

^!+F12:: ; Toggles LaTeX Hotstrings
LatexHotstrings()
return


;[style]} ______________________________________________________________________________________________
;[style]							: ACTUAL HOTSTRINGS
;[style]{ ______________________________________________________________________________________________

;						: EXPANSION	: COMPLICATED STRINGS
;[style]{ --------------------------------
:*:@potet::<@245189840470147072> 
:*:@burny::<@318350925183844355>
::@Y::<@354316862735253505>
:*:@zyntha::<@330811222939271170>
:*:@astro::<@193734142704353280>
:*:@rein::<@315661562398638080>
::from:me::from{:}245189840470147072{Space}

;[style]} 
;									: SPECIAL SYMBOLS / LaTeX
;[style]{ --------------------------------

; // all of these can be toggled via ctrl alt shift F12, remember to add those to the list.

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
	SetTitleMatchMode, 2
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
	SetTitleMatchMode, 2
}

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
;[style]			END‎ OF ACTIVE SCRIPT: HELP‎ SECTION‎
;[style]{ ______________________________________________________________________________________________
;
;	Hotkey Modifier Buttons: ^ = Strg, + = Shift, # = Windows, ! = Alt; <^>! = AltGR
;	Use IfWinExist with DetectHiddenWindows, on each script has a "window" with the name of the script in its title.
;	+E0x08000000 means the GUI won't be activated when the user clicks on it.
;
;
;
;[style]} ______________________________________________________________________________________________
;[style]			DEPRECATED : HOTKEYS
;[style]{ ______________________________________________________________________________________________


;// Plants vs Zombies
/*
	^+Ö::	; Automate Plants vs Zombies Tree of Wisdom food
	Loop, 3 {
		Gosub, tenTimesWisdoomFood
	}
	; GoSub, tenTimesWisdomFoodFeed
	return


	tenTimesWisdoomFood:
	Loop, 10 {
		if !WinActive("Plants vs. Zombies ahk_exe popcapgame1.exe")
			return
		ControlClick, X475 Y375, Plants vs. Zombies ahk_exe popcapgame1.exe,, Left,, NA ;// Click on food in shop
		Sleep, 100
		Click, 300, 420
		Sleep, 100
	}
	ControlClick, X430 Y575, Plants vs. Zombies ahk_exe popcapgame1.exe,, Left,, NA ;// Click on go back Sign
	Sleep, 150
	tenTimesWisdomFoodFeed:
	Loop, 10 {
		ControlClick, X66 Y60, Plants vs. Zombies ahk_exe popcapgame1.exe,, Left,, NA ;//food
		Sleep, 75
		ControlClick, X400 Y350, Plants vs. Zombies ahk_exe popcapgame1.exe,, Left,, NA;//tree
		Sleep, 200
	}
	ControlClick, X750 Y80, Plants vs. Zombies ahk_exe popcapgame1.exe,, Left,, NA ;// Click on Shop Sign
	Sleep, 75
	return
*/

;// NGU Idle
/*

#IfWinActive ahk_exe NGUIdle.exe
;[style]{----- NGU Idle
^!F::	; NGU assign resources
nguAssignResources()
return

^!D::	; NGU Cast Cards
if (castcardtoggle := !castcardtoggle) {
	SetTimer, castCardTest, 80
	MouseClick, L, 760, 280
}
else
	SetTimer, castCardTest, Off
return


#IfWinActive
;[style]}-----
*/
;// IT Takes Two Trial
/*
#IfWinActive ahk_exe ItTakesTwo_Trial.exe
;[style]{----- It Takes Two

^ü::	; It takes two: e spam
if (etog := !etog)
	SetTimer, sendE, 20
else
	SetTimer, sendE, Off
return

sendE() {
	Send, {e down}
	Sleep, 10
	Send, {e up}
}
#IfWinActive
;[style]}-----
*/

;// COUNTS NUMBERS AUTOMATICALLY
/*
	^NumpadMult::
	if (toggleCountingSpam = !toggleCountingSpam)
		if WinExist("#spamzone-2 - Discord" or "#spamzone-1 - Discord")
			SetTimer, CountingSpam, 800
	else 
		SetTimer, CountingSpam, Off
	return
*/

;// HUNTS, FISHES 
/*
	#NumpadSub::
	Gosub, IdleMCFishHunt
	return
*/
;// TRIVIA
/*
	<^>!.:: ;//<- this is alt gr + .
	Send, .t -w1
	return
*/

;// CLAIM WAIFU ON PEPE
/*
	^B:: ; claim waifu from clipboard
	Send, .claimwaifu 50 %clipboard%
	return
*/

;// DISCORD HALLOWEEN EVENT
/*
	^L:: ; h!treat
	Send, h{!}treat{Enter}
	return

	^O:: ; h!trick
	Send, h{!}trick{Enter}
	return
*/

;// Discord bots
/*
	^NumpadSub:: ; Mantaro Mine/Loot/Fish
	GoSub, MantaroMineLootFish
	return

	+NumpadSub:: ; Tatsu Fish/Train/Cookies
	GoSub, TatsuFishing
	GoSub, TatsuTrainingCookies
	return
*/

;// Discord Menu
/*
	#IfWinActive, DiscordMenu
		^S:: ; GUI: Save Settings of DiscordMenu GUI
		GoSub, DiscordMenuButtonSave
		return 
	#IfWinActive

	NumpadEnter::	; Starts DiscordScript
	GoSub, StartDiscordScript
	return

	NumpadAdd:: 	; Stops DiscordScript
	GoSub, StopDiscordScript
	return

	^#NumpadEnter::	; Toggles DiscordScript window 
	if (WinExist("#boooooooooot - Discord") And !WinExist("DiscordMenu"))
		Gui, DiscordMenu:Show, AutoSize NoActivate X-1650 Y900, DiscordMenu
	else if WinExist("DiscordMenu")
		Gui, DiscordMenu:Submit
	return
*/

;// ITRTG
/*
*/
;[style]} ______________________________________________________________________________________________
;[style]			DEPRECATED : FUNCTIONS
;[style]{ ______________________________________________________________________________________________ 

;// stupid function just to count in botspam for xp
/*
	CountingSpam:
	if WinExist("#spamzone-2 - Discord" or "#spamzone-1 - Discord")	{
		Send, %CurrentCount%{Enter}
		CurrentCount++
	}
	return
*/

;// i got banned from this bot, but i was also pretty bored from it ...which is why these functions exist
/*
	IdleMCSellUp:
	if WinExist("#boooooooooot - Discord")	{	
		Critical
		WinGetActiveTitle, ComebackWindow
		WinActivate #boooooooooot - Discord
		if (IdleMinerP + IdleMinerB = 2)	{
			if (PickBack = "p")
				PickBack := "b"
			else
				PickBack := "p"
		}
		Send,?sell{Enter}
		if (IdleMinerP + IdleMinerB > 0)	{
			Sleep, 230
			Send, ?up %PickBack% a{Enter}
		}
		Sleep, 100
		WinActivate %ComebackWindow% 
		if (TimerActivity = 1)	{
			Random, IdleMinerUpgradeIntervalTime, 15000, 30000
			SetTimer,, %IdleMinerUpgradeIntervalTime%
		}
	}
	return

	IdleMCFishHunt:
	if WinExist("#boooooooooot - Discord")	{	
		Critical
		WinGetActiveTitle, ComebackWindow
		WinActivate #boooooooooot - Discord
		Send,?hunt{Enter}
		Sleep,300
		Send,?fish{Enter}
		Sleep, 100
		if (TimerActivity = 1)	{
			Random, IMCFHTime, 308000, 315000
			SetTimer,, %IMCFHTime%
		}
		else	{
			Sleep, 200
			Send, ?sell{Enter}
			Sleep, 300
			Send, ?quiz{Enter}
			Sleep, 100
		}
		WinActivate %ComebackWindow% 
	}
	return

	IdleMinerPause:
	SetTimer, IdleMCFishHunt, Off
	SetTimer, IdleMCSellUp, Off
	return
*/

;// Tatsu automated cookies, fishing
/*	
	TatsuTrainingCookies:
	if WinExist("#boooooooooot - Discord")	{	
		Critical
		WinGetActiveTitle, ComebackWindow
		WinActivate #boooooooooot - Discord
		Send,t{!}tg train{Enter}
		Sleep, 300
		Send, t{!}cookie 239631525350604801{Enter}
		Sleep, 100
		WinActivate %ComebackWindow%
		if (TimerActivity = 1)	{
				Random, TTrainingCookiesTime, 11000, 14000			; make it random for the next timer. basically refreshes itself. the if clause necessary if timer is running while im checkboxing
				SetTimer,, %TTrainingCookiesTime%
		}
	}
	return

	TatsuFishing:
	if WinExist("#boooooooooot - Discord")	{	
		Critical
		WinGetActiveTitle, ComebackWindow
		WinActivate #boooooooooot - Discord
		Send,t{!}fish{Enter}
		Sleep, 100
		WinActivate %ComebackWindow% 
		if (TimerActivity = 1)	{
				Random, TFishTime, 32000, 35000
				SetTimer,, %TFishTime%
		}
	}
	return
*/

;// mantaro automated mining, fishing, looting
/*
	MantaroMineLootFish:
	SetTitleMatchMode, 2 ; other accounts -> browser window
	if WinExist("#boooooooooot")	{	
		Critical
		WinGetActiveTitle, ComebackWindow
		WinActivate #boooooooooot
		Send,>mine{Enter}
		Sleep,200
		Send,>loot{Enter}
		Sleep,200
		Send,>fish{Enter}
		Sleep, 100
		WinActivate %ComebackWindow% 
		if (TimerActivity = 1)	{
			Random, MMLFTime, 308000, 312000
			SetTimer,, %MMLFTime%
		}
	}
	SetTitleMatchMode, 3
	return
*/

;// Label to start other timers for labels in random times to not get banned for perfect 10s fishes
/*
	StartDiscordScript:
	TimerActivity = 1
	if Tatsustuff	{
		Random, TTrainingCookiesTime, 11000, 14000
		Random, TFishTime, 32000, 35000
		Gosub, TatsuTrainingCookies
		Sleep, 300
		Gosub, Tatsufishing
		Sleep, 300
		SetTimer, TatsuTrainingCookies, %TTrainingCookiesTime%
		Sleep, 400
		SetTimer, TatsuFishing, %TFishTime%
		Sleep, 300
	}
	if Mantarostuff	{
		Random, MMLFTime, 308000, 312000
		Gosub, MantaroMineLootFish
		Sleep, 300
		SetTimer, MantaroMineLootFish, %MMLFTime%
		Sleep, 300
	}
	return

	StopDiscordScript:
	TimerActivity = 0
	SetTimer, TatsuTrainingCookies, Off
	SetTimer, TatsuFishing, Off
	SetTimer, MantaroMineLootFish, Off
	return

*/

;// Discord Menu initialization. Since i always hid it, i never created a new one, which is why its not a function
/*
	create_discord_menu() {
		Gui, DiscordMenu:New, +AlwaysOnTop +Border +Owner -SysMenu, DiscordMenu
		Gui, DiscordMenu:Add, Checkbox, vTatsustuff, 						Enable Tatsu commands?
		Gui, DiscordMenu:Add, Checkbox, vMantarostuff, 						Enable Mantaro commands?
		Gui, DiscordMenu:Add, Button, xp yp+20 default gDiscordMenuButtonSave, Save ;
	}
*/

;// Discord Menu Labels
/*
	DiscordMenuGuiEscape:
	DiscordMenuGuiClose:
	Gui, DiscordMenu:Hide
	return

	DiscordMenuButtonSave:
	Gui, DiscordMenu:Submit, NoHide
	if !Tatsustuff	{
		SetTimer, TatsuTrainingCookies, Off
		SetTimer, TatsuFishing, Off
	}
	if !Mantarostuff
		SetTimer, MantaroMineLootFish, Off
	return
*/

;// Discord Menu Timer
/*
	DiscordGui:
	if WinExist("#boooooooooot - Discord")	{
		if !WinExist("DiscordMenu")
			Gui, DiscordMenu:Show, AutoSize NoActivate X-1650 Y900, DiscordMenu
	}
	else	{
		if WinExist("DiscordMenu")
			Gui, DiscordMenu:Submit
	}
	return
*/

;// This function has been moved and modified to \Libraries\TransparentTaskbar.ahk
/*
TaskBar_SetAttr(accent_state := 0, gradient_color := "0x01000000") { ; //stolen & modified from JNizM, https://github.com/jNizM/AHK_TaskBar_SetAttr/
;// 0 = off, 1 = gradient (+color), 2 = transparent (+color), 3 = blur. color -> ABGR (alpha | blue | green | red) 0xffd7a78f
    static init, hTrayWnd, hTrayWnd2, ver := DllCall("GetVersion") & 0xff < 10
    static pad := A_PtrSize = 8 ? 4 : 0, WCA_ACCENT_POLICY := 19

    if !(init) {
        if (ver)
            throw Exception("Minimum support client: Windows 10", -1)
        if !(hTrayWnd := DllCall("user32\FindWindow", "str", "Shell_TrayWnd", "ptr", 0, "ptr"))
            throw Exception("Failed to get the handle", -1)
		if !(hTrayWnd2 := DllCall("user32\FindWindow", "str", "Shell_SecondaryTrayWnd", "ptr", 0, "ptr"))
			throw Exception("Failed to get the handle", -1)
        init := 1
    }

    accent_size := VarSetCapacity(ACCENT_POLICY, 16, 0)
    NumPut((accent_state > 0 && accent_state < 4) ? accent_state : 0, ACCENT_POLICY, 0, "int")

    if (accent_state >= 1) && (accent_state <= 2) && (RegExMatch(gradient_color, "0x[[:xdigit:]]{8}"))
        NumPut(gradient_color, ACCENT_POLICY, 8, "int")

    VarSetCapacity(WINCOMPATTRDATA, 4 + pad + A_PtrSize + 4 + pad, 0)
    && NumPut(WCA_ACCENT_POLICY, WINCOMPATTRDATA, 0, "int")
    && NumPut(&ACCENT_POLICY, WINCOMPATTRDATA, 4 + pad, "ptr")
    && NumPut(accent_size, WINCOMPATTRDATA, 4 + pad + A_PtrSize, "uint")
    if !(DllCall("user32\SetWindowCompositionAttribute", "ptr", hTrayWnd, "ptr", &WINCOMPATTRDATA))
        throw Exception("Failed to set transparency / blur", -1)
	if !(DllCall("user32\SetWindowCompositionAttribute", "ptr", hTrayWnd2, "ptr", &WINCOMPATTRDATA))
		throw Exception("Failed to set transparency / blur", -1)
	return true
}
*/

;// Time Clickers 100% automation
/*
	^+Ä:: ; Automates TimeClickers
	; We need to do: - either every 40 minutes, or check pixels for 100k TC,
	; then automatic timecube reset. no buying? then spam C, H for abilities/pistol, spam asdfg for other things, then normal procedure, repeat
	if (active := !active) {
		WinGetPos, timeClickersTopLX, timeClickersTopLY, timeClickersW, timeClickersH, ahk_exe TimeClickers.exe
		if WinActive("ahk_exe TimeClickers.exe"){
			SetControlDelay -1
			SetTimer, TimeClickersClicking, 50
		}
		SetTimer, TimeClickersUpgrades, 2000
	}
	else {
		SetTimer, TimeClickersClicking, Off
		SetTimer, TimeClickersUpgrades, Off
		SetControlDelay 20
	}
	return

	#IfWinActive ahk_exe TimeClickers.exe
	^+!a::
	autoWarpFarmVar := Func("autoWarpFarm")
	if (autoWarpFarm := !autoWarpFarm) {
		WinActivate, ahk_exe TimeClickers.exe
		TimeClickersInstantiatePrestige()
		SetTimer, %autoWarpFarmVar%, 200
	}
	else {
		SetTimer, %autoWarpFarmVar%, Off
	}
	return
	#IfWinActive
	
	TimeClickersUpgrades:
	ControlSend,, asdfg, ahk_exe TimeClickers.exe
	WinGetActiveTitle, ComebackWindow
	WinActivate, ahk_exe TimeClickers.exe
	WinActivate, %ComebackWindow%
	return

	TimeClickersClicking:
	WinActivate, ahk_exe TimeClickers.exe
	MouseMove, timeClickersW/2, timeClickersH/2, 0 ; timeClickersTopLX + timeClickersW/2 , timeClickersTopLY + timeClickersH/2, 0
	; MouseClick, Left,,,5,0
	ControlClick, X500 Y500, ahk_exe TimeClickers.exe,,Left,5,NA
	return

	autoWarpFarm() {
		WinActivate, ahk_exe TimeClickers.exe
		PixelGetColor, color, 1260, 340 
		if (color = "0x00FF29") {
			; ControlClick, X1260 Y340, ahk_exe TimeClickers.exe,,Left,1,NA
			MouseClick, Left, 1260, 340
			Sleep, 400
			; ControlClick, X580 Y540, ahk_exe TimeClickers.exe,,Left,1,NA
			MouseClick, Left, 580, 540
			Sleep, 400
			; ControlClick, X1150 Y360, ahk_exe TimeClickers.exe,,Left,1,NA
			MouseClick, Left, 1150, 360
			Sleep, 2100
			TimeClickersInstantiatePrestige()
		}
	}

	TimeClickersInstantiatePrestige() {
		Loop, 10 {
			Send, asdfg
			Sleep, 30
		}
		Loop 2 {
			Send, h
			Sleep, 50
		}
		Loop, 20 {
			Send, c
			Sleep, 20
		}
	}
*/

;// NGU Idle
/*
nguAssignResources() {
	MouseGetPos, ngux, nguy
	MouseClick, L, 1068, 125	; 4% resource 3
	Sleep, 50
	MouseClick, L, 1163, 323	; assign to wish
	Sleep, 50
	MouseClick, L, 1031, 58		; 2% other
	Sleep, 50
	MouseClick, L, 996, 314		; assign to wish energy
	Sleep, 50
	MouseClick, L, 816, 327		; assign to wish magic
	Sleep, 50
	MouseMove, %ngux%, %nguy%
}

castCardTest() {
	PixelGetColor, pxc, 702, 220
	if (pxc = "0x666666")
		return
	if (pxc != "0xBEBE3E") {
	;	ToolTip, %pxc%
		MouseClick, L, 550, 525
		Sleep, 30
	}
	MouseClick, L, 460, 525
}
*/

;[style]} ______________________________________________________________________________________________
;[style]			EVERYTHING HERE WAS ADDED AFTERWARDS OR_ MODIFIED AUTOMATICALLY
#IfWinActive	; DON'T REMOVE THIS, THE AUTOMATIC HOTKEYS SHOULD ALWAYS BE ACTIVE
