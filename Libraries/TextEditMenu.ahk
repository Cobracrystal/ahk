#Include %A_ScriptDir%\Libraries\BasicUtilities.ahk

TextEditMenuVar := Func("textMenuHandler")
Menu, textModify, Add, Spongebobify, % TextEditMenuVar
Menu, textModify, Add, Spaceit, % TextEditMenuVar
Menu, textModify, Add, Reverse, % TextEditMenuVar
Menu, textModify, Add, Smallify, % TextEditMenuVar
Menu, textModify, Add, Smallcapify, % TextEditMenuVar
Menu, runifyMenu, Add, Runify (DE), % TextEditMenuVar
Menu, runifyMenu, Add, Runify (EN), % TextEditMenuVar
Menu, textModify, Add, Runify, :runifyMenu
Menu, derunifyMenu, Add, Derunify (DE), % TextEditMenuVar
Menu, derunifyMenu, Add, Derunify (EN), % TextEditMenuVar
Menu, textModify, Add, Derunify, :derunifyMenu


textMenuHandler(menuLabel) {
	text := fastCopy()
	if text is space
		return
	switch menuLabel {
		case "Spongebobify":
			result := spongebobify(text)
		case "Spaceit":
			result := spreadString(text, " ")
		case "Reverse":
			result := reverseString(text)
		case "Smallify":
			result := smallify(text)
		case "Smallcapify":
			result := smallcapify(text)
		case "Runify (DE)":
			result := runify(text, "DE")
		case "Runify (EN)":
			result := runify(text, "EN")
		case "Derunify (DE)":
			result := derunify(text, "DE")
		case "Derunify (EN)":
			result := derunify(text, "EN")
		default:
			MsgBox, % menuLabel
	}
	fastPrint(result)
}

spongebobify(text) {
	result := ""
	c := ""
	Loop, Parse, text
	{
		Random, caseFormat, 0, 1
		if (caseFormat)
			c := Format("{:U}", A_LoopField)
		else 
			c := Format("{:L}", A_LoopField)
		result := result . c
	}
	return result
}

spreadString(text, delimiter, trim := 1) {
	result := ""
	Loop, Parse, text 
	{
		result := result . A_LoopField . delimiter
	}
	if (trim)
		result := RTrim(result, Omitchars := delimiter)
	return result
}

reverseString(text) {
	result := ""
	Loop, Parse, text 
	{
		result := A_LoopField . result 
	}
	return result
}

smallify(text) {
	return ReplaceChars(text, "abcdefghijklmnopqrstuvwxyz", "ᵃᵇᶜᵈᵉᶠᵍʰᶦʲᵏˡᵐⁿᵒᵖᵠʳˢᵗᵘᵛʷˣʸᶻ")
}

smallcapify(text) {
	return ReplaceChars(text, "abcdefghijklmnopqrstuvwxyz", "ᴀʙᴄᴅᴇғɢʜɪᴊᴋʟᴍɴᴏᴘǫʀsᴛᴜᴠᴡxʏᴢ")
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
	result := ReplaceChars(text, "ᚫᛒᚳᛞᛖᚠᚷᚻᛁᛃᚲᛚᛗᚾᛟᛈᚱᛋᛏᚢᚹᚹᛃ", "abcdefghijklmnoprstuvwyz")
	return result
}

ReplaceChars(Text, Chars, ReplaceChars) 
{
	ReplacedText := Text
	Loop, parse, Text, 
	{
		Index := A_Index
		Char := A_LoopField
		Loop, parse, Chars,
		{
			if (A_LoopField = Char) {
				ReplacedText := SubStr(ReplacedText, 1, Index-1) . SubStr(ReplaceChars, A_Index, 1) . SubStr(ReplacedText, Index+1)
				break
			}
		}
	}
	return ReplacedText
}