tatsuTrainingCookies(onOff := 1) {	;// 5 seconds
	if !(onOff) {
		SetTimer(tatsuTrainingCookies, 0)
		return
	}
	textToDiscord("t{!}tg train{Enter}t{!}cookie 387292489561800706", 1)
	SetTimer(tatsuTrainingCookies, Random(5500, 6500))
}

tatsuFish(onOff := 1) {
	if !(onOff) {
		SetTimer(tatsuFish, 0)
		return
	}
	textToDiscord("t{!}fish", 1)
	SetTimer(tatsuFish, Random(30500, 32000))
}

textToDiscord(text, flagEnter) {
	if WinExist("boooooooooot - Discord") {
		Sleep(50)
		ControlSend("{Esc} " . text . (flagEnter ? "{Enter}":""),, "ahk_exe Discord.exe")
	}
}