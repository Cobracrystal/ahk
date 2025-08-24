; https://github.com/cobracrystal/ahk

#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\ObjectUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\WinUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\jsongo.ahk"

class YoutubeDLGui {
	youtubeDLGui(mode := "O") {
		mode := SubStr(mode, 1, 1)
		if (mode == "T")
			mode := (this.data.guiVisibility ? "H" : "O")
		if (this.gui) {
			if (mode == "C") {
				this.data.coords := WinUtilities.getWindowPlacement(this.gui.Hwnd)
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
		guiMenu.Add("Open YoutubeDL Gui", (*) => this.youtubeDLGui())
		A_TrayMenu.Add("GUIs", guiMenu)
		; establish basic data necessary for handling
		this.data := {
			coords: {x: 750, y: 425},
			savePath: A_Appdata . "\Autohotkey\YTDL",
			output: "",
			outputLastLine: "",
			outputLastLineCFlag: 0,
		}
		this.settingsManager("Load")
		this.settings.debug := flagDebug
		this.controls := {}
		this.resetGUI()
	}

	guiCreate() {
		this.gui := Gui("+Border +OwnDialogs", "YoutubeDL Manager")
		this.gui.OnEvent("Escape", (*) => this.youtubeDLGui("Hide"))
		this.gui.OnEvent("Close", (*) => this.youtubeDLGui("Close"))
		this.gui.AddText("Center Section", "Enter Link(s) to download")
		this.controls.editInput := this.gui.AddEdit("ys+17 xs r7 w373")
		this.gui.AddCheckbox("vCheckboxConvertToAudio yp xs+383 Checked" . (this.settings.resetConverttoAudio ? 0 : this.options["extract-audio"].selected), "Convert to Audio?").OnEvent("Click", this.settingsHandler.bind(this))
		this.gui.AddCheckbox("vCheckboxUpdate Checked" this.options["update"].selected, "Update YoutubeDL Gui").OnEvent("Click", this.settingsHandler.bind(this))
		this.gui.AddButton("", "Settings").OnEvent("Click", this.settingsGUI.bind(this))
		this.gui.AddButton("xs-1 h35 w375 Default", "Launch yt-dlp").OnEvent("Click", (*) => this.mainButton())
		this.controls.editCmdConfig := this.gui.AddEdit("xs+1 r1 w500 -Multi Readonly", "")
		this.controls.editOutput := this.gui.AddEdit("xs+1 r13 w500 Multi Readonly")
		this.ytdlOptionHandler()
		this.gui.Show(Format("x{1}y{2} Autosize", this.data.coords.x, this.data.coords.y))
		this.data.guiVisibility := 1
	}

	updateGuiOutput(cmdLine) {
		static WM_VSCROLL := 0x115 
		static SB_BOTTOM  := 7
		lineArray := StrSplit(Rtrim(StrReplace(cmdLine, "`r`n", "`n"), "`n"), "`n")
		for i, newLine in lineArray {
			if (Instr(newLine, "https://") || Instr(newLine, "http://")) && !(Instr(this.data.outputLastLine, "[redirect]") || Instr(newLine, "[redirect]")) && (this.data.outputLastLine != "") && (this.data.outputLastLine != YoutubeDLGui.UIComponents.separator . "`n") {
				this.data.outputLastLine .= YoutubeDLGui.UIComponents.separatorSmall . "`n"
				this.data.outputLastLineCFlag := 0
			}
			; if not the last line, then there might be `r`n for the end, so remove that. StrSplit Trims on *both* sides, so it does not work (since `r at the start is necessary for overwriting lines)
			if (i != lineArray.Length)
				newLine := RTrim(newLine, "`r")
			StrReplace(newLine, "`r", "`r", , &carriageCount)
			if (carriageCount) { ; if `r in string, only take the last string part.
				tArr := StrSplit(newLine, "`r")
				newLine := tArr[-1]
			}
			; if current line AND previous line have `r, then overwrite prev line, otherwise save the line.
			if !(carriageCount && this.data.outputLastLineCFlag)
				this.data.output .= this.data.outputLastLine
			this.data.outputLastLine := newLine . "`n"
			this.data.outputLastLineCFlag := carriageCount
			; write saved output and current line to gui
			; pos := scrollbarGetPosition(this.controls.editOutput.Hwnd)
			this.controls.editOutput.value := this.data.output . this.data.outputLastLine
			; if (pos == 1) ; bottom
			SendMessage(WM_VSCROLL, SB_BOTTOM, 0, this.controls.editOutput.hwnd)
		}
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

	settingsHandler(ctrlObject, *) {
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
			case "CheckboxUseInlineConsole":
				this.settings.useInlineConsole := !this.settings.useInlineConsole
			case "CheckboxOnlyPrintFilename":
				this.ytdlOptionHandler("print")
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
				fileP := FileSelect("3", this.settings.ffmpegPath, "Choose ffmpeg.exe", "Executables (*.exe)")
				if (fileP != "") {
					this.settings.ffmpegPath := fileP
					this.controls.editFFmpegPath.value := fileP
					this.ytdlOptionHandler("ffmpeg-location", , fileP)
				}
			case "ButtonYTDLPath":
				fileP := FileSelect("3", this.settings.ytdlPath, "Choose youtube DL .exe file", "Executables (*.exe)")
				if (fileP != "") {
					this.settings.ytdlPath := fileP
					this.controls.editYTDLPath.Value := fileP
					this.ytdlOptionHandler() ; just updates the thing
				}
			default:
				return
		}
		this.settingsManager("Save")
	}

	mainButton() {
		links := this.controls.editInput.Value
		if (this.settings.ytdlPath == "") {
			Msgbox("Please set YoutubeDL path.")
			this.settingsGUI()
			return
		}
		this.ytdlOptionHandler()
		fullRuncmd := this.controls.editCmdConfig.value . "`"" StrReplace(Trim(links, " `t`n`r"), "`n", "`" `"") "`""
		if (this.settings.useInlineConsole) {
			cmdRetAsync(fullRuncmd, this.updateGuiOutput.bind(this), "UTF-8", 200, this.__done.bind(this, links))
		} else {
			A_Clipboard := fullRuncmd
;			Run("cmd /k `"mode con: cols=100 lines=30 && " fullRuncmd "`"")
		}
	}

	__done(links, fullOutput, status) {
		this.updateGuiOutput(YoutubeDLGui.UIComponents.separator)
		if (!WinActive(this.gui))
			this.YoutubeDLGui("Hide")
		if (links == "" || !this.settings.openExplorer)
			return
		if (this.settings.trySelectFile) {
			arrLong := StrSplit(fullOutput, YoutubeDLGui.UIComponents.separator)
			responseArr := StrSplit(arrLong[-1], YoutubeDLGui.UIComponents.separatorSmall)
			fileNames := []
			for i, e in responseArr
			{
				lineArr := StrSplit(RTrim(e, "`n"), "`n")
				regexM := StrReplace(this.settings.outputPath, "\", "\\") . "\\([[:ascii:]]*?\." . (this.options["extract-audio"].selected ? "mp3" : "mp4") . ")"
				for i, e in arrayInReverse(lineArr)
					if !(Instr(e, "Deleting")) && (RegexMatch(e, regexM, &o))
						break
				if (o != "")
					fileNames.push(o[1])
			}
			if (this.settings.debug)
				for i, e in fileNames
					this.updateGuiOutput(e)
			if (fileNames.Length == 0)
				return
			for oWin in ComObject("Shell.Application").Windows
				if (oWin.Name == "Explorer") && (this.settings.outputPath = oWin.Document.Folder.Self.Path) {
					WinActivate("ahk_id " . oWin.HWND)
					PostMessage(0x111, 28931, , , "ahk_id " . oWin.HWND) ; forcibly refresh ?
					oItems := oWin.Document.Folder.Items
					oWin.Document.SelectItem(oItems.Item(fileNames[-1]), 29)
					for i, e in fileNames
						oWin.Document.SelectItem(oItems.Item(e), 1)
					oWin := oItems := ""
					return
				}
		}
		if (WinExist(this.settings.outputPath . " ahk_exe explorer.exe"))
			WinActivate()
		else
			Run('explorer "' . this.settings.outputPath . (fileName ?? "") . (ext ?? "") '"')
		;	Run, % "explorer /select, """ . this.settings.outputPath . "\" . o.Value(1) . """" ; THIS IF THE INPUT IS ONLY ONE LINE (AKA ONE FILE)
	
	}

	settingsGUI(*) {
		settingsGui := Gui("+Border +OwnDialogs +Owner" . this.gui.Hwnd, "Settings")
		this.gui.Opt("+Disabled")
		settingsGui.OnEvent("Escape", settingsGUIClose)
		settingsGui.OnEvent("Close", settingsGUIClose)
		settingsGui.OnEvent("DropFiles", settingsGUIDropFiles)
		settingsGui.AddText("Center Section", "Settings for YoutubeDL Gui")
		settingsGui.AddCheckbox("vCheckboxUseAliases Checked" this.settings.useAliases, "Use aliases for arguments").OnEvent("Click", this.settingsHandler.bind(this))
		settingsGui.AddCheckbox("vCheckboxUseInlineConsole Checked" this.settings.useInlineConsole, "Use the inbuilt Console").OnEvent("Click", this.settingsHandler.bind(this))
		settingsGui.AddCheckbox("vCheckboxDownloadPlaylist Checked" . !this.options["no-playlist"].selected, "Download playlist?").OnEvent("Click", this.settingsHandler.bind(this))
		settingsGui.AddCheckbox("vCheckboxOnlyPrintFilename Checked" . this.options["print"].selected, "Only print filename").OnEvent("Click", this.settingsHandler.bind(this))
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
		this.gui.GetPos(&gx, &gy)
		settingsGui.Show(Format("x{1}y{2} Autosize", gx + 20, gy + 20))

		resetSettings(*) {
			if (MsgBox("Are you sure? This will reset all settings to their default values.", "Reset Settings", "0x1") == "Cancel")
				return
			this.settings := YoutubeDLGui.defaultSettings
			this.options := this.settings.options
			this.ytdlOptionHandler()
			settingsGUIClose()
			this.settingsGUI()
			this.gui["CheckboxConvertToAudio"].Value := 0
			this.gui["CheckboxUpdate"].Value := 0
			this.settingsManager("Save")
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
			this.settingsManager("Save")
		}
	}

	resetGUI() {
		if (this.settings.resetConverttoAudio) {
			this.ytdlOptionHandler(["extract-audio", "audio-quality", "audio-format"], false, , false)
			this.ytdlOptionHandler("format", , "bestvideo[height<=1080]+bestaudio/best", false)
		}
		this.data.guiVisibility := 0
		this.data.output := ""
		this.data.outputLastLine := ""
		this.data.outputLastLineCFlag := 0
		this.gui := 0
	}

	settingsManager(mode := "Save") {
		mode := StrUpper(Substr(mode, 1, 1))
		if (!Instr(FileExist(this.data.savePath), "D"))
			DirCreate(this.data.savePath)
		if (mode == "S") {
			f := FileOpen(this.data.savePath . "\settings.json", "w", "UTF-8")
			f.Write(jsongo.Stringify(this.settings, , "`t"))
			f.Close()
			return 1
		}
		else if (mode == "L") {
			this.settings := {}, settings := {}
			if (FileExist(this.data.savePath "\settings.json")) {
				try settings := jsongo.Parse(FileRead(this.data.savePath "\settings.json", "UTF-8"))
			}
			settings := MapToObj(settings, true)
			settings.options := objToMap(settings.HasOwnProp("options") ? settings.options : {}, false)
			; remove settings that dont exist
			for i, e in settings.OwnProps()
				if (YoutubeDLGui.defaultSettings.HasOwnProp(i))
					this.settings.%i% := e
			; populate nonexisting settings with default values
			for i, e in YoutubeDLGui.defaultSettings.OwnProps()
				if !(settings.HasOwnProp(i))
					this.settings.%i% := e
			; populate nonexisting options with default values
			for i, e in YoutubeDLGui.getOptions()
				if !(this.settings.options.Has(i))
					this.settings.options[i] := e
			this.options := this.settings.options
			return 1
		}
		return 0
	}

	static UIComponents => {
		separator: "▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬",
		separatorSmall: "══════════════════════════════════════════════════════════════════════════════"
	}

	static defaultSettings => {
		resetConverttoAudio: 1,
		useAliases: 0,
		useInlineConsole: 1,
		openExplorer: 1,
		trySelectFile: 0,
		outputPath: A_ScriptDir,
		outputPattern: A_ScriptDir . "\%(title)s.%(ext)s",
		ffmpegPath: "",
		ytdlPath: "",
		debug: 0,
		options: YoutubeDLGui.getOptions()
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
		youtubeDLOptions["no-warning"] := {}
		youtubeDLOptions["print"] := { param: "after_move:filepath" }
		for i, e in youtubeDLOptions
			youtubeDLOptions[i].selected := false
		for i, e in ["ignore-config", "output", "no-overwrites", "no-playlist", "retries", "limit-rate", "format", "ffmpeg-location", "merge-output-format", "no-warning", "print"]
			youtubeDLOptions[e].selected := true
		return youtubeDLOptions
	}
}