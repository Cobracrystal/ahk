#SingleInstance Force ; replace old instance immediately

; folder to copy to: <user>\Documents\USB_BACKUP
folderToCopyTo := A_MyDocuments . "\USB_BACKUP"

; create folder if it doesn't exist yet
if !InStr(FileExist(folderToCopyTo), 'D')
	DirCreate(folderToCopyTo)

mainFunc(folderToCopyTo)

mainFunc(folderToCopyTo) {
	try {
		list := DriveGetList('REMOVABLE')
		while (true) {
			oldList := list
			list := DriveGetList('REMOVABLE')
			if (oldList != list) {
				arr1 := StrSplit(oldList)
				arr2 := StrSplit(list)
				if arr1.Length > arr2.Length
					continue
				for i, driveLetter in arr2 {
					if (driveLetter != arr1[i]) {
						Sleep(1000)
						copyContent(driveLetter, folderToCopyTo)
						break
					}
				}
				break
			}
			Sleep(100)
		}
	} catch {
		Sleep(10000)
		mainFunc(folderToCopyTo)
	}
}


copyContent(driveLetter, folderToCopyTo) {
	try {
		DirCopy(driveLetter ':\', folderToCopyTo '\' driveLetter '_backup', 1)
	} catch {
		return
	}
}
