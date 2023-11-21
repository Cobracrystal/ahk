#Include %A_ScriptDir%\Libraries\WinHook.ahk
WinHook.Shell.Add("Created",,, "NOTEPAD.EXE",1) ; Notepad Window Created
WinHook.Shell.Add("Destroyed",,, "NOTEPAD.EXE",2) ; Notepad Window Destroyed

Esc::ExitApp

Destroyed(Win_Hwnd, Win_Title, Win_Class, Win_Exe, Win_Event)
{
	MsgBox Destroyed
}

Created(Win_Hwnd, Win_Title, Win_Class, Win_Exe, Win_Event)
{
	MsgBox Created
	WinGet, PID, PID, ahk_id %Win_Hwnd%
	EH1 := WinHook.Event.Add(0x0016, 0x0016, "Minimized", PID) 
	EH2 := WinHook.Event.Add(0x0017, 0x0017, "Restored", PID) rmiter
}

Minimized(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime)
{
	MsgBox Minimized
}

Restored(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime)
{
	MsgBox Restored
}

MoveStart(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime)
{
	Tooltip, started moving
}

MoveEnd(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime)
{
	MsgBox stopped moving
}