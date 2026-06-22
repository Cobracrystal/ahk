#SingleInstance Force
#Include "LibrariesV2\cobracrystalBot.ahk"
#Include  "LibrariesV2\External\jsongo.ahk"
#Include  "LibrariesV2\ObjectUtilities.ahk"
FileEncoding("UTF-8")
SetWorkingDir(A_ScriptDir "\script_files\discordBot")

mainchat := Main.servers["clegends"]["channels"]["main"]
; bot.sendMessage(mainchat, {content: "<@" users["dev"] "> Ho Ho Ho. You forgot to remove this message."})
; Main.applyTheme("Original")
; notes: use admin role because manage channels is somehow broken and doesn't grant permission / discord revokes access
; notes: shitposting -> jingle-hell

class Main {
	static __New() {
		this.servers := jsongo.Parse(FileRead("servers.json", "UTF-8"))
		this.users := jsongo.Parse(FileRead("users.json", "UTF-8"))
		this.bot := CCBot(FileRead("discordBotToken.token", "UTF-8"))
		servers := objDoForEach(this.bot.getCurrentUserGuilds(), v => objFilter(v, (k, t) => (objContainsValue(["permissions", "name", "id"], k))))
		this.log("Started up. Servers Loaded: `n" toString(servers))
	}

	static log(msg) {
		static logChannel := this.servers["dev"]["channels"]["log"]
		if isObj := IsObject(msg)
			msg := toString(msg, 0, 1, 1)
		print(msg)
		if StrLen(msg) < 2000 {
			this.bot.sendMessage(logChannel, {content: isObj ? "``````" msg "``````" : msg})
		}
	}

	static applyTheme(themeName) {
		static clID := this.servers["clegends"]["id"]
		static clBotChID := this.servers["clegends"]["channels"]["bots"]
		this.bot.loadThemes(A_WorkingDir "\CLegends Colour Management - Season Themes (Roles Only).csv",
					A_WorkingDir "\CLegends Colour Management - Season Themes (Channels Only).csv", 1)
		print("Attempting to Apply Theme _" themeName "_")
		this.bot.sendMessage(clBotChID, {content:"Attempting to Apply Theme _" themeName "_"},)
		errorlog := this.bot.applyTheme(this.servers["clegends"], themeName, true)
		print("Errorlog: " errorlog)
		FileAppend(errorlog, "/output/errorlog_" themeName "_" A_Now ".txt", "UTF-8")
		this.bot.sendMessage(clBotChID, {content: "Errorlog: " errorlog})
		this.logServerState(themeName)
	}

	static logServerState(curTheme := "Original") {
		static clID := this.servers["clegends"]["id"]
		curDir := A_WorkingDir "\output\" FormatTime(A_Now, "yyyy_MM_dd-hh.mm.ss") "-" curTheme
		DirCreate(curDir)
		roles := this.bot.getGuildRoles(clID)
		FileAppend(jsongo.Stringify(roles,,"`t"), Format("{}\CL_roles.json", curDir), "UTF-8")
		channels := this.bot.getGuildChannels(clID)
		FileAppend(jsongo.Stringify(channels,, "`t"), Format("{}\CL_channels.json", curDir), "UTF-8")
	}
}

^+!R::{
	reload()
}
