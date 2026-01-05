; https://github.com/cobracrystal/ahk
; todo:
; OPTION TO MAKE REMINDER MESSAGE A TOOLTIP.
; todo: save reminders over multiple restarts in ini file.
; then just load those up on starting -> no need to call 1337 reminder everytime. tada
; custom functions -> text body of function that you write just gets saved in file, timer is set to run that file

; if nextTimeMS >= 2**32, do nextTimeMS -= 2**32, custom function that will restart itself until timeMS < 2**32, then launch function.
#Include "%A_LineFile%\..\..\LibrariesV2\TimeUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\ObjectUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\WinUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\DiscordBot.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\jsongo.ahk"

class TimerWorker {
	
	/**
	 * Initializes some settings
	 */
	static __New() {
		guiMenu := TrayMenu.submenus["GUIs"]
		guiMenu.Add("Open Reminder Manager", (*) => this.Gui.Open())
		A_TrayMenu.Add("GUIs", guiMenu)
		this.settings := { 
			debug: 0, 
			token: 0, 
			notifyOnMissedRemindersThreshold: 86400, 
			omitBlankValuesOnSave: 1, 
			logReminders: true,
			defaultCachePath: "Reminders\reminders.json", 
			defaultLogPath: "Reminders\log.txt"
		}
		this.timerList := Map()
	}

