/**
 * Given a function fn, returns the largest possible value in given range where fn returns true.
 * @param fn 
 * @param {Integer} lower 
 * @param {Integer} upper 
 */
binarySearch(fn, lower := 0, upper := 100000) {
	n := lower + (upper - lower)//2
	while(true) {
		if (Abs(lower - upper) <= 1)
			break
		if (fn(n))
			lower := n
		else
			upper := n
		n := lower + (upper - lower)//2
	}
	return n
}

/**
 * Given a string HayStack and a string SearchText, returns the amount of times SearchText is found within HayStack
 * @param HayStack 
 * @param SearchText 
 * @param {Integer} CaseSense 
 */
strCountStr(HayStack, SearchText, CaseSense := false) {
	StrReplace(HayStack, SearchText,,CaseSense, &count)
	return count
}

/**
 * Just like InStr, but SearchTexts may be an array of strings which are all searched for.
 * Other Notable difference: Occurence may be 0 to return array of ALL indices that were found
 * @param HayStack 
 * @param SearchTexts 
 * @param CaseSense 
 * @param {Integer} StartPos 
 * @param {Integer} Occurence 
 */
stringssInStr(HayStack, SearchTexts, CaseSense, StartPos := 1, Occurence := 1) {
	throw Error("Not implemented")
}

strReverse(str) {
	result := ""
	for i, e in StrSplitUTF8(str)
		result := e . result
	return result
}

strRotate(str, offset := 0) {
	offset := Mod(offset, StrLen(str))
	return SubStr(str, -offset + 1) . SubStr(str, 1, -offset)
}

strMultiply(str, count) {
	return StrReplace(Format("{:0" count "}",''), '0', str)
}

strFill(str, width, alignRight := true, char := A_Space) {
	s := strMultiply(char, width - StrLen(str))
	if alignRight
		return s . str
	return str . s
}

strDoPerChar(text, fn := (e => e . " ")) {
	result := ""
	for i, e in StrSplitUTF8(text)
		result .= fn(e)
	return RTrim(result)
}

strRemoveConsecutiveDuplicates(str, delim := "`n") {
	pos := 0
	str2 := ""
	loop parse str, delim, "" {
		pos += StrLen(A_LoopField) + 1
		if (lastField == A_LoopField)
			continue
		str2 .= A_LoopField . SubStr(str, pos, 1) 
		lastField := A_LoopField
	}
	return str2
}

replaceCharacters(text, replacer) {
	if !(replacer is Map || replacer is Func)
		return text
	result := ""
	isMap := replacer is Map
	for i, e in StrSplitUTF8(text) {
		if (isMap)
			result .= (replacer.Has(e) ? replacer[e] : e)
		else
			result .= replacer(e)
	}
	return result
}

strBuffer(str, encoding := 'UTF-8', fillValue?) {
	buf := Buffer(StrPut(str, encoding), fillValue?)
	StrPut(str, buf, encoding)
	return buf
}

strChangeEncoding(str, encodingFrom, encodingTo := 'UTF-16') {
	return StrGet(strBuffer(str, encodingFrom), encodingTo)
}

strCheckPossibleEncodings(str) {
	; utf8, utf16, ansi, western EU, west EU 2, japanese, simplified chinese, traditional chinese
	static encodingsToCheck := ['UTF-8', 'UTF-16', 'CP0', 'CP850', 'CP1252', 'CP932', 'CP936', 'CP950']
	arr := []
	for from in encodingsToCheck
		for to in encodingsToCheck
			if from != to
				arr.push({from: from, to: to, str: strChangeEncoding(str, from, to)})
	return arr
}

/**
 * Makes a string literal for regex usage
 * @param str 
 * @returns {string} 
 */
RegExEscape(str) => "\Q" StrReplace(str, "\E", "\E\\E\Q") "\E"

