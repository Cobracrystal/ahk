A_WorkingDir := A_ScriptDir "\..\script_files\everything\zahlen"
if !(InStr(FileExist(A_WorkingDir "\output"), "D"))
	DirCreate("output")
numberAsStr := FileRead(A_WorkingDir "\pi.txt")
outputFileList := A_WorkingDir "\list.txt"
FileOpen(outputFileList, "w").Write(makeList(numberAsStr, 100))
cmdStr := 'ffmpeg -f concat -safe 0 -i "' outputFileList '" -c copy ' A_WorkingDir "\output\" A_Now ".mp3"
Run("cmd /k echo " cmdStr " && " cmdStr)


makeList(str, length) {
	template := "file '" A_WorkingDir "\{}'`n"
	list := ""
	allowedArr := Map()
	loop files "*.mp3"
		allowedArr[StrReplace(A_LoopFileName, ".mp3")] := Format(template, A_LoopFileName)
	loop parse str {
		if (A_Index > length)
			break
		if (allowedArr.Has(A_LoopField))
			list .= allowedArr[A_LoopField]
		else
			list .= allowedArr["äh"]
	}
	return list
}