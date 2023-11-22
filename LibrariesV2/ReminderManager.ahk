; OPTION TO MAKE REMINDER MESSAGE A TOOLTIP.
; have text already inside the edit fields of the GUI. The method of both text and edit control is not a problem, its precisely what we want since blank content -> current date/hour whatever. Can't be hardcoded then tho.
; todo: manage reminders
; todo b: save reminders over multiple restarts in ini file.
; then just load those up on starting -> no need to call 1337 reminder everytime. tada
; for custom functions: add field to add a full function body. This gets added in customReminderFunctions.ahk in appdata folder, and main file gets inclusion.

; OK SO FOR MISSED REMINDERS:
; WE SAVE THE CURRENT TIME ON EXIT / EVERY X MINUTES
; WHEN THE SCRIPT STARTS IT READS THAT TIME, IT CALCULATES THE TIMESPAN
; NOW IF A REMINDER IS SET FOR A DATE THAT LIES IN THAT TIMESPAN AKA IS SET IN THE PAST
; THEN IT TRIGGERS IMMEDIATELY
; ONLY FOR [LOADED] REMINDERS THO, WOULD BE BAD ON THE 4 AM OR 1337 REMINDER.

#Include "%A_ScriptDir%\LibrariesV2\BasicUtilities.ahk"
#Include "%A_ScriptDir%\LibrariesV2\DiscordClient.ahk"

class ReminderManager {
	/*
	* @param flagLoad Load reminders from a specified file
	* @param flagDebug Enables seconds for GUI timers and more notifications
	* @param threshold threshold after which timers will not be started (as it is expected the script will be restarted before it)
	*/
	__New(flagLoad := 0, flagDebug := 0, threshold := 604800) {
		guiMenu := TrayMenu.submenus["GUIs"]
		guiMenu.Add("Open Reminder Manager", this.reminderManagerGUI.Bind(this))
		A_TrayMenu.Add("GUIs", guiMenu)
		this.data := {coords: [565, 300]}
		this.guiVars := {1: ["rem1Message", "rem1S", "rem1M", "rem1H", "rem1D"], 2: ["rem2Message", "rem2S", "rem2M", "rem2H", "rem2D", "rem2Mo"]}
		this.gui := -1
		this.LV := -1
		this.settings := {initialized: 1, flagDebug: flagDebug, flagLoad: flagLoad}
		this.timerList := Map()
		this.timerCount := 0
		if (flagLoad)  {
			; load reminders from file in appdata or smth.
			msgbox("not implemented yet")
		}
		return this
	}

	/*
	* sets a reminder in the given time
	* @param times* days, hours, minutes, seconds; after which the reminder will be called
	* @param function A optional function object that will be called when the reminder finishes. 
	* @param message An optional message to display when the reminder finishes. If both function and message are given, the function object must accept at least one parameter.
	* If neither a message or function object are specified, a simple message box will open
	*/
	setTimerIn(days := 0, hours := 0, minutes := 0, seconds := 0, message := "", function := "") {
		if (days < 0 || hours < 0 || minutes < 0 || seconds < 0)
			throw Error("Invalid Time specified.")
		time := DateAdd(A_Now, days, "Days")
		time := DateAdd(time, hours, "Hours")
		time := DateAdd(time, minutes, "Minutes")
		time := DateAdd(time, seconds, "Seconds")
		return this.setTimerOn(time, message, function)
	}
	
