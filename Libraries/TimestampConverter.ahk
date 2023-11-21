#Include %A_ScriptDir%\Libraries\BasicUtilities.ahk

; NOTE: DOES NOT ACKNOWLEDGE SUMMER/WINTER TIME. INTERPRETS LOCALE TIME, IF AFFECTED BY SUMMER/WINTER TIME, AS ±1 TIMEZONE.
textTimestampConverter(hotkey) {
	text := fastCopy()
	text := Trim(text)
	if (text = "") {
		validatedTimestamp := A_Now
		unixTimestamp := UnixTimeStamp(A_NowUTC)
		flag := 25
	}
	else {
		arr := parseToTimeFormat(text)
		timestamp := arr[1]
		flag := arr[2]
		FormatTime, validatedTimestamp, % timestamp, yyyyMMddHHmmss
		unixTimestamp := UnixTimeStamp(validatedTimestamp, true)
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
	SetTitleMatchMode, RegEx
;// Flags: 1 = no year, 2 = no date, 3 = no seconds, 4 = only hours, 5 = no time, 6 = invalid date
	if (flag == 6) {
		Menu, timestampMenu, Add, Invalid Date, doNothing
		Menu, timestampMenu, Disable, Invalid Date
	}
	else {
		if (WinActive("Discord ahk_exe Discord.*\.exe")) {
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
			if (flag == 25)
				Menu, timestampMenu, Add, Paste formatted current date (long) (%l%), % timeStampHandlerVar
			else
				Menu, timestampMenu, Add, Paste 'related' format (R) (<t:%unixTimestamp%:R>), % timeStampHandlerVar
		}
		else if (flag == 25) {
			FormatTime, d, %A_Now%, dd/MM/yyyy
			FormatTime, bigT, %A_Now%, HH:mm:ss
			Menu, timestampMenu, Add, Paste numeric Timestamp (UNIX) (%unixTimestamp%), % timeStampHandlerVar
			Menu, timestampMenu, Add, Paste current date (short) (%d%), % timeStampHandlerVar
			Menu, timestampMenu, Add, Paste current date (long) (%l%), % timeStampHandlerVar
			Menu, timestampMenu, Add, Paste current time (%bigT%), % timeStampHandlerVar
		}
		Menu, timestampMenu, Add, Paste numeric Timestamp (UNIX) (%unixTimestamp%), % timeStampHandlerVar	
	}
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
	switch format {
		case "U":
			str := unixTimestamp
		case "s":
			FormatTime, str, %validatedTimestamp%, dd.MM.yyyy
		case "l":
			FormatTime, str, %validatedTimestamp%, dd.MM.yyyy, HH:mm
		default:
			if (RegexMatch(format, "\d"))
				FormatTime, str, %validatedTimestamp%, HH:mm:ss
			else
				str := "<t:" . UnixTimeStamp . ":" . format . ">"
	}
	Sleep, 50
	fastPrint(str)
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
				hhmiss := A_Hour . A_Min . A_Sec
				flag .= 5
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

UnixTimeStamp(timeYMDHMS, use_locale := false)	{
	if (StrLen(timeYMDHMS) != 14) || (timeYMDHMS is not integer)
		throw Exception("Invalid YYYYMMDDHHMISS Timestamp given to UnixTimestamp(): " . timeYMDHMS)
	yyyy := SubStr(timeYMDHMS, 1, 4)
	mm := SubStr(timeYMDHMS, 5, 2)
	dd := SubStr(timeYMDHMS, 7, 2)
	hh := SubStr(timeYMDHMS, 9, 2)
	mi := SubStr(timeYMDHMS, 11, 2)
	ss := SubStr(timeYMDHMS, 13, 2)
	unix_month := ((mm > 2 ? 28 : 0) + floor(mm>8?(mm+1)/2:mm/2)*31 + floor(mm>8 ? (mm-4)/2 : (mm>3 ? (mm-3)/2 : 0))*30)*86400
	unix_leap := Floor((yyyy - 1968)/4) * 86400
	if (mod(yyyy,4) == 0 && mm <= 2)
		unix_leap -= 86400
	unix_full := 31536000*(yyyy - 1970) + unix_month + (dd - 1)*86400 + unix_leap + hh*3600 + mi*60 + ss
	if (use_locale)
		unix_full += UnixTimeStamp(A_NowUTC) - UnixTimeStamp(A_Now)
	return unix_full
}

