#Include %A_ScriptDir%\Libraries\JSON.ahk


class DiscordClient {
	static BaseURL := "https://discord.com/api/v10"
	static token
	
	__New(token) {
		this.token := token
		this.gw := new Gateway
	}
	
	createDM(userID) {
		return this.callApi("POST", "/users/@me/channels", {"recipient_id":userID})
	}
	
	sendMessage(content, id, dm := 0) {
		if (dm)
			channelID := this.createDM(id).id
		else
			channelID := id
		return this.callApi("POST", "/channels/" . channelID . "/messages", {"content":content})
	}
	
	getMessages(channelID) {
		return this.callApi("GET", "/channels/" . channelID . "/messages")
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
	
	CallAPI(method, endPoint, content := "") {
		http := ComObjCreate("WinHTTP.WinHTTPRequest.5.1")
		Loop, 2 {
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
					throw Exception("Failed to load rate limit retry_after")
				else
				{
					Sleep, % response.retry_after
					continue
				}
			}
			break ; only loop if rate limit, else directly continue
		}
		if (http.status != 200 && http.status != 204)
			throw Exception("Request failed`n" . "Status: " http.status "`nResponse: " http.responseText "`nendPoint: " . endPoint . "`nContent: `n" . JSON.Dump(content))
		return JSON.Load(http.responseText)
	}
	
	class Gateway {
		
	}
	
}