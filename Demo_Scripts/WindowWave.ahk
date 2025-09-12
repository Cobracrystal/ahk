#SingleInstance Force
#Requires AutoHotkey v2
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
	guis := []
	Loop(coords.Length) {
		coords[A_Index].gui := Gui("+AlwaysOnTop +ToolWindow -Caption")
		coords[A_Index].gui.BackColor := 0x0080FF
		coords[A_Index].gui.Show(Format("x{1} y{2} w{3} h{3} NoActivate",coords[A_Index].x, coords[A_Index].y, size))
	}
}

calculateCurveValues(height, periods := 2, width:=70) { ; 10, 1, 2
	static PI := 3.14159
	lPeriod := (A_ScreenWidth+width)/periods
	hPeriod := height*lPeriod/(2*pi)
	arr := []
	Loop(A_ScreenWidth+width+1)
		arr.push({x:A_Index-width-1, y:A_ScreenHeight//2+hPeriod*sin((A_Index-width-1)/lPeriod*2*pi)})
	return arr
}

+!^r::Reload()

+^p::Pause()
