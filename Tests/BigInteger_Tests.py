import random

NUM_ITERATIONS = 1000
NUM1_MIN = 1
NUM1_MAX = 2**1000
NUM2_MIN = 1
NUM2_MAX = 2**32 - 1
OUTPUT_FILE_DIGIT = "Tests\\tests_digit.txt"
OUTPUT_FILE_FULL = "Tests\\tests_full.txt"
OUTPUT_FILE_POW = "Tests\\tests_pow.txt"
numbers = []
for _ in range(NUM_ITERATIONS):
	len = random.randint(1, 1000)
	len2 = random.randint(1, 100)
	num1 = random.randint(1, 2**len)
	num2 = random.randint(1, 2**len)
	int32 = random.randint(1, 2**32 - 1)
	powBase = random.randint(1, 2**len2)
	powExp = random.randint(0, 100)
	numbers.append([num1, num2, int32, powBase, powExp])

resultsDigit = []
resultsFull = []
resultsPow = []
# BigInt | Digit
for num1, _, int32, _, _ in numbers:
	add = num1 + int32
	sub = num1 - int32
	mul = num1 * int32
	div = num1 // int32
	rem = num1 % int32
	resultsDigit.append(
		f"NUM1:{num1}, NUM2:{int32}, ADD:{add}, SUB:{sub}, MUL:{mul}, DIV:{div}, REM:{rem}"
	)

# BigInt | BigInt
for num1, num2, _, _, _ in numbers:
	add = num1 + num2
	sub = num1 - num2
	mul = num1 * num2
	div = num1 // num2
	rem = num1 % num2
	resultsFull.append(
		f"NUM1:{num1}, NUM2:{num2}, ADD:{add}, SUB:{sub}, MUL:{mul}, DIV:{div}, REM:{rem}"
	)

for _, _, _, powBase, powExp in numbers:
	pow_ = pow(powBase, powExp)
	resultsPow.append(
		f"NUM1:{powBase}, NUM2:{powExp}, POW:{pow_}"
	)

with open(OUTPUT_FILE_DIGIT, "w") as f:
	f.write('\n'.join(resultsDigit))

with open(OUTPUT_FILE_FULL, "w") as f:
	f.write('\n'.join(resultsFull))

with open(OUTPUT_FILE_POW, "w") as f:
	f.write('\n'.join(resultsPow))