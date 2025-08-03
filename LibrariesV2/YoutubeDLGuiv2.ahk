/*
TODO SETTINGS:
Add Setting: 
- Hidden Launched Console Window
- --quiet flag
- worst quality option
- format option with proper choices


USE A LISTVIEW FOR [URL][TITLE][ARTIST][ALBUM][GENRE][IMAGEYESNO]
*/

#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\jsongo.ahk"

class YoutubeDLGuiv2 {
	ytdlGui(mode := "O") {
		mode := SubStr(mode, 1, 1)
		if (mode == "T")
			mode := (this.data.guiVisibility ? "H" : "O")
		if (this.gui) {
			if (mode == "C") {
				this.data.coords := WinUtilities.windowGetCoordinates(this.gui.Hwnd)
				this.gui.Destroy()
				this.resetGUI()
			}
			else if (mode == "H") {
				this.gui.Hide()
				this.data.guiVisibility := 0
			}
			else if (mode == "O") {
				this.gui.Show()
				this.data.guiVisibility := 1
			}
		}
		else if (mode == "O" || mode == "T") { ; if gui doesn't exist and mode = open/toggle, create
			this.guiCreate()
		}
	}

	__New(flagDebug := 0) {
		guiMenu := TrayMenu.submenus["GUIs"]
		guiMenu.Add("Open YoutubeDL Gui", (*) => this.ytdlGui())
		A_TrayMenu.Add("GUIs", guiMenu)
		; establish basic data necessary for handling
		this.data := {
			coords: {x: 750, y: 425},
			savePath: A_Appdata . "\Autohotkey\YTDL"
		}
		this.settingsManager(1)
		this.settings.debug := flagDebug
		this.controls := {}
		this.resetGUI()
	}

	guiCreate() {
		this.gui := Gui("+Border +OwnDialogs", "YoutubeDL Manager")
		this.gui.OnEvent("Escape", (*) => this.ytdlGui("Hide"))
		this.gui.OnEvent("Close", (*) => this.ytdlGui("Close"))
		this.gui.AddText("Center Section", "Enter Link(s) to download")
		this.controls.editInput := this.gui.AddEdit("ys+17 xs r3 w375")
		this.gui.AddCheckbox("vCheckboxConvertToAudio yp xs+383 Checked" . (this.settings.resetConverttoAudio ? 0 : this.options["extract-audio"].selected), "Convert to Audio?").OnEvent("Click", this.settingsHandler.bind(this))
		this.gui.AddCheckbox("vCheckboxUpdate Checked" this.options["update"].selected, "Update YoutubeDL Gui").OnEvent("Click", this.settingsHandler.bind(this))
		this.gui.AddButton("", "Settings").OnEvent("Click", this.settingsGUI.bind(this))
		this.gui.AddButton("", "Get Data").OnEvent("Click", (*) => this.getMetadata())
		this.gui.AddButton("", "Launch yt-dlp").OnEvent("Click", (*) => this.mainButton())
		this.controls.audioLV := this.gui.AddListview("")
		this.controls.editCmdConfig := this.gui.AddEdit("xs+1 r1 w500 -Multi Readonly", "")
		this.controls.editOutput := this.gui.AddEdit("xs+1 r13 w500 Multi Readonly")
		this.ytdlOptionHandler()
		this.gui.Show(Format("x{1}y{2} Autosize", this.data.coords.x, this.data.coords.y))
		this.data.guiVisibility := 1
	}

