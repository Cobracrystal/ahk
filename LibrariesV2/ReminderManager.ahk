; OPTION TO MAKE REMINDER MESSAGE A TOOLTIP.
; have text already inside the edit fields of the GUI. The method of both text and edit control is not a problem, its precisely what we want since blank content -> current date/hour whatever. Can't be hardcoded then tho.
; todo: manage reminders
; todo b: save reminders over multiple restarts in ini file.
; then just load those up on starting -> no need to call 1337 reminder everytime. tada
; for custom functions: add field to add a full function body. This gets added in customReminderFunctions.ahk in appdata folder, and main file gets inclusion.
; do a check if file is not already included. Include at the top
; GUI should have a function field.
; first however class needs to have an array storing all timers.

; OK SO FOR MISSED REMINDERS:
; WE SAVE THE CURRENT TIME ON EXIT / EVERY X MINUTES
; WHEN THE SCRIPT STARTS IT READS THAT TIME, IT CALCULATES THE TIMESPAN
; NOW IF A REMINDER IS SET FOR A DATE THAT LIES IN THAT TIMESPAN AKA IS SET IN THE PAST
; THEN IT TRIGGERS IMMEDIATELY
; ONLY FOR [LOADED] REMINDERS THO, WOULD BE BAD ON THE 4 AM OR 1337 REMINDER.

; REMOVE ALL GLOBAL VARIABLES, GUICONTROLGET CAN BE USED WITH HANDLES TO RETRIEVE CONTENT OF CONTROLS. USE this.settings TO STORE HANDLES, WORKS PERFECTLY.


/*
toggleTimer(timerFunc, delay := 1000) {
	static timerContainer := []
	if arrayContains(timerContainer, timerFunc) {
		arrayRemove(timerContainer, timerFunc)
		SetTimer, % timerFunc, Off
	}
	else {
		SetTimer, % timerFunc, % delay
		timerContainer.push(timerFunc)
	}
}
*/
#Include "%A_ScriptDir%\LibrariesV2\BasicUtilities.ahk"
#Include "%A_ScriptDir%\LibrariesV2\DiscordClient.ahk"

class ReminderManager {
	__New(flagDebug := 0, flagLoad := 0) {
		guiMenu := TrayMenu.submenus["GUIs"]
		guiMenu.Add("Open Reminder Manager", this.reminderManagerGUI.Bind(this))
		A_TrayMenu.Add("GUIs", guiMenu)
		this.data := {coords: [565, 300]}
		this.gui := -1
		this.settings := {initialized: 1, flagDebug: flagDebug, flagLoad: flagLoad}
		this.timerList := {}
		if (flagLoad)  {
			; load reminders from file in appdata or smth.
			msgbox("not implemented yet")
		}
		return this
	}

	reminderManagerGUI(mode := "O", *) {
		mode := SubStr(mode, 1, 1)
		if (WinExist(this.gui)) {
			if (mode == "O") ; if gui exists and mode = open, activate window
				WinActivate(this.gui.hwnd)
			else {	; if gui exists and mode = close/toggle, close
				this.data.coords := windowGetCoordinates(this.gui.hwnd)
				this.gui.destroy()
				this.gui := -1
			}
		}
		else if (mode != "C") ; if gui doesn't exist and mode = open/toggle, create
			this.guiCreate() 
	}

