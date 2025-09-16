/************************************************************************
 * @description A class to analyze and visualize dependencies or creating quickly compiling single-file scripts
 * @author cobracrystal
 * @date 2025/09/16
 * @version 1.0.0
 ***********************************************************************/


class Dependencies {
		
	/**
	 * Returns a string depicting the dependency structure for the given file
	 * @param path (Absolute) Path to the file to get dependencies of. Assumes that path == A_ScriptFullPath. This may work most of the time with relative paths, but wasnt tested extensively.
	 * @param relativePaths Causes all paths to be returned relative to the given path, if possible
	 * @param {Boolean} includeRedundantDependencies Whether to include dependencies that, if the script were to be compiled, would be ignored as they are already included by previous include statements. This only applies when considering the context of the main script given to this function, not in the context of its included scripts on their own. Redundant Dependencies are marked as duplicate while their dependencies are not shown.
	 * @returns {String} A string representing the dependency tree of the path.
	 */
	static prettyTree(path, relativePaths := true, includeRedundantDependencies := true, indent := '  ') {
		static _charT := '┣', _charL := '┗', _charI := '┃', char_ := '━'
		charT := _charT . RegExReplace(indent, '.', char_)
		charI := _charI . indent
		charL := _charL . RegExReplace(indent, '.', char_)
		deps := this.tree(path, relativePaths, includeRedundantDependencies)
		dummyObj := {_path: path, _state: '', dependencies: deps}
		return _beautifyStr(dummyObj, '')

		_beautifyStr(obj, indentStr) {
			str := obj._path . (obj._state ? ' (' obj._state ')' : '')
			nextIndentStr := indentStr . charI
			symbol := charT
			for i, o in obj.dependencies {
				if (i == obj.dependencies.Length) {
					nextIndentStr := indentStr . '   '
					symbol := charL
				}
				str .= '`n' . indentStr . symbol . _beautifyStr(o, nextIndentStr)
			}
			return str
		}
	}

