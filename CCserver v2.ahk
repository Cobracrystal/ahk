#Requires AutoHotkey v2.0
#SingleInstance Force
#Include "LibrariesV2"
#Include "BasicUtilities.ahk"
#Include "FileUtilities.ahk"
#Include "TimeUtilities.ahk"
#Include "External\WebSocket.ahk"
#Include "External\httpserver.ahk"
#Include "External\jsongo.ahk"
#Include "External\compress.ahk"
Persistent()
SetWorkingDir(A_ScriptDir "\script_files\httpserver")




/*
TODO
whr.body directly into res how
what the fuck is solar doing
flutter not working correctly
line 209 redirect doesn't work cause vpath doesn't include the origin

*/
CCServer.Serve("3141")
testRequest()
class CCServer {
	static __New() {
		this.baseURL := "http://localhost"
		this.paths := Map(
			"/", this.mainIndex.bind(this),
			"/favicon.ico", this.favicon.bind(this),
			"/whoami", this.whoami.bind(this),
			"/iptracker", this.whoami.bind(this),
			"/redirect", this.redirect.bind(this,,, "https://www.youtube.com/watch?v=dQw4w9WgXcQ"),
			"/page", this.page.bind(this),
			"/calc", this.calc.bind(this),
			"/solar", this.solar.bind(this),
			"/counter", this.mediocreCounter.bind(this),
			"/bettercounter", this.betterCounter.bind(this),
			"/webfiles", this.FileIndex.web.bind(this.FileIndex),
			"/music", this.FileIndex.music.bind(this.FileIndex),
			"/ahk", this.FileIndex.ahk.bind(this.FileIndex)
			; "/embed/*", "embedder" 
		)
	}

	static Serve(port) {
		this.publicIP := sendRequest("https://icanhazip.com") ; SEE NOTES AT BOTTOM OF SCRIPT
		this.server := HttpServer()
		this.serverURL := this.baseURL . ":" port
		; Monitor all IPs on the current computer, requiring administrator privileges
		; this.server.Add('http://+:1212/', handler)

		for vPath, handler in this.paths
			this.server.Add(this.serverURL . vPath, handler)
	}

	static mainIndex(req, res) {
		this.logger(req)
		if (this.parsePath(req) != "/")
			res("Oops! This page doesn't exist.", 404)
		else
			res(HttpServer.File(A_WorkingDir . "\meta\mainIndex.html"))
	}

	static redirect(req, res, to := "https://icanhazip.com/") {
		this.logger(req)
		res["Location"] := to
		res(,301)
	}

	static page(req, res) {
		this.logger(req)
		queries := this.parseQueries(req)
		ahp := "<html>`n<title>Query Test</title>`n<body>`n<b>[var]</b>`n</body>`n</html>"
		form := '<form action="/calc" method="get"><input type="text" name="num1" value="' queries["num1"] '"> + <input type="text" name="num2" value="' queries["num2"] '"><input type="submit"></form>'
		serve := StrReplace(ahp, "[var]", "num1: " queries["num1"] " - num2: " queries["num2"] "<br><br>" form)
		res["Content-Type"] := 'text/html;charset=utf-8'
		res(serve)
	}

	static calc(req, res) {
		this.logger(req)
		queries := this.parseQueries(req)
		ahp := "<html>`n<title>Still a query test.</title>`n<body>`n<b>[var]</b>`n</body>`n</html>"
		answer := queries["num1"] + queries["num2"]
		serve := StrReplace(ahp, "[var]", queries["num1"] "+" queries["num2"] "=" answer)
		res["Content-Type"] := 'text/html;charset=utf-8' ; unnecessary ? 
		res(serve)
	}

