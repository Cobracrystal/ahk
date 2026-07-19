#Include WinUtilities.ahk
#Include MsgBoxAsGui.ahk

class DesktopState {
	static __New() {
		this.timer := this.save.bind(this)
		this.prevState := { name: "Previous", timestamp: 0, info: [] }
		this.listLines := 0
		this.customStates := Map()
	}

	static enable(period := 20000) {
		SetTimer(this.timer, -1)
		Sleep(10)
		SetTimer(this.timer, period)
	}

	static disable() {
		SetTimer(this.timer, 0)
	}

	static save(custom?) {
		ListLines(this.listLines)
		if (IsSet(custom)) {
			return this.customStates[custom] := {
				timestamp: A_Now,
				name: custom,
				info: WinUtilities.getAllWindowInfo()
			}
		}
		else {
			return this.prevStates := {
				timestamp: A_Now,
				name: "Previous",
				info: WinUtilities.getAllWindowInfo()
			}
		}
	}

	static restore(custom?) {
		logString := ""
		state := IsSet(custom) ? this.customStates[custom] : this.prevStates
		for i, e in state.info {
			if (!WinExist(e.hwnd))
				continue
			try {
				if (e.state == -1)
					WinMinimize(e.hwnd)
				else if (e.state == 1)
					WinMaximize(e.hwnd)
				else {
					if WinGetMinMax(e.hwnd)
						WinRestore(e.hwnd)
					WinMove(e.xpos, e.ypos, e.width, e.height, e.hwnd)
				}
			}
			catch OSError as err {
				logString .= "Failed updating hwnd " e.hwnd ": " WinGetTitle(e.hwnd) . " with reason `"" err.Message "`" in function " err.What "`n"
			}
		}
	}
}