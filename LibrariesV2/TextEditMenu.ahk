#Include %A_ScriptDir%\LibrariesV2\BasicUtilities.ahk

class TextEditMenu {

	static __New() {
		caseMenu := Menu()
		caseMenu.Add("Random Case", (*) => modifySelectedText(this.randomCase))
		caseMenu.Add("Uppercase", (*) => modifySelectedText((t) => Format("{:U}", StrReplace(t, "ß", "ẞ"))))
		caseMenu.Add("Lowercase", (*) => modifySelectedText((t) => Format("{:L}", StrReplace(t, "ẞ", "ß"))))
		caseMenu.Add("Capitals", (*) => modifySelectedText((t) => Format("{:T}", t)))
		fontMenu := Menu()
		fontMenu.Add("Bold", this.menuHandler.bind(this))
		fontMenu.Add("Italic", this.menuHandler.bind(this))
		fontMenu.Add("Superscript", this.menuHandler.bind(this))
		fontMenu.Add("Subscript", this.menuHandler.bind(this))
		fontMenu.Add("Small Capitals", this.menuHandler.bind(this))
		fontMenu.Add("MathSF", this.menuHandler.bind(this))
		fontMenu.Add("MathTT", this.menuHandler.bind(this))
		fontMenu.Add("MathBB", this.menuHandler.bind(this))
		fontMenu.Add("MathCal", this.menuHandler.bind(this))
		fontMenu.Add("MathFrak", this.menuHandler.bind(this))
		textModifyMenu := Menu()
		textModifyMenu.Add("Change Letter Case", caseMenu)
		textModifyMenu.Add("Change Font", fontMenu)
		textModifyMenu.Add("Reverse", this.menuHandler.bind(this))
		textModifyMenu.Add("Mirror", this.menuHandler.bind(this))
		textModifyMenu.Add("Upside Down", this.menuHandler.bind(this))
		textModifyMenu.Add("Spaced Text", this.menuHandler.bind(this))
		textModifyMenu.Add("Add Zalgo", this.menuHandler.bind(this))
		; Menu, runifyMenu, Add, Runify (DE), % TextEditMenuVar
		; Menu, runifyMenu, Add, Runify (EN), % TextEditMenuVar
		; Menu, textModify, Add, Runify, :runifyMenu
		; Menu, derunifyMenu, Add, Derunify (DE), % TextEditMenuVar
		; Menu, derunifyMenu, Add, Derunify (EN), % TextEditMenuVar
		; Menu, textModify, Add, Derunify, :derunifyMenu
		this.menu := textModifyMenu
		/*
		this.menuItems := { "caseMenu": {"text": "Letter Case", "menu": "textModify", "isSubMenu":true}
					, "fontMenu": {"text": "Change Font", "menu": "textModify", "isSubMenu":true}
		
					, "randomCase": {"text": "Spongebobify", "menu": "caseMenu"}
					, "uppercase": {"text": "All Uppercase", "menu": "caseMenu"}
					, "lowercase": {"text": "All Lowercase", "menu": "caseMenu"}
					, "capitalization": {"text": "Proper Capitals", "menu": "caseMenu"}
					
					, "bold": {"text": "Bold Text", "menu": "fontMenu"}
					, "italic": {"text": "Italic Text", "menu": "fontMenu"}
					, "superscript": {"text": "Superscript", "menu": "fontMenu"}
					, "subscript": {"text": "Subscript", "menu": "fontMenu"}
					, "mathSF": {"text": "Narrow Text", "menu": "fontMenu"}
					, "mathTT": {"text": "Small Text", "menu": "fontMenu"}
					, "mathBB": {"text": "mathBB", "menu": "fontMenu"}
					, "mathCal": {"text": "mathCal", "menu": "fontMenu"}
					, "mathFrak": {"text": "MathFrak", "menu": "fontMenu"}
					
					, "reverse": {"text": "Reverse", "menu": "textModify"}
					, "mirror": {"text": "Mirror", "menu": "textModify"}
					, "upsidedown": {"text": "Turn upside down", "menu": "textModify"}
					, "increaseSpacing": {"text": "Increase Spacing", "menu": "textModify"}
					, "zalgo": {"text": "Add Zalgo", "menu": "textModify"} }
		*/
		/*
		FORMAT: [small letters] [CAPITAL LETTERS] [NUMBERS]
		https://milde.users.sourceforge.net/LUCR/Math/unimathsymbols.pdf
		https://en.wikipedia.org/wiki/Mathematical_Alphanumeric_Symbols
		*/
		this.alphabets := Map("serifNormal", StrSplit("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") ; Serif
			, "serifItalic", StrSplit("𝑎𝑏𝑐𝑑𝑒𝑓𝑔ℎ𝑖𝑗𝑘𝑙𝑚𝑛𝑜𝑝𝑞𝑟𝑠𝑡𝑢𝑣𝑤𝑥𝑦𝑧𝐴𝐵𝐶𝐷𝐸𝐹𝐺𝐻𝐼𝐽𝐾𝐿𝑀𝑁𝑂𝑃𝑄𝑅𝑆𝑇𝑈𝑉𝑊𝑋𝑌𝑍0123456789")
			, "serifBold", StrSplit("𝐚𝐛𝐜𝐝𝐞𝐟𝐠𝐡𝐢𝐣𝐤𝐥𝐦𝐧𝐨𝐩𝐪𝐫𝐬𝐭𝐮𝐯𝐰𝐱𝐲𝐳𝐀𝐁𝐂𝐃𝐄𝐅𝐆𝐇𝐈𝐉𝐊𝐋𝐌𝐍𝐎𝐏𝐐𝐑𝐒𝐓𝐔𝐕𝐖𝐗𝐘𝐙𝟎𝟏𝟐𝟑𝟒𝟓𝟔𝟕𝟖𝟗")
			, "serifBoldItalic", StrSplit("𝒂𝒃𝒄𝒅𝒆𝒇𝒈𝒉𝒊𝒋𝒌𝒍𝒎𝒏𝒐𝒑𝒒𝒓𝒔𝒕𝒖𝒗𝒘𝒙𝒚𝒛𝑨𝑩𝑪𝑫𝑬𝑭𝑮𝑯𝑰𝑱𝑲𝑳𝑴𝑵𝑶𝑷𝑸𝑹𝑺𝑻𝑼𝑽𝑾𝑿𝒀𝒁𝟎𝟏𝟐𝟑𝟒𝟓𝟔𝟕𝟖𝟗")
			, "mathSF", StrSplit("𝖺𝖻𝖼𝖽𝖾𝖿𝗀𝗁𝗂𝗃𝗄𝗅𝗆𝗇𝗈𝗉𝗊𝗋𝗌𝗍𝗎𝗏𝗐𝗑𝗒𝗓𝖠𝖡𝖢𝖣𝖤𝖥𝖦𝖧𝖨𝖩𝖪𝖫𝖬𝖭𝖮𝖯𝖰𝖱𝖲𝖳𝖴𝖵𝖶𝖷𝖸𝖹𝟢𝟣𝟤𝟥𝟦𝟧𝟨𝟩𝟪𝟫") ; SF = Sans Serif
			, "mathSFBold", StrSplit("𝗮𝗯𝗰𝗱𝗲𝗳𝗴𝗵𝗶𝗷𝗸𝗹𝗺𝗻𝗼𝗽𝗾𝗿𝘀𝘁𝘂𝘃𝘄𝘅𝘆𝘇𝗔𝗕𝗖𝗗𝗘𝗙𝗚𝗛𝗜𝗝𝗞𝗟𝗠𝗡𝗢𝗣𝗤𝗥𝗦𝗧𝗨𝗩𝗪𝗫𝗬𝗭𝟬𝟭𝟮𝟯𝟰𝟱𝟲𝟳𝟴𝟵")
			, "mathSFItalic", StrSplit("𝘢𝘣𝘤𝘥𝘦𝘧𝘨𝘩𝘪𝘫𝘬𝘭𝘮𝘯𝘰𝘱𝘲𝘳𝘴𝘵𝘶𝘷𝘸𝘹𝘺𝘻𝘈𝘉𝘊𝘋𝘌𝘍𝘎𝘏𝘐𝘑𝘒𝘓𝘔𝘕𝘖𝘗𝘘𝘙𝘚𝘛𝘜𝘝𝘞𝘟𝘠𝘡𝟢𝟣𝟤𝟥𝟦𝟧𝟨𝟩𝟪𝟫")
			, "mathSFBoldItalic", StrSplit("𝙖𝙗𝙘𝙙𝙚𝙛𝙜𝙝𝙞𝙟𝙠𝙡𝙢𝙣𝙤𝙥𝙦𝙧𝙨𝙩𝙪𝙫𝙬𝙭𝙮𝙯𝘼𝘽𝘾𝘿𝙀𝙁𝙂𝙃𝙄𝙅𝙆𝙇𝙈𝙉𝙊𝙋𝙌𝙍𝙎𝙏𝙐𝙑𝙒𝙓𝙔𝙕𝟬𝟭𝟮𝟯𝟰𝟱𝟲𝟳𝟴𝟵")
			, "mathCal", StrSplit("𝒶𝒷𝒸𝒹ℯ𝒻ℊ𝒽𝒾𝒿𝓀𝓁𝓂𝓃ℴ𝓅𝓆𝓇𝓈𝓉𝓊𝓋𝓌𝓍𝓎𝓏𝒜ℬ𝒞𝒟ℰℱ𝒢ℋℐ𝒥𝒦ℒℳ𝒩𝒪𝒫𝒬ℛ𝒮𝒯𝒰𝒱𝒲𝒳𝒴𝒵𝟢𝟣𝟤𝟥𝟦𝟧𝟨𝟩𝟪𝟫") ; Cal = Calligraphy
			, "mathCalBold", StrSplit("𝓪𝓫𝓬𝓭𝓮𝓯𝓰𝓱𝓲𝓳𝓴𝓵𝓶𝓷𝓸𝓹𝓺𝓻𝓼𝓽𝓾𝓿𝔀𝔁𝔂𝔃𝓐𝓑𝓒𝓓𝓔𝓕𝓖𝓗𝓘𝓙𝓚𝓛𝓜𝓝𝓞𝓟𝓠𝓡𝓢𝓣𝓤𝓥𝓦𝓧𝓨𝓩𝟬𝟭𝟮𝟯𝟰𝟱𝟲𝟳𝟴𝟵")
			, "mathFraktur", StrSplit("𝔞𝔟𝔠𝔡𝔢𝔣𝔤𝔥𝔦𝔧𝔨𝔩𝔪𝔫𝔬𝔭𝔮𝔯𝔰𝔱𝔲𝔳𝔴𝔵𝔶𝔷𝔄𝔅ℭ𝔇𝔈𝔉𝔊ℌℑ𝔍𝔎𝔏𝔐𝔑𝔒𝔓𝔔ℜ𝔖𝔗𝔘𝔙𝔚𝔛𝔜ℨ𝟢𝟣𝟤𝟥𝟦𝟧𝟨𝟩𝟪𝟫") ; Frak = Fraktur
			, "mathFrakturBold", StrSplit("𝖆𝖇𝖈𝖉𝖊𝖋𝖌𝖍𝖎𝖏𝖐𝖑𝖒𝖓𝖔𝖕𝖖𝖗𝖘𝖙𝖚𝖛𝖜𝖝𝖞𝖟𝕬𝕭𝕮𝕯𝕰𝕱𝕲𝕳𝕴𝕵𝕶𝕷𝕸𝕹𝕺𝕻𝕼𝕽𝕾𝕿𝖀𝖁𝖂𝖃𝖄𝖅𝟬𝟭𝟮𝟯𝟰𝟱𝟲𝟳𝟴𝟵")
			, "monoSpace", StrSplit("𝚊𝚋𝚌𝚍𝚎𝚏𝚐𝚑𝚒𝚓𝚔𝚕𝚖𝚗𝚘𝚙𝚚𝚛𝚜𝚝𝚞𝚟𝚠𝚡𝚢𝚣𝙰𝙱𝙲𝙳𝙴𝙵𝙶𝙷𝙸𝙹𝙺𝙻𝙼𝙽𝙾𝙿𝚀𝚁𝚂𝚃𝚄𝚅𝚆𝚇𝚈𝚉𝟶𝟷𝟸𝟹𝟺𝟻𝟼𝟽𝟾𝟿") ; TT = Monospace
			, "mathBB", StrSplit("𝕒𝕓𝕔𝕕𝕖𝕗𝕘𝕙𝕚𝕛𝕜𝕝𝕞𝕟𝕠𝕡𝕢𝕣𝕤𝕥𝕦𝕧𝕨𝕩𝕪𝕫𝔸𝔹ℂ𝔻𝔼𝔽𝔾ℍ𝕀𝕁𝕂𝕃𝕄ℕ𝕆ℙℚℝ𝕊𝕋𝕌𝕍𝕎𝕏𝕐ℤ𝟘𝟙𝟚𝟛𝟜𝟝𝟞𝟟𝟠𝟡") ; BB = Blackboard
			, "superscript", StrSplit("ᵃᵇᶜᵈᵉᶠᵍʰᶦʲᵏˡᵐⁿᵒᵖᵠʳˢᵗᵘᵛʷˣʸᶻ⁰¹²³⁴⁵⁶⁷⁸⁹")
			, "smallCapitals", StrSplit("ᴀʙᴄᴅᴇғɢʜɪᴊᴋʟᴍɴᴏᴘǫʀsᴛᴜᴠᴡxʏᴢ") ; !!!!
			, "mirror", StrSplit("ɒdɔbɘʇϱʜiįʞlmnoqpɿƨɈυvwxγz") ; !!!!
			, "upsidedown", StrSplit("ɐqɔpǝⅎƃɥᴉɾʞʅɯuodbɹsʇnʌʍxʎz∀ꓭϽᗡƎᖵ⅁HIᒋꓘ⅂ꟽNOԀꝹꓤSꓕՈɅϺX⅄Z0⇂↊↋ᔭ59𝘓86")
			, "special", StrSplit("ßẞ")
			, "sharpScript", StrSplit("闩⻏⼕ᗪ🝗ﾁᎶ卄讠丿长㇄爪𝓝ㄖ尸Ɋ尺丂〸ㄩᐯ山〤丫Ⲍ闩乃⼕ᗪ㠪千Ꮆ廾工丿长㇄爪𝓝龱尸Ɋ尺丂ㄒㄩᐯ山乂ㄚ乙0丨己㇌丩567〥9")
			, "wideSpaced", StrSplit("ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ０１２３４５６７８９")
			
			, "zalgo", ["̾","̿","̀","́","͂","̓","̈́","ͅ","͆","͇","͈","͉","͊","͋","͌","͍","͎","͏","͐","͑","͒","͓","͔","͕","͖","͗","͘","͙","͚","͛","͜","͝","͞","͟","͠","͡","͢","ͣ","ͤ","ͥ","ͦ","ͧ","ͨ","ͩ","ͪ","ͫ","ͬ","ͭ","ͮ"])
	}

