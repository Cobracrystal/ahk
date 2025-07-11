#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"

; todo: for nightcore, match original song from description (we have title and know its nightcore - title, so search in description for artist etc)
; a much simpler class than youtubeDL to instantly download music
SongDownloader.downloadSong("https://www.youtube.com/watch?v=P-TPx8lcoZ4&list=WL&index=3&pp=gAQBiAQB")
class SongDownloader {
	
	static __New() {
		this.data := {
			coords: {x: 750, y: 425},
			commandLineString: ""
		}
		this.settings := {
			useInlineConsole: 1,
			useAliases: 1,
			runHidden: 0,
			keepOpen: 1,
			openExplorer: 1,
			trySelectFile: 0,
			currentTodo: 70,
			outputBaseFolder: "C:\Users\Simon\Music\Collections",
			ffmpegPath: "C:\Users\Simon\Music\ConvertMusic\ytdl\ffmpeg.exe",
			ytdlPath: "C:\Users\Simon\Music\ConvertMusic\ytdl\yt-dlp.exe",
		}
		this.options := this.getOptions()
	}

	static downloadSong(songLink) {
		songLink := RegExReplace(songLink, "music\.youtube", "youtube")
		if (RegExMatch(songLink, "youtube\.com\/watch\?v=([A-Za-z0-9_-]{11})", &o))
			songLink := "https://youtube.com/watch?v=" . o[1]
		if (RegExMatch(songLink, "^[A-Za-z0-9_-]{11}$"))
			songLink := "https://youtube.com/watch?v=" . songLink
		timedTooltip("Loading Metadata...")
		firstMetadata := this.getMetaData(songLink)
		this.songDLGui(firstMetadata)
	}

	static getMetaData(songLink) {
		command := '"' this.settings.ytdlPath '" --ignore-config --no-playlist --write-info-json --skip-download --dump-json ' . songLink
		fn := (sOutPut) => (timedTooltip(SubStr(sOutPut, 1, 40)))
		videoData := jsongo.parse(cmdRet(command, fn))
		title := videoData.Has("track") ? videoData["track"] : videoData["title"]
		artist := videoData.Has("artists") ? objCollect(videoData["artists"], (a,b) => a ", " b) : (videoData.Has("creator") ? videoData["creator"] : videoData["uploader"])
		album := videoData.Has("album") ? videoData["album"] : ""
		genre := ""
		if (InStr(title, "Nightcore")) {
			if RegExMatch(title, "i)Nightcore\s*-\s*") 
				title := RegExReplace(title, "i)Nightcore\s*-\s*")
			else
				title := RegExReplace(title, "\(\s*Nightcore\s*\)")
			genre := "Nightcore"
			album := "Nightcore"
		}
		if (pos := InStr(title, " - ")) {
			artist := StrLen(artist) > 1 ? artist : Trim(SubStr(title, 1, pos))
			title := SubStr(title, pos+3)
		}
		if (RegExMatch(title, "\((?:feat|ft)\.?\s*(.*?)\)", &o)) {
			title := RegExReplace(title, "\((?:feat|ft)\.?\s*.*?\)")
			artist .= " ft " o[1]
		} else if (RegExMatch(title, "(?:feat|ft)\.?\s+(.*)$")) {
			title := RegExReplace(title, "(?:feat|ft)\.?\s+(.*)$")
			artist .= " ft " o[1]
		}
		return  {
			link: songLink,
			title: title,
			artist: artist,
			album: album,
			genre: genre
		}
	}

	static songDLGui(data) {
		g := Gui("+Border +OwnDialogs", "Download Song")
		g.OnEvent("Escape", this.finishGui.bind(this))
		g.OnEvent("Close", (*) => g.Destroy())
		g.AddText("", "Links")
		g.AddEdit("w250 R1 vLink", data.link)
		g.AddText("", "Title")
		g.AddEdit("w250 vTitle", data.title)
		g.AddText("", "Artist")
		g.AddEdit("w250 vArtist", data.artist)
		g.AddText("", "Album")
		g.AddEdit("w250 vAlbum", data.album)
		g.AddText("", "Genre")
		g.AddEdit("w250 vGenre", data.genre)
		g.AddCheckbox("vEmbedThumbnail Checked1", "Embed Thumbnail").OnEvent("Click", (g, *) => (g.gui["CMD"].Value := this.cmdStringBuilder()))
		str := this.cmdStringBuilder()
		g.AddText("", "Current Command Line")
		g.AddEdit("vCMD w250 R1 Readonly", str)
		g.AddButton("xs-1 h35 w250 Default", "Launch yt-dlp").OnEvent("Click", this.finishGui.bind(this))
		g.Show(Format("x{1}y{2} Autosize", this.data.coords.x, this.data.coords.y))
	}
	

	static finishGui(g, info?) {
		if (g is Gui.Button)
			g := g.gui
		metadata := {
			link: g["Link"].Value,
			title: g["Title"].Value,
			artist: g["Artist"].Value,
			album: g["Album"].Value,
			genre: g["Genre"].Value,
		}
		cmd := g["CMD"].Value
		g.destroy()
		this.launchYTDL(cmd, metadata)
	}

