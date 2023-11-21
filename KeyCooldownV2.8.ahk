#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input
SetWorkingDir %A_ScriptDir%
#MaxHotkeysPerInterval 50000
Critical On
scriptenabled := 1
Gui, gui1:Default
Gui, gui1:New, +Border -MaximizeBox
Gui, gui1:Add, Checkbox, section gScriptToggle, Enable Script
Gui, gui1:Add, Button, gReloadScript ys-3, Reload Script
Gui, gui1:Add, ListView,vThisList R7 w310 xs, KEY|TYPE|COMMENT
for Index, Element in Hotkeys(Hotkeys)
    LV_Add("",Element.Hotkey, Element.Type, Element.Comment)
LV_ModifyCol()
Gui, gui1:Show, x200y200 NoActivate Autosize,:PauseChamp:
GuiControl,gui1:, Enable Script, 1
;SetTimer, CheckGui, 200
return

; ";" means comment, so if you want a hotkey do deactivate for now just add ; in front of it
; Adding keys: Simply copy the line above and raise the number of hotkey cooldown by 1. (and change the hotkey key in the start and in the "")
; Then, in the "static t:=[...], one more A_TickCount needs to be added corresponding to the number. (Currently there are 10)
; the current keys are setup in a way that any modifier key (alt, windows key, ctrl, shift, alt gr) will be verriden, 
; which is there because for example Sprinting with Ctrl + W would be a different keypress than only W and would have a different cooldown from W.
; If a modifier key is actually changing the key, simply remove the "*" in front of the hotkey and or add the modifier key
; ^ = ctrl, ! = Alt, # = Windows, + = Shift. Therefore ^w:: is ctrl + w. If you manually add that, you would have sprinting on a cooldown, but not walking. ; uwu
; ctrl + shift + R is to reload the script after editing something in here.
; ctrl + shift + alt + F to completely stop the hotkey functions.



; This is for left/rightclick. remove ; to enable
;$LButton::MouseCooldown("{Click}",1,500)
;$RButton::MouseCooldown("{Click,,,Right}",2,500)

; This is for keys. Line below is the the way it works
; *${KEY}::Cooldown("{KEY}",{number of hotkey cooldown},{Cooldown in ms})

*$ü::Cooldown("ü",1,3000) ; Cooldown of ü
;*$ä::Cooldown("ä",2,3000) ; Cooldown of ä
;*$ö::Cooldown("ö",3,3000) ; Cooldown of ö
;*$d::Cooldown("d",4,3000)

; This is for a cooldown when you hold down a key
; *${KEY}::Cooldown("{KEY}",{number of hotkey cooldown},{Cooldown in ms},{Maximum Time you can hold the key before it goes on cooldown)
*$Left::KeyHoldingCooldown("Left",1,2000,2000)


^+R:: ; Reloads Script
ReloadScript:
Reload

^+!F:: ; Toggles Script Activity
Suspend, Toggle
scriptenabled := !scriptenabled
GuiControl,gui1:, Enable Script, %scriptenabled%
return


^+K:: ; Closes Script
GuiClose:
ExitApp

ScriptToggle:
scriptenabled := !scriptenabled
Suspend, Toggle
return

Cooldown(keys,n,cd)
{
	static t:=[A_TickCount,A_TickCount,A_TickCount,A_TickCount,A_TickCount,A_TickCount,A_TickCount,A_TickCount,A_TickCount,A_TickCount]
    if (A_TickCount - t[n] > cd)
	{
		SendInput {%keys% down}
		KeyWait, %keys%, U 
		SendInput {%keys% up}
        t[n] := A_TickCount
    }
}

KeyHoldingCooldown(keys,n,cd1,cd2)
{
	static t3:=[A_TickCount,A_TickCount,A_TickCount,A_TickCount,A_TickCount,A_TickCount,A_TickCount,A_TickCount,A_TickCount,A_TickCount]
    if (A_TickCount - t3[n] > cd1)
	{
		cd2 := cd2/1000
		SendInput {%keys% Down}
		KeyWait, %keys%, U ; T%cd2%
		SendInput {%keys% Up}
		t3[n] := A_TickCount
    }
}

MouseCooldown(keys,n,cd)
{
	static t2:=[A_TickCount,A_TickCount]
    if (A_TickCount - t2[n] > cd)
	{
		SendInput %keys%
        t2[n] := A_TickCount
    }
}

CheckGui:
Gui, gui1:Submit, NoHide
return

Hotkeys(ByRef Hotkeys)
{
    FileRead, Script, %A_ScriptFullPath%
    Script :=  RegExReplace(Script, "ms`a)^\s*/\*.*?^\s*\*/\s*|^\s*\(.*?^\s*\)\s*")
    Hotkeys := {}
    Loop, Parse, Script, `n, `r
        if RegExMatch(A_LoopField,"(?!;)^\s*(.*):`:",Match) ; OLD VERSION
        {
			RegExMatch(A_LoopField,"(?!;)^\s*(.*):`:.*`;\s?(.*)",Comment)
			if (Comment = "")
				Comment2 = None
			if RegExMatch(A_LoopField,"(?!;)^\s*(.*):`:Cooldown(.*)")
				Type := "Key Cooldown"
			else if RegExMatch(A_LoopField,"(?!;)^\s*(.*):`:KeyHoldingCooldown(.*)")
				Type := "Holding Key CD"
			else if RegExMatch(A_LoopField,"(?!;)^\s*(.*):`:MouseCooldown(.*)")
				Type := "Mouse Cooldown"
			else 
				Type := "Hotkey"
            if !RegExMatch(Match1,"(Shift|Alt|Ctrl|Win)")
            {
				Match1 := StrReplace(Match1, "+", "Shift+", limit:=1)
				Match1 := StrReplace(Match1, "<^>!", "AltGr+", limit:=1)
				Match1 := StrReplace(Match1, "<", "Left", limit:=-1)
				Match1 := StrReplace(Match1, ">", "Right", limit:=-1)
				Match1 := StrReplace(Match1, "!", "Alt+", limit:=1)
				Match1 := StrReplace(Match1, "^", "Ctrl+", limit:=1)
				Match1 := StrReplace(Match1, "#", "Win+", limit:=1)
				Match1 := StrReplace(Match1, "*","", limit:=1)
				Match1 := StrReplace(Match1, "$","", limit:=1)
            }
            Hotkeys.Push({"Hotkey":Match1, "Type":Type, "Comment":Comment2})
        }
    return Hotkeys
}

