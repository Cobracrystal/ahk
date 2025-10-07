/************************************************************************
 * @description A class to handle arbitrary precision Integers
 * @author cobracrystal
 * @date 2025/10/07
 * @version 1.0.0
 ***********************************************************************/

/**
 * METHODS
 * @example
 * ; Construction from and output to native values
 * .__New(intOrString)
 * BigInteger.valueOf(intOrString)
 * BigInteger.fromMagnitude([digits*], signum)
 * BigInteger.fromAnyMagnitude([digits*], radix, signum)
 * BigInteger.fromTwosComplement([signWord, digits*])
 * .toString(radix)
 * .toStringApprox(radix)
 * .getFirstNDigits(radix, digits)
 * .Length(radix)
 * ; Arithmetic
 * .abs()
 * .negate()
 * .add(anyInt)
 * .subtract(anyInt)
 * .multiply(anyInt)
 * .pow(anyInt)
 * .divide(anyInt, &remainder)
 * .divideByIntPower(divisor, exponent, &remainder)
 * .mod(anyInt)
 * BigInteger.mod(numerator, divisor)
 * .gcd(anyInt)
 * BigInteger.gcd(anyInt, anyInts*)
 * .sqrt(&remainder)
 * .nthRoot(n, &remainder)
 * ; Comparison
 * .equals(anyInt)
 * .compareTo(anyInt)
 * .min(anyInts*)
 * .max(anyInts*)
 * BigInteger.min(anyInt, anyInts*)
 * BigInteger.max(anyInt, anyInts*)
 * BigInteger.Sort(anyInt, anyInts*)
 * ; bitwise arithmetic
 * .and(anyInt)
 * .not()
 * .andNot(anyInt)
 * .or(anyInt)
 * .xor(anyInt)
 * .shiftLeft(int)
 * .shiftRight(int)
 * .maskBits(int)
 * ; Type conversion
 * .shortValue()
 * .int32Value()
 * .intValue()
 * .getBitLength()
 * .getLowestSetBit()
 * .toTwosComplement()
 * ; Properties
 * .getSignum()
 * .getMagnitude()
 * ; Other
 * .Clone()
 * BigInteger.validateBigInteger()
 * BigInteger.gcdInt(intValue, intValues*)
 * ; Constants
 * BigInteger.MINUS_ONE ; -1
 * BigInteger.ZERO ; 0
 * BigInteger.ONE ; 1
 * BigInteger.TWO ; 2
 * BigInteger.TEN ; 10
 * BigInteger.THOUSAND ; 1000
 * BigInteger.TWO_POW32 ; 2^32
 */

class BigInteger {
	/**
	 * Constructs a BigInteger given any integer-like input
	 * @param {Integer | String} anyInt An Integer or a string representing an integer
	 * @returns {BigInteger} The constructed BigInteger
	 * @example 
	 * BigInteger(2394)
	 * BigInteger(-923849234922394)
	 * BigInteger('-11111112334902834928304820934820938429304820348234')
	 */
	__New(anyInt, radix := 10) {
		if (Type(anyInt) != "String")
			anyInt := String(anyInt)
		first := SubStr(anyInt, 1, 1)
		switch first {
			case '-':
				this.signum := -1
				anyInt := SubStr(anyInt, 2)
			case '+':
				this.signum := 1
				anyInt := SubStr(anyInt, 2)
			default:
				this.signum := 1
		}
		if (anyInt == "0") {
			this.signum := 0
			this.mag := [0]
			return this
		}
		if !IsAlnum(anyInt) || anyInt == ""
			throw BigInteger.Error.NOT_INTEGER[anyInt]
		this.mag := BigInteger.Helpers.magnitudeFromString(anyInt, radix)
		return this
	}

	/**
	 * Returns a new BigInteger. Synonymous with creating a BigInteger instance
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @param {Integer} radix The radix or base of the given number.
	 * @returns {BigInteger} The constructed BigInteger
	 */
	static valueOf(anyInt, radix := 10) => BigInteger(anyInt, radix)

	/**
	 * Constructs a BigInteger given its base 2^32 digit representation and signum.
	 * This does NOT do validation checks before accepting the magnitude.
	 * @param {Array} mag an array of integers < 2^32 in bigEndian notation
	 * @param {Integer} signum The signum of the number. 1 for positive, -1 for negative, 0 for 0. If magnitude is an array containing only 0, signum will be automatically set to 0.
	 * @returns {BigInteger} The Constructed Value
	 * @example
	 * BigInteger.fromMagnitude([1,2], -1) => - (1 * 2**32 + 2) = -4294967298
	 * BigInteger.fromMagnitude([0], -1) => 0 ; signum gets ignored
	 */
	static fromMagnitude(mag, signum := 1) {
		static template := BigInteger(0)
		obj := (Object.Clone)(template)
		obj.signum := (mag.Length = 1 && mag[1] = 0) ? 0 : signum
		obj.mag := mag.Clone()
		return obj
	}

	/**
	 * Constructs a BigInteger given any base digit representation and signum.
	 * @param {Array} mag An array of integers < 2^32 in bigEndian notation
	 * @param {Integer} radix The base of the given magnitude. Defaults to 10
	 * @param {Integer} signum The signum of the number. 1 for positive, -1 for negative, 0 for 0. If magnitude is an array containing only 0, signum will be automatically set to 0.
	 * @returns {BigInteger} The Constructed Value
	 * @example
	 * BigInteger.fromAnyMagnitude([3,2,3,0,1,2,3], 4) ; Represents 3230123 in base 4
	 * BigInteger.fromAnyMagnitude(['AE','BF','10','0', '5', '1F'], 256) ; Equivalent to 0xAEBF1000551F in base 16
	 */
	static fromAnyMagnitude(mag, radix := 10, signum := 1) {
		signum := (mag.Length = 1 && mag[1] = 0) ? 0 : signum
		mag := BigInteger.Helpers.validateMagnitudeRadix(mag, radix)
		exponent := BigInteger.Helpers.getMaxComputableRadixPower(radix)
		maxRadixMag := BigInteger.Helpers.shrinkMagnitudeToPowRadix(mag, radix, exponent)
		return BigInteger.Helpers.fromTrustedMagnitude(BigInteger.Helpers.normalizeMagnitudeBase(maxRadixMag, radix**exponent), signum)
	}

	/**
	 * Constructs a BigInteger from a magnitude in twos complement, interpreting it from the leading sign word.
	 * @param {Array} mag A Magnitude of the form [(0 | 0xFFFFFFFF), ...]. Must include the leading sign word (Otherwise all values are ambiguous)
	 * @returns {BigInteger} The created BigInteger
	 * @example
	 * BigInteger.fromTwosComplement([0, 0xFFFFFFFF]).toString() => 4294967295
	 * BigInteger.fromTwosComplement([0xFFFFFFFF, 0xFFFFFFFF]).toString() => -1
	 * BigInteger.fromTwosComplement([0]).toString() => 0
	 * BigInteger.fromTwosComplement([5]) => Error
	 */
	static fromTwosComplement(mag) {
		len := mag.Length - 1
		if len == 0 && mag[1] == 0
			return BigInteger.ZERO
		if len <= 0
			throw BigInteger.Error.BAD_TWO_COMPLEMENT[1, len]
		mag := mag.Clone()
		leadingSign := mag.RemoveAt(1)
		if (leadingSign == 0)
			return BigInteger.Helpers.fromTrustedMagnitude(BigInteger.Helpers.stripLeadingZeros(mag), 1)
		if leadingSign != BigInteger.INT_MASK
			throw BigInteger.Error.BAD_TWO_COMPLEMENT[2, leadingSign]
		newMag := []
		newMag.Length := len
		unchangedWords := BigInteger.Helpers.fromTrustedMagnitude(mag).getLowestSetBit() >>> 5 ; a bit ugly
		Loop (unchangedWords) ; copy rightmost words that are 0
			newMag[-A_index] := 0
		newMag[-unchangedWords - 1] := (~mag[-unchangedWords - 1] + 1) & BigInteger.INT_MASK
		Loop (len - unchangedWords - 1)
			newMag[A_Index] := ~mag[A_Index] & BigInteger.INT_MASK
		return BigInteger.Helpers.fromTrustedMagnitude(BigInteger.Helpers.stripLeadingZeros(newMag), -1)
	}

	/**
	 * Returns a String representing (this).
	 * @param {Integer} radix. Must be 2 <= radix <= 36
	 * @returns {String} The number this BigInteger represents. May start with -. Never starts with +.
	 * @example
	 * b := BigInteger.fromAnyMagnitude([54,123], 150, -1) ; base 150
	 * b.toString(17) => "-1B7C" ; base 17
	 * b.toString(2) => "-10000000011111" ; base 2
	 */
	toString(radix := 10) {
		if (this.signum == 0)
			return '0'
		if radix < 2 || radix > 36
			throw BigInteger.Error.INVALID_RADIX[radix]

		str := this.signum < 0 ? '-' : ''
		ex := BigInteger.Helpers.getMaxComputableRadixPower(radix)
		powRadix := radix**ex
		newMag := BigInteger.Helpers.convertMagnitudeBase(this.mag, powRadix)
		if (radix == 10) {
			str .= newMag[1]
			Loop (newMag.Length - 1)
				str .= Format("{:09}", newMag[A_Index + 1])
		} else { ; this is *significantly* faster than directly converting to radix
			newMag := BigInteger.Helpers.expandMagnitudeToRadix(newMag, powRadix, radix)
			for d in newMag
				str .= d > 9 ? Chr(d + 55) : d
		}
		return str
	}

	/**
	 * Returns a String representing an approximate representation of (this) in scientific format (x.xxxxxx * radix^exp) with 10 total digits
	 * @param {Integer} radix. Must be 2 <= radix <= 36
	 * @returns {String} The number this BigInteger represents. May start with -. Never starts with +.
	 * @example
	 * BigInteger.fromMagnitude([1, 0, 5], 1).toStringApprox() => 1.844674407e+19
	 */
	toStringApprox(radix := 10) {
		if (this.signum == 0)
			return '0'
		if radix < 2 || radix > 36
			throw BigInteger.Error.INVALID_RADIX[radix]

		exponent := this.Length(radix) - 1
		ndigits := this.getFirstNDigits(radix, 10)
		return SubStr(ndigits, 1, 2) . "." SubStr(ndigits, 3) . "e+" exponent
	}

	/**
	 * Returns the first N digits of the BigInteger. This is slower than directly calling toString for small numbers, but may be preferable for very large numbers due to string manipulation being expensive.
	 * @param {Integer} radix The radix that the digits should be returned in. Should be between 2 and 36
	 * @param {Integer} digits The amount of digits to return. Numbers larger than the length of the biginteger will simply return toString()
	 * @returns {String} The first N digits of the BigInteger
	 * @example
	 * BigInteger('-82389429834').getFirstNDigits(10, 5) => '-82389'
	 */
	getFirstNDigits(radix := 10, digits := 10) {
		if (this.signum == 0)
			return '0'
		if radix < 2 || radix > 36
			throw BigInteger.Error.INVALID_RADIX[radix]
		len := this.Length(radix)
		if digits >= len
			return this.toString(radix)
		if digits < 1
			return ''
		; wordsNeeded := this.mag.Length - (len - digits) * Log(radix) / (32 * Log(2))
		wordsNeeded := Min(Ceil(digits * Log(radix) / (32 * Log(2))) + 1, this.mag.Length)
		newMag := []
		Loop (wordsNeeded)
			newMag.push(this.mag[A_Index])
		loop (this.mag.Length - wordsNeeded)
			newMag.push(0)
		ndigits := BigInteger.Helpers.fromTrustedMagnitude(newMag, this.signum).divideByIntPower(radix, len - digits)
		return ndigits.toString(radix)
	}