	guiCreate() {
		this.gui := Gui("+Border", "Reminder Manager")
		this.gui.OnEvent("Escape", (*) => this.reminderManagerGUI("Close"))
		this.gui.OnEvent("Close", (*) => this.reminderManagerGUI("Close"))
		; Gui, ReminderManager:New, % "+Border +HwndguiHandle +Label" . this.__Class . ".__on"
		this.gui.AddGroupBox("Section w400 h90", "Add Reminder in")
			this.gui.SetFont("s9")
			this.gui.AddText("Center ys+22 xs+10", "Remind me in ")
			this.gui.AddEdit("ys+20 x+5 r1 w30").Name := "rem1D"
			this.gui.AddText("Center ys+22 x+5", "d")
			this.gui.AddEdit("ys+20 x+5 r1 w30").Name := "rem1H"
			this.gui.AddText("Center ys+22 x+5", "h")
			this.gui.AddEdit("ys+20 x+5 r1 w30").Name := "rem1M"
			this.gui.AddText("Center ys+22 x+5", "m ")
			if (this.settings.flagDebug) {
				this.gui.AddEdit("ys+20 x+5 r1 w30").Name := "rem1S"
				this.gui.AddText("Center ys+22 x+5", "s")
			}
			this.gui.AddText("Center ys+22 x+5", "with the message:")
			this.gui.AddEdit("ys+47 xs+10 r2 w375").Name := "rem1Message"
		this.gui.AddButton("ys+5 h60 w80 Default", "Add Reminder").OnEvent("Click", this.createReminderFromGUI.bind(this, 1))
		this.gui.AddGroupBox("xs Section w400 h90", "Add Reminder on")
			this.gui.SetFont("s9")
			this.gui.AddText("Center ys+22 xs+10", "Remind me on")
			this.gui.AddEdit("ys+20 x+5 r1 w30").Name := "rem2D"
			this.gui.AddText("Center ys+22 x+5", ".")
			this.gui.AddEdit("ys+20 x+5 r1 w30").Name := "rem2Mo"
			this.gui.AddText("Center ys+22 x+5", ", at")
			this.gui.AddEdit("ys+20 x+5 r1 w30").Name := "rem2H"
			this.gui.AddText("Center ys+22 x+5", ":")
			this.gui.AddEdit("ys+20 x+5 r1 w30").Name := "rem2M"
			if (this.settings.flagDebug) {
				this.gui.AddText("Center ys+22 x+5", ":")
				this.gui.AddEdit("ys+20 x+5 r1 w30").Name := "rem2S"
			}
			this.gui.AddText("Center ys+22 x+5", "with the message:")
			this.gui.AddEdit("ys+47 xs+10 r2 w375").Name := "rem2Message"
		this.gui.AddButton("ys+5 h60 w80 Default", "Add Reminder").OnEvent("Click", this.createReminderFromGUI.bind(this, 2))
	; list of reminders to manage: TODO
	;	this.gui.AddListView()
		this.gui.Show(Format("x{1}y{2} Autosize", this.data.coords[1], this.data.coords[2]))
	}

	setTimerIn(seconds := 0, minutes := 0, hours := 0, days := 0, message := "", function := "") {
		if (this.settings.flagDebug)
			msgbox(Format("Message: {1}`nDays: {2}`nHours: {3}`nMinutes: {4}`nSeconds: {5}", message, days, hours, minutes, seconds))
		if (days < 0 || hours < 0 || minutes < 0 || seconds < 0)
			return 0
		time := DateAdd(A_Now, days, "Days")
		time := DateAdd(time, hours, "Hours")
		time := DateAdd(time, minutes, "Minutes")
		time := DateAdd(time, seconds, "Seconds")
		return this.setTimerOn(time, message, function)
	}
	
	; function -> any func object
	setTimerOn(time, message := "", function := "") {
		if (!IsTime(time))
			return 0
		;	throw Error("Invalid Timestamp given: " . time)
		timeDiff := DateDiff(time, A_Now, "Seconds")
		if (timeDiff < 0)
			return 0
		;	throw Error("Cannot create Reminder in the Past: " time " is " timeDiff * -1 "seconds in the past.")
		nextTimeMS := (timeDiff == 0 ? -1 : timeDiff * -1000)
		if !(function is Func)
			function := this.defaultReminder.Bind(this, message)
		SetTimer(function, nextTimeMS)
		return 1
	}

