/*
MousePrecise.ahk from the book AutoHotkey Hotkey Techniques
(https://www.computoredgebooks.com/AutoHotkey-Hotkey-Techniques-All-File-Formats_c41.htm?sourceCode=MousePrecise)
is an AutoHotkey script which converts the nummeric pad key into a mouse cursor repositioning
tool which moves the cursor one pixels at a time in eight possible directions with or
without the left mouse button held down.

This AutoHotkey script creates a graphics tool for precisely positioning the mouse cursor.
GroupAdd command is used to add graphics programs to the group of windows where Hotkeys are active.
Snipping Tool requires three different windows in the group.

ALT+arrow key moves mouse one pixel in the direction of the arrow key for precise alignment.

Scan Codes for numeric pad are used to map mouse cursor movement in eight directions
bypassing the NumLock key.

Numpad0 toggles left mouse button up and down.

Since the left mouse is disabled while LButton is toggled down, NumpadEnter is an escape
key for those times when a graphic window accidentally goes inactive while the LButton
is toggled down.

To temporarily activate the Hotkey group for any window to use CTRL+NumpadDel key.
This Hotkey adds the current active window's class to the Graphics group. To permanently
add the programs class, insert the GroupAdd command below.

If for some reason the hotkeys stop working, right-click on the system tray icon and select Reload.

To temporarily add a window to the group right-click on the system tray icon and select Add Window Class.

October 8, 2019 — Added the Create_Mouse2_ico(NewHandle := False) function created by Image2Include.ahk to embed the
Mouse2.ico file in the script. This eliminates the need for the FileInstall command or providing the ICO file
separately.

https://autohotkey.com/board/topic/93292-image2include-include-images-in-your-scripts/

February 29, 2020

Added a Hotkey to the center button (5) to jump 16 pixel increments to form squares. This aids in
cropping for icons (16x16, 32x32, 48x48). Hold SHIFT+5 to reverse cursor movement.
*/

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
; FileInstall, Mouse2.ico, Mouse2.ico

; add to auto-execute section of script
GroupAdd, Graphics, ahk_class Microsoft-Windows-Tablet-SnipperToolbar
GroupAdd, Graphics, ahk_class Microsoft-Windows-Tablet-SnipperCaptureForm
GroupAdd, Graphics, ahk_class Microsoft-Windows-Tablet-SnipperEditor
GroupAdd, Graphics, ahk_class IrfanView
GroupAdd, Graphics, ahk_class MSPaintApp


Hotkey, NumpadEnter, off
Menu, tray, add, Add Window Class (CTRL+NumpadDel), AddClass
Menu, tray, add, Reload, Reload

; Changed to embedded ICO file
; Menu, tray, Icon, Mouse2.ico
Menu, tray, Icon, % "HBITMAP:*" . Create_Mouse2_ico()

		
; Add the following directives and Hotkeys toward the end of the script

#IfWinActive ahk_group Graphics  
    
!up::MouseMove, 0, -1, 0, R  ; Win+UpArrow hotkey => Move cursor upward
!Down::MouseMove, 0, 1, 0, R  ; Win+DownArrow => Move cursor downward
!Left::MouseMove, -1, 0, 0, R  ; Win+LeftArrow => Move cursor to the left
!Right::MouseMove, 1, 0, 0, R  ; Win+RightArrow => Move cursor to the right
;Numpad0::Send % (toggle := !toggle) ? "{LButton Down}" : "{LButton Up}"  ; Replaced with Scan Code

;SC052::Send % (toggle := !toggle) ? "{LButton Down}" : "{LButton Up}"    ; Replaced with "If" conditional to add more features

; There are two forms of the SC052 Hotkey. The first uses If conditional statements to embedded additional commands.
; The second form (currently active) uses functions to embed the on and off command, plus the ternary operator in the Hotkey.
; The second form makes the script more modular (one Hotkey and two functions) while making the function available
; elsewhere in the script—if needed.


/*         
SC052::                ; This is the If conditional form of the Hotkey
   if  (toggle := !toggle)
    {
	  Hotkey, NumpadEnter, on
	  Send {LButton Down}
	  Tooltip, Left Button Down`rNumpadEnter to cancel, 20,20
	}
    else
	{	   
	  Hotkey, NumpadEnter, off
	  Send {LButton Up}
	  Tooltip
	}
Return
*/

