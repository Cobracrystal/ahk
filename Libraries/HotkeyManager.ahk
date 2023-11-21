;// made by Cobracrystal
;------------------------- AUTO EXECUTE SECTION -------------------------
#Include %A_ScriptDir%\Libraries\BasicUtilities.ahk

;// Add two options on top of the normal Tray Menu
Menu, FILES, Add, Edit Hotkey File, editSavedHotkeys
Menu, GUIS, Add, Open Hotkey GUI, HotkeyManager
Menu, Tray, Add, Files, :FILES
Menu, Tray, Add, GUIs, :GUIS
Menu, Tray, Nostandard
Menu, Tray, Standard

;------------------------------------------------------------------------

; RIDICULOUSLY COMPLICATED TODO:
; A) MAKE FUNCTION THAT REMOVES /* */ COMMENTS WHILE KEEPING LINECOUNT
; B) CHECK ALL INCLUDED FILES FOR HOTKEYS
; C) CREATE SEARCH FUNCTION IN MAIN GUI
; D) SETTINGS TAB TO SAVE STYLE
; E) ; BINDING GUI CLOSE FUNCTIONS INSIDE A CLASS !!!! MAKE ALL THIS INTO ONE CLASS https://www.autohotkey.com/boards/viewtopic.php?t=64337 

; -------- MAIN FUNCTION 
HotkeyManager(mode := "O") {
	; mode = O(pen), C(lose), T(oggle)
	static guiHWND, guiCoords := [300,135] ;// to access the HWND for WinExist
	mode := SubStr(mode, 1, 1)
	if (WinExist("ahk_id" . guiHWND)) {
		if (mode == "O") 
			WinActivate, ahk_id %guiHWND%
		else { ; if gui does exist and mode = close/toggle, close
			guiCoords := windowGetCoordinates(guiHWND)
			Gui, HotkeyManager:Destroy
		}
	}
	else {
		if (mode != "C") ; if gui doesn't exist and mode = open/toggle, create
			guiHWND := hotkeyManagerGuiCreate(guiCoords[1], guiCoords[2]) 
	}
	return
}

; -------- LOADING IN DATA
Hotkeys(ByRef Hotkeys)	{
    FileRead, Script, %A_ScriptFullPath%
    Script :=  RegExReplace(Script, "ms`a)^\s*/\*.*?^\s*\*/\s*|^\s*\(.*?^\s*\)\s*") ;// no comments like /* this */
    Hotkeys := {}
    Loop, Parse, Script, `n, `r
		if RegExMatch(A_LoopField,"^((?!\s*(;|:.*:.*:`:|.*=.*:`:|.*"".*:`:|Gui)).*)::(?:.*;)?\s*(.*)",Match)	{  ;//matches hotkey text and recognizes ";", hotstrings, quotes and Gui as negative lookaheads
			if (Match3 = "")
				Match3 = None
            if !(RegExMatch(Match1,"(Shift|Alt|Ctrl|Win)") && !RegExMatch(Match1,"LWin"))	{
				Match1 := StrReplace(Match1, "+", "Shift+", limit:=1)
				Match1 := StrReplace(Match1, "<^>!", "AltGr+", limit:=1)
				Match1 := StrReplace(Match1, "<", "Left", limit:=-1)
				Match1 := StrReplace(Match1, ">", "Right", limit:=-1)
				Match1 := StrReplace(Match1, "!", "Alt+", limit:=1)
				Match1 := StrReplace(Match1, "^", "Ctrl+", limit:=1)
				Match1 := StrReplace(Match1, "#", "Win+", limit:=1)
				Match1 := StrReplace(Match1, "*","", limit:=1)
				Match1 := StrReplace(Match1, "$","", limit:=1)
				Match1 := StrReplace(Match1, "~","", limit:=1)
            }
            Hotkeys.Push({"Line":A_Index, "Hotkey":Match1, "Comment":Match3})
        }
    return Hotkeys
}

Hotstrings(ByRef Hotstrings)	{
    FileRead, Script, %A_ScriptFullPath%
    Script :=  RegExReplace(Script, "ms`a)^\s*/\*.*?^\s*\*/\s*|^\s*\(.*?^\s*\)\s*")
    Hotstrings := {}
    Loop, Parse, Script, `n, `r
        if RegExMatch(A_LoopField,"^\s*:([0-9\*\?BbCcKkOoPpRrSsIiEeZz]*?):(.*?):`:(.*)\;?\s*(.*)", Match) || RegexMatch(A_LoopField, "^\s*(?:HotString|Hotstring)\(\"":([0-9\*\?BbCcKkOoPpRrSsIiEeZz]*?):(.*?)\"",\""(?:(.*)\""),.*?\)\s*\;?\s*(.*)", Match)	{
			;// EXPLANATION: start of line : [possible modifiers only once]:[string]:(escape char):(seconds string)[check for spaces][comment] OR ALTERNATIVELY
			;// HotString(" (<- escaped via "" which turns into ", and that escaped via \ so \"" = ")[modifiers]:[string]","[replacement]", [variable which we don't need])
			if (Match4 = "")	{
				Match4 := "None"
			}
			if RegExMatch(Match2,"({:}|{!})")	{
				Match2 := StrReplace(Match2, "{:}", ":", limit:=-1)
				Match2 := StrReplace(Match2, "{!}", "!", limit:=-1)
            }
			if RegExMatch(Match3,"({:}|{!}||{Space})")	{
				Match3 := StrReplace(Match3, "{:}", ":", limit:=-1)
				Match3 := StrReplace(Match3, "{!}", "!", limit:=-1)
				Match3 := StrReplace(Match3, "{Space}", " ", limit:=-1)
            }
			if RegexMatch(Match1, ".*b0.*")
				Match3 := Match2 . Match3
            Hotstrings.Push({"Line":A_Index, "Options":Match1, "Hotstring":Match2, "Replacestring":Match3, "Comment":Match4})
        }
    return Hotstrings
}

