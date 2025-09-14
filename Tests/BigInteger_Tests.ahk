; LibrariesV2/test_BigInteger.ahk

#Include "%A_LineFile%\..\..\LibrariesV2"
#Include BasicUtilities.ahk
#Include BigInteger.ahk
methods := ["add", "sub", "mul", "div", "rem"]
RunTests('div')

RunTests(method) {
	static fileDigit := 'tests_digit.txt'
	static fileFull := 'tests_full.txt'
	static fileFull := 'tests_pow.txt'
	static methodMap := Map(
		"add", "Add",
		"sub", "Subtract",
		"mul", "Multiply",
		"div", "Divide",
		"rem", "Mod"
	)
	; Test data lines from test_digit and test_full
	testfile := FileRead(fileDigit, 'UTF-8')
	tests := []
	loop parse testfile, '`n', '`r' {
		RegExMatch(A_LoopField, "NUM1:(?<num1>\d+), NUM2:(?<num2>\d+), ADD:(?<add>\d+), SUB:(?<sub>-?\d+), MUL:(?<mul>\d+), DIV:(?<div>\d+), REM:(?<rem>\d+)", &o)
		tests.push({
			num1: o["num1"], num2: o["num2"], add: o["add"], sub: o["sub"], 
			mul: o["mul"], div: o["div"], rem: o["rem"] 
		})
	}
	results := []
	snap := qpc()
	for i, e in tests {
		num1 := BigInteger(e.num1)
		num2 := BigInteger(e.num2)
		results.push({
			num1: num1, num2: num2, expected: BigInteger(e.%method%)
		})
	}
	elapsed := qpc() - snap
	print('Parsed to BigIntegers in ' elapsed 's')
	snap := qpc()
	for e in results
		e.%method% := e.num1.%methodMap[method]%(e.num2)
		; e.%method% := BigInteger.fromMagnitude(BigInteger.divideMagnitudeByDigit(e.num1.magnitude, e.num2.magnitude[1])[1])
	elapsed := qpc() - snap
	c := e := 0
	print('Performed Calculations [' method ']in ' elapsed 's')
	for i, r in results {
		t := tests[i]
		if (r.expected.equals(r.%method%)) {
			c++
		} else {
			e++
			print("Test failed for " method ": " r.num1.toString() " " method " " r.num2.toString() "`nExpected: " r.expected.toString() "`nGot:      " r.%method%.toString())
		}
	}
	print('Total Errors: ' e ', Total Passes: ' c)
}