SC052::% (toggle := !toggle) ? toggleon() : toggleoff()  ; This form of the Hotkey using functions and the ternary
toggleon()
    {
	  Hotkey, NumpadEnter, on
	  Send {LButton Down}
	  Tooltip, Left Button Down`rNumpadEnter to cancel, 20,20
	}

toggleoff()
	{	   
	  Hotkey, NumpadEnter, off
	  Send {LButton Up}
	  Tooltip
	}
	
; Hardwire mouse cursor movement in eight directions one pixel at a times

SC04F::MouseMove, -1, 1, 0, R  ; Numpad1 key down left
SC050::MouseMove, 0, 1, 0, R   ; Numpad2 key down
SC051::MouseMove, 1, 1, 0, R   ; Numpad3 key down right
SC04B::MouseMove, -1, 0, 0, R  ; Numpad4 key left
SC04C::MouseMove, 16, 16, 0, R ; Numpad5 key 16px square
+SC04C::MouseMove, -16, -16, 0, R ; Numpad5 key 16px square (reverse)
SC04D::MouseMove, 1, 0, 0, R   ; Numpad6 key right
SC047::MouseMove, -1, -1, 0, R ; Numpad7 key up left
SC048::MouseMove, 0, -1, 0, R  ; Numpad8 key up
SC049::MouseMove, 1, -1, 0, R  ; Numpad9 key up right

^SC050::MouseMove, -1, 2, 0, R ; Sample code for adding another angle  206.6°
^SC048::MouseMove, 1, -2, 0, R ; Sample code for adding another angle   26.6°
^SC04D::MouseMove, 7, -4, 0, R ; Sample code for adding another angle   ~60 °

#If toggle and WinActive("ahk_group Graphics") ;disable the left mouse button
 
LButton::Return

#If



NumpadEnter::   ; Escape Hotkey
  Tooltip              ; turn Tooltip off
  toggle = 0           ; set toogle to off
  Send {LButton Up}    ; release LButton
Return


^SC053::   ;Hotkey CTRL+NumpadDel to add window class to group
  WinGetTitle, title , A
  WinGetClass, class, A
  ; Ignore certain classes of windows — This portion stolen from Jim S.
  ; Progman = Desktop; DV2ControlHost = Start Menu; Shell_TrayWnd = Taskbar
If class in Progman,DV2ControlHost,Shell_TrayWnd,Windows.UI.Core.CoreWindow,WorkerW,MultitaskingViewFrame
  Return
Else
  {
  GroupAdd, Graphics, ahk_class %class%
  RegExMatch(title,"-\s(.*)",ProgName)
  MsgBox, % ProgName1 . " temporarily`radded to MousePrecise group."
  }
Return

Reload:
  Reload
Return

AddClass:
  SendInput, !{Esc}
  GoSub, ^SC053
Return

