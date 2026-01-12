#Include "%A_ScriptDir%\LibrariesV2\BasicUtilities.ahk"
#Include "%A_ScriptDir%\LibrariesV2\MathUtilities.ahk"
#Include "%A_ScriptDir%\LibrariesV2\ObjectUtilities.ahk"
#Include "%A_ScriptDir%\LibrariesV2\TimeUtilities.ahk"
#Include "%A_ScriptDir%\LibrariesV2\FileUtilities.ahk"
#Include "%A_ScriptDir%\LibrariesV2\PrimitiveUtilities.ahk"

drawMouseCircle(radius, centerX?, centerY?, max_degrees := 360) {
	MouseGetPos(IsSet(centerX) ? unset : &centerX, IsSet(centerY) ? unset : &centerY)
	MouseMove(centerX, centerY + radius)
	Sleep(50)
	Send("{LButton Down}")
	SendMode("Event")
	Loop(max_degrees) {
		x := Round(radius * Sin(2 * A_Index/max_degrees * 3.141592653))
		y := Ceil(radius * Cos(2 * A_Index/max_degrees * 3.141592653))
		MouseMove(centerX + x, centerY + y, 1)
	}
	Send("{LButton Up}")
}

updateScript() {
	url := "https://raw.githubusercontent.com/Cobracrystal/ahk/refs/heads/main/LibrariesV2/" . A_ScriptName
	text := sendRequest(url)
	thisScript := FileRead(A_LineFile, "UTF-8")
	if StrCompare(text, thisScript)
		Download(url, A_LineFile)
}

class Demonstrator {

	static demonstratePropertyDistribution() {
		thing1 := this.Thing()
		thing2 := this.Thing
		thing3 := this.Thing.Prototype
		for e in ["property", "method", "staticProperty", "staticmethod", "__Class"] {
			print("Instance:     " e ": HasOwnProp => " thing1.HasOwnProp(e) ", HasProp => " thing1.HasProp(e) ", HasMethod => " thing1.HasMethod(e))
			print("Class Object: " e ": HasOwnProp => " thing2.HasOwnProp(e) ", HasProp => " thing2.HasProp(e) ", HasMethod => " thing2.HasMethod(e))
			print("Prototype   : " e ": HasOwnProp => " thing3.HasOwnProp(e) ", HasProp => " thing3.HasProp(e) ", HasMethod => " thing3.HasMethod(e))
		}
	}

	static demonstrateInheritance() {
		obj := this.Thing
		base__ClassChain := 		".__Class of base chain: `n> " obj.__Class "`n"
		Prototype__ClassChain := 	".__Class of Prototype chain: `n> " obj.Prototype.__Class "`n"
		full__ClassChain := 		".__Class of Prototype of base: `n> " Type(obj) ": " obj.Prototype.__Class "`n"
		base := ObjGetBase(obj)
		sep := ""
		while (base) {
			sep .= "`t"
			base__ClassChain .= sep " > " base.__Class "`n"
			full__ClassChain .= sep " > " Type(base) ": " (Type(base) != "Prototype" ? base.Prototype.__Class : base.__Class) "`n"
			base := ObjGetBase(base)
		}
		sep := ""
		base := ObjGetBase(obj.Prototype)
		while (base) {
			sep .= "`t"
			Prototype__ClassChain .= sep " > " base.__Class "`n"
			base := ObjGetBase(base)
		}
		print(base__ClassChain)
		print(Prototype__ClassChain)
		print(full__ClassChain)
	}

	class Thing extends Map {
		property := 1
		method() => 5

		static staticproperty := 2
		static staticmethod() => 7
	}

	static showIcons(dll := 1) {
		if (IsInteger(dll))
			dll := dll ? "imageres.dll" : "shell32.dll"
		g := Gui()
		Loop(512) {
			i := A_Index
			try {
				r := g.AddPicture((Mod(i, 32) ? "yp" : "x16") " w32 h32 Icon" i, dll)
				r.iconid := i
				r.OnEvent("Click", (o, *) => msgbox(o.iconid))
			}
		}
		g.show()
	}

