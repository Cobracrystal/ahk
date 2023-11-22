#SingleInstance Force
global startTime := A_TickCount, guis := Map()
reopen()
return


reopen(same := 0) {
	static index := 1
	xcoord := Mod(index, 10) == 1 ? A_ScreenWidth/2-55 : Random(-20, A_ScreenWidth - 120)
	ycoord := Mod(index, 10) == 1 ? A_ScreenHeight / 2 - 85 : Random(-20, A_ScreenHeight - 150)
	guis[index] := Gui("+AlwaysOnTop -MinimizeBox -MaximizeBox", "Spammy Window")
	guis[index].OnEvent("Close", (*) => reviewGuiClose.bind(index))
	guis[index].AddText("w70 h20 x30 y15", "Round " index)
	guis[index].AddButton("vButton w100 h60 x10 y60", "Close x " index).OnEvent("Click", reviewGuiClose.bind(index))
	guis[index].Show(Format("x{} y{}", xcoord, ycoord))
	index++
}

move(index) {
	xcoord := Random(10, A_ScreenWidth - 120)
	ycoord := Random(10, A_ScreenHeight - 150)
	guis[index].Hide()
	Sleep(50)
	guis[index].Show(Format("x{} y{}", xcoord, ycoord))
}

reviewGuiClose(index, *) {
	static fOb := reopen
	guis[index]["Button"].Enabled := false
	if (index <= 10) {
		guis[index].Destroy()
		SetTimer(reopen, -500)
	}
	if (index > 10 && index < 20) {
		guis[index].Destroy()
		reopen()
	}
	if (index >= 20 && index <= 30) {
		guis[index].Destroy()
		SetTimer(fOb, 0)
		Sleep(300)
		reopen()
		SetTimer(fOb := move.bind(index+1), 700)
	}
	if (index > 30) && (index <= 40) {
		SetTimer(fOb, 0)
		reopen()
		SetTimer(fOb := move.bind(index+1), 2000)
	}
	if (index == 41) {
		SetTimer(fOb, 0)
		Loop (11) {
			guis[A_Index + 30].Destroy()
		}
		SetTimer(finished.bind(index), -2000)
	}
}

finished(index) {
	SetTimer(reopen, 0)
	EndTime := A_TickCount
	TempTimeS := Floor((EndTime - StartTime) / 1000)
	TMinutes := Floor(TempTimeS / 60)
	TSeconds := Mod(TempTimeS, 60)
	done := Gui("+AlwaysOnTop -MinimizeBox -MaximizeBox", "Congratulations.")
	done.AddText("w300 h100 x20 y20", "Congratulations! You wasted " tMinutes " minutes and " tSeconds " seconds here!")
	done.AddButton("w100 h60 x10 y60", "I don't like you.").OnEvent("Click", badEnd.bind(index))
	done.AddButton(" w100 h60 x180 y60", "Ok").OnEvent("Click", (*) => ExitApp())
	done.Show("Center")
}

badEnd(index, ctrlObj, *) {
	ctrlObj.gui.Destroy()
	g := Gui("+AlwaysOnTop +ToolWindow -SysMenu")
	g.OnEvent("Close", (*) => 0)
	g.SetFont("s30")
	g.AddText("x150 y150 w500 h100 Center", "Well, fuck you too")
	g.Show("Center h400 w800")
	Sleep(1500)
	g.Destroy()
	Loop (500) {
		i := A_Index + index
		xcoord := Random(0, A_ScreenWidth - 20)
		ycoord := Random(0, A_ScreenHeight - 50)
		guis[i] := Gui("+AlwaysOnTop -SysMenu", "You have reached the Bad End.")
		guis[i].OnEvent("Close", reviewGuiClose.bind(i))
		guis[i].AddText("w70 x30 y15", "You Suck x " Integer(i**1.5))
		guis[i].AddButton("vButton w100 h60 x10 y60 Center", "Oops x " Integer(i**1.5)).OnEvent("Click", restartClose.bind(i))
		guis[i].Show(Format("x{} y{}", xcoord, ycoord))
		Sleep(10)
	}
	Sleep(1000)
	global final := Gui("-SysMenu +Owner +AlwaysOnTop", "You deserve this")
	g.SetFont("s30")
	final.AddText("x150 y150 w500 h100 Center", "That's what you get for clicking that button.")
	final.Show("h500 w500 Center")
	Sleep(500)
	MsgBox("I am a hidden message. I hope you're having fun.")
}

restartClose(index, *) {
	guis[index].Destroy()
	if !WinExist("You have reached the Bad End. ahk_exe Autohotkey64.exe") {
		final.Destroy()
		finished(index)
	}
}

^#K:: ExitApp()

^!+r:: Reload()