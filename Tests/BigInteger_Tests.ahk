; LibrariesV2/test_BigInteger.ahk

#Include "%A_LineFile%\..\..\LibrariesV2"
#Include BasicUtilities.ahk
#Include BigInteger.ahk
methods := ["add", "sub", "mul", "div", "rem"]

	
RunTests('add')
RunTests('sub')
RunTests('mul')
RunTests('pow')

RunTests(method, givenFile?) {
	static methodMap := Map(
		"add", "add",
		"sub", "subtract",
		"mul", "multiply",
		"div", "divide",
		"rem", "mod",
		"pow", "pow"
	)
	static testsCache := Map()
	if (testsCache.Count == 0) {
		snap := qpc()
		testsCache := parseTests()
		elapsed := qpc() - snap
		print('Parsed to BigIntegers in ' elapsed 's')
	}
	; Test data lines from test_digit and test_full
	snap := qpc()
	for e in testsCache[method] {
		e.%'res_' method% := e.num1.%methodMap[method]%(e.num2)
		; e.%method% := BigInteger.fromMagnitude(BigInteger.divideMagnitudeByDigit(e.num1.magnitude, e.num2.magnitude[1])[1])
	}
	elapsed := qpc() - snap
	c := e := 0
	print('Performed Calculations [' method '] in ' elapsed 's')
	for i, r in testsCache[method] {
		if (r.%method%.equals(r.%'res_' method%))
			c++
		else {
			print("Test failed for " method ": " r.num1.toString() " " method " " r.num2.toString() "`nExpected: " r.%method%.toString() "`nGot:      " r.%'res_' method%.toString())
			e++
		}
	}
	print('Total Errors: ' e ', Total Passes: ' c)
}

parseTests() {
	static files := {
		fileDigit: 'tests_digit.txt',
		fileFull: 'tests_full.txt',
		filePow: 'tests_pow.txt'
	}
	static fileMap := [
		{ path: files.fileDigit, names: ["NUM1", "NUM2", "ADD", "SUB", "MUL", "DIV", "REM"] },
		; { path: files.fileFull, names: ["NUM1", "NUM2", "ADD", "SUB", "MUL", "DIV", "REM"] },
		{ path: files.filePow, names: ["NUM1", "NUM2", "POW"] }
	]
	tests := Map()
	tests.CaseSense := false
	for fObj in fileMap {
		regStr := ''
		for i, e in fObj.names
			regStr .= Format("{1}:(?<{1}>-?\d+)", e) (i == fObj.names.Length ? '' : ',\s*')
		testfile := FileRead(fObj.path, 'UTF-8')
		arr := []
		loop parse testfile, '`n', '`r' {
			RegExMatch(A_LoopField, regStr, &o)
			obj := {}
			for e in fObj.names
				obj.%e% := BigInteger(o[e])
			arr.push(obj)
		}
		for i, e in fObj.names
			tests[e] := arr
	}
	return tests
}