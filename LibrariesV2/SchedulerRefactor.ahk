/*
listview for windows sucks still
missedNotification, oldTimestamp in functioncallable removed -> create new funcs in notification for missed timers and manually bind them
*/


; https://github.com/cobracrystal/ahk
; todo:
; custom functions -> text body of function that you write just gets saved in file, timer is set to run that file
; add function like .resume() or something that imports timers from the cache of functions
#Include "BasicUtilities.ahk"
#Include "TimeUtilities.ahk"
#Include "ObjectUtilities.ahk"
#Include "WinUtilities.ahk"
#Include "DiscordBot.ahk"
#Include "MsgBoxAsGui.ahk"
#Include "External\jsongo.ahk"

class Scheduler {
	; internal list to track all timers
	static timerMap := Map()

	/**
	 * Schedules a function to be called in a certain time in the future
	 * @param {Integer} days Days after which the timer will be called
	 * @param {Integer} hours Hours after which the timer will be called
	 * @param {Integer} minutes Minutes after which the timer will be called
	 * @param {Integer} seconds Seconds after which the timer will be called
	 * @param {Func} function An (unbound) Function which will be called when the timer triggers. Unbound functions are usually simpler to handle as their name can be easily retrieved.
	 * @param {Any*} fparams The parameters to call with the function.
	 * @returns {Integer} 
	 */
	static setOnceIn(days := 0, hours := 0, minutes := 0, seconds := 0, function := Scheduler.Notification.default, fparams*) {
		time := DateAdd(A_Now, days, "Days")
		time := DateAdd(time, hours, "Hours")
		time := DateAdd(time, minutes, "Minutes")
		time := DateAdd(time, seconds, "Seconds")
		return this.setOnceOn(time, function, fparams*)
	}

	/**
	 * Schedules a function to be called at a given point in the future
	 * @param {Integer|String} time A timestamp in the future at which point the function will be called
	 * @param {Func} function An (unbound) Function which will be called when the timer triggers. Unbound functions are usually simpler to handle as their name can be easily retrieved.
	 * @param {Any*} fparams The parameters to call with the function.
	 * @returns {Integer} 
	 */
	static setOnceOn(time, function := Scheduler.Notification.default, fparams*) {
		MSec := A_MSec
		Now := A_Now
		timestamp := time is Object ? nextMatchingTime(Now, flattenTimeVariableObject(time)*) : time
		if (!IsTime(timestamp))
			throw Error("Invalid Timestamp given: " timestamp)
		timeDiff := DateDiff(timestamp, Now, "Seconds")
		if (timeDiff < 0)
			throw Error("Cannot create Timer in the Past: " timestamp " is " timeDiff * -1 " seconds in the past.")
		nextTimeMS := (timeDiff == 0 ? MSec - 1000 : timeDiff * -1000 + MSec - 10)
		callableFuncBound := this.bindFunctionParams(function, fparams*)
		uniqueTimerID := this.getUniqueTimerID(-nextTimeMS, false)
		if (nextTimeMS > -4294967296)
			_handleTimerBound := this.handleTimer.bind(this, callableFuncBound, uniqueTimerID, false)
		else {
			_handleTimerBound := this.handleTimer.bind(this, callableFuncBound, uniqueTimerID, false, true, timestamp)
			nextTimeMS := -4000000000
		}
		timerMetadata := {
			function: function,
			functionName: this.getFuncName(function),
			multi: 0,
			timer: _handleTimerBound,
			nextOccurenceTime: timestamp,
			fparams: fparams.Length > 0 ? fparams : unset
		}
		if time is Object
			timerMetadata.units := time
		else
			timerMetadata.nextTime := timestamp
		this.timerMap[uniqueTimerID] := timerMetadata
		SetTimer(_handleTimerBound, nextTimeMS)
		return 1
	}

