#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SetWorkingDir %A_ScriptDir%\script_files\GlobesweeperSaves
#Persistent
IniRead, counter, GlobesweeperSaves.ini, variables, counter, 1
savestatebackup()
SetTimer, savestatebackup, 240000
return

savestatebackup() {
	global counter
	if WinActive("ahk_exe Globesweeper.exe") {
		ToolTip, saving
		WinClose, ahk_exe Globesweeper.exe
		Sleep, 4000
		FileCopy, C:\Users\Simon\AppData\LocalLow\IncandescentGames\Globesweeper\*.dat, %counter%*.*
		counter++
		IniWrite, %counter%, GlobesweeperSaves.ini, variables, counter
		Run, steam://launch/982220
		ToolTip
	}
}

^+!P::
savestaterestore()
return

savestaterestore() {
	SetTimer, savestatebackup, off
	WinClose, ahk_exe Globesweeper.exe
	Sleep, 3000
	i := counter-1
	FileCopy, %i%GameInfo.dat, C:\Users\Simon\AppData\LocalLow\IncandescentGames\Globesweeper\GameInfo.dat, true
	FileCopy, %i%GamePref.dat, C:\Users\Simon\AppData\LocalLow\IncandescentGames\Globesweeper\GamePref.dat, true
	FileCopy, %i%GameStat.dat, C:\Users\Simon\AppData\LocalLow\IncandescentGames\Globesweeper\GameStat.dat, true
	Sleep, 1000
	SetTimer, savestatebackup, 120000
	Run, steam://launch/982220
}