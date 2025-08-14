#Requires AutoHotkey v2
#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"

; todo: split video chapters into separate files option
; todo: attempt to parse artist/title from description if title/uploader doesn't seem correct
; todo: allow for specifying path/url to supply alternate thumbnail 
if (A_LineFile == A_ScriptFullPath) { ; NECESSARY TO WORK WHEN INCLUDING
	SetWorkingDir(A_ScriptDir "\..\script_files\SongDownloader")
	SongDownloader.download(A_Clipboard)
	; usage options
	; SongDownloader.downloadSong("https://www.youtube.com/watch?v=MzsBwcXkghQ")
	; SongDownloader.downloadSong("Never Gonna Give You Up")
	; playlistdata := SongDownloader.getMetadataJson("https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=WL&index=3&pp=gAQBiAQB", false, true)
	; usage 
	; SongDownloader.settings.browserCookies := "firefox"
	; SongDownloader.settings.useCookies := true
	; jsonStr := SongDownloader.getMetadataJson("https://www.youtube.com/playlist?list=WL")
	; SongDownloader.downloadFromJson(jsonStr)
}

class SongDownloader {

	static __New() {
		this.settings := {
			debug: false,
			simulate: false,
			useAliases: true,
			useVisibleCMD: false,
			useCookies: true,
			browserCookies: "firefox",
			currentTodo: 71,
			outputBaseFolder: normalizePath(A_Desktop  "\..\Music\Collections"),
			outputSubFolder: "",
			logMetadata: true,
			logFolder: normalizePath(A_Desktop "\..\Music\ConvertMusic\ytdl\Logs"),
			ffmpegPath: normalizePath(A_Desktop "\programs\other\ProgramUtilities\ffmpeg\bin\ffmpeg.exe"),
			ffprobePath: normalizePath(A_Desktop "\programs\other\ProgramUtilities\ffmpeg\bin\ffprobe.exe"),
			ytdlPath: normalizePath(A_Desktop "\..\Music\ConvertMusic\ytdl\yt-dlp.exe"),
			metadataFields: ["title", "artist", "album", "genre"]
		}
		this.settings.outputSubFolder := Format("p{:03}", this.settings.currentTodo)
		this.data := {
			coords: {x: 750, y: 425},
			currentOutputSubFolder: this.settings.outputSubFolder,
			lastSongMetadata: {}
		}
	}

