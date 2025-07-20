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


class unicodeData {
	
	; https://unicode-org.github.io/icu-docs/apidoc/released/icu4c/uchar_8h.html#a46c049f7988a44e14d221f68e2e63db2

	; Alias of lookup
	static charFromName(name, nameChoice := this.NameChoice.U_UNICODE_CHAR_NAME, default?) => this.lookup(name, nameChoice, default?)
	; Look up character by name. If a character with the given name is found, return the corresponding character. If not found, KeyError is raised. 
	static lookup(name, nameChoice := this.NameChoice.U_UNICODE_CHAR_NAME, default?) {
		this.verifyVersion()
		errorCode := 0
		nameBuf := Buffer(StrPut(name, "UTF-8"))
		StrPut(name, nameBuf, "UTF-8")
		codePoint := DllCall("icuuc\u_charFromName", "int", nameChoice, "Ptr", nameBuf, "int*", &errorCode)
		switch errorCode {
			case this.UErrorCode.U_ZERO_ERROR:
				return Chr(codePoint)
			case this.UErrorCode.U_ILLEGAL_CHAR_FOUND:
				if (IsSet(default))
					return default
				throw ValueError("Invalid name given: " name)
			default:
				throw(OSError("u_charName returned Error " errorCode))
		}
		if (errorCode)
			throw Error("u_charFromName returned Error " errorCode)
	}

	; Returns the name assigned to the character char as a string.
	static charName(char, nameChoice := this.NameChoice.U_UNICODE_CHAR_NAME) {
		this.verifyVersion()
		name := Buffer(512)
		errorCode := 0
		length := DllCall("icuuc\u_charName", "uchar", Ord(char), "int", nameChoice, "Ptr", name, "int", name.Size, "int*", &errorCode)
		switch errorCode {
			case this.UErrorCode.U_ZERO_ERROR:
				return StrGet(name, length, "UTF-8")
			default:
				throw(OSError("u_charName returned Error " errorCode))
		}
	}

	; Returns the general category (UCharCategory) value for the code point
	static charType(char) {
		this.verifyVersion()
		charType := DllCall("icuuc\u_charType", "uchar", Ord(char))
		return charType
	}


	; Returns the decimal value assigned to the character char as integer. If no such value is defined, default is returned, or, if not given, ValueError is raised. 
	static decimal(char, default?) => 0


	; Returns the digit value assigned to the character char as integer. If no such value is defined, default is returned, or, if not given, ValueError is raised. 
	static digit(char, default?) => 0


	; Returns the numeric value assigned to the character char as float. If no such value is defined, default is returned, or, if not given, ValueError is raised. 
	static numeric(char, default?) => 0


	; Returns the general category assigned to the character char as string. 
	static category(char) => 0


	; Returns the bidirectional class assigned to the character char as string. If no such value is defined, an empty string is returned. 
	static bidirectional(char) => 0


	; Returns the canonical combining class assigned to the character char as integer. Returns 0 if no combining class is defined. 
	static combining(char) => 0


	; Returns the east asian width assigned to the character char as string. 
	static east_asian_width(char) => 0


	; Returns the mirrored property assigned to the character char as integer. Returns 1 if the character has been identified as a “mirrored” character in bidirectional text, 0 otherwise. 
	static mirrored(char) {
		this.verifyVersion()
		codePoint := DllCall("icuuc\u_charMirror", "uchar", Ord(char))
		return Chr(codePoint)
	}

	static pairedBracket(char) {
		this.verifyVersion()
		codePoint := DllCall("icuuc\u_getBidiPairedBracket", "uchar", Ord(char))
		return Chr(codePoint)
	}

	static enumCharNames(start, limit, fn, context, nameChoice) => 0

	; Returns the character decomposition mapping assigned to the character char as string. An empty string is returned in case no such mapping is defined. 
	static decomposition(char) => 0


