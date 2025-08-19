#Requires AutoHotkey v2.0
#SingleInstance Off
#Include "%A_MyDocuments%\..\Desktop\programs\programming\ahk\LibrariesV2\BasicUtilities.ahk"
CoordMode("ToolTip", "Screen")
mainFunc()
return
; bad script to download files from links in clipboard, potentially parsing file info from webpage for filename
; TODO: (DAN)BOORU REST API
; TODO: FOR R34 GET THE LATTER PART OF THE TITLE
; TODO: FOR kemono GET THE URL f= TAG AND USE THAT AS THE FILENAME
mainFunc() {
	static folderPath := "Q:\stuff\media\unsorted\tUnsorted"
	text := A_Clipboard
	if (InStr(A_ScriptDir, folderPath "\tN"))
		folderPath := A_ScriptDir
	else
		folderPath .= "\tN" SubStr(A_YYYY, 3,2) . A_MM . A_DD
	if !(InStr(FileExist(folderPath), "D"))
		DirCreate(folderPath)
	if (objContainsMatch(A_Args, v => Instr(v, "--open-folder"))) {
		if (WinExist(SubStr(folderPath, InStr(folderPath, "\",,,-1)+1) . " ahk_exe explorer.exe"))
			WinActivate()
		else
			Run('explorer.exe "' folderPath '"')
		ExitApp()
	}
	linkArray := parseInput(text)
	extractLinksFromLandingPages(linkArray)
	fixLinks(linkArray)
	betterFileNames(linkArray)
	downloadLog := downloadLinks(folderPath, linkArray)
	verifyLog := verifyFiles(folderPath, downloadLog)
	writeLog(folderPath, downloadLog, verifyLog)
	info := verifyLog.Pop()
	timedTooltip((info.message), 700)
}

writeLog(folder, fileLog, verifyLog, verbose := false) {
	str := ""
	if (!verbose && fileLog.Length == 0 && verifyLog.Length == 1)
		return
	for i, e in fileLog
		if (verbose || e.result != "Success")
			str .= e.result ": " e.message ". URL:`n" e.url "`nFile: " e.fileName "." e.extension (e.origin ? " (Origin: " e.origin ")`n" : "`n")
	str .= "=============`n"
	for i, e in verifyLog {
		if (e.result = "Info")
			str .= e.result ": " e.message "`n"
		else
			str .= e.result ": " e.message ". URL: " e.url " File: " e.fileName (e.origin ? " (Origin: " e.origin ")`n" : "`n")		
	}
	FileAppend(str, folder "\log.txt")
}

verifyFiles(folder, fileLog) {
	countSuccesses := 0
	countWarnings := 0
	countErrors := 0
	countbadDownloads := 0
	local verifyLog := []
	for i, e in fileLog {
		switch e.result {
			case "Success":
				if !(FileExist(folder "\" e.fileName "." e.extension)) {
					verifyLog.Push({ result: "Error", message: "File missing", fileName: e.fileName, url: e.url, origin: e.origin })
					countbadDownloads++
				} else if (FileGetSize(folder "\" e.fileName "." e.extension) == 0) {
					verifyLog.Push({ result: "Error", message: "Deleted empty File", fileName: e.fileName . "." . e.extension, url: e.url, origin: e.origin })
					FileDelete(folder "\" e.fileName "." e.extension)
					countbadDownloads++
				} else
					countSuccesses++
			case "Error":
				countErrors++
			case "Warning":
				countWarnings++
		}
	}
	verifyLog.Push({ result: "Info", message: "Successes: " countSuccesses ", Bad Downloads: " countbadDownloads ", Warnings: " countWarnings ", Errors: " countErrors })
	return verifyLog
}

downloadLinks(folder, linkArray) {
	local downloadLog := []
	; links is an array of objects
	for i, e in linkArray {
		if (e.url = "") {
			downloadLog.Push({ result: "Error", message: "Empty URL", origin: e.origin, url: e.url, fileName: e.fileName, extension: e.extension })
		} else if (InStr(e.status, "Duplicate URL")) {
			downloadLog.Push({ result: "Error", message: e.status, origin: e.origin, url: e.url, fileName: e.fileName, extension: e.extension })
		} else if (FileExist(folder "\" e.fileName "." e.extension)) {
			downloadLog.Push({ result: "Error", message: "File already exists", origin: e.origin, url: e.url, fileName: e.fileName, extension: e.extension })
		} else {
			if (RegexMatch(e.url, "(.*)/samples/(.*)/sample_(.*)", &m)) {
				tooltiptext := "Downloading Sample " i "/" linkArray.Length ": " e.filename "." e.extension
				downloadLog.Push({ result: "Warning", message: "Thumbnail URL", origin: e.origin, url: e.url, fileName: e.fileName, extension: e.extension })
			}
			else
				tooltiptext := "Downloading " i "/" linkArray.Length ": " e.filename "." e.extension
			Tooltip(tooltiptext, 3, 3)
			Download(e.url, folder "\" e.fileName "." e.extension)
			downloadLog.Push({ result: "Success", message: "Downloaded", origin: e.origin, url: e.url, fileName: e.fileName, extension: e.extension })
			Tooltip()
		}
	}
	return downloadLog
}

fixLinks(linkArray) {
	for i, e in linkArray {
		if (InStr(e.url, "redgifs")) {
			url := e.url
			url := StrReplace(e.url, "-silent.", ".")
			linkArray[i].url := RegExReplace(url, "thumbs[\d]\.", "media.")
		}
		; bad because depending on domain, we might have to change the URL further + png/jpg might change from preview to original
		; if (RegexMatch(e.url, "(.*)/samples/(.*)/sample_(.*)", &m)) {
		; 	url := m[1] "/images/" m[2] "/" m[3] "`n"
		; }
	}
}

betterFileNames(linkArray) {
	for i, e in linkArray {
		; if we have a landing page, we can extract the title of the page and use that as the filename
		; if we have a direct link to a file, we can extract the filename from the URL
		arr := StrSplit(e.fileName, "|", " `t")
		newFileName := (arr.Length > 1) ? arr[1] : e.fileName
		for badName in ["Rule 34 - "]
			newFileName := StrReplace(newFileName, badName)
		flagHasUrlComponent := false
		for url, urlFileComponent in Map("rule34", "Rule34_", "redgif", "RedGifs_") {
			if InStr(e.url, url) {
				newFileName := urlFileComponent . newFileName
				flagHasUrlComponent := true
				break
			}
		}
		if (arr.Length > 1 && !flagHasUrlComponent)
			newFileName := StrReplace(arr[2], " ") "_" arr[1]
		newFileName := RegExReplace(newFileName, "(?<!,) ", "_")
		newFileName := SubStr(newFileName, 1, 150)
		for i, e in Map(":", "-", "/", ",", "\", "", "*", "_", "?", "!", '"', "'", "<", "", ">", "", "|", ",")
			newFileName := StrReplace(newFileName, i, e)
		newFileName :=	objCollect(objGetUniques(StrSplitUTF8(newFileName, "-,_",,true), v => Substr(v,1,-1)))
		newFileName := Trim(newFileName, " `t-_,")
		linkArray[i].fileName := newFileName
	}
	newLinkArray := []
	dupeURLs := objGetDuplicates(linkArray, e => e.url, false)
	for e in dupeURLs
		Loop(e.Length - 1)
			linkArray[e[A_Index + 1]].status := "Duplicate URL (URL " e[1] ")"
	; get duplicates of filenames while ignoring duplicate urls.
	dupeFileNames := Map()
	for i, e in linkArray {
		el := e.filename
		if (InStr(e.status, "Duplicate URL"))
			continue
		if (dupeFileNames.Has(el))
			dupeFileNames[el].push(i)
		else
			dupeFileNames[el] := [i]
	}
	for i, e in dupeFileNames {
		if (e.Length > 1)
			for j, k in e
				linkArray[k].fileName := linkArray[k].fileName "_" j
	}
}

extractLinksFromLandingPages(lnkAr) {
	for i, e in lnkAr {
		ext := ""
		RegExMatch(e.url, "([^\/\?]+)(\?.*)?$", &o)
		if (o && RegexMatch(o[1], "\.(png|jpg|jpeg|webp|gif|webm|mp4|mov|m4v|mp3|wav|ogg|opus)$", &ext)) {
			if (!e.fileName || InStr(e.fileName, o[1]))
				lnkAr[i].fileName := SubStr(o[1], 1, -4)
			lnkAr[i].extension := ext[1]
		}
		else { ; we are on a landing page. (probably.)
			Loop(2) {
				ToolTip("Extracting Links.. " (100*i//lnkAr.Length) "% done", 3, 3)
				html := StrReplace(sendRequest(e.url), "`n")
				title := RegExMatch(html, "<title>(.*)</title>", &title) ? title[1] : ""
				if (InStr(title, "Rate limiting")) {
					ToolTip("Rate Limited, Sleeping", 3, 3)
					Sleep(500)
					continue
				}
				link := RegexMatch(html, '<meta\s*property\s*=\s*"og:image".*?content="(.*?)".*?\/?>', &link) ? link[1] : ""
				if !(link)
					link := RegexMatch(html, '<meta\s*property\s*=\s*"og:video".*?content="(.*?)".*?\/?>', &link) ? link[1] : ""
				lnkAr[i].origin := e.url
				lnkAr[i].url := link
				if (RegexMatch(link, "([^\/\?]+)(\?.*)?$", &f))
					RegexMatch(f[1], "\.(png|jpg|jpeg|webp|gif|webm|mp4|m4v|mov)$", &ext)
				finfo := f ? f[1] : "unknown"
				if (ext) {
					lnkAr[i].extension := ext[1]
					finfo := SubStr(f[1], 1, -4)
				}
				else 
					lnkAr[i].extension := "html"
				lnkAr[i].fileName := title ? title : (e.fileName ? e.fileName : finfo)
				break
			}
		}
	}
	ToolTip()
}

parseInput(text) {
	arr := []
	text := Trim(text, " `t`n`r")
	Loop Parse text, "`n", "`r" {
		if (separatorPos := InStr(A_LoopField, "|")) {
			url := Trim(SubStr(A_LoopField, 1, separatorPos - 1))
			fileName := Trim(SubStr(A_LoopField, separatorPos + 1))
			arr.push({url: url, fileName: fileName, origin: "", status: "", extension: ""})
		}
		else
			arr.push({url: Trim(A_LoopField), fileName: "", origin: "", status: "", extension: ""})
	}
	return arr
}