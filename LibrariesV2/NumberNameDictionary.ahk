#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"
mainfun()

mainfun() {
	a := NumberNames.getName(87243323244)
}

class NumberNames {
	static getName(num) {
		if (num == 0)
			return "null"
		name := ""
		str := ""
		isEnd := false
		if (SubStr(num, 1, 1) == "-") {
			name := "minus "
			num := SubStr(num, 2)
		}
		groups := this.splitIntoTriGroups(num)
		for i, e in groups { ; THIS WORKS
			triname := this.getGroupName(e, i - 1)
			groupidentifier := this.getSeparator(i)
			str .= triname . groupidentifier
		}
		return str
	}

	static getNumber(name) {
		return 0
	}

	static getGroupName(numStr, isPrefix) {
		; 0 - 999
		arr := StrSplit(numStr)
		huns := arr[1]
		tens := arr[2]
		ones := arr[3]
		name := ""
		hN := this.DE_DICT.HUNDRED.%huns%
		hN := (hN ? hN . "hundert" : "")
		switch tens {
			case 2, 3, 4, 5, 6, 7, 8, 9:
				tensName := this.DE_DICT.TENS.%tens%
			case 0:
			case 1:
		}
	}

	static getSeparator(groupIndex) {
		return ""
	}

	static splitIntoTriGroups(num) {
		groups := []
		offset := Mod(StrLen(num), 3)
		if (offset > 0)
			groups.push(SubStr(num, 1, offset))
		while (s := SubStr(num, offset + 1, 3)) {
			groups.push(s)
			offset += 3
		}
		return groups
	}

	static DE_DICT := {
		TO: {
			ONES: Map(1, "ein", 2, "zwei", 3, "drei", 4, "vier", 5, "fünf", 6, "sechs", 7, "sieben", 8, "acht", 9, "neun"),
			TENS: Map(1, "zehn", 2, "zwanzig", 3, "dreißig", 4, "vierzig", 5, "fünfzig", 6, "sechzig", 7, "siebzig", 8, "achtzig", 9, "neunzig" ),
			LATIN: Map(6, "Mi", 12, "Bi", 18, "Tri", 24, "Quadri", 30, "Quinti", 36, "Sexti", 42, "Septi", 48, "Okti", 56, "Noni", 60, "Dezi"),
			EXTRA: Map(11, "elf", 12, "zwölf", 16, "sechzehn", 17, "siebzehn")
		},
		FROM: {
			ONES: Map("ein", 1, "eine", 1, "eins", 1, "zwei", 2, "drei", 3, "vier", 4, "fünf", 5, "sech", 6, "sechs", 6, "sieb", 7, "sieben", 7, "acht", 8, "neun", 9),
			TENS: Map("zehn", 10, "elf", 11, "zwölf", 12, "zwanzig", 20, "dreißig", 30, "vierzig", 40, "fünfzig", 50, "sechzig", 60, "siebzig", 70, "achtzig", 80, "neunzig", 90),
			HUNDREDS: Map("ein", 100, "zwei", 200, "drei", 300, "vier", 400, "fünf", 500, "sechs", 600, "sieben", 700, "acht", 800, "neun", 900),
			LATIN: Map("mi", 6, "bi", 12, "tri", 18, "quadri", 24, "quinti", 30, "sexti", 36, "septi", 42, "okti", 48, "noni", 56, "dezi", 60)
		}
	}
}