	/*
	* sets a timer with given period after a given time
	* @param time year, month, day, hour, minute, second. If omitted, defaults to next instance of largest set units.
	* @param period Integer period in which the timer will repeat
	* @param periodUnit Time Unit can be one of the strings (or their first letter): Years, Weeks, Days, Hours, Minutes, Seconds
	* @param function A function object that will be called when the reminder finishes
	*/
	setPeriodicTimerOn(time, period, periodUnit := "Seconds", message := "", function := "") {
		if (!IsTime(time))
			throw Error("Invalid Timestamp: " . time)
		if (period <= 0)
			throw Error("Invalid Period: " period)
		timeDiff := DateDiff(time, Now := A_Now, "Seconds")
		if (timeDiff < 0) {
			switch periodUnit, 0 {
				case "Seconds", "S", "Minutes", "M", "Hours", "H", "Days", "D":
					secs := DateDiff(DateAdd("1998", period, periodUnit), "1998", "Seconds")
					timeDiff := Mod(timeDiff, secs) + secs
				case "Weeks", "W":
					secs := DateDiff(DateAdd("1998", period*7, "D"), "1998", "Seconds")
					timeDiff := Mod(timeDiff, secs) + secs
				case "Months", "Mo":
					monthDiff := Mod((SubStr(time, 1, 4) - A_YYYY) * 12 + (SubStr(time, 5, 2) - A_MM), period)
					if (monthDiff == 0) {
						guessTime := A_YYYY . A_MM . SubStr(time, 7)
						if (!IsTime(guessTime)) {
							nextMonth := Format("{:02}", Mod(A_MM, 12) + 1)
							nextYear := A_YYYY + A_MM//12 ; technically unnecessary since when the fuck do we have an invalid december date
							rolledOverDays := Format("{:02}", SubStr(time, 7, 2) - DateDiff(nextYear . nextMonth, A_YYYY . A_MM, "D"))
							guessTime := nextYear . nextMonth . rolledOverDays . SubStr(time, 9)
							if (!IsTime(guessTime))
								throw Error("0xD37824 - This should never happen " . guessTime)
						}
						else if (DateDiff(guessTime, Now, "Seconds") < 0) {
							monthDiffFull := (A_YYYY - SubStr(time, 1, 4)) * 12 + A_MM - SubStr(time, 5, 2)
							guessTime := DateAddW(time, monthDiffFull + monthDiff + period, "Months")
						}
					}
					else {
						monthDiffFull := (A_YYYY - SubStr(time, 1, 4)) * 12 + A_MM - SubStr(time, 5, 2)
						guessTime := DateAddW(time, monthDiffFull + monthDiff + period, "Months")
					}
					timeDiff := DateDiff(guessTime, Now, "Seconds")
				case "Years", "Y":
					yearDiff := Mod(SubStr(time, 1, 4) - A_YYYY, period)
					if (yearDiff == 0) {
						guessTime := A_YYYY . SubStr(time, 5)
						if (!IsTime(guessTime)) ; if leap year
							guessTime := A_YYYY . SubStr(DateAdd(time, 1, "D"), 5)
						if (DateDiff(guessTime, Now, "Seconds") < 0)
							guessTime := DateAddW(time, A_YYYY - SubStr(time, 1, 4) + period, "Years")
					}
					else
						guessTime := DateAddW(time, A_YYYY - SubStr(time, 1, 4) + yearDiff + period, "Years")
					timeDiff := DateDiff(guessTime, Now, "Seconds")
				default:
					return
			}
		}
		nextTimeMS := (timeDiff == 0 ? -1 : timeDiff * -1000)
		if (nextTimeMS > 4294967295)
			throw Error("Integer Limit for Timers reached.")
		if !(function is Func)
			function := this.defaultReminder.Bind(this, message)
		SetTimer(this.restartTimer.bind(this, period, periodUnit, function), nextTimeMS)
	}

	; basicutilities ->

