tatsuTrainingCookies(onOff := 1) {	;// 5 seconds
	static f := Func("tatsuTrainingCookies")
	if !(onOff) {
		SetTimer, %f%, Off
		return
	}
	textToDiscord("t{!}tg train{Enter}t{!}cookie 387292489561800706", 1)
	Random, rTime, 5500, 6500
	SetTimer, %f%, %rTime%
}

tatsuFish(onOff := 1) {
	static f := Func("tatsuFish")
	if !(onOff) {
		SetTimer, %f%, Off
		return
	}
	textToDiscord("t{!}fish", 1)
	Random, rTime, 30500, 32000
	SetTimer, %f%, %rTime%
}

textToDiscord(text, flagEnter) {
	if WinExist("boooooooooot - Discord") {
		ControlFocus,, ahk_exe Discord.exe
		sleep, 50
		ControlSend,, % "{Esc}" . text . (flagEnter ? "{Enter}":""), ahk_exe Discord.exe
	}
}