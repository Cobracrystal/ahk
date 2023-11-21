#Include %A_ScriptDir%\Libraries\BasicUtilities.ahk

;// MAIN FUNCTION
calculateExpression() {
	expression := fastCopy()
	result := createResult(expression)
;//	if (Instr(expression, "x"))	;// bad for recognizing equations.
;//		endSymbol := " => x = "
;//	else 
		endSymbol := " = "
	if (result = "")
		return
	Send {Right}
	fastPrint(endSymbol . result)
}

/* ExecScript functions
	Asc(string) -> gives ascii code
	Chr(number) -> gives character from number
	
*/

createResult(expression) {
;// expression: implicit function factors
	if (RegexMatch(expression, "^factor\(\d+\)$") || RegexMatch(expression, "^fact\(\d+\)$") || RegexMatch(expression, "^factors\(\d+\)$"))
		return factorization(expression)
;// expression: implicit function prime
	if (RegexMatch(expression, "^prim\(\d+\)$") || RegexMatch(expression, "^prime\(\d+\)$")) {
		RegexMatch(expression, "O)(\d+)", m)
		return primetest(m.Value(1))
	}
;// integer functions and stuff done: clean
	expression := clean_expression(expression)
;//	expression := equation
	if (InStr(expression, "x")) {
;//		expression := equation_transformer(expression)
		return equation_solver(expression)
	}
	return roundProper(ExecScript(expression))	
	
}

equation_transformer(equation) {
	transformed_form := equation
	equalSignPos := InStr(equation, "=")
	leftside := SubStr(equation, 1, equalSignPos-1)
	rightside := SubStr(equation, equalSignPos+1)
	if (!equalSignPos)
		return
	return transformed_form
}

factorization(expression) {
	RegexMatch(expression, "O)(\d+)", m)
	n := m.Value(1)
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
		if (Mod(n,i)==0) {
			n := n/i
			if (ti != i && c != 0) {
				s .= (s == "" ? "" : "*") . ti . (c>1 ? "^" . c : "")
				c := 1
			}
			else
				c++
			ti := i
			if (n==1)
				s .= (s == "" ? "" : "*") . ti . (c>1 ? "^" . c : "") 
			i := 1
		}
		i++
	}
	return s
}

primetest(n) {
	if n is not integer
		return -1
	if (n == 2)
		return true
	i := 2
	while (i <= sqrt(n)) {
		if (Mod(n,i)==0)
			return false
		i++
	}
	return true
}

equation_solver(equation) {
	if (!equation)
		return
	if (RegexMatch(equation, "O)^\s*x\s*=(.*)", m))
		return ExecScript(m.Value(1))
	if (RegexMatch(equation, "O)^(\+|-|)(\d*\.\d*|\d*)(\*|)(x\*\*2|)(\+|-|)(\d*\.\d*|\d*)(\*|)(x|)(\+|-|)(\d*\.\d*|\d*)=(\+|-|)(\d*\.\d*|\d*)$", m))
		return quadratic_equation_solver(m)
	return roundProper(ExecScript(equation))
}

