#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"
; this class exists to generate german number names from a numeric string and vice versa.

NumberNames.main()

class NumberNames {

	static main() {
		nextLine := ""
		numName := ""
		numNameNum := "0"
        r := ""
		Loop(10000) {
			Loop(5)
				r .= Random(0, 2**31-1)
			numName := this.getName(String(r))
			numNameNum := this.getValue(numName)
			nextLine := r . ", " . numName . ": " . (numNameNum == String(r) ? "Correct" : "Incorrect, " . numNameNum)
			print(nextLine)
		}
	}
	

	static getValue(name) {
		static dict := this.DE_DICT.FROM
		name := Format("{:L}", name)
		if name == "null"
			return "0"
		arr := StrSplit(name, " ")
		flagIsNegative := false
		result := "0"
		i := 0
		while (i < arr.Length) {
			word := arr[i + 1]
			if word == 'minus'
				flagIsNegative := true
			else if InStr(word, 'llion') || InStr(word, 'lliarde') {
				prefix := SubStr(word, 1, InStr(word, 'lli') - 1)
				if (dict.LATIN.Has(prefix)) {
					amountZeroes := dict.LATIN[prefix] + (InStr(word, 'lliarde') ? 3 : 0)
					num := this.triGroupDigitValue(arr[i])
					result := SubStr(result, 1, -(StrLen(num) + amountZeroes)) . num . strMultiply('0', amountZeroes)
				} else 
					throw ValueError("Unrecognized Number")
			}
			else if (i >= arr.length - 2 && SubStr(word, -7) == 'tausend') {
				thousandsValue := this.triGroupDigitValue(SubStr(word, 1, InStr(word, 'tausend') - 1))
				result := SubStr(result, 1, -(StrLen(thousandsValue) + 3)) . thousandsValue . '000'
			} else if (i == arr.length - 1) {
				singles := word
				if (InStr(word, "tausend")) {
					arr2 := StrSplit(word, 'tausend')
					thousandsValue := this.triGroupDigitValue(arr2[1])
					result := SubStr(result, 1, -(StrLen(thousandsValue) + 3)) . thousandsValue . '000'
					singles := arr2[2]
				}
				last := this.triGroupDigitValue(singles)
				result := SubStr(result, 1, -StrLen(last)) . last
			}
			i++
		}
		if (flagIsNegative)
			result := '-' . result
		return result
	}

	static getName(num) {
		if (num == 0)
			return "null"
		name := ""
		cur := ""
		isEnd := false
		if SubStr(num, 1, 1) == "-" {
			num := SubStr(num, 2)
			name := "minus "
		}
		offset := Mod(StrLen(num), 3)
		num := strMultiply('0', Mod(3 - offset, 3)) . num
		len := StrLen(num)
		i := 0
		while (i < len) {
			isEnd := (i == len - 3)
			group := SubStr(num, i + 1, 3)
			cur := this.triGroupDigitName(group, isEnd)
			if (cur != "")
				cur .= (i >= len - 6 ? "" : " ") . this.triGroupSuffixName(group, len - i - 3) . (i >= len - 6 ? "" : " ")
			name .= cur
			i += 3
		}
		return name
	}

	static triGroupSuffixName(triDigits, zeros) {
		lastTwoDigits := SubStr(triDigits, 2, 2)
		if (zeros < 3)
			return ""
		if (zeros < 6)
			return "tausend"
		name := this.DE_DICT.TO.LATIN[Mod(zeros, 6) == 0 ? zeros : zeros - 3]
		if (Mod(zeros, 6) == 0)
			name .= lastTwoDigits == '01' ? 'llion' : 'llionen'
		else
			name .= lastTwoDigits == '01' ? 'lliarde' : 'lliarden'
		return name
	}

