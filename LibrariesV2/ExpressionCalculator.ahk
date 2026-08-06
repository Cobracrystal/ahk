#Include MathUtilities.ahk
#Include BasicUtilities.ahk
#Include External\jsongo.ahk

class expressionCalculator {

	static setWolframAlphaToken(token) {
		this.token := token
	}
	
	static calculateExpression(mode := "print") {
		expression := fastCopy()
		if (SubStr(expression, 1, 2) == "w:")
			result := this.giveUpAndCallWolframalpha(SubStr(expression, 3))
		else if (SubStr(expression, 1, 2) == "b:")
			return ExecHelperScript(this.replaceConstants(SubStr(expression, 3)), false, true)
		else
			result := this.readableFormat(ExecHelperScript(this.replaceConstants(expression)))
		; READ THE ERROR STREAM. IF THERE'S SOME ERROR IN THERE, ALSO GIVE IT TO WOLFRAMALPHA
		; ADD A CONTEXT MENU OPTION FOR THIS, EITHER WOLFRAM OR SOMETHING ELSE OR LOCAL
	;	result := this.giveUpAndCallWolframalpha(expression)
		if (result = "")
			return
		Send("{Right}")
		switch (SubStr(mode, 1, 1)) {
			case "p":
				fastPrint((InStr(result, "`n") ? "`n" : " = ") . result)
			case "c":
				A_Clipboard := result
			default:
				MsgBoxAsGui(result,"Expression Result")
		}
	}

	static readableFormat(numStr) {
		if (InStr(numStr, ".") && !InStr(numStr, "e"))
			numStr := RTrim(numStr, "0")
		if (SubStr(numStr, -1) = ".")
			numStr := SubStr(numStr, 1, -1)
		return numStr
	}
	
	static giveUpAndCallWolframalpha(expression) {
		static baseURL := "https://api.wolframalpha.com/v2/query?input=" 
		static queryParameters := "&format=plaintext&output=JSON&appid="
		if !(this.token)
			throw(Error("No token set for WolframAlpha API"))
		encoded := Uri.encode(expression)
		url := baseURL . encoded . queryParameters . this.token
		retObj := sendRequest(url, "GET")
		return parseWolframAlphaResponse(retObj)

		parseWolframAlphaResponse(response) {
			response := jsongo.Parse(response)
			result := response["queryresult"]
			if (!result["success"] && result["error"])
				return "Error: " . result["error"]["msg"]
			if (!result["success"])
				return "Error: No result found (?)"
			if (!result["pods"])
				return "Error: No pods found"
			pods := result["pods"]
			resultStr := ""
			for i, pod in pods {
				if (pod["id"] == "Result") {
					if (pod["numsubpods"] == 1)
						resultStr := pod["subpods"][1]["plaintext"]
					else {
						for j, subpod in pod["subpods"] {
							if (subpod["plaintext"])
								resultStr .= subpod["plaintext"] . ", "
						}
						resultStr := "[" SubStr(resultStr, 1, -2) "]"
					}
					break
				}
			}
			if (!resultStr) {
				resultStr := "`n"
				for i, pod in pods {
					tStr := ""
					for j, subpod in pod["subpods"]
						if (subpod["plaintext"])
							tStr .= subpod["plaintext"] . ", "
					if (tStr) {
						if (pod["numsubpods"] == 1)
							resultStr .= pod["title"] . ": " . StrReplace(SubStr(tStr, 1, -2), "`n", "`t") . "`n"
						else
							resultStr .= pod["title"] . ": [" StrReplace(SubStr(tStr, 1, -2), "`n", "`t") "]`n"
					}
				}
			}
			return resultStr
		}
	}

	static replaceConstants(expression) {
		list := [{ key: "\pi", val: "3.141592653589793" }, { key: "\phi", val: "((1+sqrt(5))/2)" }, { key: "\e", val: "2.718281828459045" }
		]
		for i, e in list
			expression := StrReplace(expression, e.key, e.val)
		expression := Trim(expression, "`n`r`t ")
		return expression
	}
}