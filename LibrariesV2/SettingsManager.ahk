#Include "%A_LineFile%\..\..\LibrariesV2\ObjectUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\FileUtilities.ahk"
#Include "%A_LineFile%\..\..\LibrariesV2\External\jsongo.ahk"

class SettingsManager {
	static defaultSettingsFile := "default_settings.json"
	static settingsFile := "settings.json"

	__New(savePath := A_AppData "\Autohotkey\" A_ScriptName, defaultSettings := {}) {
		if SubStr(savePath, -4) == ".ahk"
			savePath := SubStr(savePath, 1, -4)
		this.savePath := normalizePath(savePath)
		if (!Instr(FileExist(this.savePath), "D"))
			DirCreate(this.savePath)
		this._defaultSettings := objClone(defaultSettings)
		this.settings := objClone(defaultSettings)
		this.storeDefaultSettings()
	}

	setDefault(defaultSettings) {
		this.defaultSettings := objClone(defaultSettings)
		this.storeDefaultSettings()
	}

	defaultSettings => objClone(this._defaultSettings)

	storeDefaultSettings() {
		filePath := this.savePath "\" SettingsManager.defaultSettingsFile
		try {
			f := FileOpen(filePath, "rwd", "UTF-8")
			f.Write(jsongo.Stringify(this.defaultSettings))
			f.Close()
			return 1 
		} catch as e {
			return 0
		}
	}

	saveSettings() {
		filePath := this.savePath "\" SettingsManager.settingsFile
		if (!Instr(FileExist(this.savePath), "D"))
			DirCreate(this.savePath)
		try {
			f := FileOpen(filePath, "rwd", "UTF-8")
			f.Write(jsongo.Stringify(this.settings))
			f.Close()
			return 1 
		} catch as e {
			return 0
		}
	}

	loadSettings(overwriteCurrentSettings := true, setDefaultSettings := true, removeUndefinedSettings := true) {
		filePath := this.savePath "\" SettingsManager.settingsFile
		settings := {}
		if (FileExist(filePath))
			try settings := jsongo.Parse(FileRead(filePath, "UTF-8"))
		; the default Settings (sub)types dictates all object types.
		settings := objSyncObjectTypes(this.defaultSettings, settings)
		if (overwriteCurrentSettings) { ; keep everything in settings, only add things defined in this.settings which are not defined in the file. May occur on outdated settings files.
			SettingsManager._mergeSettings(settings, this.settings)
			this.settings := settings
		} else { ; only populate settings not defined in current settings (this usually shouldn't occur)
			SettingsManager._mergeSettings(this.settings, settings)
		}
		if (setDefaultSettings) {
			; populate nonexisting settings with default values
			SettingsManager._mergeSettings(this.settings, this.defaultSettings) ; NOT _defaultSettings, as otherwise we will edit them later
		}
		if removeUndefinedSettings
			this.purgeUndefinedSettings()
		return this.settings
	}

	purgeUndefinedSettings() {
		if this._defaultSettings is Map
			return _purgeUndefinedSettingsMap()
		return _purgeUndefinedSettingsObj()

		_purgeUndefinedSettingsMap() {
			for i, e in this.settings
				if !(this._defaultSettings.Has(i))
					this.settings.Delete(i)
		}

		_purgeUndefinedSettingsObj() {
			for i, e in this.settings.OwnProps()
				if !(this._defaultSettings.HasOwnProp(i))
					this.settings.DeleteProp(i)
		}
	}

	static _mergeSettings(mainSettings, toMergeSettings) {
		if Type(mainSettings) == "Map"
			return _mergeMapSettings(mainSettings, toMergeSettings)
		if Type(mainSettings) == "Object"
			return _mergeObjectSettings(mainSettings, toMergeSettings)
		return mainSettings

		_mergeMapSettings(mainSettings, toMergeSettings) {
			for i, e in toMergeSettings {
				if !mainSettings.Has(i)
					mainSettings.Set(i, e)
				else
					mainSettings.Set(i, SettingsManager._mergeSettings(mainSettings[i], e))
			}
			return mainSettings
		}

		_mergeObjectSettings(mainSettings, toMergeSettings) {
			for i, e in toMergeSettings.OwnProps() {
				if !mainSettings.HasOwnProp(i)
					mainSettings.%i% := e
				else
					mainSettings.%i% := SettingsManager._mergeSettings(mainSettings.%i%, e)
			}
			return mainSettings
		}
	}
}