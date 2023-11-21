#Include %A_ScriptDir%\Libraries\JSON.ahk








; ADD ALL THE MATH FONTS (AT BOTTOM OF LATEXHOTSTRINGS JSON) TO TEXTEDITMENU, ITS WAY BETTER THAT WAY









HotstringLoader.initialize()

class HotstringLoader {
	static onOffStatus := 0
	static hotstrings := {}
	static defaultSet := ""
	hotstringHandler(modeItemName := 0, itemPosUNUSED := 0, menuNameUNUSED := 0) {
		if (SubStr(modeItemName, 1, 1) == "E")
			mode := !this.onOffStatus
		if (SubStr(mode, 1, 1) == "T")
			mode := !this.onOffStatus
		if (mode == 1) {
		
		}
		else if (mode == 0) {
		
		}
		return
	}
	
	initialize() {
		tObj := this.hotstringHandler.Bind(this)
		Menu, Tray, Add, Enable Latex Hotstrings, % tObj
		Menu, Tray, NoStandard
		Menu, Tray, Standard
		
		this.initialized := true
	}
	
	load(filePath, name := "", register := 1, setDefault := 1, encoding := "UTF-8") {
		fileObj := FileOpen(filePath, "r", encoding)
		jsonStr := fileObj.Read()
		hotstringObj := JSON.Load(jsonStr)
		if (name == "") {
			name := this.hotstrings.Count() + 1
		}
		this.hotstrings[name] := hotstringObj
		if (register) {
			this.registerHotstrings(name)
			this.defaultSet := name
		}
		return name
	}
	
	registerAll() {
		for i, e in this.hotstrings
			this.registerHotstrings(i)
	}
	
	registerHotstrings(name) {
		obj := this.hotstrings[name]
		for i, e in obj
			this.callHotstring(e.string, e.options, e.replacement, 1)
	}
	
	callHotstring(hotstring, options := "", replacement := "", onofftoggle := "") {
		try
			HotString(":" . options . ":" . hotstring, replacement, onofftoggle)
		catch
			throw new Exception("Hotstring function failed:`nHotString(" . hotstring . ", " . replacement . ", " . OnOffToggle . ")")
	}
}