	static showBigIcons(dll := 1) {
		if (IsInteger(dll))
			dll := dll ? "imageres.dll" : "shell32.dll"
		g := Gui()
		Loop(512) {
			i := A_Index
			try {
				r := g.addpicture((Mod(i, 32) ? "yp" : "x16") " w32 h32", "HICON:" LoadPicture("imageres.dll", "Icon" i, &it))
				r.iconid := i
				r.onevent("Click", (o,*) => msgbox(o.iconid))
			}
		}
		g.show()
	}

	static showScrollbarPosition() {
		static SIF_RANGE := 0x01
		static SIF_PAGE := 0x02
		static SIF_POS := 0x04
		static SIF_TRACKPOS := 0x10
		static SIF_ALL := (SIF_RANGE | SIF_PAGE | SIF_POS | SIF_TRACKPOS)
		static SB_HORZ := 0
		static SB_VERT := 1
		static SB_CTL := 2
		static SB_BOTH := 3
		static SB_BOTTOM := 7
		static WM_VSCROLL := 0x115
		g := Gui()
		g.OnEvent("Close", (*) => ExitApp())
		g.OnEvent("Escape", (*) => ExitApp())
		ed := g.addEdit("+ReadOnly R20 w200", "Start")
		g.show()
		Loop(51)
			ed.Value .= Format("`nLine {}", A_Index)
		Loop {
			NumPut("UInt", 28, ScrollInfo := Buffer(28, 0))
			NumPut("UInt", SIF_ALL, ScrollInfo, 4)
			DllCall("GetScrollInfo", "uint", ed.hwnd, "int", SB_VERT, "Ptr", ScrollInfo)
			nMin := NumGet(ScrollInfo, 8, "int")
			nMax := NumGet(ScrollInfo, 12, "int")
			nPage := NumGet(ScrollInfo, 16, "uint")
			curPos := NumGet(ScrollInfo, 20, "uint")
			; curPos := DllCall("user32\GetScrollPos", "Ptr", ed.hwnd, "int", SB_VERT)
			ToolTip(nMin "-" nMax ": " curPos ". " nPage)
			trueMax := nMax - nPage + 1
			position := curPos / (trueMax - nMin)
			ToolTip(nMin "-" nMax ": " curPos ". " nPage ": " position)
			; PostMessage(WM_VSCROLL, SB_BOTTOM, 0, ed.hwnd)
			; postmessage(0xB7,-1,-2, ed.hwnd)
			Sleep(200)
		}
		; EM_SCROLLCARET
	}

	static coloredGUI() {
		newGui := Gui("+Border", "a")
		newGui.SetFont("c0x00FF00")
		newGui.BackColor := "0x1e1e1e"
		newGui.LV := newGui.AddListView("R5 w150", ["A", "B", "C"]) ; LVEvent, Altsubmit
		newGui.AddGroupBox("w500 h50", "TEEEXT")
		newGui.AddButton("Section r1 w100", "Add Row to List").OnEvent("Click", (*) => 0)
		showString := "Center Autosize"
		newGui.AddText("ys", "UHHH HELLO?????")
		newGui.AddCheckbox("ys", "Hey there")
		for i, ctrl in newGui {
			ctrl.SetFont("c0xFF0000")
			ctrl.Opt("+BackgroundYellow")
		}
		newGui.Show(showString)
	}

	; ORDER OF OPERATIONS
	; static __Init() (aka static variables at the top) is called for the class Prototype
	; static __New() then this prototype is created and thus this gets launched
	; if we are calling the class (ie. instance := ClassName())
	; static Call is called. This normally would call __Init and __New, but can be override. Then use super()
	; Call must return the class instance.

	class OperationOrder {
		; static asd := msgbox(1) ; commented out since this would always pop up at start of script
		; sdf := msgbox(4) ; since __Init is defined, this is illegal

		__Init() {
			msgbox(4)
			this.asd := 5
		}

		static method1(a) {
			return 5
		}

		static Call(asd) {
			msgbox(3)
			super("__NewParam") ; -> return class instance
			return this ; -> return class object
		}
		static __New() {
			; msgbox(2) ; commented out since this would always pop up at start of script
		}

