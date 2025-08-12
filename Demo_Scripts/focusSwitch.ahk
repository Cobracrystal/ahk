#SingleInstance Force
#Include ..\LibrariesV2\BasicUtilities.ahk
; switch focus, limited per monitor
!Up::		focusSwitch.moveFocus("U")
!Down::		focusSwitch.moveFocus("D")
!Left::		focusSwitch.moveFocus("L")
!Right::	focusSwitch.moveFocus("R")
; switch focus including across monitors
^!Up::		focusSwitch.moveFocus("U", 0)
^!Down::	focusSwitch.moveFocus("D", 0)
^!Left::	focusSwitch.moveFocus("L", 0)
^!Right::	focusSwitch.moveFocus("R", 0)


class focusSwitch {

	static blacklist := [
			"",
			"NVIDIA GeForce Overlay",
			"ahk_class MultitaskingViewFrame ahk_exe explorer.exe",
			"ahk_class Windows.UI.Core.CoreWindow",
			"ahk_class WorkerW ahk_exe explorer.exe",
			"ahk_class Progman ahk_exe explorer.exe",
			"ahk_class Shell_SecondaryTrayWnd ahk_exe explorer.exe",
			"ahk_class Shell_TrayWnd ahk_exe explorer.exe"
		]	; initial blacklist. Includes nvidia screen overlay, windows with no title, alt+tab screen, startmenu, desktop screen and taskbars (in that order).

	static monitors := this.getMonitors()
	/**
	 * Moves focus to closest window in given direction
	 * @param {Integer} vertical 1 = up, 0 = no change, -1 = down
	 * @param {Integer} horizontal 1 = right, 0 = no change, -1 = left
	 */
	static moveFocus(direction, limitToMonitor := true) {
		direction := SubStr(direction, 1, 1)
		if !(activeHwnd := WinExist("A"))
			return
		monitor := 0
		if (limitToMonitor) {
			WinGetPos(&x, &y, &w, &h, activeHwnd)
			for mon in this.monitors
				if (this.windowOnMonitor(x, y, w, h, mon))
					monitor := mon.number
		}
		coordinates := this.getDesktopWindows(monitor) ; get all coordinates of visible windows on screen.
		sortedByX := this.objSort(coordinates, a => a.x, "N")
		sortedByY := this.objSort(coordinates, a => a.y, "N")
		switch direction, 0 {
			case "L", "R":
				arr := sortedByX
				axis := "x", axis2 := "y"
				direction := (direction == "L" ? -1 : 1)
			case "U", "D":
				arr := sortedByY
				axis := "y", axis2 := "x"
				direction := (direction == "U" ? -1 : 1)
			default: 
				return
		}
		index := this.objContainsValue(arr, activeHwnd, (a, b) => (a.value.hwnd == b))
		if !(index)
			return
		curVal := arr[index].value.%axis%
		axis2Val := arr[index].value.%axis2%
		selectableWindows := []
		while(true) { ; there may be multiple windows with same x/y-coord
			index += direction
			if (index > arr.Length || index < 1)
				break
			if (direction == 1 && arr[index].value.%axis% > curVal) || (direction == -1 && arr[index].value.%axis% < curVal)
				selectableWindows.push(arr[index].value)
		}
		if !selectableWindows.Length
			return
		nextWindow := selectableWindows[1]
		for o in selectableWindows { ; if multiple windows are same distance from current one, but one is on same axis, prefer that one
			if nextWindow.%axis% != o.%axis%
				break
			else if o.%axis2% == axis2Val {
				nextWindow := o
				break
			}
		}
		WinActivate(nextWindow.hwnd)
	}

	static getDesktopWindows(monitor := 0) {
		windows := []
			wHandles := WinGetList()
		for i, wHandle in wHandles {
			for e in this.blacklist
				if ((e != "" && WinExist(e " ahk_id " wHandle)) || (e == "" && WinGetTitle(wHandle) == ""))
					continue 2
			WinGetPos(&x, &y, &w, &h, wHandle)
			if (monitor && !this.windowOnMonitor(x,y,w,h,this.monitors[monitor]))
				continue
			if !(WinGetMinMax(wHandle))
				windows.push({
					hwnd: wHandle, 
					title: WinGetTitle(wHandle),
					x: x, y: y, w: w, h: h
				})
		}
		return windows
	}

	static windowOnMonitor(x, y, w, h, mon) {
		middleX := x + w/2
		middleY := y + h/2
		return middleX > mon.Left && middleX < mon.Right && middleY > mon.Top && middleY < mon.Bottom
	}

	static objContainsValue(obj, value, comparator := ((iterator,value) => (iterator = value))) {
		isArrLike := (obj is Array || obj is Map)
		for i, e in (isArrLike ? obj : obj.OwnProps())
			if (comparator(e, value))
				return i
		return 0
	}

	static objSort(obj, fn := (a => a), mode := "") {
		isArrLike := obj is Array || obj is Map
		sortedArr := []
		indexMap := Map()
		counterMap := Map()
		if objGetValueCount(obj) == 0
			return sortedArr
		for i, e in objGetEnumerator(obj) {
			v := String(fn(e))
			if (indexMap.Has(v))
				indexMap[v].push(i)
			else {
				indexMap[v] := [i]
				counterMap[v] := 1
			}
			str .= v . "©"
		}
		sortMode := RegExReplace(sortMode, "D.")
		valArr := StrSplit(Sort(SubStr(str, 1, -1), sortMode . " D©"), "©")
		if isArrLike {
			for v in valArr {
				key := indexMap[v][counterMap[v]++]
				sortedArr.push({ key: key, value: obj[key]})
			}
		} else {
			for v in valArr {
				key := indexMap[v][counterMap[v]++]
				sortedArr.push({ key: key, value: obj.%key% })
			}
		}
		return sortedArr
	}

	static getMonitors() {
		monitors := []
		Loop(MonitorGetCount())
		{
			MonitorGet(A_Index, &mLeft, &mTop, &mRight, &mBottom)
			monitors.push({number:A_Index, Left:mLeft, Right:mRight, Top:mTop, Bottom:mBottom})
		}
		return monitors
	}
}