LatexHotstrings(OnOffToggle := -1) {
	static trayInit := 0
	if (!trayInit) {
		Menu, Tray, Add, Enable LaTeX Hotstrings, LatexHotstrings
		Menu, Tray, NoStandard
		Menu, Tray, Standard
		trayInit := 1
	}
	if (OnOffToggle = "Enable LaTeX Hotstrings") ;// menu identifier is given to function upon clicking menu.
		OnOffToggle := -1
	Menu, Tray, ToggleCheck, Enable LaTeX Hotstrings
	Hotkey, IfWinNotActive, Online LaTeX Editor Overleaf - Mozilla Firefox ahk_exe firefox.exe
	HotString(":o?:\infty","∞", OnOffToggle)
	HotString(":o?:\sqrt","√", OnOffToggle)
	HotString(":o?:\leftrightarrow","↔", OnOffToggle)
	HotString(":o?:\leftarrow","←", OnOffToggle)
	HotString(":o?:\rightarrow","→", OnOffToggle)
	HotString(":o?:\uparrow","↑", OnOffToggle)
	HotString(":o?:\downarrow","↓", OnOffToggle)
	HotString(":o?:\plusminus","±", OnOffToggle)
	HotString(":o?:\times","×", OnOffToggle)
	HotString(":o?:\divide","÷", OnOffToggle)
	HotString(":o?:\emptyset","ø", OnOffToggle)
	HotString(":o?:\neq","≠", OnOffToggle)
	HotString(":o?:\leq","≤", OnOffToggle)
	HotString(":o?:\geq","≥", OnOffToggle)
	HotString(":o?:\approx","≈", OnOffToggle)
	HotString(":o?:\identity","≡", OnOffToggle)
	HotString(":o?:\cong","≅", OnOffToggle)
	HotString(":o?:\sum","∑", OnOffToggle)
	HotString(":o?:\prod","∏", OnOffToggle)
	HotString(":o?:\int","∫", OnOffToggle)
	HotString(":o?:\vert","⊥", OnOffToggle)
	HotString(":o?:\in","∈", OnOffToggle)
	HotString(":o?:\notin","∉", OnOffToggle)
	HotString(":o?:\block","█", OnOffToggle)
	HotString(":o?:\square","▢", OnOffToggle)
	HotString(":o?:\rectangle","□", OnOffToggle)
	HotString(":o?:\checkmark","▣", OnOffToggle)
	HotString(":o?:\exists","∃", OnOffToggle)
	HotString(":o?:\forall","∀", OnOffToggle)
	HotString(":o?:\cap","∩", OnOffToggle)
	HotString(":o?:\cup","∪", OnOffToggle)
	HotString(":o?:\vee","∨", OnOffToggle)
	HotString(":o?:\wedge","∧", OnOffToggle)
	HotString(":o?:\neg","¬", OnOffToggle)
	HotString(":o?:\notin","∉", OnOffToggle)
	HotString(":o?:\cdot","·", OnOffToggle)
	HotString(":o?:\proportional","∝", OnOffToggle)
	HotString(":o?:\longdash","–", OnOffToggle)
	
		; // GREEK LETTERS
	HotString(":o?:\alpha","α", OnOffToggle)
	HotString(":o?:\beta","β", OnOffToggle)
	HotString(":o?:\gamma","γ", OnOffToggle)
	HotString(":o?:\delta","δ", OnOffToggle)
	HotString(":o?:\epsilon","ε", OnOffToggle)
	HotString(":o?:\zeta","ζ", OnOffToggle)
	HotString(":o?:\eta","η", OnOffToggle)
	HotString(":o?:\theta","θ", OnOffToggle)
	HotString(":o?:\iota","ι", OnOffToggle)
	HotString(":o?:\kappa","κ", OnOffToggle)
	HotString(":o?:\lambda","λ", OnOffToggle)
	HotString(":o?:\mu","μ", OnOffToggle)
	HotString(":o?:\vu","ν", OnOffToggle)
	HotString(":o?:\xi","ξ", OnOffToggle)
	HotString(":o?:\pi","π", OnOffToggle)
	HotString(":o?:\rho","ρ", OnOffToggle)
	HotString(":o?:\omicron","ο", OnOffToggle)
	HotString(":o?:\sigma","σ", OnOffToggle)
	HotString(":o?:\ssigma","ς", OnOffToggle)
	HotString(":o?:\tau","τ", OnOffToggle)
	HotString(":o?:\upsilon","υ", OnOffToggle)
	HotString(":o?:\phi","φ", OnOffToggle)
	HotString(":o?:\chi","χ", OnOffToggle)
	HotString(":o?:\psi","ψ", OnOffToggle)
	HotString(":o?:\omega","ω", OnOffToggle)
		; //  ˢᵘᵖᵉʳˢᶜʳᶦᵖᵗ & ₛᵤᵦₛ𝒸ᵣᵢₚₜ (i have no idea why the t formats here)
	HotString(":o?:^0","⁰", OnOffToggle)
	HotString(":o?:^1","¹", OnOffToggle)
	HotString(":o?:^2","²", OnOffToggle)
	HotString(":o?:^3","³", OnOffToggle)
	HotString(":o?:^4","⁴", OnOffToggle)
	HotString(":o?:^5","⁵", OnOffToggle)
	HotString(":o?:^6","⁶", OnOffToggle)
	HotString(":o?:^7","⁷", OnOffToggle)
	HotString(":o?:^8","⁸", OnOffToggle)
	HotString(":o?:^9","⁹", OnOffToggle)
	HotString(":o?:^x","ˣ", OnOffToggle)
	HotString(":o?:^y","ʸ", OnOffToggle)
	HotString(":o?:^i","ᶦ", OnOffToggle)
	HotString(":o?:^t","ᵗ", OnOffToggle)
	HotString(":o?:^f","ᶠ", OnOffToggle)

	HotString(":o?:_0","₀", OnOffToggle)
	HotString(":o?:_1","₁", OnOffToggle)
	HotString(":o?:_2","₂", OnOffToggle)
	HotString(":o?:_3","₃", OnOffToggle)
	HotString(":o?:_4","₄", OnOffToggle)
	HotString(":o?:_5","₅", OnOffToggle)
	HotString(":o?:_6","₆", OnOffToggle)
	HotString(":o?:_7","₇", OnOffToggle)
	HotString(":o?:_8","₈", OnOffToggle)
	HotString(":o?:_9","₉", OnOffToggle)
	HotString(":o?:\_x","ₓ", OnOffToggle)
	HotString(":o?:\_y","ᵧ", OnOffToggle)
	HotString(":o?:\_i","ᵢ", OnOffToggle)
	HotString(":o?:\_t","ₜ", OnOffToggle)
	
	HotString(":o?:\#f","𝒻", OnOffToggle)
	Hotkey, IfWinActive
}