	/**
	 * Returns the Length of the number in the specified base (default 10). An alias for base 2 is given through getBitLength()
	 * For Zero, this always returns 0.
	 * @param {Integer} radix The base in which to compute the Length of. Must be between 2 and 2**32 (base 1 is this BigInteger).
	 * @returns {Integer} The Length of this BigInteger in the given base
	 * @example
	 * BigInteger(-923489234).Length() => 9 ; sign is not counted
	 * BigInteger(0).Length() => 0
	 */
	Length(radix := 10) {
		static log10ofBase := Log(BigInteger.INT32)
		top := this.mag[1]
		n := this.mag.Length
		if n == 1 && top == 0
			return 0
		if radix == 2
			return this.getBitLength()
		if radix == 2**32
			return this.mag.Length
		hatL := ((n - 1) * log10ofBase + Log(top)) / Log(radix)
		digitCandidate := Floor(hatL) + 1
		/**
		 * dCandidate is at most ±1 off from the actual result.
		 * Floating point errors do not matter here:
		 * float error in log(int32) ≈ 8.85e-16, so for (n-1) * errLog > 0.5, we need n >= 10^14, which is >25 Petabytes of storage.
		 * Similarly, fractional resolution is irrelevant.
		 * Instead, exactness matters:
		 * topHatL ≈ Log(N) = (n-1) log(B) + log(top)
		 * but: N = top * B^(n-1) + lower = B^(n-1) * (top + lower/B^(n-1)), thus
		 * log(N) = (n-1) log(B) + log(top + lower/B^(n-1))
		 * 	= (n-1) log(B) + log(top) + log(1 + lower/(top*B^(n-1)))
		 * set delta = log(1 + lower/(top*B^(n-1)))
		 * so log(N) = topHatL + delta.
		 * Since lower/B^n-1 < 1, delta < log(1+1/top) so use this as upper bound to check if delta should be computed (as it usually is < 10^-6)
		 */
		upper_bound := Log(1 + 1 / top) / Log(radix)
		fracpart := hatL - Floor(hatL)
		dist := Min(fracpart, 1 - fracpart)
		if dist > upper_bound
			return digitCandidate
		frac := 0
		scale := 1 / BigInteger.INT32
		epsilon := 2**-52
		Loop (n - 1) { ; lower / B^n-1
			cur := this.mag[A_Index + 1] * scale
			if cur < epsilon ; 2**(32*33) > 0, but 2**(32*34) == 0. Thus this will always have 34 iterations at most.
				break
			scale /= BigInteger.INT32
			frac += cur
		}
		delta := Log(1 + frac / top) / Log(radix)
		hatL += delta
		digitCandidate := Floor(hatL + 1e-18) + 1 ; minimal correction if we are 1 epsilon off
		return digitCandidate
	}

	/**
	 * Returns the absolute value of (this)
	 * @returns {BigInteger} A guaranteed positive-or-zero BigInteger
	 */
	abs() {
		if this.signum == 0
			return BigInteger.ZERO
		return BigInteger.fromMagnitude(this.mag, 1)
	}

	/**
	 * Returns a new BigInteger with the signum flipped.
	 * @returns {BigInteger} A BigInteger with a signum inverted from (this).
	 */
	negate() => BigInteger.fromMagnitude(this.mag, -this.signum)

	/**
	 * Adds the given Integer Representation to (this) and returns a new BigInteger representing the result.
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {BigInteger} The sum of the two BigIntegers
	 */
	add(anyInt) {
		anyInt := BigInteger.validateBigInteger(anyInt)
		if (this.signum == anyInt.signum) {
			magSum := BigInteger.Helpers.addMagnitudes(this.mag, anyInt.mag)
			return BigInteger.Helpers.fromTrustedMagnitude(magSum, this.signum)
		} else {
			comparison := BigInteger.Helpers.compareMagnitudes(this.mag, anyInt.mag)
			if !comparison
				return BigInteger.ZERO
			minuend := comparison == 1 ? this : anyInt
			subtrahend := comparison == 1 ? anyInt : this
			return BigInteger.Helpers.fromTrustedMagnitude(BigInteger.Helpers.subtractMagnitudes(minuend.mag, subtrahend.mag), minuend.signum)
		}
	}

	/**
	 * Adds the given Integer Representation to (this) and returns a new BigInteger representing the result.
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {BigInteger} The sum of the two BigIntegers
	 */
	subtract(anyInt) {
		anyInt := BigInteger.validateBigInteger(anyInt)
		if (this.signum != anyInt.signum) {
			if !this.signum
				return anyInt.negate()
			if !anyInt.signum
				return this.Clone()
			return BigInteger.Helpers.fromTrustedMagnitude(this.abs().add(anyInt.abs()).mag, this.signum)
		} else {
			comparison := BigInteger.Helpers.compareMagnitudes(this.mag, anyInt.mag)
			if comparison == 0
				return BigInteger.ZERO
			minuend := comparison == 1 ? this : anyInt
			subtrahend := comparison == 1 ? anyInt : this
			magDiff := BigInteger.Helpers.subtractMagnitudes(minuend.mag, subtrahend.mag)
			return BigInteger.Helpers.fromTrustedMagnitude(magDiff, comparison == 1 ? this.signum : -this.signum)
		}
	}

	/**
	 * Multiplies the given Integer Representation with (this) and returns a new BigInteger representing the new result
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {BigInteger} The product of (this) with the given Number
	 */
	multiply(anyInt) {
		anyInt := BigInteger.validateBigInteger(anyInt)
		if this.signum == 0 || anyInt.signum == 0
			return BigInteger.ZERO
		magProduct := BigInteger.Helpers.multiplyMagnitudes(this.mag, anyInt.mag)
		return BigInteger.Helpers.fromTrustedMagnitude(magProduct, this.signum * anyInt.signum)
	}

	/**
	 * Exponentiates (this) by the given exponent. As a negative exponent will mean x^-n = 1/x^n, which in the case of integer division is always 0, this function throws an error on a negative exponent.
	 * @param {Integer} exponent A positive integer to exponentiate (this) by.
	 * @returns {BigInteger} The result of the exponentiation of (this) to the power of exponent
	 */
	pow(exponent) {
		if exponent is BigInteger {
			if exponent.mag.Length > 1
				throw BigInteger.Error.GIGABYTE_OPERATION['pow', exponent]
			exponent := exponent.signum * exponent.mag[1]
		}
		if exponent < 0
			throw BigInteger.Error.ILLEGAL_NEGATIVE['pow', exponent]
		if exponent >= BigInteger.INT32
			throw BigInteger.Error.GIGABYTE_OPERATION['pow', exponent]
		if !this.signum
			return exponent == 0 ? BigInteger.ONE : BigInteger.ZERO
		if !exponent
			return BigInteger.ONE
		powerofTwo := this.getLowestSetBit() - 1
		if (powerofTwo > 0) {
			partToSquare := this.shiftRight(powerofTwo)
			if (partToSquare.getBitLength() == 1) {
				mag := BigInteger.Helpers.shiftMagnitudeLeft([1], powerofTwo * exponent)
				return BigInteger.Helpers.fromTrustedMagnitude(mag, exponent & 0x1 && this.signum < 0 ? -1 : 1)
			}
		} else if this.getBitLength() == 1 {
			return (this.signum < 0 && exponent & 0x1) ? BigInteger.MINUS_ONE : BigInteger.ONE
		} else {
			partToSquare := this
		}
		magSquare := partToSquare.mag
		workingExponent := exponent
		result := [1]
		while (workingExponent != 0) { ; this is not incredibly faster than regular repeated multiplication, but becomes much faster because squareMagnitude can be implemented in O(n)
			if (workingExponent & 1)
				result := BigInteger.Helpers.multiplyMagnitudes(result, magSquare)
			if ((workingExponent >>>= 1) != 0) ; cuts off right-most bit if it is 1
				magSquare := BigInteger.Helpers.squareMagnitude(magSquare)
		}
		if (powerofTwo)
			result := BigInteger.Helpers.shiftMagnitudeLeft(result, powerofTwo * exponent)
		res := BigInteger.Helpers.fromTrustedMagnitude(result, exponent & 0x1 ? this.signum : 1)
		return res
	}

	/**
	 * Divides (this) by the given Integer Representation and returns a new BigInteger representing the new result
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @param {&BigInteger?} remainder This variable will be set to the remainder of the division, if requested.
	 * @returns {BigInteger} The result of division, rounded down to the nearest BigInteger. 22/7 = 3
	 */
	divide(anyInt, &remainder?) {
		anyInt := BigInteger.validateBigInteger(anyInt)
		if anyInt.signum == 0
			throw ZeroDivisionError()
		cmp := BigInteger.Helpers.compareMagnitudes(this.mag, anyInt.mag)
		if (cmp == 0) {
			remainder := BigInteger.ZERO
			return this.signum * anyInt.signum > 0 ? BigInteger.ONE : BigInteger.MINUS_ONE
		}
		if (cmp == -1) {
			remainder := this.Clone()
			return BigInteger.ZERO
		}
		if (anyInt.mag.Length == 1)
			return this.divideByIntPower(anyInt.signum * anyInt.mag[1], 1, &remainder?)
		magQuotient := BigInteger.Helpers.divideMagnitudes(this.mag, anyInt.mag, &rem)
		remainder := BigInteger.Helpers.fromTrustedMagnitude(rem, this.signum)
		return BigInteger.Helpers.fromTrustedMagnitude(magQuotient, this.signum * anyInt.signum)
	}

	/**
	 * Divides (this) by the given <2**32 int raised to pow. Note that this is in O(pow * ...) as it runs pow Loops of a word divide. Nonetheless this is far superior to .Divide in performance.
	 * @param {Integer} divisor Any Integer.
	 * @param {Integer} pow An Integer representing the power that the divisor will be raised to.
	 * @param {&BigInteger?} remainder This variable will be set to the remainder of the division, if requested.
	 * @returns {BigInteger} The result of the integer division of (this) // divisor**pow
	 */
	divideByIntPower(divisor, pow := 1, &remainder?) {
		if divisor == 0
			throw ZeroDivisionError()
		signum := this.signum * (divisor > 0 || pow & 0x1 == 0 ? 1 : -1)
		divisor := abs(divisor)
		if (isPowerOfTwo := (divisor & (divisor - 1) == 0)) { ; divisor is power of two. 
			shiftBits := BigInteger.Helpers.numberOfTrailingZeros(divisor) * pow
			if shiftBits > this.getBitLength()
				rem := this.mag.Clone()
			else { ; do not use maskBits as that uses twos complement
				rem := []
				words := shiftBits >>> 5
				bits := shiftBits & 0x1F
				rem.Length := words
				Loop (words)
					rem[-A_Index] := this.mag[-A_Index]
				rem.InsertAt(1, this.mag[-words - 1] & ((1 << bits) - 1))
				BigInteger.Helpers.stripLeadingZeros(rem)
			}
			remainder := BigInteger.Helpers.fromTrustedMagnitude(rem, this.signum)
			res := BigInteger.Helpers.shiftMagnitudeRight(this.mag, shiftBits)
			return BigInteger.Helpers.fromTrustedMagnitude(res, signum)
		}
		mag := this.mag.Clone()
		if (overflow := divisor >= 2**31) { ; overflow
			baseDivPrecompute := BigInteger.INT32 // divisor
			baseRemPrecompute := Mod(BigInteger.INT32, divisor)
		}
		divAsBigInt := BigInteger.validateBigInteger(divisor)
		remainder := BigInteger.ZERO
		Loop (pow) {
			if (overflow)
				arr := BigInteger.Helpers.magDivHelperOverflowDivide(mag, divisor, baseDivPrecompute, baseRemPrecompute)
			else
				arr := BigInteger.Helpers.magDivHelperDivide(mag, divisor)
			mag := arr[1]
			remainder := remainder.add(divAsBigInt.pow(pow - A_Index).multiply(arr[2]))
		}
		if remainder.signum != 0
			remainder.signum := this.signum
		return BigInteger.Helpers.fromTrustedMagnitude(mag, signum)
	}

