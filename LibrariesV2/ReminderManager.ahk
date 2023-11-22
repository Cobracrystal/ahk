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
	static __New(flagDebug := 0, flagLoad := 0) {
		if (!this.settings.initialized) {
			guiMenu := TrayMenu.submenus["GUIs"]
			guiMenu.Add("Open Reminder Manager", this.reminderManagerGUI.Bind(this))
			A_TrayMenu.Add("GUIs", guiMenu)
		}
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
		this.gui.AddGroupBox("Section w425 h90", "Add Reminder in")
			this.gui.SetFont("s9")
			this.gui.AddText("Center ys+22 xs+10", "Remind me in ")
			this.gui.AddEdit("vNewReminderTimeDays ys+20 x+5 r1 w30")
			this.gui.AddText("Center ys+22 x+5", "d")
			this.gui.AddEdit("vNewReminderTimeHours ys+20 x+5 r1 w30")
			this.gui.AddText("Center ys+22 x+5", "h")
			this.gui.AddEdit("vNewReminderTimeMinutes ys+20 x+5 r1 w30")
			this.gui.AddText("Center ys+22 x+5", "m ")
			if (this.settings.flagDebug) {
				this.gui.AddEdit("vNewReminderTimeSeconds ys+20 x+5 r1 w30")
				this.gui.AddText("Center ys+22 x+5", "s")
			}
			this.gui.AddText("Center ys+22 x+5", "with the following message:")
			this.gui.AddEdit("vNewReminderMessage ys+47 xs+10 r2 w375")
		this.gui.AddButton("ys+5 h60 w80 Default", "Add Reminder").OnEvent("Click", this.createReminderFromGUI.bind(this))
		this.gui.AddGroupBox("xs Section w425 h90", "Add Reminder on")
			this.gui.SetFont("s9")
			this.gui.AddText("Center ys+22 xs+10", "Remind me on")
			this.gui.AddEdit("vNewReminderDateDay ys+20 x+5 r1 w30")
			this.gui.AddText("Center ys+22 x+5", ".")
			this.gui.AddEdit("vNewReminderDateMonth ys+20 x+5 r1 w30")
			this.gui.AddText("Center ys+22 x+5", ", at")
			this.gui.AddEdit("vNewReminderDateHour ys+20 x+5 r1 w30")
			this.gui.AddText("Center ys+22 x+5", ":")
			this.gui.AddEdit("vNewReminderDateMinute ys+20 x+5 r1 w30")
			if (this.settings.flagDebug) {
				this.gui.AddText("Center ys+22 x+5", ":")
				this.gui.AddEdit("vNewReminderDateSecond ys+20 x+5 r1 w30")
			}
			this.gui.AddText("Center ys+22 x+5", "with the following message:")
			this.gui.AddEdit("vNewReminderMessage2 ys+47 xs+10 r2 w375")
		this.gui.AddButton("ys+5 h60 w80 Default", "Add Reminder").OnEvent("Click", this.createReminderFromGUI.bind(this, 2))
	; list of reminders to manage: TODO
	;	this.gui.AddListView()
		this.gui.Show(Format("x{1}y{2} Autosize", this.data.coords[1], this.data.coords[2]))
	}

	setTimerIn(seconds := 0, minutes := 0, hours := 0, days := 0, function := this.defaultReminder, message := "") {
		if (this.settings.flagDebug)
			msgbox(Format("Message: {1}`nDays: {2}`nHours: {3}`nMinutes: {4}`nSeconds: {5}", message, days, hours, minutes, seconds))
		if (days < 0 || hours < 0 || minutes < 0 || seconds < 0)
			return 0
		time := DateAdd(A_Now, days, "Days")
		time := DateAdd(time, hours, "Hours")
		time := DateAdd(time, minutes, "Minutes")
		time := DateAdd(time, seconds, "Seconds")
		return this.setTimerOn(time, function, message, 0, -1)
	}
	
	; function -> any func object accepting at least one "message" parameter
	setTimerOn(time, message := "", function := this.defaultReminder) {
		if (!IsTime(time))
			throw Error("Invalid Timestamp given: " . time)
		timeDiff := DateDiff(time, A_Now, "Seconds")
		if (timeDiff < 0)
			throw Error("Cannot create Reminder in the Past: " time " is " timeDiff * -1 "seconds in the past.")
		nextTimeMS := (timeDiff == 0 ? -1 : timeDiff * -1000)
		if (function is Func && function.MaxParams > 0)
			function := function.Bind(message)
		else
			function := this.defaultReminder.Bind(this, message)
		SetTimer(function, nextTimeMS)
		return 1
	}

	/*
	* sets a timer with given period after a given time
	* @param time year, month, day, hour, minute, second. If omitted, defaults to next instance of largest set units.
	* @param period Integer period in which the timer will repeat
	* @param periodUnit Time Unit can be one of the strings (or their first letter): Years, Weeks, Days, Hours, Minutes, Seconds
	*/
	setPeriodicTimerOn(time, period, periodUnit := "Seconds", message := "", function := this.defaultReminder) {
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
		if (function is Func && function.MaxParams > 0)
			function := function.Bind(message)
		else
			function := this.defaultReminder.Bind(this, message)
		SetTimer(this.restartTimer.bind(this, period, periodUnit, function), nextTimeMS)
		SetTimer(function, nextTimeMS)
	}

	restartTimer(period, periodUnit, function) {
		nextOccurence := this.DateAddW(A_Now, period, periodUnit)
		nextTimeMS := 1000 * DateDiff(A_Now, nextOccurence, "Seconds")
		SetTimer(,0) ; fix this by accessing a list in data
		SetTimer(this.restartTimer.bind(this, period, periodUnit, function), nextTimeMS)
		function()
	}

		
	enumerateDay(day) {
		d := Substr(day,1,2)
		switch d {
			case "mo":
				day := 2
			case "di","tu":
				day := 3
			case "mi","we":
				day := 4
			case "do","th":
				day := 5
			case "fr":
				day := 6
			case "sa":
				day := 7
			case "so","su":
				day := 1
			default:
				return -1
		}
		return A_DD - A_WDAY + day
	}
		
	defaultReminder(text) {
	;	L1033 -> en-US for day name.
		message := "It is " . FormatTime("L1033 dddd, dd.MM.yyyy, HH:mm:ss") . "`nYou set a reminder for this point in time."
		message .= (text == "" ? "" : "`nReminder Message: " . text) 
		SoundPlay("*48")
		MsgBox(message, "Reminder")
		return
	}
		
	createReminderFromGUI(button) {
		Gui, ReminderManager:Submit, NoHide
		this.gui.Submit(false)
		if !(NewReminderMessage ) {
			MsgBox, 1, Confirm, % "You have not set a reminder message. Proceed?"
			IfMsgBox, Cancel
				return
		} ; ??????????????????????????????????????????????? WHAT ABOUT THE OTHER REMINDER MESSAGE
		if (button == 1) {
			NewReminderTimeDays := (NewReminderTimeDays ? NewReminderTimeDays : 0)
			NewReminderTimeHours := (NewReminderTimeHours ? NewReminderTimeHours : 0)
			NewReminderTimeMinutes := (NewReminderTimeMinutes ? NewReminderTimeMinutes : 0)
			NewReminderTimeSeconds := (NewReminderTimeSeconds ? NewReminderTimeSeconds : 0)
			f := this.setSingleTimerIn(NewReminderTimeDays, NewReminderTimeHours, NewReminderTimeMinutes, NewReminderTimeSeconds, ,NewReminderMessage)
			if (!f) {
				msgbox % "Problem setting the Reminder. Check if entered time is valid."
				return 0
			}
			else {
				timedTooltip("Success!", 1000)
				GuiControl, ReminderManager:, NewReminderTimeDays, % ""
				GuiControl, ReminderManager:, NewReminderTimeHours, % ""
				GuiControl, ReminderManager:, NewReminderTimeMinutes, % ""
				GuiControl, ReminderManager:, NewReminderTimeSeconds, % ""
				GuiControl, ReminderManager:, NewReminderMessage, % ""		
			}
		}
		else if (button == 2) {
			NewReminderDateMonth := (NewReminderDateMonth ? NewReminderDateMonth : -1)
			NewReminderDateDay := (NewReminderDateDay ? NewReminderDateDay : -1)
			NewReminderDateHour := (NewReminderDateHour ? NewReminderDateHour : -1)
			NewReminderDateMinute := (NewReminderDateMinute ? NewReminderDateMinute : -1)
			NewReminderDateSecond := (NewReminderDateSecond ? NewReminderDateSecond : -1)
			f := this.setSpecificTimer(,NewReminderMessage2,,, NewReminderDateHour, NewReminderDateMinute, NewReminderDateSecond, NewReminderDateDay, NewReminderDateMonth)
			if (!f) {
				msgbox % "Problem setting the Reminder. Check if entered time is valid."
				return 0
			}
			else {
				timedTooltip("Success!", 1000)
				GuiControl, ReminderManager:, NewReminderDateMonth, % ""
				GuiControl, ReminderManager:, NewReminderDateDay, % ""
				GuiControl, ReminderManager:, NewReminderDateHour, % ""
				GuiControl, ReminderManager:, NewReminderDateMinute, % ""
				GuiControl, ReminderManager:, NewReminderDateSecond, % ""
				GuiControl, ReminderManager:, NewReminderMessage2, % ""		
			}
		}
		return 1
	}

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