#Persistent
#EscapeChar `
#MaxMem 4095
#Include %A_ScriptDir%\Libraries\BasicUtilities.ahk
#Include %A_ScriptDir%\Libraries\JSON.ahk
#Include %A_ScriptDir%\Libraries\Jxon.ahk
#Include %A_ScriptDir%\Libraries\DiscordClient.ahk
SendMode, Input
SetWorkingDir %A_ScriptDir%\script_files\discordBot
bot := new DiscordClient(readFileIntoVar(A_WorkingDir . "\discordBotToken.token"))

; text := "Test uwu"
channelID := "346615877346525185"
serverIDCLegends := "356823991215980544"
serverIDmyown := "346615877346525184"
return


^+R::
reload
return

^+l::
fgetFullServerMembers(bot, serverIDmyown, true, false, sID . "_" . formatTimeFunc(A_Now, "yyyyMMdd-HHmmss") . "_members.json")
return

^+ö::
js := readFileIntoVar(A_WorkingDir . "\clMessages_1000_910602796_356843297790099457.json")
obj := JSON.Load(js)
FileAppend, % JSON.Dump(getAuthors(obj)), % "cl_Authors_ChillLounge_past100k.json"
return

^+ü::
js := readFileIntoVar(A_WorkingDir . "\cl_Authors_ChillLounge_past100k.json")
arr := sortKeyArray(JSON.Load(js), "count", "N R")
FileAppend % Json.Dump(arr), % "cl_Authors_Sorted.json"
return


getAuthors(msgs) {
	authors := {}
	authors[1] := { "username" : "Total Message Count", "count": msgs.Count() * msgs[1].Count() }
	for i, e in msgs
	{
		for ii, msg in e
		{
			pos := keyArrayContains(authors, "id", msg.author.id)
			if (pos)
				authors[pos].count += 1
			else
				authors.push({ "count" : 1, "id": msg.author.id, "username" : msg.author.username, "global_name" : msg.author.global_name, "avatar" : msg.author.avatar})
		}
	}
	return authors
}

fgetMessages(ByRef bot, cID, n := 1, showProgress := false, singleRet := false, path := "messages.json") {
	bigObj := bot.getMessages(cID, lim)
	lastID := bigObj[bigObj.Count()].id
	if (!singleRet) {
		f := FileOpen(path, "w")
		f.Write("[" . JSON.Dump(bigObj) . ",")
		f.Seek(0)
	}
	Loop % n-1
	{
		if (showProgress)
			Tooltip % Format("{:d}%", (A_Index+1) * 100/n)
		msgs := bot.getMessages(cID, lim, "before", lastID)
		lastID := msgs[msgs.Count()].id
		if (singleRet)
			bigObj.insertAt(1, msgs)
		else {
			f.Write(JSON.Dump(bigObj) . (A_Index == n-1 ? "" : ","))
			f.Seek(0)
		}
	}
	if (showProgress)
		Tooltip 
	if (singleRet)
		return bigObj
	f.Write("]")
	f.Close()
	return 1
}

fgetFullServerMembers(ByRef bot, serverID, showProgress := false, singleRet := false, path := "members.json") {
	n := bot.getGuild(serverID, true).approximate_member_count
	n := n // 1000 + 2
	bigObj := {}
	prevID := 0
	if (!singleRet)
		FileAppend, % "[", % path
	Loop % n
	{
		vMembers := bot.getMembers(sID, "1000", prevID)
		if (vMembers.Count() == 0)
			break
		prevID := vMembers[vMembers.Count()].user.id
		if (singleRet)
			bigObj.push(vMembers)
		else
			FileAppend, % JSON.dump(vMembers) . (A_Index == n ? "" : ","), % path
		if (showProgress)
			Tooltip % A_Index * 1000 . " members got"
	}
	if (showProgress)
		Tooltip
	if (singleRet)
		return bigObj
	FileAppend, % "]", % path
	return 1
}