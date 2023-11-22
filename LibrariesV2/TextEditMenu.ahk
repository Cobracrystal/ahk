#Include %A_ScriptDir%\LibrariesV2\BasicUtilities.ahk


capitalMenu := Menu()
capitalMenu.Add("Spongebobify", textMenuHandler)
capitalMenu.Add("All Uppercase", textMenuHandler)
capitalMenu.Add("All Lowercase", textMenuHandler)
capitalMenu.Add("Proper Capitals", textMenuHandler)
textModifyMenu := Menu()
textModifyMenu.Add("Lettercasify", capitalMenu)
textModifyMenu.Add("Spaceit", textMenuHandler)
textModifyMenu.Add("Reverse", textMenuHandler)
textModifyMenu.Add("Mirror", textMenuHandler)
textModifyMenu.Add("Smallify", textMenuHandler)
textModifyMenu.Add("Smallcapify", textMenuHandler)
textModifyMenu.Add("Upsidedownify", textMenuHandler)
textModifyMenu.Add("Zalgoify", textMenuHandler)
; Menu, runifyMenu, Add, Runify (DE), % TextEditMenuVar
; Menu, runifyMenu, Add, Runify (EN), % TextEditMenuVar
; Menu, textModify, Add, Runify, :runifyMenu
; Menu, derunifyMenu, Add, Derunify (DE), % TextEditMenuVar
; Menu, derunifyMenu, Add, Derunify (EN), % TextEditMenuVar
; Menu, textModify, Add, Derunify, :derunifyMenu

textMenuHandler(menuLabel, menuLabelNum, menuName) {
;	msgbox % menuLabel ", " menuLabelNum "," menuName
;	return
	text := fastCopy()
	if(IsSpace(text))
		return
	switch menuLabel {
		case "Spongebobify":
			result := spongebobify(text)
		case "All Uppercase":
			result := uppercasify(text)
		case "All Lowercase":
			result := lowercasify(text)
		case "Proper Capitals":
			result := capitalify(text)
		case "Spaceit":
			result := spreadString(text, " ")
		case "Reverse":
			result := reverseString(text)
		case "Mirror":
			result := mirrorify(text)
		case "Smallify":
			result := smallify(text)
		case "Smallcapify":
			result := smallcapify(text)
		case "Upsidedownify":
			result := upsidedownify(text)
		case "Zalgoify":
			result := zalgoify(text, 5)
		case "Runify (DE)":
			result := runify(text, "DE")
		case "Runify (EN)":
			result := runify(text, "EN")
		case "Derunify (DE)":
			result := derunify(text, "DE")
		case "Derunify (EN)":
			result := derunify(text, "EN")
		default:
			MsgBox("Unexpected Label name: " . menuLabel)
	}
	fastPrint(result)
}

spongebobify(text) {
	result := ""
	c := ""
	Loop Parse, text
	{
		caseFormat := Random(0, 1)
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

uppercasify(text) {
	return Format("{:U}", text)
}

lowercasify(text) {
	return Format("{:L}", text)
}

capitalify(text) {
	return Format("{:T}", text)
}

spreadString(text, delimiter, trim := 1) {
	result := ""
	Loop Parse, text 
	{
		result := result . A_LoopField . delimiter
	}
	if (trim)
		result := RTrim(result, Omitchars := delimiter)
	return result
}

mirrorify(text) {
	text := reverseString(text)
	return ReplaceChars(text, "abcdefghijklmnopqrstuvwxyzɒdɔbɘʇϱʜiįʞlmnoqpɿƨɈυvwxγz", "ɒdɔbɘʇϱʜiįʞlmnoqpɿƨɈυvwxγzabcdefghijklmnopqrstuvwxyz")
}

smallify(text) {
	return ReplaceChars(text, "abcdefghijklmnopqrstuvwxyzᵃᵇᶜᵈᵉᶠᵍʰᶦʲᵏˡᵐⁿᵒᵖᵠʳˢᵗᵘᵛʷˣʸᶻ", "ᵃᵇᶜᵈᵉᶠᵍʰᶦʲᵏˡᵐⁿᵒᵖᵠʳˢᵗᵘᵛʷˣʸᶻabcdefghijklmnopqrstuvwxyz")
}

smallcapify(text) {
	return ReplaceChars(text, "abcdefghijklmnopqrstuvwxyzᴀʙᴄᴅᴇғɢʜɪᴊᴋʟᴍɴᴏᴘǫʀsᴛᴜᴠᴡxʏᴢ", "ᴀʙᴄᴅᴇғɢʜɪᴊᴋʟᴍɴᴏᴘǫʀsᴛᴜᴠᴡxʏᴢabcdefghijklmnopqrstuvwxyz")
}

upsidedownify(text) {
	text := reverseString(text)
	return ReplaceChars(text, "abcdefghijklmnopqrstuvwxyzɐqɔpǝɟƃɥᴉɾʞlɯuodbɹsʇnʌʍxʎz", "ɐqɔpǝɟƃɥᴉɾʞlɯuodbɹsʇnʌʍxʎzabcdefghijklmnopqrstuvwxyz")
}

zalgoify(str, intensity) {
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

runify(text, language) {
	switch language {
		case "DE":
			; // Basically, do the ReplaceChars function with all single chars that can be determined, then execute StringReplace a few times with the combinations. 
			; // this is really easy. why did i struggle with this before?
		case "EN":
	}
	result := ReplaceChars(text, "abcdefghijklmnopqrstuvwxyz", "ᚫᛒᚳᛞᛖᚠᚷᚻᛁᛃᚲᛚᛗᚾᛟᛈ◊ᚱᛋᛏᚢᚹᚹ□ᛃᛉ")
	return result
}

derunify(text, language) {
	result := ReplaceChars(text, 	"ᚠᚡᚢᚣᚤᚥᚨᚩᚪᚫᚬᚭᚮᚯᚰᚱᚲᚴᚵᚷᚸᚹᚺᚻᚼᚽᚾᚿᛀᛁᛂᛃᛄᛅᛆᛈᛉᛊᛋᛌᛍᛎᛏᛐᛑᛒᛓᛔᛕᛖᛗᛘᛙᛚᛛᛞᛟᛤᛦᛧ", 	"fvuyywaoaaoooöorkkgggvhhhhnnnieyjaapzsssczttdbbppemmmlldokry")
	return result
}
