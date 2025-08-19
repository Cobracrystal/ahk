#Include "%A_LineFile%\..\..\LibrariesV2\DiscordClient.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\jsongo.ahk"


class DiscordBot extends DiscordClient {
	; __New(token) {
	; 	super.__New(token)
	; }

	sendMessageToUser(userID, content) {
		channelID := this.createDM(channelID)["id"]
		return this.sendMessage(channelID, content)
	}

	duplicateRole(serverID, roleID) {
		role := this.getRoleById(serverID, roleID)
		pos := role["position"]
		; role := objRemoveValue(role, "")
		objRemoveValue(role["colors"], "")
		duplRole := Map()
		for e in ["name","permissions","colors","hoist","icon","unicode_emoji","mentionable"]
			if role.has(e)
				duplRole[e] := role[e]
		newRole := this.createGuildRole(serverID, duplRole)
		this.modifyGuildRolePositions(serverID, [{id: newRole["id"], position: pos + 1}])
		return newRole
	}

	getHighestRole(userRoles, serverRoles) {
		for i, e in serverRoles
			if (this.inArr(userRoles, e["id"]) && e["position"] >= highestRole["position"])
				highestRole := e
		return highestRole
	}
}