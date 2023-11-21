colorGradientArr(amount, colors*) {
	; variadic function to accept unlimited colors
	color_R := []
	color_G := []
	color_B := []
	gradient := []
	if (amount < colors.length()-2)
		return 0
	else if (amount == colors.length()-2)
		return colors
	for index, color in colors
	{	; just bitshift to get single RGB vals
		color_R[A_index] := ((color & 0xFF0000) >> 16)
		color_G[A_index] := ((color & 0xFF00) >> 8)
		color_B[A_index] := (color & 0xFF)
	}
	; first color given, format with 6 padded 0s in case of black
	gradient[1] := format("0x{:06X}", colors[1])
	; amount of color gradients to perform
	segments := colors.length()-1
	Loop %amount% {
		; current gradient segment we are in
		segment := floor((A_Index/(amount+1))*segments)+1
		; percentage progress in the current gradient segment as decimal
		segProgress := ((A_Index/(amount+1)*segments)-segment+1)
		; RGB obtained via percentage * (end of gradient - start of gradient), then adding current RGB value again.
		r := round((segProgress * (color_R[segment+1]-color_R[segment]))+color_R[segment])
		g := round((segProgress * (color_G[segment+1]-color_G[segment]))+color_G[segment])
		b := round((segProgress * (color_B[segment+1]-color_B[segment]))+color_B[segment])
		hex:=format("0x{1:02X}{2:02X}{3:02X}", r, g, b)
		gradient[A_Index+1] := hex
	}
	; last color given, same as first
	gradient[amount+2] := format("0x{:06X}", colors[colors.length()])
	; return array of amount+2 colors
	return gradient
}

changeColorFormat(clr, reverse := true, alph := "") {
	/*	alph = -1 to remove alpha, reverse for RGB<->BGR
		clr HAS to be in 0x[hex*6] format, alph is either decimal or 0x[hex*2]
		RGB -> RGB		BGR -> RGB		ABGR -> RGB		ARGB -> RGB
		RGB -> BGR		BGR -> BGR		ABGR -> BGR		ARGB -> BGR
		RGB -> ARGB		BGR -> ARGB		ABGR -> ARGB	ARGB -> ARGB
		RGB -> ABGR		BGR -> ABGR		ABGR -> ABGR	ARGB -> ABGR
	*/
	if (RegExMatch(clr, "^0x[[:xdigit:]]{8}$")) {
		al := format("{1:02X}", ((clr & 0xFF000000) >> 24))
		rb := ((clr & 0xFF0000) >> 16)
		gg := ((clr & 0xFF00) >> 8)
		br := (clr & 0xFF)
	}
	else if (RegExMatch(clr, "^(0x)?[[:xdigit:]]{6}$")) {
		rb := ((clr & 0xFF0000) >> 16)
		gg := ((clr & 0xFF00) >> 8)
		br := (clr & 0xFF)
	}
	else 
		throw Exception("Color provided is not in correct Format")
	; if alph is given, its always prioritized.
	if (alph == -1)
		al := ""
	else if (RegExMatch(alph, "^(0x)?[[:xdigit:]]{2}$"))
		al := format("{1:02X}", alph)
	if (reverse)
		return format("0x{4}{1:02X}{2:02X}{3:02X}", br, gg, rb, al)
	else
		return format("0x{4}{1:02X}{2:02X}{3:02X}", rb, gg, br, al)
}

hexcodeColorPreview(hotkey) {
	text := fastCopy()
	if text is not xdigit
		return
	if (InStr(text, "0x"))
		text := StrReplace(text, "0x")
	if (Strlen(text) != 6)
		return
	tcm := A_CoordModeMouse
	CoordMode, Mouse
	MouseGetPos, x, y
	Gui, colorPreview:New, +AlwaysOnTop +Lastfound  +ToolWindow -Caption +hwndColorHwnd
	Gui, colorPreview:Color, %text%
	Gui, colorPreview:Show, % "x" . x-30 . " y" . y-30 . "w50 h50 NoActivate"
	CoordMode, Mouse, %tcm%
	Sleep, 1500
	Gui, colorPreview:Destroy
}