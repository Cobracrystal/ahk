#Include %A_ScriptDir%\LibrariesV2\BasicUtilities.ahk

class TextEditMenu {

	static __New() {
		this.alphabets := Map()
		caseMenu := Menu()
		caseMenu.Add("Random Case", (*) => modifySelectedText(this.randomCase.bind(this)))
		caseMenu.Add("Uppercase", (*) => modifySelectedText((t) => Format("{:U}", StrReplace(t, "ß", "ẞ"))))
		caseMenu.Add("Lowercase", (*) => modifySelectedText((t) => Format("{:L}", StrReplace(t, "ẞ", "ß"))))
		caseMenu.Add("Capitals", (*) => modifySelectedText((t) => Format("{:T}", t)))
		fontMenu := Menu()
		fontMenu.Add("Bold Serif", (*) => modifySelectedText(this.replaceCharacters.bind(this), "serifBold"))
		fontMenu.Add("Italic Serif", (*) => modifySelectedText(this.replaceCharacters.bind(this), "serifItalic"))
			fontMenu.Add("Bold Italic Serif", (*) => modifySelectedText(this.replaceCharacters.bind(this), "serifBoldItalic"))
		fontMenu.Add("Superscript", (*) => modifySelectedText(this.replaceCharacters.bind(this), "superscript"))
	;	fontMenu.Add("Subscript", (*) => modifySelectedText(this.replaceCharacters.bind(this), "serifBold"))
	;	fontMenu.Add("Small Capitals", (*) => modifySelectedText(this.replaceCharacters.bind(this), "serifBold"))
		fontMenu.Add("MathSF", (*) => modifySelectedText(this.replaceCharacters.bind(this), "mathSF"))
			fontMenu.Add("Bold MathSF", (*) => modifySelectedText(this.replaceCharacters.bind(this), "mathSFBold"))
			fontMenu.Add("Italic MathSF", (*) => modifySelectedText(this.replaceCharacters.bind(this), "mathSFItalic"))
			fontMenu.Add("Bold Italic MathSF", (*) => modifySelectedText(this.replaceCharacters.bind(this), "mathSFBoldItalic"))
		fontMenu.Add("Monospace", (*) => modifySelectedText(this.replaceCharacters.bind(this), "monoSpace"))
		fontMenu.Add("Widespace", (*) => modifySelectedText(this.replaceCharacters.bind(this), "wideSpace"))
		fontMenu.Add("MathBB", (*) => modifySelectedText(this.replaceCharacters.bind(this), "mathBB"))
		fontMenu.Add("MathCal", (*) => modifySelectedText(this.replaceCharacters.bind(this), "mathCal"))
			fontMenu.Add("Bold MathCal", (*) => modifySelectedText(this.replaceCharacters.bind(this), "mathCalBold"))
		fontMenu.Add("MathFrak", (*) => modifySelectedText(this.replaceCharacters.bind(this), "mathFraktur"))
			fontMenu.Add("Bold MathFrak", (*) => modifySelectedText(this.replaceCharacters.bind(this), "mathFrakturBold"))
		fontMenu.Add("Sharp Script", (*) => modifySelectedText(this.replaceCharacters.bind(this), "sharpScript"))
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
		serifNormal := "a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,0,1,2,3,4,5,6,7,8,9"
		strings := Map("serifItalic", "𝑎,𝑏,𝑐,𝑑,𝑒,𝑓,𝑔,ℎ,𝑖,𝑗,𝑘,𝑙,𝑚,𝑛,𝑜,𝑝,𝑞,𝑟,𝑠,𝑡,𝑢,𝑣,𝑤,𝑥,𝑦,𝑧,𝐴,𝐵,𝐶,𝐷,𝐸,𝐹,𝐺,𝐻,𝐼,𝐽,𝐾,𝐿,𝑀,𝑁,𝑂,𝑃,𝑄,𝑅,𝑆,𝑇,𝑈,𝑉,𝑊,𝑋,𝑌,𝑍,0,1,2,3,4,5,6,7,8,9"
			, "serifBold", "𝐚,𝐛,𝐜,𝐝,𝐞,𝐟,𝐠,𝐡,𝐢,𝐣,𝐤,𝐥,𝐦,𝐧,𝐨,𝐩,𝐪,𝐫,𝐬,𝐭,𝐮,𝐯,𝐰,𝐱,𝐲,𝐳,𝐀,𝐁,𝐂,𝐃,𝐄,𝐅,𝐆,𝐇,𝐈,𝐉,𝐊,𝐋,𝐌,𝐍,𝐎,𝐏,𝐐,𝐑,𝐒,𝐓,𝐔,𝐕,𝐖,𝐗,𝐘,𝐙,𝟎,𝟏,𝟐,𝟑,𝟒,𝟓,𝟔,𝟕,𝟖,𝟗"
			, "serifBoldItalic", "𝒂,𝒃,𝒄,𝒅,𝒆,𝒇,𝒈,𝒉,𝒊,𝒋,𝒌,𝒍,𝒎,𝒏,𝒐,𝒑,𝒒,𝒓,𝒔,𝒕,𝒖,𝒗,𝒘,𝒙,𝒚,𝒛,𝑨,𝑩,𝑪,𝑫,𝑬,𝑭,𝑮,𝑯,𝑰,𝑱,𝑲,𝑳,𝑴,𝑵,𝑶,𝑷,𝑸,𝑹,𝑺,𝑻,𝑼,𝑽,𝑾,𝑿,𝒀,𝒁,𝟎,𝟏,𝟐,𝟑,𝟒,𝟓,𝟔,𝟕,𝟖,𝟗"
			, "mathSF", "𝖺,𝖻,𝖼,𝖽,𝖾,𝖿,𝗀,𝗁,𝗂,𝗃,𝗄,𝗅,𝗆,𝗇,𝗈,𝗉,𝗊,𝗋,𝗌,𝗍,𝗎,𝗏,𝗐,𝗑,𝗒,𝗓,𝖠,𝖡,𝖢,𝖣,𝖤,𝖥,𝖦,𝖧,𝖨,𝖩,𝖪,𝖫,𝖬,𝖭,𝖮,𝖯,𝖰,𝖱,𝖲,𝖳,𝖴,𝖵,𝖶,𝖷,𝖸,𝖹,𝟢,𝟣,𝟤,𝟥,𝟦,𝟧,𝟨,𝟩,𝟪,𝟫" ; SF = Sans Serif
			, "mathSFBold", "𝗮,𝗯,𝗰,𝗱,𝗲,𝗳,𝗴,𝗵,𝗶,𝗷,𝗸,𝗹,𝗺,𝗻,𝗼,𝗽,𝗾,𝗿,𝘀,𝘁,𝘂,𝘃,𝘄,𝘅,𝘆,𝘇,𝗔,𝗕,𝗖,𝗗,𝗘,𝗙,𝗚,𝗛,𝗜,𝗝,𝗞,𝗟,𝗠,𝗡,𝗢,𝗣,𝗤,𝗥,𝗦,𝗧,𝗨,𝗩,𝗪,𝗫,𝗬,𝗭,𝟬,𝟭,𝟮,𝟯,𝟰,𝟱,𝟲,𝟳,𝟴,𝟵"
			, "mathSFItalic", "𝘢,𝘣,𝘤,𝘥,𝘦,𝘧,𝘨,𝘩,𝘪,𝘫,𝘬,𝘭,𝘮,𝘯,𝘰,𝘱,𝘲,𝘳,𝘴,𝘵,𝘶,𝘷,𝘸,𝘹,𝘺,𝘻,𝘈,𝘉,𝘊,𝘋,𝘌,𝘍,𝘎,𝘏,𝘐,𝘑,𝘒,𝘓,𝘔,𝘕,𝘖,𝘗,𝘘,𝘙,𝘚,𝘛,𝘜,𝘝,𝘞,𝘟,𝘠,𝘡,𝟢,𝟣,𝟤,𝟥,𝟦,𝟧,𝟨,𝟩,𝟪,𝟫"
			, "mathSFBoldItalic", "𝙖,𝙗,𝙘,𝙙,𝙚,𝙛,𝙜,𝙝,𝙞,𝙟,𝙠,𝙡,𝙢,𝙣,𝙤,𝙥,𝙦,𝙧,𝙨,𝙩,𝙪,𝙫,𝙬,𝙭,𝙮,𝙯,𝘼,𝘽,𝘾,𝘿,𝙀,𝙁,𝙂,𝙃,𝙄,𝙅,𝙆,𝙇,𝙈,𝙉,𝙊,𝙋,𝙌,𝙍,𝙎,𝙏,𝙐,𝙑,𝙒,𝙓,𝙔,𝙕,𝟬,𝟭,𝟮,𝟯,𝟰,𝟱,𝟲,𝟳,𝟴,𝟵"
			, "mathCal", "𝒶,𝒷,𝒸,𝒹,ℯ,𝒻,ℊ,𝒽,𝒾,𝒿,𝓀,𝓁,𝓂,𝓃,ℴ,𝓅,𝓆,𝓇,𝓈,𝓉,𝓊,𝓋,𝓌,𝓍,𝓎,𝓏,𝒜,ℬ,𝒞,𝒟,ℰ,ℱ,𝒢,ℋ,ℐ,𝒥,𝒦,ℒ,ℳ,𝒩,𝒪,𝒫,𝒬,ℛ,𝒮,𝒯,𝒰,𝒱,𝒲,𝒳,𝒴,𝒵,𝟢,𝟣,𝟤,𝟥,𝟦,𝟧,𝟨,𝟩,𝟪,𝟫" ; Cal = Calligraphy
			, "mathCalBold", "𝓪,𝓫,𝓬,𝓭,𝓮,𝓯,𝓰,𝓱,𝓲,𝓳,𝓴,𝓵,𝓶,𝓷,𝓸,𝓹,𝓺,𝓻,𝓼,𝓽,𝓾,𝓿,𝔀,𝔁,𝔂,𝔃,𝓐,𝓑,𝓒,𝓓,𝓔,𝓕,𝓖,𝓗,𝓘,𝓙,𝓚,𝓛,𝓜,𝓝,𝓞,𝓟,𝓠,𝓡,𝓢,𝓣,𝓤,𝓥,𝓦,𝓧,𝓨,𝓩,𝟬,𝟭,𝟮,𝟯,𝟰,𝟱,𝟲,𝟳,𝟴,𝟵"
			, "mathFraktur", "𝔞,𝔟,𝔠,𝔡,𝔢,𝔣,𝔤,𝔥,𝔦,𝔧,𝔨,𝔩,𝔪,𝔫,𝔬,𝔭,𝔮,𝔯,𝔰,𝔱,𝔲,𝔳,𝔴,𝔵,𝔶,𝔷,𝔄,𝔅,ℭ,𝔇,𝔈,𝔉,𝔊,ℌ,ℑ,𝔍,𝔎,𝔏,𝔐,𝔑,𝔒,𝔓,𝔔,ℜ,𝔖,𝔗,𝔘,𝔙,𝔚,𝔛,𝔜,ℨ,𝟢,𝟣,𝟤,𝟥,𝟦,𝟧,𝟨,𝟩,𝟪,𝟫" ; Frak = Fraktur
			, "mathFrakturBold", "𝖆,𝖇,𝖈,𝖉,𝖊,𝖋,𝖌,𝖍,𝖎,𝖏,𝖐,𝖑,𝖒,𝖓,𝖔,𝖕,𝖖,𝖗,𝖘,𝖙,𝖚,𝖛,𝖜,𝖝,𝖞,𝖟,𝕬,𝕭,𝕮,𝕯,𝕰,𝕱,𝕲,𝕳,𝕴,𝕵,𝕶,𝕷,𝕸,𝕹,𝕺,𝕻,𝕼,𝕽,𝕾,𝕿,𝖀,𝖁,𝖂,𝖃,𝖄,𝖅,𝟬,𝟭,𝟮,𝟯,𝟰,𝟱,𝟲,𝟳,𝟴,𝟵"
			, "monoSpace", "𝚊,𝚋,𝚌,𝚍,𝚎,𝚏,𝚐,𝚑,𝚒,𝚓,𝚔,𝚕,𝚖,𝚗,𝚘,𝚙,𝚚,𝚛,𝚜,𝚝,𝚞,𝚟,𝚠,𝚡,𝚢,𝚣,𝙰,𝙱,𝙲,𝙳,𝙴,𝙵,𝙶,𝙷,𝙸,𝙹,𝙺,𝙻,𝙼,𝙽,𝙾,𝙿,𝚀,𝚁,𝚂,𝚃,𝚄,𝚅,𝚆,𝚇,𝚈,𝚉,𝟶,𝟷,𝟸,𝟹,𝟺,𝟻,𝟼,𝟽,𝟾,𝟿" ; TT = Monospace
			, "wideSpace", "ａ,ｂ,ｃ,ｄ,ｅ,ｆ,ｇ,ｈ,ｉ,ｊ,ｋ,ｌ,ｍ,ｎ,ｏ,ｐ,ｑ,ｒ,ｓ,ｔ,ｕ,ｖ,ｗ,ｘ,ｙ,ｚ,Ａ,Ｂ,Ｃ,Ｄ,Ｅ,Ｆ,Ｇ,Ｈ,Ｉ,Ｊ,Ｋ,Ｌ,Ｍ,Ｎ,Ｏ,Ｐ,Ｑ,Ｒ,Ｓ,Ｔ,Ｕ,Ｖ,Ｗ,Ｘ,Ｙ,Ｚ,０,１,２,３,４,５,６,７,８,９"
			, "mathBB", "𝕒,𝕓,𝕔,𝕕,𝕖,𝕗,𝕘,𝕙,𝕚,𝕛,𝕜,𝕝,𝕞,𝕟,𝕠,𝕡,𝕢,𝕣,𝕤,𝕥,𝕦,𝕧,𝕨,𝕩,𝕪,𝕫,𝔸,𝔹,ℂ,𝔻,𝔼,𝔽,𝔾,ℍ,𝕀,𝕁,𝕂,𝕃,𝕄,ℕ,𝕆,ℙ,ℚ,ℝ,𝕊,𝕋,𝕌,𝕍,𝕎,𝕏,𝕐,ℤ,𝟘,𝟙,𝟚,𝟛,𝟜,𝟝,𝟞,𝟟,𝟠,𝟡" ; BB = Blackboard
			, "superscript", "ᵃ,ᵇ,ᶜ,ᵈ,ᵉ,ᶠ,ᵍ,ʰ,ᶦ,ʲ,ᵏ,ˡ,ᵐ,ⁿ,ᵒ,ᵖ,ᵠ,ʳ,ˢ,ᵗ,ᵘ,ᵛ,ʷ,ˣ,ʸ,ᶻ,ᵃ,ᵇ,ᶜ,ᵈ,ᵉ,ᶠ,ᵍ,ʰ,ᶦ,ʲ,ᵏ,ˡ,ᵐ,ⁿ,ᵒ,ᵖ,ᵠ,ʳ,ˢ,ᵗ,ᵘ,ᵛ,ʷ,ˣ,ʸ,ᶻ,⁰,¹,²,³,⁴,⁵,⁶,⁷,⁸,⁹"
	;		, "smallCapitals", "ᴀ,ʙ,ᴄ,ᴅ,ᴇ,ғ,ɢ,ʜ,ɪ,ᴊ,ᴋ,ʟ,ᴍ,ɴ,ᴏ,ᴘ,ǫ,ʀ,s,ᴛ,ᴜ,ᴠ,ᴡ,x,ʏ,ᴢ"
	;		, "mirror", "ɒ,d,ɔ,b,ɘ,ʇ,ϱ,ʜ,i,į,ʞ,l,m,n,o,q,p,ɿ,ƨ,Ɉ,υ,v,w,x,γ,z"
			, "upsidedown", "ɐ,q,ɔ,p,ǝ,ⅎ,ƃ,ɥ,ᴉ,ɾ,ʞ,ʅ,ɯ,u,o,d,b,ɹ,s,ʇ,n,ʌ,ʍ,x,ʎ,z,∀,ꓭ,Ͻ,ᗡ,Ǝ,ᖵ,⅁,H,I,ᒋ,ꓘ,⅂,ꟽ,N,O,Ԁ,Ꝺ,ꓤ,S,ꓕ,Ո,Ʌ,Ϻ,X,⅄,Z,0,⇂,↊,↋,ᔭ,5,9,𝘓,8,6"
	;		, "special", "ß,ẞ"
			, "sharpScript", "闩,⻏,⼕,ᗪ,🝗,ﾁ,Ꮆ,卄,讠,丿,长,㇄,爪,𝓝,ㄖ,尸,Ɋ,尺,丂,〸,ㄩ,ᐯ,山,〤,丫,Ⲍ,闩,乃,⼕,ᗪ,㠪,千,Ꮆ,廾,工,丿,长,㇄,爪,𝓝,龱,尸,Ɋ,尺,丂,ㄒ,ㄩ,ᐯ,山,乂,ㄚ,乙,0,丨,己,㇌,丩,5,6,7,〥,9")
		for i, e in strings {
			this.alphabets[i] := this.mapFromArrays(StrSplit(serifNormal, ","), StrSplit(e, ","))	
		}
		this.zalgo := ["̾","̿","̀","́","͂","̓","̈́","ͅ","͆","͇","͈","͉","͊","͋","͌","͍","͎","͏","͐","͑","͒","͓","͔","͕","͖","͗","͘","͙","͚","͛","͜","͝","͞","͟","͠","͡","͢","ͣ","ͤ","ͥ","ͦ","ͧ","ͨ","ͩ","ͪ","ͫ","ͬ","ͭ","ͮ"]
	}

	static mapFromArrays(keyArray, valueArray) {
		if (keyArray.Length != valueArray.Length || !(keyArray is Array) || !(valueArray is Array))
			return 5
		tM := Map()
		for i, e in keyArray
			tM[e] := valueArray[i]
		return tM
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

	static replaceCharacters(text, alphName) {
		result := ""
		Loop Parse, text {
			if (this.alphabets[alphName].Has(A_LoopField))
				result .= this.alphabets[alphName][A_LoopField]
			else
				result .= A_Loopfield
		}
		return result
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