	restartTimer(period, periodUnit, function) {
		nextOccurence := DateAddW(A_Now, period, periodUnit)
		nextTimeMS := 1000 * DateDiff(A_Now, nextOccurence, "Seconds")
		SetTimer(,0) ; fix this by accessing a list in data
		SetTimer(this.restartTimer.bind(this, period, periodUnit, function), nextTimeMS)
		function()
	}
		
		
	createReminderFromGUI(reminderType, *) {
		guiContent := this.gui.Submit(false)
		if (reminderType == 1) {
			if !(guiContent.rem1Message) {
				if (MsgBox("You have not set a reminder message. Proceed?", "Reminder", 0x1) == "Cancel")
					return
			}
			days := guiContent.rem1D ? guiContent.rem1D : 0
			hours := guiContent.rem1H ? guiContent.rem1H : 0
			minutes := guiContent.rem1M ? guiContent.rem1M : 0
			if (this.settings.flagDebug)
				seconds := guiContent.rem1S ? guiContent.rem1S : 0

			res := this.setTimerIn(seconds, minutes, hours, days, guiContent.rem1Message)
			if (!res) {
				msgbox("Problem setting the Reminder. Check if entered time is valid.")
				return 0
			}
			else {
				timedTooltip("Success!", 1000)
				this.gui["rem1D"].Value := ""
				this.gui["rem1H"].Value := ""
				this.gui["rem1M"].Value := ""
				this.gui["rem1S"].Value := ""
				this.gui["rem1Message"].Value := ""
			}
		}
		else if (reminderType == 2) {
			if !(guiContent.rem2Message) {
				if (MsgBox("You have not set a reminder message. Proceed?", "Reminder", 0x1) == "Cancel")
					return
			}
			months := guiContent.rem2Mo ? guiContent.rem2Mo : unset
			days := guiContent.rem2D ? guiContent.rem2D : unset
			hours := guiContent.rem2H ? guiContent.rem2H : unset
			minutes := guiContent.rem2M ? guiContent.rem2M : unset
			if (this.settings.flagDebug)
				seconds := guiContent.rem2S ? guiContent.rem2S : unset
			try 
				res := this.setTimerOn(parseTime(,months?,days?,hours?,minutes?,seconds?), guiContent.rem2Message)
			catch Error {
				msgbox("Problem setting the Reminder. Check if entered time is valid.")
				return 0
			}
			timedTooltip("Success!", 1000)
			this.gui["rem2Mo"].Value := ""
			this.gui["rem2D"].Value := ""
			this.gui["rem2H"].Value := ""
			this.gui["rem2M"].Value := ""
			this.gui["rem2S"].Value := ""
			this.gui["rem2Message"].Value := ""
		}
		return 1
	}

	defaultReminder(text) {
	;	L1033 -> en-US for day name.
		message := "It is " . FormatTime("L1033 dddd, dd.MM.yyyy, HH:mm:ss") . "`nYou set a reminder for this point in time."
		message .= (text == "" ? "" : "`nReminder Message: " . text) 
		SoundPlay("*48")
		MsgBox(message, "Reminder")
		return
	}

	reminder1337(*) {
		; SetTimer, 1337reminder, % (24*3600)*1000
		SoundPlay("*48")
		if (MsgBox("Copy 1337 in clipboard and activate discord?", "1337", 0x1) == "Cancel")
			return
		A_Clipboard := 1337
		if (WinExist("ahk_exe discord.exe"))
			WinActivate("ahk_exe discord.exe")
	}
	
	discordReminder(token, id, text) {
		discordBot := DiscordClient(token)
		time := FormatTime("L1033 dddd, dd.MM.yyyy, HH:mm:ss") ; L1033 -> en-US for day name.
		message := "It is " . time . "`nYou set a reminder for this point in time."
		message .= (text == "" ? "" : "`nReminder Message: " . text)
		discordBot.sendMessage(message, id, 1)
	}
}
