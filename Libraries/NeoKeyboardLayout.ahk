
NeoKeyboardLayout.initialize()

class NeoKeyboardLayout {

	static controls
	static path := "C:\Users\Simon\Desktop\programs\programming\ahk\script_files\NeoKeyboardLayout\"
	; ------------------------ MAIN FUNCTION
	
	KeyboardLayoutGUI(mode := "O") {
		mode := SubStr(mode, 1, 1)
		if (WinExist("ahk_id " . this.controls.guiMain.handle)) {
			if (mode == "O") ; if gui exists and mode = open, activate window
				WinActivate, % "ahk_id " . this.controls.guiMain.handle
			else {	; if gui exists and mode = close/toggle, close
				this.controls.guiMain.coords := windowGetCoordinates(this.controls.guiMain.handle)
				Gui, NeoKeyboardLayout:Destroy
				this.controls.guiMain.handle  := ""
			}
		}
		else if (mode != "C") ; if gui doesn't exist and mode = open/toggle, create
			this.guiCreateActiveX() 
	}
	
	initialize() {
		; Tray Menu
		tObj := this.KeyboardLayoutGUI.Bind(this)
		Menu, GUIS, Add, Open Keyboard Layout GUI, % tObj
		Menu, Tray, Add, GUIs, :GUIS
		Menu, Tray, Standard
		Menu, Tray, NoStandard
		; this format is necessary to establish objects properly
		this.controls := { 	"guiMain": {"text": "Current Layout"} }
		this.controls.guiMain.coords := [50, 50]
	}
	
	guiCreate() {
		Gui, NeoKeyboardLayout:New, % "+lastfound +HwndguiHandle +AlwaysOnTop -SysMenu -Caption"
		Gui, NeoKeyboardLayout:Color, ffffff
		WinSet, TransColor, ffffff ; , ahk_id %guiHandle%
		Gui, NeoKeyboardLayout:Add, Picture, w905 h240 +BackgroundTrans, NeoKeyboardLayout\bone1.png 
		Gui, NeoKeyboardLayout:Show, % Format("x{1}y{2}w{3}h{4} NoActivate", this.controls.guiMain.coords[1], this.controls.guiMain.coords[2], 920, 240), % this.controls.guiMain.text
		this.controls.guiMain.handle := guiHandle
	}
	
	guiCreateActiveX() {
		global WBObj
		Gui, NeoKeyboardLayout:New, % "+lastfound +HwndguiHandle +AlwaysOnTop -SysMenu -Caption"
		Gui, NeoKeyboardLayout:Add, ActiveX, x0 y0 w700 h200 hwndcHandle vWBObj, shell explorer
		GuiControlGet, WBObj, , % cHandle, 
		WBObj.Navigate("about:blank")
		vHtml := "<meta http-equiv=""X-UA-Compatible"" content=""IE=9"">`n<html>`n<title>name</title>`n<body>`n<center>`n<img src=""" . this.path . "svg_bone-1.svg" . """ >`n</center>`n</body>`n</html>"
		WBObj.document.write(vHtml)
		WBObj.Refresh()
		Gui, NeoKeyboardLayout:Show, % Format("x{1}y{2}w{3}h{4} NoActivate", this.controls.guiMain.coords[1], this.controls.guiMain.coords[2], 700, 200), % this.controls.guiMain.text
		this.controls.guiMain.handle := guiHandle
	}
}
