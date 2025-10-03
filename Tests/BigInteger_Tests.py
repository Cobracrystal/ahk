import random
import math
NUM_ITERATIONS = 1000
NUM1_MIN = 1
NUM1_MAX = 2**1000
NUM2_MIN = 1
NUM2_MAX = 2**32 - 1
OUTPUT_FILE_FULL = "Tests\\tests_arithmetic.txt"
OUTPUT_FILE_POW = "Tests\\tests_powAndBit.txt"
OUTPUT_FILE_ROOT = "Tests\\tests_iroot.txt"
resultsFull = []
resultsPow = []
resultsRoot = []
def nthRoot(k, n):
    u, s = n, n+1
    while u < s:
        s = u
        t = (k-1) * s + n // pow(s, k-1)
        u = t // k
    return s

def appendBasicOperations(num1, num2):
	add = num1 + num2
	sub = num1 - num2
	mul = num1 * num2
	# python 6 // -4 => -2 because integer division floors. ahk 6 // -4 => -1
	div = abs(num1) // abs(num2) * (1 if ((num1 > 0) and (num2 > 0)) or ((num1 < 0) and (num2 < 0)) else -1)
	# python 6 % -4 => -2, ahk 2. python -6 % 4 => 2, ahk -6 % 4 => -2
	mod = abs(num1) % abs(num2) * (1 if num1 > 0 else -1)
	gcd = math.gcd(num1, num2)
	
	abs_ = abs(num1)
	negate_ = -1 * num1
	
	and_ = num1 & num2
	not_ = ~num1
	andNot = num1 & ~num2
	or_ = num1 | num2
	xor = num1 ^ num2
	equal = int(num1 == num2)
	compare = 0 if num1 == num2 else (1 if num1 > num2 else -1)
	resultsFull.append(
		f"a:{num1}, p1:{num2}, add:{add}, subtract:{sub}, multiply:{mul}, divide:{div}, mod:{mod}, gcd:{gcd}, abs:{abs_}, negate:{negate_}, and:{and_}, not:{not_}, andNot:{andNot}, or:{or_}, xor:{xor}, equals:{equal}, compare:{compare}"
	)

def appendBigSmallOperations(num1, num2):
	pow_ = num1**num2
	shiftL = num1 << num2
	shiftR = num1 >> num2
	mask = num1 & ((1 << num2) - 1)
	resultsPow.append(
		f"a:{num1}, p1:{num2}, pow:{pow_}, shiftLeft:{shiftL}, shiftRight:{shiftR}, maskBits:{mask}"
	)

def appendBigSmallPosOperations(num1, num2):
	sqrt = math.isqrt(num1)
	iroot = nthRoot(num2, num1)
	resultsRoot.append(
		f"a:{num1}, p1:{num2}, sqrt:{sqrt}, nthroot:{iroot}"
	)

# single-digit
for _ in range(NUM_ITERATIONS // 2):
	len = random.randint(1, 1000)
	num1 = random.randint(0, 2**len)
	num2 = random.randint(1, 2**32 - 1)
	appendBasicOperations(num1, num2)
# negative single-digit
for _ in range(NUM_ITERATIONS // 2):
	len = random.randint(1, 1000)
	num1 = random.randint(-2**len, 2**len)
	num2 = (random.randint(0,1) * 2 - 1) * random.randint(1, 2**32 - 1)
	appendBasicOperations(num1, num2)
# multi-digit
for _ in range(NUM_ITERATIONS // 2):
	num1 = random.randint(1, 2**random.randint(0, 1000))
	num2 = random.randint(1, 2**random.randint(0, 1000))
	appendBasicOperations(num1, num2)
# negative multi-digit
for _ in range(NUM_ITERATIONS // 2):
	len = random.randint(0, 1000)
	num1 = random.randint(2**len, 2**len)
	num2 = (random.randint(0,1) * 2 - 1) * random.randint(1, 2**random.randint(0, 1000))
	appendBasicOperations(num1, num2)
# pow, shifting, masking single digit
for _ in range(NUM_ITERATIONS // 2):
	num1 = random.randint(-2**32+1, 2**32-1)
	num2 = random.randint(0, 32)
	appendBigSmallOperations(num1, num2)
# pow, shifting, masking
for _ in range(NUM_ITERATIONS // 2):
	len2 = random.randint(0, 100)
	num1 = random.randint(-2**len2, 2**len2)
	num2 = random.randint(0, 32)
	appendBigSmallOperations(num1, num2)
# roots posit
for _ in range(NUM_ITERATIONS // 2):
	len2 = random.randint(0, 100)
	num1 = random.randint(1, 2**len2)
	num2 = random.randint(2, 32)
	appendBigSmallPosOperations(num1, num2)

with open(OUTPUT_FILE_FULL, "w") as f:
	f.write('\n'.join(resultsFull))

with open(OUTPUT_FILE_POW, "w") as f:
	f.write('\n'.join(resultsPow))

with open(OUTPUT_FILE_ROOT, "w") as f:
	f.write('\n'.join(resultsRoot))