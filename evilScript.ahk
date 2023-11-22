#NoTrayIcon
Persistent()
#SingleInstance Force
r := Random(1200000, 12000000)
SetTimer(randomError, r)
return


randomError() {
	SoundPlay("*-1")
	MsgBox("Fatal Error, A Fatal Error has occured in C:\System32\sysconfig.dll.`nRestart your system immediately.", "sysconfig.dll+0xF7D7E", "0x40000")
	SetTimer(randomError, Random(10000, 600000))
}

#HotIf doEvilStuff(5)
o::i
i::o
m::n
n::m
RButton::return
F2::F1
#::return
BackSpace::Space
^S::return

~Shift:: {
	Send("{Shift Up}")
	SetTimer(shiftdown, -100)
}

~Enter::{
	if (!Random(0, 5)) {
		SoundPlay("*16")
		if (Random(0,1))
			SetTimer(randomError, -4000)
	}
}

~LButton::{ ; sometimes adds clicks to doubleclicks
	Sleep(25)
	Click()
}

~Capslock::{ ;// This correctly toggles capslock, and toggles it back after 5 seconds
	SetTimer(toggleCapsLock, -5000)
}

^V::Clipboard := ""

shiftdown() { 
	Send("{Shift down}") 
	Sleep(200)
	Send("{Shift up}") 
}

toggleCapsLock() {
	SetCapsLockState(!GetKeyState("CapsLock", "T")) 
}

doEvilStuff(max) {
	return (Random(0,max) ? 0 : 1)
}
