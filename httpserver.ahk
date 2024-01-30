#Persistent
#SingleInstance, force
#include %A_ScriptDir%\Libraries\AHKhttp.ahk
#include %A_ScriptDir%\Libraries\AHKsock.ahk
#include %A_ScriptDir%\Libraries\BasicUtilities.ahk
SetWorkingDir, %A_ScriptDir%\script_files\httpserver
SetBatchLines, -1

pathArr := {  "/":"mainIndex"
			, "404":"NotFound"
			, "/whoami":"whoami"
			, "/iptracker": "whoami"
			, "/redirect":"redirect"
			, "/page":"page"
			, "/calc":"calc"
			, "/bettercounter/*":"bettercounter"
			, "/webfiles/*":"handleWebfiles"
			, "/music/*":"handleMusicfiles"
			, "/ahk/*":"handleAHKfiles" }
; paths["/index"] := Redirect
paths := registerFunctions(pathArr)
server := new HttpServer()
server.LoadMimes(A_WorkingDir . "\meta\mime.types")
server.SetFavicon(A_WorkingDir . "\meta\favicon.ico")
server.SetPaths(paths)
server.Serve(80)
CURRENT_PUBLIC_IP := sendRequest("https://icanhazip.com") ; SEE NOTES AT BOTTOM OF SCRIPT
; CURRENT_PUBLIC_IP := getIP()
return


mainIndex(ByRef req, ByRef res, ByRef server) {
	logger(req)
	server.ServeFile(res, A_WorkingDir . "\mainIndex.html")
	res.status := 200
}

redirect(ByRef req, ByRef res, ByRef server) {
	logger(req)
	res.headers["Location"] := "http://florianten.de"
	res.status := 307
	return
	server.ServeFile(res, A_WorkingDir . "\webfiles\redirectflorianten.html")
	res.status := 200
}

NotFound(ByRef req, ByRef res, ByRef server) {
	logger(req)
    res.SetBodyText("Page not found")
    res.status := 200
}

