#Include %A_LineFile%\..\..\LibrariesV2\BigInteger.ahk

class BigIntegerUtils {

	/**
	 * Given integer, returns array of its prime factors. Includes 1 and n itself
	 * @param {BigInteger} n
	 * @returns {Array} 
	 */
	static primefactor(n) {
		n := BigInteger.validateBigInteger(n)
		if (n.equals(0))
			return [BigInteger.ZERO]
		local factors := []
		n := n.abs()
		divisor := BigInteger.TWO
		limit := n.sqrt(&rem)
		if rem.compareTo(0) > 0
			limit := limit.add(1)
		while (!n.equals(1)) {
			if (divisor.compareTo(limit) > 0) {
				factors.push(n)
				break
			}
			if (n.mod(divisor, &quotient).equals(BigInteger.ZERO)) {
				n := quotient
				limit := n.sqrt(&rem)
				if rem.compareTo(0) > 0
					limit := limit.add(1)
				factors.push(divisor)
				continue
			}
			divisor := divisor.add(1)
		}
		return factors
	}

	; /**
	;  * Given integer, returns array of all its factors. Includes 1 and n itself.
	;  * @param n Integer
	;  * @returns {Array} Array of factors. 
	;  */
	; static factors(n) {
	; 	_pfactors := this.primefactor(n)
	; 	_factors := []
	; 	pfactorExpos := []
	; 	prev := 0
	; 	for i, e in _pfactors {
	; 		if (prev == e) {
	; 			factExpos.push(e**factExpos.Length)
	; 		} else {
	; 			if (i != 1)
	; 				pfactorExpos.push(factExpos)
	; 			factExpos := [1, e]
	; 		}
	; 		prev := e
	; 	}
	; 	pfactorExpos.push(factExpos)
	; 	for factArr in combinations(pfactorExpos)
	; 		_factors.push(prod(factArr*))
	; 	return objSortNumerically(_factors)
	; }

	; /**
	;  * Gives the Least Common Multiple
	;  * @param nums 
	;  * @returns {Number} 
	;  */
	; static lcm(nums*) {
	; 	value := 1
	; 	for i, e in nums
	; 		value *= e
	; 	return nums.Length == 1 ? value : value//gcd(nums*)
	; }

	; /**
	;  * Returns least common divisor of given numbers
	;  * @param nums List of numbers
	;  * @returns {Integer} 
	;  */
	; static lcd(nums*) {
	; 	i := 2
	; 	while (i * i <= Max(nums*)) {
	; 		flag := true
	; 		for j, e in nums {
	; 			if (Mod(e, i) != 0)
	; 				flag := false
	; 		}
	; 		if (flag)
	; 			return i
	; 		i++
	; 	}
	; }

	; /**
	;  * Returns greatest common multiple of given numbers. (Why is this function here?)
	;  * @param nums 
	;  * @returns {Number} 
	;  */
	; static gcm(nums*) {
	; 	n := lcm(nums*)
	; 	while (n < 2**62)
	; 		n *= 2
	; 	return n
	; }

	; ; returns the index of the smallest value
	; static MinIndex(value1, valueN*) {
	; 	curMin := value1
	; 	curI := 1
	; 	for i, e in valueN
	; 		if e < curMin {
	; 			curMin := e
	; 			curI := i+1
	; 		}
	; 	return curI
	; }

	; ; returns the index of the largest value
	; static MaxIndex(value1, valueN*) {
	; 	curMin := value1
	; 	curI := 1
	; 	for i, e in valueN
	; 		if e > curMin {
	; 			curMin := e
	; 			curI := i+1
	; 		}
	; 	return curI
	; }

	/**
	 * Given an Integer, returns whether it is prime.
	 * @param {BigInteger} n Integer
	 * @param {BigInteger} foundFactor Integer
	 * @returns {Integer} true or false 
	 */
	static primetest(n, &foundFactor?) {
		n := BigInteger.validateBigInteger(n).abs()
		if (n.equals(BigInteger.TWO))
			return true
		i := BigInteger.TWO
		limit := n.sqrt().add(1)
		while (i.compareTo(limit) <= 0) {
			if (n.mod(i).equals(BigInteger.ZERO)) {
				foundFactor := i
				return false
			}
			i := i.add(1)
		}
		return true
	}

