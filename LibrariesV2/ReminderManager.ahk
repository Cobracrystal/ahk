; https://github.com/cobracrystal/ahk
; todo:
; OPTION TO MAKE REMINDER MESSAGE A TOOLTIP.
; todo: save reminders over multiple restarts in ini file.
; then just load those up on starting -> no need to call 1337 reminder everytime. tada
; custom functions -> text body of function that you write just gets saved in file, timer is set to run that file

; if nextTimeMS >= 2**32, do nextTimeMS -= 2**32, custom function that will restart itself until timeMS < 2**32, then launch function.
#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\DiscordClient.ahk"

class ReminderManager {
	/**
	* @param flagLoad Load reminders from a specified file
	* @param flagDebug Enables seconds for GUI timers and more notifications
	* @param threshold threshold after which timers will not be started (as it is expected the script will be restarted before it)
	*/
	__New(flagLoad := 0, flagDebug := 0, threshold := 604800) {
		guiMenu := TrayMenu.submenus["GUIs"]
		guiMenu.Add("Open Reminder Manager", this.reminderManagerGUI.Bind(this))
		A_TrayMenu.Add("GUIs", guiMenu)
		this.data := { coords: [565, 300] }
		this.guiVars := { 1: ["rem1Message", "rem1S", "rem1M", "rem1H", "rem1D"], 2: ["rem2Message", "rem2S", "rem2M", "rem2H", "rem2D", "rem2Mo"] }
		this.gui := -1
		this.LV := -1
		this.settings := { initialized: 1, flagDebug: flagDebug, flagLoad: flagLoad }
		this.timerList := Map()
		this.timerCount := 0
		if (flagLoad) {
			; load reminders from file in appdata or smth.
			msgbox("not implemented yet")
		}
		return this
	}

