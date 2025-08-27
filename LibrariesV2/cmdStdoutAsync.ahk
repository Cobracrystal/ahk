/*
Written by teadrinker https://www.autohotkey.com/boards/viewtopic.php?t=112734
RegisterWaitCallback by Lexikos

Slightly modified from original to 
a) fix the example which had issues with async (and also wasnt the most readable) 
and b) 
allow instances from the class to be handled without having to declare them global or have the thread wait until the function is finished.
RegisterWaitCallback's handling of params caused ahk to garbage collect the entire class before it finished operating, which is why there is a
circular reference now
*/

#Requires AutoHotkey v2
; example:
F3:: {
	static g := createGui()
	static updateGui := ReadOutput.bind(g)
	updateGui("", -3) ; reset the gui. -3 is arbitrary unused value
	CmdStdOutAsync('ping google.com', , updateGui)
}

createGui() {
	myGui := Gui('+Resize', 'Async reading of stdout')
	myGui.MarginX := myGui.MarginY := 0
	myGui.SetFont('s12', 'Calibri')
	myGui.AddText('x10 y10', 'Complete: ')
	myGui.AddText('x+5 yp w100 vComplete', 'false')
	cEdit := myGui.AddEdit('xm y+10 w600 h400 vEdit')
	cEdit.GetPos(, &y := unset)
	myGui.OnEvent('Size', (o, m, w, h) => cEdit.Move(, , w, h - y))
	myGui.OnEvent('Close', (*) => ExitApp())
	return myGui
}

ReadOutput(myGui, line, complete := 0) {
	static fullOutput := ""
	if complete == -3 && !DllCall('IsWindowVisible', 'Ptr', myGui.hwnd)
		return myGui.show()
	fullOutput .= line
	myGui["Edit"].Value := fullOutput
	myGui["Complete"].Value := complete == -1 ? 'timed out' : complete = false ? 'false' : 'true'
	if complete {
		MsgBox(fullOutput, 'Complete stdout', 0x2040)
		fullOutput := ""
	}
}

class CmdStdOutAsync {
	__New(cmd, encoding?, callback?, timeOut?) {
		encoding := encoding ?? 'cp' . DllCall('GetOEMCP', 'UInt')
		this.event := CmdStdOutAsync.Event()
		this.params := {
			buf: Buffer(4096, 0),
			overlapped: Buffer(A_PtrSize * 3 + 8, 0),
			hEvent: this.event.handle,
			outData: '',
			encoding: encoding,
			complete: false
		}
		if IsSet(callback)
			this.params.callback := callback
		if IsSet(timeOut) {
			this.params.timeOut := timeOut
			this.params.startTime := A_TickCount
		}
		this.process := CmdStdOutAsync.Process(this, cmd, this.params) ; MODIFIED: Add circular reference
		this.signal := CmdStdOutAsync.EventSignal(this, this.process, this.params) ; MODIFIED: Add circular reference
		this.process.Read()
	}

	processID {
		get => this.process.PID
	}

	complete {
		get => this.params.complete
	}

	outData {
		get => this.params.outData
	}

	clear() { ; MODIFIED: Final actions are called manually upon error, timeout or completion
		DllCall('CancelIoEx', 'Ptr', this.process.hPipeRead, 'Ptr', this.params.overlapped)
		this.event.Set()
		this.signal.Clear()
		this.process.Clear()
	}

	__Delete() { ; MODIFIED: Unsure if these are actually needed, but for the sake of modifying as little as possible, kept
		this.params.buf.Size := 0
		this.params.outData := '' 
	}

	class Event {
		__New() => this.handle := DllCall('CreateEvent', 'Int', 0, 'Int', 0, 'Int', 0, 'Int', 0, 'Ptr')
		__Delete() => DllCall('CloseHandle', 'Ptr', this.handle)
		Set() => DllCall('SetEvent', 'Ptr', this.handle)
	}

	class Process {
		__New(classObj, cmd, info) {
			this.classObj := classObj ; MODIFIED: Add circular reference
			this.info := info
			this.CreatePipes()
			if !this.PID := this.CreateProcess(cmd) {
				classObj.clear() ; MODIFIED: Remove circular reference
				throw MethodError('Failed to create process')
			}
		}

