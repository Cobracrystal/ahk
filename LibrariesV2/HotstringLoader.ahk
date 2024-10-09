; https://github.com/cobracrystal/ahk
; .json for hotkeys requires format [{ "options": "o?", "string": "youre", "replacement": "you're"}, ...]
#Include "%A_LineFile%\..\..\LibrariesV2\jsongo.ahk"

class HotstringLoader {
		
	static __New() {
		this.onOffStatus := 0
		this.hotstrings := Map()
		this.hotstrings.CaseSense := false
		this.defaultMenutext := "Enable Hotstring Group: {}"
	}

	static load(jsonAsStr, name?, addMenu := true, register := true, startOff := true, skipError := false) {
		hotstringObj := jsongo.Parse(jsonAsStr)
		index := name ?? this.hotstrings.Count + 1
		this.hotstrings[index] := {obj: hotstringObj, status: -1, hasMenu: addMenu} ; -1 = unregistered, 0 = off, 1 = on
		if (register) {
			this.registerHotstrings(index, startOff, skipError)
			this.hotstrings[index].status := startOff ? 0 : 1
		}
		if (addMenu && IsSet(name)) {
			A_TrayMenu.Add(Format(this.defaultMenutext, index), this.switchFromMenu.bind(this, index))
			if (!startOff)
				A_TrayMenu.Check(Format(this.defaultMenutext, index))
		}
		return index
	}

	static switchFromMenu(index, itemName, itemPos, menuName) {
		this.switchHotstringState(index, "T")
	}

	static switchHotstringState(index, newStatus := "T") {
		if (!this.hotstrings.Has(index))
			throw(Error("Invalid Hotstring Group Index given: " index))
		if (this.hotstrings[index].status == -1)
			this.registerHotstrings(index)
		if (SubStr(newStatus, 1, 1) == "T")
			newStatus := !this.hotstrings[index].status
		for i, e in this.hotstrings[index].obj
			HotString(":" e["options"] ":" e["string"], , newStatus)
		this.hotstrings[index].status := newStatus
		if (this.hotstrings[index].hasMenu) {
			switch newStatus {
				case 1, "On":
					A_TrayMenu.Check(Format(this.defaultMenutext, index))
				case 0, "Off":
					A_TrayMenu.Uncheck(Format(this.defaultMenutext, index))
			}
		}
	}
	
	static registerHotstrings(index, startOff := 1, skipError := false) {
		queue := []
		for i, e in this.hotstrings[index].obj {
			tObj := Map()
			if (e.Has("string") && e.Has("replacement")) {
				try {
					HotString(":" (e.Has("options") ? e["options"] : "") ":" e["string"], e["replacement"], startOff ? 0 : 1)
				}
				catch {
					if (!skipError)
						throw(Error("Register Hotstring function failed:`nHotString(" . e["string"] . ", " . e["replacement"] . ", " . 1 . ")"))	
					queue.push(i)
				}
			}
		}
		for i, e in reverseArray(queue) {
			this.hotstrings[index].obj.RemoveAt(e)
		}
	}
}