	/**
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

	/**
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
		nextTimeMS := (timeDiff == 0 ? -1 : timeDiff * -1000 + MSec - 10)
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
				else if (name == "")
					name := "/ (Lambda)"
			}
			if (message != "")
				function := function.bind(message)
		}
		timerObj := this.handleTimer.bind(this, 0, function, ++this.timerCount)
		this.timerList[this.timerCount] := { nextTime: time, multi: 0, message: message, function: name, timer: timerObj }
		SetTimer(timerObj, nextTimeMS)
		return 1
	}

	/**
	* Sets a timer with given period after a given time
	* @param time year, month, day, hour, minute, second. If omitted, defaults to next instance of largest set units.
	* @param period Integer period in which the timer will repeat
	* @param periodUnit Time Unit can be one of the strings (or their first letter): Years, Weeks, Days, Hours, Minutes, Seconds
	* @param message An optional message to display when the reminder finishes.
	* @param function A optional function object that will be called when the reminder finishes. If both function and message are given, the function object must accept at least one parameter.
	* If neither a message or function object are specified, a simple message box will open.
	 */
	setPeriodicTimerOn(time, period, periodUnit := "Days", message := "", function := "") {
		MSec := A_Msec
		if (!IsTime(String(time)))
			throw Error("Invalid Timestamp: " . time)
		if (period <= 0)
			throw Error("Invalid Period: " period)
		switch periodUnit, 0 {
			case "S", "Seconds", "Second":
				periodUnit := "Seconds"
			case "M", "Minutes", "Minute":
				periodUnit := "Minutes"
			case "H", "Hours", "Hour":
				periodUnit := "Hours"
			case "D", "Days", "Day":
				periodUnit := "Days"
			case "W", "Weeks", "Week":
				periodUnit := "Weeks"
			case "Mo", "Months", "Month":
				periodUnit := "Months"
			case "Y", "Years", "Year":
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
					secs := DateDiff(DateAdd("1998", period * 7, "D"), "1998", "Seconds")
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
		nextTimeMS := (timeDiff == 0 ? MSec - 1000 : timeDiff * -1000 + MSec - 10)
		if (nextTimeMS < -4294967295)
			return
;			throw Error("Integer Limit for Timers reached.")
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
				else if (name == "")
					name := "/ (Lambda)"
			}
			if (message != "")
				function := function.bind(message)
		}
		timerObj := this.handleTimer.bind(this, 1, function, ++this.timerCount, period, periodUnit)
		this.timerList[this.timerCount] := { nextTime: DateAdd(Now, timeDiff, "S"), multi: 1, period: period, periodUnit: periodUnit, message: message, function: name, timer: timerObj }
		SetTimer(timerObj, nextTimeMS)
	}

	handleTimer(isMulti, function, index, period?, periodUnit?) {
		MSec := A_MSec
		if (!isMulti) {
			this.timerList.Delete(index)
			this.refreshListViewRow(index, 0)
		}
		else {
			nextOccurence := DateAddW(A_Now, period, periodUnit)
			nextTimeMS := 1000 * DateDiff(A_Now, nextOccurence, "Seconds") + MSec - 10 ; -10 -> correction against cases of .999
			if (nextTimeMS > -4294967296)
				SetTimer(this.timerList[index].timer, nextTimeMS)
			this.timerList[index].nextTime := nextOccurence
			this.refreshListViewRow(index, 1, 1, 0, FormatTime(nextOccurence, "yyyy-MM-dd, HH:mm:ss"))
		}
		function()
	}

	guiCreate() {
		this.gui := Gui("+Border", "Reminder Manager")
		this.gui.OnEvent("Escape", (*) => this.reminderManagerGUI("Close"))
		this.gui.OnEvent("Close", (*) => this.reminderManagerGUI("Close"))
		this.gui.AddGroupBox("Section w400 h90", "Add Reminder in")
		this.gui.SetFont("s9")
		this.gui.AddText("Center ys+22 xs+10", "Remind me in ")
		this.gui.AddEdit("ys+20 x+5 r1 w30", 0).Name := this.guiVars.1[5]
		this.gui.AddText("Center ys+22 x+5", "d")
		this.gui.AddEdit("ys+20 x+5 r1 w30", 0).Name := this.guiVars.1[4]
		this.gui.AddText("Center ys+22 x+5", "h")
		this.gui.AddEdit("ys+20 x+5 r1 w30", 0).Name := this.guiVars.1[3]
		this.gui.AddText("Center ys+22 x+5", "m ")
		this.gui.AddEdit("ys+20 x+5 r1 w30 " (this.settings.flagDebug ? "" : "Hidden"), 0).Name := this.guiVars.1[2]
		this.gui.AddText("Center ys+22 x+5 " (this.settings.flagDebug ? "" : "Hidden"), "s")
		this.gui.AddText("Center ys+22 x+5", "with the message:")
		this.gui.AddEdit("ys+47 xs+10 r2 w375").Name := this.guiVars.1[1]
		this.gui.AddButton("ys+5 h60 w80", "Add Reminder").OnEvent("Click", this.reminderInFromGUI.bind(this))
		this.gui.AddGroupBox("xs Section w400 h90", "Add Reminder on")
		this.gui.SetFont("s9")
		this.gui.AddText("Center ys+22 xs+10", "Remind me on")
		this.gui.AddEdit("ys+20 x+5 r1 w30", A_DD).Name := this.guiVars.2[5]
		this.gui.AddText("Center ys+22 x+5", ".")
		this.gui.AddEdit("ys+20 x+5 r1 w30", A_MM).Name := this.guiVars.2[6]
		this.gui.AddText("Center ys+22 x+5", ", at")
		this.gui.AddEdit("ys+20 x+5 r1 w30", A_Hour).Name := this.guiVars.2[4]
		this.gui.AddText("Center ys+22 x+5", ":")
		this.gui.AddEdit("ys+20 x+5 r1 w30", A_Min).Name := this.guiVars.2[3]
		this.gui.AddText("Center ys+22 x+5 " (this.settings.flagDebug ? "" : "Hidden"), ":")
		this.gui.AddEdit("ys+20 x+5 r1 w30 " (this.settings.flagDebug ? "" : "Hidden"), A_Sec).Name := this.guiVars.2[2]
		this.gui.AddText("Center ys+22 x+5", "with the message:")
		this.gui.AddEdit("ys+47 xs+10 r2 w375").Name := this.guiVars.2[1]
		this.gui.AddButton("ys+5 h60 w80", "Add Reminder").OnEvent("Click", this.reminderOnFromGUI.bind(this))
		this.LV := this.gui.AddListView("xs R10 w500 -Multi Sort", ["Next Occurence", "Period", "Function/Message", "Index"])
		this.LV.OnEvent("ContextMenu", this.onContextMenu.bind(this))
		this.LV.OnNotify(-155, this.onKeyPress.bind(this))
		this.createListView()
		this.gui.Show(Format("x{1}y{2} Autosize", this.data.coords[1], this.data.coords[2]))
	}

	reminderManagerGUI(mode := "O", *) {
		mode := SubStr(mode, 1, 1)
		if (WinExist(this.gui)) {
			if (mode == "O")
				WinActivate(this.gui.hwnd)
			else {
				this.data.coords := windowGetCoordinates(this.gui.hwnd)
				this.gui.destroy()
				this.gui := -1
			}
		}
		else if (mode != "C")
			this.guiCreate()
	}

	createListView() {
		this.LV.Delete()
		this.LV.ModifyCol(4, 0)
		for i, e in this.timerList
			this.LV.Add(, FormatTime(e.nextTime, "yyyy-MM-dd, HH:mm:ss"),
				HasProp(e, "period") ? e.period " " (e.period == 1 ? SubStr(e.periodUnit, 1, -1) : e.periodUnit) : "/",
				e.function (e.message != "" ? ', "' e.message '"' : ""), i
			)
		Loop (3)
			this.LV.ModifyCol(A_Index, "+AutoHdr")
	}

	; operation values: 0 = Delete, 1 = Modify Column Content
	refreshListViewRow(index, operation, column := 1, refresh := 0, values*) {
		if !(WinExist(this.gui))
			return
		Loop (this.LV.GetCount()) {
			if (this.LV.GetText(A_Index, 4) == index) {
				if (operation == 0)
					this.LV.delete(A_Index)
				else if (operation == 1) {
					this.LV.Modify(A_Index, "Col" column, values*)
					this.LV.ModifyCol(column, "AutoHdr Sort")
				}
				break
			}
		}
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
				index := Integer(this.LV.GetText(rowN, 4))
				try SetTimer(this.timerList[index].timer, 0)
				this.timerList.delete(index)
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
			time := parseTime(, t[6] ? t[6] : unset, t[5] ? t[5] : unset, t[4] ? t[4] : unset, t[3] ? t[3] : unset, t[2] ? t[2] : unset)
		catch Error {
			msgbox("Invalid Time specified.")
			return 0
		}
		try
			this.setTimerOn(time, t[1])
		catch Error {
			MsgBox("Cannot set a reminder for that time.")
			return 0
		}
		timedTooltip("Success!", 1000)
		for i, e in this.guiVars.2
			this.gui[e].Value := ""
		this.createListView()
		return 1
	}

	defaultReminder(text := "") {
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