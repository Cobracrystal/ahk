#Include WinUtilities.ahk
#Include MsgBoxAsGui.ahk

class DesktopState {
	static __New() {
		this.timer := this.updateSnapshotHistory.bind(this)
		this.snapshotHistory := []
		this.customSnapshots := Map()
		this.listLines := 0
	}

	static enableSnapshotHistory(period := 60000) {
		SetTimer(this.timer, -1)
		Sleep(10)
		SetTimer(this.timer, period)
	}

	static disableSnapshotHistory() {
		SetTimer(this.timer, 0)
	}

	static takeSnapshot(name?, getHidden := false, useBlacklist := true) {
		newSnapshot := this.Snapshot(name?, getHidden, useBlacklist)
		this.customSnapshots[newSnapshot.name] := newSnapshot
		return newSnapshot
	}

	static updateSnapshotHistory() {
		static histCounter := 1
		if (this.snapshotHistory.Length) >= 10 {
			this.snapshotHistory.InsertAt(1, this.Snapshot("History_" histCounter++))
			lastItem := this.snapshotHistory.Pop()
		} else {
			this.snapshotHistory.InsertAt(1, this.Snapshot("History_" histCounter++))
		}
	}

	static getMostRecentSnapshot() => this.snapshotHistory[1]

	static restoreFromSnapshotHistory(index := 1) => this.restoreSnapshot(this.snapshotHistory[1])

	static restoreCustomSnapshot(name) => this.restoreSnapshot(this.customSnapshots[name])

	static restoreSnapshot(snapshot) {
		logString := ""
		for i, e in snapshot.info {
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

	class Snapshot {
		static counter := 1

		static Call(name?, getHidden := false, useBlacklist := true) {
			this := super()
			this.id := DesktopState.Snapshot.counter++
			this.name := name ?? this.id
			this.timestamp := A_Now
			this.info := WinUtilities.getAllWindowInfo(getHidden, useBlacklist ? unset : [])
			return this
		}
	}
}