#Requires AutoHotkey v2.0
#SingleInstance Off
#Include "BasicUtilities.ahk"
#Include "PrimitiveUtilities.ahk"
if (A_LineFile == A_ScriptFullPath) {
	CoordMode("ToolTip", "Screen")
	BooruDownload.main()
}

; bad script to download files from links in clipboard, potentially parsing file info from webpage for filename
; TODO: (DAN)BOORU REST API
; TODO: FOR R34 GET THE LATTER PART OF THE TITLE
; TODO: FOR kemono GET THE URL f= TAG AND USE THAT AS THE FILENAME
class BooruDownload {
	static basePath := "Q:\stuff\media\unsorted\tUnsorted"
	
	static main(text := A_Clipboard) {
		folderPath := this.getCurrentPath()
		linkArray := this.parseLinks(text)
		this.extractLinksFromLandingPages(linkArray)
		this.fixLinks(linkArray)
		this.generateFileNames(linkArray)
		downloadLog := this.downloadLinks(folderPath, linkArray)
		verifyLog := this.verifyFiles(folderPath, downloadLog)
		this.writeLog(folderPath, downloadLog, verifyLog)
		info := verifyLog.Pop()
		timedTooltip((info.message), 700)
	}

	static openFolder() {
		folderPath := this.getCurrentPath()
		SplitPath(folderPath, &name)
		if (WinExist(name . " ahk_exe explorer.exe"))
			WinActivate()
		else
			Run('explorer.exe "' folderPath '"')
	}

	static getCurrentPath() {
		if (InStr(A_ScriptDir, this.basePath "\tN")) ; if script inside of folder of shape tUnsorted\tN..., use that directory
			folderPath := A_ScriptDir
		else
			folderPath := this.basePath "\tN" SubStr(A_YYYY, 3,2) . A_MM . A_DD
		if !(DirExist(folderPath))
			DirCreate(folderPath)
		return folderPath
	}

	static writeLog(folder, fileLog, verifyLog, verbose := false) {
		str := "`n===== " FormatTime(A_Now,"HH:mm:ss") " ====="
		if (!verbose && fileLog.Length == 0 && verifyLog.Length == 1)
			return
		for i, e in fileLog
			if (verbose || e.result != "Success")
				str .= e.result ": " e.message ". URL:`n" e.url "`nFile: " e.fileName "." e.extension (e.origin ? " (Origin: " e.origin ")`n" : "`n")
		str .= "--------------------`n"
		for i, e in verifyLog {
			if (e.result = "Info")
				str .= e.result ": " e.message "`n"
			else
				str .= e.result ": " e.message ". URL: " e.url " File: " e.fileName (e.origin ? " (Origin: " e.origin ")`n" : "`n")		
		}
		FileAppend(str, folder "\log.txt")
	}

