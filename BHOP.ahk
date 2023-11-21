#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.



F11:: Hotkey, *~$Space, Toggle

End::
ExitApp

*~$Space::
Sleep 1
Loop
{
GetKeyState, SpaceState, Space, P
If SpaceState = U
break 
Sleep 1
Send, {Blind}{Space}
}
Return