/**
 * StrReplace but from and to can be arrays containing multiple values which will be replaced in order, while guaranteeing that they will not replace themselves.
 * @param string String in which to replace the strings
 * @param from Array containing strings that are to be replaced in decreasing priority order
 * @param to Array containing strings that are the replacements for values in @from, in same order
 * @returns {string} 
 * @example StrMultiReplace("abcd", ["a", "b"], ["b", "r"]) => "rrcd" ; since a->b->r 
 * @example StrIndependentMultiReplace("abcd", ["a", "b"], ["b", "r"]) => "brcd" ; Replaced values independent of each other.
 */
StrIndependentMultiReplace(text, from, to) {
	return __recursiveReplaceMap(text, from, to)

	__recursiveReplaceMap(text, from, to, __index := 1) {
		replacedString := ""
		if (__index == from.Length)
			return StrReplace(text, from[__index], to[__index])
		strArr := StrSplit(text, from[__index])
		for i, e in strArr
			replacedString .= __recursiveReplaceMap(e, from, to, __index + 1) . (i == strArr.Length ? "" : to[__index])
		return replacedString
	}
}

StrMultiReplace(text, from, to, caseSense := true, &outputvarCount := 0, limit := -1) {
	Loop(from.Length) {
		text := StrReplace(text, from[A_Index], to[A_Index], caseSense, &repl, limit)
		limit -= repl
		outputvarCount += repl
	}
	return text
}

strSimilarity(s1, s2) => 1 - strDistanceNormalizedLevenshtein(s1, s2)

strDistanceNormalizedLevenshtein(s1, s2) {
	len := Max(StrLen(s1), StrLen(s2))
	if !len
		return 0
	return strDistanceLevenshtein(s1, s2) / len
}

strDistanceLevenshtein(s1, s2, limit := 2**31-1) {
	if (s1 == s2)
		return 0
	len1 := StrLen(s1)
	len2 := StrLen(s2)
	if !(len1)
		return len2
	if !(len2)
		return len1
	v0 := [], v1 := []
	v0.Capacity := v0.Length := v1.Capacity := v1.Length := len2+1
	Loop(len2+1)
		v0[A_Index] := A_Index-1
	Loop(len1) {
		v1[1] := minv1 := i := A_Index
		Loop(len2) {
			cost := SubStr(s1, i, 1) != SubStr(s2, A_Index, 1)
			v1[A_Index + 1] := Min(v1[A_Index] + 1, v0[A_Index+1] + 1, v0[A_Index] + cost) ; min of ins, del, sub
			minv1 := Min(minv1, v1[A_Index+1])
		}
		if (minv1 >= limit)
			return limit
		temp := v0
		v0 := v1
		v1 := temp
	}
	return v0.Pop()
}

strDistanceWeightedLevenshtein(s1, s2, limit := 1e+307, insertionCost := (char) => 1.0, deletionCost := (char) => 1.0, substitutionCost := (char1, char2) => 1.0) {
	if (s1 == s2)
		return 0
	len1 := StrLen(s1)
	len2 := StrLen(s2)
	if !(len1)
		return len2
	if !(len2)
		return len1
	v0 := [], v1 := []
	v0.Capacity := v0.Length := v1.Capacity := v1.Length := len2+1
	v0[1] := 0
	Loop(len2)
		v0[A_Index + 1] := v0[A_Index] + insertionCost(SubStr(s2, A_Index, 1))
	Loop(len1) {
		i := A_Index
		char1 := SubStr(s1, i, 1)
		costDel := deletionCost(char1)
		v1[1] := minv1 := v0[1] + costDel
		Loop(len2) {
			char2 := SubStr(s2, A_Index, 1)
			costSub := char1 != char2 ? substitutionCost(char1, char2) : 0
			costIns := insertionCost(char2)
			v1[A_Index+1] := Min(v1[A_Index] + costIns, v0[A_Index+1] + costDel, v0[A_Index] + costSub)
			minv1 := Min(minv1, v1[A_Index+1])
		}
		if (minv1 >= limit)
			return limit
		temp := v0
		v0 := v1
		v1 := temp
	}
	return v0.Pop()
}

