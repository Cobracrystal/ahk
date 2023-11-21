#Include %A_ScriptDir%\Libraries\BasicUtilities.ahk

textTimestampConverter(hotkey) {
	text := fastCopy()
	text := Trim(text)
	if (text = "") {
		validatedTimestamp := A_NowUTC
		unixTimestamp := UnixTimeStamp(A_NowUTC)
		flag := 25
	}
	else {
		arr := parseToTimeFormat(text)
		timestamp := arr[1]
		flag := arr[2]
		FormatTime, validatedTimestamp, %timestamp%, yyyyMMddHHmmss
		unixTimestamp := UnixTimeStamp(validatedTimestamp)
		if (unixTimestamp = -1)
			flag := 6
	}
	createTimeStampMenu(flag, unixTimestamp, validatedTimestamp)
}

createTimeStampMenu(flag, unixTimestamp, validatedTimestamp) {
	FormatTime, l, 		%validatedTimestamp%, dd.MM.yyyy, HH:mm
	FormatTime, d, 		%validatedTimestamp%, dd/MM/yyyy
	FormatTime, bigD, 	%validatedTimestamp%, MMMM dd, yyyy
	FormatTime, t, 		%validatedTimestamp%, HH:mm
	FormatTime, bigT, 	%validatedTimestamp%, HH:mm:ss
	FormatTime, f, 		%validatedTimestamp%, MMMM dd, yyyy HH:mm
	FormatTime, bigF, 	%validatedTimestamp%, dddd, MMMM dd, yyyy HH:mm
	FormatTime, nice, %validatedTimestamp%, HHmm
	if (nice = 1337) {
		Menu, timestampMenu, Add, Nice, doNothing
		Menu, timestampMenu, Default, Nice
		Menu, timestampMenu, Disable, Nice
	}
	timeStampHandlerVar := Func("timestampHandler").Bind(unixTimestamp, validatedTimestamp)
	tMode := A_TitleMatchMode
	SetTitleMatchMode, RegEx
;// Flags: 1 = no year, 2 = no date, 3 = no seconds, 4 = only hours, 5 = no time, 6 = invalid date
	if (flag = 6) {
		Menu, timestampMenu, Add, Invalid Date, doNothing
		Menu, timestampMenu, Disable, Invalid Date
	}
	else if (WinActive("Discord ahk_exe Discord.*\.exe")) {
		if (flag = 23)
			Menu, timestampMenu, Add, Paste short time (t) (%t%), % timeStampHandlerVar
		else {
			if (flag = 5 || flag = 15 || flag = 25)
				Menu, timestampMenu, Add, Paste short date (d) (%d%), % timeStampHandlerVar
			if (flag = 5 || flag = 15)
				Menu, timestampMenu, Add, Paste long date (D) (%bigD%), % timeStampHandlerVar
			if (flag = 2 || flag = 25)
				Menu, timestampMenu, Add, Paste long time (T) (%bigT%), % timeStampHandlerVar
			if (flag = 1 || flag = 4 || flag = 3 || flag = 13 || flag = 14 || flag = 25 || flag = "") {
				Menu, timestampMenu, Add, Paste full date (f) (%f%), % timeStampHandlerVar
				Menu, timestampMenu, Add, Paste long full date (F) (%bigF%), % timeStampHandlerVar
			}
		}
		if (flag != 25)
			Menu, timestampMenu, Add, Paste 'related' format (R) (<t:%unixTimestamp%:R>), % timeStampHandlerVar
		else
			Menu, timestampMenu, Add, Paste formatted current date (long) (%l%), % timeStampHandlerVar
	}
	else if (flag != 6 && flag != 25)
			Menu, timestampMenu, Add, Paste Timestamp (UNIX) (%unixTimestamp%), % timeStampHandlerVar
	else if (flag = 25) {
		FormatTime, d, %A_Now%, dd/MM/yyyy
		FormatTime, bigT, %A_Now%, HH:mm:ss
		Menu, timestampMenu, Add, Paste current Timestamp (UNIX) (%unixTimestamp%), % timeStampHandlerVar
		Menu, timestampMenu, Add, Paste current date (short) (%d%), % timeStampHandlerVar
		Menu, timestampMenu, Add, Paste current date (long) (%l%), % timeStampHandlerVar
		Menu, timestampMenu, Add, Paste current time (%bigT%), % timeStampHandlerVar
	}
	SetTitleMatchMode, %tMode%
	Menu, timestampMenu, Show
	Menu, timestampMenu, DeleteAll
}

