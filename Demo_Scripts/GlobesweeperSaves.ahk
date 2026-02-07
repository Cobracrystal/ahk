#Requires AutoHotkey >=v2.0
#SingleInstance Force  
Persistent()
SetWorkingDir(A_ScriptDir "\..\script_files\GlobesweeperSaves")
counter := IniRead("GlobesweeperSaves.ini", "variables", "counter", 1)
global timePerBackup := 300000
savestatebackup()
SetTimer(savestatebackup, timePerBackup)
return

savestatebackup(force := 0) {
	global counter
	static path := A_AppData "\..\LocalLow\IncandescentGames\Globesweeper"
	if (force || WinActive("ahk_exe Globesweeper.exe")) {
		ToolTip("saving")
		if !force
			WinClose("ahk_exe Globesweeper.exe")
		Sleep(4000)
		FileCopy(path "\GameInfo.dat", Format("{}_GameInfo.dat", counter))
		FileCopy(path "\GamePref.dat", Format("{}_GamePref.dat", counter))
		FileCopy(path "\GameStat.dat", Format("{}_GameStat.dat", counter))
		counter++
		IniWrite(counter, "GlobesweeperSaves.ini", "variables", "counter")
		Run("steam://launch/982220")
		ToolTip()
	}
}

^+!G::savestaterestore()

savestaterestore() {
	static path := A_AppData "\..\LocalLow\IncandescentGames\Globesweeper"
	SetTimer(savestatebackup, 0)
	try WinClose("ahk_exe Globesweeper.exe")
	Sleep(3000)
	i := counter - 1
	FileCopy(Format("{}_GameInfo.dat", i), path "\GameInfo.dat", true)
	FileCopy(Format("{}_GamePref.dat", i), path "\GamePref.dat", true)
	FileCopy(Format("{}_GameStat.dat", i), path "\GameStat.dat", true)
	Sleep(1000)
	SetTimer(savestatebackup, timePerBackup)
	Run("steam://launch/982220")
}