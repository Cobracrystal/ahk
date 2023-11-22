﻿#Include %A_ScriptDir%\LibrariesV2\JSON.ahk

class HotstringLoader {
		
	static __New() {
		this.onOffStatus := 0
		this.hotstrings := Map()
		this.defaultMenutext := "Enable Hotstring Group: {}"
	}

	static load(filePath, name?, addMenu := true, register := true, encoding := "UTF-8") {
		jsonStr := FileOpen(filePath, "r", encoding).Read()
		hotstringObj := JSON.Load(jsonStr)
		index := name ?? this.hotstrings.Count + 1
		this.hotstrings[index] := {obj: hotstringObj, status: -1, hasMenu: addMenu} ; -1 = unregistered, 0 = off, 1 = on
		if (register) {
			this.registerHotstrings(index)
			this.hotstrings[index].status := 1
		}
		if (addMenu && IsSet(name)) {
			A_TrayMenu.Add(Format(this.defaultMenutext, index), this.switchFromMenu.bind(this, index))
			if (register)
				A_TrayMenu.Check(Format(this.defaultMenutext, index))
		}
		return index
	}

	static switchFromMenu(index, itemName, itemPos, menuName) {
		this.switchHotstringState(index, "T")
	}

	static switchHotstringState(index, newStatus := "T") {
		if (!this.hotstrings.Has(index))
			return 0
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
		for i, e in this.hotstrings[index].obj {
			try
				HotString(":" e["options"] ":" e["string"], e["replacement"], 1)
			catch
				if (!skipError)
					throw Error("Hotstring function failed:`nHotString(" . hotstring . ", " . e["replacement"] . ", " . 1 . ")")
		}
	}
}