	static launchYTDL(cmd, songData) {
		title := songData.title ? songData.title : this.TEMPLATE.TITLE
		artist := songData.artist ? songData.artist : this.TEMPLATE.ARTIST
		fileName := artist " - " title "." this.TEMPLATE.EXT
		folder := Format("{:03}", this.settings.currentTodo)
		cmd := StrReplace(cmd, "{REPLACE_TEMPLATE_OUTPUT_IDENTIFER}", folder "\" fileName)
		arr := []
		if (songData.title)
			arr.push([songData.title, '%(meta_title)s'])
		if (songData.artist)
			arr.push([songData.artist, '%(meta_artist)s'])
		if (songData.album)
			arr.push([songData.album, '%(meta_album)s'])
		if (songData.genre)
			arr.push([songData.genre, '%(meta_genre)s'])
		str1 := "##", str2 := "##"
		for e in arr
			str1 .= e[1] "##", str2 .= e[2] "##"
		cmd := StrReplace(cmd, "{REPLACE_TEMPLATE_METADATA_IDENTIFER}", str1 ":" str2)
		fullCommand := cmd . '"' songData.link '"'
		if (this.settings.runHidden)
			output := cmdRet(fullCommand, , "UTF-8")
		else if (this.settings.keepOpen)
			Run(A_ComSpec " /k mode con: cols=100 lines=30 && echo " fullCommand " && " fullCommand)
		else
			RunWait(A_ComSpec " /c mode con: cols=100 lines=30 && " fullCommand)
	}

	static cmdStringBuilder(option := 0, select := -1, param := -1) {
		if (option is Map)
			for i, e in option
				this.options[i].selected := e
		else if (option is Array) {
			if (select != -1) { ; set all options in array to given selection
				for i, e in option
					this.options[e].selected := select
			}
			else ; toggle all given options
				for i, e in option
					this.options[e].selected := !this.options[e].selected
		}
		else if (option != 0) { ; if option was given
			if (param == -1 && select == -1) ; if neither selection or param are given, toggle
				this.options[option].selected := !this.options[option].selected
			if (select != -1) ; set selection
				this.options[option].selected := select
			if (param != -1 && this.options[option].HasOwnProp("param")) ; change param if given
				this.options[option].param := param
		}
		str := '"' this.settings.ytdlPath '" '
		for i, e in this.options ; generate string for gui
			if (e.selected)
				str .= (this.settings.useAliases && e.HasOwnProp("alias") ? '-' e.alias ' ' : '--' i ' ') . (e.HasOwnProp("param") ? '"' . e.param . '" ' : '')
		return str
	}

	static getOptions() {
		youtubeDLOptions := Map()
		; General and Meta Options
		youtubeDLOptions["ignore-config"] := {}
		youtubeDLOptions["update"] := { alias: "U" }
		youtubeDLOptions["simulate"] := { alias: "s" }
		youtubeDLOptions["list-formats"] := { alias: "F" }
		youtubeDLOptions["print-traffic"] := {}
		youtubeDLOptions["newline"] := {}
		; Downloading Options
		youtubeDLOptions["output"] := { alias: "o", param: this.settings.outputBaseFolder "\{REPLACE_TEMPLATE_OUTPUT_IDENTIFER}" }
		youtubeDLOptions["no-overwrites"] := { alias: "w" }
		youtubeDLOptions["force-overwrites"] := {}
		youtubeDLOptions["no-playlist"] := {}
		youtubeDLOptions["retries"] := { alias: "R", param: 1 }
		youtubeDLOptions["restrict-filenames"] := {}
		youtubeDLOptions["limit-rate"] := { alias: "r", param: "5M" }
		youtubeDLOptions["format"] := { alias: "f", param: "bestaudio/best" }
		; Extra Data Options
		youtubeDLOptions["skip-download"] := {}
		youtubeDLOptions["write-description"] := {}
		youtubeDLOptions["write-info-json"] := {}
		youtubeDLOptions["write-comments"] := {}
		youtubeDLOptions["write-thumbnail"] := {}
		youtubeDLOptions["write-subs"] := {}
		; Authentification Options
		youtubeDLOptions["username"] := { alias: "u", param: "" }
		youtubeDLOptions["password"] := { alias: "p", param: "" }
		youtubeDLOptions["twofactor"] := { alias: "2", param: "" }
		; Post-Processing Options
		youtubeDLOptions["ffmpeg-location"] := { param: this.settings.ffmpegPath }
		youtubeDLOptions["extract-audio"] := { alias: "x" }
		youtubeDLOptions["audio-quality"] := { param: 0 }
		youtubeDLOptions["audio-format"] := { param: "mp3" }
		youtubeDLOptions["merge-output-format"] := { param: "mp4" }
		youtubeDLOptions["embed-subs"] := {}
		youtubeDLOptions["embed-thumbnail"] := {}
		youtubeDLOptions["embed-metadata"] := {}
		youtubeDLOptions["parse-metadata"] := { param: "{REPLACE_TEMPLATE_METADATA_IDENTIFER}" }
		youtubeDLOptions["convert-thumbnail"] := { param: "jpg" }
		youtubeDLOptions["postprocessor-args"] := { alias:"-ppa", param: 'ThumbnailsConvertor+FFmpeg_o:-c:v mjpeg -qmin 1 -qscale:v 1 -vf crop=\"min(iw\,ih)\":\"min(iw\,ih)\"' }
		youtubeDLOptions["no-warning"] := {}
		youtubeDLOptions["print"] := { param: "after_move:filepath" }
		for i, e in youtubeDLOptions
			youtubeDLOptions[i].selected := false
		for i, e in ["parse-metadata" , "embed-metadata", "embed-thumbnail", "convert-thumbnail", "postprocessor-args", "ignore-config", "output", "no-overwrites", "no-playlist", "retries", "limit-rate", "format", "ffmpeg-location", "merge-output-format", "no-warning", "print", "extract-audio", "audio-quality", "audio-format"]
			youtubeDLOptions[e].selected := true
		return youtubeDLOptions
	}

	static TEMPLATE => {
		EXT: "%(ext)s",
		ARTIST: "%(uploader)s",
		TITLE: "%(title)s"
	}
}