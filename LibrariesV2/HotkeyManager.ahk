;// made by Cobracrystal
;------------------------- AUTO EXECUTE SECTION -------------------------
#Include %A_ScriptDir%\LibrariesV2\BasicUtilities.ahk

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
    FileRead, script, %A_ScriptFullPath%
    cleanScript := cleanComments(script) 
	; no comments like /* this */ or ( this )
    Hotkeys := {}
	Loop, Parse, cleanScript, `n, `r
	if RegExMatch(A_LoopField,"O)^((?!\s*(;|:.*:.*:`:|.*=.*:`:|.*"".*:`:|Gui)).*)::(?:.*;)?\s*(.*)",match)	{  ;//matches hotkey text and recognizes ";", hotstrings, quotes and Gui as negative lookaheads
		comment := (match[3] == "" ? "None" : match[3])
		hkey := match[1]
	;	if !(RegExMatch(hkey,"(Shift|Alt|Ctrl|Win)"))	{
			hkey := (InStr(hkey, "+") == StrLen(hkey) ? hkey : StrReplace(hkey, "+", "Shift+", limit:=1))
			hkey := StrReplace(hkey, "<^>!", "AltGr+", limit:=1)
			hkey := StrReplace(hkey, "<", "Left", limit:=-1)
			hkey := StrReplace(hkey, ">", "Right", limit:=-1)
			hkey := StrReplace(hkey, "!", "Alt+", limit:=1)
			hkey := StrReplace(hkey, "^", "Ctrl+", limit:=1)
			hkey := StrReplace(hkey, "#", "Win+", limit:=1)
			hkey := StrReplace(hkey, "*","", limit:=1)
			hkey := StrReplace(hkey, "$","", limit:=1)
			hkey := StrReplace(hkey, "~","", limit:=1)
	;	}
		Hotkeys.Push({"Line":A_Index, "Hotkey":hkey, "Comment":comment})
	}
	return Hotkeys
}

Hotstrings(ByRef Hotstrings)	{
    FileRead, script, %A_ScriptFullPath%
    cleanScript := cleanComments(script)
    Hotstrings := {}
    Loop, Parse, cleanScript, `n, `r
        if RegExMatch(A_LoopField,"Oi)^\s*:([0-9\*\?BCKOPRSIEZ]*?):(.*?):`:(.*)\;?\s*(.*)", match) || RegexMatch(A_LoopField, "Oi)^\s*(?:HotString|Hotstring)\(\"":([0-9\*\?BCKOPRSIEZ]*?):(.*?)\"",\""(?:(.*)\""),.*?\)\s*\;?\s*(.*)", match)	{
			;// EXPLANATION: start of line : [possible modifiers only once]:[string]:(escape char):(seconds string)[check for spaces][comment] OR ALTERNATIVELY
			;// HotString(" (<- escaped via "" which turns into ", and that escaped via \ so \"" = ")[modifiers]:[string]","[replacement]", [variable which we don't need])
			hString := match[2]
			rString := match[3]
			comment := (match[4] == "" ? "None" : match[4])
			if RegExMatch(hString,"({:}|{!})")	{
				hString := StrReplace(hString, "{:}", ":", limit:=-1)
				hString := StrReplace(hString, "{!}", "!", limit:=-1)
            }
			if RegExMatch(rString,"({:}|{!}||{Space})")	{
				rString := StrReplace(rString, "{:}", ":", limit:=-1)
				rString := StrReplace(rString, "{!}", "!", limit:=-1)
				rString := StrReplace(rString, "{Space}", " ", limit:=-1)
            }
			if RegexMatch(match[1], ".*b0.*")
				rString := hString . rString
            Hotstrings.Push({"Line":A_Index, "Options":match[1], "Hotstring":hString, "Replacestring":rString, "Comment":match[4]})
        }
    return Hotstrings
}

SavedHotkeys(ByRef SavedHotkeys)	{
	if 	!(FileExist("HotkeyManager\SavedHotkeys.txt")) {
		MsgBox, % "Created SavedHotkeys.txt in script folder in case of Custom Hotkeys added by user"
		FileCreateDir, % "HotkeyManager"
		FileAppend, % "// Add Custom Hotkeys not from the script here to show up in the Hotkey List.`n// Format is Hotkey/Hotstring:[hotkey/hotstring], [Program], [Command (optional)]", HotkeyManager\SavedHotkeys.txt
		return
	}
	FileRead, Script, HotkeyManager\SavedHotkeys.txt
    SavedHotkeys := {}
    Loop, Parse, Script, `n, `r
        if RegExMatch(A_LoopField,"O)^(?!\s*;|//)Hotkey:\s*(.*)\s*,\s*(.*)\s*,\s*(.*)\s*",match)	{ 
			comment := (match[3] == "" ? "None" : match[3])
            SavedHotkeys.Push({"Hotkey":match[1], "Program":match[2], "Comment":comment})
        }
    return SavedHotkeys
}