	/**
	 * Sets a timer with given period after a given time
	 * If no function object is specified, a simple message box will open.
	 * @param {String|Integer|Object} time A string/Integer representing a valid YYYYMMDDHHMISS timestamp or an object with specified time units. 
	 * @param {Integer} period Integer period in which the timer will repeat
	 * @param {String} periodUnit Time Unit can be one of the strings (or their first letter): Years, Weeks, Days, Hours, Minutes, Seconds
	 * @param {String} function An optional function object that will be called when the timer finishes. If both function and fparams are given, the function object must accept all of these parameters. Alternatively, specify a name of any of the .Notification functions
	 * @param {Any*} fparams Optional parameters passed to the function, used for "Notification.discord" or other custom timers
	 */
	static setOnAndRepeat(time, period := 1, periodUnit := "Days", function := Scheduler.Notification.default, fparams*) {
		MSec := A_Msec
		Now := A_Now
		periodUnit := validateTimeUnit(periodUnit)
		timestamp := time is Object ? nextMatchingTime(Now, flattenTimeVariableObject(time)*) : time
		if time is Object && !timestamp
			timestamp := earliestMatchingTime(flattenTimeVariableObject(time)*)
		nextTime := getNextPeriodicTimestamp(timestamp, period, periodUnit, Now)
		timeDiff := DateDiffW(nextTime, Now, "Seconds")
		nextTimeMS := (timeDiff == 0 ? MSec - 1000 : timeDiff * -1000 + MSec - 10)
		uniqueTimerID := this.getUniqueTimerID(-nextTime, true)
		callableFuncBound := this.bindFunctionParams(function, fparams*)
		if (nextTimeMS > -4294967296)
			_handleTimerBound := this.handleTimer.bind(this, callableFuncBound, uniqueTimerID, true)
		else {
			_handleTimerBound := this.handleTimer.bind(this, callableFuncBound, uniqueTimerID, true, true, nextTime)
			nextTimeMS := -4000000000
		}
		timerMetadata := {
			function: function,
			functionName: this.getFuncName(function),
			multi: 1, 
			period: period, 
			periodUnit: periodUnit,
			timer: _handleTimerBound,
			nextOccurenceTime: nextTime,
			fparams: fparams.Length > 0 ? fparams : unset
		}
		if time is Object
			timerMetadata.units := time
		else
			timerMetadata.nextTime := timestamp
		this.timerMap[uniqueTimerID] := timerMetadata
		SetTimer(_handleTimerBound, nextTimeMS)
	}

	static handleTimer(callableFuncBound, uniqueTimerID, isMulti := 0, isExtended := 0, extendedTimestamp := 0) {
		MSec := A_MSec
		if (isExtended) { ; for timers that are too long
			timerMetadata := this.timerMap[uniqueTimerID]
			timeDiff := DateDiffW(extendedTimestamp, A_Now, "Seconds")
			nextTimeMS := (timeDiff == 0 ? MSec - 1000 : timeDiff * -1000 + MSec - 10)
			if (nextTimeMS > -4294967296) {
				_handleTimerBound := this.handleTimer.bind(this, callableFuncBound, uniqueTimerID, isMulti)
				timerMetadata.timer := _handleTimerBound
				SetTimer(_handleTimerBound, nextTimeMS)
			} else {
				SetTimer(timerMetadata.timer, -4000000000)
			}
			return uniqueTimerID
		}
		timerMetadata := this.timerMap.Delete(uniqueTimerID)
		if isMulti {
			nextOccurence := DateAddW(timerMetadata.nextOccurenceTime, timerMetadata.period, timerMetadata.periodUnit)
			timerMetadata.nextOccurenceTime := nextOccurence
			nextTimeMS := 1000 * DateDiff(A_Now, nextOccurence, "Seconds") + MSec - 10 ; -10 -> correction against cases of .999
			uniqueTimerID := this.getUniqueTimerID(nextTimeMS, isMulti)
			if (nextTimeMS > -4294967296) {
				_handleTimerBound := this.handleTimer.bind(this, callableFuncBound, uniqueTimerID, isMulti)
				SetTimer(_handleTimerBound, nextTimeMS)
			} else {
				_handleTimerBound := this.handleTimer.bind(this, callableFuncBound, uniqueTimerID, isMulti, true, nextOccurence)
				SetTimer(_handleTimerBound, -4000000000)
			}
			timerMetadata.timer := _handleTimerBound
			this.timerMap[uniqueTimerID] := timerMetadata
		}
		callableFuncBound()
		return uniqueTimerID
	}

	; generates a unique ID to use for the timer map
	static getUniqueTimerID(NegativeDeltaTimeMS, isMulti) {
		static count := 1
		return Format("{:012}.{}.{}.{}.{:06}", -NegativeDeltaTimeMS, A_Now, A_MSec, isMulti, count++)
	}
	
	/**
	 * Binds the given parameters to the given function, binding (this) if the function is a class member
	 * @param {Func} function The function to bind
	 * @param {Any*} fparams The parameters to bind to the function
	 * @returns {Any} 
	 */
	static bindFunctionParams(function, fparams*) {
		if !(function is Func)
			throw(TypeError("bindFunctionParams received " Type(function)))
		if !(function is BoundFunc) && (classObj := getLowerClassFromName(function.Name))
			function := function.bind(classObj)
		function := function.bind(fparams*)
		return function
	}

