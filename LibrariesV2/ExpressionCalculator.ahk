#Include MathUtilities.ahk
#Include BasicUtilities.ahk
#Include MsgBoxAsGui.ahk
#Include External\jsongo.ahk

class expressionCalculator {

	static setWolframAlphaToken(token) {
		this.token := token
	}
	
	static calculateExpression(mode := "print") {
		expression := fastCopy()
		result := this.resolveExpression(expression)
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
	
	static wolframAlphaCall(expression) {
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

	static resolveExpression(expression) {
		expression := Trim(expression, "`n`r`t ")
		mode := -1
		if RegExMatch(expression, "^([a-z]):", &o) {
			mode := o[1]
			expression := SubStr(expression, 3)
		}
		flagGiveUp := false
		try {
			switch mode {
				case 'w': ; address wolfram alpha
					try result := this.wolframAlphaCall(expression)
					catch
						return ''
				case 'b', 'v': ; run as void, under the assumption that the program displays its results on its own somehow
					processedExpression := this.preprocess(expression)
					result := ExecHelperScript(processedExpression, false, true, &err)
				default:
					processedExpression := this.preprocess(expression)
					result := this.readableFormat(ExecHelperScript(processedExpression, &err))			
			}
		} catch {
			flagGiveUp := true
		}
		if flagGiveUp || (err ?? 0)
			try result := this.wolframAlphaCall(expression)
			catch 
				result := ''
		; for this to fully work, ExecHelperScript should wrap the program in try {} catch { print error to stderr } because by default stderr only contains pre-runtime errors
		return result
	}

	static preprocess(expression) {
		; constants
		static list := [
			{ k: "\pi", v: "3.141592653589793" }, 
			{ k: "π", v: "3.141592653589793" }, 
			{ k: "\phi", v: "((1+sqrt(5))/2)" }, 
			{ k: "φ", v: "((1+sqrt(5))/2)" }, 
			{ k: "\e", v: "2.718281828459045" }
		]
		for i, e in list
			expression := StrReplace(expression, e.k, e.v)
		; factorials
		while RegExMatch(expression, "(\d+)!", &o) 
			expression := RegExReplace(expression, "(\d+)!", factorial(Integer(o[1])),,1)
		return expression
	}
}