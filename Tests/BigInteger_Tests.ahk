; LibrariesV2/test_BigInteger.ahk

#Include "%A_LineFile%\..\..\LibrariesV2"
#Include BasicUtilities.ahk
#Include MathUtilities.ahk
#Include BigInteger.ahk
#SingleInstance Force
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
	for e in methods
		performanceTestMethod(res, e, ,,1)

}

testCacheMethods(detailedOutput) {
	static cache1Methods := ["add", "subtract", "multiply", "divide", "gcd", "and", "andNot", "or", "xor", "equals", "compare"]
	static cache1Methods2 := ["negate", "abs", "not"]
	static cache2Methods := ["pow", "shiftLeft", "shiftRight", "maskBits"]
	static cache3Methods := ["sqrt", "nthroot"]
	print("Beginning to read tests")
	t := cache1Methods.Clone()
	for e in cache1Methods2
		t.push(e)
	arFull := parseTestFile("tests_arithmetic.txt", t)
	arPow := parseTestFile("tests_powAndBit.txt", cache2Methods)
	arRoot := parseTestFile("tests_iroot.txt", cache3Methods)
	print('Parsed text files.')
	cacheFull := performanceTestParse(arFull)
	cachePow := performanceTestParse(arPow)
	cacheRoot := performanceTestParse(arPow)
	print('Parsed Tests to BigIntegers.')
	; test arithmetic
	for e in cache1Methods
		performanceTestMethod(cacheFull, e, 1, detailedOutput)
	for e in cache1Methods2
		performanceTestMethod(cacheFull, e, 0, detailedOutput)
	for e in cache2Methods
		performanceTestMethod(cachePow, e, 1, detailedOutput)
	for e in cache3Methods
		performanceTestMethod(cacheRoot, e, 1, detailedOutput)
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
				throw q
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
performanceTestMethod(cache, method, paramCount?, detailed := false, staticMethod := false) {
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
		if IsSet(paramCount) {
			pars := []
			loop(paramCount)
				pars.push(row.params[A_Index])
		} else
			pars := row.params
		try row.%method '_res'% := staticMethod ? BigInteger.%method%(row.a, pars*) : row.a.%method%(pars*)
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
			if detailed {
				print("Test failed for " method ":`nExpected: " row.%method%.toString() "`nGot:      " row.%method '_res'%.toString())
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
