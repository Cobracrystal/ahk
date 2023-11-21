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

class ReminderManager {
	static controls
	static settings
	static timerList
	static discordBot
	
	ReminderManagerGUI(mode := "O") {
		mode := SubStr(mode, 1, 1)
		if (WinExist("ahk_id " . this.controls.guiMain.handle)) {
			if (mode == "O") ; if gui exists and mode = open, activate window
				WinActivate, % "ahk_id " . this.controls.guiMain.handle
			else {	; if gui exists and mode = close/toggle, close
				this.controls.guiMain.coords := windowGetCoordinates(this.controls.guiMain.handle)
				Gui, ReminderManager:Destroy
				this.controls.guiMain.handle  := ""
			}
		}
		else if (mode != "C") ; if gui doesn't exist and mode = open/toggle, create
			this.controls.guiMain.handle := this.guiCreate() 
	}
	
	initialize(flagDebug := 0, flagLoad := 0, discordToken := "", guiPosX := 565, guiPosY := 300) {
		; Tray Menu
		tObj := this.ReminderManagerGUI.Bind(this)
		if (!this.settings.initialized) {
			Menu, GUIS, Add, Open Reminder Handler, % tObj
			Menu, Tray, Add, GUIs, :GUIS
			Menu, Tray, NoStandard
			Menu, Tray, Standard
		}
		; init class variables
		; this format is necessary to establish objects.
		this.controls := {"guiMain": {"text": "Reminder Manager", "coords": [guiPosX, guiPosY]}}
		this.settings := {"initialized": 1, "flagDebug": flagDebug, "flagLoad": flagLoad}
		this.timerList := {}
		if (discordToken != 0)
			this.discordBot := new DiscordClient(discordToken)
		if (flagLoad) 
			; load reminders from file in appdata or smth.
			msgbox not implemented lol
	}
		
	setSingleTimerIn(days := 0, hours := 0, minutes := 0, seconds := 0, function := "", message := "") {
		if (this.settings.flagDebug)
			msgbox % "func " . function "`n" . "message " . message "`n" . "days " . days "`n" . "h " . hours "`n" . "mins " . minutes "`n" . "secs " . seconds
		if (days < 0 || hours < 0 || minutes < 0 || seconds < 0)
			return 0
		tC := A_Now
		EnvAdd, tC, days, Days
		EnvAdd, tC, hours, Hours
		EnvAdd, tC, minutes, Minutes
		EnvAdd, tC, seconds, Seconds
		return this.setSpecificTimer(function,message,,,SubStr(tC,9,2),SubStr(tC,11,2),SubStr(tC,13,2),SubStr(tC,7,2),SubStr(tC,5,2))
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
				if day is alpha
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
			day := (day == -1 ? 1 : day)
			hours := (hours == -1 ? 0 : hours) ; if month is set, alarm at 1.[month] at 00:00:00
		}
		minutes := (minutes == -1 ? 0 : minutes)
		seconds := (seconds == -1 ? 0 : seconds)
		