	static solar(req, res) {
		static target := "http://raspi.local:5000"
		static URLOrigin := "/solar"
		this.logger(req)
		path := this.parsePath(req)
		whr := ComObject("WinHttp.WinHttpRequest.5.1")
		url := target . SubStr(path, StrLen(URLOrigin) + 1)
		OutputDebug("Got request path " path "`n")
		OutputDebug("sending to " url "`n")
		whr.Open("GET", url, false)
		for name, value in req.headers
			whr.SetRequestHeader(name, value)
		Loop(2) {
			try {
				if req.Body
					whr.Send(req.Body)
				else
					whr.Send()
				whr.WaitForResponse()
			} catch {
				Sleep(100)
				continue
			}
			break
		}
		for name, value in StrSplit(whr.GetAllResponseHeaders(), "`r`n") {
			if (name == "")
				continue
			parts := StrSplit(value, ":",,2)
			if (parts.Length() == 2)
				res.SetHeader(Trim(parts[1]), Trim(parts[2]))
		}
		respText := whr.ResponseText
		if (req.path == "/solar" || req.path == "/solar/") {
			respText := StrReplace(respText, 'src="/static', 'src="/solar/static')
			respText := StrReplace(respText, "fetch('/", "fetch('/solar/")
			res["Content-Type"] := 'text/html;charset=utf-8'
			res(respText)
		} else if InStr(req.path, ".json") {
			res["Content-Type"] := 'application/json'
			res(respText)
		}
		else if InStr(req.path, ".js") {
			res["Content-Type"] := 'application/javascript'
			res(respText)
		}
		else
			res(whr.ResponseBody)
	}

