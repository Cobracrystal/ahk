#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"

; todo: for nightcore, match original song from description (we have title and know its nightcore - title, so search in description for artist etc)
; todo: split videos via chapters
; todo for profile adjusting: function that compares objects deeply, then remove the ones that match
; a much simpler class than youtubeDL to instantly download music
if (A_LineFile == A_ScriptFullPath) {
	SongDownloader.downloadSong("https://www.youtube.com/watch?v=KH89fk-0qks")
	; SongDownloader.downloadSong("https://www.youtube.com/watch?v=MzsBwcXkghQ")
	; SongDownloader.downloadSong("Never Gonna Give You Up")
	; SongDownloader.downloadSong("https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=WL&index=3&pp=gAQBiAQB")
}
class SongDownloader {

	static __New() {
		this.data := {
			coords: {x: 750, y: 425},
			commandLineString: ""
		}
		this.settings := {
			useInlineConsole: 1,
			useAliases: 1,
			launchHidden: 1,
			keepOpen: 1,
			openExplorer: 1,
			trySelectFile: 0,
			currentTodo: 70,
			outputBaseFolder: "C:\Users\Simon\Music\Collections",
			outputSubFolder: "p001",
			ffmpegPath: "C:\Users\Simon\Music\ConvertMusic\ytdl\ffmpeg.exe",
			ytdlPath: "C:\Users\Simon\Music\ConvertMusic\ytdl\yt-dlp.exe",
		}
		this.settings.outputSubFolder := Format("p{:03}", this.settings.currentTodo)
	}

	static downloadSong(songLink) {
		songLink := this.constructLink(songLink)
		ToolTip("Loading Metadata...")
		metaData := this.getMetaData(songLink,, false)
		ToolTip()
		if !metaData
			return 0
		this.songDLGui(metaData)
	}

	static downloadFromJson(jsonAsStr, outputSubFolder := this.settings.outputSubFolder, embedThumbnail := true) {
		data := MapToObj(jsongo.Parse(jsonAsStr))
		for i, dataPoint in data {
			profile := this.PROFILE_MUSIC[this.constructParseMetadataString(dataPoint), this.constructOutputPatternString(dataPoint), outputSubFolder]
			str .= this.launchYTDL(profile, dataPoint.link, this.settings.launchHidden, true) "`n==============================`n"
		}
		return str
	}
	
	static getMetadataJson(songLinks) {
		return objToString(SongDownloader.getMetaData(songLinks, false),false,false,true,true)
	}

