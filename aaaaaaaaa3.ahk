#NoEnv
Gui, New
Gui, Add, Checkbox,, Detect Hidden Windows?
Gui, Add, ListView, vASD R20 w1000, num|key
loop 15 {
	random, a, 20, 100
	random, b, 0x0, 0xFFFFFF
	LV_Add("", a, format("{:#x}", b))
}
Gui, Show, Autosize, WindowList
return

^+e::
reload
return

guiescape(h) {
	Gui, Destroy
}

GuiClose(h) {
	Gui, Destroy
}