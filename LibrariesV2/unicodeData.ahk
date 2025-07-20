
class unicodeData {
	
	; https://unicode-org.github.io/icu-docs/apidoc/released/icu4c/uchar_8h.html#a46c049f7988a44e14d221f68e2e63db2

	; Alias of lookup
	static charFromName(name, nameChoice := this.UCharNameChoice.U_UNICODE_CHAR_NAME, default?) => this.lookup(name, nameChoice, default?)
	; Look up character by name. If a character with the given name is found, return the corresponding character. If not found, KeyError is raised. 
	static lookup(name, nameChoice := this.UCharNameChoice.U_UNICODE_CHAR_NAME, default?) {
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
	}

	; Returns the name assigned to the character char as a string.
	static charName(char, nameChoice := this.UCharNameChoice.U_UNICODE_CHAR_NAME) {
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
	
	; The version of the Unicode database used in this module. 
	static unidata_version => 0


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

	class Wrapper {		
		; Check a binary Unicode property for a code point. Properties are listed in unicodeData.UProperty
		; Property must be UCHAR_BINARY_START<=whichUProperty<UCHAR_BINARY_LIMIT.
		static hasBinaryProperty(char, whichUProperty) {
			this.verifyVersion()
			if (whichUProperty is String)
				whichUProperty := unicodeData.UProperty.%whichUProperty%
			return DllCall("icuuc\u_hasBinaryProperty", "uchar", Ord(char), "int", whichUProperty)
		}
		
		;  	Returns true if the property is true for the string. 
		static stringHasBinaryProperty(str, length, whichUProperty) {
			this.verifyVersion()
			strBuf := Buffer(StrPut(str, "UTF-8"))
			StrPut(str, strBuf, "UTF-8")
			if (whichUProperty is String)
				whichUProperty := unicodeData.UProperty.%whichUProperty%
			return DllCall("icuuc\u_stringHasBinaryProperty", "Ptr", strBuf, "int", length, "int", whichUProperty)
		}
		
		;  	Returns a frozen USet for a binary property. 
		static getBinaryPropertySet(whichUProperty) {
			this.verifyVersion()
			errorCode := 0
			if (whichUProperty is String)
				whichUProperty := unicodeData.UProperty.%whichUProperty%
			ret := DllCall("icuuc\u_getBinaryPropertySet", "int", whichUProperty, "int*", &errorCode)
			switch errorCode {
				case unicodeData.UErrorCode.U_ZERO_ERROR:
					return "NOT IMPLEMENTED, ITS A USET"
				default:
					throw(OSError("getBinaryPropertySet returned Error " errorCode))
			}
		}
		
		;  	Check if a code point has the Alphabetic Unicode property. 
		static isUAlphabetic(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isUAlphabetic", "uchar", Ord(char))
		}
		
		;  	Check if a code point has the Lowercase Unicode property. 
		static isULowercase(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isULowercase", "uchar", Ord(char))
		}
		
		;  	Check if a code point has the Uppercase Unicode property. 
		static isUUppercase(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isUUppercase", "uchar", Ord(char))
		}
		
		;  	Check if a code point has the White_Space Unicode property. 
		static isUWhiteSpace(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isUWhiteSpace", "uchar", Ord(char))
		}
		
		;  	Get the property value for an enumerated or integer Unicode property for a code point. 
		static getIntPropertyValue(char, whichUProperty) {
			this.verifyVersion()
			if (whichUProperty is String)
				whichUProperty := unicodeData.UProperty.%whichUProperty%
			return DllCall("icuuc\u_getIntPropertyValue", "uchar", Ord(char), "int", whichUProperty)
		}
		
		;  	Get the minimum value for an enumerated/integer/binary Unicode property. 
		static getIntPropertyMinValue(whichUProperty) {
			this.verifyVersion()
			if (whichUProperty is String)
				whichUProperty := unicodeData.UProperty.%whichUProperty%
			return DllCall("icuuc\u_getIntPropertyMinValue", "int", whichUProperty)
		}
		
		;  	Get the maximum value for an enumerated/integer/binary Unicode property. 
		static getIntPropertyMaxValue(whichUProperty) {
			this.verifyVersion()
			if (whichUProperty is String)
				whichUProperty := unicodeData.UProperty.%whichUProperty%
			return DllCall("icuuc\u_getIntPropertyMaxValue", "int", whichUProperty)
		}
		
		;  	Returns an immutable UCPMap for an enumerated/catalog/int-valued property. 
		static getIntPropertyMap(whichUProperty) {
			this.verifyVersion()
			errorCode := 0
			if (whichUProperty is String)
				whichUProperty := unicodeData.UProperty.%whichUProperty%
			ret := DllCall("icuuc\u_getIntPropertyMap", "int", whichUProperty, "int*", &errorCode)
			switch errorCode {
				case unicodeData.UErrorCode.U_ZERO_ERROR:
					return "NOT IMPLEMENTED, IS UCPMAP"
				default:
					throw(OSError("getIntPropertyMap returned Error " errorCode))
			}
		}
		
		;  	Get the numeric value for a Unicode code point as defined in the Unicode Character Database. 
		static getNumericValue(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_getNumericValue", "uchar", Ord(char))
		}
		
		;  	Determines whether the specified code point has the general category "Ll" (lowercase letter) => 0. 
		static islower(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_islower", "uchar", Ord(char))
		}
		
		;  	Determines whether the specified code point has the general category "Lu" (uppercase letter) => 0. 
		static isupper(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isupper", "uchar", Ord(char))
		}
		
		;  	Determines whether the specified code point is a titlecase letter. 
		static istitle(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_istitle", "uchar", Ord(char))
		}
		
		;  	Determines whether the specified code point is a digit character according to Java. 
		static isdigit(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isdigit", "uchar", Ord(char))
		}
		
		;  	Determines whether the specified code point is a letter character. 
		static isalpha(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isalpha", "uchar", Ord(char))
		}
		
		;  	Determines whether the specified code point is an alphanumeric character (letter or digit) => 0 according to Java. 
		static isalnum(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isalnum", "uchar", Ord(char))
		}
		
		;  	Determines whether the specified code point is a hexadecimal digit. 
		static isxdigit(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isxdigit", "uchar", Ord(char))
		}
		
		;  	Determines whether the specified code point is a punctuation character. 
		static ispunct(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_ispunct", "uchar", Ord(char))
		}
		
		;  	Determines whether the specified code point is a "graphic" character (printable, excluding spaces) => 0. 
		static isgraph(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isgraph", "uchar", Ord(char))
		}
		
		;  	Determines whether the specified code point is a "blank" or "horizontal space", a character that visibly separates words on a line. 
		static isblank(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isblank", "uchar", Ord(char))
		}
		
		;  	Determines whether the specified code point is "defined", which usually means that it is assigned a character. 
		static isdefined(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isdefined", "uchar", Ord(char))
		}
		
		;  	Determines if the specified character is a space character or not. 
		static isspace(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isspace", "uchar", Ord(char))
		}
		
		;  	Determine if the specified code point is a space character according to Java. 
		static isJavaSpaceChar(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isJavaSpaceChar", "uchar", Ord(char))
		}
		
		;  	Determines if the specified code point is a whitespace character according to Java/ICU. 
		static isWhitespace(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isWhitespace", "uchar", Ord(char))
		}
		
		;  	Determines whether the specified code point is a control character (as defined by this function) => 0. 
		static iscntrl(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_iscntrl", "uchar", Ord(char))
		}
		
		;  	Determines whether the specified code point is an ISO control code. 
		static isISOControl(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isISOControl", "uchar", Ord(char))
		}
		
		;  	Determines whether the specified code point is a printable character. 
		static isprint(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isprint", "uchar", Ord(char))
		}
		
		;  	Non-standard: Determines whether the specified code point is a base character. 
		static isbase(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isbase", "uchar", Ord(char))
		}
		
		;  	Returns the bidirectional category value for the code point, which is used in the Unicode bidirectional algorithm (UAX #9 http://www.unicode.org/reports/tr9/). 
		; See UCharDirection Enum
		static charDirection(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_charDirection", "uchar", Ord(char))
		}
		
		;  	Determines whether the code point has the Bidi_Mirrored property. 
		static isMirrored(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isMirrored", "uchar", Ord(char))
		}
		
		;  	Maps the specified character to a "mirror-image" character. 
		static charMirror(char) {
			this.verifyVersion()
			codePoint := DllCall("icuuc\u_charMirror", "uchar", Ord(char))
			return Chr(codePoint)
		}
		
		;  	Maps the specified character to its paired bracket character. 
		static getBidiPairedBracket(char) {
			this.verifyVersion()
			codePoint := DllCall("icuuc\u_getBidiPairedBracket", "uchar", Ord(char))
			return Chr(codePoint)
		}
		
		;  	Returns the general category value for the code point. 
		static charType(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_charType", "uchar", Ord(char))
		}
		
		;  	Enumerate efficiently all code points with their Unicode general categories. 
		; static enumCharTypes(UCharEnumTypeRange *enumRange, const void *context) {
		; 	this.verifyVersion()
		; 	ret := DllCall("icuuc\u_enumCharTypes")
		; }
		
		;  	Returns the combining class of the code point as specified in UnicodeData.txt. 
		static getCombiningClass(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_getCombiningClass", "uchar", Ord(char))
		}
		
		;  	Returns the decimal digit value of a decimal digit character. 
		static charDigitValue(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_charDigitValue", "uchar", Ord(char))
		}
		
		; 	Returns the Unicode allocation block that contains the character. 
		static ublock_getCode(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_ublock_getCode ", "uchar", Ord(char))
		}

		;  	Retrieve the name of a Unicode character. 
		static charName(char, nameChoice := unicodeData.UCharNameChoice.U_UNICODE_CHAR_NAME) {
			this.verifyVersion()
			name := Buffer(512)
			errorCode := 0
			length := DllCall("icuuc\u_charName", "uchar", Ord(char), "int", nameChoice, "Ptr", name, "int", name.Size, "int*", &errorCode)
			switch errorCode {
				case unicodeData.UErrorCode.U_ZERO_ERROR:
					return StrGet(name, length, "UTF-8")
				default:
					throw(OSError("u_charName returned Error " errorCode))
			}
		}
		
		;  	Returns an empty string. 
		static getISOComment(char) {
			this.verifyVersion()
			errorCode := 0
			dest := Buffer(512)
			DllCall("icuuc\u_getISOComment", "uchar", Ord(char), "Ptr", dest, "int", dest.Size, "int*", &errorCode)
			switch errorCode {
				case unicodeData.UErrorCode.U_ZERO_ERROR:
					return StrGet(dest,, "UTF-8")
				default:
					throw(OSError("u_getISOComment returned Error " errorCode))
			}
		}
		
		;  	Find a Unicode character by its name and return its code point value. 
		static charFromName(name, nameChoice := unicodeData.UCharNameChoice.U_UNICODE_CHAR_NAME) {
			this.verifyVersion()
			errorCode := 0
			nameBuf := Buffer(StrPut(name, "UTF-8"))
			StrPut(name, nameBuf, "UTF-8")
			codePoint := DllCall("icuuc\u_charFromName", "int", nameChoice, "Ptr", name, "int*", &errorCode)
			switch errorCode {
				case unicodeData.UErrorCode.U_ZERO_ERROR:
					return Chr(codePoint)
				default:
					throw(OSError("u_charName returned Error " errorCode))
			}
		}
		
		;  	Enumerate all assigned Unicode characters between the start and limit code points (start inclusive, limit exclusive) => 0 and call a function for each, passing the code point value and the character name. 
		; static enumCharNames(start, limit, UEnumCharNamesFn *fn, void *context, nameChoice := unicodeData.UCharNameChoice.U_UNICODE_CHAR_NAME) {
		; 	this.verifyVersion()
		; 	errorCode := 0
		; 	ret := DllCall("icuuc\u_enumCharNames", "uchar", Ord(start), "uchar", Ord(limit),,, "int", nameChoice, "int*", &errorCode)
		; 	switch errorCode {
				
		; 	}
		; }
		
		;  	Return the Unicode name for a given property, as given in the Unicode database file PropertyAliases.txt. 
		static getPropertyName(whichUProperty, nameChoice := unicodeData.UPropertyNameChoice.U_LONG_PROPERTY_NAME) {
			this.verifyVersion()
			if (whichUProperty is String)
				whichUProperty := unicodeData.UProperty.%whichUProperty%
			name := DllCall("icuuc\u_getPropertyName", "int", whichUProperty, "int", nameChoice)
			return StrGet(name,, "UTF-8")
		}
		
		;  	Return the UProperty enum for a given property name, as specified in the Unicode database file PropertyAliases.txt. 
		; static getPropertyEnum(alias) {
		; 	this.verifyVersion()
		; 	aliasBuf := Buffer(StrPut(alias, "UTF-8"))
		; 	StrPut(alias, aliasBuf, "UTF-8")
		; 	ret := DllCall("icuuc\u_getPropertyEnum", "Ptr", aliasBuf)
		; }
		
		;  	Return the Unicode name for a given property value, as given in the Unicode database file PropertyValueAliases.txt. 
		static getPropertyValueName(whichUProperty, value, nameChoice := unicodeData.UPropertyNameChoice.U_LONG_PROPERTY_NAME) {
			this.verifyVersion()
			if (whichUProperty is String)
				whichUProperty := unicodeData.UProperty.%whichUProperty%
			ret := DllCall("icuuc\u_getPropertyValueName", "int", whichUProperty, "int", value, "int", nameChoice)
			return StrGet(ret,, "UTF-8")
		}
		
		;  	Return the property value integer for a given value name, as specified in the Unicode database file PropertyValueAliases.txt. 
		; static getPropertyValueEnum(whichUProperty, alias) {
		; 	this.verifyVersion()
		; 	aliasBuf := Buffer(StrPut(alias, "UTF-8"))
		; 	StrPut(alias, aliasBuf, "UTF-8")
		; 	if (whichUProperty is String)
		; 		whichUProperty := unicodeData.UProperty.%whichUProperty%
		; 	ret := DllCall("icuuc\u_getPropertyValueEnum", "int", whichUProperty, "Ptr", aliasBuf)
		; }
		
		;  	Determines if the specified character is permissible as the first character in an identifier according to UAX #31 Unicode Identifier and Pattern Syntax. 
		static isIDStart(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isIDStart", "uchar", Ord(char))
		}
		
		;  	Determines if the specified character is permissible as a non-initial character of an identifier according to UAX #31 Unicode Identifier and Pattern Syntax. 
		static isIDPart(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isIDPart", "uchar", Ord(char))
		}
		
		;  	Does the set of Identifier_Type values code point c contain the given type? 
		; can't find UIDentifierType enum values 
		; static hasIDType(char, type := unicodeData.UIdentifierType) {
		; 	this.verifyVersion()
		; 	return DllCall("icuuc\u_hasIDType", "uchar", Ord(char))
		; }
		
		;  	Writes code point c's Identifier_Type as a list of UIdentifierType values to the output types array and returns the number of types. 
		; can't find UIDentifierType enum values 
		; static getIDTypes(char, UIdentifierType *types, int32_t capacity) {
		; 	this.verifyVersion()
		; 	errorCode := 0
		; 	ret := DllCall("icuuc\u_getIDTypes", "uchar", Ord(char), "int*", &errorCode)
		; 	switch errorCode {
				
		; 	}
		; }
		
		;  	Determines if the specified character should be regarded as an ignorable character in an identifier, according to Java. 
		static isIDIgnorable(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isIDIgnorable", "uchar", Ord(char))
		}
		
		;  	Determines if the specified character is permissible as the first character in a Java identifier. 
		static isJavaIDStart(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isJavaIDStart", "uchar", Ord(char))
		}
		
		;  	Determines if the specified character is permissible in a Java identifier. 
		static isJavaIDPart(char) {
			this.verifyVersion()
			return DllCall("icuuc\u_isJavaIDPart", "uchar", Ord(char))
		}
		
		;  	The given character is mapped to its lowercase equivalent according to UnicodeData.txt; if the character has no lowercase equivalent, the character itself is returned. 
		static tolower(char) {
			this.verifyVersion()
			codePoint := DllCall("icuuc\u_tolower", "uchar", Ord(char))
			return Chr(codePoint)
		}
		
		;  	The given character is mapped to its uppercase equivalent according to UnicodeData.txt; if the character has no uppercase equivalent, the character itself is returned. 
		static toupper(char) {
			this.verifyVersion()
			codePoint := DllCall("icuuc\u_toupper", "uchar", Ord(char))
			return Chr(codePoint)
		}
		
		;  	The given character is mapped to its titlecase equivalent according to UnicodeData.txt; if none is defined, the character itself is returned. 
		static totitle(char) {
			this.verifyVersion()
			codePoint := DllCall("icuuc\u_totitle", "uchar", Ord(char))
			return Chr(codePoint)
		}
		
		;  	The given character is mapped to its case folding equivalent according to UnicodeData.txt and CaseFolding.txt; if the character has no case folding equivalent, the character itself is returned. 
		; options are either U_FOLD_CASE_DEFAULT == 0 or U_FOLD_CASE_EXCLUDE_SPECIAL_I == 1
		static foldCase(char, options := unicodeData.FoldOption.U_FOLD_CASE_DEFAULT) {
			this.verifyVersion()
			codePoint := DllCall("icuuc\u_foldCase", "uchar", Ord(char), "int", options)
			return Chr(codePoint)
		}
		
		;  	Returns the decimal digit value of the code point in the specified radix. 
		static digit(char, radix) {
			this.verifyVersion()
			return DllCall("icuuc\u_digit", "uchar", Ord(char), "char", radix) ; int8 == char
		}
		
		;  	Determines the character representation for a specific digit in the specified radix. 
		static forDigit(digit, radix) {
			this.verifyVersion()
			codePoint := DllCall("icuuc\u_forDigit", "int", digit, "char", radix)
			return Chr(codePoint)
		}
		
		;  	Get the "age" of the code point. 
		static charAge(char) {
			this.verifyVersion()
			versionArray := Buffer(4)
			DllCall("icuuc\u_charAge", "uchar", Ord(char), "Ptr", versionArray)
			return [NumGet(versionArray, 0, "uchar"), NumGet(versionArray, 1, "uchar"), NumGet(versionArray, 2, "uchar"), NumGet(versionArray, 3, "uchar")]
		}
		
		;  	Gets the Unicode version information. 
		static getUnicodeVersion() {
			this.verifyVersion()
			versionArray := Buffer(4)
			DllCall("icuuc\u_getUnicodeVersion", "Ptr", versionArray)
			return [NumGet(versionArray, 0, "uchar"), NumGet(versionArray, 1, "uchar"), NumGet(versionArray, 2, "uchar"), NumGet(versionArray, 3, "uchar")]
		}
		
		;  	Get the FC_NFKC_Closure property string for a character. 
		static getFC_NFKC_Closure(char) {
			this.verifyVersion()
			errorCode := 0
			dest := Buffer(512)
			length := DllCall("icuuc\u_getFC_NFKC_Closure", "uchar", Ord(char), "Ptr", dest, "int", dest.Size, "int*", &errorCode)
			switch errorCode {
				case unicodeData.UErrorCode.U_ZERO_ERROR:
					return StrGet(dest, length, "UTF-8")
				default:
					throw(OSError("getFC_NFKC_Closure returned Error " errorCode))
			}
		}

		; alias
		static verifyVersion() => unicodeData.verifyVersion()

		
	}
	
	static Normalization => {
		NFC: 0x1, ; Unicode normalization form C, canonical composition. Transforms each decomposed grouping, consisting of a base character plus combining characters, to the canonical precomposed equivalent. For example, A + ¨ becomes Ä.
		NFD: 0x2, ; Unicode normalization form D, canonical decomposition. Transforms each precomposed character to its canonical decomposed equivalent. For example, Ä becomes A + ¨.
		NFKC: 0x5, ; Unicode normalization form KC, compatibility composition. Transforms each base plus combining characters to the canonical precomposed equivalent and all compatibility characters to their equivalents. For example, the ligature ﬁ becomes f + i; similarly, A + ¨ + ﬁ + n becomes Ä + f + i + n.
		NFKD: 0x6 ; Unicode normalization form KD, compatibility decomposition. Transforms each precomposed character to its canonical decomposed equivalent and all compatibility characters to their equivalents. For example, Ä + ﬁ + n becomes A + ¨ + f + i + n.
	}

	static FoldOption => {
		U_FOLD_CASE_DEFAULT: 0,
		U_FOLD_CASE_EXCLUDE_SPECIAL_I: 1
	}
	
	static UIdentifierStatus => {}

	static UIdentifierType => {}

	static UIndicConjunctBreak => {}

	static UNumericType => {
		U_NT_NONE: 0,
		U_NT_DECIMAL: 1,
		U_NT_DIGIT: 2,
		U_NT_NUMERIC: 3,
		U_NT_COUNT: 4
	}

	static UHangulSyllableType => {
		U_HST_NOT_APPLICABLE: 0,
		U_HST_LEADING_JAMO: 1,
		U_HST_VOWEL_JAMO: 2,
		U_HST_TRAILING_JAMO: 3,
		U_HST_LV_SYLLABLE: 4,
		U_HST_LVT_SYLLABLE: 5,
		U_HST_COUNT: 6
	}

	static UIndicPositionalCategory => {
		U_INPC_NA: 0,
		U_INPC_BOTTOM: 1,
		U_INPC_BOTTOM_AND_LEFT: 2,
		U_INPC_BOTTOM_AND_RIGHT: 3,
		U_INPC_LEFT: 4,
		U_INPC_LEFT_AND_RIGHT: 5,
		U_INPC_OVERSTRUCK: 6,
		U_INPC_RIGHT: 7,
		U_INPC_TOP: 8,
		U_INPC_TOP_AND_BOTTOM: 9,
		U_INPC_TOP_AND_BOTTOM_AND_RIGHT: 10,
		U_INPC_TOP_AND_LEFT: 11,
		U_INPC_TOP_AND_LEFT_AND_RIGHT: 12,
		U_INPC_TOP_AND_RIGHT: 13,
		U_INPC_VISUAL_ORDER_LEFT: 14,
		U_INPC_TOP_AND_BOTTOM_AND_LEFT: 15
	}

	static UIndicSyllabicCategory => {
		U_INSC_OTHER: 0,
		U_INSC_AVAGRAHA: 1,
		U_INSC_BINDU: 2,
		U_INSC_BRAHMI_JOINING_NUMBER: 3,
		U_INSC_CANTILLATION_MARK: 4,
		U_INSC_CONSONANT: 5,
		U_INSC_CONSONANT_DEAD: 6,
		U_INSC_CONSONANT_FINAL: 7,
		U_INSC_CONSONANT_HEAD_LETTER: 8,
		U_INSC_CONSONANT_INITIAL_POSTFIXED: 9,
		U_INSC_CONSONANT_KILLER: 10,
		U_INSC_CONSONANT_MEDIAL: 11,
		U_INSC_CONSONANT_PLACEHOLDER: 12,
		U_INSC_CONSONANT_PRECEDING_REPHA: 13,
		U_INSC_CONSONANT_PREFIXED: 14,
		U_INSC_CONSONANT_SUBJOINED: 15,
		U_INSC_CONSONANT_SUCCEEDING_REPHA: 16,
		U_INSC_CONSONANT_WITH_STACKER: 17,
		U_INSC_GEMINATION_MARK: 18,
		U_INSC_INVISIBLE_STACKER: 19,
		U_INSC_JOINER: 20,
		U_INSC_MODIFYING_LETTER: 21,
		U_INSC_NON_JOINER: 22,
		U_INSC_NUKTA: 23,
		U_INSC_NUMBER: 24,
		U_INSC_NUMBER_JOINER: 25,
		U_INSC_PURE_KILLER: 26,
		U_INSC_REGISTER_SHIFTER: 27,
		U_INSC_SYLLABLE_MODIFIER: 28,
		U_INSC_TONE_LETTER: 29,
		U_INSC_TONE_MARK: 30,
		U_INSC_VIRAMA: 31,
		U_INSC_VISARGA: 32,
		U_INSC_VOWEL: 33,
		U_INSC_VOWEL_DEPENDENT: 34,
		U_INSC_VOWEL_INDEPENDENT: 35
	}

	static UVerticalOrientation => {
		U_VO_ROTATED: 0,
		U_VO_TRANSFORMED_ROTATED: 1,
		U_VO_TRANSFORMED_UPRIGHT: 2,
		U_VO_UPRIGHT: 3
	}

	static ULineBreak => {
		U_LB_UNKNOWN: 0,
		U_LB_AMBIGUOUS: 1,
		U_LB_ALPHABETIC: 2,
		U_LB_BREAK_BOTH: 3,
		U_LB_BREAK_AFTER: 4,
		U_LB_BREAK_BEFORE: 5,
		U_LB_MANDATORY_BREAK: 6,
		U_LB_CONTINGENT_BREAK: 7,
		U_LB_CLOSE_PUNCTUATION: 8,
		U_LB_COMBINING_MARK: 9,
		U_LB_CARRIAGE_RETURN: 10,
		U_LB_EXCLAMATION: 11,
		U_LB_GLUE: 12,
		U_LB_HYPHEN: 13,
		U_LB_IDEOGRAPHIC: 14,
		U_LB_INSEPARABLE: 15,
		U_LB_INSEPERABLE: 15,
		U_LB_INFIX_NUMERIC: 16,
		U_LB_LINE_FEED: 17,
		U_LB_NONSTARTER: 18,
		U_LB_NUMERIC: 19,
		U_LB_OPEN_PUNCTUATION: 20,
		U_LB_POSTFIX_NUMERIC: 21,
		U_LB_PREFIX_NUMERIC: 22,
		U_LB_QUOTATION: 23,
		U_LB_COMPLEX_CONTEXT: 24,
		U_LB_SURROGATE: 25,
		U_LB_SPACE: 26,
		U_LB_BREAK_SYMBOLS: 27,
		U_LB_ZWSPACE: 28,
		U_LB_NEXT_LINE: 29,
		U_LB_WORD_JOINER: 30,
		U_LB_H2: 31,
		U_LB_H3: 32,
		U_LB_JL: 33,
		U_LB_JT: 34,
		U_LB_JV: 35,
		U_LB_CLOSE_PARENTHESIS: 36,
		U_LB_CONDITIONAL_JAPANESE_STARTER: 37,
		U_LB_HEBREW_LETTER: 38,
		U_LB_REGIONAL_INDICATOR: 39,
		U_LB_E_BASE: 40,
		U_LB_E_MODIFIER: 41,
		U_LB_ZWJ: 42,
		U_LB_COUNT: 40
	}
	
	static USentenceBreak => {
		U_SB_OTHER: 0,
		U_SB_ATERM: 1,
		U_SB_CLOSE: 2,
		U_SB_FORMAT: 3,
		U_SB_LOWER: 4,
		U_SB_NUMERIC: 5,
		U_SB_OLETTER: 6,
		U_SB_SEP: 7,
		U_SB_SP: 8,
		U_SB_STERM: 9,
		U_SB_UPPER: 10,
		U_SB_CR: 11,
		U_SB_EXTEND: 12,
		U_SB_LF: 13,
		U_SB_SCONTINUE: 14,
		U_SB_COUNT: 15
	}

	static UWordBreakValues => {
		U_WB_OTHER: 0,
		U_WB_ALETTER: 1,
		U_WB_FORMAT: 2,
		U_WB_KATAKANA: 3,
		U_WB_MIDLETTER: 4,
		U_WB_MIDNUM: 5,
		U_WB_NUMERIC: 6,
		U_WB_EXTENDNUMLET: 7,
		U_WB_CR: 8,
		U_WB_EXTEND: 9,
		U_WB_LF: 10,
		U_WB_MIDNUMLET: 11,
		U_WB_NEWLINE: 12,
		U_WB_REGIONAL_INDICATOR: 13,
		U_WB_HEBREW_LETTER: 14,
		U_WB_SINGLE_QUOTE: 15,
		U_WB_DOUBLE_QUOTE: 16,
		U_WB_E_BASE: 17,
		U_WB_E_BASE_GAZ: 18,
		U_WB_E_MODIFIER: 19,
		U_WB_GLUE_AFTER_ZWJ: 20,
		U_WB_ZWJ: 21,
		U_WB_WSEGSPACE: 22,
		U_WB_COUNT: 17
	}

	static UGraphemeClusterBreak => {
		U_GCB_OTHER: 0,
		U_GCB_CONTROL: 1,
		U_GCB_CR: 2,
		U_GCB_EXTEND: 3,
		U_GCB_L: 4,
		U_GCB_LF: 5,
		U_GCB_LV: 6,
		U_GCB_LVT: 7,
		U_GCB_T: 8,
		U_GCB_V: 9,
		U_GCB_SPACING_MARK: 10,
		U_GCB_PREPEND: 11,
		U_GCB_REGIONAL_INDICATOR: 12,
		U_GCB_E_BASE: 13,
		U_GCB_E_BASE_GAZ: 14,
		U_GCB_E_MODIFIER: 15,
		U_GCB_GLUE_AFTER_ZWJ: 16,
		U_GCB_ZWJ: 17,
		U_GCB_COUNT: 13
	}

	static UJoiningType => {
		U_JT_NON_JOINING: 0,
		U_JT_JOIN_CAUSING: 1,
		U_JT_DUAL_JOINING: 2,
		U_JT_LEFT_JOINING: 3,
		U_JT_RIGHT_JOINING: 4,
		U_JT_TRANSPARENT: 5,
		U_JT_COUNT: 6
	}

	static UDecompositionType => {
		U_DT_NONE: 0,
		U_DT_CANONICAL: 1,
		U_DT_COMPAT: 2,
		U_DT_CIRCLE: 3,
		U_DT_FINAL: 4,
		U_DT_FONT: 5,
		U_DT_FRACTION: 6,
		U_DT_INITIAL: 7,
		U_DT_ISOLATED: 8,
		U_DT_MEDIAL: 9,
		U_DT_NARROW: 10,
		U_DT_NOBREAK: 11,
		U_DT_SMALL: 12,
		U_DT_SQUARE: 13,
		U_DT_SUB: 14,
		U_DT_SUPER: 15,
		U_DT_VERTICAL: 16,
		U_DT_WIDE: 17,
		U_DT_COUNT: 18
	}

	static UPropertyNameChoice => {
		U_SHORT_PROPERTY_NAME: 0,
		U_LONG_PROPERTY_NAME: 1,
		U_PROPERTY_NAME_CHOICE_COUNT: 2
	}

	static UCharNameChoice => {
		U_UNICODE_CHAR_NAME: 0x0,
		U_UNICODE_10_CHAR_NAME: 0x1,
		U_EXTENDED_CHAR_NAME: 0x2,
		U_CHAR_NAME_ALIAS: 0x3,
		U_CHAR_NAME_CHOICE_COUNT: 0x4
	}

	static UEastAsianWidth => {
		U_EA_NEUTRAL: 0, 
		U_EA_AMBIGUOUS: 1, 
		U_EA_HALFWIDTH: 2, 
		U_EA_FULLWIDTH: 3,
		U_EA_NARROW: 4,
		U_EA_WIDE: 5,
		U_EA_COUNT: 6
	}

	static UBlockCode => {	
		UBLOCK_NO_BLOCK: 0,
		UBLOCK_BASIC_LATIN: 1,
		UBLOCK_LATIN_1_SUPPLEMENT: 2,
		UBLOCK_LATIN_EXTENDED_A: 3,
		UBLOCK_LATIN_EXTENDED_B: 4,
		UBLOCK_IPA_EXTENSIONS: 5,
		UBLOCK_SPACING_MODIFIER_LETTERS: 6,
		UBLOCK_COMBINING_DIACRITICAL_MARKS: 7,
		UBLOCK_GREEK: 8,
		UBLOCK_CYRILLIC: 9,
		UBLOCK_ARMENIAN: 10,
		UBLOCK_HEBREW: 11,
		UBLOCK_ARABIC: 12,
		UBLOCK_SYRIAC: 13,
		UBLOCK_THAANA: 14,
		UBLOCK_DEVANAGARI: 15,
		UBLOCK_BENGALI: 16,
		UBLOCK_GURMUKHI: 17,
		UBLOCK_GUJARATI: 18,
		UBLOCK_ORIYA: 19,
		UBLOCK_TAMIL: 20,
		UBLOCK_TELUGU: 21,
		UBLOCK_KANNADA: 22,
		UBLOCK_MALAYALAM: 23,
		UBLOCK_SINHALA: 24,
		UBLOCK_THAI: 25,
		UBLOCK_LAO: 26,
		UBLOCK_TIBETAN: 27,
		UBLOCK_MYANMAR: 28,
		UBLOCK_GEORGIAN: 29,
		UBLOCK_HANGUL_JAMO: 30,
		UBLOCK_ETHIOPIC: 31,
		UBLOCK_CHEROKEE: 32,
		UBLOCK_UNIFIED_CANADIAN_ABORIGINAL_SYLLABICS: 33,
		UBLOCK_OGHAM: 34,
		UBLOCK_RUNIC: 35,
		UBLOCK_KHMER: 36,
		UBLOCK_MONGOLIAN: 37,
		UBLOCK_LATIN_EXTENDED_ADDITIONAL: 38,
		UBLOCK_GREEK_EXTENDED: 39,
		UBLOCK_GENERAL_PUNCTUATION: 40,
		UBLOCK_SUPERSCRIPTS_AND_SUBSCRIPTS: 41,
		UBLOCK_CURRENCY_SYMBOLS: 42,
		UBLOCK_COMBINING_MARKS_FOR_SYMBOLS: 43,
		UBLOCK_LETTERLIKE_SYMBOLS: 44,
		UBLOCK_NUMBER_FORMS: 45,
		UBLOCK_ARROWS: 46,
		UBLOCK_MATHEMATICAL_OPERATORS: 47,
		UBLOCK_MISCELLANEOUS_TECHNICAL: 48,
		UBLOCK_CONTROL_PICTURES: 49,
		UBLOCK_OPTICAL_CHARACTER_RECOGNITION: 50,
		UBLOCK_ENCLOSED_ALPHANUMERICS: 51,
		UBLOCK_BOX_DRAWING: 52,
		UBLOCK_BLOCK_ELEMENTS: 53,
		UBLOCK_GEOMETRIC_SHAPES: 54,
		UBLOCK_MISCELLANEOUS_SYMBOLS: 55,
		UBLOCK_DINGBATS: 56,
		UBLOCK_BRAILLE_PATTERNS: 57,
		UBLOCK_CJK_RADICALS_SUPPLEMENT: 58,
		UBLOCK_KANGXI_RADICALS: 59,
		UBLOCK_IDEOGRAPHIC_DESCRIPTION_CHARACTERS: 60,
		UBLOCK_CJK_SYMBOLS_AND_PUNCTUATION: 61,
		UBLOCK_HIRAGANA: 62,
		UBLOCK_KATAKANA: 63,
		UBLOCK_BOPOMOFO: 64,
		UBLOCK_HANGUL_COMPATIBILITY_JAMO: 65,
		UBLOCK_KANBUN: 66,
		UBLOCK_BOPOMOFO_EXTENDED: 67,
		UBLOCK_ENCLOSED_CJK_LETTERS_AND_MONTHS: 68,
		UBLOCK_CJK_COMPATIBILITY: 69,
		UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_A: 70,
		UBLOCK_CJK_UNIFIED_IDEOGRAPHS: 71,
		UBLOCK_YI_SYLLABLES: 72,
		UBLOCK_YI_RADICALS: 73,
		UBLOCK_HANGUL_SYLLABLES: 74,
		UBLOCK_HIGH_SURROGATES: 75,
		UBLOCK_HIGH_PRIVATE_USE_SURROGATES: 76,
		UBLOCK_LOW_SURROGATES: 77,
		UBLOCK_PRIVATE_USE_AREA: 78,
		UBLOCK_PRIVATE_USE: 78,
		UBLOCK_CJK_COMPATIBILITY_IDEOGRAPHS: 79,
		UBLOCK_ALPHABETIC_PRESENTATION_FORMS: 80,
		UBLOCK_ARABIC_PRESENTATION_FORMS_A: 81,
		UBLOCK_COMBINING_HALF_MARKS: 82,
		UBLOCK_CJK_COMPATIBILITY_FORMS: 83,
		UBLOCK_SMALL_FORM_VARIANTS: 84,
		UBLOCK_ARABIC_PRESENTATION_FORMS_B: 85,
		UBLOCK_SPECIALS: 86,
		UBLOCK_HALFWIDTH_AND_FULLWIDTH_FORMS: 87,
		UBLOCK_OLD_ITALIC: 88,
		UBLOCK_GOTHIC: 89,
		UBLOCK_DESERET: 90,
		UBLOCK_BYZANTINE_MUSICAL_SYMBOLS: 91,
		UBLOCK_MUSICAL_SYMBOLS: 92,
		UBLOCK_MATHEMATICAL_ALPHANUMERIC_SYMBOLS: 93,
		UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_B: 94,
		UBLOCK_CJK_COMPATIBILITY_IDEOGRAPHS_SUPPLEMENT: 95,
		UBLOCK_TAGS: 96,
		UBLOCK_CYRILLIC_SUPPLEMENT: 97,
		UBLOCK_CYRILLIC_SUPPLEMENTARY: 97,
		UBLOCK_TAGALOG: 98,
		UBLOCK_HANUNOO: 99,
		UBLOCK_BUHID: 100,
		UBLOCK_TAGBANWA: 101,
		UBLOCK_MISCELLANEOUS_MATHEMATICAL_SYMBOLS_A: 102,
		UBLOCK_SUPPLEMENTAL_ARROWS_A: 103,
		UBLOCK_SUPPLEMENTAL_ARROWS_B: 104,
		UBLOCK_MISCELLANEOUS_MATHEMATICAL_SYMBOLS_B: 105,
		UBLOCK_SUPPLEMENTAL_MATHEMATICAL_OPERATORS: 106,
		UBLOCK_KATAKANA_PHONETIC_EXTENSIONS: 107,
		UBLOCK_VARIATION_SELECTORS: 108,
		UBLOCK_SUPPLEMENTARY_PRIVATE_USE_AREA_A: 109,
		UBLOCK_SUPPLEMENTARY_PRIVATE_USE_AREA_B: 110,
		UBLOCK_LIMBU: 111,
		UBLOCK_TAI_LE: 112,
		UBLOCK_KHMER_SYMBOLS: 113,
		UBLOCK_PHONETIC_EXTENSIONS: 114,
		UBLOCK_MISCELLANEOUS_SYMBOLS_AND_ARROWS: 115,
		UBLOCK_YIJING_HEXAGRAM_SYMBOLS: 116,
		UBLOCK_LINEAR_B_SYLLABARY: 117,
		UBLOCK_LINEAR_B_IDEOGRAMS: 118,
		UBLOCK_AEGEAN_NUMBERS: 119,
		UBLOCK_UGARITIC: 120,
		UBLOCK_SHAVIAN: 121,
		UBLOCK_OSMANYA: 122,
		UBLOCK_CYPRIOT_SYLLABARY: 123,
		UBLOCK_TAI_XUAN_JING_SYMBOLS: 124,
		UBLOCK_VARIATION_SELECTORS_SUPPLEMENT: 125,
		UBLOCK_ANCIENT_GREEK_MUSICAL_NOTATION: 126,
		UBLOCK_ANCIENT_GREEK_NUMBERS: 127,
		UBLOCK_ARABIC_SUPPLEMENT: 128,
		UBLOCK_BUGINESE: 129,
		UBLOCK_CJK_STROKES: 130,
		UBLOCK_COMBINING_DIACRITICAL_MARKS_SUPPLEMENT: 131,
		UBLOCK_COPTIC: 132,
		UBLOCK_ETHIOPIC_EXTENDED: 133,
		UBLOCK_ETHIOPIC_SUPPLEMENT: 134,
		UBLOCK_GEORGIAN_SUPPLEMENT: 135,
		UBLOCK_GLAGOLITIC: 136,
		UBLOCK_KHAROSHTHI: 137,
		UBLOCK_MODIFIER_TONE_LETTERS: 138,
		UBLOCK_NEW_TAI_LUE: 139,
		UBLOCK_OLD_PERSIAN: 140,
		UBLOCK_PHONETIC_EXTENSIONS_SUPPLEMENT: 141,
		UBLOCK_SUPPLEMENTAL_PUNCTUATION: 142,
		UBLOCK_SYLOTI_NAGRI: 143,
		UBLOCK_TIFINAGH: 144,
		UBLOCK_VERTICAL_FORMS: 145,
		UBLOCK_NKO: 146,
		UBLOCK_BALINESE: 147,
		UBLOCK_LATIN_EXTENDED_C: 148,
		UBLOCK_LATIN_EXTENDED_D: 149,
		UBLOCK_PHAGS_PA: 150,
		UBLOCK_PHOENICIAN: 151,
		UBLOCK_CUNEIFORM: 152,
		UBLOCK_CUNEIFORM_NUMBERS_AND_PUNCTUATION: 153,
		UBLOCK_COUNTING_ROD_NUMERALS: 154,
		UBLOCK_SUNDANESE: 155,
		UBLOCK_LEPCHA: 156,
		UBLOCK_OL_CHIKI: 157,
		UBLOCK_CYRILLIC_EXTENDED_A: 158,
		UBLOCK_VAI: 159,
		UBLOCK_CYRILLIC_EXTENDED_B: 160,
		UBLOCK_SAURASHTRA: 161,
		UBLOCK_KAYAH_LI: 162,
		UBLOCK_REJANG: 163,
		UBLOCK_CHAM: 164,
		UBLOCK_ANCIENT_SYMBOLS: 165,
		UBLOCK_PHAISTOS_DISC: 166,
		UBLOCK_LYCIAN: 167,
		UBLOCK_CARIAN: 168,
		UBLOCK_LYDIAN: 169,
		UBLOCK_MAHJONG_TILES: 170,
		UBLOCK_DOMINO_TILES: 171,
		UBLOCK_SAMARITAN: 172,
		UBLOCK_UNIFIED_CANADIAN_ABORIGINAL_SYLLABICS_EXTENDED: 173,
		UBLOCK_TAI_THAM: 174,
		UBLOCK_VEDIC_EXTENSIONS: 175,
		UBLOCK_LISU: 176,
		UBLOCK_BAMUM: 177,
		UBLOCK_COMMON_INDIC_NUMBER_FORMS: 178,
		UBLOCK_DEVANAGARI_EXTENDED: 179,
		UBLOCK_HANGUL_JAMO_EXTENDED_A: 180,
		UBLOCK_JAVANESE: 181,
		UBLOCK_MYANMAR_EXTENDED_A: 182,
		UBLOCK_TAI_VIET: 183,
		UBLOCK_MEETEI_MAYEK: 184,
		UBLOCK_HANGUL_JAMO_EXTENDED_B: 185,
		UBLOCK_IMPERIAL_ARAMAIC: 186,
		UBLOCK_OLD_SOUTH_ARABIAN: 187,
		UBLOCK_AVESTAN: 188,
		UBLOCK_INSCRIPTIONAL_PARTHIAN: 189,
		UBLOCK_INSCRIPTIONAL_PAHLAVI: 190,
		UBLOCK_OLD_TURKIC: 191,
		UBLOCK_RUMI_NUMERAL_SYMBOLS: 192,
		UBLOCK_KAITHI: 193,
		UBLOCK_EGYPTIAN_HIEROGLYPHS: 194,
		UBLOCK_ENCLOSED_ALPHANUMERIC_SUPPLEMENT: 195,
		UBLOCK_ENCLOSED_IDEOGRAPHIC_SUPPLEMENT: 196,
		UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_C: 197,
		UBLOCK_MANDAIC: 198,
		UBLOCK_BATAK: 199,
		UBLOCK_ETHIOPIC_EXTENDED_A: 200,
		UBLOCK_BRAHMI: 201,
		UBLOCK_BAMUM_SUPPLEMENT: 202,
		UBLOCK_KANA_SUPPLEMENT: 203,
		UBLOCK_PLAYING_CARDS: 204,
		UBLOCK_MISCELLANEOUS_SYMBOLS_AND_PICTOGRAPHS: 205,
		UBLOCK_EMOTICONS: 206,
		UBLOCK_TRANSPORT_AND_MAP_SYMBOLS: 207,
		UBLOCK_ALCHEMICAL_SYMBOLS: 208,
		UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_D: 209,
		UBLOCK_ARABIC_EXTENDED_A: 210,
		UBLOCK_ARABIC_MATHEMATICAL_ALPHABETIC_SYMBOLS: 211,
		UBLOCK_CHAKMA: 212,
		UBLOCK_MEETEI_MAYEK_EXTENSIONS: 213,
		UBLOCK_MEROITIC_CURSIVE: 214,
		UBLOCK_MEROITIC_HIEROGLYPHS: 215,
		UBLOCK_MIAO: 216,
		UBLOCK_SHARADA: 217,
		UBLOCK_SORA_SOMPENG: 218,
		UBLOCK_SUNDANESE_SUPPLEMENT: 219,
		UBLOCK_TAKRI: 220,
		UBLOCK_BASSA_VAH: 221,
		UBLOCK_CAUCASIAN_ALBANIAN: 222,
		UBLOCK_COPTIC_EPACT_NUMBERS: 223,
		UBLOCK_COMBINING_DIACRITICAL_MARKS_EXTENDED: 224,
		UBLOCK_DUPLOYAN: 225,
		UBLOCK_ELBASAN: 226,
		UBLOCK_GEOMETRIC_SHAPES_EXTENDED: 227,
		UBLOCK_GRANTHA: 228,
		UBLOCK_KHOJKI: 229,
		UBLOCK_KHUDAWADI: 230,
		UBLOCK_LATIN_EXTENDED_E: 231,
		UBLOCK_LINEAR_A: 232,
		UBLOCK_MAHAJANI: 233,
		UBLOCK_MANICHAEAN: 234,
		UBLOCK_MENDE_KIKAKUI: 235,
		UBLOCK_MODI: 236,
		UBLOCK_MRO: 237,
		UBLOCK_MYANMAR_EXTENDED_B: 238,
		UBLOCK_NABATAEAN: 239,
		UBLOCK_OLD_NORTH_ARABIAN: 240,
		UBLOCK_OLD_PERMIC: 241,
		UBLOCK_ORNAMENTAL_DINGBATS: 242,
		UBLOCK_PAHAWH_HMONG: 243,
		UBLOCK_PALMYRENE: 244,
		UBLOCK_PAU_CIN_HAU: 245,
		UBLOCK_PSALTER_PAHLAVI: 246,
		UBLOCK_SHORTHAND_FORMAT_CONTROLS: 247,
		UBLOCK_SIDDHAM: 248,
		UBLOCK_SINHALA_ARCHAIC_NUMBERS: 249,
		UBLOCK_SUPPLEMENTAL_ARROWS_C: 250,
		UBLOCK_TIRHUTA: 251,
		UBLOCK_WARANG_CITI: 252,
		UBLOCK_AHOM: 253,
		UBLOCK_ANATOLIAN_HIEROGLYPHS: 254,
		UBLOCK_CHEROKEE_SUPPLEMENT: 255,
		UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_E: 256,
		UBLOCK_EARLY_DYNASTIC_CUNEIFORM: 257,
		UBLOCK_HATRAN: 258,
		UBLOCK_MULTANI: 259,
		UBLOCK_OLD_HUNGARIAN: 260,
		UBLOCK_SUPPLEMENTAL_SYMBOLS_AND_PICTOGRAPHS: 261,
		UBLOCK_SUTTON_SIGNWRITING: 262,
		UBLOCK_ADLAM: 263,
		UBLOCK_BHAIKSUKI: 264,
		UBLOCK_CYRILLIC_EXTENDED_C: 265,
		UBLOCK_GLAGOLITIC_SUPPLEMENT: 266,
		UBLOCK_IDEOGRAPHIC_SYMBOLS_AND_PUNCTUATION: 267,
		UBLOCK_MARCHEN: 268,
		UBLOCK_MONGOLIAN_SUPPLEMENT: 269,
		UBLOCK_NEWA: 270,
		UBLOCK_OSAGE: 271,
		UBLOCK_TANGUT: 272,
		UBLOCK_TANGUT_COMPONENTS: 273,
		UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_F: 274,
		UBLOCK_KANA_EXTENDED_A: 275,
		UBLOCK_MASARAM_GONDI: 276,
		UBLOCK_NUSHU: 277,
		UBLOCK_SOYOMBO: 278,
		UBLOCK_SYRIAC_SUPPLEMENT: 279,
		UBLOCK_ZANABAZAR_SQUARE: 280,
		UBLOCK_CHESS_SYMBOLS: 281,
		UBLOCK_DOGRA: 282,
		UBLOCK_GEORGIAN_EXTENDED: 283,
		UBLOCK_GUNJALA_GONDI: 284,
		UBLOCK_HANIFI_ROHINGYA: 285,
		UBLOCK_INDIC_SIYAQ_NUMBERS: 286,
		UBLOCK_MAKASAR: 287,
		UBLOCK_MAYAN_NUMERALS: 288,
		UBLOCK_MEDEFAIDRIN: 289,
		UBLOCK_OLD_SOGDIAN: 290,
		UBLOCK_SOGDIAN: 291,
		UBLOCK_EGYPTIAN_HIEROGLYPH_FORMAT_CONTROLS: 292,
		UBLOCK_ELYMAIC: 293,
		UBLOCK_NANDINAGARI: 294,
		UBLOCK_NYIAKENG_PUACHUE_HMONG: 295,
		UBLOCK_OTTOMAN_SIYAQ_NUMBERS: 296,
		UBLOCK_SMALL_KANA_EXTENSION: 297,
		UBLOCK_SYMBOLS_AND_PICTOGRAPHS_EXTENDED_A: 298,
		UBLOCK_TAMIL_SUPPLEMENT: 299,
		UBLOCK_WANCHO: 300,
		UBLOCK_CHORASMIAN: 301,
		UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_G: 302,
		UBLOCK_DIVES_AKURU: 303,
		UBLOCK_KHITAN_SMALL_SCRIPT: 304,
		UBLOCK_LISU_SUPPLEMENT: 305,
		UBLOCK_SYMBOLS_FOR_LEGACY_COMPUTING: 306,
		UBLOCK_TANGUT_SUPPLEMENT: 307,
		UBLOCK_YEZIDI: 308,
		UBLOCK_ARABIC_EXTENDED_B: 309,
		UBLOCK_CYPRO_MINOAN: 310,
		UBLOCK_ETHIOPIC_EXTENDED_B: 311,
		UBLOCK_KANA_EXTENDED_B: 312,
		UBLOCK_LATIN_EXTENDED_F: 313,
		UBLOCK_LATIN_EXTENDED_G: 314,
		UBLOCK_OLD_UYGHUR: 315,
		UBLOCK_TANGSA: 316,
		UBLOCK_TOTO: 317,
		UBLOCK_UNIFIED_CANADIAN_ABORIGINAL_SYLLABICS_EXTENDED_A: 318,
		UBLOCK_VITHKUQI: 319,
		UBLOCK_ZNAMENNY_MUSICAL_NOTATION: 320,
		UBLOCK_ARABIC_EXTENDED_C: 321,
		UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_H: 322,
		UBLOCK_CYRILLIC_EXTENDED_D: 323,
		UBLOCK_DEVANAGARI_EXTENDED_A: 324,
		UBLOCK_KAKTOVIK_NUMERALS: 325,
		UBLOCK_KAWI: 326,
		UBLOCK_NAG_MUNDARI: 327,
		UBLOCK_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_I: 328,
		UBLOCK_EGYPTIAN_HIEROGLYPHS_EXTENDED_A: 329,
		UBLOCK_GARAY: 330,
		UBLOCK_GURUNG_KHEMA: 331,
		UBLOCK_KIRAT_RAI: 332,
		UBLOCK_MYANMAR_EXTENDED_C: 333,
		UBLOCK_OL_ONAL: 334,
		UBLOCK_SUNUWAR: 335,
		UBLOCK_SYMBOLS_FOR_LEGACY_COMPUTING_SUPPLEMENT: 336,
		UBLOCK_TODHRI: 337,
		UBLOCK_TULU_TIGALARI: 338,
		UBLOCK_COUNT: 339,
		UBLOCK_INVALID_CODE: -1
	}

	static UBidiPairedBracketType => {
		U_BPT_NONE: 0, 
		U_BPT_OPEN: 1, 
		U_BPT_CLOSE: 2, 
		U_BPT_COUNT: 3 
	}

	static UCharDirection => {	
		U_LEFT_TO_RIGHT: 0,
		U_RIGHT_TO_LEFT: 1,
		U_EUROPEAN_NUMBER: 2,
		U_EUROPEAN_NUMBER_SEPARATOR: 3,
		U_EUROPEAN_NUMBER_TERMINATOR: 4,
		U_ARABIC_NUMBER: 5,
		U_COMMON_NUMBER_SEPARATOR: 6,
		U_BLOCK_SEPARATOR: 7,
		U_SEGMENT_SEPARATOR: 8,
		U_WHITE_SPACE_NEUTRAL: 9,
		U_OTHER_NEUTRAL: 10,
		U_LEFT_TO_RIGHT_EMBEDDING: 11,
		U_LEFT_TO_RIGHT_OVERRIDE: 12,
		U_RIGHT_TO_LEFT_ARABIC: 13,
		U_RIGHT_TO_LEFT_EMBEDDING: 14,
		U_RIGHT_TO_LEFT_OVERRIDE: 15,
		U_POP_DIRECTIONAL_FORMAT: 16,
		U_DIR_NON_SPACING_MARK: 17,
		U_BOUNDARY_NEUTRAL: 18,
		U_FIRST_STRONG_ISOLATE: 19,
		U_LEFT_TO_RIGHT_ISOLATE: 20,
		U_RIGHT_TO_LEFT_ISOLATE: 21,
		U_POP_DIRECTIONAL_ISOLATE: 22,
		U_CHAR_DIRECTION_COUNT: 23
	}

	static UCharCategory => {
		U_UNASSIGNED: 0,
		U_GENERAL_OTHER_TYPES: 0,
		U_UPPERCASE_LETTER: 1,
		U_LOWERCASE_LETTER: 2,
		U_TITLECASE_LETTER: 3,
		U_MODIFIER_LETTER: 4,
		U_OTHER_LETTER: 5,
		U_NON_SPACING_MARK: 6,
		U_ENCLOSING_MARK: 7,
		U_COMBINING_SPACING_MARK: 8,
		U_DECIMAL_DIGIT_NUMBER: 9,
		U_LETTER_NUMBER: 10,
		U_OTHER_NUMBER: 11,
		U_SPACE_SEPARATOR: 12,
		U_LINE_SEPARATOR: 13,
		U_PARAGRAPH_SEPARATOR: 14,
		U_CONTROL_CHAR: 15,
		U_FORMAT_CHAR: 16,
		U_PRIVATE_USE_CHAR: 17,
		U_SURROGATE: 18,
		U_DASH_PUNCTUATION: 19,
		U_START_PUNCTUATION: 20,
		U_END_PUNCTUATION: 21,
		U_CONNECTOR_PUNCTUATION: 22,
		U_OTHER_PUNCTUATION: 23,
		U_MATH_SYMBOL: 24,
		U_CURRENCY_SYMBOL: 25,
		U_MODIFIER_SYMBOL: 26,
		U_OTHER_SYMBOL: 27,
		U_INITIAL_PUNCTUATION: 28,
		U_FINAL_PUNCTUATION: 29,
		U_CHAR_CATEGORY_COUNT: 30
	}

	static UProperty => {
		UCHAR_ALPHABETIC: 0,
		UCHAR_BINARY_START: 0,
		UCHAR_ASCII_HEX_DIGIT: 1,
		UCHAR_BIDI_CONTROL: 2,
		UCHAR_BIDI_MIRRORED: 3,
		UCHAR_DASH: 4,
		UCHAR_DEFAULT_IGNORABLE_CODE_POINT: 5,
		UCHAR_DEPRECATED: 6,
		UCHAR_DIACRITIC: 7,
		UCHAR_EXTENDER: 8,
		UCHAR_FULL_COMPOSITION_EXCLUSION: 9,
		UCHAR_GRAPHEME_BASE: 10,
		UCHAR_GRAPHEME_EXTEND: 11,
		UCHAR_GRAPHEME_LINK: 12,
		UCHAR_HEX_DIGIT: 13,
		UCHAR_HYPHEN: 14,
		UCHAR_ID_CONTINUE: 15,
		UCHAR_ID_START: 16,
		UCHAR_IDEOGRAPHIC: 17,
		UCHAR_IDS_BINARY_OPERATOR: 18,
		UCHAR_IDS_TRINARY_OPERATOR: 19,
		UCHAR_JOIN_CONTROL: 20,
		UCHAR_LOGICAL_ORDER_EXCEPTION: 21,
		UCHAR_LOWERCASE: 22,
		UCHAR_MATH: 23,
		UCHAR_NONCHARACTER_CODE_POINT: 24,
		UCHAR_QUOTATION_MARK: 25,
		UCHAR_RADICAL: 26,
		UCHAR_SOFT_DOTTED: 27,
		UCHAR_TERMINAL_PUNCTUATION: 28,
		UCHAR_UNIFIED_IDEOGRAPH: 29,
		UCHAR_UPPERCASE: 30,
		UCHAR_WHITE_SPACE: 31,
		UCHAR_XID_CONTINUE: 32,
		UCHAR_XID_START: 33,
		UCHAR_CASE_SENSITIVE: 34,
		UCHAR_S_TERM: 35,
		UCHAR_VARIATION_SELECTOR: 36,
		UCHAR_NFD_INERT: 37,
		UCHAR_NFKD_INERT: 38,
		UCHAR_NFC_INERT: 39,
		UCHAR_NFKC_INERT: 40,
		UCHAR_SEGMENT_STARTER: 41,
		UCHAR_PATTERN_SYNTAX: 42,
		UCHAR_PATTERN_WHITE_SPACE: 43,
		UCHAR_POSIX_ALNUM: 44,
		UCHAR_POSIX_BLANK: 45,
		UCHAR_POSIX_GRAPH: 46,
		UCHAR_POSIX_PRINT: 47,
		UCHAR_POSIX_XDIGIT: 48,
		UCHAR_CASED: 49,
		UCHAR_CASE_IGNORABLE: 50,
		UCHAR_CHANGES_WHEN_LOWERCASED: 51,
		UCHAR_CHANGES_WHEN_UPPERCASED: 52,
		UCHAR_CHANGES_WHEN_TITLECASED: 53,
		UCHAR_CHANGES_WHEN_CASEFOLDED: 54,
		UCHAR_CHANGES_WHEN_CASEMAPPED: 55,
		UCHAR_CHANGES_WHEN_NFKC_CASEFOLDED: 56,
		UCHAR_EMOJI: 57,
		UCHAR_EMOJI_PRESENTATION: 58,
		UCHAR_EMOJI_MODIFIER: 59,
		UCHAR_EMOJI_MODIFIER_BASE: 60,
		UCHAR_EMOJI_COMPONENT: 61,
		UCHAR_REGIONAL_INDICATOR: 62,
		UCHAR_PREPENDED_CONCATENATION_MARK: 63,
		UCHAR_EXTENDED_PICTOGRAPHIC: 64,
		UCHAR_BASIC_EMOJI: 65,
		UCHAR_EMOJI_KEYCAP_SEQUENCE: 66,
		UCHAR_RGI_EMOJI_MODIFIER_SEQUENCE: 67,
		UCHAR_RGI_EMOJI_FLAG_SEQUENCE: 68,
		UCHAR_RGI_EMOJI_TAG_SEQUENCE: 69,
		UCHAR_RGI_EMOJI_ZWJ_SEQUENCE: 70,
		UCHAR_RGI_EMOJI: 71,
		UCHAR_IDS_UNARY_OPERATOR: 72,
		UCHAR_ID_COMPAT_MATH_START: 73,
		UCHAR_ID_COMPAT_MATH_CONTINUE: 74,
		UCHAR_MODIFIER_COMBINING_MARK: 75,
		UCHAR_BINARY_LIMIT: 76,
		UCHAR_BIDI_CLASS: 0x1000,
		UCHAR_INT_START: 0x1000,
		UCHAR_BLOCK: 0x1001,
		UCHAR_CANONICAL_COMBINING_CLASS: 0x1002,
		UCHAR_DECOMPOSITION_TYPE: 0x1003,
		UCHAR_EAST_ASIAN_WIDTH: 0x1004,
		UCHAR_GENERAL_CATEGORY: 0x1005,
		UCHAR_JOINING_GROUP: 0x1006,
		UCHAR_JOINING_TYPE: 0x1007,
		UCHAR_LINE_BREAK: 0x1008,
		UCHAR_NUMERIC_TYPE: 0x1009,
		UCHAR_SCRIPT: 0x100A,
		UCHAR_HANGUL_SYLLABLE_TYPE: 0x100B,
		UCHAR_NFD_QUICK_CHECK: 0x100C,
		UCHAR_NFKD_QUICK_CHECK: 0x100D,
		UCHAR_NFC_QUICK_CHECK: 0x100E,
		UCHAR_NFKC_QUICK_CHECK: 0x100F,
		UCHAR_LEAD_CANONICAL_COMBINING_CLASS: 0x1010,
		UCHAR_TRAIL_CANONICAL_COMBINING_CLASS: 0x1011,
		UCHAR_GRAPHEME_CLUSTER_BREAK: 0x1012,
		UCHAR_SENTENCE_BREAK: 0x1013,
		UCHAR_WORD_BREAK: 0x1014,
		UCHAR_BIDI_PAIRED_BRACKET_TYPE: 0x1015,
		UCHAR_INDIC_POSITIONAL_CATEGORY: 0x1016,
		UCHAR_INDIC_SYLLABIC_CATEGORY: 0x1017,
		UCHAR_VERTICAL_ORIENTATION: 0x1018,
		UCHAR_IDENTIFIER_STATUS: 0x1019,
		UCHAR_INDIC_CONJUNCT_BREAK: 0x101A,
		UCHAR_INT_LIMIT: 0x101B,
		UCHAR_GENERAL_CATEGORY_MASK: 0x2000,
		UCHAR_MASK_START: 0x2000,
		UCHAR_MASK_LIMIT: 0x2001,
		UCHAR_NUMERIC_VALUE: 0x3000,
		UCHAR_DOUBLE_START: 0x3000,
		UCHAR_DOUBLE_LIMIT: 0x3001,
		UCHAR_AGE: 0x4000,
		UCHAR_STRING_START: 0x4000,
		UCHAR_BIDI_MIRRORING_GLYPH: 0x4001,
		UCHAR_CASE_FOLDING: 0x4002,
		UCHAR_ISO_COMMENT: 0x4003,
		UCHAR_LOWERCASE_MAPPING: 0x4004,
		UCHAR_NAME: 0x4005,
		UCHAR_SIMPLE_CASE_FOLDING: 0x4006,
		UCHAR_SIMPLE_LOWERCASE_MAPPING: 0x4007,
		UCHAR_SIMPLE_TITLECASE_MAPPING: 0x4008,
		UCHAR_SIMPLE_UPPERCASE_MAPPING: 0x4009,
		UCHAR_TITLECASE_MAPPING: 0x400A,
		UCHAR_UNICODE_1_NAME: 0x400B,
		UCHAR_UPPERCASE_MAPPING: 0x400C,
		UCHAR_BIDI_PAIRED_BRACKET: 0x400D,
		UCHAR_STRING_LIMIT: 0x400E,
		UCHAR_SCRIPT_EXTENSIONS: 0x7000,
		UCHAR_OTHER_PROPERTY_START: 0x7000,
		UCHAR_IDENTIFIER_TYPE: 0x7001,
		UCHAR_OTHER_PROPERTY_LIMIT: 0x7002,
		UCHAR_INVALID_CODE:  -1
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