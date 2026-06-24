#Requires Autohotkey v2+
#Include "%A_LineFile%\..\..\LibrariesV2\External\jsongo.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\PrimitiveUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\ObjectUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\FileUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\BasicUtilities.ahk"
SetWorkingDir(A_ScriptDir "\script_files\")

class wpEngine {
	static pathSteamfolder := "C:\Program Files (x86)\Steam\SteamApps\common\wallpaper_engine"
	static pathWorkshop := "C:\Program Files (x86)\Steam\SteamApps\workshop\content\431960"
	static pathBackup := "C:\Program Files (x86)\Steam\SteamApps\common\wallpaper_engine\projects\backup"
	static pathDownloads := "C:\Program Files (x86)\Steam\SteamApps\workshop\downloads\431960"
	static mainPaths := [this.pathWorkshop, this.pathBackup]
	static allPaths := [this.pathWorkshop, this.pathBackup, this.pathDownloads]
	static steamBaseUrl := "https://steamcommunity.com/sharedfiles/filedetails/?id="
	static config := 0

	static getItemsByTag(folderPath := this.pathBackup, includeTag?, excludeTag?) {
		f := getFolderAsArr(folderPath, , 'FD', 0)
		f := this.getItemsFromFolderArr(f)
		lambda := v => (
			(IsSet(includeTag) ? (v.HasOwnProp('tags') ? objContainsValue(v.tags, includeTag) : false) : true) 
		 && (IsSet(excludeTag) ? (v.HasOwnProp('tags') ? !objContainsValue(v.tags, excludeTag) : true) : true)
		)
		A_Clipboard := toString(f, 0, 0, 1)
		f2 := this.filterItems(lambda, , f)
		return f2
		; objDoForEach(files, v => v.path "\" v.project["file"])
	}

	static getItemsFromFolderArr(folderArr?) {
		if !IsSet(folderArr)
			folderArr := getFolderAsArr(this.pathWorkshop, , 'FD', 0)
		for fObj in folderArr
			fObj.project := this.getConfigObjFromFolder(fObj.path)
		return folderArr
	}

	static getBackupConfigObjFromID(ID) => this.getConfigObjFromFolder(this.pathBackup "\" ID)

	static getDefaultConfigObjFromID(ID) => this.getConfigObjFromFolder(this.pathWorkshop "\" ID)

	static getConfigObjFromFolder(folderPath) {
		if !FileExist(folderPath)
			return 0
		str := FileRead(folderPath "\project.json", "UTF-8")
		try obj := jsongo.Parse(str)
		catch
			return ""
		return obj
	}

	static getFolderObjFromFolderName(folderName) {
		if !this.config
			this.loadMainWPConfig()
		folders := this.config["Cobracrystal"]["general"]["browser"]["folders"]
		foundFolder := []
		for fold in folders
			findInFolder(fold)
		if foundFolder.Length > 1
			return foundFolder
		else
			return foundFolder[1]

		findInFolder(folder) {
			for fold in folder["subfolders"]
				findInFolder(fold)
			if folder["title"] == folderName
				foundFolder.push(folder)
		}
	}

	/**
	 * Given a UI folder like 'Aesthetic', retrieves the item paths like 'C:/Program Files (x86)/Steam/SteamApps/common/wallpaper_engine/projects/backup/2766268842' or 'C:\Program Files (x86)\Steam\SteamApps\workshop\content\431960\382904233'
	 * @param folder 
	 * @returns {Any} 
	 */
	static getItemPathsFromWPUIFolder(folder) {
		paths := objflatten(folder["items"],,true)
		paths := objDoForEach(paths, v => StrReplace(v, '/', '\'))
		paths := objDoForEach(paths, v => InStr(v, "\") ? v : this.pathWorkshop "\" v)
		paths := objFilter(paths, (k, v) => FileExist(v)) 
		paths := objDoForEach(paths, v => getFileInfo(v)) 
		paths := objDoForEach(paths, v => !InStr(v.attrib, 'D') ? getFileInfo(v.dir) : v)
		paths := objDoForEach(paths, v => (v.project := this.getConfigObjFromFolder(v.path), v))
		return paths
	}

	static filterItems(comparator, sortedBy := 1, items?) {
		items := items ?? this.getItemsFromFolderArr()
		items := objFilter(items, (k, v) => comparator(v.project))
		switch sortedBy {
			case 0, "date", "created":
				return arraySort(items, v => v.timeCreated)
			case 1, "modified":
				return arraySort(items, v => v.timeModified)
			case 2, "title":
				return arraySort(items, v => v.project["title"])
			case 3, "size":
				return arraySort(items, v => v.size)
			case 4, "id":
				return arraySort(items, v => v.project["id"])
		}
	}

	; this finds files that are included in both the backup and current subscriptions.
	static findDuplicatesInBackup() {
		dupes := getFileDuplicates([this.pathWorkshop, this.pathBackup], ["name"], false, true)
		dupes := objDoForEach(dupes, v => objDoForEach(v, t => { name: t.name, dir: t.dir }))
		for e in dupes {
			e.url := this.steamBaseUrl . e.name
			try e.title := jsongo.parse(FileRead(e.dir "\" e.name "\project.json"))["title"]
			splitpath(e.dir, &subdir)
			e.dir := subdir
		}
		A_Clipboard := toString(dupes, 0, 0, 1)
		print(dupes)
	}

	static checkIfWorkshopItemsAccessible(fileArr) {
		; fileArr := getFolderAsArr(this.wpEnginePath, , 'FD', 1)
		l := fileArr.Length
		arr := []
		for i, e in fileArr {
			resp := sendRequest(this.steamBaseUrl e)
			if InStr(resp, "Subscribe to download") || InStr(resp, "You must be logged in to view this item.") {
				print(A_Index "/" l)
				continue
			}
			print(A_Index "/" l "(!)")
			f := this.pathBackup . "\" e "\project.json"
			ob := jsongo.Parse(FileRead(f, "utf-8"))
			ob["url"] := this.steamBaseUrl i
			ob["id"] := i
			try ob.delete("general")
			try ob.delete("tags")
			arr.push(ob)
		}
		return arr
	}

	static loadMainWPConfig() {
		this.config := jsongo.parse(FileRead(this.pathSteamfolder "\config.json", "UTF-8"))
	}

	static getItemsFromFolder(folderName, tag?, sortedBy := "title") {
		folderObj := wpEngine.getFolderObjFromFolderName(folderName)
		files := wpEngine.getItemPathsFromWPUIFolder(folderObj)
		lambda := IsSet(tag) ? (v => v.HasOwnProp('tags') ? objContainsValue(v.tags, tag) : false) : v => true
		files := wpEngine.filterItems(lambda, sortedBy, files)
		files := objFilter(files, (k, v) => v.project["type"] = "video") ; case insensitive !!!!
		files := objDoForEach(files, v => v.path "\" v.project["file"])
		return files
	}

	static checkConfigIntegrity() {
		configs := getFolderAsArr(this.pathBackup, "*project.json")
		cPresets := cVideos := cWeb := cScene := cApp := cMissing := cBroken := 0
		for i, e in configs {
			parent := PathGetSplit(e.dir).name
			wp := jsongo.Parse(fileread(e.path, "UTF-8"))
			if !wp.has("type") {
				if wp.has("dependency")
					print(Format("{}: [{}] Title '{}'", parent, "Preset", wp["title"])), cPresets++
				else
					print(Format("{}: [{}] Title '{}'", parent, "BROKEN", wp["title"])), cBroken++
				continue
			}
			switch wp["type"], 0 {
				case "scene":
					cScene++
					print(Format("{}: [{}] Title '{}'", parent, wp["type"], wp["title"]))
				case "video":
					cVideos++
					f := e.dir "\" wp["file"]
					if FileExist(f) {
						print(Format("{}: [{}] Title '{}'", parent, wp["type"], wp["title"]))
					} else {
						cMissing++
						print(parent ": DOES NOT EXIST: " wp["file"] " @ title: " wp["title"])
					}
				case "web":
					cWeb++
					print(Format("{}: [{}] Title '{}'", parent, wp["type"], wp["title"]))
				case "application":
					cApp++
					print(Format("{}: [{}] Title '{}'", parent, wp["type"], wp["title"]))
				default:
					cBroken++
					print(Format("{}: [{}] UNRECOGNIZED: Title '{}'", parent, wp["type"], wp["title"]))
			}
		}
		print("Total Wallpapers: " configs.Length)
		print("Total Scenes: " cScene)
		print("Total Applications: " cApp)
		print("Total Web: " cWeb)
		print("Total Presets: " cPresets)
		print("Total Broken: " cBroken)
		print("Total Videos: " cScene)
		print("Total Videos Missing: " cMissing)
	}

}

class wpEngineHelpers {
	
	static playWPEngineItemsFromFolderInVLC(folderName, tag?, sortedBy := "size") {
		files := wpEngine.getItemsFromFolder(folderName, tag?, sortedBy)
		this.playItemsInVLC(files)
	}

	static playItemsInVLC(fileArr, sleepTime := 100) {
		static cmd := 'C:\Program Files\VideoLAN\VLC\vlc.exe --started-from-file --playlist-enqueue "{}"'
		for e in fileArr {
			Sleep(100)
			Run(Format(cmd, e))
		}
	}
	
	static steamCMDGetUnsubscribedItems(str := A_Clipboard) {
		res := ""
		for i, e in strSplitOnNewLine(str) {
			if !InStr(e, "Item")
				continue
			if InStr(e, "subscribed")
				continue
			else {
				RegExMatch(e, ".*Item (\d+).*", &o)
				id := o[1]
				res .= id ","
			}
		}
		return res
	}

	static openLinksIfNotExist(idList := A_Clipboard) {
		list := strSplitOnNewLine(idList)
		for i, e in list {
			if (id := this.checkIfExist(e)) {
				Run(wpEngine.steamBaseUrl . e)
				Sleep(30000)
			}
		}
		MsgBoxAsGui("Opened " list.Length " Links")
	}

	static filterLinkList(str := A_Clipboard) {
		t := []
		for i, e in strsplit(str, ["`n", ","]) {
			if (id := this.checkIfExist(e)) {
				t.push(id)
			}
		}
		return objCollectString(t)
	}

	static checkIfExist(str := A_Clipboard, notifyOnOK := false) {
		static mapper := Map(1, "Workshop", 2, "Backup", 3, "Downloads")
		if !RegExMatch(str, "filedetails\/\?id=(\d+)", &o) && !RegExMatch(str, "^\s*(\d+)\s*$", &o)
			return 0
		if (i := objContainsMatch(wpEngine.allPaths, (k, v) => (DirExist(v "\" o[1])))) {
			MsgBoxAsGui(Format("[{}] ID already exists in {}", o[1], mapper[i]))
			return 0
		} else if notifyOnOK
			timedTooltip("Does not exist yet")
		return o[1]
	}
}
; NOTE: OPTION A: USE STEAM CONSOLE workshop_download_item 431960 ID
; NOTE: OPTION B:
/*
JS:
var id_array = [];
var appid = 431960;
id_array.forEach((id, index) => {
	setTimeout(() => {
		try {
			SendSubscribeItemRequest(id, 431960, false);
			console.log(`%c[${index + 1}/${id_array.length}] Sent subscription request for ID ${id}`, "color: #00ff00;");
		} catch (e) {
			console.log(`%c[${index + 1}/${id_array.length}] Failed to send subscription request for ID ${id}. Error:`, e);
		}
	}, index * 1500);
});
*/
; NOTE: OPTION C: EDIT appworkshop_431960.acf
; Also, see if there's stuff with manifest: -1 in there (legacy installed item fix)