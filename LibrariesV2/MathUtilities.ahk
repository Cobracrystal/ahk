﻿; https://github.com/cobracrystal/ahk

#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"

; MAIN FUNCTION
calculateExpression(mode := "print") {
	expression := fastCopy()
	result := createResult(expression)
	;	if (Instr(expression, "x"))	; bad for recognizing equations.
	;		endSymbol := " => x = "
	;	else
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

createResult(expression) {
	clean := RegExReplace(expression, "\s+", "")
	if (RegexMatch(clean, "^factor\((\d+)\)$", &m))
		return factorization(clean)
	else if (RegexMatch(clean, "^prime\((\d+)\)$", &m))
		return primetest(m[1])
	else if (RegexMatch(clean, "^(?:gcd|ggt)\(((?:\d+(?:\.\d+)?,)*\d+(?:\.\d+)?)\)$", &m))
		return gcd(StrSplit(m[1], ",")*)
	else if (RegexMatch(clean, "^(?:lcm|kgv)\(((?:\d+(?:\.\d+)?,)*\d+(?:\.\d+)?)\)$", &m))
		return lcm(StrSplit(m[1], ",")*)
	else if (RegexMatch(clean, "^(?:lcd|kgt)\(((?:\d+(?:\.\d+)?,)*\d+(?:\.\d+)?)\)$", &m))
		return lcd(StrSplit(m[1], ",")*)
	else if (RegexMatch(clean, "^(?:gcm|ggv)\(((?:\d+(?:\.\d+)?,)*\d+(?:\.\d+)?)\)$", &m))
		return gcm(StrSplit(m[1], ",")*)
	; if (InStr(expression, "x")) {
	; 	expression := RegexReplace(expression, "(\d)x", "$1*x")
	; 	expression := RegexReplace(expression, "(\d),(\d)", "$1.$2")
	; 	expression := extendFactorials(expression)
	; 	return equation_solver(expression)
	; }
	; return roundProper(ExecScript(clean_expression(expression)))
	return readableFormat(ExecScript(clean_expression(expression)))

}

readableFormat(numStr) {
	if (InStr(numStr, "."))
		numStr := RTrim(numStr, "0")
	if (SubStr(numStr, -1) = ".")
		numStr := SubStr(numStr, 1, -1)
	return
}

equation_transformer(equation) {
	transformed_form := equation
	equalSignPos := InStr(equation, "=")
	leftside := SubStr(equation, 1, equalSignPos - 1)
	rightside := SubStr(equation, equalSignPos + 1)
	if (!equalSignPos)
		return
	return transformed_form
}

factorization(expression) {
	RegexMatch(expression, "(\d+)", &m)
	n := m[1]
	if (n == 0)
		return 0
	if (n < 0)
		n := abs(n)
	i := 2
	ti := 1
	c := 0
	if (primetest(n))
		return "1*" . n
	s := ""
	while (n != 1) {
		if (Mod(n, i) == 0) {
			n := n / i
			if (ti != i && c != 0) {
				s .= (s == "" ? "" : "*") . ti . (c > 1 ? "^" . c : "")
				c := 1
			}
			else
				c++
			ti := i
			if (n == 1)
				s .= (s == "" ? "" : "*") . ti . (c > 1 ? "^" . c : "")
			i := 1
		}
		i++
	}
	return s
}

equation_solver(equation) {
	if (!equation)
		return
	if (RegexMatch(equation, "^\s*x\s*=(.*)", &m))
		return ExecScript(m[1])
	if (RegexMatch(equation, "^(\+|-|)(\d*\.\d*|\d*)(\*|)(x\*\*2|)(\+|-|)(\d*\.\d*|\d*)(\*|)(x|)(\+|-|)(\d*\.\d*|\d*)=(\+|-|)(\d*\.\d*|\d*)$", &m))
		return quadratic_equation_solver(m)
	return roundProper(ExecScript(equation))
}

quadratic_equation_solver(m) {
	if ((m[11] && !m[12]) || (m[9] && !m[10]) || (m[8] && !m[9] && m[10]) || (m[7] && !m[8]) || (m[6] && !m[8] && m[10]) || (m[5] && !m[6] && m[7]) || (m[5] && !m[6] && !m[8] && m[9]) || (m[3] && !m[4] && (m[5] || m[6] || m[7])) || (m[2] && !m[4] && m[6]) || (m[1] && !m[2] && m[3]) || (m[1] && !m[4] && m[5]))
		return
	;	pos := RegexMatch(equation, "^(\+|-|)(\d*\.\d*|\d*)(\*|)(x\*\*2|)(\+|-|)(\d*\.\d*|\d*)(\*|)(x|)(\+|-|)(\d*\.\d*|\d*)=(\+|-|)(\d*\.\d*|\d*)$", m)
	;	pos := RegexMatch(equation, "^$1     $2            $3   $4       $5     $6            $7   $8  $9     $10            $11    $12           $")
	if (!m[4])
		a := 0
	else {
		a := (m[1] = "-" ? -1 : 1)
		if (m[2])
			a *= m[2]
	}
	if (!m[8])
		b := 0
	else {
		b := (m[5] = "-" ? -1 : 1)
		if (m[6])
			b *= m[6]
		else {
			if (!m[5]) {
				b := (m[1] = "-" ? -1 : 1)
				if (m[2])
					b *= m[2]
			}
		}
	}
	if (m[8] = "x") {
		c := (m[9] = "-" ? -1 : 1)
		if (m[10])
			c *= m[10]
	}
	else if (m[6])
		c := (m[5] = "-" ? -1 : 1) * m[6]
	if (m[12])
		c += (m[11] = "-" ? 1 : -1) * (m[12] ? m[12] : 0)
	;	MsgBox % "1: " . m[1] . "`n2: " . m[2] . "`n3: " . m[3] . "`n4: " . m[4] . "`n5: " . m[5] . "`n6: " . m[6] . "`n7: " m[7] . "`n8: " . m[8] . "`n9: " . m[9] . "`n10: " . m[10] . "`n11: " . m[11] . "`n12: " . m[12] . "`na: " . a . "`nb: " . b . "`nc: " . c
	if (b ** 2 - 4 * a * c < 0) {
		p1 := (b != 0 ? -1 * b / (2 * a) : "")
		p2sol1 := (a > 0 && p1 ? "+" : "")
		p2sol2 := (a < 0 && p1 ? "+" : (a > 0 ? "-" : ""))
		p3 := roundProper(sqrt(-1 * (b ** 2 - 4 * a * c)) / (2 * a))
		p3 := (p3 = 1 ? "" : p3)
		sol1 := roundProper(p1) . p2sol1 . p3 . "i"
		sol2 := roundProper(p1) . p2sol2 . p3 . "i"
	}
	else {
		if (a) {
			sol1 := roundProper((-1 * b + sqrt(b ** 2 - 4 * a * c)) / (2 * a))
			sol2 := roundProper((-1 * b - sqrt(b ** 2 - 4 * a * c)) / (2 * a))
		}
		else
			return roundProper(-c / b)
	}
	return "[" . sol1 . ", " . sol2 . "]"
}


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

clean_expression(expression) {
	list := [{ key: "\pi", val: "3.141592653589793" }, { key: "\phi", val: "((1+sqrt(5))/2)" }, { key: "\e", val: "2.718281828459045" }
	]
	for i, e in list
		expression := StrReplace(expression, e.key, e.val)
	expression := Trim(expression, "`n`r`t ")
	return expression
}

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
 * Given integer, returns array of its factors. Includes 1 and n itself
 * @param n integer
 * @returns {Array} 
 */
factor(n) {
	num := Abs(n)
	factors := [num == n ? 1 : -1]
	divisor := 2
	while (num != 1) {
		if (Mod(num, divisor) == 0) {
			num /= divisor
			factors.push(divisor)
			continue
		}
		divisor++
	}
	factors.push(num)
	return factors
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
		seq := sortArray(uniqueArray(sequence), "N")
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