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

class DemonstratePrototypes {

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