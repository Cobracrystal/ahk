; LibrariesV2/test_BigInteger.ahk

#Include "%A_LineFile%\..\..\LibrariesV2"
#Include BasicUtilities.ahk
#Include MathUtilities.ahk
#Include BigInteger.ahk
#SingleInstance Force

class BigIntegerTests {
	class Construction {

	}

	class BitwiseRandom {

		loops := 1000

		not() {
			Loop(this.loops) {
				; random 64-bit nums
				a := randomNBitInt(63)
				a1 := BigInteger(a).not()
				a2 := ~a
				if (a1.tostring() != a2)
					throw(Error("Expected " a2 ", got " a1.toString()))
			}
		}

		and() {
			Loop(this.loops) {
				a := randomNBitInt(63)
				b := randomNBitInt(63)
				r := BigInteger(a).and(b)
				r2 := a & b
				if (r.tostring() != r2)
					throw(Error("Expected " r2 ", got " r.toString()))
			}
		}

		or() {
			Loop(this.loops) {
				a := randomNBitInt(63)
				b := randomNBitInt(63)
				r := BigInteger(a).or(b)
				r2 := a | b
				if (r.tostring() != r2)
					throw(Error("Expected " r2 ", got " r.toString()))
			}
		}

		andNot() {
			Loop(this.loops) {
				a := randomNBitInt(63)
				b := randomNBitInt(63)
				r := BigInteger(a).andNot(b)
				r2 := a & ~b
				if (r.tostring() != r2)
					throw(Error("Expected " r2 ", got " r.toString()))
			}
		}

		xor() {
			Loop(this.loops) {
				a := randomNBitInt(63)
				b := randomNBitInt(63)
				r := BigInteger(a).xor(b)
				r2 := a ^ b
				if (r.tostring() != r2)
					throw(Error("Expected " r2 ", got " r.toString()))
			}
		}
	}

	class Arithmetic {
		class SingleMagnitude {

		}

		class FromFiles {

		}
	}

	class Comparison {
		equals() {
			
		}

		compareTo() {
			
		}
	}
}

randomNBitInt(n) {
	return (Random(0,1)*2-1) * Random(0, 2**Random(0,n))
}

randomNonZeroNBitInt(n) {
	return (Random(0,1)*2-1) * Random(1, 2**Random(0,n))
}

randomNonZeroNBitUInt(n) {
	return Random(1, 2**Random(0,n))
}

randomNBitUInt(n) {
	return Random(0, 2**Random(0,n))
}