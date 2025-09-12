#Requires AutoHotkey v2
#Include "%A_LineFile%\..\..\LibrariesV2\jsongo.ahk"
SetWorkingDir(A_WorkingDir "\..\script_files")
fileNameFrom := A_WorkingDir "\TableFilter\Kayoogis.json"

str := transformTableIntoHotstring(fileNameFrom, "Deutsch", "Kayoogis", "")
FileOpen(A_WorkingDir "\everything\kayoogishotstrings.json", "w", "UTF-8").write(str)

transformTableIntoHotstring(fileNameFrom, stringName, replacementName, options := "") {
	jsonasstr := FileRead(fileNameFrom)
	table := jsongo.Parse(jsonasstr)
	data := table["data"]
	if !data.Length
		return
	hotstrings := []
	for i, row in data {
		if (row.Has(stringName) && row.Has(replacementName) && row[stringName] != "" && row[replacementName] != "" && row[stringName] != "-" && row[replacementName] != "-") {
			hotstringasObj := Map()
			hotstringasObj["string"] := row[stringName]
			hotstringasObj["replacement"] := row[replacementName]
			hotstringasObj["options"] := options
			hotstrings.push(hotstringasObj)
		}
	}
	return jsongo.Stringify(hotstrings,, "`t")
}