		__New(*) {
			msgbox(5)
		}

		method2(*) {
			return 5
		}
	}
	
	/*
	we have an object.
	if it is a class instance object, we wish to get the properties that it got from the class
	ie. msgbox is a func object and thus has the MinParams property, but this property does not appear in ObjOwnProps(Msgbox)

	if it is enumerable, we directly enumerate it.

	we enumerate ObjOwnProps() with one variable. This will get us ALL property names.
	If a property name has a getter, call it.
	Otherwise, print information about that property

	if the object has a Base object, enumerate that.

	the base of a class is the class object that it is extended from.
	the base of class Any is class.Prototype and then we chain
	The base of a class instance is class.Prototype
	Now:
	class Thing {
		property := 1
		static staticproperty := 2
		method() => 1
		static staticmethod => 2
	}

	The Instance contains only instance properties. Instance methods are inherited from Prototype. __Class is inherited from Prototype and contains the class name 
	Method counts as Prop, not an OwnProp
	The Prototype contains only instance methods and Properties (that exist in the class. Properties assigned via New/Init/Assignments in class Body are not included) 
	. __Class is defined here and is the class name
	Method counts as OwnProp
	The class Object contains only static properties and static methods. __Class is inherited from class class and thus contains "Class"
	static methods count as OwnProps
	*/
}

objIterate(o,f) { ; this could be a oneliner
	return (
		t(o,f,fl,en,*) => (
			en(&i, &e) ? t(
				o,
				f,
				fl,
				en,
				fl ? o[i] := f(e) : o.%i% := f(e)
			) : o
		),
		t(
			o.Clone(),
			f,
			fl := (o is Array || o is Map),
			fl ? o.__Enum(2) : o.OwnProps().__Enum(2)
		)
	)
}

printCompareFolders(folder1, folder2) {
	comp := compareFolders(folder1, folder2)
	comp := objSort(comp, a => a.size, "N A")
	for e in comp
		print((instr(e.attrib, "D") ? "Folder: " : "File:   ") . strfill( "[" e.size "] ", 15) e.path)
	print("Total size: " objGetSum(comp, a => a.size))
	print("Total count: "  comp.Length)

	comp := compareFolders(folder2, folder1)
	comp := objSort(comp, a => a.size, "N A")
	for e in comp
		print((instr(e.attrib, "D") ? "Folder: " : "File:   ") . strfill( "[" e.size "] ", 15) e.path)
	print("Total size: " objGetSum(comp, a => a.size))
	print("Total count: "  comp.Length)
}

ao3GetBookmarkChapterCount(pages) => objGetSum(ao3GetBookmarks(pages), v => ((p := InStr(v.chapters, "/")) ? SubStr(v.chapters, 1, p-1) : v.chapters))
ao3GetBookmarkWordcount(pages) => objGetSum(ao3GetBookmarks(pages), v => v.words)
ao3GetBookmarks(pages) {
	bigArr := []
	arr := getBookmarks(pages)
	; return MapToObj(jsongo.Parse(A_Clipboard))
	for i, key in arr
		bigArr.push(ao3parseHtml(key)*)
	return bigArr

	ao3parseHtml(str) {
		pos := 1
		arr := []
		len := strlen(str)
		A_Clipboard := str
		while (pos <= len) {
			work := {}
			pos := InStr(str, '<!--title, author, fandom-->',, pos)
			if (pos == 0)
				break
			RegExMatch(str, '<a href="\/works\/(\d+)">(.*?)<\/a>', &workMatch, pos)
			posEnd := RegExMatch(str, '<dl class="stats">((?:.|\n)*?)<\/dl>', &workStats, pos)
			work.id := workMatch[1]
			work.name := workMatch[2]
			for key in ["language","words","chapters","comments","kudos","bookmarks","hits"] {
				if RegExMatch(workstats[1], '<dd class="' key '"[^>]*?>(?:<a[^>]*?>)?([^>]*?)(?:<\/a>[^<>\n]*?)?(?:\s|\n)*\/?<\/dd>', &stat)
					work.%key% := Trim(StrReplace(stat[1], ","), " `t`n`r\/")
			}
			pos := posEnd + StrLen(workStats[0])
			arr.push(work)
		}
		return arr
	}

	getBookmarks(pages) {
		static baseURL := "https://archiveofourown.org/users/Cobracrystal/bookmarks"
		htmlArr := []
		Loop (pages) {
			htmlArr.push(sendRequest(baseURL . (A_Index > 1 ? "?page=" A_Index : "")))
			print(Round(A_Index / pages * 100, 1) "%")
		}
		return htmlArr
	}
}

