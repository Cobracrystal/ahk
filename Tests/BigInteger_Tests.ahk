; LibrariesV2/test_BigInteger.ahk

#Include "%A_LineFile%\..\..\LibrariesV2"
#Include BasicUtilities.ahk
#Include BigInteger.ahk
#SingleInstance Force
RunTests(true)

RunTests(detailedOutput := false) {
	testArithmeticMethods(detailedOutput)
	testArithmeticMethodsSmall(3000,detailedOutput)
	; test conversion

	; test bitwise arithmetic
	testBitWiseMethodsSmall(3000,detailedOutput)
	; test comparison
}

testArithmeticMethods(detailedOutput) {
	static arithmeticMethods := ["add", "subtract", "multiply", "divide", "mod"]
	static powMethod := ["pow"]
	arFull := parseTestFile("tests_full.txt", arithmeticMethods)
	arDigit := parseTestFile("tests_digit.txt", arithmeticMethods)
	arPow := parseTestFile("tests_pow.txt", powMethod)
	print('Parsed text files.')
	cacheFull := performanceTestParse(arFull)
	cacheDigit := performanceTestParse(arFull)
	cachePow := performanceTestParse(arPow)
	print('Parsed Tests to BigIntegers.')
	; test arithmetic
	for e in arithmeticMethods
		performanceTestMethod(arFull, e, 1, detailedOutput)
	for e in arithmeticMethods
		performanceTestMethod(arDigit, e, 1, detailedOutput)
	for e in powMethod
		performanceTestMethod(arPow, e, 1, detailedOutput)
}

testArithmeticMethodsSmall(loops := 1000, detailedOutput := false) {
	static arithmeticMethods := ["add", "subtract", "divide", "mod"]
	res := []
	resP := []
	resM := []
	Loop(loops) {
		; random 64-bit nums
		a := randomNBitInt(61)
		b := randomNonZeroNBitInt(61)
		c := (-1)**Random(0,1) * Random(1, 15)
		d := Random(0, 15)
		e := randomNBitUInt(31)
		f := randomNBitUInt(31)
		res.push({rawA: a, rawParams:[b], rawAdd: a+b, rawSubtract: a-b, rawDivide: a//b, rawMod: Mod(a,b)})
		resP.push({rawA: c, rawParams:[d], rawPow: c**d})
		resM.push({rawA: e, rawParams:[f], rawMultiply: e*f})
	}
	cacheFull := performanceTestParse(res)
	cacheMul := performanceTestParse(resM)
	cachePow := performanceTestParse(resP)
	print('Parsed Arithmetic Tests to BigIntegers.')
	for e in arithmeticMethods
		performanceTestMethod(cacheFull, e, 1, detailedOutput)
	performanceTestMethod(cacheMul, "multiply", 1, detailedOutput)
	performanceTestMethod(cachePow, "pow", 1, detailedOutput)
}

; bitwise arithmetic, tests with values <2*64 (mag of two at most)

testBitWiseMethodsSmall(loops := 1000, detailedOutput := false) {
	static paramMap := Map(
		0, ['not'],
		1, ['and', 'or', 'andNot', 'xor']
	)
	res := []
	Loop(loops) {
		; random 64-bit nums
		a := randomNBitInt(63)
		b := randomNBitInt(63)
		res.push({rawA: a, rawParams:[b], rawNot: ~a, rawAnd: a & b, rawOr: a | b, rawAndNot: a & ~b, rawXor: a ^ b})
	}
	performanceTestParse(res)
	for i, e in paramMap {
		for method in e
			performanceTestMethod(res, method, i, detailedOutput)
	}
}

randomNBitInt(n) {
	return (Random(0,1)*2-1) * Random(0, 2**Random(0,n))
}

randomNonZeroNBitInt(n) {
	return (Random(0,1)*2-1) * Random(1, 2**Random(0,n))
}

randomNonZeroNBitUInt(n) {
	return Random(1, 2**Random(0,n))
}

randomNBitUInt(n) {
	return Random(0, 2**Random(0,n))
}

parseTestFile(filePath, lineKeys) {
	tests := []
	testfile := FileRead(filePath, 'UTF-8')
	arr := []
	loop parse testfile, '`n', '`r' {
		cur := A_LoopField
		linePars := StrSplit(cur, [',', ' '])
		obj := { params: [] }
		for e in linePars {
			if e == ''
				continue
			id := StrSplit(e, ':')
			if SubStr(id[1], 1, 1) == 'p' && IsInteger(SubStr(id[1], 2))
				obj.params.push(id[2])
			else
				obj.%'raw' id[1]% := id[2]
		}
		arr.push(obj)
	}
	return arr
}

performanceTestParse(rawCache) {
	snap := qpc()
	for i, e in rawCache {
		for key, val in e.OwnProps() {
			try {
				if InStr(key, 'raw') {
					if val is Array {
						v := []
						for t in val
							v.push(BigInteger(t))
						
					} else {
						v := BigInteger(val)
					}
					e.%StrReplace(key, 'raw')% := v
				}
			} catch as q {
				throw Error("???")
			}
		}		
	}
	print('Parsed to BigIntegers in ' qpc() - snap)
	return rawCache
}

/**
 * Performance tests a method
 * @param cache cache := [ {a: , params: [b,c, ...], rawA:, rawParams: [rawB, rawC, ...], rawMethod: rawExpected, method: expected}, ...] One Test per row
 * @param method Method name. Assumed to be in BigInteger and not static
 * @param params How many params to give to the method
 */
performanceTestMethod(cache, method, paramCount, detailed := false) {
	static str := "
	( LTrim
		Test Method [{}]
		Runtime {}s
		Average Time per method execution: {}ms
		Errors: {}; Failures: {}; Successes: {}
		Total Runs: {}
		=========================
	)"
	errors := successes := failures := 0
	snap := qpc()
	for row in cache {
		pars := []
		loop(paramCount)
			pars.push(row.params[A_Index])
		try row.%method '_res'% := row.a.%method%(pars*)
		catch as e
			errors++
	}
	runTime := qpc() - snap
	for row in cache {
		if !row.HasOwnProp(method '_res')
			continue
		if (row.%method%.equals(row.%method '_res'%))
			successes++
		else {
			print("Test failed for " method ":`nExpected: " row.%method%.toString() "`nGot:      " row.%method '_res'%.toString())
			if detailed {
				print("Params: ")
				print(row.rawA '(' (row.a.signum ? '':'-') toString(row.a.mag) ')')
				loop(paramCount)
					print(row.rawParams[A_Index] '(' (row.params[A_Index].signum ? '':'-') toString(row.params[A_Index].mag) ')')
			}
			failures++
		}
	}
	print(Format(str, method, runTime, 1000 * runTime / cache.Length, errors, failures, successes, cache.Length))
}
