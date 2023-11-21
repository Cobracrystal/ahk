#Persistent
#NoEnv


^+j::
arr := ["a", "b", "c", "d", "e", "f", "g"]
makeGui(arr)
return
return

^+n::
msgbox % varsthing()
return

^+m::
WinGet, all, ControlList, ahk_id %guihwnd%
Loop, Parse, all, `n
{
	GuiControlGet, s,%GuiHwnd%:, %A_Loopfield%
	GuiControlGet, ss, %GuiHwnd%:Name, %A_Loopfield%
	asd .= A_Loopfield . ", " . s . ", " . ss . "`n"
}
msgbox % asd
asd := ""
return

makeGui(arr) {
	global
	Gui, New, +Border +hwndGuiHwnd
	for i, e in arr
	{
		Gui, Add, Text, % (i==1?"Section":"ys"), % e
		Gui, Add, Edit, % "vNewRow" . i . " r1 w" . 100, % i*i
	}
	Gui, Show
}

varsthing() {
	global
	local strp := []
	Gui, %GuiHwnd%:Submit, Nohide
	for i, e in arr
	{
		strp[i] := NewRow%i%
	}
	for i, e in strp
		str .= strp[i] . " "
	return str
}

^+r::
reload
return