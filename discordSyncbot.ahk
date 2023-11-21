#Persistent
#Include %A_ScriptDir%\Libraries\JSON.ahk
#Include %A_ScriptDir%\Libraries\Discord.ahk
SendMode, Input
token := readFileIntoVar(A_ScriptDir . "\script_files\discordBotToken.token")
SetWorkingDir %A_ScriptDir%\script_files\discordBot
bot := new Discord(token)
return



;// TRY REMAKING DISCORD.AHK BY EXTENDING WEBSOCKE CLASS ??? MAYBE
^k::
bot.sendMessage("346615877346525185", "screams")
return


^+r::
reload
return


readFileIntoVar(path, encoding := "UTF-8") {
	return FileOpen(path, "r", encoding).Read()
}