;// made by Cobracrystal
#Include %A_ScriptDir%\Libraries\BasicUtilities.ahk
#Include %A_ScriptDir%\Libraries\JSON.ahk

/* JERE IS DOCUMENTATION 

PATHS can be found in settings at line 71, where they are set from line 73-76
The convertToAudio setting (same area) is the default on launch, but can be changed within the GUI.
to include this script, simply use
^+F10::
YoutubeDLGui.YoutubeDLGui("T")
return

the various ytdl(p) options are in the ytdlOptions starting at line 80.
changing parameters by directly editing them.
include more parameters by a) manually setting "selected" to 1 (not recommended) 
or b) including their index (in comments to the right, or count the lines from 0 ) in defaultConfigSelection in line 73 in the array (ordering doesn't matter)

ADD OPTION TO CHOOSE OUTPUT FOLDER
*/

;------------------------- AUTO EXECUTE SECTION -------------------------

YoutubeDLGui.initialize()

class YoutubeDLGui {
	static controls
	static settings
	static ytdlOptions
	; ------------------------ MAIN FUNCTION
	YoutubeDLGui(mode := "O") {
		mode := SubStr(mode, 1, 1)
		if (mode == "T")
			mode := ( this.controls.guiMain.visibility ? "H" : "O" )
		if (this.controls.guiMain.handle != "") {
			if (mode == "C") {
				this.controls.guiMain.coords := windowGetCoordinates(this.controls.guiMain.handle)
				Gui, ytdlGui:Destroy
				this.resetGUI(1)
			}
			else if (mode == "H") {	
				Gui, ytdlGui:Hide
				this.controls.guiMain.visibility := 0
			}
			else if (mode == "O") {
				Gui, ytdlGui:Show
				this.controls.guiMain.visibility := 1
			}
		}
		else if (mode == "O" || mode == "T") { ; if gui doesn't exist and mode = open/toggle, create
			this.guiCreate() 
		}
	}

	;------------------------------------------------------------------------