	static verifyFiles(folder, downloadLog) {
		countSuccesses := 0
		countWarnings := 0
		countErrors := 0
		countbadDownloads := 0
		local verifyLog := []
		for logObject in downloadLog {
			switch logObject.result {
				case "Success":
					if !(FileExist(folder "\" logObject.fileName "." logObject.extension)) {
						verifyLog.Push({ result: "Error", message: "File missing", fileName: logObject.fileName, url: logObject.url, origin: logObject.origin })
						countbadDownloads++
					} else if (FileGetSize(folder "\" logObject.fileName "." logObject.extension) == 0) {
						verifyLog.Push({ result: "Error", message: "Deleted empty File", fileName: logObject.fileName . "." . logObject.extension, url: logObject.url, origin: logObject.origin })
						FileDelete(folder "\" logObject.fileName "." logObject.extension)
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

	static downloadLinks(folder, linkArray) {
		local downloadLog := []
		; links is an array of objects
		for i, linkObj in linkArray {
			logObject := { origin: linkObj.origin, url: linkObj.url, fileName: linkObj.fileName, extension: linkObj.extension }
			if (linkObj.url == "") {
				logObject.result := "Error"
				logObject.message := "Empty URL"
				downloadLog.push(logObject)
				continue
			}
			if (InStr(linkObj.status, "Duplicate URL")) {
				logObject.result := "Error"
				logObject.message := linkObj.status
				downloadLog.push(logObject)
				continue
			}
			if (FileExist(folder "\" linkObj.fileName "." linkObj.extension)) {
				logObject.result := "Error"
				logObject.message := "File already exists"
				downloadLog.push(logObject)
				continue
			}
			if (InStr(linkObj.url, "sample") || InStr(linkObj.url, "thumb")) {
				tooltiptext := "Downloading Sample " i "/" linkArray.Length ": " linkObj.filename "." linkObj.extension
				logObject.result := "Warning"
				logObject.message := "Thumbnail URL"
				downloadLog.Push(logObject)
			}
			else
				tooltiptext := "Downloading " i "/" linkArray.Length ": " linkObj.filename "." linkObj.extension
			Tooltip(tooltiptext, 3, 3)
			Download(linkObj.url, folder "\" linkObj.fileName "." linkObj.extension)
			logObject.result := "Success"
			logObject.message := "Downloaded"
			downloadLog.Push(logObject)
			Tooltip()
		}
		return downloadLog
	}

	static fixLinks(linkArray) {
		for linkObject in linkArray {
			if (InStr(linkObject.url, "redgifs")) {
				url := linkObject.url
				url := StrReplace(linkObject.url, "-silent.", ".")
				linkObject.url := RegExReplace(url, "thumbs[\d]\.", "media.")
			}
			; bad because depending on domain, we might have to change the URL further + png/jpg might change from preview to original
			; if (RegexMatch(e.url, "(.*)/samples/(.*)/sample_(.*)", &m)) {
			; 	url := m[1] "/images/" m[2] "/" m[3] "`n"
			; }
		}
	}

	static generateFileNames(linkArray) {
		for linkObject in linkArray {
			; if we have a landing page, we can extract the title of the page and use that as the filename
			; if we have a direct link to a file, we can extract the filename from the URL
			arr := StrSplit(linkObject.fileName, "|", " `t")
			newFileName := (arr.Length > 1) ? arr[1] : linkObject.fileName
			for badName in ["Rule 34 - "]
				newFileName := StrReplace(newFileName, badName)
			flagHasUrlComponent := false
			for url, urlFileComponent in Map("rule34", "Rule34_", "redgif", "RedGifs_", "Gelbooru", "Gelbooru_") {
				if InStr(linkObject.url, url) {
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
			newFileName :=	objCollect(objGetUniques(StrSplit(newFileName, "-,_",,true), v => Substr(v,1,-1)))
			newFileName := Trim(newFileName, " `t-_,")
			linkObject.fileName := newFileName
		}
		dupeURLs := objGetDuplicates(linkArray, e => e.url,, true)
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
		for index, dupesIterator in dupeFileNames {
			if (dupesIterator.Length > 1)
				for j, k in dupesIterator
					linkArray[k].fileName := linkArray[k].fileName "_" j
		}
	}

	static isDirectFileLink(link) {
		RegExMatch(link, "([^\/\?]+)(\?.*)?$", &o)
		if (o && RegexMatch(o[1], "\.(png|jpg|jpeg|webp|gif|webm|mp4|mov|m4v|mp3|wav|ogg|opus)$", &ext))
			return { lastUrlPathSegment: o[1], query: o[2], ext: ext[1]}
		else
			return 0
	}
	
	static getFilenameFromURL(link) {
		if (info := this.isDirectFileLink(link))
			return SubStr(info.lastUrlPathSegment, 1, -strlen(info.ext) - 1)
	}

	static extractLinksFromLandingPages(linkArray) {
		for i, linkObject in linkArray {
			ext := ""
			if (info := this.isDirectFileLink(linkObject.url)) {
				if (!linkObject.filename || InStr(linkObject.fileName, info.lastUrlPathSegment))
					linkObject.fileName := SubStr(info.lastUrlPathSegment, 1, -strlen(info.ext) - 1)
				linkObject.extension := info.ext
			}
			else { ; we are on a landing page. (probably.)
				Loop(2) {
					ToolTip("Extracting Links.. " (100*i//linkArray.Length) "% done", 3, 3)
					headers := Map("Sec-Fetch-Site", "same-origin", "Sec-Fetch-Mode", "navigate", "Sec-Fetch-Dest", "document", "referer", RegExReplace(linkObject.url, "i)(^https?:\/\/[^\/]+\/?).*", "$1"))
					html := StrReplace(sendRequest(linkObject.url, ,,,, headers), "`n")
					title := RegExMatch(html, "<title>(.*)</title>", &title) ? title[1] : ""
					if (InStr(title, "Rate limiting")) {
						ToolTip("Rate Limited, Sleeping", 3, 3)
						Sleep(500)
						continue
					}
					if InStr(linkObject.url, "yande.re") {
						link := RegExMatch(html, '"file_url":"(.*?)"', &link) ? link[1] : ""
					} else {
						link := RegexMatch(html, '<meta\s*property\s*=\s*"og:image".*?content="(.*?)".*?\/?>', &link) ? link[1] : ""
						if !(link)
							link := RegexMatch(html, '<meta\s*property\s*=\s*"og:video".*?content="(.*?)".*?\/?>', &link) ? link[1] : ""
					}
					linkObject.origin := linkObject.url
					linkObject.url := link
					if (RegexMatch(link, "([^\/\?]+)(\?.*)?$", &f))
						RegexMatch(f[1], "\.(png|jpg|jpeg|webp|gif|webm|mp4|m4v|mov)$", &ext)
					finfo := f ? f[1] : "unknown"
					if (ext) {
						linkObject.extension := ext[1]
						finfo := SubStr(f[1], 1, -4)
					}
					else 
						linkObject.extension := "html"
					linkObject.fileName := title ? title : (linkObject.fileName ? linkObject.fileName : finfo)
					break
				}
			}
		}
		ToolTip()
	}

	static basicFileName() {

	}

	static parseLinks(text) {
		arr := []
		for line in strSplitOnNewLine(text) {
			splits := StrSplit(line, "|", " `t")
			arr.push({url: splits[1], fileName: splits.Length > 1 ? splits[2] : "", origin: "", status: "", extension: ""})
		}
		return arr
	}
}