	/**
	 * Sets options for TimerWorker usage.
	 * @param flagDebug Enables seconds for reminders and more notifications
	 * @param {Integer} threshold Threshold beyond which missed reminders will not be notified
	 * @param token Discord token.
	 */
	static setOptions(flagDebug?,  token?, threshold := this.settings.notifyOnMissedRemindersThreshold, notification := this.Notification.default, omitBlankValuesOnSave := true) {
		if IsSet(flagDebug)
			this.settings.debug := flagDebug
		if IsSet(token)
			this.settings.token := token
		this.settings.notifyOnMissedRemindersThreshold := threshold
		this.settings.omitBlankValuesOnSave := omitBlankValuesOnSave
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
	 * @param time 
	 * @param {String|Integer|Object} time A string/Integer representing a valid YYYYMMDDHHMISS timestamp or an object with specified time units. 
	 * @param {String} message The message to display
	 * @param {String} function A function object or name of a valid Notification function
	 * @param {Any*} fparams Additional parameters to feed the function 
	 * @returns {Integer} 
	 */
	static setTimerOn(time, message := "", function := "", fparams*) {
		MSec := A_MSec
		flagTimeUnitObject := IsObject(time)
		timestamp := flagTimeUnitObject ? nextMatchingTime(flattenTimeVariableObject(time)*) : time
		if (!IsTime(timestamp))
			throw (Error("Invalid Timestamp given: " . timestamp))
		timeDiff := DateDiff(timestamp, A_Now, "Seconds")
		if (timeDiff < 0)
			throw (Error("Cannot create Reminder in the Past: " timestamp " is " timeDiff * -1 " seconds in the past."))
		nextTimeMS := (timeDiff == 0 ? MSec - 1000 : timeDiff * -1000 + MSec - 10)
		funcName := this.getFuncName(function)
		callable := this.getCallableNotification(message, function,,, fparams*)
		listKey := format("{:012}", nextTimeMS * -1) '_' A_Now . MSec . '_' . 0 . '_' . message
		if (nextTimeMS > -4294967296)
			timerObj := this._handleTimer.bind(this, callable, listKey, 0)
		else {
			timerObj := this._handleTimer.bind(this, callable, listKey,,,, true, timestamp)
			nextTimeMS := -4000000000
		}
		reminderObj := {
			function: funcName,
			message: message,
			multi: 0,
			fparams: fparams,
			timer: timerObj,
			occurenceTimestamp: timestamp
		}
		if flagTimeUnitObject
			reminderObj.units := time
		else
			reminderObj.nextTime := timestamp
		this.timerList[listKey] := reminderObj
		SetTimer(timerObj, nextTimeMS)
		return 1
	}

	/**
	 * Sets a timer with given period after a given time
	 * If neither a message or function object are specified, a simple message box will open.
	 * @param {String|Integer|Object} time A string/Integer representing a valid YYYYMMDDHHMISS timestamp or an object with specified time units. 
	 * @param {Integer} period Integer period in which the timer will repeat
	 * @param {String} periodUnit Time Unit can be one of the strings (or their first letter): Years, Weeks, Days, Hours, Minutes, Seconds
	 * @param {String} message An optional message to display when the reminder finishes.
	 * @param {String} function An optional function object that will be called when the reminder finishes. If both function and message are given, the function object must accept at least one parameter. Alternatively, specify a name of any of the .Notification functions
	 * @param {Any*} fparams Optional parameters passed to the function, used for "discordReminder" or other special reminders
	 */
	static setPeriodicTimerOn(time, period := 1, periodUnit := "Days", message := "", function := "", fparams*) {
		MSec := A_Msec
		Now := A_Now
		periodUnit := validateTimeUnit(periodUnit)
		flagTimeUnitObject := IsObject(time)
		timestamp := flagTimeUnitObject ? nextMatchingTime(flattenTimeVariableObject(time)*) : time
		nextTime := getNextPeriodicTimestamp(timestamp, period, periodUnit)
		timeDiff := DateDiffW(nextTime, Now, "Seconds")
		nextTimeMS := (timeDiff == 0 ? MSec - 1000 : timeDiff * -1000 + MSec - 10)
		if (this.settings.debug)
			timedTooltip(nextTimeMS "`n" MSec)
		listKey := format("{:012}", nextTimeMS * -1) '_' A_Now . MSec . '_' . 1 . '_' . message
		funcName := this.getFuncName(function)
		callable := this.getCallableNotification(message, function,,, fparams*)
		if (nextTimeMS > -4294967296)
			timerObj := this._handleTimer.bind(this, callable, listKey, 1, period, periodUnit)
		else {
			timerObj := this._handleTimer.bind(this, callable, listKey, 1, period, periodUnit, true, timestamp)
			nextTimeMS := -4000000000
		}
		reminderObj := {
			function: funcName,
			message: message,
			multi: 1, 
			period: period, 
			periodUnit: periodUnit, 
			fparams: fparams,
			timer: timerObj,
			occurenceTimestamp: timestamp
		}
		if flagTimeUnitObject
			reminderObj.units := time
		else
			reminderObj.nextTime := timestamp
		this.timerList[listKey] := reminderObj
		SetTimer(timerObj, nextTimeMS)
	}

	/**
	 * Given a function name or object, creates a callable object to set the timer for
	 * @param message 
	 * @param function 
	 * @param fparams 
	 * @returns {BoundFunc} 
	 */
	static getCallableNotification(message, function, missedNotification := 0, oldTimestamp?, fparams*) {
		if !(function is Func)
			function := this.parseFunctionStringToFunction(function).Bind(this.Notification)
		else if !(function is BoundFunc) {
			name := this.getFuncName(function)
			if (Instr(name, ".")) {
				loop ((cNames := StrSplit(name, ".")).Length - 1)
					classObj := A_Index == 1 ? %cNames[1]% : classObj.%cNames[A_Index]%
				function := function.bind(classObj)
			}
		}
		function := function.bind({message: message, missed: missedNotification, oldTimestamp: oldTimestamp?})
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

	static _handleTimer(callable, listKey, isMulti := 0, period?, periodUnit?, isExtended := 0, finalTimestamp := 0) {
		MSec := A_MSec
		if (isExtended) { ; for timers that are too long
			reminderObj := this.timerList[listKey]
			timeDiff := DateDiffW(finalTimestamp, A_Now, "Seconds")
			nextTimeMS := (timeDiff == 0 ? MSec - 1000 : timeDiff * -1000 + MSec - 10)
			if (nextTimeMS > -4294967296) {
				newTimerObj := this._handleTimer.bind(this, callable, listKey, isMulti, period?, periodUnit?)
				reminderObj.timer := newTimerObj
				SetTimer(newTimerObj, nextTimeMS)
			} else {
				SetTimer(reminderObj.timer, -4000000000)
			}
			return
		}
		reminderObj := this.timerList.Delete(listKey)
		if (!isMulti) {
			if this.Gui.current
				this.Gui.LVDeleteRow(listKey)
			this.exportReminders(this.settings.defaultCachePath)
			if this.settings.logReminders
				this.logReminder(reminderObj.message, A_Now)
		} else {
			nextOccurence := DateAddW(A_Now, period, periodUnit)
			nextTimeMS := 1000 * DateDiff(A_Now, nextOccurence, "Seconds") + MSec - 10 ; -10 -> correction against cases of .999
			listKey := format("{:012}", nextTimeMS * -1) '_' A_Now . MSec . '_' . isMulti . '_' . reminderObj.message
			if (nextTimeMS > -4294967296) {
				newTimerObj := this._handleTimer.bind(this, callable, listKey, 1, period, periodUnit)
				SetTimer(newTimerObj, nextTimeMS)
			} else {
				newTimerObj := this._handleTimer.bind(this, callable, listKey, 1, period, periodUnit, 1, nextOccurence)
				SetTimer(newTimerObj, -4000000000)
			}
			reminderObj.timer := newTimerObj
			this.timerList[listKey] := reminderObj
			if this.Gui.current
				this.Gui.LVModifyRowTimestamp(listKey, formatTimeISO8601(nextOccurence, ', '))
		}
		callable()
	}

	class Gui {
		static __New() {
			this.data := { 
				coords: { x: 565, y: 300 }, 
				variables: {
					reminderIn: { message: "rem1Message", seconds: "rem1S", minutes: "rem1M", hours: "rem1H"},
					reminderOn: { message: "rem2Message", seconds: "rem2S", minutes: "rem2M", hours: "rem2H", days: "rem2D", months: "rem2Mo"},
					multiReminderOn: { message: "rem3Message", seconds: "rem3S", minutes: "rem3M", hours: "rem3H", days: "rem3D", months: "rem3Mo", period: "rem3P", periodUnit: "rem3PU" }
				} 
			}
			this.core := TimerWorker
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
			this.current.AddGroupBox("Section w411 h90", "Add Reminder in")
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
			this.current.AddButton("ys+5 h85 w80", "Add Reminder").OnEvent("Click", (*) => setReminderIn())
			this.current.AddButton("ys+5 h30 w65", "Settings").OnEvent("Click", (*) => settingsGui())
			this.current.AddButton("xp h49 w65", "Recurring`nReminders").OnEvent("Click", (*) => recurringReminderGui())
			this.current.AddGroupBox("xs Section w411 h90", "Add Reminder on")
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
			this.current.AddButton("ys+5 h85 w80", "Add Reminder").OnEvent("Click", (*) => setReminderOn())
			this.LV := this.current.AddListView("xs R10 w575 -Multi Sort", ["Next Occurence", "Period", "Message", "Function", "Index"])
			this.LV.OnEvent("ContextMenu", onContextMenu)
			this.LV.OnNotify(LVN_KEYDOWN, onKeyPress)
			createListView()
			this.current.Show(Format("x{1}y{2} Autosize", this.data.coords.x, this.data.coords.y))

			createListView() {
				this.LV.Delete()
				if !this.core.settings.debug
					this.LV.ModifyCol(5, 0)
				for i, e in this.core.timerList {
					this.LV.Add(, 
						formatTimeISO8601(e.occurenceTimestamp, ', '),
						HasProp(e, "period") ? e.period " " (e.period == 1 ? SubStr(e.periodUnit, 1, -1) : e.periodUnit) : "/",
						e.message,
						e.function,
						i
					)
				}
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
				this.core.exportReminders(this.core.settings.defaultCachePath)
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
				this.core.exportReminders(this.core.settings.defaultCachePath)
				timedTooltip("Success!", 1000)
				this.current[names.message].Value := ""
				this.current[names.months].Value := A_Mon
				this.current[names.days].Value := A_MDay
				this.current[names.hours].Value := A_Hour
				this.current[names.minutes].Value := A_Min
				this.current[names.seconds].Value := this.core.settings.debug ? A_Sec : 0 
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
						key := this.LV.GetText(rowN, 5)
						try SetTimer(this.core.timerList[key].timer, 0)
						if !this.core.timerList[key].multi
							this.core.timerList.Delete(key)
						this.LV.delete(rowN)
					case "116":	;// F5 Key -> Reload
						createListView()
					default:
						return
				}
			}

			settingsGui(*) {
				return
			}

			recurringReminderGui(*) {
				multiRemGui := Gui("+Border", "Recurring Reminder Creator")
				multiRemGui.OnEvent("Escape", (*) => multiRemGui.Destroy())
				multiRemGui.OnEvent("Close", (*) => multiRemGui.Destroy())
				multiRemGui.AddGroupBox("Section w400 h125", "Add Recurring Reminder")
				multiRemGui.SetFont("s9")
				multiRemGui.AddText("Center R1.45 ys+22 xs+10", "Remind me on")
				multiRemGui.AddEdit("ys+20 x+5 r1 w30", '/').Name := this.data.variables.multiReminderOn.days
				multiRemGui.AddText("Center R1.45 ys+22 x+5", ".")
				multiRemGui.AddEdit("ys+20 x+5 r1 w30", '/').Name := this.data.variables.multiReminderOn.months
				multiRemGui.AddText("Center R1.45 ys+22 x+5", " at")
				multiRemGui.AddEdit("ys+20 x+5 r1 w30", '/').Name := this.data.variables.multiReminderOn.hours
				multiRemGui.AddText("Center R1.45 ys+22 x+5", ":")
				multiRemGui.AddEdit("ys+20 x+5 r1 w30", '/').Name := this.data.variables.multiReminderOn.minutes
				multiRemGui.AddText("Center R1.45 ys+22 x+5", ":")
				multiRemGui.AddEdit("ys+20 x+5 r1 w30", '/').Name := this.data.variables.multiReminderOn.seconds
				multiRemGui.AddText("Center R1.45 ys+50 xs+10", "and then every")
				multiRemGui.AddEdit("ys+47 x+5 r1 w30", '1').Name := this.data.variables.multiReminderOn.period
				multiRemGui.AddDDL("ys+47 x+5 r7 w65 Choose1", ["Years", "Months", "Weeks", "Days", "Hours", "Minutes", "Seconds"]).Name := this.data.variables.multiReminderOn.periodUnit
				multiRemGui.AddText("Center R1.45 ys+50 x+5", "with the message:")
				multiRemGui.AddEdit("ys+74 xs+10 r2 w375").Name := this.data.variables.multiReminderOn.message
				multiRemGui.AddButton("ys+5 h85 w80", "Add Reminder").OnEvent("Click", (*) => setRecurringReminderOn())
				multiRemGui.Show("Autosize")

				setRecurringReminderOn() {
					static names := this.data.variables.multiReminderOn
					vars := multiRemGui.Submit(false)
					message := vars.%names.message%
					period := vars.%names.period%
					periodUnit := vars.%names.periodUnit%
					if !(message) || !(period)
						return MsgBoxAsGui("You have not set a reminder message or have entered an invalid period. You must set both before setting a multireminder.", "Reminder")
					try {
						units := {
							months: IsInteger(vars.%names.months%) ? vars.%names.months% : unset,
							days: IsInteger(vars.%names.days%) ? vars.%names.days% : unset,
							hours: IsInteger(vars.%names.hours%) ? vars.%names.hours% : unset,
							minutes: IsInteger(vars.%names.minutes%) ? vars.%names.minutes% : unset,
							seconds: IsInteger(vars.%names.seconds%) ? vars.%names.seconds% : unset
						}
						this.core.setPeriodicTimerOn(units, period, periodUnit, message)
					}
					catch Error {
						MsgBox("Invalid Time specified.")
						return 0
					}
					this.core.exportReminders(this.core.settings.defaultCachePath)
					timedTooltip("Success!", 1000)
					multiRemGui[names.message].Value := ""
					multiRemGui[names.months].Value := '/'
					multiRemGui[names.days].Value := '/'
					multiRemGui[names.hours].Value := '/'
					multiRemGui[names.minutes].Value := '/'
					multiRemGui[names.seconds].Value := '/'
					multiRemGui[names.period].Value := '/'
					multiRemGui[names.periodUnit].Choose(1)
					createListView()
				}
			}

		}

		static LVDeleteRow(key) {
			Loop(this.LV.GetCount()) {
				if (this.LV.GetText(A_Index, 5) == key) {
					this.LV.delete(A_Index)
					break
				}
			}
		}

		static LVModifyRowTimestamp(key, timestamp) {
			Loop(this.LV.GetCount()) {
				if (this.LV.GetText(A_Index, 5) == key) {
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
	static importReminders(filePath, ignoreInstantNotifications := false, ignoreMissedNotifications := false, overrideReminderFunc?, overridefparams?, encoding := "UTF-8") {
		jsonStr := FileRead(filePath, encoding)
		remArr := MapToObj(jsongo.Parse(jsonStr))
		flagUpdateCache := false
		for i, o in remArr {
			if o.HasOwnProp('nextTime') && IsTime(o.nextTime) {
				timeParam := o.nextTime
				earliestTimestamp := timeParam
			} else {
				timeParam := o.units
				unitArr := flattenTimeVariableObject(timeParam)
				earliestTimestamp := nextMatchingTime(unitArr*)
			}
			fparams := o.HasOwnProp("fparams") ? o.fparams : overridefparams && !o.HasOwnProp("function") ? overridefparams : []
			if !(fparams is Array)
				fparams := [fparams]
			function := o.HasOwnProp("function") ? o.function : overrideReminderFunc ? overrideReminderFunc : ""
			multi := o.HasOwnProp("multi") ? o.multi : 0
			if (earliestTimestamp == 0)
				earliestTimestamp := lastMatchingTime(unitArr*)
			diff := DateDiff(A_Now, earliestTimestamp, 'S')
			if (diff > 1) && !multi { ; we are in the past
				if ignoreMissedNotifications
					continue
				flagUpdateCache := true
				if (diff > this.settings.notifyOnMissedRemindersThreshold)
					continue
				this.getCallableNotification(o.message, function, 1, earliestTimestamp, fparams*).Call()
				if this.settings.logReminders
					this.logReminder(o.message, earliestTimestamp)
				continue
			} else if (ignoreInstantNotifications && Abs(DateDiff(earliestTimestamp, A_Now, "Seconds")) <= 1) {
				if (multi) {
					if o.HasOwnProp('nextTime') && IsTime(o.nextTime) ; exact timestamp -> add period
						this.setPeriodicTimerOn(DateAddW(o.nextTime, o.period, o.periodUnit), o.period, o.periodUnit)
					else {
						lastSetUnitIndex := getTimeUnitInfo(unitArr).last ; ignore year
						; leftalign with spaces, replace spaces with 0. 2+lastSetUnitIndex*2 because everything but the year has width 2
						timestampPart := SubStr(earliestTimestamp, 1, 2+lastSetUnitIndex*2)
						if lastSetUnitIndex < 2
							timestampPart .= '01'
						if lastSetUnitIndex < 3
							timestampPart .= '01'
						minimalEarliestTimestamp := StrReplace(Format("{:-14}",timestampPart), ' ', 0)
						secondBestTime := DateAddW(minimalEarliestTimestamp, 1, o.periodUnit)
						this.setPeriodicTimerOn(secondBestTime, o.period, o.periodUnit, o.message, function, fparams*)
					}
				}
				continue
			}
			if (o.multi)
				this.setPeriodicTimerOn(timeParam, o.period, o.periodUnit, o.message, function, fparams*)
			else
				this.setTimerOn(timeParam, o.message, function, fparams*)
		}
		if flagUpdateCache
			this.exportReminders(this.settings.defaultCachePath)

		tf(n) => Format("{:02}", n)
	}

	static exportReminders(filepath := "") {
		arr := []
		for i, e in this.timerList
			arr.push(e)
		jsonString := jsongo.Stringify(arr, ["timer", "occurenceTimestamp"], "`t")
		FileOpen(filePath, "w", "UTF-8").Write(jsonString)
	}

	static logReminder(message, timestamp) {
		str := '[' formatTimeISO8601(timestamp, ' ') '] Message: ' message '`n'
		FileAppend(str, this.settings.defaultLogPath, 'UTF-8')
	}

	class Notification {

		static __New() {
			this.core := TimerWorker
			this.default := this.notificationAsyncMsgBox
		}

		static generateReminderMessage(msgObj) {
			message := "It is " . formatTimeLongDateTimeUS() . "`n"
			message .= msgObj.missed ? ("You have a missed reminder from " . formatTimeLongDateTimeUS(msgObj.oldTimestamp)) : "You set a reminder for this point in time."
			message .= (msgObj.message == "" ? "" : "`nReminder Message: " . msgObj.message)
			return message
		}

		static notificationAsyncMsgBox(msgObj := "") {
			SoundPlay("*48")
			MsgBoxAsGui(this.generateReminderMessage(msgObj), "Reminder")
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
		static discord(msgObj, id) {
			static bot := DiscordBot(this.core.settings.token)
			bot.sendMessageToUser(id, { content: this.generateReminderMessage(msgObj) })
		}

		static toast(msgObj) {
			TrayTip(this.generateReminderMessage(msgObj), "Reminder")
		}

		/**
		 * Sends a notification with the specified text to a discord user with the specified id as well as displaying it on screen through both msgbox and toast
		 * @param msgObj The message to send.
		 * @param id The id of the user.
		 */
		static all(msgObj, id) {
			this.notificationAsyncMsgBox(msgObj)
			this.toast(msgObj)
			this.discord(msgObj, id)
		}
	}
}