	/**
	 * Returns a dependency structure for the given file
	 * @param path (Absolute) Path to the file to get dependencies of. Assumes that path == A_ScriptFullPath. This may work most of the time with relative paths, but wasnt tested extensively.
	 * @param relativePaths Causes all paths to be stored relative to the given path, if possible
	 * @param {Boolean} includeRedundantDependencies Whether to include dependencies that, if the script were to be compiled, would be ignored as they are already included by previous include statements. This only applies when considering the context of the main script given to this function, not in the context of its included scripts on their own.
	 * @returns {Array} An array of objects. Each entry is a dependency with the properties 
	 * _path: {String} <filepath>,
	 * dependencies: {Array} Array of dependency objects. May be empty
	 * _state: {String} An empty string or the words 'Again', 'Ignore', 'Duplicate Directive', 'Missing' or any combination of the four (in that order)
	 */
	static tree(path, relativePaths := true, includeRedundantDependencies := true) {
		local dependencies := Map()
		dependencies.CaseSense := false
		deps := _getDependencies(path, Map())
		if !relativePaths
			return deps
		SplitPath(path, , &dir)
		recursiveHelper(deps)
		return deps
		
		_getDependencies(currentPath, dependenciesInBranch, lastIncludeDirectory?) {
			currentDependencies := []
			RedundantDependencies := []
			localDependencies := Map()
			script := this.getUncommentedScript(FileRead(currentPath, "UTF-8"),, false)
			Loop Parse, script, '`n', '`r' {
				if (RegexMatch(A_LoopField, "^\s*#Include")) {
					include := this.getIncludePath(A_LoopField, currentPath, path, lastIncludeDirectory?)
					state := include.includeAgain ? 'Again, ' : ''
					state .= include.ignoreErrors ? 'Ignore, ' : ''
					if !FileExist(include.path) {
						localDependencies[include.path] := true
						if localDependencies.Has(include.path) && !include.includeAgain
							state .= 'Duplicate Directive, '
						currentDependencies.push({_path: include.path, _state: state . 'Missing', dependencies: []})
					}
					else if InStr(FileGetAttrib(include.path), 'D')
						lastIncludeDirectory := include.path
					else if (include.path) {
						if localDependencies.Has(include.path) && !include.includeAgain
							currentDependencies.push({_path: include.path, _state: state . 'Duplicate Directive', dependencies: []})
						else if (!dependenciesInBranch.Has(include.path) || include.includeAgain) {
							localDependencies[include.path] := true
							encDep := includeRedundantDependencies ? dependenciesInBranch.clone() : dependenciesInBranch
							encDep[include.path] := true
							currentDependencies.push({_path: include.path, _state: RTrim(state, ', '), dependencies: _getDependencies(include.path, encDep, lastIncludeDirectory?)})
						} else {
							currentDependencies.push({_path: include.path, _state: state . 'Redundant', dependencies: []})
						}
					}
				}
			}
			return currentDependencies
		}

		recursiveHelper(m) {
			if !IsObject(m)
				return
			for v in m {
				v._path := StrReplace(v._path, dir '\')
				recursiveHelper(v.dependencies)
			}
		}

	}

	/**
	 * Returns a flat Array of all paths recursively included in the given path. Assumes that path == A_ScriptFullPath
	 * @param path (Absolute) Path to the file to get dependencies of. Assumes that path == A_ScriptFullPath. This may work most of the time with relative paths, but wasnt tested extensively.
	 * @param relativePaths Causes all paths to be stored relative to the given path, if possible
	 * @returns {Array} Array of all included files in the order that they were encountered
	 */
	static asArray(path, relativePaths := false) {
		local includes := Map()
		includesArr := []
		includes.CaseSense := false
		SplitPath(path, , &dir)
		_getIncludes(path, dir)
		if relativePaths
			for i, e in includesArr
				includesArr[i] := StrReplace(e, dir '\')
		return includesArr
		
		_getIncludes(currentPath, lastIncludeDirectory) {
			includes[currentPath] := true
			script := FileExist(currentPath) ? this.getUncommentedScript(FileRead(currentPath, "UTF-8"),, false) : ''
			Loop Parse, script, '`n', '`r' {
				if (RegexMatch(A_LoopField, "^\s*#Include")) {
					include := this.getIncludePath(A_LoopField, currentPath, path, lastIncludeDirectory)
					if !FileExist(include.path) {
						if !include.ignoreErrors
							throw OSError("Specified File does not exist:" include.path)
					} else {
						if InStr(FileGetAttrib(include.path), 'D') {
							lastIncludeDirectory := include.path
							continue
						}
					}
					if (include.path && (!includes.Has(include.path) || include.includeAgain)) {
						includes[include.path] := true
						includesArr.push(include.path)
						_getIncludes(include.path, lastIncludeDirectory)
					}
				}
			}
			return includes
		}
	}

	/**
	 * @description Generates a standalone script without #include directives from a given path. Assumes that path == A_ScriptFullPath. There is no guarantee that the generated script will work as there may be references to A_LineFile or similar relative paths in other locations of the script.
	 * @param path (Absolute) Path to the file to get dependencies of. Assumes that path == A_ScriptFullPath, affecting %A_ScriptDir% and %A_ScriptFullPath%. This may work most of the time with relative paths, but wasnt tested extensively.
	 * @param commentIncludes If this is set to true, adds a comment of the form [; REPLACED: #Include [relative path]] above the replacement for every #include directive
	 * @returns {String} The script located in path as if it were compiled by replacing #include directives with the script located at their specified file.
	 */
	static getFullScript(path, commentIncludes := false) {
		local includes := Map()
		includes.CaseSense := false
		SplitPath(path, , &dir)
		return _getFullScript(path, dir)
		
		_getFullScript(currentPath, lastIncludeDirectory) {
			includes[currentPath] := true
			fullScript := FileExist(currentPath) ? FileRead(currentPath, "UTF-8") : ""
			fullScriptArr := StrSplit(fullScript, '`n', '`r')
			cleanScript := StrSplit(this.getUncommentedScript(fullScript,, true), '`n', '`r')
			fullScript := ""
			for i, line in cleanScript {
				if (RegexMatch(line, "^\s*#Include")) {
					include := this.getIncludePath(line, currentPath, path, lastIncludeDirectory)
					if !FileExist(include.path) {
						if !include.ignoreErrors
							throw OSError("Specified File does not exist:" include.path)
					} else {
						if InStr(FileGetAttrib(include.path), 'D') {
							lastIncludeDirectory := include.path
							continue
						}
					}
					if (include.path && (!includes.Has(include.path) || include.includeAgain)) {
						includes[include.path] := true
						if commentIncludes
							fullScript .= '; REPLACED: #Include "' StrReplace(include.path, dir '\') '"`n'
						fullScript .= _getFullScript(include.path, lastIncludeDirectory) '`n'
					}
				} else
					fullScript .= fullScriptArr[i] (i < fullScriptArr.Length ? '`n' : '')
			}
			return fullScript
		}
	}

	/**
	 * Given a text, returns the text content without comments (/* comment */) and optionally single-line comments
	 * @param {String} text A String representing an autohotkey script or similar text
	 * @param {Boolean} removeSemicolonComments Normally, this function only removes multiline (/* comment */) comments. Set this to true to also remove single-line comments ( ; comment)
	 * @param {Boolean} keepLineNumbersAccurate Whether to omit comments fully or replace them with a newline. This only applies to multiline comments.
	 * @returns {String} The text without multi- or single-line comments
	 */
	static getUncommentedScript(text, removeSemicolonComments := false, keepLineNumbersAccurate := true) {
		cleanScript := ""
		flagComment := 0
		Loop Parse, text, "`n", "`r" {
			if (flagComment) {
				if (RegexMatch(A_LoopField, "\*\/\s*$"))
					flagComment := false
				if keepLineNumbersAccurate
					cleanScript .= "`n"
				continue
			} 
			if (RegExMatch(A_LoopField, "^\s*\/\*")) { ; /* comments MUST be at start of line, so this is valid
				if (!RegexMatch(A_LoopField, "^\s*\/*.*\*\/\h*$")) ; these lines are ENTIRELY comments regardless. /* */ [text] is the same as ; [text]
					flagComment := true
				if keepLineNumbersAccurate
					cleanScript .= "`n"
				continue
			}
			if removeSemicolonComments && InStr(A_LoopField, ";") {
				if keepLineNumbersAccurate
					cleanScript .= RegExReplace(A_LoopField, "(^\s*|\s+);.*", "$1") . '`n'
				else {
					line := RegExReplace(A_LoopField, "(^\s*|\s+);.*", "")
					if line
						cleanScript .= line . '`n'
				}
			}
			else
				cleanScript .= A_LoopField . '`n'
		}
		return SubStr(cleanScript, 1, -1)
		; return RegExReplace(script, "ms`a)(?:^\s*\/\*.*?\*\/\s*\v|^\s*\/\*(?!.*\*\/\s*\v).*)") ; works but is unreadable
	}

	/**
	 * Gets path of an included file
	 * @description Given a line potentially containing an autohotkey #Include directive, creates a path leading to the file specified by the directive.
	 * @param line The line to parse
	 * @param {String} scriptFile Path to the script specified by A_LineFile. Should be absolute or cover all backtracking in the include directive
	 * @param {String} originalScript The script specified by A_ScriptFullPath. Defaults to scriptFile (ie assuming that the supplied script file is the 'main' script file). Should be absolute or cover all backtracking in the include directive
	 * @param {String} withWorkingDir A potentially set working directory (that was formerly specified via #Include directory). Should be absolute.
	 * @returns {Object} An Object of the form { path: path, ignoreErrors: 1 | 0, includeAgain: 1 | 0}
	 */
	static getIncludePath(line, scriptFile, originalScript := scriptFile, withWorkingDir?) {
		static AHK_VARS := ["A_AhkPath", "A_AppData", "A_AppDataCommon", "A_ComputerName", "A_ComSpec", "A_Desktop", "A_DesktopCommon", "A_IsCompiled", "A_MyDocuments", "A_ProgramFiles", "A_Programs", "A_ProgramsCommon", "A_Space", "A_StartMenu", "A_StartMenuCommon", "A_Startup", "A_StartupCommon", "A_Tab", "A_Temp", "A_UserName", "A_WinDir"]
		if !RegexMatch(line, '^\s*#Include(?<again>(?:Again)?)\s+(?<quot>(?:"|`')?)(?<ignore>(?:\*i)?)\s*(?<path>.*)(?P=quot)', &m)
			return ''
		path := m["path"]
		SplitPath(originalScript, &name, &dir)
		SplitPath(scriptFile, , &scriptDir)
		if SubStr(path, 1, 1) == '<' && SubStr(path, -1, 1) == '>' { ; is library inclusion
			if m['ignore'] ; library file errors cannot be ignored
				return ''
			fname := SubStr(path, 2, -1)
			path := checkLibs(fname)
			if !path && (pos := InStr(path, '_'))
				path := checkLibs(SubStr(fname, 1, pos - 1))
		} else { ; is actual path
			for e in AHK_VARS
				path := StrReplace(path, "%" e "%", %e%)
			path := StrReplace(path, '%A_ScriptDir%', dir)
			path := StrReplace(path, '%A_ScriptFullPath%', originalScript)
			path := StrReplace(path, '%A_ScriptName%', name)
			path := StrReplace(path, '%A_LineFile%', scriptFile)
			path := StrReplace(path, "``;", ";")
			if (!RegexMatch(path, "i)^[a-z]:\\") && RegexMatch(scriptFile, "i)^[a-z]:\\")) ; path is relative, but we have an absolute path supplied. If supplied path is relative too, ignore.
				path := (withWorkingDir ?? scriptDir) . (SubStr(path, 1, 1) == "\" ? "" : "\") . path
		}
		return { path: this.normalizePath(path), ignoreErrors: m["ignore"] ? 1 : 0, includeAgain: m["again"] ? 1 : 0 }

		checkLibs(fName) {
			static ahkExeDir := 0
			if !ahkExeDir
				SplitPath(A_AhkPath,, &ahkExeDir)
			if FileExist(dir . '\Lib\' . fName . '.ahk')
				path := dir . '\Lib\' . fName . '.ahk'
			else if FileExist(A_MyDocuments . '\AutoHotkey\Lib\' . fName . '.ahk')
				path := A_MyDocuments . '\AutoHotkey\Lib\' . fName . '.ahk'
			else if FileExist(ahkExeDir . '\Lib\' . fName . '.ahk')
				path := ahkExeDir . '\Lib\' . fName . '.ahk'
			return path ?? ''
		}
	}

	/**
	 * Given a path, removes any backtracking of paths through \..\ to create a unique absolute path.
	 * @param absolutePath The absolute path to normalize. While a relative path may be given, there is no guarantee it can be resolved (eg \folder\..\..\otherstuff\file.txt will backtrack outside of the scope of the path)
	 * @returns {String} A normalized Path (if valid) or an empty string if the path could not be resolved.
	 */
	static normalizePath(path) {
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

}
