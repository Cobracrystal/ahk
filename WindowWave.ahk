#NoEnv 
#SingleInstance Force
SendMode Input
num := 200
height := 1
period := 2
size := 5
global coords := calculateCurveValues(height, period, size) 
launchWave(size, 100)
return

launchwave(size, sleepTime) {
	global coords
	ind := []
	Loop % coords.Count()
	{
		Gui, wave%A_Index%:New, +AlwaysOnTop +ToolWindow -Caption +hwndtHwnd
		Gui, wave%A_Index%:Color, 0080ff
		coords[A_Index].hwnd := tHwnd
		Gui, % coords[A_Index].hwnd ":Show", % Format("x{1}y{2} w{3} h{3} NoActivate",coords[A_Index].x, coords[A_Index].y, size)
	}
}

calculateCurveValues(height, periods := 2, width:=70) { ; 10, 1, 2
	static PI := 3.14159
	lPeriod := (A_ScreenWidth+width)/periods
	hPeriod := height*lPeriod/(2*pi)
	arr := []
	Loop % A_ScreenWidth+width+1
	{
		i := A_Index-width-1
		arr.push({"x":i, "y":A_ScreenHeight//2+hPeriod*sin(i/lPeriod*2*pi)})
	}
	return arr
}

+!^r::
Reload
return

+^p::
Pause
return