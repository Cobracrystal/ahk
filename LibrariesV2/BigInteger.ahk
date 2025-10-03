/************************************************************************
 * @description A class to handle arbitrary precision Integers
 * @author cobracrystal
 * @date 2025/10/02
 * @version 0.8.5
 ***********************************************************************/

; static alias for these?
; FINAL DOESN'T MEAN THAT DOCS ARE ADDED!!!!
; merge the two respective division functions (the two non-overflow and the two overflow versions)
; Todo getFirstNDigits and divideByIntPower should utilize radix expansion to be more efficient.
; TOdo squareMag linear (karatsuba)
; TOdo multiply via karatsuba
; todo divide
; todo gcd failure
/**
 * METHODS
 * @example														; NOTES:
 * ; Construction from and output to native values
 * BigInteger.Prototype.__New(intOrString) 						; IMPLEMENTED, FINAL
 * BigInteger.valueOf(intOrString) 								; IMPLEMENTED, FINAL
 * BigInteger.fromMagnitude([digits*], 1) 						; IMPLEMENTED, FINAL
 * BigInteger.fromAnyMagnitude([digits*], radix, signum)		; IMPLEMENTED, FINAL
 * BigInteger.fromTwosComplement([signWord, digits*])			; IMPLEMENTED, FINAL
 * BigInteger.Prototype.toString(radix) 						; IMPLEMENTED, FINAL
 * BigInteger.Prototype.toStringApprox(radix)					; IMPLEMENTED, FINAL
 * BigInteger.Prototype.getFirstNDigits(radix, digits)			; IMPLEMENTED, FINAL
 * BigInteger.Prototype.Length(radix) 							; IMPLEMENTED, FINAL
 * ; Arithmetic
 * BigInteger.Prototype.abs()							 		; IMPLEMENTED, FINAL
 * BigInteger.Prototype.negate()								; IMPLEMENTED, FINAL
 * BigInteger.Prototype.add(anyInt) 							; IMPLEMENTED, FINAL
 * BigInteger.Prototype.subtract(anyInt) 						; IMPLEMENTED, FINAL
 * BigInteger.Prototype.multiply(anyInt) 						; IMPLEMENTED, SEMI-EFFICIENT
 * BigInteger.Prototype.pow(anyInt) 							; IMPLEMENTED, FINAL (APART FROM SQUAREMAG)
 * BigInteger.Prototype.divide(anyInt, &remainder) 				; IMPLEMENTED, FINAL
 * BigInteger.Prototype.divideByIntPower(int, int, &remainder)	; IMPLEMENTED, FINAL
 * BigInteger.Prototype.mod(anyInt) 							; IMPLEMENTED, FINAL
 * BigInteger.mod(numerator, divisor) 							; IMPLEMENTED, FINAL
 * BigInteger.Prototype.gcd(anyInt) 							; IMPLEMENTED, FINAL
 * BigInteger.gcd(anyInt, anyInts*)								; IMPLEMENTED, FINAL
 * BigInteger.Prototype.sqrt()							 		; IMPLEMENTED, FINAL
 * BigInteger.Prototype.nthRoot()						 		; IMPLEMENTED, FINAL
 * ; Comparison
 * BigInteger.Prototype.equals(anyInt) 							; IMPLEMENTED, FINAL
 * BigInteger.Prototype.compareTo(anyInt) 						; IMPLEMENTED, FINAL
 * BigInteger.Prototype.min(anyInt*)							; IMPLEMENTED, FINAL
 * BigInteger.Prototype.max(anyInt*)							; IMPLEMENTED, FINAL
 * BigInteger.min(anyInt*)										; IMPLEMENTED, FINAL
 * BigInteger.max(anyInt*)										; IMPLEMENTED, FINAL
 * BigInteger.Sort(anyInt, anyInts*) 							; IMPLEMENTED, FINAL
 * ; bitwise arithmetic
 * BigInteger.Prototype.and(anyInt) 							; IMPLEMENTED, FINAL
 * BigInteger.Prototype.not()							 		; IMPLEMENTED, FINAL
 * BigInteger.Prototype.andNot(anyInt) 							; IMPLEMENTED, FINAL
 * BigInteger.Prototype.or(anyInt) 								; IMPLEMENTED, FINAL
 * BigInteger.Prototype.xor(anyInt) 							; IMPLEMENTED, FINAL
 * BigInteger.Prototype.shiftLeft(int) 							; IMPLEMENTED, FINAL
 * BigInteger.Prototype.shiftRight(int) 						; IMPLEMENTED, FINAL
 * BigInteger.Prototype.maskBits(int) 							; IMPLEMENTED, FINAL
 * ; Type conversion
 * BigInteger.Prototype.shortValue() 							; IMPLEMENTED, FINAL
 * BigInteger.Prototype.int32Value() 							; IMPLEMENTED, FINAL
 * BigInteger.Prototype.intValue() 								; IMPLEMENTED, FINAL
 * BigInteger.Prototype.getBitLength()							; IMPLEMENTED, FINAL
 * BigInteger.Prototype.getLowestSetBit()						; IMPLEMENTED, FINAL
 * BigInteger.Prototype.toTwosComplement()						; IMPLEMENTED, FINAL
 * ; Primes
 * BigInteger.Prototype.isProbablePrime()						; TODO
 * BigInteger.Prototype.nextProbablePrime()						; TODO
 * ; Properties
 * BigInteger.Prototype.getSignum()								; IMPLEMENTED, FINAL
 * BigInteger.Prototype.getMagnitude()							; IMPLEMENTED, FINAL
 * ; Other
 * BigInteger.Prototype.Clone()									; IMPLEMENTED, FINAL (Overriding default .Clone())
 * 
 * 
 * ; Helper functions. These trust the input and will throw unexpected errors if input is not validated correctly.
 * ; Magnitude arithmetic
 * BigInteger.addMagnitudes()
 * BigInteger.subtractMagnitudes()
 * BigInteger.multiplyMagnitudes()
 * BigInteger.squareMagnitude()
 * BigInteger.divideMagnitudes()
 * ; magnitude manipulation
 * BigInteger.convertMagnitudeBase()
 * BigInteger.normalizeMagnitudeBase()
 * BigInteger.expandMagnitudeToRadix()
 * BigInteger.shrinkMagnitudeToPowRadix()
 * BigInteger.stripLeadingZeros()
 * BigInteger.magnitudeFromString()
 * BigInteger.compareMagnitudes()
 * BigInteger.magDivHelperDivide()
 * BigInteger.magDivHelperNormalize()
 * BigInteger.magDivHelperOverflowDivide()
 * BigInteger.magDivHelperOverflowNormalize()
 * BigInteger.magDivHelperShiftRight()
 * ; int32 functions
 * BigInteger.gcdInt()
 * BigInteger.isPowerOf()
 * BigInteger.getMaxComputableRadixPower()
 * BigInteger.numberOfLeadingZeros()
 * BigInteger.numberOfTrailingZeros()
 * ; validation
 * BigInteger.validateBigInteger()
 * BigInteger.validateMagnitudeRadix()
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
			return
		}
		if !IsAlnum(anyInt) || anyInt == ""
			throw BigInteger.Error.NOT_INTEGER[anyInt]
		this.mag := BigInteger.magnitudeFromString(anyInt, radix)
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
		obj := BigInteger(0) ; Do not call BigInteger.ZERO, that's recursive
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
		mag := this.validateMagnitudeRadix(mag, radix)
		exponent := BigInteger.getMaxComputableRadixPower(radix)
		maxRadixMag := BigInteger.shrinkMagnitudeToPowRadix(mag, radix, exponent)
		return BigInteger.fromMagnitude(BigInteger.normalizeMagnitudeBase(maxRadixMag, radix**exponent), signum)
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
		if mag.Length == 1 && mag[1] == 0
			return BigInteger.ZERO
		if mag.Length <= 1
			throw BigInteger.Error.BAD_TWO_COMPLEMENT[1, mag.Length]
		mag := mag.Clone()
		leadingSign := mag.RemoveAt(1)
		if (leadingSign == 0)
			return BigInteger.fromMagnitude(BigInteger.stripLeadingZeros(mag), 1)
		if leadingSign != BigInteger.INT_MASK
			throw BigInteger.Error.BAD_TWO_COMPLEMENT[2, leadingSign]
		newMag := []
		newMag.Length := len := mag.Length
		if len == 0
			throw BigInteger.Error.BAD_TWO_COMPLEMENT[]
		unchangedWords := BigInteger.fromMagnitude(mag).getLowestSetBit() >>> 5
		Loop (unchangedWords) ; copy rightmost words that are 0
			newMag[-A_index] := 0
		newMag[-unchangedWords - 1] := (~mag[-unchangedWords - 1] + 1) & BigInteger.INT_MASK
		Loop (len - unchangedWords - 1)
			newMag[A_Index] := ~mag[A_Index] & BigInteger.INT_MASK
		return BigInteger.fromMagnitude(BigInteger.stripLeadingZeros(newMag), -1)
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
		ex := BigInteger.getMaxComputableRadixPower(radix)
		powRadix := radix**ex
		newMag := BigInteger.convertMagnitudeBase(this.mag, powRadix)
		if (radix == 10) {
			str .= newMag[1]
			Loop (newMag.Length - 1)
				str .= Format("{:09}", newMag[A_Index + 1])
		} else { ; this is *significantly* faster than directly converting to radix
			newMag := BigInteger.expandMagnitudeToRadix(newMag, powRadix, radix)
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

		str := this.signum < 0 ? '-' : ''
		exponent := this.Length(radix) - 1
		ndigits := this.getFirstNDigits(radix, 10)
		return str . SubStr(ndigits, 1, 1) . "." SubStr(ndigits, 2) . "e+" exponent
	}

	/**
	 * Returns the first N digits of the BigInteger. This is slower (why?) than directly calling toString, but may be preferable for very large numbers due to string manipulation being expensive.
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
		ndigits := BigInteger.fromMagnitude(newMag, this.signum).divideByIntPower(radix, len - digits)
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
			magSum := BigInteger.addMagnitudes(this.mag, anyInt.mag)
			return BigInteger.fromMagnitude(magSum, this.signum)
		} else {
			comparison := BigInteger.compareMagnitudes(this.mag, anyInt.mag)
			if !comparison
				return BigInteger.ZERO
			minuend := comparison == 1 ? this : anyInt
			subtrahend := comparison == 1 ? anyInt : this
			return BigInteger.fromMagnitude(BigInteger.subtractMagnitudes(minuend.mag, subtrahend.mag), minuend.signum)
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
			return BigInteger.fromMagnitude(this.abs().add(anyInt.abs()).mag, this.signum)
		} else {
			comparison := BigInteger.compareMagnitudes(this.mag, anyInt.mag)
			if comparison == 0
				return BigInteger.ZERO
			minuend := comparison == 1 ? this : anyInt
			subtrahend := comparison == 1 ? anyInt : this
			magDiff := BigInteger.subtractMagnitudes(minuend.mag, subtrahend.mag)
			return BigInteger.fromMagnitude(magDiff, comparison == 1 ? this.signum : -this.signum)
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
		if this.mag.Length == 1 && this.mag[1] == 1
			return BigInteger.fromMagnitude(anyInt.mag, this.signum * anyInt.signum)
		if anyInt.mag.Length == 1 && anyInt.mag[1] == 1
			return BigInteger.fromMagnitude(this.mag, this.signum * anyInt.signum)
		magProduct := BigInteger.multiplyMagnitudes(this.mag, anyInt.mag)
		return BigInteger.fromMagnitude(magProduct, this.signum * anyInt.signum)
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
				if (exponent & 0x1) && this.signum < 0
					return BigInteger.MINUS_ONE.shiftLeft(powerofTwo * exponent)
				else
					return BigInteger.ONE.shiftLeft(powerofTwo * exponent)
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
				result := BigInteger.multiplyMagnitudes(result, magSquare)
			if ((workingExponent >>>= 1) != 0) ; cuts off right-most bit if it is 1
				magSquare := BigInteger.squareMagnitude(magSquare)
		}
		res := BigInteger.fromMagnitude(result, exponent & 0x1 ? this.signum : 1)
		if (powerofTwo)
			return res.shiftLeft(powerofTwo * exponent)
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
		cmp := BigInteger.compareMagnitudes(this.mag, anyInt.mag)
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
		magQuotient := BigInteger.divideMagnitudes(this.mag, anyInt.mag, &rem)
		remainder := BigInteger.fromMagnitude(rem, this.signum)
		return BigInteger.fromMagnitude(magQuotient, this.signum * anyInt.signum)
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
			shiftBits := BigInteger.numberOfTrailingZeros(divisor) * pow
			if shiftBits > this.getBitLength()
				rem := this.mag
			else { ; do not use maskBits as that uses twos complement
				rem := []
				words := shiftBits >>> 5
				bits := shiftBits & 0x1F
				rem.Length := words
				Loop (words)
					rem[-A_Index] := this.mag[-A_Index]
				rem.InsertAt(1, this.mag[-words - 1] & ((1 << bits) - 1))
			}
			remainder := BigInteger.fromMagnitude(BigInteger.stripLeadingZeros(rem), this.signum)
			res := this.shiftRight(shiftBits)
			res.signum := signum
			return res
		}
		mag := this.mag
		if (overflow := divisor >= 2**31) { ; overflow
			baseDivPrecompute := BigInteger.INT32 // divisor
			baseRemPrecompute := Mod(BigInteger.INT32, divisor)
		}
		divAsBigInt := BigInteger.validateBigInteger(divisor)
		remainder := BigInteger.ZERO
		Loop (pow) {
			if (overflow)
				arr := BigInteger.magDivHelperOverflowDivide(mag, divisor, baseDivPrecompute, baseRemPrecompute)
			else
				arr := BigInteger.magDivHelperDivide(mag, divisor)
			mag := arr[1]
			remainder := remainder.add(divAsBigInt.pow(pow - A_Index).multiply(arr[2]))
		}
		if !remainder.equals(BigInteger.ZERO)
			remainder.signum := this.signum
		return BigInteger.fromMagnitude(mag, signum)
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
	 * Modulo. Returns the remainder of anyIntNum divided by anyIntDiv. This is an alias for BigInteger.Prototype.divide(anyInt, &remainder) with its parameters swapped.
	 * @param {Integer | String | BigInteger} anyIntNum An Integer, a string representing an integer or a BigInteger
	 * @param {Integer | String | BigInteger} anyIntDiv An Integer, a string representing an integer or a BigInteger
	 * @param {&BigInteger?} quotient This will be set to the result of the division, if given.
	 * @returns {BigInteger} The result of the modulo operation.
	 */
	static Mod(anyIntNum, anyIntDiv) => this.validateBigInteger(anyIntNum).mod(anyIntDiv)
	
	/**
	 * Calculates the greatest common divisor amongst the given Integer-likes and (this), using Euclids algorithm. This will always be positive. Use gcdInt if values are small as this is expensive due to division.
	 * @param {Integer | String | BigInteger} anyInts Any number of Integers, strings representing an integer or BigIntegers
	 * @returns {BigInteger} A new BigInteger representing the greatest common divisor of (this) and anyInt
	 * @example
	 * BigInteger(3033956).gcd('824387595128', '-178468', BigInteger(892340)).toString() => 178468
	 */
	gcd(anyintValues*) {
		copyNums := []
		anyintValues.push(this)
		for i, e in anyintValues {
			v := BigInteger.validateBigInteger(e)
			if !v.equals(BigInteger.ZERO)
				copyNums.push(BigInteger.validateBigInteger(e).abs())
		}
		firstMin := curMin := BigInteger.Min(copyNums*)
		while (copyNums.Length > 1) {
			tNums := []
			for i, e in copyNums {
				if (e == curMin) { ; == is valid because we check object pointers
					tNums.Push(e)
					continue
				}
				m := e.Mod(curMin)
				if !m.equals(BigInteger.ZERO)
					tNums.push(m)
			}
			; division is very expensive so if everything fits into int, just throw it to regular division. 
			; this check makes runtime about ~3x faster on average
			if curMin.mag.Length <= 1 || (curMin.mag.Length == 2 && curMin.mag[1] < 2**31) {
				r := []
				for e in tNums
					r.push(e.intValue())
				return BigInteger.fromMagnitude([BigInteger.gcdInt(r*)])
			}
			copyNums := tNums
			curMin := BigInteger.Min(copyNums*)
		}
		if curMin == firstMin
			return curMin.Clone()
		return curMin
	}
	
	/**
	 * Calculates the greatest common divisor amongst the given Integer-likes, using Euclids algorithm. This will always be positive.
	 * @param {Integer | String | BigInteger} anyInt An Integer, string representing an integer or BigInteger
	 * @param {Integer | String | BigInteger} anyInts Any number of Integers, strings representing an integer or BigIntegers
	 * @returns {BigInteger} A new BigInteger representing the greatest common divisor of the given values
	 * @example
	 * BigInteger.gcd(3033956, '824387595128', '-178468', BigInteger(892340)).toString() => 178468
	 */
	static gcd(anyInt, anyIntValues*) => this.validateBigInteger(anyInt).gcd(anyIntValues*)

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
	 * @param {&BigInteger?} remainder The remainder of the operation, ie a number st i^n + remainder == (this)
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
			if (BigInteger.compareMagnitudes(xk1.mag, xk.mag) == 0) {
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
		magComp := BigInteger.compareMagnitudes(this.mag, anyInt.mag)
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
		shiftBits := n & 0x1F
		shiftWords := n >>> 5
		if n == 0
			return this.Clone()
		if n < 0
			throw BigInteger.Error.ILLEGAL_NEGATIVE['shiftLeft', n]
		newMag := []
		len := this.mag.Length
		mag := []
		if (shiftBits == 0) {
			mag := this.mag.Clone()
			Loop (shiftWords)
				mag.push(0)
		} else {
			p := 0
			mask := (1 << shiftBits) - 1
			mag := []
			mag.Length := i := len
			while (i >= 1) {
				mag[i] := ((this.mag[i] << shiftBits & BigInteger.INT_MASK) | p)
				p := this.mag[i] >> (32 - shiftBits)
				i--
			}
			if (p > 0)
				mag.InsertAt(1, p)
			Loop (shiftWords)
				mag.push(0)
			p := 0
		}
		return BigInteger.fromMagnitude(mag, this.signum)
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
		shiftBits := n & 0x1F
		shiftWords := n >>> 5
		if n == 0
			return this.Clone()
		if n < 0
			throw BigInteger.Error.ILLEGAL_NEGATIVE['shiftRight', n]
		len := this.mag.Length
		if shiftWords >= len
			return this.signum >= 0 ? BigInteger.ZERO : BigInteger.MINUS_ONE
		mag := []
		if (shiftBits == 0) {
			Loop (len - shiftWords)
				mag.push(this.mag[A_Index])
		} else {
			if (shiftWords == 0)
				tMag := this.mag
			else {
				tMag := []
				Loop (len - shiftWords)
					tMag.push(this.mag[A_Index])
			}
			p := 0
			mask := (1 << shiftBits) - 1 ; binary with <shiftBits> one-bits at the end
			shiftBitsLeft := 32 - shiftBits
			for i, e in tMag {
				mag.push((e >> shiftBits) | (p << shiftBitsLeft))
				p := e & mask
			}
			BigInteger.stripLeadingZeros(mag)
		}
		return BigInteger.fromMagnitude(mag, this.signum)
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
		if n == 0 || (this.mag.Length == 1 && this.mag[1] == 0)
			return BigInteger.ZERO
		len := this.mag.Length
		if words >= len
			return this.Clone()
		mag := []
		Loop (words)
			mag.push(this.mag[len - words + A_Index])
		if bitMask
			mag.InsertAt(1, this.mag[len - words] & bitMask)
		return BigInteger.fromMagnitude(mag, this.signum)
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
	static Min(anyInt, anyintValues*) => this.validateBigInteger(anyInt).Min(anyintValues*)
	
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
	static Max(anyInt, anyintValues*) => this.validateBigInteger(anyInt).Max(anyintValues*)

	/**
	 * Given any number of BigIntegers, sorts them numerically ascending using a custom mergesort.
	 * @param {Integer | String | BigInteger} anyInt An Integer, string representing an integer or BigInteger
	 * @param {Integer | String | BigInteger} anyIntValues* Any number of Integers, strings representing an integer or BigIntegers
	 * @returns {Array} A numerically ascending sorted array containing BigIntegers. Note that these BigIntegers are not clones, but the same as the original BigIntegers referenced in the parameters.
	 * @example
	 * BigInteger.Sort(-1, '-329428934829349', 5, 3242) => [BigInteger('-329428934829349'), BigInteger(-1), BigInteger(5), BigInteger(3242)]
	 */
	static Sort(anyInt, anyIntValues*) {
		nums := [this.validateBigInteger(anyInt)]
		for i, e in anyIntValues
			nums.push(this.validateBigInteger(e)) ; while compareTo validates too, it is called O(nlogn) times, so this is better
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
			bits := ((this.mag.Length - 1) << 5) + (64 - BigInteger.numberOfLeadingZeros(this.mag[1]))
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
				lsb := ((len - i) << 5) + BigInteger.numberOfTrailingZeros(this.mag[i]) + 1
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
	Clone() => BigInteger.fromMagnitude(this.mag, this.signum)

	/**
	 * Given a string of arbitrary length in base 10, returns an array of its digits in base 2**32
	 * @param {String} str A positive Integer String of arbitrary length. Must not contain -/+ at the beginning.
	 * @param {Integer} radix 2<0radix<=36
	 * @returns {Array} The strings base-n digit representation as an Array
	 */
	static magnitudeFromString(str, radix := 10) {
		; parse string into base-10**9 magnitude
		magBaseB := []
		len := StrLen(str)
		chunkLen := BigInteger.getMaxComputableRadixPower(radix)
		if (radix == 10) { ; parse string in chunks and interpret as base 10^9
			if (offset := Mod(len, chunkLen))
				magBaseB.push(Integer(SubStr(str, 1, offset)))
			chunkIndex := offset + 1
			Loop (len // chunkLen) { ; interpret as base 10**9
				magBaseB.push(Integer(SubStr(str, chunkIndex, chunkLen)))
				chunkIndex += chunkLen
			}
			return BigInteger.normalizeMagnitudeBase(magBaseB, radix**chunkLen)
		} else if (radix == 16) { ; parse in chunks and directly cast to base 2^32
			if (offset := Mod(len, chunkLen))
				magBaseB.push(Integer('0x' SubStr(str, 1, offset)))
			chunkIndex := offset + 1
			Loop (len // chunkLen) {
				magBaseB.push(Integer('0x' SubStr(str, chunkIndex, chunkLen)))
				chunkIndex += chunkLen
			}
			return magBaseB
		} else if (radix & (radix - 1) == 0) { ; power of two, utilize that
			mag := BigInteger.validateMagnitudeRadix(StrSplit(str), radix)
			maxRadixMag := BigInteger.shrinkMagnitudeToPowRadix(mag, radix, chunkLen)
			return BigInteger.normalizeMagnitudeBase(maxRadixMag, radix**chunkLen)
		} else {
			mag := BigInteger.validateMagnitudeRadix(StrSplit(str), radix)
			maxRadixMag := BigInteger.shrinkMagnitudeToPowRadix(mag, radix, chunkLen)
			return BigInteger.normalizeMagnitudeBase(maxRadixMag, radix**chunkLen)
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
			if e >= baseRadix
				throw BigInteger.Error.INVALID_RADIX[baseRadix " (Found " e " in magnitude)"]
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
		ex := BigInteger.isPowerOf(baseRadix, powRadix)
		if !ex
			throw BigInteger.Error.INCOMPATIBLE_RADIX[powRadix, baseRadix]
		if ex == 1
			return mag.clone()
		isPowerOfTwo := (baseRadix & (baseRadix - 1) == 0)
		mask := baseRadix - 1
		z := BigInteger.numberOfTrailingZeros(baseRadix)
		newMag := []
		for i, digit in mag {
			miniMag := []
			Loop (ex) { ; remainder and thus overflow is irrelevant here
				miniMag.InsertAt(1, isPowerOfTwo ? digit & mask : Mod(digit, baseRadix))
				digit := isPowerOfTwo ? digit >> z : digit // baseRadix
			}
			if (i == 1)
				BigInteger.stripLeadingZeros(miniMag)
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
		while (mag[1] != 0) {
			if (overflow)
				arr := BigInteger.magDivHelperOverflowNormalize(mag, base)
			else
				arr := BigInteger.magDivHelperNormalize(mag, base)
			mag := arr[1]
			result.InsertAt(1, arr[2])
		}
		return result
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
			if BigInteger.isPowerOf(base, BigInteger.INT32) ; 2**32 is (base^n), so digits can be read per word
				return BigInteger.expandMagnitudeToRadix(mag, BigInteger.INT32, base)
			mask := base - 1
			z := BigInteger.numberOfTrailingZeros(base)
		}
		result := []
		if (overflow := base >= 2**31) {
			baseDivPrecompute := BigInteger.INT32 // base
			baseRemPrecompute := Mod(BigInteger.INT32, base)
		}
		while (mag[1] != 0) {
			if isPowerOfTwo
				arr := BigInteger.magDivHelperShiftRight(mag, z)
			else if overflow
				arr := BigInteger.magDivHelperOverflowDivide(mag, base, baseDivPrecompute, baseRemPrecompute)
			else
				arr := BigInteger.magDivHelperDivide(mag, base)
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
	 * Multiplies mag1 with mag2 and returns the product
	 * @param mag1 
	 * @param mag2 
	 * @returns {BigInteger}
	 */
	static multiplyMagnitudes(mag1, mag2) {
		len1 := mag1.Length
		len2 := mag2.Length
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

	/**
	 * Efficiently squares a magnitude
	 * @param mag 
	 * @returns {BigInteger} 
	 */
	static squareMagnitude(mag) {
		static KARATSUBA_SQUARE_THRESHOLD := 128
		len := mag.Length
		if len < KARATSUBA_SQUARE_THRESHOLD
			return simpleSquare()
		else
			return karatsubaSquare()

		simpleSquare() {
			return this.multiplyMagnitudes(mag, mag)
		}

		karatsubaSquare() {
			return this.multiplyMagnitudes(mag, mag)
		}
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
		shift := BigInteger.numberOfLeadingZeros(divisor[1]) - 32
		divAsBigInt := BigInteger.fromMagnitude(divisor)
		numAsBigInt := BigInteger.fromMagnitude(dividend)
		; U, the dividend of m+n digits
		numLen := dividend.Length
		; V, the divisor of n digits
		divLen := divisor.Length
		; Q, the quotient of m+1 digits, and R, the remainder of n digits
		resLen := dividend.Length - divLen + 1
		; normalize the divisor so that its >= 2**31 (>= Base / 2)
		div := divAsBigInt.shiftLeft(shift).mag
		num := numAsBigInt.shiftLeft(shift).mag
		if (div.Length == num.Length) { ; we assume mag2 > mag1, so if after normalization we get this, its one. This check isn't necessary, but helps
			remainder := BigInteger.subtractMagnitudes(dividend, divisor)
			return [1]
		}
		divHigh := div[1]
		divLow := div[2]
		mag := []
		baseDivPrecompute := BigInteger.INT32 // divHigh
		baseRemPrecompute := Mod(BigInteger.INT32, divHigh)
		; U is m+n digits stored in m+n+1 digit array. The shiftLeft may have caused this to already exist, otherwise fill it in.
		if num.Length == numLen ; shifting did not cause a spillover, so pad with 0
			num.InsertAt(1, 0)
		Loop (resLen) { ; big endian notation
			i := A_Index
			; Set Q̂ to (U[i] × B + U[i+1]) ÷ V[1];
			; Set R̂ to (U[i] × B + U[i+1]) % V[1];
			; below are the "normal" calculations which overflow. We apply the precomputation trick twice
			; qhat := ( num[i] << 32 | uHigh ) // divHigh
			; rhat := Mod(num[i] << 32 | uHigh, divHigh)
			uHigh := num[i + 1]
			uLow := num[i + 2]
			qtmp := baseDivPrecompute * num[i]
			rtmp := baseRemPrecompute * num[i] + uHigh
			qhat := (qtmp + rtmp // divHigh) & BigInteger.INT_MASK
			rhat := Mod(rtmp, divHigh)
			if (divLow > 0) {
				cDivPrec := BigInteger.INT32 // divLow
				cRemPrec := Mod(BigInteger.INT32, divLow)
			}
			; Test if Q̂ equals B or Q̂ × V[2] is greater than R̂ × B + U[i+2];
			; qhat * divLow > rhat * base + uLow => qhat > (rhat * base + uLow) // divLow
			while (qhat == BigInteger.INT32 || (divLow > 0 && (qhat > (cDivPrec * rhat + (cRemPrec * rhat + uLow) // divLow)))) {
				; If yes, then decrease Q̂ by 1, increase R̂ by V[1], and repeat this test while R is less than B.
				qhat--
				rhat += divHigh
				if rhat >= BigInteger.INT32 ; loop happens at most 2 times
					break
			}
			; Replace (U[i]U[i+1]…U[i+n]) by (U[i]U[i+1]…U[i+n]) − Q̂ × (V[1]…V[n-1]V[n]).
			tDiv := BigInteger.sliceMagnitude(num, i, divLen + 1)
			tProd := BigInteger.multiplyMagnitudes(div, [qhat])
			; Decrease Q[j] by 1 and add (0V[1]…V[n-1]V[n]) to (U[i]U[i+1]…U[i+n-1]U[i+n]).
			if (BigInteger.compareMagnitudes(tDiv, tProd) == -1) {
				tProd := BigInteger.subtractMagnitudes(tProd, div)
				qhat--
			}
			if tProd.Length == divLen ; pad with 0 to ensure length n+1
				tProd.InsertAt(1, 0)
			num := BigInteger.magSubHelperCutFromLeft(num, tProd, i) ; performs [3,1,2,9,....,5,6] - [1,1,0] = [2,0,2,9,....,5,6] (with the window shifting by i)
			mag.push(qhat)
		}
		remainder := BigInteger.fromMagnitude(BigInteger.stripLeadingZeros(num)).shiftRight(shift).mag ; a bit cursed, but fine
		return BigInteger.stripLeadingZeros(mag)
	}

	/**
	 * Subtracts mag2 from mag1 as if mag2 was extended to the right with zeros, and then trimming the result to the length of mag2.
	 * Eg [12,4,5,6,....,5,1], [3,2,4,1] -> [9,2,1,5,....,5,1]
	 * @param mag1
	 * @param mag2
	 * @param index Index of window
	 * @returns {Array}
	 */
	static magSubHelperCutFromLeft(mag1, mag2, index) {
		magDiff := []
		carry := 0
		l1 := mag1.Length
		l2 := mag2.Length
		i := l2
		while (i > 0) {
			a := mag1[index + i - 1]
			b := mag2[i]
			diff := a - b - carry
			carry := 0
			if (diff < 0) {
				diff += BigInteger.INT32
				carry := 1
			}
			magDiff.InsertAt(1, diff)
			i--
		}
		if carry
			throw Error("mag2 was larger than mag1 in magSubHelperCutFromLeft")
		Loop (index - 1) ; add nums back in front
			magDiff.InsertAt(1, mag1[A_Index])
		Loop (l1 - l2 - index + 1) ; add nums back in back
			magDiff.push(mag1[l2 + A_Index])
		return magDiff
	}

	/**
	 * Efficiently shifts a magnitude <= 32 digits to the right and returns an array of the shift result and remainder.
	 * This is a helper function for division by powers of two.
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
		BigInteger.stripLeadingZeros(quotient)
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
		BigInteger.stripLeadingZeros(quotient)
		return [quotient, remainder]
	}

	/**
	 * Divides a magnitude in base base by 2**32 to normalize it
	 * @param mag 
	 * @param base 
	 * @returns {Array} 
	 */
	static magDivHelperNormalize(mag, base) {
		quotient := []
		remainder := 0
		for digit in mag {
			dividend := remainder * base + digit
			q := dividend >> 32
			remainder := dividend & 0xFFFFFFFF
			quotient.push(q)
		}
		BigInteger.stripLeadingZeros(quotient)
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
		BigInteger.stripLeadingZeros(quotient)
		return [quotient, remainder]
	}

	/**
	 * Divides a magnitude in base base by 2**32 to normalize it, accounting for overflow
	 * @param mag 
	 * @param base 
	 * @returns {Array} 
	 */
	static magDivHelperOverflowNormalize(mag, base) {
		; baseDivPrecompute := base >> 32 ; this is always zero, so forget the term
		; baseRemPrecompute := base & 0xFFFFFFFF ; this is always just base
		quotient := []
		remainder := 0
		for digit in mag {
			qtmp := base * remainder + digit
			quotDigit := (qtmp >>> 32) & BigInteger.INT_MASK
			remainder := qtmp & 0xFFFFFFFF
			quotient.push(quotDigit)
		}
		BigInteger.stripLeadingZeros(quotient)
		return [quotient, remainder]
	}

	; start is inclusive. array of 10, start of 4, len of 3 will get index 4,5,6
	/**
	 * Slices a magnitude (or any other array) starting at index start and ending at index start+len-1
	 * @param mag 
	 * @param start 
	 * @param len 
	 * @returns {Array} 
	 * @example
	 * BigInteger.sliceMagnitude([1,2,3,4,5,6,7], 3, 3) => [3,4,5]
	 */
	static sliceMagnitude(mag, start, len) {
		newMag := []
		Loop (len)
			newMag.push(mag[start + A_Index - 1])
		return newMag
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
	 * Checks if m is a power of n. Returns the exponent k st n^k == m if true, or 0 otherwise. If both 1 and 0 would be valid exponents, returns 1.
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

	/**
	 * Validates a given potential BigInteger and returns a BigInteger
	 * @param {Integer | String | BigInteger} anyInt
	 * @returns {BigInteger} A BigInteger representing the given value
	 */
	static validateBigInteger(anyInt) => anyInt is BigInteger ? anyInt : BigInteger.valueOf(anyInt)

	; BigInteger constant -1
	static MINUS_ONE => BigInteger.fromMagnitude([1], -1)
	; BigInteger constant 0
	static ZERO => BigInteger.fromMagnitude([0], 0)
	; BigInteger constant 1
	static ONE => BigInteger.fromMagnitude([1], 1)
	; BigInteger constant 2
	static TWO => BigInteger.fromMagnitude([2], 1)
	; BigInteger constant 10
	static TEN => BigInteger.fromMagnitude([10], 1)
	; BigInteger constant 1000
	static THOUSAND => BigInteger.fromMagnitude([1000], 1)
	; BigInteger constant 2^32
	static TWO_POW_32 => BigInteger.fromMagnitude([1, 0], 1)

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
	; Masks values to < 2**63, 0x7FFFFFFFFFFFFFFF
	static SIGNED_LONG_MASK := 0x7FFFFFFFFFFFFFFF
	; Masks values to < 2**32, 0xFFFFFFFF
	static INT_MASK := 0xFFFFFFFF
	; Masks values to < 2**16, 0xFFFF
	static SHORT_MASK := 0xFFFF
	; The number of bytes necessary to store an ahk integer, long int: 64
	static MAX_INT_SIZE := 64

	class Error {
		static NOT_INTEGER[n] => ValueError("Received non-integer input: " (IsObject(n) ? Type(n) : n))
		static INVALID_RADIX[n] => ValueError("Invalid Radix: " (IsObject(n) ? Type(n) : n))
		static INCOMPATIBLE_RADIX[n, m] => ValueError("Cannot convert digits of Radix " n " to digits of radix " m " with function expandMagnitudeToRadix. Use convertMagnitudeBase for that")
		static ILLEGAL_NEGATIVE[method, n] => ValueError("Specified parameter cannot be negative: " method " can only use positive values, but received " (n is BigInteger ? n.toStringApprox() : n))
		static GIGABYTE_OPERATION[method, n] => ValueError("Specified parameter outside of supported range: If method " method " were to use given value " (n is BigInteger ? n.toStringApprox() : n) ", the calculation would create a variable of size >4GB in memory.")
		static BAD_TWO_COMPLEMENT[type, n] => ValueError("Invalid twos complement representation:`nMust include leading word or be zero, received " (type == 1 ? "mag of Length " : "Leading word of value ") n)
	}
}