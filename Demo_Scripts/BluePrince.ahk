#Requires AutoHotkey >=v2.0
#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\MathUtilities.ahk"
mainfunc()

mainfunc() {
	; input := A_Clipboard
	input := "PIGS SAND MAIL DATE HEAD CLAM PEAK HEAT JOYA WELL TOAD CARD WILL TAPE LEGS TREE ROAD MAID SLAB ROCK HAND VASE SAFE CLAY TOES"
	print(objToString(solveCores(input),,false))
}

solveCores(str) {
	arr := []
	str := StrReplace(str, "`n", " ")
	for i, e in StrSplitUTF8(str, " ")
		arr.push(objForEach(StrSplitUTF8(e), (char) => (ord(char) - ord("A") + 1)))
	solutions := []
	for i, e in arr {
		core := numericCore(e*)
		solutions.push(core)
	}
	return objForEach(solutions, (a) => (a.insertAt(1, Chr(a[1] + Ord("A") - 1)), a))
}

bestNumericCorePermutative(n,m,o,p) {
	values := permutations([n,m,o,p])
	solutions := []
	for i, e in values {
		f := numericCore(e*)
		if (f[2] != 0)
			solutions.push(f)
	}
	if solutions.Length == 0
		return 0
	sortedSolutions := objSortByKey(solutions, 1, "N")
	s := sortedSolutions[1].value
	if (s[1] >= 1000) {
		ncr := bestNumericCorePermutative(s[1]*)
		ncr.push(s*)
		return ncr
	}
	return s
}

bestNumericCore(n) {
	values := splitRecursive(n, 4)
	solutions := []
	for i, e in values {
		for j, f in e
			if strlen(f) != StrLen(Integer(f))
				continue 2
		f := numericCore(e*)
		if (f[2] != 0)
			solutions.push(f)
	}
	if solutions.Length == 0
		return 0
	sortedSolutions := objSortByKey(solutions, 1, "N")
	s := sortedSolutions[1].value
	if (s[1] >= 1000) {
		ncr := bestNumericCore(s[1])
		ncr.push(s*)
		return ncr
	}
	return s
}

numericCore(m,n,o,p) {
	static beStupid := false
	static calcStrings := Map(1, "{}-{}*{}/{}",	2, "{}-{}/{}*{}", 3, "{}*{}-{}/{}", 4, "{}*{}/{}-{}", 5, "{}/{}*{}-{}", 6, "{}/{}-{}*{}")
	m := Integer(m), n := Integer(n), o := Integer(o), p := Integer(p), arr := []
	a1 := p = 0 ? -1 : (m - n) * o / p
	a2 := o = 0 ? -1 : (m - n) / o * p
	a3 := p = 0 ? -1 : (m * n - o) / p
	a4 := o = 0 ? -1 : m * n / o - p
	a5 := n = 0 ? -1 : m / n * o - p
	a6 := n = 0 ? -1 : (m / n - o) * p
	arr := [a1, a2, a3, a4, a5, a6]
	sI := objContainsValue(arr,0,(e,*) => ((beStupid ? e : round(e, 14)) == round(e) && e > 0)) ; round(e,14) to avoid floating point issues
	if (sI == 0)
		return [0, 0]
	for i, e in arr
		if (e < arr[sI] && (beStupid ? e : round(e, 14)) == round(e) && e > 0)
			sI := i
	return [Integer(arr[sI]), Format(calcStrings[sI], m,n,o,p)]
}