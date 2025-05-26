﻿; https://github.com/cobracrystal/ahk

#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"

class expressionCalculator {

	static setWolframAlphaToken(token) {
		this.token := token
	}
	
	static calculateExpression(mode := "print") {
		expression := fastCopy()
		if (SubStr(expression, 1, 2) == "w:")
			result := this.giveUpAndCallWolframalpha(SubStr(expression, 3))
		else if (SubStr(expression, 1, 2) == "b:")
			return ExecScript(this.clean_expression(SubStr(expression, 3)), false, true)
		else
			result := this.readableFormat(ExecScript(this.clean_expression(expression)))
		; READ THE ERROR STREAM. IF THERE'S SOME ERROR IN THERE, ALSO GIVE IT TO WOLFRAMALPHA
		; ADD A CONTEXT MENU OPTION FOR THIS, EITHER WOLFRAM OR SOMETHING ELSE OR LOCAL
	;	result := this.giveUpAndCallWolframalpha(expression)
		endSymbol := " = "
		if (result = "")
			return
		Send("{Right}")
		switch (SubStr(mode, 1, 1)) {
			case "p":
				fastPrint(endSymbol . result)
			case "c":
				A_Clipboard := result
			default:
				MsgBoxAsGui(result,"Expression Result")
		}
	}

