;//		MADE BY COBRACRYSTAL
;//		MAIN FUNCTION

class MacroRecorder {

	static createMacro(startEndKey) {	;// Generating Function. Call this from the hotkey.
		this.macro := []
		this.prevticks := 0
		this.recordMacro(startEndKey)	;// this records everything. stops as soon as startEndKey is pressed
		this.genMacroCode()	;// this takes the recording object and creates functional code out of it
		this.createMacroGenGUI()		;// this takes the given code and displays it to edit it. Further Code all Happens via Buttons within the GUI.
	}
	
	;//		RECORDER FUNCTIONS
	
	static recordMacro(startEndKey) {	;// Tracks Keyboard Activity via InputHook
		Hotkey(startEndKey, "Off")
		this.detectMouseActivity(1)	;// creates hotkeys that record and add to macro, since there is no MouseHook
		keyChain := InputHook()
		keyChain.KeyOpt("{all}", "EV")
		keyChain.KeyOpt("{LCtrl}{RCtrl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}", "-E") ;// modifiers are not endkeys
		keyChain.KeyOpt("{" startEndKey "}", "S") ;// Supress Endkey Press
		Loop {
			keyChain.start()
			keyChain.wait()
			inputMods := RegExReplace(keyChain.EndMods, "[<>](.)(?:>\1)?", "$1")
			keyChainInput := inputMods . keyChain.EndKey
			if (this.compareKeys(inputMods, keyChain.EndKey, startEndKey))
				break
			this.macro.push({Button:keyChainInput, Time:A_TickCount})
		}
		this.detectMouseActivity(0)
		Hotkey(startEndKey, "On")
	}
	
	static recordMouseMacro(key) {	;// Records Mouse activity and stores it in the given object "macro". Does not track movement as it has no functionality
		MouseGetPos(&tx, &ty, &twin)
		this.macro.Push({Button:StrReplace(key, "~"), Time:A_TickCount, x: tx, y:ty, win: twin})
	}
	
	static detectMouseActivity(mode := 0) {	;// Initializes/toggles the hotkeys needed for tracking mouse activity
		if (mode) {
			Hotkey("~LButton", this.recordMouseMacro.Bind(this))
			Hotkey("~RButton", this.recordMouseMacro.Bind(this))
			Hotkey("~MButton", this.recordMouseMacro.Bind(this))
			;// Technically, WheelUp and WheelDown should also be in here, but they never get used anyway
			return
		}
		else {
			Hotkey("~LButton", "Off")
			Hotkey("~MButton", "Off")
			Hotkey("~RButton", "Off")
		}
	}
	
	;//		CODE GENERATING FUNCTIONS
	
	static genMacroCode() {	;// Simply loops over the object and makes readable code from it.
		code := ""
		for i, e in this.macro
			code .= this.createCodeAction(e)
		t := FormatTime(, "dd.MM.yyyy, HH:mm:ss")
		code := "^Insert::{	`; Automatic Hotkey generated " . t . "`n" . "Loop(1) {`n" . code . "}}`n"
		this.prevticks := 0
		this.macroCode := code
	}
	
	static createCodeAction(action, mode := 0) {	;// Keeps track of ticks for "Sleep, x" for timing.
		if !(this.prevTicks) {
			this.prevTicks := action.Time
			return A_Tab . this.makeLine(action) . "`n"
		}
		sleepTime := action.Time - this.prevTicks
		this.prevTicks := action.Time
		return Format(A_Tab . "Sleep({1})`n{2}`n", sleepTime, A_Tab . this.makeLine(action))
	}
	
