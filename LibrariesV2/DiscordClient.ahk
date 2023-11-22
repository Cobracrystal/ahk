; https://github.com/cobracrystal/ahk
#Include %A_ScriptDir%\LibrariesV2\jsongo.ahk

class DiscordClient {
	
	__New(token) {
		this.token := token
		this.BaseURL := "https://discord.com/api/v10"
		this.waitingTime := 0
		this.gw := DiscordClient.Gateway("placeholder")
	}
	
	createDM(userID) {
		return this.callApi("POST", "/users/@me/channels", {recipient_id:userID})
	}
	
	sendMessage(content, id, dm := 0) {
		local channelID
		if (dm)
			channelID := this.createDM(id)["id"]
		else
			channelID := id
		return this.callApi("POST", "/channels/" channelID . "/messages", {content:content})
	}
	
	getMessages(channelID, limit := 100, mType := "", mID := 0) {
		switch mType {
			case "","after","before","around":
			default:
				throw Error('Bad Message Request: Requested Message with Query Type"' . mType . '"')
		}
		return this.callApi("GET", "/channels/" channelID . "/messages?limit=" limit . (mType ? "&" mType . "=" mID : ""))
	}
	
	getMessage(channelID, messageID) {
		return this.callApi("GET", "/channels/" channelID . "/messages/" messageID)
	}
	
	getReaction(channelID, messageID, emoji) {
		return this.callApi("GET", "/channels/" channelID . "/messages/" messageID . "/reactions/" emoji)
	}
	
	getUser(userID) {
		return this.callApi("GET", "/users/" userID)
	}

	getChannel(channelID) {
		return this.callApi("GET", "/channels/" channelID)
	}
	
	getGuild(serverID, member_count := false) {
		return this.callAPI("GET", "/guilds/" serverID . (member_count ? "&with_counts=true" : ""))
	}

	getGuildChannels(serverID) {
		return this.callApi("GET", "/guilds/" serverID "/channels")
	}
	
	getMembers(serverID, limit := "1", after := "0") {
		return this.callAPI("GET", "/guilds/" serverID . "/members?limit=" limit . (after ? "&after=" after : ""))
	}

	getGuildMember(serverID, userID) {
		return this.callApi("GET", "/guilds/" serverID "/members/" userID)
	}

	getCurrentUser() {
		return this.callApi("GET", "/users/@me")
	}

	getCurrentUserGuilds() {
		return this.callApi("GET", "/users/@me/guilds")
	}
	
	getRoles(serverID) {
		return this.callAPI("GET", "/guilds/" serverID . "/roles")
	}

	modifyGuildRole(serverID, roleID, content) {
		return this.callApi("PATCH", "/guilds/" serverID "/roles/" roleID, content)
	}

	modifyChannel(channelID, content) {
		return this.callApi("PATCH", "/channels/" channelID, content)
	}
	
	callApi(method, endPoint, content := "") {
		http := ComObject("WinHTTP.WinHTTPRequest.5.1")
		Loop(2) {
			http.Open(method, this.BaseURL . endpoint)
			http.SetRequestHeader("Authorization", "Bot " . this.token)
			http.SetRequestHeader("User-Agent", "DiscordBot ($https://discordapp.com, $1337)")
			http.SetRequestHeader("Content-Type", "application/json")
			if (content)
				http.Send(asd := jsongo.Stringify(content))
			else 
				http.Send()
			if (http.status == 429) { ; rate limit
				response := jsongo.Parse(http.responseText)
				if (response["retry_after"] == "")
					throw Error("Failed to load rate limit retry_after")
				else
				{
					this.waitingTime += response["retry_after"] * 1000
					timedTooltip(response["retry_after"] * 1000)
					Sleep(response["retry_after"] * 1000 + 5)
					continue
				}
			}
			break ; only loop if rate limit, else directly continue
		}
		if (http.status != 200 && http.status != 204)
			throw Error("Request failed`nStatus: " http.status "`nResponse: " jsongo.Stringify(jsongo.parse(http.responseText),,"`t") "`nendPoint: " . endPoint . "`nContent: `n" . jsongo.Stringify(content))
		str := http.ResponseText
		A_Clipboard := str
		return jsongo.Parse(str)
	}
	
	class Gateway {
		__New(placeholder) {
			return
		}
	}
}