#NoEnv ;// Compatibility for future via empty variable assignment
#KeyHistory 500
#Persistent
pic := "https://cdn.discordapp.com/emojis/783760070831112232.gif"
;// starting coordinates for gecko
xc := 50
yc := 50
;// size of GUI
wgif := 128
hgif := 128
moveX := 1
moveY := 1

Gui, gekOverlay:New, +AlwaysOnTop +Lastfound  +ToolWindow -Caption
Gui, gekOverlay:Color, ffffff
WinSet, TransColor, ffffff
Gui, Add, ActiveX, w128 h128, % "mshtml:<img src='" pic "' />"
gekMagicTimer := Func("gekMagic").Bind(wgif,hgif,moveX,moveY)
return

^Numpad8::
if (overlay := !overlay) 
	SetTimer, %gekMagicTimer%, 10
else {
	SetTimer, %gekMagicTimer%, Off
	Gui, gekOverlay:Hide
}
return


^+R::
Reload
return


gekMagic(wgif, hgif, moveX, moveY) {
	static xc := 50
	static yc := 50
	xc := xc + moveX
	yc := yc + moveY
	if (xc > A_ScreenWidth  - wgui - 22 || xc < 22)
		moveX := moveX * -1
	if (yc > A_ScreenHeight - hgui - 39 || yc < 39)
		moveY := moveY * -1
	Gui, gekOverlay:Show, x%xc% y%yc% NoActivate
}