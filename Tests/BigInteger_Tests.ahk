; LibrariesV2/test_BigInteger.ahk

#Include "%A_LineFile%\..\..\LibrariesV2"
#Include BasicUtilities.ahk
#Include BigInteger.ahk
methods := ["add", "sub", "mul", "div", "rem"]
RunTests('add')
RunTests('sub')
RunTests('mul')
RunTests('rem')

RunTests(method) {
	static fileDigit := 'tests_digit.txt'
	static fileFull := 'tests_full.txt'
	static filePow := 'tests_pow.txt'
	static methodMap := Map(
		"add", "Add",
		"sub", "Subtract",
		"mul", "Multiply",
		"div", "Divide",
		"rem", "Mod"
	)
	static testsCache := []
	; Test data lines from test_digit and test_full
	if testsCache.Length == 0 {
		snap := qpc()
		testfile := FileRead(fileFull, 'UTF-8')
		loop parse testfile, '`n', '`r' {
			RegExMatch(A_LoopField, "NUM1:(?<num1>\d+), NUM2:(?<num2>\d+), ADD:(?<add>\d+), SUB:(?<sub>-?\d+), MUL:(?<mul>\d+), DIV:(?<div>\d+), REM:(?<rem>\d+)", &o)
			testsCache.push({
				raw_num1: o["num1"], num1: BigInteger(o["num1"]),
				raw_num2: o["num2"], num2: BigInteger(o["num2"]), 
				raw_add: o["add"], add: BigInteger(o["add"]), 
				raw_sub: o["sub"], sub: BigInteger(o["sub"]), 
				raw_mul: o["mul"], mul: BigInteger(o["mul"]), 
				raw_div: o["div"], div: BigInteger(o["div"]), 
				raw_rem: o["rem"], rem: BigInteger(o["rem"])  
			})
		}
		elapsed := qpc() - snap
		print('Parsed to BigIntegers in ' elapsed 's')
	}
	snap := qpc()
	for e in testsCache {
		e.%'res_' method% := e.num1.%methodMap[method]%(e.num2)
		; e.%method% := BigInteger.fromMagnitude(BigInteger.divideMagnitudeByDigit(e.num1.magnitude, e.num2.magnitude[1])[1])
	}
	elapsed := qpc() - snap
	c := e := 0
	print('Performed Calculations [' method '] in ' elapsed 's')
	for i, r in testsCache {
		t := testsCache[i]
		if (r.%method%.equals(r.%'res_' method%)) {
			c++
		} else {
			e++
			print("Test failed for " method ": " r.num1.toString() " " method " " r.num2.toString() "`nExpected: " r.%method%.toString() "`nGot:      " r.%'res_' method%.toString())
		}
	}
	print('Total Errors: ' e ', Total Passes: ' c)
}