	initialize() {
		; Tray Menu
		tObj := this.YoutubeDLGui.Bind(this)
		Menu, GUIS, Add, Open YTDL GUI, % tObj
		Menu, Tray, Add, GUIs, :GUIS
		Menu, Tray, NoStandard
		Menu, Tray, Standard
		; init class variables
		; this format is necessary to establish objects.
		this.savePath := A_Appdata . "\Autohotkey\YTDL"
		this.settings := this.settingsManager("Load")
		if (!this.settingsManager("Load")) {
			this.settings := { "convertToAudio": 0
				, "resetConverttoAudio" : 1
				, "useAliases" : 0
				, "openExplorer" : 1
				, "trySelectFile": 0
				, "update" : 0
				, "downloadPlaylist" : 0
				, "defaultConfigSelection": [0, 1,7,8,10,11,13,14,24,28] ; this should get loaded in some form or another. This is temporary.
				, "outputPath":A_ScriptDir
				, "ffmpegPath":""
				, "ytdlPath":""
				, "debug":0 }
		}
		if (this.settings.resetConverttoAudio)
			this.settings.convertToAudio := 0
		this.controls := { 	"guiMain": {"text": "Youtube-DL Manager", "coords": [750, 425], "visibility":0}
			, "guiSettings": {"text": "Settings"}
			, "textMain": {"text": "Enter Link(s) to download", "type":"Text"}
			, "textSettings": {"text": "Settings for YTDL Gui", "type":"Text"}
			, "checkboxConvertToAudio": {"text": "Convert to Audio?", "type":"Checkbox", "endpoint":this.settingsHandler}
			, "checkboxDownloadPlaylist": {"text": "Download playlist?", "type":"Checkbox", "endpoint":this.settingsHandler}
			, "checkboxUpdate": {"text": "Update ytdlgui", "type":"Checkbox","endpoint":this.settingsHandler}
			, "checkboxUseAliases": {"text": "Use aliases for arguments", "type":"Checkbox","endpoint":this.settingsHandler}
			, "checkboxOpenExplorer": {"text": "Open Explorer after download", "type":"Checkbox","endpoint":this.settingsHandler}
			, "checkboxTrySelectFile": {"text": "Try Selecting File When Opening Explorer (Experimental)", "type":"Checkbox","endpoint":this.settingsHandler}
			, "checkboxResetConverttoaudio": {"text": "Always Start with ""Convert To Audio"" Off", "type":"Checkbox","endpoint":this.settingsHandler}
			, "buttonOpenSettings": {"text": "Settings", "type":"Button", "endpoint":this.buttonHandler}
			, "buttonOutputPath": {"text": "Choose Output Path", "type":"Button", "endpoint":this.settingsHandler}
			, "buttonffmpegPath": {"text": "Choose ffmpeg Path", "type":"Button", "endpoint":this.settingsHandler}
			, "buttonytdlpath": {"text": "Choose YTDL Path", "type":"Button", "endpoint":this.settingsHandler}
			, "buttonDownload": {"text": "Launch ytdlp", "type":"Button", "endpoint":this.buttonHandler}
			, "editOutputPath": {"text": this.settings.outputPath, "type":"Edit"}
			, "editffmpegPath": {"text": this.settings.ffmpegPath, "type":"Edit"}
			, "editytdlPath": {"text": this.settings.ytdlPath, "type":"Edit"}
			, "editInput": {"text": "", "type":"Edit"}
			, "editOutput": {"text": "", "type":"Edit", "lastLine":"", "lastLineCarriageReturn":0
				, "separator":"▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬"
				, "separatorSmall":"══════════════════════════════════════════════════════════════════════════════"}
			, "editCmdConfig": {"text": "", "type":"Edit"} }
		for i, e in this.controls
			this.controls[i].handle := ""
		this.ytdlOptions := []
		this.ytdlOptions[0] := {"name":"", "param": this.settings.ytdlPath} 
		; General and Meta Options
		this.ytdlOptions[1] := {"name":"--ignore-config"}
		this.ytdlOptions[2] := {"name":"--update", "alias":"-U"}
		this.ytdlOptions[3] := {"name":"--simulate", "alias":"-s"}
		this.ytdlOptions[4] := {"name":"--list-formats", "alias":"-F"}
		this.ytdlOptions[5] := {"name":"--print-traffic"}
		this.ytdlOptions[6] := {"name":"--newline"}
		; Downloading Options
		this.ytdlOptions[7] := {"name":"--output", "alias":"-o", "param": this.settings.outputPath . "\%(title)s.%(ext)s"}
		this.ytdlOptions[8] := {"name":"--no-overwrites", "alias":"-w"}
		this.ytdlOptions[9] := {"name":"--force-overwrites"}
		this.ytdlOptions[10] := {"name":"--no-playlist"}
		this.ytdlOptions[11] := {"name":"--retries", "alias":"-R", "param":1}
		this.ytdlOptions[12] := {"name":"--restrict-filenames"}						
		this.ytdlOptions[13] := {"name":"--limit-rate", "alias":"-r", "param":"5M"}
		this.ytdlOptions[14] := {"name":"--format", "alias":"-f", "param":"bestvideo[height<=1080]+bestaudio/best"}
		; Extra Data Options
		this.ytdlOptions[15] := {"name":"--skip-download"}
		this.ytdlOptions[16] := {"name":"--write-description"}
		this.ytdlOptions[17] := {"name":"--write-info-json"}
		this.ytdlOptions[18] := {"name":"--write-comments"}
		this.ytdlOptions[19] := {"name":"--write-thumbnail"}
		this.ytdlOptions[20] := {"name":"--write-subs"}
		; Authentification Options
		this.ytdlOptions[21] := {"name":"--username", "alias":"-u", "param":""}
		this.ytdlOptions[22] := {"name":"--password", "alias":"-p", "param":""}
		this.ytdlOptions[23] := {"name":"--twofactor", "alias":"-2", "param":""}
		; Post-Processing Options
		this.ytdlOptions[24] := {"name":"--ffmpeg-location", "param":this.settings.ffmpegPath}
		this.ytdlOptions[25] := {"name":"--extract-audio", "alias":"-x"}
		this.ytdlOptions[26] := {"name":"--audio-quality", "param":0}
		this.ytdlOptions[27] := {"name":"--audio-format", "param":"mp3"}
		this.ytdlOptions[28] := {"name":"--merge-output-format", "param":"mp4"}
		this.ytdlOptions[29] := {"name":"--embed-subs"}
		this.ytdlOptions[30] := {"name":"--embed-thumbnail"}
		this.ytdlOptions[31] := {"name":"--embed-metadata"}
		this.ytdlOptions[32] := {"name":"--parse-metadata", "param":""}
		this.ytdlOptions[33] := {"name":"--convert-thumbnails", "param":"jpg"}
		for i, e in this.ytdlOptions
			this.ytdlOptions[i].selected := false
		; load jxon objecct of all this! (or inistuff i guess. Point is, after loading settings, the options are selected and params are correct.)
				; whether that be directly or by calling ytdlOptionHandler is irrelevant
	}

	
	guiCreate() {
		Gui, ytdlGui:New, % "+Border +HwndguiHandle +Label" . this.__Class . ".__on" ; +AlwaysOnTop
		this.setControl(this.controls.textMain, "Center Section")
		this.setControl(this.controls.editInput, "ys+17 xs r7 w373")
		this.setControl(this.controls.checkboxConvertToAudio, "yp xs+383 Checked" . (this.settings.resetConverttoAudio ? 0 : this.settings.convertToAudio))
		this.setControl(this.controls.checkboxUpdate, "Checked" . this.settings.update)
		this.setControl(this.controls.buttonOpenSettings, "")
		this.setControl(this.controls.buttonDownload, "xs-1 h35 w375 Default")
		this.setControl(this.controls.editCmdConfig, "xs+1 r1 w500 -Multi Readonly")
		this.setControl(this.controls.editOutput, "xs+1 r13 w500 Multi Readonly")
		
		this.ytdlOptionHandler(1, this.settings.defaultConfigSelection, 1)
		Gui, ytdlGui:Show, % Format("x{1}y{2} Autosize", this.controls.guiMain.coords[1], this.controls.guiMain.coords[2]), % this.controls.guiMain.text 
		this.controls.guiMain.handle := guiHandle
		this.controls.guiMain.visibility := 1
	}
	