	/**
	 * Given any function object, returns the name of the function as specified by its source code
	 * @param function 
	 * @returns {String} 
	 */
	static getFuncName(function) {
		if !(function is Func)
			throw(TypeError("getFuncName requires a function. Got: " Type(function)))
		if function is BoundFunc {
			try
				name := getBoundFuncName(function)
			catch
				name := "/ (Unknown)"
		} else {
			name := function.Name ? function.Name : "/ (Lambda)"
		}
		return StrReplace(name, ".Prototype")
	}

	class Notification {

		static default := this.asyncMsgBox
		static discordToken := 0

		static setToken(token) => this.discordToken := token

		static generateNotificationMessage(text?) {
			message := "It is " . formatTimeLongDateTimeUS() . "`n"
			message .= "You set a Notification for this point in time."
			message .= (IsSet(text) && text != "" ? "`nNotification Message: " . text : '')
			return message
		}

		static asyncMsgBox(text?) {
			SoundPlay("*48")
			MsgBoxAsGui(this.generateNotificationMessage(text?), "Notification")
		}

		/**
		 * Sends a notification with the specified text to a discord user with the specified id
		 * @param id The id of the user.
		 * @param msg The message to send.
		 */
		static discord(id, text?) {
			if !this.discordToken
				throw(Error("Attempted to send Discord Notification, but no token was set"))
			DiscordBot(this.discordToken).sendMessageToUser(id, { content: this.generateNotificationMessage(text?) })
		}

		static toast(text?) => TrayTip(this.generateNotificationMessage(text?), "Notification")

		static tooltip(text?) => ToolTip(this.generateNotificationMessage(text?))

		/**
		 * Sends a notification with the specified text to a discord user with the specified id as well as displaying it on screen through both msgbox and toast
		 * @param id The id of the user.
		 * @param text 
		 */
		static all(id, text?) {
			this.asyncMsgBox(text)
			this.toast(text)
			if this.discordToken
				this.discord(id, text)
		}
	}
}

class PersistentScheduler extends Scheduler {
	static missedTimersCutoff := 602400
	static doLogging := true
	static cachePath := "Scheduler\timers.json"
	static logPath := "Scheduler\log_testing.txt"

	/**
	 * Imports timers from a file. File must contain valid json with an array of values of the following form:
	 * {
	 * 	function: function name or an empty string
	 * 	multi: Boolean, whether it is periodic
	 * 	period: must be set if multi is true. Positive Integer.
	 * 	periodUnit: must be set if multi is true. One of Years, Months, Weeks, Days, Hours, Minutes, Seconds
	 * 	units: An object specifying a timestamp, using Years, Months, Days, Hours, Minutes, Seconds.
	 * 	OR nextTime instead of units, a YYYYMODDHHMISS timestamp of the next event
	 * 	fparams: array or string
	 * }
	/**
	 * Imports timers from the given json file, which must contain an array of objects each of which represents a (partial) scheduler timerMetadata object.
	 * @param {String} filePath The file to import
	 * @param {Integer} ignoreInstantNotifications If this is set to true, timers that would immediately run are ignored.
	 * @param {Integer} runMissedTimers If this is set to true, single-use timers that would have ran in the past are run now.
	 * @param {Func} defaultFunction The function to use if no function is provided in timerMetadata or the provided function name could not be resolved.
	 * @returns {Integer} Amount of imported timers
	 */
	static importTimers(filePath := this.cachePath, ignoreInstantNotifications := false, runMissedTimers := true, defaultFunction := Scheduler.Notification.default) {
		Now := A_Now
		timerArr := jsongo.Parse(FileRead(filePath, 'UTF-8'))
		for index, timerMetadata in timerArr {
			; get parameters from given objects
			if timerMetadata.Has("functionName") && (fn := getValueFromName(timerMetadata["functionName"]))
				function := fn
			else
				function := defaultFunction
			fparams := timerMetadata.Has("fparams") ? (timerMetadata["fparams"] is Array ? timerMetadata["fparams"] : [timerMetadata["fparams"]]) : []
			multi := timerMetadata.HasOwnProp("multi") ? timerMetadata["multi"] : 0
			
			if timerMetadata.Has('nextTime') {
				givenTimeParam := timerMetadata["nextTime"]
				timerTimestamp := givenTimeParam
			} else {
				givenTimeParam := timerMetadata["units"]
				unitArr := flattenTimeVariableObject(givenTimeParam)
				timerTimestamp := nextMatchingTime(Now, unitArr*)
				if (timerTimestamp == 0)
					timerTimestamp := multi ? earliestMatchingTime(unitArr*) : lastMatchingTime(unitArr*) ; for usage later
			}
			
			deltaTime := DateDiff(Now, timerTimestamp, 'S')
			if (deltaTime > 1) && !multi { ; Non-Multi reminders in the past are subject to runMissedTimers
				if multi
					throw(Error("you're stupid and missed something"))
				if !runMissedTimers
					continue
				flagExportToCache := true ; order is relevant, if we run missed timers we drop them, else we don't.
				if (deltaTime > this.missedTimersCutoff)
					continue
				try { ; a jank method to force missed timers to use PersistentScheduler.Notification.Missed functions if defined 
					this.bindFunctionParams(this.Notification.Missed.%StrSplit(function.Name, ".")[-1]%, timerTimestamp, fparams*).Call()
				} catch 
					this.bindFunctionParams(function, fparams*).Call()
				if this.doLogging
					this.logTimer(this.getFuncName(function), fparams, timerTimestamp)
				continue
			} else if (Abs(DateDiff(timerTimestamp, Now, "Seconds")) <= 1) && ignoreInstantNotifications { ; Periodic timers that would fire immediately are, if ignored, scheduled for their next period
				if !multi ; an ignored non-multi reminder is simply ignored again and thus dropped
					continue
				earliestMatchedTime := timerMetadata.HasOwnProp('nextTime') ? timerTimestamp : earliestMatchingTime(unitArr*)
				nextTimeOffset := DateAddW(earliestMatchedTime, timerMetadata["period"], timerMetadata["periodUnit"])
				super.setOnAndRepeat(nextTimeOffset, timerMetadata["period"], timerMetadata["periodUnit"], function, fparams*)
				continue
			}
			if (timerMetadata.multi)
				super.setOnAndRepeat(givenTimeParam, timerMetadata["period"], timerMetadata["periodUnit"], function, fparams*)
			else
				super.setOnceOn(givenTimeParam, function, fparams*)
		}
		if flagExportToCache
			this.exportTimers()
		return 5
	}