	static betterCounter(req, res) {
		this.logger(req)
		static origin := A_WorkingDir . "\webfiles\web"
		static URLorigin := "/bettercounter/"
		vpath := StrReplace(Substr(this.parsePath(req), StrLen(URLorigin)), "/", "\")
		if (vpath == "\" || vPath == "") {
			res(HttpServer.File(A_WorkingDir . "\webfiles\web\index.html"))
		} 
		else ; THIS IS NECESSARY AS FLUTTER REQUESTS MORE FILES LIKE FontManifest.json ETC THAT ARE SERVED BY THIS.
			CCServer.FileIndex.genericIndex(req, res, origin, vpath, "/webfiles/web")
	}

	static mediocreCounter(req, res) {
		static data := ""
		static URLorigin := "/counter/"
		static cfile := A_WorkingDir . "\countingData.json"
		
		vpath := Substr(this.parsePath(req), StrLen(URLorigin))
		if (data == "")
			data := jsongo.Parse(FileRead(cfile, "UTF-8"))
		if (vpath == "/" || vPath == "") {
			res(HttpServer.File(A_WorkingDir . "\meta\button.html"))
			this.logger(req)
		} else if (vpath == "/fetch") {
			res["Content-Type"] := "application/json; charset=utf-8"
			res(jsongo.Stringify(data))
		} else if (vpath == "/increment") {
			data["count"]++
			res(, 200)
		} else {
			res("Doesn't exist.")
		}
		FileOpen(cfile, "w", "UTF-8").Write(jsongo.Stringify(data))
	}

	static embedder(req, res) {
		msgbox("IMPLEMENT!!!")
	}


	class FileIndex {
		static t := CCServer

		static web(req, res) {
			static origin := A_WorkingDir . "\webfiles"
			static URLorigin := "/webfiles/"
			this.t.logger(req)
			vpath := StrReplace(SubStr(this.t.parsePath(req), StrLen(URLorigin)), "/", "\")
			this.genericIndex(req, res, origin, vpath, "/webfiles")
		}

		static music(req, res) {
			static origin := RegexReplace(A_MyDocuments, "\\[^\\]*$", "") . "\Music\Collections"
			static URLorigin := "/music/"
			this.t.logger(req)
			vpath := StrReplace(SubStr(this.t.parsePath(req), StrLen(URLorigin)), "/", "\")
			if (req.headers.Has("CF-Connecting-IP") && req.headers["CF-Connecting-IP"] != CCServer.publicIP)
				res("Not allowed to see.", 200)
			else {
				this.genericIndex(req, res, origin, vpath, "/music")
			}
		}

		static ahk(req, res) {
			static origin := A_Desktop "\programs\programming\ahk"
			static URLorigin := "/ahk/"
			this.t.logger(req)
			vpath := StrReplace(SubStr(this.t.parsePath(req), StrLen(URLorigin)), "/", "\") ; since path will ALWAYS start with /ahk/, we don't have to worry about anything else.
			this.genericIndex(req, res, origin, vpath, "/ahk", "ahk")
		}

		static genericIndex(req, res, origin, vpath := "\", title := "", ext := "*", mode := "DF") {
			normPath := normalizePath(origin . vpath)
		;	FileAppend, % "normpath: " normPath . "`n", * ; debugging purposes
			if (t := FileExist(normPath)) && InStr(normPath, origin) {
				if (InStr(t, "D")) {
					if (SubStr(vpath, -1) != "\") {
						res["Location"] := StrReplace(vpath, "\", "/") . "/"
						res(, 308)
						return
					}
					html := this.generateDirectoryListing(normPath, vpath, title, ext, mode)
					res(html)
				}
				else {
					SplitPath(normPath,,,&fExt)
					if (ext == "*" || fExt == ext) {
						res(HttpServer.File(normPath))
					;	res.Set ; make a title for the tab??
					}
					else
						res("File not available.")
				}
			}
			else
				res("File cannot be accessed.")
		}

		static generateDirectoryListing(folderPath, vpath := "\", title := "", ext := "*", fileMode := "DF") {
			htmlTemplate := FileRead(A_WorkingDir . "\meta\indexTemplate.html", "UTF-8")
			folderPath := (SubStr(folderPath, -1) != "\" ? folderPath . "\" : folderPath)
			fileIndex := getFolderAsArr(folderPath, "*", fileMode, 0)
			str := '<a href="../">../</a>`n'
			strEnd := ""
			for i, e in fileIndex {
				if InStr(e.attrib, 'D')
					str .= Format('<a href="{}/">{:-64}{}`n', e.name, e.name . '</a>', formatTimeDateTime(e.timeModified, ' '))
				else
					strEnd .= Format('<a href="{}">{:-64}{}  {:15} Bytes`n', e.name, e.name . '</a>',  formatTimeDateTime(e.timeModified, ' '), RegExReplace(e.size, "\G\d+?(?=(\d{3})+(?:\D|$))", "$0," ))
			}
			str := str . strEnd
			full := StrReplace(htmlTemplate, "[var1]", StrReplace(title . vpath, "\", "/"))
			full := StrReplace(full, "[var2]", str)
			return full
		}
	}

	static whoami(req, res) {
		logFile := A_WorkingDir . "\fullRequestLogV2.txt"
		str := Format("
		(
			-----------------------------------------------------
			REQUEST MADE AT {1}.{2} (System Time)
			-----------------------------------------------------
			Request Path: {3}
			Request Method: {4}
			Request Protocol: {5}
			Request Headers: {6}
			Request Query: {7}
		)", formatTimeISO8601(), Mod(A_TickCount,1000),
			req.CookedUrl.AbsPath,
			"GET?",
			"PROTOCOL?",
			objCollect(req.Headers, (b, e) => (b . "`n" e), (k, v) => ("`t" k ": " v),"",, true),
			req.CookedUrl.QueryStringLength > 0 ? req.CookedUrl.QueryString : ""
		)
		res["Content-Type"] := 'text/plain;charset=utf-8'
		res(str)
		FileAppend(str, logFile, "UTF-8")
	}

	static favicon(req, res) {
		res(HttpServer.File(A_WorkingDir "\meta\favicon.ico"))
	}

	static notFound(req, res) {
		this.logger(req)
		res("Page not found", 404)
	}


	static test(req, res) {
		; set response header
		res['from'] := 'ahk server'
		; send file as response
		; res(HttpServer.File(filepath))

		; send 404 not found
		; res(, 404)

		html :=
		(
			'<h1>hello world</h1>
			<h3>rawurl</h3>' req.RawUrl '
			<h3>query</h3>' (req.CookedUrl.QueryString || '') '
			<h3>address</h3>' req.RemoteAddress '
			<h3>verb</h3>' req.Verb '
			<h3>headers</h3>' jsongo.Stringify(req.Headers) '
			<h3>postdata</h3>' StrGet(req.body, 'cp0')
		)
		encoding := req.Headers.Get('Accept-Encoding', '')
		if InStr(encoding, e := 'zstd') || InStr(encoding, e := 'gzip') {
			; send utf-8 html with zstd/gzip compress
			StrPut(html, buf := Buffer(StrPut(html, 'utf-8') - 1), 'utf-8')
			res['Content-Type'] := 'text/html;charset=utf-8'
			res(compress.encode(buf, , res['Content-Encoding'] := e))
		} else
			; send utf-8 html
			res(html)
	}

	static logger(req) {
		static logFile := A_WorkingDir . "\logAllRequestsV2.txt"
		; print(ToStringNoBases(req),,,0)
		str := Format("
		( LTrim
			-----------------------------------------------------
			NEW REQUEST MADE AT {1}.{2} (System Time)
			Path: {3}
			IP: {4} (Country: {5})
			User Agent: {6}
			Queries: {7}"
		)", formatTimeISO8601(), 
			Mod(A_TickCount,1000),
			req.CookedUrl.AbsPath,
			req.headers.has("CF-Connecting-IP") ? req.headers["CF-Connecting-IP"] . (req.headers["CF-Connecting-IP"] == this.publicIP ? " (self)" : "") : "?",
			req.headers.has("CF-IPCountry") ? req.headers["CF-IPCountry"] : "?",
			req.headers.has("user-agent") ? req.headers["user-agent"] : "?",
			req.CookedUrl.QueryStringLength > 0 ? req.CookedUrl.QueryString : ""
		)
		str .= "`n"
		FileAppend(str, logFile, "UTF-8")
	}

	static parsePath(req) {
		if req.CookedUrl.QueryStringLength > 0
			return SubStr(req.CookedUrl.AbsPath, 1, -req.CookedUrl.QueryStringLength)
		return req.CookedUrl.AbsPath
	}

	static parseQueries(req) {
		if !req.CookedUrl.QueryStringLength 
			return Map()
		querystring := req.CookedUrl.QueryString
		if SubStr(querystring, 1, 1) == "?"
			querystring := SubStr(querystring, 2)
		queries := Map()
		for e in StrSplit(querystring, "&") {
			qr := StrSplit(e, "=")
			queries[qr[1]] := qr[2]
		}
		return queries
	}
}

; if !A_IsAdmin {
;	Run('*RunAs ' Format('"{}" /restart "{}"', A_AhkPath, A_ScriptFullPath))
;	ExitApp()
; }

testRequest() {
	; headers := Map("Sec-Fetch-Site", "same-origin", "Sec-Fetch-Mode", "navigate", "Sec-Fetch-Dest", "document", "Sec-Fetch-Dest2", "document")
	; html := sendRequest(CCServer.serverURL, "POST",,,, headers)
	; html := sendRequest(CCServer.serverURL "/whoami", "GET")
	; MsgBoxAsGui(html)
	; whr := ComObject('WinHttp.WinHttpRequest.5.1')
	; whr.Open('POST', 'http://localhost:3141/aa.htm?hsy=6&jss=6', 1)
	; whr.SetRequestHeader('abcd', 'hello')
	; whr.Send('abcdefghi')
	; whr.WaitForResponse()
	; MsgBoxAsGui(whr.GetAllResponseHeaders() '`n' whr.ResponseText)
}
