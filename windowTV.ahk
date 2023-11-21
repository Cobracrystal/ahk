#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
global HWND :=
return

^+R::
Reload
return

^!J::
HWND:=WinExist("A")
return

^F1::
	TVCloseOpen(HWND,500,500)
return

TVCloseOpen(HWND,HeightStep:=100,WidthStep:=100){ ; Credit @ tmplinshi,Improved and Modified by AfterLemon
static p:=[]
	WinDelay:=A_WinDelay
	SetWinDelay,-1
	If p[HWND].1{
		x:=p[HWND].1+(p[HWND].3/2),y:=p[HWND].2+(p[HWND].4/2),Step:=p[HWND].4/HeightStep,Step2:=p[HWND].3/WidthStep
		WinMove,ahk_id %HWND%,,x,y,(p[HWND].5&0xC00000?-3:3),(p[HWND].5&0xC00000?-25:3)
		WinShow,ahk_id %HWND%
		Loop,% WidthStep
			WinMove,ahk_id %HWND%,,% xn:=x-((Step2*A_Index)/2),,% wn:=p[HWND].3-(Step2*(WidthStep-A_Index))
		If(p[HWND].5&0xC00000)
			WinSet,Style,+0xC00000,ahk_id %HWND%
		Loop,% HeightStep
			WinMove,ahk_id %HWND%,,,% yn:=y-((Step*A_Index)/2),,% hn:=p[HWND].4-(Step*(HeightStep-A_Index))
		p[HWND]:=""
	}else{
		WinGetPos,x,y,w,h,ahk_id %HWND%
		WinGet,S,Style,ahk_id %HWND%
		p[HWND]:=[x,y,w,h,S],Step:=(h-3)/HeightStep,Step2:=(w-3)/WidthStep
		Loop,% HeightStep
			WinMove,ahk_id %HWND%,,,% y:=y+(Step/2),,% h:=h-Step
		WinSet,Style,-0xC00000,ahk_id %HWND%
		WinSet,Redraw,,ahk_id %HWND%
		Loop,% WidthStep
			WinMove,ahk_id %HWND%,,% x:=x+(Step2/2),,% w:=w-Step2
		WinHide,ahk_id %HWND%
		WinMove,ahk_id %HWND%,,% p[HWND].1,% p[HWND].2,% p[HWND].3,% p[HWND].4
	}
	SetWinDelay,%WinDelay%
}


TVClose(HideAndRestore = False, H_ReduceCount = 2, W_ReduceCount = 2)
{
	Gui, %A_Gui%:+LastFound
	; Decrease height (keep 3 pixels)
	Step := (h - 3) / H_ReduceCount
	Loop, % H_ReduceCount
	{
		y += Step / 2 ; Moving down
		h -= Step     ; Decreasing height
		WinMove,,,, %y%,, %h%
	}
	
	; Decrease Width (keep 3 pixels)
	Step := (w - 3) / W_ReduceCount
	Loop, % W_ReduceCount
	{
		x += Step / 2 ; Moving right
		w -= Step     ; Decreasing width
		WinMove,,, %x%,, %w%
	}
	Gui, Destroy
}