; https://github.com/cobracrystal/ahk
; todo:
; OPTION TO MAKE REMINDER MESSAGE A TOOLTIP.
; todo: save reminders over multiple restarts in ini file.
; then just load those up on starting -> no need to call 1337 reminder everytime. tada
; custom functions -> text body of function that you write just gets saved in file, timer is set to run that file

; if nextTimeMS >= 2**32, do nextTimeMS -= 2**32, custom function that will restart itself until timeMS < 2**32, then launch function.
#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\DiscordClient.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\jsongo.ahk"

class ReminderManager {
	/**
	* @param flagDebug Enables seconds for GUI timers and more notifications
	* @param threshold threshold after which timers will not be started (as it is expected the script will be restarted before it)
	*/
	__New(flagDebug := 0, threshold := 604800, token := 0) {
		guiMenu := TrayMenu.submenus["GUIs"]
		guiMenu.Add("Open Reminder Manager", this.reminderManagerGUI.Bind(this))
		A_TrayMenu.Add("GUIs", guiMenu)
		this.data := { coords: {x: 565, y: 300} }
		this.guiVars := { 1: ["rem1Message", "rem1S", "rem1M", "rem1H"], 
						  2: ["rem2Message", "rem2S", "rem2M", "rem2H", "rem2D", "rem2Mo"] }
		this.gui := -1
		this.LV := -1
		this.settings := { initialized: 1, flagDebug: flagDebug, token:token}
		this.timerList := []
		return this
	}

	/**
	* sets a reminder in the given time
	* @param times* days, hours, minutes, seconds; after which the reminder will be called
	* @param function A optional function object that will be called when the reminder finishes.
	* @param message An optional message to display when the reminder finishes. If both function and message are given, the function object must accept at least one parameter.
	* If neither a message or function object are specified, a simple message box will open
	*/
	setTimerIn(days := 0, hours := 0, minutes := 0, seconds := 0, message := "", function := "", fparams*) {
		if (days < 0 || hours < 0 || minutes < 0 || seconds < 0)
			throw(Error("Invalid Time specified:" days " Days, " hours " hours, " minutes " minutes, " seconds " seconds"))
		time := DateAdd(A_Now, days, "Days")
		time := DateAdd(time, hours, "Hours")
		time := DateAdd(time, minutes, "Minutes")
		time := DateAdd(time, seconds, "Seconds")
		return this.setTimerOn(time, message, function, fparams*)
	}

	/**
	* sets a reminder in the given time
	* @param time YYYYMMDDHHMISS timestamp on which the reminder will be called
	* @param message An optional message to be displayed via MsgBox instead of a function object
	* @param function A function object that will be called when the reminder is called
	* If neither a message or function object are specified, a simple message box will open.
	*/
	setTimerOn(time, message := "", function := "", fparams*) {
		MSec := A_MSec
		if (!IsTime(time))
			throw(Error("Invalid Timestamp given: " . time))
		timeDiff := DateDiff(time, A_Now, "Seconds")
		if (timeDiff < 0)
			throw(Error("Cannot create Reminder in the Past: " time " is " timeDiff * -1 " seconds in the past."))
		nextTimeMS := (timeDiff == 0 ? -1 : timeDiff * -1000 + MSec - 10)
		if (nextTimeMS < -4294967295)
			throw(Error("Integer Limit for Timers reached."))
		fArr := this.generateFuncObj(message, function, fparams*)
		timerObj := this._handleTimer.bind(this, 0, fArr[1], this.timerList.Length+1)
		this.timerList.Push({ nextTime: time, multi: 0, message: message, function: fArr[2], fparams: fparams, timer: timerObj })
		SetTimer(timerObj, nextTimeMS)
		return 1
	}

	/**
	* Sets a timer with given period after a given time
	* @param time year, month, day, hour, minute, second. If omitted, defaults to next instance of largest set units.
	* @param period Integer period in which the timer will repeat
	* @param periodUnit Time Unit can be one of the strings (or their first letter): Years, Weeks, Days, Hours, Minutes, Seconds
	* @param message An optional message to display when the reminder finishes.
	* @param function An optional function object that will be called when the reminder finishes. If both function and message are given, the function object must accept at least one parameter. Alternatively, specify either "defaultReminder", "discordReminder", "reminder1337" to execute those functions.
	* @param fparams Optional parameters passed to the function, used for "discordReminder" or other special reminders
	* If neither a message or function object are specified, a simple message box will open.
	 */
	setPeriodicTimerOn(time, period := 1, periodUnit := "Days", message := "", function := "", fparams*) {
		MSec := A_Msec
		Now := A_Now
		periodUnit := validateTimeUnit(periodUnit)
		nextTime := getNextPeriodicTimestamp(time, period, periodUnit)
		timeDiff := DateDiffW(nextTime, Now, "Seconds")
		nextTimeMS := (timeDiff == 0 ? MSec - 1000 : timeDiff * -1000 + MSec - 10)
		if (nextTimeMS < -4294967295)
			return
;			throw(Error("Integer Limit for Timers reached."))
		if (this.settings.flagDebug)
			timedTooltip(nextTimeMS "`n" MSec)
		fArr := this.generateFuncObj(message, function, fparams*)
		timerObj := this._handleTimer.bind(this, 1, fArr[1], this.timerList.Length+1, period, periodUnit)
		this.timerList.Push({ nextTime: DateAdd(Now, timeDiff, "S"), multi: 1, period: period, periodUnit: periodUnit, message: message, function: fArr[2], fparams:fparams, timer: timerObj })
		SetTimer(timerObj, nextTimeMS)
	}

