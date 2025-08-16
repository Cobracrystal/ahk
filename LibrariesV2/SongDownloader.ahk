#Requires AutoHotkey v2
#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"

; todo: split video chapters into separate files option
; todo: attempt to parse artist/title from description if title/uploader doesn't seem correct
; todo: allow for specifying path/url to supply alternate thumbnail
; todo metadata management: re-download needs to edit metadata file
; todo metadata management: edit metadata needs to edit metadata file
; todo verify: func that creates metadata file from folder
; todo verify: func that directly overrides metadata from file
; todo verify: func that verifies that metadata file matches folder, and add option to overwrite if it doesn't (ie continued messageboxes (in both directions))
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
			if (A_LineFile == A_ScriptFullPath)
				MsgBoxAsGui(this.getMetadataFromLinks(str), "Metadata",,0,,,,1,,"i",,1000)
			else
				Run(A_LineFile)
		} else {
			return this.downloadSongWithGui(str)
		}
	}

	static downloadSongWithGui(songLink) {
		ToolTip("Loading Metadata...")
		rawDataString := this.getRawMetadataFromLinks(songLink, false, false)
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
		try metadata := jsongo.parse(jsonStr)
		catch as e {
			if RegExMatch(jsonStr, '(?:\n|\r)(\[.*\] [^"]+)(?:\n|\r|$)', &o) {
				jsonStr := RegExReplace(jsonStr, '(?:\n|\r)(\[.*\] [^"]+)(?:\n|\r|$)')
				print(Format("File {}: Got unexpected data while getting metadata: `n{}", filePath, o[1]))
				try metadata := jsongo.parse(jsonStr)
				catch as e {
					print(Format("File {}: Getting metadata unsuccessful. Setting it as empty. Error was: {}`nFull Command was: {}", filePath, objToString(e,,0,1), cmd))
					return { filePath: filePath }
				}
			} else {
				print(Format("File {}: Getting metadata unsuccessful. Setting it as empty. Error was: {}`nFull Command was: {}", filePath, objToString(e,,0,1), cmd))
				return { filePath: filePath }
			}
		}
		metadata := metadata["format"].has("tags") ? metadata["format"]["tags"] : {}
		metadata := MapToObj(metadata)
		metadata.filePath := filePath
		for tag in this.settings.metadataFields
			if !metadata.HasOwnProp(tag)
				metadata.%tag% := ""
		return metadata
	}

	static getMetadataFromFolder(folder, setEmptyDefaultValues := true) {
		if !InStr(folder, "\")
			folder := this.settings.outputBaseFolder "\" folder
		folder := getFolderAsArr(folder, , , 0, "timeCreated")
		metadataArr := objDoForEach(folder, v => this.getMetadataFromFile(v.path))
		fields := arrayMerge(this.settings.metadataFields, ["purl", "comment", "description"])
		if setEmptyDefaultValues
			for v in metadataArr
				for field in fields
					if !v.HasOwnProp(field)
						v.%field% := ""
		return metadataArr
	}

	static downloadFromJson(jsonAsStr, outputSubFolder := this.settings.outputSubFolder, embedThumbnail := true) {
		data := MapToObj(jsongo.Parse(jsonAsStr))
		if !(data is Array)
			data := [data]
		finisher := this.onFinish.bind(this, data.length, outputSubFolder, 1, 0)
		for i, dataPoint in data {
			profile := this.PROFILE_MUSIC[this.PROFILE_PARSE_METADATA[dataPoint], this.constructOutputPatternString(dataPoint), outputSubFolder, this.settings.useCookies, true, embedThumbnail]
			this.launchYTDL(profile, dataPoint.link, this.settings.useVisibleCMD, finisher)
		}
	}
	
	static getMetadataFromLinks(songLinks, allData := false, withPlaylist := false, printIntermediateSteps := false) {
		rawDataString := this.getRawMetadataFromLinks(songLinks, printIntermediateSteps, withPlaylist)
		return this.parseMetadata(rawDataString, allData)
	}

	static getRawMetadataFromLinks(songLinks, printIntermediateSteps := false, withPlaylist := false) {
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
				this.logMetadata(songData, 1, gData.OutputFolder)
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
		g.AddEdit("xs w250 R1 ReadOnly vFileName", name)
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
					SplitPath(g["FileName"].Value,,,&ext)
					g["FileName"].Value := g["Artist"].Value " - " g["Title"].Value "." ext
				case "Title", "Artist":
					SplitPath(g["FileName"].Value,,,&ext)
					g["FileName"].Value := g["Artist"].Value " - " g["Title"].Value "." ext
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

	static editMetadata(filePath, metadata, extraFields*) {
		SplitPath(filePath, &oldName, &dir, &ext, &oldNameNoExt)
		SplitPath(dir, &dirname)
		str := ""
		flagSameFileName := (metadata.filename = oldName) ; with ext. Ignore capitalization since its a filename
		finalFilePath := dir "\" metadata.filename
		targetFilePath := flagSameFileName ? dir "\" oldNameNoExt "_." ext : finalFilePath
		cmd := this.cmdStringBuilder(this.settings.ffmpegPath, this.PROFILE_EDITMETADATA[metadata, filePath, extraFields*],, targetFilePath)
		if this.settings.debug
			print(cmd)
		cmdRetAsync(cmd, , "UTF-8",,finishEdit, 5000)
	
		finishEdit(output, success) {
			Sleep(300)
			if success == -1 || InStr(output, "Error") {
				MsgBoxAsGui("ERROR:`n" output,,,,,,,1)
				return
			}
			else if (FileExist(targetFilePath)) {
				if (flagSameFileName)
					FileMove(targetFilePath, finalFilePath, 1)
				else
					FileDelete(filePath)
			}
			logStr := "Edited Metadata of " filePath . (flagSameFileName ? " " : " (now " finalFilePath ")")
			this.logAction(logStr, dirname)
			MsgBoxAsGui("Done!")
		}
	}

	static thumbnailPreviewer(metadata) {
		static HTML_TEMPLATE := '<!DOCTYPE html><html><head><style>html,body {margin: 0;padding: 0;}.overlay {position: absolute;top: 0;height: {3}px;background-color: #000;filter: alpha(opacity=85);}</style></head><body><div style="width:{2}px;height:{3}px;"><img src="{1}" alt="Picture" style="width:{2}px;height:{3}px;"><div class="overlay" style="left:0;width:{4}px;"></div><div class="overlay" style="right:0;width:{4}px;"></div></div></body></html>'
		
		if !metadata.HasOwnProp("thumbnails") {
			if (!metadata.link)
				return MsgBoxAsGui("No Link set to retrieve thumbnail from and retrieving it from metadata is not yet implemented.")
			dataStr := this.getRawMetadataFromLinks(metadata.link)
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
		logStr := "Downloaded " count "/" amount ": " output
		this.logAction(output, logID, count==amount)
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
			input := "https://www.youtube.com/watch?v=" . o[1]
		else if (RegExMatch(input, "^[A-Za-z0-9_-]{11}$"))
			input := "https://www.youtube.com/watch?v=" . input
		return Trim(input)
	}

	static constructOutputPatternString(songData, withExt := true, &count?) {
		if songData.HasOwnProp("filename")
			filename := songData.filename . (withExt ? "." this.TEMPLATES.EXT : "")
		else {
			title := songData.title ? songData.title : this.TEMPLATES.TITLE
			artist := songData.artist ? songData.artist : this.TEMPLATES.ARTIST
			filename := artist " - " title . (withExt ? "." this.TEMPLATES.EXT : "")
		}
		filename := strReplaceIllegalChars(filename, &count?)
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

	static PROFILE_EDITMETADATA[metadata, filePath, extraFields*] {
		get {
			profile := [
				{ option: this.ffmpegoptions.i, param: filePath},
				{ option: this.ffmpegoptions.hide_banner },
				{ option: this.ffmpegoptions.codec, param: "copy"}
			]
			for tag in this.settings.metadataFields
				profile.push( { option: this.ffmpegoptions.metadata, param: tag "=" metadata.%tag%})
			for tag in extraFields
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

	static logAction(str, logID, addSeparator := true) {
		path := Format(this.settings.logFolder "\" this.TEMPLATES.LOGFILE, logID)
		fullStr := Format("[{}] {}`n", FormatTime(A_Now, "dd.MM.yyyy, ~HH:mm:ss"), Trim(str, " `t`r`n"))
		if addSeparator
			fullStr .= strMultiply("=", 22) "`n"
		FileAppend(fullStr, path, "UTF-8")
	}

	static logMetadata(metadata, action, logID) {
		metadatapath := Format(this.settings.logFolder "\" this.TEMPLATES.METADATAFILE, logID)
		switch action {
			case 0, "add":
			case 1, "remove":
			case 2, "edit":
				doNothing()
		}
		dataArr := []
		if FileExist(metadatapath)
			dataArr := jsongo.parse(FileRead(metadatapath, "UTF-8"))
		dataArr.push(metadata)
		f := FileOpen(metadatapath, "w", "UTF-8")
		f.Write(objToString(dataArr,false,false,true))
		f.Close()
	}

	static createMetadataFile(folder, alwaysOverwrite := false) {
		SplitPath(folder, &name)
		arr := this.getMetadataFromFolder(folder)
		arrInFormat := []
		arrInFormat.Capacity := arr.Length
		for v in arr {
			SplitPath(v.filePath,,,, &nameNoExt)
			nObj := { artist: v.artist,	title: v.title, album: v.album,	genre: v.genre,
				description: v.description,	link: v.purl,
				comment: v.comment == v.purl ? unset : v.comment,
			}
			this.constructOutputPatternString(v,0,&c)
			if c > 0
				nObj.filename := nameNoExt
			arrInFormat.push(nObj)
		}
		json := objToString(arrInFormat, 0, 0, 1)
		filename := Format(this.TEMPLATES.METADATAFILE, name)
		path := this.settings.logFolder "\" filename
		if FileExist(path) && !alwaysOverwrite {
			newName := StrReplace(filename, ".json", "_" FormatTime(FileGetTime(path), "yy-MM-dd") ".json")
			oldJson := FileRead(path, "UTF-8")
			text := Format("
				(
				{} already exists. Overwrite, Rename existing file to {} or Cancel?

				Length of existing file: {} Characters / {} Lines / {} Objects
				Length of new file: {} Characters / {} Lines / {} Objects
				)", 
				filename, 
				newName,
				StrLenUTF8(oldJson), 
				strCountStr(oldJson, "`n") + 1, 
				strCountStr(oldJson, '"title":'), 
				StrLenUTF8(json), 
				strCountStr(json, "`n") + 1, 
				arrInFormat.Length
			)
			res := MsgBoxAsGui(text, "Confirm", 0x1,, true,,,,["Overwrite", "Rename", "Cancel"])
			if res == "Cancel"
				return
			if res == "Rename" {
				newPath := this.settings.logFolder "\" newName
				if FileExist(newPath)
					newPath := StrReplace(newPath, ".json", "_" FormatTime(FileGetTime(path), "HH-mm-ss") ".json")
				try FileMove(path, newPath)
				catch as e {
					MsgBoxAsGui("Error while moving file:`n" objToString(e))
					return
				}
				Sleep(200)
			}
		}
		f := FileOpen(path, 'w', 'UTF-8')
		f.Write(json)
		f.close()
		print(Format("Created Metadata File for folder {}, with {} Objects", folder, arrInFormat.Length))
	}

	static verifyData(folderToCheck := this.settings.outputSubFolder, customJsonObj?, verifyMetadata := true, onlyReturnMismatches := true) {
		SplitPath(folderToCheck, &name)
		folder := this.settings.outputBaseFolder "\" name
		if IsSet(customJsonObj)
			data := customJsonObj
		else if FileExist(path := Format(this.settings.logFolder '\' this.TEMPLATES.METADATAFILE, name))
			data := MapToObj(jsongo.Parse(FileRead(path, "UTF-8")))
		else
			return "There's nothing to check against"
		fields := arrayMerge(this.settings.metadataFields, ["link", "description"])
		for v in data
			for field in fields
				if !v.HasOwnProp(field)
					v.%field% := ""
		comparisons := this.compareFolderToData(folder, data, verifyMetadata, onlyReturnMismatches)
		for e in comparisons { ; beautify these comparisons so that there aren't any monstrous strings in there
			if e.metadata {
				for field, val in e.metadata.OwnProps() {
					str1 := val.expected
					str2 := val.actual
					if (StrLen(str1) > 100 || StrLen(str2) > 100) {
						diff := strLimitToDiffs(str1, str2)
						val.expected := diff[1]
						val.actual := diff[2]
					}
				}
			}
		}
		for e in comparisons {
			print(e)
			; res := MsgBoxAsGui("Choose Metadata that is embedded in the File or the one defined in the json?",,,,1,,,,["File", "JSON"])
			; if (res == "JSON") {
			; 	SongDownloader.writeMetadataToFile(folder, SongDownloader.settings.outputBaseFolder "\" folder "\" e.filename ".mp3", e.index)
			; } else if res == "File" {
			; 	SongDownloader.writeMetadataFromFile(folder, SongDownloader.settings.outputBaseFolder "\" folder "\" e.filename ".mp3", e.index)
			; }
			; MsgBox("waiting...")
		}
	}
	
	static compareFolderToData(folder, data, verifyMetadata := true, onlyReturnMismatches := true) {
		comparisons := []
		expectedFiles := Map()
		expectedFiles.CaseSense := false
		if verifyMetadata {
			folderMetadata := this.getMetadataFromFolder(folder)
			arrFnames := objDoForEach(folderMetadata, v => (SplitPath(v.filePath,,,,&nne), nne))
			actualMetadata := Map()
			actualMetadata.CaseSense := false
			for fName, metadataObj in objzip(arrFnames, folderMetadata)
				actualMetadata[fName] := metadataObj
		}
		for i, dataPoint in data {
			fName := this.constructOutputPatternString(dataPoint, false)
			o := {
				fileName: fName,
				index: i,
				specified: true,
				; exists: true,
				other: 0,
				metadata: 0
			}
			if (FileExist(folder "\" fName ".mp*")) {
				o.exists := true
				if expectedFiles.Has(fName) {
					comparisons[expectedFiles[fName]].other := "Duplicate"
					o.other := "Duplicate"
				} else {
					expectedFiles[fName] := i
					o.metadata := verifyMetadata ? this.compareMetadata(dataPoint, actualMetadata[fName]): 0
				}
			} else {
				expectedFiles[fName] := 0
				o.exists := false
			}
			comparisons.push(o)
		}
		for f in getFolderAsArr(folder,,,0) {
			o := {	fileName: f.name,
					; specified: 0,
					exists: true,
					metadata: false,
					other: false  }
			if (expectedFiles.has(f.nameNoExt)) {
				if expectedFiles[f.nameNoExt] 
					continue
				o.specified := true
				o.other := "Wrong extension"
			} else
				o.specified := false
			comparisons.push(o)
		}
		if onlyReturnMismatches
			return objFilter(comparisons, (k,v) => !v.exists || !v.specified || v.metadata || v.other)
		return comparisons

	}

	static compareMetadata(m1, m2) {
		static fieldMap := Map(
			"title", "title", 
			"artist", "artist", 
			"album", "album", 
			"genre", "genre", 
			"description", "description", 
			"link", "purl"
		)
		c := {}
		for f1, f2 in fieldMap {
			if m1.%f1% == m2.%f2%
				continue
			c.%f1% := { expected: m1.%f1%, actual: m2.%f2%}
		}
		if ObjOwnPropCount(c)
			return c
		return 0
	}

	static writeMetadataFromFile(folder, filepath, index) {
		SplitPath(folder, &name)
		fileData := this.getMetadataFromFile(filepath)
		SplitPath(fileData.filePath,,,, &nameNoExt)
		metadata := {
			artist: fileData.artist,
			title: fileData.title,
			album: fileData.album,
			genre: fileData.genre,
			description: fileData.description,
			link: fileData.purl,
			comment: fileData.comment == fileData.purl ? unset : fileData.comment,
			fileName: this.constructOutputPatternString(fileData,0) == nameNoExt ? unset : nameNoExt
		}
		mtlogname := Format(this.TEMPLATES.METADATAFILE, name)
		path := this.settings.logFolder "\" mtlogname
		if FileExist(path) {
			curData := jsongo.Parse(FileRead(path, "UTF-8"))
			curData[index] := metadata
		} else {
			curData := [metadata]
		}
		json := objToString(curData, 0, 0, 1)
		f := FileOpen(path, 'w', 'UTF-8')
		f.Write(json)
		f.close()
	}

	static writeMetadataToFile(folder, filepath, index) {
		SplitPath(folder, &name)
		SplitPath(filepath, &fname)
		path := Format(this.settings.logFolder "\" this.TEMPLATES.METADATAFILE, name)
		metadata := MapToObj(jsongo.parse(FileRead(path, "UTF-8"))[index])
		metadata.filename := fname
		this.editMetadata(filepath, metadata, "description") ; doesn't edit description field
	}

	static findMetadataDupes() {
		data := []
		loop files this.settings.logFolder "\*", '' {
			if (RegExMatch(A_LoopFileName, "^p\d{3}_metadata.json$")) {
				try mdata := jsongo.Parse(FileRead(A_LoopFileFullPath, "UTF-8"))
				mdata := mdata ?? []
				mdata := objDoForEach(mdata, (val => (val.folder := A_LoopFileName, val)))
				data.push((mdata ?? [])*)
			}
		}
		lambda := a => (a.has("title") && a.has("artist") ? a["title"] a["artist"] : a.has("filename") ? a["filename"] : true)
		indices := objGetDuplicates(data, lambda, false, true)
		dupls := []
		for e in indices {
			for i in e
				dupls.push(data[i])
		}
		return dupls
	}
}