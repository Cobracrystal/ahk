;// made by Cobracrystal
;------------------------- AUTO EXECUTE SECTION -------------------------
;// Coordinates for first creation of window
global hotkeyManagerGuiPosX := -530
global hotkeyManagerGuiPosY := 35

;// Add two options on top of the normal Tray Menu
Menu, Tray, Add, Edit Settings File, editSettings
Menu, Tray, Add, Open Hotkey GUI, showHotkeyManagerGui
Menu, Tray, Nostandard
Menu, Tray, Standard

;------------------------------------------------------------------------
 
editSettings() {
	run, Notepad++ SavedHotkeys.txt
}

showHotkeyManagerGui() {
	global hotkeyManagerGuiHwnd ;// to access the HWND for WinExist
	if !WinExist("ahk_id"  hotkeyManagerGuiHwnd)
		createHotkeyManagerGui(hotkeyManagerGuiPosX, hotkeyManagerGuiPosY)
	else
		WinActivate, ahk_id %hotkeyManagerGuiHwnd%
}

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
    ; Script :=  RegExReplace(Script, "ms`a)^\s*/\*.*?^\s*\*/\s*|^\s*\(.*?^\s*\)\s*")
    Hotstrings := {}
    Loop, Parse, Script, `n, `r
        if RegExMatch(A_LoopField,"^\s*:([0-9\*\?BbCcKkOoPpRrSsIiEeZz]*?):(.*?):`:(?:(.*)\;)?\s*(.*)", Match)	{
			if (Match3 = "")	{
				Match3 = %Match4%
				Match4 = None
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
				Match3 = %Match2%%Match3%
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

createHotkeyManagerGui(hotkeyManagerGuiPosX, hotkeyManagerGuiPosY) {
	global hotkeyManagerGuiHwnd
	Gui, HotkeyManager:New, +Border +HwndhotkeyManagerGuiHwnd
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
		LV_ModifyCol(2,60)
		LV_ModifyCol(5,155)
		createHotkeyManagerHotstringEditor()
		Gui, HotkeyManager:Show, x%hotkeyManagerGuiPosX%y%hotkeyManagerGuiPosY% Autosize, HotkeyList
}

HotkeyManagerGuiEscape(GuiHwnd) {
	HotkeyManagerGuiClose(GuiHwnd)
}

HotkeyManagerGuiClose(GuiHwnd) {
	WinGet, minimize_status, MinMax, ahk_id %GuiHwnd%
	if (minimize_status <> -1) 
		WinGetPos, hotkeyManagerGuiPosX, hotkeyManagerGuiPosY,,, ahk_id %GuiHwnd%
	else {
		VarSetCapacity(pos, 44, 0)
		NumPut(44, pos)
		DllCall("GetWindowPlacement", "uint", GuiHwnd, "uint", &pos)
		hotkeyManagerGuiPosX := NumGet(pos, 28, "int")
		hotkeyManagerGuiPosY := NumGet(pos, 32, "int")
		/*
		DetectHiddenWindows, On
		WinHide, ahk_id %GuiHwnd%
		WinRestore, ahk_id %GuiHwnd%
		WinGetPos, hotkeyManagerGuiPosX, hotkeyManagerGuiPosY,,, ahk_id %GuiHwnd%
		DetectHiddenWindows, Off
		*/
	}
	Gui, HotkeyManager:Destroy
	return 0
}

HotkeyGuiEvent() {
	global HotkeyListView
	Gui, ListView, HotkeyListView
	LV_GetText(hotkeyLine, A_EventInfo, 1)
	Switch A_GuiEvent {
		Case "DoubleClick": 
			if hotkeyLine is integer 
				Run, Notepad++ %A_ScriptFullPath% -n%hotkeyLine%
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

CustomHotstringCreator() {
	global CustomHotstringModifiers
	global CustomHotstringInput
	global CustomHotstringReplacement
	global CustomHotstringComment
	global InvalidHotstringText
	Gui, HotkeyManager:Submit, NoHide
	if !(RegexMatch(CustomHotstringModifiers, "^[0-9\*\?BbCcKkOoPpRrSsIiEeZz]*?$") && CustomHotstringInput && CustomHotstringReplacement) {
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