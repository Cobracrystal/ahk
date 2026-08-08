
#Include ..\LibrariesV2
#Include ObjectUtilities.ahk
#Include PrimitiveUtilities.ahk
#Include BasicUtilities.ahk
#Include MsgBoxAsGui.ahk

class Wordle {
	static debug := true

	static validGuesses := strSplitOnNewLine(FileRead(A_LineFile "\..\..\script_files\Test\valid-wordle-words.txt", "UTF-8"))
	static validAnswers := strSplitOnNewLine(FileRead(A_LineFile "\..\..\script_files\Test\wordle-answers-alphabetical.txt", "UTF-8"))
	static completeWordMap := mapFromArrays(this.validGuesses, this.validGuesses)
	static enum := {
		grey: 0,
		green: 1,
		yellow: 2
	}
	static enum_str := {
		grey: "0",
		green: "1",
		yellow: "2"
	}
	static enum_emoji := {
		grey: "⬛",
		green: "🟩",
		yellow: "🟨"
	}

	static gameSolver(solution) {
		return 0
	}

	class Game {
		static origin := Wordle
		static entropy := Wordle.EntropyAnalysis
		static helpers := Wordle.Helpers

		static consoleGame(solution?, hardWords := false) {
			guesses := []
			patterns := []
			solution := Wordle.Helpers.getRandomWord(hardWords)
			solution := StrUpper(solution)
			if Wordle.debug
				possibleSolutions := hardWords ? Wordle.validGuesses : Wordle.validAnswers
			hwnd := 0
			Loop(6) {
				word := InputBox("Enter Guess:").Value
				while (!IsAlpha(word) || StrLen(word) != 5 || !Wordle.completeWordMap.Has(word)) {
					ib := InputBox("Invalid. Try Again:", "Guess Box")
					if ib.Result == "Cancel"
						break 2
					word := ib.Value
				}
				if WinExist(hwnd)
					WinClose(hwnd)
				guesses.push(word)
				patterns.push(this.helpers.generatePattern(word, solution, 0, Wordle.enum))
				print StrUpper(word) " | " Wordle.Helpers.generatePattern(word, solution, 1, Wordle.enum_emoji)
				if word = solution {
					print "yay!!! you won!! it was ["  solution "]!!!"
					break
				}
				if Wordle.debug
					possibleSolutions := Wordle.Helpers.findFromPattern(word, patterns[-1],possibleSolutions)
					if possibleSolutions.Length < 1000
						hwnd := MsgBoxAsGui(toString(possibleSolutions)).hwnd
			}
			if word != solution {
				print "booo!! you lost... :< Solution was [" solution "]"
			}
		}

		; unfortunately emojis don't render properly in this.
		static guiGame(solution?, hardWords := false) {
			solution := Wordle.Helpers.getRandomWord(hardWords)
			solution := StrUpper(solution)
			guesses := 0
			g := Gui('+Resize', 'Printer')
			g.MarginX := g.MarginY := 0
			g.SetFont('s12', 'Calibri')
			g.AddText('Section x10 y10 w80', 'Guesses:')
			g.AddText('yp w10 vGuesses', guesses)
			cEdit := g.AddEdit('xm ys+30 w600 h400 vEdit ReadOnly')
			eEdit := g.AddEdit("w600 R2 vField -WantReturn")
			g.AddButton("Default Hidden").OnEvent("Click", submitGuess)
			g.show()
			return g

			submitGuess(*) {
				guess := eEdit.Value
				if !(IsAlpha(guess) && StrLen(guess) == 5)
					return
				guesses++
				p := Wordle.Helpers.generatePattern(guess, solution, 1, Wordle.enum_emoji)
				cEdit.Value := cEdit.Value "`n" p
				g["Guesses"].Text := guesses
			}
		}
	}

	class Helpers {

		static getRandomWord(searchSpace := Wordle.validAnswers) {
			return objGetRandomValue(searchSpace)
		}

		static selectEnum(strOrArray) {
			entry := strOrArray is Array ? strOrArray[1] : substr(strOrArray, 1, 1)
			switch entry {
				case Wordle.enum_str.green, Wordle.enum_str.grey, Wordle.enum_str.yellow:
					return Wordle.enum_str
				case Wordle.enum.green, Wordle.enum.grey, Wordle.enum.yellow:
					return Wordle.enum
				case Wordle.enum_emoji.green, Wordle.enum_emoji.grey, Wordle.enum_emoji.yellow:
					return Wordle.enum_emoji
				default:
					throw(Error("Bad Str"))
			}
		}
		