timestampHandler(unixTimestamp, validatedTimestamp, menuLabel) {
	pos := RegexMatch(menuLabel, "\(.*?\)")
	format := SubStr(menuLabel, pos+1, 1)
	FormatTime, l, 		%validatedTimestamp%, dd.MM.yyyy, HH:mm
	FormatTime, d, 		%validatedTimestamp%, dd/MM/yyyy
	FormatTime, bigD, 	%validatedTimestamp%, MMMM dd, yyyy
	FormatTime, t, 		%validatedTimestamp%, HH:mm
	FormatTime, bigT, 	%validatedTimestamp%, HH:mm:ss
	FormatTime, f, 		%validatedTimestamp%, MMMM dd, yyyy HH:mm
	FormatTime, bigF, 	%validatedTimestamp%, dddd, MMMM dd, yyyy HH:mm
	if (format != "U" && format != "s" && format != "l" && !RegexMatch(format, "\d"))
		date := "<t:" . UnixTimeStamp . ":" . format . ">"
	else switch format {
		case "U":
			date := unixTimestamp
		case "s":
			FormatTime, date, %validatedTimestamp%, dd.MM.yyyy
		case "l":
			FormatTime, date, %validatedTimestamp%, dd.MM.yyyy, HH:mm
		default:
			FormatTime, date, %validatedTimestamp%, HH:mm:ss
	}
	Sleep, 100
	fastPrint(date)
}

parseToTimeFormat(text) {
	flag := ""
	text := RegexReplace(text, "/", ".")
	posDate := RegexMatch(text, "[0-9]{2}\.[0-9]{2}\.[0-9]{4}")
	if (posDate) {
		yyyymmdd := SubStr(text, posDate+6, 4) . SubStr(text, posDate+3, 2) . SubStr(text, posDate, 2)
		text := RegexReplace(text, "[0-9]{2}\.[0-9]{2}\.[0-9]{4}")
	}
	else {
		posDate := RegexMatch(text, "[0-9]{2}\.[0-9]{2}\.[0-9]{2}")
		if (posDate) {
			yyyymmdd := "20" . SubStr(text, posDate+6, 2) . SubStr(text, posDate+3, 2) . SubStr(text, posDate, 2)
			text := RegexReplace(text, "[0-9]{2}\.[0-9]{2}\.[0-9]{2}")
		}
		else {
			posDate := RegexMatch(text, "[0-9]{2}\.[0-9]{2}")
			if (posDate) {
				yyyymmdd := A_Year . SubStr(text, posDate+3, 2) . SubStr(text, posDate, 2)
				text := RegexReplace(text, "[0-9]{2}\.[0-9]{2}")
				flag .= 1
			}
			else {
				yyyymmdd := A_Year . A_MM . A_DD
				flag .= 2
			}
		}
	}
	posTime := RegexMatch(text, "[0-9]{2}:[0-9]{2}:[0-9]{2}")
	if (posTime)
		hhmiss := SubStr(text, posTime, 2) . SubStr(text, posTime+3, 2) . SubStr(text, posTime+6, 2)
	else {
		posTime := RegexMatch(text, "[0-9]{2}:[0-9]{2}")
		if (posTime) {
			hhmiss := SubStr(text, posTime, 2) . SubStr(text, posTime+3, 2) . "00"
			flag .= 3
		}
		else {
			if (flag = 2) {
				flag .= 5
				return A_NowUTC
			}
			else {
				posTime := RegexMatch(text, "[0-9]{2}")
				if (posTime) {
					hhmiss := SubStr(text, posTime, 2) . "0000"
					flag .= 4
				}
				else {
					hhmiss := "000000"
					flag .= 5
				}
			}
		}
			
	}
	return [yyyymmdd . hhmiss, flag]
}

UnixTimeStamp(time_orig)	{	;// stolen from https://autohotkey.com/board/topic/2486-code-to-convert-fromto-unix-timestamp/
	StringLen, date_len, time_orig
	if (date_len != 14) || (time_orig is not integer)
	  return -1

	StringLeft, now_year, time_orig, 4
	StringMid, now_month, time_orig, 5, 2
	StringMid, now_day, time_orig, 7, 2
	StringMid, now_hour, time_orig, 9, 2
	StringMid, now_min, time_orig, 11, 2
	StringRight, now_sec, time_orig, 2

	year_sec := 31536000*(now_year - 1970)

	leap_days := (now_year - 1972)/4 + 1
	Transform, leap_days, Floor, %leap_days%

	this_leap := now_year/4
	Transform, this_leap_round, Floor, %this_leap%
	If (this_leap = this_leap_round)
	  If (now_month <= 2)
		leap_days-- 
	leap_sec := leap_days*86400
	switch now_month {
		case "01":
			month_sec = 0
		case "02":
			month_sec = 2678400
		case "03":
			month_sec = 5097600
		case "04":
			month_sec = 7776000
		case "05":
			month_sec = 10368000
		case "06":
			month_sec = 13046400
		case "07":
			month_sec = 15638400
		case "08":
			month_sec = 18316800
		case "09":
			month_sec = 20995200
		case "10":
			month_sec = 23587200
		case "11":
			month_sec = 26265600
		case "12":
			month_sec = 28857600
		default:
			return -1
	}
	
	day_sec := (now_day - 1)*86400

	hour_sec := now_hour*3600 

	min_sec := now_min*60

	date_sec := year_sec + month_sec + day_sec + leap_sec + hour_sec + min_sec + now_sec

	return date_sec
}