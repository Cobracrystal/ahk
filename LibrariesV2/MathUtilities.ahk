; https://github.com/cobracrystal/ahk

#Include MsgBoxAsGui.ahk
#Include BigInteger.ahk
#Include ObjectUtilities.ahk

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
	limit := Ceil(sqrt(n))
	while (n != 1) {
		if (divisor > limit) {
			factors.push(n)
			break
		}
		if (Mod(n, divisor) == 0) {
			n //= divisor
			limit := Ceil(sqrt(n))
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
	_pfactors := primefactor(n)
	_factors := []
	pfactorExpos := []
	prev := 0
	for i, e in _pfactors {
		if (prev == e) {
			factExpos.push(e**factExpos.Length)
		} else {
			if (i != 1)
				pfactorExpos.push(factExpos)
			factExpos := [1, e]
		}
		prev := e
	}
	pfactorExpos.push(factExpos)
	for factArr in combinations(pfactorExpos)
		_factors.push(prod(factArr*))
	return objsort(_factors,,"N")
}

/**
 * Given an array (or Map) containing arrays, returns all possible combinations of values from the subarrays, where each combinations contains one item from each subarray.
 * @param arr
 * Eg, [[1,2], [3,4]] returns [[1,3],[1,4],[2,3],[2,4]]
 * @example 
 * combinations([[1,2]]) => [[1],[2]] 
 * combinations([[1,2],[3,4]]) => [[1,3],[1,4],[2,3],[2,4]] 
 * @example
 * ; calculating (a+b) * (c + d + k) * g
 * combinations([["a","b"],["c","d","k"],["g"]]) => [["a","c","g"],["a","d","g"],["a","k","g"],["b","c","g"],["b","d","g"],["b","k","g"]] 
 * ; the result is thus acg + adg + akg + bcg + bdg + bkg
 */
combinations(arr) {
	collection := []
	if objGetValueCount(arr) == 1 {
		for sel in arr[1]
			collection.push([sel])
		return collection
	}
	t := combinations(arrayIgnoreIndex(arr, 1))
	for sel in arr[1]
		for combs in t
			collection.push([sel, combs*])
	return collection
}

/**
 * Given an array of (unique) values, chooses all unique combinations with n of those values, **ignoring order** and returns an array of them.
 * @param arr An array of any values.
 * @param n How long the combination should be. Must be 1 <= n <= arr.Length 
 * @example 
 * chooseCombinations([1,2,3,4], 2) => [[1,2],[1,3],[1,4],[2,3],[2,4],[3,4]]
 * chooseCombinations([1,2,3,4,5],3) => [[1,2,3],[1,2,4],[1,2,5],[1,3,4],[1,3,5],[1,4,5],[2,3,4],[2,3,5],[2,4,5],[3,4,5]]
 */
chooseCombinations(arr, n) {
	if (arr.Length <= n)
		return [arr.Clone()]
	collection := []
	if (n == 1) {
		for element in arr
			collection.push([element])
		return collection
	}
	Loop(arr.Length - n + 1) {
		i := A_Index
		for combination in chooseCombinations(arraySlice(arr, i+1), n - 1)
			collection.push([arr[i], combination*])
	}
	return collection
}

/**
 * Given an array n of some values, calculates all unique combinations of values of the array with length n.
 * @param arr 
 * @param n 
 * @example chooseCombinationsOrdered([1,2,3,4], 2) => [[1,2],[1,3],[1,4],[2,1],[2,3],[2,4],[3,1],[3,2],[3,4],[4,1],[4,2],[4,3]]
 */
chooseCombinationsOrdered(arr, n) {
	if arr.length <= n
		return [arr.clone()]
	collection := []
	if (n == 1) {
		for e in arr
			collection.push([e])
		return collection
	}
	for i, e in arr {
		for k, v in chooseCombinationsOrdered(arrayIgnoreIndex(arr, i), n - 1) {
			v.InsertAt(1, e)
			collection.push(v)
		}
	}
	return collection
}

/**
 * Given array, returns powerset of all of its members.
 * @param arr
 * @returns {Array}
 * @example powerset(["a","b","c"]) => [[],["a"],["b"],["a","b"],["c"],["a","c"],["b","c"],["a","b","c"]] 
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
 * Given a list of parameters, returns array of all permutations of its members
 * @param arr 
 * @returns {Array}
 * @example permutations([1,2,3]) =>
	[
	[1,2,3],
	[1,3,2],
	[2,1,3],
	[2,3,1],
	[3,1,2],
	[3,2,1]
	]
 */
permutations(arr) {
	if arr.Length == 1
		return [arr]
	local permutationArr := []
	for i, e in arr {
		perms := permutations(arrayIgnoreIndex(arr, i))
		for f in perms
			permutationArr.push([e, f*])
	}
	return permutationArr
}

/**
 * Gives the greatest Common Divisor of specified Numbers using the Euclidean algorithm
 * @param additionalNums 
 * @returns {Integer} 
 */
gcd(num, additionalNums*) {
	additionalNums.push(num)
	copyNums := []
	for e in additionalNums
		if e != 0
			copyNums.push(abs(e))
	while (copyNums.Length > 1) {
		tNums := []
		curMin := Min(copyNums*)
		firstEncounter := true
		for i, e in copyNums {
			if (firstEncounter && e == curMin) {
				tNums.Push(e)
				firstEncounter := false
				continue
			}
			m := Mod(e, curMin)
			if m != 0
				tNums.push(m)
		}
		copyNums := tNums
	}
	return copyNums[1]
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
 * Returns greatest common multiple of given numbers. (Why is this function here?)
 * @param nums 
 * @returns {Number} 
 */
gcm(nums*) {
	n := lcm(nums*)
	while (n < 2**62)
		n *= 2
	return n
}

; returns the index of the smallest value
MinIndex(value1, valueN*) {
	curMin := value1
	curI := 1
	for i, e in valueN
		if e < curMin {
			curMin := e
			curI := i+1
		}
	return curI
}

; returns the index of the largest value
MaxIndex(value1, valueN*) {
	curMin := value1
	curI := 1
	for i, e in valueN
		if e > curMin {
			curMin := e
			curI := i+1
		}
	return curI
}

/**
 * Given an Integer, returns whether it is prime.
 * @param n Integer
 * @returns {Integer} true or false 
 */
primetest(n) {
	if !IsInteger(n)
		return false
	if (n == 2)
		return true
	i := 2
	limit := Ceil(sqrt(n))
	while (i <= limit) {
		if (Mod(n, i) == 0)
			return 0
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

/**
 * Given a number, returns next prime number
 * This is incredibly inefficient
 * @param n 
 */
nextPrime(n) {
	if self := primetest(n)
		return n
	k := n + (Mod(n, 2) == 0)
	while(true) {
		k += 2
		if primetest(k)
			return k
	}
}

factorial(n) {
	; stirling approx derivation: ln(n!) = ln(1) + ln(2) + ... + ln(n) = sum1-n: ln j ≈ integral1-n ln x dx = n ln n - n + 1
	if (n is BigInteger || n * log(n) / log(2.719) - n + 1 > 300) {
		r := BigInteger.ONE
		Loop(n)
			r := r.multiply(A_Index)
		return r
	}
	r := 1.0
	Loop(n)
		r *= Float(A_Index)
	return r
}

binomialCoefficient(n,m) {
	f1 := 1
	Loop(n-m)
		f1 *= (m+A_Index)/A_Index
	return f1
}

/**
 * Calculates the chance of m successes with chance p occuring in n events.
 * This is equivalent to simply calculating choose(n, m) * p**m * (1-p)**(n-m)
 * @param n Total number of events
 * @param m Number of successes.
 * @param p Probability of one success.
 */
probabilityMassFunction(n, m, p) {
	return binomialCoefficient(n, m) * p**m * (1-p)**(n-m)
}

/**
 * Returns an array (or optionally, map) of probabilities for all possible amounts of successes occuring with chance p.
 * This is not efficient (as in, no caching or efficient binomial coefficient calculation) 
 * @param n Total number of events.
 * @param p Probability of success.
 */
binomialDistribution(n, p, asMap := false) {
	if (asMap) {
		result := Map()
		Loop(n+1)
			result[A_Index-1] := probabilityMassFunction(n, A_Index - 1, p)
	} else {
		result := []
		result.Length := n+1
		Loop(n+1)
			result[A_Index] := probabilityMassFunction(n, A_Index - 1, p)
	}
	return result
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
		index := objContainsValue(diffs, bestDiff)
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

pascalsTriangle(nRows) {
	rows := []
	rows.push([1])
	Loop(nRows - 1) {
		p := rows[A_Index]
		nextRow := [1]
		Loop(p.Length - 1)
			nextRow.push(p[A_Index] + p[A_Index + 1])
		nextRow.push(1)
		rows.push(nextRow)
	}
	return rows
}

streetInDice(streetLen, diceAmount) {
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
		amount += numscontainStreet(dices, streetLen)
	}
	return [amount, nums]

	numscontainStreet(sequence, streetLen) {
		; LOG
		strDice := "["
		Loop(sequence.Length)
			strDice .= sequence[A_Index] . ","
		seq := objsort(objGetUniques(sequence),, "N")
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
Sum(vals*) => objgetsum(vals)
Prod(vals*) => objGetProd(vals)