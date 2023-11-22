;// made by Cobracrystal
#Include %A_ScriptDir%\LibrariesV2\BasicUtilities.ahk
/* HERE IS DOCUMENTATION 

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
				this.resetSettings(1)
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

	static __New() {
		; Tray Menu
		tObj := this.YoutubeDLGui.Bind(this)
		Menu, GUIS, Add, Open YTDL GUI, % tObj
		Menu, Tray, Add, GUIs, :GUIS
		; init class variables
		; this format is necessary to establish objects.
		this.controls := { 	"guiMain": {"text": "Youtube-DL Manager", "coords": [750, 425], "visibility":0}
			, "textMain": {"text": "Enter Link(s) to download", "type":"Text"}
			, "checkboxConvertToAudio": {"text": "Convert to Audio?", "type":"Checkbox", "endpoint":this.settingsHandler}
			, "checkboxDownloadPlaylist": {"text": "Download playlist?", "type":"Checkbox", "endpoint":this.settingsHandler}
			, "checkboxUpdate": {"text": "Update ytdlgui", "type":"Checkbox","endpoint":this.settingsHandler}
			, "checkboxUseAliases": {"text": "Use aliases for arguments", "type":"Checkbox","endpoint":this.settingsHandler}
			, "checkboxOpenExplorer": {"text": "Open Explorer after download", "type":"Checkbox","endpoint":this.settingsHandler}
			, "buttonDownload": {"text": "Launch ytdlp", "type":"Button", "endpoint":this.buttonHandler}
			, "editInput": {"text": "", "type":"Edit"}
			, "editOutput": {"text": "", "type":"Edit", "lastLine":"", "lastLineCarriageReturn":0
				, "separator":"▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬"
				, "separatorSmall":"══════════════════════════════════════════════════════════════════════════════"}
			, "editCmdConfig": {"text": "", "type":"Edit"} }
		for i, e in this.controls
			this.controls[i].handle := ""
		this.settings := { "convertToAudio": 0
			, "useAliases" : 0
			, "openExplorer" : 1
			, "defaultConfigSelection": [0,1,7,8,10,11,13,14,24,28] ; this should get loaded in some form or another. This is temporary.
			, "outputPath": A_MyDocuments "\..\Music\Musik\ConvertMusic"
			, "ffmpegPath": A_Desktop "\programs\other\ffmpeg.exe"
			, "ytdlPath": A_MyDocuments "\..\Music\Musik\ytdl\yt-dlp.exe"
			, "debug":0 }
		this.ytdlOptions := []
		this.ytdlOptions[0] := {name:this.settings.ytdlPath} 
		; General and Meta Options
		this.ytdlOptions[1] := {name:"--ignore-config"}
		this.ytdlOptions[2] := {name:"--update", alias:"-U"}
		this.ytdlOptions[3] := {name:"--simulate", alias:"-s"}
		this.ytdlOptions[4] := {name:"--list-formats", alias:"-F"}
		this.ytdlOptions[5] := {name:"--print-traffic"}
		this.ytdlOptions[6] := {name:"--newline"}
		; Downloading Options
		this.ytdlOptions[7] := {name:"--output", alias:"-o", param: this.settings.outputPath . "\%(title)s.%(ext)s"}
		this.ytdlOptions[8] := {name:"--no-overwrites", alias:"-w"}
		this.ytdlOptions[9] := {name:"--force-overwrites"}
		this.ytdlOptions[10] := {name:"--no-playlist"}
		this.ytdlOptions[11] := {name:"--retries", alias:"-R", param:1}
		this.ytdlOptions[12] := {name:"--restrict-filenames"}						
		this.ytdlOptions[13] := {name:"--limit-rate", alias:"-r", param:"5M"}
		this.ytdlOptions[14] := {name:"--format", alias:"-f", param:"bestvideo[height<=1080]+bestaudio/best"}
		; Extra Data Options
		this.ytdlOptions[15] := {name:"--skip-download"}
		this.ytdlOptions[16] := {name:"--write-description"}
		this.ytdlOptions[17] := {name:"--write-info-json"}
		this.ytdlOptions[18] := {name:"--write-comments"}
		this.ytdlOptions[19] := {name:"--write-thumbnail"}
		this.ytdlOptions[20] := {name:"--write-subs"}
		; Authentification Options
		this.ytdlOptions[21] := {name:"--username", alias:"-u", param:""}
		this.ytdlOptions[22] := {name:"--password", alias:"-p", param:""}
		this.ytdlOptions[23] := {name:"--twofactor", alias:"-2", param:""}
		; Post-Processing Options
		this.ytdlOptions[24] := {name:"--ffmpeg-location", param:this.settings.ffmpegPath}
		this.ytdlOptions[25] := {name:"--extract-audio", alias:"-x"}
		this.ytdlOptions[26] := {name:"--audio-quality", param:0}
		this.ytdlOptions[27] := {name:"--audio-format", param:"mp3"}
		this.ytdlOptions[28] := {name:"--merge-output-format", param:"mp4"}
		this.ytdlOptions[29] := {name:"--embed-subs"}
		this.ytdlOptions[30] := {name:"--embed-thumbnail"}
		this.ytdlOptions[31] := {name:"--embed-metadata"}
		this.ytdlOptions[32] := {name:"--parse-metadata", param:""}
		this.ytdlOptions[33] := {name:"--convert-thumbnails", param:"jpg"}
		for i, e in this.ytdlOptions
			this.ytdlOptions[i].selected := false
		; load jxon objecct of all this! (or inistuff i guess. Point is, after loading settings, the options are selected and params are correct.)
				; whether that be directly or by calling ytdlOptionHandler is irrelevant
	}


	
	guiCreate() {
		Gui, ytdlGui:New, % "+Border +HwndguiHandle +Label" . this.__Class . ".__on" ; +AlwaysOnTop
		this.setControl(this.controls.textMain, "Center Section")
		this.setControl(this.controls.editInput, "ys+17 xs r7 w373")
		this.setControl(this.controls.checkboxConvertToAudio, "Checked0 yp xs+383")
		this.setControl(this.controls.checkboxDownloadPlaylist, "Checked0")
		this.setControl(this.controls.checkboxUpdate, "Checked0")
		this.setControl(this.controls.checkboxUseAliases, "Checked0")
		this.setControl(this.controls.checkboxOpenExplorer, "Checked1")
		this.setControl(this.controls.buttonDownload, "xs-1 h35 w375 Default")
		this.setControl(this.controls.editCmdConfig, "xs+1 r1 w500 -Multi Readonly")
		this.setControl(this.controls.editOutput, "xs+1 r13 w500 Multi Readonly")
		
		this.ytdlOptionHandler(1, this.settings.defaultConfigSelection, 1)
		Gui, ytdlGui:Show, % Format("x{1}y{2} Autosize", this.controls.guiMain.coords[1], this.controls.guiMain.coords[2]), % this.controls.guiMain.text 
		this.controls.guiMain.handle := guiHandle
		this.controls.guiMain.visibility := 1
	}
	
	setControl(&controlObj, Options) {
		Gui, ytdlGui:Add, % controlObj.type, % Options . " HwndcHandle", % controlObj.text
		if (controlObj.HasOwnProp("endpoint")) {
			gHandle := controlObj.endpoint.Bind(this)
			GuiControl, +g, % cHandle, % gHandle
		}
		controlObj.handle := cHandle
	}
	
	updateGuiOutput(cmdLine) {
		cmdLine := Rtrim(cmdLine, "`n")
		lineArray := StrSplit(cmdLine, "`n")
		for i, newLine in lineArray {
			if (Instr(newLine, "https://") || Instr(newLine, "http://")) && !(Instr(this.controls.editOutput.lastLine, "[redirect]") || Instr(newLine, "[redirect]")) && (this.controls.editOutput.lastLine != "")
				this.updateGuiOutput(this.controls.editOutput.separatorSmall)
			StrReplace(newLine, "`r","`r",, &carriageCount)
			if (carriageCount) {
				flagC := true
				tArr := StrSplit(newLine, "`r")
				newLine := tArr[tArr.Count()]
			}
			if !(flagC && this.controls.editOutput.lastLineCarriageReturn)
				this.controls.editOutput.text .= this.controls.editOutput.lastLine
			this.controls.editOutput.lastLine := newLine . "`n"
			this.controls.editOutput.lastLineCarriageReturn := ( flagC ? 1 : 0 )
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
				str .= ( this.settings.useAliases && e.Has("alias") ? e.alias : e.name ) . (e.Haskey("param") ? " """ . e.param . """ " : " ")
		this.controls.editCmdConfig.text := str
		if (updateGUI)
			GuiControl, , % this.controls.editCmdConfig.handle, % this.controls.editCmdConfig.text
	}
	
	settingsHandler(controlhandle := 0, b := 0, c := 0) {
		Gui, ytdlGui:Submit, NoHide
		controlhandle := Format("0x{:x}",controlhandle)
		switch controlHandle {
			case this.controls.checkboxConvertToAudio.handle:
				this.settings.convertToAudio := !this.settings.convertToAudio
				this.ytdlOptionHandler(1, [25, 26, 27], this.settings.convertToAudio) ; technically last parameter unnecessary
				this.ytdlOptionHandler(1, 28, !this.settings.convertToAudio) ; same as above
				this.ytdlOptionHandler(1, 14, -1, (this.settings.convertToAudio ? "bestaudio/best" : "bestvideo[height<=1080]+bestaudio/best"))
			case this.controls.checkboxDownloadPlaylist.handle:
				this.ytdlOptionHandler(1, 10)
			case this.controls.checkboxUpdate.handle:
				this.ytdlOptionHandler(1, 2)
			case this.controls.checkboxUseAliases.handle:
				this.settings.useAliases := !this.settings.useAliases
				this.ytdlOptionHandler(1)
			case this.controls.checkboxOpenExplorer.handle:
				this.settings.openExplorer := !this.settings.openExplorer
			default:
				return
		}
	}
	
	buttonHandler(controlhandle := 0, b := 0, c := 0) {
		switch controlHandle {
			case this.controls.buttonDownload.handle:
				this.mainButton()
		}
	}
	
	mainButton() {
		Gui, ytdlGui:Submit, NoHide
		GuiControlGet, tContent,, % this.controls.editInput.handle
		this.controls.editInput.text := tContent
		fullRuncmd := this.controls.editCmdConfig.text . StrReplace(this.controls.editInput.text, "`n", A_Space)
		output := cmdRet(fullRuncmd, this.updateGuiOutput.bind(this), "CP850")
		this.updateGuiOutput(this.controls.editOutput.separator)
		if (!WinActive("ahk_id " . this.controls.guiMain.handle))
			this.YoutubeDLGui("Hide")
		if (this.controls.editInput.text == "" || !this.settings.openExplorer)
			return
		arrLong := StrSplit(this.controls.editOutput.text, this.controls.editOutput.separator)
		responseArr := StrSplit(arrLong[arrLong.Count()], this.controls.editOutput.separatorSmall)
		fileNames := []
	/*	for i, e in responseArr
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
	*/
		if (WinExist(this.settings.outputPath . " ahk_exe explorer.exe"))
			WinActivate()
		else
			Run('explorer "' . this.settings.outputPath '"') ; . fileName . ext '"')
		;	Run, % "explorer /select, """ . this.settings.outputPath . "\" . o.Value(1) . """"
	}
	
	resetSettings(mode := 0) {
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