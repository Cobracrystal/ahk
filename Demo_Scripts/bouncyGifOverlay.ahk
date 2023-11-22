KeyHistory(500)
Persistent()
pic := "https://cdn.discordapp.com/emojis/783760070831112232.gif"
;// size of GUI
wgif := 128
hgif := 128
moveX := 1
moveY := 1

gekGui := Gui("+AlwaysOnTop +ToolWindow -Caption", "GekOverlay")
gekGui.BackColor := "FFFFFF"
WinSetTransColor("FFFFFF", gekGui.hwnd)
gekGui.AddActiveX("w128 h128", "mshtml:<img src='" pic "' />")
SetTimer(gekMagic, 10)
return

^Numpad8::{
	global gekGui
	static overlay := true
	if (overlay := !overlay)
		SetTimer(gekMagic, 10)
	else {
		SetTimer(gekMagic, 0)
		gekGui.Hide()
	}
}


gekMagic() {
	global gekGui
	static xc := 200, yc := 200, wgui := 128, hgui := 128, moveX := -2, moveY := -2
	xc += moveX
	yc += moveY
	if (xc > A_ScreenWidth - wgui - 22 || xc < -30)
		moveX := moveX * -1
	if (yc > A_ScreenHeight - hgui - 39 || yc < -40)
		moveY := moveY * -1
	gekGui.Show(Format("x{} y{} NoActivate", xc, yc))
}