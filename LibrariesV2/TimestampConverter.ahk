; https://github.com/cobracrystal/ahk

#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"

; note: does not acknowledge summer/winter time. will interpret locale time, if affected by summer/winter time, as ±1 timezone.
textTimestampConverter() {
	text := fastCopy(0.1)
	text := Trim(text)
	unix := 0
	if (IsSpace(text)) {
		valid := A_Now
		unix := unixTimeStamp(A_NowUTC)
		flag := 25
	}
	else {
		arr := parseToTimeFormat(text)
		timestamp := arr[1]
		flag := arr[2]
		valid := FormatTime(timestamp, "yyyyMMddHHmmss")
		try 
			unix := unixTimeStamp(valid)
		catch error
			flag := 6
	}
	createTimeStampMenu(flag, unix, valid)
}

unixTimeStamp(timestamp) {
	if (!IsTime(timestamp))
		throw Error("Invalid Timestamp")
	return DateDiff(timestamp, "19700101000000", "S")
}

formatUnixTimeStamp(unixTimeStamp) {
	if !IsDigit(unixTimeStamp)
		throw TypeError("Invalid Unix Timestamp")
	return DateAdd("19700101000000", unixTimeStamp, "S")
}

getTimestampFromText(text) {
	return Format(parseToTimeFormat(text)[1], "yyyyMMddHHmmss")
}

createTimeStampMenu(flag, unix, valid) {
	formats := {
		unix: unix,
		fullDateTime:		FormatTime(valid, "dd.MM.yyyy, HH:mm"),
		dateTimeUSA:		FormatTime(valid, "dd/MM/yyyy"),
		longDate:			FormatTime(valid, "MMMM dd, yyyy"),
		time:				FormatTime(valid, "HH:mm"),
		fullTime:			FormatTime(valid, "HH:mm:ss"),
		longDateTime:		FormatTime(valid, "MMMM dd, yyyy HH:mm"),
		fullLongDateTime: 	FormatTime(valid, "dddd, MMMM dd, yyyy HH:mm")
	}
	timestampMenu := Menu()
	; timestampMenu.Add("Flags: " . flag, doNothing)
;// Flags: 1 = no year, 2 = no date, 3 = no seconds, 4 = only hours, 5 = no time, 6 = invalid date
	if (flag == 6) {
		timestampMenu.Add("Invalid Date", doNothing)
		timestampMenu.Disable("Invalid Date")
	}
	else {
		printer := timestampHandler
		if (WinActive("Discord ahk_exe Discord.exe")) {
			timestampMenu.Add("Paste numeric Timestamp (" formats.unix ")", 				printer.Bind(unix))
			timestampMenu.Add("Paste short time (" formats.time ")", 						printer.Bind("<t:" unix ":t>"))
			timestampMenu.Add("Paste long time (" formats.fullTime ")", 					printer.Bind("<t:" unix ":tT>"))
			timestampMenu.Add("Paste short date (" formats.dateTimeUSA ")", 				printer.Bind("<t:" unix ":d>"))
			timestampMenu.Add("Paste long date (" formats.longDate ")", 					printer.Bind("<t:" unix ":D>"))
			timestampMenu.Add("Paste full date (" formats.fullLongDateTime ")", 			printer.Bind("<t:" unix ":f>"))
			timestampMenu.Add("Paste long full date (" formats.fullLongDateTime ")", 		printer.Bind("<t:" unix ":F>"))
			timestampMenu.Add("Paste formatted current date (" formats.fullDateTime ")",	printer.Bind(formats.fullDateTime))
			timestampMenu.Add("Paste 'related' format (<t:" formats.unix ":R>)", 			printer.Bind("<t:" unix ":R>"))
		} else {
			timestampMenu.Add("Paste Unix Timestamp (" formats.unix ")", 			printer.Bind(formats.unix))
			timestampMenu.Add("Paste american date (" formats.dateTimeUSA ")", 		printer.Bind(formats.dateTimeUSA))
			timestampMenu.Add("Paste current date (" formats.fullDateTime ")", 		printer.Bind(formats.fullDateTime))
			timestampMenu.Add("Paste current date (" formats.fullLongDateTime ")", 	printer.Bind(formats.fullLongDateTime))
			timestampMenu.Add("Paste current date (" formats.longDate ")", 			printer.Bind(formats.longDate))
			timestampMenu.Add("Paste current time (" formats.fullTime ")", 			printer.Bind(formats.fullTime))
			timestampMenu.Add("Paste numeric Timestamp (" formats.unix ")", 		printer.Bind(formats.unix))
			timeStampMenu.Add("Paste long date (" formats.fullLongDateTime ")", 	printer.Bind(formats.fullLongDateTime))
		}
	}
	timestampMenu.Show()
	timestampMenu.Delete()
}

timestampHandler(str, *) {
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
				if (IsDigit(text)) {
					yyyymmdd := SubStr(formatUnixTimeStamp(text), 1, 8)
				}
				else {
					yyyymmdd := A_Year . A_MM . A_DD
					flag .= 2
				}
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