	setPeriodicTimerOnParser(years?, months?, days?, hours?, minutes?, seconds?, period := 1, periodUnit := "Days", message := "", function := "", fparams*) => this.setPeriodicTimerOn(nextMatchingTime(years?, months?, days?, hours?, minutes?, seconds?), period, periodUnit, message, function, fparams*)
	setTimerOnParser(years?, months?, days?, hours?, minutes?, seconds?, message := "", function := "", fparams*) => this.setTimerOn(nextMatchingTime(years?, months?, days?, hours?, minutes?, seconds?), message, function, fparams*) 


	generateFuncObj(message, function, fparams*) {
		if !(function is Func) {
			switch function {
				case "discordReminder", "ReminderManager.discordReminder":
					if (fparams.Length == 1)
						function := this.discordReminder
					else
						function := this.defaultReminder
				case "reminder1337", "ReminderManager.reminder1337":
					function := this.reminder1337
				default:
					function := this.defaultReminder
			}
			name := StrReplace(function.Name, ".Prototype")
			function := function.Bind(this)
		}
		else {
			if (function is BoundFunc) {
				try 
					name := StrReplace(BoundFnName(function), ".Prototype")
				catch Error
					name := "/ (Unknown)"
			}
			else {
				name := StrReplace(function.Name, ".Prototype")
				if (Instr(name, ".")) {
					loop((cNames := StrSplit(name, ".")).Length)
						classObj := A_Index == 1 ? %cNames[1]% : classObj.%cNames[A_Index]%
					function := function.bind(classObj)
				}
				else if (name == "")
					name := "/ (Lambda)"
			}
		}
		if (message != "")
			function := function.bind(message)
		function := function.bind(fparams*)
		return [function, name]
	}

	_handleTimer(isMulti, function, index, period?, periodUnit?) {
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
		static LVN_KEYDOWN := -155
		this.gui := Gui("+Border", "Reminder Manager")
		this.gui.OnEvent("Escape", (*) => this.reminderManagerGUI("Close"))
		this.gui.OnEvent("Close", (*) => this.reminderManagerGUI("Close"))
		this.gui.AddGroupBox("Section w400 h90", "Add Reminder in")
		this.gui.SetFont("s9")
		this.gui.AddText("Center ys+22 xs+10", "Remind me in ")
			; this.gui.AddEdit("ys+20 x+5 r1", 0).Name := this.guiVars.1[5]
			; this.gui.AddText("Center ys+22 x+5", "d")
			this.gui.AddEdit("ys+20 x+5 r1 w30", 0).Name := this.guiVars.1[4]
			this.gui.AddText("Center ys+22 x+5", "h")
			this.gui.AddEdit("ys+20 x+5 r1 w30", 0).Name := this.guiVars.1[3]
			this.gui.AddText("Center ys+22 x+5", "m ")
			this.gui.AddEdit("ys+20 x+5 r1 w30", 0).Name := this.guiVars.1[2]
			this.gui.AddText("Center ys+22 x+5", "s")
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
			this.gui.AddEdit("ys+20 x+5 r1 w30 " (this.settings.flagDebug ? "" : "Hidden"), (this.settings.flagDebug ? A_Sec : 0)).Name := this.guiVars.2[2]
		this.gui.AddText("Center ys+22 x+5", "with the message:")
			this.gui.AddEdit("ys+47 xs+10 r2 w375").Name := this.guiVars.2[1]
		this.gui.AddButton("ys+5 h60 w80", "Add Reminder").OnEvent("Click", this.reminderOnFromGUI.bind(this))
		this.LV := this.gui.AddListView("xs R10 w500 -Multi Sort", ["Next Occurence", "Period", "Message", "Function", "Index"])
		this.LV.OnEvent("ContextMenu", this.onContextMenu.bind(this))
		this.LV.OnNotify(LVN_KEYDOWN, this.onKeyPress.bind(this))
		this.createListView()
		this.gui.Show(Format("x{1}y{2} Autosize", this.data.coords.x, this.data.coords.y))
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
		this.LV.ModifyCol(5, 0)
		for i, e in this.timerList
			if (IsSet(e))
				this.LV.Add(, FormatTime(e.nextTime, "yyyy-MM-dd, HH:mm:ss"),
					HasProp(e, "period") ? e.period " " (e.period == 1 ? SubStr(e.periodUnit, 1, -1) : e.periodUnit) : "/",
					e.message, 
					e.function,
					i
				)
		Loop (2)
			this.LV.ModifyCol(A_Index, "+AutoHdr")
		this.LV.ModifyCol(3, 225)
		this.LV.ModifyCol(4, "+AutoHdr")
	}