sessionBuddyGetObjectFromOneTabHTML(path) {
	; path := "C:\Users\Simon\Downloads\website.htm"
	html := FileRead(path, "UTF-8")
	output := ""
	previous := ""
	collectionsArray := []
	collection := {}
	url := {}
	loop parse html, "`n", "`r" {
		line := A_LoopField
		if (InStr(line, 'class="tabGroup"')) {
			if (ObjOwnPropCount(collection) > 0)
				collectionsArray.push(collection)
			collection := {title: "", links: []}
		}
		else if (InStr(line, 'class="tabGroupLabel"')) {
			RegexMatch(line, '<div class="tabGroupLabel">(.*)</div>', &o)
			collection.title := htmlDecode(o[1])
		} else if (InStr(line, '<div class="tab">')) {
			if (ObjOwnPropCount(url) > 0)
				collection.links.push(url)
			url := {}
		} else if (InStr(line, 'class="favIconImg"')) {
			RegExMatch(line, '<img class="favIconImg" src="(.*)">', &o)
			url.favIconUrl := htmlDecode(o[1])
		} else if (InStr(line, 'class="tabLink"')) {
			RegExMatch(line, '<a class="tabLink" rel="ugc" href="(.*)">(.*)</a>', &o)
			url.url := htmlDecode(o[1])
			url.title := htmlDecode(o[2])
		}
	}
	collection.links.push(url)
	collectionsArray.Push(collection)
	return jsongo.Stringify(collectionsArray)
}

sessionBuddyTransformSpecificCollectionsWithReadInName(text) {
	; text := FileRead("C:\Users\Simon\Desktop\programs\programming\ahk\oneTabJson.json", "UTF-8")
	obj := jsongo.parse(text)
	collectionRead := {title:"read", folders:[]}
	collectionTodo := {title:"Todo", folders:[]}
	collection3 := {title:"Other", folders:[]}
	local collectionsArray := [collectionRead, collectionTodo, collection3]
	for i, e in obj {
		timestamp := e["created"]
		e.Delete("created")
		for j, url in e["links"] {
			RegExMatch(url["url"], "(https?://[^/]+)", &o)
			url["favIconUrl"] := o[1] "/favicon.ico"
		}
		if (InStr(e["title"], "read")) {
				e["title"] := DateAddW("19700101000000", timestamp / 1000, "S")
				collectionRead.folders.push(e)
		} else if (InStr(e["title"], "todo"))
			collectionTodo.folders.Push(e)
		else
			collection3.folders.Push(e)
		
	}
	return jsongo.Stringify(collectionsArray)
}

