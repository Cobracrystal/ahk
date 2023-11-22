#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

return

^+R::
Reload
return

^+!P::
Gui, CodeGen:New, +Border
Gui, CodeGen:Add, Button, vCustom		Default h30 w100 			gEncode Section, Custom Encode 
Gui, CodeGen:Add, Button, 				Default h30 w100 xp ys+30 	gSwapTextAndEdit, Swap Fields
Gui, CodeGen:Add, Button, vRunesDE		Default h30 w100 ys 		gButtonEncodeRunic, Latin->Runes (DE)
Gui, CodeGen:Add, Button, vRunesRDE		Default h30 w100 xp ys+30 	gButtonDecodeRunic, Runes->Latin (DE)
Gui, CodeGen:Add, Button, vAlphabet 	Default h30 w100 ys 		gEncode, a->b->c etc.
Gui, CodeGen:Add, Button, vAlphabetR 	Default h30 w100 xp ys+30 	gEncode, a<-b<-c etc.
Gui, CodeGen:Add, Button, vVocals 		Default h30 w100 ys 		gEncode, a->e->i->o->u->a
Gui, CodeGen:Add, Button, vVocalsR 		Default h30 w100 xp ys+30 	gEncode, a<-e<-i<-o<-u<-a
Gui, CodeGen:Add, Button, vReverse 		Default h30 w100 xs 		gEncode Section, Reverse
Gui, CodeGen:Add, Button, vRunesEN		Default h30 w100 ys 		gButtonEncodeRunic, Latin->Runes (EN)
Gui, CodeGen:Add, Button, vRunesREN		Default h30 w100 xp ys+30 	gButtonDecodeRunic, Runes->Latin (EN)
Gui, CodeGen:Add, Edit, Section xs vInput r20 w480
Gui, CodeGen:Add, Edit, vOutput r20 w480 ReadOnly, Encoded Text will appear here when pressing "Encode" Button.
Gui, CodeGen:Show, AutoSize, Encoder
return

SwapTextAndEdit:
Gui, CodeGen:Submit, NoHide
temp := Input
GuiControl, CodeGen:, Input, %Output%
GuiControl, CodeGen:, Output, %temp%
return

Encode:
Gui, CodeGen:Submit, NoHide
switch A_GuiControl {
	Case "Custom":
		InputBox, chars, InputChars, Symbols that you want to replace (As a Word without spaces)
			if ErrorLevel
				return
		InputBox, ReplaceChars, OutputChars, The Symbols that you want to replace those with (As a word of the same length without spaces)
			if ErrorLevel
				return
		
		if !(StrLen(chars) = StrLen(ReplaceChars)) {
			MsgBox, 4,, The strings have different length. This means the replacement may not work properly or at all. Do you want to continue?
				IfMsgBox, No
					return
				IfMsgBox, Timeout
					return
		}
	Case "Alphabet": 
		chars = "abcdefghijklmnopqrstuvwxyzäöü"
		replaceChars = "bcdefghijklmnopqrstuvwxyzaöüä"
	Case "AlphabetR":
		chars = "bcdefghijklmnopqrstuvwxyzaöüä"
		replaceChars = "abcdefghijklmnopqrstuvwxyzäöü"
	Case "Vocals":
		chars = "aeiou"
		replaceChars = "eioua"
	Case "VocalsR":
		chars = "eioua"
		replaceChars = "aeiou"
	Case "Reverse":
		chars = "abcdefghijklmnopqrstuvwxyz"
		replaceChars = "zyxwvutsrqponmlkjihgfedcba"
	Case "Default":
		chars = "abcdefghijklmnopqrstuvwxyz01234567890ßäöü.,;:-_#'+*~`´?=()/&$§!²³{[]}<>|"
		replaceChars = "□"
}
ReplacedText := ReplaceChars(Input, chars, replaceChars)
GuiControl, CodeGen:, Output, %ReplacedText%
return

ButtonEncodeRunic:
Gui, CodeGen:Submit, NoHide
; todo: check ei, th, ch, sh -> ᛝ,ᛪ,ᚦ,ᛇ
ReplacedText := ReplaceChars(Input, "abcdefghijklmnopqrstuvwxyz", "ᚫᛒᚳᛞᛖᚠᚷᚻᛁᛃᚲᛚᛗᚾᛟᛈ◊ᚱᛋᛏᚢᚹᚹ□ᛃᛉ")
; todo: ?, ◊ -> ᚲᚹ (de) / ᚲᚢ (en), ᚲᛋ
GuiControl, CodeGen:, Output, %ReplacedText% 
return

ButtonDecodeRunic:
Gui, CodeGen:Submit, NoHide
; todo: check ᚲᚹ (de), ᚲᚢ (en), ᚲᛋ, 
ReplacedText := ReplaceChars(Input, "ᚫᛒᚳᛞᛖᚠᚷᚻᛁᛃᚲᛚᛗᚾᛟᛈᚱᛋᛏᚢᚹᚹᛃ", "abcdefghijklmnoprstuvwyz")
; ᛝ,ᛪ,ᚦ,ᛇ -> ch, sh, th, ei
GuiControl, CodeGen:, Output, %ReplacedText% 
return


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