; add this func at bottom:
; ##################################################################################
; # This #Include file was generated by Image2Include.ahk, you must not change it! #
; #
; # https://autohotkey.com/board/topic/93292-image2include-include-images-in-your-scripts/
; #
; ##################################################################################
Create_Mouse2_ico(NewHandle := False) {
Static hBitmap := 0
If (NewHandle)
   hBitmap := 0
If (hBitmap)
   Return hBitmap
VarSetCapacity(B64, 4352 << !!A_IsUnicode)
B64 := "AAABAAEAICAAAAEAGACoDAAAFgAAACgAAAAgAAAAQAAAAAEAGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDR0dGFhppbWmtBQVQqKj4eHjkhKToqKj4bGzQeHjkbGzQjKT4/R1tma35+h5B7fouwt73w8PDw8PCpvONbdNFBa85LddHk7+/w8PDw8PDw8PDw8PDw8PDw8PDw8PDb2+AsMVIrL1I3Q2ZEWH5XaZNfdZ9TcKNKY5pFYZc+VH5AUnJTXXtfZn1SWm9MVmhFSFVgZXHw8PDk7+8zM5gyMpFEg9OwyOXw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDa2+NslMRlkdM5UpszQXRTcKx0j8BijsY6W6MxM3o1PY6qtszw8PDw8PDw8PDw8PDw8PDw8PDw8PCGmcwwMHNejtLs8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDo7++ivNhbfbk6VJ8yN3kvMnIvMnI1Pok5U54zOY41Q4x8iaPg4uXw8PDw8PDw8PDw8PDY2+YyMpFWftPw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDs8PDi6u7V2+a/xtm/zNhcfrUyOXUvPGN3iqnJ0tvF0ejCzufZ3uvJ0N1wk8HE0ODw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDj5umUrMOfscLJ0dfK1tyhveNmmtlzntqVtuGpxuXa4ujg4uXi6u7w8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDi6u6wxtS/z9q+ztmTs8s9cbg+a848ZM1SmdhSitVEgdNtm9qvytnV4ufZ4+zw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDL2eW2y+KxxtiMt9xSjL41Q4wwMHQ1Q4Q9cs85U5kzNog5VKRin8u10OfQ4OvX4+zw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDe5u2nwNaJs8+Ft+CWwuOhx+ScxN9klb9Wcpd9pMdJaZJHg7WTwOOhx+Sp0Oeyzue50ejW4+zw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDD0t1Zi7hyo8Vvps+NveKpx+C+zNrN1+LR1um3uuPQ1eLC0t26zue10OeizOaWwuOYvNWvx+Xk7+/w8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PCkuMpci7R5pMiHs8+Tut2vxti+0N2FrNZLZc1/idd7ltm80ejO2eLC0+i10eeiw9ySs89wmL/C0uPw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PBui6lHdKN8pcF0o8RmlbeUssR1n8M3S5oqKlwtLWouLnI9dca1zuK80eiiw9yiw9yqxdd6ocSdudHw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PBrh6dBcaBei65NdJ5Qe6JAY4o8aJs5UaIqL1oiIkQuMmk8XbBtmLeApceFrMyTtdCkw9xtmLyDpMHw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PCIn7RBcaA8bJY5XYdGcZgxQ2QzSmo6XI0rNFkvPGA5WKM6fLRDbJlFc6ZZi7hdjriSss13mbylt8jw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PCrt787Yo05WX05WoFIbJAxQ1YhKToxQFojKUAtO1ozSm4/WXgzSm5Ec6NPgaxJgK13n79njrLQ1dzw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDPz9M7Z5M3UnM6YYtFapIrNUQWFiYyRW0sN1gxQ2g3U3kqN0sUFBRCcJ5Je6c7eatUgKdoianm5ubw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PBcdJI7aZU6YZg4V3oxQmM2UG4xQ2kvPGAwQGE4UYIyR2csO1U7ZpY+fa1BcKNQdJ2vvMfw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PCwt8A8Yag3UY41TXE3UnUyQVotPF4wPmQrN1IyRW05WX03VXY7aZU8aZ1llsFngZ/P0dPw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PBzp9w9Vco6VpkxQ2o4UYAwP2MsN1gxQ2QsN1UsN1kzS245XYc5XYc3VoQ6gMqTq8Dw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PC80eg9cs86etE9bb4oMVIwPGUvPGQrNVQsO1MtPFcwPmQyRW03UXw1SndLe69Fldc+jtXo7+/w8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PBfn9o9iNQ+j9U9i9QvPGAxQ2k5WX83SGM9SV4/T2k5UnM4U3w1SncyRW5SjdF0rN0/lNa2zufw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PA+kNY6ftJPn9lnmMw1SneDkqVIXns5U3Y5U3Y4VXg4VHpFXXtNZ4Y2THt2ptx4sN5XodqFs9/w8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PBPmtg7dNBpqdxHeq/GytHw8PDY2NimsbqIlaZ4iZyWpK/S0tbm5ulPaZFmkMODveFAltd5rt7w8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDK2+Y6fNE8iM+/ytTw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDe3uROeKt9t+A9i9Sew+Tw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDd4+3d4+3w8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PC9xdI9idRlpdvw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDo7+/w8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PDw8PAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=="
If !DllCall("Crypt32.dll\CryptStringToBinary", "Ptr", &B64, "UInt", 0, "UInt", 0x01, "Ptr", 0, "UIntP", DecLen, "Ptr", 0, "Ptr", 0)
   Return False
VarSetCapacity(Dec, DecLen, 0)
If !DllCall("Crypt32.dll\CryptStringToBinary", "Ptr", &B64, "UInt", 0, "UInt", 0x01, "Ptr", &Dec, "UIntP", DecLen, "Ptr", 0, "Ptr", 0)
   Return False
; Bitmap creation adopted from "How to convert Image data (JPEG/PNG/GIF) to hBITMAP?" by SKAN
; -> http://www.autohotkey.com/board/topic/21213-how-to-convert-image-data-jpegpnggif-to-hbitmap/?p=139257
hData := DllCall("Kernel32.dll\GlobalAlloc", "UInt", 2, "UPtr", DecLen, "UPtr")
pData := DllCall("Kernel32.dll\GlobalLock", "Ptr", hData, "UPtr")
DllCall("Kernel32.dll\RtlMoveMemory", "Ptr", pData, "Ptr", &Dec, "UPtr", DecLen)
DllCall("Kernel32.dll\GlobalUnlock", "Ptr", hData)
DllCall("Ole32.dll\CreateStreamOnHGlobal", "Ptr", hData, "Int", True, "PtrP", pStream)
hGdip := DllCall("Kernel32.dll\LoadLibrary", "Str", "Gdiplus.dll", "UPtr")
VarSetCapacity(SI, 16, 0), NumPut(1, SI, 0, "UChar")
DllCall("Gdiplus.dll\GdiplusStartup", "PtrP", pToken, "Ptr", &SI, "Ptr", 0)
DllCall("Gdiplus.dll\GdipCreateBitmapFromStream",  "Ptr", pStream, "PtrP", pBitmap)
DllCall("Gdiplus.dll\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "PtrP", hBitmap, "UInt", 0)
DllCall("Gdiplus.dll\GdipDisposeImage", "Ptr", pBitmap)
DllCall("Gdiplus.dll\GdiplusShutdown", "Ptr", pToken)
DllCall("Kernel32.dll\FreeLibrary", "Ptr", hGdip)
DllCall(NumGet(NumGet(pStream + 0, 0, "UPtr") + (A_PtrSize * 2), 0, "UPtr"), "Ptr", pStream)
Return hBitmap
}
