/************************************************************************
 * @description A class to handle arbitrary precision Integers
 * @author cobracrystal
 * @date 2025/09/10
 * @version 0.2.5
***********************************************************************/

; NEXT, CREAT STATIC ALIASES FOR ALL OF THESE



/**
 * METHODS
 * @example
 * ; Construction and Properties
 * BigInteger.Prototype.__New(intOrString) ; IMPLEMENTED, FINAL
 * BigInteger.valueOf(intOrString) ; IMPLEMENTED, FINAL
 * BigInteger.fromMagnitude([digits*], 1) ; IMPLEMENTED, FINAL
 * BigInteger.Prototype.toString() ; IMPLEMENTED, NOT FINAL (Radix conversion remains somewhat inefficient)
 * BigInteger.Prototype.getSignum() ; IMPLEMENTED, FINAL
 * BigInteger.Prototype.getMagnitude() ; IMPLEMENTED, FINAL
 * BigInteger.Prototype.Length() ; IMPLEMENTED, FINAL
 * ; bitwise arithmetic
 * BigInteger.Prototype.and(anyInt) ; NOT IMPLEMENTED
 * BigInteger.Prototype.not() ; NOT IMPLEMENTED
 * BigInteger.Prototype.or(anyInt) ; NOT IMPLEMENTED
 * BigInteger.Prototype.xor(anyInt) ; NOT IMPLEMENTED
 * BigInteger.Prototype.andNot(anyInt) ; NOT IMPLEMENTED
 * BigInteger.Prototype.getBitLength() ; IMPLEMENTED, FINAL
 * BigInteger.Prototype.getLowestSetBit() ; IMPLEMENTED, FINAL
 * ; Comparison
 * BigInteger.Prototype.min(*) ; IMPLEMENTED, FINAL
 * BigInteger.Prototype.max(*) ; IMPLEMENTED, FINAL
 * BigInteger.Prototype.equals(anyInt) ; IMPLEMENTED, FINAL
 * BigInteger.Prototype.compareTo(anyInt) ; IMPLEMENTED, FINAL
 * ; Arithmetic
 * BigInteger.Prototype.abs() ; IMPLEMENTED, FINAL
 * BigInteger.Prototype.negate() ; IMPLEMENTED, FINAL
 * BigInteger.Prototype.add(anyInt) ; IMPLEMENTED, NOT FINAL (Inefficient)
 * BigInteger.Prototype.subtract(anyInt) ; IMPLEMENTED, NOT FINAL (Inefficient)
 * BigInteger.Prototype.multiply(anyInt) ; IMPLEMENTED, NOT FINAL (Inefficient)
 * BigInteger.Prototype.pow(anyInt) ; IMPLEMENTED, NOT FINAL (Inefficient)
 * BigInteger.Prototype.divide(anyInt) ; NOT IMPLEMENTED (incorrect implementation atm)
 * BigInteger.Prototype.divideAndRemainder(anyInt) ; NOT IMPLEMENTED
 * BigInteger.Prototype.sqrt() ; NOT IMPLEMENTED
 * BigInteger.Prototype.sqrtAndRemainder() ; NOT IMPLEMENTED
 * BigInteger.Prototype.mod(anyInt) ; NOT IMPLEMENTED
 * BigInteger.Prototype.gcd(anyInt) ; NOT IMPLEMENTED
 * ; Primes and Hashing
 * BigInteger.Prototype.isProbablePrime() ; NOT IMPLEMENTED
 * BigInteger.Prototype.nextProbablePrime() ; NOT IMPLEMENTED
 * BigInteger.Prototype.hashCode() ; NOT IMPLEMENTED
 */
class BigInteger {
	signum := 0 ; 0 (ZERO), -1 (NEGATIVE), 1 (POSITIVE)
	magnitude := []
	lowestSetBit := -1
	bitLength := -1