	; /**
	;  * Given a number, returns closest prime number
	;  * @param n 
	;  */
	; static closestPrime(n) {
	; 	i := 0
	; 	sw := -1
	; 	while(true) {
	; 		k := Round(n) + (sw := sw * -1) * i
	; 		if primetest(k)
	; 			return k
	; 		i++
	; 	}
	; }

	; /**
	;  * Given a number, returns next prime number
	;  * This is incredibly inefficient
	;  * @param n 
	;  */
	; static nextPrime(n) {
	; 	if self := primetest(n)
	; 		return n
	; 	k := n + (Mod(n, 2) == 0)
	; 	while(true) {
	; 		k += 2
	; 		if primetest(k)
	; 			return k
	; 		print(k)
	; 	}
	; }
	
	/**
	 * 
	 * @param {BigInteger} n 
	 * @returns {BigInteger} 
	 */
	static factorial(n) {
		; stirling approx derivation: ln(n!) = ln(1) + ln(2) + ... + ln(n) = sum1-n: ln j ≈ integral1-n ln x dx = n ln n - n + 1
		; if (n.add(299).divide(n).compareTo(Floor(n.log())) < 0)
		if (n * log(n) - n + 1 >= Log(BigInteger.INT32)) {
			r := BigInteger.ONE
			Loop(n)
				r := r.multiply(A_Index)
			return r
		} else {
			r := 1 
			Loop(n)
				r *= A_Index
			return BigInteger(r)
		}
	}

	static binomialCoefficient(n,m) {
		n := BigInteger.validateBigInteger(n)
		m := BigInteger.validateBigInteger(m)
		loops := n.subtract(m)
		if loops.compareTo(10000) > 0
			throw(BigInteger.Error.GIGABYTE_OPERATION["BinomialCoefficient", n])
		loops := Integer(loops.toString())
		f1 := BigInteger.ONE
		Loop(loops)
			f1 := f1.multiply(m.add(A_Index))
		f2 := f1.divide(this.factorial(loops))
		return f2
	}

	/**
	 * Calculates the chance of m successes with chance p occuring in n events.
	 * This is equivalent to simply calculating choose(n, m) * p**m * (1-p)**(n-m)
	 * @param n Total number of events
	 * @param m Number of successes.
	 * @param p Probability of one success.
	 */
	static probabilityMassFunction(n, m, p) {
		n := BigInteger.validateBigInteger(n)
		m := BigInteger.validateBigInteger(m)
		return Float(this.binomialCoefficient(n, m).toStringApprox()) * p**Integer(m.toString()) * (1-p)**Integer(n.subtract(m).toString())
	}

	/**
	 * Returns an array (or optionally, map) of probabilities for all possible amounts of successes occuring with chance p.
	 * This is not efficient (as in, no caching or efficient binomial coefficient calculation) 
	 * @param n Total number of events.
	 * @param p Probability of success.
	 */
	static binomialDistribution(n, p, asMap := false) {
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
	 * Given an integer, finds all numbers smaller than it such that they have any integer root
	 * @param n 
	 * @returns {Array} 
	 */
	static perfectPowers(n) {
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

	; ALIAS SECTION
	static pfactor(n) => this.primefactor(n)
	static pfactors(n) => this.primefactor(n)
	; static factor(n) => this.factors(n)
	; static prime(n) => this.primetest(n)
	; static ggT(n) => this.gcd(n)
	; static kgv(n) => this.lcm(n)
	; static kgt(n) => this.lcd(n)
	; static ggv(n) => this.gcm(n)
	static choose(n,m) => this.binomialCoefficient(n,m)
	; static Sum(vals*) => this.objgetsum(vals)
	; static Prod(vals*) => this.objGetProd(vals)
}