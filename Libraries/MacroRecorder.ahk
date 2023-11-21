;//		MAIN FUNCTION

createMacro(startEndKey) {	;// Generating Function. Call this from the hotkey.
	macro := recordMacro(startEndKey)	;// this records everything. stops as soon as startEndKey is pressed
	macroCode := genMacroCode(macro)	;// this takes the recording object and creates functional code out of it
	createMacroGenGUI(macroCode)		;// this takes the given code and displays it to edit it. Further Code all Happens via Buttons within the GUI.
}

;//		RECORDER FUNCTIONS

recordMacro(startEndKey) {	;// Tracks Keyboard Activity via InputHook
	macro := {}
	detectMouseActivity(macro, 1)	;// creates hotkeys that record and add to macro, since there is no MouseHook
	keyChain := InputHook()
	keyChain.KeyOpt("{all}", "EV")
	keyChain.KeyOpt("{LCtrl}{RCtrl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}", "-E") ;// modifiers are not endkeys
	keyChain.KeyOpt("{%startEndKey%}", "S") ;// Supress Endkey Press
	Loop {
		keyChain.start()
		keyChain.wait()
		inputMods := RegExReplace(keyChain.EndMods, "[<>](.)(?:>\1)?", "$1")
		keyChainInput := inputMods . keyChain.EndKey
		if (compareKeys(inputMods, keyChain.EndKey, startEndKey))
			break
		macro.push({"Button":keyChainInput, "Time":A_TickCount})
	}
	detectMouseActivity(0, 0)
	return macro
}

recordMouseMacro(key, ByRef macro) {	;// Records Mouse activity and stores it in the given object "macro". Does not track movement as it has no functionality
	MouseGetPos, tx, ty, twin
	macro.Push({"Button":key, "Time":A_TickCount, "x": tx, "y":ty, "win": twin})
}

detectMouseActivity(ByRef macro, mode := 0) {	;// Initializes/toggles the hotkeys needed for tracking mouse activity
	if (mode) {
		func := Func("recordMouseMacro").Bind("LButton", macro)
		Hotkey, ~LButton, % func, On
		func := Func("recordMouseMacro").Bind("RButton", macro)
		Hotkey, ~RButton, % func, On
		func := Func("recordMouseMacro").Bind("MButton", macro)
		Hotkey, ~MButton, % func, On ;// Technically, WheelUp and WheelDown should also be in here, but they never get used anyway
		return
	}
	else {
		Hotkey, ~LButton, Off
		Hotkey, ~MButton, Off
		Hotkey, ~RButton, Off
	}
}

;//		CODE GENERATING FUNCTIONS

genMacroCode(macro) {	;// Simply loops over the object and makes readable code from it.
	code := ""
	for Index, Element in macro
		code .= createCodeAction(Element)
	FormatTime, t,, dd.MM.yyyy`, HH:mm:ss
	code := "^Insert::	`; Automatic Hotkey generated " . t . "`n" . "Loop, 1 {`n" . code . "}`nreturn`n"
	createCodeAction(0, -1) ;// reset prevTicks so we can record a new macro later
	return code
}

createCodeAction(action, mode := 0) {	;// Keeps track of ticks for "Sleep, x" for timing.
	static prevTicks
	if (mode = -1) {
		prevTicks := 0
		return
	}
	if !(prevTicks) {
		prevTicks := action.Time
		return A_Tab . makeLine(action) . "`n"
	}
	sleepTime := action.Time - prevTicks
	prevTicks := action.Time
	return A_Tab . "Sleep, " . sleepTime . "`n" . A_Tab . makeLine(action) . "`n"
}

makeLine(action) {	;// Converts a single action as given by keys/clicks/coordinates into a line of code
	if (RegExMatch(action.Button, "(LButton|RButton|MButton)"))
		return "MouseClick, " . SubStr(action.Button, 1,1) . ", " . action.x . ", " . action.y
	specialKeys := "(Space|Tab|CapsLock|Enter|Return|Backspace|Escape|Home|End|PgUp|PgDn|Insert|Delete|ScrollLock|PrintScreen|Pause|Up|Down|Left|Right|NumpadDiv|NumpadMult|NumpadSub|NumpadAdd|NumpadEnter|NumLock|Ctrlbreak|F[0-9]+|Numpad[0-9])"
	keys := action.Button
	keys := RegExReplace(keys, specialKeys, "`{$1`}" )
	return "Send, " . keys
}

contractCode(macroCode, contractTime) {	;// Chains multiple "Send" into one, Chains multiple "MouseClick" on the same coordinates into one (with a given time)
	newCode := ""
	count := 1
	Loop, Parse, macroCode, `n 
	{
		line := Trim(A_LoopField)
		if (RegexMatch(line, "O)Sleep, (\d+)", contraction)) {
			if (contraction.Value(1) < contractTime) {
				continue
			}
		}
		if (pLine) {
			if (SubStr(line, 1, 2) = pLine) {
				if (pLine = "Se") {
					newCode .= SubStr(line, 7)
					continue
				}
				else if (pLine = "Mo") {
					RegexMatch(line, "O)MouseClick, (.), (\d+), (\d+)", cLineMouse)
					if (pLineMouse.Value(1) = cLineMouse.Value(1) && Abs(pLineMouse.Value(2) - cLineMouse.Value(2)) < 8 && Abs(pLineMouse.Value(3) - cLineMouse.Value(3)) < 8) {
						count += 1
						continue
					}
				}
			}
		}
		if (pLine = "Mo" && count > 1) {
			newCode .= ", " . count
			count := 0
		}
		newCode .= "`n" . A_LoopField ;// Add `n if its a new line type / different coordinate click. This will *only* trigger on noncontractables. 
		pLine := SubStr(line, 1, 2) ;// Get first two letters, these will always be "Mo" or "Se" or "Sl" (or "Wi")
		if (pLine = "Mo") {
			RegexMatch(line, "O)MouseClick, (.), (\d+), (\d+)", pLineMouse) ;// Get coordinates and button of mouse to store for next Loop Instance
		}
	}
	return SubStr(newCode, 2)
}