		tStamp := this.validateTime(month, day, hours, minutes, seconds)
		if !(tStamp)
			throw Exception("Timestamp is invalid")
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
			throw Exception("Time comparison was blank")
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
		if tS is not time
			return 0
		else
			return tS
	}
	
	compareTime(timestamp) {
		EnvSub, timestamp, A_Now, seconds
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
		message := "It is " . FormatTimeFunc("L1033","dddd, dd.MM.yyyy, HH:mm:ss") . "`nYou set a reminder for this point in time.`nReminder Message: "
		if (text == "")
			message .= "None (No reminder message set)"
		else
			message .= text
		SoundPlay *48
		MsgBox,, Reminder, % message
		return
	}
	
	discordReminder(text, id) {
		FormatTime, temp, L1033, dddd, dd.MM.yyyy, HH:mm:ss ; L1033 -> en-US for day name.
		message := "It is " . temp . "`nYou set a reminder for this point in time.`nReminder Message: "
		if (text == "")
			message .= "None (No reminder message set)"
		else
			message .= text
		this.discordBot.sendMessage(message, id, 1)
	}
	
	multiUseTimerRestarter(period, funcObj) {
		SetTimer, % funcObj, % period
	}
	
	addToTimerList(reminder) {
		this.timerList.push(reminder)
		return
	}
	
	getTimerList() {
		return this.timerList
	}

	guiCreate() {
		Gui, ReminderManager:New, % "+Border +HwndguiHandle +Label" . this.__Class . ".__on"
		Gui, ReminderManager:Submit, NoHide
		Gui, ReminderManager:Add, GroupBox, Section w425 h90, Add Reminder in
			Gui, Font, s9 Norm
			Gui, ReminderManager:Add, Text, Center ys+22 xs+10, Remind me in 
			Gui, ReminderManager:Add, Edit, vNewReminderTimeDays ys+20 x+5 r1 w30
			Gui, ReminderManager:Add, Text, Center ys+22 x+5, d
			Gui, ReminderManager:Add, Edit, vNewReminderTimeHours ys+20 x+5 r1 w30
			Gui, ReminderManager:Add, Text, Center ys+22 x+5, h
			Gui, ReminderManager:Add, Edit, vNewReminderTimeMinutes ys+20 x+5 r1 w30
			Gui, ReminderManager:Add, Text, Center ys+22 x+5, m 
			if (this.settings.flagDebug) {
				Gui, ReminderManager:Add, Edit, vNewReminderTimeSeconds ys+20 x+5 r1 w30
				Gui, ReminderManager:Add, Text, Center ys+22 x+5, s
			}
			Gui, ReminderManager:Add, Text, Center ys+22 x+5, with the following message:
			Gui, ReminderManager:Add, Edit, vNewReminderMessage ys+47 xs+10 r2 w375
		Gui, ReminderManager:Add, Button, ys+5 h60 w80 Default HwndcHandle, Add Reminder
			gHandle := this.createReminderFromGUI.bind(this, 1)
			GuiControl +g, % cHandle, % gHandle
		
		Gui, ReminderManager:Add, GroupBox, xs Section w425 h90, Add Reminder on
			Gui, Font, s9 Norm
			Gui, ReminderManager:Add, Text, Center ys+22 xs+10, Remind me on
			Gui, ReminderManager:Add, Edit, vNewReminderDateDay ys+20 x+5 r1 w30
			Gui, ReminderManager:Add, Text, Center ys+22 x+5, .
			Gui, ReminderManager:Add, Edit, vNewReminderDateMonth ys+20 x+5 r1 w30
			Gui, ReminderManager:Add, Text, Center ys+22 x+5, `, at
			Gui, ReminderManager:Add, Edit, vNewReminderDateHour ys+20 x+5 r1 w30
			Gui, ReminderManager:Add, Text, Center ys+22 x+5, :
			Gui, ReminderManager:Add, Edit, vNewReminderDateMinute ys+20 x+5 r1 w30
			if (this.settings.flagDebug) {
				Gui, ReminderManager:Add, Text, Center ys+22 x+5, :
				Gui, ReminderManager:Add, Edit, vNewReminderDateSecond ys+20 x+5 r1 w30
			}
			Gui, ReminderManager:Add, Text, Center ys+22 x+5, with the following message:
			Gui, ReminderManager:Add, Edit, vNewReminderMessageOn ys+47 xs+10 r2 w375
		Gui, ReminderManager:Add, Button, ys+5 h60 w80 Default HwndcHandle, Add Reminder
			gHandle := this.createReminderFromGUI.bind(this, 2)
			GuiControl +g, % cHandle, % gHandle
	; list of reminders to manage: TODO
	;	Gui, ReminderManager:Add, ListView
		Gui, ReminderManager:Show, % Format("x{1}y{2} Autosize", this.controls.guiMain.coords[1], this.controls.guiMain.coords[2]), % this.controls.guiMain.text
		return guiHandle
	}
	
	__onEscape() {
		ReminderManager.ReminderManagerGUI("Close")
	}
	
	__onClose() {
		ReminderManager.ReminderManagerGUI("Close")
	}
		
	createReminderFromGUI(button) {
		global NewReminderTimeDays
		global NewReminderTimeHours
		global NewReminderTimeMinutes
		global NewReminderTimeSeconds
		global NewReminderDateDay
		global NewReminderDateMonth
		global NewReminderDateHour
		global NewReminderDateMinute
		global NewReminderDateSecond
		global NewReminderMessage
		global NewReminderMessageOn
		Gui, ReminderManager:Submit, NoHide
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
			f := this.setSpecificTimer(,NewReminderMessageOn,,, NewReminderDateHour, NewReminderDateMinute, NewReminderDateSecond, NewReminderDateDay, NewReminderDateMonth)
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
				GuiControl, ReminderManager:, NewReminderMessageOn, % ""		
			}
		}
		return 1
	}

}

1337reminder(message) {
	; SetTimer, 1337reminder, % (24*3600)*1000
	SoundPlay *48
	MsgBox, 1, The Time has come., 1337! Copy 1337 in clipboard and activate discord?
	IfMsgBox, Cancel
		return
	Clipboard := "1337"
	ClipWait 0
	If WinExist("ahk_exe discord.exe")
		WinActivate, ahk_exe discord.exe
}
