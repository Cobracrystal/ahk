/************************************************************************
 * @description A class to handle arbitrary precision Integers
 * @author cobracrystal
 * @date 2025/09/10
 * @version 0.5.2
***********************************************************************/

; static alias for these?
; FINAL DOESN'T MEAN THAT DOCS ARE ADDED!!!!
; merge the two respective division functions (the two non-overflow and the two overflow versions)
/**
 * METHODS
 * @example													; NOTES:
 * ; Construction from and output to native values
 * BigInteger.Prototype.__New(intOrString) 					; IMPLEMENTED, FINAL
 * BigInteger.valueOf(intOrString) 							; IMPLEMENTED, FINAL
 * BigInteger.fromMagnitude([digits*], 1) 					; IMPLEMENTED, FINAL
 * BigInteger.fromAnyMagnitude([digits*], radix, signum)	; IMPLEMENTED, FINAL
 * BigInteger.Prototype.toString(radix) 					; IMPLEMENTED, FINAL
 * BigInteger.Prototype.toStringApprox(radix)				; IMPLEMENTED, FINAL
 * BigInteger.Prototype.getFirstNDigits(radix, digits)		; IMPLEMENTED, FINAL
 * BigInteger.Prototype.Length(radix) 						; IMPLEMENTED, FINAL
 * ; Type conversion
 * BigInteger.Prototype.shortValue() 						; IMPLEMENTED, FINAL
 * BigInteger.Prototype.int32Value() 						; IMPLEMENTED, FINAL
 * BigInteger.Prototype.intValue() 							; IMPLEMENTED, FINAL
 * BigInteger.Prototype.uintValue() 						; IMPLEMENTED, FINAL
 * BigInteger.Prototype.getBitLength()						; IMPLEMENTED, FINAL
 * BigInteger.Prototype.getLowestSetBit()					; IMPLEMENTED, FINAL
 * ; bitwise arithmetic
 * BigInteger.Prototype.and(anyInt) 						; IMPLEMENTED, lazy (only for positive)
 * BigInteger.Prototype.not()							 	; IMPLEMENTED, FINAL
 * BigInteger.Prototype.andNot(anyInt) 						; IMPLEMENTED, FINAL
 * BigInteger.Prototype.or(anyInt) 							; IMPLEMENTED, lazy (only for positive)
 * BigInteger.Prototype.xor(anyInt) 						; IMPLEMENTED, lazy (only for positive)
 * BigInteger.Prototype.shiftLeft(int) 						; IMPLEMENTED, FINAL
 * BigInteger.Prototype.shiftRight(int) 					; IMPLEMENTED, FINAL
 * BigInteger.Prototype.maskBits(int) 						; IMPLEMENTED, FINAL
 * ; Comparison
 * BigInteger.Prototype.equals(anyInt) 						; IMPLEMENTED, FINAL
 * BigInteger.Prototype.compareTo(anyInt) 					; IMPLEMENTED, FINAL
 * BigInteger.Prototype.min(anyInt*)						; IMPLEMENTED, FINAL
 * BigInteger.Prototype.max(anyInt*)						; IMPLEMENTED, FINAL
 * BigInteger.min(anyInt*)									; IMPLEMENTED, FINAL
 * BigInteger.max(anyInt*)									; IMPLEMENTED, FINAL
 * BigInteger.Sort(anyInt, anyInts*) 								; IMPLEMENTED, FINAL
 * ; Arithmetic
 * BigInteger.Prototype.abs()							 	; IMPLEMENTED, FINAL
 * BigInteger.Prototype.negate()							; IMPLEMENTED, FINAL
 * BigInteger.Prototype.add(anyInt) 						; IMPLEMENTED, INEFFICIENT
 * BigInteger.Prototype.subtract(anyInt) 					; IMPLEMENTED, INEFFICIENT
 * BigInteger.Prototype.multiply(anyInt) 					; IMPLEMENTED, INEFFICIENT
 * BigInteger.Prototype.pow(anyInt) 						; IMPLEMENTED, INEFFICIENT
 * BigInteger.Prototype.divide(anyInt) 						; TODO (incorrect implementation atm)
 * BigInteger.Prototype.divideAndRemainder(anyInt) 			; TODO
 * BigInteger.Prototype.divideByDigitPower(int, int) 		; IMPLEMENTED, FINAL
 * BigInteger.Prototype.mod(anyInt) 						; TODO
 * BigInteger.Prototype.gcd(anyInt) 						; TODO
 * BigInteger.Prototype.sqrt()							 	; TODO
 * BigInteger.Prototype.sqrtAndRemainder()					; TODO
 * ; Primes and Hashing
 * BigInteger.Prototype.isProbablePrime()					; TODO
 * BigInteger.Prototype.nextProbablePrime()					; TODO
 * BigInteger.Prototype.hashCode()							; TODO
 * BigInteger.nextProbablePrime()							; TODO
 * BigInteger.isProbablePrime()								; TODO
 * BigInteger.hashCode()									; TODO
 * ; Properties
 * BigInteger.Prototype.getSignum()							; IMPLEMENTED, FINAL
 * BigInteger.Prototype.getMagnitude()						; IMPLEMENTED, FINAL
 * BigInteger.signum
 * BigInteger.mag
 * ; Other
 * BigInteger.Prototype.Clone()								; IMPLEMENTED, FINAL (Overriding default .Clone())
 * 
 * 
 * ; Helper functions
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
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {BigInteger}
	 */
	__New(anyInt, radix := 10) {
		if (Type(anyInt) != "String")
			anyInt := String(anyInt)
		if (SubStr(anyInt, 1, 1) = "-") {
			this.signum := -1
			anyInt := SubStr(anyInt, 2)
		} else if (SubStr(anyInt, 1, 1) = "+") {
			this.signum := 1
			anyInt := SubStr(anyInt, 2)
		} else {
			this.signum := 1
		}
		if (anyInt == "0") {
			this.signum := 0
			this.mag := [0]
			return
		}
		if !IsAlnum(anyInt)
			throw BigInteger.Error.NOT_INTEGER[anyInt]
		this.mag := BigInteger.magnitudeFromString(anyInt, radix)
	}

	/**
	 * Returns a new BigInteger. Synonymous with creating a BigInteger instance
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @param {Integer} radix The radix or base of the given number.
	 * @returns {BigInteger}
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
	 */
	static fromMagnitude(mag, signum := 1) {
		obj := BigInteger(0) ; can't construct empty biginteger instance
		obj.signum := (mag.Length = 1 && mag[1] = 0) ? 0 : signum
		obj.mag := mag.Clone()
		return obj
	}

	/**
	 * Constructs a BigInteger given any base digit representation and signum.
	 * @param {Array} mag an array of integers < 2^32 in bigEndian notation
	 * @param {Integer} radix The base of the given magnitude. Defaults to 10
	 * @param {Integer} signum The signum of the number. 1 for positive, -1 for negative, 0 for 0. If magnitude is an array containing only 0, signum will be automatically set to 0.
	 * @returns {BigInteger} The Constructed Value
	 */
	static fromAnyMagnitude(mag, radix := 10, signum := 1) {
		signum := (mag.Length = 1 && mag[1] = 0) ? 0 : signum
		mag := this.validateMagnitudeRadix(mag, radix)
		exponent := BigInteger.getMaxComputableRadixPower(radix)
		maxRadixMag := BigInteger.shrinkMagnitudeToPowRadix(mag, radix, exponent)
		return BigInteger.fromMagnitude(BigInteger.normalizeMagnitudeBase(maxRadixMag, radix**exponent), signum)
	}

	/**
	 * Returns a String representing this.
	 * @param {Integer} radix. Must be 2 <= radix <= 36
	 * @returns {String} The number this BigInteger represents. May start with -. Never starts with +.
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
			Loop(newMag.Length - 1)
				str .= Format("{:09}", newMag[A_Index + 1])
		} else { ; this is *significantly* faster than directly converting to radix
			newMag := BigInteger.expandMagnitudeToRadix(newMag, powRadix, radix)
			for d in newMag
				str .= d > 9 ? Chr(d+55) : d
		}
		return str
	}

	/**
	 * Returns a String representing an approximate representation of this in scientific format (x.xxxxxx * radix^exp) with 10 total digits
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
	 * Returns the first N digits of the BigInteger. This is relatively more efficient than calling toString() for very large numbers
	 * @param {Integer} radix The radix that the digits should be returned in. Should be between 2 and 36
	 * @param {Integer} digits The amount of digits to return. Numbers larger than the length of the biginteger will simply return toString()
	 * @returns {String} The first N digits of the BigInteger
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
		wordsNeeded := Min(Ceil(digits * Log(radix)/(32 * Log(2))) + 1, this.mag.Length)
		newMag := []
		Loop(wordsNeeded)
			newMag.push(this.mag[A_Index])
		loop(this.mag.Length - wordsNeeded)
			newMag.push(0)
		ndigits := BigInteger.fromMagnitude(newMag, this.signum).divideByDigitPower(radix, len - digits)
		return ndigits.toString(radix)
	}

	/**
	 * Returns 1 if (this) is larger than anyInt, -1 if it is smaller.
	 * Logically equivalent to the comparison (this > anyInt) ? 1 : this == anyInt ? 0 : -1
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {Integer} 1, 0, -1.
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
	 * Returns true if this and anyInt represent the same number, 0 otherwise.
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {Boolean} true if this == anyInt. false otherwise
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
	 * Returns the absolute value of (this)
	 * @returns {BigInteger}
	 */
	abs() {
		if this.signum == 0
			return BigInteger(0)
		return BigInteger.fromMagnitude(this.mag, 1)
	}

	/**
	 * Returns a new BigInteger with the signum flipped.
	 * @returns {BigInteger} The created BigInteger
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
	 * @returns {BigInteger}
	 */
	multiply(anyInt) {
		anyInt := BigInteger.validateBigInteger(anyInt)
		magProduct := BigInteger.multiplyMagnitudes(this.mag, anyInt.mag)
		return BigInteger.fromMagnitude(magProduct, this.signum * anyInt.signum)
	}

	/**
	 *
	 * @param {Integer} exponent A positive integer to exponentiate [this] by.
	 * @returns {BigInteger}
	 */
	pow(exponent) {
		if exponent is BigInteger {
			if exponent.mag.Length > 1
				throw BigInteger.Error.EXPONENT_OUT_OF_RANGE[exponent]
			exponent := exponent.mag[1]
		}
		if exponent < 0
			throw BigInteger.Error.EXPONENT_OUT_OF_RANGE[exponent]
		if exponent >= BigInteger.INT32
			throw BigInteger.Error.EXPONENT_OUT_OF_RANGE[exponent]
		if !this.signum
			return exponent == 0 ? BigInteger.ONE : BigInteger.ZERO
		workingExponent := exponent
		result := [1]
		magSquare := this.mag.Clone()
		while (workingExponent != 0) { ; this is *not* more speed-efficient than just multiplying self n times. Both are O(n²k²) with n=exp, k=maglen. however squaremagnitude can be improved to linear instead of O(k²).
			if (workingExponent & 1)
				result := BigInteger.multiplyMagnitudes(result, magSquare)
			if ((workingExponent >>>= 1) != 0) ; cuts off right-most bit if it is 1
				magSquare := BigInteger.squareMagnitude(magSquare)
		}
		; more efficient: factor out all powers of two. we can square those easily and don't need to multiply with them. then add them back in
		; n = 2^m * q with q%2 = 1. Thus n^p = 2^m^p * q^p. But 2^m^p = 2^(m*p), so we just need to shift left
		return BigInteger.fromMagnitude(result, exponent & 1 ? this.signum : 1) ; lowest bit set -> odd exponent
	}

	/**
	 * Divides (this) by the given Integer Representation and returns a new BigInteger representing the new result
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {BigInteger} The result of division, rounded down to the nearest BigInteger. 22/7 = 3
	 */
	divide(anyInt) {
		anyInt := BigInteger.validateBigInteger(anyInt)
		magQuotient := BigInteger.divideMagnitudes(this.mag, anyInt.mag)
		return BigInteger.fromMagnitude(magQuotient, this.signum * anyInt.signum)
	}

	divideAndRemainder(anyInt) => this

	/**
	 * Divides this by the given digit raised to pow.
	 * @param divDigit An Integer > 0 and < 2**32
	 * @returns {Array} The new magnitude
	 */
	divideByDigitPower(divisor, pow := 1) {
		if (isPowerOfTwo := (divisor & (divisor - 1) == 0)) { ; base is power of two
			shiftBits := BigInteger.numberOfTrailingZeros(divisor) * pow
			return this.shiftRight(shiftBits)
		}
		mag := this.mag
		if (overflow := divisor >= 2**31) { ; overflow
			baseDivPrecompute := BigInteger.INT32 // divisor
			baseRemPrecompute := Mod(BigInteger.INT32, divisor)
		}
		Loop(pow) {
			if (overflow)
				mag := BigInteger.magDivHelperOverflowDivide(mag, divisor, baseDivPrecompute, baseRemPrecompute)[1]
			else
				mag := BigInteger.magDivHelperDivide(mag, divisor)[1]
		}
		return BigInteger.fromMagnitude(mag, this.signum)
	}
	
	/**
	 *
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {BigInteger}
	 */
	mod(anyInt) => this
	
	/**
	 *
	 * @param {Integer | String | BigInteger} anyInt Any number of Integers, strings representing an integer or BigIntegers
	 * @returns {BigInteger}
	 */
	gcd(anyInt*) => 0
	

	sqrt() => this
	sqrtAndRemainder() => this
	
	and(anyInt) {
		anyInt := BigInteger.validateBigInteger(anyInt)
		newMag := []
		n1 := this.mag.Length
		n2 := anyInt.mag.Length
		largerMag := n1 >= n2 ? this.mag : anyInt.mag
		smallerMag := n1 >= n2 ? anyInt.mag : this.mag
		if true || (this.signum == 1 && anyInt.signum == 1) {
			d := Abs(n1 - n2)
			Loop(Min(n1, n2))
				newMag.push(smallerMag[A_Index] & largerMag[A_Index + d])
		}
		return BigInteger.fromMagnitude(newMag, this.signum & anyInt.signum)
	}

	/**
	 * Returns a BigInteger whose value is equivalent to ~this as if it was stored in twos complement.
	 * @returns {BigInteger} 
	 */
	not() => this.negate().subtract(1)
	
	andNot(anyInt) => this.and(BigInteger.validateBigInteger(anyInt).not())

	or(anyInt) {
		anyInt := BigInteger.validateBigInteger(anyInt)
		newMag := []
		n1 := this.mag.Length
		n2 := anyInt.mag.Length
		largerMag := n1 >= n2 ? this.mag : anyInt.mag
		smallerMag := n1 >= n2 ? anyInt.mag : this.mag
		if true || (this.signum == 1 && anyInt.signum == 1) {
			Loop(d := Abs(n1 - n2))
				newMag.push(largerMag[A_Index])
			Loop(Min(n1, n2))
				newMag.push(smallerMag[A_Index] | largerMag[A_Index + d])
		}
		return BigInteger.fromMagnitude(newMag, this.signum | anyInt.signum)
	}

	xor(anyInt) {
		anyInt := BigInteger.validateBigInteger(anyInt)
		newMag := []
		n1 := this.mag.Length
		n2 := anyInt.mag.Length
		largerMag := n1 >= n2 ? this.mag : anyInt.mag
		smallerMag := n1 >= n2 ? anyInt.mag : this.mag
		if true || (this.signum == 1 && anyInt.signum == 1) {
			Loop(d := Abs(n1 - n2))
				newMag.push(largerMag[A_Index])
			Loop(Min(n1, n2))
				newMag.push(smallerMag[A_Index] ^ largerMag[A_Index + d])
		}
		signum := this.signum * anyInt.signum ? this.signum * anyInt.signum : this.signum | anyInt.signum ; x ^ 0 == x | 0
		return BigInteger.fromMagnitude(newMag, signum)
	}

	shiftLeft(n) {
		shiftBits := n & 0x1F
		shiftWords := n >>> 5
		if n <= 0
			return n == 0 ? this.Clone() : this.shiftRight(-n)
		newMag := []
		len := this.mag.Length
		if shiftWords > len
			return this.signum >= 0 ? BigInteger.ZERO : BigInteger.MINUS_ONE
		mag := []
		if (shiftBits == 0) {
			mag := this.mag.Clone()
			Loop(shiftWords)
				mag.push(0)
		} else {
			if (shiftWords == 0)
				tMag := this.mag
			else {
				tMag := []
				Loop(len)
					tMag := this.mag.clone()
				Loop(shiftWords)
					tMag.push(0)
			}
			p := 0
			mask := (1 << shiftBits) - 1
			mag.Length := i := len
			while(i >= 1) {
				mag[i] := ((this.mag[i] << shiftBits & BigInteger.INT_MASK) | p)
				p := this.mag[i] >> (32 - shiftBits)
				i--
			}
			if (p > 0)
				mag.InsertAt(1, p)
		}
		return BigInteger.fromMagnitude(mag, this.signum)
	}

	/**
	 * Performs this >> n. Preserves sign
	 * @param {Integer} n Must be smaller than 2**32 (Not that it matters)
	 * @returns {BigInteger} A new biginteger representing this >> n
	 */
	shiftRight(n) {
		shiftBits := n & 0x1F
		shiftWords := n >>> 5
		if n <= 0
			return n == 0 ? this.Clone() : this.shiftLeft(-n)
		len := this.mag.Length
		if shiftWords > len
			return this.signum >= 0 ? BigInteger.ZERO : BigInteger.MINUS_ONE
		mag := []
		if (shiftBits == 0) {
			Loop(len - shiftWords)
				mag.push(this.mag[A_Index])
		} else {
			if (shiftWords == 0)
				tMag := this.mag
			else {
				tMag := []
				Loop(len - shiftWords)
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
	 * Gets the last n bits
	 * @param {Integer} n
	 * @returns {BigInteger} A BigInteger which represents the n bits.
	 */
	maskBits(n) {
		bitMask := (1 << (n & 0x1F)) - 1 ; mask
		words := n >>> 5
		if n == 0
			return [0]
		len := this.mag.Length
		if words >= len
			return this.Clone()
		mag := []
		Loop(words)
			mag.push(this.mag[len - words + A_Index])
		if bitMask
			mag.InsertAt(1, this.mag[len - words - 1] & bitMask)
		return BigInteger.fromMagnitude(mag, this.signum)
	}

	shortValue() => this.signum * (this.mag[-1] & 0xFFFF)

	int32Value() => this.signum * this.mag[-1]

	intValue() => this.signum * ((this.mag.Length > 1 ? (this.mag[-2] & 0x7FFFFFFF) << 32 : 0) + this.mag[-1])

	uintValue() => this.signum * ((this.mag.Length > 1 ? (this.mag[-2]) << 32 : 0) + this.mag[-1])

	/**
	 * Returns the index of the first one-bit in this BigInteger in little-endian
	 * @description The reason why the values
	 * @example
	 * BigInteger(0xFFFF).getLowestSetBit() ; -> 1
	 * BigInteger(0x1000).getLowestSetBit() ; -> 13
	 * BigInteger(0).getLowestSetBit() ; -> 0
	 */
	getLowestSetBit() {
		lsb := this.lowestSetBit
		if lsb == -1 { ; uninitialized
			if !this.signum {
				lsb := 0
			} else {
				len := this.mag.Length
				Loop(len) {
					i := len - A_Index + 1
					num := this.mag[i]
					if num != 0
						break
				}
				lsb := ((len - i) << 5) + BigInteger.numberOfTrailingZeros(num) + 1
			}
			this.lowestSetBit := lsb
		}
		return lsb
	}

	/**
	 * Returns the number of bits in the representation of this BigInteger, excluding the sign Bit.
	 * For Zero, this returns 0.
	 * @returns {Integer} Number of bits in this BigInteger
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
	 * Returns the Length of the number in the specified base (default 10). An alias for base 2 is given through getBitLength()
	 * For Zero, this always returns 0.
	 * @param {Integer} radix The base in which to compute the Length of. Must be between 2 and 2**32 (base 1 is this BigInteger).
	 * @returns {Integer} The Length of this BigInteger in base 10
	 */
	Length(radix := 10) {
		static log10ofBase := Log(BigInteger.INT32)
		top := this.mag[1]
		n := this.mag.Length
		if n == 0 && top == 0
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
		upper_bound := Log(1 + 1/top) / Log(radix)
		fracpart := hatL - Floor(hatL)
		dist := Min(fracpart, 1 - fracpart)
		if dist > upper_bound
			return digitCandidate
		frac := 0
		scale := 1 / BigInteger.INT32
		epsilon := 2**-52
		Loop(n - 1) { ; lower / B^n-1
			cur := this.mag[A_Index + 1] * scale
			if cur < epsilon ; 2**(32*33) > 0, but 2**(32*34) == 0. Thus this will always have 34 iterations at most.
				break
			scale /= BigInteger.INT32
			frac += cur
		}
		delta := Log(1 + frac/top) / Log(radix)
		hatL += delta
		digitCandidate := Floor(hatL + 1e-18) + 1 ; minimal correction if we are 1 epsilon off
		return digitCandidate
	}
	
	/**
	 * Gets the lowest value from (this) and given values.
	 * @param {Integer | String | BigInteger} anyInt Any number of Integers, strings representing an integer or BigIntegers
	 */
	min(anyInt*) {
		curMin := this
		for bigInt in anyInt
			curMin := curMin.compareTo(bigInt) == 1 ? bigInt : curMin
		return curMin
	}

	/**
	 * Gets the highest value from (this) and given values.
	 * @param {Integer | String | BigInteger} anyInt Any number of Integers, strings representing an integer or BigIntegers
	 * @returns {BigInteger}
	 */
	max(anyInt*) {
		curMax := this
		for bigInt in anyInt
			curMax := curMax.compareTo(bigInt) == -1 ? bigInt : curMax
		return curMax
	}
	
	isProbablePrime() => false
	nextProbablePrime() => this
	hashCode() => 0

	; static methods that correspond to Prototype methods
	static Min(anyInt, anyintValues*) 	=> this.validateBigInteger(anyInt).Min(anyintValues*)
	static Max(anyInt, anyintValues*) 	=> this.validateBigInteger(anyInt).Max(anyintValues*)
	static isProbablePrime(anyInt) 		=> this.validateBigInteger(anyInt).isProbablePrime()
	static nextProbablePrime(anyInt) 	=> this.validateBigInteger(anyInt).nextProbablePrime()
	static hashCode(anyInt) 			=> this.validateBigInteger(anyInt).hashCode()

	/**
	 * Given any number of BigIntegers, sorts them numerically ascending using a custom mergesort.
	 * @param {Integer | String | BigInteger} anyInt An Integer, string representing an integer or BigInteger
	 * @param {Integer | String | BigInteger} anyIntValues* Any number of Integers, strings representing an integer or BigIntegers
	 * @returns {Array} A numerically ascending sorted array containing BigIntegers. Note that these BigIntegers are not clones, but the same as the original BigIntegers referenced in the parameters.
	 */
	static Sort(anyInt, anyIntValues*) {
		nums := [this.validateBigInteger(anyInt)]
		for i, e in anyIntValues
			nums.push(this.validateBigInteger(e)) ; while compareTo validates too, it is called O(nlogn) times, so this is better
		len := anyIntValues.length + 1
		res := []
		res.Length := len
		sliceLen := 1
		while(sliceLen <= len) {
			c := 1
			while (c <= len) {
				i := c
				j := indexB := min(c + sliceLen, len)
				lastIndex := min(c + 2 * sliceLen - 1, len)
				Loop(lastIndex - c + 1) {
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
	 * Returns the signum of the number.
	 * @returns {BigInteger} Will be -1, 0, 1, corresponding to this < 0, this = 0, this > 0
	 */
	getSignum() => this.signum
	
	/**
	 * Returns a clone of the magnitude of the number.
	 * @returns {Array} Array of Integers that are base-2^32 digits representing the number
	 */
	getMagnitude() => this.mag.Clone()

	Clone() => BigInteger.fromMagnitude(this.mag, this.signum)
	
	/**
	 * Given a string of arbitrary length in base 10, returns an array of its digits in base 2**32
	 * @param {String} str A positive Integer String of arbitrary length. Must not contain -/+ at the beginning.
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
			Loop(len // chunkLen) { ; interpret as base 10**9
				magBaseB.push(Integer(SubStr(str, chunkIndex, chunkLen)))
				chunkIndex += chunkLen
			}
			return BigInteger.normalizeMagnitudeBase(magBaseB, radix**chunkLen)
		} else if (radix == 16) { ; parse in chunks and directly cast to base 2^32
			if (offset := Mod(len, chunkLen))
				magBaseB.push(Integer('0x' SubStr(str, 1, offset)))
			chunkIndex := offset + 1
			Loop(len // chunkLen) {
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
		m := Mod(n-1, exponent)
		v := 0
		for i, e in mag {
			if e >= baseRadix
				throw BigInteger.Error.INVALID_RADIX[baseRadix " (Found " e " in magnitude)"]
			v += e * baseRadix**m
			m--
			if Mod(n-i, exponent) == 0 {
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
			Loop(ex) { ; remainder and thus overflow is irrelevant here
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
	static getMaxComputableRadixPower(radix) => Floor(log(1 << 32)/log(radix))

	/**
	 * Convert a magnitude in base to base 2^32.
	 * @param mag
	 * @param base
	 * @returns {Array}
	 */
	static normalizeMagnitudeBase(mag, base) {
		result := []
		if base == BigInteger.INT32
			return mag.clone()
		if base == 0
			throw ValueError("You entered base 0, which doesn't exist. If you do think that it exists, please write me an email.")
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
	 * @param mag
	 * @param base
	 * @returns {Array}
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
			magSum.InsertAt(1, carry)
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

	static multiplyMagnitudes(mag1, mag2) {
		len1 := mag1.Length
		len2 := mag2.Length
		result := []
		Loop len1 + len2 ; minimum is max(len1, len2), maximum is len1+len2 (eg 0xFF * 0xFF = 0xFE01)
			result.Push(0)
		Loop(len1) {
			i := A_Index
			carry := 0
			a := mag1[-i]
			Loop(len2) {
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
	 * @param {Array} mag1 Dividend magnitude
	 * @param {Array} mag2 Divisor magnitude
	 * @returns {Array} Quotient magnitude
	 */
	static divideMagnitudes(mag1, mag2) {
		return BigInteger.ZERO
	}

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
		 * remainder= Mod(remainder * base + digit) // divisor
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

	/**
	 * Computes the greatest common divisor between regular Integers
	 * @param {Integer} num
	 * @param {Integer} nums*
	 * @returns {Integer} The greatest common divisor
	 */
	static gcdInt(num, additionalNums*) {
		additionalNums.push(num)
		copyNums := additionalNums
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
		static ONE_OVER_LOG2 := 3.3219280948873622
		if n <= 0
			return n == 0 ? 64 : 0
		return 63 - Floor(Log(n) * ONE_OVER_LOG2)
	}
	
	/**
	 * Returns the number of zero bits succeeding the lowest set one-bit in n
	 * @param n An ahk-based Integer (long long int)
	 * @returns {Integer} 
	 */
	static numberOfTrailingZeros(n) {
		static ONE_OVER_LOG2 := 3.3219280948873622
		if (n == 0)
			return -1
		return Floor(Log(n & -n) * ONE_OVER_LOG2)
	}

	/**
	 * Checks if m is a power of n. Returns the exponent k st n^k == m if true, or 0 otherwise. If both 1 and 0 would be valid exponents, returns 1.
	 * Note that this implies 1 is a power of any number, since x^0 == 1
	 * This has O(log log m) complexity
	 * @param n The base to check
	 * @param m The power to check
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
				return i//2 + mid
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
	static MINUS_ONE => BigInteger(-1)
	; BigInteger constant 0
	static ZERO => BigInteger(0)
	; BigInteger constant 1
	static ONE => BigInteger(1)
	; BigInteger constant 2
	static TWO => BigInteger(2)
	; BigInteger constant 10
	static TEN => BigInteger(10)
	; BigInteger constant 1000
	static THOUSAND => BigInteger(1000)
	; BigInteger constant 2^32
	static TWO_POW_32 => BigInteger(this.INT32)

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
	; Masks values to < 2**64 - 1
	static LONG_MASK := 0xFFFFFFFFFFFFFFFF
	; Masks values to < 2**32 - 1
	static INT_MASK := 0xFFFFFFFF
	; The Maximum Value of an ahk integer, or long long int: 2^63-1
	static MAX_INT_VALUE := (1 << 63) - 1
	; The number of bytes necessary to store an ahk integer, or long long int: 64
	static MAX_INT_SIZE := 64

	class Error {
		static NOT_INTEGER[n] => ValueError("Received non-integer input: " (IsObject(n) ? Type(n) : n))
		static INVALID_RADIX[n] => ValueError("Invalid Radix: " (IsObject(n) ? Type(n) : n))
		static EXPONENT_OUT_OF_RANGE[n] => ValueError("Exponent out of range for supported values (>= 2**32): " (n is BigInteger ? n.toStringApprox() : n))
		static INCOMPATIBLE_RADIX[n, m] => ValueError("Cannot convert digits of Radix " n " to digits of radix " m "")
	}
}