	static exportTimers(filePath := this.cachePath) {
		timerArr := []
		for i, timerMetadata in this.timerMap
			timerArr.push(timerMetadata)
		jsonString := jsongo.Stringify(timerArr, [ "timer", "nextOccurenceTime", "function"], "`t")
		FileOpen(filePath, "w", "UTF-8").Write(jsonString)
		return 1
	}

	static logTimer(functionName, fparams, timestamp) {
		paramString := objCollectString(fparams, ", ")
		str := Format('[{}] Function: {}; Parameters: {}`n', formatTimeISO8601(timestamp, ' '), functionName, paramString)
		FileAppend(str, this.logPath, 'UTF-8')
	}

	; ====== OVERWRITTEN FUNCTIONS ======

	static setOnceIn(days := 0, hours := 0, minutes := 0, seconds := 0, function := Scheduler.Notification.default, fparams*) {
		super.setOnceIn(days, hours, minutes, seconds, function, fparams*)
		this.exportTimers()
	}

	static setOnceOn(time, function := Scheduler.Notification.default, fparams*) {
		super.setOnceOn(time, function, fparams*)
		this.exportTimers()
	}

	static setOnAndRepeat(time, period := 1, periodUnit := "Days", function := Scheduler.Notification.default, fparams*) {
		super.setOnAndRepeat(time, period, periodUnit, function, fparams*)
		this.exportTimers()
	}

	static handleTimer(callableFuncBound, uniqueTimerID, isMulti := 0, isExtended := 0, extendedTimestamp := 0) {
		uniqueTimerID := super.handleTimer(callableFuncBound, uniqueTimerID, isMulti, isExtended, extendedTimestamp)
		if (!isMulti) {
			this.exportTimers()
			timerMetadata := this.timerMap[uniqueTimerID]
			if this.doLogging
				this.logTimer(timerMetadata.function, timerMetadata.HasOwnProp("fparams") ? timerMetadata.fparams : [], A_Now)
		}
		return uniqueTimerID
	}

	class Notification extends Scheduler.Notification {
		class Missed extends Scheduler.Notification {
			static generateNotificationMessage(missedTimestamp, text?) {
				message := "You have a missed Notification from " . formatTimeLongDateTimeUS(missedTimestamp) . "`n"
				message .= super.generateNotificationMessage(text?)
				return message
			}

			static asyncMsgBox(missedTimestamp, text?) {
				SoundPlay("*48")
				MsgBoxAsGui(this.generateNotificationMessage(missedTimestamp, text?), "Notification")
			}

