#Include "%A_ScriptDir%\LibrariesV2\DiscordClient.ahk"

class cobracrystalBot {

	static __New() {
		this.workingDir := A_ScriptDir "\script_files\discordBot\"
		this.servers := this.readJson(this.workingDir "serverIDs.json")
		this.bot := DiscordClient(FileRead(this.workingDir "discordBotToken.token", "UTF-8"))
		this.me := this.bot.getCurrentUser()
		this.themes := {roles: Map(), channels: Map()}
		this.permissions := {
			CREATE_INSTANT_INVITE: 0x0000000000000001,
			KICK_MEMBERS: 0x0000000000000002,
			BAN_MEMBERS: 0x0000000000000004,
			ADMINISTRATOR: 0x0000000000000008,
			MANAGE_CHANNELS: 0x0000000000000010,
			MANAGE_GUILD: 0x0000000000000020,
			ADD_REACTIONS: 0x0000000000000040,
			VIEW_AUDIT_LOG: 0x0000000000000080,
			PRIORITY_SPEAKER: 0x0000000000000100,
			STREAM: 0x0000000000000200,
			VIEW_CHANNEL: 0x0000000000000400,
			SEND_MESSAGES: 0x0000000000000800,
			SEND_TTS_MESSAGES: 0x0000000000001000,
			MANAGE_MESSAGES: 0x0000000000002000,
			EMBED_LINKS: 0x0000000000004000,
			ATTACH_FILES: 0x0000000000008000,
			READ_MESSAGE_HISTORY: 0x0000000000010000,
			MENTION_EVERYONE: 0x0000000000020000,
			USE_EXTERNAL_EMOJIS: 0x0000000000040000,
			VIEW_GUILD_INSIGHTS: 0x0000000000080000,
			CONNECT: 0x0000000000100000,
			SPEAK: 0x0000000000200000,
			MUTE_MEMBERS: 0x0000000000400000,
			DEAFEN_MEMBERS: 0x0000000000800000,
			MOVE_MEMBERS: 0x0000000001000000,
			USE_VAD: 0x0000000002000000,
			CHANGE_NICKNAME: 0x0000000004000000,
			MANAGE_NICKNAMES: 0x0000000008000000,
			MANAGE_ROLES: 0x0000000010000000,
			MANAGE_WEBHOOKS: 0x0000000020000000,
			MANAGE_GUILD_EXPRESSIONS: 0x0000000040000000,
			USE_APPLICATION_COMMANDS: 0x0000000080000000,
			REQUEST_TO_SPEAK: 0x0000000100000000,
			MANAGE_EVENTS: 0x0000000200000000,
			MANAGE_THREADS: 0x0000000400000000,
			CREATE_PUBLIC_THREADS: 0x0000000800000000,
			CREATE_PRIVATE_THREADS: 0x0000001000000000,
			USE_EXTERNAL_STICKERS: 0x0000002000000000,
			SEND_MESSAGES_IN_THREADS: 0x0000004000000000,
			USE_EMBEDDED_ACTIVITIES: 0x0000008000000000,
			MODERATE_MEMBERS: 0x0000010000000000,
			VIEW_CREATOR_MONETIZATION_ANALYTICS: 0x0000020000000000,
			USE_SOUNDBOARD: 0x0000040000000000,
			CREATE_GUILD_EXPRESSIONS: 0x0000080000000000,
			CREATE_EVENTS: 0x0000100000000000,
			USE_EXTERNAL_SOUNDS: 0x0000200000000000,
			SEND_VOICE_MESSAGES: 0x0000400000000000,
		}
	}

	static loadThemes(filepathRoles?, filepathChannels?, save := true) {
		if (IsSet(filepathRoles)) {
			SplitPath(filepathRoles, , , &ext)
			if (ext == "csv")
				roleThemes := this.parseColorCSV(filepathRoles)
			else if (ext == "json")
				roleThemes := this.readJson(filepathRoles)
			else throw Error()
		}
		if (IsSet(filepathChannels)) {
			SplitPath(filepathChannels, , , &ext)
			if (ext == "csv")
				channelThemes := this.parseColorCSV(filepathChannels)
			else if (ext == "json")
				channelThemes := this.readJson(filepathChannels)
			else throw Error()
		}
		this.themes := {roles:roleThemes?, channels: channelThemes?}
		if (save)
			this.writeJson(this.themes, "themes")
	}
	
	static applyTheme(serverID, themeName) {
		; check if bot has permissions. 
		if (!this.hasPermissionInServer(serverID, "ANY", this.permissions.ADMINISTRATOR, this.permissions.MANAGE_ROLES))
			throw Error("Missing Permission to Edit Roles")
		errorlog := ""
		if (this.themes.roles.Has(themeName)) {
			try {
				roleTheme := this.themes.roles[themeName]
				guildRoles := this.bot.getRoles(serverID)
				highestRole := this.highestRole(serverID)
				rolesbyID := Map()
				for i, e in guildRoles
					rolesbyID[e["id"]] := e
				for i, e in roleTheme {
					if (rolesbyID.Has(i)) {
						if (rolesbyID[i]["position"] < highestRole["position"])
							this.bot.modifyGuildRole(serverID, i, e)
						else 
							errorlog .= "Did not edit Role " i "(" rolesbyID[i]["name"] ") because it was higher ranked than the Bot role.`n"
					}
					else
						errorlog .= "Did not edit Role " i " because wasn't found.`n"
				}
			}
			catch e {
				MsgBox(errorlog . e.Message "`n" e.What "`n" e.Extra)
			}
		}
		if (!this.hasPermissionInServer(serverID, "ANY", this.permissions.ADMINISTRATOR, this.permissions.MANAGE_CHANNELS))
			throw Error("Missing Permission to Edit Channels at all")
		if (this.themes.channels.Has(themeName)) {
			try {
				channelTheme := this.themes.channels[themeName]
				guildChannels := this.bot.getGuildChannels(serverID)
				channelIDs := []
				for i, e in guildChannels
					channelIDs.push(e["id"])
				for i, e in channelTheme {
					if (objContainsValue(channelIDs, i))
						this.bot.modifyChannel(i, e)
					else
						errorlog .= "Channel " i " not found.`n"
				}
			}
			catch e {
				MsgBox(errorlog . e.Message "`n" e.What "`n" e.Extra)
			}
		}
		msgbox(errorlog)
	}

