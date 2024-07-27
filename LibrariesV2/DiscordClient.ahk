; https://github.com/cobracrystal/ahk
#Include "%A_LineFile%\..\..\LibrariesV2\jsongo.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\WebSocket.ahk"

class DiscordClient {
	
	__New(token, useWS := true) {
		this.token := token
		version := "10"
		this.BaseURL := "https://discord.com/api/v" version
		this.me := this.getCurrentUser()
		if (useWS) {
			this.wsData := {
				heartbeatACK: false,
				heartbeatInterval: 0,
				url: this.callApi("GET", "/gateway/bot")["url"] . "?v=" version "&encoding=json"
			}
			this.ws := Websocket(
				this.wsData.url,
				{
					open: this.ws_OnOpen.bind(this), ; (this)=>void,
					data: this.ws_OnData.bind(this), ; (this, data, size)=>bool,
					message: this.ws_OnMessage.bind(this), ; (this, msg)=>bool,
					close: this.ws_OnClose.bind(this) ; (this, status, reason)=>void
				}
			)
		}
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
		return this.callApi("POST", "/channels/" channelID . "/messages", content)
	}
	
	; THIS SHOULD FILTER FOR MULTIPLE mTypeS AND NOT JUST ONE. ?limit=100&after=ID&before=ID IS POSSIBLE AHHHHHH
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

