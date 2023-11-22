colorGradientArr(amount, colors*) {
	; variadic function to accept unlimited colors
	color_R := []
	color_G := []
	color_B := []
	gradient := []
	if (amount < colors.Count()-2)
		return 0
	else if (amount == colors.Count()-2)
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
	segments := colors.Count()-1
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
	gradient[amount+2] := format("0x{:06X}", colors[colors.Count()])
	; return array of amount+2 colors
	return gradient
}

rainbowArr(num, intensity := 0xFF) {
	if (num < 7)
		return 0
	if (intensity < 0 || intensity > 255)
		return 0
	intensity := format("{:#x}", intensity)
	r := intensity * 0x010000
	g := intensity * 0x000100
	b := intensity * 0x000001
	return colorGradientArr(num-2, r, r|g/2, r|g, g, g|b, g/2|b, b, b|r, r)
}

changeColorFormat(clr, reverse := true, alph := "") {
	/*	alph = -1 to remove alpha, reverse for RGB<->BGR
		clr in (0x)[hex*6/8] format, alph is either decimal or (0x)[hex*2]
		(RGB -> RGB)	 BGR -> RGB		 ABGR -> RGB	 ARGB -> RGB
		 RGB -> BGR		(BGR -> BGR)	 ABGR -> BGR	 ARGB -> BGR
		 RGB -> ABGR	 BGR -> ABGR	(ABGR -> ABGR)	 ARGB -> ABGR
		 RGB -> ARGB	 BGR -> ARGB	 ABGR -> ARGB	(ARGB -> ARGB)
	*/
	if (RegexMatch(clr, "^[[:xdigit:]]{6}([[:xdigit:]]{2})?$"))
		clr := "0x" . clr
	if (RegExMatch(clr, "P)^0x[[:xdigit:]]{6}(?:[[:xdigit:]]{2})?$", mL)) {
		if (mL == 10)
			al := format("{1:02X}", ((clr & 0xFF000000) >> 24))
		rb := ((clr & 0xFF0000) >> 16)
		gg := ((clr & 0xFF00) >> 8)
		br := (clr & 0xFF)
	}
	else 
		throw Exception("Color provided is not in correct Format")
	; if alph is given, its always prioritized.
	if (RegExMatch(alph, "^[[:xdigit:]]{2}$"))
		al := format("{1:02X}", "0x" . alph)
	else if (alph >= 0 && alph < 256)
		al := format("{1:02X}", alph)
	else if (alph == -1)
		al := ""
	else 
		throw Exception("Color provided is not in correct Format")
	if (reverse)
		return format("0x{4}{1:02X}{2:02X}{3:02X}", br, gg, rb, al)
	else
		return format("0x{4}{1:02X}{2:02X}{3:02X}", rb, gg, br, al)
}
; 0xFF00FFA2k
hexcodeColorPreview(hotkey) {
	text := fastCopy()
	if text is not xdigit
		return
	if (text == "")
		return
	tcm := A_CoordModeMouse
	CoordMode, Mouse
	MouseGetPos, x, y
	Gui, colorPreview:New, +AlwaysOnTop +Lastfound  +ToolWindow -Caption +hwndColorHwnd
	Gui, colorPreview:Color, %text%
	Gui, colorPreview:Show, % "x" . x-30 . " y" . y-30 . "w50 h50 NoActivate"
	Sleep, 1500
	Gui, colorPreview:Destroy
}