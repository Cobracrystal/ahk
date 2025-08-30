#Requires AutoHotkey v2
#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\WinUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\FileUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\unicodeData.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\jsongo.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\cmdStdoutAsync.ahk"

; todo: split video chapters into separate files option
; todo: attempt to parse artist/title from description if title/uploader doesn't seem correct
; todo: allow for specifying path/url to supply alternate thumbnail
; todo metadata management: re-download needs to edit metadata file
; todo metadata management: edit metadata needs to edit metadata file
; todo verify: func that creates metadata file from folder
; todo verify: func that directly overrides metadata from file
; todo verify: warning/note if filename property is unnecessary
; todo verify: func that verifies that metadata file matches folder, and add option to overwrite if it doesn't (ie continued messageboxes (in both directions))
if (A_LineFile == A_ScriptFullPath) { ; NECESSARY TO WORK WHEN INCLUDING
	SetWorkingDir(A_ScriptDir "\..\script_files\SongDownloader")
	SongDownloader.download(A_Clipboard)
	; usage options
	; SongDownloader.downloadSong("https://www.youtube.com/watch?v=MzsBwcXkghQ")
	; SongDownloader.downloadSong("Never Gonna Give You Up")
	; playlistdata := SongDownloader.getMetadataJson("https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=WL&index=3&pp=gAQBiAQB", false, true)
	; usage 
	; SongDownloader.settings.ytdl.browserCookies := "firefox"
	; SongDownloader.settings.ytdl.useCookies := true
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
			currentTodo: 71,
			outputBaseFolder: normalizePath(A_Desktop  "\..\Music\Collections"),
			outputSubFolder: "",
			logMetadata: true,
			logFolder: normalizePath(A_Desktop "\..\Music\ConvertMusic\ytdl\Logs"),
			ffmpegPath: normalizePath(A_Desktop "\programs\other\ProgramUtilities\ffmpeg\bin\ffmpeg.exe"),
			ffprobePath: normalizePath(A_Desktop "\programs\other\ProgramUtilities\ffmpeg\bin\ffprobe.exe"),
			ytdlPath: normalizePath(A_Desktop "\..\Music\ConvertMusic\ytdl\yt-dlp.exe"),
			metadataFields: ["title", "artist", "album", "genre"],
			ytdl: {
				useCookies: true,
				browserCookies: "firefox",
				embedThumbnail: true,
				cropThumbnailToSquare: true,
				skipNonMusic: true
			}
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
				this.getMetadataFromLinks(str, MsgBoxAsGui.bind(, "Metadata",,0,,,,1,,"i",,1000))
			else
				Run(A_LineFile)
		} else {
			this.downloadSongWithGui(str)
		}
	}

	static downloadSongWithGui(songLink) {
		ToolTip("Loading Metadata...")
		this.getRawMetadataFromLinks(songLink, callback, false, false)
		
		callback(rawDataString) {
			metaData := this.parseMetadata(rawDataString, true)
			ToolTip()
			if !metaData || !objGetValueCount(metadata)
				return
			this.songDLGui(metaData)
		}
	}

	static editMetadataWithGui(filePath) {
		this.getMetadataFromFile(filePath, metadata => this.editMetadataGui(filePath, metadata))
	}

	static getMetadataFromFile(filePath, returnCallback) {
		cmd := this.cmdStringBuilder(this.settings.ffprobePath, this.PROFILE_GETMETADATAFROMFILE,, filePath)
		if this.settings.debug
			print(cmd)
		CmdStdOutAsync(cmd, 'UTF-8',,, callback)

		callback(jsonStr, success := 0) {
			try {
				tags := jsongo.parse(jsonStr)
				tags := tags["format"].has("tags") ? MapToObj(tags["format"]["tags"]) : {}
				metadata := {
					artist: 		tags.HasOwnProp("artist") ? tags.artist : "",
					title: 			tags.HasOwnProp("title") ? tags.title : "",
					album: 			tags.HasOwnProp("album") ? tags.album : "",
					genre: 			tags.HasOwnProp("genre") ? tags.genre : "",
					description: 	tags.HasOwnProp("description") ? tags.description : "",
					link: 			tags.HasOwnProp("purl") ? tags.purl : ""
				}
				fName := this.getFileNameFromMetadata(metadata)
				SplitPath(filePath,,,,&namenoext)
				if fName != namenoext
					metadata.filename := namenoext
				if tags.HasOwnProp("comment") {
					if metadata.link != tags.comment
						metadata.comment := tags.comment
				}
				returnCallback(metadata)
			}
			catch as e {
				if RegExMatch(jsonStr, '(?:\n|\r)(\[.*\] [^"]+)(?:\n|\r|$)', &o) {
					jsonStr := RegExReplace(jsonStr, '(?:\n|\r)(\[.*\] [^"]+)(?:\n|\r|$)')
					print(Format("File {}: Got unexpected data while getting metadata: `n{}", filePath, o[1]))
					try tags := jsongo.parse(jsonStr)
					catch as e {
						print(Format("File {}: Getting metadata unsuccessful. Setting it as empty. Error was: {}`nFull Command was: {}", filePath, toString(e,,0,1), cmd))
						returnCallback({ filePath: filePath })
					}
				} else {
					print(Format("File {}: Getting metadata unsuccessful. Setting it as empty. Error was: {}`nFull Command was: {}", filePath, toString(e,,0,1), cmd))
					returnCallback({ filePath: filePath })
				}
			}
		}
	}

	static getMetadataFromFolder(folder, retCallback, onlyGetMetadata := false) {
		SplitPath(folder, &name)
		folderPath := this.settings.outputBaseFolder "\" name
		folderQueue := getFolderAsArr(folderPath, , , 0, "timeCreated")
		asyncQueueMetadata(0)
		return folderQueue

		asyncQueueMetadata(index, retValue?) {
			if IsSet(retValue) {
				if onlyGetMetadata
					folderQueue[index] := retValue
				else
					folderQueue[index].metadata := retValue
			}
			if index == folderQueue.Length
				return retCallback(folderQueue)
			index++
			item := folderQueue[index]
			this.getMetadataFromFile(item.path, asyncQueueMetadata.bind(index))
		}
	}

	; note: if jsonAsStr defines a file with title/artist containing illegal chars, the file will save correctly, but will obviously not match the json provided.
	; maybe use an onfinish handler to take the file name outputted and write it (if it did contain illegal chars). This would require a path to a json being given though.
	static downloadFromJson(jsonAsStr, outputFolder := this.settings.outputSubFolder) {
		data := MapToObj(jsongo.Parse(jsonAsStr))
		if !(data is Array)
			data := [data]
		if this.settings.useVisibleCMD
			for i, dataPoint in data
				Run("wt cmd " (this.settings.debug ? "/k" : "/c") " chcp 65001 && title SongDownloader && echo " fullCommand " && " fullCommand)
		else
			asyncQueueJson(0)
		return data

		asyncQueueJson(index, output?, success := 0) {
			if IsSet(output) {
				this.logAction(output, outputFolder, index == data.Length)
				ToolTip(Format("[~{}/{}] {}", index, data.Length, Trim(SubStr(output, InStr(output, "|")+1))), -1920, 0)
			}
			if index == data.Length {
				ToolTip()
				this.onFinishMsgBox(outputFolder)
				return
			}
			index++
			dataPoint := data[index]
			profile := this.PROFILE_MUSIC[
				this.PROFILE_PARSE_METADATA[dataPoint], 
				this.getOutputPatternFromMetadata(dataPoint), 
				outputFolder, 
				this.settings.ytdl.useCookies, 
				this.settings.ytdl.skipNonMusic,
				this.settings.ytdl.embedThumbnail, 
				this.settings.ytdl.cropThumbnailToSquare
			]
			fullCommand := this.cmdStringBuilder(this.settings.ytdlPath, profile, 0, dataPoint.link)
			if (this.settings.debug)
				print(fullCommand)
			CmdStdOutAsync(fullCommand, "UTF-8",,, asyncQueueJson.bind(index))
		}
	}
	
	static getMetadataFromLinks(songLinks, callback, allData := false, withPlaylist := false, printIntermediateSteps := false) {
		this.getRawMetadataFromLinks(songLinks, rawDataString => callback(this.parseMetadata(rawDataString, allData)), printIntermediateSteps, withPlaylist)
	}

	static getRawMetadataFromLinks(songLinks, returnCallback, printIntermediateSteps := false, withPlaylist := false) {
		if !(songLinks is Array)
			songLinks := StrSplitUTF8(Trim(songLinks, "`n`r"), "`n", "`r")
		songLinks := objDoForEach(songLinks, (e => this.constructLink(e)))
		command := this.cmdStringBuilder(this.settings.ytdlPath, this.PROFILE_GETMETADATA[printIntermediateSteps, withPlaylist, true],,songLinks*)
		CmdStdOutAsync(command, 'UTF-8', callback)

		callback(output, success := 0) {
			static fullOutput := ""
			fullOutput .= output
			if RegExMatch(SubStr(output, 1, 20), "^\[[[:alnum:]]+\]")
				Tooltip(SubStr(output, 1, 40))
			if success {
				tOutput := fullOutput
				fullOutput := ""
				if (this.settings.debug) {
					if (!InStr(FileExist(A_WorkingDir "\SongDownloader"), "D"))
						DirCreate(A_WorkingDir "\SongDownloader")
					FileAppend(tOutput, A_WorkingDir "\SongDownloader\retLog_" FormatTime(A_Now, "yyyy-MM-dd_HH.mm.ss") ".txt", "UTF-8")
				}
				returnCallback(tOutput)
			}
		}
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
				closed := unicodeData.getBidiPairedBracket(open)
				if open != closed
					title := RegExReplace(title, Format("i){}\s*(?:Official|Lyric)\s+((Music|Lyric|HD)\s+)?(Video|Audio)\s*{}", '\' open, '\' closed))
			}
			artist := videoData.Has("artists") ? Trim(toString(videoData["artists"],1,0), " []") : videoData.Has("creator") ? artist := videoData["creator"] : ""
			if RegexMatch(title, "^(.*?)(?:-|–|—)\s+(.*)$", &m) {
				if artist == ""
					artist := m[1]
				title := m[2]
			}
			if artist == ""
				artist := videoData["uploader"]
			if RegExMatch(title, "i)^(.*?)(\S)\s*\b(?:feat|ft)\b\.?(.*)", &match) {
				open := match[2]
				closed := unicodeData.getBidiPairedBracket(match[2])
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
				closed := unicodeData.getBidiPairedBracket(match[2])
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
		outputFolder := this.settings.outputSubFolder
		if IsSet(destination) {
			SplitPath(destination, &fl)
			outputFolder := fl
		}
		g.AddEdit("xs+110 ys R1 w30 vOutputFolder", outputFolder).OnEvent("Change", guiHandler)
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
			g.AddButton("xs+151 yp-1 w100", "Show Full Json").OnEvent("Click", (*) => MsgBoxAsGui(toString(data.shortJson,0,0,1), "JSON",,0,,,g.hwnd,1,,,,800, 1200))
		g.AddEdit("xs w250 vGenre", metadataVar.genre).OnEvent("Change", guiHandler)
		g["Title"].Focus()
		g.AddCheckbox("xs vEmbedThumbnail Checked" this.settings.ytdl.embedThumbnail, "Embed Thumbnail").OnEvent("Click", guiHandler)
		g.AddCheckbox("xs+125 yp vUseVisibleCMD Checked" this.settings.useVisibleCMD, "Visble CMD")
		g.AddCheckbox("xs vUseCookies Checked" this.settings.ytdl.useCookies, "Use Cookies (" this.settings.ytdl.browserCookies ")").OnEvent("Click", guiHandler)
		g.AddCheckbox("xs+125 yp vSkipNonMusic Checked" this.settings.ytdl.skipNonMusic, "Skip Non-Music Parts").OnEvent("Click", guiHandler)
		g.AddCheckbox("xs vLogMetadata Checked" this.settings.logMetadata, "Log Metadata")
		g.AddCheckbox("xs+125 yp vReuseData Checked" false, "Re-Use Data")
		g.AddCheckbox("xs vOmitArtistName Checked" false, "Omit Artist in Filename").OnEvent("Click", guiHandler)
		g.AddCheckbox("xs+125 yp vCropThumbToSquare Checked" this.settings.ytdl.cropThumbnailToSquare, "Crop Thumb To Square").OnEvent("Click", guiHandler)
		g.AddText("xs", "Current Command Line")
		profile := this.PROFILE_MUSIC[
			this.PROFILE_PARSE_METADATA[data],
			this.getOutputPatternFromMetadata(data),
			outputFolder,
			this.settings.ytdl.useCookies,
			this.settings.ytdl.skipNonMusic,
			this.settings.ytdl.embedThumbnail,
			this.settings.ytdl.cropThumbnailToSquare
		]
		cropToSquare := this.settings.ytdl.cropThumbnailToSquare ; for use of the checkbox
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
					rem := [{ option: this.ytdloptions.output, param: this.getOutputPatternFromMetadata(data)}]
					data.%name% := val ; THIS LINE BEING IN THIS ORDER IS RELEVANT
					add := [{ option: this.ytdloptions.output, param: this.getOutputPatternFromMetadata(data)}]
					profile := this.addRemoveProfile(profile, rem, add, true, true)
				case "Link":
					data.link := val
				case "OutputFolder":
					rem := [{ option: this.ytdloptions.paths, param: this.settings.outputBaseFolder "\" outputFolder }]
					add := [{ option: this.ytdloptions.paths, param: this.settings.outputBaseFolder "\" val }]
					outputFolder := val
					profile := this.addRemoveProfile(profile, rem, add, true, true)
				case "EmbedThumbnail":
					toggleProfile := this.PROFILE_EMBED_THUMBNAIL[cropToSquare]
					profile := this.toggleProfile(profile, toggleProfile)
				case "CropThumbToSquare":
					rem := this.PROFILE_EMBED_THUMBNAIL[cropToSquare]
					add := this.PROFILE_EMBED_THUMBNAIL[val]
					cropToSquare := val
					profile := this.addRemoveProfile(profile, rem, add, true) ; not in-place because arr lengths don't match
				case "UseCookies": ; might cause issues if this setting changes while in GUI but ehhh
					toggleProfile := [{option: this.ytdloptions.cookies_from_browser, param: this.settings.ytdl.browserCookies}]
					profile := this.toggleProfile(profile, toggleProfile)
				case "SkipNonMusic":
					toggleProfile := [{option: this.ytdloptions.sponsorblock_remove, param: "music_offtopic"}]
					profile := this.toggleProfile(profile, toggleProfile)
				case "OmitArtistName":
					rem := [{ option: this.ytdloptions.output, param: this.getOutputPatternFromMetadata(data)}]
					add := [{ option: this.ytdloptions.output, param: this.getOutputPatternFromMetadata(data,val)}]
					profile := this.addRemoveProfile(profile, rem, add, true, true)
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
				this.getOutputPatternFromMetadata(songData, gData.OmitArtistName, &wasIrregular),
				gData.OutputFolder,
				gData.UseCookies,
				gData.SkipNonMusic,
				gData.embedThumbnail,
				gData.cropThumbToSquare
			]
			if wasIrregular
				this.getFileNameFromMetadata(songData, gData.OmitArtistName)
			if (gData.ReuseData)
				this.data.lastSongMetadata := songData
			else
				this.data.lastSongMetadata := {}
			if gData.LogMetadata {
				this.logMetadata(songData, 1, gData.OutputFolder)
			}
			fullCommand := this.cmdStringBuilder(this.settings.ytdlPath, profile, false, songData.link)
			if (this.settings.debug)
				print(fullCommand)
			if (gData.useVisibleCMD)
				Run("wt cmd " (this.settings.debug ? "/k" : "/c") " chcp 65001 && title SongDownloader && echo " fullCommand " && " fullCommand)
			else
				CmdStdOutAsync(fullCommand, "UTF-8",,, doneHandler)

			doneHandler(output, success := 0) {
				this.logAction(output, gData.OutputFolder)
				this.onFinishMsgBox(gData.OutputFolder)
			}
		}
	}

	; todo: add checkbox to omit artist here too
	static editMetadataGui(filePath, metadata) {
		g := Gui("+Border +OwnDialogs", "Edit Metadata")
		g.OnEvent("Close", (*) => g.Destroy())
		SplitPath(filePath,, &dir)
		SplitPath(dir, &dirname)
		g.AddText("Section 0x200 R1.45", "File | Current Folder: " )
		g.AddEdit("xs+110 ys R1 w30 vOutputFolder", dirname)
		if (metadata.HasOwnProp("link"))
			g.AddButton("xs+151 ys-1 w100", "Open Link").OnEvent("Click", (*) => Run(metadata.link))
		g.AddEdit("xs w250 R1 ReadOnly vFileName", this.getFileNameFromMetadata(metadata))
		g.AddText("0x200 R1.45", "Title")
		g.AddEdit("xs w250 vTitle", metadata.title).OnEvent("Change", guiHandler)
		g.AddText("0x200 R1.45", "Artist")
		g.AddButton("xs+151 yp-1 w100 vSwapButton", "Swap Title - Artist").OnEvent("Click", guiHandler)
		g.AddEdit("xs w250 vArtist", metadata.artist).OnEvent("Change", guiHandler)
		g.AddText("0x200 R1.45", "Album")
		if metadata.HasOwnProp("description")
			g.AddButton("xs+151 yp-1 w100", "Show Description").OnEvent("Click", (*) => MsgBoxAsGui(metadata.description, "Video Description",,0,,,g.hwnd,1,,,,,1200))
		g.AddEdit("xs w250 vAlbum", metadata.album).OnEvent("Change", guiHandler)
		g.AddText("", "Genre")
		g.AddEdit("xs w250 vGenre", metadata.genre).OnEvent("Change", guiHandler)
		g.AddButton("xs-1 h30 w251 vReDownload", "Re-Download").OnEvent("Click", finishGui)
		g.AddButton("xs1 h30 w251 vEditMetadata Default", "Edit Metadata").OnEvent("Click", finishGui)
		g.Show(Format("x{1}y{2} Autosize", this.data.coords.x, this.data.coords.y))

		guiHandler(guiCtrlObj, info?) {
			switch guiCtrlObj.Name {
				case "SwapButton":
					temp := g["Artist"].Value
					g["Artist"].Value := g["Title"].Value
					g["Title"].Value := temp
					g["FileName"].Value := this.getFileNameFromMetadata(metadata,,1)
				case "Title", "Artist":
					g["FileName"].Value := this.getFileNameFromMetadata(metadata,,1)
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
						link: metadata.link, description: metadata.Description
					}
					this.getFileNameFromMetadata(songData)
					this.songDLGui(songData, dirname, true)
				case "EditMetadata":
					this.editMetadata(filePath, gData)
			}
		}
	}


	/**
	 * Edit Metadata of a file with given metadata using ffmpeg
	 * @param currentFilePath file path to apply the object to
	 * @param metadata metadata object to apply
	 * @param extraFields extra fields in metadata to write (eg description, link etc)
	 */
	static editMetadata(currentFilePath, metadata, extraFields*) {
		SplitPath(currentFilePath, &oldName, &dir, &ext, &oldNameNoExt)
		SplitPath(dir, &dirname)
		newFileName := this.getFileNameFromMetadata(metadata)
		flagSameFileName := (newFileName = oldNameNoExt) ; with ext. Ignore capitalization since its a filename
		finalFilePath := dir "\" newFileName "." ext
		targetFilePath := flagSameFileName ? dir "\" oldNameNoExt "_" Random(1000000, 9999999) "." ext : finalFilePath
		cmd := this.cmdStringBuilder(this.settings.ffmpegPath, this.PROFILE_EDITMETADATA[metadata, currentFilePath, extraFields*],, targetFilePath)
		if this.settings.debug
			print(cmd)
		CmdStdOutAsync(cmd, 'UTF-8', , 5000, finishEdit)
	
		finishEdit(output, success := 0) {
			fullOutput := ""
			if success == -1 || InStr(output, "Error") {
				MsgBoxAsGui("ERROR:`n" output,,,,,,,1)
				return
			} else if (FileExist(targetFilePath)) {
				if (flagSameFileName)
					FileMove(targetFilePath, finalFilePath, 1)
				else
					FileDelete(currentFilePath)
			}
			logStr := "Edited Metadata of " currentFilePath . (flagSameFileName ? " " : " (now " finalFilePath ")")
			this.logAction(logStr, dirname)
			MsgBoxAsGui("Done!")
		}
	}

	static thumbnailPreviewer(metadata) {
		static HTML_TEMPLATE := '<!DOCTYPE html><html><head><style>html,body {margin: 0;padding: 0;}.overlay {position: absolute;top: 0;height: {3};background-color: #000;filter: alpha(opacity=85);}</style></head><body><div style="width:{2};height:{3};"><img src="{1}" alt="Picture" style="width:{2};height:{3};"><div class="overlay" style="left:0;width:{4}px;"></div><div class="overlay" style="right:0;width:{4}px;"></div></div></body></html>'
		if metadata.HasOwnProp("thumbnails") {
			RegExMatch(metadata.thumbnails[1].url, "https:\/\/.*?\/.*?\/([a-zA-Z0-9-_]{11})\/.*?\.", &o)
			getThumbs := InStr(metadata.link, o[1]) ? 0 : 1
		}
		if !metadata.HasOwnProp("thumbnails") || getThumbs {
			if (!metadata.link)
				return MsgBoxAsGui("No Link set to retrieve thumbnail from and retrieving it from metadata is not yet implemented.")
			timedTooltip('Retrieving thumbnails...')
			this.getRawMetadataFromLinks(metadata.link, tfunc.bind(metadata))
			return

			tfunc(metadata, dataStr) {
				metadata.thumbnails := this.parseMetadata(dataStr).thumbnails
				this.thumbnailPreviewer(metadata)
			}
		}
		
		for th in arrayInReverse(metadata.thumbnails) {
			if InStr(th.url, ".webp") ; activex doesn't support webps
				continue
			thumb := th
			break
		}
		flagHasSize := thumb.HasOwnProp("height")
		height := flagHasSize ? clamp(thumb.height, 1, 500) : 500
		width := flagHasSize ? Round(height/thumb.height * thumb.width) : 889
		squareOffset := (width - height) // 2
		g := Gui("+Border +OwnDialogs +E" WinUtilities.EXSTYLES.WS_EX_COMPOSITED, "Thumbnail Preview")
		g.OnEvent("Close", (*) => g.Destroy())
		sect := g.AddText("Section 0x200 R1.45", "Link | Thumbnail ID: " )
		sect.GetPos(&sectX)
		g.AddEdit("xs+110 ys R1 w30 vThumbID", thumb.id).OnEvent("Change", changeThumbId)
		g.AddText("xs+150 w150 0x200 R1.45 ys vThumbInfo", flagHasSize ? "Dimensions: " thumb.width " x " thumb.height : "Unknown Dimensions")
		g.AddText("xs+310 w150 0x200 R1.45 ys vThumbInfo2", "")
		g.AddButton(Format("xs+{} ys-1 w130", width-129), "View Thumbnails Json").OnEvent("Click", (*) => MsgBoxAsGui(toString(metadata.thumbnails,0,0,1), "JSON",,0,,,g.hwnd,1,,,,800, 1200))
		g.AddEdit(Format("xs w{} R1 vFile", width), thumb.url)
		WBObj := g.AddActiveX(Format("xs w{} h{} vThumb", width, height), "Shell.Explorer2").Value ; Explorer2 because persistently vanishing scrollbars.
		WBObj.Silent := true
		if flagHasSize
			WBObj.Navigate("about:" Format(HTML_TEMPLATE, thumb.url, width "px", height "px", squareOffset))
		else
			WBObj.Navigate("about:" Format(HTML_TEMPLATE, thumb.url, "auto", "auto", 0))	
		g.Show(Format("x{1}y{2} Autosize", this.data.coords.x + 125 - width//2, this.data.coords.y + 200 - 100 - height//2))

		changeThumbId(ctrlObj, info?) {
			id := Integer(g["ThumbID"].Value)
			if i := objContainsValue(metadata.thumbnails, id, v => v.id) {
				thumb := metadata.thumbnails[i]
				if Instr(thumb.url, ".webp")
					g["ThumbInfo2"].Value := "Webp preview not supported"
				else {
					g["ThumbInfo2"].Value := ""
					flagHasSize := thumb.HasOwnProp("height")
					height := flagHasSize ? clamp(thumb.height, 1, 500) : 500
					width := flagHasSize ? Round(height/thumb.height * thumb.width) : 889
					g["ThumbInfo"].Value := flagHasSize ? "Dimensions: " thumb.width " x " thumb.height : "Unknown Dimensions"
					if flagHasSize
						WBObj.Navigate("about:" Format(HTML_TEMPLATE, thumb.url, width "px", height "px", squareOffset))
					else
						WBObj.Navigate("about:" Format(HTML_TEMPLATE, thumb.url, "auto", "auto", 0))
				}
			}
		}
	}

	static launchffmpeg() {

	}

	static onFinishMsgBox(logID) {
		return MsgBoxAsGui("Finished All Downloads", "Finished",,,,doneHandler,,,["OK", "Open Folder", "Open Log", "Open Both"])
		
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

	static getFileNameFromMetadata(metadata, omitArtistName := false, ignoreFilenameProp := false, &irregularFilename?) {
		if (metadata.HasOwnProp("filename") && !ignoreFilenameProp) {
			irregularFilename := 0
			return metadata.filename
		} else {
			filename := ""
			if !omitArtistName
				filename := metadata.artist " - "
			filename .= metadata.title
			filename := RegExReplace(filename, "\s+", " ") ; normalize spaces
			filename := strReplaceIllegalChars(filename, &count)
			if irregularFilename := (count > 0 || omitArtistName)
				metadata.filename := filename
			return filename
		}
	}

	static getOutputPatternFromMetadata(songData, omitArtistName := false, &wasIrregular?) {
		if songData.HasOwnProp("filename")
			filename := songData.filename
		else {
			title := songData.title != "" ? songData.title : this.TEMPLATES.TITLE
			artist := songData.artist != "" ? songData.artist : this.TEMPLATES.ARTIST
			filename := (omitArtistName ? "" : artist " - ") . title
		}
		filename .= "." this.TEMPLATES.EXT
		filename := RegExReplace(filename, "\s+", " ") ; normalize spaces
		filename := strReplaceIllegalChars(filename, &count)
		wasIrregular := (count > 0 || omitArtistName)
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
		for i, e in (profileToMerge) {
			if !(e.option.param && e.HasOwnProp("param"))
				throw(ValueError("addRemoveProfile received malformed merge profile"))
			else if (index := objContainsMatch(nProfile, (k,v) => objcompare(v.option, e.option)))
				nProfile[index].param := e.param
		}
		return nProfile
	}

	static addRemoveProfile(profile, profileToRemove := [], profileToAdd := [], paramCompare := true, inplace := false) {
		nProfile := profile.clone() ; deepclone unnecessary.
		optCompare := (k, v, v2) => (objCompare(v.option, v2.option))
		optCompare2 := (v, v2) => (objCompare(v.option, v2.option))
		allCompare2 := (v, v2) => (objCompare(v, v2))
		allCompare := (k, v, v2) => (objCompare(v, v2))
		lambda := paramCompare ? allCompare : optCompare
		lambda2 := paramCompare ? allCompare : optCompare
		if (inplace) {
			if (profileToRemove.Length != profileToAdd.Length) {
				if pos := arrayContainsArray(nProfile, profileToRemove, lambda2) {
					nProfile.RemoveAt(pos, profileToRemove.Length)
					nProfile.InsertAt(pos, profileToAdd*)
				} else
					throw(ValueError("Given Arrays have different Lengths and aren't sequential in profile"))
			}
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
			if this.settings.ytdl.useCookies
				profile.push({ option: this.ytdloptions.cookies_from_browser, param: this.settings.ytdl.browserCookies})
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

	static PROFILE_MUSIC[PROFILE_PARSE_METADATA, outputTemplate, outputSubFolder, withCookies, skipNonMusic, embedThumbnail, cropThumbnailToSquare] {
		get {
			profile := [
				{ option: this.ytdloptions.ignore_config },
				{ option: this.ytdloptions.retries, param: 1 },
				{ option: this.ytdloptions.limit_rate, param: "5M" },
				; { option: this.ytdloptions.no_overwrites },
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
				profile.Push(this.PROFILE_EMBED_THUMBNAIL[cropThumbnailToSquare]*)
			profile.Push(PROFILE_PARSE_METADATA*)
			if withCookies
				profile.push({ option: this.ytdloptions.cookies_from_browser, param: this.settings.ytdl.browserCookies})
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

	static PROFILE_EMBED_THUMBNAIL[cropToSquare := false] {
		get {
			profile := [
				{ option: this.ytdloptions.embed_thumbnail },
				{ option: this.ytdloptions.convert_thumbnail, param: "jpg" }
			]
			if cropToSquare
				profile.push(
					{ option: this.ytdloptions.postprocessor_args, param: 'ThumbnailsConvertor+FFmpeg_o:-c:v mjpeg -qmin 1 -qscale:v 1 -vf crop="min(iw\,ih)":"min(iw\,ih)"' } ; crop to square
				)
			return profile
		}
	}

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
		if this.settings.debug
			print(fullStr)
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
		f.Write(toString(dataArr,false,false,true))
		f.Close()
	}

	static renameFilesToMatchMetadata(folder) {
		SplitPath(folder, &name)
		folder := this.settings.outputBaseFolder "\" folder
		this.getMetadataFromFolder(folder, callback)

		callback(folderMetadata) {
			filename := Format(this.TEMPLATES.METADATAFILE, name)
			path := this.settings.logFolder "\" filename
			for f in folderMetadata {
				currentFilename := this.getFileNameFromMetadata(f.metadata) "." f.ext
				expectedFilename := this.getFileNameFromMetadata(f.metadata,,true) "." f.ext
				if currentFilename == expectedFilename
					continue
				str := Format('Rename "{}" => "{}"', currentFilename, expectedFilename)
				if askPermissionMsgbox(str, ["Rename File", "Cancel"]) == "Rename File" {
					if FileExist(folder "\" expectedFilename)
						str := "[Failure] " str " (Error: File already exists)"
					else {
						try {
							FileMove(folder "\" currentFilename, folder "\" expectedFilename)
							str := "[Success] " str
						}
						catch as e
							str := "[Failure] " str " (Error: " e.Message ")"
					}
				}
				else
					str := "[Cancel] " str
				print(str)
			}
		}

		askPermissionMsgbox(str, btns) {
			return MsgBoxAsGui(str, "Confirm",,,true,,,,btns)
		}
	}

	static applyMetadataFile(folder, noMsgBoxConfirms := false, applyEvenIfMatching := false, deleteUnspecifiedFiles := false, renameFilesToMatchMetadata := false) {
		static checkIfValid := (v => !v.exists || !v.specified || v.metadata || v.other)
		
		SplitPath(folder, &name)
		folder := this.settings.outputBaseFolder "\" name
		metadataFile := Format(this.TEMPLATES.METADATAFILE, name)
		path := this.settings.logFolder "\" metadataFile
		try metadataFilepath := MapToObj(jsongo.Parse(FileRead(path, "UTF-8")))
		catch
			return
		this.compareFolderToData(folder, callback, metadataFilepath, true, false)
		
		callback(comparisons) {
			for comp in comparisons {
				switch {
					case comp.exists && comp.specified:
						if comp.metadata || applyEvenIfMatching {
							str := "Editing File [" comp.fileName "." comp.ext "]"
							str .= comp.metadata ? " Metadata Fields: " toString(objFlatten(comp.metadata,,1)) : " (Rule ApplyEvenIfMatching)."
							if comp.other
								str .= "`nNote: " comp.other
							if noMsgBoxConfirms || askPermissionMsgbox(str, ["Edit Metadata", "Cancel"]) == "Edit Metadata"
								this.editMetadata(folder "\" comp.fileName "." comp.ext, metadataFilepath[comp.index], "description", "link")
							else
								str := "[Cancel] " str
							print(str)
						}
					case comp.exists && !comp.specified:
						str := "Unspecified File [" comp.fileName "] found."
						if (deleteUnspecifiedFiles && (noMsgBoxConfirms || askPermissionMsgbox(str, ["Delete", "Cancel"]) == "Delete")) {
							try {
								FileDelete(comp.filename)
								str .= " Deleted."
							} catch as e
								str .= " Could not delete due to Error " e.Message "."
						}
						if comp.other
							str .= "`nNote: " comp.other
						print(str)
					case !comp.exists && comp.specified:
						print("File " comp.fileName " not found.")
				}
			}
		}

		askPermissionMsgbox(str, btns) {
			return MsgBoxAsGui(str, "Confirm",,,true,,,,btns)
		}
	}

	static createMetadataFile(folder, alwaysOverwrite := false) {
		SplitPath(folder, &name)
		this.getMetadataFromFolder(folder, callback, true)

		callback(folderMetadata) {
			json := toString(folderMetadata, 0, 0, 1)
			filename := Format(this.TEMPLATES.METADATAFILE, name)
			path := this.settings.logFolder "\" filename
			if FileExist(path) && !alwaysOverwrite {
				newName := StrReplace(filename, ".json", "_" FormatTime(FileGetTime(path), "yy-MM-dd") ".json")
				oldJson := FileRead(path, "UTF-8")
				text := Format("{} already exists. Overwrite, Rename existing file to {} or Cancel?`nLength of existing file: {} Characters / {} Lines / {} Objects`nLength of new file: {} Characters / {} Lines / {} Objects",
					filename, newName,
					StrLenUTF8(oldJson), strCountStr(oldJson, "`n") + 1, strCountStr(oldJson, '"title":'), 
					StrLenUTF8(json), strCountStr(json, "`n") + 1, folderMetadata.Length
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
						MsgBoxAsGui("Error while moving file:`n" toString(e))
						return
					}
					Sleep(200)
				}
			}
			f := FileOpen(path, 'w', 'UTF-8')
			f.Write(json)
			f.close()
			print(Format("Created Metadata File for folder {}, with {} Objects", folder, folderMetadata.Length))
		}
	}

	static verifyData(folderToCheck := this.settings.outputSubFolder, customJsonObj?, verifyMetadata := true, onlyReturnMismatches := true) {
		SplitPath(folderToCheck, &name)
		folder := this.settings.outputBaseFolder "\" name
		if IsSet(customJsonObj)
			data := customJsonObj
		else if FileExist(path := Format(this.settings.logFolder '\' this.TEMPLATES.METADATAFILE, name))
			data := MapToObj(jsongo.Parse(FileRead(path, "UTF-8")))
		else
			return print("There's nothing to check against")
		fields := arrayMerge(this.settings.metadataFields, ["link", "description"])
		for v in data
			for field in fields
				if !v.HasOwnProp(field)
					v.%field% := ""
		this.compareFolderToData(folder, callback, data, verifyMetadata, onlyReturnMismatches)
		
		callback(comparisons) {
			for e in comparisons { ; beautify these comparisons so that there aren't any monstrous strings in there
				if e.metadata {
					for field, val in e.metadata.OwnProps() {
						str1 := val.jsonValue
						str2 := val.fileValue
						if (StrLen(str1) > 100 || StrLen(str2) > 100) {
							diff := strLimitToDiffs(str1, str2,,,"")
							val.jsonValue := diff[1]
							val.fileValue := diff[2]
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
			if !comparisons.Length
				print("All data correct")
			print(qpc())
			return comparisons
		}
	}

	static removeMetadataDuplicates(foldertoCheck := this.settings.outputSubFolder) {
		SplitPath(folderToCheck, &name)
		folder := this.settings.outputBaseFolder "\" name
		if FileExist(path := Format(this.settings.logFolder '\' this.TEMPLATES.METADATAFILE, name))
			data := MapToObj(jsongo.Parse(FileRead(path, "UTF-8")))
		else
			return print("There's nothing to check against")
		fields := arrayMerge(this.settings.metadataFields, ["link", "description"])
		for v in data
			for field in fields
				if !v.HasOwnProp(field)
					v.%field% := ""
		duplicates := objGetDuplicates(data, v => this.getFileNameFromMetadata(v), false, true)
		print(objDoForEach(duplicates, v => objFromArrays(v, objDoForEach(v, q => this.getFileNameFromMetadata(data[q])))))
		queue := []
		for indices in duplicates {
			j := indices[1]
			for i, index in indices {
				if i == 1
					continue
				if objCompare(data[j], data[index])
					queue.push(index)
			}
		}
		queue := arraySortNumerically(queue, "N R")
		for e in queue
			data.RemoveAt(e)
		if queue.length {
			f := FileOpen(path, "w", "UTF-8")
			f.Write(toString(data, 0, 0, 1))
			f.close()
		}
	}
	
	static compareFolderToData(folder, retCallback, data, verifyMetadata := true, onlyReturnMismatches := true) {
		if verifyMetadata
			this.getMetadataFromFolder(folder, callback, 1)
		else
			callback(0)
		
		callback(folderMetadata) {
			SplitPath(folder, &name)
			folder := this.settings.outputBaseFolder "\" name
			comparisons := []
			expectedFiles := Map()
			expectedFiles.CaseSense := false
			if verifyMetadata {
				actualMetadata := Map()
				actualMetadata.CaseSense := false
				for v in folderMetadata
					actualMetadata[this.getFileNameFromMetadata(v)] := v
			}
			for i, dataPoint in data {
				fName := this.getFileNameFromMetadata(dataPoint,,,&irregular)
				o := {
					fileName: fName,
					index: i,
					specified: true,
					; exists: true,
					ext: 0,
					other: 0,
					metadata: 0
				}
				if (FileExist(folder "\" fName ".mp*")) {
					existingFiles := getFilesAsArr(folder "\" fName ".mp*", 'F')
					if existingFiles.Length > 1
						o.other := "Multiple Files Match: " toString(objflatten(existingFiles, v => v.ext))
					o.ext := existingFiles[1].ext
					o.exists := true
					if expectedFiles.Has(fName) {
						comparisons[expectedFiles[fName]].other := (comparisons[expectedFiles[fName]].other ? comparisons[expectedFiles[fName]].other ", " : "") "Duplicate"
						o.other := (o.other ? o.other ", " : "") "Duplicate"
					} else {
						expectedFiles[fName] := i
						o.metadata := verifyMetadata ? this.compareMetadata(dataPoint, actualMetadata[fName]): 0
					}
					f1 := dataPoint.HasOwnProp("filename") ? dataPoint.filename : ""
					f2 := actualMetadata[fName].HasOwnProp("filename") ? actualMetadata[fName].filename : ""
					if f2 == "" && f1
						o.other := (o.other ? o.other ", " : "") "Unnecessary Filename marked: " f1
					if f1 == "" && f2
						o.other := (o.other ? o.other ", " : "") 'Irregular Filename not marked: Filename "' f2 '", Metadata "' fName '"'
				} else {
					expectedFiles[fName] := 0
					o.exists := false
				}
				if irregular
					o.other := (o.other ? o.other ", " : "") "Irregular Filename not marked: Metadata is `"" dataPoint.artist " - " dataPoint.title "`""
				comparisons.push(o)
			}
			for f in getFolderAsArr(folder,,,0) {
				o := {	fileName: f.name,
						; specified: 0,
						exists: true,
						ext: f.ext,
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
				retCallback(objFilter(comparisons, (k,v) => !v.exists || !v.specified || v.metadata || v.other))
			else
				retCallback(comparisons)
		}
	}

	static compareMetadata(m1, m2) {
		static fields := ["artist", "title", "album", "genre", "description", "link"]
		c := {}
		for key in fields {
			if m1.%key% == m2.%key%
				continue
			c.%key% := { jsonValue: m1.%key%, fileValue: m2.%key% }
		}
		if ObjOwnPropCount(c)
			return c
		return 0
	}

	static writeMetadataFromFile(folder, filepath, index) {
		SplitPath(folder, &name)
		this.getMetadataFromFile(filepath, callback)

		callback(metadata) {
			path := this.settings.logFolder "\" Format(this.TEMPLATES.METADATAFILE, name)
			if FileExist(path) {
				curData := jsongo.Parse(FileRead(path, "UTF-8"))
				curData[index] := metadata
			} else {
				curData := [metadata]
			}
			json := toString(curData, 0, 0, 1)
			f := FileOpen(path, 'w', 'UTF-8')
			f.Write(json)
			f.close()
		}
	}

	; this needs filepath because the new metadata might not match the old one (and thus have a different filename)
	static writeMetadataToFile(folder, filepath, index) {
		SplitPath(folder, &folderName)
		SplitPath(filepath, &fname)
		path := Format(this.settings.logFolder "\" this.TEMPLATES.METADATAFILE, folderName)
		metadata := MapToObj(jsongo.parse(FileRead(path, "UTF-8"))[index])
		this.editMetadata(filepath, metadata, "description", "link") ; manually add to edit description field
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