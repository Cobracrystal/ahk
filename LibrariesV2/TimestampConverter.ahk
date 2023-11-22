; https://github.com/cobracrystal/ahk

#Include %A_ScriptDir%\LibrariesV2\BasicUtilities.ahk

; note: does not acknowledge summer/winter time. will interpret locale time, if affected by summer/winter time, as ±1 timezone.
textTimestampConverter() {
	text := fastCopy()
	text := Trim(text)
	unix := 0
	if (IsSpace(text)) {
		valid := A_Now
		unix := DateDiff(A_NowUTC, "19700101000000", "S")
		flag := 25
	}
	else {
		arr := parseToTimeFormat(text)
		timestamp := arr[1]
		flag := arr[2]
		valid := FormatTime(timestamp, "yyyyMMddHHmmss")
		try 
			unix := DateDiff(valid, "19700101000000", "S")
		catch error
			flag := 6
	}
	createTimeStampMenu(flag, unix, valid)
}

createTimeStampMenu(flag, unix, valid) {
	l := 	FormatTime(valid, "dd.MM.yyyy, HH:mm")
	d := 	FormatTime(valid, "dd/MM/yyyy")
	bigD := FormatTime(valid, "MMMM dd, yyyy")
	t := 	FormatTime(valid, "HH:mm")
	bigT := FormatTime(valid, "HH:mm:ss")
	f := 	FormatTime(valid, "MMMM dd, yyyy HH:mm")
	bigF := FormatTime(valid, "dddd, MMMM dd, yyyy HH:mm")
	timestampMenu := Menu()
	; timestampMenu.Add("Flags: " . flag, doNothing)
	SetTitleMatchMode("RegEx")
;// Flags: 1 = no year, 2 = no date, 3 = no seconds, 4 = only hours, 5 = no time, 6 = invalid date
	if (flag == 6) {
		timestampMenu.Add("Invalid Date", doNothing)
		timestampMenu.Disable("Invalid Date")
	}
	else {
		o := timestampHandler
		if (WinActive("Discord ahk_exe Discord.*\.exe")) {
			if (flag = 23)
				timestampMenu.Add("Paste short time (" t ")", o.Bind("<t:" unix ":t>"))
			else {
				if (flag = 5 || flag = 15 || flag = 25)
					timestampMenu.Add("Paste short date (" d ")", o.Bind("<t:" unix ":d>"))
				if (flag = 5 || flag = 15)
					timestampMenu.Add("Paste long date (" bigD ")", o.Bind("<t:" unix ":D>"))
				if (flag = 2 || flag = 25)
					timestampMenu.Add("Paste long time (" bigT ")", o.Bind("<t:" unix ":tT>"))
				if (flag = 1 || flag = 4 || flag = 3 || flag = 13 || flag = 14 || flag = 25 || flag = "") {
					timestampMenu.Add("Paste full date (" f ")", o.Bind("<t:" unix ":f>"))
					timestampMenu.Add("Paste long full date (" bigF ")", o.Bind("<t:" unix ":F>"))
				}
			}
			if (flag == 25)
				timestampMenu.Add("Paste formatted current date (" l ")", o.Bind(l))
			else
				timestampMenu.Add("Paste 'related' format (<t:" unix ":R>)", o.Bind("<t:" unix ":R>"))
			timestampMenu.Add("Paste numeric Timestamp (" unix ")", o.Bind(unix))
		}
		else if (flag == 25) {
			timestampMenu.Add("Paste numeric Timestamp (" unix ")", o.Bind(unix))
			timestampMenu.Add("Paste current date (" d ")", o.Bind(d))
			timestampMenu.Add("Paste current date (" l ")", o.Bind(l))
			timestampMenu.Add("Paste current date (" bigF ")", o.Bind(bigF))
			timestampMenu.Add("Paste current time (" bigT ")", o.Bind(bigT))
		}
		else {
			timestampMenu.Add("Paste numeric Timestamp (" unix ")", o.Bind(unix))
			timeStampMenu.Add("Paste long date (" bigF ")", o.Bind(bigF))
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