page(ByRef req, ByRef res) {
	logger(req)
	ahp := "<html>`n<title>Query Test</title>`n<body>`n<b>[var]</b>`n</body>`n</html>"
	form := "<form action=""/calc"" method=""get""><input type=""text"" name=""num1"" value=""" req.queries["num1"] """> + <input type=""text"" name=""num2"" value=""" req.queries["num2"] """><input type=""submit""></form>"
	serve := StrReplace(ahp, "[var]", "num1: " req.queries["num1"] " - num2: " req.queries["num2"] "<br><br>" form)
	clipboard := serve
    res.SetBodyText(serve, "text/html")
    res.status := 200
}

calc(ByRef req, ByRef res) {
	logger(req)
	ahp := "<html>`n<title>Still a query test.</title>`n<body>`n<b>[var]</b>`n</body>`n</html>"
	answer := req.queries["num1"] + req.queries["num2"]
	serve := StrReplace(ahp, "[var]", req.queries["num1"] "+" req.queries["num2"] "=" answer)
    res.SetBodyText(serve, "text/html")
    res.status := 200
}

whoami(ByRef req, ByRef res, ByRef server) {
	logger(req)
	logFile := A_WorkingDir . "\fullRequestLog.txt"
	str := "-----------------------------------------------------`n"
	str .= "REQUEST MADE AT " . formatTimeFunc(,"dd-MM-yyyy HH:mm:ss.") . Mod(A_TickCount,1000) . " (System Time)`n"
	str .= "-----------------------------------------------------`n"
	str .= "Request Path: " . req.path . "`n"
	str .= "Request Method: " . req.method . "`n"
	str .= "Request Protocol: " . req.protocol . "`n"
	if (req.headers.Count() > 0)
		str .= "Request Headers:`n"
	for i, e in req.headers
		str .= "`t" . i . ": " . e . "`n"
	if (req.queries.Count() > 0)
		str .= "Request Queries:`n"
	for i, e in req.queries
		str .= "`t" . i . ": " . e . "`n"
	res.SetBodyText(str)
	res.status := 200
	FileAppend, % str, % logFile, % "UTF-8"
}

logger(ByRef req) {
	logFile := A_WorkingDir . "\logAllRequests.txt"
	str := "-----------------------------------------------------`nNEW REQUEST MADE AT " . formatTimeFunc(,"dd-MM-yyyy HH:mm:ss.") . Mod(A_TickCount,1000) . " (System Time)`n"
	str .= "Path: " . req.path . "`nIP: " req.headers["CF-Connecting-IP"] . " (Country: " . req.headers["CF-IPCountry"] . ")`nUser Agent: " . req.headers["user-agent"] . "`nQueries: "
	for i, e in req.queries
		if (e != req.path)
			str .= i . ": " . e . ", "
	str .= "`n"
	FileAppend, % str, % logFile, % "UTF-8"
}

handleWebfiles(ByRef req, ByRef res, ByRef server) {
	logger(req)
	origin := A_WorkingDir
	vpath := StrReplace(req.path, "/", "\")
	indexFilesGeneric(req, res, server, origin, vpath)
}


handleMusicfiles(ByRef req, ByRef res, ByRef server) {
	logger(req)
	global CURRENT_PUBLIC_IP
	static origin := RegexReplace(A_MyDocuments, "\\[^\\]*$", "") . "\Music\Musik\ConvertMusic\NoMetadata"
	URLorigin := "/music/"
	vpath := StrReplace(SubStr(req.path, StrLen(URLorigin)), "/", "\")
	if (req.headers["CF-Connecting-IP"] == CURRENT_PUBLIC_IP)
		indexFilesGeneric(req, res, server, origin, vpath, "/music")
	else {
		res.SetBodyText("Not allowed to see.")
		res.status := 200
	}
}

handleAHKfiles(ByRef req, ByRef res, ByRef server) {
	logger(req)
	origin := A_Desktop "\programs\programming\ahk"
	URLorigin := "/ahk/"
	vpath := StrReplace(SubStr(req.path, StrLen(URLorigin)), "/", "\") ; since path will ALWAYS start with /ahk/, we don't have to worry about anything else.
	indexFilesGeneric(req, res, server, origin, vpath, "/ahk", "ahk")
}

bettercounter(ByRef req, ByRef res, ByRef server) {
	logger(req)
	origin := A_WorkingDir . "\webfiles\web"
	URLorigin := "/bettercounter/"
	vpath := StrReplace(Substr(req.path, StrLen(URLorigin)), "/", "\")
	if (vpath == "\" || vPath == "") {
		server.ServeFile(res, A_WorkingDir . "\webfiles\web\index.html")
		res.status := 200
	} 
	else
		indexFilesGeneric(req, res, server, origin, vpath, "/webfiles/web")
}

bettercounter2(ByRef req, ByRef res, ByRef server) {
	logger(req)
	origin := A_WorkingDir . "\webfiles\web"
	URLorigin := "/bettercounter/"
	vpath := StrReplace(Substr(req.path, StrLen(URLorigin)), "/", "\")
	indexFilesGeneric(req, res, server, origin, vpath, "/webfiles/web")
}

indexFilesGeneric(ByRef req, ByRef res, ByRef server, origin, vpath := "\", title := "", ext := "*", mode := "DF") {
	normPath := normalizePath(origin . vpath)
	t := FileExist(normPath)
	if (t) {
		if (InStr(t, "D")) {
			if (SubStr(vpath, 0) != "\") {
				res.headers["Location"] := StrReplace(vpath, "\", "/") . "/"
				res.status := 308
				return
			}
			html := generateDirectoryListing(origin, vpath, title, ext, mode)
			if (html)
				res.SetBodyText(html, "text/html")
			else 
				res.SetBodyText("Illegal File access.")
		}
		else {
			SplitPath, % normPath, , , fExt
			if (ext == "*" || fExt == ext) {
			;	res.Set ; make a title for the tab??
				server.ServeFile(res, normPath)
			}
			else 
				res.SetBodyText("File not available.")
		}
	}
	else
		res.SetBodyText("File not found.")
	res.status := 200
}

generateDirectoryListing(origin, vpath := "\", title := "", ext := "*", fileMode := "DF") {
	htmlTemplate := readFileIntoVar(A_workingDir . "\meta\indexTemplate.html")
	origin := (SubStr(origin, 0) == "\" ? SubStr(origin, 1, -1) : origin)
	fullPath := normalizePath(origin . vpath)
	if !(InStr(fullPath, origin))
		return ""
	arrFiles := {}
	arrFolders := {}
	Loop, Files, % fullPath . "*.*", % fileMode
	{
		if (InStr(A_LoopFileAttrib, "D"))
			arrFolders.push({"name":A_LoopFileName, "time":A_LoopFileTimeCreated})
		else if (ext == "*" || A_LoopFileExt == ext)
			arrFiles.push({"name":A_LoopFileName, "time":A_LoopFileTimeModified, "size":A_LoopFileSize})
	}
	arr1 := sortKeyArray(arrFolders, "name")
	arr2 := sortKeyArray(arrFiles, "name")
	str := "<a href=""../"">../</a>`n"
	for i, e in arr1
		str .= Format("<a href=""" . e.name . "/"">{1:-64}{2}`n", e.name . "</a>",  FormatTimeFunc(e.time, "dd-MM-yyyy HH:mm:ss"))
	for i, e in arr2
		str .= Format("<a href=""" . e.name . """>{1:-64}{2}  {3:15} Bytes`n", e.name "</a>",  FormatTimeFunc(e.time, "dd-MM-yyyy HH:mm:ss"), RegExReplace(e.size, "\G\d+?(?=(\d{3})+(?:\D|$))", "$0," ))
	full := StrReplace(htmlTemplate, "[var1]", StrReplace((title=="" ? vpath : title . vpath), "\", "/"))
	full := StrReplace(full, "[var2]", str)
	return full
}

registerFunctions(array) {
	arr2 := {}
	for i, e in array 
		if (IsFunc(e))	
			arr2[i . ""] := Func(e) ; appending "" so that numerical paths get treated as strings, since arr[10] ≠ arr["10"]
	return arr2
}

getIp() {
	return cmdRet("dig @resolver4.opendns.com myip.opendns.com +short")
}
sendRequest(url := "https://icanhazip.com/", method := "GET") {
	HttpObj := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	HttpObj.Open(method, url)
	HttpObj.Send()
	return Trim(httpobj.ResponseText, "`n`r`t ")
}

^+r::
reload
return

/*
FOR SELF-REQUESTING IP:
anstr := "1234567890abcdefghijklmnopqrstuvxyz"
randomID := SubStr(StrReplace(sortFunc(RegExReplace(anstr . anstr, "[^a-z0-9]*", "|"), "D| Random"), "|"), StrLen(anstr))
pathArr["/" . randomID] := "selfRequest"
CURRENT_PUBLIC_IP2 := sendRequest("https://cobracrystal.com/" . randomID)
selfRequest(ByRef req, ByRef res, ByRef server) {
	res.SetBodyText(req.headers["CF-Connecting-IP"])
	res.status := 200
}
; HOWEVER, THIS LITERALLY CRASHES BECAUSE AHK WAITS FOR COMOBJ AND CANT HANDLE THE REQUEST AT THE SAME TIME
; otherwise: run wanip / dig @resolver4.opendns.com myip.opendns.com +short through cmdRet
*/
