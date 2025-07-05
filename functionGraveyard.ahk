#Include "%A_ScriptDir%\LibrariesV2\BasicUtilities.ahk"

drawMouseCircle(radius, centerX?, centerY?, max_degrees := 360) {
	MouseGetPos(IsSet(centerX) ? unset : &centerX, IsSet(centerY) ? unset : &centerY)
	MouseMove(centerX, centerY + radius)
	Sleep(50)
	Send("{LButton Down}")
	SendMode("Event")
	Loop(max_degrees) {
		x := Round(radius * Sin(2 * A_Index/max_degrees * 3.141592653))
		y := Ceil(radius * Cos(2 * A_Index/max_degrees * 3.141592653))
		MouseMove(centerX + x, centerY + y, 1)
	}
	Send("{LButton Up}")
}

objIterate(o,f) { ; this could be a oneliner
	return (
		t(o,f,fl,en,*) => (
			en(&i, &e) ? t(
				o,
				f,
				fl,
				en,
				fl ? o[i] := f(e) : o.%i% := f(e)
			) : o
		),
		t(
			o.Clone(),
			f,
			fl := (o is Array || o is Map),
			fl ? o.__Enum(2) : o.OwnProps().__Enum(2)
		)
	)
}