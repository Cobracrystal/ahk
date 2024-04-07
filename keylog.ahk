; original idea from:
; http://www.autohotkey.com/board/topic/30294-simple-key-stroke-recorder/
; modified yet again by Cobracrystal to make it into a readable, functionable thing that isn't terrible
; // maybe todo: if only keys in succession without mouse interruption then chain them together into one line
; // if key is held down for a while, log it only once
#Requires Autohotkey v2+
#SingleInstance Force
#Warn All, Off
A_HotkeyInterval := 0
; LogKey() {
; 	Key := RegExReplace(asc(SubStr(A_ThisHotkey,0)),"^0x")
; 	FileAppend, % (StrLen(Key) == 1 ? "0" : "") . Key, Log.log
; }


KeyLogger.start(1)

class KeyLogger {
	static start(initMouse := false) {
		this.logdir := A_AppData "\keylogger"
		DirCreate(this.logdir)
		this.setlog()
		this.date := 0
		A_TrayMenu.Delete()
		A_TrayMenu.Add("Enable Logger", this.logToggleMenu)
		A_TrayMenu.Check("Enable Logger")
		A_TrayMenu.Add("Log Mouse", this.mouseLogToggleMenu)
		A_TrayMenu.Check("Log Mouse")
		A_TrayMenu.Add()
		A_TrayMenu.Add("Start new logfile", this.setlog.bind(this))
		A_TrayMenu.Add("Open log folder", (*) => Run('explorer.exe "' this.logdir '"'))
		A_TrayMenu.Add("Reload", (*) => Reload())
		A_TrayMenu.Add("Exit", (*) => ExitApp())
		this.getwin()
		SetTimer(this.wingetLoop.bind(this), -1)

		if (!initMouse)
			this.mouseLogToggleMenu()

		; loop ASCII: ! to ~.
		Loop(32)
			Hotkey("~*" . Chr(A_Index+32), this.keyEvent.bind(this))
		Loop(26)
			Hotkey("~*+" . Chr(A_Index+64), this.keyEvent.bind(this))
		Loop(36)
			Hotkey("~*" . Chr(A_Index+90), this.keyEvent.bind(this))
		Loop(24)
			Hotkey("~*F" . A_Index, this.keyEvent.bind(this, "{F" . A_Index . "}"))
		; special keys
		nonAsciiKeys := ["´","°","§","ß"]
		numpadKeys := ["0","1","2","3","4","5","6","7","8","9","Add","Clear","Del","Div","Dot","Down","End","Enter","Home","Ins","Left","Mult","PgDn","PgUp","Right","Sub","Up"]
		genFunctionKeys := ["AppsKey","PrintScreen","Pause","Delete","Insert","Home","End","PgUp","PgDn","Up","Down","left","Right","NumLock","ScrollLock","CapsLock","Esc","Enter","Tab","Space","XButton1","XButton2"]
		mouseButtons := ["LButton","RButton","MButton"] ; xbutton1/2 are mouse, but not relevant for coordinates
		modKeys := ["Win","Control","Shift","Alt"]
		for i, key in nonAsciiKeys
			Hotkey("~*" key, this.keyEvent.bind(this))
		for i, key in numpadKeys
			Hotkey("~*Numpad" . key, this.keyEvent.bind(this, "{Numpad" key "}"))
		for i, key in genFunctionKeys
			Hotkey("~*" key, this.keyEvent.Bind(this,"{" key "}"))
		for i, mKey in mouseButtons
			Hotkey("~*" mKey, this.mouseevent.Bind(this, mKey))
		for i, modKey in modKeys {
			Hotkey("~*L" modKey, this.keyEvent.bind(this, "{L" modKey " Down}"))
			Hotkey("~*R" modKey, this.keyEvent.bind(this, "{R" modKey " Down}"))
			Hotkey("~*L" modKey " Up", this.keyEvent.bind(this, "{L" modKey " Up}"))
			Hotkey("~*R" modKey " Up", this.keyEvent.bind(this, "{R" modKey " Up}"))
		}
		Hotkey("~*SC00E", this.keyEvent.bind(this,"{BS}"))
	}

