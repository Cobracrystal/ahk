#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir% 

YouSuckThisMuch = 1
GuiVar = 1
StartTime := A_TickCount
Start:
    SetTimer, Reopen, 150
return


Reopen:
if !WinExist("You Suck") Or (YouSuckThisMuch = 20) Or (GuiVar > 1)
	{
		Random, xcoord, 10, % A_ScreenWidth - 120
		Random, ycoord, 10, % A_ScreenHeight - 150
		if (YouSuckThisMuch = 1) or (YouSuckThisMuch = 21)
			{
				xcoord = % A_ScreenWidth/2 - 55
				ycoord = % A_ScreenHeight/2 - 85
			}
		Gui, YouSuck%GuiVar%:New, +AlwaysOnTop -MinimizeBox -MaximizeBox
		Gui , YouSuck%GuiVar%:Add , Text , w70 h20 x30 y15, You Suck x %YouSuckThisMuch%
		Gui , YouSuck%GuiVar%:Add , Button , w100 h60 x10 y60 gReviewGuiClose, Oh fuck x %YouSuckThisMuch%
		Gui , YouSuck%GuiVar%:Show, x%xcoord% y%ycoord% , You Suck
		GuiInVar := GuiVar
	}
return

ReviewGuiClose:
	GuiControl, YouSuck%GuiVar%:Disable, Button1
	YouSuckThisMuch := YouSuckThisMuch + 1
	if (YouSuckThisMuch < 11)
		{
			SetTimer, Reopen, Off
		}
	if (YouSuckThisMuch = 20)
		{
			SetTimer, Reopen, 700
			return
		}
	if (YouSuckThisMuch = 21)
		{
			SetTimer, Reopen, Off
			Gosub, Reopen
		}
	if (YouSuckThisMuch > 30) and (YouSuckThisMuch < 41)
		{
			if (GuiVar = GuiInVar)
				{
					GuiVar := GuiVar + 1
					SetTimer, Reopen, 800
					return
				}
				else
				{
					return
				}
		}
	if (YouSuckThisMuch = 41)
		{
			Loop, 11
				{
					CleaningUp := A_Index +29
					Gui, YouSuck%A_Index%:Destroy
				}
			SetTimer, Finished, -5000
			Goto Start
		}
	Gui , YouSuck%GuiVar%:Destroy
    Sleep, 500
	Goto Start

GuiEscape:
GuiClose:
Goto ReviewGuiClose

Finished:
SetTimer, Reopen, Off
Gui , YouSuck%GuiVar%:Destroy
EndTime := A_TickCount
TempTimeS := Floor((EndTime - StartTime)/1000)
TMinutes := Floor(TempTimeS/60)
TSeconds := Mod(TempTimeS, 60)
Gui, Done:New, +AlwaysOnTop -MinimizeBox -MaximizeBox
Gui , Done:Add , Text , w300 h100 x20 y20, Congratulations! You wasted %TMinutes% minutes and %TSeconds% seconds here!
Gui , Done:Add , Button , w100 h60 x10 y60 gYouFuckedUp, Fuck You
Gui, Done:Add, Button, w100 h60 x180 y60 gShutTheFuckUp, Ok
Gui , Done:Show, xCenter yCenter , Congratulations!
return

ShutTheFuckUp:
if !WinExist("YOU SUCK")
	{
		ExitApp
	}
return

YouFuckedUp:
Gui, Done:Destroy
Gui, FUCKYOU:New, +AlwaysOnTop -MinimizeBox -MaximizeBox
Gui, FUCKYOU:Font, s30
Gui, FUCKYOU:Add, Text, x150 y150 w500 h100 +Center , WELL FUCK YOU TOO
Gui, FUCKYOU:Show, xCenter yCenter h400 w800, New GUI Window
Sleep, 1500 
Gui, FUCKYOU:Destroy
Loop, 500
	{
		GuiVar := A_Index + 41
		YouSuckThisMuch := Floor(YouSuckThisMuch + YouSuckThisMuch/20)
		Random, xcoord, 0, % A_ScreenWidth - 20
		Random, ycoord, 0, % A_ScreenHeight - 50
		Gui, YouSuck%GuiVar%:New, +AlwaysOnTop -SysMenu 
		Gui , YouSuck%GuiVar%:Add , Text , w70 x30 y15 +Center, YOU SUCK x %YouSuckThisMuch%
		Gui , YouSuck%GuiVar%:Add , Button , w100 h60 x10 y60 +Center gFuckYouClose, OH FUCK x %YouSuckThisMuch%
		Gui , YouSuck%GuiVar%:Show, x%xcoord% y%ycoord% , YOU SUCK
		Sleep, 10
	}
Sleep, 1000
Gui, HAH:New, -SysMenu +AlwaysOnTop +Owner
Gui, HAH:Add, Text, +Center, Thats what you get for insulting me.
Gui, HAH:Show, h500 w500 xCenter yCenter, You deserve this.
Sleep, 500
MsgBox, I am a hidden message. I hope you're having fun.
return 

FuckYouClose:
Gui, YouSuck%GuiVar%:Destroy
GuiVar := GuiVar - 1
if !WinExist("YOU SUCK")
	{
		Gui, HAH:Destroy
		Goto Finished
	}
return

^#K::
ExitApp


^!+r::
Reload
return