	; operation values: 0 = Delete, 1 = Modify Column Content
	refreshListViewRow(index, operation, column := 1, refresh := 0, values*) {
		if !(WinExist(this.gui))
			return
		Loop (this.LV.GetCount()) {
			if (this.LV.GetText(A_Index, 5) == index) {
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
		return ; todo
	}

	onKeyPress(ctrlObj, lParam) {
		vKey := NumGet(lParam, 24, "UShort")
		switch vKey {
			case "46": 	;// Del/Entf Key -> Delete Reminder
				if ((rowN := this.LV.GetNext()) == 0)
					return
				index := Integer(this.LV.GetText(rowN, 5))
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
			res := this.setTimerIn(, t[4], t[3], t[2], t[1])
		catch Error as e {
			msgbox("Problem setting the Reminder. Check if entered time is valid.`nSpecifically: " e.What " failed with`n" e.Message)
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
			time := nextMatchingTime(,				t[6] != "" ? t[6] : unset, 
				t[5] != "" ? t[5] : unset, t[4] != "" ? t[4] : unset, 
				t[3] != "" ? t[3] : unset, t[2] != "" ? t[2] : unset)
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

	importReminders(filePath, ignoreMissedReminders := false, encoding := "UTF-8") {
		if (!FileExist(filepath))
			throw(TargetError("Nonexistent Reminder File Given"))
		jsonStr := FileRead(filePath, encoding)
		remArr := MapToObj(jsongo.Parse(jsonStr))
		for i, rObj in remArr {
			y := rObj.units.HasOwnProp("years") ? rObj.units.years : unset
			mo := rObj.units.HasOwnProp("months") ? rObj.units.months : unset
			d := rObj.units.HasOwnProp("days") ? rObj.units.days : unset
			h := rObj.units.HasOwnProp("hours") ? rObj.units.hours : unset
			m := rObj.units.HasOwnProp("minutes") ? rObj.units.minutes : unset
			s := rObj.units.HasOwnProp("seconds") ? rObj.units.seconds : unset
			fparArr := rObj.HasOwnProp("fparams") ? rObj.fparams : []
			if (ignoreMissedReminders && Abs(DateDiff(nextMatchingTime(y?,mo?,d?,h?,m?,s?), A_Now, "Seconds")) <= 1)
				continue
			if (rObj.multi)
				this.setPeriodicTimerOnParser(y?,mo?,d?,h?,m?,s?, rObj.period, rObj.periodUnit, rObj.message, rObj.function, fparArr*)			
			else
				this.setTimerOnParser(y?,mo?,d?,h?,m?,s?,rObj.message, rObj.function, fparArr*)
		}
	}

	exportReminders(filepath := "") {
		jsonString := jsongo.Stringify(this.timerList, ["timer"], "`t")
		FileOpen(filePath, "w", "UTF-8").Write(jsonString)
	}

	defaultReminder(msg := "") {
		;	L1033 -> en-US for day name.
		message := "It is " . FormatTime("L1033", "dddd, dd.MM.yyyy, HH:mm:ss") . "`nYou set a reminder for this point in time."
		message .= (msg == "" ? "" : "`nReminder Message: " . msg)
		SoundPlay("*48")
		MsgBoxAsGui(message, "Reminder")
	}

	reminder1337(*) {
		SoundPlay("*48")
		MsgBoxAsGui("Copy 1337 in clipboard and activate discord?", "1337", 0x1,,, (r) => (
			r == "Cancel" ? 0 : 
				( 
					A_Clipboard := "1337", 
					WinExist("ahk_exe discord.exe") ? WinActivate("ahk_exe discord.exe") : 0
				)
			))
	}

	discordReminder(msg, id) {
		discordBot := DiscordClient(this.settings.token, false)
		time := FormatTime("L1033", "dddd, dd.MM.yyyy, HH:mm:ss") ; L1033 -> en-US for day name.
		message := "It is " . time . "`nYou set a reminder for this point in time."
		message .= (msg == "" ? "" : "`nReminder Message: " . msg)
		discordBot.sendMessage({content:message}, id, 1)
	}
}