	static getMetaData(songLink, keepJsonData := true, printIntermediateSteps := false) {
		if !(songLink is Array)
			songLink := StrSplitUTF8(Trim(songLink, "`n`r"), "`n", "`r")
		songLink := objDoForEach(songLink, (e => this.constructLink(e)))
		linkString := objCollect(songLink, (b, i) => (b . '"' i '" '), "")
		command := this.cmdStringBuilder(this.PROFILE_GETMETADATA[printIntermediateSteps]) . linkString
		fn := (sOutPut) => (RegExMatch(SubStr(sOutPut, 1, 20), "^\[[[:alnum:]]+\]") ? timedTooltip(SubStr(sOutPut, 1, 40)) : 0)
		fullOutputStr := Trim(cmdRet(command, printIntermediateSteps ? fn : unset), " `t`r`n")
		metaData := []
		Loop Parse fullOutputStr, "`n", "`r" {
			if (printIntermediateSteps && RegExMatch(SubStr(A_LoopField, 1, 20), "^\[[[:alnum:]]+\]"))
				continue
			jsonStr := A_LoopField
			try	
				videoData := jsongo.parse(jsonStr)
			catch 
				return songLink.Length > 1 ? 0 : MsgBoxAsGui("Failed to get Metadata. Aborting. Copy Response?",,0x1,,, (response) => (response == "Copy" ? A_Clipboard := fullOutputStr : 0),A_ScriptHwnd,,["Copy", "Exit"])
			title := videoData.Has("track") ? videoData["track"] : videoData["title"]
			artist := videoData.Has("artists") ? objCollect(videoData["artists"], (a,b) => a ", " b) : (videoData.Has("creator") ? videoData["creator"] : videoData["uploader"])
			album := videoData.Has("album") ? videoData["album"] : ""
			genre := ""
			; A_Clipboard := objToString(videoData, 0, 0, 1, 1)
			if (InStr(title, "Nightcore")) {
				if RegExMatch(title, "i)Nightcore\s*-\s*")
					title := RegExReplace(title, "i)\s*Nightcore\s*-\s*")
				else
					title := RegExReplace(title, "\(\s*Nightcore\s*\)")
				genre := "Nightcore"
				album := "Nightcore"
			}
			if (pos := InStr(title, " - ")) {
				artist := StrLen(artist) > 1 ? artist : Trim(SubStr(title, 1, pos))
				title := SubStr(title, pos+3)
			}
			if (RegExMatch(title, "\s*\(\s*(?:feat|ft)\.?\s*(.*?)\)", &o)) {
				title := RegExReplace(title, "\s*\(\s*(?:feat|ft)\.?\s*.*?\)")
				artist .= " ft " o[1]
			} else if (RegExMatch(title, "(?:feat|ft)\.?\s+(.*)$", &o)) {
				title := RegExReplace(title, "\s*(?:feat|ft)\.?\s+(.*)$")
				artist .= " ft " o[1]
			}
			objRemoveValues(videoData, ["automatic_captions", "formats", "heatmap", "requested_formats", "thumbnails", "subtitles"],,(i,e,v) => (i=v),"MANUALLY REMOVED")
			metaData.push({
				input: songLink[A_Index],
				link: this.constructLink(videoData["id"]),
				title: title,
				artist: artist,
				album: album,
				genre: genre,
				description: videoData["description"],
				shortJson: keepJsonData ? videoData : unset
			})
		}
		if (metaData.Length == 1)
			metaData := metaData[1]
		return metaData
	}

