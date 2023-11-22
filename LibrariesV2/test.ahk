#SingleInstance Force
SetTitleMatchMode("RegEx")
GroupAdd("asodhasuidfh", "i)Unbenannt")
msgbox(winGetTitle("ahk_group asodhasuidfh"))
; Msgbox(WinGetTitle("i)nvidia geforce overlay ahk_class i)cef-osc-widget|unbenannt)"))

class test {

	__New() {
		this.windowID := 5
		this.property2 := true
	}
	create() {
		this.asd := Gui()
		this.a := this.asd.AddListView("r20 w700", ["1", "2"])
		; a.OnEvent("Click", function)
		; a.OnEvent("ItemFocus", function)
		; a.OnEvent("ItemSelect", function)
		this.a.OnNotify(-155, function2)
		this.a.OnEvent("Click", (*) => this.property2 ? 0 : MsgBox(this.a.GetNext(,"F")))
		this.a.Add(, "Lorem", "Ipsum")
		this.a.Add(, "Dolor Sit", "Amet")
	;	this.asd.show("autosize")
	}

	asdasd() {
		this.windowID := 89234
	}
}
; obj := (a) => false ? msgbox(a) : a+1
; msgbox(obj.call(5))
a := test()
a.create()
WinGetPos(&x, &y, &w, &h, a.asd.hwnd)
return



function2(guiCtrlObj, lParam) {
	Msgbox(NumGet(lParam, 24, "ushort"))
}
