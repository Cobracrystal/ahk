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

class ReminderManager {
	static Call(flagDebug := 0, flagLoad := 0) {
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
		if (IsTime(time))
			throw Error("Invalid Timestamp: " . time)
		timeDiff := DateDiff(time, A_Now, "Seconds")
		if (timeDiff < 0) {
			switch periodUnit, 0 {
				case "Seconds", "S", "Minutes", "M", "Hours", "H", "Days", "D":
					secs := DateDiff("1998", DateAdd("1998", period, periodUnit), "Seconds")
					timeDiff := Mod(timeDiff, secs) + secs
				case "Weeks", "W":
					secs := DateDiff("1998", DateAdd("1998", period*7, "D"), "Seconds")
					timeDiff := Mod(timeDiff, secs) + secs
				case "Years", "Y":
					; YEAR DIFFERENCE? eg. given 2020 leap day, year period of 7 -> 2027. + 1 day?
					; what if given 2020-10-17, with 3 year period -> 2023-10-17 is over -> use 2026 ! ?
					nextTimestamp := (SubStr(time, 1, 4)+value) . SubStr(dateTime, 5)
					if !IsTime(nextTimestamp) ; leap day
						nextTimestamp := DateAdd(nextTimestamp, 1, "D")
					return nextTimestamp
				case "Months", "Mo":
					YMo := SubStr(dateTime, 1, 4) + (value//12) . Format("{:02}", Mod(SubStr(dateTime, 5, 2) + Mod(value, 12) - 1, 12)+1)
					msgbox(YMo)
					return DateAdd(dateTime, DateDiff(YMo, SubStr(dateTime, 1, 6), "D"), "D")
				default:
					return 0
			}
		}
		if (function is Func && function.MaxParams > 0)
			function := function.Bind(message)
		else
			function := this.defaultReminder.Bind(this, message)
		nextTimeMS := (timeDiff == 0 ? -1 : timeDiff * -1000)
		if (period <= 0)
			return 0
		SetTimer(this.restartTimer.bind(this, period, periodUnit, function), nextTimeMS)
		SetTimer(function, nextTimeMS)
	}


	restartTimer(period, periodUnit, function) {
		nextOccurence := this.DateAddW(A_Now, period, periodUnit)
		nextTimeMS := 1000 * DateDiff(A_Now, nextOccurence, "Seconds")
		SetTimer(,0)
		SetTimer(this.restartTimer.bind(this, period, periodUnit, function), nextTimeMS)
		function()
	}
	/*
	* Extended version of DateAdd, allowing Weeks (W), Months (MO), Years (Y) for timeUnit. Returns YYYYMMDDHH24MISS timestamp
	* @param periodUnit Time Unit can be one of the strings (or their first letter): Years, Weeks, Days, Hours, Minutes, Seconds NOT months because that's bad
	* Remark: Adding years to a leap day will result in the corresponding day number of the resulting year (29-02-2024 + 1 Year -> 30-01-2025)
	* Similarly, if a resulting month does not have as many days as the starting one, the result will be rolled over (31-10-2024 + 1 Month -> 01-12-2024)
	*/
	DateAddW(dateTime, value, timeUnit) {
		switch timeUnit, 0 {
			case "Seconds", "S", "Minutes", "M", "Hours", "H", "Days", "D":
				return DateAdd(dateTime, value, timeUnit)
			case "Weeks", "W":
				return DateAdd(dateTime, value*7, "D")
			case "Years", "Y":
				nextTimestamp := (SubStr(dateTime, 1, 4)+value) . SubStr(dateTime, 5)
				if !IsTime(nextTimestamp) ; leap day
					nextTimestamp := DateAdd(nextTimestamp, 1, "D")
				return nextTimestamp
			case "Months", "Mo":
				YMo := SubStr(dateTime, 1, 4) + (value//12) . Format("{:02}", Mod(SubStr(dateTime, 5, 2) + Mod(value, 12) - 1, 12)+1)
				msgbox(YMo)
				return DateAdd(dateTime, DateDiff(YMo, SubStr(dateTime, 1, 6), "D"), "D")
			default:
				return 0
		}
	}

	/*
	* Given a set of time parts, returns a YYYYMMDDHH24MISS timestamp of the next time when all given parts matchs 
	*/
	parseTime(years, months, days, hours, minutes, seconds) {

	}

	setSpecificTimer(function := "", message := "", multiReminder := 0, period := -1, hours := -1, minutes := -1, seconds := -1, day := -1, month := -1, target := "") {
		flagWeekly := 0
		largestSetUnit := "Minute"
		if (month == -1) {
			month := A_MM
			if (day == -1) {
				day := A_DD
				if (hours == -1) {
					hours := A_Hour
					if (minutes == -1)
						return 0
				}
				else
					largestSetUnit := "Hour"
			}
			else {
				if IsAlpha(day)
				{
					day := this.enumerateDay(day)
					if (day == -1)
						return 0
					flagWeekly := 1
				}
				hours := (hours == -1 ? 7 : hours) ; if month is not set but day, put it as 7:00:00
				largestSetUnit := "Day"
			}
		}
		else {
			largestSetUnit := "Month"
			day := (day == -1 ? 1 : day) ; day ?? 1, use unset instead of -1
			hours := (hours == -1 ? 0 : hours) ; if month is set, alarm at 1.[month] at 00:00:00
		}
		minutes := (minutes == -1 ? 0 : minutes)
		seconds := (seconds == -1 ? 0 : seconds)
		
		tStamp := this.validateTime(month, day, hours, minutes, seconds)
		if !(tStamp)
			throw Error("Timestamp is invalid")
		timeDiff := this.compareTime(tStamp)
		msgboxStr := Format("First Guess:`nTimestamp: {} (Reminder on {:02}.{:02}, {:02}:{:02}:{:02})`nTime Difference: {}", tStamp, day, month, hours, minutes, seconds, timeDiff) . ( timeDiff < 0 ? " (invalid)" : Format(" (Reminder in {:02}:{:02}:{:02})", timeDiff//3600, mod(timeDiff,3600)//60, mod(timeDiff,60)) )
		if (timeDiff < 0) {
			switch largestSetUnit {
				case "Month":
					tStamp := (A_YYYY +1) . SubStr(tStamp, 5)
				case "Day":
					if (flagWeekly)
						EnvAdd, tStamp, 7, Days
					else
						tStamp := (A_YYYY +1) . SubStr(tStamp, 5) ; you can't "add a month" cause months have varying lengths, and monthly reminders aren't a thing
				case "Hour":
					EnvAdd, tStamp, 1, Days
				case "Minute":
					EnvAdd, tStamp, 1, Hours
			}
			timeDiff := this.compareTime(tStamp)
			msgBoxStr .= Format("`nSecond Guess:`nTimestamp: {} (Reminder on {})`nTime Difference: {} (Reminder in {:02}:{:02}:{:02})", tStamp, formatTimeFunc(tStamp,"dd.MM, HH:mm:ss") , timeDiff, timeDiff//3600, mod(timeDiff,3600)//60, mod(timeDiff,60))
		}
		if (timeDiff == "")
			throw Error("Time comparison was blank")
		nextTimeMS := this.getTimeStampinMS(timeDiff)
		if (this.settings.flagDebug)
			msgbox % msgBoxStr . "`nMilliseconds until Reminder: " . nextTimeMS
		if (function != "") {
			if (function == "discordReminder" && target != "")
				reminderFunc := this.discordReminder.Bind(this, message, target)
			else if (IsFunc(function) == 2)
				reminderFunc := Func(function).Bind(message)
			else 
				reminderFunc := this.defaultReminder.Bind(this, message)
		}
		else 
			reminderFunc := this.defaultReminder.Bind(this, message)
		SetTimer, % reminderFunc, % nextTimeMS
		if (multiReminder) {
			if (period <= 0)
				return 0
			multiUseRestarterFuncObj := this.multiUseTimerRestarter.Bind(this, period * 1000, reminderFunc)
			SetTimer, % multiUseRestarterFuncObj, % nextTimeMS
		}
		return 1
		; return codes: 1 success, 0 failure
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
	
	validateTime(month, day, hours, minutes, seconds) {
		month := Format("{:02}", month)
		day := Format("{:02}", day)
		hours := Format("{:02}", hours)
		minutes := Format("{:02}", minutes)
		seconds := Format("{:02}", seconds)
		; validate timestamp:
		tS := A_YYYY . month . day . hours . minutes . seconds
		if (IsTime(tS))
			return tS
		return 0
	}
	
	compareTime(timestamp) {
		return DateDiff(A_Now, timestamp, "Seconds")
		return timestamp
	}
	
	getTimeStampinMS(timestamp) {
		nextTimeMS := timestamp * 1000
		if (nextTimeMS == 0)
			nextTimeMS := 1
		return "-" . nextTimeMS
	}
	
	defaultReminder(text) {
	;	L1033 -> en-US for day name.
		message := "It is " . FormatTime("L1033 dddd, dd.MM.yyyy, HH:mm:ss") . "`nYou set a reminder for this point in time."
		message .= (text == "" ? "" : "`nReminder Message: " . text) 
		SoundPlay("*48")
		MsgBox(message, "Reminder")
		return
	}
	
	
	multiUseTimerRestarter(period, funcObj) {
		SetTimer(funcObj, period)
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