SavedHotkeys(ByRef SavedHotkeys)	{
	if 	!(FileExist("SavedHotkeys.txt")) {
		MsgBox, % "Created SavedHotkeys.txt in script folder in case of Custom Hotkeys added by user"
		FileAppend, % "// Add Custom Hotkeys not from the script here to show up in the Hotkey List.`n// Format is Hotkey/Hotstring:[hotkey/hotstring], [Program], [Command (optional)]", SavedHotkeys.txt
		return
	}
	FileRead, Script, SavedHotkeys.txt
    SavedHotkeys := {}
    Loop, Parse, Script, `n, `r
        if RegExMatch(A_LoopField,"^(?!\s*;|//)Hotkey:\s*(.*)\s*,\s*(.*)\s*,\s*(.*)\s*",Match)	{ 
			if (Match3 = "")
				Match3 = None
            SavedHotkeys.Push({"Hotkey":Match1, "Program":Match2, "Comment":Match3})
        }
    return SavedHotkeys
}

; -------- MAIN GUI

hotkeyManagerGuiCreate(guiX, guiY) {
	global HotkeyListView, SavedHotkeyListView, HotstringListView
	Gui, HotkeyManager:New, +Border +HwndguiHWND
	Gui, HotkeyManager:Add, Tab3, w526 h500, AHK Hotkeys|Other Hotkeys|Hotstrings|Settings
	Gui, Tab, 1 ; below controls belong to first tab
	Gui, HotkeyManager:Add, ListView, vHotkeyListView AltSubmit gHotkeyGuiEvent R25 w500, LINE|KEYS|PROGRAM|COMMENT
		for Index, Element in Hotkeys(Hotkeys)
			LV_Add("",Element.Line, Element.Hotkey, "ahk", Element.Comment)
		LV_ModifyCol()
		LV_ModifyCol(1,"38 Integer")
		LV_ModifyCol(3,68)
	Gui, Tab, 2
	Gui, HotkeyManager:Add, ListView, vSavedHotkeyListView AltSubmit gHotkeyGuiEvent R25 w500, LINE|KEYS|PROGRAM|COMMENT
		for Index, Element in SavedHotkeys(SavedHotkeys)
			LV_Add("","*", Element.Hotkey, Element.Program, Element.Comment)
	Gui, Tab, 3
	Gui, HotkeyManager:Add, ListView, vHotstringListView AltSubmit gHotstringGuiEvent R25 w500, LINE|OPTIONS|TEXT|CORRECTION|COMMENT
		for Index, Element in Hotstrings(Hotstrings)
			LV_Add("",Element.Line, Element.Options, Element.Hotstring, Element.Replacestring,  Element.Comment)
		LV_ModifyCol()
		LV_ModifyCol(1,"38 Integer")
		LV_ModifyCol(5,155)
		createHotkeyManagerHotstringEditor()
	Gui, HotkeyManager:Show, x%guiX%y%guiY% Autosize, HotkeyList
	return guiHWND
}

hotkeyManagerGuiCreateOldStyle(guiX, guiY) {
	Gui, HotkeyManager:New, +Border +HwndguiHWND
	Gui, HotkeyManager:Add, ListView, vHotkeyListView AltSubmit gHotkeyGuiEvent R20 w500, LINE|KEYS|PROGRAM|COMMENT
		for Index, Element in Hotkeys(Hotkeys)
			LV_Add("",Element.Line, Element.Hotkey, "ahk", Element.Comment)
		for Index, Element in SavedHotkeys(SavedHotkeys)
			LV_Add("","*", Element.Hotkey, Element.Program, Element.Comment)
		LV_ModifyCol()
		LV_ModifyCol(1,"38 Integer")
		LV_ModifyCol(3,68)
	Gui, HotkeyManager:Add, ListView, vHotstringListView AltSubmit gHotstringGuiEvent R20 w500 xs, LINE|OPTIONS|TEXT|CORRECTION|COMMENT
		for Index, Element in Hotstrings(Hotstrings)
			LV_Add("",Element.Line, Element.Options, Element.Hotstring, Element.Replacestring,  Element.Comment)
		LV_ModifyCol()
		LV_ModifyCol(1,"38 Integer")
		LV_ModifyCol(5,155)
		createHotkeyManagerHotstringEditor()
		Gui, HotkeyManager:Show, x%guiX%y%guiY% Autosize, HotkeyList
	return guiHWND
}

