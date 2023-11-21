#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

lock := False

while true
{
	if (WinActive("Brawlhalla") and !lock)
	{
		WinGetPos, X, Y, Width, Height, Brawlhalla
		MouseGetPos, MouseX, MouseY
		
		ClipCursor(True, X, Y, Width, Height)
		
		lock := True
	} else if (lock) {
		ClipCursor(False)
		lock := False
	}
	
	Sleep, 1000
}

ClipCursor( Confine=True, x1=0 , y1=0, x2=1, y2=1 ) 
{
	VarSetCapacity(R,16,0),  NumPut(x1,&R+0),NumPut(y1,&R+4),NumPut(x2,&R+8),NumPut(y2,&R+12)
	Return Confine ? DllCall( "ClipCursor", UInt,&R ) : DllCall( "ClipCursor" )
}