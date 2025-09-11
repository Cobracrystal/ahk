/************************************************************************
 * @description A class to handle arbitrary precision Integers
 * @author cobracrystal
 * @date 2025/09/10
 * @version 0.1.0
***********************************************************************/

class BigInteger {
	_signum := 0 ; 0 (ZERO), -1 (NEGATIVE), 1 (POSITIVE) 
	magnitude := []

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
			this._signum := -1
			anyInt := SubStr(anyInt, 2)
		} else if (SubStr(anyInt, 1, 1) = "+") {
			this._signum := 1
			anyInt := SubStr(anyInt, 2)
		} else {
			this._signum := 1
		}
		if (anyInt == "0") {
			this._signum := 0
			this.magnitude := [0]
			return
		}
		this.magnitude := BigInteger.getMagnitudes(anyInt)
	}

	/**
	 * Returns a new BigInteger. Synonymous with directly calling BigInteger
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {BigInteger} 
	 */
	static valueOf(anyInt) => BigInteger(anyInt)

	/**
	 * Returns a String representing this.
	 * @returns {String} The number stored this BigInteger represents. May start with -. Never starts with +.
	 */
	toString() {
		if (this._signum == 0)
			return '0'
		str := '0'
		base := BigInteger.INT32
		for int in this.magnitude {
			str := BigInteger.MultiplyStringByInt(str, base)
			str := BigInteger.AddIntToString(str, int)
		}
		if (this._signum < 0)
			str := "-" . str
		return str
	}

	/**
	 * Adds the given Integer Representation to (this) and returns a new BigInteger representing the result.
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {BigInteger} The sum of the two BigIntegers
	 */
	Add(anyInt) {
		if !(anyInt is BigInteger)
			anyInt := BigInteger(anyInt)
		if (this.signum() == anyInt.signum()) {
			magSum := BigInteger.addMagnitudes(this.magnitude, anyInt.magnitude)
			return BigInteger.fromMagnitude(magSum, this.signum())
		} else {
			comparison := BigInteger.compareMagnitudes(this.magnitude, anyInt.magnitude)
			if !comparison
				return BigInteger.ZERO
			minuend := comparison == 1 ? this : anyInt
			subtrahend := comparison == 1 ? anyInt : this
			return BigInteger.fromMagnitude(BigInteger.subtractMagnitudes(minuend.magnitude, subtrahend.magnitude), minuend.signum())
		}
	}

	/**
	 * Adds the given Integer Representation to (this) and returns a new BigInteger representing the result.
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {BigInteger} The sum of the two BigIntegers
	 */
	Subtract(anyInt) {
		if !(anyInt is BigInteger)
			anyInt := BigInteger(anyInt)
		if (this.signum() != anyInt.signum()) {
			if !this.signum()
				return anyInt.negate()
			if !anyInt.signum()
				return BigInteger.fromMagnitude(this.magnitude, this.signum())
			return BigInteger.fromMagnitude(this.Abs().Add(anyInt.Abs()).magnitude, this.signum())
		} else {
			comparison := BigInteger.compareMagnitudes(this.magnitude, anyInt.magnitude)
			if comparison == 0
				return BigInteger.ZERO
			minuend := comparison == 1 ? this : anyInt
			subtrahend := comparison == 1 ? anyInt : this
			magDiff := BigInteger.subtractMagnitudes(minuend.magnitude, subtrahend.magnitude)
			return BigInteger.fromMagnitude(magDiff, comparison == 1 ? this.signum() : -this.signum())
		}
	}

	/**
	 * Multiplies the given Integer Representation with (this) and returns a new BigInteger representing the new result
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {BigInteger} 
	 */
	Multiply(anyInt) {
		if !(anyInt is BigInteger)
			anyInt := BigInteger(anyInt)
		magProduct := BigInteger.multiplyMagnitudes(this.magnitude, anyInt.magnitude)
		return BigInteger.fromMagnitude(magProduct, this.signum() * anyInt.signum())
	}

	/**
	 * 
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {BigInteger} 
	 */
	Divide(anyInt) => 0

	/**
	 * 
	 * @returns {BigInteger} 
	 */
	divideAndRemainder() => 0
	
	/**
	 * 
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {BigInteger} 
	 */
	Mod(anyInt) => 0

	/**
	 * 
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {BigInteger} 
	 */
	Pow(anyInt) => 0
	
	
	/**
	 * Returns the absolute value of (this) 
	 * @returns {BigInteger} 
	 */
	Abs() {
		if this.signum() == 0
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
		if this.signum() > anyInt.signum()
			return 1 
		else if this.signum() < anyInt.signum()
			return -1
		magComp := BigInteger.compareMagnitudes(this.magnitude, anyInt.magnitude)
		return this.signum() == 1 ? magComp : -magComp
	}
	
	/**
	 * Returns true if this and anyInt represent the same number, 0 otherwise.
	 * @param {Integer | String | BigInteger} anyInt An Integer, a string representing an integer or a BigInteger
	 * @returns {Boolean} true if this == anyInt. false otherwise 
	 */
	equals(anyInt) {
		if !(anyInt is BigInteger)
			anyInt := BigInteger(anyInt)
		flag := (this.signum() == anyInt.signum() && this.magnitude.Length == anyInt.magnitude.Length)
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
	Min(anyInt*) {
		for i, bigInt in anyInt
			if !(bigInt is BigInteger)
				anyInt[i] := BigInteger(bigInt)
		curMin := this
		for bigInt in curMin
			curMin := curMin.compareTo(bigInt) == 1 ? bigInt : curMin
		return curMin
	}

	/**
	 * Gets the highest value from (this) and given values.
	 * @param {Integer | String | BigInteger} anyInt Any number of Integers, strings representing an integer or BigIntegers
	 * @returns {BigInteger} 
	 */
	Max(anyInt*) {
		for i, bigInt in anyInt
			if !(bigInt is BigInteger)
				anyInt[i] := BigInteger(bigInt)
		curMax := this
		for bigInt in curMax
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
	negate() => BigInteger.fromMagnitude(this.magnitude, -this.signum())
	
	/**
	 * Returns the signum of the number. 
	 * @returns {BigInteger} Will be -1, 0, 1, corresponding to this < 0, this = 0, this > 0
	 */
	signum() => this._signum

	/**
	 * Constructs a BigInteger given its base 2^32 digit representation and signum
	 * @param magnitude an array of integers < 2^32 in bigEndian notation
	 * @param signum The signum of the number. 1 for positive, -1 for negative, 0 for 0. If magnitude is an array containing only 0, signum will be automatically set to 0.
	 * @returns {BigInteger} The Constructed Value 
	 */
	static fromMagnitude(magnitude, signum) {
		obj := BigInteger(0) ; can't construct empty biginteger instance
		obj._signum := (magnitude.Length = 1 && magnitude[1] = 0) ? 0 : signum
		obj.magnitude := magnitude.Clone()
		return obj
	}

	/**
	 * Given a string of arbitrary length, returns an array of its digits in the specified base (default: 2^32)
	 * @param str A positive Integer String of arbitrary length. Must not contain -/+ at the beginning.
	 * @returns {Array} The strings base-n digit representation as an Array
	 */
	static getMagnitudes(str, base := BigInteger.INT32) {
		mag := []
		while (str != "") { ; Divide string by base, get quotient and remainder
			q := ""
			carry := 0
			for char in StrSplit(str) {
				digit := Integer(char)
				carry := carry * 10 + digit
				qDigit := carry // base
				q .= qDigit
				carry := Mod(carry, base)
			}
			mag.InsertAt(1, carry)
			str := LTrim(q, '0')
		}
		return mag
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
			if diff >= 0
				carry := 0
			else {
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
		static INT_MASK := 0xFFFFFFFF
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
				result[-pos] := s & INT_MASK
				carry := (s >> 32) & INT_MASK ; since s might be >2**63-1, when shifting right the high bit is still interpreted as negative value. thus, we cut it off
			}
			result[-(i + j)] += carry ; write carry to the position left to the last written value
		}
		while (result.Length > 1 && result[1] == 0)
			result.RemoveAt(1)
		return result
	}


	/**
	 * Multiplies a string of arbitrary length by a positive integer
	 * @param str A positive Integer String of arbitrary length. Must not contain -/+ at the beginning.
	 * @param factor A positive integer.
	 * @returns {String} The product of the two values
	 */
	static MultiplyStringByInt(str, factor) {
		carry := 0
		result := ""
		c := StrLen(str)
		Loop(c) {
			i := c - A_Index + 1
			digit := Integer(SubStr(str, i, 1))
			total := digit * factor + carry
			result := Mod(total, 10) . result
			carry := total // 10
		}
		while (carry > 0) {
			result := Mod(carry, 10) . result
			carry := carry // 10
		}
		return result
	}

	/**
	 * Adds a positive integer to a string of arbitrary length
	 * @param str A positive Integer String of arbitrary length. Must not contain -/+ at the beginning.
	 * @param addend A positive integer.
	 * @returns {String} The sum of the two values
	 */
	static AddIntToString(str, addend) {
		carry := addend
		result := ""
		c := StrLen(str)
		Loop(c) {
			i := c - A_Index + 1
			digit := Integer(SubStr(str, i, 1))
			_sum := digit + carry
			result := Mod(_sum, 10) . result
			carry := _sum // 10
		}
		while (carry > 0) {
			result := Mod(carry, 10) . result
			carry := carry // 10
		}
		return result
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
	; BigInteger constant 2^32
	static TWO_POW_32 => BigInteger(this.INT32)

	; The Maximum Value of an unsigned int: 2^32
	static INT32 := 1 << 32
	; The Maximum Value of an ahk integer, or long long int: 2^63-1
	static MAX_INT_VALUE := (1 << 63) - 1
	; The number of bytes necessary to store an ahk integer, or long long int: 64
	static MAX_INT_SIZE := 64
}