HotkeyManagerGuiEscape(guiHWND) {
	HotkeyManager("Close")
}

hotkeyManagerGuiClose(guiHWND) {
	HotkeyManager("Close")
}

; -------- MAIN GUI EVENTS

HotkeyGuiEvent() {
	global HotkeyListView
	Gui, ListView, HotkeyListView
	LV_GetText(hotkeyLine, A_EventInfo, 1)
	switch A_GuiEvent {
		case "DoubleClick": 
			if hotkeyLine is integer
				Run, "C:\Program Files\Notepad++\notepad++.exe" %A_ScriptFullPath% -n%hotkeyLine%
		Default: return ; //for future compatibility
	}
}

HotstringGuiEvent() {
	global HotstringListView
	Gui, ListView, HotstringListView
	LV_GetText(hotstringLine, A_EventInfo, 1)
	Switch A_GuiEvent {
		Case "DoubleClick": 
			if hotstringLine is integer 
				Run, Notepad++ %A_ScriptFullPath% -n%hotstringLine%
		Default: return ; //for future compatibility
	}
}

; -------- HOTSTRING EDITOR

createHotkeyManagerHotstringEditor() {
	Gui, Font, s11
	Gui, HotkeyManager:Add, GroupBox, w500 h80, Custom Hotstrings
		Gui, Font, s15 
		Gui, HotkeyManager:Add, Text, Section Center xp+15 yp+15, :
		Gui, Font, s9 Norm
		Gui, HotkeyManager:Add, Edit, vCustomHotstringModifiers ys+5 xp+8 r1 w30
		Gui, HotkeyManager:Add, Text, xp+3 yp+3, c*
		Gui, Font, s15 
		Gui, HotkeyManager:Add, Text, Center ys xp+28, :	
		Gui, Font, s9 Norm
		Gui, HotkeyManager:Add, Edit, vCustomHotstringInput ys+5 xp+8 r1 w75
		Gui, HotkeyManager:Add, Text, xp+3 yp+3, js@g
		Gui, Font, s15 
		Gui, HotkeyManager:Add, Text, Center ys xp+73, ::
		Gui, Font, s9 Norm
		Gui, HotkeyManager:Add, Edit, vCustomHotstringReplacement ys+5 xp+14 r1 w125
		Gui, HotkeyManager:Add, Text, xp+3 yp+3, johnsmith@gmail.com
		Gui, Font, s15 
		Gui, HotkeyManager:Add, Text, Center ys xp+127, `; 
		Gui, Font, s9 Norm
		Gui, HotkeyManager:Add, Edit, vCustomHotstringComment ys+5 xp+10 r1 w100 
		Gui, HotkeyManager:Add, Text, xp+3 yp+3, Comment (optional)
		Gui, HotkeyManager:Add, Button, ys+5 w80 Default gCustomHotstringCreator, Add HotString
		Gui, HotkeyManager:Add, Text, vInvalidHotstringText Hidden, Invalid Hotstring!
		Gui, HotkeyManager:Add, Text, xs, Common Hotstring Modifiers: *, ?, b0 , c, c1, o, r, x, z
} 

CustomHotstringCreator() {
	global CustomHotstringModifiers
	global CustomHotstringInput
	global CustomHotstringReplacement
	global CustomHotstringComment
	global InvalidHotstringText
	Gui, HotkeyManager:Submit, NoHide
	if !(RegexMatch(CustomHotstringModifiers, "^[0-9\*\?BbCcKkOoPpRrSsIiEeZz]*?$") && CustomHotstringInput != "" && CustomHotstringReplacement != "") {
		GuiControl, HotkeyManager:Show, InvalidHotstringText
		Gui, HotkeyManager:Flash
		SoundPlay, *-1
		return
	}
	GuiControl, HotkeyManager:Hide, InvalidHotstringText
	if (CustomHotstringComment)
		FullCustomHotstringComment := A_Tab . "; " . CustomHotstringComment
	CustomHotstring := ":" . CustomHotstringModifiers . ":" . CustomHotstringInput . "::" . CustomHotstringReplacement . FullCustomHotstringComment
	MsgBox, 1, Confirm Dialog, Add  "%CustomHotstring%" to this script?`nYou will need to reload the script for this to have any effect.
	IfMsgBox, Cancel
		return
	FileAppend, `n%CustomHotstring%, %A_ScriptFullPath%
	Gui, ListView, HotstringListView
	LV_Add("", "NaN", CustomHotstringModifiers, CustomHotstringInput, CustomHotstringReplacement, CustomHotstringComment ? CustomHotstringComment : "None")
}

; -------- MENU FUNCTIONS

editSavedHotkeys() {
	try {
		run, Notepad++ SavedHotkeys.txt
	} catch e {
		run, notepad SavedHotkeys.txt
	}
}
