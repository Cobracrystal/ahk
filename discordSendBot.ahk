#Persistent
#EscapeChar `
#Include %A_ScriptDir%\Libraries\JSON.ahk
#Include %A_ScriptDir%\Libraries\Jxon.ahk
#Include %A_ScriptDir%\Libraries\DiscordClient.ahk
SendMode, Input
token := readFileIntoVar(A_ScriptDir . "\script_files\discordBotToken.token")
SetWorkingDir %A_ScriptDir%\script_files\discordBot
bot := new DiscordClient(token)

; text := "Test uwu"
channelID := "346615877346525185"
return

readFileIntoVar(path, encoding := "UTF-8") {
		dataFile := FileOpen(path, "r", encoding)
		return dataFile.Read()
}

^+R::
reload
return

^k::
; bot.sendMessage("test", "346615877346525185")
bot.sendMessage("test", "245189840470147072", 1)
return

^ö::
msgbox % JSON.dump(bot.getMessage("346615877346525185", "1028307466502545538"))
return

^l::
i := 0
out := bot.getMessages(channelID)
parsed := JSON.Load(out)
for ii, e in parsed
{
	msgbox % ii . ":" . e.content
}
msgbox % i
return

^ä::
bot.sendMessage("test", channelID)
return