quadratic_equation_solver(m) {
	if ((m.Value(11) && !m.Value(12)) || (m.Value(9) && !m.Value(10)) || (m.Value(8) && !m.Value(9) && m.Value(10)) || (m.Value(7) && !m.Value(8)) || (m.Value(6) && !m.Value(8) && m.Value(10)) || (m.Value(5) && !m.Value(6) && m.Value(7)) || (m.Value(5) && !m.Value(6) && !m.Value(8) && m.Value(9)) || (m.Value(3) && !m.Value(4) && (m.Value(5) || m.Value(6) || m.Value(7))) || (m.Value(2) && !m.Value(4) && m.Value(6)) || (m.Value(1) && !m.Value(2) && m.Value(3)) || (m.Value(1) && !m.Value(4) && m.Value(5)))
		return
;	pos := RegexMatch(equation, "O)^(\+|-|)(\d*\.\d*|\d*)(\*|)(x\*\*2|)(\+|-|)(\d*\.\d*|\d*)(\*|)(x|)(\+|-|)(\d*\.\d*|\d*)=(\+|-|)(\d*\.\d*|\d*)$", m)
;	pos := RegexMatch(equation, "O)^$1     $2            $3   $4       $5     $6            $7   $8  $9     $10            $11    $12           $")
	if (!m.Value(4))
		a := 0
	else {
		a := (m.Value(1) = "-" ? -1 : 1)
		if (m.Value(2))
			a *= m.Value(2)
	}
	if (!m.Value(8))
		b := 0
	else {
		b := (m.Value(5)= "-" ? -1 : 1)
		if (m.Value(6))
			b *= m.Value(6)
		else {
			if (!m.Value(5)) {
				b := (m.Value(1)= "-" ? -1 : 1)
				if (m.Value(2))
					b *= m.Value(2)
			}
		}
	}
	if (m.Value(8) = "x") {
		c := (m.Value(9)= "-" ? -1 : 1)
		if (m.Value(10)) 
			c *= m.Value(10)
	}
	else if (m.Value(6))
		c := (m.Value(5)= "-" ? -1 : 1) * m.Value(6)
	if (m.Value(12))
		c += (m.Value(11) = "-" ? 1 : -1) * (m.Value(12) ? m.Value(12) : 0)
;	MsgBox % "1: " . m.Value(1) . "`n2: " . m.Value(2) . "`n3: " . m.Value(3) . "`n4: " . m.Value(4) . "`n5: " . m.Value(5) . "`n6: " . m.Value(6) . "`n7: " m.Value(7) . "`n8: " . m.Value(8) . "`n9: " . m.Value(9) . "`n10: " . m.Value(10) . "`n11: " . m.Value(11) . "`n12: " . m.Value(12) . "`na: " . a . "`nb: " . b . "`nc: " . c
	if (b**2 - 4*a*c < 0) {
		p1 := (b!=0 ? -1*b/(2*a) : "")
		p2sol1 := (a > 0 && p1 ? "+" : "")
		p2sol2 := (a < 0 && p1 ? "+" : (a > 0 ? "-" : ""))
		p3 := roundProper(sqrt(-1*(b**2-4*a*c))/(2*a))
		p3 := (p3 = 1 ? "" : p3)
		sol1 := roundProper(p1) . p2sol1 . p3 . "i"
		sol2 := roundProper(p1) . p2sol2 . p3 . "i"
	}
	else {
		if (a) {
			sol1 := roundProper((-1*b + sqrt(b**2-4*a*c))/(2*a))
			sol2 := roundProper((-1*b - sqrt(b**2-4*a*c))/(2*a))
		}
		else
			return roundProper(-c/b)
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
	list := [ {"key":"pi","val":"3.141592653589793"}
			, {"key":"phi","val":"((1+sqrt(5))/2)"}
			, {"key":"e","val":"2.718281828459045"}
			, {"key":",","val":"."}
			, {"key":"^","val":"**"}
			, {"key":"²","val":"**2"}
			, {"key":"³","val":"**3"}]
	for index, element in list 
	{
		expression := StrReplace(expression, element.key, element.val)
	}
	expression := RegexReplace(expression, "\s+")
	expression := RegexReplace(expression, "(\d)x", "$1*x")
	expression := extendFactorials(expression)
	return expression
}

extendFactorials(expression) {
	Loop {
		if (!RegexMatch(expression, "O)(?<!\.)(\d+?)!", f))
			break
		fs := "1.0"
		tVal := f.Value(1)
		if (tVal > 180)
			expression := RegexReplace(expression, "(?<!\.)(\d+?)!", "2**1030",,1)
		Loop % tVal-1
		{
			fs .= "*" . A_Index+1
		}
		expression := RegexReplace(expression, "(?<!\.)(\d+?)!", fs,,1)
	}
	return expression
}

roundProper(number) {
	if isInt(number)
		return Round(number)
	else
		return RTrim(number, "0.")
}

isInt(number) {
	return (Round(number) = number)
}