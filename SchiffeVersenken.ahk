#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#KeyHistory 500
#Persistent
SetTitleMatchMode, 3
SetWorkingDir %A_ScriptDir% 

myfieldvar := 1
EnemyPosition := 0
MyGuess := 0
EnemyGuess = 0
xcoord := A_ScreenWidth / 8 - 100
ycoord := A_ScreenHeight / 8
visibility = true

Random, EnemyPosition, 1, 16
GoSub, GenerateFields
return

F::
xcoord := A_ScreenWidth / 8 - 100
ycoord := A_ScreenHeight / 8
GoSub, GenerateFields
return

GenerateFields:
Loop, 16
{
	xcoord := xcoord+A_ScreenWidth/2
	Gui, MyField_%A_Index%:New, +AlwaysOnTop -SysMenu +Owner
			Gui , Myfield_%A_Index%:Add , Text , x42 y15, %A_Index%
			Gui , Myfield_%A_Index%:Add , Button , w75 h45 x15 y45 vMyshipposbutton gChooseShipPos, Choose Ship
			Gui , Myfield_%A_Index%:Show, x%xcoord% y%ycoord% , MyField
	xcoord := xcoord-A_ScreenWidth/2
	Gui, Enemyfield_%A_Index%:New, +AlwaysOnTop -Sysmenu +Owner
			Gui , Enemyfield_%A_Index%:Add , Text , x42 y15, %A_Index% 
			Gui , Enemyfield_%A_Index%:Add , Button , w75 h45 x15 y45 vGuessposbutton gGuessPos, Guess Pos
			Gui , Enemyfield_%A_Index%:Show, x%xcoord% y%ycoord% , EnemyField
	if( Mod(A_Index, 4) = 0) 
	{ 
		ycoord := ycoord + 140
		xcoord := xcoord - 390
		}
	else xcoord := xcoord + 130
}
return

Switchfieldvisibility:
Loop, 16	{
	if(visibility = False) {
			;Gui, MyField_%A_Index%:Show
			Gui, Enemyfield_%A_Index%:Show
			}
	else {
			;Gui, MyField_%A_Index%:Hide 
			Gui, Enemyfield_%A_Index%:Hide
		}
	}
visibility := !visibility
return



ChooseShipPos:
MyPosition := StrSplit(A_Gui, "_")
MyPosition := MyPosition[2]
Loop, 16
{
	GuiControl, MyField_%A_Index%:Disable, Myshipposbutton
	GuiControl, MyField_%A_Index%:Text, Myshipposbutton, Water
	if(A_Index = MyPosition) {
		GuiControl, MyField_%A_Index%:Text, Myshipposbutton, My Ship
		}
	Gui, MyField_%A_Index%:Submit, NoHide
	Gui, MyField_%A_Index%:Show, AutoSize
}
return

GuessPos:
return

+F7::
GoSub, Switchfieldvisibility
return
