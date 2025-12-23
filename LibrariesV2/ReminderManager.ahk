; https://github.com/cobracrystal/ahk
; todo:
; OPTION TO MAKE REMINDER MESSAGE A TOOLTIP.
; todo: save reminders over multiple restarts in ini file.
; then just load those up on starting -> no need to call 1337 reminder everytime. tada
; custom functions -> text body of function that you write just gets saved in file, timer is set to run that file

; if nextTimeMS >= 2**32, do nextTimeMS -= 2**32, custom function that will restart itself until timeMS < 2**32, then launch function.
#Include "%A_LineFile%\..\..\LibrariesV2\TimeUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\WinUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\DiscordBot.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\jsongo.ahk"

class ReminderManager {
	
	/**
	 * Initializes some settings
	 */
	static __New() {
		guiMenu := TrayMenu.submenus["GUIs"]
		guiMenu.Add("Open Reminder Manager", (*) => this.Gui.Open())
		A_TrayMenu.Add("GUIs", guiMenu)
		this.settings := { debug: 0, token: 0, threshold: 604800 }
		this.timerList := []
	}

	/**
	 * Sets options for ReminderManager usage.
	 * @param flagDebug Enables seconds for reminders and more notifications
	 * @param {Integer} threshold Threshold beyond which reminders will not be set, ie 64800 means a reminder of >1 day will not be set.
	 * @param token Discord token.
	 */
	static setOptions(flagDebug?,  token?, threshold := this.settings.threshold, notification := this.Notification.default) {
		if IsSet(flagDebug)
			this.settings.debug := flagDebug
		if IsSet(token)
			this.settings.token := token
		this.settings.threshold := threshold
		this.Notification.default := notification
	}

	/**
	 * Sets a reminder at a point in the future which is the specified timeframe away
	 * @param times* days, hours, minutes, seconds; after which the reminder will be called
	 * @param function A optional function object that will be called when the reminder finishes.
	 * @param message An optional message to display when the reminder finishes. If both function and message are given, the function object must accept at least one parameter.
	 * If neither a message or function object are specified, a simple message box will open
	 */
	static setTimerIn(days := 0, hours := 0, minutes := 0, seconds := 0, message := "", function := "", fparams*) {
		if (days < 0 || hours < 0 || minutes < 0 || seconds < 0)
			throw (Error("Invalid Time specified:" days " Days, " hours " hours, " minutes " minutes, " seconds " seconds"))
		time := DateAdd(A_Now, days, "Days")
		time := DateAdd(time, hours, "Hours")
		time := DateAdd(time, minutes, "Minutes")
		time := DateAdd(time, seconds, "Seconds")
		return this.setTimerOn(time, message, function, fparams*)
	}

	/**
	 * Sets a reminder at the given timestamp
	 * @param time YYYYMMDDHHMISS timestamp on which the reminder will be called
	 * @param message An optional message to be displayed via MsgBox instead of a function object
	 * @param function A function object that will be called when the reminder is called
	 * If neither a message or function object are specified, a simple message box will open.
	 */
	static setTimerOn(time, message := "", function := "", fparams*) {
		MSec := A_MSec
		if (!IsTime(time))
			throw (Error("Invalid Timestamp given: " . time))
		timeDiff := DateDiff(time, A_Now, "Seconds")
		if (timeDiff < 0)
			throw (Error("Cannot create Reminder in the Past: " time " is " timeDiff * -1 " seconds in the past."))
		nextTimeMS := (timeDiff == 0 ? -1 : timeDiff * -1000 + MSec - 10)
		if (nextTimeMS < -4294967295)
			throw (Error("Integer Limit for Timers reached."))
		funcName := this.getFuncName(function)
		callable := this.getCallableFunc(message, function, fparams*)
		timerObj := this._handleTimer.bind(this, 0, callable, this.timerList.Length + 1)
		this.timerList.Push({ nextTime: time, multi: 0, message: message, function: funcName, fparams: fparams, timer: timerObj })
		SetTimer(timerObj, nextTimeMS)
		return 1
	}

