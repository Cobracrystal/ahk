Persistent()

; SETTINGS

global color_intensity := 0xAE ; intensity of cycling colors
global transparency := 0xD0 ; general transparency of the taskbar
global rotation_length := 60 ; SECONDS, ON AVERAGE
;------------------------------------------------------------------------
; STARTUP
SetTimer(updateTaskbarTimer, 25)
;-----------------------------------------------
; 
A_TrayMenu.Delete()
A_TrayMenu.Add("Reload", (*) => Reload())
A_TrayMenu.Add("Exit", (*) => ExitApp())
return

updateTaskbarTimer() {
	static init := false, trayHandles, gradient, i := 0
	try {
		if !(init) {
			if (DllCall("GetVersion") & 0xff < 10)
				throw Error("Minimum support client: Windows 10", -1)
			r := color_intensity * 0x010000
			g := color_intensity * 0x000100
			b := color_intensity * 0x000001
			gradient := colorGradientArr(round(rotation_length*63), r, r|g//2, r|g, g, g|b, g//2|b, b, b//2|r//3, b|r, r)
			trayHandles := WinGetList("ahk_class Shell_SecondaryTrayWnd")
			trayHandles.InsertAt(1, WinGetID("ahk_class Shell_TrayWnd"))
			init := 1
		}
		for _, handle in trayHandles {
			TaskBar_SetAttribute(handle, rgbToABGR(gradient[i+1], transparency))
			i := mod(i+1,round(rotation_length*63)+2)
		}
	} catch Error as e {
		MsgBox("Error: " e.Message "`nAufgetreten in: " e.What "`nKlingt nach einem groben Fehler in RGB-Taskbar-5000™️. Tja.`nSchließ mich und öffne mich nochmal.`nOder mach halt nix. Wie auch immer.`nUnd falls du dies zum zweiten Mal liest, solltest du einen Spezialisten um Rat fragen.")
		SetTimer(updateTaskbarTimer, 0)
		init := 0
	}
}

TaskBar_SetAttribute(handle, gradient_ABGR := "0x01000000") {
	static pad := A_PtrSize = 8 ? 4 : 0, WCA_ACCENT_POLICY := 19
	ACCENT_POLICY := Buffer(16, 0)
	NumPut("int", 2, ACCENT_POLICY, 0)
	NumPut("int", gradient_ABGR, ACCENT_POLICY, 8)
	WINCOMPATTRDATA := Buffer(4 + pad + A_PtrSize + 4 + pad, 0)
	NumPut("int", WCA_ACCENT_POLICY, WINCOMPATTRDATA, 0)
	NumPut("ptr", ACCENT_POLICY.Ptr, WINCOMPATTRDATA, 4 + pad)
	NumPut("uint", ACCENT_POLICY.Size, WINCOMPATTRDATA, 4 + pad + A_PtrSize)
	if !(DllCall("user32\SetWindowCompositionAttribute", "ptr", handle, "ptr", WINCOMPATTRDATA)) {
		throw Error("Failed to set transparency / blur", -1)
	}
	return true
}

colorGradientArr(amount, colors*) {
	rgb := [], gradient := []
	for _, color in colors
		rgb.push({r:(color & 0xFF0000) >> 16, g:(color & 0xFF00) >> 8, b:color & 0xFF})
	gradient.push(format("0x{:06X}", colors[1]))
	segs := colors.length-1
	Loop(amount) {
		s := floor((A_Index/(amount+1))*segs)+1
		segProgress := ((A_Index/(amount+1)*segs)-s+1)
		r := round((segProgress * (rgb[s+1].r-rgb[s].r))+rgb[s].r)
		g := round((segProgress * (rgb[s+1].g-rgb[s].g))+rgb[s].g)
		b := round((segProgress * (rgb[s+1].b-rgb[s].b))+rgb[s].b)
		gradient.push(format("0x{1:02X}{2:02X}{3:02X}", r, g, b))
	}
	gradient.push(format("0x{:06X}", colors[colors.length]))
	return gradient
}

rgbToABGR(color, alph) {
	return Format("0x{1:02X}{2:02X}{3:02X}{4:02X}", alph, (color & 0xFF), ((color & 0xFF00) >> 8), ((color & 0xFF0000) >> 16))
}
