#Include "%A_LineFile%\..\..\LibrariesV2\DiscordClient.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\jsongo.ahk"

class ccBot {

	__New(token) {
		this.workingDir := A_ScriptDir "\script_files\discordBot\"
		DirCreate(this.workingDir . "output")
		this.bot := DiscordClient(token, false)
		this.themes := {roles: Map(), channels: Map()}
	}
	/**
	 * @param filepathRoles A path to a file which is either a csv or a json containing a theme structure for Roles.
	 * @param filepathChannels A path to a file which is either a csv or a json containing a theme structure for Channels.
	 * Example Structure of a json for Roles:
	 * { "THEME_NAME_1": { "ROLE_ID": {"name":"THEMED_ROLE_NAME", "color":"THEMED_ROLE_COLOR"}, "ROLE_ID2": ..... }, "THEME_NAME_2": .....}
	 * and for Channels:
	 * { "THEME_NAME_1": { "CHANNEL_ID": {"name":"THEMED_ROLE_NAME"}, "CHANNEL_ID": ..... }, "THEME_NAME_2": .....}
	 * @param save if true, saves both roles and channels (if given) as json files into output folder
	 */
	loadThemes(filepathRoles?, filepathChannels?, save := true) {
		if (IsSet(filepathRoles)) {
			SplitPath(filepathRoles, , , &ext)
			if (ext == "csv")
				roleThemes := ccBot.parseColorCSV(filepathRoles)
			else if (ext == "json")
				roleThemes := ccBot.readJson(filepathRoles)
			else throw(Error())
		}
		if (IsSet(filepathChannels)) {
			SplitPath(filepathChannels, , , &ext)
			if (ext == "csv")
				channelThemes := ccBot.parseColorCSV(filepathChannels)
			else if (ext == "json")
				channelThemes := ccBot.readJson(filepathChannels)
			else throw(Error())
		}
		if !(IsSet(roleThemes) || IsSet(channelThemes))
			throw(Error("Nothing given."))
		this.themes := {roles:roleThemes??Map(), channels: channelThemes??Map()}
		if (save) {
			if IsSet(roleThemes)
				ccBot.writeJson(roleThemes, this.workingDir, "rolethemes")
			if IsSet(channelThemes)
				ccBot.writeJson(channelThemes, this.workingDir, "channelthemes")
		}
	}
	
	/**
	 * Applies a loaded theme to the specified server (which must correspond with the theme)
	 * @param serverID snowflake ID of the discord server the theme is applied to.
	 * @param themeName name of the theme as specified inside the theme files.
	 */
	applyTheme(serverID, themeName, silentError := 0) {
		; check if bot has permissions. 
		if (!this.bot.isInGuild(serverID))
			throw(Error("Bot is not in given Server."))
		errorlog := ""
		userRoles := this.bot.getGuildMember(serverID, this.bot.me["id"])["roles"]
		guildRoles := this.bot.getRoles(serverID)
		if (this.themes.roles.Has(themeName)) {
			if (!this.bot.hasPermissionInServer(userRoles, guildRoles, "ANY", Permissions.ADMINISTRATOR, Permissions.MANAGE_ROLES)) {
				if (silentError)
					errorlog .= "Missing permission to edit roles`n"
				else throw(Error("Missing permission to edit roles"))
			}
			try {
				rolesEditedCount := 0
				roleTheme := this.themes.roles[themeName]
				roleThemeOriginal := this.themes.roles["Original"]
				highestRole := this.bot.getHighestRole(userRoles, guildRoles)
				rolesbyID := Map()
				for i, e in guildRoles
					rolesbyID[e["id"]] := e
				for i, e in roleTheme {
					if (rolesbyID.Has(i)) {
						if (rolesbyID[i]["position"] < highestRole["position"]) {
							this.bot.modifyGuildRole(serverID, i, e)
							rolesEditedCount++ 
						}
						else 
							errorlog .= "Did not edit Role " i "(" rolesbyID[i]["name"] ") because it was higher ranked than the Bot role.`n"
					}
					else
						errorlog .= "Did not edit Role " i "(" ( roleThemeOriginal.Has(i) ? roleThemeOriginal[i] : "Unknown" ) ") because it wasn't found.`n"
				}
			}
			catch as e {
				MsgBox("Role Error: " errorlog . e.Message "`n" e.What "`n" e.Extra)
			} finally {
				errorlog .= rolesEditedCount . " roles edited.`n"
			}
		}
		if (this.themes.channels.Has(themeName)) {
			if (!this.bot.hasPermissionInServer(userRoles, guildRoles, "ANY", Permissions.ADMINISTRATOR, Permissions.MANAGE_CHANNELS)) {
				if (silentError)
					errorlog .= "Missing permission to edit channels`n"
				else throw(Error("Missing permission to edit channels"))
			}
			try {
				channelsEditedCount := 0
				channelTheme := this.themes.channels[themeName]
				channelThemeOriginal := this.themes.channels["Original"]
				guildChannels := this.bot.getGuildChannels(serverID)
				channelIDs := []
				for i, e in guildChannels
					channelIDs.push(e["id"])
				for i, e in channelTheme {
					if (this.bot.inArr(channelIDs, i)) {
						this.bot.modifyChannel(i, e)
						channelsEditedCount++
					}
					else
						errorlog .= "Did not edit Channel " i "(" ( channelThemeOriginal.Has(i) ? channelThemeOriginal[i] : "Unknown" ) ") because it wasn't found.`n"
				}
			}
			catch as e {
				MsgBox("Channel Error: " . errorlog . e.Message "`n" e.What "`n" e.Extra)
			} finally {
				errorlog .= channelsEditedCount . " channels edited.`n"
			}
		}
		return errorlog
	}




	; helper functions

	static writeJson(obj, path, name) {
		nfile := FileOpen(path "\output\" name ".json", "w", "UTF-8")
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
					if (A_LoopField != "" && !InStr(A_LoopField, "Archived") && !InStr(A_LoopField, "Deleted"))
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