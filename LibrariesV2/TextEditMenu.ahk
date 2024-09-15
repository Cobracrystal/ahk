; https://github.com/cobracrystal/ahk
#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\jsongo.ahk"
class TextEditMenu {

	static __New() {
		this.dictionaryPath := A_WorkingDir "\TextEditMenu\dictionary.json"
		this.dictionary := Map()
		if !(FileExist(this.dictionaryPath)) {
			SplitPath(this.dictionaryPath, , &dir)
			if !(DirExist(dir))
				DirCreate(dir)
			this.dictionary := this.generateDictionary()
			FileAppend(jsongo.Stringify(this.dictionary,,"`t"), this.dictionaryPath, "UTF-8")
		}
		else
			this.dictionary := jsongo.Parse(FileRead(this.dictionaryPath, "UTF-8"))
		replFN := (alphTo) => modifySelectedText(this.replaceCharacters.bind(this), "mixed", alphTo)
		caseMenu := Menu()
		caseMenu.Add("Random Case", (*) => modifySelectedText(this.randomCase.bind(this)))
		caseMenu.Add("All Uppercase", (*) => modifySelectedText((t) => Format("{:U}", StrReplace(t, "ß", "ẞ"))))
		caseMenu.Add("All Lowercase", (*) => modifySelectedText((t) => Format("{:L}", StrReplace(t, "ẞ", "ß"))))
		caseMenu.Add("Proper Capitals", (*) => modifySelectedText((t) => Format("{:T}", t)))
		fontMenu := Menu()
		fontMenu.Add("Serif Standard", (*) => replFN("serif"))
		fontMenu.Default := "Serif Standard"
		fontMenu.Add("Superscript", (*) => replFN("superscript"))
		fontMenu.Add("Small Capitals", (*) => replFN("smallcapitals"))
		; fontMenu.Add("Italics", (*) => replFN("italic")) ; PERSISTING ITALIC/BOLD ie mathSf -> Italic MathSf instead of SerifItalic
		; fontMenu.Add("Bold", (*) => replFN("bold"))
		fontMenu.Add("𝐁𝐨𝐥𝐝 𝐒𝐞𝐫𝐢𝐟", (*) => replFN("serifBold"))
		fontMenu.Add("𝐼𝑡𝑎𝑙𝑖𝑐 𝑆𝑒𝑟𝑖𝑓", (*) => replFN("serifItalic"))
		fontMenu.Add("𝑩𝒐𝒍𝒅 𝑰𝒕𝒂𝒍𝒊𝒄 𝑺𝒆𝒓𝒊𝒇",	(*) => replFN("serifBoldItalic"))
		fontMenu.Add("𝖬𝖺𝗍𝗁𝖲𝖥", (*) => replFN("mathSF"))
		fontMenu.Add("𝗕𝗼𝗹𝗱 𝗠𝗮𝘁𝗵𝗦𝗙", (*) => replFN("mathSFBold"))
		fontMenu.Add("𝘐𝘵𝘢𝘭𝘪𝘤 𝘔𝘢𝘵𝘩𝘚𝘍", (*) => replFN("mathSFItalic"))
		fontMenu.Add("𝘽𝙤𝙡𝙙 𝙄𝙩𝙖𝙡𝙞𝙘 𝙈𝙖𝙩𝙝𝙎𝙁", (*) => replFN("mathSFBoldItalic"))
		fontMenu.Add("𝙼𝚘𝚗𝚘𝚜𝚙𝚊𝚌𝚎", (*) => replFN("monospace"))
		fontMenu.Add("Ｗｉｄｅｓｐａｃｅ", (*) => replFN("widespace"))
		fontMenu.Add("𝕄𝕒𝕥𝕙𝔹𝔹", (*) => replFN("mathBB"))
		fontMenu.Add("ℳ𝒶𝓉𝒽𝒞𝒶𝓁", (*) => replFN("mathCal"))
		fontMenu.Add("𝓑𝓸𝓵𝓭 𝓜𝓪𝓽𝓱𝓒𝓪𝓵", (*) => replFN("mathCalBold"))
		fontMenu.Add("𝔐𝔞𝔱𝔥𝔉𝔯𝔞𝔨", (*) => replFN("mathFraktur"))
		fontMenu.Add("𝕭𝖔𝖑𝖉 𝕸𝖆𝖙𝖍𝕱𝖗𝖆𝖐", (*) => replFN("mathFrakturBold"))
		fontMenu.Add("丂卄闩尺尸 丂⼕尺讠尸〸", (*) => replFN("sharpscript"))
		runeMenu := Menu()
		runeMenu.Add("Runify (DE)", (*) => modifySelectedText(this.runify.bind(this), "DE"))
		runeMenu.Add("Runify (EN)", (*) => modifySelectedText(this.runify.bind(this), "EN"))
		runeMenu.Add("Derunify (DE)", (*) => modifySelectedText(this.derunify.bind(this), "DE"))
		runeMenu.Add("Derunify (EN)", (*) => modifySelectedText(this.derunify.bind(this), "EN"))
		textModifyMenu := Menu()
		textModifyMenu.Add("Letter Case", caseMenu)
		textModifyMenu.Add("Font", fontMenu)
		textModifyMenu.Add("Runes", runeMenu)
		textModifyMenu.Add("Reverse", (*) => modifySelectedText(reverseString))
		textModifyMenu.Add("Mirror", (*) => modifySelectedText(this.mirror.bind(this)))
		textModifyMenu.Add("Flip", (*) => modifySelectedText(this.flip.bind(this)))
		textModifyMenu.Add("Spaced Text", (*) => modifySelectedText(this.spreadString.bind(this), " "))
		textModifyMenu.Add("Add Zalgo", (*) => modifySelectedText(this.zalgo.bind(this), 5))
		;	menu_RemoveSpace(textModifyMenu.Handle) ; this also decreases vertical spacing.
		this.menu := textModifyMenu
	}