calculateCompatibilityData() {
	input := "
	( LTrim
	REDACTED 66	93	42	54	70	59	88	69	90	79
	REDACTED 93	26	98	77	64	96	69	70	39	82
	REDACTED 42	98	31	41	68	40	77	66	95	69
	REDACTED 54	77	41	71	90	56	72	80	85	70
	REDACTED 70	64	68	90	100	74	75	93	76	80
	REDACTED 59	96	40	56	74	59	88	72	96	81
	REDACTED 88	69	77	72	75	88	97	78	74	91
	REDACTED 69	70	66	80	93	72	78	95	81	86
	REDACTED 90	39	95	85	76	96	74	81	56	85
	REDACTED 79	82	69	70	80	81	91	86	85	94
	)"
	names := Map()
	compareNames := Map()
	compData := parseInput(input)
	; obj := calculateNComp(3)
	obj := calculateHarem(7)
	; obj := objSort(obj, v => v.score, 'N D')
	; A_Clipboard := prettyPrintNCompList(obj)
	A_Clipboard := prettyPrintHaremList(obj)
	; g := gui()
	; lv := g.AddListView('w800 h400 Sort Hdr', ["Score", "Name", "Name", "Name"])
	; for e in obj
	; 	lv.Add(, Round(e.score), e.names*)
	; Loop(4)
	; 	lv.ModifyCol(A_Index, 'AutoHdr')
	; g.show()
	return

	prettyPrintHaremList(data) {
		str := ""
		for i, e in data
			str .= print(e.master '`t' objCollectString(e.members, '`t') '`t' e.score)
		return str
	}

	prettyPrintNCompList(data) {
		str := ""
		for i, e in data
			str .= print(objCollectString(e.names, '`t') . '`t' . e.score)
		return str
	}

	; calculates compatibility of a harem, meaning one person + [members] other people
	calculateHarem(members) {
		n := members + 1
		obj := []
		dataLenRange := rangeAsArr(1, compData[1].Length)
		for memberIndexes in chooseCombinations(dataLenRange, n) {
			listOfPairs := chooseCombinations(memberIndexes, 2)
			if samePersonTwice(listOfPairs)
				continue
			for i, haremMaster in memberIndexes {
				haremMembers := arrayIgnoreIndex(memberIndexes, i)
				score := 0
				for j, member in haremMembers
					score += compData[haremMaster][member]
				obj.push({ score: Round(score / members, 1), members: objDoForEach(haremMembers, v => Format("{:T}", names[v])), master: Format("{:T}", names[haremMaster])})
			}
		}
		return obj
	}

	calculateThrouple() => calculateNComp(3)
	calculateQuartett() => calculateNComp(4)

	; calculates average compability between n members
	calculateNComp(n) {
		obj := []
		dataLenRange := rangeAsArr(1, compData[1].Length)
		for memberIndexes in chooseCombinations(dataLenRange, n) {
			listOfPairs := chooseCombinations(memberIndexes, 2)
			if samePersonTwice(listOfPairs)
				continue
			score := 0
			loop(n)
				score += scoreFromIndexArr(listOfPairs[A_Index])
			obj.push({ score: Round(score / n, 1), names: objDoForEach(memberIndexes, v => Format("{:T}", names[v]))})
		}
		return obj
	}

	scoreFromIndexArr(inArr) => compData[inArr[1]][inArr[2]]

	samePersonTwice(obj) {
		for a in obj
			if strInEachOther(a[1], a[2])
				return true			
		return false
		
		strInEachOther(i, j) => compareNames[i] == compareNames[j]
	}

	parseInput(input) {
		arr := []
		for i, line in strSplitOnNewLine(input) {
			tArr := []
			for k, pNum in strSplitOnWhiteSpace(line) {
				if !IsInteger(pNum) {
					if k == 1 {
						compareNames[i] := pNum
						name := pNum
					} else
						name .= ' ' pNum
				}
				else
					tArr.push(Integer(pNum))
			}
			names[i] := Trim(name)
			arr.push(tArr)
		}
		return arr
	}
}

sessionBuddyCollectionTransformToFoldersAndFaviconLinks() {
	text := FileRead("C:\Users\Simon\Desktop\programs\programming\ahk\oneTabJson.json", "UTF-8")
	obj := jsongo.parse(text)
	local collectionsArray := []
	for i, e in obj {
		for j, url in e["links"] {
			RegExMatch(url["url"], "(https?://[^/]+)", &o)
			url["favIconUrl"] := o[1] "/favicon.ico"
		}
		e["folders"] := [{links:e["links"]}]
		e.delete("links")
	}
	A_Clipboard := jsongo.Stringify(obj)
}

sortYoutubePlaylistLinksByIndex() {
	str := A_Clipboard
	o := []
	loop parse str, "`n" {
		if RegExMatch(A_LoopField, "(.*)&list=WL&index=(\d+)", &m) {
			o.push({link:m[0], index:m[2]})
		}
	}
	s := ""
	sorted := objSort(o, r => r.index, "N")
	for i, e in sorted {
		s .= e.link "`n"
	}
	A_Clipboard := s
}