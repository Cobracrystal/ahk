
/**
 * Extended version of DateAdd, allowing Weeks (W), Months (MO), Years (Y) for timeUnit. Returns YYYYMMDDHH24MISS timestamp
 * @param dateTime valid YYYYMMDDHH24MISS timestamp to add time to.
 * @param amount Amount of time to be added.
 * @param timeUnit Time Unit can be one of the strings (or their first letter): Years, Weeks, Days, Hours, Minutes, Seconds.
 * 
 * Months / Mo is available. Adding a month will result in the same day number the next month unless that would be invalid, in which case the number of days in the current month will be added.
 * 
 * Similarly, adding years to a leap day will result in the corresponding day number of the resulting year (2024-02-29 + 1 Year -> 2025-03-01)
 * @returns {string} YYYYMMDDHH24MISS Timestamp.
 */
DateAddW(dateTime, amount, timeUnit) {
	timeUnit := validateTimeUnit(timeUnit)
	if (amount == 0)
		return dateTime
	switch timeUnit {
		case "Seconds", "Minutes", "Hours", "Days":
			return DateAdd(dateTime, amount, timeUnit)
		case "Weeks":
			return DateAdd(dateTime, amount * 7, "D")
		case "Months":
			curMonth := parseTime(dateTime, "Mo")
			newMonth := Mod(curMonth + amount, 12)
			newMonth := Format("{:02}", (newMonth > 0 ? newMonth : 12 + newMonth))
			nextMonth := Format("{:02}", Mod(newMonth, 12) + 1)
			newYear := parseTime(dateTime, "Y") + Floor((curMonth + amount - 1) / 12)
			newTime := newYear . newMonth . SubStr(dateTime, 7)
			if (!IsTime(newTime)) {
				newDay := parseTime(dateTime, "D") - DateDiff(newYear . nextMonth, newYear . newMonth, "D")
				newTime := newYear . nextMonth . Format("{:02}", newDay) . SubStr(dateTime, 9)
			}
			return newTime
		case "Years":
			newYear := (parseTime(dateTime, "Y") + amount)
			newTime := newYear . SubStr(dateTime, 5)
			if !IsTime(newTime) ; leap day
				newTime := newYear . SubStr(DateAdd(dateTime, 1, "D"), 5)
			return newTime
		default:
			throw(ValueError("Invalid Time Unit: " timeUnit))
	}
}

/**
 * The difference is negative if dateTime1 is earlier than dateTime2
 * @param dateTime1 
 * @param dateTime2 
 * @param timeUnit 
 * @returns {Number} 
 */
DateDiffW(dateTime1, dateTime2, timeUnit) {
	timeUnit := validateTimeUnit(timeUnit)
	switch timeUnit, 0 {
		case "Seconds", "Minutes", "Days":
			diff := DateDiff(dateTime1, dateTime2, timeUnit)
		case "Weeks":
			diff := DateDiff(dateTime1, dateTime2, "Days") // 7
		case "Months":
			yDiff := parseTime(dateTime1, "Y") - parseTime(dateTime2, "Y")
			diff := 12 * yDiff + parseTime(dateTime1, "Mo") - parseTime(dateTime2, "Mo")
			newDate := DateAddW(dateTime2, diff, "Months")
			if DateDiff(dateTime1, newDate, "Seconds") >= 0
				diff--
		case "Years":
			diff := parseTime(dateTime1, "Y") - parseTime(dateTime2, "Y")
			if DateDiff(dateTime1, DateAddW(dateTime2, diff, "Years"), "Seconds") >= 0
				diff--
	}
	return diff
}

