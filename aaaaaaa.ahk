#Persistent
#Warn
uwu.__init(100)
return

class uwu {
	static sliderValue
	
	__init(val) {
		this.sliderValue := val
	}
	
	guimake() {
		gui, uwu:new, +border
		sliderWorker(0)
		gHandle := this.sliderWorker.Bind(this)
		GuiControl, +g, TransparencyValue, % gHandle
		Gui, uwu:Show, % Format("x{1}y{2}w{3}h{4} Autosize", 300, 300, 300, 300), WindowList
	}
	
	sliderWorker(worker := 1) {
		static TransparencyValue
		if (worker) {
			gui, uwu:submit, nohide
			this.sliderValue := TransparencyValue
			; some other function
		}
		else
			Gui, uwu:Add, Slider, % "vTransparencyValue AltSubmit Range0-255 ToolTip NoTicks", this.sliderValue
	}
}


class cube {
	static x
	static y
	static z
	
	__New(var1 := 0, var2 := 0, var3 := 0) {
		this.x := var1
		this.y := var2
		this.z := 0
	}
	
	calcSum() {
		this.z := this.x + this.y
		return this
	}
	
	shiftZbyX() {
		this.z += this.x
		return this
	}
	
	showSum() {
		msgbox % this.z
	}

}

class String {
	__New(str) {
		this.str := str
	}
	
	length() {
		return StrLen(this.str)
	}
}

^+f::
reload