strDistanceSIFT(s1, s2, maxOffset := 5, maxDistance?) {
	if (s1 == s2)
		return 0
	tl1 := StrLen(s1)
	tl2 := StrLen(s2)
	if !(tl1)
		return tl2
	if !(tl2)
		return tl1
	t1 := StrSplit(s1)
	t2 := StrSplit(s2)
	c1 := c2 := 1 ; Cursors
	lcss := 0 ; Largest common subsequence
	lcs := 0 ; Largest common substring
	trans := 0 ; Number of transpositions
	offsets := [] ; Offset pair array

	while (c1 <= tl1 && c2 <= tl2) {
		if t1[c1] == t2[c2] {
			lcs += 1
			while(offsets.Length) {
				if (c1 <= offsets[1][1] || c2 <= offsets[1][2]) {
					trans++
					break
				} else {
					offsets.RemoveAt(1)
				}
			}
			offsets.push([c1, c2])
		} else {
			lcss += lcs
			lcs := 0
			if(c1 !== c2) {
				c1 := c2 := Min(c1, c2)
			}
			Loop(maxOffset) {
				i := A_Index - 1
				if(c1 + i <= tl1 && t1[c1+i] == t2[c2]) {
					c1 += i - 1
					c2 -= 1
					break
				}
				if(c2 + i <= tl2 && t1[c1] == t2[c2+i]) {
					c1 -= 1
					c2 += i - 1
					break
				}
			}
		}
		c1++
		c2++

		if(IsSet(maxDistance)) {
			distance := Max(c1, c2) - 1 - (lcss - trans / 2)
			if(distance >= maxDistance)
				return Round(distance)
		}
	}
	lcss += lcs
	return Round(Max(tl1, tl2) - (lcss - trans/2))
}

/**
 * This is ONLY appropriate where the difference in strings is one mismatched run of addition (and even then pretty bad)
 * @param s1 
 * @param s2 
 * @param {Integer} maxOffset 
 * @returns {Array | Primitive} 
 */
strDifferenceSIFT(s1, s2, maxOffset := 5) {
	if (s1 == s2)
		return []
	tl1 := StrLen(s1)
	tl2 := StrLen(s2)
	t1 := StrSplit(s1)
	t2 := StrSplit(s2)
	c1 := c2 := 1 ; Cursors
	lcs := 0 ; Largest common substring
	lcss := 0 ; Largest common subsequence
	trans := 0 ; Number of transpositions
	offsets := [] ; Offset pair array

	mismatches := []
	mismatchStart := mismatchStart1 := mismatchStart2 := -1
	while (c1 <= tl1 && c2 <= tl2) {
		if t1[c1] == t2[c2] {
			lcs += 1
			if (mismatchStart != -1) {
				m1len := c1 - mismatchStart1
				m2len := c2 - mismatchStart2
				if (m1len >= 0 && m2len >= 0)
					mismatches.push({
						index1: mismatchStart1,
						length1: m1len,
						str1: SubStr(s1, mismatchStart1, m1len),
						index2: mismatchStart2,
						length2: m2len,
						str2: SubStr(s2, mismatchStart2, m2len),
					})
				mismatchStart := mismatchStart1 := mismatchStart2 := -1
			}
			while(offsets.Length) {
				if (c1 <= offsets[1][1] || c2 <= offsets[1][2]) {
					trans++
					break
				} else {
					offsets.RemoveAt(1)
				}
			}
			offsets.push([c1, c2])
		} else {
			if (mismatchStart == -1) {
				mismatchStart := Max(c1, c2)
				mismatchStart1 := c1
				mismatchStart2 := c2
			}
			lcss += lcs
			lcs := 0
			if(c1 !== c2) {
				c1 := c2 := Min(c1, c2)
			}
			Loop(maxOffset) {
				i := A_Index - 1
				if(c1 + i <= tl1 && t1[c1+i] == t2[c2]) {
					c1 += i - 1
					c2 -= 1
					break
				}
				if(c2 + i <= tl2 && t1[c1] == t2[c2+i]) {
					c1 -= 1
					c2 += i - 1
					break
				}
			}
		}
		c1++
		c2++

		if(IsSet(maxDistance)) {
			distance := Max(c1, c2) - 1 - (lcss - trans /2)
			if(distance >= maxDistance) 
				return Round(distance)
		}
	}
	if (mismatchStart >= 0) {
		m1len := c1 - mismatchStart1
		m2len := c2 - mismatchStart2
		mismatches.push({
			index1: mismatchStart1,
			length1: m1len,
			str1: SubStr(s1, mismatchStart1, m1len),
			index2: mismatchStart2,
			length2: m2len,
			str2: SubStr(s2, mismatchStart2, m2len),
		})
	}
	if (c1 < tl1 || c2 < tl2) {
		mismatches.push({
			index1: c1,
			length1: Max(tl1 - c1 + 1),
			str1: SubStr(s1, c1),
			index2: c2,
			length2: Max(0, tl2 - c2 + 1),
			str2: SubStr(s2, c2),
		})
	}
	return mismatches
}