	/**
	 * Modulo. Returns the remainder of (this) divided by anyInt. This is an alias for .divide(anyInt, &remainder) with its parameters swapped.
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @param {&BigInteger?} quotient This will be set to the result of the division, if given.
	 * @returns {BigInteger} The result of the modulo operation.
	 */
	mod(anyInt, &quotient?) {
		quotient := this.divide(anyInt, &rem)
		return rem
	}

	/**
	 * Modulo. Returns the remainder of anyIntNum divided by anyIntDiv. This is an alias for .divide(anyInt, &remainder) with its parameters swapped.
	 * @param {Integer | String | BigInteger} anyIntNum An Integer, a string representing an integer or a BigInteger
	 * @param {Integer | String | BigInteger} anyIntDiv An Integer, a string representing an integer or a BigInteger
	 * @param {&BigInteger?} quotient This will be set to the result of the division, if given.
	 * @returns {BigInteger} The result of the modulo operation.
	 */
	static Mod(anyIntNum, anyIntDiv) => BigInteger.validateBigInteger(anyIntNum).mod(anyIntDiv)
	
	/**
	 * Calculates the greatest common divisor amongst the given Integer-likes and (this), using binary GCD on the two smallest values, dividing the others by that gcd and running modified binary GCD on those again.
	 * This will always be positive.
	 * @param {Integer | String | BigInteger} anyIntValues Any number of Integers, strings representing an integer or BigIntegers
	 * @returns {BigInteger} A new BigInteger representing the greatest common divisor of (this) and anyInt
	 * @example
	 * BigInteger(3033956).gcd('824387595128', '-178468', BigInteger(892340)).toString() => 178468
	 * BigInteger.gcd('1', 0, '38422342893482938482384234').toString() => 1
	 */
	gcd(anyIntValues*) {
		; ensure there are at least two values
		if anyIntValues.Length == 0
			return this.abs()
		; validate & ensure all values are > 0 while retrieving the two smallest values
		tNums := []
		curMin := this.abs()
		curMin2 := anyIntValues[1] := BigInteger.validateBigInteger(anyIntValues[1]).abs()
		for i, e in anyIntValues {
			bigInt := BigInteger.validateBigInteger(e).abs()
			if i == 1 || bigInt.signum == 0
				continue
			if (curMin.compareTo(bigInt) == 1) {
				tNums.push(curMin2)
				curMin2 := curMin
				curMin := bigInt
			} else if (curMin2.compareTo(bigInt) == 1) {
				tNums.push(curMin2)
				curMin2 := bigInt
			} else {
				tNums.push(bigInt)
			}
		}
		; calculate the gcd of these two values
		curGcd := gcdTwoVar(curMin, curMin2)
		if curGcd.equals(BigInteger.ONE)
			return curGcd
		; drastically reduce size of tNums values
		copyNums := [curGcd]
		for e in tNums {
			m := e.mod(curGcd)
			if m.signum != 0
				copyNums.push(m)
		}
		copyNums := tNums
		copyNums.push(curGcd)
		; calculate gcd of nums using gcdBinary again
		gcdTwoPowFactors := []
		for i, e in copyNums {
			copyNums[i] := e.shiftRight(j := e.getLowestSetBit() - 1)
			gcdTwoPowFactors.push(j)
		}
		k := Min(gcdTwoPowFactors*)
		while (copyNums.Length > 1) {
			curMin := BigInteger.Min(copyNums*)
			tNums := []
			for i, e in copyNums {
				if (e != curMin) { ; see gcdTwoVar for an explanation
					e := e.subtract(curMin)
					if e.signum == 0
						continue
					e := e.shiftRight(e.getLowestSetBit() - 1)
				}
				tNums.push(e)
			}
			copyNums := tNums
		}
		return copyNums[1].shiftLeft(k)
		
		gcdTwoVar(n, m) {
			n := n.shiftRight(i := n.getLowestSetBit() - 1)
			m := m.shiftRight(j := m.getLowestSetBit() - 1)
			k := Min(i, j)
			while(true) { ; this guarantees at least 1-digit reduction per iteration at O(n) per iteration
				if (n.compareTo(m) == -1) { ; m > n -> swap
					temp := n
					n := m
					m := temp
				}
				; both are odd -> gcd(u, v) = gcd(u, u-v)
				n := n.subtract(m)
				if n.signum == 0 {
					return m.shiftLeft(k)
				}
				; gcd(2^k u, v) = gcd(u, v) if v odd, which is ensured through pre-loop prep and subtract
				n := n.shiftRight(n.getLowestSetBit() - 1)
			}
		}
	}
	
	/**
	 * Calculates the greatest common divisor amongst the given Integer-likes, using Euclids algorithm. This will always be positive.
	 * @param {Integer | String | BigInteger} anyInt An Integer, string representing an integer or BigInteger
	 * @param {Integer | String | BigInteger} anyInts Any number of Integers, strings representing an integer or BigIntegers
	 * @returns {BigInteger} A new BigInteger representing the greatest common divisor of the given values
	 * @example
	 * BigInteger.gcd(3033956, '824387595128', '-178468', BigInteger(892340)).toString() => 178468
	 */
	static gcd(anyInt, anyIntValues*) => BigInteger.validateBigInteger(anyInt).gcd(anyIntValues*)