	static isInGuild(serverID) {
		for i, e in this.bot.getCurrentUserGuilds()
			if (e["id"] == serverID)
				return true
		return false
	}

	static highestRole(serverID) {
		if (!this.isInGuild(serverID))
			return 0
		userRoleIDs := this.bot.getGuildMember(serverID, this.me["id"])["roles"]
		serverRoles := this.bot.getRoles(serverID)
		highestRolePos := 0
		highestRole := {}
		for i, e in serverRoles {
			if (objContainsValue(userRoleIDs, e["id"]) && e["position"] >= highestRolePos) {
				highestRolePos := e["position"]
				highestRole := e
			}
		}
		return highestRole
	}

	static permissionsInServer(serverID) {
		if !(this.isInGuild(serverID))
			return 0
		userRoleIDs := this.bot.getGuildMember(serverID, this.me["id"])["roles"]
		serverRoles := this.bot.getRoles(serverID)
		permissions := []
		for i, e in serverRoles {
			if (objContainsValue(userRoleIDs, e["id"])) {
				permissions.push(e["permissions"])
			}
		}
		finalPermissions := 0x0000000000000000
		for i, e in permissions
			finalPermissions := finalPermissions | Integer(e) ; bitwise or
		return finalPermissions
	}

	static hasPermissionInServer(serverID, mode, wantpermission*) {
		permissions := this.permissionsInServer(serverID)
		if (mode = "ANY" || mode = "OR") {
			for i, e in wantpermission {
				if (e & permissions)
					return true
			}
			return false
		}
		p := 0x0000000000000000
		for i, e in wantpermission
			p := p | e
		return (permissions & p)
	}

	; helper functions

	static writeJson(obj, name) {
		nfile := FileOpen(this.workingDir "output\" name ".json", "w", "UTF-8")
		nfile.Write(jsongo.Stringify(obj, , "`t"))
		nfile.Close()
	}

	static readJson(path) {
		return jsongo.Parse(FileRead(path, "UTF-8"))
	}

	static parseColorCSV(path) { ; make sure its a proper csv. (no unescaped commas)
		content := FileRead(path)
		cols := []
		colCount := 0
		Loop parse, content, "`n", "`r" {
			Loop Parse, A_LoopField, "CSV"
				colCount := A_Index
			break
		}
		cols.Length := colCount ; number of columns.
		Loop Parse, content, "`n", "`r" {
			line := A_Index
			Loop Parse, A_LoopField, "CSV" {
				if (line == 1) { ; IF WE ARE IN THE FIRST LINE AKA THE HEADERS, THEN SAVE THOSE.
					if (A_LoopField != "")
						cols[A_Index] := {name: A_LoopField, rows: Map() }
				}
				else { ; NOT IN FIRST LINE -> SAVE [UNDER] HEADERS. if cols has index, it must have a header.
					if (cols.Has(A_Index) && A_LoopField != "" && Trim(A_LoopField) != "–" && Trim(A_LoopField) != "-" && !InStr(A_LoopField, "no rename") && !InStr(A_LoopField, "?"))
						cols[A_Index].rows[line] := A_LoopField
				}
			}
		}
		IDArray := []
		for i, e in cols { ; the only thing this loop does is extract the ID column and delete it from the columns.
			if (!IsSet(e)) 
				continue
			if (e.name == "ID") {
				IDArray := e.rows.Clone()
				cols.Delete(i)
			}
		}
		; construct obj
		themes := Map()
		for i, e in cols {
			if (!IsSet(e)) ; e isn't set means there is no header. then, everything in the column is ignored.
				continue
			; in case of roles: two consecutive columns with name | hex
			if (Instr(e.name, "name", false) && cols.Has(i+1) && InStr(cols[i+1].name, "HEX", false)) {
				tArr := Map()
				for j, f in IDArray {
					tObj := {} ; set id to role
					if (e.rows.Has(j))
						tObj.name := String(e.rows[j]) ; set name if exists
					if (cols[i+1].rows.Has(j) && RegexMatch(cols[i+1].rows[j], "^[[:xdigit:]]{6}$"))
						tObj.color :=  Number("0x" cols[i+1].rows[j])
					if (tObj.HasOwnProp("name") || tObj.HasOwnProp("color"))
						tArr[String(f)] := tObj
				}
				title := Trim(StrReplace(StrReplace(e.name, "name", "", false), "  ", " "))
				themes[title] := tArr ; array of objects with {id, name, color?}
			}
			; in case of channels and its a SOLO column -> its name
			else if ((i == 1 || !cols.Has(i-1)) && !cols.Has(i+1) && Instr(e.name, "name", false)) {
				tArr := Map()
				for j, f in IDArray {
					tObj := {} ; set id to role
					if (e.rows.Has(j))
						tObj.name := String(e.rows[j]) ; set role name
					if (!tObj.HasOwnProp("name"))
						continue
					else 
						tArr[String(f)] := tObj
				}
				title := Trim(StrReplace(StrReplace(e.name, "name", "", false), "  ", " "))
				themes[title] := tArr ; array of objects with {id, name, color}
			}
		}
		return themes
	}
}