#SingleInstance Force ; replace old instance immediately

; folder to copy to: <user>\Documents\USB_BACKUP
folderToCopyTo := A_MyDocuments . "\USB_BACKUP"

; create folder if it doesn't exist yet
if !InStr(FileExist(folderToCopyTo), 'D')
	DirCreate(folderToCopyTo)

mainFunc(folderToCopyTo)

mainFunc(folderToCopyTo) {
	try {
		oldDrives := DriveGetList()
	} catch {
		Sleep(100)
		mainFunc(folderToCopyTo)
		return
	}
	while (true) {
		try {
			newDrives := DriveGetList()
			if (newDrives != oldDrives) {
				compare := oldDrives
				oldDrives := newDrives
				if StrLen(compare) > StrLen(newDrives)
					continue
				loop parse newDrives {
					if !InStr(compare, A_LoopField) {
						Sleep(300)
						copyContent(A_LoopField, folderToCopyTo)
						break
					}
				}
			}
		} catch as e {
			error_map := Map(
				3, "ERROR_PATH_NOT_FOUND",
				82, "ERROR_CANNOT_MAKE",
				80, "ERROR_FILE_EXISTS",
				83, "ERROR_FAIL_I24"
			)
			; MsgBox(error_map[A_LastError])
			; throw e
			Sleep(1000)
			continue
		}
		Sleep(100)
	}
}


copyContent(driveLetter, folderToCopyTo) {
	path := folderToCopyTo '\' driveLetter '_backup\'
	if !DirExist(path)
		DirCreate(path)
	try {
		loop files driveLetter ':\*', 'FD' {
			if InStr(A_LoopFileAttrib, 'S') ; skip system files
				continue
			if InStr(A_LoopFileAttrib, 'D')
				DirCopy(A_LoopFileFullPath, path . A_LoopFileName, 1)
			else
				FileCopy(A_LoopFileFullPath, path A_LoopFileName, 1)
		}
	} catch as e {
		; throw e
		return
	}
}