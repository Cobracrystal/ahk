; LibrariesV2/test_unicodeData.ahk

#Include "%A_LineFile%\..\..\LibrariesV2"
#Include unicodeData.ahk
#Include BasicUtilities.ahk

RunTests()

RunTests() {
	static icuTests := {
		isalpha: { inputValid: "A", inputInvalid: "#", expectedValid: 1, expectedInvalid: 0, additionalparams: [] },
		isdigit: { inputValid: "5", inputInvalid: "#", expectedValid: 1, expectedInvalid: 0, additionalparams: [] },
		digit:   { inputValid: "5", inputInvalid: "#", expectedValid: 5, expectedInvalid: -1, additionalparams: [10] },
		islower: { inputValid: "a", inputInvalid: "A", expectedValid: 1, expectedInvalid: 0, additionalparams: [] },
		isupper: { inputValid: "A", inputInvalid: "a", expectedValid: 1, expectedInvalid: 0, additionalparams: [] },
		isblank: { inputValid: " ", inputInvalid: "A", expectedValid: 1, expectedInvalid: 0, additionalparams: [] },
		isspace: { inputValid: " ", inputInvalid: "A", expectedValid: 1, expectedInvalid: 0, additionalparams: [] },
		ispunct: { inputValid: ".", inputInvalid: "A", expectedValid: 1, expectedInvalid: 0, additionalparams: [] },
		isalnum: { inputValid: "A", inputInvalid: "#", expectedValid: 1, expectedInvalid: 0, additionalparams: [] },
		toLower: { inputValid: "A", inputInvalid: "a", expectedValid: "a", expectedInvalid: "a", additionalparams: [] },
		toUpper: { inputValid: "a", inputInvalid: "A", expectedValid: "A", expectedInvalid: "A", additionalparams: [] },
		forDigit: { inputValid: 9, inputInvalid: 11, expectedValid: "9", expectedInvalid: "", additionalparams: [10] },
		getNumericValue: { inputValid: "5", inputInvalid: "A", expectedValid: 5, expectedInvalid: -123456789.0, additionalparams: [] }
	}
	ud := unicodeData
	resultSummary := ""
	for fnName, testCase in ObjOwnProps(icuTests) {
		; Prepare parameters
		validParams := [testCase.inputValid, testCase.additionalparams*]
		invalidParams := [testCase.inputInvalid, testCase.additionalparams*]

		; Call function dynamically
		try
			validResult := ud.%fnName%(validParams*)
		catch as e
			validResult := "Error in function " fnName " with param " testCase.inputInvalid  ": " e.Message
		try
			invalidResult := ud.%fnName%(invalidParams*)
		catch as e
			invalidResult := "Error in function " fnName " with param " testCase.inputInvalid ": " e.Message

		; Compare and display result
		validPass := (validResult == testCase.expectedValid)
		invalidPass := (invalidResult == testCase.expectedInvalid)

		resultSummary .= fnName "(): "
		resultSummary .= validPass ? "✅ valid " : "❌ valid (got " validResult ") "
		resultSummary .= invalidPass ? "✅ invalid" : "❌ invalid (got " invalidResult ")"
		resultSummary .= "`n"
	}

	print(resultSummary)
}


logF(name, input, result, expected, isError := false) {
	if (isError)
		print(Format("Function {} with input {} gave error {}, expected: {}. Correctness: {}", name, input, result, expected, expected == result))
	else
		print(Format("Function {} with input {} gave result {}, expected: {}. Correctness: {}", name, input, result, expected, expected == result))
}