	static makeLine(action) {	;// Converts a single action as given by keys/clicks/coordinates into a line of codeasd
		if (InStr(action.Button, "Button"))
			return Format('MouseClick("{1}", {2}, {3})', SubStr(action.Button, 1, 1), action.x, action.y)
		specialKeys := "(Space|Tab|CapsLock|Enter|Return|Backspace|Escape|Home|End|PgUp|PgDn|Insert|Delete|ScrollLock|PrintScreen|Pause|Up|Down|Left|Right|NumpadDiv|NumpadMult|NumpadSub|NumpadAdd|NumpadEnter|NumLock|Ctrlbreak|F[0-9]+|Numpad[0-9])"
		keys := action.Button
		keys := RegExReplace(keys, specialKeys, "{$1}" )
		return Format('Send("{1}")', keys)
	}
	
	static contractCode(macroCode, contractTime) {	;// Chains multiple "Send" into one, Chains multiple "MouseClick" on the same coordinates into one (with a given time)
		newCode := ""
		pLine := ""
		Loop Parse, macroCode, "`n"
		{
			line := A_LoopField . "`n"
			if (RegexMatch(line, "Sleep\((\d+)\)", &contraction)) {
				if (contraction[1] < contractTime) {
					lastSkippedSleep := line
					continue ; skip setting pLine and newCode, aka acting as if the sleep line wasnt there
				}
			}
			if (pLine && SubStr(line, 1, 3) = SubStr(pLine, 1, 3)) {
				if (RegexMatch(line, 'Send\("(.*)"\)', &sendKeys)) {
					pLine := RegexReplace(pLine, 'Send\("(.*)"\)', 'Send("$1' sendKeys[1] '")')
					continue
				}
				else if (RegexMatch(line, 'MouseClick\("(.)", (\d+), (\d+)(?:, (\d+))?\)', &cLineMouse)) {
					RegexMatch(pLine, 'MouseClick\("(.)", (\d+), (\d+)(?:, (\d+))?\)', &pLineMouse)
					if (pLineMouse[1] = cLineMouse[1] && Abs(pLineMouse[2] - cLineMouse[2]) < 8 && Abs(pLineMouse[3] - cLineMouse[3]) < 8) {
						pLine := RegexReplace(pLine, 'MouseClick\("(.)", (\d+), (\d+)(?:, (\d+))?\)', 'MouseClick("$1", $2, $3, ' . (pLineMouse[4] != "" ? pLineMouse[4]+1 : 2) . ')')
						continue
					}
					else {
						newCode .= pLine . lastSkippedSleep
						pLine := line
						continue
					}
				}
			}
			newCode .= pLine ;// Add `n if its a new line type / different coordinate click. This will *only* trigger on noncontractables. 
			pLine := line ; Remember last line. first two letters, these will always be "Mo" or "Se" or "Sl" (or "Wi")
		}
		newCode .= pLine
		return newCode
	}
	
	static adjustSleepTime(macroCode, maxTime, newTime := -1) {	;// replaces sleep times with new ones
		newCode := ""
		count := 1
		Loop Parse, macroCode, "`n" 
		{
			if (RegexMatch(A_LoopField, "Sleep\((\d+)\)", &sleepTime)) {
				if (sleepTime[1] < maxTime) {
					newCode .= RegexReplace(A_Loopfield, "Sleep\(\d+\)", Format("Sleep({})", newTime == -1 ? (sleepTime[1] < 50 ? 50 : Round(sleepTime[1], -2)): newTime)) . "`n"
					continue
				}
			}
			newCode .= A_LoopField . "`n" ;// Add `n if its a new line type / different coordinate click
		}
		return newCode
	}
	
	;// 	HELP FUNCTIONS
	
	static compareKeys(firstKeyMods, firstKey, secondKey) {	;// Compares two hotkeys, one with given modifiers and key distinction, one without. 
		if (StrLen(firstKeyMods) + StrLen(firstKey) != StrLen(secondKey))
			return 0
		if (SubStr(secondKey, -StrLen(firstKey)) != firstKey)
			return 0
		secMods := SubStr(secondKey, 1, StrLen(firstKeyMods))
		Loop Parse, firstKeyMods 
			if !(InStr(secMods, A_LoopField))
				return 0
		return 1
	}
	
