#Include %A_ScriptDir%\LibrariesV2\BasicUtilities.ahk

class TextEditMenu {

	static __New() {
		this.alphabets := Map()
		serifNormal := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		strings := Map("serifItalic", "𝑎𝑏𝑐𝑑𝑒𝑓𝑔ℎ𝑖𝑗𝑘𝑙𝑚𝑛𝑜𝑝𝑞𝑟𝑠𝑡𝑢𝑣𝑤𝑥𝑦𝑧𝐴𝐵𝐶𝐷𝐸𝐹𝐺𝐻𝐼𝐽𝐾𝐿𝑀𝑁𝑂𝑃𝑄𝑅𝑆𝑇𝑈𝑉𝑊𝑋𝑌𝑍0123456789"
			, "serifBold", "𝐚𝐛𝐜𝐝𝐞𝐟𝐠𝐡𝐢𝐣𝐤𝐥𝐦𝐧𝐨𝐩𝐪𝐫𝐬𝐭𝐮𝐯𝐰𝐱𝐲𝐳𝐀𝐁𝐂𝐃𝐄𝐅𝐆𝐇𝐈𝐉𝐊𝐋𝐌𝐍𝐎𝐏𝐐𝐑𝐒𝐓𝐔𝐕𝐖𝐗𝐘𝐙𝟎𝟏𝟐𝟑𝟒𝟓𝟔𝟕𝟖𝟗"
			, "serifBoldItalic", "𝒂𝒃𝒄𝒅𝒆𝒇𝒈𝒉𝒊𝒋𝒌𝒍𝒎𝒏𝒐𝒑𝒒𝒓𝒔𝒕𝒖𝒗𝒘𝒙𝒚𝒛𝑨𝑩𝑪𝑫𝑬𝑭𝑮𝑯𝑰𝑱𝑲𝑳𝑴𝑵𝑶𝑷𝑸𝑹𝑺𝑻𝑼𝑽𝑾𝑿𝒀𝒁𝟎𝟏𝟐𝟑𝟒𝟓𝟔𝟕𝟖𝟗"
			, "mathSF", "𝖺𝖻𝖼𝖽𝖾𝖿𝗀𝗁𝗂𝗃𝗄𝗅𝗆𝗇𝗈𝗉𝗊𝗋𝗌𝗍𝗎𝗏𝗐𝗑𝗒𝗓𝖠𝖡𝖢𝖣𝖤𝖥𝖦𝖧𝖨𝖩𝖪𝖫𝖬𝖭𝖮𝖯𝖰𝖱𝖲𝖳𝖴𝖵𝖶𝖷𝖸𝖹𝟢𝟣𝟤𝟥𝟦𝟧𝟨𝟩𝟪𝟫" ; SF = Sans Serif
			, "mathSFBold", "𝗮𝗯𝗰𝗱𝗲𝗳𝗴𝗵𝗶𝗷𝗸𝗹𝗺𝗻𝗼𝗽𝗾𝗿𝘀𝘁𝘂𝘃𝘄𝘅𝘆𝘇𝗔𝗕𝗖𝗗𝗘𝗙𝗚𝗛𝗜𝗝𝗞𝗟𝗠𝗡𝗢𝗣𝗤𝗥𝗦𝗧𝗨𝗩𝗪𝗫𝗬𝗭𝟬𝟭𝟮𝟯𝟰𝟱𝟲𝟳𝟴𝟵"
			, "mathSFItalic", "𝘢𝘣𝘤𝘥𝘦𝘧𝘨𝘩𝘪𝘫𝘬𝘭𝘮𝘯𝘰𝘱𝘲𝘳𝘴𝘵𝘶𝘷𝘸𝘹𝘺𝘻𝘈𝘉𝘊𝘋𝘌𝘍𝘎𝘏𝘐𝘑𝘒𝘓𝘔𝘕𝘖𝘗𝘘𝘙𝘚𝘛𝘜𝘝𝘞𝘟𝘠𝘡𝟢𝟣𝟤𝟥𝟦𝟧𝟨𝟩𝟪𝟫"
			, "mathSFBoldItalic", "𝙖𝙗𝙘𝙙𝙚𝙛𝙜𝙝𝙞𝙟𝙠𝙡𝙢𝙣𝙤𝙥𝙦𝙧𝙨𝙩𝙪𝙫𝙬𝙭𝙮𝙯𝘼𝘽𝘾𝘿𝙀𝙁𝙂𝙃𝙄𝙅𝙆𝙇𝙈𝙉𝙊𝙋𝙌𝙍𝙎𝙏𝙐𝙑𝙒𝙓𝙔𝙕𝟬𝟭𝟮𝟯𝟰𝟱𝟲𝟳𝟴𝟵"
			, "mathCal", "𝒶𝒷𝒸𝒹ℯ𝒻ℊ𝒽𝒾𝒿𝓀𝓁𝓂𝓃ℴ𝓅𝓆𝓇𝓈𝓉𝓊𝓋𝓌𝓍𝓎𝓏𝒜ℬ𝒞𝒟ℰℱ𝒢ℋℐ𝒥𝒦ℒℳ𝒩𝒪𝒫𝒬ℛ𝒮𝒯𝒰𝒱𝒲𝒳𝒴𝒵𝟢𝟣𝟤𝟥𝟦𝟧𝟨𝟩𝟪𝟫" ; Cal = Calligraphy
			, "mathCalBold", "𝓪𝓫𝓬𝓭𝓮𝓯𝓰𝓱𝓲𝓳𝓴𝓵𝓶𝓷𝓸𝓹𝓺𝓻𝓼𝓽𝓾𝓿𝔀𝔁𝔂𝔃𝓐𝓑𝓒𝓓𝓔𝓕𝓖𝓗𝓘𝓙𝓚𝓛𝓜𝓝𝓞𝓟𝓠𝓡𝓢𝓣𝓤𝓥𝓦𝓧𝓨𝓩𝟬𝟭𝟮𝟯𝟰𝟱𝟲𝟳𝟴𝟵"
			, "mathFraktur", "𝔞𝔟𝔠𝔡𝔢𝔣𝔤𝔥𝔦𝔧𝔨𝔩𝔪𝔫𝔬𝔭𝔮𝔯𝔰𝔱𝔲𝔳𝔴𝔵𝔶𝔷𝔄𝔅ℭ𝔇𝔈𝔉𝔊ℌℑ𝔍𝔎𝔏𝔐𝔑𝔒𝔓𝔔ℜ𝔖𝔗𝔘𝔙𝔚𝔛𝔜ℨ𝟢𝟣𝟤𝟥𝟦𝟧𝟨𝟩𝟪𝟫"
			, "mathFrakturBold", "𝖆𝖇𝖈𝖉𝖊𝖋𝖌𝖍𝖎𝖏𝖐𝖑𝖒𝖓𝖔𝖕𝖖𝖗𝖘𝖙𝖚𝖛𝖜𝖝𝖞𝖟𝕬𝕭𝕮𝕯𝕰𝕱𝕲𝕳𝕴𝕵𝕶𝕷𝕸𝕹𝕺𝕻𝕼𝕽𝕾𝕿𝖀𝖁𝖂𝖃𝖄𝖅𝟬𝟭𝟮𝟯𝟰𝟱𝟲𝟳𝟴𝟵"
			, "monospace", "𝚊𝚋𝚌𝚍𝚎𝚏𝚐𝚑𝚒𝚓𝚔𝚕𝚖𝚗𝚘𝚙𝚚𝚛𝚜𝚝𝚞𝚟𝚠𝚡𝚢𝚣𝙰𝙱𝙲𝙳𝙴𝙵𝙶𝙷𝙸𝙹𝙺𝙻𝙼𝙽𝙾𝙿𝚀𝚁𝚂𝚃𝚄𝚅𝚆𝚇𝚈𝚉𝟶𝟷𝟸𝟹𝟺𝟻𝟼𝟽𝟾𝟿" ; TT = monospace
			, "widespace", "ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ０１２３４５６７８９"
			, "mathBB", "𝕒𝕓𝕔𝕕𝕖𝕗𝕘𝕙𝕚𝕛𝕜𝕝𝕞𝕟𝕠𝕡𝕢𝕣𝕤𝕥𝕦𝕧𝕨𝕩𝕪𝕫𝔸𝔹ℂ𝔻𝔼𝔽𝔾ℍ𝕀𝕁𝕂𝕃𝕄ℕ𝕆ℙℚℝ𝕊𝕋𝕌𝕍𝕎𝕏𝕐ℤ𝟘𝟙𝟚𝟛𝟜𝟝𝟞𝟟𝟠𝟡" ; BB = Blackboard
			, "superscript", "ᵃᵇᶜᵈᵉᶠᵍʰᶦʲᵏˡᵐⁿᵒᵖᵠʳˢᵗᵘᵛʷˣʸᶻᴬᴮᶜᴰᴱᶠᴳᴴᴵᴶᴷᴸᴹᴺᴼᴾᵠᴿˢᵀᵁⱽᵂˣʸᶻ⁰¹²³⁴⁵⁶⁷⁸⁹"
			, "smallCapitals", "ᴀʙᴄᴅᴇғɢʜɪᴊᴋʟᴍɴᴏᴘǫʀsᴛᴜᴠᴡxʏᴢᴀʙᴄᴅᴇғɢʜɪᴊᴋʟᴍɴᴏᴘǫʀsᴛᴜᴠᴡxʏᴢ0123456789"
			, "mirror", "ɒdɔbɘʇϱʜiįʞlmnoqpɿƨɈυvwxγzAઘƆႧƎᆿӘHIႱʞ⅃MИOԳϘЯƧTUVWXYZ0ƖςƐμटმ٢8୧"
			, "upsidedown", "ɐqɔpǝⅎƃɥᴉɾʞʅɯuodbɹsʇnʌʍxʎz∀ꓭϽᗡƎᖵ⅁HIᒋꓘ⅂ꟽNOԀꝹꓤSꓕՈɅϺX⅄Z0⇂↊↋ᔭ59𝘓86"
			, "sharpscript", "闩⻏⼕ᗪ🝗ﾁᎶ卄讠丿长㇄爪𝓝ㄖ尸Ɋ尺丂〸ㄩᐯ山〤丫Ⲍ闩乃⼕ᗪ㠪千Ꮆ廾工丿长㇄爪𝓝龱尸Ɋ尺丂ㄒㄩᐯ山乂ㄚ乙0丨己㇌丩567〥9")
		; [small letters] [CAPITAL LETTERS] [NUMBERS]
		; https://milde.users.sourceforge.net/LUCR/Math/unimathsymbols.pdf
		; https://en.wikipedia.org/wiki/Mathematical_Alphanumeric_Symbols
		for i, e in strings {
			this.alphabets[i] := this.mapFromArrays(StrSplitUTF8(serifNormal), StrSplitUTF8(e))
		}
		this.alphabets["bold"] := this.mapFromArrays(StrSplitUTF8(serifNormal strings["serifItalic"] strings["mathSF"] strings["mathSFItalic"] strings["mathCal"] strings["mathFraktur"]), StrSplitUTF8(strings["serifBold"] strings["serifBoldItalic"] strings["mathSFBold"] strings["mathSFBoldItalic"] strings["mathCalBold"] strings["mathFrakturBold"]))
		this.alphabets["italic"] := this.mapFromArrays(StrSplitUTF8(serifNormal strings["serifBold"] strings["mathSF"] strings["mathSFBold"]), StrSplitUTF8(strings["serifItalic"] strings["serifBoldItalic"] strings["mathSFItalic"] strings["mathSFBoldItalic"]))
		this.alphabets["zalgo"] := ["̾", "̿", "̀", "́", "͂", "̓", "̈́", "ͅ", "͆", "͇", "͈", "͉", "͊", "͋", "͌", "͍", "͎", "͏", "͐", "͑", "͒", "͓", "͔", "͕", "͖", "͗", "͘", "͙", "͚", "͛", "͜", "͝", "͞", "͟", "͠", "͡", "͢", "ͣ", "ͤ", "ͥ", "ͦ", "ͧ", "ͨ", "ͩ", "ͪ", "ͫ", "ͬ", "ͭ", "ͮ"]

		caseMenu := Menu()
		caseMenu.Add("Random Case", (*) => modifySelectedText(this.randomCase.bind(this)))
		caseMenu.Add("All Uppercase", (*) => modifySelectedText((t) => Format("{:U}", StrReplace(t, "ß", "ẞ"))))
		caseMenu.Add("All Lowercase", (*) => modifySelectedText((t) => Format("{:L}", StrReplace(t, "ẞ", "ß"))))
		caseMenu.Add("Proper Capitals", (*) => modifySelectedText((t) => Format("{:T}", t)))
		fontMenu := Menu()
		fontMenu.Add("Superscript", (*) => modifySelectedText(this.replaceCharacters.bind(this), "superscript"))
		fontMenu.Add("Subscript", (*) => modifySelectedText(this.replaceCharacters.bind(this), "subscript"))
		fontMenu.Add("Small Capitals", (*) => modifySelectedText(this.replaceCharacters.bind(this), "smallcapitals"))
		fontMenu.Add("Italics", (*) => modifySelectedText(this.replaceCharacters.bind(this), "italic"))
		fontMenu.Add("Italics", (*) => modifySelectedText(this.replaceCharacters.bind(this), "bold"))
		;	fontMenu.Add("𝐁𝐨𝐥𝐝 𝐒𝐞𝐫𝐢𝐟", (*) => modifySelectedText(this.replaceCharacters.bind(this), "serifBold"))
		;	fontMenu.Add("𝐼𝑡𝑎𝑙𝑖𝑐 𝑆𝑒𝑟𝑖𝑓", (*) => modifySelectedText(this.replaceCharacters.bind(this), "serifItalic"))
		;	fontMenu.Add("𝑩𝒐𝒍𝒅 𝑰𝒕𝒂𝒍𝒊𝒄 𝑺𝒆𝒓𝒊𝒇", (*) => modifySelectedText(this.replaceCharacters.bind(this), "serifBoldItalic"))
		fontMenu.Add("𝖬𝖺𝗍𝗁𝖲𝖥", (*) => modifySelectedText(this.replaceCharacters.bind(this), "mathSF"))
		;	fontMenu.Add("𝗕𝗼𝗹𝗱 𝗠𝗮𝘁𝗵𝗦𝗙", (*) => modifySelectedText(this.replaceCharacters.bind(this), "mathSFBold"))
		;	fontMenu.Add("𝘐𝘵𝘢𝘭𝘪𝘤 𝘔𝘢𝘵𝘩𝘚𝘍", (*) => modifySelectedText(this.replaceCharacters.bind(this), "mathSFItalic"))
		;	fontMenu.Add("𝘽𝙤𝙡𝙙 𝙄𝙩𝙖𝙡𝙞𝙘 𝙈𝙖𝙩𝙝𝙎𝙁", (*) => modifySelectedText(this.replaceCharacters.bind(this), "mathSFBoldItalic"))
		fontMenu.Add("𝙼𝚘𝚗𝚘𝚜𝚙𝚊𝚌𝚎", (*) => modifySelectedText(this.replaceCharacters.bind(this), "monospace"))
		fontMenu.Add("Ｗｉｄｅｓｐａｃｅ", (*) => modifySelectedText(this.replaceCharacters.bind(this), "widespace"))
		fontMenu.Add("𝕄𝕒𝕥𝕙𝔹𝔹", (*) => modifySelectedText(this.replaceCharacters.bind(this), "mathBB"))
		fontMenu.Add("ℳ𝒶𝓉𝒽𝒞𝒶𝓁", (*) => modifySelectedText(this.replaceCharacters.bind(this), "mathCal"))
		;	fontMenu.Add("𝓑𝓸𝓵𝓭 𝓜𝓪𝓽𝓱𝓒𝓪𝓵", (*) => modifySelectedText(this.replaceCharacters.bind(this), "mathCalBold"))
		fontMenu.Add("𝔐𝔞𝔱𝔥𝔉𝔯𝔞𝔨", (*) => modifySelectedText(this.replaceCharacters.bind(this), "mathFraktur"))
		;	fontMenu.Add("𝕭𝖔𝖑𝖉 𝕸𝖆𝖙𝖍𝕱𝖗𝖆𝖐", (*) => modifySelectedText(this.replaceCharacters.bind(this), "mathFrakturBold"))
		fontMenu.Add("丂卄闩尺尸 丂⼕尺讠尸〸", (*) => modifySelectedText(this.replaceCharacters.bind(this), "sharpscript"))
		textModifyMenu := Menu()
		textModifyMenu.Add("Letter Case", caseMenu)
		textModifyMenu.Add("Font", fontMenu)
		textModifyMenu.Add("Reverse", (*) => modifySelectedText(reverseString))
		textModifyMenu.Add("Mirror", (*) => modifySelectedText(this.mirror.bind(this), "mirror"))
		textModifyMenu.Add("Flip", (*) => modifySelectedText(this.flip.bind(this)))
		textModifyMenu.Add("Spaced Text", (*) => modifySelectedText(this.spreadString.bind(this), " "))
		textModifyMenu.Add("Add Zalgo", (*) => modifySelectedText(this.zalgo.bind(this), 5))
	;	menu_RemoveSpace(textModifyMenu.Handle) ; this also decreases vertical spacing.
		this.menu := textModifyMenu
	}