		/**
		 * Wrapper for Wordle.Helpers.find, this receives a word and the pattern it produces and returns a list of possible solutions.
		 * @param guess 
		 * @param pattern 
		 * @param searchSpace
		 * @returns {Array} 
		 */
		static findFromPattern(guess, pattern, searchSpace := Wordle.validAnswers) {
			guessArr := strsplit(guess)
			patternArr := pattern is Array ? pattern : StrSplitUTF8(pattern)
			_green := Map()
			_yellow := Map()
			_grey := Map()
			enum := this.selectEnum(patternArr)
			for i, e in patternArr {
				switch e {
					case enum.grey:
						_grey[i] := guessArr[i]
					case enum.yellow:
						_yellow[i] := guessArr[i]
					case enum.green:
						_green[i] := guessArr[i]
				}
			}
			return this.find(_green, _yellow, _grey,,searchSpace)
		}

		/**
		 * Given letters and their pattern result, returns a list of words that could be the solution
		 * @param {Map} greenLetters {2: "A"}
		 * @param {Map} yellowLetters {3: "B"}
		 * @param {String|Array|Map} greyLetters "CGX"
		 * @param {String} unknownPositionLetters "KED" 
		 * @returns {Array} ["baked"]
		 */
		static find(greenLetters := Map(), yellowLetters := Map(), greyLetters := "", unknownPositionLetters := "", searchSpace := Wordle.validGuesses, silentError := false) {
			greyLetters := greyLetters is Map || greyLetters is Array ? greyLetters : StrSplit(greyLetters)
			unknownPositionLetters := StrSplit(unknownPositionLetters)
			list := searchSpace
			for i, e in greenLetters {
				_index := i, _element := e
				list := objFilter(list, v => substr(v, _index, 1) = _element)
			}
			for i, e in greyLetters {
				_index := i, _element := e
				allowedCountYellow := objCountValue(yellowLetters, _element)
				if allowedCountYellow && objContainsValue(yellowLetters, e) >= greyLetters {
					if silentError
						return []
					throw(Error("Invalid Pattern containing both grey and yellow in bad order"))
				}
				allowedCount := objCountValue(greenLetters, _element) + allowedCountYellow
				if allowedCount
					list := objFilter(list, v => (strCountStr(v, _element) == allowedCount && SubStr(v, _index, 1) != _element))
				else
					list := objFilter(list, v => (!InStr(v, _element)))
			}
			for i, e in yellowLetters {
				_index := i, _element := e
				allowedCount := objCountValue(greenLetters, _element) + objCountValue(yellowLetters, _element)
				if allowedCount > 1
					list := objFilter(list, v => (strCountStr(v, _element) >= allowedCount && SubStr(v, _index, 1) != _element))
				else
					list := objFilter(list, v => (InStr(v, _element) && SubStr(v, _index, 1) != _element))
			}
			for i, e in unknownPositionLetters {
				_index := i, _element := e
				list := objFilter(list, v => (InStr(v, _element)))
			}
			return list
		}

		/**
		 * Given a pattern and a solution, generates a list of words that would create the given pattern when matched against solution.
		 * @param {String} pattern 
		 * @param {String} solution 
		 * @param {Array} searchSpace 
		 * @returns {Integer} 
		 */
		static getWordsForPattern(pattern := "", solution := "", searchSpace := Wordle.validGuesses) {
			solution := StrLower(solution)
			solArr := StrSplit(solution)
			patternArr := StrSplitUTF8(pattern)
			enum := this.selectEnum(patternArr)
			_green := Map()
			for i, n in patternArr
				if n == enum.green
					_green[i] := solArr[i]
			list := this.find(_green,,,,searchSpace)
			retList := objfilter(
				list,
				v => this.generatePattern(v, solution, 1, enum) == pattern
			)
			list2 := this.findFromPattern(solution, pattern, searchSpace)
			print "lists equal? : " objCompare(retList, list2)
			return retList
		}

		/**
		 * Given a word and the solution, generates the pattern of matching word against solution.
		 * @param word 
		 * @param solution 
		 * @param {Integer} asStr 
		 * @param {Object} enum 
		 * @returns {String | Array} 
		 */
		static generatePattern(word, solution, asStr := false, enum := Wordle.enum) {
			p := []
			p.Length := 5
			word := word is Array ? word.Clone() : StrSplit(word)
			solution := solution is Array ? solution.Clone() : StrSplit(solution)
			Loop(5) {
				i := 6-A_Index
				if word[i] == solution[i] {
					p[i] := enum.green
					word[i] := 0
					solution.RemoveAt(i)
				} else {
					p[i] := enum.grey
				}
			}
			for pos, char in word {
				if char != 0 {
					for pos2, char2 in solution {
						if char == char2 {
							p[pos] := enum.yellow
							solution.RemoveAt(pos2)
							break
						}
					}
				}
			}
			return asStr ? p[1] . p[2] . p[3] . p[4] . p[5] : p
		}