/*
* Given a set of time units, returns a YYYYMMDDHH24MISS timestamp
; of the earliest possible time in the future when all given parts match
* Examples: The current time is 27th December, 2023, 17:16:34
* parseTime() -> A_Now
* parseTime(2023,12) -> A_Now.
* parseTime(2023, , 27) -> A_Now.
* parseTime(2023, , 28) -> 20231228000000.
* parseTime(, 2, 29) -> 20240229000000 (next leap year).
* parseTime(2022, ...) -> 0.
* parseTime(2025, 02, 29) -> throw Error: Invalid Date
* parseTime(, 1, , , 19) -> 20240101001900
*/
nextMatchingTime(years?, months?, days?, hours?, minutes?, seconds?) {
	Now := A_Now
	local paramInfo := getTimeUnitInfo(years?, months?, days?, hours?, minutes?, seconds?)
	switch paramInfo.first {
		case 0:
			return Now
		case 1:
			if (years == A_Year && paramInfo.gap) { ; why compare to current year? leap year stuff
				tStamp := nextMatchingTime(, months?, days?, hours?, minutes?, seconds?)
				return (parseTime(tStamp, "Y") == years) ? tStamp : 0
			}
			tStamp := years tf(months ?? 1) tf(days ?? 1) tf(hours ?? 0) tf(minutes ?? 0) tf(seconds ?? 0)
			if (!IsTime(tStamp)) {
				if (!IsSet(years) && IsSet(months) && months == 2 && IsSet(days) && days == 29) ; correct leap year
					tStamp := (A_Year + 4 - Mod(A_Year, 4)) . SubStr(tStamp, 5)
				else if (!IsSet(months) && days > 29) ; correct possible month error. no need for mod, since dec has 31 days
					tStamp := SubStr(tStamp 1, 4) . tf(A_MM + 1) . SubStr(tStamp, 7)
				if (!IsTime(tStamp))
					throw(ValueError("Invalid date specified."))
			}
			if (DateDiff(tStamp, Now, "S") >= 0) ; year is in the future
				return tStamp
			; this case is ONLY for when year is in the present AND there is no gap present (if year is in the future, datediff must be positive.)
			if (paramInfo.last < 6) ; populate unset vars with current time before giving up
				return nextMatchingTime(years, months ?? A_MM, days ?? A_DD, hours ?? A_Hour, minutes ?? A_Min, seconds ?? A_Sec)
			return 0 ; a year in the past will never occur again
		case 2:
			if (tf(months) == A_MM && paramInfo.gap) {
				tStamp := nextMatchingTime(, , days?, hours?, minutes?, seconds?)
				return parseTime(tStamp, "Mo") == tf(months) ? tStamp : DateAddW(tStamp, 1, "Y")
			}
			tStamp := A_Year tf(months) tf(days ?? 1) tf(hours ?? 0) tf(minutes ?? 0) tf(seconds ?? 0)
			if (!IsTime(tStamp)) {
				if (tf(months) == "02" && IsSet(days) && days == 29) ; leap year
					tStamp := (A_Year + 4 - Mod(A_Year, 4)) . SubStr(tStamp, 5)
				if (!IsTime(tStamp))
					throw(ValueError("Invalid date specified."))
			}
			if (DateDiff(tStamp, Now, "S") >= 0)
				return tStamp
			nStamp := A_Year tf(months) tf(days??A_DD) tf(hours??0) tf(minutes ?? 0) tf(seconds ?? 0)
			if (DateDiff(nStamp, Now, "S") >= 0)
				return nStamp
			nStamp := A_Year tf(months) tf(days??A_DD) tf(hours??A_Hour) tf(minutes ?? 0) tf(seconds ?? 0)
			if (DateDiff(nStamp, Now, "S") >= 0)
				return nStamp
			nStamp := A_Year tf(months) tf(days??A_DD) tf(hours??A_Hour) tf(minutes ?? A_Min) tf(seconds ?? 0)
			if (DateDiff(nStamp, Now, "S") >= 0)
				return nStamp
			nStamp := A_Year tf(months) tf(days??A_DD) tf(hours??A_Hour) tf(minutes ?? A_Min) tf(seconds ?? A_Sec)
			if (DateDiff(nStamp, Now, "S") >= 0)
				return nStamp
			return DateAddW(tStamp, 1, "Y")
		case 3:
			if (days == A_DD && paramInfo.gap) {
				tStamp := nextMatchingTime(, , , hours?, minutes?, seconds?)
				return (parseTime(tStamp, "D") == days) ? tStamp : DateAddW(tStamp, 1, "Mo")
			}
			tStamp := SubStr(Now, 1, 6) tf(days) tf(hours ?? 0) tf(minutes ?? 0) tf(seconds ?? 0)
			if (!IsTime(tStamp)) {
				if (A_MM == 02 && days == 29) ; leap year
					tStamp := (A_Year + 4 - Mod(A_Year, 4)) . SubStr(tStamp, 5)
				else if (days > 29) ; correct possible month error. no need for mod, since dec has 31 days
					tStamp := SubStr(tStamp 1, 4) . tf(A_MM + 1) . SubStr(tStamp, 7)
				if (!IsTime(tStamp))
					throw(ValueError("Invalid date specified."))
			}
			if (DateDiff(tStamp, Now, "S") >= 0)
				return tStamp
			nStamp := SubStr(Now, 1, 6) tf(days) tf(hours ?? A_Hour) tf(minutes ?? 0) tf(seconds ?? 0)
			if (DateDiff(nStamp, Now, "S") >= 0)
				return nStamp
			nStamp := SubStr(Now, 1, 6) tf(days) tf(hours ?? A_Hour) tf(minutes ?? A_Min) tf(seconds ?? 0)
			if (DateDiff(nStamp, Now, "S") >= 0)
				return nStamp
			nStamp := SubStr(Now, 1, 6) tf(days) tf(hours ?? A_Hour) tf(minutes ?? A_Min) tf(seconds ?? A_Sec)
			if (DateDiff(nStamp, Now, "S") >= 0)
				return nStamp
			return DateAddW(tStamp, 1, "Mo")
		case 4:
			if (tf(hours) == A_Hour && paramInfo.gap) { ; minutes are missing, so just increase seconds until it matches
				tStamp := nextMatchingTime(, , , , , seconds?)
				return (parseTime(tStamp, "H") == tf(hours)) ? tStamp : DateAddW(tStamp, 1, "D") ; might be 59:xx but specified <xx -> +1D
			}
			tStamp := SubStr(Now, 1, 8) tf(hours) tf(minutes ?? 0) tf(seconds ?? 0)
			if (DateDiff(tStamp, Now, "S") >= 0)
				return tStamp
			nStamp := SubStr(Now, 1, 8) tf(hours) tf(minutes ?? A_Min) tf(seconds ?? 0)
			if (DateDiff(nStamp, Now, "S") >= 0)
				return nStamp
			nStamp := SubStr(Now, 1, 8) tf(hours) tf(minutes ?? A_Min) tf(seconds ?? A_Sec)
			if (DateDiff(nStamp, Now, "S") >= 0)
				return nStamp
			return DateAddW(tStamp, 1, "D")
		case 5:
			if (tf(minutes) == A_Min) {
				tStamp := nextMatchingTime(, , , , , seconds?)
				return parseTime(tStamp, "M") == tf(minutes) ? tStamp : 0
			}
			tStamp := SubStr(Now, 1, 10) tf(minutes) tf(seconds ?? 0)
			if (DateDiff(tStamp, Now, "S") >= 0)
				return tStamp
			nStamp := SubStr(Now, 1, 10) tf(minutes) tf(seconds ?? A_Sec)
			if (DateDiff(nStamp, Now, "S") >= 0)
				return nStamp
			return DateAddW(tStamp, 1, "H")
		case 6:
			tStamp := SubStr(Now, 1, 12) . tf(seconds)
			if (DateDiff(tStamp, Now, "S") >= 0)
				return tStamp
			return DateAddW(tStamp, 1, "M")
	}
	tf(n) => Format("{:02}", n)

}

