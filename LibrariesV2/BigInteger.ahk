/************************************************************************
 * @description A class to handle arbitrary precision Integers
 * @author cobracrystal
 * @date 2025/09/10
 * @version 0.4.9
***********************************************************************/

; static alias for these?
; FINAL DOESN'T MEAN THAT DOCS ARE ADDED!!!!

/**
 * METHODS
 * @example													; NOTES:
 * ; Construction from and output to native values
 * BigInteger.Prototype.__New(intOrString) 					; IMPLEMENTED, FINAL
 * BigInteger.valueOf(intOrString) 							; IMPLEMENTED, FINAL
 * BigInteger.fromMagnitude([digits*], 1) 					; IMPLEMENTED, FINAL
 * BigInteger.fromAnyMagnitude([digits*], radix, signum)	; IMPLEMENTED, FINAL
 * BigInteger.Prototype.toString(radix) 					; IMPLEMENTED, FINAL (?)
 * BigInteger.Prototype.toStringApprox(radix)				; IMPLEMENTED, FINAL
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
 * BigInteger.Prototype.not()							 	; IMPLEMENTED, INEFFICIENT (lazy)
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
 * BigInteger.Sort(anyInt*) 								; TODO
 * ; Arithmetic
 * BigInteger.Prototype.abs()							 	; IMPLEMENTED, FINAL
 * BigInteger.Prototype.negate()							; IMPLEMENTED, FINAL
 * BigInteger.Prototype.add(anyInt) 						; IMPLEMENTED, INEFFICIENT
 * BigInteger.Prototype.subtract(anyInt) 					; IMPLEMENTED, INEFFICIENT
 * BigInteger.Prototype.multiply(anyInt) 					; IMPLEMENTED, INEFFICIENT
 * BigInteger.Prototype.pow(anyInt) 						; IMPLEMENTED, INEFFICIENT
 * BigInteger.Prototype.divide(anyInt) 						; TODO (incorrect implementation atm)
 * BigInteger.Prototype.divideAndRemainder(anyInt) 			; TODO
 * BigInteger.Prototype.mod(anyInt) 						; TODO
 * BigInteger.Prototype.gcd(anyInt) 						; TODO
 * BigInteger.Prototype.sqrt()							 	; TODO
 * BigInteger.Prototype.sqrtAndRemainder()					; TODO
 * ; Primes and Hashing
 * BigInteger.Prototype.isProbablePrime()					; TODO
 * BigInteger.isProbablePrime()								; TODO
 * BigInteger.Prototype.nextProbablePrime()					; TODO
 * BigInteger.nextProbablePrime()							; TODO
 * BigInteger.Prototype.hashCode()							; TODO
 * BigInteger.hashCode()									; TODO
 * ; Properties
 * BigInteger.Prototype.getSignum()							; IMPLEMENTED, FINAL
 * BigInteger.Prototype.getMagnitude()						; IMPLEMENTED, FINAL
 */
class BigInteger {
	/**
	 * Constructs a BigInteger given any integer-like input
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {BigInteger}
	 */
	__New(anyInt) {
		if (Type(anyInt) != "String")
			anyInt := String(anyInt)
		if !IsInteger(anyInt)
			throw BigInteger.Error.NOT_INTEGER[anyInt]
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
		this.mag := BigInteger.magnitudeFromString(anyInt)
	}

	/**
	 * Returns a new BigInteger. Synonymous with creating a BigInteger instance
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {BigInteger}
	 */
	static valueOf(anyInt) => BigInteger(anyInt)

