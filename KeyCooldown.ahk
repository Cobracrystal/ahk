#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input
SetWorkingDir %A_ScriptDir%
#MaxHotkeysPerInterval 50000
Critical On
scriptenabled := 1
Gui, New, +Border -MaximizeBox
Gui, Add, Checkbox, section Checked1 gScriptToggle, Enable Script
Gui, Add, Button, gReloadScript ys-3, Reload Script
Gui, Add, ListView,vThisList R7 w310 xs, KEY|TYPE|COMMENT
for i, e in Hotkeys(Hotkeys)
    LV_Add("",e.Hotkey, e.Type, e.Comment)
LV_ModifyCol()
Gui, Show, x200y200 NoActivate Autosize,:PauseChamp:
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
;$LButton::MouseCooldown("{Click}",500)
;$RButton::MouseCooldown("{Click,,,Right}",500)

; This is for keys. Line below is the the way it works
; *${KEY}::Cooldown("{KEY}",{Cooldown in ms})

*$ü::Cooldown("ü",3000) ; Cooldown of ü
;*$ä::Cooldown("ä",3000) ; Cooldown of ä
;*$ö::Cooldown("ö",3000) ; Cooldown of ö
;*$d::Cooldown("d",3000)

; This is for a cooldown when you hold down a key
; *${KEY}::Cooldown("{KEY}",{Cooldown in ms},{Maximum Time you can hold the key before it goes on cooldown)
*$Left::KeyHoldingCooldown("Left",2000,2000)


^+R:: ; Reloads Script
ReloadScript() {
	Reload
}

^+K:: ; Closes Script
GuiClose:
ExitApp

^+!F:: ; pauses script
ScriptToggle(ctrlhwnd := 0, guievent := 0, eventinfo := 0) {
	if (ctrlhwnd == 0) {
		GuiControlGet, tvar,, Enable Script
		GuiControl,, Enable Script, !tvar
	}
	Suspend, Toggle
	return
}

Cooldown(keys,cd)
{
	static t:=[]
	if !(t[keys])
		t[keys] := 0
	if (A_TickCount - t[keys] > cd)
	{
		SendInput {%keys% down}
		KeyWait, %keys%, U 
		SendInput {%keys% up}
        t[keys] := A_TickCount
    }
}

KeyHoldingCooldown(keys,n,cd1,cd2)
{
	
	static t:=[]
	if !(t[keys])
		t[keys] := 0
	if (A_TickCount - t[keys] > cd1)
	{
		cd2 := cd2/1000
		SendInput {%keys% Down}
		KeyWait, %keys%, U ; T%cd2%
		SendInput {%keys% Up}
		t[keys] := A_TickCount
    }
}

MouseCooldown(keys,n,cd)
{
	static t:=[A_TickCount,A_TickCount]
    if (A_TickCount - t[n] > cd)
	{
		SendInput %keys%
        t[n] := A_TickCount
    }
}

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

