A_MaxHotkeysPerInterval := 50000
Critical(1)
scriptenabled := 1
keygui := Gui("+Border -MaximizeBox", "Hotkey Script")
keygui.OnEvent("Close", (*) => ExitApp())
checkbox := keygui.AddCheckbox("Section Checked1", "Enable Script").OnEvent("Click", (*) => scriptToggle())
keygui.AddButton("ys-3", "Reload Script").OnEvent("Click", (*) => Reload())
lv := keygui.AddListView("R7 w310 xs", ["Key", "Type", "Comment"])
for i, e in getHotkeys()
    lv.Add("",e.Hotkey, e.Type, e.Comment)
lv.ModifyCol()
keygui.Show("x200 y200 NoActivate")
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


^+R::Reload() ; Reloads Script

^+K::ExitApp() ; Closes Script

^+!F:: ; pauses script
ScriptToggle(ctrlObj := 0, info := 0) {
	if (ctrlObj == 0) {
		global checkbox
		checkbox.Value := !checkbox.Value
	}
	Suspend(-1)
	return
}

Cooldown(keys,cd)
{
	static t:=Map()
	if !(t.Has(keys))
		t[keys] := 0
	if (A_TickCount - t[keys] > cd)
	{
		SendInput("{" keys " Down}")
		KeyWait(keys, "U") 
		SendInput("{" keys " Up}")
        t[keys] := A_TickCount
    }
}

KeyHoldingCooldown(keys,cd1,cd2)
{
	
	static t:=Map()
	if !(t.Has(keys))
		t[keys] := 0
	if (A_TickCount - t[keys] > cd1)
	{
		cd2 := cd2/1000
		SendInput("{" keys " Down}")
		KeyWait(keys, "U") 
		SendInput("{" keys " Up}")
		t[keys] := A_TickCount
    }
}

MouseCooldown(keys,n,cd)
{
	static t:=[A_TickCount,A_TickCount]
    if (A_TickCount - t[n] > cd)
	{
		SendInput(keys)
        t[n] := A_TickCount
    }
}

; # Imported
getHotkeys()	{
    script := getFullScript()
	hotkeys := []
	hotkeyModifiers := [  {mod:"+", replacement:"Shift"}, {mod:"<^>!", replacement:"AltGr"}
						, {mod:"^", replacement:"Ctrl"}	, {mod:"!", replacement:"Alt"}
						, {mod:"#", replacement:"Win"}  , {mod:"<", replacement:"Left"}
						, {mod:">",	replacement:"Right"}]
	Loop Parse, script, "`n", "`r" { ; loop parse > strsplit for memory
		if !(InStr(SubStr(A_Loopfield, 1, RegexMatch(A_Loopfield, "\s;")), "::")) ; skip non-hotkeys
			continue
		StrReplace(SubStr(A_Loopfield, 1, InStr(A_Loopfield, "::")), "`"",,, &count)
		if (count > 1) ; skip strings containing two quotes before ::
			continue
		; matches duo keys, modifier keys, modifie*d* leys, numeric value hotkeys, virtual key code hkeys and gets comment after
		if RegExMatch(A_LoopField,"^((?!(?:;|:.*:.*::|(?!.*\s&\s|^\s*[\^+!#<>~*$]*`").*`".*::)).*)::\s*{?(?:.*;)?\s*(.*)", &match)	{
			comment := match[2]
			hkey := LTrim(match[1])
			if RegExMatch(A_LoopField,"^.*::Cooldown.*")
				hType := "Key Cooldown"
			else if RegExMatch(A_LoopField,"^.*::KeyHoldingCooldown.*")
				hType := "Holding Key CD"
			else if RegExMatch(A_LoopField,"^.*::MouseCooldown.*")
				hType := "Mouse Cooldown"
			else 
				hType := "Hotkey"
			if (InStr(hkey, " & ")) { ; if duo hotkey, modifiers are impossible so push
				hotkeys.push({line:A_Index, hotkey:hkey, type:hType, comment:comment})
				continue
			}
			if (StrLen(hkey) == 1) { ; single key can't be a modifier ~> symbol is hotkey
				hotkeys.push({line:A_Index, hotkey:hkey, type:hType, comment:comment})
				continue
			}
			if (hkey == "<^>!") { ; altgr = leftCtrl + RightAlt, but on its own LeftCtrl + excl mark
				hotkeys.push({line:A_Index, hotkey:"Left Ctrl + !", type:hType, comment:comment})
				continue
			}
			hk := SubStr(hkey, 1, -1)
			for j, f in hotkeyModifiers ; order in array important, shift must be first to ensure no "+" replacements
				hk := StrReplace(hk, f.mod, f.replacement . (f.mod != "<" && f.mod != ">" ? " + " : " "))
			hotkeys.Push({line:A_Index, hotkey:hk . SubStr(hkey, -1), type:hType, comment:comment})
		}
	}
	return hotkeys
}

getFullScript() {
	fileObj := FileOpen(A_ScriptFullPath, "r", "UTF-8")
	script := fileObj.Read()
	fileObj.Close()
	flagCom := false
	flagMult := false
	cleanScript := ""
	Loop Parse, script, "`n", "`r"
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
}