/**
 * Transforms an object with time unit properties into an array of Length six, containing these in descending order.
 * @param timeObject 
 * @returns {Array} 
 */
flattenTimeVariableObject(timeObject) {
	tObj := {}
	for i, e in (timeObject is Map ? timeObject : timeObject.OwnProps()) {
		unit := validateTimeUnit(i)
		tObj.%unit% := e
	}
	arr := []
	for e in ["years","months","days","hours","minutes","seconds"]
		arr.push(tObj.HasOwnProp(e) ? tObj.%e% : unset)
	return arr
}

; Returns the index of the first set unit, the index of the last set unit, and whether there is a gap between them
getTimeUnitInfo(y?, mo?, d?, h?, m?, s?) {
	mapA := Map(1, y?, 2, mo?, 3, d?, 4, h?, 5, m?, 6, s?)
	first := 0, last := 0
	for i, e in mapA {
		if (A_Index == 1)
			first := i
		last := i
		if (first + A_Index - 1 != i)
			return { first: first, after: last, gap: true }
	}
	return {first: first, last: last, gap: false}
}

enumerateTimeUnits(unit) {
	unit := validateTimeUnit(unit)
	switch unit {
		case "Years":
			return 1
		case "Months":
			return 2
		case "Days":
			return 3
		case "Hours":
			return 4
		case "Minutes":
			return 5
		case "Seconds":
			return 6
	}
}

enumerateTimeUnitIndex(unitIndex) {
	switch unitIndex {
		case 1:
			return "Years"
		case 2:
			return "Months"
		case 3:
			return "Days"
		case 4:
			return "Hours"
		case 5:
			return "Minutes"
		case 6:
			return "Seconds"
		default:
			throw(Error("Invalid Unit Index: " . unitIndex))
	}
}

/**
* Given a set of time units which MUST be in the past, returns a YYYYMMDDHH24MISS timestamp
; of the last possible time in the past when all given parts match
 * @param y
 * @param mo 
 * @param d 
 * @param h 
 * @param m 
 * @param s 
 */
lastMatchingTime(y, mo?, d?, h?, m?, s?) {
	return y . tf(mo ?? 12) . tf(d ?? (IsSet(mo) ? enumerateMonthDays(mo, y) : 31)) . tf(h??23) . tf(m??59) . tf(s??59)
	tf(n) => Format("{:02}", n)
}

/**
 * Given a timestamp and a time interval, adds time interval to [time] until the new timestamp is in the future. If [time] is already in the future, returns it.
 * @param time 
 * @param intervalAmount 
 * @param intervalUnit 
 */