	; Return the normal form form for the Unicode string unistr. Valid values for form are "C", "KC", "D", and "KD". 
	; The Unicode standard defines various normalization forms of a Unicode string, based on the definition of canonical equivalence and compatibility equivalence. In Unicode, several characters can be expressed in various way. For example, the character U+00C7 (LATIN CAPITAL LETTER C WITH CEDILLA) can also be expressed as the sequence U+0043 (LATIN CAPITAL LETTER C) U+0327 (COMBINING CEDILLA). 
	; For each character, there are two normal forms: normal form C and normal form D. Normal form D (NFD) is also known as canonical decomposition, and translates each character into its decomposed form. Normal form C (NFC) first applies a canonical decomposition, then composes pre-combined characters again. 
	; In addition to these two forms, there are two additional normal forms based on compatibility equivalence. In Unicode, certain characters are supported which normally would be unified with other characters. For example, U+2160 (ROMAN NUMERAL ONE) is really the same thing as U+0049 (LATIN CAPITAL LETTER I). However, it is supported in Unicode for compatibility with existing character sets (e.g. gb2312). 
	; The normal form KD (NFKD) will apply the compatibility decomposition, i.e. replace all compatibility characters with their equivalents. The normal form KC (NFKC) first applies the compatibility decomposition, followed by the canonical composition. 
	; Even if two unicode strings are normalized and look the same to a human reader, if one has combining characters and the other doesn’t, they may not compare equal. 
	static normalize(normForm, unistr) {
		normForm := this._getNormalizationFormFromStr(normForm)
		cwDstLength := DllCall("NormalizeString", "uint", normForm, "Str", unistr, "int", -1, "Ptr", 0, "int", 0)
		VarSetStrCapacity(&lpDstString, cwDstLength)
		writtenWChars := DllCall("NormalizeString", "int", normForm, "Str", unistr, "int", -1, "Str", &lpDstString, "int", cwDstLength)
		return lpDstString
	}


	; Return whether the Unicode string unistr is in the normal form form. Valid values for form are "C", "KC", "D", and "KD". 
	static is_normalized(normForm, uniStr) {
		normForm := this._getNormalizationFormFromStr(normForm)
		lpString := Buffer(StrPut(uniStr))
		cwLength := StrLen(uniStr)
		StrPut(uniStr, lpString)
		return DllCall("IsNormalizedString", "int", normForm, "Ptr", lpString, "int",  cwLength)
	}


	; The version of the Unicode database used in this module. 
	static unidata_version => 0

	static verifyVersion() {
		if !(VerCompare(A_OSVersion, "10.0.16299"))
			throw(OSError("This function only works in windows build >= 1709"))
	}

	static _getNormalizationFormFromStr(uniStr) {
		switch unistr {
			case "C":
				return this.Normalization.NFC
			case "D":
				return this.Normalization.NFD
			case "KC":
				return this.Normalization.NFKC
			case "KD":
				return this.Normalization.NFKD
			default:
				throw ValueError("Invalid Normalization String given: " uniStr)
		}
	}

	static Normalization => {
		NFC: 0x1, ; Unicode normalization form C, canonical composition. Transforms each decomposed grouping, consisting of a base character plus combining characters, to the canonical precomposed equivalent. For example, A + ¨ becomes Ä.
		NFD: 0x2, ; Unicode normalization form D, canonical decomposition. Transforms each precomposed character to its canonical decomposed equivalent. For example, Ä becomes A + ¨.
		NFKC: 0x5, ; Unicode normalization form KC, compatibility composition. Transforms each base plus combining characters to the canonical precomposed equivalent and all compatibility characters to their equivalents. For example, the ligature ﬁ becomes f + i; similarly, A + ¨ + ﬁ + n becomes Ä + f + i + n.
		NFKD: 0x6 ; Unicode normalization form KD, compatibility decomposition. Transforms each precomposed character to its canonical decomposed equivalent and all compatibility characters to their equivalents. For example, Ä + ﬁ + n becomes A + ¨ + f + i + n.
	}

	static NameChoice => {
		U_UNICODE_CHAR_NAME: 0x0,
		U_UNICODE_10_CHAR_NAME: 0x1,
		U_EXTENDED_CHAR_NAME: 0x2,
		U_CHAR_NAME_ALIAS: 0x3,
		U_CHAR_NAME_CHOICE_COUNT: 0x4
	}

