#Include %A_ScriptDir%\LibrariesV2\JSON.ahk


class DiscordClient {
	
	__New(token) {
		this.token := token
		this.BaseURL := "https://discord.com/api/v10"
		this.waitingTime := 0
		this.gw := this.Gateway("ahk_class")
	}
	
	createDM(userID) {
		return this.callApi("POST", "/users/@me/channels", {recipient_id:userID})
	}
	
	sendMessage(content, id, dm := 0) {
		if (dm)
			channelID := this.createDM(id).id
		else
			channelID := id
		return this.callApi("POST", "/channels/" . channelID . "/messages", {content:content})
	}
	
	getMessages(channelID, limit := 100, mType := "", mID := 0) {
		switch mType {
			case "","after","before","around":
			default:
				throw Error('Bad Message Request: Requested Message with Query Type"' . mType . '"')
		}
		return this.callApi("GET", "/channels/" . channelID . "/messages?limit=" . limit . (mType ? "&" . mType . "=" . mID : ""))
	}
	
	getMessage(channelID, messageID) {
		return this.callApi("GET", "/channels/" . channelID . "/messages/" . messageID)
	}
	
	getReaction(channelID, messageID, emoji) {
		return this.callApi("GET", "/channels/" . channelID . "/messages/" . messageID . "/reactions/" . emoji)
	}
	
	getUser(userID) {
		return this.callApi("GET", "/users/" . userID)
	}
	
	getGuild(serverID, member_count := false) {
		return this.callAPI("GET", "/guilds/" . serverID . (member_count ? "&with_counts=true" : ""))
	}
	
	getMembers(serverID, limit := "1", after := "0") {
		return this.callAPI("GET", "/guilds/" . serverID . "/members?limit=" . limit . (after ? "&after=" . after : ""))
	}
	
	getRoles(serverID) {
		return this.callAPI("GET", "/guilds/" . serverID . "/roles")
	}
	
	CallAPI(method, endPoint, content := "") {
		http := ComObject("WinHTTP.WinHTTPRequest.5.1")
		Loop(2) {
			http.Open(method, this.BaseURL . endpoint)
			http.SetRequestHeader("Authorization", "Bot " . this.token)
			http.SetRequestHeader("User-Agent", "DiscordBot ($https://discordapp.com, $1337)")
			http.SetRequestHeader("Content-Type", "application/json")
			if (content)
				http.Send(JSON.Dump(content))
			else 
				http.Send()
			if (http.status == 429) { ; rate limit
				response := JSON.Load(http.responseText)
				if (response.retry_after == "")
					throw Error("Failed to load rate limit retry_after")
				else
				{
					this.waitingTime += response.retry_after * 1000
					Sleep(response.retry_after * 1000 + 5)
					continue
				}
			}
			break ; only loop if rate limit, else directly continue
		}
		if (http.status != 200 && http.status != 204)
			throw Error("Request failed`n" . "Status: " http.status "`nResponse: " http.responseText "`nendPoint: " . endPoint . "`nContent: `n" . JSON.Dump(content))
		return JSON.Load(http.responseText)
	}
	
	class Gateway {
		__New() {
			return
		}
	}
	
}