	/**
	 * Sets a timer with given period after a given time
	 * @param time year, month, day, hour, minute, second. If omitted, defaults to next instance of largest set units.
	 * @param period Integer period in which the timer will repeat
	 * @param periodUnit Time Unit can be one of the strings (or their first letter): Years, Weeks, Days, Hours, Minutes, Seconds
	 * @param message An optional message to display when the reminder finishes.
	 * @param function An optional function object that will be called when the reminder finishes. If both function and message are given, the function object must accept at least one parameter. Alternatively, specify a name of any of the .Notification functions
	 * @param fparams Optional parameters passed to the function, used for "discordReminder" or other special reminders
	 * If neither a message or function object are specified, a simple message box will open.
	 */
	static setPeriodicTimerOn(time, period := 1, periodUnit := "Days", message := "", function := "", fparams*) {
		MSec := A_Msec
		Now := A_Now
		periodUnit := validateTimeUnit(periodUnit)
		nextTime := getNextPeriodicTimestamp(time, period, periodUnit)
		timeDiff := DateDiffW(nextTime, Now, "Seconds")
		nextTimeMS := (timeDiff == 0 ? MSec - 1000 : timeDiff * -1000 + MSec - 10)
		if (nextTimeMS < -4294967295)
			return
		;			throw(Error("Integer Limit for Timers reached."))
		if (this.settings.debug)
			timedTooltip(nextTimeMS "`n" MSec)
		funcName := this.getFuncName(function)
		callable := this.getCallableFunc(message, function, fparams*)
		timerObj := this._handleTimer.bind(this, 1, callable, this.timerList.Length + 1, period, periodUnit)
		this.timerList.Push({ nextTime: DateAdd(Now, timeDiff, "S"), multi: 1, period: period, periodUnit: periodUnit, message: message, function: funcName, fparams: fparams, timer: timerObj })
		SetTimer(timerObj, nextTimeMS)
	}

	/**
	 * Given a function name or object, creates a callable object to set the timer for
	 * @param message 
	 * @param function 
	 * @param fparams 
	 * @returns {BoundFunc} 
	 */
	static getCallableFunc(message, function, fparams*) {
		if !(function is Func)
			function := this.parseFunctionStringToFunction(function).Bind(this.Notification)
		else if !(function is BoundFunc) {
			name := this.getFuncName(function)
			if (Instr(name, ".")) {
				loop ((cNames := StrSplit(name, ".")).Length)
					classObj := A_Index == 1 ? %cNames[1]% : classObj.%cNames[A_Index]%
				function := function.bind(classObj)
			}
		}
		if (message != "")
			function := function.bind(message)
		function := function.bind(fparams*)
		return function
	}

	/**
	 * Given any function name or object, returns the name of the function as specified by its source code
	 * @param function 
	 * @returns {String} 
	 */
	static getFuncName(function) {
		if !(function is Func) {
			name := this.parseFunctionStringToFunction(function).Name
		} else if (function is BoundFunc) {
			try
				name := BoundFnName(function)
			catch Error
				name := "/ (Unknown)"
		} else {
			name := function.Name ? function.Name : "/ (Lambda)"
		}
		return StrReplace(name, ".Prototype")
	}

	static parseFunctionStringToFunction(function) {
		if InStr(function, "discord")
			return this.Notification.discord
		else if InStr(function, "1337")
			return this.Notification._1337
		else if InStr(function, "Toast")
			return this.Notification.toast
		else if InStr(function, "All") || InStr(function, "Combined")
			return this.Notification.all
		else
			return this.Notification.default
	}

	static _handleTimer(isMulti, callable, index, period?, periodUnit?) {
		MSec := A_MSec
		if (!isMulti) {
			this.timerList.Delete(index)
			if this.Gui.current
				this.Gui.LVDeleteRow(index)
		}
		else {
			nextOccurence := DateAddW(A_Now, period, periodUnit)
			nextTimeMS := 1000 * DateDiff(A_Now, nextOccurence, "Seconds") + MSec - 10 ; -10 -> correction against cases of .999
			if (nextTimeMS > -4294967296)
				SetTimer(this.timerList[index].timer, nextTimeMS)
			this.timerList[index].nextTime := nextOccurence
			if this.Gui.current
				this.Gui.LVModifyRowTimestamp(index, FormatTime(nextOccurence, "yyyy-MM-dd, HH:mm:ss"))
		}
		callable()
	}

