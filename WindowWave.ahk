#NoEnv 
SendMode Input 
SetWorkingDir %A_ScriptDir%\script_files 

speed = 0.8
waveheight = 60
wavecount = 2
WaveNumbers = 20
wavepos = 50
Screens = 1
SurferOn = 0



WaveNumbers = % WaveNumbers * (Screens)
GuiVar = 1
pi = 3.141592653
xcoord = % 2*A_ScreenWidth
ycoord = % A_ScreenHeight/2 - 85
temp = % xcoord
Sysget, Mon2, Monitor, 2
fullwidth = % A_ScreenWidth - (Screens - 1) * Mon2Left
WaveIterations = % (fullwidth*1.1)/(WaveNumbers * speed) 
WaveDistance = % A_ScreenWidth / 10 
Loop, %WaveNumbers% {
	Gui, wave%GuiVar%:New, +Lastfound +AlwaysOnTop +ToolWindow -Caption
	Gui, wave%GuiVar%:Color, ffffff
	WinSet, TransColor, ffffff
	Gui, wave%GuiVar%:Add, Picture, w250 h-1 +BackgroundTrans, WindowWave\wave.png   
	Gui, wave%GuiVar%:Show, x%xcoord% y%ycoord% NoActivate
	GuiVar = % GuiVar + 1 
}
Loop %SurferOn% {
Gui, surfer:New, +Lastfound +AlwaysOnTop +ToolWindow -Caption
Gui, surfer:Color, ffffff
WinSet, TransColor, ffffff
Gui, surfer:Add, Picture, w250 h-1 +BackgroundTrans, WindowWave\surfer.png   
Gui, surfer:Show, x%xcoord% y%ycoord% NoActivate
}
GuiVar = 1
Loop {
	Loop %WaveIterations% {
		Loop, %WaveNumbers% {
			Gui , wave%GuiVar%:Show, x%temp% y%ycoord% NoActivate
			xcoord = % xcoord-speed
			ycoord = % A_ScreenHeight/2 +400 -wavepos + waveheight*cos(wavecount*2*pi*xcoord/(1.1*fullwidth))
			temp = % xcoord - WaveDistance*GuiVar
			GuiVar = % GuiVar + 1
		}
		GuiVar = 1
		if (SurferOn) {
			temp2 = % xcoord -A_ScreenWidth*(Screens) - 130
			Gui, surfer:Show, x%temp2% y%ycoord% NoActivate
		}
		
	}
xcoord = % (1+ Screens)*A_ScreenWidth
}



+!^r::
Reload
return

+^p::
Pause
return