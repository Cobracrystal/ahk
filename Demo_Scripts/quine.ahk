#Requires AutoHotkey >=v2.0
newline := '`n'
quote := '"'
escape := '``'
str := "#Requires AutoHotkey >=v2.0{1}newline := '{3}n'{1}quote := '{2}'{1}escape := '{3}{3}'{1}str := {2}{4}{2}{1}fStr := Format(str, newline, quote, escape, str){1}try FileAppend(fStr, '*', 'UTF-8'){1}catch {1}	MsgBox(fStr){1}"
fStr := Format(str, newline, quote, escape, str)
try FileAppend(fStr, '*', 'UTF-8')
catch 
	MsgBox(fStr)