	static mapFromArrays(keyArray, valueArray) {
		if (keyArray.Length != valueArray.Length || !(keyArray is Array) || !(valueArray is Array))
			throw Error("Invalid Arrays given: Lengths are " keyArray.Length " and " valueArray.Length)
		tM := Map()
		for i, e in keyArray
			tM[e] := valueArray[i]
		return tM
	}

	static showMenu() {
		this.menu.show()
	}

	static randomCase(text) {
		result := ""
		c := ""
		for i, e in StrSplitUTF8(text) {
			caseFormat := Random(0, 1)
			if (A_LoopField == "ß" || A_LoopField == "ẞ")
				c := caseFormat ? "ß" : "ẞ"
			if (caseFormat)
				c := Format("{:U}", A_LoopField)
			else
				c := Format("{:L}", A_LoopField)
			if (A_LoopField = "I" || A_LoopField = "i")
				c := "i"
			else if (A_LoopField = "L" || A_LoopField = "l")
				c := "L"
			else if (A_LoopField == "ß" || A_LoopField == "ẞ")
				c := (caseFormat ? "ß" : "ẞ")
			result := result . c
		}
		return result
	}

	static replaceCharacters(text, alphName) {
		result := ""
		if !(this.alphabets.Has(alphName))
			return text
		for i, e in StrSplitUTF8(text) {
			if (this.alphabets[alphName].Has(e))
				result .= this.alphabets[alphName][e]
			else
				result .= e
		}
		return result
	}

