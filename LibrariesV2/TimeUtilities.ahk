
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
			curMonth := parseTimePart(dateTime, "Mo")
			newMonth := Mod(curMonth + amount, 12)
			newMonth := Format("{:02}", (newMonth > 0 ? newMonth : 12 + newMonth))
			nextMonth := Format("{:02}", Mod(newMonth, 12) + 1)
			newYear := parseTimePart(dateTime, "Y") + Floor((curMonth + amount - 1) / 12)
			newTime := newYear . newMonth . SubStr(dateTime, 7)
			if (!IsTime(newTime)) {
				newDay := parseTimePart(dateTime, "D") - DateDiff(newYear . nextMonth, newYear . newMonth, "D")
				newTime := newYear . nextMonth . Format("{:02}", newDay) . SubStr(dateTime, 9)
			}
			return newTime
		case "Years":
			newYear := (parseTimePart(dateTime, "Y") + amount)
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
			yDiff := parseTimePart(dateTime1, "Y") - parseTimePart(dateTime2, "Y")
			diff := 12 * yDiff + parseTimePart(dateTime1, "Mo") - parseTimePart(dateTime2, "Mo")
			newDate := DateAddW(dateTime2, diff, "Months")
			if DateDiff(dateTime1, newDate, "Seconds") >= 0
				diff--
		case "Years":
			diff := parseTimePart(dateTime1, "Y") - parseTimePart(dateTime2, "Y")
			if DateDiff(dateTime1, DateAddW(dateTime2, diff, "Years"), "Seconds") >= 0
				diff--
	}
	return diff
}

/**
 * Checks whether the given time units could be part of a valid date-
 * @param years 
 * @param months 
 * @param days 
 * @param hours 
 * @param minutes 
 * @param seconds
 * @return {Integer} 1|0 
 */
checkValidDateEligibility(years?, months?, days?, hours?, minutes?, seconds?) {
	seconds := seconds ?? 1
	minutes := minutes ?? 1
	hours := hours ?? 1
	days := days ?? 1
	months := months ?? 1
	years := years ?? 2000 ; leap year
	if seconds > 60 || minutes > 60 || hours > 24 || months > 12
		return 0
	if days > enumerateMonthDays(months, years) ; if neither are given, checks again jan 2000, ie 31 days. if month but not year is given, checks leap year. Otherwise checks given units.
		return 0
	return 1
}

