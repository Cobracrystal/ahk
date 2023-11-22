
class NeoKeyboardLayout {

	; ------------------------ MAIN FUNCTION
	
	static KeyboardLayoutGUI(mode := "O", *) {
		mode := SubStr(mode, 1, 1)
		if (mode == "T")
			mode := this.gui.hidden ? "O" : "C" 
		DetectHiddenWindows(1)
		if (WinExist(this.gui.obj)) {
			if (mode == "O") { ; if gui exists and mode = open, activate window
				this.gui.obj.Show()
				this.gui.hidden := false
			}
			else {	; if gui exists and mode = close/toggle, close
				this.gui.coords := windowGetCoordinates(this.gui.obj.hwnd)
				this.gui.obj.Hide()
				this.gui.hidden := true
			}
		}
		else if (mode != "C") ; if gui doesn't exist and mode = open/toggle, create
			this.guiCreateActiveX() 
	}
	
	static __New() {
		; Tray Menu
		this.path := A_WorkingDir "\NeoKeyboardLayout"
		tObj := this.KeyboardLayoutGUI.Bind(this)
		guiMenu := TrayMenu.submenus["GUIs"]
		guiMenu.Add("Open Keyboard Layout GUI", this.KeyboardLayoutGUI.Bind(this))
		A_TrayMenu.Add("GUIs", guiMenu)
		; this format is necessary to establish objects properly
		this.gui := {text: "Current Layout", coords: [50, 50], obj: -1, hidden: true}
	}
	
	static guiCreate() {
		this.gui.obj := Gui("+LastFound +ToolWindow +AlwaysOnTop -SysMenu -Caption", this.gui.text)
		this.gui.obj.BackColor := 0xFFFFFF
		WinSetTransColor(0xFFFFFF, this.gui.obj)
		this.gui.obj.AddPicture("w905 h240 +backgroundTrans", this.path . "\bone1.png")
		this.gui.obj.Show(Format("x{1}y{2}w{3}h{4} NoActivate", this.gui.coords[1], this.gui.coords[2], 920, 240))
		this.gui.hidden := false
	}
	
	static guiCreateActiveX() {
		this.gui.obj := Gui("+LastFound +ToolWindow +AlwaysOnTop -SysMenu -Caption", this.gui.text)
		WB := this.gui.obj.AddActiveX("x0 y0 w700 h205 vWBObj", "Shell.Explorer").Value
		WB.Navigate("about:blank")
		vHtml := '<meta http-equiv="X-UA-Compatible" content="IE=9">`n<html>`n<title>name</title>`n<body>`n<center>`n<img src="' . this.path . "\svg_bone-1.svg" . '">`n</center>`n</body>`n</html>'
		WB.document.write(vHtml)
		WB.Refresh()
		this.gui.obj.Show(Format("x{1}y{2}w{3}h{4} NoActivate", this.gui.coords[1], this.gui.coords[2], 700, 200))
		this.gui.hidden := false
	}
}