	class Gui {
		static __New() {
			this.data := { 
				coords: { x: 565, y: 300 }, 
				variables: {
					reminderIn: { message: "rem1Message", seconds: "rem1S", minutes: "rem1M", hours: "rem1H"},
					reminderOn: { message: "rem2Message", seconds: "rem2S", minutes: "rem2M", hours: "rem2H", days: "rem2D", months: "rem2Mo"}
				} 
			}
			this.core := ReminderManager
			this.current := 0
			this.currentLV := 0
		}

		static Open(*) {
			if this.current
				WinActivate(this.current)
			else
				this.create()
			return 1
		}

		static Close(*) {
			if this.current {
				this.data.coords := WinUtilities.getWindowPlacement(this.current.hwnd)
				this.current.destroy()
				this.current := 0
			}
			return 1
		}

		static Toggle(*) {
			if this.current
				this.Close()
			else
				this.Open()
		}

		static create() {
			static LVN_KEYDOWN := -155
			this.current := Gui("+Border", "Reminder Manager")
			this.current.OnEvent("Escape", (*) => this.close())
			this.current.OnEvent("Close", (*) => this.close())
			this.current.AddGroupBox("Section w400 h90", "Add Reminder in")
			this.current.SetFont("s9")
			this.current.AddText("Center ys+22 xs+10", "Remind me in ")
			; this.gui.AddEdit("ys+20 x+5 r1", 0).Name := this.guiVars.1[5]
			; this.gui.AddText("Center ys+22 x+5", "d")
			this.current.AddEdit("ys+20 x+5 r1 w30", 0).Name := this.data.variables.reminderIn.hours
			this.current.AddText("Center ys+22 x+5", "h")
			this.current.AddEdit("ys+20 x+5 r1 w30", 0).Name := this.data.variables.reminderIn.minutes
			this.current.AddText("Center ys+22 x+5", "m ")
			this.current.AddEdit("ys+20 x+5 r1 w30", 0).Name := this.data.variables.reminderIn.seconds
			this.current.AddText("Center ys+22 x+5", "s")
			this.current.AddText("Center ys+22 x+5", "with the message:")
			this.current.AddEdit("ys+47 xs+10 r2 w375").Name := this.data.variables.reminderIn.message
			this.current.AddButton("ys+5 h60 w80", "Add Reminder").OnEvent("Click", (*) => setReminderIn())
			this.current.AddGroupBox("xs Section w400 h90", "Add Reminder on")
			this.current.SetFont("s9")
			this.current.AddText("Center ys+22 xs+10", "Remind me on")
			this.current.AddEdit("ys+20 x+5 r1 w30", A_DD).Name := this.data.variables.reminderOn.days
			this.current.AddText("Center ys+22 x+5", ".")
			this.current.AddEdit("ys+20 x+5 r1 w30", A_MM).Name := this.data.variables.reminderOn.months
			this.current.AddText("Center ys+22 x+5", ", at")
			this.current.AddEdit("ys+20 x+5 r1 w30", A_Hour).Name := this.data.variables.reminderOn.hours
			this.current.AddText("Center ys+22 x+5", ":")
			this.current.AddEdit("ys+20 x+5 r1 w30", A_Min).Name := this.data.variables.reminderOn.minutes
			this.current.AddText("Center ys+22 x+5 " (this.core.settings.debug ? "" : "Hidden"), ":")
			this.current.AddEdit("ys+20 x+5 r1 w30 " (this.core.settings.debug ? "" : "Hidden"), (this.core.settings.debug ? A_Sec : 0)).Name := this.data.variables.reminderOn.seconds
			this.current.AddText("Center ys+22 x+5", "with the message:")
			this.current.AddEdit("ys+47 xs+10 r2 w375").Name := this.data.variables.reminderOn.message
			this.current.AddButton("ys+5 h60 w80", "Add Reminder").OnEvent("Click", (*) => setReminderOn())
			this.LV := this.current.AddListView("xs R10 w500 -Multi Sort", ["Next Occurence", "Period", "Message", "Function", "Index"])
			this.LV.OnEvent("ContextMenu", onContextMenu)
			this.LV.OnNotify(LVN_KEYDOWN, onKeyPress)
			createListView()
			this.current.Show(Format("x{1}y{2} Autosize", this.data.coords.x, this.data.coords.y))

			createListView() {
				this.LV.Delete()
				this.LV.ModifyCol(5, 0)
				for i, e in this.core.timerList
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

			setReminderIn(*) {
				static names := this.data.variables.reminderIn
				vars := this.current.Submit(0)
				message := vars.%names.message%
				if !(message) {
					if (MsgBox("You have not set a reminder message. Proceed?", "Reminder", 0x1) == "Cancel")
						return
				}
				try
					res := this.core.setTimerIn(0, vars.%names.hours%, vars.%names.minutes%, vars.%names.seconds%, message)
				catch Error as e {
					msgbox("Problem setting the Reminder. Check if entered time is valid.`nSpecifically: " e.What " failed with`n" e.Message)
					return 0
				}
				timedTooltip("Success!", 1000)
				this.current[names.message].Value := ""
				this.current[names.hours].Value := 0
				this.current[names.minutes].Value := 0
				this.current[names.seconds].Value := 0
				createListView()
			}

			setReminderOn(*) {
				static names := this.data.variables.reminderOn
				vars := this.current.Submit(false)
				message := vars.%names.message%
				if !(message) {
					if (MsgBox("You have not set a reminder message. Proceed?", "Reminder", 0x1) == "Cancel")
						return
				}
				try {
					time := nextMatchingTime(, 
						vars.%names.months% != "" ? vars.%names.months% : unset,
						vars.%names.days% != "" ? vars.%names.days% : unset,
						vars.%names.hours% != "" ? vars.%names.hours% : unset,
						vars.%names.minutes% != "" ? vars.%names.minutes% : unset,
						vars.%names.seconds% != "" ? vars.%names.seconds% : unset
					)
					this.core.setTimerOn(time, message)
				}
				catch Error {
					MsgBox("Invalid Time specified.")
					return 0
				}
				timedTooltip("Success!", 1000)
				this.current[names.message].Value := ""
				this.current[names.months].Value := A_Mon
				this.current[names.days].Value := A_MDay
				this.current[names.hours].Value := A_Hour
				this.current[names.minutes].Value := A_Min
				this.current[names.seconds].Value := A_Sec
				createListView()
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
						try SetTimer(this.core.timerList[index].timer, 0)
						this.core.timerList.delete(index)
						this.LV.delete(rowN)
					case "116":	;// F5 Key -> Reload
						createListView()
					default:
						return
				}
			}
		}

