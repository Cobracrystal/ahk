#Persistent
#NoEnv

; SETTINGS

global color_intensity := 0xAE ; intensity of cycling colors
global transparency := 0xD0 ; general transparency of the taskbar
global rotation_length := 60 ; SECONDS, ON AVERAGE
;------------------------------------------------------------------------
; STARTUP
SetTimer, updateTaskbarTimer, 25
;-----------------------------------------------
; 
Menu, Tray, NoStandard
Menu, Tray, Add, Reload, reloadScript
Menu, Tray, Add, Exit, exitScript
return

updateTaskbarTimer() {
	static init, mCount, gradient, i := 0
	try {
	if !(init) {
		SysGet, mCount, MonitorCount
		r := color_intensity * 0x010000
		g := color_intensity * 0x000100
		b := color_intensity * 0x000001
		gradient := colorGradientArr(round(rotation_length*63), r, r|g/2, r|g, g, g|b, g/2|b, g/3|b, b, b/2|r/3, b|r, r)	
		init := 1
	}
		Loop %mCount% {
			tColor := rgbToABGR(gradient[i+1], transparency)
			i := mod(i+1,round(rotation_length*63)+2)
			TaskBar_SetAttr(A_Index, tColor)
		}
	} catch e {
		MsgBox % "Error: " e.Message "`nAufgetreten in: " e.What "`nKlingt nach einem groben Fehler in RGB-Taskbar-5000™️. Tja.`nSchließ mich und öffne mich nochmal.`nOder mach halt nix. Wie auch immer."
		SetTimer, updateTaskbarTimer, Off
	}
}

TaskBar_SetAttr(monitor := -1, gradient_color := "0x01000000") { ; 
	static init, monitorPrimary, hTrayWnd, hTrayWnd2, ver := DllCall("GetVersion") & 0xff < 10
	static pad := A_PtrSize = 8 ? 4 : 0, WCA_ACCENT_POLICY := 19
	if !(init) {
		if (ver)
			throw Exception("Minimum support client: Windows 10", -1)
		if !((hTrayWnd := DllCall("user32\FindWindow", "str", "Shell_TrayWnd", "ptr", 0, "ptr")) && hTrayWnd2 := DllCall("user32\FindWindow", "str", "Shell_SecondaryTrayWnd", "ptr", 0, "ptr"))
			throw Exception("Failed to get the handle", -1)
		SysGet, monitorPrimary, MonitorPrimary
		init := 1
	}
	if (monitor == -1)
		throw Exception("Attempted to set transparency on monitor that doesn't exist.",-1)
	accent_size := VarSetCapacity(ACCENT_POLICY, 16, 0)
	NumPut(2, ACCENT_POLICY, 0, "int")
	NumPut(gradient_color, ACCENT_POLICY, 8, "int")
	VarSetCapacity(WINCOMPATTRDATA, 4 + pad + A_PtrSize + 4 + pad, 0)
	&& NumPut(WCA_ACCENT_POLICY, WINCOMPATTRDATA, 0, "int")
	&& NumPut(&ACCENT_POLICY, WINCOMPATTRDATA, 4 + pad, "ptr")
	&& NumPut(accent_size, WINCOMPATTRDATA, 4 + pad + A_PtrSize, "uint")
	if (monitor = MonitorPrimary) {
		if !(DllCall("user32\SetWindowCompositionAttribute", "ptr", hTrayWnd, "ptr", &WINCOMPATTRDATA)) {
			init := 0
			throw Exception("Failed to set transparency / blur", -1)
		}
	}
	else if !(DllCall("user32\SetWindowCompositionAttribute", "ptr", hTrayWnd2, "ptr", &WINCOMPATTRDATA)){
		init := 0
		throw Exception("Failed to set transparency / blur", -1)
	}
	return true
}

colorGradientArr(amount, colors*) {
	color_R := []
	color_G := []
	color_B := []
	gradient := []
	if (amount < colors.length()-2)
		throw Exception("Amount of colors in gradient range is too short")
	else if (amount == colors.length()-2)
		return colors
	for index, color in colors
	{
		
		color_R[A_index] := ((color & 0xFF0000) >> 16)
		color_G[A_index] := ((color & 0xFF00) >> 8)
		color_B[A_index] := (color & 0xFF)
	}
	gradient[1] := format("0x{:06X}", colors[1])
	segments := colors.length()-1
	Loop %amount% {
		segment := floor((A_Index/(amount+1))*segments)+1
		segProgress := ((A_Index/(amount+1)*segments)-segment+1)
		r := round((segProgress * (color_R[segment+1]-color_R[segment]))+color_R[segment])
		g := round((segProgress * (color_G[segment+1]-color_G[segment]))+color_G[segment])
		b := round((segProgress * (color_B[segment+1]-color_B[segment]))+color_B[segment])
		hex:=format("0x{1:02X}{2:02X}{3:02X}", r, g, b)
		gradient[A_Index+1] := hex
	}
	gradient[amount+2] := format("0x{:06X}", colors[colors.length()])
	return gradient
}

rgbToABGR(color, alph) {
	if (color == "")
		throw Exception("Empty Color.")
	if (alph == "")
		alph := 0xFF
	r := ((color & 0xFF0000) >> 16)
	g := ((color & 0xFF00) >> 8)
	b := (color & 0xFF)
	return format("0x{1:02X}{2:02X}{3:02X}{4:02X}", alph, b, g, r)
}

reloadScript() {
	Reload
}

exitScript() {
	ExitApp
}
