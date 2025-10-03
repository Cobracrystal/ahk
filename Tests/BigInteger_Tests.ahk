; LibrariesV2/test_BigInteger.ahk

#Include "%A_LineFile%\..\..\LibrariesV2"
#Include BasicUtilities.ahk
#Include MathUtilities.ahk
#Include BigInteger.ahk
#SingleInstance Force

/* ❌✅
 * ; Construction from and output to native value
 * BigInteger.Prototype.__New(intOrString)
 * BigInteger.valueOf(intOrString)
 * ⭕ BigInteger.fromMagnitude([digits*], 1)
 * BigInteger.fromAnyMagnitude([digits*], radix, signum)
 * BigInteger.fromTwosComplement([signWord, digits*])
 * BigInteger.Prototype.toString(radix)
 * BigInteger.Prototype.toStringApprox(radix)
 * BigInteger.Prototype.getFirstNDigits(radix, digits)
 * BigInteger.Prototype.Length(radix)
 * ; Arithmet
 * BigInteger.Prototype.abs()
 * BigInteger.Prototype.negate()
 * BigInteger.Prototype.add(anyInt)
 * BigInteger.Prototype.subtract(anyInt)
 * BigInteger.Prototype.multiply(anyInt)
 * BigInteger.Prototype.pow(anyInt)
 * BigInteger.Prototype.divide(anyInt, &remainder)
 * BigInteger.Prototype.divideByIntPower(int, int, &remainder)
 * BigInteger.Prototype.mod(anyInt)
 * BigInteger.mod(numerator, divisor)
 * BigInteger.Prototype.gcd(anyInt)
 * BigInteger.gcd(anyInt, anyInts*)
 * BigInteger.Prototype.sqrt()
 * BigInteger.Prototype.nthRoot()
 * ; Comparis
 * BigInteger.Prototype.equals(anyInt)
 * BigInteger.Prototype.compareTo(anyInt)
 * BigInteger.Prototype.min(anyInt*)
 * BigInteger.Prototype.max(anyInt*)
 * BigInteger.min(anyInt*)
 * BigInteger.max(anyInt*)
 * BigInteger.Sort(anyInt, anyInts*)
 * ; bitwise arithmet
 * BigInteger.Prototype.and(anyInt)
 * BigInteger.Prototype.not()
 * BigInteger.Prototype.andNot(anyInt)
 * BigInteger.Prototype.or(anyInt)
 * BigInteger.Prototype.xor(anyInt)
 * BigInteger.Prototype.shiftLeft(int)
 * BigInteger.Prototype.shiftRight(int)
 * BigInteger.Prototype.maskBits(int)
 * ; Type conversi
 * BigInteger.Prototype.shortValue()
 * BigInteger.Prototype.int32Value()
 * BigInteger.Prototype.intValue()
 * BigInteger.Prototype.getBitLength()
 * BigInteger.Prototype.getLowestSetBit()
 * BigInteger.Prototype.toTwosComplement()
 * ; Prim
 * ⭕ BigInteger.Prototype.isProbablePrime()
 * ⭕ BigInteger.Prototype.nextProbablePrime()
 * ; Properti
 * ⭕ BigInteger.Prototype.getSignum()
 * ⭕ BigInteger.Prototype.getMagnitude()
 * ; Other
 * ⭕ BigInteger.Prototype.Clone()		
 */

; Todo: Make test with 0, 1, -1, pos digit, neg digit, pos pow2 digit, neg pow2 digit, pos multi-digit, neg multi-digit and all combinations of the two
RunTests(0)


RunTests(detailedOutput := false) {
	; live-generate tests
	; testGcd(3000, detailedOutput)
	; testArithmeticMethodsSmall(3000,detailedOutput)
	; testBitWiseMethodsSmall(3000,detailedOutput)
	testCacheMethods(detailedOutput)
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
	stats := performanceTestMethod(res, 'gcdInt',,detailedOutput, 1, 1)
	print(stats)
}

testCacheMethods(detailedOutput) {
	static cacheMethods := Map(
		"tests_arithmetic", Map(
			0, ["negate", "abs", "not"],
			1, ["add", "subtract", "multiply", "divide", "gcd", "and", "andNot", "or", "xor", "equals", "compareTo"]
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
	for testFile, methodMap in cacheMethods
		for paramCount, methods in methodMap
			for method in methods
				stats := performanceTestMethod(cacheTests[testFile], method, paramCount, detailedOutput)
	print(stats)
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
					print("Test failed for " method ":`nExpected: " row.%method%.toString() "`nGot:      " row.%methodRes%.toString())
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
	print(Format(str, method, runTime, 1000 * runTime / cache.Length, errors, failures, successes, cache.Length, (successes == cache.Length ? '✅' : '❌')))
	return totalStats
}
