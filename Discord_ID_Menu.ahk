#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#Persistent
SetTitleMatchMode, 1

Gui, IDGui:New, -SysMenu +AlwaysOnTop +Owner, ID-Gui ;be able to close the gui = remove -SysMenu
; This script couldve been so much shorter, but it looks cool now 

Userbuttons = 10 ; Insert the amount of Buttons you want to have. 
; Everything above 15 doesnt work.
Rows = 3
; Number of rows of the buttons. For a list, use 1.

UserID1 = 245189840470147072 ; Potet is number one. 
ButtonName1 = Potet ; What will be displayed on the button.
UserID2 = 330811222939271170
ButtonName2 = Zyntha
UserID3 = 172002275412279296
ButtonName3 = Tatsumaki
UserID4 = Yall suck
ButtonName4 = ????
UserID5 = You suck
ButtonName5 = ?????
; Just add more variables with this format in here, then specify the ID. 
; Leave the rest blank. If one of the IDs that are a button is left blank, the button will clear your clipboard. 

width := 15 + Rows * 135
Loop, %Userbuttons%
	{
		ButtonName := ButtonName%A_Index%
		xcoord := 15 + Mod(A_Index - 1, Rows) * 135
		ycoord := 15 + Floor((A_Index - 1) / Rows)  * 50
		Gui, IDGui:Add, Button, x%xcoord% y%ycoord% h40 w120 g%A_Index%IDLabel, %ButtonName%
	}
Gui, IDGui:Add, StatusBar,, Current Clipboard
SB_SetText(" Current Selection: ")
Gui, IDGui:Show, w%width% NoActivate, ID-Gui
return

1IDLabel:
Clipboard = %UserID1%
Goto CrtClipBoardUpdate

2IDLabel:
Clipboard = %UserID2%
Goto CrtClipBoardUpdate

3IDLabel:
Clipboard = %UserID3%
Goto CrtClipBoardUpdate

4IDLabel:
Clipboard = %UserID4%
Goto CrtClipBoardUpdate

5IDLabel:
Clipboard = %UserID5%
Goto CrtClipBoardUpdate

6IDLabel:
Clipboard = %UserID6%
Goto CrtClipBoardUpdate

7IDLabel:
Clipboard = %UserID7%
Goto CrtClipBoardUpdate

8IDLabel:
Clipboard = %UserID8%
Goto CrtClipBoardUpdate

9IDLabel:
Clipboard = %UserID9%
Goto CrtClipBoardUpdate

10IDLabel:
Clipboard = %UserID10%
Goto CrtClipBoardUpdate

11IDLabel:
Clipboard = %UserID11%
Goto CrtClipBoardUpdate

12IDLabel:
Clipboard = %UserID12%
Goto CrtClipBoardUpdate

13IDLabel:
Clipboard = %UserID13%
Goto CrtClipBoardUpdate

14IDLabel:
Clipboard = %UserID14%
Goto CrtClipBoardUpdate

15IDLabel:
Clipboard = %UserID15%
Goto CrtClipBoardUpdate

GuiEscape:
GuiClose:
Gui, IDGui:Hide

CrtClipboardUpdate:
SB_SetText(" Current Selection: " clipboard )
return

^ä::
if WinExist("ID-Gui")
	Gui, IDGui:Hide
else
	Gui, IDGui:Show 
return