	/*
	* sets a reminder in the given time
	* @param time YYYYMMDDHHMISS timestamp on which the reminder will be called
	* @param message An optional message to be displayed via MsgBox instead of a function object
	* @param function A function object that will be called when the reminder is called
	* If neither a message or function object are specified, a simple message box will open.
	*/
	setTimerOn(time, message := "", function := "") {
		MSec := A_MSec
		if (!IsTime(time))
			throw Error("Invalid Timestamp given: " . time)
		timeDiff := DateDiff(time, A_Now, "Seconds")
		if (timeDiff < 0)
			throw Error("Cannot create Reminder in the Past: " time " is " timeDiff * -1 "seconds in the past.")
		nextTimeMS := (timeDiff == 0 ? -1 : timeDiff * -1000 + MSec)
		if (nextTimeMS < -4294967295)
			throw Error("Integer Limit for Timers reached.")
		if !(function is Func) {
			function := this.defaultReminder.Bind(this, message)
			name := StrReplace(this.defaultReminder.Name, ".Prototype")
		}
		else {
			if (function is BoundFunc)
				name := StrReplace(BoundFnName(function), ".Prototype")
			else {
				name := function.Name
				if (Instr(name, "."))
					function := function.bind("this")
			}
			if (message != "")
				function := function.bind(message)
		}
		this.timerList[++this.timerCount] := {nextTime:time, multi:0, message:message, function:name}
		SetTimer(this.handleTimer.bind(this, 0, function, this.timerCount), nextTimeMS)
		A_Clipboard := nextTimeMS
		return 1
	}

