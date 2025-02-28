; https://github.com/cobracrystal/ahk

#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"

class expressionCalculator {

	static setWolframAlphaToken(token) {
		this.token := token
	}

	static calculateExpression(mode := "print") {
		expression := fastCopy()
		result := this.giveUpAndCallWolframalpha(expression)
;		result := this.readableFormat(ExecScript(this.clean_expression(expression)))
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
				msgbox(result)
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
			throw Error("No token set for WolframAlpha API")
		encoded := Uri.encode(expression)
		url := baseURL . encoded . queryParameters . this.token
		retObj := sendRequest(url, "GET")
		return retObj
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


extendFactorials(expression) {
	Loop {
		if (!RegexMatch(expression, "(?<!\.)(\d+?)!", &f))
			break
		fs := "1.0"
		tVal := f[1]
		if (tVal > 180)
			expression := RegexReplace(expression, "(?<!\.)(\d+?)!", "2**1030", , 1)
		Loop (tVal - 1)
		{
			fs .= "*" . A_Index + 1
		}
		expression := RegexReplace(expression, "(?<!\.)(\d+?)!", fs, , 1)
	}
	return expression
}


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
	num := Abs(n)
	local factors := []
	divisor := 2
	while (num != 1) {
		if (Mod(num, divisor) == 0) {
			num //= divisor
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
	factors := uniquesFromArray(factors)
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
	return 2**63 - mod(2**63-1,240) - 1
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
	Loop Parse, str, "," {
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
		seq := sortArray(uniquesFromArray(sequence), "N")
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

; ALIAS SECTION
pfactor(n) => primefactor(n)
pfactors(n) => primefactor(n)
factor(n) => factors(n)
prime(n) => primetest(n)
ggT(n) => gcd(n)
kgv(n) => lcm(n)
kgt(n) => lcd(n)
ggv(n) => gcm(n)