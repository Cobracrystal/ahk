#Include %A_ScriptDir%\LibrariesV2\BasicUtilities.ahk

; NOTE: DOES NOT ACKNOWLEDGE SUMMER/WINTER TIME. INTERPRETS LOCALE TIME, IF AFFECTED BY SUMMER/WINTER TIME, AS ±1 TIMEZONE.
textTimestampConverter(hotkey) {
	text := fastCopy()
	text := Trim(text)
	unixTimestamp := 0
	if (IsSpace(text)) {
		validatedTimestamp := A_Now
		unixTimestamp := GetUnixTimeStamp(A_NowUTC)
		flag := 25
	}
	else {
		arr := parseToTimeFormat(text)
		timestamp := arr[1]
		flag := arr[2]
		validatedTimestamp := FormatTime(timestamp, "yyyyMMddHHmmss")
		try 
			unixTimestamp := GetUnixTimeStamp(validatedTimestamp, true)
		catch error
			flag := 6
	}
	createTimeStampMenu(flag, unixTimestamp, validatedTimestamp)
}

createTimeStampMenu(flag, unixTimestamp, validatedTimestamp) {
	l := 	FormatTime(validatedTimestamp, "dd.MM.yyyy, HH:mm")
	d := 	FormatTime(validatedTimestamp, "dd/MM/yyyy")
	bigD := FormatTime(validatedTimestamp, "MMMM dd, yyyy")
	t := 	FormatTime(validatedTimestamp, "HH:mm")
	bigT := FormatTime(validatedTimestamp, "HH:mm:ss")
	f := 	FormatTime(validatedTimestamp, "MMMM dd, yyyy HH:mm")
	bigF := FormatTime(validatedTimestamp, "dddd, MMMM dd, yyyy HH:mm")
	nice := FormatTime(validatedTimestamp, "HHmm")
	timestampMenu := Menu()
;	timestampMenu.Add("Flags: " . flag, doNothing)
	if (nice = 1337) {
		timestampMenu.Add("Nice", doNothing)
		timestampMenu.Default := "Nice"
		timestampMenu.Disable("Nice")
	}
	SetTitleMatchMode("RegEx")
;// Flags: 1 = no year, 2 = no date, 3 = no seconds, 4 = only hours, 5 = no time, 6 = invalid date
	if (flag == 6) {
		timestampMenu.Add("Invalid Date", doNothing)
		timestampMenu.Disable("Invalid Date")
	}
	else {
		tshO := timestampHandler
		if (WinActive("Discord ahk_exe Discord.*\.exe")) {
			if (flag = 23)
				timestampMenu.Add("Paste short time (" t ")", tshO.Bind("<t:" unixTimestamp ":t>"))
			else {
				if (flag = 5 || flag = 15 || flag = 25)
					timestampMenu.Add("Paste short date (" d ")", tshO.Bind("<t:" unixTimestamp ":d>"))
				if (flag = 5 || flag = 15)
					timestampMenu.Add("Paste long date (" bigD ")", tshO.Bind("<t:" unixTimestamp ":D>"))
				if (flag = 2 || flag = 25)
					timestampMenu.Add("Paste long time (" bigT ")", tshO.Bind("<t:" unixTimestamp ":tT>"))
				if (flag = 1 || flag = 4 || flag = 3 || flag = 13 || flag = 14 || flag = 25 || flag = "") {
					timestampMenu.Add("Paste full date (" f ")", tshO.Bind("<t:" unixTimestamp ":f>"))
					timestampMenu.Add("Paste long full date (" bigF ")", tshO.Bind("<t:" unixTimestamp ":F>"))
				}
			}
			if (flag == 25)
				timestampMenu.Add("Paste formatted current date (" l ")", tshO.Bind(l))
			else
				timestampMenu.Add("Paste 'related' format (<t:" unixTimestamp ":R>)", tshO.Bind("<t:" unixTimestamp ":R>"))
			timestampMenu.Add("Paste numeric Timestamp (" unixTimestamp ")", tshO.Bind(unixTimestamp))
		}
		else if (flag == 25) {
			timestampMenu.Add("Paste numeric Timestamp (" unixTimestamp ")", tshO.Bind(unixTimestamp))
			timestampMenu.Add("Paste current date (" d ")", tshO.Bind(d))
			timestampMenu.Add("Paste current date (" l ")", tshO.Bind(l))
			timestampMenu.Add("Paste current date (" bigF ")", tshO.Bind(bigF))
			timestampMenu.Add("Paste current time (" bigT ")", tshO.Bind(bigT))
		}
		else {
			timestampMenu.Add("Paste numeric Timestamp (" unixTimestamp ")", tshO.Bind(unixTimestamp))
			timeStampMenu.Add("Paste long date (" bigF ")", tshO.Bind(bigF))
		}
	}
	timestampMenu.Show()
	timestampMenu.Delete()
}

timestampHandler(str, *) {
	Sleep(50)
	fastPrint(str)
}

parseToTimeFormat(text) {
	flag := ""
	text := RegexReplace(text, "/", ".")
	posDate := RegexMatch(text, "[0-9]{2}\.[0-9]{2}\.[0-9]{4}")
	if (posDate) {
		yyyymmdd := SubStr(text, posDate+6, 4) . SubStr(text, posDate+3, 2) . SubStr(text, posDate, 2)
		text := RegexReplace(text, "[0-9]{2}\.[0-9]{2}\.[0-9]{4}", "##########")
	}
	else {
		posDate := RegexMatch(text, "[0-9]{2}\.[0-9]{2}\.[0-9]{2}")
		if (posDate) {
			yyyymmdd := "20" . SubStr(text, posDate+6, 2) . SubStr(text, posDate+3, 2) . SubStr(text, posDate, 2)
			text := RegexReplace(text, "[0-9]{2}\.[0-9]{2}\.[0-9]{2}", "########")
		}
		else {
			posDate := RegexMatch(text, "[0-9]{2}\.[0-9]{2}")
			if (posDate) {
				yyyymmdd := A_Year . SubStr(text, posDate+3, 2) . SubStr(text, posDate, 2)
				text := RegexReplace(text, "[0-9]{2}\.[0-9]{2}", "#####")
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

GetUnixTimeStamp(timeYMDHMS, use_locale := false)	{
	if (StrLen(timeYMDHMS) != 14) || (!IsInteger(timeYMDHMS))
		throw Error("Invalid YYYYMMDDHHMISS Timestamp given to UnixTimestamp(): " . timeYMDHMS)
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
		unix_full += GetUnixTimeStamp(A_NowUTC) - GetUnixTimeStamp(A_Now)
	return unix_full
}