cleanComments(script) {
	flagCom := false
	flagMult := false
	cleanScript := ""
	Loop, Parse, script, `n, `r
	{
		if (flagCom) {
			if (RegExMatch(A_Loopfield, "^\s*\*\/"))
				flagCom := false
			cleanScript .= "`n"
		}
		else if (RegExMatch(A_Loopfield, "^\s*\/\*")) {
			flagCom := true
			cleanScript .= "`n"
		}
		else if (flagMult) {
			if (RegExMatch(A_Loopfield, "^\s*\)"))
				flagMult := false
			cleanScript .= "`n"
		}
		else if (RegExMatch(A_Loopfield, "^\s*\(")) {
			flagMult := true
			cleanScript .= "`n"
		}
		else
			cleanScript .= A_LoopField . "`n"
	}
	return cleanScript
;	return RegExReplace(script, "ms`a)^\s*\/\*.*?^\s*\*\/\s*|^\s*\(.*?^\s*\)\s*") 
}
; -------- MAIN GUI

hotkeyManagerGuiCreate(guiX, guiY) {
	global HotkeyListView, SavedHotkeyListView, HotstringListView
	Gui, HotkeyManager:New, +Border +HwndguiHWND
	Gui, HotkeyManager:Add, Tab3, w526 h500, AHK Hotkeys|Other Hotkeys|Hotstrings|Settings
	Gui, Tab, 1 ; below controls belong to first tab
	Gui, HotkeyManager:Add, ListView, vHotkeyListView AltSubmit gHotkeyGuiEvent R25 w500, LINE|KEYS|COMMENT
		for Index, Element in Hotkeys(Hotkeys)
			LV_Add("",Element.Line, Element.Hotkey, Element.Comment)
		LV_ModifyCol()
		LV_ModifyCol(1,"38 Integer")
		LV_ModifyCol(2)
	Gui, Tab, 2
	Gui, HotkeyManager:Add, ListView, vSavedHotkeyListView AltSubmit gHotkeyGuiEvent R25 w500, LINE|KEYS|PROGRAM|COMMENT
		for Index, Element in SavedHotkeys(SavedHotkeys)
			LV_Add("","*", Element.Hotkey, Element.Program, Element.Comment)
		LV_ModifyCol()
		LV_ModifyCol(1,"38 Integer")
		LV_ModifyCol(3,68)
	Gui, Tab, 3
	Gui, HotkeyManager:Add, ListView, vHotstringListView AltSubmit gHotstringGuiEvent R22 w500, LINE|OPTIONS|TEXT|CORRECTION|COMMENT
		for Index, Element in Hotstrings(Hotstrings)
			LV_Add("",Element.Line, Element.Options, Element.Hotstring, Element.Replacestring,  Element.Comment)
		LV_ModifyCol()
		LV_ModifyCol(1,"38 Integer")
		LV_ModifyCol(5,155)
		createHotkeyManagerHotstringEditor()
	Gui, Tab, 4
		Gui, Add, Text, Section, Enable Settings
		Gui, Add, Checkbox, xs, Enable Settings
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
				Run, notepad++ %A_ScriptFullPath% -n%hotkeyLine%
		Default: return
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
		Default: return
	}
}

; -------- HOTSTRING EDITOR

createHotkeyManagerHotstringEditor() {
	Gui, Font, s11
	Gui, HotkeyManager:Add, GroupBox, w500 h55, Custom Hotstrings
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
} 

CustomHotstringCreator() {
	global CustomHotstringModifiers
	global CustomHotstringInput
	global CustomHotstringReplacement
	global CustomHotstringComment
	global InvalidHotstringText
	Gui, HotkeyManager:Submit, NoHide
	if !(RegexMatch(CustomHotstringModifiers, "i)^[0-9\*\?BCKOPRSIEZ]*?$") && CustomHotstringInput != "" && CustomHotstringReplacement != "") {
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
		run, Notepad++ HotkeyManager\SavedHotkeys.txt
	} catch e {
		run, notepad HotkeyManager\SavedHotkeys.txt
	}
}
