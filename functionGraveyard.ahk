
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