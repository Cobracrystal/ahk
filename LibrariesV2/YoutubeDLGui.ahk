﻿; https://github.com/cobracrystal/ahk
/*
todo:
clean links from stuff
(resolution option?)
format option (mp3, mp4, wav, etc)
thumbnail download?

FORMAT -f "bestvideo+bestaudio": twitter, instagram do not have an audio file so bestaudio causes failure.
^ that is native ytdlp stuff, fix by just using better -f option

only show finished + launch explorer if successful
add option to clean part files
add option to abort (modify cmdret potentially?)
*/

#Include %A_ScriptDir%\LibrariesV2\BasicUtilities.ahk
#Include %A_ScriptDir%\LibrariesV2\JSON.ahk

class YoutubeDLGui {
	youtubeDLGui(mode := "O") {
		mode := SubStr(mode, 1, 1)
		if (mode == "T")
			mode := (this.data.guiVisibility ? "H" : "O")
		if (this.gui) {
			if (mode == "C") {
				this.data.coords := windowGetCoordinates(this.gui.Hwnd)
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
			coords: [750, 425],
			savePath: A_Appdata . "\Autohotkey\YTDL",
			output: "",
			outputLastLine: "",
			outputLastLineCFlag: 0,
			separator: "▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬",
			separatorSmall: "══════════════════════════════════════════════════════════════════════════════",
		}
		this.settingsManager("Load")
		this.settings.flagDebug := flagDebug
		this.controls := {}
		this.resetGUI()
	}

	guiCreate() {
		this.gui := Gui("+Border", "YoutubeDL Manager")
		this.gui.OnEvent("Escape", (*) => this.youtubeDLGui("Hide"))
		this.gui.OnEvent("Close", (*) => this.youtubeDLGui("Close"))
		this.gui.AddText("Center Section", "Enter Link(s) to download")
		this.controls.editInput := this.gui.AddEdit("ys+17 xs r7 w373")
		this.gui.AddCheckbox("vCheckboxConvertToAudio yp xs+383 Checked" . (this.settings.resetConverttoAudio ? 0 : this.options["extract-audio"].selected), "Convert to Audio?").OnEvent("Click", this.settingsHandler.bind(this))
		this.gui.AddCheckbox("vCheckboxUpdate Checked" this.options["update"].selected, "Update YoutubeDL Gui").OnEvent("Click", this.settingsHandler.bind(this))
		this.gui.AddButton("", "Settings").OnEvent("Click", (*) => this.settingsGUI("O"))
		this.gui.AddButton("xs-1 h35 w375 Default", "Launch yt-dlp").OnEvent("Click", (*) => this.mainButton())
		this.controls.editCmdConfig := this.gui.AddEdit("xs+1 r1 w500 -Multi Readonly", "")
		this.controls.editOutput := this.gui.AddEdit("xs+1 r13 w500 Multi Readonly")
		this.ytdlOptionHandler()
		this.gui.Show(Format("x{1}y{2} Autosize", this.data.coords[1], this.data.coords[2]))
		this.data.guiVisibility := 1
	}

	updateGuiOutput(cmdLine) {
		lineArray := StrSplit(Rtrim(StrReplace(cmdLine, "`r`n", "`n"), "`n"), "`n")
		for i, newLine in lineArray {
			if (Instr(newLine, "https://") || Instr(newLine, "http://")) && !(Instr(this.data.outputLastLine, "[redirect]") || Instr(newLine, "[redirect]")) && (this.data.outputLastLine != "") && (this.data.outputLastLine != this.data.separator . "`n") {
				this.data.outputLastLine .= this.data.separatorSmall . "`n"
				this.data.outputLastLineCFlag := 0
			}
			; if not the last line, then there might be `r`n for the end, so remove that. StrSplit Trims on *both* sides, so it does not work (since `r at the start is necessary for overwriting lines)
			if (i != lineArray.Length)
				newLine := RTrim(newLine, "`r")
			StrReplace(newLine, "`r", "`r", , &carriageCount)
			if (carriageCount) { ; if `r in string, only take the last string part.
				tArr := StrSplit(newLine, "`r")
				newLine := tArr[tArr.Length]
			}
			; if current line AND previous line have `r, then overwrite prev line, otherwise save the line.
			if !(carriageCount && this.data.outputLastLineCFlag)
				this.data.output .= this.data.outputLastLine
			this.data.outputLastLine := newLine . "`n"
			this.data.outputLastLineCFlag := carriageCount
			; write saved output and current line to gui
			this.controls.editOutput.value := this.data.output . this.data.outputLastLine
			; if !(flagC && this.data.outputLastLineCFlag && WinActive(this.gui)) {
			; 	this.controls.editOutput.Focus()
			; 	Send("^{end}")
			; }
			; NEEDS BETTER SCROLLING. https://www.autohotkey.com/board/topic/63325-updating-editscroll-down-after-adding-text/
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

	settingsHandler(ctrlObject := 0, *) {
		switch ctrlObject.Name {
			case "CheckboxConvertToAudio":
				if (this.settings.ffmpegPath == "") {
					ctrlObject.Value := 0
					Msgbox("Please choose FFmpeg.exe location first.")
					this.settingsGUI("Open")
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
				fileP := FileSelect(3, this.settings.ytdlPath, "Choose youtube DL .exe file", "Executables (*.exe)")
				if (fileP != "") {
					this.settings.ytdlPath := fileP
					this.controls.editYTDLPath.Value := fileP
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
			this.settingsGUI("Open")
			return
		}
		fullRuncmd := this.controls.editCmdConfig.value . StrReplace(links, "`n", A_Space)
		output := cmdRet(fullRuncmd, this.updateGuiOutput.bind(this), "UTF-8")
		fullOutput := this.controls.editOutput.value
		this.updateGuiOutput(this.data.separator)
		if (!WinActive(this.gui))
			this.YoutubeDLGui("Hide")
		if (links == "" || !this.settings.openExplorer)
			return
		if (this.settings.trySelectFile) {
			arrLong := StrSplit(fullOutput, this.data.separator)
			responseArr := StrSplit(arrLong[arrLong.Length], this.data.separatorSmall)
			fileNames := []
			for i, e in responseArr
			{
				lineArr := StrSplit(RTrim(e, "`n"), "`n")
				regexM := StrReplace(this.settings.outputPath, "\", "\\") . "\\([[:ascii:]]*?\." . (this.options["extract-audio"].selected ? "mp3" : "mp4") . ")"
				for i, e in reverseArray(lineArr)
					if !(Instr(e, "Deleting")) && (RegexMatch(e, regexM, &o))
						break
				if (o != "")
					fileNames.push(o[1])
			}
			if (this.settings.flagDebug)
				for i, e in fileNames
					this.updateGuiOutput(e)
			if (fileNames.Length == 0)
				return
			for oWin in ComObject("Shell.Application").Windows
				if (oWin.Name == "Explorer") && (this.settings.outputPath = oWin.Document.Folder.Self.Path) {
					WinActivate("ahk_id " . oWin.HWND)
					PostMessage(0x111, 28931, , , "ahk_id " . oWin.HWND) ; forcibly refresh ?
					oItems := oWin.Document.Folder.Items
					oWin.Document.SelectItem(oItems.Item(fileNames[fileNames.Length]), 29)
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

	settingsGUI(mode := "O", *) {
		mode := SubStr(mode, 1, 1)
		if (mode == "O") {
			this.gui.Opt("+Disabled")
			this.guiSettings := Gui("+Border +Owner" . this.gui.Hwnd, "Settings")
			this.guiSettings.OnEvent("Escape", (*) => this.settingsGUI("Close"))
			this.guiSettings.OnEvent("Close", (*) => this.settingsGUI("Close"))

			this.guiSettings.AddText("Center Section", "Settings for YoutubeDL Gui")
			this.guiSettings.AddCheckbox("vCheckboxUseAliases Checked" this.settings.useAliases, "Use aliases for arguments").OnEvent("Click", this.settingsHandler.bind(this))
			this.guiSettings.AddCheckbox("vCheckboxDownloadPlaylist Checked" . !this.options["no-playlist"].selected, "Download playlist?").OnEvent("Click", this.settingsHandler.bind(this))
			this.guiSettings.AddCheckbox("vCheckboxOpenExplorer Checked" this.settings.openExplorer, "Open Explorer after download").OnEvent("Click", this.settingsHandler.bind(this))
			this.guiSettings.AddCheckbox("vCheckboxTrySelectFile Checked" this.settings.trySelectFile, "Try Selecting File When Opening Explorer (Experimental)").OnEvent("Click", this.settingsHandler.bind(this))
			this.guiSettings.AddCheckbox("vCheckboxResetConvertToAudio Checked" this.settings.resetConverttoAudio, "Always Start with `"Convert To Audio`" Off").OnEvent("Click", this.settingsHandler.bind(this))

			this.guiSettings.AddButton("vButtonOutputPath xs-1", "Choose Output Path").OnEvent("Click", this.settingsHandler.bind(this))
			this.controls.editOutputPath := this.guiSettings.AddEdit("xs r1 w400 -Multi Readonly", this.settings.outputPath)
			this.guiSettings.AddButton("vButtonFFmpegPath xs-1", "Choose FFmpeg Path").OnEvent("Click", this.settingsHandler.bind(this))
			this.controls.editFFmpegPath := this.guiSettings.AddEdit("xs r1 w400 -Multi Readonly", this.settings.ffmpegPath)
			this.guiSettings.AddButton("vButtonYTDLPath xs-1", "Choose YTDL Executable Path").OnEvent("Click", this.settingsHandler.bind(this))
			this.controls.editYTDLPath := this.guiSettings.AddEdit("xs r1 w400 -Multi Readonly", this.settings.ytdlPath)
			this.guiSettings.AddButton("xs-1", "Reset Settings").OnEvent("Click", this.resetSettings.bind(this))
			this.guiSettings.Show(Format("x{1}y{2} Autosize", this.data.coords[1] + 20, this.data.coords[2] + 20))
		}
		else if (mode == "C") {
			WinSetAlwaysOnTop(1, this.gui)
			this.guiSettings.Destroy()
			this.gui.Opt("-Disabled")
			WinSetAlwaysOnTop(0, this.gui)
			WinActivate(this.gui)
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

	resetSettings(*) {
		if (MsgBox("Are you sure? This will reset all settings to their default values.", "Reset Settings", "0x1") == "Cancel")
			return
		newSettings := YoutubeDLGui.getDefaultSettings()
		options := YoutubeDLGui.getOptions()
		this.settings := newSettings
		this.options := options
		this.settings.options := this.options
		this.ytdlOptionHandler()
		this.settingsGUI("Close")
		this.settingsGUI("Open")
		this.gui["CheckboxConvertToAudio"].Value := 0
		this.gui["CheckboxUpdate"].Value := 0
		this.settingsManager("Save")
	}

	settingsManager(mode := "Save") {
		mode := Substr(mode, 1, 1)
		if (!Instr(FileExist(this.data.savePath), "D"))
			DirCreate(this.data.savePath)
		if (mode == "S") {
			f := FileOpen(this.data.savePath . "\ahk_settings.json", "w", "UTF-8")
			f.Write(JSON.Dump(this.settings))
			f.Close()
			return 1
		}
		else if (mode == "L") {
			this.settings := {}
			if (FileExist(this.data.savePath "\ahk_settings.json")) {
				s := FileRead(this.data.savePath "\ahk_settings.json", "UTF-8")
				try this.settings := JSON.Load(s, , false)
			}
			for i, e in YoutubeDLGui.getDefaultSettings().OwnProps() {
				if !(this.settings.HasOwnProp(i))
					this.settings.%i% := e
			}
			this.options := Map()
			for i, e in YoutubeDLGui.getOptions()
				this.options[i] := (this.settings.options.HasOwnProp(i) ? this.settings.options.%i% : e)
			this.settings.options := this.options
			; maybe [,"ignore-config","no-playlist","retries"]
			return 1
		}
		return 0
	}

	; these functions exist to get the first-time default values.
	static getDefaultSettings() {
		settings := {
			resetConverttoAudio: 1,
			useAliases: 0,
			openExplorer: 1,
			trySelectFile: 0,
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
		for i, e in ["ignore-config", "output", "no-overwrites", "no-playlist", "retries", "limit-rate", "format", "ffmpeg-location", "merge-output-format"]
			youtubeDLOptions[e].selected := true
		return youtubeDLOptions
	}
}