	ytdlOptionHandler(option := 0, select := -1, param := -1, updateGui := true) {
		if (option is Map) {
			for i, e in option
				this.options[i].selected := e
		}
		else if (option is Array) {
			if (select != -1) { ; set all options in array to given selection
				for i, e in option
					this.options[e].selected := select
			}
			else { ; toggle all given options
				for i, e in option
					this.options[e].selected := !this.options[e].selected
			}
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
				str .= (this.settings.useAliases && e.HasOwnProp("alias") ? e.alias ' ' : '--' i ' ') . (e.HasOwnProp("param") ? '"' . e.param . '" ' : '')
		if (updateGui)
			this.controls.editCmdConfig.value := str
	}

	settingsHandler(ctrlObject := 0, *) {
		switch ctrlObject.Name {
			case "CheckboxConvertToAudio":
				if (this.settings.ffmpegPath == "") {
					ctrlObject.Value := 0
					Msgbox("Please choose FFmpeg.exe location first.")
					this.settingsGUI()
					return
				}
				this.ytdlOptionHandler(["extract-audio", "audio-quality", "audio-format"])
				this.ytdlOptionHandler("format", , (this.options["extract-audio"].selected ? "bestaudio/best" : "bestvideo[height<=1080]+bestaudio/best"))
			case "CheckboxResetConvertToAudio":
				this.settings.resetConverttoAudio := !this.settings.resetConverttoAudio
			case "CheckboxDownloadPlaylist":
				this.ytdlOptionHandler("no-playlist")
			case "CheckboxUpdate":
				this.ytdlOptionHandler("update")
			case "CheckboxUseAliases":
				this.settings.useAliases := !this.settings.useAliases
				this.ytdlOptionHandler()
			case "CheckboxOpenExplorer":
				this.settings.openExplorer := !this.settings.openExplorer
			case "CheckboxTrySelectFile":
				this.settings.trySelectFile := !this.settings.trySelectFile
			case "ButtonOutputPath":
				folderP := FileSelect("D3", this.settings.outputPath, "Please select a folder")
				if (folderP != "") {
					this.settings.outputPath := RegexReplace(folderP, "\\$")
					this.controls.editOutputPath.value := folderP
					this.settings.outputPattern := this.settings.outputPath . "\%(title)s.%(ext)s"
					this.ytdlOptionHandler("output", , this.settings.outputPattern)
				}
			case "ButtonFFmpegPath":
				fileP := FileSelect(3, this.settings.ffmpegPath, "Choose ffmpeg.exe", "Executables (*.exe)")
				if (fileP != "") {
					this.settings.ffmpegPath := fileP
					this.controls.editFFmpegPath.value := fileP
					this.ytdlOptionHandler("ffmpeg-location", , fileP)
				}
			case "ButtonYTDLPath":
				fileP := FileSelect(3, this.settings.ytdlPath, "Choose youtube-dl .exe file", "Executables (*.exe)")
				if (fileP != "") {
					this.settings.ytdlPath := fileP
					this.controls.editYTDLPath.Value := fileP
					this.ytdlOptionHandler() ; just updates the thing
				}
			default:
				return
		}
		this.settingsManager()
	}

	mainButton() {
		links := this.controls.editInput.Value
		if (this.settings.ytdlPath == "") {
			Msgbox("Please set YoutubeDL path.")
			this.settingsGUI()
			return
		}
		this.ytdlOptionHandler()
		fullRuncmd := this.controls.editCmdConfig.value . StrReplace(links, "`n", A_Space)
		for i, link in StrSplitUTF8(links, "`n") {
			fullRuncmd := this.controls.editCmdConfig.value . '"' link '"'
			if (this.settings.runHidden) {
				output := cmdRet(fullRuncmd, , "UTF-8")
				this.controls.editOutput.value .= output "`n"
			}
			else
				RunWait(fullRuncmd)
		}
		Msgbox("pog downloaded")
	}

	getMetadata() {
		return
	}

	settingsGUI(*) {
		settingsGui := Gui("+Border +OwnDialogs +Owner" . this.gui.Hwnd, "Settings")
		this.gui.Opt("+Disabled")
		settingsGui.OnEvent("Escape", settingsGUIClose)
		settingsGui.OnEvent("Close", settingsGUIClose)
		settingsGui.OnEvent("DropFiles", settingsGUIDropFiles)
		settingsGui.AddText("Center Section", "Settings for YoutubeDL Gui")
		settingsGui.AddCheckbox("vCheckboxUseAliases Checked" this.settings.useAliases, "Use aliases for arguments").OnEvent("Click", this.settingsHandler.bind(this))
		settingsGui.AddCheckbox("vCheckboxDownloadPlaylist Checked" . !this.options["no-playlist"].selected, "Download playlist?").OnEvent("Click", this.settingsHandler.bind(this))
		settingsGui.AddCheckbox("vCheckboxOpenExplorer Checked" this.settings.openExplorer, "Open Explorer after download").OnEvent("Click", this.settingsHandler.bind(this))
		settingsGui.AddCheckbox("vCheckboxTrySelectFile Checked" this.settings.trySelectFile, "Try Selecting File When Opening Explorer (Experimental)").OnEvent("Click", this.settingsHandler.bind(this))
		settingsGui.AddCheckbox("vCheckboxResetConvertToAudio Checked" this.settings.resetConverttoAudio, "Always Start with `"Convert To Audio`" Off").OnEvent("Click", this.settingsHandler.bind(this))

		settingsGui.AddText("xs 0x200 R1.45", "Output Path:")
		this.controls.editOutputPath := settingsGui.AddEdit("xp+70 yp r1 w250 -Multi Readonly", this.settings.outputPath)
		settingsGui.AddButton("vButtonOutputPath yp-1 xp+255", "Browse...").OnEvent("Click", this.settingsHandler.bind(this))
		settingsGui.AddText("xs", "FFMpeg Path:")
		this.controls.editFFmpegPath := settingsGui.AddEdit("yp-3 xp+70 r1 w250 -Multi Readonly", this.settings.ffmpegPath)
		settingsGui.AddButton("vButtonFFmpegPath yp-1 xp+255", "Browse...").OnEvent("Click", this.settingsHandler.bind(this))
		settingsGui.AddText("xs", "YTDL Path:")
		this.controls.editYTDLPath := settingsGui.AddEdit("yp-3 xp+70 r1 w250 -Multi Readonly", this.settings.ytdlPath)
		settingsGui.AddButton("vButtonYTDLPath yp-1 xp+255", "Browse...").OnEvent("Click", this.settingsHandler.bind(this))
		settingsGui.AddButton("xs-1", "Reset Settings").OnEvent("Click", resetSettings)
		settingsGui.Show(Format("x{1}y{2} Autosize", this.data.coords.x + 20, this.data.coords.y + 20))

		resetSettings(*) {
			if (MsgBox("Are you sure? This will reset all settings to their default values.", "Reset Settings", "0x1") == "Cancel")
				return
			this.settings := YoutubeDLGuiv2.getDefaultSettings()
			this.options := YoutubeDLGuiv2.getOptions()
			this.settings.options := this.options
			this.ytdlOptionHandler()
			settingsGUIClose()
			this.settingsGUI()
			this.gui["CheckboxConvertToAudio"].Value := 0
			this.gui["CheckboxUpdate"].Value := 0
			this.settingsManager()
		}

		settingsGUIClose(*) {
			this.gui.Opt("-Disabled")
			settingsGui.Destroy()
		}

		settingsGUIDropFiles(guiObj, guiCtrlObj, fileArray, x, y) {
			for i, fileP in fileArray {
				if (RegexMatch(fileP, ".*\\(?:youtube-dl|yt-dlp)\.exe$")) {
					this.settings.ytdlPath := fileP
					this.controls.editYTDLPath.Value := fileP
					this.ytdlOptionHandler() ; just updates the thing
				}
				else if (RegExMatch(fileP, ".*\\ffmpeg\.exe$")) {
					this.settings.ffmpegPath := fileP
					this.controls.editFFmpegPath.value := fileP
					this.ytdlOptionHandler("ffmpeg-location", , fileP)
				}
				else if (InStr(FileExist(fileP), "D")) {
					this.settings.outputPath := RegexReplace(fileP, "\\$")
					this.controls.editOutputPath.value := fileP
					this.settings.outputPattern := this.settings.outputPath . "\%(title)s.%(ext)s"
					this.ytdlOptionHandler("output", , this.settings.outputPattern)
				}
			}
			this.settingsManager()
		}
	}

	resetGUI() {
		if (this.settings.resetConverttoAudio) {
			this.ytdlOptionHandler(["extract-audio", "audio-quality", "audio-format"], false, , false)
			this.ytdlOptionHandler("format", , "bestvideo[height<=1080]+bestaudio/best", false)
		}
		this.data.guiVisibility := 0
		this.gui := 0
	}

	settingsManager(mode := "Save") {
		mode := StrUpper(Substr(mode, 1, 1))
		if (!Instr(FileExist(this.data.savePath), "D"))
			DirCreate(this.data.savePath)
		if (mode == "S") {
			f := FileOpen(this.data.savePath . "\ahk_settings.json", "w", "UTF-8")
			f.Write(jsongo.Stringify(this.settings))
			f.Close()
			return 1
		}
		else if (mode == "L") {
			this.settings := {}
			if (FileExist(this.data.savePath "\ahk_settings.json")) {
				s := FileRead(this.data.savePath "\ahk_settings.json", "UTF-8")
				try this.settings := jsongo.Parse(s)
			}
			this.settings := MapToObj(this.settings, true)
			for i, e in YoutubeDLGuiv2.getDefaultSettings().OwnProps() {
				if !(this.settings.HasOwnProp(i))
					this.settings.%i% := e
			}
			this.options := Map()
			for i, e in YoutubeDLGuiv2.getOptions() {
				this.options[i] := (this.settings.options.HasOwnProp(i) ? this.settings.options.%i% : e)
			}
			this.settings.options := this.options
			; maybe [,"ignore-config","no-playlist","retries"]
			return 1
		}
		return 0
	}

	static getDefaultSettings() {
		settings := {
			resetConverttoAudio: 1,
			useAliases: 0,
			openExplorer: 1,
			trySelectFile: 0,
			runHidden: 0,
			runQuiet: 0,
			outputPath: A_ScriptDir,
			outputPattern: A_ScriptDir . "\%(title)s.%(ext)s",
			ffmpegPath: "",
			ytdlPath: "",
			debug: 0,
			options: {} ; options as object since json saves and loads them as object anyway
		}
		return settings
	}

	static getOptions() {
		youtubeDLOptions := Map()
		; General and Meta Options
		youtubeDLOptions["ignore-config"] := {}
		youtubeDLOptions["update"] := { alias: "-U" }
		youtubeDLOptions["simulate"] := { alias: "-s" }
		youtubeDLOptions["list-formats"] := { alias: "-F" }
		youtubeDLOptions["print-traffic"] := {}
		youtubeDLOptions["newline"] := {}
		youtubeDLOptions["print"] := { param: "after_move:filepath" }
		youtubeDLOptions["no-warning"] := {}
		; Downloading Options
		youtubeDLOptions["output"] := { alias: "-o", param: A_ScriptDir . "\%(title)s.%(ext)s" }
		youtubeDLOptions["no-overwrites"] := { alias: "-w" }
		youtubeDLOptions["force-overwrites"] := {}
		youtubeDLOptions["no-playlist"] := {}
		youtubeDLOptions["retries"] := { alias: "-R", param: 1 }
		youtubeDLOptions["restrict-filenames"] := {}
		youtubeDLOptions["limit-rate"] := { alias: "-r", param: "5M" }
		youtubeDLOptions["format"] := { alias: "-f", param: "bestvideo[height<=1080]+bestaudio/best" }
		; Extra Data Options
		youtubeDLOptions["skip-download"] := {}
		youtubeDLOptions["write-description"] := {}
		youtubeDLOptions["write-info-json"] := {}
		youtubeDLOptions["write-comments"] := {}
		youtubeDLOptions["write-thumbnail"] := {}
		youtubeDLOptions["write-subs"] := {}
		; Authentification Options
		youtubeDLOptions["username"] := { alias: "-u", param: "" }
		youtubeDLOptions["password"] := { alias: "-p", param: "" }
		youtubeDLOptions["twofactor"] := { alias: "-2", param: "" }
		; Post-Processing Options
		youtubeDLOptions["ffmpeg-location"] := { param: "" }
		youtubeDLOptions["extract-audio"] := { alias: "-x" }
		youtubeDLOptions["audio-quality"] := { param: 0 }
		youtubeDLOptions["audio-format"] := { param: "mp3" }
		youtubeDLOptions["merge-output-format"] := { param: "mp4" }
		youtubeDLOptions["embed-subs"] := {}
		youtubeDLOptions["embed-thumbnail"] := {}
		youtubeDLOptions["embed-metadata"] := {}
		youtubeDLOptions["parse-metadata"] := { param: "" }
		youtubeDLOptions["convert-thumbnails"] := { param: "jpg" }
		for i, e in youtubeDLOptions
			youtubeDLOptions[i].selected := false
		for i, e in ["ignore-config", "output", "no-overwrites", "no-playlist", "retries", "limit-rate", "format", "ffmpeg-location", "merge-output-format", "no-warning", "print"]
			youtubeDLOptions[e].selected := true
		return youtubeDLOptions
	}

}