	static showMenu() {
		this.menu.show()
	}

	static menuHandler(itemName, itemPos, menuObj) {
		text := fastCopy()
		if(IsSpace(text))
			return
		switch itemName {
			case "Random Case":
				result := this.randomCase(text)
			case "Spaced Text":
				result := this.spreadString(text, " ")
			case "Reverse":
				result := reverseString(text)
			case "Mirror":
				result := this.mirrorify(text)
			case "Superscript":
				result := this.smallify(text)
			case "Small Capitals":
				result := this.smallcapify(text)
			case "Upside Down":
				result := this.upsidedownify(text)
			case "Add Zalgo":
				result := this.zalgoify(text, 5)
			case "Runify (DE)":
				result := this.runify(text, "DE")
			case "Runify (EN)":
				result := this.runify(text, "EN")
			case "Derunify (DE)":
				result := this.derunify(text, "DE")
			case "Derunify (EN)":
				result := this.derunify(text, "EN")
			default:
				MsgBox("Unexpected Label name: " . itemName)
				return
		}
		fastPrint(result)
	}

	static randomCase(text) {
		result := ""
		c := ""
		Loop Parse, text
		{
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

	static replaceCharacters(text, arrFrom, arrTo) {
		if (arrFrom.Length > arrTo.Length)
			return
	;	Loop Parse, text {
	;		result .= this.alphabetMap["serif"]["mathSF"][A_LoopField]
	;		text := StrReplace(text, arrFrom[i], arrTo[i], true)
	;	}
	}

	static ReplaceChars(Text, Chars, ReplaceChars) {
		ReplacedText := Text
		Loop Parse, Text {
			Index := A_Index
			Char := A_LoopField
			Loop Parse, Chars
			{
				if (A_LoopField = Char) {
					ReplacedText := SubStr(ReplacedText, 1, Index - 1) . SubStr(ReplaceChars, A_Index, 1) . SubStr(ReplacedText, Index + 1)
					break
				}
			}
		}
		return ReplacedText
	}

	static spreadString(text, delimiter) {
		result := ""
		Loop Parse, text 
			result .= A_LoopField . delimiter
		return RTrim(result, delimiter)
	}

	static mirrorify(text) {
		text := reverseString(text)
		return ReplaceChars(text, "", "")
	}

	static smallify(text) {
		return ReplaceChars(text, "", "")
	}

	static smallcapify(text) {
		return ReplaceChars(text, "", "")
	}

	static upsidedownify(text) {
		text := reverseString(text)
		return ReplaceChars(text, "", "")
	}

	static zalgoify(str, intensity) {
		listAccentSymbols := ["̾","̿","̀","́","͂","̓","̈́","ͅ","͆","͇","͈","͉","͊","͋","͌","͍","͎","͏","͐","͑","͒","͓","͔","͕","͖","͗","͘","͙","͚","͛","͜","͝","͞","͟","͠","͡","͢","ͣ","ͤ","ͥ","ͦ","ͧ","ͨ","ͩ","ͪ","ͫ","ͬ","ͭ","ͮ"]
		l := listAccentSymbols.Length
		newStr := ""
		Loop Parse, str
		{
			zalgoStr := ""
			Loop(intensity)
			{
				zalgoStr .= listAccentSymbols[Random(1, l)]
			}
			newStr .= A_LoopField . zalgoStr
		}
		return newStr
	}

	static runify(text, language) {
		switch language {
			case "DE":
				; // Basically, do the ReplaceChars function with all single chars that can be determined, then execute StringReplace a few times with the combinations. 
				; // this is really easy. why did i struggle with this before?
			case "EN":
		}
		result := ReplaceChars(text, "abcdefghijklmnopqrstuvwxyz", "ᚫᛒᚳᛞᛖᚠᚷᚻᛁᛃᚲᛚᛗᚾᛟᛈ◊ᚱᛋᛏᚢᚹᚹ□ᛃᛉ")
		return result
	}

	static derunify(text, language) {
		result := ReplaceChars(text, 	"ᚠᚡᚢᚣᚤᚥᚨᚩᚪᚫᚬᚭᚮᚯᚰᚱᚲᚴᚵᚷᚸᚹᚺᚻᚼᚽᚾᚿᛀᛁᛂᛃᛄᛅᛆᛈᛉᛊᛋᛌᛍᛎᛏᛐᛑᛒᛓᛔᛕᛖᛗᛘᛙᛚᛛᛞᛟᛤᛦᛧ", 	"fvuyywaoaaoooöorkkgggvhhhhnnnieyjaapzsssczttdbbppemmmlldokry")
		return result
	}
}

