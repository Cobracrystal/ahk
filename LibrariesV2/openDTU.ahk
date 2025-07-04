; this should never be used in a serious setting, its a shitty temporary solution
#Include "%A_LineFile%\..\..\LibrariesV2\jsongo.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"

; password := FileRead(A_Desktop "\programs\Files\openDTUAuth.pw")
; onlineURL := FileRead(A_Desktop "\programs\Files\openDTUurl.dt")


; openDTUman := openDTU("http://192.168.178.48", 80, "admin", password)
; openDTUman2 := openDTU(onlineURL, 81)
; FileAppend(jsongo.Stringify(openDTUman.getInverterList(),,"`t") "`n", "*","UTF-8")
; FileAppend(jsongo.Stringify(openDTUman.setInverterLimitConfig(openDTUman.getInverterSerialNumber(1),{limit_type:1, limit_value:100}),,"`t") "`n", "*","UTF-8")
; FileAppend(jsongo.Stringify(openDTUman.getInverterLimitConfig(),,"`t") "`n", "*","UTF-8")
; Sleep(2000)
; FileAppend(jsongo.Stringify(openDTUman.getInverterLimitConfig(),,"`t") "`n", "*","UTF-8")

class openDTU {

	__New(url?, port?, username?, password?) {
		this.username := username ?? openDTU.defaultConfig.username
		this.password := password ?? openDTU.defaultConfig.password
		this.domain := IsSet(url) ? RTrim(url, "`t /") : openDTU.defaultConfig.url
		this.port := port ?? openDTU.defaultConfig.port
		this.baseURL := this.domain . ":" this.port . "/api/"
	}

	getInverterList() {
		return this.callApi("GET", "inverter/list")
	}

	getInverterRuntimeInfo() {
		return this.callApi("GET", "livedata/status")
	}

	getEventLog(serial) {
		return this.callApi("GET", "eventlog/status?inv=" . serial)
	}

	getInverterLimitConfig() {
		return this.callApi("GET", "limit/status")
	}

	setInverterLimitConfig(serial, config) {
	;	currentConfig := this.getInverterLimitConfig()
		config.serial := serial
		return this.callApi("POST", "limit/config", config)
	}

	getInverterPowerConfig() {
		return this.callApi("GET", "power/status")
	}

	setInverterPowerConfig(serial, config) {
		config.serial := serial
		return this.callApi("POST", "power/config", config)
	}

	getSecurityAuth() {
		return this.callApi("GET", "security/authenticate")
	}

	getInverterSerialNumber(index := 1) {
		return this.getInverterRuntimeInfo()["inverters"][1]["serial"]
	}

	getTotalPowerYield() {
		return this.getInverterRuntimeInfo()["total"]["YieldTotal"] ; Map with "d" (?), "u" (unit), "v" (value)
	}

	getNTPconfig() {
		return this.callApi("GET", "ntp/config")
	}

	callApi(method, endPoint, content := "") {
		http := ComObject("WinHTTP.WinHTTPRequest.5.1")
		http.Open(method, this.BaseURL . endpoint, true)
		http.SetRequestHeader("Authorization", "Basic " . base64Encode(this.username . ":" . this.password))
		http.SetRequestHeader("User-Agent", "Bad Local AHK-Bot")
		http.SetRequestHeader("Content-Type", content ? "application/x-www-form-urlencoded" : "application/json")
		http.Send(content ? 'data=' jsongo.Stringify(content) : unset)
		http.WaitForResponse()
		if (http.ResponseBody) {
			arr := http.ResponseBody
			pData := NumGet(ComObjValue(arr) + 8 + A_PtrSize, 0, "UPtr")
			length := (arr.MaxIndex() - arr.MinIndex()) + 1
			responseText := Trim(StrGet(pData, length, "UTF-8"), "`n`r`t ")
		}
		responseHeaders := http.GetAllResponseHeaders()
		if (http.status == 401 || !http.ResponseBody)
			return parseHeaders(responseHeaders)
		if (http.status != 200 && http.status != 204)
			return Map("Status", http.status, "Response", http.responseText, "Endpoint", endPoint, "Content", 'data=' jsongo.Stringify(content))
		return jsongo.Parse(responseText)
	}

	static defaultConfig => {
		username: "admin",
		password: "openDTU42",
		url: "http://192.168.178.48",
		port: 80
	}
}