	static showMenu() => this.menu.show()

	static randomCase(text) {
		result := ""
		c := ""
		for i, e in StrSplitUTF8(text) {
			caseFormat := Random(0, 1)
			if (caseFormat)
				c := Format("{:U}", e)
			else
				c := Format("{:L}", e)
			if (e = "i")
				c := "i"
			else if (e = "l")
				c := "L"
			else if (e == "ß" || e == "ẞ")
				c := (caseFormat ? "ß" : "ẞ")
			result := result . c
		}
		return result 
	}

	; works one character at a time
	static replaceCharacters(text, alphNameFrom, alphnameTo) {
		serif := ""
		result := ""
		foundAlphabets := [] ; TODO: COLLECT ENCOUNTERED ALPHABETS. THEN, IF alphnameTo is "SWAP" AND ALPHABETS ARE EXACTLY TWO, SWAP THEM. USE FOR MIRROR, FLIP ETC.
		if (alphNameFrom == "mixed") {
			for i, e in StrSplitUTF8(text) {
				serifSymbol := e
				if !(objContainsValue(this.dictionary["otherAlphabet"]["serif"], e))
					for alphName, alphMap in this.dictionary["fromAlphabet"] {
						if (alphMap.Has(e)) {
							serifSymbol := alphMap[e]
							break
						}
					}
				serif .= serifSymbol
			}
		}
		else if (alphNameFrom != "serif") {
			if !(this.dictionary["fromAlphabet"].Has(alphNameFrom))
				return text
			alph := this.dictionary["fromAlphabet"][alphNameFrom]
			for i, e in StrSplitUTF8(text) {
				if (alph.Has(e))
					serif .= alph[e]
				else
					serif .= e
			}
		}
		else
			serif := text
		if !(this.dictionary["toAlphabet"].Has(alphnameTo))
			return serif
		return replaceCharacters(serif, this.dictionary["toAlphabet"][alphnameTo])
	}