	static spreadString(text, delimiter) {
		result := ""
		for i, e in StrSplitUTF8(text)
			result .= e . delimiter
		return RTrim(result, delimiter)
	}

	static mirror(text) => this.replaceCharacters(reverseString(text), "mirror")

	static flip(text) => this.replaceCharacters(reverseString(text), "upsidedown")

	static zalgo(str, intensity) {
		len := this.alphabets["zalgo"].length
		newStr := ""
		for i, e in StrSplitUTF8(str) {
			newStr .= e
			Loop (intensity)
				newStr .= this.alphabets["zalgo"][Random(1, len)]
		}
		return newStr
	}

	; static runify(text, language) {
	; 	switch language {
	; 		case "DE":
	; 			; // Basically, do the replaceCharacters function with all single chars that can be determined, then execute StringReplace a few times with the combinations.
	; 			; // this is really easy. why did i struggle with this before?
	; 		case "EN":
	; 	}
	; 	result := replaceCharacters(text, "abcdefghijklmnopqrstuvwxyz", "ᚫᛒᚳᛞᛖᚠᚷᚻᛁᛃᚲᛚᛗᚾᛟᛈ◊ᚱᛋᛏᚢᚹᚹ□ᛃᛉ")
	; 	return result
	; }

	; static derunify(text, language) {
	; 	result := replaceCharacters(text, 	"ᚠᚡᚢᚣᚤᚥᚨᚩᚪᚫᚬᚭᚮᚯᚰᚱᚲᚴᚵᚷᚸᚹᚺᚻᚼᚽᚾᚿᛀᛁᛂᛃᛄᛅᛆᛈᛉᛊᛋᛌᛍᛎᛏᛐᛑᛒᛓᛔᛕᛖᛗᛘᛙᛚᛛᛞᛟᛤᛦᛧ", 	"fvuyywaoaaoooöorkkgggvhhhhnnnieyjaapzsssczttdbbppemmmlldokry")
	; 	return result
	; }
}