getNextPeriodicTimestamp(time, intervalLength, intervalUnit) {
	if (!IsTime(time))
		throw(ValueError("Invalid Timestamp"))
	intervalUnit := validateTimeUnit(intervalUnit)
	Now := A_Now
	secsDiff := DateDiff(Now, time, "Seconds")
	if secsDiff < 0
		return time
	if intervalLength <= 0
		throw ValueError("Huh")
	switch intervalUnit {
		case "Seconds", "Minutes", "Hours", "Days", "Weeks":
			intervalLengthSecs := convertToSeconds(intervalLength, intervalUnit)
			secsSinceLastInterval := Mod(secsDiff, intervalLengthSecs)
			secsSinceLastInterval := secsSinceLastInterval > 0 ? secsSinceLastInterval : intervalLengthSecs 
			time := DateAddW(time, secsDiff + intervalLengthSecs - secsSinceLastInterval, "Seconds")
			if (DateDiff(time, Now, "Seconds") < 0)
				time := DateAddW(time, intervalLength, "Seconds")
		case "Months", "Years":
			unitDiff := parseTime(Now, intervalUnit) - parseTime(time, intervalUnit)
			if (intervalUnit == "Months")
				unitDiff += (parseTime(Now, "Years") - parseTime(time, "Years")) * 12
			unitsSinceLastInterval := Mod(unitDiff, intervalLength)
			unitsSinceLastInterval := unitsSinceLastInterval > 0 ? unitsSinceLastInterval : intervalLength
			time := DateAddW(time, unitDiff + intervalLength - unitsSinceLastInterval, intervalUnit)
			if (DateDiff(time, Now, "Seconds") < 0)
				time := DateAddW(time, intervalLength, intervalUnit)
	}
	return time
}

/**
 * Given a timestamp and a unit, returns that value for the respective unit
 * @param time timestamp
 * @param timeUnit
 * @returns {Integer}
 */
parseTime(time, timeUnit) {
	if (!IsTime(time))
		throw(ValueError("Invalid Timestamp"))
	timeUnit := validateTimeUnit(timeUnit)
	switch timeUnit {
		case "Seconds":
			return Integer(FormatTime(time, "s"))
		case "Minutes":
			return Integer(FormatTime(time, "m"))
		case "Hours":
			return Integer(FormatTime(time, "H"))
		case "Days":
			return Integer(FormatTime(time, "d"))
		case "Months":
			return Integer(FormatTime(time, "M"))
		case "Years":
			return Integer(FormatTime(time, "yyyy"))
		case "Weeks":
			return Integer(SubStr(FormatTime(time, "YWeek"), 5, 2))
		case "YDay":
			return Integer(FormatTime(time, "YDay"))
	}
}

enumerateDay(day) { ; sunday == 1 because WDay uses 1 for sunday.
	d := Substr(day, 1, 2)
	switch d, 0 {
		case "mo":
			day := 2
		case "di", "tu":
			day := 3
		case "mi", "we":
			day := 4
		case "do", "th":
			day := 5
		case "fr":
			day := 6
		case "sa":
			day := 7
		case "so", "su":
			day := 1
		default:
			return -1
	}
	return A_DD - A_WDAY + day
}

enumerateMonthDays(month, year?) {
	switch month {
		case 1,3,5,7,8,10,12:
			return 31
		case 2:
			return IsSet(year) && Mod(year, 4) == 0 ? 29 : 28
		case 4,6,9,11:
			return 30
	}
}

validateTimeUnit(timeUnit) {
	switch timeUnit, 0 {
		case "S", "Sec", "Secs", "Second", "Seconds":
			timeUnit := "Seconds"
		case "M", "Min", "Mins", "Minute", "Minutes":
			timeUnit := "Minutes"
		case "H", "Hr", "Hrs", "Hour", "Hours":
			timeUnit := "Hours"
		case "D", "Day", "Days":
			timeUnit := "Days"
		case "W", "Wk", "Wks", "Week", "Weeks":
			timeUnit := "Weeks"
		case "Mo", "Month", "Months":
			timeUnit := "Months"
		case "Y", "A", "Yr", "Yrs", "Year", "Years":
			timeUnit := "Years"
		case "YDay":
			timeUnit := "YDay"
		default:
			throw(Error("Invalid Period Unit: " . timeUnit))
	}
	return timeUnit
}

convertToSeconds(amount, unit) {
	if (amount < 0)
		return -DateDiffW(DateAddW("1601", amount * -1, unit), "1601", "Seconds")
	return DateDiffW(DateAddW("1601", amount, unit), "1601", "Seconds")	
}

randomTime(timestamp1 := "16010101000000", timestamp2 := A_Now) {
	r := Random(0, DateDiff(timestamp2, timestamp1, "Seconds"))
	return DateAdd(timestamp1, r, "Seconds")
}