	/*
	* sets a timer with given period after a given time
	* @param time year, month, day, hour, minute, second. If omitted, defaults to next instance of largest set units.
	* @param period Integer period in which the timer will repeat
	* @param periodUnit Time Unit can be one of the strings (or their first letter): Years, Weeks, Days, Hours, Minutes, Seconds
	* @param message An optional message to display when the reminder finishes. 
	* @param function A optional function object that will be called when the reminder finishes. If both function and message are given, the function object must accept at least one parameter.
	* If neither a message or function object are specified, a simple message box will open.
	*/
	setPeriodicTimerOn(time, period, periodUnit := "Days", message := "", function := "") {
		MSec := A_Msec
		if (!IsTime(time))
			throw Error("Invalid Timestamp: " . time)
		if (period <= 0)
			throw Error("Invalid Period: " period)
		switch periodUnit, 0 {
			case "S", "Seconds":
				periodUnit := "Seconds"
			case "M", "Minutes":
				periodUnit := "Minutes"
			case "H", "Hours":
				periodUnit := "Hours"
			case "D", "Days":
				periodUnit := "Days"
			case "W", "Weeks":
				periodUnit := "Weeks"
			case "Mo", "Months":
				periodUnit := "Months"
			case "Y", "Years":
				periodUnit := "Years"
			default:
				throw Error("Invalid Period Unit: " . periodUnit)
		}
		timeDiff := DateDiff(time, Now := A_Now, "Seconds")
		if (timeDiff < 0) {
			switch periodUnit, 0 {
				case "Seconds", "Minutes", "Hours", "Days":
					secs := DateDiff(DateAdd("1998", period, periodUnit), "1998", "Seconds")
					timeDiff := Mod(timeDiff, secs) + secs
				case "Weeks":
					secs := DateDiff(DateAdd("1998", period*7, "D"), "1998", "Seconds")
					timeDiff := Mod(timeDiff, secs) + secs
				case "Months":
					monthDiff := Mod((SubStr(time, 1, 4) - A_YYYY) * 12 + (SubStr(time, 5, 2) - A_MM), period)
					if (monthDiff == 0) { ; if given time + n*period is current month
						guessTime := A_YYYY . A_MM . SubStr(time, 7)
						if (!IsTime(guessTime)) { ; if it is current month, but invalid date
							nextMonth := Format("{:02}", Mod(A_MM, 12) + 1) ; cannot result in december->january, since dec has 31 days
							rolledOverDays := Format("{:02}", SubStr(time, 7, 2) - DateDiff(A_YYYY . nextMonth, A_YYYY . A_MM, "D"))
							guessTime := A_YYYY . nextMonth . rolledOverDays . SubStr(time, 9) 
							; since all invalid dates are at the end of a month, rolling over a month means we are definitely in the future.
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
				case "Years":
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
			}
		}
		nextTimeMS := (timeDiff == 0 ? MSec - 1000 : timeDiff * -1000 + MSec)
		if (nextTimeMS < -4294967295)
			throw Error("Integer Limit for Timers reached.")
		if (this.settings.flagDebug)
			timedTooltip(nextTimeMS "`n" MSec)
		if !(function is Func) {
			function := this.defaultReminder.Bind(this, message)
			name := StrReplace(this.defaultReminder.Name, ".Prototype")
		}
		else {
			if (function is BoundFunc)
				name := StrReplace(BoundFnName(function), ".Prototype")
			else {
				name := StrReplace(function.Name, ".Prototype")
				if (Instr(name, ".")) ; bind fake @this parameter for classes.
					function := function.bind(0) 
			}
			if (message != "")
				function := function.bind(message)
		}
		this.timerList[++this.timerCount] := {nextTime:DateAdd(Now, timeDiff, "S"), multi:1, period:period, periodUnit:periodUnit, message:message, function:name}
		SetTimer(this.handleTimer.bind(this, 1, function, this.timerCount, period, periodUnit), nextTimeMS)
	}

	handleTimer(isMulti, function, index, period?, periodUnit?) {
		MSec := A_MSec
		if (!isMulti)
			this.timerList.Delete(index)
		else {
			nextOccurence := DateAddW(A_Now, period, periodUnit)
			nextTimeMS := 1000 * DateDiff(A_Now, nextOccurence, "Seconds") + MSec
			; previous timer is automatically deleted, now create new one with nextTime. Can't use periodic timer since monthly isn't a thing
			SetTimer(this.handleTimer.bind(this, 1, function, index, period, periodUnit), nextTimeMS)
			this.timerList[index].nextTime := nextOccurence
		}
		function()
		if (WinExist(this.gui))
			this.createListView()
	}

	guiCreate() {
		this.gui := Gui("+Border", "Reminder Manager")
		this.gui.OnEvent("Escape", this.reminderManagerGUI.bind(this,"Close"))
		this.gui.OnEvent("Close", this.reminderManagerGUI.bind(this,"Close"))
		this.gui.AddGroupBox("Section w400 h90", "Add Reminder in")
			this.gui.SetFont("s9")
			this.gui.AddText("Center ys+22 xs+10", "Remind me in ")
			this.gui.AddEdit("ys+20 x+5 r1 w30").Name := this.guiVars.1[5]
			this.gui.AddText("Center ys+22 x+5", "d")
			this.gui.AddEdit("ys+20 x+5 r1 w30").Name := this.guiVars.1[4]
			this.gui.AddText("Center ys+22 x+5", "h")
			this.gui.AddEdit("ys+20 x+5 r1 w30").Name := this.guiVars.1[3]
			this.gui.AddText("Center ys+22 x+5", "m ")
			this.gui.AddEdit("ys+20 x+5 r1 w30 " (this.settings.flagDebug ? "" : "Hidden")).Name := this.guiVars.1[2]
			this.gui.AddText("Center ys+22 x+5 " (this.settings.flagDebug ? "" : "Hidden"), "s")
			this.gui.AddText("Center ys+22 x+5", "with the message:")
			this.gui.AddEdit("ys+47 xs+10 r2 w375").Name := this.guiVars.1[1]
		this.gui.AddButton("ys+5 h60 w80", "Add Reminder").OnEvent("Click", this.reminderInFromGUI.bind(this))
		this.gui.AddGroupBox("xs Section w400 h90", "Add Reminder on")
			this.gui.SetFont("s9")
			this.gui.AddText("Center ys+22 xs+10", "Remind me on")
			this.gui.AddEdit("ys+20 x+5 r1 w30").Name := this.guiVars.2[6]
			this.gui.AddText("Center ys+22 x+5", ".")
			this.gui.AddEdit("ys+20 x+5 r1 w30").Name := this.guiVars.2[5]
			this.gui.AddText("Center ys+22 x+5", ", at")
			this.gui.AddEdit("ys+20 x+5 r1 w30").Name := this.guiVars.2[4]
			this.gui.AddText("Center ys+22 x+5", ":")
			this.gui.AddEdit("ys+20 x+5 r1 w30").Name := this.guiVars.2[3]
			this.gui.AddText("Center ys+22 x+5 " (this.settings.flagDebug ? "" : "Hidden"), ":")
			this.gui.AddEdit("ys+20 x+5 r1 w30 " (this.settings.flagDebug ? "" : "Hidden")).Name := this.guiVars.2[2]
			this.gui.AddText("Center ys+22 x+5", "with the message:")
			this.gui.AddEdit("ys+47 xs+10 r2 w375").Name := this.guiVars.2[1]
		this.gui.AddButton("ys+5 h60 w80", "Add Reminder").OnEvent("Click", this.reminderOnFromGUI.bind(this))
		
		this.LV := this.gui.AddListView("xs R10 w500 -Multi", ["Index", "Next Occurence", "Period", "Function/Message"])
		this.LV.OnEvent("ContextMenu", this.onContextMenu.bind(this))
		this.LV.OnNotify(-155, this.onKeyPress.bind(this))
		this.createListView()
		
		this.gui.Show(Format("x{1}y{2} Autosize", this.data.coords[1], this.data.coords[2]))
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
	
	createListView() {
		this.LV.Delete()
		this.LV.ModifyCol(1, "0")
		this.LV.ModifyCol(2, "110")
		this.LV.ModifyCol(3, "AutoHdr")
		this.LV.ModifyCol(4, "AutoHdr")
		for i, e in this.timerList
			this.LV.Add(,i
				, FormatTime(e.nextTime, "dd.MM.yyyy HH:mm:ss")
				, HasProp(e, "period") ? e.period " " (e.period == 1 ? SubStr(e.periodUnit, 1) : e.periodUnit) : "/"
				, e.function (e.message != "" ? ', "' e.message '"': ""))
		Loop(this.LV.GetCount("Col") - 1)
			this.LV.ModifyCol(A_Index + 1, "+AutoHdr")
	}

	onContextMenu(ctrlObj, rowN, isRightclick, x, y) {
		return
	}

	onKeyPress(ctrlObj, lParam) {
		vKey := NumGet(lParam, 24, "UShort")
		switch vKey {
			case "46": 	;// Del/Entf Key -> Delete Reminder
				if ((rowN := this.LV.GetNext()) == 0)
					return
				index := Integer(this.LV.GetText(rowN, 1))
				if ("action successful?")
					this.LV.delete(rowN)
			case "116":	;// F5 Key -> Reload
				this.createListView()
			default: 
				return
		}
	}

	reminderInFromGUI(*) {
		t := []
		for i, e in this.guiVars.1
			t.push(this.gui[e].Value ? this.gui[e].Value : 0)
		if !(t[1]) && (MsgBox("You have not set a reminder message. Proceed?", "Reminder", 0x1) == "Cancel")
			return
		try
			res := this.setTimerIn(t[5], t[4], t[3], t[2], t[1])
		catch Error {
			msgbox("Problem setting the Reminder. Check if entered time is valid.")
			return 0
		}
		timedTooltip("Success!", 1000)
		for i, e in this.guiVars.1
			this.gui[e].Value := ""
		this.createListView()
	}
	
	reminderOnFromGUI(*) {
		guiContent := this.gui.Submit(false)
		t := []
		for i, e in this.guiVars.2
			t.push(this.gui[e].Value)
		if !(t[1]) && (MsgBox("You have not set a reminder message. Proceed?", "Reminder", 0x1) == "Cancel")
			return
		try 
			this.setTimerOn(parseTime(,t[6]?t[6]:unset, t[5]?t[5]:unset, t[4]?t[4]:unset, t[3]?t[3]:unset, t[2]?t[2]:unset), t[1])
		catch Error {
			msgbox("Problem setting the Reminder. Check if entered time is valid.")
			return 0
		}
		timedTooltip("Success!", 1000)
		for i, e in this.guiVars.2
			this.gui[e].Value := ""
		this.createListView()
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
