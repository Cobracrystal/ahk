#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
MsgBox, % "Dies ist eine hochoffizielle ytdlp herunterladeanwendung."
InputBox, outPath, very creative title, Bitte Pfad zum aktuellen youtube-dl.exe ordner hier eingeben
if ErrorLevel
{
	msgbox bye then
	return
}
if (!Instr(FileExist(outPath),"D")) {
	msgbox ne, der pfad ist so nicht richtig. Bitte nochmal.
	reload
}
else {
	SetWorkingDir % outPath
	Msgbox, 4, noch kreativerer titel, ytdlp herunterladen?
	ifMsgbox no
		msgbox ok dann halt nicht
	else {
		UrlDownloadToFile, https://github.com/yt-dlp/yt-dlp/releases/download/2023.03.04/yt-dlp.exe, yt-dlp.exe
		msgbox yt-dlp wurde heruntergeladen.
	}
	if !(InStr(FileExist(A_AppData . "\yt-dlp"), "D")) {
		msgbox created yt-dlp config folder
		FileCreateDir, % A_Appdata . "\yt-dlp"
	}
	else {
		if (FileExist(A_Appdata . "\yt-dlp\config.txt")) {
			msgbox, 4, ultrakreativer titel, found a config file in Appdata\Roaming\yt-dlp\config.txt`nSkip config copy?
			if MsgBox Yes
				flagc := true
		}
	}
	if (!flagc) {
		if (!FileExist(A_AppData . "\youtube-dl\config.txt")) {
			InputBox, outYTDLCONFIGPATH, unfassbar genial kreativer titel, config-datei von youtube-dl wurde nicht gefunden. Sie sollte in appdata\youtube-dl liegen. den pfad zu dieser configdatei bitte hier eingeben. Falls dieser unbekannt ist, bitte potet anschreiben
			if (InStr(FileExist(outYTDLCONFIGPATH),"D")) {
				if (FileExist(outYTDLCONFIGPATH . "\config.txt"))
					configPath := outYTDLCONFIGPATH . "\config.txt"
				else {
					msgbox ne, der pfad ist so nicht richtig. und nochmal
					reload
				}
			}
			else if (FileExist(outYTDLCONFIGPATH))
				configPath := outYTDLCONFIGPATH
			else {
				msgbox ne, der pfad ist so nicht richtig. und nochmal
				reload
			}
		}
		else {
			configPath := A_AppData . "\youtube-dl\config.txt"
			msgbox found youtube-dl config at %A_AppData%\youtube-dl\config.txt
		}
		Msgbox, 4, unfassbar supermegakreativer titel, % "Copy config from`n" . configPath . "`n to`n" . A_Appdata . "\yt-dlp\config.txt ?"
		ifMsgBox yes
		{
			FileCopy, % configPath, % A_Appdata . "\yt-dlp\config.txt", 1
		}
		else 
			InputBox, aaaaaaa, ?, bitte gib hier in einem 500-Wort-Essay an, wieso
	}
	Msgbox, 4, dies ist kein titel, yt-dlp mit --config-location starten`, um die configdatei zu setzen?
	ifmsgbox yes
	{
		Run, % "yt-dlp.exe --no-download --config-location """ . A_Appdata . "\yt-dlp\config.txt"""
	}
	msgbox, 4, dies ist ein titel, youtube-dl löschen?
	ifmsgbox yes
	{
		if (fileexist("youtube-dl.exe"))
			FileDelete, youtube-dl.exe
		else if (fileexist("yt-dl.exe"))
			FileDelete, yt-dl.exe
		else if (FileExist("ytdl.exe"))
			FileDelete, ytdl.exe
		else {
			msgbox youtuble-dl.exe nicht gefunden. tja.
		}
	}
	msgbox installation professional abgeschlossen. Als Bonus wird nun ein fuchsbild heruntergeladen. Dies kann nicht verhindert werden.
	UrlDownloadToFile, https://www.pbs.org/wnet/nature/files/2017/09/x1WLcZn-asset-mezzanine-16x9-6kkb4dA.jpg, fox.jpg
}
return
