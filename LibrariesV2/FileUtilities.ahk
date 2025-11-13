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

getFilesAsArr(filePattern := "*", mode := 'FDR', getMode := 3, sortedBy := "name", disableSorting := false) {
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
	if disableSorting
		return files
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
	if !InStr(folder1, ":") || !InStr(folder2, ":")
		throw(Error("Must be absolute paths"))
	folder1 := RTrim(folder1, "\/")
	folder2 := RTrim(folder2, "\/")
	loop files folder1 "\*", "R" {
		relPath := StrReplace(A_LoopFilePath, folder1)
		fSize := A_LoopFileSize
		if (FileExist(folder2 . relPath) && fSize == FileGetSize(folder2 .1 relPath)) {
			FileDelete(folder2 . relPath)
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
compareFolders(folder1, folder2, recursive := true) {
	arr := []
	if !InStr(folder1, ":") || !InStr(folder2, ":")
		throw(Error("Must be absolute paths"))
	folder1 := RTrim(folder1, "\/")
	folder2 := RTrim(folder2, "\/")
	files1 := getFolderAsArr(folder1,, recursive ? 'FDR' : 'FD',0)
	for i, fl in files1 {
		relPath := StrReplace(fl.path, folder1)
		if InStr(fl.attrib, "D") {
			if DirExist(folder2 . relPath)
				continue
		} else {
			if (FileExist(folder2 . relPath) && fl.size == FileGetSize(folder2 . relPath))
				continue
		}
		arr.push(fl)
	}
	return arr
}

/**
 * Compares folder1 and folder2. If an item is present in folder1, but not present in folder2 (or its size is different), it is deleted. No other actions are taken.
 * @param folder1 
 * @param folder2 
 * @param deleteFolders whether to delete folders, default true
 * @returns {Integer} Count of items deleted
 */
syncDeletesToLeftFolder(folder1, folder2, deleteFolders := true) {
	count := 0
	if !InStr(folder1, ":") || !InStr(folder2, ":")
		throw(Error("Must be absolute paths"))
	folder1 := RTrim(folder1, "\/")
	folder2 := RTrim(folder2, "\/")
	loop files folder1 "\*", "R" {
		relPath := StrReplace(A_LoopFilePath, folder1)
		fSize := A_LoopFileSize
		if (FileExist(folder2 . relPath) && fSize == FileGetSize(folder2 . relPath))
			continue
		FileDelete(folder1 . relPath)
		count++
	}
	if !deleteFolders
		return count
	loop files folder1 "\*", "DR" {
		relPath := StrReplace(A_LoopFilePath, folder1)
		if FileExist(folder2 . relPath)
			continue
		try {
			DirDelete(folder1 . relPath, 1)
		} catch as e
			continue
		count++
	}
	return count
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
 * Given a path, removes any backtracking of paths through \..\ to create a unique absolute path.
 * @param path The absolute path to normalize. While a relative path may be given, there is no guarantee it can be resolved (eg \folder\..\..\otherstuff\file.txt will backtrack outside of the scope of the path)
 * @returns {String} A normalized Path (if valid) or an empty string if the path could not be resolved.
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
			if i > 2 ; drive is unaffected by \..\
				pathArr.RemoveAt(--i)
		}
	}
	nPath := ''
	for i, e in pathArr
		nPath .= e . (i == pathArr.Length ? '' : '\')
	return nPath
}
