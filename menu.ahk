#SingleInstance force

data_file=%a_workingdir%\Data.ini
data_txt=%a_workingdir%\Data.txt

Gui +OwnDialogs
Gui +Resize
Gui, Font, , Century Gothic
Gui, Add, Button, x12 y150 w110 h30 gAdd, Add
Gui, Add, Button, x132 y150 w110 h30 gRefresh, Refresh
Gui, Add, GroupBox, x2 y0 w250 h190 , Add Admin
Gui, Add, Text, x12 y20 w60 h20 , Username
Gui, Add, Text, x12 y40 w60 h20 , Value
Gui, Add, Text, x12 y60 w60 h20 , Date
Gui, Add, Text, x12 y80 w60 h20 , Comment
Gui, Add, Edit, x72 y20 w170 h20 vUsername,
Gui, Add, Edit, x72 y40 w170 h20 right readonly
Gui, Add, UpDown, x222 y40 w20 h20 Range1-12 vValue,
Gui, Add, DateTime, x72 y60 w170 h20 vDatein
Gui, Add, Edit, x72 y80 w170 h60 vComment,
Gui, Add, GroupBox, x2 y190 w510 h280 vView, View Admin
Gui, Add, MonthCal, x262 y10 w240 h180  readonly,
Gui, Font, , Courier New
Gui, Add, ListView, x12 y210 w490 Center vList gList, Username|Value|Date In|Date Out|Comment
LV_ModifyCol(1,115)
LV_ModifyCol(2,50)
LV_ModifyCol(2,"Integer")
LV_ModifyCol(3,85)
LV_ModifyCol(4,85)
LV_ModifyCol(5,150)

Gui, Show, Center h480 w260,
GoSub, load

Menu, MyContextMenu, Add, Change Username,load
Menu, MyContextMenu, Add, Change Value, load
Menu, MyContextMenu, Add, Change Comment,load
Menu, MyContextMenu, Add  ; Add a separator line below the submenu.
Menu, MyContextMenu, Add, Add Expired/Deleted,load
Menu, MyContextMenu, Default, Add Expired/Deleted  ; Make "Open" a bold font to indicate that double-click does the same thing.

return

Refresh:
Reload

load:
iniread, Total, %data_file%, Others, Total

index := 0
Loop
{
index++
iniread, Username%A_Index%, %data_file%, Username, Admin%A_index%
iniread, Value%A_Index%, %data_file%, Value, Admin%A_index%
iniread, Dateold%A_Index%, %data_file%, Date In, Admin%A_index%
iniread, Datenew%A_Index%, %data_file%, Date Out, Admin%A_index%
iniread, Comment%A_Index%, %data_file%, Comment, Admin%A_index%

If (Username%A_index% = "Error" && Value%A_index% = "Error" && Dateold%A_index% = "Error" && Datenew%A_index% = "Error" && Comment%A_index% = "Error")
break

}
Gui, 1: Default
index-=1
Loop, %index%
{
LV_Delete(index)
LV_Add(%A_index% Auto, Username%A_Index%, Value%A_Index%, Dateold%A_Index%, Datenew%A_Index%, Comment%A_Index%)
LV_ModifyCol(%A_index%,AutoHdr)
}
return

add:
gui,submit,nohide
iniread, Total, %data_file%, Others, Total
total+=1

Day := SubStr(DateIn, 7, 2) ; get the day
Month := SubStr(DateIn, 5, 2) ; get the month
Year := SubStr(DateIn, 1, 4) ; get the year
Month += Value ; add the value
While (Month > 12) { ; as long as month > 12
   Month -= 12 ; subtract 12 from month
   Year += 1 ; add one vear
}
MMYYYY := SubStr("0" . Month, -1) . "/" . Year ; create the YYYYMM part of the new datestring
If (Day > 28) { ; check for invalid days in certain months
   LD := LDOM(MMYYYY) ; get the last day of the new month
   If (Day > LD) ; day is invalid in this month
      Day := LD ; maybe you want to do some other stuff here
}
DateOld := SubStr("0" . Day, -1) . "/" . SubStr(DateIn, 5, 2) . "/" . SubStr(DateIn, 1, 4)
DateNew := SubStr("0" . Day, -1) . "/" . MMYYYY ; complete the new datestring

iniwrite, %Username%, %data_file%, Username, Admin%total%
iniwrite, %Value%, %data_file%, Value, Admin%total%
iniwrite, %DateOld%, %data_file%, Date In, Admin%total%
iniwrite, %DateNew%, %data_file%, Date Out, Admin%total%
iniwrite, %Comment%, %data_file%, Comment, Admin%total%
iniwrite, %total%, %data_file%, Others, Total

GoSub, Load

FileAppend,
(
%total%.    %Username%	  %Value%	 %DateOld%   %DateNew%   %Comment%

),%data_txt%
;Run, E:\Programs\W3XP\MirageBotPortable.exe
;GroupAdd, MIRAGE , W3XP | JHEB-@PvPGN (bnet.nusa.in) -- MirageBot X (Portable)
;Sleep, 10000
;WinWait, ahk_group MIRAGE
;IfWinNotActive, ahk_group MIRAGE, , WinActivate, ahk_group MIRAGE,
;WinWaitActive, ahk_group MIRAGE,

;Send /W NSR-ONET !AddAdmin %Username%
;Send /W NSR-ONET !AddFriend %Username%
GuiControl,, Username,
GuiControl,, Value, 1
GuiControl,, DateIn,
GuiControl,, Comment,
return

GuiSize:  ; Expand or shrink the ListView in response to the user's resizing of the window.
if A_EventInfo = 1  ; The window has been minimized.  No action needed.
    return
; Otherwise, the window has been resized or maximized. Resize the ListView to match.
GuiControl, Move, List, % "W" . (A_GuiWidth - 25) . " H" . (A_GuiHeight - 225)
GuiControl, Move, View, % "W" . (A_GuiWidth - 5) . " H" . (A_GuiHeight - 195)
return

List:
if A_GuiEvent = DoubleClick  ; There are many other possible values the script can check.
{
    LV_GetText(FileName, A_EventInfo, 1) ; Get the text of the first field.
    LV_GetText(FileDir, A_EventInfo, 2)  ; Get the text of the second field.
    Run %FileDir%\%FileName%,, UseErrorLevel
    if ErrorLevel
	    MsgBox Could not open "%FileDir%\%FileName%".
}
return

GuiContextMenu:  ; Launched in response to a right-click or press of the Apps key.
if A_GuiControl <> MyList  ; Display the menu only for clicks inside the ListView.
    return
; Show the menu at the provided coordinates, A_GuiX and A_GuiY.  These should be used
; because they provide correct coordinates even if the user pressed the Apps key:
Menu, MyContextMenu, Show
return

guiclose:
ExitApp



LDOM(DateStr) { ; get the last day of the month - by Laszlo / SKAN
   DateStr := SubStr(DateStr, 1, 6) ; get the YYYYMM part
   DateStr += 31, Days ; jump into the next month
   DateStr := SubStr(DateStr, 1, 6) ; get the YYYYMM part
   DateStr += -1, Days ; jump to the last day of the previous month
   Return SubStr(DateStr, 7, 2) ; return the DD part
}