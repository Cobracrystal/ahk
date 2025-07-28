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

getFilesInFolder(path) {
	arr := []
	loop files path "\*", 'FDR'{
		arr.push(A_LoopFileFullPath)
	}
	A_Clipboard := objToString(arr,,,1,1)
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
	sArr := objSortByKey(bigArr, "wordcount", "N")
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
			o.push({link:m[1], index:m[2]})
		}
	}
	s := ""
	sorted := objSortByKey(o, "index", "N")
	for i, e in sorted {
		s .= e.value.link "`n"
	}
	A_Clipboard := s
}