	getGuildRoles(serverID) {
		return this.callApi("GET", "/guilds/" serverID "/roles")
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

	deleteMessage(channelID, messageID) {
		return this.callApi("DELETE", "/channels/" channelID "/messages/" messageID)
	}
	
	isInGuild(serverID) {
		for i, e in this.getCurrentUserGuilds()
			if (e["id"] == serverID)
				return true
		return false
	}

	permissionsInServer(userRoles, serverRoles) {
		finalPermissions := 0x0000000000000000
		for i, e in serverRoles {
			if (this.inArr(userRoles, e["id"])) {
				finalPermissions := finalPermissions | Integer(e["permissions"])
			}
		}
		return finalPermissions
	}

	hasPermissionInServer(userRoles, serverRoles, mode, wantpermission*) {
		local permissions := this.permissionsInServer(userRoles, serverRoles) 
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

	getHighestRole(userRoles, serverRoles) {
		highestRole := Map("position", 0)
		for i, e in serverRoles
			if (this.inArr(userRoles, e["id"]) && e["position"] >= highestRole["position"])
				highestRole := e
		return highestRole
	}
	
	callApi(method, endPoint, content := "") {
		http := ComObject("WinHTTP.WinHTTPRequest.5.1")
		Loop(2) {
			http.Open(method, this.BaseURL . endpoint)
			http.SetRequestHeader("Authorization", "Bot " . this.token)
			http.SetRequestHeader("User-Agent", "DiscordBot ($https://discordapp.com, $1337)")
			http.SetRequestHeader("Content-Type", "application/json")
			if (content)
				http.Send(jsongo.Stringify(content))
			else 
				http.Send()
			if (http.status == 429) { ; rate limit
				response := jsongo.Parse(http.responseText)
				if (response["retry_after"] == "")
					throw Error("Failed to load rate limit retry_after")
				else
				{
					Sleep(response["retry_after"] * 1000 + 5)
					continue
				}
			}
			break ; only loop if rate limit, else directly continue
		}
		if (http.status != 200 && http.status != 204)
			throw Error("Request failed`nStatus: " http.status "`nResponse: " jsongo.Stringify(jsongo.parse(http.responseText),,"`t") "`nendPoint: " . endPoint . "`nContent: `n" . jsongo.Stringify(content))
		return jsongo.Parse(http.ResponseText)
	}

	inArr(arr, val) {
		for i, e in arr
			if (e = val)
				return i
		return 0
	}

	ws_SendData(object, ws?) {
		if (!IsSet(ws))
			ws := this.ws
		str := jsongo.Stringify(object)
		sBuf := Buffer(StrPut(str, "UTF-16"))
		StrPut(jsongo.Stringify(object), sBuf, "UTF-16")
		ws.Send(sBuf)
	}

	ws_SendIdentify(ws?) {
		obj := {
			op:2, 
			d:{
				token: this.token, 
				properties: Map(
					"$os", "windows",
					"$browser", "DiscordClient.ahk", 
					"$device", "DiscordClient.ahk", 
					"$referrer", "", 
					"$referring_domain", ""),
				compress:false, ; this requires zlib and much more effort
				large_threshold: 250
			}
		}
		this.ws_SendData(obj, ws?)
	}

	ws_OnOpen(ws) {
		this.ws_SendIdentify(ws?)
	}
	
	ws_OnMessage(ws, msg) {
		data := jsongo.Parse(msg.data)

		if data["s"]
			this.wsData.SequenceNum := data["s"]
		
		; call opcode function
		fn := "ws_Op" . data["op"]
		if (this.HasMethod(fn))
			return this.%fn%(data)
		else
			return false
	}
	
	ws_OnData(ws, data, size) {
		return 1
	}

	ws_OnClose(ws, status, reason) {
		throw Error("Unhandled Discord.ahk WebSocket Close")
	}
	
	; opcode = 10 => Hello Event in response to opening Gateway
	; https://discord.com/developers/docs/topics/gateway#hello-event
	ws_OP10(Data) {
		this.wsData.heartbeatACK := True
		this.wsData.heartbeatInterval := Data["d"]["heartbeat_interval"]
		initRand := Integer(-1 * Random(1, this.wsData.heartbeatInterval))
		SetTimer(this.ws_SendHeartbeat.bind(this), initRand)
		SetTimer(SetTimer.Bind(this.ws_SendHeartbeat.bind(this), this.wsData.heartbeatInterval), initRand+1)
	}
	
	; opcode = 11 => Heartbeat acknowledged
	OP11(Data) {
		this.wsData.HeartbeatACK := True
	}
	
	; opcode = 0 => Event Dispatched
	OP0(Data) {
		fn := this["OP0_" Data.t]
		%fn%(this, Data.d)
	}
	
	ws_SendHeartbeat() {
		if !this.wsData.HeartbeatACK {
			throw Error("Heartbeat did not respond")
			/*
				https://discord.com/developers/docs/topics/gateway#heartbeat-interval-example-heartbeat-ack
				this needs to be handled
			*/
		}
		this.wsData.HeartbeatACK := false
		this.ws_SendData({op: 1, d: this.wsData.SequenceNum})
	}

}

class Permissions {
	static CREATE_INSTANT_INVITE := 0x0000000000000001
	static KICK_MEMBERS := 0x0000000000000002
	static BAN_MEMBERS := 0x0000000000000004
	static ADMINISTRATOR := 0x0000000000000008
	static MANAGE_CHANNELS := 0x0000000000000010
	static MANAGE_GUILD := 0x0000000000000020
	static ADD_REACTIONS := 0x0000000000000040
	static VIEW_AUDIT_LOG := 0x0000000000000080
	static PRIORITY_SPEAKER := 0x0000000000000100
	static STREAM := 0x0000000000000200
	static VIEW_CHANNEL := 0x0000000000000400
	static SEND_MESSAGES := 0x0000000000000800
	static SEND_TTS_MESSAGES := 0x0000000000001000
	static MANAGE_MESSAGES := 0x0000000000002000
	static EMBED_LINKS := 0x0000000000004000
	static ATTACH_FILES := 0x0000000000008000
	static READ_MESSAGE_HISTORY := 0x0000000000010000
	static MENTION_EVERYONE := 0x0000000000020000
	static USE_EXTERNAL_EMOJIS := 0x0000000000040000
	static VIEW_GUILD_INSIGHTS := 0x0000000000080000
	static CONNECT := 0x0000000000100000
	static SPEAK := 0x0000000000200000
	static MUTE_MEMBERS := 0x0000000000400000
	static DEAFEN_MEMBERS := 0x0000000000800000
	static MOVE_MEMBERS := 0x0000000001000000
	static USE_VAD := 0x0000000002000000
	static CHANGE_NICKNAME := 0x0000000004000000
	static MANAGE_NICKNAMES := 0x0000000008000000
	static MANAGE_ROLES := 0x0000000010000000
	static MANAGE_WEBHOOKS := 0x0000000020000000
	static MANAGE_GUILD_EXPRESSIONS := 0x0000000040000000
	static USE_APPLICATION_COMMANDS := 0x0000000080000000
	static REQUEST_TO_SPEAK := 0x0000000100000000
	static MANAGE_EVENTS := 0x0000000200000000
	static MANAGE_THREADS := 0x0000000400000000
	static CREATE_PUBLIC_THREADS := 0x0000000800000000
	static CREATE_PRIVATE_THREADS := 0x0000001000000000
	static USE_EXTERNAL_STICKERS := 0x0000002000000000
	static SEND_MESSAGES_IN_THREADS := 0x0000004000000000
	static USE_EMBEDDED_ACTIVITIES := 0x0000008000000000
	static MODERATE_MEMBERS := 0x0000010000000000
	static VIEW_CREATOR_MONETIZATION_ANALYTICS := 0x0000020000000000
	static USE_SOUNDBOARD := 0x0000040000000000
	static CREATE_GUILD_EXPRESSIONS := 0x0000080000000000
	static CREATE_EVENTS := 0x0000100000000000
	static USE_EXTERNAL_SOUNDS := 0x0000200000000000
	static SEND_VOICE_MESSAGES := 0x0000400000000000
}