#Include "%A_LineFile%\..\..\LibrariesV2\ObjectUtilities.ahk"
/**
 * Gets Specified Files in a folder as an array of filenames (if short) or array of objects with all their associated data
 * @param folder Path to a folder
 * @param {String} filePattern Filepattern to filter for. By default all files are included
 * @param {String} mode F,D,R (Include Files, Include Directories, Recursive.) Defaults to Files no folders no recursive
 * @param {Integer} getMode 0 = all fileinfo, 1 = only name, 2 = only full path, 3 = name, ext, namenoext, size, dir
 * @returns {Array} Array containing objects of the following type:
 * 
 * obj := { name, nameNoExt, ext, path, shortPath shortName dir, attrib, size, sizeKB, sizeMB, timeModified, timeCreated, timeAccessed }
 */
getFolderAsArr(folder, filePattern := "*", mode := 'FDR', getMode := 3, sortedBy := "name") => getFilesAsArr(folder "\" filePattern, mode, getMode, sortedBy)

getFilesAsArr(filePattern := "*", mode := 'FDR', getMode := 3, sortedBy := "name") {
	files := []
	loop files filePattern, mode {
		switch getMode {
			case 0:
				SplitPath(A_LoopFileFullPath,,,, &nameNoExt)
				files.push({
					name:			A_LoopFileName,
					nameNoExt:		nameNoExt,
					ext:			A_LoopFileExt,
					path:			A_LoopFileFullPath,
					shortPath:		A_LoopFileShortPath,
					shortName:		A_LoopFileShortName,
					dir:			A_LoopFileDir,
					attrib:			A_LoopFileAttrib,
					size:			A_LoopFileSize,
					sizeKB:			A_LoopFileSizeKB,
					sizeMB:			A_LoopFileSizeMB,
					timeModified:	A_LoopFileTimeModified,
					timeCreated:	A_LoopFileTimeCreated,
					timeAccessed:	A_LoopFileTimeAccessed
				})
			case 1:
				files.push(A_LoopFileName)
			case 2:
				files.push(A_LoopFileFullPath)
			case 3:
				SplitPath(A_LoopFileFullPath,,,, &nameNoExt)
				files.push({
					name: A_LoopFileName,
					dir: A_LoopFileDir,
					ext: A_LoopFileExt,
					nameNoExt: nameNoExt,
					size: A_LoopFileSize,
				})
		}
	}
	sorted := arraySort(files, getMode == 1 || getMode == 2 ? unset : a => a.%sortedBy%)
	return sorted
}

getFileInfo(filePath, getMode := 0) {
	path := filePath,
	size := FileGetSize(filePath)
	sizeKB := FileGetSize(filePath, "K")
	sizeMB := FileGetSize(filePath, "M")
	timeCreated := FileGetTime(filePath, 'C')
	timeModified := FileGetTime(filePath, 'M')
	timeAccessed := FileGetTime(filePath, 'A')
	attrib := FileGetAttrib(filePath)
	SplitPath(filePath, &name, &dir, &ext, &nameNoExt)
	if getMode == 0
		return {
			name:			name,
			nameNoExt:		nameNoExt,
			ext:			ext,
			path:			path,
			dir:			dir,
			attrib:			attrib,
			size:			size,
			sizeKB:			sizeKB,
			sizeMB:			sizeMB,
			timeModified:	timeModified,
			timeCreated:	timeCreated,
			timeAccessed:	timeAccessed
		}
	else
		return {
			name: A_LoopFileName,
			dir: A_LoopFileDir,
			ext: A_LoopFileExt,
			nameNoExt: nameNoExt,
			size: A_LoopFileSize,
		}
}

removeDupes(folder1, folder2) {
	count := 0
	loop files folder1 "\*", "R" {
		fName := A_LoopFileName
		fSize := A_LoopFileSize
		if (FileExist(folder2 "\" fName) && fSize == FileGetSize(folder2 "\" fName)) {
			FileDelete(folder2 "\" fName)
			count++
		}
	}
	return count
}

getFileDupes(recursive := true, caseSense := false, bySize := false, byName := true, byExt := true, grouped := true, folders*) {
	fileList := []
	mode := recursive ? 'FDR' : 'FD'
	for folder in folders
		fileList.push(getFolderAsArr(folder, , mode , 3)*)
	switch {
		case bySize && byName && byExt:
			fn := (a => (a.size "|" a.name))
		case bySize && byName && !byExt:
			fn := (a => (a.size "|" a.nameNoExt))
		case bySize && !byName && byExt:
			fn := (a => (a.size . "|" a.ext))
		case bySize && !byName && !byExt:
			fn := (a => (a.size))
		case !bySize && byName && byExt:
			fn := (a => (a.name))
		case !bySize && byName && !byExt:
			fn := (a => (a.nameNoExt))
		case !bySize && !byName && byExt:
			fn := (a => (a.ext))
		case !bySize && !byName && !byExt:
			throw(ValueError("You must compare by something"))
	}
	indices := objGetDuplicates(fileList, fn, caseSense, grouped)
	dupes := []
	for e in indices {
		if grouped
			for f in e
				dupes.push(fileList[f])
		else
			dupes.push(fileList[e])
	}
	return dupes
}

getMetadataFolder(folder, metadata := []) {
	data := []
	loop files folder . "\*", '' {
		fileData := FGP.List(A_LoopFileFullPath)
		fObj := Map()
		for e in metadata
			if fileData.has(e)
				fObj[e] := fileData[e]
		fObj["filename"] := A_LoopFileName
		data.push(fObj)
	}
	return data
}

strContainsIllegalChar(str) {
	static charMap := Map("\", "-", "/", "⧸", ":", "", "*", "＊", "?", ".", '"', "'", "<", "(", ">", ")", "|", "-")
	for i, e in charMap
		if InStr(str, i)
			return 1
	return 0
}

strReplaceIllegalChars(str, &replaceCount) {
	static charMap := Map("\", "-", "/", "⧸", ":", "", "*", "＊", "?", ".", '"', "'", "<", "(", ">", ")", "|", "-")
	total := 0
	for i, e in charMap {
		str := StrReplace(str, i, e,, &count)
		total += count
	}
	replaceCount := total
	return str
}

/**
 * Compares items in folders. optionally recursive. returns items present in folder 1 that are not present in folder 2
 * @param folder1 
 * @param folder2 
 * @returns {Map} 
 */
compareFolders(folder1, folder2, recursive := false) {
	f1exists := Map()
	changes := Map()
	loop files folder1 "\*", recursive ? 'FDR' : 'FD' {
		if !FileExist(folder2 "\" A_LoopFilename)
			changes[A_LoopFileName] := true
	}
	return changes
}

class FGP {

	static PropTable {
		get {
			if !this.HasOwnProp("_Proptable")
				this._Proptable := this.Init()
			return this._Proptable
		}
	}

	/*  FGP_Init()
	*		Gets an object containing all of the property numbers that have corresponding names.
	*		Used to initialize the other functions.
	*	Returns
	*		An object with the following format:
	*			PropTable.Name["PropName"]	:= PropNum
	*			PropTable.Num[PropNum]		:= "PropName"
	*/
	static Init() {
		if (!IsSet(PropTable)) {
			;PropTable := {Name:={},Num:={} }
			;PropTable := {{},{}}
			PropTable := { Name: Map(), Num: Map() }
			Gap := 0
			oShell := ComObject("Shell.Application")
			oFolder := oShell.NameSpace(0)
			while (Gap < 11) {
				if (PropName := oFolder.GetDetailsOf(0, A_Index - 1)) {
					PropTable.Name[PropName] := A_Index - 1
					PropTable.Num[A_Index - 1] := PropName
					;PropTable.Num.InsertAt( A_Index - 1 , PropName )
					Gap := 0
				}
				else {
					Gap++
				}
			}
		}
		return PropTable
	}


	/*  FGP_List(FilePath)
	*		Gets all of a file's non-blank properties.
	*	Parameters
	*		FilePath	- The full path of a file.
	*	Returns
	*		An object with the following format:
	*			PropList.CSV				:= "PropNum,PropName,PropVal`r`n..."
	*			PropList.Name["PropName"]	:= PropVal
	*			PropList.Num[PropNum]		:= PropVal
	*/
	static List(FilePath, asNums := false) {
		SplitPath(FilePath, &FileName, &DirPath)
		oShell := ComObject("Shell.Application")
		oFolder := oShell.NameSpace(DirPath)
		oFolderItem := oFolder.ParseName(FileName)
		PropList := Map()
		for PropNum, PropName in this.PropTable.Num
			if (PropVal := oFolder.GetDetailsOf(oFolderItem, PropNum))
				PropList[asNums ? PropNum : PropName] := PropVal
		return PropList
	}


	/*  FGP_Name(PropNum)
	*		Gets a property name based on the property number.
	*	Parameters
	*		PropNum		- The property number.
	*	Returns
	*		If succesful the file property name is returned. Otherwise:
	*		-1			- The property number does not have an associated name.
	*/
	static Name(PropNum) {
		if (this.PropTable.Num[PropNum] != "")
			return this.PropTable.Num[PropNum]
		return -1
	}


	/*  FGP_Num(PropName)
	*		Gets a property number based on the property name.
	*	Parameters
	*		PropName	- The property name.
	*	Returns
	*		If succesful the file property number is returned. Otherwise:
	*		-1			- The property name does not have an associated number.
	*/
	static Num(PropName) {
		if (this.PropTable.Name[PropName] != "")
			return this.PropTable.Name[PropName]
		return -1
	}


	/*  FGP_Value(FilePath, Property)
	*		Gets a file property value.
	*	Parameters
	*		FilePath	- The full path of a file.
	*		Property	- Either the name or number of a property.
	*	Returns
	*		If succesful the file property value is returned. Otherwise:
	*		0			- The property is blank.
	*		-1			- The property name or number is not valid.
	*/
	static Value(FilePath, Property) {
		if ((PropNum := this.PropTable.Name.Has(Property) ? this.PropTable.Name[Property] : this.PropTable.Num[Property] ? Property : "") != "") {
			SplitPath(FilePath, &FileName, &DirPath)
			oShell := ComObject("Shell.Application")
			oFolder := oShell.NameSpace(DirPath)
			oFolderItem := oFolder.ParseName(FileName)
			if (PropVal := oFolder.GetDetailsOf(oFolderItem, PropNum))
				return PropVal
			return 0
		}
		return -1
	}
}

/**
 * Get full script of a .ahk script (With all #include files being physically replaced with their content in the script)
 * @param path 
 * @returns {Any} 
 */
getFullScript(path) {
	pathList := Map()
	pathList.CaseSense := false
	return objCollect(_getFullScript(path), (b,e) => b "`n" e)
	
	_getFullScript(path) {
		pathList[path] := true
		script := FileRead(path, "UTF-8")
		fullScript := []
		pos := 0
		arr := StrSplit(script, "`n", "`r")
		for i, line in arr {
			if (RegexMatch(line, "^\s*#Include")) {
				includedPath := getIncludePath(line, path) ; keep track of include working directory. THIS IS PER FILE.)
				if (includedPath && !pathList.Has(includedPath)) {
					fullScript.push(_getFullScript(includedPath)*)
				}
			} else {
				fullScript.push(line)
			}
		}
		return fullScript
	}
}

getIncludePath(line, from := A_ScriptFullPath) {
	static currentWorkingDirectory := A_ScriptDir
	RegexMatch(line, '^\s*#Include (?<quot>"?|`'?)(?<ignore>(?:\*i)?\s*)(?<path>.*)(?P=quot)', &m)
	path := m["path"]
	for i, e in ["A_AhkPath", "A_AppData", "A_AppDataCommon", "A_ComputerName", "A_ComSpec", "A_Desktop", "A_DesktopCommon", "A_IsCompiled", "A_MyDocuments", "A_ProgramFiles", "A_Programs", "A_ProgramsCommon", "A_ScriptDir", "A_ScriptFullPath", "A_ScriptName", "A_Space", "A_StartMenu", "A_StartMenuCommon", "A_Startup", "A_StartupCommon", "A_Tab", "A_Temp", "A_UserName", "A_WinDir"]
		path := StrReplace(path, "%" e "%", %e%)
	path := StrReplace(path, "%A_LineFile%", from)
	path := StrReplace(path, "``;", ";")
	if (!RegexMatch(path, "i)^[a-z]:\\"))
		path := currentWorkingDirectory . (SubStr(path, 1, 1) == "\" ? "" : "\") . path
	path := normalizePath(path)
	if (InStr(FileGetAttrib(path), "D")) {
		currentWorkingDirectory := (SubStr(path, -1) == "\" ? SubStr(path, 1, -1) : path)
		return ""
	}
	return path
}

/**
 * Given a path, removes any backtracking of paths through \..\ to create a unique absolute path.
 * @param path Path to normalize
 * @returns {string} A normalized Path (if valid) or an empty string if the path could not be resolved.
 */
normalizePath(path) {
	path := StrReplace(path, "\\", "\")
	path := StrReplace(path, "/", "\")
	while InStr(path, "\.\") ; \.\ does nothing since . is current file
		path := StrReplace(path, "\.\", "\")
	if (SubStr(path, -2) == "\.")
		path := SubStr(path, 1, -2)
	path := Trim(path, " `t\")
	pathArr := StrSplit(path, "\")
	i := 1
	while(i <= pathArr.Length) {
		if (pathArr[i] != "..")
			i++
		else {
			patharr.RemoveAt(i)
			if i > 2 ; pathArr[1] is the drive. C:\..\Users\..\..\Users => C:\Users
				pathArr.RemoveAt(--i)
		}
	}
	return objCollect(pathArr, (b, e) => b "\" e)
}