	static spreadString(text, delimiter) {
		result := ""
		for i, e in StrSplitUTF8(text)
			result .= e . delimiter
		return RTrim(result, delimiter)
	}

	static mirror(text) => this.replaceCharacters(reverseString(text), "mixed", "mirror")

	static flip(text) => this.replaceCharacters(reverseString(text), "mixed", "upsidedown")

	static zalgo(str, intensity) {
		len := this.dictionary["otherAlphabet"]["zalgo"].length
		newStr := ""
		for i, e in StrSplitUTF8(str) {
			newStr .= e
			Loop (intensity)
				newStr .= this.dictionary["otherAlphabet"]["zalgo"][Random(1, len)]
		}
		return newStr
	}

	static runify(text, language) {
		runicStr := Format("{:L}", StrReplace(text, "ẞ", "ß"))
		for needle, repl in this.dictionary["otherAlphabet"]["runes"]["to"][language]["multichar"]
			runicStr := StrReplace(runicStr, needle, repl, 0)
		for needle, repl in this.dictionary["otherAlphabet"]["runes"]["to"]["global"]["multichar"]
			runicStr := StrReplace(runicStr, needle, repl, 0)
		runicStr := replaceCharacters(runicStr, this.dictionary["otherAlphabet"]["runes"]["to"][language]["singlechar"])
		runicStr := replaceCharacters(runicStr, this.dictionary["otherAlphabet"]["runes"]["to"]["global"]["singlechar"])
		return runicStr
	}

	static derunify(text, language) {
		latinStr := text
		for needle, repl in this.dictionary["otherAlphabet"]["runes"]["from"][language]["multichar"]
			latinStr := StrReplace(latinStr, needle, repl, 0)
		for needle, repl in this.dictionary["otherAlphabet"]["runes"]["from"]["global"]["multichar"]
			latinStr := StrReplace(latinStr, needle, repl, 0)
		for needle, repl in this.dictionary["otherAlphabet"]["runes"]["from"]["extra"]["multichar"]
			latinStr := StrReplace(latinStr, needle, repl, 0)
		latinStr := replaceCharacters(latinStr, this.dictionary["otherAlphabet"]["runes"]["from"][language]["singlechar"])
		latinStr := replaceCharacters(latinStr, this.dictionary["otherAlphabet"]["runes"]["from"]["global"]["singlechar"])
		latinStr := replaceCharacters(latinStr, this.dictionary["otherAlphabet"]["runes"]["from"]["extra"]["singlechar"])
		return latinStr
	}