		CreatePipes() {
			static FILE_FLAG_OVERLAPPED := 0x40000000, PIPE_ACCESS_INBOUND := 0x1, pipeMode := (PIPE_TYPE_BYTE := 0) | (PIPE_WAIT := 0), GENERIC_WRITE := 0x40000000, OPEN_EXISTING := 0x3, FILE_ATTRIBUTE_NORMAL := 0x80, HANDLE_FLAG_INHERIT := 0x1

			this.hPipeRead := DllCall('CreateNamedPipe', 'Str', pipeName := '\\.\pipe\StdOut_' . A_TickCount, 'UInt', PIPE_ACCESS_INBOUND | FILE_FLAG_OVERLAPPED, 'UInt', pipeMode, 'UInt', 1, 'UInt', this.info.buf.Size, 'UInt', this.info.buf.Size, 'UInt', 120000, 'Ptr', 0, 'Ptr')
			this.hPipeWrite := DllCall('CreateFile', 'Str', pipeName, 'UInt', GENERIC_WRITE, 'UInt', 0, 'Ptr', 0, 'UInt', OPEN_EXISTING, 'UInt', FILE_ATTRIBUTE_NORMAL | FILE_FLAG_OVERLAPPED, 'Ptr', 0, 'Ptr')
			DllCall('SetHandleInformation', 'Ptr', this.hPipeWrite, 'UInt', HANDLE_FLAG_INHERIT, 'UInt', HANDLE_FLAG_INHERIT)
		}

		CreateProcess(cmd) {
			static STARTF_USESTDHANDLES := 0x100, CREATE_NO_WINDOW := 0x8000000
			STARTUPINFO := Buffer(siSize := A_PtrSize * 9 + 4 * 8, 0)
			NumPut('UInt', siSize, STARTUPINFO)
			NumPut('UInt', STARTF_USESTDHANDLES, STARTUPINFO, A_PtrSize * 4 + 4 * 7)
			NumPut('Ptr', this.hPipeWrite, STARTUPINFO, siSize - A_PtrSize * 2)
			NumPut('Ptr', this.hPipeWrite, STARTUPINFO, siSize - A_PtrSize)

			PROCESS_INFORMATION := Buffer(A_PtrSize * 2 + 4 * 2, 0)
			if !DllCall('CreateProcess', 'Ptr', 0, 'Str', cmd, 'Ptr', 0, 'Ptr', 0, 'UInt', true, 'UInt', CREATE_NO_WINDOW, 'Ptr', 0, 'Ptr', 0, 'Ptr', STARTUPINFO, 'Ptr', PROCESS_INFORMATION)
				return this.Clear()
			DllCall('CloseHandle', 'Ptr', this.hPipeWrite), this.hPipeWrite := 0
			return NumGet(PROCESS_INFORMATION, A_PtrSize * 2, 'UInt')
		}

		Read() {
			buf := this.info.buf, overlapped := this.info.overlapped
			overlapped.__New(overlapped.Size, 0)
			NumPut('Ptr', this.info.hEvent, overlapped, A_PtrSize * 2 + 8)
			bool := DllCall('ReadFile', 'Ptr', this.hPipeRead, 'Ptr', buf, 'UInt', buf.Size, 'UIntP', &size := 0, 'Ptr', overlapped)
			if bool {
				this.info.outData .= str := StrGet(buf, size, this.info.encoding)
				if this.info.HasProp('callback')
					SetTimer(this.info.callback.Bind(str), -10)
				this.Read()
			}
			else if !bool && A_LastError != ERROR_IO_PENDING := 997 {
				this.info.complete := true
				if this.info.HasProp('callback') {
					SetTimer(this.info.callback.Bind('', true), -10)
					this.classObj.Clear() ; MODIFIED: Remove circular reference
				}
			}
		}

		Clear() {
			DllCall('CloseHandle', 'Ptr', this.hPipeRead)
			if this.hPipeWrite
				DllCall('CloseHandle', 'Ptr', this.hPipeWrite)
			this.DeleteProp("classObj") ; MODIFIED: Remove circular reference
		}
	}

	class EventSignal {
		__New(classObject, stdOut, info) {
			this.classObj := classObject ; MODIFIED: Add circular reference
			this.info := info
			this.stdOut := stdOut
			this.onEvent := this.Signal.bind(this)
			timeout := info.HasProp('timeOut') ? info.timeOut : -1
			this.regWait := this.RegisterWaitCallback(this.info.hEvent, this.onEvent, timeout)
		}

