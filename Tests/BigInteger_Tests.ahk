; LibrariesV2/test_BigInteger.ahk

#Include "%A_LineFile%\..\..\LibrariesV2"
#Include BasicUtilities.ahk
#Include MathUtilities.ahk
#Include BigInteger.ahk
#SingleInstance Force


; Todo: Make test with 0, 1, -1, pos digit, neg digit, pos pow2 digit, neg pow2 digit, pos multi-digit, neg multi-digit and all combinations of the two
RunTests(1)


RunTests(detailedOutput := false) {
	; live-generate tests
	; testGcd(3000, detailedOutput)
	; testArithmeticMethodsSmall(3000,detailedOutput)
	; testBitWiseMethodsSmall(3000,detailedOutput)
	; testCacheMethods(detailedOutput)
	testSquareThresholds()
}

testGcd(loops := 1000, detailedOutput := false) {
	static methods := ['gcd', 'gcdInt']
	res := []
	snap := qpc()
	Loop(loops) {
		; random 64-bit nums
		p := []
		Loop(Random(0,7))
			p.push(randomNonZeroNBitInt(63))
		a := randomNonZeroNBitInt(63)
		res.push({rawA: a, rawParams:p, rawGcd: gcd(a,p*), rawGcdInt: gcd(a,p*)})
	}
	print('Created tests for gcd in ' qpc() - snap 's')
	res := performanceTestParse(res)
	intCopy := []
	performanceTestMethod(res, 'gcd', ,detailedOutput, 1)
	stats := performanceTestMethod(res, 'gcdInt',,detailedOutput, 1, 1)[1]
	print(stats)
}

testSquareThresholds() {
	arr := [[],[],[],[],[],[],[],[],[],[]]
	old := 0
	res := []
	Loop(300) ; create 10 big nums to square
		Loop(10)
		arr[A_Index].push(Random(1, 2**32-1))
	Loop(300) { ; test thresholds
		i := A_Index+3
		t := testT(i)
		res.push(t)
		print(format('Time @ {:03}: {}', i, t))

	}
	Loop(291) {
		i := A_Index
		s := 0
		Loop(10)
			s += res[i+A_Index-1]
		print('mv avg: ' format("{:03}", round(s/10,4)))
	}
	

	testT(n) {
		snap := qpc()
		loop(10)
			BigInteger.Helpers.squareMagnitude(arr[Ceil(A_Index / 3)], n)
		return Round((qpc() - snap) * 200,5)
	}
}

testCacheMethods(detailedOutput) {
	static cacheMethods := Map(
		"tests_arithmetic", Map(
			0, ["negate", "abs", "not"],
			1, ["add", "subtract", "multiply", "divide", "mod", "and", "andNot", "or", "xor", "equals", "compareTo"] ; not gcd because it takes forever
		),
		"tests_powAndBit", Map(
			1, ["pow", "shiftLeft", "shiftRight", "maskBits"]
		),
		"tests_roots", Map(
			0, ["sqrt"],
			1, ["nthroot"]
		)
	)
	print("Beginning to read tests")
	cacheTests := Map()
	for testFile, methodMap in cacheMethods {
		methodList := []
		for paramCount, methods in methodMap
			methodList.push(methods*)
		cacheTests[testFile] := parseTestFile(testFile, methodList)
	}
	print('Parsed text files.')
	for testFile, tests in cacheTests
		cacheTests[testFile] := performanceTestParse(tests)
	print('Parsed Tests to BigIntegers.')
	resps := []
	for testFile, methodMap in cacheMethods
		for paramCount, methods in methodMap
			for method in methods
				resps.push(performanceTestMethod(cacheTests[testFile], method, paramCount, detailedOutput))
	str := strMultiply('=', 50) '`n' FormatTime(,'yyyy-MM-dd-HH.mm.ss') '`n' objCollect(resps, (b,e) => b '`n' e[2], '') '`n'
	FileAppend(str, 'test_results.txt', 'UTF-8')
	FileAppend('Total stats: ' toString(resps[-1][1]), 'test_results.txt', 'UTF-8')
	print(resps[-1][1])
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
	testfile := FileRead(filePath '.txt', 'UTF-8')
	arr := []
	loop parse testfile, '`n', '`r' {
		cur := A_LoopField
		linePars := StrSplit(cur, [',', ' '])
		obj := { rawParams: [] }
		for e in linePars {
			if e == ''
				continue
			id := StrSplit(e, ':')
			if SubStr(id[1], 1, 1) == 'p' && IsInteger(SubStr(id[1], 2))
				obj.rawParams.push(id[2])
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
			if InStr(key, 'raw') {
				if val is Array {
					v := []
					for t in val
						v.push(BigInteger(t))
				} else
					v := BigInteger(val)
				e.%StrReplace(key, 'raw')% := v
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
performanceTestMethod(cache, method, paramCount?, detailed := false, staticMethod := false, useRawParams := false) {
	static str := "
	( LTrim
		Test Method [{1}]
		Runtime {2}s (avg time per method execution: {3}ms)
		Errors: {4}/{7}; Failures: {5}/{7}; Successes: {6}/{7} - {8}
		=========================
	)"
	static totalStats := { runs: 0, errors: 0, failures: 0, successes: 0, runtime: 0, methodsTested: [] }
	errors := successes := failures := 0
	methodRes := method . '_result'
	snap := qpc()
	for row in cache {
		if IsSet(paramCount) {
			params := []
			loop(paramCount)
				params.push(useRawParams ? row.rawParams[A_Index] : row.params[A_Index])
		} else
			params := useRawParams ? row.rawParams : row.params
		a := useRawParams ? row.rawA : row.a
		row.%methodRes% := staticMethod ? BigInteger.%method%(a, params*) : a.%method%(params*)
		; try row.%methodRes% := staticMethod ? BigInteger.%method%(a, params*) : a.%method%(params*)
		; catch as e
		; 	errors++
	}
	runTime := qpc() - snap
	for row in cache {
		if !row.HasOwnProp(methodRes)
			continue
		try {
			if (row.%method% is BigInteger ? row.%method%.equals(row.%methodRes%) : objCompare(row.%method%, row.%methodRes%))
				successes++
			else {
				if detailed {
					print("Test failed for " method ":")
					print("Expected: " row.%method%.toString() "( " (row.%method%.signum ? '':'-') toString(row.%method%.mag) " )")
					print("Got:      " row.%methodRes%.toString() "( " (row.%methodRes%.signum ? '':'-') toString(row.%methodRes%.mag) " )")
					print("Params: ")
					print(row.rawA '(' (row.a.signum ? '':'-') toString(row.a.mag) ')')
					loop(paramCount)
						print(row.rawParams[A_Index] '(' (row.params[A_Index].signum ? '':'-') toString(row.params[A_Index].mag) ')')
					print("================")
				}
				failures++
			}
		} catch as e {
			print(row)
			throw e
		}
	}
	totalStats.errors += errors
	totalStats.failures += failures
	totalStats.successes += successes
	totalStats.runs += cache.Length
	totalStats.runtime += runTime
	totalStats.methodsTested.push(method)
	retStr := print(Format(str, method, Round(runTime,5), Round(1000 * runTime / cache.Length,5), errors, failures, successes, cache.Length, (successes == cache.Length ? '✅' : '❌')))
	return [totalStats, retStr]
}