/*
* Given a set of time units, returns a YYYYMMDDHH24MISS timestamp
; of the earliest possible time in the future when all given parts match
* Examples: The current time is 27th December, 2023, 17:16:34
* nextMatchingTime() -> A_Now
* nextMatchingTime(,2023,12) -> A_Now.
* nextMatchingTime(,2023, , 27) -> A_Now.
* nextMatchingTime(,2023, , 28) -> 20231228000000.
* nextMatchingTime(, 2, 29) -> 20240229000000 (next leap year).
* nextMatchingTime(,2022, ...) -> 0.
* nextMatchingTime(,2025, 02, 29) -> throw Error: Invalid Date
* nextMatchingTime(, 1, , , 19) -> 20240101001900
*/
nextMatchingTime(offset := A_Now, years?, months?, days?, hours?, minutes?, seconds?) {
	timeParamArr := [years?, months?, days?, hours?, minutes?, seconds?]
	if !checkValidDateEligibility(timeParamArr*)
		throw(ValueError("Invalid date specified"))
	if !IsTime(offset)
		throw(ValueError("Invalid Offset specified"))
	_Year := parseTimePart(offset, "Y"), _Month := parseTimePart(offset, "Mo"), _Day := parseTimePart(offset, "D"), _Hour := parseTimePart(offset, "H"), _Min := parseTimePart(offset, "m"), _Sec := parseTimePart(offset, "s")
	switch {
		case IsSet(years):
			years := Integer(years)
			if years < _Year
				return 0
			if years > _Year ; we know that the units can form a valid date, so this must be valid.
				return mergePartialTimeStamp(Format("{:04}", years), 4, months ?? 1, days ?? 1, hours ?? 0, minutes ?? 0, seconds ?? 0)
			tStamp := nextMatchingTime(offset, , months?, days?, hours?, minutes?, seconds?)
			return parseTimePart(tStamp, "Y") == years ? tStamp : 0
		case IsSet(months):
			months := Integer(months)
			tStamp := mergePartialTimeStamp(offset, 4, months, days ?? 1, hours ?? 0, minutes ?? 0, seconds ?? 0)
			if months > _Month
				return tStamp
			tStampGuess := nextMatchingTime(offset, , , days?, hours?, minutes?, seconds?)
			if parseTimePart(tStampGuess, "Mo") == months
				return tStampGuess
			if !IsTime(tStamp) ; the only way for this to occur is if we are not in a leap year and we have Feb 29 specified
				return (_Year + 4 - Mod(_Year, 4)) . SubStr(tStamp, 5)
			return DateAddW(tStamp, 1, "Y")
		case IsSet(days):
			days := Integer(days)
			tStamp := mergePartialTimeStamp(offset, 6, days, hours ?? 0, minutes ?? 0, seconds ?? 0)
			maxDaysThisMonth := enumerateMonthDays(parseTimePart(offset, "Mo"), parseTimePart(offset, "Y"))
			if days > _Day && days <= maxDaysThisMonth ; we are in the future and its still a valid date this month
				return tStamp
			tStampGuess := nextMatchingTime(offset, , , , hours?, minutes?, seconds?)
			if parseTimePart(tStampGuess, "D") == days
				return tStampGuess
			if days <= maxDaysThisMonth ; safe tStamp date -> safe addition
				return DateAddW(tStamp, 1, "Mo")
			; tstamp is invalid. since every second month has 31 days, we manually add a month and are done.
			; Since december has 31 days, _Month+1 is always <= 12 and the addition is safe
			return SubStr(offset, 1, 4) tf(_Month+1) SubStr(tStamp, 7)
		case IsSet(hours):
			hours := Integer(hours)
			tStamp := mergePartialTimeStamp(offset, 8, hours, minutes ?? 0, seconds ?? 0)
			if hours > _Hour
				return tStamp
			tStampGuess := nextMatchingTime(offset,,,,,minutes?,seconds?)
			if parseTimePart(tStampGuess, "H") == hours
				return tStampGuess
			return DateAdd(tStamp, 1, "D")
		case IsSet(minutes):
			minutes := Integer(minutes)
			tStamp := mergePartialTimeStamp(offset, 10, minutes, seconds ?? 0)
			if minutes > _Min
				return tStamp
			tStampGuess := nextMatchingTime(offset, , , , , , seconds?)
			if parseTimePart(tStampGuess, "M") == minutes ; returned timestamp is in current minute
				return tStampGuess
			return DateAdd(tStamp, 1, "H")
		case IsSet(seconds):
			tStamp := mergePartialTimeStamp(offset, 12, seconds)
			if isInPast(tStamp, offset)
				return DateAdd(tStamp, 1, "M")
			return tStamp
		default: ; no unit is set
			return offset
	}

	tf(value) => Format("{:02}", value)
	isInPast(timestamp, now) => DateDiff(timestamp, now, "S") < 0
	mergePartialTimeStamp(timestamp, length, units*) {
		tStamp := SubStr(timestamp, 1, length)
		for unit in units
			tStamp .= Format("{:02}", unit)
		if StrLen(tStamp) != "14"
			throw(Error("WEEWOOWEEWOO"))
		return tStamp
	}
}

earliestMatchingTime(years?, months?, days?, hours?, minutes?, seconds?) {
	if (months??1) == 2 && (days??1) == 29 && !IsSet(years)
		return Format("{:04}", years ?? 1604) . tf(months ?? 1) . tf(days ?? 1) . tf(hours ?? 0) . tf(minutes ?? 0) . tf(seconds ?? 0)
	return Format("{:04}", years ?? 1601) . tf(months ?? 1) . tf(days ?? 1) . tf(hours ?? 0) . tf(minutes ?? 0) . tf(seconds ?? 0)
	tf(n) => Format("{:02}", n)
}


/**
 * Given a set of time units which MUST be in the past, returns a YYYYMMDDHH24MISS timestamp of the last possible time in the past when all given parts match
 * @param years 
 * @param months 
 * @param days 
 * @param hours 
 * @param minutes 
 * @param seconds 
 * @returns {String} 
 */
