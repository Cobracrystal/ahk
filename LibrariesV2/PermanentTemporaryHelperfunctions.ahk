#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\jsongo.ahk"

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