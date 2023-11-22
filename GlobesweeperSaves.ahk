SetWorkingDir(A_ScriptDir "\script_files\GlobesweeperSaves")
Persistent()
IniRead("GlobesweeperSaves.ini", "variables", "counter", 1)
savestatebackup()
SetTimer(savestatebackup, 240000)
return

savestatebackup() {
	global counter
	if WinActive("ahk_exe Globesweeper.exe") {
		ToolTip("saving")
		WinClose("ahk_exe Globesweeper.exe")
		Sleep(4000)
		FileCopy(A_AppData "\..\LocalLow\IncandescentGames\Globesweeper\*.dat", "counter*.*")
		counter++
		IniWrite(counter, "GlobesweeperSaves.ini", "variables", "counter")
		Run("steam://launch/982220")
		ToolTip()
	}
}

^+!P::savestaterestore()

savestaterestore() {
	SetTimer(savestatebackup, 0)
	WinClose("ahk_exe Globesweeper.exe")
	Sleep(3000)
	i := counter-1
	FileCopy(i "GameInfo.dat", A_Appdata "\..\LocalLow\IncandescentGames\Globesweeper\GameInfo.dat", true)
	FileCopy(i "GamePref.dat", A_Appdata "\..\LocalLow\IncandescentGames\Globesweeper\GamePref.dat", true)
	FileCopy(i "GameStat.dat", A_Appdata "\..\LocalLow\IncandescentGames\Globesweeper\GameStat.dat", true)
	Sleep(1000)
	SetTimer(savestatebackup, 120000)
	Run("steam://launch/982220")
}