		static getPatternID(word, solution) {
			hash := 0
			word := word is Array ? word.Clone() : StrSplit(word)
			solution := solution is Array ? solution.Clone() : StrSplit(solution)
			Loop(5) {
				i := 6-A_Index
				if word[i] == solution[i] {
					hash += 3**(A_Index-1) * 1
					word[i] := 0
					solution.RemoveAt(i)
				}
			}
			for pos, char in word {
				if char != 0 {
					for pos2, char2 in solution {
						if char == char2 {
							hash += 3**(5-pos) * 2
							solution.RemoveAt(pos2)
							break
						}
					}
				}
			}
			return hash
		}
	}
	

	class EntropyAnalysis {
		static STRATEGY := {
			countLetterDistribution: this.shittyWordEntropyScores.bind(this),
			shennanEntropy: this.shittyWordEntropyScores.bind(this),
			shennanEntropy: this.shittyWordEntropyScores.bind(this)
		}
		static fullSpacePrecalculations := Map()

		static shittyWordEntropyScores(searchSpace := Wordle.validAnswers) {
			arrSearchSpace := objDoForEach(searchSpace, word => StrSplit(word))
			b := Map()
			loop(26)
				b[chr(96+A_Index)] := 0 ; fill with letters
			buckets := [b.Clone(), b.Clone(), b.Clone(), b.Clone(), b.Clone()]
			for wordArr in arrSearchSpace {
				counts := objCountDuplicates(wordArr)
				for obj in counts {
					Loop(obj.c)
						buckets[A_Index][obj.v]++
				}
			}
			letterScores := objDoForEach(buckets,
				singleletterscore => objDoForEach(singleletterscore, 
					v => (v / searchSpace.Length) * (1 - v / searchSpace.Length)
				)
			)
			wordScores := Map()
			for i, word in searchSpace {
				letters := arrSearchSpace[i]
				counts := objCountDuplicates(letters)
				wordScore := 0
				for obj in counts ; both loops together are always 5 iterations
					Loop(obj.c)
						wordScore += letterScores[A_Index][obj.v]
				wordScores[word] := wordScore
			}
			wordScoresSorted := objSort(wordScores,,"N R",false)
			return wordScoresSorted
		}

		static autoSolveWord(solution, strategy := this.STRATEGY.countLetterDistribution) {

		}

		static benchmarkAutosolver(strategy := this.STRATEGY.countLetterDistribution, detailedPrints := false, amount := 100) {
			initialSearchSpace := Wordle.validAnswers
			initialGuesses := strategy(initialSearchSpace)
			guesses := []
			Loop(1000) {
				solution := Wordle.Helpers.getRandomWord()
				; solution := "fluff"
				starter := initialGuesses[Random(1,3)].key
				searchSpace := initialSearchSpace
				guess := ""
				count := 0
				str := ""
				str2 := ""
				str3 := ""
				while guess != solution {
					guess := (A_Index == 1) ? starter : Wordle.EntropyAnalysis.shittyWordEntropyScores(searchSpace)[1].key
					pattern := Wordle.Helpers.generatePattern(guess, solution)
					patternE := Wordle.Helpers.generatePattern(guess, solution,1,Wordle.enum_emoji)
					searchSpace := Wordle.Helpers.findFromPattern(guess, pattern, searchSpace)
					; print("Guess #" A_Index ": " guess " | " patternE " | Searchspace Len: " searchSpace.Length " | " (searchSpace.Length < 15 ? toString(searchSpace,1,0) : ""))
					str .= guess " -> "
					str2 .= patternE " -> "
					str3 .= searchSpace.Length " -> "
					count++
				}
				guesses.Push(count)
				if count == 2 {
					print(Format("[{}] ({}) {}", solution, count, substr(str,1,-4)),,1)
					print(Format("[{}] ({}) {}", solution, count, substr(str2,1,-4)),,1)
					print(Format("[{}] ({}) {}", solution, count, substr(str3,1,-4)),,1)
				}
			}
			print objGetAverage(guesses)
		}
	}
}