	/**
	 * Calculates the integer square root of (this), ie. the largest integer i such that i*i <= (this)
	 * @param {&BigInteger?} remainder The remainder of the operation, ie. i*i+remainder == (this)
	 * @returns {BigInteger} The integer square root of (this).
	 * @example
	 * BigInteger(10000000).sqrt(&remainder).toString() => 3162
	 * remainder.toString() => 1756
	 */
	sqrt(&remainder?) {
		if !this.signum
			return BigInteger.ZERO
		if this.signum == -1
			throw BigInteger.Error.ILLEGAL_NEGATIVE['sqrt', this]
		wantRemainder := !IsSet(remainder)
		shift := Max(this.getBitLength() - 63, 0)
		if shift & 0x1 ; equivalent to Ceil(shift/2) * 2, force it to be even.
			shift++
		guess := Float(this.shiftRight(Max(0,shift)).intValue())
		; this is ~2**(log2(n)//2 + 1)
		; if x = a^b, then sqrt(x) = a^(b/2). Halve shift and get approximate root of rest is better though, then shift back.
		guess := BigInteger.valueOf(Ceil(sqrt(guess))).shiftLeft(Max(0,shift//2))
		xk := guess
		while (true) {
			xk1 := this.divide(xk).add(xk).shiftRight(1) ; equivalent to (xk + this // xk) // 2
			if (xk1.compareTo(xk) >= 0) {
				remainder := this.subtract(xk.pow(2))
				return xk
			}
			xk := xk1
		}
	}

	/**
	 * Calculates the largest integer i such that i^n <= (this).
	 * @param {Integer} n Positive. Which root to calculate. 2 is equivalent to calling sqrt() (but slower).
	 * @param {&BigInteger?} remainder The remainder of the operation, ie. a number st i^n + remainder == (this)
	 * @returns {BigInteger} The nth integer root of (this)
	 * @example
	 * BigInteger.fromMagnitude([1,0]).nthRoot(10,&rem).toString() => 9 ; 9**10 = 3486784401
	 * rem.toString() => 808182895 ; 9**10 + 808182895 = 2**32
	 */
	nthRoot(n, &remainder?) {
		if (!this.signum) {
			remainder := BigInteger.ZERO
			return BigInteger.ZERO
		}
		if (this.signum == -1)
			throw BigInteger.Error.ILLEGAL_NEGATIVE['nthroot', this]
		if (n is BigInteger) {
			if (n.signum <= 0)
				throw BigInteger.Error.ILLEGAL_NEGATIVE['nthroot', n]
			if (n.mag.length > 1) {
				remainder := this.Clone()
				return BigInteger.ONE
			}
			n := n.mag[1]
		}
		if n <= 0
			throw BigInteger.Error.ILLEGAL_NEGATIVE['nthroot', n]
		if (n == 1) {
			remainder := BigInteger.ZERO
			return this.Clone()
		}
		; guess
		shift := Max(this.getBitLength() - 63, 0)
		shift := Ceil(shift / n) * n
		guessFloat := Max(1, Float(this.shiftRight(shift).intValue())) ; guess should be at least 1
		guess := BigInteger.valueOf(Ceil(guessFloat**(1.0 / n))).shiftLeft(shift // n)
		xk := guess
		while (true) {
			; xk1 := xk - (xk^n - this)/(n*xk^(n-1)) = ( (n-1)*x + a/(x^(n-1)))/n
			xk1 := this.divide(xk.pow(n - 1)).add(xk.multiply(n - 1)).add(n - 1).divideByIntPower(n)
			if (BigInteger.Helpers.compareMagnitudes(xk1.mag, xk.mag) == 0) {
				while (xk.pow(n).compareTo(this) > 0)
					xk := xk.subtract(BigInteger.ONE)
				remainder := this.subtract(xk.pow(n))
				return xk
			}
			xk := xk1
		}
	}

	/**
	 * Returns 1 if (this) is larger than anyInt, -1 if it is smaller.
	 * Logically equivalent to the comparison (this > anyInt) ? 1 : this == anyInt ? 0 : -1
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {Integer} 1, 0, -1.
	 * @example
	 * BigInteger.TWO.compareTo(10) => -1
	 * BigInteger.TWO.compareTo(2) => 0
	 * BigInteger.TWO.compareTo(-1) => 1
	 */
	compareTo(anyInt) {
		anyInt := BigInteger.validateBigInteger(anyInt)
		if this.signum > anyInt.signum
			return 1
		else if this.signum < anyInt.signum
			return -1
		magComp := BigInteger.Helpers.compareMagnitudes(this.mag, anyInt.mag)
		return this.signum == 1 ? magComp : -magComp
	}

	/**
	 * Returns true if (this) and anyInt represent the same number, 0 otherwise.
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {Boolean} true if (this) == anyInt. false otherwise
	 */
	equals(anyInt) {
		anyInt := BigInteger.validateBigInteger(anyInt)
		flag := (this.signum == anyInt.signum && this.mag.Length == anyInt.mag.Length)
		if !flag
			return false
		for i, e in this.mag
			if anyInt.mag[i] != e
				return false
		return true
	}

	/**
	 * Gets the lowest value from (this) and given values.
	 * @param {Integer | String | BigInteger} anyInt Any number of Integers, strings representing an integer or BigIntegers
	 * @returns {BigInteger} A BigInteger representing the smallest integer between this and values and anyInt. If this already was a BigInteger, it is returned (not cloned)
	 * @example
	 * BigInteger(5).min(-1, 3, 2934) => -1
	 * a := BigInteger(3)
	 * b := a.min(5,6,7) ; returns a without cloning it
	 * b := 5
	 * a => 5
	 */
	min(anyInt*) {
		curMin := this
		for bigInt in anyInt
			curMin := curMin.compareTo(bigInt) == 1 ? bigInt : curMin
		return curMin
	}

	/**
	 * Gets the smallest value from the given values.
	 * @param {Integer | String | BigInteger} anyInt An Integer, string representing an integer or BigInteger
	 * @param {Integer | String | BigInteger*} anyIntValues Any number of Integers, strings representing an integer or BigIntegers
	 * @returns {BigInteger} A BigInteger representing the smallest integer between the given values. If this already was a BigInteger, it is returned (not cloned)
	 * @example
	 * ; See the non-static method for an example
	 */
	static Min(anyInt, anyintValues*) => BigInteger.validateBigInteger(anyInt).Min(anyintValues*)
	
	/**
	 * Gets the highest value from (this) and given values.
	 * @param {Integer | String | BigInteger} anyInt Any number of Integers, strings representing an integer or BigIntegers
	 * @returns {BigInteger} A BigInteger representing the largest integer between this and values and anyInt. If this already was a BigInteger, it is returned (not cloned)
	 * @returns {BigInteger}
	 * @example
	 * BigInteger(5).max(-1, 3, 2934) => 2934
	 * a := BigInteger(13)
	 * b := a.max(5,6,7) ; returns a without cloning it
	 * b := 5
	 * a => 5
	 */
	max(anyInt*) {
		curMax := this
		for bigInt in anyInt
			curMax := curMax.compareTo(bigInt) == -1 ? bigInt : curMax
		return curMax
	}

	/**
	 * Gets the highest value from the given values.
	 * @param {Integer | String | BigInteger} anyInt An Integer, string representing an integer or BigInteger
	 * @param {Integer | String | BigInteger*} anyIntValues Any number of Integers, strings representing an integer or BigIntegers
	 * @returns {BigInteger} A BigInteger representing the largest integer between the given values. If this already was a BigInteger, it is returned (not cloned)
	 * @example
	 * ; See the non-static method for an example
	 */
	static Max(anyInt, anyintValues*) => BigInteger.validateBigInteger(anyInt).Max(anyintValues*)

	/**
	 * Given any number of BigIntegers, sorts them numerically ascending using a custom mergesort.
	 * @param {Integer | String | BigInteger} anyInt An Integer, string representing an integer or BigInteger
	 * @param {Integer | String | BigInteger} anyIntValues* Any number of Integers, strings representing an integer or BigIntegers
	 * @returns {Array} A numerically ascending sorted array containing BigIntegers. Note that these BigIntegers are not clones, but the same as the original BigIntegers referenced in the parameters.
	 * @example
	 * BigInteger.Sort(-1, '-329428934829349', 5, 3242) => [BigInteger('-329428934829349'), BigInteger(-1), BigInteger(5), BigInteger(3242)]
	 */
	static Sort(anyInt, anyIntValues*) {
		nums := [BigInteger.validateBigInteger(anyInt)]
		for i, e in anyIntValues
			nums.push(BigInteger.validateBigInteger(e)) ; while compareTo validates too, it is called O(nlogn) times, so this is better
		len := anyIntValues.length + 1
		res := []
		res.Length := len
		sliceLen := 1
		while (sliceLen <= len) { ; O(log2(len))
			c := 1
			while (c <= len) { ; O(len)
				i := c
				j := indexB := min(c + sliceLen, len)
				lastIndex := min(c + 2 * sliceLen - 1, len)
				Loop (lastIndex - c + 1) {
					k := c + A_Index - 1
					if (i < indexB && (j > lastIndex || (nums[i].compareTo(nums[j]) == -1)))
						res[k] := nums[i++]
					else
						res[k] := nums[j++]
				}
				c += 2 * sliceLen
			}
			sliceLen *= 2
			nums := res.clone()
		}
		return res
	}

	/**
	 * Returns a BigInteger whose values is (this) & anyInt bitwise. Treats both this and anyInt as if they were stored in twos complement.
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {BigInteger} the ANDed BigInteger
	 */
	and(anyInt) {
		anyInt := BigInteger.validateBigInteger(anyInt)
		thisTwos := this.toTwosComplement()
		anyIntTwos := anyInt.toTwosComplement()
		len1 := thisTwos.Length
		len2 := anyIntTwos.Length
		andMag := []
		; let S,T be the signWord
		;   [  S,   a,   b,   c,   d,   e]
		; & [            T,   x,   y,   z]
		; = [S&T, a&T, b&T, c&x, d&y, e&z]
		if (len1 > len2) {
			andMag.Length := len1
			smallLeadWord := anyIntTwos[1]
			Loop (len1 - len2)
				andMag[A_Index] := smallLeadWord & thisTwos[A_Index]
		} else {
			andMag.Length := len2
			smallLeadWord := thisTwos[1]
			Loop (len2 - len1 + 1)
				andMag[A_Index] := smallLeadWord & anyIntTwos[A_Index]
		}
		Loop (Min(len1, len2))
			andMag[-A_Index] := thisTwos[-A_Index] & anyIntTwos[-A_Index]
		return BigInteger.fromTwosComplement(andMag)
	}

	/**
	 * Returns a BigInteger whose value is equivalent to ~this as if it was stored in twos complement.
	 * @returns {BigInteger}
	 */
	not() => this.negate().subtract(1)

	/**
	 * Returns a BigInteger whose values is (this) & ~anyInt bitwise. Treats both this and anyInt as if they were stored in twos complement.
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {BigInteger} A BigInteger representing (this) & ~anyInt
	 */
	andNot(anyInt) => this.and(BigInteger.validateBigInteger(anyInt).not())

	/**
	 * Returns a BigInteger whose values is (this) | anyInt bitwise. Treats both this and anyInt as if they were stored in twos complement.
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {BigInteger} the ORed BigInteger
	 */
	or(anyInt) {
		anyInt := BigInteger.validateBigInteger(anyInt)
		thisTwos := this.toTwosComplement()
		anyIntTwos := anyInt.toTwosComplement()
		len1 := thisTwos.Length
		len2 := anyIntTwos.Length
		andMag := []
		; See .and() for an explanation
		if (len1 > len2) {
			andMag.Length := len1
			smallLeadWord := anyIntTwos[1]
			Loop (len1 - len2)
				andMag[A_Index] := smallLeadWord | thisTwos[A_Index]
		} else {
			andMag.Length := len2
			smallLeadWord := thisTwos[1]
			Loop (len2 - len1 + 1)
				andMag[A_Index] := smallLeadWord | anyIntTwos[A_Index]
		}
		Loop (Min(len1, len2))
			andMag[-A_Index] := thisTwos[-A_Index] | anyIntTwos[-A_Index]
		return BigInteger.fromTwosComplement(andMag)
	}

	/**
	 * Returns a BigInteger whose values is (this) & anyInt bitwise. Treats both this and anyInt as if they were stored in twos complement.
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {BigInteger} the ANDed BigInteger
	 */
	xor(anyInt) {
		anyInt := BigInteger.validateBigInteger(anyInt)
		thisTwos := this.toTwosComplement()
		anyIntTwos := anyInt.toTwosComplement()
		len1 := thisTwos.Length
		len2 := anyIntTwos.Length
		andMag := []
		; See .and() for an explanation
		if (len1 > len2) {
			andMag.Length := len1
			smallLeadWord := anyIntTwos[1]
			Loop (len1 - len2)
				andMag[A_Index] := smallLeadWord ^ thisTwos[A_Index]
		} else {
			andMag.Length := len2
			smallLeadWord := thisTwos[1]
			Loop (len2 - len1 + 1)
				andMag[A_Index] := smallLeadWord ^ anyIntTwos[A_Index]
		}
		Loop (Min(len1, len2))
			andMag[-A_Index] := thisTwos[-A_Index] ^ anyIntTwos[-A_Index]
		return BigInteger.fromTwosComplement(andMag)
	}

	/**
	 * Performs a bitwise left shift operation on (this) by n bits, equivalent to (this) << n
	 * This operation is equivalent to multiplying by 2**n.
	 * @param {Integer} n The number of bits to shift left. If negative, will shift Right instead.
	 * @returns {BigInteger} A new BigInteger representing the result of the left shift
	 * @example
	 * BigInteger(8).shiftLeft(3).toString() => 64
	 * BigInteger(-1).shiftLeft(3).toString() => -8
	 */
	shiftLeft(n) {
		if n is BigInteger {
			if n.signum == -1
				throw BigInteger.Error.ILLEGAL_NEGATIVE['shiftRight', n]
			if n.mag.Length > 1
				throw BigInteger.Error.GIGABYTE_OPERATION['shiftLeft', n]
			n := n.mag[1]
		}
		if n == 0
			return this.Clone()
		if n < 0
			throw BigInteger.Error.ILLEGAL_NEGATIVE['shiftLeft', n]
		return BigInteger.Helpers.fromTrustedMagnitude(BigInteger.Helpers.shiftMagnitudeLeft(this.mag, n), this.signum)
	}

	/**
	 * Performs a bitwise right shift operation on (this) by n bits. 
	 * Equivalent to this >> n.
	 * This operation is equivalent to dividing by 2**n only if (this) is positive (as -3 >> 2 = -2, 3 >> 2 = 1, -3 // 2 == -1)
	 * @param {Integer} n The number of bits to shift right. If negative, will shift right instead.
	 * @returns {BigInteger} A new BigInteger representing the result of the right shift
	 * @example
	 * BigInteger(8).shiftRight(3).toString() => 1
	 * BigInteger(8).shiftRight(20).toString() => 0
	 * BigInteger(-8).shiftRight(1).toString() => -4
	 * BigInteger(-1).shiftRight(3).toString() => 0
	 * BigInteger(3).shiftRight(1).toString() => 1
	 * BigInteger(3).shiftRight(1).shiftLeft(1).toString() => 2
	 * BigInteger(-3).shiftRight(1).toString() => -2
	 * BigInteger(-3).shiftRight(1).shiftLeft(1) => -4
	 */
	shiftRight(n) {
		if n is BigInteger {
			if n.signum == -1
				throw BigInteger.Error.ILLEGAL_NEGATIVE['shiftRight', n]
			n := n.mag.Length > 1 ? BigInteger.INT32 : n.mag[1]
		}
		if n < 0
			throw BigInteger.Error.ILLEGAL_NEGATIVE['shiftRight', n]
		len := this.mag.Length
		hasLeftover := this.getLowestSetBit() <= n
		mag := BigInteger.Helpers.shiftMagnitudeRight(this.mag, n)
		if mag[1] == 0
			return this.signum >= 0 ? BigInteger.ZERO : BigInteger.MINUS_ONE
		if (this.signum == -1 && hasLeftover) ; 3 >> 1 = 0b11 >> 1 = 0b1 = 1, while -3 >> 1 = 0b111...1101 >> 1 = 0b11..110 = -2
			mag := BigInteger.Helpers.addMagnitudes(mag, [1])
		return BigInteger.Helpers.fromTrustedMagnitude(mag, this.signum)
	}

	/**
	 * Gets the last n bits. Equivalent to (this) & ((1 << n) - 1) ignoring signum.
	 * 
	 * As there is no fixed sign bit, masking will always cause the leading bits to be 0 and the number thus positive.
	 * 
	 * Thus while -342 & ((1 << 64) - 1) = -342 & 0xFFFFFFFFFFFFFFFF == -342 natively, here the leading bit is not interpreted as a sign, but literally.
	 * 
	 * Thus BigInteger(-342).maskBits(64).toString() = 18446744073709551274. This is useful since this is 0b1111111111111111111111111111111111111111111111111111111010101010 which ahk interprets as -342 again.
	 * @param {Integer} n The number of bits to mask
	 * @returns {BigInteger} A BigInteger which represents the n bits.
	 * @example
	 * BigInteger(2**32-1).maskBits(10).toString() => 1023
	 */
	maskBits(n) {
		if n is BigInteger
			n := n.mag.Length > 1 ? BigInteger.INT32 : n.mag[1]
		words := n >>> 5
		bitMask := (1 << (n & 0x1F)) - 1 ; mask bottom 31 bits of n to get mask for 31 bits (32 is a full word)
		if n == 0 || this.signum == 0
			return BigInteger.ZERO
		len := this.mag.Length
		if this.signum == 1 {
			if words >= len
				return this.Clone()
			mag := []
			if bitMask
				mag.push(this.mag[len - words] & bitMask)
			Loop (words)
				mag.push(this.mag[len - words + A_Index])
			return BigInteger.Helpers.fromTrustedMagnitude(mag, this.signum)
		} else {
			mag := []
			compl := this.toTwosComplement()
			compl.RemoveAt(1)
			if bitMask
				mag.push((words >= len ? BigInteger.INT_MASK : compl[len-words]) & bitMask)
			Loop(words - len)
				mag.push(BigInteger.INT_MASK)
			if words >= len
				mag.push(compl*)
			else Loop(words)
				mag.push(compl[len - words + A_Index])
			return BigInteger.Helpers.fromTrustedMagnitude(mag, 1)
		}
	}

	/**
	 * Gets (this) as a short by truncating it, as if it were represented in twos complement.
	 * Because of twos complement, this is not equivalent to maskBits(16)
	 * @returns {Integer} The short, ranging from 0 to 0xFFFF, where values above 0x7FFF are considered negative.
	 */
	shortValue() => this.toTwosComplement()[-1] & BigInteger.SHORT_MASK

	/**
	 * Gets (this) as an int by truncating it, as if it were represented in twos complement.
	 * Because of twos complement, this is not equivalent to maskBits(32)
	 * @returns {Integer} The int, ranging from 0 to 0xFFFFFFFF, where values above 0x7FFFFFFF are considered negative
	 */
	int32Value() => this.toTwosComplement()[-1]

	/**
	 * Gets (this) as a 64-bit int (long) by truncating it, as if it were represented in twos complement.
	 * Because of twos complement, this is not equivalent to maskBits(64)
	 * @returns {Integer} The long, ranging from 0 to 0xFFFFFFFFFFFFFFFF, where values above 0x7FFFFFFFFFFFFFFF are considered negative
	 */
	intValue() => ((t := this.toTwosComplement()).Length > 1 ? t[-2] << 32 : 0) | t[-1]

	/**
	 * Returns the number of bits in the representation of this BigInteger, excluding the sign Bit.
	 * For Zero, this returns 0.
	 * @returns {Integer} Number of bits in this BigInteger
	 * @example
	 * BigInteger(0).getBitLength() => 0
	 * BigInteger(-1).getBitLength() => 1
	 * BigInteger(1).getBitLength() => 1
	 */
	getBitLength() {
		bits := this.bitLength
		if (bits == -1) {
			bits := ((this.mag.Length - 1) << 5) + (64 - BigInteger.Helpers.numberOfLeadingZeros(this.mag[1]))
			this.bitLength := bits
		}
		return bits
	}

	/**
	 * Returns the index of the first one-bit in this BigInteger in little-endian. Sign does not matter for this (as this value is the same regardless of sign in twos complement).
	 * @returns {Integer} The index of the rightmost one-bit.
	 * @example
	 * BigInteger(2**32).getLowestSetBit() => 33
	 * BigInteger(-2**31).getLowestSetBit() = 32
	 * BigInteger(0x1000).getLowestSetBit() => 13
	 * BigInteger(-2).getLowestSetBit() => 2
	 * BigInteger(0xFFFF).getLowestSetBit() => 1
	 * BigInteger(0).getLowestSetBit() => 0
	 */
	getLowestSetBit() {
		lsb := this.lowestSetBit
		if lsb == -1 { ; uninitialized
			if !this.signum {
				lsb := 0
			} else {
				i := len := this.mag.Length
				while (this.mag[i] == 0)
					i--
				lsb := ((len - i) << 5) + BigInteger.Helpers.numberOfTrailingZeros(this.mag[i]) + 1
			}
			this.lowestSetBit := lsb
		}
		return lsb
	}

	/**
	 * Returns the canonical twos complement version of this. For positive values, this will be identical to mag. For negative values, it will not.
	 * @returns {Array} Magnitude in twos-complement variant of the big Integer. Will always have a leading word which is either 0 or 0xFFFFFFFF, unless the biginteger is 0.
	 * @example
	 * BigInteger(27).toTwosComplement() => [0,27]
	 * BigInteger(-27).toTwosComplement() => [4294967295,4294967269]
	 * BigInteger(-2**32).toTwosComplement() => [4294967295,4294967295,0]
	 * BigInteger(-2**32+1).toTwosComplement() => [4294967295,1]
	 */
	toTwosComplement() {
		if this.signum == 0
			return [0]
		if this.signum == 1 {
			mag := this.mag.Clone()
			mag.InsertAt(1, 0)
			return mag
		}
		mag := []
		mag.Length := this.mag.Length
		unchangedWords := (this.getLowestSetBit() - 1) >>> 5
		Loop (unchangedWords) ; copy rightmost words that are 0
			mag[-A_index] := 0
		mag[-unchangedWords - 1] := (~this.mag[-unchangedWords - 1] + 1) & BigInteger.INT_MASK
		Loop (mag.Length - unchangedWords - 1) ; this is suddenly left-to-right but it doesn't matter, this is symmetric
			mag[A_Index] := ~this.mag[A_Index] & BigInteger.INT_MASK
		mag.InsertAt(1, BigInteger.INT_MASK)
		return mag
	}

	/**
	 * Returns the signum of the number.
	 * @returns {BigInteger} Will be -1, 0, 1, corresponding to this < 0, this = 0, this > 0
	 */
	getSignum() => this.signum

	/**
	 * Returns a clone of the magnitude of the number.
	 * @returns {Array} Array of Integers that are base-2^32 digits representing the number
	 */
	getMagnitude() => this.mag.Clone()

	/**
	 * Returns a full copy of (this) without references to (this)
	 * @returns {BigInteger} The copy of (this)
	 */
	Clone() {
		copy := BigInteger.fromMagnitude(this.mag, this.signum)
		if this.bitLength != -1
			copy.bitLength := this.bitLength
		if this.lowestSetBit != -1
			copy.lowestSetBit := this.lowestSetBit
		return copy
	}


	/**
	 * Various helper functions. All functions in this trust that 
	 * a) magnitudes are in base 2**32 and contain no digits that are >=2**32 or unset
	 * b) have no leading zero unless they are 0 themselves
	 * c) have a length of at least 1
	 */
	class Helpers {

		/**
		 * Constructs a BigInteger given its base 2^32 digit representation and signum.
		 * This trusts that the magnitude will not be altered and does not copy it accordingly.
		 * This does not do any validation checks except for setting the signum if the magnitude is 0.
		 * @param {Array} mag an array of integers < 2^32 in bigEndian notation
		 * @param {Integer} signum The signum of the number. 1 for positive, -1 for negative, 0 for 0. If magnitude is an array containing only 0, signum will be automatically set to 0.
		 * @returns {BigInteger} The Constructed Value
		 * @example
		 * BigInteger.fromTrustedMagnitude([1,2], -1) => - (1 * 2**32 + 2) = -4294967298
		 * BigInteger.fromTrustedMagnitude([0], -1) => 0 ; signum gets ignored
		 */
		static fromTrustedMagnitude(mag, signum := 1) {
			static template := BigInteger(0) ; this does not have any properties set to values besides mag and signum.
			obj := (Object.Clone)(template)
			obj.signum := (mag.Length = 1 && mag[1] = 0) ? 0 : signum
			obj.mag := mag
			return obj
		}

		/**
		 * Given a string of arbitrary length in base 10, returns an array of its digits in base 2**32
		 * @param {String} str A positive Integer String of arbitrary length. Must not contain -/+ at the beginning.
		 * @param {Integer} radix 2<=radix<=36
		 * @returns {Array} The strings base-n digit representation as an Array
		 */
		static magnitudeFromString(str, radix := 10) {
			; parse string into base-10**9 magnitude
			magBaseB := []
			len := StrLen(str)
			chunkLen := this.getMaxComputableRadixPower(radix)
			if (radix == 10) { ; parse string in chunks and interpret as base 10^9
				if (offset := Mod(len, chunkLen))
					magBaseB.push(Integer(SubStr(str, 1, offset)))
				chunkIndex := offset + 1
				Loop (len // chunkLen) { ; interpret as base 10**9
					magBaseB.push(Integer(SubStr(str, chunkIndex, chunkLen)))
					chunkIndex += chunkLen
				}
				return this.normalizeMagnitudeBase(magBaseB, radix**chunkLen)
			} else if (radix == 16) { ; parse in chunks and directly cast to base 2^32
				if (offset := Mod(len, chunkLen))
					magBaseB.push(Integer('0x' SubStr(str, 1, offset)))
				chunkIndex := offset + 1
				Loop (len // chunkLen) {
					magBaseB.push(Integer('0x' SubStr(str, chunkIndex, chunkLen)))
					chunkIndex += chunkLen
				}
				return magBaseB
			} else {
				mag := this.validateMagnitudeRadix(StrSplit(str), radix)
				maxRadixMag := this.shrinkMagnitudeToPowRadix(mag, radix, chunkLen)
				return this.normalizeMagnitudeBase(maxRadixMag, radix**chunkLen)
			}
		}

		/**
		 * Transforms alphanumeric digits into numerical ones and checks if all digits are within the range of the specified radix
		 * @param {Array} mag The magnitude to check 
		 * @param {Integer} radix The suspected base
		 * @returns {Array} The validated magnitude
		 */
		static validateMagnitudeRadix(mag, radix) {
			if radix > BigInteger.INT32
				throw BigInteger.Error.INVALID_RADIX[radix '(Must be < 2^32)']
			possibleAlphaDigit := radix > 10 && radix <= 36
			newMag := []
			for i, e in mag {
				if !isAlpha(String(e))
					n := e
				else {
					if !possibleAlphaDigit
						throw BigInteger.Error.INVALID_RADIX[radix '( Found alphanumerical digit ' e ')']
					n := Ord(e) - 55
				}
				if n >= radix
					throw BigInteger.Error.INVALID_RADIX[radix . ' (Found ' n ' in magnitude)']
				newMag.push(Integer(n))
			}
			return newMag
		}

		/**
		 * Shrinks a given magnitude efficiently by converting its base from baseRadix to radix^exponent.
		 * @param {Array} mag an array of integers < 2^32 in bigEndian notation
		 * @param {Integer} baseRadix The radix the magnitude is currently in
		 * @param {Integer} exponent The exponent defining radix^exponent as the new radix
		 * @returns {Array} The new magnitude in base baseRadix^exponent
		 */
		static shrinkMagnitudeToPowRadix(mag, baseRadix, exponent) {
			if exponent * Log(baseRadix) / Log(2) > 32
				throw BigInteger.Error.INVALID_RADIX[baseRadix**exponent]
			if exponent == 1
				return mag.Clone()
			n := mag.Length
			newMag := []
			m := Mod(n - 1, exponent)
			v := 0
			for i, e in mag {
				v += e * baseRadix**m
				m--
				if Mod(n - i, exponent) == 0 {
					m := exponent - 1
					newMag.push(v)
					v := 0
				}
			}
			return newMag
		}

		/**
		 * Given a magnitude in base <powRadix>, where powRadix is a power of baseRadix, ie. baseRadix^n == powRadix, converts digits to the new radix
		 * @param {Array} mag an array of integers < 2^32 in bigEndian notation
		 * @param {Integer} powRadix The radix the magnitude is currently in
		 * @param {Integer} baseRadix The radix the magnitude is currently in
		 * @returns {Array} The new magnitude
		 */
		static expandMagnitudeToRadix(mag, powRadix, baseRadix) {
			ex := this.isPowerOf(baseRadix, powRadix)
			if !ex
				throw BigInteger.Error.INCOMPATIBLE_RADIX[powRadix, baseRadix]
			if ex == 1
				return mag.clone()
			isPowerOfTwo := (baseRadix & (baseRadix - 1) == 0)
			mask := baseRadix - 1
			z := this.numberOfTrailingZeros(baseRadix)
			newMag := []
			for i, digit in mag {
				miniMag := []
				Loop (ex) { ; remainder and thus overflow is irrelevant here
					miniMag.InsertAt(1, isPowerOfTwo ? digit & mask : Mod(digit, baseRadix))
					digit := isPowerOfTwo ? digit >> z : digit // baseRadix
				}
				if (i == 1)
					this.stripLeadingZeros(miniMag)
				newMag.push(miniMag*)
			}
			return newMag
		}

		/**
		 * Calculates the largest integer n such that radix**n < 2**32
		 * @param radix Any value < 2**32 and
		 * @returns {Number} The calculated exponent
		 */
		static getMaxComputableRadixPower(radix) => Floor(log(1 << 32) / log(radix))

		/**
		 * Convert a magnitude in base to base 2^32 by repeated efficient single-integer division.
		 * @param {Array} mag The magnitude
		 * @param {Integer} base the radix of the magnitude
		 * @returns {Array} The normalized magnitude
		 */
		static normalizeMagnitudeBase(mag, base) {
			result := []
			if base == BigInteger.INT32
				return mag.clone()
			if base == 0
				throw ValueError("Base 0 does not exist.")
			overflow := base >= 2**31 ; overflow
			if overflow {
				while (mag[1] != 0)
					magDivHelperOverflowNormalize()
			} else {
				while (mag[1] != 0)
					magDivHelperNormalize()
			}
			return result

			magDivHelperNormalize() {
				quotient := []
				remainder := 0
				for digit in mag {
					dividend := remainder * base + digit
					q := dividend >> 32
					remainder := dividend & 0xFFFFFFFF
					quotient.push(q)
				}
				mag := this.stripLeadingZeros(quotient)
				result.InsertAt(1, remainder)
			}

			magDivHelperOverflowNormalize() {
				; precompute values are 0 or irrelevant here
				quotient := []
				remainder := 0
				for digit in mag {
					qtmp := base * remainder + digit
					quotDigit := (qtmp >>> 32) & BigInteger.INT_MASK
					remainder := qtmp & 0xFFFFFFFF
					quotient.push(quotDigit)
				}
				mag := this.stripLeadingZeros(quotient)
				result.InsertAt(1, remainder)
			}
		}

		/**
		 * Convert a magnitude in base 2^32 to base. Note that if base >= 2^31, this will cause overflows and not work.
		 * @param {Array} mag The specified magnitude
		 * @param {Integer} base The radix in which to convert mag into
		 * @returns {Array} The converted magnitude
		 */
		static convertMagnitudeBase(mag, base) {
			if base == BigInteger.INT32
				return mag.clone()
			if base == 0
				throw ValueError("You entered base 0, which doesn't exist. If you do think that it exists, please write me an email.")
			if (isPowerOfTwo := (base & (base - 1) == 0)) { ; base is 2^n
				if this.isPowerOf(base, BigInteger.INT32) ; 2**32 is (base^n), so digits can be read per word
					return this.expandMagnitudeToRadix(mag, BigInteger.INT32, base)
				mask := base - 1
				z := this.numberOfTrailingZeros(base)
			}
			result := []
			if (overflow := base >= 2**31) {
				baseDivPrecompute := BigInteger.INT32 // base
				baseRemPrecompute := Mod(BigInteger.INT32, base)
			}
			while (mag[1] != 0) {
				if isPowerOfTwo
					arr := this.magDivHelperShiftRight(mag, z)
				else if overflow
					arr := this.magDivHelperOverflowDivide(mag, base, baseDivPrecompute, baseRemPrecompute)
				else
					arr := this.magDivHelperDivide(mag, base)
				mag := arr[1]
				result.InsertAt(1, arr[2])
			}
			return result
		}

		/**
		 * Returns 1 if mag1 is larger than mag2, -1 if it is smaller, 0 otherwise.
		 * This is functionally equivalent to calling num1.Abs().compareTo(num2.Abs())
		 * @param {Array} mag1 The first Magnitude array
		 * @param {Array} mag2 The second Magnitude array
		 * @returns {Integer} 1, 0, -1.
		 */
		static compareMagnitudes(mag1, mag2) {
			if mag1.Length > mag2.Length
				return 1
			else if mag1.Length < mag2.Length
				return -1
			for i, thisDigit in mag1 {
				compDigit := mag2[i]
				if thisDigit > compDigit
					return 1
				else if thisDigit < compDigit
					return -1
			}
			return 0
		}

		/**
		 * Adds two magnitudes together and returns a new magnitude expressing their sum
		 * @param mag1
		 * @param mag2
		 * @returns {Array}
		 */
		static addMagnitudes(mag1, mag2) {
			if mag1[1] == 0
				return mag2.Clone()
			if mag2[1] == 0
				return mag1.Clone()
			magSum := []
			carry := 0
			l1 := mag1.Length
			l2 := mag2.Length
			l := Max(l1, l2)
			i := 0
			while (i++ < l) {
				a := i <= l1 ? mag1[-i] : 0
				b := i <= l2 ? mag2[-i] : 0
				s := a + b + carry
				if (s < BigInteger.INT32)
					carry := 0
				else {
					s -= BigInteger.INT32
					carry := 1
				}
				magSum.InsertAt(1, s)
			}
			if (carry)
				magSum.InsertAt(1, 1)
			return magSum
		}

		/**
		 * Subtracts mag2 (the smaller magnitude) from mag1 (the larger magnitude) and returns a new magnitude expressing the difference.
		 * mag1 MUST be larger than mag2 or this function will fail.
		 * @param mag1
		 * @param mag2
		 * @returns {Array}
		 */
		static subtractMagnitudes(mag1, mag2) {
			if mag2[1] == 0
				return mag1.Clone()
			magDiff := []
			carry := 0
			l1 := mag1.Length
			l2 := mag2.Length
			i := 0
			while (i++ < l1) {
				a := mag1[-i]
				b := i <= l2 ? mag2[-i] : 0
				diff := a - b - carry
				carry := 0
				if diff < 0 {
					diff += BigInteger.INT32
					carry := 1
				}
				magDiff.InsertAt(1, diff)
			}
			while magDiff.Length > 1 && magDiff[1] == 0 ; strip leading zeros
				magDiff.RemoveAt(1)
			return magDiff
		}

		/**
		 * Multiplies mag1 with mag2 and returns the product.
		 * @param mag1 
		 * @param mag2 
		 * @returns {BigInteger}
		 */
		static multiplyMagnitudes(mag1, mag2) {
			static KARATSUBA_MULTIPLY_TRESHOLD := 56 ; approx good
			len1 := mag1.Length
			len2 := mag2.Length
			if (len1 < KARATSUBA_MULTIPLY_TRESHOLD || len2 < KARATSUBA_MULTIPLY_TRESHOLD) {
				if (len1 == 1) {
					if mag1[1] == 1
						return mag2.Clone()
					return multiplyByInt(mag2, mag1[1])
				}
				if (len2 == 1) {
					if mag2[1] == 1
						return mag1.Clone()
					return multiplyByInt(mag1, mag2[1])
				}
				return simpleMult(mag1, mag2)
			} else {
				return karatsubaMult(mag1, mag2)
			}

			multiplyByInt(mag, int) {
				result := []
				result.Length := len := mag.Length
				result[-1] := 0
				carry := 0
				Loop (len) {
					s := mag[-A_Index] * int + carry
					result[-A_Index] := s & BigInteger.INT_MASK
					carry := (s >>> 32)
				}
				if carry
					result.InsertAt(1, carry)
				return this.stripLeadingZeros(result)
			}

			simpleMult(mag1, mag2) {
				result := []
				Loop len1 + len2 ; minimum is max(len1, len2), maximum is len1+len2 (eg 0xFF * 0xFF = 0xFE01)
					result.Push(0)
				Loop (len1) {
					i := A_Index
					carry := 0
					a := mag1[-i]
					Loop (len2) {
						j := A_Index
						b := mag2[-j]
						pos := i + j - 1
						s := result[-pos] + (a * b) + carry
						result[-pos] := s & BigInteger.INT_MASK
						carry := (s >>> 32) ; since s might be >2**63-1, when shifting right the high bit is still interpreted as negative value. thus, we cut it off
					}
					result[-(i + j)] += carry ; write carry to the position left to the last written value
				}
				return this.stripLeadingZeros(result)
			}

			karatsubaMult(mag1, mag2) {
				half := Max(len1, len2) // 2
				xl := getLower(mag1, half)
				xh := getUpper(mag1, half)
				yl := getLower(mag2, half)
				yh := getUpper(mag2, half)
				p1 := this.multiplyMagnitudes(xh, yh)
				p2 := this.multiplyMagnitudes(xl, yl)
				s1 := this.addMagnitudes(xh, xl)
				s2 := this.addMagnitudes(yh, yl)
				p3 := this.multiplyMagnitudes(s1, s2) ; (xh+xl) * (yh*yl)
				r1 := this.shiftMagnitudeLeft(p1, 32*half)
				s3 := this.subtractMagnitudes(this.subtractMagnitudes(p3, p1), p2) ; p3-p1-p2
				r2 := this.addMagnitudes(r1, s3)
				r3 := this.shiftMagnitudeLeft(r2, 32*half)
				r4 := this.addMagnitudes(r3, p2)
				return r4
				; p1 := xh.multiply(yh) 
				; p2 := xl.multiply(yl)
				; p3 := xh.add(xl).multiply(yh.add(yl))
				; return p1.shiftLeft(32*half).add(p3.subtract(p1).subtract(p2)).shiftLeft(32*half).add(p2)

				getUpper(mag, n) => n >= mag.length ? [0] : this.sliceMagnitude(mag, 1, mag.length-n)
				getLower(mag, n) => n >= mag.length ? mag : this.sliceMagnitude(mag, mag.length-n+1, n)
			}

		}

		/**
		 * Efficiently squares a magnitude
		 * @param mag 
		 * @returns {BigInteger} 
		 */
		static squareMagnitude(mag) {
			static HALF_CALC_THRESHOLD := 13
			static KARATSUBA_SQUARE_THRESHOLD := 120
			len := mag.length
			if len < HALF_CALC_THRESHOLD ; simpleSquare is better in theory, but in practice its implementation is slightly slower here
				return this.multiplyMagnitudes(mag, mag)
			if mag.Length < KARATSUBA_SQUARE_THRESHOLD
				return simpleSquare(mag)
			else
				return karatsubaSquare(mag)

			/**
			 *   					a	b	c	d	e
			 * *					a	b	c	d	e
			 * =======================================
			 *						ae	be	ce	de	ee
			* 					ad	bd	cd	dd	ed
			* 				ac	bc	cc	dc	ec
			* 			ab	bb	cb	db	eb
			* 		aa	ba	ca	da	ea
			* =======================================
			*										ee
			* 								dd
			* 						cc
			* 				bb
			* 		aa
			* +++++++++++++++++++++++++++++++++++++++
			*	2*					ae	be	ce	de
			* 	2*				ad	bd	cd
			* 	2*			ac	bc
			* 	2*		ab
			* 	2*
			* =======================================
			* 
			*/
			simpleSquare(mag) {
				half := len // 2
				diagonal := []
				aboveDiagonal := []
				Loop (2 * len) {
					diagonal.Push(0)
					aboveDiagonal.push(0)
				}
				Loop (len) {
					pos := i := A_Index
					u := mag[-i]
					s := u * u ; carry cannot reach two digits (and diagonal jumps two digits everytime)
					diagonal[-(2*i-1)] := s & BigInteger.INT_MASK
					diagonal[-(2*i)] := (s >>> 32) ; guaranteed empty
					carry := 0
					Loop (len - i) {
						j := A_Index + i
						v := mag[-j]
						pos := i + j - 1
						s := aboveDiagonal[-pos] + carry + u * v
						aboveDiagonal[-pos] := s & BigInteger.INT_MASK
						carry := (s >>> 32)
					}
					aboveDiagonal[-(pos+1)] += carry ; write carry to the position left to the last written value
				}
				aboveDiagonal := this.stripLeadingZeros(aboveDiagonal)
				diagonal := this.stripLeadingZeros(diagonal)
				aboveDiagonal := this.shiftMagnitudeLeft(aboveDiagonal, 1)
				return this.addMagnitudes(aboveDiagonal, diagonal)
			}

			karatsubaSquare(mag) {
				half := len // 2
				xl := getLower(half)
				xh := getUpper(half)
				xls := this.squareMagnitude(xl)
				xhs := this.squareMagnitude(xh)
				
				s1 := this.shiftMagnitudeLeft(xhs, half*32) ; xh^2 << 64 (we shift again at r2)
				t1 := this.squareMagnitude(this.addMagnitudes(xl, xh)) ; (xl+xh)^2
				t2 := this.addMagnitudes(xhs, xls) ; (xh^2 + xl^2)
				r1 := this.subtractMagnitudes(t1, t2) ; ((xl+xh)^2 - (xh^2 + xl^2)) (= 2 * xl * xh)
				r2 := this.shiftMagnitudeLeft(this.addMagnitudes(s1, r1), half*32) ; xh^2 << 64  +  (((xl+xh)^2 - (xh^2 + xl^2)) << 32)
        		; xh^2 << 64  +  (((xl+xh)^2 - (xh^2 + xl^2)) << 32) + xl^2
				return this.addMagnitudes(r2, xls)
				; return xhs.shiftLeft(half*32).add(xl.add(xh).pow(2).subtract(xhs.add(xls))).shiftLeft(half*32).add(xls)
				getUpper(n) => n >= len ? [0] : this.sliceMagnitude(mag, 1, len-n)
				getLower(n) => n >= len ? mag : this.sliceMagnitude(mag, len-n+1, n)
			}
		}

		/**
		 * Shifts a magnitude n bits left
		 * @param mag 
		 * @param {Integer} bits 
		 * @returns {BigInteger} 
		 */
		static shiftMagnitudeLeft(mag, bits) {
			shiftBits := bits & 0x1F
			shiftWords := bits >>> 5
			newMag := []
			len := mag.Length
			result := []
			if (shiftBits == 0) {
				result := mag.Clone()
				Loop (shiftWords)
					result.push(0)
			} else {
				p := 0
				mask := (1 << shiftBits) - 1
				result := []
				result.Length := i := len
				while (i >= 1) {
					result[i] := ((mag[i] << shiftBits & BigInteger.INT_MASK) | p)
					p := mag[i] >> (32 - shiftBits)
					i--
				}
				if (p > 0)
					result.InsertAt(1, p)
				Loop (shiftWords)
					result.push(0)
			}
			return result
		}

		/**
		 * Shifts magnitude n bits to the right. Always assumes it is positive.
		 * @param mag 
		 * @param bits 
		 * @returns {Object | BigInteger} 
		 */
		static shiftMagnitudeRight(mag, bits) {
			shiftBits := bits & 0x1F
			shiftWords := bits >>> 5
			if bits == 0
				return mag.Clone()
			len := mag.Length
			if shiftWords >= len
				return [0]
			result := []
			if (shiftBits == 0) {
				Loop (len - shiftWords)
					result.push(mag[A_Index])
			} else {
				if (shiftWords == 0)
					tMag := mag
				else {
					tMag := []
					Loop (len - shiftWords)
						tMag.push(mag[A_Index])
				}
				remainder := 0
				mask := (1 << shiftBits) - 1 ; mask to retrieve bottom <shiftBits> bits
				shiftBitsLeft := 32 - shiftBits
				for i, digit in tMag {
					result.push((digit >> shiftBits) | (remainder << shiftBitsLeft))
					remainder := digit & mask
				}
				this.stripLeadingZeros(result)
			}
			return result
		}

		/**
		 * Divides one magnitude by another magnitude using Knuth's Algorithm D (long division).
		 * Trusts that dividend > divisor.
		 * Trusts that divisor.Length > 1 (Use divideByInt otherwise)
		 * See https://skanthak.hier-im-netz.de/division.html for information
		 * @param {Array} mag1 Dividend magnitude
		 * @param {Array} mag2 Divisor magnitude
		 * @param {&BigInteger} remainder The remainder
		 * @returns {Array} Quotient magnitude and remainder magnitude
		 */
		static divideMagnitudes(dividend, divisor, &remainder?) {
			; assert div.intLen > 1
			; factor out power of two. a / divisor = a / (q * 2^n) =
			shift := this.numberOfLeadingZeros(divisor[1]) - 32
			; U, the dividend of m+n digits
			numLen := dividend.Length + 1
			; V, the divisor of n digits
			divLen := divisor.Length + 1
			; Q, the quotient of m+1 digits, and R, the remainder of n digits
			resLen := numLen - divLen + 1
			; normalize the divisor so that its >= 2**31 (>= Base / 2)
			num := this.shiftMagnitudeLeft(dividend, shift)
			div := this.shiftMagnitudeLeft(divisor, shift)
			if (div.Length == num.Length) { ; we assume mag2 > mag1, so if after normalization we get this, its one. This check isn't necessary, but helps
				remainder := this.subtractMagnitudes(dividend, divisor)
				return [1]
			}
			divHigh := div[1]
			divLow := div[2]
			mag := []
			baseDivPrec := BigInteger.INT32 // divHigh
			baseRemPrec := Mod(BigInteger.INT32, divHigh)
			cDivPrec := divLow > 0 ? BigInteger.INT32 // divLow : 0
			cRemPrec := divLow > 0 ? Mod(BigInteger.INT32, divLow) : 0
			; U is m+n digits stored in m+n+1 digit array. The shiftLeft may have caused this to already exist, otherwise fill it in.
			if num.Length < numLen ; shifting did not cause a spillover, so pad with 0
				num.InsertAt(1, 0)
			Loop (resLen) { ; big endian notation
				i := A_Index
				; these calculations overflow so apply precomputation trick twice
				; Set Q̂ to (U[i] × B + U[i+1]) ÷ V[1] => qhat := ( num[i] << 32 | uHigh ) // divHigh
				; Set R̂ to (U[i] × B + U[i+1]) % V[1] => rhat := Mod(num[i] << 32 | uHigh, divHigh)
				uHigh := num[i + 1]
				uLow := num[i + 2]
				qtmp := baseDivPrec * num[i]
				rtmp := baseRemPrec * num[i] + uHigh
				qhat := (qtmp + rtmp // divHigh) ; & BigInteger.INT_MASK
				rhat := Mod(rtmp, divHigh)
				; this overflows so instead of qhat * divlow, do (rhat * base + uLow) // divLow using precomputation trick
				; Test if Q̂ equals B or Q̂ × V[2] is greater than R̂ × B + U[i+2] => qhat * divLow > rhat * base + uLow
				while (qhat == BigInteger.INT32 || (divLow > 0 && (qhat > (cDivPrec * rhat + (cRemPrec * rhat + uLow) // divLow)))) {
					; If yes, then decrease Q̂ by 1, increase R̂ by V[1], and repeat this test while R is less than B.
					qhat--
					rhat += divHigh
					if (rhat >= BigInteger.INT32)
						break
				}
				; Replace (U[i]U[i+1]…U[i+n]) by (U[i]U[i+1]…U[i+n]) − Q̂ × (V[1]…V[n-1]V[n]).
				tDiv := this.sliceMagnitude(num, i, divLen)
				tProd := this.multiplyMagnitudes(div, [qhat])
				; Decrease Q[j] by 1 and add (0V[1]…V[n-1]V[n]) to (U[i]U[i+1]…U[i+n-1]U[i+n]).
				if (this.compareMagnitudes(tDiv, tProd) == -1) {
					tProd := this.subtractMagnitudes(tProd, div)
					qhat--
				}
				Loop(divLen - tProd.Length)
					tProd.InsertAt(1, 0)
				magSubSliceHelper(i) ; performs [3,1,2,9,....,5,6] - [1,1,0] = [2,0,2,9,....,5,6] (with the window shifting by i)
				mag.push(qhat)
			}
			remainder := this.shiftMagnitudeRight(this.stripLeadingZeros(num), shift)
			return this.stripLeadingZeros(mag)

			; mag1 = [A,B,C,D,E,...,K,L]
			; mag2 =     [M,N,O,P,R,S] 
			; index = 3
			; trust that [C,D,E,F,G,H] - [M,N,O,P,R,S] will be positive
			; =>     [A,B, [C,D,E,F,G,H] - [M,N,O,P,R,S], I,J,K,L]
			magSubSliceHelper(index) {
				offset := index - 1
				; subtract nums from index to index + mag2.Length (backwards)
				carry := 0
				i := divLen
				while (i > 0) {
					diff := num[offset + i] - tProd[i] - carry
					if (carry := (diff < 0))
						diff += BigInteger.INT32
					num[offset + i] := diff
					i--
				}
			}
		}

		/**
		 * shifts a magnitude <= 32 digits to the right and returns an array of the shift result and remainder.
		 * This is a helper function for division by powers of two and exists solely because shiftMagnitudeRight doesn't return remainder
		 * @param mag 
		 * @param shift 
		 * @returns {Array} 
		 */
		static magDivHelperShiftRight(mag, shift) {
			quotient := []
			remainder := 0
			mask := (1 << shift) - 1
			shiftLeft := 32 - shift
			for digit in mag {
				quotient.push((digit >> shift) | (remainder << shiftLeft))
				remainder := digit & mask
			}
			this.stripLeadingZeros(quotient)
			return [quotient, remainder]
		}

		/**
		 * Divides a magnitude in base 2**32 by divisor, trusting that the divisor is < 2**31 to avoid overflow calculation
		 * @param mag 
		 * @param divisor 
		 * @returns {Array} 
		 */
		static magDivHelperDivide(mag, divisor) {
			quotient := []
			remainder := 0
			for digit in mag {
				dividend := (remainder << 32) + digit
				q := dividend // divisor
				remainder := Mod(dividend, divisor)
				quotient.push(q)
			}
			this.stripLeadingZeros(quotient)
			return [quotient, remainder]
		}

		/**
		 * Divides a magnitude in base 2**32 by divisor, while accounting for overflow
		 * @param mag 
		 * @param divisor 
		 * @param baseDivPrecompute 
		 * @param baseRemPrecompute 
		 * @returns {Array} 
		 */
		static magDivHelperOverflowDivide(mag, divisor, baseDivPrecompute, baseRemPrecompute) {
			/**
			 * Long Division:
			 * Go most significant to least significant
			 * First digit, divide the digit by the divisor and get the remainder through Mod
			 * next digit, remainder * base + digit gives the full number
			 * thus
			 * dividend := remainder * 2**32 + digit
			 * quotient := dividend // divisor
			 * remainder := Mod(divident, divisor)
			 * 1. Optimization: // INT32 <-> >> 32, * INT32 <-> << 32, Mod(,Int32) <-> & INT32 - 1
			 * dividend := (remainder << 32) + digit
			 * quotient := isPowerOfTwo ? dividend >> z : dividend // divisor
			 * remainder := isPowerOfTwo ? dividend & mask : Mod(dividend, base)
			 * 2. remainder < divisor. This means that if divisor >= 2**31, then remainder * 2**32 >= 2**63 => overflow
			 * Thus
			 * quotient = (remainder * base + digit) // divisor ; overflows
			 * 			= (remainder * (base//divisor * divisor + Mod(base, divisor)) + digit) // divisor
			 * 			= (remainder * base//divisor * divisor + remainder * Mod(base, divisor) + digit) // divisor
			 * 			= remainder * base//divisor + (remainder * Mod(base, divisor) + digit) // divisor
			 * 			= base//divisor * remainder + (Mod(base, divisor) * remainder + digit) // divisor
			 * 			= const1	    * remainder + (const2             * remainder + digit) // divisor
			 * 			= const1	    * remainder + (const2             * remainder + digit) // divisor
			 * remainder= Mod(remainder * base + digit, divisor)
			 * 			= Mod(remainder * base//divisor * divisor + remainder * Mod(base, divisor) + digit, divisor)
			 * 			= Mod(remainder * Mod(base, divisor) + digit, divisor)
			 * 			= Mod(const2 * remainder + digit, divisor)
			 * 3. base // divisor = 0 if divisor > base. So in case of converting from base < 2**32 to base 2**32:
			 * quotient = (remainder * base + digit) // divisor
			 * 			= (remainder * 0 * divisor + remainder * Mod(base, divisor) + digit) // divisor
			 * 			= (remainder * Mod(base, divisor) + digit) // divisor
			 * 			= const2 * remainder + digit) // divisor
			 * remainder= unchanged
			 */
			; baseDivPrecompute := BigInteger.INT32 // divisor
			; baseRemPrecompute := Mod(BigInteger.INT32, divisor)
			quotient := []
			remainder := 0
			for digit in mag {
				qtmp1 := baseDivPrecompute * remainder
				qtmp2 := baseRemPrecompute * remainder + digit
				quotDigit := (qtmp1 + qtmp2 // divisor) & BigInteger.INT_MASK
				remainder := Mod(qtmp2, divisor) ; no mask, divisor <= MASK
				quotient.push(quotDigit)
			}
			this.stripLeadingZeros(quotient)
			return [quotient, remainder]
		}

		; start is inclusive. array of 10, start of 4, len of 3 will get index 4,5,6
		/**
		 * Slices a magnitude (or any other array) starting at index start and ending at (inclusive) index start+len-1
		 * @param mag 
		 * @param start 
		 * @param len 
		 * @returns {Array} 
		 * @example
		 * BigInteger.sliceMagnitude([1,2,3,4,5,6,7], 3, 3) => [3,4,5]
		 */
		static sliceMagnitude(mag, start, len) {
			newMag := []
			newMag.Length := len
			Loop (len)
				newMag[A_Index] := mag[start + A_Index - 1]
			return newMag
		}

		static stripLeadingZeros(mag) {
			while (mag.Length > 1 && mag[1] == 0)
				mag.RemoveAt(1)
			return mag
		}

		/**
		 * Returns the number of zero bits preceding the highest-order one-bit in the two's complement representation of n.
		 * @param n An ahk-based Integer (long long int)
		 * @returns {Integer}
		 */
		static numberOfLeadingZeros(n) {
			if n <= 0
				return n == 0 ? 64 : 0
			return 63 - Floor(Log(n) / Log(2))
		}

		/**
		 * Returns the number of zero bits succeeding the lowest set one-bit in n
		 * @param n An ahk-based Integer (long long int)
		 * @returns {Integer}
		 */
		static numberOfTrailingZeros(n) {
			if (n == 0)
				return -1
			return Floor(Log(n & -n) / Log(2))
		}

		/**
		 * Checks if m is a power of n. Returns the exponent k such that n^k == m if true, or 0 otherwise. If both 1 and 0 would be valid exponents, returns 1.
		 * Note that this implies 1 is a power of any number, since x^0 == 1
		 * This has O(log log m) complexity
		 * @param {Integer} n The base to check
		 * @param {Integer} m The power to check
		 * @returns {Integer} 0 or the exponent to which n is raised to equal m
		 */
		static isPowerOf(n, m) {
			if n == 0 || n == 1
				return n == m ? 1 : 0
			if m == 1
				return 0
			pow := n
			i := 1
			while (pow < m) {
				powP := pow
				pow *= pow
				i *= 2
				if pow < powP
					break
			}
			if (pow == m)
				return i
			low := 0
			high := i // 2
			; binary search using i
			while (low + 1 < high) {
				mid := high // 2 + low // 2
				result := powP * n**mid
				if (result == m)
					return i // 2 + mid
				if (result < m)
					low := mid
				else
					high := mid
			}
			return 0
		}
	}

	/**
	 * Computes the greatest common divisor between regular Integers.
	 * @param {Integer} num
	 * @param {Integer} nums*
	 * @returns {Integer} The greatest common divisor
	 */
	static gcdInt(num, additionalNums*) {
		copyNums := []
		additionalNums.push(num)
		for i, e in additionalNums
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
	 * Validates a given potential BigInteger and returns either the given BigInteger or a newly constructed one from the given value
	 * @param {Integer | String | BigInteger} anyInt
	 * @returns {BigInteger} A BigInteger representing the given value
	 */
	static validateBigInteger(anyInt) => anyInt is BigInteger ? anyInt : BigInteger.valueOf(anyInt)

	; BigInteger constant -1
	static MINUS_ONE => BigInteger.Helpers.fromTrustedMagnitude([1], -1)
	; BigInteger constant 0
	static ZERO => BigInteger.Helpers.fromTrustedMagnitude([0], 0)
	; BigInteger constant 1
	static ONE => BigInteger.Helpers.fromTrustedMagnitude([1], 1)
	; BigInteger constant 2
	static TWO => BigInteger.Helpers.fromTrustedMagnitude([2], 1)
	; BigInteger constant 10
	static TEN => BigInteger.Helpers.fromTrustedMagnitude([10], 1)
	; BigInteger constant 1000
	static THOUSAND => BigInteger.Helpers.fromTrustedMagnitude([1000], 1)
	; BigInteger constant 2^32
	static TWO_POW32 =>	BigInteger.Helpers.fromTrustedMagnitude([1, 0], 1)

	/**
	 * BigInteger Properties. THESE VALUES ARE LISTED HERE FOR COMPLETENESS SAKE. USE THEIR GETTER FUNCTIONS TO GET THEM.
	 * ONLY MAG AND SIGNUM ARE SET AT INITIALIZATION, WHILE THE OTHERS ARE SET ON THEIR FIRST REQUEST OF THEIR GETTER
	 * Why not a property getter? A check via HasOwnProp() is possible, but ugly, and without it we would need a second var _lowestBitset etc so it ddoesn't fix anything.
	 * Treat these as if they were private. So why not use the __ prefix to mark them as private? Because then they show up at the top of every symbol index.
	 */
	; The signum of the BigInteger
	signum := 0 ; 0 (ZERO), -1 (NEGATIVE), 1 (POSITIVE)
	; The magnitude of the BigInteger
	mag := []
	; The index of the rightmost nonzero bit, where 0 is 0, 1 is XXXXX1, 2 is XXXX10 etc
	lowestSetBit := -1
	; The length in bits of this number, excluding the sign bit.
	bitLength := -1

	; The Maximum Value of an unsigned int: 2^32
	static INT32 := 1 << 32
	; Masks values to < 2**64, 0xFFFFFFFFFFFFFFFF
	static LONG_MASK := 0xFFFFFFFFFFFFFFFF
	; Masks values to < 2**32, 0xFFFFFFFF
	static INT_MASK := 0xFFFFFFFF
	; Masks values to < 2**16, 0xFFFF
	static SHORT_MASK := 0xFFFF

	class Error {
		static NOT_INTEGER[n] => ValueError("Received non-integer input: " (IsObject(n) ? Type(n) : n))
		static INVALID_RADIX[n] => ValueError("Invalid Radix: " (IsObject(n) ? Type(n) : n))
		static INCOMPATIBLE_RADIX[n, m] => ValueError("Cannot convert digits of Radix " n " to digits of radix " m " with function expandMagnitudeToRadix. Use convertMagnitudeBase for that")
		static ILLEGAL_NEGATIVE[method, n] => ValueError("Specified parameter cannot be negative: " method " can only use positive values, but received " (n is BigInteger ? n.toStringApprox() : n))
		static GIGABYTE_OPERATION[method, n] => ValueError("Specified parameter outside of supported range: If method " method " were to use given value " (n is BigInteger ? n.toStringApprox() : n) ", the calculation would create a variable of size >4GB in memory.")
		static BAD_TWO_COMPLEMENT[type, n] => ValueError("Invalid twos complement representation:`nMust include leading word or be zero, received " (type == 1 ? "mag of Length " : "Leading word of value ") n)
	}
}