strLimitToDiffs(str1, str2, maxOffset := 5, radius := 10, fillChar := "#", separator := " ... ") {
	s1 := s2 := ""
	diffs := strDifferenceSIFT(str1, str2, maxOffset)
	for i, diff in diffs {
		c1 := strGetContext(str1, diff.index1, diff.index1 + diff.length1, radius, &rs1, &re1)
		c2 := strGetContext(str2, diff.index2, diff.index2 + diff.length2, radius, &rs2, &re2)
		if (i == 1) {
			s1 := (rs1 ? "" : LTrim(separator, " `t`r`n"))
			s2 := (rs2 ? "" : LTrim(separator, " `t`r`n"))
		}
		if (diff.length1 > diff.length2) {
			s1 .= c1[1] strfill(diff.str1, diff.length1,, fillChar) c1[2] separator
			s2 .= c2[1] strfill(diff.str2, diff.length1,, fillChar) c2[2] separator
		} else {
			s1 .= c1[1] strfill(diff.str1, diff.length2,, fillChar) c1[2] separator
			s2 .= c2[1] strfill(diff.str2, diff.length2,, fillChar) c2[2] separator
		}
	}
	s1 := re1 ? SubStr(s1, 1, -StrLen(separator)) : RTrim(s1, " `t`r`n")
	s2 := re2 ? SubStr(s2, 1, -StrLen(separator)) : RTrim(s2, " `t`r`n")
	return [s1, s2]
}

strGetContext(str, startIndex, endIndex := startIndex, radius := 15, &reachedStart?, &reachedEnd?) {
	befLen := Min(radius, startIndex - 1)
	befStart := Max(1, startIndex - radius)
	afterLen := Min(radius, StrLen(str) - endIndex + 1)
	afterStart := endIndex
	reachedStart := (befStart == 1)
	reachedEnd := (afterLen != radius)
	return [SubStr(str, befStart, befLen), SubStr(str, afterStart, afterLen)]
}

/**
 * Behaves exactly as strsplit without optional parameters except that it doesn't split unicode characters in two.
 * @param str 
 * @returns {Array} 
 */
StrSplitUTF8(str) {
	arr := []
	skip := false
	pos := 1
	Loop Parse str {
		if (skip) {
			skip := false
			continue
		}
		if (isClamped(Ord(A_LoopField), 0xD7FF, 0xDC00)) {
			arr.push(A_LoopField . SubStr(str, pos + 1, 1))
			skip := true
			pos += 2
			continue
		}
		arr.push(A_LoopField)
		pos++
	}
	return arr
}

StrLenUTF8(str) {
	RegExReplace(str, "s).", "", &i) ; yes this is actually the fastest way to do so.
	return i
}