	static UErrorCode => {
		U_USING_FALLBACK_WARNING:	-128,
		U_ERROR_WARNING_START:	-128,
		U_USING_DEFAULT_WARNING:	-127,
		U_SAFECLONE_ALLOCATED_WARNING:	-126,
		U_STATE_OLD_WARNING:	-125,
		U_STRING_NOT_TERMINATED_WARNING:	-124,
		U_SORT_KEY_TOO_SHORT_WARNING:	-123,
		U_AMBIGUOUS_ALIAS_WARNING:	-122,
		U_DIFFERENT_UCA_VERSION:	-121,
		U_PLUGIN_CHANGED_LEVEL_WARNING:	-120,
		U_ZERO_ERROR:	0,
		U_ILLEGAL_ARGUMENT_ERROR:	1,
		U_MISSING_RESOURCE_ERROR:	2,
		U_INVALID_FORMAT_ERROR:	3,
		U_FILE_ACCESS_ERROR:	4,
		U_INTERNAL_PROGRAM_ERROR:	5,
		U_MESSAGE_PARSE_ERROR:	6,
		U_MEMORY_ALLOCATION_ERROR:	7,
		U_INDEX_OUTOFBOUNDS_ERROR:	8,
		U_PARSE_ERROR:	9,
		U_INVALID_CHAR_FOUND:	10,
		U_TRUNCATED_CHAR_FOUND:	11,
		U_ILLEGAL_CHAR_FOUND:	12,
		U_INVALID_TABLE_FORMAT:	13,
		U_INVALID_TABLE_FILE:	14,
		U_BUFFER_OVERFLOW_ERROR:	15,
		U_UNSUPPORTED_ERROR:	16,
		U_RESOURCE_TYPE_MISMATCH:	17,
		U_ILLEGAL_ESCAPE_SEQUENCE:	18,
		U_UNSUPPORTED_ESCAPE_SEQUENCE:	19,
		U_NO_SPACE_AVAILABLE:	20,
		U_CE_NOT_FOUND_ERROR:	21,
		U_PRIMARY_TOO_LONG_ERROR:	22,
		U_STATE_TOO_OLD_ERROR:	23,
		U_TOO_MANY_ALIASES_ERROR:	24,
		U_ENUM_OUT_OF_SYNC_ERROR:	25,
		U_INVARIANT_CONVERSION_ERROR:	26,
		U_INVALID_STATE_ERROR:	27,
		U_COLLATOR_VERSION_MISMATCH:	28,
		U_USELESS_COLLATOR_ERROR:	29,
		U_NO_WRITE_PERMISSION:	30,
		U_INPUT_TOO_LONG_ERROR:	31,
		U_BAD_VARIABLE_DEFINITION:	65536,
		U_PARSE_ERROR_START:	65536,
		U_MALFORMED_RULE:	65537,
		U_MALFORMED_SET:	65538,
		U_MALFORMED_SYMBOL_REFERENCE:	65539,
		U_MALFORMED_UNICODE_ESCAPE:	65540,
		U_MALFORMED_VARIABLE_DEFINITION:	65541,
		U_MALFORMED_VARIABLE_REFERENCE:	65542,
		U_MISMATCHED_SEGMENT_DELIMITERS:	65543,
		U_MISPLACED_ANCHOR_START:	65544,
		U_MISPLACED_CURSOR_OFFSET:	65545,
		U_MISPLACED_QUANTIFIER:	65546,
		U_MISSING_OPERATOR:	65547,
		U_MISSING_SEGMENT_CLOSE:	65548,
		U_MULTIPLE_ANTE_CONTEXTS:	65549,
		U_MULTIPLE_CURSORS:	65550,
		U_MULTIPLE_POST_CONTEXTS:	65551,
		U_TRAILING_BACKSLASH:	65552,
		U_UNDEFINED_SEGMENT_REFERENCE:	65553,
		U_UNDEFINED_VARIABLE:	65554,
		U_UNQUOTED_SPECIAL:	65555,
		U_UNTERMINATED_QUOTE:	65556,
		U_RULE_MASK_ERROR:	65557,
		U_MISPLACED_COMPOUND_FILTER:	65558,
		U_MULTIPLE_COMPOUND_FILTERS:	65559,
		U_INVALID_RBT_SYNTAX:	65560,
		U_INVALID_PROPERTY_PATTERN:	65561,
		U_MALFORMED_PRAGMA:	65562,
		U_UNCLOSED_SEGMENT:	65563,
		U_ILLEGAL_CHAR_IN_SEGMENT:	65564,
		U_VARIABLE_RANGE_EXHAUSTED:	65565,
		U_VARIABLE_RANGE_OVERLAP:	65566,
		U_ILLEGAL_CHARACTER:	65567,
		U_INTERNAL_TRANSLITERATOR_ERROR:	65568,
		U_INVALID_ID:	65569,
		U_INVALID_FUNCTION:	65570,
		U_UNEXPECTED_TOKEN:	65792,
		U_FMT_PARSE_ERROR_START:	65792,
		U_MULTIPLE_DECIMAL_SEPARATORS:	65793,
		U_MULTIPLE_DECIMAL_SEPERATORS:	65793,
		U_MULTIPLE_EXPONENTIAL_SYMBOLS:	65794,
		U_MALFORMED_EXPONENTIAL_PATTERN:	65795,
		U_MULTIPLE_PERCENT_SYMBOLS:	65796,
		U_MULTIPLE_PERMILL_SYMBOLS:	65797,
		U_MULTIPLE_PAD_SPECIFIERS:	65798,
		U_PATTERN_SYNTAX_ERROR:	65799,
		U_ILLEGAL_PAD_POSITION:	65800,
		U_UNMATCHED_BRACES:	65801,
		U_UNSUPPORTED_PROPERTY:	65802,
		U_UNSUPPORTED_ATTRIBUTE:	65803,
		U_ARGUMENT_TYPE_MISMATCH:	65804,
		U_DUPLICATE_KEYWORD:	65805,
		U_UNDEFINED_KEYWORD:	65806,
		U_DEFAULT_KEYWORD_MISSING:	65807,
		U_DECIMAL_NUMBER_SYNTAX_ERROR:	65808,
		U_FORMAT_INEXACT_ERROR:	65809,
		U_NUMBER_ARG_OUTOFBOUNDS_ERROR:	65810,
		U_NUMBER_SKELETON_SYNTAX_ERROR:	65811,
		U_BRK_INTERNAL_ERROR:	66048,
		U_BRK_ERROR_START:	66048,
		U_BRK_HEX_DIGITS_EXPECTED:	66049,
		U_BRK_SEMICOLON_EXPECTED:	66050,
		U_BRK_RULE_SYNTAX:	66051,
		U_BRK_UNCLOSED_SET:	66052,
		U_BRK_ASSIGN_ERROR:	66053,
		U_BRK_VARIABLE_REDFINITION:	66054,
		U_BRK_MISMATCHED_PAREN:	66055,
		U_BRK_NEW_LINE_IN_QUOTED_STRING:	66056,
		U_BRK_UNDEFINED_VARIABLE:	66057,
		U_BRK_INIT_ERROR:	66058,
		U_BRK_RULE_EMPTY_SET:	66059,
		U_BRK_UNRECOGNIZED_OPTION:	66060,
		U_BRK_MALFORMED_RULE_TAG:	66061,
		U_REGEX_INTERNAL_ERROR:	66304,
		U_REGEX_ERROR_START:	66304,
		U_REGEX_RULE_SYNTAX:	66305,
		U_REGEX_INVALID_STATE:	66306,
		U_REGEX_BAD_ESCAPE_SEQUENCE:	66307,
		U_REGEX_PROPERTY_SYNTAX:	66308,
		U_REGEX_UNIMPLEMENTED:	66309,
		U_REGEX_MISMATCHED_PAREN:	66310,
		U_REGEX_NUMBER_TOO_BIG:	66311,
		U_REGEX_BAD_INTERVAL:	66312,
		U_REGEX_MAX_LT_MIN:	66313,
		U_REGEX_INVALID_BACK_REF:	66314,
		U_REGEX_INVALID_FLAG:	66315,
		U_REGEX_LOOK_BEHIND_LIMIT:	66316,
		U_REGEX_SET_CONTAINS_STRING:	66317,
		U_REGEX_MISSING_CLOSE_BRACKET:	66319,
		U_REGEX_INVALID_RANGE:	66320,
		U_REGEX_STACK_OVERFLOW:	66321,
		U_REGEX_TIME_OUT:	66322,
		U_REGEX_STOPPED_BY_CALLER:	66323,
		U_REGEX_PATTERN_TOO_BIG:	66324,
		U_REGEX_INVALID_CAPTURE_GROUP_NAME:	66325,
		U_IDNA_PROHIBITED_ERROR:	66560,
		U_IDNA_ERROR_START:	66560,
		U_IDNA_UNASSIGNED_ERROR:	66561,
		U_IDNA_CHECK_BIDI_ERROR:	66562,
		U_IDNA_STD3_ASCII_RULES_ERROR:	66563,
		U_IDNA_ACE_PREFIX_ERROR:	66564,
		U_IDNA_VERIFICATION_ERROR:	66565,
		U_IDNA_LABEL_TOO_LONG_ERROR:	66566,
		U_IDNA_ZERO_LENGTH_LABEL_ERROR:	66567,
		U_IDNA_DOMAIN_NAME_TOO_LONG_ERROR:	66568,
		U_STRINGPREP_PROHIBITED_ERROR:	66560,
		U_STRINGPREP_UNASSIGNED_ERROR:	66561,
		U_STRINGPREP_CHECK_BIDI_ERROR:	66562,
		U_PLUGIN_ERROR_START:	66816,
		U_PLUGIN_TOO_HIGH:	66816,
		U_PLUGIN_DIDNT_SET_LEVEL:	66817,
		U_ERROR_WARNING_LIMIT:	-119,
		U_STANDARD_ERROR_LIMIT:	31,
		U_PARSE_ERROR_LIMIT:	65571,
		U_FMT_PARSE_ERROR_LIMIT:	65810,
		U_BRK_ERROR_LIMIT:	66062,
		U_REGEX_ERROR_LIMIT:	66326,
		U_IDNA_ERROR_LIMIT:	66569,
		U_PLUGIN_ERROR_LIMIT:	66818,
		U_ERROR_LIMIT:	66818
	}
}