adjustSleepTime(macroCode, maxTime, newTime) {	;// replaces sleep times with new ones
	newCode := ""
	count := 1
	Loop, Parse, macroCode, `n 
	{
		if (RegexMatch(A_LoopField, "O)Sleep, (\d+)", sleepTime)) {
			if (sleepTime.Value(1) < maxTime) {
				newCode .= A_Tab . "Sleep, " . (newTime = -1 ? (sleepTime.Value(1) < 50 ? 50 : Round(sleepTime.Value(1), -2)): newTime) . "`n"
				continue
			}
		}
		newCode .= A_LoopField . "`n" ;// Add `n if its a new line type / different coordinate click
	}
	return newCode
}

;// 	HELP FUNCTIONS

compareKeys(firstKeyMods, firstKey, secondKey) {	;// Compares two hotkeys, one with given modifiers and key distinction, one without. 
	if (StrLen(firstKeyMods)+StrLen(firstKey) = StrLen(secondKey))
		if (SubStr(secondKey, -StrLen(firstKey)+1) = firstKey) {
			secMods := SubStr(secondKey, 1, StrLen(firstKey))
			Loop, Parse, firstKeyMods 
				if !(InStr(secMods, A_LoopField))
					return 0
			return 1
		}
	return 0
}

;// 	GUI STUFF

createMacroGenGUI(macroCode) {	;// Creates the actual GUI to display the code in.
	resetMacroCode := Func("resetCode").Bind(macroCode)
	Gui, macroGen:New, +Border +OwnDialogs
	Gui, macroGen:Add, Button, Section gContractSend, Contract all "Send"
	Gui, macroGen:Add, Button, ys xp+110 greplaceSleepTime, Norm all SleepTimers
	Gui, macroGen:Add, Button, ys xp+120 gAddCodeToScript, Add Code to Script
	Gui, macroGen:Add, Button, xs, Reset to original Code
	Gui, macroGen:Add, Edit, xs vCode r30 w500 WantTab WantReturn, if you read this you suck
	GuiControl, macroGen:, Code, %macroCode%
	GuiControl, macrogen:+g, Reset to original Code, %resetMacroCode%
	Gui, macroGen:Show, AutoSize, Macro Generator
}

resetCode(macroCode) {
	GuiControl, macroGen:, Code, % macroCode
}

ContractSend() {	;// Pressing the "Contract Code" Button
	global Code
	Gui, macroGen:Submit, NoHide
	InputBox, d, Ignored SleepTime, Specify the time under which Commands will be chained together,,,,,,,,100
	if ErrorLevel
		return
	if d is not integer
	{
		MsgBox, Not a valid entry.
		return
	}
	GuiControl, macroGen:, Code, % contractCode(Code, d)
}

replaceSleepTime() {
	global Code
	Gui, macroGen:Submit, NoHide
	InputBox, d, Norm SleepTime, Specify the time under which Sleeps will be normed,,,,,,,,5000
	if ErrorLevel
		return
	if d is not integer
	{
		MsgBox, Not a valid entry.
		return
	}
	InputBox, e, Norm SleepTime, Specify what time the Sleeps should be normed to`nEnter -1 for rounding to the nearest 1/10s,,,,,,,,75
	if ErrorLevel
		return
	if e is not integer
	{
		MsgBox, Not a valid entry.
		return
	}
	GuiControl, macroGen:, Code, % adjustSleepTime(Code, d, e)
}

AddCodeToScript() {
	global Code
	Gui, macroGen:Submit, NoHide
	hotkey := SubStr(Code, 1, InStr(Code, "::")-1)
	if(StrLen(hotkey) < 2)
		MsgBox, 0, No Hotkey found.
	if (hotkey="^Insert")
		msgBoxtext := "DEFAULT Hotkey`n	" . hotkey . "`nto the script.`nProceed Anyway?"
	else
		msgBoxtext := "Hotkey`n	" . hotkey . "`nto the script.`nProceed?"
	MsgBox, 4, Add to Script, % "This will add the recorded Macro with the " . msgBoxtext ;// 4 = Yes/No
	IfMsgBox Yes
		FileAppend, `n%Code%, %A_ScriptFullPath%
	else 
		return
	MsgBox, 4, Reload?, Added to script. Reload?
	IfMsgBox Yes
	{
		if IsFunc("reload") {
			fn := Func("reload")
			fn.call()
		}
		else
			Reload
	}
	return
}

macroGenGuiEscape() {	;// Close GUI with escape
	macroGenGuiClose()
}

macroGenGuiClose() {	;// Close GUI
	MsgBox, 1, Delete macro?, % "Close GUI and delete recording?"
	IfMsgBox OK
		Gui, macroGen:Destroy
}


