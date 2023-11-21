#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.

wallpaperPath := "C:\Program Files (x86)\Steam\SteamApps\workshop\content\431960"
repkgPath := "C:\Users\Simon\Desktop\programs\other\RePKG"
return

^k::
mainFunc()
return

mainFunc() {
	global wallpaperPath, repkgPath
	listObj := getScenefiles(wallpaperPath)
	if (!listObj)
		return
	str := ""
	for i, e in listObj
		str .= e.shortPath . ": " . e.time . ": " . e.title . "`n"
	Clipboard := str
}

getScenefiles(wallpaperFolderPath) {
	FileSelectFile, file, 3, %wallpaperFolderPath%
	if !(file)
		return 0
	folder := RegexReplace(file, "\\[^\\]+$")
	o := {}
	listString := ""
	FileGetTime, origfolderTime, %folder%, C
	Loop, Files, % wallpaperFolderPath . "\*.*", FD
	{
		title := verifyFile(A_LoopFilePath)
		if (title == 0 || title == -1)
			continue
		else {
			tFolderTime := A_LoopFileTimeCreated
			EnvSub, tFolderTime, origfolderTime, Seconds
		;	if (tFolderTime < 0)
		;		continue
			listString .= tFolderTime . "`t" . A_LoopFilePath . "`t" . A_LoopFileName . "`t" . title . "`n"
		}
	}
	Sort, listString, N ;// does by date per default
	Loop, Parse, listString, `n
	{
		if ( A_LoopField == "")
			continue 
		arr := StrSplit(A_Loopfield, A_Tab)
		o.Push({"path":arr[2], "shortPath":arr[3], "title": arr[4], "time":arr[1]})
	}
	return o
}

verifyFile(folderPath) {
	if !(FileExist(folderPath . "\scene.pkg"))
		return -1
	jsonFile := FileOpen(folderPath . "\project.json", "r", "UTF-8")
	jsonText := jsonFile.Read()
	if !(Instr(jsonText, """contentrating"" : ""Mature"""))
		return 0
	RegexMatch(jsonText, "O)""title"" : ""(.*?)""", m)
	return m.Value(1)
}

extractRepkg(a) {
	return
}


^+R::
reload