	static songDLGui(data) {
		g := Gui("+Border +OwnDialogs", "Download Song")
		g.OnEvent("Escape", this.finishGui.bind(this))
		g.OnEvent("Close", (*) => g.Destroy())
		g.AddText("Section 0x200 R1.45", "Links | Current Folder: " )
		g.AddEdit("xs+110 ys R1 w30 vOutputFolder", (subOutputFolder := this.settings.outputSubFolder)).OnEvent("Change", adjustCMDField)
		if data.description
			g.AddButton("xs+151 vButtonDescription ys-1 w100", "Show Description").OnEvent("Click", (*) => MsgBoxAsGui(data.description, "Video Description",,0,,,g.hwnd,1,,,,,1200))
		g.AddEdit("xs w250 R1 ReadOnly vLink", data.link)
		g["Link"].Focus()
		g.AddText("0x200 R1.45", "Title")
		g.AddButton("xs+151 yp-1 w100", "Show Full Json").OnEvent("Click", (*) => MsgBoxAsGui(objToString(data.shortJson,0,0,1), "JSON",,0,,,g.hwnd,1,,,,800, 1200))
		g.AddEdit("xs w250 vTitle", data.title).OnEvent("Change", adjustCMDField)
		g.AddText("", "Artist")
		g.AddEdit("w250 vArtist", data.artist).OnEvent("Change", adjustCMDField)
		g.AddText("", "Album")
		g.AddEdit("w250 vAlbum", data.album).OnEvent("Change", adjustCMDField)
		g.AddText("", "Genre")
		g.AddEdit("w250 vGenre", data.genre).OnEvent("Change", adjustCMDField)
		g.AddCheckbox("vEmbedThumbnail Checked1", "Embed Thumbnail").OnEvent("Click", adjustCMDField)
		g.AddCheckbox("yp vLaunchHidden Checked" this.settings.launchHidden, "Launch Hidden")
		g.AddText("xs", "Current Command Line")
		profile := this.PROFILE_MUSIC[
			this.constructParseMetadataString(data),
			this.constructOutputPatternString(data),
			subOutputFolder
		]
		g.AddEdit("vCMD w250 R1 Readonly", this.cmdStringBuilder(profile) '"' data.link '"')
		g.AddButton("xs-1 h30 w251 Default", "Launch yt-dlp").OnEvent("Click", this.finishGui.bind(this))
		g.Show(Format("x{1}y{2} Autosize", this.data.coords.x, this.data.coords.y))

		; this is entirely for copying purposes
		adjustCMDField(guiCtrlObj, info?) {
			name := guiCtrlObj.Name
			val := guiCtrlObj.Value
			switch name {
				case "Title", "Artist", "Album", "Genre":
					rem := [{ option: this.options.output, param: this.constructOutputPatternString(data)},
							{ option: this.options.output, param: this.constructOutputPatternString(data)}]
					data.%name% := val
					add := [{ option: this.options.output, param: this.constructOutputPatternString(data)},
							{ option: this.options.output, param: this.constructOutputPatternString(data)}]
					profile := this.addRemoveProfile(profile, rem, add, true, true)
				case "OutputFolder":
					rem := [{ option: this.options.paths, param: this.settings.outputBaseFolder "\" subOutputFolder }]
					add := [{ option: this.options.paths, param: this.settings.outputBaseFolder "\" val }]
					subOutputFolder := val
					profile := this.addRemoveProfile(profile, rem, add, true, true)
				case "EmbedThumbnail":
					toggleProfile := [	{ option: this.options.embed_thumbnail },
										{ option: this.options.convert_thumbnail, param: "jpg" },
										{ option: this.options.postprocessor_args, param: 'ThumbnailsConvertor+FFmpeg_o:-c:v mjpeg -qmin 1 -qscale:v 1 -vf crop=\"min(iw\,ih)\":\"min(iw\,ih)\"' }]
					profile := this.toggleProfile(profile, toggleProfile)
			}
			g["CMD"].Value := this.cmdStringBuilder(profile) '"' data.link '"'
		}
	}


	static finishGui(g, info?) {
		if (g is Gui.Button)
			g := g.gui
		songData := {
			title: g["Title"].Value, artist: g["Artist"].Value,
			album: g["Album"].Value, genre: g["Genre"].Value
		}
		link := g["Link"].Value
		launchHidden := g["LaunchHidden"].Value
		outputSubFolder := g["OutputFolder"].Value
		embedThumbnail := g["EmbedThumbnail"].Value
		g.destroy()
		profile := this.PROFILE_MUSIC[
			this.constructParseMetadataString(songData),
			this.constructOutputPatternString(songData),
			outputSubFolder
		]
		this.launchYTDL(profile, link, launchHidden, false)
	}

	static launchYTDL(profile, link, runHidden, runAsync := true, logFolder?) {
		profile := this.toggleProfile(profile, this.PROFILE_SPLIT_CHAPTERS)
		fullCommand := this.cmdStringBuilder(profile) . '"' link '"'
		if (runHidden) {
			if (runAsync) {
				Run(A_ComSpec " /c title SongDownloader && " fullCommand,,'Hide')
				return
			} else {
				output := strMultiply("=", 20) . cmdRet(fullCommand) . '`n'
				FileAppend(output, logFolder ?? this.settings.outputBaseFolder "\log.txt", "UTF-8")
				return output
			}
		}
		conOptions := "title SongDownloader && mode con: cols=100 lines=30"
		if (this.settings.keepOpen)
			Run(A_ComSpec " /k " conOptions " && echo " fullCommand " && " fullCommand,,'Hide', &cmdPID)
		else
			Run(A_ComSpec " /c " conOptions " && " fullCommand,, 'Hide', &cmdPID)
		ProcessWait(cmdPID)
		Sleep(500)
		WinShow("ahk_pid " cmdPID)
	}

	static cmdStringBuilder(profile, useAliases := false) {
		if !(profile is Array)
			throw(TypeError("cmdStringBuilder given " Type(profile) " instead of Array.",,objToString(profile)))
		str := '"' this.settings.ytdlPath '"' A_Space
		for set in profile {
			str .= (useAliases && set.option.has("alias") ? set.option.alias : set.option.name) . A_Space . (set.option.param ?  '"' set.param '"' A_Space : '')
		}
		return str
	}

	static constructLink(input) {
		input := RegExReplace(input, "music\.youtube", "youtube")
		if (RegExMatch(input, "youtube\.com\/watch\?v=([A-Za-z0-9_-]{11})", &o))
			input := "https://youtube.com/watch?v=" . o[1]
		if (RegExMatch(input, "^[A-Za-z0-9_-]{11}$"))
			input := "https://youtube.com/watch?v=" . input
		return input
	}

	static constructOutputPatternString(songData) {
		title := songData.title ? songData.title : this.TEMPLATE.TITLE
		artist := songData.artist ? songData.artist : this.TEMPLATE.ARTIST
		return artist " - " title "." this.TEMPLATE.EXT
	}

	static constructParseMetadataString(songData) {
		arr := []
		str1 := "##"
		str2 := "##"
		for fieldName in ["title", "artist", "album", "genre"] {
			if (songData.%fieldName%) {
				str1 .= songData.%fieldName% '##'
				str2 .= "%(meta_" fieldName ")s##"
			}
		}
		return str1 ":" str2
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
		nProfile := profile.clone()
		lambda := (k, v, v2) => (objCompare(v.option, v2.option))
		paramLambda := (k, v, v2) => (objCompare(v, v2))
		if (inplace) {
			if (profileToRemove.Length != profileToAdd.Length)
				throw(ValueError("Given Arrays have different Lengths"))
			for e, f in objZip(profileToRemove, profileToAdd)
				objRemoveValue(nProfile, e,, paramCompare ? paramLambda : lambda, f)
		} else {
			objRemoveValues(nProfile, profileToRemove,, paramCompare ? paramLambda : lambda)
			for i, e in (profileToAdd)
				nProfile.push(e)
		}
		return nProfile
	}

	static PROFILE_MUSIC[metadata_parser, outputTemplate, outputSubFolder] => [
		{ option: this.options.parse_metadata, param: metadata_parser },
		{ option: this.options.embed_metadata },
		{ option: this.options.embed_thumbnail },
		{ option: this.options.convert_thumbnail, param: "jpg" },
		{ option: this.options.postprocessor_args, param: 'ThumbnailsConvertor+FFmpeg_o:-c:v mjpeg -qmin 1 -qscale:v 1 -vf crop=\"min(iw\,ih)\":\"min(iw\,ih)\"' },
		{ option: this.options.ignore_config },
		{ option: this.options.output, param: outputTemplate},
		{ option: this.options.paths, param: "temp:C:\Users\Simon\AppData\Roaming\yt-dlp\temp"},
		{ option: this.options.paths, param: this.settings.outputBaseFolder "\" outputSubFolder},
		{ option: this.options.no_overwrites },
		{ option: this.options.no_playlist },
		{ option: this.options.no_vid },
		{ option: this.options.retries, param: 1 },
		{ option: this.options.limit_rate, param: "5M" },
		{ option: this.options.format, param: "bestaudio/best" },
		{ option: this.options.ffmpeg_location, param: this.settings.ffmpegPath },
		{ option: this.options.no_warning },
		{ option: this.options.print, param: "after_move:filepath" },
		{ option: this.options.extract_audio },
		{ option: this.options.audio_quality, param: 0},
		{ option: this.options.audio_format, param: "mp3"}
	]

	static PROFILE_SPLIT_CHAPTERS => [
		{ option: this.options.split_chapters },
		{ option: this.options.output, param: "chapter:%(meta_artist)s - " this.TEMPLATE.SECTION_TITLE "." this.TEMPLATE.EXT },
		{ option: this.options.parse_metadata, param: "%(chapter_number)s:%(meta_disc)s" },
		{ option: this.options.force_keyframes_at_cuts }
	]

	static PROFILE_GETMETADATA[with_intermediate_steps] {
		get {
			a := [
				{ option: this.options.ignore_config }, 
				{ option: this.options.default_search, param: "ytsearch" }, 
				{ option: this.options.no_playlist }, 
				{ option: this.options.skip_download }, 
				{ option: this.options.write_info_json }, 
				{ option: this.options.dump_json }
			]
			if (with_intermediate_steps)
				a.push({ option: this.options.verbose })
			return a
		}
	}

	static options => {
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
		no_warning: { name: "--no-warning", param: false },
		print: { name: "--print",  param: true }
	}

	static TEMPLATE => {
		EXT: "%(ext)s",
		ARTIST: "%(uploader)s",
		TITLE: "%(title)s",
		SECTION_TITLE: "%(section_title)s"
	}
}