ReminderManagerGuiPosX := 564
ReminderManagerGuiPosY := 300
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


; BINDING GUI CLOSE FUNCTIONS INSIDE A CLASS !!!! https://www.autohotkey.com/boards/viewtopic.php?t=64337
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

/*
asdasd := new ReminderManager()
asdasd.createReminder()
asdasd.deleteReminder()
asdasd.createGUI()
asdasd.closeGUI()
*/

class ReminderManager {
	static timerList
	static flagDebug
	static guiPosX
	static guiPosY
	static discordBot
	

	__New(flagDebug := 0, flagLoad := 0, discordToken := "", guiPosX := 350, guiPosY := 350) {
		this.timerList := {}
		this.guiPosX := guiPosX
		this.guiPosY := guiPosY
		this.flagDebug := flagDebug
		if (flagLoad)
			; load reminders from file in appdata or smth.
			msgbox not yet implemented tm
		if (discordToken != "")
			this.discordBot := new DiscordClient(discordToken)
		return this
	}
		
	setSingleTimerIn(days := 0,hours := 0,minutes := 0,seconds := 0, function := "", message := "", debug:=false) {
		msgbox % "func " . function "`n" . "message " . message "`n" . "days " . days "`n" . "h " . hours "`n" . "mins " . minutes "`n" . "secs " . seconds
		if (days < 0 || hours < 0 || minutes < 0 || seconds < 0)
			return 0
		tC := A_Now
		EnvAdd, tC, days, Days
		EnvAdd, tC, hours, Hours
		EnvAdd, tC, minutes, Minutes
		EnvAdd, tC, seconds, Seconds
		return this.setSpecificTimer(function,message,0,-1,SubStr(tC,9,2),SubStr(tC,11,2),SubStr(tC,13,2),SubStr(tC,7,2),SubStr(tC,5,2),debug)
	}
	
	setSpecificTimer(function := "", message := "", multiReminder := 0, period := -1, hours := -1, minutes := -1, seconds := -1, day := -1, month := -1, debug := false, target := "") {
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
		if (debug)
			msgbox % tStamp
		if !(tStamp)
			throw Exception("Timestamp is invalid")
		timeDiff := this.compareTime(tStamp)
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
		}
		if (debug)
			msgbox % timeDiff . " = " . Format("{:02}", timeDiff//3600) . ":" . Format("{:02}", mod(timeDiff,3600)//60) . ":" . Format("{:02}", mod(timeDiff,60))
		timeDiff := this.compareTime(tStamp)
		if (debug)
			msgbox % timeDiff . " = " . Format("{:02}", timeDiff//3600) . ":" . Format("{:02}", mod(timeDiff,3600)//60) . ":" . Format("{:02}", mod(timeDiff,60))
		if (timeDiff == "")
			throw Exception("Time comparison was blank")
		nextTimeMS := this.getTimeStampinMS(timeDiff)
		if (debug)
			msgbox % nextTimeMS
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
		FormatTime, temp, L1033, dddd, dd.MM.yyyy, HH:mm:ss ; L1033 -> en-US for day name.
		message := "It is " . temp . "`nYou set a reminder for this point in time.`nReminder Message: "
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

	guiCreate(ReminderManagerGuiPosX, ReminderManagerGuiPosY) {
		Gui, ReminderManager:New, +Border +HwndReminderManagerGuiHwnd ; +AlwaysOnTop
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
		if (this.flagDebug) {
			Gui, ReminderManager:Add, Edit, vNewReminderTimeSeconds ys+20 x+5 r1 w30
			Gui, ReminderManager:Add, Text, Center ys+22 x+5, s
		}
		Gui, ReminderManager:Add, Text, Center ys+22 x+5, with the following message:
		Gui, ReminderManager:Add, Edit, vNewReminderMessage ys+47 xs+10 r2 w375
		Gui, ReminderManager:Add, Button, ys+5 h60 w80 Default HwndReminderButton, Add Reminder
		fn := ReminderManager.createReminderFromGUI.bind(this, 1)
		GuiControl +g, %ReminderButton%, %fn%
		
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
		if (this.flagDebug) {
			Gui, ReminderManager:Add, Text, Center ys+22 x+5, :
			Gui, ReminderManager:Add, Edit, vNewReminderDateSecond ys+20 x+5 r1 w30
		}
		Gui, ReminderManager:Add, Text, Center ys+22 x+5, with the following message:
		Gui, ReminderManager:Add, Edit, vNewReminderMessageOn ys+47 xs+10 r2 w375
		Gui, ReminderManager:Add, Button, ys+5 h60 w80 Default HwndReminderButton, Add Reminder
		fn := ReminderManager.createReminderFromGUI.bind(this, 2)
		GuiControl +g, %ReminderButton%, %fn%
	; list of reminders to manage: TODO
	;	Gui, ReminderManager:Add, ListView
		Gui, ReminderManager:Show, x%ReminderManagerGuiPosX%y%ReminderManagerGuiPosY% Autosize, WindowList
		return ReminderManagerGuiHwnd
	}
	
	guiClose(hwnd) {
		ReminderManagerGuiClose(hwnd)
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
		if (button == 1) {
			if !(NewReminderMessage) {
				MsgBox, 1, Confirm, % "You have not set a reminder message. Proceed?"
				IfMsgBox, Cancel
					return
			}
			NewReminderTimeDays := (NewReminderTimeDays ? NewReminderTimeDays : 0)
			NewReminderTimeHours := (NewReminderTimeHours ? NewReminderTimeHours : 0)
			NewReminderTimeMinutes := (NewReminderTimeMinutes ? NewReminderTimeMinutes : 0)
			f := this.setSingleTimerIn(NewReminderTimeDays, NewReminderTimeHours, NewReminderTimeMinutes, 0, ,NewReminderMessage)
			if (!f)
				msgbox % "Problem setting the Reminder. Check if entered time is valid."
			else {
				msgbox % "Success"
				GuiControl, ReminderManager:, NewReminderTimeDays, % ""
				GuiControl, ReminderManager:, NewReminderTimeHours, % ""
				GuiControl, ReminderManager:, NewReminderTimeMinutes, % ""
				GuiControl, ReminderManager:, NewReminderMessage, % ""		
			}
		}
	}	

}


ReminderManagerGuiEscape(GuiHwnd) {
	ReminderManagerGuiClose(GuiHwnd)
}

ReminderManagerGuiClose(GuiHwnd) {
	WinGet, minimize_status, MinMax, ahk_id %GuiHwnd%
	if (minimize_status != -1) 
		WinGetPos, ReminderManagerGuiPosX, ReminderManagerGuiPosY,,, ahk_id %GuiHwnd%
	else {
		VarSetCapacity(pos, 44, 0)
		NumPut(44, pos)
		DllCall("GetWindowPlacement", "uint", GuiHwnd, "uint", &pos)
		ReminderManagerGuiPosX := NumGet(pos, 28, "int")
		ReminderManagerGuiPosY := NumGet(pos, 32, "int")
	}
	Gui, ReminderManager:Destroy
	return 0
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