			static discord(missedTimestamp, id, text?) {
				if !this.discordToken
					throw(Error("Attempted to send Discord Notification, but no token was set"))
				DiscordBot(this.discordToken).sendMessageToUser(id, { content: this.generateNotificationMessage(missedTimestamp, text?) })
			}

			static toast(missedTimestamp, text?) => TrayTip(this.generateNotificationMessage(missedTimestamp, text?), "Notification")

			static tooltip(missedTimestamp, text?) => ToolTip(this.generateNotificationMessage(missedTimestamp, text?))

			static all(missedTimestamp, id, text?) {
				this.asyncMsgBox(missedTimestamp, text)
				this.toast(missedTimestamp, text)
				if this.discordToken
					this.discord(missedTimestamp, id, text)
			}
		}
	}
}

class SchedulerGui extends PersistentScheduler {
	static __New() {
		guiMenu := TrayMenu.submenus["GUIs"]
		guiMenu.Add("Open Reminder Manager", (*) => this.Open())
		A_TrayMenu.Add("GUIs", guiMenu)
		this.data := { 
			coords: { x: 565, y: 300 }, 
			variables: {
				timerIn: { message: "rem1Message", seconds: "rem1S", minutes: "rem1M", hours: "rem1H"},
				timerOn: { message: "rem2Message", seconds: "rem2S", minutes: "rem2M", hours: "rem2H", days: "rem2D", months: "rem2Mo"},
				multiReminderOn: { message: "rem3Message", seconds: "rem3S", minutes: "rem3M", hours: "rem3H", days: "rem3D", months: "rem3Mo", period: "rem3P", periodUnit: "rem3PU" },
				multiReminderAt: { message: "rem4Message", seconds: "rem4S", minutes: "rem4M", hours: "rem4H", days: "rem4D", months: "rem4Mo", period: "rem4P", periodUnit: "rem4PU" }
			} 
		}
		this.current := 0
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
		static editFieldFormat := "ys+20 x+5 r1 w30"
		this.current := Gui("+Border", "Reminder Manager")
		this.current.OnEvent("Escape", (*) => this.close())
		this.current.OnEvent("Close", (*) => this.close())
		this.current.AddGroupBox("Section w411 h90", "Add Reminder in")
		this.current.SetFont("s9")
		this.current.AddText("Center ys+22 xs+10", "Remind me in ")
		this.current.AddEdit(editFieldFormat, 0).Name := this.data.variables.timerIn.hours
		this.current.AddText("Center ys+22 x+5", "h")
		this.current.AddEdit(editFieldFormat, 0).Name := this.data.variables.timerIn.minutes
		this.current.AddText("Center ys+22 x+5", "m ")
		this.current.AddEdit(editFieldFormat, 0).Name := this.data.variables.timerIn.seconds
		this.current.AddText("Center ys+22 x+5", "s")
		this.current.AddText("Center ys+22 x+5", "with the message:")
		this.current.AddEdit("ys+47 xs+10 r2 w375").Name := this.data.variables.timerIn.message
		this.current.AddButton("ys+5 h85 w80", "Add Reminder").OnEvent("Click", (*) => setReminderIn())
		this.current.AddButton("ys+5 h30 w65", "Settings").OnEvent("Click", (*) => settingsGui())
		this.current.AddButton("xp h49 w65", "Recurring`nReminders").OnEvent("Click", (*) => recurringReminderGui())
		this.current.AddGroupBox("xs Section w411 h90", "Add Reminder on")
		this.current.SetFont("s9")
		this.current.AddText("Center ys+22 xs+10", "Remind me on")
		this.current.AddEdit(editFieldFormat, A_DD).Name := this.data.variables.timerOn.days
		this.current.AddText("Center ys+22 x+5", ".")
		this.current.AddEdit(editFieldFormat, A_MM).Name := this.data.variables.timerOn.months
		this.current.AddText("Center ys+22 x+5", ", at")
		this.current.AddEdit(editFieldFormat, A_Hour).Name := this.data.variables.timerOn.hours
		this.current.AddText("Center ys+22 x+5", ":")
		this.current.AddEdit(editFieldFormat, A_Min).Name := this.data.variables.timerOn.minutes
		; this.current.AddText("Center ys+22 x+5 " (this.settings.debug ? "" : "Hidden"), ":")
		; this.current.AddEdit("ys+20 x+5 r1 w30 " (this.settings.debug ? "" : "Hidden"), (this.settings.debug ? A_Sec : 0)).Name := this.data.variables.timerOn.seconds
		this.current.AddText("Center ys+22 x+5", "with the message:")
		this.current.AddEdit("ys+47 xs+10 r2 w375").Name := this.data.variables.timerOn.message
		this.current.AddButton("ys+5 h85 w80", "Add Reminder").OnEvent("Click", (*) => setReminderOn())
		this.LV := this.current.AddListView("xs R10 w575 -Multi Sort", ["Next Occurence", "Period", "Parameters", "Function", "Index"])
		this.LV.OnEvent("DoubleClick", onDoubleClick)
		this.LV.OnEvent("ContextMenu", onContextMenu)
		this.LV.OnNotify(LVN_KEYDOWN, onKeyPress)
		createListView()
		this.current.Show(Format("x{1}y{2} Autosize", this.data.coords.x, this.data.coords.y))

		createListView() {
			this.LV.Delete()
			; if !this.settings.debug
			; 	this.LV.ModifyCol(5, 0)
			for i, e in this.timerMap {
				fparamstring := e.HasOwnProp("fparams") ? objCollect(e.fparams, (a,b) => (a ', ' b)) : ''
				this.LV.Add(, 
					formatTimeISO8601(e.nextOccurenceTime, ', '),
					HasProp(e, "period") ? e.period " " (e.period == 1 ? SubStr(e.periodUnit, 1, -1) : e.periodUnit) : "/",
					fparamstring,
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
			static names := this.data.variables.timerIn
			vars := this.current.Submit(0)
			message := vars.%names.message%
			if !(message) {
				if (MsgBox("You have not set a notification message. Proceed?", "Reminder", 0x1) == "Cancel")
					return
			}
			try
				res := this.setOnceIn(0, vars.%names.hours%, vars.%names.minutes%, vars.%names.seconds%,, message)
			catch Error as e {
				msgbox("Problem setting the Notification. Check if entered time is valid.`nSpecifically: " e.What " failed with`n" e.Message)
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
			static names := this.data.variables.timerOn
			vars := this.current.Submit(false)
			message := vars.%names.message%
			if !(message) {
				if (MsgBox("You have not set a timer message. Proceed?", "Reminder", 0x1) == "Cancel")
					return
			}
			try {
				time := nextMatchingTime(, ,
					vars.%names.months% != "" ? vars.%names.months% : unset,
					vars.%names.days% != "" ? vars.%names.days% : unset,
					vars.%names.hours% != "" ? vars.%names.hours% : unset,
					vars.%names.minutes% != "" ? vars.%names.minutes% : unset,
					vars.%names.seconds% != "" ? vars.%names.seconds% : unset
				)
				this.setOnceOn(time, , message)
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
			this.current[names.seconds].Value := 0 ; this.debug ? A_Sec : 0 
			createListView()
		}

		onDoubleClick(ctrlObj, rowN) {
			if !rowN
				return
			key := this.LV.GetText(rowN, 5)
			timerMetadata := objExcludeKeys(this.timerMap[key], [ "timer" ])
			MsgBoxAsGui.fromConfig({
				text: toString(timerMetadata,,0),
				title: "Reminder Object",
				addCopyButton: true,
				owner: this.current.hwnd
			})
		}

		onContextMenu(ctrlObj, rowN, isRightclick, x, y) {
			m := Menu()
			m.Add("Copy Parameters", menuHandler)
			m.Add("Show Config", menuHandler)
			m.Add("Edit Message", menuHandler)
			m.Add("Edit Reminder", menuHandler)
			m.Add("Delete Reminder", menuHandler)
			m.Show()

			menuHandler(itemName, itemPos?, menuObj?) {
				if ((rowN := this.LV.GetNext()) == 0)
					return
				timerID := this.LV.GetText(rowN, 5)
				timerMetadata := this.timerMap[timerID]
				switch itemName {
					case "Copy Parameters":
						A_Clipboard := this.LV.GetText(rowN, 3)
					case "Show Config":
						onDoubleClick(ctrlObj, rowN)
					case "Edit Message":
						MsgBoxAsGui("not yet implemented lol")
					case "Edit Reminder":
						MsgBoxAsGui("not yet implemented lol")
					case "Delete Reminder":
						config := {
							text: "Turn off this timer?",
							title: "Confirmation Prompt",
							defaultButton: timerMetadata.multi ? 3 : 2,
							buttonNames: timerMetadata.multi ? ["Only this time", "Remove Permanently", "Cancel"] : ["Remove Permanently", "Cancel"], 
							wait: true
						}
						switch MsgBoxAsGui.fromConfig(config).result {
							case "Remove Permanently":
								this.timerMap.Delete(timerID)
								this.exportTimers()
							case "Cancel":
								return
						}
						try SetTimer(timerMetadata.timer, 0)
						this.LV.delete(rowN)
				}
			}
		}

		onKeyPress(ctrlObj, lParam) {
			vKey := NumGet(lParam, 24, "UShort")
			switch vKey {
				case "46": 	;// Del/Entf Key -> Delete Reminder
					if ((rowN := this.LV.GetNext()) == 0)
						return
					timerID := this.LV.GetText(rowN, 5)
					timerMetadata := this.timerMap[timerID]
					config := {
						text: "Turn off this timer?",
						title: "Confirmation Prompt",
						defaultButton: timerMetadata.multi ? 3 : 2,
						buttonNames: timerMetadata.multi ? ["Only this time", "Remove Permanently", "Cancel"] : ["Remove Permanently", "Cancel"], 
						wait: true
					}
					switch MsgBoxAsGui.fromConfig(config).result {
						case "Remove Permanently":
							this.timerMap.Delete(timerID)
							this.exportTimers()
						case "Cancel":
							return
					}
					try SetTimer(timerMetadata.timer, 0)
					this.LV.delete(rowN)
				case "116":	;// F5 Key -> Reload
					createListView()
				default:
					return
			}
		}

		settingsGui(*) {
			MsgBoxAsGui(FileRead(this.cachePath, "UTF-8"))
		}

		recurringReminderGui(*) {
			multiRemGui := Gui("+Border", "Recurring Reminder Creator")
			multiRemGui.OnEvent("Escape", (*) => multiRemGui.Destroy())
			multiRemGui.OnEvent("Close", (*) => multiRemGui.Destroy())
			multiRemGui.AddGroupBox("Section w400 h125", "Add Recurring Reminder (GIVEN TIME MUST BE SMALLER THAN PERIOD)")
			multiRemGui.SetFont("s9")
			multiRemGui.AddText("Center R1.45 ys+22 xs+10", "Remind me on")
			curNames := this.data.variables.multiReminderOn
			multiRemGui.AddEdit("ys+20 x+5 r1 w30", '/').Name := curNames.days
			multiRemGui.AddText("Center R1.45 ys+22 x+5", ".")
			multiRemGui.AddEdit("ys+20 x+5 r1 w30", '/').Name := curNames.months
			multiRemGui.AddText("Center R1.45 ys+22 x+5", " at")
			multiRemGui.AddEdit("ys+20 x+5 r1 w30", '/').Name := curNames.hours
			multiRemGui.AddText("Center R1.45 ys+22 x+5", ":")
			multiRemGui.AddEdit("ys+20 x+5 r1 w30", '/').Name := curNames.minutes
			multiRemGui.AddText("Center R1.45 ys+22 x+5", ":")
			multiRemGui.AddEdit("ys+20 x+5 r1 w30", '/').Name := curNames.seconds
			multiRemGui.AddText("Center R1.45 ys+50 xs+10", "and then every")
			multiRemGui.AddEdit("ys+47 x+5 r1 w30", '1').Name := curNames.period
			multiRemGui.AddDDL("ys+47 x+5 r7 w65 Choose1", ["Years", "Months", "Weeks", "Days", "Hours", "Minutes", "Seconds"]).Name := curNames.periodUnit
			multiRemGui.AddText("Center R1.45 ys+50 x+5", "with the message:")
			multiRemGui.AddEdit("ys+74 xs+10 r2 w375").Name := curNames.message
			multiRemGui.AddButton("ys+5 h85 w80", "Add Reminder").OnEvent("Click", (*) => setRecurringReminderOn(0))
			multiRemGui.AddGroupBox("Section w400 h125 xs", "Add Recurring Reminder (uses nextTime and will then use Missed Reminders)")
			multiRemGui.SetFont("s9")
			multiRemGui.AddText("Center R1.45 ys+22 xs+10", "Remind me on")
			curNames := this.data.variables.multiReminderAt
			multiRemGui.AddEdit("ys+20 x+5 r1 w30", '/').Name := curNames.days
			multiRemGui.AddText("Center R1.45 ys+22 x+5", ".")
			multiRemGui.AddEdit("ys+20 x+5 r1 w30", '/').Name := curNames.months
			multiRemGui.AddText("Center R1.45 ys+22 x+5", " at")
			multiRemGui.AddEdit("ys+20 x+5 r1 w30", '/').Name := curNames.hours
			multiRemGui.AddText("Center R1.45 ys+22 x+5", ":")
			multiRemGui.AddEdit("ys+20 x+5 r1 w30", '/').Name := curNames.minutes
			multiRemGui.AddText("Center R1.45 ys+22 x+5", ":")
			multiRemGui.AddEdit("ys+20 x+5 r1 w30", '/').Name := curNames.seconds
			multiRemGui.AddText("Center R1.45 ys+50 xs+10", "and then every")
			multiRemGui.AddEdit("ys+47 x+5 r1 w30", '1').Name := curNames.period
			multiRemGui.AddDDL("ys+47 x+5 r7 w65 Choose1", ["Years", "Months", "Weeks", "Days", "Hours", "Minutes", "Seconds"]).Name := curNames.periodUnit
			multiRemGui.AddText("Center R1.45 ys+50 x+5", "with the message:")
			multiRemGui.AddEdit("ys+74 xs+10 r2 w375").Name := curNames.message
			multiRemGui.AddButton("ys+5 h85 w80", "Add Reminder").OnEvent("Click", (*) => setRecurringReminderOn(1))
			multiRemGui.Show("Autosize")

			setRecurringReminderOn(useFlatTimestamp := false) {
				names := useFlatTimestamp ? this.data.variables.multiReminderAt : this.data.variables.multiReminderOn
				vars := multiRemGui.Submit(false)
				message := vars.%names.message%
				period := vars.%names.period%
				periodUnit := vars.%names.periodUnit%
				if !(message) || !(period)
					return MsgBoxAsGui("You have not set a timer message or have entered an invalid period. You must set both before setting a multitimer.", "Reminder")
				try {
					units := {
						months: IsInteger(vars.%names.months%) ? vars.%names.months% : unset,
						days: IsInteger(vars.%names.days%) ? vars.%names.days% : unset,
						hours: IsInteger(vars.%names.hours%) ? vars.%names.hours% : unset,
						minutes: IsInteger(vars.%names.minutes%) ? vars.%names.minutes% : unset,
						seconds: IsInteger(vars.%names.seconds%) ? vars.%names.seconds% : unset
					}
					if (useFlatTimestamp) {
						timestamp := nextMatchingTime(,flattenTimeVariableObject(units)*)
						this.setOnAndRepeat(timestamp, period, periodUnit,, message)
					} else {
						this.setOnAndRepeat(units, period, periodUnit,, message)
					}
				}
				catch Error {
					MsgBox("Invalid Time specified.")
					return 0
				}
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

			setRecurringReminderAt() {
				static names := this.data.variables.multiReminderAt
				vars := multiRemGui.Submit(false)
				message := vars.%names.message%
				period := vars.%names.period%
				periodUnit := vars.%names.periodUnit%
				if !(message) || !(period)
					return MsgBoxAsGui("You have not set a timer message or have entered an invalid period. You must set both before setting a multitimer.", "Reminder")
				try {
					units := {
						months: IsInteger(vars.%names.months%) ? vars.%names.months% : unset,
						days: IsInteger(vars.%names.days%) ? vars.%names.days% : unset,
						hours: IsInteger(vars.%names.hours%) ? vars.%names.hours% : unset,
						minutes: IsInteger(vars.%names.minutes%) ? vars.%names.minutes% : unset,
						seconds: IsInteger(vars.%names.seconds%) ? vars.%names.seconds% : unset
					}
					timestamp := nextMatchingTime(,flattenTimeVariableObject(units)*)
					this.setOnAndRepeat(timestamp, period, periodUnit,, message)
				}
				catch Error {
					MsgBox("Invalid Time specified.")
					return 0
				}
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
		if i := this.LVGetRowFromKey(key)
			this.LV.delete(i)
	}

	static LVModifyRowTimestamp(key, timestamp) {
		if i := this.LVGetRowFromKey(key) {
			this.LV.Modify(A_Index, timestamp)
			this.LV.ModifyCol(1, "AutoHdr Sort")
		}
	}

	static LVGetRowFromKey(key) {
		Loop(this.LV.GetCount())
			if (this.LV.GetText(A_Index, 5) == key)
				return A_Index
		return 0
	}

	static handleTimer(callableFuncBound, uniqueTimerID, isMulti := 0, isExtended := 0, extendedTimestamp := 0) {
		uniqueTimerID := super.handleTimer(callableFuncBound, uniqueTimerID, isMulti, isExtended, extendedTimestamp)
		if this.current {
			if (!isMulti)
				this.LVDeleteRow(uniqueTimerID)
			else
				this.LVModifyRowTimestamp(uniqueTimerID, formatTimeISO8601(this.timerMap[uniqueTimerID].nextOccurenceTime, ', '))
		}
	}
}