	static download(str) {
		str := Trim(str, " `t`r`n`"`'")
		if SubStr(str,1,1) == "{" || SubStr(str,1,1) == "[" {
			try {
				jsongo.parse(str) ; this is just a test to check if its valid json.
				if (A_LineFile == A_ScriptFullPath)
					this.downloadFromJson(str)
				else
					Run(A_LineFile)
			} catch { ; something wack is happening
				MsgBoxAsGui("Invalid JSON/Download: " str,,,,,,,,,,,1000)
			}
		} else if FileExist(str) || (RegExMatch(str, '^(?:filelist:)?(")?(\w:\\.*?)\1?$', &o) && FileExist(o[2])) {
			this.editMetadataWithGui(IsSet(o) ? o[2] : str)
		} else if (strCountStr(str, "https") > 1) { ; assume its multiple songs, so retrieve metadata
			if (A_LineFile == A_ScriptFullPath) {
				r := this.getMetadataJson(str)
				MsgBoxAsGui(r, "Metadata",,0,,,,1,,"i",,1000)
			} else
				Run(A_LineFile)
		} else {
			return this.downloadSongWithGui(str)
		}
	}

	static downloadSongWithGui(songLink) {
		ToolTip("Loading Metadata...")
		rawDataString := this.getMetaDataStr(songLink, false, false)
		metaData := this.parseMetadata(rawDataString, true)
		ToolTip()
		if !metaData || !objGetValueCount(metadata)
			return 0
		this.songDLGui(metaData)
		return 1
	}

	static editMetadataWithGui(filePath) {
		metadata := this.getMetadataFromFile(filePath)
		this.editMetadataGui(metadata)
	}

	static getMetadataFromFile(filePath) {
		cmd := this.cmdStringBuilder(this.settings.ffprobePath, this.PROFILE_GETMETADATAFROMFILE,, filePath)
		if this.settings.debug
			print(cmd)
		jsonStr := cmdRet(cmd,, "UTF-8")
		metadata := MapToObj(jsongo.parse(jsonStr)["format"]["tags"])
		metadata.filePath := filePath
		for tag in this.settings.metadataFields
			if !metadata.HasOwnProp(tag)
				metadata.%tag% := ""
		return metadata
	}

	static downloadFromJson(jsonAsStr, outputSubFolder := this.settings.outputSubFolder, embedThumbnail := true) {
		data := MapToObj(jsongo.Parse(jsonAsStr))
		if !(data is Array)
			data := [data]
		finisher := this.onFinish.bind(this, data.length, this.settings.outputSubFolder, 1, 0)
		for i, dataPoint in data {
			profile := this.PROFILE_MUSIC[this.PROFILE_PARSE_METADATA[dataPoint], this.constructOutputPatternString(dataPoint), outputSubFolder, this.settings.useCookies, true, embedThumbnail]
			this.launchYTDL(profile, dataPoint.link, this.settings.useVisibleCMD, finisher)
		}
	}
	
	static getMetadataJson(songLinks, allData := false, withPlaylist := false, printIntermediateSteps := false) {
		rawDataString := this.getMetaDataStr(songLinks, printIntermediateSteps, withPlaylist)
		metadata := this.parseMetadata(rawDataString, allData)
		return objToString(metadata,false,false,true,true)
	}

	static getMetaDataStr(songLinks, printIntermediateSteps := false, withPlaylist := false) {
		if !(songLinks is Array)
			songLinks := StrSplitUTF8(Trim(songLinks, "`n`r"), "`n", "`r")
		songLinks := objDoForEach(songLinks, (e => this.constructLink(e)))
		command := this.cmdStringBuilder(this.settings.ytdlPath, this.PROFILE_GETMETADATA[printIntermediateSteps, withPlaylist, true],,songLinks*)
		fn := (sOutPut) => (RegExMatch(SubStr(sOutPut, 1, 20), "^\[[[:alnum:]]+\]") ? Tooltip(SubStr(sOutPut, 1, 40)) : 0)
		fullOutputStr := Trim(cmdRet(command, printIntermediateSteps ? fn : unset), " `t`r`n")
		if (this.settings.debug) {
			if (!InStr(FileExist(A_WorkingDir "\SongDownloader"), "D"))
				DirCreate(A_WorkingDir "\SongDownloader")
			FileAppend(fullOutputStr, A_WorkingDir "\SongDownloader\retLog_" FormatTime(A_Now, "yyyy-MM-dd_HH.mm.ss") ".txt", "UTF-8")
		}
		return fullOutputStr
	}

	; normalization should be in the following form: 
	; Title is always of the form "Title (CoverArtist Cover|RemixArtist Remix|Full Album)"
	; Artist is always of the form "Artist [x|&|,] Artist2 ft Feature"
	static parseMetadata(rawData, keepJsonData := false) {
		rawData := RTrim(rawData, " `t`n`r")
		lines := strCountStr(rawData, "`n")
		metaData := []
		receivedBadInfo := []
		Loop Parse rawData, "`n", "`r" {
			jsonStr := A_LoopField
			try	videoData := jsongo.parse(jsonStr)
			catch {
				isError := InStr(jsonStr, "ERROR:") ? true : false
				if isError { ; if its a warning, metadata should still be parsed next iteration
					lnk := RegExMatch(jsonStr, "\[youtube\]\s+([A-Za-z0-9_-]{11}):", &o) ? o[1] : ""
					metaData.push({ link: this.constructLink(lnk), title: "", artist: "", album:"", genre:"",description:"",error:1, shortJson: jsonStr})
				}
				receivedBadInfo.push(jsonStr)
				continue
			}
			title := videoData.Has("track") ? videoData["track"] : videoData["title"]
			album := videoData.Has("album") ? videoData["album"] : ""
			genre := ""
			if (InStr(title, "Nightcore")) {
				if RegExMatch(title, "i)Nightcore\s*(?:-|–|—)\s*")
					title := RegExReplace(title, "i)Nightcore\s*(?:-|–|—)")
				else
					title := RegExReplace(title, "\(\s*Nightcore\s*\)")
				genre := "Nightcore"
				album := "Nightcore"
			}
			if RegExMatch(title, "i)(.)\s*\b(?:Official|Lyric)\s.*(?:Video|Audio)", &char) { ; clean (Official Lyric Video) and similar from title.
				open := char[1]
				closed := unicodeData.Wrapper.getBidiPairedBracket(open)
				if open != closed
					title := RegExReplace(title, Format("i){}\s*(?:Official|Lyric)\s+((Music|Lyric|HD)\s+)?(Video|Audio)\s*{}", '\' open, '\' closed))
			}
			artist := videoData.Has("artists") ? Trim(objToString(videoData["artists"],1,0), " []") : videoData.Has("creator") ? artist := videoData["creator"] : ""
			if RegexMatch(title, "^(.*?)(?:-|–|—)\s+(.*)$", &m) {
				if artist == ""
					artist := m[1]
				title := m[2]
			}
			if artist == ""
				artist := videoData["uploader"]
			if RegExMatch(title, "i)^(.*?)(\S)\s*\b(?:feat|ft)\b\.?(.*)", &match) {
				open := match[2]
				closed := unicodeData.Wrapper.getBidiPairedBracket(match[2])
				if (open != closed && RegExMatch(title, Format("i){}\s*(?:feat|ft)\.?(.*?){}(.*)", '\' open, '\' closed), &match2)) { ; eg Artist - Title (feat. Thing) [some other stuff]
					artist := Trim(artist) " ft " Trim(match2[1])
					title := Trim(match[1]) . " " . Trim(match2[2])
				} else { ; of the form Artist - Title feat. Singer (and thus there isn't a bracket) (or they forgot to close the bracket)
					artist := Trim(artist) " ft " Trim(match[3])
					title := match[1] . match[2]
				} 
			}
			if RegExMatch(artist, "(.*)(\S)\s*\b(?:feat|ft)\b\.?(.*)", &match) {
				open := match[2]
				closed := unicodeData.Wrapper.getBidiPairedBracket(match[2])
				if (open != closed && RegExMatch(title, Format("(.*){}\s*(?:feat|ft)\.?(.*?){}(.*)", open, closed), &match2)) ; eg Artist (feat. Thing) [some other stuff]
					artist := Trim(match2[1]) " ft " Trim(match2[2]) . " " Trim(match2[3])
				else ; of the form Artist - Title feat. Singer (and thus there isn't a bracket) (or they forgot to close the bracket)
					artist := Trim(match[1] . match[2]) " ft " Trim(match[3])
			}
			thumbnails := videoData["thumbnails"]
			objRemoveValues(videoData, ["formats", "requested_formats", "thumbnails", "subtitles"],,(i,e,v) => (i=v), "MANUALLY REMOVED")
			metaData.push({
				link: this.constructLink(videoData["id"]),
				title: Trim(title),
				artist: Trim(artist),
				album: Trim(album),
				genre: Trim(genre),
				description: videoData["description"],
				shortJson: keepJsonData ? videoData : unset,
				thumbnails: MapToObj(thumbnails)
			})
		}
		if receivedBadInfo.Length > 0 {
			str := objCollect(receivedBadInfo, (b, v) => b . "`n" v)
			MsgBoxAsGui("Received issues while parsing Metadata. Received`n`n" str,,,,,,,1,,,,2000)
		}
		if (metaData.Length == 1)
			metaData := metaData[1]
		return metaData
	}

	static songDLGui(data, destination?, editableLink := false) {
		g := Gui("+Border +OwnDialogs", "Download Song")
		g.OnEvent("Close", (*) => g.Destroy())
		if data.HasOwnProp("error") {
			errEdit := g.AddEdit("w250 R10 ReadOnly", data.shortJson)
			errEdit.SetFont("cRed Bold")
		}
		g.AddText("Section 0x200 R1.45", "Links | Current Folder: " )
		folder := this.settings.outputSubFolder
		if IsSet(destination) {
			SplitPath(destination,, &dir)
			SplitPath(dir, &fl)
			folder := fl
		}
		g.AddEdit("xs+110 ys R1 w30 vOutputFolder", folder).OnEvent("Change", guiHandler)
		g.AddButton("xs+151 ys-1 w100", "Open Link").OnEvent("Click", (*) => Run(data.link))
		g.AddEdit("xs w250 R1 vLink " (editableLink ? "" : "ReadOnly"), data.link).OnEvent("Change", guiHandler)
		g.AddText("0x200 R1.45", "Title")
		g.AddButton("xs+151 yp-1 w100", "Show Thumbnail").OnEvent("Click", (*) => this.thumbnailPreviewer(data))
		g.AddEdit("xs w250 vTitle", data.title).OnEvent("Change", guiHandler)
		g.AddText("", "Artist")
		metadataVar := ObjOwnPropCount(this.data.lastSongMetadata) > 0 ? this.data.lastSongMetadata : data
		g.AddEdit("xs w250 vArtist", metadataVar.artist).OnEvent("Change", guiHandler)
		g.AddText("0x200 R1.45", "Album")
		g.AddButton("xs+151 yp-1 w100", "Show Description").OnEvent("Click", (*) => MsgBoxAsGui(data.description, "Video Description",,0,,,g.hwnd,1,,,,,1200))
		g.AddEdit("xs w250 vAlbum", metadataVar.album).OnEvent("Change", guiHandler)
		g.AddText("0x200 R1.45", "Genre")
		if data.HasOwnProp("shortJson")
			g.AddButton("xs+151 yp-1 w100", "Show Full Json").OnEvent("Click", (*) => MsgBoxAsGui(objToString(data.shortJson,0,0,1), "JSON",,0,,,g.hwnd,1,,,,800, 1200))
		g.AddEdit("xs w250 vGenre", metadataVar.genre).OnEvent("Change", guiHandler)
		g["Title"].Focus()
		g.AddCheckbox("xs vEmbedThumbnail Checked" true, "Embed Thumbnail").OnEvent("Click", guiHandler)
		g.AddCheckbox("xs+125 yp vUseVisibleCMD Checked" this.settings.useVisibleCMD, "Visble CMD")
		g.AddCheckbox("xs vUseCookies Checked" this.settings.useCookies, "Use Cookies (" this.settings.browserCookies ")").OnEvent("Click", guiHandler)
		g.AddCheckbox("xs+125 yp vSkipNonMusic Checked" true, "Skip Non-Music Parts").OnEvent("Click", guiHandler)
		g.AddCheckbox("xs vLogMetadata Checked" this.settings.logMetadata, "Log Metadata")
		g.AddCheckbox("xs+125 yp vReuseData Checked" false, "Re-Use Data")
		g.AddText("xs", "Current Command Line")
		profile := this.PROFILE_MUSIC[
			this.PROFILE_PARSE_METADATA[data],
			this.constructOutputPatternString(data),
			folder,
			this.settings.useCookies,
			true,
			true
		]
		g.AddEdit("vCMD w250 R1 Readonly", this.cmdStringBuilder(this.settings.ytdlPath, profile,, data.link))
		g.AddButton("xs-1 h30 w251 Default", "Launch yt-dlp").OnEvent("Click", finishGui)
		g.Show(Format("x{1}y{2} Autosize", this.data.coords.x, this.data.coords.y))

		; USE SETTINGS GUI FOR AFFECTING SETTINGS.
		; this creates the string in vCMD and edits {data} (only matters for Link).
		; ACTUAL DATA GATHERING OCCURS IN finishGui THROUGH SUBMIT
		guiHandler(guiCtrlObj, info?) {
			name := guiCtrlObj.Name
			val := Trim(guiCtrlObj.Value)
			switch name {
				case "Title", "Artist", "Album", "Genre":
					rem := [{ option: this.ytdloptions.output, param: this.constructOutputPatternString(data)}]
					data.%name% := val ; THIS LINE BEING IN THIS ORDER IS RELEVANT
					add := [{ option: this.ytdloptions.output, param: this.constructOutputPatternString(data)}]
					profile := this.addRemoveProfile(profile, rem, add, true, true)
				case "Link":
					data.link := val
				case "OutputFolder":
					rem := [{ option: this.ytdloptions.paths, param: this.settings.outputBaseFolder "\" subOutputFolder }]
					add := [{ option: this.ytdloptions.paths, param: this.settings.outputBaseFolder "\" val }]
					subOutputFolder := val
					profile := this.addRemoveProfile(profile, rem, add, true, true)
				case "EmbedThumbnail":
					toggleProfile := this.PROFILE_EMBED_THUMBNAIL
					profile := this.toggleProfile(profile, toggleProfile)
				case "UseCookies": ; might cause issues if this setting changes while in GUI but ehhh
					toggleProfile := [{option: this.ytdloptions.cookies_from_browser, param: this.settings.browserCookies}]
					profile := this.toggleProfile(profile, toggleProfile)
				case "SkipNonMusic":
					toggleProfile := [{option: this.ytdloptions.sponsorblock_remove, param: "music_offtopic"}]
					profile := this.toggleProfile(profile, toggleProfile)
			}
			g["CMD"].Value := this.cmdStringBuilder(this.settings.ytdlPath, profile,, data.link)
		}

		finishGui(ctrlObj, info?) {
			gData := ctrlObj.gui.submit(true)
			gData := objDoForEach(gData, v => Trim(v))
			ctrlObj.gui.destroy()
			songData := {
				title: gData.Title, artist: gData.Artist,
				album: gData.Album, genre: gData.Genre,
				link: gData.Link, description: Trim(data.Description, " `t`r`n")
			}
			profile := this.PROFILE_MUSIC[
				this.PROFILE_PARSE_METADATA[songData],
				this.constructOutputPatternString(songData),
				gData.OutputFolder,
				gData.UseCookies,
				gData.SkipNonMusic,
				gData.EmbedThumbnail
			]
			if (gData.ReuseData)
				this.data.lastSongMetadata := songData
			else
				this.data.lastSongMetadata := {}
			if gData.LogMetadata {
				metadatapath := Format(this.settings.logFolder "\" this.TEMPLATES.METADATAFILE, gData.OutputFolder)
				if FileExist(metadatapath) {
					try {
						curData := jsongo.parse(FileRead(metadatapath, "UTF-8"))
						try curData.push(songData)
						catch
							curData := [curData, songData]
					}
				}
				f := FileOpen(metadatapath, "w", "UTF-8")
				f.Write(objToString(curData ?? [songData],false,false,true))
				f.Close()
			}
			this.launchYTDL(profile, songData.link, gData.UseVisibleCMD, this.onFinish.bind(this, 1, gData.OutputFolder, 0, 0))
		}
	}

	static editMetadataGui(data) {
		g := Gui("+Border +OwnDialogs", "Edit Metadata")
		g.OnEvent("Close", (*) => g.Destroy())
		SplitPath(data.filePath, &name, &dir, &ext, &nameNoExt)
		SplitPath(dir, &dirname)
		g.AddText("Section 0x200 R1.45", "File | Current Folder: " )
		g.AddEdit("xs+110 ys R1 w30 vOutputFolder", dirname)
		if (data.HasOwnProp("purl"))
			g.AddButton("xs+151 ys-1 w100", "Open Link").OnEvent("Click", (*) => Run(data.purl))
		g.AddEdit("xs w250 R1 ReadOnly vFile", name)
		g.AddText("0x200 R1.45", "Title")
		g.AddEdit("xs w250 vTitle", data.title).OnEvent("Change", guiHandler)
		g.AddText("0x200 R1.45", "Artist")
		g.AddButton("xs+151 yp-1 w100 vSwapButton", "Swap Title - Artist").OnEvent("Click", guiHandler)
		g.AddEdit("xs w250 vArtist", data.artist).OnEvent("Change", guiHandler)
		g.AddText("0x200 R1.45", "Album")
		if data.HasOwnProp("description")
			g.AddButton("xs+151 yp-1 w100", "Show Description").OnEvent("Click", (*) => MsgBoxAsGui(data.description, "Video Description",,0,,,g.hwnd,1,,,,,1200))
		g.AddEdit("xs w250 vAlbum", data.album).OnEvent("Change", guiHandler)
		g.AddText("", "Genre")
		g.AddEdit("xs w250 vGenre", data.genre).OnEvent("Change", guiHandler)
		g.AddButton("xs-1 h30 w251 vReDownload", "Re-Download").OnEvent("Click", finishGui)
		g.AddButton("xs1 h30 w251 vEditMetadata Default", "Edit Metadata").OnEvent("Click", finishGui)
		g.Show(Format("x{1}y{2} Autosize", this.data.coords.x, this.data.coords.y))

		guiHandler(guiCtrlObj, info?) {
			switch guiCtrlObj.Name {
				case "SwapButton":
					temp := g["Artist"].Value
					g["Artist"].Value := g["Title"].Value
					g["Title"].Value := temp
					SplitPath(g["File"].Value,,,&ext)
					g["File"].Value := g["Artist"].Value " - " g["Title"].Value "." ext
				case "Title", "Artist":
					SplitPath(g["File"].Value,,,&ext)
					g["File"].Value := g["Artist"].Value " - " g["Title"].Value "." ext
			}
		}

		finishGui(ctrlObj, info?) {
			gData := ctrlObj.gui.submit()
			gData := objDoForEach(gData, v => Trim(v))
			ctrlName := ctrlObj.Name
			ctrlObj.gui.destroy()
			switch ctrlName {
				case "ReDownload":
					songData := {
						title: gData.Title, artist: gData.Artist,
						album: gData.Album, genre: gData.Genre,
						link: data.HasOwnProp("purl") ? data.purl : "", description: data.HasOwnProp("description") ? data.Description : ""
					}
					this.songDLGui(songData, data.filePath, true)
				case "EditMetadata":
					this.editMetadata(data.filePath, gData)
			}
		}
	}

	static editMetadata(filePath, metadata) {
		SplitPath(filePath, &oldName, &dir, &ext, &oldNameNoExt)
		SplitPath(dir, &dirname)
		str := ""
		flagSameFileName := (metadata.file = oldName) ; with ext. Ignore capitalization since its a filename
		finalFilePath := dir "\" metadata.file
		targetFilePath := flagSameFileName ? dir "\" oldNameNoExt "_." ext : finalFilePath
		cmd := this.cmdStringBuilder(this.settings.ffmpegPath, this.PROFILE_EDITMETADATA[metadata, filePath],, targetFilePath)
		if this.settings.debug
			print(cmd)
		cmdRetAsync(cmd, , "UTF-8",,finishEdit, 5000)
	
		finishEdit(output, success) {
			Sleep(300)
			if success == -1
				MsgBoxAsGui("ERROR:`n" output,,,,,,,1)
			else if (FileExist(targetFilePath)) {
				if (flagSameFileName)
					FileMove(targetFilePath, finalFilePath, 1)
				else
					FileDelete(filePath)
			}
			MsgBoxAsGui("Done")
		}
	}

	static thumbnailPreviewer(metadata) {
		static HTML_TEMPLATE := '<!DOCTYPE html><html><head><style>html,body {margin: 0;padding: 0;}.overlay {position: absolute;top: 0;height: {3}px;background-color: #000;filter: alpha(opacity=85);}</style></head><body><div style="width:{2}px;height:{3}px;"><img src="{1}" alt="Picture" style="width:{2}px;height:{3}px;"><div class="overlay" style="left:0;width:{4}px;"></div><div class="overlay" style="right:0;width:{4}px;"></div></div></body></html>'
		
		if !metadata.HasOwnProp("thumbnails") {
			if (!metadata.link)
				return MsgBoxAsGui("No Link set to retrieve thumbnail from and retrieving it from metadata is not yet implemented.")
			dataStr := this.getMetaDataStr(metadata.link)
			metadata.thumbnails := this.parseMetadata(dataStr).thumbnails
		}
		
		for th in arrayInReverse(metadata.thumbnails) {
			if RegExMatch(th.url, "webp$") ; activex doesn't support webps
				continue
			thumb := th
			break
		}
		height := clamp(thumb.height, 1, 500)
		width := Round(height/thumb.height * thumb.width)
		squareOffset := (width - height) // 2
		g := Gui("+Border +OwnDialogs +E" WinUtilities.EXSTYLES.WS_EX_COMPOSITED, "Thumbnail Preview")
		g.OnEvent("Close", (*) => g.Destroy())
		sect := g.AddText("Section 0x200 R1.45", "Link | Thumbnail ID: " )
		sect.GetPos(&sectX)
		g.AddEdit("xs+110 ys R1 w30 vThumbID", thumb.id)
		g.AddText("xs+150 0x200 R1.45 ys vThumbInfo", "Dimensions: " thumb.width " x " thumb.height)
		g.AddButton(Format("xs+{} ys-1 w130", width-129), "View Thumbnails Json").OnEvent("Click", (*) => MsgBoxAsGui(objToString(metadata.thumbnails,0,0,1), "JSON",,0,,,g.hwnd,1,,,,800, 1200))
		g.AddEdit(Format("xs w{} R1 vFile", width), thumb.url)
		g.AddText("vCoverLeft Hidden Section xs w" squareOffset " h" height)
		g.AddText("vCoverRight Hidden x" sectX + width - squareOffset " yp w" squareOffset " h" height)
		WBObj := g.AddActiveX(Format("xs ys w{} h{} vThumb", width, height), "Shell.Explorer2").Value ; Explorer2 because persistently vanishing scrollbars.
		WBObj.Silent := true
		WBObj.Navigate("about:" Format(HTML_TEMPLATE, thumb.url, width, height, squareOffset))
		g.Show(Format("x{1}y{2} Autosize", this.data.coords.x + 125 - width//2, this.data.coords.y + 200 - 100 - height//2))
	}

	static launchffmpeg() {

	}

	static launchYTDL(profile, link, useVisibleCMD, finisherFunc?) {
		; profile := this.toggleProfile(profile, this.PROFILE_SPLIT_CHAPTERS)
		fullCommand := this.cmdStringBuilder(this.settings.ytdlPath, profile,, link)
		OutputDebug(fullCommand "`n")
		if (useVisibleCMD) {
			modifier := this.settings.debug ? "/k" : "/c"
			Run("wt cmd " modifier " chcp 65001 && title SongDownloader && echo " fullCommand " && " fullCommand)
		} else {
			fn := finisherFunc ?? this.onFinish.bind(this, -1, this.settings.outputSubFolder, 0, 0)
			fn := fn.bind(link)
			success := cmdRetAsync(fullCommand, unset, "UTF-8", 500, fn)
		}
		return success ?? 1
	}

	static onFinish(amount, logID, withTooltips, finalCallback, link, output, status) {
		static count := 0
		count++
		logger(output)
		if (count == amount) {
			ToolTip()
			MsgBoxAsGui("Finished All Downloads", "Finished",,,,doneHandler,,,["OK", "Open Folder", "Open Log", "Open Both"])
			if finalCallback
				finalCallback(output)
			count := 0
			return amount
		} else if withTooltips
			ToolTip(Format("[~{}/{}] {}", count, amount, Trim(SubStr(output, InStr(output, "|")+1))), -1920, 0)
		return count

		doneHandler(ret) {
			flagFolder := (ret == "Open Folder" || ret == "Open Both")
			flagLog := (ret == "Open Log" || ret == "Open Both")
			if flagFolder {
				if (WinExist(logID " ahk_class CabinetWClass"))
					WinActivate(logID " ahk_class CabinetWClass")
				else
					Run('explorer.exe "' this.settings.outputBaseFolder "\" logID '"')
			}
			if flagLog
				tryEditTextFile("notepad", Format(this.settings.logFolder "\" this.TEMPLATES.LOGFILE, logID))
		}

		logger(output) {
			path := Format(this.settings.logFolder "\" this.TEMPLATES.LOGFILE, logID)
			fullStr := Format("[{}] {}`n{}`n", FormatTime(A_Now, "dd.MM.yyyy, ~HH:mm:ss"), Trim(output, " `t`r`n"), strMultiply("=", 22))
			FileAppend(fullStr, path, "UTF-8")
		}
	}

	static verifyDownloads(jsonAsStr, folderToCheck := this.settings.outputSubFolder) {
		data := MapToObj(jsongo.Parse(jsonAsStr))
		folder := InStr(folderToCheck, ":") ? folderToCheck : (this.settings.outputBaseFolder . "\" . folderToCheck)
		ext := "mp3"
		expectedFiles := Map()
		local log := ""
		for i, dataPoint in data {
			fName := this.constructOutputPatternString(dataPoint)
			fName := SubStr(fName, 1, -1 * (StrLen(this.TEMPLATES.EXT) + 1))
			if (FileExist(folder "\" fName "." ext)) {
				expectedFiles[fName] := 1
				log .= "✅ File " fName "." ext " found.`n"
			} else {
				expectedFiles[fName] := 0
				log .= "❌ File " fName "." ext " not found.`n"
			}
		}
		loop files folder "\*", '' {
			SplitPath(A_LoopFileName,,, &ext, &name)
			if expectedFiles.Has(name) {
				if expectedFiles[name]
					continue
				else
					log .= "❓ File " . name "." ext " found. (Not mp3?)`n"
			} else {
				log .= "❔ File " . name "." ext " found. (Unexpected)`n"
			}
		}
		return log
	}

	static findMetadataDupes() {
		data := []
		loop files this.settings.logFolder "\*", '' {
			if (A_LoopFileExt == "json") && InStr(A_LoopFileName, "_metadata") {
				try mdata := jsongo.Parse(FileRead(A_LoopFileFullPath, "UTF-8"))
				mdata := mdata ?? []
				mdata := objDoForEach(mdata, (val => (val.folder := A_LoopFileName, val)))
				data.push((mdata ?? [])*)
			}
		}
		indices := objGetDuplicates(data, (a => ((a.has("title") ? a["title"] : "") A_Space (a.has("artist") ? a["artist"] : ""))), false, true)
		dupls := []
		for e in indices {
			for i in e
				dupls.push(data[i])
		}
		return dupls
	}

	static cmdStringBuilder(path, profile, useAliases := false, additionalParams*) {
		str := '"' path '"' A_Space
		for set in profile
			str .= (useAliases && set.option.has("alias") ? set.option.alias : set.option.name) . A_Space . (set.option.param ?  '"' StrReplace(set.param, '"', '\"') '"' A_Space : '')
		for param in additionalParams
			str .= '"' param '"' A_Space
		return Trim(str)
	}

	static constructLink(input) {
		input := RegExReplace(input, "music\.youtube", "youtube")
		if (RegExMatch(input, "youtube\.com\/watch\?v=([A-Za-z0-9_-]{11})", &o))
			input := "https://youtube.com/watch?v=" . o[1]
		else if (RegExMatch(input, "^[A-Za-z0-9_-]{11}$"))
			input := "https://youtube.com/watch?v=" . input
		return Trim(input)
	}

	static constructOutputPatternString(songData) {
		static charMap := Map("\", "-", "/", "⧸", ":", "", "*", "＊", "?", ".", '"', "'", "<", "(", ">", ")", "|", "-")
		if songData.HasOwnProp("filename")
			filename := songData.filename "." this.TEMPLATES.EXT
		else {
			title := songData.title ? songData.title : this.TEMPLATES.TITLE
			artist := songData.artist ? songData.artist : this.TEMPLATES.ARTIST
			filename := artist " - " title "." this.TEMPLATES.EXT
		}
		for i, e in charMap
			filename := StrReplace(filename, i, e)
		filename := RegExReplace(filename, "\s+", " ") ; normalize spaces
		return filename
	}

	static toggleProfile(profile, profileToToggle) {
		nProfile := profile.clone()
		paramLambda := (k, v, v2) => (objCompare(v, v2))
		for o in profileToToggle {
			if !objRemoveValue(nProfile, o,, paramLambda)
				nProfile.push(o)
		}
		return nProfile
	}

	static mergeProfile(profile, profileToMerge) {
		nProfile := profile.clone()
		lambda := (k, v, v2) => (objCompare(v.option, v2.option))
		for i, e in (profileToMerge) {
			if !(e.option.param && e.HasOwnProp("param"))
				throw(ValueError("addRemoveProfile received malformed merge profile"))
			else if (index := objContainsValue(nProfile, e, lambda))
				nProfile[index].param := e.param
		}
		return nProfile
	}

	static addRemoveProfile(profile, profileToRemove := [], profileToAdd := [], paramCompare := true, inplace := false) {
		nProfile := profile.clone() ; deepclone unnecessary.
		optCompare := (k, v, v2) => (objCompare(v.option, v2.option))
		allCompare := (k, v, v2) => (objCompare(v, v2))
		lambda := paramCompare ? allCompare : optCompare
		if (inplace) {
			if (profileToRemove.Length != profileToAdd.Length)
				throw(ValueError("Given Arrays have different Lengths"))
			for e, f in objZip(profileToRemove, profileToAdd)
				objRemoveValue(nProfile, e,, lambda, f)
		} else {
			objRemoveValues(nProfile, profileToRemove,, lambda)
			for i, e in (profileToAdd)
				nProfile.push(e)
		}
		return nProfile
	}

	static PROFILE_GETMETADATA[withIntermediateSteps, withPlaylist, skipJunk] {
		get {
			profile := [
				{ option: this.ytdloptions.ignore_config }, 
				{ option: this.ytdloptions.default_search, param: "ytsearch" }, 
				{ option: this.ytdloptions.skip_download }, 
				{ option: this.ytdloptions.write_info_json }, 
				{ option: this.ytdloptions.dump_json }
			]
			if (withIntermediateSteps)
				profile.push({ option: this.ytdloptions.verbose })
			if !(withPlaylist)
				profile.push({ option: this.ytdloptions.no_playlist })
			if this.settings.useCookies
				profile.push({ option: this.ytdloptions.cookies_from_browser, param: this.settings.browserCookies})
			if skipJunk { ; don't remove "thumbnails", "subtitles", we might need those for parsing
				for field in ["automatic_captions", "heatmap"]
					profile.push({option: this.ytdloptions.parse_metadata, param: Format(":(?P<{}>)", field)})
			}
			return profile
		}
	}

	static PROFILE_EDITMETADATA[metadata, filePath] {
		get {
			profile := [
				{ option: this.ffmpegoptions.i, param: filePath},
				{ option: this.ffmpegoptions.hide_banner },
				{ option: this.ffmpegoptions.codec, param: "copy"}
			]
			for tag in this.settings.metadataFields
				profile.push( { option: this.ffmpegoptions.metadata, param: tag "=" metadata.%tag%})
			return profile
		}
	}

	static PROFILE_GETMETADATAFROMFILE => [
		{ option: this.ffprobeoptions.v, param: "error"},
		{ option: this.ffprobeoptions.output_format, param: "json"},
		{ option: this.ffprobeoptions.show_entries, param: "format_tags"},
	]

	static PROFILE_MUSIC[PROFILE_PARSE_METADATA, outputTemplate, outputSubFolder, withCookies, skipNonMusic, embedThumbnail] {
		get {
			profile := [
				{ option: this.ytdloptions.ignore_config },
				{ option: this.ytdloptions.retries, param: 1 },
				{ option: this.ytdloptions.limit_rate, param: "5M" },
				{ option: this.ytdloptions.no_overwrites },
				{ option: this.ytdloptions.no_playlist },
				{ option: this.ytdloptions.no_vid },
				{ option: this.ytdloptions.no_warning },
				{ option: this.ytdloptions.print, param: "after_move:%(filepath)s | %(original_url)s" },
				{ option: this.ytdloptions.output, param: outputTemplate},
				{ option: this.ytdloptions.paths, param: "temp:" A_AppData "\yt-dlp\temp"},
				{ option: this.ytdloptions.paths, param: this.settings.outputBaseFolder "\" outputSubFolder},
				{ option: this.ytdloptions.format, param: "bestaudio/best" },
				{ option: this.ytdloptions.ffmpeg_location, param: this.settings.ffmpegPath },
				{ option: this.ytdloptions.ffmpeg_location, param: this.settings.ffProbePath }, ; technically unnecessary since it searches in the same folder but who cares
				{ option: this.ytdloptions.extract_audio },
				{ option: this.ytdloptions.audio_quality, param: 0},
				{ option: this.ytdloptions.audio_format, param: "mp3"},
				{ option: this.ytdloptions.embed_metadata }
			]
			if embedThumbnail
				profile.Push(this.PROFILE_EMBED_THUMBNAIL*)
			profile.Push(PROFILE_PARSE_METADATA*)
			if withCookies
				profile.push({ option: this.ytdloptions.cookies_from_browser, param: this.settings.browserCookies})
			if skipNonMusic
				profile.push({ option: this.ytdloptions.sponsorblock_remove, param: "music_offtopic"})
			return profile
		}
	}

	static PROFILE_SPLIT_CHAPTERS => [
		{ option: this.ytdloptions.split_chapters },
		{ option: this.ytdloptions.output, param: "chapter:%(meta_artist)s - " this.TEMPLATES.SECTION_TITLE "." this.TEMPLATES.EXT },
		{ option: this.ytdloptions.parse_metadata, param: "%(chapter_number)s:%(meta_disc)s" },
		{ option: this.ytdloptions.force_keyframes_at_cuts }
	]

	static PROFILE_EMBED_THUMBNAIL => [
		{ option: this.ytdloptions.embed_thumbnail },
		{ option: this.ytdloptions.convert_thumbnail, param: "jpg" },
		{ option: this.ytdloptions.postprocessor_args, param: 'ThumbnailsConvertor+FFmpeg_o:-c:v mjpeg -qmin 1 -qscale:v 1 -vf crop="min(iw\,ih)":"min(iw\,ih)"' } ; crop to square
	]

	static PROFILE_PARSE_METADATA[songData] {
		get {
			profile := []
			for fieldName in this.settings.metadataFields {
				if (songData.%fieldName%) {
					parser_string := Format("#{}#:#%(meta_{})s#", StrReplace(songData.%fieldName%, ":", "\:"), fieldName)
					profile.push({ option: this.ytdloptions.parse_metadata, param: parser_string })
				}
			}
			return profile
		}
	}

	static ytdloptions := { ; this is not nearly all-encompassing.
		; General and Meta Options
		ignore_config: { name: "--ignore-config",  alias: "--no-config", param: false },
		update: { name: "--update",  alias: "-U", param: false },
		simulate: { name: "--simulate",  alias: "-s", param: false },
		list_formats: { name: "--list-formats",  alias: "-F", param: false },
		print_traffic: { name: "--print-traffic", param: false },
		newline: { name: "--newline", param: false },
		verbose: { name: "--verbose", param: false },
		; Downloading Options
		default_search: { name: "--default-search", param: true },
		output: { name: "--output",  alias: "-o", param: true },
		paths: { name: "--paths", alias: "-P", param: true },
		no_overwrites: { name: "--no-overwrites",  alias: "-w", param: false },
		force_overwrites: { name: "--force-overwrites", param: false },
		no_playlist: { name: "--no-playlist", param: false },
		retries: { name: "--retries",  alias: "-R", param: true },
		restrict_filenames: { name: "--restrict-filenames", param: false },
		limit_rate: { name: "--limit-rate",  alias: "-r", param: true },
		format: { name: "--format",  alias: "-f", param: true },
		no_vid: { name: "--no-vid", param: false },
		force_keyframes_at_cuts: { name: "--force-keyframes-at-cuts", param: false },
		split_chapters: { name: "--split-chapters", param: false },
		; Extra Data Options
		skip_download: { name: "--skip-download", param: false },
		write_description: { name: "--write-description", param: false },
		write_info_json: { name: "--write-info-json", param: false },
		write_comments: { name: "--write-comments", param: false },
		write_thumbnail: { name: "--write-thumbnail", param: false },
		write_subs: { name: "--write-subs", param: false },
		dump_json: { name: "--dump-json",  alias: "-j", param: false },
		dump_single_json: { name: "--dump-single-json",  alias: "-J", param: false },
		; Authentification Options
		username: { name: "--username",  alias: "-u", param: true },
		password: { name: "--password",  alias: "-p", param: true },
		twofactor: { name: "--twofactor",  alias: "-2", param: true },
		cookies: { name: "--cookies",  param: true },
		cookies_from_browser: { name: "--cookies-from-browser",  param: true },
		; Post-Processing Options
		ffmpeg_location: { name: "--ffmpeg-location",  param: true },
		extract_audio: { name: "--extract-audio",  alias: "-x", param: false },
		audio_quality: { name: "--audio-quality",  param: true },
		audio_format: { name: "--audio-format",  param: true },
		merge_output_format: { name: "--merge-output-format",  param: true },
		embed_subs: { name: "--embed-subs", param: false },
		embed_thumbnail: { name: "--embed-thumbnail", param: false },
		embed_metadata: { name: "--embed-metadata", param: false },
		parse_metadata: { name: "--parse-metadata",  param: true },
		convert_thumbnail: { name: "--convert-thumbnail",  param: true },
		postprocessor_args: { name: "--postprocessor-args",  alias:"--ppa", param: true },
		sponsorblock_remove: { name: "--sponsorblock-remove",  alias:"--ppa", param: true },
		no_warning: { name: "--no-warning", param: false },
		print: { name: "--print",  param: true }
	}

	static ffprobeoptions := {
		v: { name: "-v", param: true },
		output_format: { name: "-output_format", param: true},
		show_entries: { name: "-show_entries", param: true}
	}
	
	static ffmpegoptions := {
		metadata: { name : "-metadata", param: true },
		i: { name : "-i", param: true },
		hide_banner: { name : "-hide_banner", param: false },
		codec: { name : "-codec", param: true },
	}

	static TEMPLATES := {
		EXT: "%(ext)s",
		ARTIST: "%(uploader)s",
		TITLE: "%(title)s",
		SECTION_TITLE: "%(section_title)s",
		LOGFILE: "{}_log.txt",
		METADATAFILE: "{}_metadata.json"
	}
}