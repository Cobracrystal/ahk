#Include "%A_ScriptDir%\LibrariesV2\BasicUtilities.ahk"

drawMouseCircle(radius, centerX?, centerY?, max_degrees := 360) {
	MouseGetPos(IsSet(centerX) ? unset : &centerX, IsSet(centerY) ? unset : &centerY)
	MouseMove(centerX, centerY + radius)
	Sleep(50)
	Send("{LButton Down}")
	SendMode("Event")
	Loop(max_degrees) {
		x := Round(radius * Sin(2 * A_Index/max_degrees * 3.141592653))
		y := Ceil(radius * Cos(2 * A_Index/max_degrees * 3.141592653))
		MouseMove(centerX + x, centerY + y, 1)
	}
	Send("{LButton Up}")
}

updateScript() {
	url := "https://raw.githubusercontent.com/Cobracrystal/ahk/refs/heads/main/LibrariesV2/" . A_ScriptName
	text := sendRequest(url)
	thisScript := FileRead(A_LineFile, "UTF-8")
	if StrCompare(text, thisScript)
		Download(url, A_LineFile)
}

class Demonstrator {

	static demonstratePropertyDistribution() {
		thing1 := this.Thing()
		thing2 := this.Thing
		thing3 := this.Thing.Prototype
		for e in ["property", "method", "staticProperty", "staticmethod", "__Class"] {
			print("Instance:     " e ": HasOwnProp => " thing1.HasOwnProp(e) ", HasProp => " thing1.HasProp(e) ", HasMethod => " thing1.HasMethod(e))
			print("Class Object: " e ": HasOwnProp => " thing2.HasOwnProp(e) ", HasProp => " thing2.HasProp(e) ", HasMethod => " thing2.HasMethod(e))
			print("Prototype   : " e ": HasOwnProp => " thing3.HasOwnProp(e) ", HasProp => " thing3.HasProp(e) ", HasMethod => " thing3.HasMethod(e))
		}
	}

	static demonstrateInheritance() {
		obj := this.Thing
		base__ClassChain := 		".__Class of base chain: `n> " obj.__Class "`n"
		Prototype__ClassChain := 	".__Class of Prototype chain: `n> " obj.Prototype.__Class "`n"
		full__ClassChain := 		".__Class of Prototype of base: `n> " Type(obj) ": " obj.Prototype.__Class "`n"
		base := ObjGetBase(obj)
		sep := ""
		while (base) {
			sep .= "`t"
			base__ClassChain .= sep " > " base.__Class "`n"
			full__ClassChain .= sep " > " Type(base) ": " (Type(base) != "Prototype" ? base.Prototype.__Class : base.__Class) "`n"
			base := ObjGetBase(base)
		}
		sep := ""
		base := ObjGetBase(obj.Prototype)
		while (base) {
			sep .= "`t"
			Prototype__ClassChain .= sep " > " base.__Class "`n"
			base := ObjGetBase(base)
		}
		print(base__ClassChain)
		print(Prototype__ClassChain)
		print(full__ClassChain)
	}

	class Thing extends Map {
		property := 1
		method() => 5

		static staticproperty := 2
		static staticmethod() => 7
	}

	static showIcons(dll := 1) {
		if (IsInteger(dll))
			dll := dll ? "imageres.dll" : "shell32.dll"
		g := Gui()
		Loop(512) {
			i := A_Index
			try {
				r := g.AddPicture((Mod(i, 32) ? "yp" : "x16") " w32 h32 Icon" i, dll)
				r.iconid := i
				r.OnEvent("Click", (o, *) => msgbox(o.iconid))
			}
		}
		g.show()
	}

	static showBigIcons(dll := 1) {
		if (IsInteger(dll))
			dll := dll ? "imageres.dll" : "shell32.dll"
		g := Gui()
		Loop(512) {
			i := A_Index
			try {
				r := g.addpicture((Mod(i, 32) ? "yp" : "x16") " w32 h32", "HICON:" LoadPicture("imageres.dll", "Icon" i, &it))
				r.iconid := i
				r.onevent("Click", (o,*) => msgbox(o.iconid))
			}
		}
		g.show()
	}

	static showScrollbarPosition() {
		static SIF_RANGE := 0x01
		static SIF_PAGE := 0x02
		static SIF_POS := 0x04
		static SIF_TRACKPOS := 0x10
		static SIF_ALL := (SIF_RANGE | SIF_PAGE | SIF_POS | SIF_TRACKPOS)
		static SB_HORZ := 0
		static SB_VERT := 1
		static SB_CTL := 2
		static SB_BOTH := 3
		static SB_BOTTOM := 7
		static WM_VSCROLL := 0x115
		g := Gui()
		g.OnEvent("Close", (*) => ExitApp())
		g.OnEvent("Escape", (*) => ExitApp())
		ed := g.addEdit("+ReadOnly R20 w200", "Start")
		g.show()
		Loop(51)
			ed.Value .= Format("`nLine {}", A_Index)
		Loop {
			NumPut("UInt", 28, ScrollInfo := Buffer(28, 0))
			NumPut("UInt", SIF_ALL, ScrollInfo, 4)
			DllCall("GetScrollInfo", "uint", ed.hwnd, "int", SB_VERT, "Ptr", ScrollInfo)
			nMin := NumGet(ScrollInfo, 8, "int")
			nMax := NumGet(ScrollInfo, 12, "int")
			nPage := NumGet(ScrollInfo, 16, "uint")
			curPos := NumGet(ScrollInfo, 20, "uint")
			; curPos := DllCall("user32\GetScrollPos", "Ptr", ed.hwnd, "int", SB_VERT)
			ToolTip(nMin "-" nMax ": " curPos ". " nPage)
			trueMax := nMax - nPage + 1
			position := curPos / (trueMax - nMin)
			ToolTip(nMin "-" nMax ": " curPos ". " nPage ": " position)
			; PostMessage(WM_VSCROLL, SB_BOTTOM, 0, ed.hwnd)
			; postmessage(0xB7,-1,-2, ed.hwnd)
			Sleep(200)
		}
		; EM_SCROLLCARET
	}