		static LVDeleteRow(index) {
			Loop(this.LV.GetCount()) {
				if (this.LV.GetText(A_Index, 5) == index) {
					this.LV.delete(A_Index)
					break
				}
			}
		}

		static LVModifyRowTimestamp(index, timestamp) {
			Loop(this.LV.GetCount()) {
				if (this.LV.GetText(A_Index, 5) == index) {
					this.LV.Modify(A_Index, timestamp)
					this.LV.ModifyCol(1, "AutoHdr Sort")
					break
				}
			}
		}
	}

	/**
	 * Imports reminders from a file. File must containv valid json with an array of values of the following form:
	 * {
	 * 	function: function name or an empty string
	 * 	message: message or an empty string
	 * 	multi: Boolean, whether it is periodic
	 * 	period: must be set if multi is true. Positive Integer.
	 * 	periodUnit: must be set if multi is true. One of Years, Months, Weeks, Days, Hours, Minutes, Seconds
	 * 	units: An object specifying a timestamp, using Years, Months, Days, Hours, Minutes, Seconds.
	 * 	OR nextTime instead of units, a YYYYMODDHHMISS timestamp of the next event
	 * 	fparams
	 * }
	 * @param filePath 
	 * @param {Integer} ignoreInstantNotifications If this is set to true, ignores reminders that would immediately fire (and sets them to trigger on the next possible period discontinuous with now)
	 * @param {Array} overrideReminderFunc Array of functions to use instead of the default for all unset reminders in the file. 
	 * @param {String} encoding 
	 */
	static importReminders(filePath, ignoreInstantNotifications := false, overrideReminderFunc?, overridefparams?, encoding := "UTF-8") {
		jsonStr := FileRead(filePath, encoding)
		remArr := MapToObj(jsongo.Parse(jsonStr))
		for i, o in remArr {
			if o.HasOwnProp('nextTime') && IsTime(o.nextTime)
				earliestTimestamp := o.nextTime
			else {
				y := o.units.HasOwnProp("years") ? o.units.years : unset
				mo := o.units.HasOwnProp("months") ? o.units.months : unset
				d := o.units.HasOwnProp("days") ? o.units.days : unset
				h := o.units.HasOwnProp("hours") ? o.units.hours : unset
				m := o.units.HasOwnProp("minutes") ? o.units.minutes : unset
				s := o.units.HasOwnProp("seconds") ? o.units.seconds : unset
				earliestTimestamp := nextMatchingTime(y?, mo?, d?, h?, m?, s?)
			}
			fparams := o.HasOwnProp("fparams") ? o.fparams : overridefparams ? overridefparams : []
			if !(fparams is Array)
				fparams := [fparams]
			function := o.HasOwnProp("function") ? o.function : overrideReminderFunc ? overrideReminderFunc : ""
			multi := o.HasOwnProp("multi") ? o.multi : 0
			if (ignoreInstantNotifications && Abs(DateDiff(earliestTimestamp, A_Now, "Seconds")) <= 1) {
				if (multi) {
					if o.HasOwnProp('nextTime') && IsTime(o.nextTime) ; exact timestamp -> add period
						this.setPeriodicTimerOn(DateAddW(o.nextTime, o.period, o.periodUnit))
					else {
						units := [y, mo, d, h, m, s]
						Loop (units.Length) { ; trim the smallest unset units.
							if !units.Has(-A_Index)
								units.Pop()
						}
						secondBestTime := nextMatchingTime(units*)
						interval := DateDiffW(secondBestTime, earliestTimestamp, o.periodUnit)
						if (interval > o.period)
							secondBestTime := DateAddW(secondBestTime, -(interval // o.period) * o.period, o.periodUnit)
						this.setPeriodicTimerOn(secondBestTime, o.period, o.periodUnit, o.message, function, fparams*)
					}
				}
				continue
			}
			if (o.multi)
				this.setPeriodicTimerOn(earliestTimestamp, o.period, o.periodUnit, o.message, function, fparams*)
			else
				this.setTimerOn(earliestTimestamp, o.message, function, fparams*)
		}
	}

	static exportReminders(filepath := "") {
		jsonString := jsongo.Stringify(this.timerList, ["timer"], "`t")
		FileOpen(filePath, "w", "UTF-8").Write(jsonString)
	}

	class Notification {

		static __New() {
			this.core := ReminderManager
			this.default := this.notificationAsyncMsgBox
		}

		static generateReminderMessage(msg) {
			time := FormatTime("L1033", "dddd, dd.MM.yyyy, HH:mm:ss") ; L1033 -> en-US for day name.
			message := "It is " . time . "`nYou set a reminder for this point in time."
			message .= (msg == "" ? "" : "`nReminder Message: " . msg)
			return message
		}

		static notificationAsyncMsgBox(msg := "") {
			SoundPlay("*48")
			MsgBoxAsGui(this.generateReminderMessage(msg), "Reminder")
		}

		static _1337(*) {
			SoundPlay("*48")
			MsgBoxAsGui("Copy 1337 in clipboard and activate discord?", "1337", 0x1, , , (r) => (
				r == "Cancel" ? 0 :
				(
					A_Clipboard := "1337",
					WinExist("Discord") ? WinActivate() : 0
				)
			))
		}

		/**
		 * Sends a notification with the specified text to a discord user with the specified id
		 * @param msg The message to send.
		 * @param id The id of the user.
		 */
		static discord(msg, id) {
			static bot := DiscordBot(this.core.settings.token)
			bot.sendMessageToUser(id, { content: this.generateReminderMessage(msg) })
		}

		static toast(msg) {
			TrayTip(this.generateReminderMessage(msg), "Reminder")
		}

		/**
		 * Sends a notification with the specified text to a discord user with the specified id as well as displaying it on screen through both msgbox and toast
		 * @param msg The message to send.
		 * @param id The id of the user.
		 */
		static all(msg, id) {
			this.notificationAsyncMsgBox(msg)
			this.toast(msg)
			this.discord(msg, id)
		}
	}
}