	;// 	GUI STUFF
	
	static createMacroGenGUI() {	;// Creates the actual GUI to display the code in.
		macroGen := Gui("+Border +OwnDialogs", "Macro Generator")
		macroGen.AddButton("Section", "Contract all `"Send`"").OnEvent("Click", this.ContractSend.Bind(this))
		macroGen.AddButton("ys xp+110", "Norm all SleepTimers").OnEvent("Click", this.replaceSleepTime.Bind(this))
		macroGen.AddButton("ys xp+120", "Add Code to Script").OnEvent("Click", this.AddCodeToScript.Bind(this))
		macroGen.AddButton("xs", "Reset to original Code").OnEvent("Click", this.resetCode.Bind(this))
		macroGen.AddEdit("xs r30 w500 WantTab WantReturn vCodeEdit", this.macroCode)
		macroGen.OnEvent("Close", this.guiClose.bind(this))
		macroGen.OnEvent("Escape", this.guiClose.bind(this))
		this.gui := macroGen
		macroGen.Show("AutoSize")
	}
	
	static resetCode(macroCode, *) {
		this.gui["CodeEdit"].Value := this.macroCode
	}
	
	static ContractSend(*) {	;// Pressing the "Contract Code" Button
		code := this.gui["CodeEdit"].Value
		d := InputBox("Specify the time under which Commands will be chained together", "Ignored Sleeptime",,100)
		if (d.Result != "OK")
			return
		if !IsInteger(d.Value)
		{
			MsgBox("Not a valid entry.")
			return
		}
		this.gui["CodeEdit"].Value := this.contractCode(code, d.value)
	}
	
	static replaceSleepTime(*) {
		code := this.gui["CodeEdit"].Value
		d := InputBox("Specify the time under which Sleeps will be normed", "Norm Sleeptime",,5000)
		if (d.Result != "OK")
			return
		if !IsInteger(d.Value)
		{
			MsgBox("Not a valid entry.")
			return
		}
		e := InputBox("Specify what time the Sleeps should be normed to`nEnter -1 for rounding to the nearest 1/10s", "Norm Sleeptime",,75)
		if (e.Result != "OK")
			return
		if !IsInteger(e.Value)
		{
			MsgBox("Not a valid entry.")
			return
		}
		this.gui["CodeEdit"].Value := this.adjustSleepTime(code, d.Value, e.Value)
	}
	
	static AddCodeToScript(*) {
		code := this.gui["CodeEdit"].Value
		if (!Instr(code, "::")) {
			MsgBox("Problem while adding", "No Hotkey found.", 0)
			return
		}
		hkey := SubStr(Code, 1, InStr(Code, "::")-1)
	;	if (Instr(Code, "#If")) {
	;		; todo: do a hotkey, if, expression before checking for validity of hotkey, to validify the if expression.	
	;	}
		try	
			Hotkey(hkey)
		catch Error {
			flag := 0
		}
		else {
			Msgbox("This hotkey already exists and adding it will result in an error.")
			return
		}
		msgBoxtext := "This will add the recorded Macro with the " . (hkey == "^Insert" ? "DEFAULT " : " ") . "Hotkey `n " . hkey . "`nto the script.`nProceed anyway?"
		ret := MsgBox(msgBoxtext, "Add to Script", 4)
		if (ret == "Yes")
			FileAppend("`n" . code, A_ScriptFullPath)
		else
			return
		if (MsgBox("Added to script. Reload?", "Reload?", 4) == "Yes")
			Reload()
		return
	}
		
	static guiClose(guiObj) {	;// Close GUI
		if (MsgBox("Close GUI and delete recording?", "Delete macro?", 1) == "OK") {
			this.gui.Destroy()
			this.gui := 0
		}
		else
			return true ; necessary to stop it from hiding
	}
}