	static coloredGUI() {
		newGui := Gui("+Border", "a")
		newGui.SetFont("c0x00FF00")
		newGui.BackColor := "0x1e1e1e"
		newGui.LV := newGui.AddListView("R5 w150", ["A", "B", "C"]) ; LVEvent, Altsubmit
		newGui.AddGroupBox("w500 h50", "TEEEXT")
		newGui.AddButton("Section r1 w100", "Add Row to List").OnEvent("Click", (*) => 0)
		showString := "Center Autosize"
		newGui.AddText("ys", "UHHH HELLO?????")
		newGui.AddCheckbox("ys", "Hey there")
		for i, ctrl in newGui {
			ctrl.SetFont("c0xFF0000")
			ctrl.Opt("+BackgroundYellow")
		}
		newGui.Show(showString)
	}

	; ORDER OF OPERATIONS
	; static __Init() (aka static variables at the top) is called for the class Prototype
	; static __New() then this prototype is created and thus this gets launched
	; if we are calling the class (ie. instance := ClassName())
	; static Call is called. This normally would call __Init and __New, but can be override. Then use super()
	; Call must return the class instance.

	class OperationOrder {
		; static asd := msgbox(1) ; commented out since this would always pop up at start of script
		; sdf := msgbox(4) ; since __Init is defined, this is illegal

		__Init() {
			msgbox(4)
			this.asd := 5
		}

		static method1(a) {
			return 5
		}

		static Call(asd) {
			msgbox(3)
			super("__NewParam") ; -> return class instance
			return this ; -> return class object
		}
		static __New() {
			; msgbox(2) ; commented out since this would always pop up at start of script
		}

		__New(*) {
			msgbox(5)
		}

		method2(*) {
			return 5
		}
	}
	
	/*
	we have an object.
	if it is a class instance object, we wish to get the properties that it got from the class
	ie. msgbox is a func object and thus has the MinParams property, but this property does not appear in ObjOwnProps(Msgbox)

	if it is enumerable, we directly enumerate it.

	we enumerate ObjOwnProps() with one variable. This will get us ALL property names.
	If a property name has a getter, call it.
	Otherwise, print information about that property

	if the object has a Base object, enumerate that.

	the base of a class is the class object that it is extended from.
	the base of class Any is class.Prototype and then we chain
	The base of a class instance is class.Prototype
	Now:
	class Thing {
		property := 1
		static staticproperty := 2
		method() => 1
		static staticmethod => 2
	}

	The Instance contains only instance properties. Instance methods are inherited from Prototype. __Class is inherited from Prototype and contains the class name 
	Method counts as Prop, not an OwnProp
	The Prototype contains only instance methods and Properties (that exist in the class. Properties assigned via New/Init/Assignments in class Body are not included) 
	. __Class is defined here and is the class name
	Method counts as OwnProp
	The class Object contains only static properties and static methods. __Class is inherited from class class and thus contains "Class"
	static methods count as OwnProps
	*/
}

objIterate(o,f) { ; this could be a oneliner
	return (
		t(o,f,fl,en,*) => (
			en(&i, &e) ? t(
				o,
				f,
				fl,
				en,
				fl ? o[i] := f(e) : o.%i% := f(e)
			) : o
		),
		t(
			o.Clone(),
			f,
			fl := (o is Array || o is Map),
			fl ? o.__Enum(2) : o.OwnProps().__Enum(2)
		)
	)
}


ao3Functions() {
	bigArr := []
	arr := ao3DLBookMarks(28)
	for i, e in arr
		bigArr.push(ao3GetStories(e)*)
	print("")
	sArr := objSort(bigArr, a => a.wordcount, "N")
	print(sArr)
	print(bigArr.Length)
	print(objCollect(bigArr, (a, b) => a + b.wordcount, 0))

	ao3GetStories(str) {
		pos := 1
		arr := []
		len := strlen(str)
		while (pos <= len) {
			ob := {}
			pos := RegexMatch(str, '<!--title, author, fandom-->\s*<div class="header module">\s*<h4 class="heading">\s*<a href="\/works\/(\d+)">(.*)<\/a>', &o, pos)
			if (pos == 0)
				break
			ob.link := o[1]
			ob.name := o[2]
			pos += StrLen(o[0])
			pos := RegExMatch(str, '<dt class="words">Words:<\/dt>\s*<dd class="words">((?:\d|,|\.)*)<\/dd>', &o, pos)
			pos += StrLen(o[0])
			ob.wordcount := StrReplace(o[1], ",")
			arr.push(ob)
		}
		return arr
	}

	ao3DLBookMarks(pages) {
		static baseURL := "https://archiveofourown.org/users/Cobracrystal/bookmarks"
		htmlArr := []
		Loop (pages) {
			htmlArr.push(sendRequest(baseURL . (A_Index > 1 ? "?page=" A_Index : "")))
			print(Round(A_Index / pages * 100, 1) "%", , false)
		}
		return htmlArr
	}
}

sortYoutubePlaylistLinksByIndex() {
	str := A_Clipboard
	o := []
	loop parse str, "`n" {
		if RegExMatch(A_LoopField, "(.*)&list=WL&index=(\d+)", &m) {
			o.push({link:m[0], index:m[2]})
		}
	}
	s := ""
	sorted := objSort(o, r => r.index, "N")
	for i, e in sorted {
		s .= e.value.link "`n"
	}
	A_Clipboard := s
}