	static setlog(*) {
		time := FormatTime(A_Now, "yyyy-MM-dd")
		this.path := this.logdir "\" time ".txt"
	}

	static winGetLoop() {
		while (true) {
			WinWaitNotActive("ahk_id " WinActive("A"))
			this.getwin()
		}
	}

	static getwin() {
		DetectHiddenWindows(1)
		time := FormatTime(A_Now, "HH:mm:ss")
		handle := WinExist("A")
		if !(handle)
			return
		title := WinGetTitle("ahk_id " handle)
		try
			process := WinGetProcessName("ahk_id " handle)
		catch Error
			process := "" 
		this.logAddHeader()
		FileAppend(Format("{1} New Active Window:`t [{2}, `"{3}`"]`n", time, process, title), this.path, "UTF-8")
	}

	static logAddHeader() {
		if (SubStr(A_Now, 1, 8) != this.date) {
			FileAppend("##################`n### " FormatTime(A_Now, "yyyy-MM-dd") " ###`n", this.path, "UTF-8")
			this.date := SubStr(A_Now, 1, 8)
		}
	}

	static mouseLogToggleMenu(*) {
		A_TrayMenu.ToggleCheck("Log Mouse")
		Hotkey("~*LButton", "Toggle")
		Hotkey("~*MButton", "Toggle")
		Hotkey("~*RButton", "Toggle")
	}

	static logToggleMenu(*) {
		static is_paused := false
		A_TrayMenu.ToggleCheck("Enable Logger")
		Suspend(-1)
		is_paused := !is_paused
		Pause(is_paused)
	}

	static keyEvent(key, *) {
		if (SubStr(key, 1, 2) == "~*") {
			key := SubStr(key, 3)
			if (StrLen(key) == 2 && SubStr(key, 1, 1) == "+")
				key := SubStr(key, 2, 1)
		}
		this.logAddHeader()
		FileAppend(Format("{1} Key:`t {2}`n", FormatTime(A_Now, "HH:mm:ss"), key), this.path, "UTF-8")
	}

	static mouseevent(mouseKey, *) {
		DetectHiddenWindows(1)
		CoordMode("Mouse", "Screen")
		time := FormatTime(A_Now, "HH:mm:ss")
		MouseGetPos(&x, &y, &handle, &controln)
		title := WinGetTitle("ahk_id " handle)
		try
			process := WinGetProcessName("ahk_id " handle)
		catch as e 
			process := "?"
		this.logAddHeader()
		FileAppend(Format("{1} Mouse:`t {2} @[x={3}, y={4}] On Window: [{5}, `"{6}`"]`t Control: {7}`n", time, mouseKey, x, y, process, title, controln), this.path)
	}
}

; -------------------------------

; -------------------- HOTKEY EVENTS HERE

; for keys that remain undetected by writing out the symbol directly
~*^!7:: KeyLogger.keyEvent("{")
~*^!8:: KeyLogger.keyEvent("[")
~*^!9:: KeyLogger.keyEvent("]")
~*^!0:: KeyLogger.keyEvent("}")
~*^!ß:: KeyLogger.keyEvent("\")
~*^+!ß:: KeyLogger.keyEvent("ẞ")
~*^!q:: KeyLogger.keyEvent("@")
~*^!m:: KeyLogger.keyEvent("µ")
~*^!e:: KeyLogger.keyEvent("€")
~*^!<:: KeyLogger.keyEvent("|")
~*^!+:: KeyLogger.keyEvent("~")
~*^!2:: KeyLogger.keyEvent("²")
~*^!3:: KeyLogger.keyEvent("³")

; ~*´:: KeyLogger.keyEvent("´")
; ~*°:: KeyLogger.keyEvent("°")
; ~*§:: KeyLogger.keyEvent("§")
; ~*ß:: KeyLogger.keyEvent("ß")

; ~*LButton:: KeyLogger.mouseEvent("LButton")
; ~*MButton:: KeyLogger.mouseEvent("MButton")
; ~*RButton:: KeyLogger.mouseEvent("RButton")

; ~*Pause:: KeyLogger.keyEvent("{Pause}")
; ~*Delete:: KeyLogger.keyEvent("{Delete}")
; ~*Insert:: KeyLogger.keyEvent("{Insert}")
; ~*Home:: KeyLogger.keyEvent("{Home}")
; ~*End:: KeyLogger.keyEvent("{End}")
; ~*PgUp:: KeyLogger.keyEvent("{PgUp}")
; ~*PgDn:: KeyLogger.keyEvent("{PgDn}")
; ~*Up:: KeyLogger.keyEvent("{Up}")
; ~*Down:: KeyLogger.keyEvent("{Down}")
; ~*Left:: KeyLogger.keyEvent("{Left}")
; ~*Right:: KeyLogger.keyEvent("{Right}")
; ~*ScrollLock:: KeyLogger.keyEvent("{ScrollLock}")
; ~*CapsLock:: KeyLogger.keyEvent("{CapsLock}")
; ~*Esc:: KeyLogger.keyEvent("{Esc}")
; ~*SC00E:: KeyLogger.keyEvent("{BS}")
; ~*Enter:: KeyLogger.keyEvent("{Enter}")
; ~*Tab:: KeyLogger.keyEvent("{Tab}")
; ~*Space:: KeyLogger.keyEvent("{Space}")
; ~*AppsKey:: KeyLogger.keyEvent("{AppsKey}")
; ~*PrintScreen:: KeyLogger.keyEvent("{PrintScreen}")

; ~*LWin:: KeyLogger.keyEvent("{LWin Down}")
; ~*RWin:: KeyLogger.keyEvent("{RWin Down}")
; ~*LControl:: KeyLogger.keyEvent("{LControl Down}")
; ~*RControl:: KeyLogger.keyEvent("{RControl Down}")
; ~*LShift:: KeyLogger.keyEvent("{LShift Down}")
; ~*RShift:: KeyLogger.keyEvent("{RShift Down}")
; ~*LAlt:: KeyLogger.keyEvent("{LAlt Down}")
; ~*RAlt:: KeyLogger.keyEvent("{RAlt Down}")

; ~*LWin Up:: KeyLogger.keyEvent("{LWin Up}")
; ~*RWin Up:: KeyLogger.keyEvent("{RWin Up}")
; ~*LControl Up:: KeyLogger.keyEvent("{LControl Up}")
; ~*RControl Up:: KeyLogger.keyEvent("{RControl Up}")
; ~*LShift Up:: KeyLogger.keyEvent("{LShift Up}")
; ~*RShift Up:: KeyLogger.keyEvent("{RShift Up}")
; ~*LAlt Up:: KeyLogger.keyEvent("{LAlt Up}")
; ~*RAlt Up:: KeyLogger.keyEvent("{RAlt Up}")

; ~*F1:: KeyLogger.keyEvent("{F1}")
; ~*F2:: KeyLogger.keyEvent("{F2}")
; ~*F3:: KeyLogger.keyEvent("{F3}")
; ~*F4:: KeyLogger.keyEvent("{F4}")
; ~*F5:: KeyLogger.keyEvent("{F5}")
; ~*F6:: KeyLogger.keyEvent("{F6}")
; ~*F7:: KeyLogger.keyEvent("{F7}")
; ~*F8:: KeyLogger.keyEvent("{F8}")
; ~*F9:: KeyLogger.keyEvent("{F9}")
; ~*F10:: KeyLogger.keyEvent("{F10}")
; ~*F11:: KeyLogger.keyEvent("{F11}")
; ~*F12:: KeyLogger.keyEvent("{F12}")
; ~*F13:: KeyLogger.keyEvent("{F13}")
; ~*F14:: KeyLogger.keyEvent("{F14}")
; ~*F15:: KeyLogger.keyEvent("{F15}")
; ~*F16:: KeyLogger.keyEvent("{F16}")
; ~*F17:: KeyLogger.keyEvent("{F17}")
; ~*F18:: KeyLogger.keyEvent("{F18}")
; ~*F19:: KeyLogger.keyEvent("{F19}")
; ~*F20:: KeyLogger.keyEvent("{F20}")
; ~*F21:: KeyLogger.keyEvent("{F21}")
; ~*F22:: KeyLogger.keyEvent("{F22}")
; ~*F23:: KeyLogger.keyEvent("{F23}")
; ~*F24:: KeyLogger.keyEvent("{F24}")

; ~*NumLock:: KeyLogger.keyEvent("{NumLock}")
; ~*Numpad0:: KeyLogger.keyEvent("{Numpad0}")
; ~*Numpad1:: KeyLogger.keyEvent("{Numpad1}")
; ~*Numpad2:: KeyLogger.keyEvent("{Numpad2}")
; ~*Numpad3:: KeyLogger.keyEvent("{Numpad3}")
; ~*Numpad4:: KeyLogger.keyEvent("{Numpad4}")
; ~*Numpad5:: KeyLogger.keyEvent("{Numpad5}")
; ~*Numpad6:: KeyLogger.keyEvent("{Numpad6}")
; ~*Numpad7:: KeyLogger.keyEvent("{Numpad7}")
; ~*Numpad8:: KeyLogger.keyEvent("{Numpad8}")
; ~*Numpad9:: KeyLogger.keyEvent("{Numpad9}")
; ~*NumpadAdd:: KeyLogger.keyEvent("{NumpadAdd}")
; ~*NumpadClear:: KeyLogger.keyEvent("{NumpadClear}")
; ~*NumpadDel:: KeyLogger.keyEvent("{NumpadDel}")
; ~*NumpadDiv:: KeyLogger.keyEvent("{NumpadDiv}")
; ~*NumpadDot:: KeyLogger.keyEvent("{NumpadDot}")
; ~*NumpadDown:: KeyLogger.keyEvent("{NumpadDown}")
; ~*NumpadEnd:: KeyLogger.keyEvent("{NumpadEnd}")
; ~*NumpadEnter:: KeyLogger.keyEvent("{NumpadEnter}")
; ~*NumpadHome:: KeyLogger.keyEvent("{NumpadHome}")
; ~*NumpadIns:: KeyLogger.keyEvent("{NumpadIns}")
; ~*NumpadLeft:: KeyLogger.keyEvent("{NumpadLeft}")
; ~*NumpadMult:: KeyLogger.keyEvent("{NumpadMult}")
; ~*NumpadPgDn:: KeyLogger.keyEvent("{NumpadPgDn}")
; ~*NumpadPgUp:: KeyLogger.keyEvent("{NumpadPgUp}")
; ~*NumpadRight:: KeyLogger.keyEvent("{NumpadRight}")
; ~*NumpadSub:: KeyLogger.keyEvent("{NumpadSub}")
; ~*NumpadUp:: KeyLogger.keyEvent("{NumpadUp}")

; ~*a:: KeyLogger.keyEvent("a")
; ~*b:: KeyLogger.keyEvent("b")
; ~*c:: KeyLogger.keyEvent("c")
; ~*d:: KeyLogger.keyEvent("d")
; ~*e:: KeyLogger.keyEvent("e")
; ~*f:: KeyLogger.keyEvent("f")
; ~*g:: KeyLogger.keyEvent("g")
; ~*h:: KeyLogger.keyEvent("h")
; ~*i:: KeyLogger.keyEvent("i")
; ~*j:: KeyLogger.keyEvent("j")
; ~*k:: KeyLogger.keyEvent("k")
; ~*l:: KeyLogger.keyEvent("l")
; ~*m:: KeyLogger.keyEvent("m")
; ~*n:: KeyLogger.keyEvent("n")
; ~*o:: KeyLogger.keyEvent("o")
; ~*p:: KeyLogger.keyEvent("p")
; ~*q:: KeyLogger.keyEvent("q")
; ~*r:: KeyLogger.keyEvent("r")
; ~*s:: KeyLogger.keyEvent("s")
; ~*t:: KeyLogger.keyEvent("t")
; ~*u:: KeyLogger.keyEvent("u")
; ~*v:: KeyLogger.keyEvent("v")
; ~*w:: KeyLogger.keyEvent("w")
; ~*x:: KeyLogger.keyEvent("x")
; ~*y:: KeyLogger.keyEvent("y")
; ~*z:: KeyLogger.keyEvent("z")
; ~*+A:: KeyLogger.keyEvent("A")
; ~*+B:: KeyLogger.keyEvent("B")
; ~*+C:: KeyLogger.keyEvent("C")
; ~*+D:: KeyLogger.keyEvent("D")
; ~*+E:: KeyLogger.keyEvent("E")
; ~*+G:: KeyLogger.keyEvent("G")
; ~*+H:: KeyLogger.keyEvent("H")
; ~*+I:: KeyLogger.keyEvent("I")
; ~*+J:: KeyLogger.keyEvent("J")
; ~*+K:: KeyLogger.keyEvent("K")
; ~*+L:: KeyLogger.keyEvent("L")
; ~*+M:: KeyLogger.keyEvent("M")
; ~*+N:: KeyLogger.keyEvent("N")
; ~*+O:: KeyLogger.keyEvent("O")
; ~*+P:: KeyLogger.keyEvent("P")
; ~*+Q:: KeyLogger.keyEvent("Q")
; ~*+R:: KeyLogger.keyEvent("R")
; ~*+S:: KeyLogger.keyEvent("S")
; ~*+T:: KeyLogger.keyEvent("T")
; ~*+U:: KeyLogger.keyEvent("U")
; ~*+V:: KeyLogger.keyEvent("V")
; ~*+W:: KeyLogger.keyEvent("W")
; ~*+X:: KeyLogger.keyEvent("X")
; ~*+Y:: KeyLogger.keyEvent("Y")
; ~*+Z:: KeyLogger.keyEvent("Z")
; ~*`:: KeyLogger.keyEvent("``")
; ~*!:: KeyLogger.keyEvent("!")
; ~*@:: KeyLogger.keyEvent("@")
; ~*#:: KeyLogger.keyEvent("#")
; ~*$:: KeyLogger.keyEvent("$")
; ~*^:: KeyLogger.keyEvent("^")
; ~*&:: KeyLogger.keyEvent("&")
; ~**:: KeyLogger.keyEvent("*")
; ~*(:: KeyLogger.keyEvent("(")
; ~*):: KeyLogger.keyEvent(")")
; ~*-:: KeyLogger.keyEvent("-")
; ~*_:: KeyLogger.keyEvent("_")
; ~*=:: KeyLogger.keyEvent("=")
; ~*+:: KeyLogger.keyEvent("+")
; ~*[:: KeyLogger.keyEvent("[")
; ~*{:: KeyLogger.keyEvent("{")
; ~*]:: KeyLogger.keyEvent("]")
; ~*}:: KeyLogger.keyEvent("}")
; ~*\:: KeyLogger.keyEvent("\")
; ~*|:: KeyLogger.keyEvent("|")
; ~*+;:: KeyLogger.keyEvent(":")
; ~*;:: KeyLogger.keyEvent(";")
; ~*SC028:: KeyLogger.keyEvent("'")
; ~*+SC028:: KeyLogger.keyEvent('"')
; ~*,:: KeyLogger.keyEvent(",")
; ~*.:: KeyLogger.keyEvent(".")
; ~*<:: KeyLogger.keyEvent("<")
; ~*>:: KeyLogger.keyEvent(">")
; ~*/:: KeyLogger.keyEvent("/")
; ~*?:: KeyLogger.keyEvent("?")
; ~*1:: KeyLogger.keyEvent("1")
; ~*2:: KeyLogger.keyEvent("2")
; ~*3:: KeyLogger.keyEvent("3")
; ~*4:: KeyLogger.keyEvent("4")
; ~*5:: KeyLogger.keyEvent("5")
; ~*6:: KeyLogger.keyEvent("6")
; ~*7:: KeyLogger.keyEvent("7")
; ~*8:: KeyLogger.keyEvent("8")
; ~*9:: KeyLogger.keyEvent("9")
; ~*0:: KeyLogger.keyEvent("0")