	static readableFormat(numStr) {
		if (InStr(numStr, "."))
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

	static clean_expression(expression) {
		list := [{ key: "\pi", val: "3.141592653589793" }, { key: "\phi", val: "((1+sqrt(5))/2)" }, { key: "\e", val: "2.718281828459045" }
		]
		for i, e in list
			expression := StrReplace(expression, e.key, e.val)
		expression := Trim(expression, "`n`r`t ")
		return expression
	}
}
; MAIN FUNCTION


/*	+5x+3=0
	133*x^2+7x-50=-13 = [0.501783, -0.554414]
	x^2=-1
	78x**2+9548x+34=3471 = [0.358918, -122.769175]
	structure:
	-> check for brackets. save positions.
	-> check for +,-. If its inside brackets, ignore.
	-> check for *,/. Find instance outside of brackets.
	-> remove instance, add to right side. Add brackets around other side.
	-> repeat until everything on left side that is left is in brackets.
	-> remove brackets.
	-> recursively call function until no brackets are left.
*/

roundProper(number, precision := 12) {
	if (!IsNumber(number) || IsSpace(number))
		return number
	if (IsInteger(number) || Round(number) == number)
		return Integer(number)
	else
		return RTrim(Round(number, precision), "0.")
}

/**
 * Given integer, returns array of its prime factors. Includes 1 and n itself
 * @param n integer
 * @returns {Array} 
 */
primefactor(n) {
	if (n == 0)
		return [0]
	local factors := []
	n := Abs(n)
	divisor := 2
	while (n != 1) {
		if (divisor > Ceil(sqrt(n))) {
			factors.push(n)
			break
		}
		if (Mod(n, divisor) == 0) {
			n //= divisor
			factors.push(divisor)
			continue
		}
		divisor++
	}
	return factors
}

/**
 * Given integer, returns array of all its factors. Includes 1 and n itself.
 * @param n Integer
 * @returns {Array} Array of factors. 
 */
factors(n) {
	local pfactors := primefactor(n)
	factorSets := powerset(pfactors)
	local factors := []
	for i, e in factorSets {
		f := 1
		for j, k in e
			f *= k
		factors.push(f)
	}
	factors := arraySort(arrayUniques(factors), "N")
	return factors
}

/**
 * Given array, returns powerset of all of its members.
 * @param arr 
 */
powerset(arr) {
	local ps := []
	i := 0
	while (i < 2**arr.Length) {
		subset := []
		j := 0
		while (j < arr.Length) {
			if (i & (1 << j))
				subset.push(arr[j+1])
			j++
		}
		ps.push(subset)
		i++
	}
	return ps
}

/**
 * Given array, returns array of all permutations of its members
 * @param arr 
 */
permutations(arr) {
	if arr.Length == 1
		return [arr]
	local permutationArr := []
	Loop(arr.Length) {
		cValue := arr[A_Index]
		perms := permutations(arrayIgnoreIndices(arr, A_Index))
		for i, e in perms
			permutationArr.push([cValue, e*])
	}
	return permutationArr
}

/**
 * Gives the greatest Common Divisor of specified Numbers using the Euclidean algorithm
 * @param nums 
 * @returns {Integer} 
 */
gcd(nums*) {
	objRemoveValue(nums, 0)
	if (nums.Length == 1)
		return nums[1]
	tMin := Min(nums*)
	index := objContainsValue(nums, tMin)
	for i, e in nums
		nums[i] := (index == i ? e : Mod(e, tMin))
	return gcd(nums*)
}

/**
 * Gives the Least Common Multiple
 * @param nums 
 * @returns {Number} 
 */
lcm(nums*) {
	value := 1
	for i, e in nums
		value *= e
	return nums.Length == 1 ? value : value//gcd(nums*)
}

/**
 * Returns least common divisor of given numbers
 * @param nums List of numbers
 * @returns {Integer} 
 */
lcd(nums*) {
	i := 2
	while (i * i <= Max(nums*)) {
		flag := true
		for j, e in nums {
			if (Mod(e, i) != 0)
				flag := false
		}
		if (flag)
			return i
		i++
	}
}

/**
 * Returns greatest common multiple of given numbers.
 * @param nums 
 * @returns {Number} 
 */
gcm(nums*) {
	n := lcm(nums*)
	return 2**63 - 1
}


/**
 * Given an Integer, returns whether it is prime.
 * @param n Integer
 * @returns {Integer} 
 */
primetest(n) {
	if !IsInteger(n)
		return false
	if (n == 2)
		return true
	i := 2
	while (i <= Ceil(sqrt(n))) {
		if (Mod(n, i) == 0)
			return false
		i++
	}
	return true
}

/**
 * Given a number, returns closest prime number
 * @param n 
 */
closestPrime(n) {
	i := 0
	sw := -1
	while(true) {
		k := Round(n) + (sw := sw * -1) * i
		if primetest(k)
			return k
		i++
	}
}

factorial(n) {
	if n == 1 || n == 0
		return 1
	return Float(n) * factorial(n-1)
}

binomialCoefficient(n,m) {
	f1 := 1
	Loop(n-m)
		f1 *= (m+A_Index)/A_Index
	return f1
}

/**
 * Returns Integer multiplication n * m that is closest to given number. 
 * @param num Number
 * @param {Integer} direction 0 for both directions, -1 to give the largest number smaller than num, 1 to give the smallest number larger than num
 * @returns {Array} Values n,m
 */
getClosestRectangle(num, direction := 0) {
	i := 0
	sw := -1
	while(true) {
		k := Round(num) + (sw := sw * -1) * i
		if primetest(k) {
			i++
			continue
		}
		facts := factor(k)
		minV := sqrt(k)
		; we have a valid decomposition, now we want the most square one from all valid factors
		diffs := []
		for i, e in facts
			diffs.push(Abs(minV - e))
		bestDiff := Min(diffs*)
		for i, e in diffs
			if (e == bestDiff) {
				index := i
				break
			}
		f1 := facts[index]
		f2 := k // f1
		return [f1, f2]
	}
}


/**
 * Given an integer, finds all numbers smaller than it such that they have any integer root
 * @param n 
 * @returns {Array} 
 */
perfectPowers(n) {
	t := Floor(sqrt(n)), i := 2, arr := []
	while (i <= t) {
		Loop {
			if (i ** (A_Index + 1) > n)
				break
			str .= i ** (A_Index + 1) ","
		}
		i++
	}
	str := Sort(str, "N D,")
	Loop Parse, SubStr(str, 1, -1), "," {
		if (IsDigit(A_LoopField))
			arr.push(A_LoopField)
	}
	return arr
}

streetInDice(streetLen, diceAmount, filePath) {
	strDice := ""
	nums := 6**diceAmount
	dices := []
	amount := 0
	fullStr := ""
	Loop(diceAmount)
		dices.push(1)
	Loop(nums) {
		Loop(diceAmount) {
			if (dices[A_Index] < 6) {
				dices[A_Index]++
				break
			}
			else
				dices[A_Index] := 1
		}
		; next dice sequence
		thing := numscontainStreet(dices, streetLen)
		strDice .= "] " thing "`n"
		fullStr .= strDice
		strDice := ""
		amount += thing
	}
	FileAppend(fullStr, filePath)
	FileAppend(amount " out of " nums " contain a street of " streetLen " in them. That's " amount / nums * 100 "%", filePath)

	numscontainStreet(sequence, streetLen) {
		; LOG
		strDice := "["
		Loop(sequence.Length)
			strDice .= sequence[A_Index] . ","
		seq := arraySort(arrayUniques(sequence), "N")
		strDice .= "] sorted ["
		Loop(seq.Length)
			strDice .= seq[A_Index] . ","
		; LOG END
		Loop(seq.Length - StreetLen + 1) {
			isStreet := true
			start := A_Index
			Loop(StreetLen - 1) {
				if (seq[start + A_Index - 1] != seq[start + A_Index] - 1) {
					isStreet := false
					break
				}
			}
			if (isStreet)
				return 1
		}
		return 0
	}
}

linearRegressionParameters(datasetX, datasetY) {
	avgX := 0
	for x in datasetX
		avgX += x
	avgX /= datasetX.Length
	avgY := 0
	for y in datasetY
		avgY += y
	avgY /= datasetY.Length
	b1 := 0
	b2 := 0
	for i, e in datasetX {
		b1 += (e - avgX) * (datasetY[i] - avgY)
		b2 += (e - avgX)**2
	}
	b := b1/b2
	a := avgY - b  * avgX
	return [a, b]
}

; ALIAS SECTION
pfactor(n) => primefactor(n)
pfactors(n) => primefactor(n)
factor(n) => factors(n)
prime(n) => primetest(n)
ggT(n) => gcd(n)
kgv(n) => lcm(n)
kgt(n) => lcd(n)
ggv(n) => gcm(n)
choose(n,m) => binomialCoefficient(n,m)