	static triGroupDigitName(group, isEnd) {
		static dict := this.DE_DICT.TO
		h := SubStr(group, 1, 1)
		t := SubStr(group, 2, 1)
		o := SubStr(group, 3, 1)
		name := ""
		if (h != '0')
			name .= dict.ONES[h] . "hundert"
		if (t != '0') {
			if (t == '1') {
				if (dict.EXTRA.Has(t . o))
					name .= dict.EXTRA[t . o]
				else
					name .= (dict.ONES.Has(o) ? dict.ONES[o] : "") . dict.TENS['1']
			}
			else {
				if (o != '0')
					name .= dict.ONES[o] . "und"
				name .= dict.TENS[t]
			}
		}
		else if (o != '0')
			name .= dict.ONES[o] . (o == '1' ? (isEnd ? 's' : 'e') : '')
		return name
	}

	static triGroupDigitValue(gruppe) {
		static dict := this.DE_DICT.FROM
		result := 0
		gruppe := (gruppe == "" ? "eins" : gruppe)
		if (SubStr(gruppe, 1, 3) == "und")
			gruppe := SubStr(gruppe, 4)
		if (posHun := InStr(gruppe, "hundert")) {
			prefix := SubStr(gruppe, 1, posHun - 1)
			prefix := (prefix != "" ? prefix : "ein")
			if (dict.HUNDREDS.Has(prefix))
				result += dict.HUNDREDS[prefix]
			else
				throw ValueError("Nicht erkannte Zahl: Prefix " prefix)
			gruppe := SubStr(gruppe, posHun + StrLen("hundert"))
		}
		if (SubStr(gruppe, 1, 3) == "und")
			gruppe := SubStr(gruppe, 4)
		if (dict.TENS.Has(gruppe))
			return (result += dict.TENS[gruppe])
		if (dict.ONES.Has(gruppe))
			return (result += dict.ONES[gruppe])
		if (SubStr(gruppe, -4) == "zehn")
			return (result += 10 + dict.ONES[SubStr(gruppe, 1, -4)])
		if (InStr(gruppe, 'und')) {
			arr := StrSplit(gruppe, 'und')
			if (!dict.ONES.Has(arr[1]))
				throw ValueError("Einserwert nicht erkannt: " arr[1])
			if (!dict.TENS.Has(arr[2]))
				throw ValueError("Zehnerwert nicht erkannt: " arr[2])
			return (result += (dict.ONES[arr[1]] + dict.TENS[arr[2]]))
		}
		return result
	}

	static DE_DICT := {
		TO: {
			ONES: Map('1', "ein", '2', "zwei", '3', "drei", '4', "vier", '5', "fünf", '6', "sechs", '7', "sieben", '8', "acht", '9', "neun"),
			TENS: Map('1', "zehn", '2', "zwanzig", '3', "dreißig", '4', "vierzig", '5', "fünfzig", '6', "sechzig", '7', "siebzig", '8', "achtzig", '9', "neunzig" ),
			LATIN: Map(6, "Mi", 12, "Bi", 18, "Tri", 24, "Quadri", 30, "Quinti", 36, "Sexti", 42, "Septi", 48, "Okti", 56, "Noni", 60, "Dezi"),
			EXTRA: Map('11', "elf", '12', "zwölf", '16', "sechzehn", '17', "siebzehn")
		},
		FROM: {
			ONES: Map("ein", '1', "eine", '1', "eins", '1', "zwei", '2', "drei", '3', "vier", '4', "fünf", '5', "sech", '6', "sechs", '6', "sieb", '7', "sieben", '7', "acht", '8', "neun", '9'),
			TENS: Map("zehn", '10', "elf", '11', "zwölf", '12', "zwanzig", '20', "dreißig", '30', "vierzig", '40', "fünfzig", '50', "sechzig", '60', "siebzig", '70', "achtzig", '80', "neunzig", '90'),
			HUNDREDS: Map("ein", '100', "zwei", '200', "drei", '300', "vier", '400', "fünf", '500', "sechs", '600', "sieben", '700', "acht", '800', "neun", '900'),
			LATIN: Map("mi", '6', "bi", '12', "tri", '18', "quadri", '24', "quinti", '30', "sexti", '36', "septi", '42', "okti", '48', "noni", '56', "dezi", '60')
		}
	}
}