		Signal(handle, timedOut) {
			if timedOut {
				if this.info.HasProp('callback')
					SetTimer(this.info.callback.Bind('', -1), -10)
				this.classObj.Clear()  ; MODIFIED: Remove circular reference
				return
			}
			if !DllCall('GetOverlappedResult', 'Ptr', handle, 'Ptr', this.info.overlapped, 'UIntP', &size := 0, 'UInt', false) {
				if this.info.HasProp('callback')
					SetTimer(this.info.callback.Bind('', true), -10)
				this.classObj.Clear()  ; MODIFIED: Remove circular reference
				return this.info.complete := true
			}
			this.info.outData .= str := StrGet(this.info.buf, size, this.info.encoding)
			if this.info.HasProp('callback')
				SetTimer(this.info.callback.Bind(str), -10)
			this.stdOut.Read()
			timeout := this.info.HasProp('timeOut') ? this.info.timeOut - A_TickCount + this.info.startTime : -1
			this.regWait := this.RegisterWaitCallback(this.info.hEvent, this.onEvent, timeout)
		}

		Clear() {
			this.regWait.Unregister()
			this.DeleteProp('regWait')
			this.DeleteProp('onEvent')
			this.DeleteProp('classObj')
		}

		RegisterWaitCallback(handle, callback, timeout := -1) {
			; by lexicos https://www.autohotkey.com/boards/viewtopic.php?t=110691
			static waitCallback, postMessageW, wnd, nmsg := 0x5743
			if !IsSet(waitCallback) {
				if A_PtrSize = 8 {
					NumPut('int64', 0x8BCAB60F44C18B48, 'int64', 0x498B48C18B4C1051, 'int64', 0x20FF4808, waitCallback := Buffer(24))
					DllCall('VirtualProtect', 'ptr', waitCallback, 'ptr', 24, 'uint', 0x40, 'uint*', 0)
				}
				else {
					NumPut('int64', 0x448B50082444B60F, 'int64', 0x70FF0870FF500824, 'int64', 0x0008C2D0FF008B04, waitCallback := Buffer(24))
					DllCall('VirtualProtect', 'ptr', waitCallback, 'ptr', 24, 'uint', 0x40, 'uint*', 0)
				}
				postMessageW := DllCall('GetProcAddress', 'ptr', DllCall('GetModuleHandle', 'str', 'user32', 'ptr'), 'astr', 'PostMessageW', 'ptr')
				wnd := Gui(), DllCall('SetParent', 'ptr', wnd.hwnd, 'ptr', -3)    ; HWND_MESSAGE = -3
				OnMessage(nmsg, messaged, 255)
			}
			NumPut('ptr', postMessageW, 'ptr', wnd.hwnd, 'uptr', nmsg, param := CmdStdOutAsync.EventSignal.RegisteredWait())
			NumPut('ptr', ObjPtr(param), param, A_PtrSize * 3)
			param.callback := callback
			param.handle := handle
			if !DllCall('RegisterWaitForSingleObject', 'ptr*', &waitHandle := 0, 'ptr', handle, 'ptr', waitCallback, 'ptr', param, 'uint', timeout, 'uint', 8) {
				this.classObj.clear() ; MODIFIED: Remove circular reference
				throw OSError()
			}
			param.waitHandle := waitHandle
			param.locked := ObjPtrAddRef(param)
			return param

			static messaged(wParam, lParam, nmsg, hwnd) {
				if hwnd = wnd.hwnd {
					local param := ObjFromPtrAddRef(NumGet(wParam + A_PtrSize * 3, 'ptr'))
					(param.callback)(param.handle, lParam)
					param._unlock()
				}
			}
		}

		class RegisteredWait extends Buffer {
			static prototype.waitHandle := 0, prototype.locked := 0
			__new() => super.__new(A_PtrSize * 5, 0)
			__delete() => this.Unregister()
			_unlock() {
				if p := this.locked {
					this.locked := 0
					OutputDebug("rel: " ObjRelease(p) "`n")
				}
			}
			Unregister() {
				wh := this.waitHandle, this.waitHandle := 0
				if (wh)
					DllCall('UnregisterWaitEx', 'ptr', wh, 'ptr', -1)
				this._unlock()
			}
		}
	}
}
