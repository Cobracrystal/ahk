#NoEnv ;// Compatibility for future via empty variable assignment
#KeyHistory 500
#Persistent
pic := "https://cdn.discordapp.com/emojis/783760070831112232.gif"
;// size of GUI
wgif := 128
hgif := 128
moveX := 1
moveY := 1

Gui, gekOverlay:New, +AlwaysOnTop +Lastfound  +ToolWindow -Caption
Gui, gekOverlay:Color, ffffff
WinSet, TransColor, ffffff
Gui, Add, ActiveX, w128 h128, % "mshtml:<img src='" pic "' />"
gekMagicTimer := Func("gekMagic")
SetTimer, % gekMagicTimer, 10
overlay := true
return

^Numpad8::
if (overlay := !overlay) 
	SetTimer, %gekMagicTimer%, 10
else {
	SetTimer, %gekMagicTimer%, Off
	Gui, gekOverlay:Hide
}
return


gekMagic() {
	static xc := 200, yc := 200, wgui := 128, hgui := 128, moveX := -2, moveY := -2
	xc += moveX
	yc += moveY
	if (xc > A_ScreenWidth - wgui - 22 || xc < -30)
		moveX := moveX * -1
	if (yc > A_ScreenHeight - hgui - 39 || yc < -40)
		moveY := moveY * -1
	Gui, gekOverlay:Show, x%xc% y%yc% NoActivate
}