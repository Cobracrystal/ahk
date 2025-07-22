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
	loop parse HayStack {

	}
}

strReverse(str) {
	result := ""
	for i, e in StrSplitUTF8(str)
		result := e . result
	return result
}

strRotate(str, offset := 0) {
	offset := Mod(offset, StrLen(str))
	return SubStr(str, -1 * offset + 1) . SubStr(str, 1, -1 * offset)
}

strMultiply(str, count) {
	s := ""
	VarSetStrCapacity(&s, count * StrLen(str))
	Loop(count)
		s .= str
	return s
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

/**
 * Makes a string literal for regex usage
 * @param str 
 * @returns {string} 
 */
RegExEscape(str) => "\Q" StrReplace(str, "\E", "\E\\E\Q") "\E"

/**
 * Replaces Strings in [string] from strings in [from] into strings in [to], in strict order of appearance in [from]
 * @param string String in which to replace the strings
 * @param from Array containing strings that are to be replaced in decreasing priority order
 * @param to Array containing strings that are the replacements for values in @from, in same order
 * @returns {string} 
 */
strRecursiveReplace(text, from, to) {
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

/**
 * Behaves exactly as strsplit except that if it is called without a delim and thus parses char by char, doesn't split unicode characters in two.
 * @param str 
 * @param {String} delim 
 * @param {String} omit 
 * @param {Integer} withDelim 
 * @returns {Array} 
 */
StrSplitUTF8(str, delim := "", omit := "", withDelim := false) {
	arr := []
	skip := false
	count := 0
	Loop Parse, str, delim, omit {
		char := A_LoopField
		if (skip) {
			skip := false
			continue
		}
		if (StrLen(A_LoopField) == 1 && Ord(A_LoopField) > 0xD7FF && Ord(A_LoopField) < 0xDC00) {
			arr.push(A_Loopfield . SubStr(str, count + 1, 1) . (withDelim ? SubStr(str, count+2, 1): ''))
			skip := true
			count += 2
			continue
		}
		count += StrLen(A_LoopField) + 1
		arr.push(A_LoopField . (withDelim ? SubStr(str, count, 1) : ''))
	}
	return arr
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

/**
 * Given a string str and a number of splits, returns an array containing all possible splits of str with [splits] partitions  
 * @param str the string to split
 * @param {Integer} splits amount of parts to split the string into
 * @returns {Array} 
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

clamp(n, minimum, maximum) => Max(min, Min(n, max))
isClamped(n, minimum, maximum) => (n <= maximum && n >= minimum)