	setControl(ByRef controlObj, Options, gui := "ytdlGui") {
		Gui, % gui . ":Add", % controlObj.type, % Options . " HwndcHandle", % controlObj.text
		if (controlObj.HasKey("endpoint")) {
			gHandle := controlObj.endpoint.Bind(this)
			GuiControl, +g, % cHandle, % gHandle
		}
		controlObj.handle := cHandle
	}
	
	updateGuiOutput(cmdLine) {
		cmdLine := Rtrim(cmdLine, "`n")
		lineArray := StrSplit(cmdLine, "`n")
		for i, newLine in lineArray {
			if (Instr(newLine, "https://") || Instr(newLine, "http://")) && !(Instr(this.controls.editOutput.lastLine, "[redirect]") || Instr(newLine, "[redirect]")) && (this.controls.editOutput.lastLine != "") {
				this.controls.editOutput.lastLine := this.controls.editOutput.separatorSmall . "`n"
				this.controls.editOutput.lastLineCarriageReturn := 0
			}
			StrReplace(newLine, "`r","`r", carriageCount)
			if (carriageCount) {
				tArr := StrSplit(newLine, "`r")
				newLine := tArr[tArr.Count()]
			}
			if !(carriageCount && this.controls.editOutput.lastLineCarriageReturn)
				this.controls.editOutput.text .= this.controls.editOutput.lastLine
			this.controls.editOutput.lastLine := newLine . "`n"
			this.controls.editOutput.lastLineCarriageReturn := carriageCount
			GuiControl,, % this.controls.editOutput.handle, % this.controls.editOutput.text . this.controls.editOutput.lastLine
		;	if !(flagC && this.controls.editOutput.lastLineCarriageReturn && WinActive("ahk_id " . this.controls.guiMain.handle)) {
		;		ControlFocus,, % "ahk_id " . this.controls.editOutput.handle,
		;		Send, ^{end}
		;	}
			; NEEDS BETTER SCROLLING. https://www.autohotkey.com/board/topic/63325-updating-editscroll-down-after-adding-text/
		}
	}
		