	/**
	 * Constructs a BigInteger given its base 2^32 digit representation and signum
	 * @param {Array} mag an array of integers < 2^32 in bigEndian notation
	 * @param {Integer} signum The signum of the number. 1 for positive, -1 for negative, 0 for 0. If magnitude is an array containing only 0, signum will be automatically set to 0.
	 * @returns {BigInteger} The Constructed Value
	 * @example 
	 * BigInteger.fromMagnitude([1,2], -1) => - (1 * 2**32 + 2) = -4294967298
	 */
	static fromMagnitude(mag, signum := 1) {
		obj := BigInteger(0) ; can't construct empty biginteger instance
		obj.signum := (mag.Length = 1 && mag[1] = 0) ? 0 : signum
		for e in mag
			if e >= BigInteger.INT32
				throw BigInteger.Error.INVALID_RADIX['? (Found ' e ' in magnitude)']
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
		if radix > BigInteger.INT32
			throw BigInteger.Error.INVALID_RADIX[radix '(Must be < 2^32)']
		possibleAlphaDigit := radix > 10 && radix <= 36
		numMag := []
		for i, e in mag {
			if isAlpha(e) {
				if !possibleAlphaDigit
					throw BigInteger.Error.INVALID_RADIX[radix '( Found alphanumerical digit ' e ')']
				n := Ord(e) - 55
			} else
				n := e
			if n >= radix
				throw BigInteger.Error.INVALID_RADIX[radix . ' (Found ' n ' in magnitude)']
			numMag[i] := n
		}
		exponent := BigInteger.getMaxComputableRadixPower(radix)
		maxRadixMag := BigInteger.shrinkMagnitudeToPowRadix(numMag, radix, exponent)
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
		
		; for higher efficiency, convert to maxComputableRadix and then convert each digit on their own?
		; for higher efficiency, detect radix == 2**n and use masks on each digit directly
		if radix == 10 {
			newMag := BigInteger.convertMagnitudeBase(this.mag, BigInteger.INT_BILLION)
			str .= newMag[1]
			Loop(newMag.Length - 1)
				str .= Format("{:09}", newMag[A_Index + 1])
		} else {
			newMag := BigInteger.convertMagnitudeBase(this.mag, radix)
			if (radix < 10) {
				for d in newMag
					str .= d
			} else {
				for d in newMag
					str .= d > 9 ? Chr(d+55) : d
			}
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
		while (workingExponent != 0) {
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
			mask := divisor - 1
			shiftBits := BigInteger.numberOfTrailingZeros(divisor) * pow
			return this.shiftRight(shiftBits)
		}
		mag := this.mag
		defaultDiv := BigInteger.INT32 // divisor
		defaultRem := Mod(BigInteger.INT32, divisor)
		Loop(pow) {
			nMag := []
			remainder := 0
			for digit in mag {
				q := defaultDiv * remainder
				tmp := defaultRem * remainder + digit
				quotient := (q + tmp // divisor) & BigInteger.INT_MASK
				remainder := Mod(tmp, divisor) ; no mask, divisor <= MASK
				nMag.push(quotient)
				; below is the arithmetically 'normal' calculation, which fails due to overflows.
				; dividend := remainder << 32 + digit
				; quotient := dividend // divisor
				; remainder := Mod(dividend, divisor)
			}
			mag := nMag
			BigInteger.stripLeadingZeros(mag)
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
	
	andnot(anyInt) => this.and(BigInteger.validateBigInteger(anyInt).not())

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
				mag.push((e >> shiftBits) | p << shiftBitsLeft)
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
		/*	dCandidate is at most ±1 off from the actual result. 
			Floating point errors do not matter here: 
			float error in log(int32) ≈ 8.85e-16, so for (n-1) * errLog > 0.5, we need n >= 10^14, which is >25 Petabytes of storage. 
			Similarly, fractional resolution is irrelevant.
			Instead, exactness matters:
			topHatL ≈ Log(N) = (n-1) log(B) + log(top)
			but: N = top * B^(n-1) + lower = B^(n-1) * (top + lower/B^(n-1)), thus
			log(N) = (n-1) log(B) + log(top + lower/B^(n-1)) 
			       = (n-1) log(B) + log(top) + log(1 + lower/(top*B^(n-1)))
			set delta = log(1 + lower/(top*B^(n-1)))
			so log(N) = topHatL + delta.
			Since lower/B^n-1 < 1, delta < log(1+1/top) so use this as upper bound to check if delta should be computed (as it usually is < 10^-6)
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

	static Min(anyInt, anyint32Values*) => this.validateBigInteger(anyInt).Min(anyint32Values*)
	static Max(anyInt, anyint32Values*) => this.validateBigInteger(anyInt).Max(anyint32Values*)
	
	
	isProbablePrime() => false
	static isProbablePrime(anyInt) => this.validateBigInteger(anyInt).isProbablePrime()
	nextProbablePrime() => this
	static nextProbablePrime(anyInt) => this.validateBigInteger(anyInt).nextProbablePrime()
	hashCode() => 0

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
	static magnitudeFromString(str) {
		; parse string into base-10**9 magnitude
		magBaseB := []
		len := StrLen(str)
		Loop(len // 9) { ; interpret as base 10**9
			chunk := len - A_Index * 9 + 1
			magBaseB.InsertAt(1, Integer(SubStr(str, chunk, 9)))
		}
		if Mod(len, 9)
			magBaseB.InsertAt(1, Integer(SubStr(str, 1, Mod(len, 9))))
		return BigInteger.normalizeMagnitudeBase(magBaseB, BigInteger.INT_BILLION)
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
	 * @returns {Array} [ new Magnitude, new Radix] The newly constructed magnitude in base radix**n
	 */
	static expandMagnitudeToRadix(mag, powRadix, baseRadix) {
		ex := Log(powRadix) / Log(baseRadix)
		if Round(ex) != ex
			throw BigInteger.Error.INCOMPATIBLE_RADIX[powRadix, baseRadix]
		isPowerOfTwo := (baseRadix & (baseRadix - 1) == 0)
		mask := baseRadix - 1
		z := BigInteger.numberOfTrailingZeros(baseRadix)
		newMag := []
		for i, digit in mag {
			remainder := 0
			miniMag := []
			Loop(ex) {
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
	 * Convert a magnitude in base to base 2^32. Note that if base >= 2^31, this will overflow and not work.
	 * @param mag
	 * @param base
	 * @returns {Array}
	 */
	static normalizeMagnitudeBase(mag, base) {
		newMag := []
		magBaseA := mag.clone()
		if base == BigInteger.INT32
			return magBaseA
		if base == 0
			throw ValueError("You entered base 0, which doesn't exist. If you do think that it exists, please write me an email.")
		while (magBaseA.Length > 1 || magBaseA[1] != 0) {
			quotient := []
			remainder := 0
			for digit in magBaseA {
				dividend := remainder * base + digit
				q := dividend // BigInteger.INT32
				remainder := dividend & 0xFFFFFFFF ; Mod(dividend, BigInteger.INT32)
				quotient.push(q)
			}
			magBaseA := BigInteger.stripLeadingZeros(quotient)
			newMag.InsertAt(1, remainder)
		}
		return newMag
	}

	/**
	 * Convert a magnitude in base 2^32 to base. Note that if base >= 2^31, this will cause overflows and not work.
	 * @param mag
	 * @param base
	 * @returns {Array}
	 */
	static convertMagnitudeBase(mag, base) {
		thisMag := mag.clone()
		if base == BigInteger.INT32
			return thisMag
		if base == 0
			throw ValueError("You entered base 0, which doesn't exist. If you do think that it exists, please write me an email.")
		newMag := []
		if (isPowerOfTwo := (base & (base - 1) == 0)) { ; base is power of two
			mask := base - 1
			ex := Log(BigInteger.INT32)/Log(base)
			if (ex == Round(ex)) ; each digit can be fully decomposed into lower base digits safely
				return BigInteger.expandMagnitudeToRadix(mag, BigInteger.INT32, base)
			z := BigInteger.numberOfTrailingZeros(base)
		}
		while (thisMag.Length > 1 || thisMag[1] != 0) {
			quotient := []
			remainder := 0
			for digit in thisMag {
				dividend := (remainder << 32) + digit
				q := isPowerOfTwo ? dividend >> z : dividend // base
				remainder := isPowerOfTwo ? dividend & mask : Mod(dividend, base)
				quotient.push(q)
			}
			thisMag := BigInteger.stripLeadingZeros(quotient)
			newMag.InsertAt(1, remainder)
		}
		return newMag
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
		Loop len1 + len2 ; minimum is max(len1, len2), maximum is len1+len2 (in case of 0xFF * 0xFF = 0xFE01)
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

	/**
	 * Divides a magnitude in base 2**32 by a given digit
	 * @param mag
	 * @param divisorDigit An Integer > 0 and < 2**32
	 * @returns {Array}
	 */
	static divideMagnitudeByDigitAndRemainder(mag, divisorDigit) {
		result := []
		remainder := 0
		for digit in mag {
			quotient := (BigInteger.INT32 // divisorDigit) * remainder
			tmp := Mod(BigInteger.INT32, divisorDigit) * remainder + digit
			quotient := (quotient + tmp // divisorDigit) & BigInteger.INT_MASK
			remainder := Mod(tmp, divisorDigit) ; no mask because divisorDigit <= MASK
			result.push(quotient)
			; this is the arithmetically sound calculation, which fails due to overflows.
			; dividend := remainder << 32 + digit
			; quotient := dividend // divisorDigit
			; remainder := Mod(dividend, divisorDigit)
		}
		return [this.stripLeadingZeros(result), remainder]
	}

	/**
	 * Computes the greatest common divisor between digit1 and digit2
	 * @param digit1 Must be >0 and <2**32 - 1
	 * @param digit2 Must be >0 and <2**32 - 1
	 * @returns {Integer} The greatest common divisor
	 */
	static gcdDigit(digit1, digit2) {
		while digit1 > 0 && digit2 > 0 {
			if digit1 > digit2
				digit1 := Mod(digit1, digit2)
			else
				digit2 := Mod(digit2, digit1)
		}
		return digit1 || digit2
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

	; The Maximum Value of an exponent of ten that is smaller than an unsigned int
	static INT_BILLION := 10**9
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
		static BASE_ZERO => ValueError("Parameters was base 0, which doesn't exist. If you do think that it exists, please explain to me how.")
		static NOT_INTEGER[n] => ValueError("Received non-integer input: " (IsObject(n) ? Type(n) : n))
		static INVALID_RADIX[n] => ValueError("Invalid Radix: " (IsObject(n) ? Type(n) : n))
		static EXPONENT_OUT_OF_RANGE[n] => ValueError("Exponent out of range for supported values (>= 2**32): " (n is BigInteger ? n.toStringApprox() : n))
		static INCOMPATIBLE_RADIX[n, m] => ValueError("Cannot convert digits of Radix " n " to digits of radix " m "")
	}
}