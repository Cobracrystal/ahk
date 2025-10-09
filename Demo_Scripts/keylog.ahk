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