	ytdlOptionHandler(updateGUI := 1, optionIndex := -1, optionSelection := -1,  optionParam := -1) {
		if (IsObject(optionIndex)) { ; if index is array
			if (optionSelection != -1) ; set all options in array to given selection
				for i, e in optionIndex 
					this.ytdlOptions[e].selected := optionSelection
			else ; toggle all given options
				for i, e in optionIndex
					this.ytdlOptions[e].selected := !this.ytdlOptions[e].selected
		}
		else if (optionIndex != -1) { ; if index is number
			if (optionParam == -1 && optionSelection == -1) ; if neither selection or param are given, toggle 
				this.ytdlOptions[optionIndex].selected := !this.ytdlOptions[optionIndex].selected
			if (optionSelection != -1) ; set selection
				this.ytdlOptions[optionIndex].selected := optionSelection
			if (optionParam != -1 && this.ytdlOptions[optionIndex].HasKey("param")) ; change param if given
				this.ytdlOptions[optionIndex].param := optionParam
		}
		for i, e in this.ytdlOptions ; generate string for gui
			if (e.selected) 
				str .= (e.name == "" ? "" : (this.settings.useAliases && e.HasKey("alias") ? e.alias " " : e.name " ")) . (e.Haskey("param") ? """" . e.param . """ " : " ")
		this.controls.editCmdConfig.text := str
		if (updateGUI)
			GuiControl, , % this.controls.editCmdConfig.handle, % this.controls.editCmdConfig.text
	}
	
	settingsHandler(controlhandle := 0, b := 0, c := 0) {
		Gui, ytdlGui:Submit, NoHide
		controlhandle := Format("0x{:x}",controlhandle)
		switch controlHandle {
			case this.controls.checkboxConvertToAudio.handle:
				if (this.settings.ffmpegPath == "") {
					GuiControl,, % this.controls.checkboxConvertToAudio.handle, 0
					msgbox % "Please choose ffmpeg.exe location first"
					return
				}
				this.settings.convertToAudio := !this.settings.convertToAudio
				this.ytdlOptionHandler(1, [25, 26, 27], this.settings.convertToAudio) ; technically last parameter unnecessary
				this.ytdlOptionHandler(1, 28, !this.settings.convertToAudio) ; same as above
				this.ytdlOptionHandler(1, 14, -1, (this.settings.convertToAudio ? "bestaudio/best" : "bestvideo[height<=1080]+bestaudio/best"))
			case this.controls.checkboxResetConverttoaudio.handle:
				this.settings.resetConverttoAudio := !this.settings.resetConverttoAudio
			case this.controls.checkboxDownloadPlaylist.handle:
				this.settings.downloadPlaylist := !this.settings.downloadPlaylist
				this.ytdlOptionHandler(1, 10)
			case this.controls.checkboxUpdate.handle:
				this.settings.update := !this.settings.update
				this.ytdlOptionHandler(1, 2)
			case this.controls.checkboxUseAliases.handle:
				this.settings.useAliases := !this.settings.useAliases
				this.ytdlOptionHandler(1)
			case this.controls.checkboxOpenExplorer.handle:
				this.settings.openExplorer := !this.settings.openExplorer
			case this.controls.checkboxTrySelectFile.handle:
				this.settings.trySelectFile := !this.settings.trySelectFile
			case this.controls.buttonOutputPath.handle:
				folderP := SelectFolderEx(StartingFolder := this.settings.outputPath, Prompt := "Please select a folder", OwnerHwnd := 0, OkBtnLabel := "SELECT")
				if (folderP != "") {
					this.settings.outputPath := RegexReplace(folderP, "\\$")
					this.controls.editOutputPath.text := folderP
					GuiControl,, % this.controls.editOutputPath.handle, % folderP
					this.ytdlOptionHandler(1, 7, , folderP)
				}
			case this.controls.buttonffmpegPath.handle:
				FileSelectFile, fileP, 3, % this.settings.ffmpegPath, % "Choose ffmpeg.exe", % "Executables (*.exe)"
				if (fileP != "") {
					this.settings.ffmpegPath := fileP
					this.controls.editffmpegPath.text := fileP
					GuiControl,, % this.controls.editffmpegPath.handle, % fileP
					this.ytdlOptionHandler(1, 24, , fileP)
				}
			case this.controls.buttonytdlpath.handle:
				FileSelectFile, fileP, 3, % this.settings.ytdlPath, % "Choose youtube DL .exe file", % "Executables (*.exe)"
				if (fileP != "") {
					this.settings.ytdlPath := fileP
					this.controls.editytdlPath.text := fileP
					GuiControl,, % this.controls.editytdlPath.handle, % fileP
					this.ytdlOptionHandler(1, 0, , fileP)
				}
			default:
				return
		}
		this.settingsManager("Save")
	}
	
	settingsManager(mode := "Save") {
		mode := Substr(mode, 1, 1)
		if (!Instr(FileExist(this.savePath), "D")) {
			FileCreateDir, % this.savePath
		}
		if (mode == "S") {
			f := FileOpen(this.savePath . "\ahk_settings.json", "w", "UTF-8")
			f.Write(JSON.Dump(this.settings))
			return 1
		}
		if (mode == "L") {
			if (FileExist(this.savePath "\ahk_settings.json")) {
				f := FileOpen(this.savePath "\ahk_settings.json", "r", "UTF-8")
				this.settings := JSON.Load(f.Read())
				return 1
			}
			return 0
		}
		return 0
	}
	
	buttonHandler(controlhandle := 0, b := 0, c := 0) {
		switch controlHandle {
			case this.controls.buttonDownload.handle:
				this.mainButton()
			case this.controls.buttonOpenSettings.handle:
				this.settingsGUI("O")
			default:
				return
		}
	}
	
	mainButton() {
		Gui, ytdlGui:Submit, NoHide
		GuiControlGet, tContent,, % this.controls.editInput.handle
		this.controls.editInput.text := tContent
		if (this.settings.ytdlPath == "") {
			Msgbox % "Please set ytdl path."
			return
		}
		fullRuncmd := this.controls.editCmdConfig.text . StrReplace(this.controls.editInput.text, "`n", A_Space)
		output := cmdRet(fullRuncmd, this.updateGuiOutput.bind(this), "CP850")
		this.updateGuiOutput(this.controls.editOutput.separator)
		if (!WinActive("ahk_id " . this.controls.guiMain.handle))
			this.YoutubeDLGui("Hide")
		if (this.controls.editInput.text == "" || !this.settings.openExplorer)
			return
		if (this.settings.trySelectFile) {
			arrLong := StrSplit(this.controls.editOutput.text, this.controls.editOutput.separator)
			responseArr := StrSplit(arrLong[arrLong.Count()], this.controls.editOutput.separatorSmall)
			fileNames := []
			for i, e in responseArr
			{
				lineArr := StrSplit(e, "`n")
				regexM := "O)" . StrReplace(this.settings.outputPath, "\", "\\") . "\\([[:ascii:]]*?\." . ( this.settings.convertToAudio ? "mp3" : "mp4" ) . ")"
				for i, e in reverseArray(lineArr)
					if !(Instr(e, "Deleting")) && (RegexMatch(e, regexM, o))
						break
				fileNames.push(o.Value(1))
			}
			for i, e in fileNames
				this.updateGuiOutput(e)
			for oWin in ComObjCreate("Shell.Application").Windows
				if (oWin.Name == "Explorer") && (this.settings.outputPath = oWin.Document.Folder.Self.Path) {
					WinActivate, % "ahk_id " . oWin.HWND
					PostMessage, 0x111, 28931,,, % "ahk_id " . oWin.HWND ; forcibly refresh ?
					oItems := oWin.Document.Folder.Items
					oWin.Document.SelectItem(oItems.Item(fileNames[fileNames.Count()]), 29)
					for i, e in fileNames
						oWin.Document.SelectItem(oItems.Item(e), 1)
					oWin := oItems := ""
					return
				}
		}
		if (WinExist(this.settings.outputPath . " ahk_exe explorer.exe"))
			WinActivate
		else
			Run, % "explorer """ . this.settings.outputPath . fileName . ext """"
		;	Run, % "explorer /select, """ . this.settings.outputPath . "\" . o.Value(1) . """" ; THIS IF THE INPUT IS ONLY ONE LINE (AKA ONE FILE)
	}
	
	settingsGUI(mode := "O") {
		mode := SubStr(mode, 1, 1)
		if (mode == "O") {
			Gui, ytdlGui:+Disabled
			Gui, ytdlSettingsGui:New, % "+Border +OwnerytdlGui +HwndguiHandle +Label" . this.__Class . ".__settingsGUIon" ; +AlwaysOnTop
			this.setControl(this.controls.textSettings, "Center Section", "ytdlSettingsGui")
			this.setControl(this.controls.checkboxUseAliases, "Checked" . this.settings.useAliases, "ytdlSettingsGui")
			this.setControl(this.controls.checkboxDownloadPlaylist, "Checked" . this.settings.downloadPlaylist, "ytdlSettingsGui")
			this.setControl(this.controls.checkboxOpenExplorer, "Checked" . this.settings.openExplorer, "ytdlSettingsGui")
			this.setControl(this.controls.checkboxTrySelectFile, "Checked" . this.settings.trySelectFile, "ytdlSettingsGui")
			this.setControl(this.controls.checkboxResetConverttoaudio, "Checked" . this.settings.resetConverttoAudio, "ytdlSettingsGui")
			
			this.setControl(this.controls.buttonOutputPath, "xs-1", "ytdlSettingsGui")
			this.setControl(this.controls.editOutputPath, "xs r1 w400 -Multi Readonly", "ytdlSettingsGui")
			this.setControl(this.controls.buttonffmpegPath, "xs-1", "ytdlSettingsGui")
			this.setControl(this.controls.editffmpegPath, "xs r1 w400 -Multi Readonly", "ytdlSettingsGui")
			this.setControl(this.controls.buttonytdlpath, "xs-1", "ytdlSettingsGui")
			this.setControl(this.controls.editytdlPath, "xs r1 w400 -Multi Readonly", "ytdlSettingsGui")
			
			Gui, ytdlSettingsGui:Show, % Format("x{1}y{2} Autosize", this.controls.guiMain.coords[1] + 20, this.controls.guiMain.coords[2] + 20), % this.controls.guiSettings.text 
			this.controls.guiSettings.handle := guiHandle
		}
		else if (mode == "C") {
			Gui, ytdlSettingsGui:Destroy
			Gui, ytdlGui:-Disabled
			WinActivate, % "ahk_id " this.controls.guiMain.handle
		}
	}
	
	resetGUI(mode := 0) {
		if (this.settings.resetConverttoAudio)
			this.settings.convertToAudio := 0
		this.controls.guiMain.handle := ""
		this.controls.guiMain.visibility := 0
		this.controls.editInput.text := ""
		this.controls.editOutput.text := ""
		this.controls.editOutput.lastLine := ""
		this.controls.editOutput.lastLineCarriageReturn := 0
		this.controls.editCmdConfig.text := ""
		; handles (apart from mainGui) don't need to be reset, since they get recreated everytime.
	}
	
	__onEscape() {
		YoutubeDLGui.YoutubeDLGui("Hide")
	}

	__onClose() {
		YoutubeDLGui.YoutubeDLGui("Close")
	}
	
	__settingsGUIonEscape() {
		YoutubeDLGui.settingsGUI("Close")
	}

	__settingsGUIonClose() {
		YoutubeDLGui.settingsGUI("Close")
	}
}
/*
clean links
(resolution option?)
format option (mp3, mp4, wav, etc)
thumbnail download?

FORMAT -f "bestvideo+bestaudio": twitter, instagram do not have an audio file so bestaudio causes failure.

only show finished + launch explorer if successful

add option to clean part files
add option to abort (modify cmdret potentially?)

gui to edit settings (and change params!)
if editing params manually, it shouldn't change those unless removed

settings:
ffmpeg path get from PATH ?
allow options for 
stuff

add override for domains -> instagram -> other format etc
(when multiple links provided, they must all have same domain? otherwise other static settings used.)
*/