lastMatchingTime(years, months?, days?, hours?, minutes?, seconds?) {
	timestamp := Format("{:04}", years) . tf(months ?? 12) . tf(days ?? (IsSet(months) ? enumerateMonthDays(months, years) : 31)) . tf(hours ?? 23) . tf(minutes ?? 59) . tf(seconds ?? 59)
	if !IsTime(timestamp)
		throw(ValueError("Invalid time given: " timestamp))
	return timestamp
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
	unitMap := Map(1, y?, 2, mo?, 3, d?, 4, h?, 5, m?, 6, s?)
	first := 0, last := 0, gap := false
	for i, e in unitMap {
		if (A_Index == 1) ; the first set key will always be iterated first.
			first := i
		last := i
		if (first + A_Index - 1 < i) ; if i increases faster than A_Index, then we jumped over a unit
			gap := true
	}
	return {first: first, last: last, gap: gap, count: unitMap.Count}
}

/**
 * Given a timestamp and a time interval, adds time interval to [time] until the new timestamp is in the future. If [time] is already in the future, returns it.
 * @param time 
 * @param intervalAmount 
 * @param intervalUnit 
 */
getNextPeriodicTimestamp(time, intervalLength, intervalUnit, offset := A_Now) {
	if (!IsTime(time))
		throw(ValueError("Invalid Timestamp"))
	intervalUnit := validateTimeUnit(intervalUnit)
	secsDiff := DateDiff(offset, time, "Seconds")
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
			if (DateDiff(time, offset, "Seconds") < 0)
				time := DateAddW(time, intervalLength, "Seconds")
		case "Months", "Years":
			unitDiff := parseTimePart(offset, intervalUnit) - parseTimePart(time, intervalUnit)
			if (intervalUnit == "Months")
				unitDiff += (parseTimePart(offset, "Years") - parseTimePart(time, "Years")) * 12
			unitsSinceLastInterval := Mod(unitDiff, intervalLength)
			unitsSinceLastInterval := unitsSinceLastInterval > 0 ? unitsSinceLastInterval : intervalLength
			time := DateAddW(time, unitDiff + intervalLength - unitsSinceLastInterval, intervalUnit)
			if (DateDiff(time, offset, "Seconds") < 0)
				time := DateAddW(time, intervalLength, intervalUnit)
	}
	return time
}

/**
 * Given a full timestamp and a unit, returns that value for the respective unit
 * @param time timestamp
 * @param timeUnit
 * @returns {Integer}
 * 
 *	parseTime(20260503121301, "Y") => 2026
 *	parseTime(20260503121301, "Mo") => 5
 *	parseTime(20260503121301, "D") => 3
 */
parseTimePart(time, timeUnit) {
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
			return "Seconds"
		case "M", "Min", "Mins", "Minute", "Minutes":
			return "Minutes"
		case "H", "Hr", "Hrs", "Hour", "Hours":
			return "Hours"
		case "D", "Day", "Days":
			return "Days"
		case "W", "Wk", "Wks", "Week", "Weeks":
			return "Weeks"
		case "Mo", "Month", "Months":
			return "Months"
		case "Y", "A", "Yr", "Yrs", "Year", "Years":
			return "Years"
		case "YDay":
			return "YDay"
		default:
			throw(Error("Invalid Period Unit: " . timeUnit))
	}
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

; dddd, dd.MM.yyyy, HH:mm:ss
formatTimeLongDateTimeUS(timestamp := A_Now) => FormatTime(timestamp " L1033", "dddd, dd.MM.yyyy, HH:mm:ss")
; dd.MM.yyyy_HH:mm:ss
formatTimeDateTime(timestamp := A_Now, dateTimeSep := '_') => FormatTime(timestamp, "dd.MM.yyyy" dateTimeSep "HH:mm:ss")
; yyyy-MM-ddTHH:mm:ss
formatTimeISO8601(timestamp := A_Now, dateTimeSep := 'T') => FormatTime(timestamp, "yyyy-MM-dd" dateTimeSep "HH:mm:ss")
; yyyy-MM-ddTHH-mm-ss
formatTimeISO8601File(timestamp := A_Now, dateTimeSep := 'T') => FormatTime(timestamp, "yyyy-MM-dd" dateTimeSep "HH-mm-ss")