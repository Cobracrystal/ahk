; https://github.com/cobracrystal/ahk

#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"

class TimestampConverter {

	static textTimestampConverter() {
		text := Trim(fastCopy(0.1))
		if (IsSpace(text))
			this.createTimeStampMenu(A_Now)
		else
			this.createTimeStampMenu(FormatTime(this.parseToTimeFormat(text), "yyyyMMddHHmmss"))
	}

	static unixTimeStamp(timestamp) {
		if (!IsTime(timestamp))
			throw Error("Invalid Timestamp")
		return DateDiff(timestamp, "19700101000000", "S")
	}

	static formatUnixTimeStamp(unixTimeStamp) {
		if !IsDigit(unixTimeStamp)
			throw TypeError("Invalid Unix Timestamp")
		return DateAdd("19700101000000", unixTimeStamp, "S")
	}

	static createTimeStampMenu(timestamp) {
		formats := {
			unix: this.unixTimeStamp(timestamp),
			fullDateTime:		FormatTime(timestamp, "dd.MM.yyyy, HH:mm:ss"),
			dateTimeUSA:		FormatTime(timestamp, "dd/MM/yyyy"),
			longDate:			FormatTime(timestamp, "MMMM dd, yyyy"),
			time:				FormatTime(timestamp, "HH:mm"),
			fullTime:			FormatTime(timestamp, "HH:mm:ss"),
			longDateTime:		FormatTime(timestamp, "MMMM dd, yyyy HH:mm"),
			fullLongDateTime: 	FormatTime(timestamp, "dddd, MMMM dd, yyyy HH:mm:ss")
		}
		timestampMenu := Menu()
		if (!IsTime(timestamp)) {
			timestampMenu.Add("Invalid Date", doNothing)
			timestampMenu.Disable("Invalid Date")
		} else {
			if (WinActive("Discord")) {
				timestampMenu.Add("Paste numeric Timestamp (" formats.unix ")", 				(*) => fastPrint(formats.unix))
				timestampMenu.Add("Paste 'related' format (<t:" formats.unix ":R>)", 			(*) => fastPrint("<t:" formats.unix ":R>"))
				timestampMenu.Add("Paste short time (" formats.time ")", 						(*) => fastPrint("<t:" formats.unix ":t>"))
				timestampMenu.Add("Paste long time (" formats.fullTime ")", 					(*) => fastPrint("<t:" formats.unix ":tT>"))
				timestampMenu.Add("Paste short date (" formats.dateTimeUSA ")", 				(*) => fastPrint("<t:" formats.unix ":d>"))
				timestampMenu.Add("Paste long date (" formats.longDate ")", 					(*) => fastPrint("<t:" formats.unix ":D>"))
				timestampMenu.Add("Paste full date (" formats.fullLongDateTime ")", 			(*) => fastPrint("<t:" formats.unix ":f>"))
				timestampMenu.Add("Paste long full date (" formats.fullLongDateTime ")", 		(*) => fastPrint("<t:" formats.unix ":F>"))
				timestampMenu.Add("Paste formatted current date (" formats.fullDateTime ")",	(*) => fastPrint(formats.fullDateTime))
			} else { ; 123123123
				timestampMenu.Add("Paste Unix Timestamp (" formats.unix ")", 			(*) => fastPrint(formats.unix))
				timestampMenu.Add("Paste american date (" formats.dateTimeUSA ")", 		(*) => fastPrint(formats.dateTimeUSA))
				timestampMenu.Add("Paste full date (" formats.fullDateTime ")", 		(*) => fastPrint(formats.fullDateTime))
				timestampMenu.Add("Paste datetime (" formats.longDateTime ")", 		(*) => fastPrint(formats.longDateTime))
				timestampMenu.Add("Paste long date (" formats.longDate ")", 			(*) => fastPrint(formats.longDate))
				timestampMenu.Add("Paste time (" formats.fullTime ")", 					(*) => fastPrint(formats.fullTime))
				timeStampMenu.Add("Paste long datetime (" formats.fullLongDateTime ")", (*) => fastPrint(formats.fullLongDateTime))
			}
		}
		timestampMenu.Show()
		timestampMenu.Delete()
	}

	static parseToTimeFormat(text) {
		text := RegexReplace(text, "/", ".")
		flagNoDate := false
		flagNoTime := false
		if (IsDigit(text))
			return this.formatUnixTimeStamp(text)
		text := Trim(text, " `t`r`n")
		if (RegexMatch(text, "([0-9]{2})\.([0-9]{2})(?:\.([0-9]{4}|[0-9]{2}))?", &o)) {
			yyyymmdd := o[3] o[2] o[1]
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
				}
				else {
					yyyymmdd := A_Year . A_MM . A_DD
					flagNoDate := true
				}
			}
		}
		posTime := RegexMatch(text, "[0-9]{2}:[0-9]{2}:[0-9]{2}")
		if (posTime)
			hhmiss := SubStr(text, posTime, 2) . SubStr(text, posTime+3, 2) . SubStr(text, posTime+6, 2)
		else {
			posTime := RegexMatch(text, "[0-9]{2}:[0-9]{2}")
			if (posTime)
				hhmiss := SubStr(text, posTime, 2) . SubStr(text, posTime+3, 2) . "00"
			else {
				if (flagNoDate)
					hhmiss := A_Hour . A_Min . A_Sec
				else {
					posTime := RegexMatch(text, "[0-9]{2}")
					if (posTime)
						hhmiss := SubStr(text, posTime, 2) . "0000"
					else {
						hhmiss := "000000"
						flagNoTime := true
					}
				}
			}
		}
		return String(yyyymmdd . hhmiss)
	}
}