strMaxCharsPerLine(str, maxCharsPerLine) {
	nStr := ""
	loops := strCountStr(str, '`n') + 1
	Loop Parse str, "`n", "`r" {
		line := A_LoopField
		fWidthLines := ""
		fWidthLine := ""
		pos := 0
		Loop Parse line, " `t" {
			word := A_LoopField
			pos += StrLen(word) + 1
			wLen := StrLen(word)
			if (StrLen(fWidthLine) + wLen <= maxCharsPerLine)
				fWidthLine .= word . SubStr(line, pos, 1)
			else {
				if (fWidthLine != "")
					fWidthLines .= fWidthLine '`n'
				if (wLen <= maxCharsPerLine)
					fWidthLine := word . SubStr(line, pos, 1)
				else {
					Loop(iters := wLen//maxCharsPerLine)
						fWidthLines .= SubStr(word, (A_Index - 1) * maxCharsPerLine + 1, maxCharsPerLine) . "`n"
					if (wLen > iters * maxCharsPerLine)
						fWidthLine := SubStr(word, iters * maxCharsPerLine + 1)
				}
			}
		}
		fWidthLines := ( fWidthLine == "" ? SubStr(fWidthLines, 1, StrLen(fWidthLines) - 1) : fWidthLines . fWidthLine)
		nStr .= fWidthLines . (A_Index == loops ? '' : '`n')
	}
	return nStr
}

strGetSplitLen(str, delim, omit := '') {
	lens := []
	Loop Parse, str, delim, omit
		lens.push(StrLen(A_LoopField))
	return lens
}

/**
 * Given a string str and a number of splits, returns an array containing all possible splits of str with [splits] partitions  
 * @param str the string to split
 * @param {Integer} splits amount of parts to split the string into
 * @returns {Array} 
 * @example ?????
 */
strSplitRecursive(str, splits := StrLen(str)) {
	if (splits == 1)
		return [[str]]
	else if (StrLen(str) == splits)
		return [StrSplit(str)]
	arr := []
	Loop(StrLen(str) - splits + 1) {
		cur := SubStr(str, 1, A_Index)
		a := strSplitRecursive(SubStr(str, A_Index + 1), splits - 1)
		for i, e in a
			a[i].insertat(1, cur)
		arr.push(a*)
	}
	return arr
}

strSplitOnWhiteSpace(str) => StrSplit(str, [' ', '`t', '`n', '`r'], " `t`r`n")
strSplitOnSpace(str) => StrSplit(str, " ")
strSplitOnNewLine(str, omitCarriageReturn := true) => StrSplit(str, '`n', omitCarriageReturn ? '`r' : unset)

class Uri {
; stolen from https://github.com/ahkscript/libcrypt.ahk/blob/master/src/URI.ahk
	static encode(str) { ; keep ":/;?@,&=+$#."
		return this.LC_UriEncode(str)
	}

	static decode(str) {
		return this.LC_UriDecode(str)
	}

	static LC_UriEncode(uri, RE := "[0-9A-Za-z]") {
		var := strBuffer(uri)
		while(code := NumGet(Var, A_Index - 1, "UChar"))
			res .= ((char := Chr(Code)) ~= RE ) ? char : Format("%{:02X}", Code)
		return res
	}

	static LC_UriDecode(uri) {
		pos := 1
		while(pos := RegExMatch(uri, "i)(%[\da-f]{2})+", &code, pos)) {
			var := Buffer(StrLen(code[0]) // 3, 0)
			Code := SubStr(code[0], 2)
			Loop Parse, code, '%'
				NumPut("UChar", "0x" A_LoopField, var, A_Index - 1)
			decoded := StrGet(var, "UTF-8")
			uri := SubStr(uri, 1, pos - 1) . decoded . SubStr(uri, pos+StrLen(Code)+1)
			pos += StrLen(decoded)+1
		}
		return uri
	}
}

/**
 * Rounds a number to its nth place while also trimming 0, . and transforming to integer if needed
 * @param num 
 * @param {Integer} precision 
 * @returns {Integer | Number} 
 */
numRoundProper(num, precision := 12) {
	if (!IsNumber(num))
		return num
	if (IsInteger(num) || Round(num) == num)
		return Integer(num)
	else
		return Number(RTrim(Round(num, precision), "0."))
}

intMax() {
	return 2**63-1
}

clamp(n, minimum, maximum) => Max(minimum, Min(n, maximum))
isClamped(n, minimum, maximum) => (n <= maximum && n >= minimum)
hex(n) => Format("0x{:X}", n)
oct(n) => Format("{:o}", n)