	/**
	 * Constructs a BigInteger given any integer-like input
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {BigInteger}
	 */
	__New(anyInt) {
		if (Type(anyInt) != "String")
			anyInt := String(anyInt)
		if !IsInteger(anyInt)
			throw ValueError("BigInteger received non-integer input: " anyInt)
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
			this.magnitude := [0]
			return
		}
		this.magnitude := BigInteger.magnitudeFromString(anyInt)
	}

	/**
	 * Returns a new BigInteger. Synonymous with creating a BigInteger instance
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {BigInteger}
	 */
	static valueOf(anyInt) => BigInteger(anyInt)

	/**
	 * Returns a String representing this.
	 * @param {Integer} radix. Must be 2 <= radix <= 36
	 * @returns {String} The number this BigInteger represents. May start with -. Never starts with +.
	 */
	toString(radix := 10) {
		if (this.signum == 0)
			return '0'
		if radix < 2 || radix > 36
			radix := 10
			
		str := this.signum < 0 ? '-' : ''
		
		; for higher efficiency, convert to maxComputableRadix and then convert each digit on their own?
		; for higher efficiency, detect radix == 2**n and use masks on each digit directly
		if radix == 10 {
			convertedMagnitude := BigInteger.magConvertBase(this.magnitude, BigInteger.INT32, BigInteger.INT_BILLION)
		} else {
			maxComputableRadix := 2**Floor(log(2**32)/log(radix))
			convertedMagnitude := BigInteger.magConvertBase(this.magnitude, BigInteger.INT32, radix)
		}
		if (radix == 10) {
			str .= convertedMagnitude[1]
			Loop(convertedMagnitude.Length - 1)
				str .= Format("{:09}", convertedMagnitude[A_Index + 1])
		}
		else if radix < 10
			for d in convertedMagnitude
				str .= d
		else
			for d in convertedMagnitude
				str .= Chr(d+55)
		return str
	}

	/**
	 * Adds the given Integer Representation to (this) and returns a new BigInteger representing the result.
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {BigInteger} The sum of the two BigIntegers
	 */
	add(anyInt) {
		if !(anyInt is BigInteger)
			anyInt := BigInteger(anyInt)
		if (this.signum == anyInt.signum) {
			magSum := BigInteger.addMagnitudes(this.magnitude, anyInt.magnitude)
			return BigInteger.fromMagnitude(magSum, this.signum)
		} else {
			comparison := BigInteger.compareMagnitudes(this.magnitude, anyInt.magnitude)
			if !comparison
				return BigInteger.ZERO
			minuend := comparison == 1 ? this : anyInt
			subtrahend := comparison == 1 ? anyInt : this
			return BigInteger.fromMagnitude(BigInteger.subtractMagnitudes(minuend.magnitude, subtrahend.magnitude), minuend.signum)
		}
	}

	/**
	 * Adds the given Integer Representation to (this) and returns a new BigInteger representing the result.
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {BigInteger} The sum of the two BigIntegers
	 */
	subtract(anyInt) {
		if !(anyInt is BigInteger)
			anyInt := BigInteger(anyInt)
		if (this.signum != anyInt.signum) {
			if !this.signum
				return anyInt.negate()
			if !anyInt.signum
				return BigInteger.fromMagnitude(this.magnitude, this.signum)
			return BigInteger.fromMagnitude(this.abs().add(anyInt.abs()).magnitude, this.signum)
		} else {
			comparison := BigInteger.compareMagnitudes(this.magnitude, anyInt.magnitude)
			if comparison == 0
				return BigInteger.ZERO
			minuend := comparison == 1 ? this : anyInt
			subtrahend := comparison == 1 ? anyInt : this
			magDiff := BigInteger.subtractMagnitudes(minuend.magnitude, subtrahend.magnitude)
			return BigInteger.fromMagnitude(magDiff, comparison == 1 ? this.signum : -this.signum)
		}
	}

	/**
	 * Multiplies the given Integer Representation with (this) and returns a new BigInteger representing the new result
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {BigInteger}
	 */
	multiply(anyInt) {
		if !(anyInt is BigInteger)
			anyInt := BigInteger(anyInt)
		magProduct := BigInteger.multiplyMagnitudes(this.magnitude, anyInt.magnitude)
		return BigInteger.fromMagnitude(magProduct, this.signum * anyInt.signum)
	}

	/**
	 * Divides (this) by the given Integer Representation and returns a new BigInteger representing the new result
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {BigInteger} The result of division, rounded down to the nearest BigInteger. 22/7 = 3
	 */
	divide(anyInt) {
		if !(anyInt is BigInteger)
			anyInt := BigInteger(anyInt)
		magQuotient := BigInteger.divideMagnitudes(this.magnitude, anyInt.magnitude)
		return BigInteger.fromMagnitude(magQuotient, this.signum * anyInt.signum)
	}

	divideAndRemainder(anyInt) => this
	and(anyInt) => this
	not() => this
	or(anyInt) => this
	andnot(anyInt) => this
	xor(anyInt) => this
	sqrt() => this
	sqrtAndRemainder() => this
	isProbablePrime() => false
	nextProbablePrime() => this
	hashCode() => 0
	

	/**
	 *
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {BigInteger}
	 */
	mod(anyInt) => this

	/**
	 *
	 * @param {Integer} exponent A positive integer to exponentiate [this] by.
	 * @returns {BigInteger}
	 */
	pow(exponent) {
		if exponent is BigInteger {
			if exponent.magnitude.Length > 1
				throw ValueError("Given exponent out of range for supported values (>= 2**32)")
			exponent := exponent.magnitude[1]
		}
		if exponent < 0
			throw ValueError("Negative Exponent")
		if exponent >= BigInteger.INT32
			throw ValueError("Given exponent out of range for supported values (>= 2**32)")
		if !this.signum
			return exponent == 0 ? BigInteger.ONE : BigInteger.ZERO
		workingExponent := exponent
		result := [1]
		magSquare := this.magnitude.Clone()
		while (workingExponent != 0) {
			if (workingExponent & 1)
				result := BigInteger.multiplyMagnitudes(result, magSquare)
			if ((workingExponent >>>= 1) != 0) ; cuts off right-most bit if it is 1
				magSquare := BigInteger.squareMagnitude(magSquare)
		}
		; MULTIPLY WITH EXPONENTIATED POWERS OF TWO THAT WE FACTORED OUT EARLIER
		return BigInteger.fromMagnitude(result, exponent & 1 ? this.signum : 1) ; lowest bit set -> odd exponent
	}
	
	
	/**
	 * Returns the absolute value of (this)
	 * @returns {BigInteger}
	 */
	abs() {
		if this.signum == 0
			return BigInteger(0)
		return BigInteger.fromMagnitude(this.magnitude, 1)
	}

	/**
	 * Returns 1 if (this) is larger than anyInt, -1 if it is smaller.
	 * Logically equivalent to the comparison (this > anyInt) ? 1 : this == anyInt ? 0 : -1
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {Integer} 1, 0, -1.
	 */
	compareTo(anyInt) {
		if !(anyInt is BigInteger)
			anyInt := BigInteger(anyInt)
		if this.signum > anyInt.signum
			return 1
		else if this.signum < anyInt.signum
			return -1
		magComp := BigInteger.compareMagnitudes(this.magnitude, anyInt.magnitude)
		return this.signum == 1 ? magComp : -magComp
	}
	
	/**
	 * Returns true if this and anyInt represent the same number, 0 otherwise.
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {Boolean} true if this == anyInt. false otherwise
	 */
	equals(anyInt) {
		if !(anyInt is BigInteger)
			anyInt := BigInteger(anyInt)
		flag := (this.signum == anyInt.signum && this.magnitude.Length == anyInt.magnitude.Length)
		if !flag
			return false
		for i, e in this.magnitude
			if anyInt.magnitude[i] != e
				return false
		return true
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
	
	/**
	 *
	 * @param {Integer | String | BigInteger} anyInt Any number of Integers, strings representing an integer or BigIntegers
	 * @returns {BigInteger}
	 */
	gcd(anyInt*) => 0
	
	/**
	 * Returns a new BigInteger with the signum flipped.
	 * @returns {BigInteger} The created BigInteger
	 */
	negate() => BigInteger.fromMagnitude(this.magnitude, -this.signum)
	
	/**
	 * Returns the signum of the number.
	 * @returns {BigInteger} Will be -1, 0, 1, corresponding to this < 0, this = 0, this > 0
	 */
	getSignum() => this.signum
	
	/**
	 * Returns the magnitude of the number.
	 * @returns {Array} Array of Integers that are base-2^32 digits representing the number
	 */
	getMagnitude() => this.magnitude.Clone()
	
	/**
	 * Returns the Length of the number in base 10. Use getBitLength for base 2.
	 * @returns {Integer} The Length of this BigInteger in base 10
	 */
	Length() => (this.magnitude.Length - 1) * 32 + StrLen(this.magnitude[1])

	/**
	 * Constructs a BigInteger given its base 2^32 digit representation and signum
	 * @param magnitude an array of integers < 2^32 in bigEndian notation
	 * @param signum The signum of the number. 1 for positive, -1 for negative, 0 for 0. If magnitude is an array containing only 0, signum will be automatically set to 0.
	 * @returns {BigInteger} The Constructed Value
	 */
	static fromMagnitude(magnitude, signum := 1) {
		obj := BigInteger(0) ; can't construct empty biginteger instance
		obj.signum := (magnitude.Length = 1 && magnitude[1] = 0) ? 0 : signum
		for e in magnitude
			if e >= BigInteger.INT32
				throw ValueError("Magnitude must be in Base 2**32")
		obj.magnitude := magnitude.Clone()
		return obj
	}
	
	/**
	 * Given a string of arbitrary length in base 10, returns an array of its digits in the specified base (default: 2^32)
	 * @param str A positive Integer String of arbitrary length. Must not contain -/+ at the beginning.
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
		return BigInteger.magConvertBase(magBaseB, BigInteger.INT_BILLION, BigInteger.INT32)
	}

	/**
	 * Convert a magnitude in base1 to base2. Note that if base1 * base2 >= 2**63, this will overflow and not work.
	 * @param magnitude
	 * @param base1
	 * @param base2
	 * @returns {Array}
	 */
	static magConvertBase(magnitude, base1, base2) {
		magBaseB := []
		mag := magnitude.clone()
		while (mag.Length > 1 || mag[1] != 0) {
			quotient := []
			remainder := 0
			for digit in mag {
				dividend := remainder * base1 + digit ; if base1 == 2**32, << 32 would be easier but means multiple separate functions for the same thing.
				q := dividend // base2
				remainder := Mod(dividend, base2)
				quotient.push(q)
			}
			mag := BigInteger.removeLeadingZeros(quotient)
			magBaseB.InsertAt(1, remainder)
		}
		return magBaseB
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
		return this.removeLeadingZeros(result)
	}

	static squareMagnitude(magnitude) {
		static KARATSUBA_SQUARE_THRESHOLD := 128
		len := magnitude.Length
		if len < KARATSUBA_SQUARE_THRESHOLD
			return simpleSquare()
		else
			return karatsubaSquare()

		simpleSquare() {
			return this.multiplyMagnitudes(magnitude, magnitude)
		}

		karatsubaSquare() {
			return [0]
		}
	}

	/**
	 * Divides one magnitude by another magnitude using Knuth's Algorithm D (long division).
	 * @param {Array} mag1 Dividend magnitude
	 * @param {Array} mag2 Divisor magnitude
	 * @returns {Array} Quotient magnitude
	 */
	static divideMagnitudes(mag1, mag2) {
		len2 := mag2.Length
		lenDiff := mag1.Length - len2
		if lenDiff < 0 ; mag2 > mag1
			return [0]
		d := 1
		if !(mag2[1] & 0x80000000) { ; highest bit is 0
			d := (BigInteger.INT32 // (mag2[1] + 1))
			mag2 := BigInteger.multiplyMagnitudes(mag2, [d])
			mag1 := BigInteger.multiplyMagnitudes(mag1, [d])
		}
		mag1.InsertAt(1, 0)
		q := []
		Loop lenDiff + 1 {
			j := A_Index
			u_j := mag1[j]
			u_j1 := mag1[j + 1]
			u_j2 := (j + 2 <= mag1.Length) ? mag1[j + 2] : 0
			v1 := mag2[1]
			v2 := (mag2.Length >= 2) ? mag2[2] : 0
			num := BigInteger.divideMagnitudeByDigit([u_j, u_j1], v1)
			qhat := num[1][1]
			rhat := num[2]
			while (qhat >= BigInteger.INT32 || ((qhat * v2) & BigInteger.LONG_MASK) > ((((rhat << 32) + u_j2) & BigInteger.LONG_MASK))) {
				qhat -= 1
				rhat := (rhat + v1) & BigInteger.LONG_MASK
				if rhat >= BigInteger.INT32
					break
			}
			; Multiply and subtract
			carry := 0
			borrow := 0
			Loop(mag2.Length) {
				i := A_Index
				p := ((mag2[-i] * qhat) & BigInteger.LONG_MASK) + carry
				carry := (p // BigInteger.INT32) & BigInteger.LONG_MASK
				p := p & BigInteger.INT_MASK
				sub := (mag1[j + len2 - i] - p - borrow) & BigInteger.LONG_MASK
				borrow := 0
				if sub < 0 {
					sub += BigInteger.INT32
					borrow := 1
				}
				mag1[j + len2 - i] := sub & BigInteger.INT_MASK
			}
			sub := mag1[j] - carry - borrow
			mag1[j] := sub
			if sub < 0 {
				sub += BigInteger.INT32
				; Correction: qhat--
				qhat -= 1
				carry := 0
				Loop (mag2.Length) {
					i := A_Index
					s := mag1[j + len2 - i] + mag2[-i] + carry
					carry := 0
					if s >= BigInteger.INT32 {
						s -= BigInteger.INT32
						carry := 1
					}
					mag1[j + len2 - i] := s
				}
				mag1[j] += carry
			}
			q.Push(qhat)
		}
		return BigInteger.removeLeadingZeros(q)
	}

	/**
	 * Divides a magnitude in base 2**32 by a given digit
	 * @param mag
	 * @param divisorDigit An Integer > 0 and < 2**32
	 * @returns {Array}
	 */
	static divideMagnitudeByDigit(mag, divisorDigit) {
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
		return [this.removeLeadingZeros(result), remainder]
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

	static removeLeadingZeros(magnitude) {
		while (magnitude.Length > 1 && magnitude[1] = 0)
 			magnitude.RemoveAt(1)
		return magnitude
	}

	/**
	 * Returns the index of the first one-bit in this BigInteger in little-endian
	 * @description The reason why the values
	 * @param magnitude
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
				len := this.magnitude.Length
				Loop(len) {
					i := len - A_Index + 1
					num := this.magnitude[i]
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
			bits := ((this.magnitude.Length - 1) << 5) + (64 - BigInteger.numberOfLeadingZeros(this.magnitude[1]))
			this.bitLength := bits
		}
		return bits
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
		n := ~n & (n-1)
		if (n == 0) 
			return -1
		return Floor(Log(n & -n) * ONE_OVER_LOG2)
	}

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
	static THOSUAND => BigInteger(1000)
	; BigInteger constant 2^32
	static TWO_POW_32 => BigInteger(this.INT32)

	; The Maximum Value of an Exponent of ten smaller than an unsigned int
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
}