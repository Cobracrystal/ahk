;// TODO: EDIT THE TRAY MENU TO BE SHORTER / HAVE SUBMENUS
;// TODO: FIX BUG WITH TRANSPARENT TASKBAR TIMER NOT DETECTING SEAMLESS FULLSCREEN
;  ____________________________________________________________________________________________________
;	INITILIZATION	: MODES
;{ ____________________________________________________________________________________________________
#NoEnv ;// Compatibility for future and optimization blabla
#KeyHistory 500
#Persistent
SendMode Input ; // Faster
SetTitleMatchMode, 3 ;// Must Match Exact Title
; CoordMode,Mouse,Window ;// Coordinates for Click are relativ to upper left corner of active Window (Look TimeClickers hotkey/Timer for usage)
; CoordMode,ToolTip,Window ;// both this and above are the default anyway, leaving for future reference
Thread, NoTimers	;// Any hotkey or menu has priority over timers. So that the custom tray menu doesn't collide with taskbarTransparencyTimer
#MaxHotkeysPerInterval 5000
;// this would change the standard editing program for ahk to n++, but i changed the tray menu anyway so it works.
; RegWrite REG_SZ, HKCR, AutoHotkeyScript\Shell\Edit\Command,, C:\Program Files (x86)\Notepad++\notepad++.exe `%1 

;// unnecessary usually
; DetectHiddenWindows, On

;} ____________________________________________________________________________________________________
;					: SUB FILES
;{ ____________________________________________________________________________________________________

if !InStr(FileExist("script_files"), "D")
	FileCreateDir, script_files
SetWorkingDir %A_ScriptDir%\script_files
if !InStr(FileExist("everything"), "D")
	FileCreateDir, everything
SetWorkingDir %A_ScriptDir%\script_files\everything
#Include %A_ScriptDir%\Libraries\TransparentTaskbar.ahk 
#Include %A_ScriptDir%\Libraries\HotkeyMenu.ahk 
#Include %A_ScriptDir%\Libraries\WindowManager.ahk
#Include %A_ScriptDir%\Libraries\TextEditMenu.ahk
#Include %A_ScriptDir%\Libraries\MacroRecorder.ahk
#Include %A_ScriptDir%\Libraries\TimestampConversion.ahk

;} ----------------------------------------------------------------------------------------------------
;					: VARIABLES
;{ ____________________________________________________________________________________________________

;// These are available settings aka global variables so i don't have to edit the library files. Since i made
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
;// TaskbarTimer because this will be initialized instantly as well as with a hotkey
taskBarTimer := Func("updateTaskbarFunction")			
;} ----------------------------------------------------------------------------------------------------
;					: STARTING FUNCTIONS
;{ ____________________________________________________________________________________________________
;// transparent taskbar initilization
updateTaskbarFunction(0, 1)
SetTimer, %taskBarTimer%, 200
;// replace the tray menu with my own
createBetterTrayMenu()
;// Initialize LaTeX Hotstrings
LatexHotstrings("On")
return

;} ____________________________________________________________________________________________________
;	HOTKEYS	 		: CONTROL
;{ ____________________________________________________________________________________________________

^+R:: ; Reload Script
reload()
return

^+LButton::	; Text Modification Menu
	Menu, textModify, Show
return

^U::	; Time/Date Converter
	textTimestampConverter()
return

^+!NumpadSub::	; Record Macro
	createMacro(A_ThisHotkey)
return

^F12:: ; Toggle Hotkey Manager
if !WinExist("ahk_id" hotkeyManagerGuiHwnd)
	createHotkeyManagerGui(hotkeyManagerGuiPosX, hotkeyManagerGuiPosY)
else
	HotkeyManagerGuiClose(hotkeyManagerGuiHwnd)
return

^F11:: ; Shows a list of all Windows
if !WinExist("ahk_id" windowManagerGuiHwnd) 
	createWindowManagerGui(windowManagerGuiPosX, windowManagerGuiPosY)
else
	WindowManagerGuiClose(windowManagerGuiHwnd)
return

^+F11:: ; Gives Key History
KeyHistory
return

^LWin Up:: ; Replace Windows Search with EverythingSearch
if (!WinExist("ahk_exe C:\Program Files\Everything\everything.exe")) {
	Run, C:\Program Files\Everything\everything.exe,,Min, everythingSearchWindowPID
	WinWait, ahk_exe C:\Program Files\Everything\Everything.exe
	WinRestore
	WinMove,,, 40, 400, 784, 648 ; // THESE ARE THE POSITIONS OF THE WINDOWS SEARCH TOOL
	WinActivate
	WinWaitNotActive
	WinClose
}
else {
	; WinActivate, ahk_exe C:\Program Files\Everything\Everything.exe
	WinClose, ahk_exe C:\Program Files\Everything\Everything.exe
}
return

#IfWinActive, ahk_exe C:\Program Files\Everything\everything.exe
	^LWin Up:: ; Close EverythingSearch if its active
		WinClose, ahk_exe C:\Program Files\Everything\Everything.exe
	return
#IfWinActive 

#IfWinActive ahk_exe vlc.exe
	^D::		; VLC : Open/Close Media Playlist
		SetTitleMatchMode, 2
		SetControlDelay -1 
		WinGet, vlcid, ID, VLC media player,, Wiedergabeliste
		WinGetPos,,,, vlcH, ahk_id %vlcid%
		controlY := vlcH - 49
		ControlSend, ahk_parent, {Esc}, ahk_id %vlcid%
		ControlClick, X222 Y%controlY%, ahk_id %vlcid%,,,, Pos NA
		SetTitleMatchMode, 3
	return
#IfWinActive
;} ----------------------------------------------------------------------------------------------------
;			 		: STANDARD 
;{ ____________________________________________________________________________________________________

^!K::	; Evaluate Math(Shell) Expression in-text
ClipboardOld := ClipboardAll
Clipboard =  
Send ^c
ClipWait 1
if ErrorLevel 
    return
result := ExecScript("FileAppend % (" Clipboard "), *")
Clipboard := ClipboardOld
if (result = "")
	return
Send {Right}{Space}={Space}%result%
return

;} ----------------------------------------------------------------------------------------------------
;					: WINDOWS 
;{ ____________________________________________________________________________________________________

^NumpadMult::	; Show Mouse Coordinates
if (coords := !coords)
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

^!+K:: ; Tiles Windows Vertically
shell := ComObjCreate("Shell.Application")
MsgBox, 1, ConfirmDialog, Tile Windows Vertically?, 10
IfMsgBox Ok
	shell.tileWindowsVertically()
tileCurrentWindows()
return
^!+I:: ; Center & Adjust Active Window
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
if (TranspToggle := !TranspToggle) {
	SetTimer, %taskBarTimer%, Off
	updateTaskbarFunction(1) ; // reset:=1 -> resets taskbar
}
else {
	SetTimer, %taskBarTimer%, 200
}
return

<^>!M::		; Minimizes Active Window
if (togglewinmin := !togglewinmin) {
	WinGet, prevWindowID, ID, A
	WinMinimize, ahk_id %prevWindowID%
}
else
	WinRestore, ahk_id %prevWindowID%
return

;} ----------------------------------------------------------------------------------------------------
;					: EXPERIMENTAL
;{ ____________________________________________________________________________________________________
^+!F11:: ; Block screen input until password "password" is typed
password := "password" 
keys=CTRL|SHIFT|ALT
Loop, Parse,keys,|
	KeyWait, %A_LoopField%
BlockInput,On
Input,var,C*,,%password%
BlockInput,Off
return


;} ----------------------------------------------------------------------------------------------------
;	FUNCTIONS		: GUI / WINDOW CONTROL
;{ ____________________________________________________________________________________________________

showcoords() {		
	MouseGetPos, ttx, tty
	PixelGetColor, ttc, ttx, tty
	Tooltip, %ttx%`, %tty%`, %ttc%
}


center_window_on_monitor(winHandle, size_percentage := 0.714286) {
	VarSetCapacity(monitorInfo, 40), NumPut(40, monitorInfo)
	monitorHandle := DllCall("MonitorFromWindow", "Ptr", winHandle, "UInt", 0x2)
	DllCall("GetMonitorInfo", "Ptr", monitorHandle, "Ptr", &monitorInfo)
	
	workLeft      := NumGet(monitorInfo, 20, "Int") ; Left
	workTop       := NumGet(monitorInfo, 24, "Int") ; Top
	workRight     := NumGet(monitorInfo, 28, "Int") ; Right
	workBottom    := NumGet(monitorInfo, 32, "Int") ; Bottom
	WinRestore, ahk_id %winHandle%
	WinMove, ahk_id %winHandle%,, workLeft + (workRight - workLeft) * (1 - size_percentage) / 2 ; // left edge of screen + half the width of it - half the width of the window, to center it.
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

;} ----------------------------------------------------------------------------------------------------
;					: STANDARD
;{ ____________________________________________________________________________________________________

ExecScript(Script, Wait:=true) {
    shell := ComObjCreate("WScript.Shell")
    exec := shell.Exec("AutoHotkey.exe /ErrorStdOut *")
    exec.StdIn.Write(script)
    exec.StdIn.Close()
    if Wait
        return exec.StdOut.ReadAll()
}

;}----------------------------------------------------------------------------------------------------
;					: MENU
;{ ____________________________________________________________________________________________________

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
			Suspend
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

OnExit("exit")

exit() {
	SystemCursor("On")
	ExitApp
}



;} ----------------------------------------------------------------------------------------------------
;	HOTSTRINGS		: HOTKEYS FOR HOTSTRINGS
;{ ____________________________________________________________________________________________________

^!+F12:: ; Toggles LaTeX Hotstrings
LatexHotstrings()
return


;} ----------------------------------------------------------------------------------------------------
;					: ACTUAL HOTSTRINGS
;{ ____________________________________________________________________________________________________

;					: SPECIAL SYMBOLS (LaTeX)
;{ --------------------------------

; // all of these can be toggled via ctrl alt shift F12, remember to add those to the list.

LatexHotstrings(OnOffToggle := "Toggle") {
	HotString(":o?:\infty","∞", OnOffToggle)
	HotString(":o?:\sqrt","√", OnOffToggle)
	HotString(":o?:\leftrightarrow","↔", OnOffToggle)
	HotString(":o?:\leftarrow","←", OnOffToggle)
	HotString(":o?:\rightarrow","→", OnOffToggle)
	HotString(":o?:\uparrow","↑", OnOffToggle)
	HotString(":o?:\downarroy","↓", OnOffToggle)
	HotString(":o?:\plusminus","±", OnOffToggle)
	HotString(":o?:\times","×", OnOffToggle)
	HotString(":o?:\emptyset","ø", OnOffToggle)
	HotString(":o?:\neq","≠", OnOffToggle)
	HotString(":o?:\leq","≤", OnOffToggle)
	HotString(":o?:\geq","≥", OnOffToggle)
	HotString(":o?:\approx","≈", OnOffToggle)
	HotString(":o?:\sum","∑", OnOffToggle)
	HotString(":o?:\prod","∏", OnOffToggle)
	HotString(":o?:\int","∫", OnOffToggle)
	HotString(":o?:\vert","⊥", OnOffToggle)
	HotString(":o?:\in","∈", OnOffToggle)
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
	HotString(":o?:\sigma","σ", OnOffToggle)
	HotString(":o?:\ssigma","ς", OnOffToggle)
	HotString(":o?:\tau","τ", OnOffToggle)
	HotString(":o?:\upsilon","υ", OnOffToggle)
	HotString(":o?:\phi","φ", OnOffToggle)
	HotString(":o?:\chi","χ", OnOffToggle)
	HotString(":o?:\psi","ψ", OnOffToggle)
	HotString(":o?:\omega","ω", OnOffToggle)
		; //  ˢᵘᵖᵉʳˢᶜʳᶦᵖᵗ & ₛᵤᵦₛ𝒸ᵣᵢₚₜ (i have no idea why the t formats here)
	HotString(":o?:\^0","⁰", OnOffToggle)
	HotString(":o?:\^1","¹", OnOffToggle)
	HotString(":o?:\^2","²", OnOffToggle)
	HotString(":o?:\^3","³", OnOffToggle)
	HotString(":o?:\^4","⁴", OnOffToggle)
	HotString(":o?:\^5","⁵", OnOffToggle)
	HotString(":o?:\^6","⁶", OnOffToggle)
	HotString(":o?:\^7","⁷", OnOffToggle)
	HotString(":o?:\^8","⁸", OnOffToggle)
	HotString(":o?:\^9","⁹", OnOffToggle)
	HotString(":o?:\^x","ˣ", OnOffToggle)
	HotString(":o?:\^y","ʸ", OnOffToggle)
	HotString(":o?:\^i","ᶦ", OnOffToggle)
	HotString(":o?:\^t","ᵗ", OnOffToggle)
	HotString(":o?:\^f","ᶠ", OnOffToggle)

	HotString(":o?:\_0","₀", OnOffToggle)
	HotString(":o?:\_1","₁", OnOffToggle)
	HotString(":o?:\_2","₂", OnOffToggle)
	HotString(":o?:\_3","₃", OnOffToggle)
	HotString(":o?:\_4","₄", OnOffToggle)
	HotString(":o?:\_5","₅", OnOffToggle)
	HotString(":o?:\_6","₆", OnOffToggle)
	HotString(":o?:\_7","₇", OnOffToggle)
	HotString(":o?:\_8","₈", OnOffToggle)
	HotString(":o?:\_9","₉", OnOffToggle)
	HotString(":o?:\_x","ₓ", OnOffToggle)
	HotString(":o?:\_y","ᵧ", OnOffToggle)
	HotString(":o?:\_i","ᵢ", OnOffToggle)
	HotString(":o?:\_t","ₜ", OnOffToggle)
	HotString(":o?:\_f","𝒻", OnOffToggle)
}

; // Not-Latex-Format-Math, not toggleable
:*?:=/=::≠
:*?:+-::±
:*?:~=::≈
; }
;						: AUTOCORRECT	: ENGLISH
;{ --------------------------------
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
; }
; 						: OTHER
;{ --------------------------------

; :*b0:**::**{left 2} ; bold in markdown
; :*b0:__::__{left 2} ; underlined in markdown

; }
;} ----------------------------------------------------------------------------------------------------
;	EVERYTHING HERE WAS ADDED AFTERWARDS OR MODIFIED AUTOMATICALLY
; ---------------------------------------------------------------------------------------------------- 