	static generateDictionary() {
		toAlphabet := Map()
		fromAlphabet := Map()
		serif := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
		toStrings := Map(
			"serifItalic", "𝑎𝑏𝑐𝑑𝑒𝑓𝑔ℎ𝑖𝑗𝑘𝑙𝑚𝑛𝑜𝑝𝑞𝑟𝑠𝑡𝑢𝑣𝑤𝑥𝑦𝑧𝐴𝐵𝐶𝐷𝐸𝐹𝐺𝐻𝐼𝐽𝐾𝐿𝑀𝑁𝑂𝑃𝑄𝑅𝑆𝑇𝑈𝑉𝑊𝑋𝑌𝑍0123456789",
			"serifBold", "𝐚𝐛𝐜𝐝𝐞𝐟𝐠𝐡𝐢𝐣𝐤𝐥𝐦𝐧𝐨𝐩𝐪𝐫𝐬𝐭𝐮𝐯𝐰𝐱𝐲𝐳𝐀𝐁𝐂𝐃𝐄𝐅𝐆𝐇𝐈𝐉𝐊𝐋𝐌𝐍𝐎𝐏𝐐𝐑𝐒𝐓𝐔𝐕𝐖𝐗𝐘𝐙𝟎𝟏𝟐𝟑𝟒𝟓𝟔𝟕𝟖𝟗",
			"serifBoldItalic", "𝒂𝒃𝒄𝒅𝒆𝒇𝒈𝒉𝒊𝒋𝒌𝒍𝒎𝒏𝒐𝒑𝒒𝒓𝒔𝒕𝒖𝒗𝒘𝒙𝒚𝒛𝑨𝑩𝑪𝑫𝑬𝑭𝑮𝑯𝑰𝑱𝑲𝑳𝑴𝑵𝑶𝑷𝑸𝑹𝑺𝑻𝑼𝑽𝑾𝑿𝒀𝒁𝟎𝟏𝟐𝟑𝟒𝟓𝟔𝟕𝟖𝟗",
			"mathSF", "𝖺𝖻𝖼𝖽𝖾𝖿𝗀𝗁𝗂𝗃𝗄𝗅𝗆𝗇𝗈𝗉𝗊𝗋𝗌𝗍𝗎𝗏𝗐𝗑𝗒𝗓𝖠𝖡𝖢𝖣𝖤𝖥𝖦𝖧𝖨𝖩𝖪𝖫𝖬𝖭𝖮𝖯𝖰𝖱𝖲𝖳𝖴𝖵𝖶𝖷𝖸𝖹𝟢𝟣𝟤𝟥𝟦𝟧𝟨𝟩𝟪𝟫", ; SF = Sans Serif
			"mathSFBold", "𝗮𝗯𝗰𝗱𝗲𝗳𝗴𝗵𝗶𝗷𝗸𝗹𝗺𝗻𝗼𝗽𝗾𝗿𝘀𝘁𝘂𝘃𝘄𝘅𝘆𝘇𝗔𝗕𝗖𝗗𝗘𝗙𝗚𝗛𝗜𝗝𝗞𝗟𝗠𝗡𝗢𝗣𝗤𝗥𝗦𝗧𝗨𝗩𝗪𝗫𝗬𝗭𝟬𝟭𝟮𝟯𝟰𝟱𝟲𝟳𝟴𝟵",
			"mathSFItalic", "𝘢𝘣𝘤𝘥𝘦𝘧𝘨𝘩𝘪𝘫𝘬𝘭𝘮𝘯𝘰𝘱𝘲𝘳𝘴𝘵𝘶𝘷𝘸𝘹𝘺𝘻𝘈𝘉𝘊𝘋𝘌𝘍𝘎𝘏𝘐𝘑𝘒𝘓𝘔𝘕𝘖𝘗𝘘𝘙𝘚𝘛𝘜𝘝𝘞𝘟𝘠𝘡𝟢𝟣𝟤𝟥𝟦𝟧𝟨𝟩𝟪𝟫",
			"mathSFBoldItalic", "𝙖𝙗𝙘𝙙𝙚𝙛𝙜𝙝𝙞𝙟𝙠𝙡𝙢𝙣𝙤𝙥𝙦𝙧𝙨𝙩𝙪𝙫𝙬𝙭𝙮𝙯𝘼𝘽𝘾𝘿𝙀𝙁𝙂𝙃𝙄𝙅𝙆𝙇𝙈𝙉𝙊𝙋𝙌𝙍𝙎𝙏𝙐𝙑𝙒𝙓𝙔𝙕𝟬𝟭𝟮𝟯𝟰𝟱𝟲𝟳𝟴𝟵",
			"mathCal", "𝒶𝒷𝒸𝒹𝑒𝒻ℊ𝒽𝒾𝒿𝓀𝓁𝓂𝓃ℴ𝓅𝓆𝓇𝓈𝓉𝓊𝓋𝓌𝓍𝓎𝓏𝒜ℬ𝒞𝒟ℰℱ𝒢ℋℐ𝒥𝒦ℒℳ𝒩𝒪𝒫𝒬ℛ𝒮𝒯𝒰𝒱𝒲𝒳𝒴𝒵𝟢𝟣𝟤𝟥𝟦𝟧𝟨𝟩𝟪𝟫", ; Cal = Calligraphy
			"mathCalBold", "𝓪𝓫𝓬𝓭𝓮𝓯𝓰𝓱𝓲𝓳𝓴𝓵𝓶𝓷𝓸𝓹𝓺𝓻𝓼𝓽𝓾𝓿𝔀𝔁𝔂𝔃𝓐𝓑𝓒𝓓𝓔𝓕𝓖𝓗𝓘𝓙𝓚𝓛𝓜𝓝𝓞𝓟𝓠𝓡𝓢𝓣𝓤𝓥𝓦𝓧𝓨𝓩𝟬𝟭𝟮𝟯𝟰𝟱𝟲𝟳𝟴𝟵",
			"mathFraktur", "𝔞𝔟𝔠𝔡𝔢𝔣𝔤𝔥𝔦𝔧𝔨𝔩𝔪𝔫𝔬𝔭𝔮𝔯𝔰𝔱𝔲𝔳𝔴𝔵𝔶𝔷𝔄𝔅ℭ𝔇𝔈𝔉𝔊ℌℑ𝔍𝔎𝔏𝔐𝔑𝔒𝔓𝔔ℜ𝔖𝔗𝔘𝔙𝔚𝔛𝔜ℨ𝟢𝟣𝟤𝟥𝟦𝟧𝟨𝟩𝟪𝟫",
			"mathFrakturBold", "𝖆𝖇𝖈𝖉𝖊𝖋𝖌𝖍𝖎𝖏𝖐𝖑𝖒𝖓𝖔𝖕𝖖𝖗𝖘𝖙𝖚𝖛𝖜𝖝𝖞𝖟𝕬𝕭𝕮𝕯𝕰𝕱𝕲𝕳𝕴𝕵𝕶𝕷𝕸𝕹𝕺𝕻𝕼𝕽𝕾𝕿𝖀𝖁𝖂𝖃𝖄𝖅𝟬𝟭𝟮𝟯𝟰𝟱𝟲𝟳𝟴𝟵",
			"monospace", "𝚊𝚋𝚌𝚍𝚎𝚏𝚐𝚑𝚒𝚓𝚔𝚕𝚖𝚗𝚘𝚙𝚚𝚛𝚜𝚝𝚞𝚟𝚠𝚡𝚢𝚣𝙰𝙱𝙲𝙳𝙴𝙵𝙶𝙷𝙸𝙹𝙺𝙻𝙼𝙽𝙾𝙿𝚀𝚁𝚂𝚃𝚄𝚅𝚆𝚇𝚈𝚉𝟶𝟷𝟸𝟹𝟺𝟻𝟼𝟽𝟾𝟿", ; TT = monospace
			"widespace", "ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ０１２３４５６７８９",
			"mathBB", "𝕒𝕓𝕔𝕕𝕖𝕗𝕘𝕙𝕚𝕛𝕜𝕝𝕞𝕟𝕠𝕡𝕢𝕣𝕤𝕥𝕦𝕧𝕨𝕩𝕪𝕫𝔸𝔹ℂ𝔻𝔼𝔽𝔾ℍ𝕀𝕁𝕂𝕃𝕄ℕ𝕆ℙℚℝ𝕊𝕋𝕌𝕍𝕎𝕏𝕐ℤ𝟘𝟙𝟚𝟛𝟜𝟝𝟞𝟟𝟠𝟡", ; BB = Blackboard
			"superscript", "ᵃᵇᶜᵈᵉᶠᵍʰᶦʲᵏˡᵐⁿᵒᵖᵠʳˢᵗᵘᵛʷˣʸᶻᴬᴮᶜᴰᴱᶠᴳᴴᴵᴶᴷᴸᴹᴺᴼᴾᵠᴿˢᵀᵁⱽᵂˣʸᶻ⁰¹²³⁴⁵⁶⁷⁸⁹",
			"smallCapitals", "ᴀʙᴄᴅᴇғɢʜɪᴊᴋʟᴍɴᴏᴘǫʀsᴛᴜᴠᴡxʏᴢᴀʙᴄᴅᴇғɢʜɪᴊᴋʟᴍɴᴏᴘǫʀsᴛᴜᴠᴡxʏᴢ0123456789",
			"mirror", "ɒdɔbɘʇϱʜiįʞlmnoqpɿƨɈυvwxγzAઘƆႧƎᆿӘHIႱʞ⅃MИOԳϘЯƧTUVWXYZ0ƖςƐμटმ٢8୧",
			"upsidedown", "ɐqɔpǝⅎƃɥᴉɾʞʅɯuodbɹsʇnʌʍxʎz∀ꓭϽᗡƎᖵ⅁HIᒋꓘ⅂ꟽNOԀꝹꓤSꓕՈɅϺX⅄Z0⇂↊↋ᔭ59𝘓86",
			"sharpscript", "闩⻏⼕ᗪ🝗ﾁᎶ卄讠丿长㇄爪𝓝ㄖ尸Ɋ尺丂〸ㄩᐯ山〤丫Ⲍ闩乃⼕ᗪ㠪千Ꮆ廾工丿长㇄爪𝓝龱尸Ɋ尺丂ㄒㄩᐯ山乂ㄚ乙0丨己㇌丩567〥9"
		)
		; [small letters] [CAPITAL LETTERS] [NUMBERS]
		; https://milde.users.sourceforge.net/LUCR/Math/unimathsymbols.pdf
		; https://en.wikipedia.org/wiki/Mathematical_Alphanumeric_Symbols
		for i, e in toStrings {
			toAlphabet[i] := mapFromArrays(StrSplitUTF8(serif), StrSplitUTF8(e))
			fromAlphabet[i] := mapFromArrays(StrSplitUTF8(e), StrSplitUTF8(serif))
		}
		otherAlphabet := Map()
		otherAlphabet["zalgo"] := ["̾", "̿", "̀", "́", "͂", "̓", "̈́", "ͅ", "͆", "͇", "͈", "͉", "͊", "͋", "͌", "͍", "͎", "͏", "͐", "͑", "͒", "͓", "͔", "͕", "͖", "͗", "͘", "͙", "͚", "͛", "͜", "͝", "͞", "͟", "͠", "͡", "͢", "ͣ", "ͤ", "ͥ", "ͦ", "ͧ", "ͨ", "ͩ", "ͪ", "ͫ", "ͬ", "ͭ", "ͮ"]
		otherAlphabet["serif"] := StrSplitUTF8(serif)
		; RUNES
		runes := Map("to", Map( "DE", Map("multichar", Map(), "singlechar", Map()), 
								"EN", Map("multichar", Map(), "singlechar", Map()),
								"global", Map("multichar", Map(), "singlechar", Map())),
					"from", Map("DE", Map("multichar", Map(), "singlechar", Map()), 
								"EN", Map("multichar", Map(), "singlechar", Map()), 
								"extra", Map("multichar", Map(), "singlechar", Map()),
								"global", Map("multichar", Map(), "singlechar", Map())))
		latinBidirectional := ["a","b","d","e","f","g","h","i","l","m","n","o","p","r","s","t","u","v","x","z","ch","sh","th","ei","ng"]
		runesBidirectional := ["ᚫ","ᛒ","ᛞ","ᛖ","ᚠ","ᚷ","ᚻ","ᛁ","ᛚ","ᛗ","ᚾ","ᛟ","ᛈ","ᚱ","ᛋ","ᛏ","ᚢ","ᚹ","ᚲᛋ","ᛉ","ᚳ","ᛪ","ᚦ","ᛇ","ᛝ"]
		for i, letter in latinBidirectional {
			rune := runesBidirectional[i]
			runes["to"]["global"][(StrLen(letter) > 1 ? "multichar" : "singlechar")][letter] := rune
			runes["from"]["global"][(StrLen(rune) > 1 ? "multichar" : "singlechar")][rune] := letter
		}
		translateOneDirectional1 := ["c","k","j","y"], translateOneDirectional2 := ["ᚲ","ᚲ","ᛃ","ᛃ"]
		for i, letter in translateOneDirectional1 {
			runes["to"]["global"]["singlechar"][letter] := translateOneDirectional2[i]
		}
		translateCircular1 := ["ä","ö","ü","ß"], translateCircular2 := ["ᚨᛖ","ᛟᛖ","ᚢᛖ","ᛋᛋ"], translateCircular3 := ["ae","oe","ue","ss"]
		for i, letter in translateCircular1 {
			runes["to"]["global"]["singlechar"][letter] := translateCircular2[i]
			runes["from"]["global"]["multichar"][translateCircular2[i]] := translateCircular3[i]
		}
		translateLanguageLatin := ["q", "w"], translateLanguageRunicDE := ["ᚲᚹ","ᚹ"], translateLanguageRunicEN := ["ᚲᚢ","ᚢ"]
		for i, letter in translateLanguageLatin {
			runes["to"]["DE"]["singlechar"][letter] := translateLanguageRunicDE[i]
			runes["to"]["EN"]["singlechar"][letter] := translateLanguageRunicEN[i]
		}
		translateLanguageRunes := ["ᚲ","ᛃ","ᚲᚹ","ᚲᚢ"], translateLanguageLatinDE := ["k","j","q","ku"], translateLanguageLatinEN := ["c","y","cv","q"]
		for i, rune in translateLanguageRunes {
			runes["from"]["DE"][(StrLen(rune) > 1 ? "multichar" : "singlechar")][rune] := translateLanguageLatinDE[i]
			runes["from"]["EN"][(StrLen(rune) > 1 ? "multichar" : "singlechar")][rune] := translateLanguageLatinEN[i]
		}
		runesExtra := ["ᚠ","ᚡ","ᚢ","ᚣ","ᚤ","ᚥ","ᚧ","ᚨ","ᚩ","ᚪ","ᚫ","ᚬ","ᚭ","ᚮ","ᚯ","ᚰ","ᚱ","ᚲ","ᚳ","ᚴ","ᚵ","ᚶ","ᚷ","ᚸ","ᚹ","ᚺ","ᚻ","ᚼ","ᚽ","ᚾ","ᚿ","ᛀ","ᛁ","ᛂ","ᛃ","ᛄ","ᛅ","ᛆ","ᛇ","ᛈ","ᛉ","ᛊ","ᛋ","ᛌ","ᛍ","ᛎ","ᛏ","ᛐ","ᛑ","ᛒ","ᛓ","ᛔ","ᛕ","ᛖ","ᛗ","ᛘ","ᛙ","ᛚ","ᛛ","ᛜ","ᛝ","ᛞ","ᛟ","ᛠ","ᛡ","ᛢ","ᛣ","ᛤ","ᛥ","ᛦ","ᛧ","ᛨ","ᛩ","ᛪ"]
		latinExtra := ["f","v","u","y","y","w","th","a","o","a","a","o","o","o","ö","o","r","k","ch","k","g","eng","g","g","v","h","h","h","h","n","n","n","i","e","y","j","a","a","ei","p","z","s","s","s","c","z","t","t","d","b","b","p","p","e","m","m","m","l","l","ng","ng","d","o","ea","io","qu","ch","k","st","r","y","rr","qu","sch"]
		for i, e in runesExtra {
			runes["from"]["extra"]["singlechar"][e] := latinExtra[i]
		}
		otherAlphabet["runes"] := runes
		dictionary := Map("toAlphabet", toAlphabet, "fromAlphabet", fromAlphabet, "otherAlphabet", otherAlphabet)
		return dictionary
	}
}