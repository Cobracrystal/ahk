; TODO: It would be more efficient (in order to deal with nested loops) to store matching indices of loop starts and loop ends in a persistent structure upon parsing code
; right now, eg. a skipped loop is evaluated every time it is encountered, eg:
; ++[>++[>++[>++[>++[>[.....]<]<]<]<]<]
; this iterates 2**5 times and the skipped loop [.....] which is always iterating 0 times would be evaluated 2**5 times.
; this makes code interpretation expensive based on O(loopiterations * code length of skipped loop) which isn't necessary

class BrainFuck {
	static executeWithCallbacks(code, callbackOutput?, callbackInput?, useAscii := true) {
		tape := [0]
		tape.Default := 0
		dataPointer := 1
		output := useAscii ? "" : []
		inputCounter := 1
		loopstack := []
		nestedLoopStartIndices := []
		nestedLoopEndIndices := []
		instructionStack := StrSplit(code)
		instructionPointer := 1
		currentLoopNestLevel := 0
		while instructionPointer <= instructionStack.Length {
			char := instructionStack[instructionPointer]
			switch char {
				case ">":
					dataPointer++
					if tape.Length < dataPointer
						tape.Length := dataPointer
				case "<":
					if dataPointer == 0
						throw(IndexError("Attempt to decrement Pointer with value 0"))
					dataPointer--
				case "+":
					tape[dataPointer] := Mod(tape[dataPointer] + 1, 256)
				case "-":
					tape[dataPointer] := Mod(tape[dataPointer] + 255, 256) ; mod(-1, n) = -1 in ahk
				case ".":
					if IsSet(callbackOutput)
						callbackOutput(useAscii ? Chr(tape[dataPointer]) : tape[dataPointer])
					if useAscii
						output .= Chr(tape[dataPointer])
					else
						output.push(tape[dataPointer])
				case ",":
					if !IsSet(callbackInput)
						throw(Error("Program requires Input, yet no Input function was specified"))
					tape[dataPointer] := Mod(Mod(callbackInput(inputCounter++), 256) + 256, 256)
					; Mod(Mod(n, b) + b, b) guarantees a positive result whereas Mod(-258, 256) = -2 ≠ 254
				case "[":
					; we havent iterated this loop even once yet
					if nestedLoopStartIndices.Length == 0 || nestedLoopStartIndices[currentLoopNestLevel] != instructionPointer {
						; Don't know loop + zero iterations -> skip to end instantly
						if tape[dataPointer] == 0 {
							while tape[instructionPointer] != "]" ; this works because there's another ++ at the end of the switch
								instructionPointer++
						} else { ; don't know loop, do iterate -> store pointer and go into a deeper nest
							nestedLoopStartIndices.push(instructionPointer)
							currentLoopNestLevel++
						}
					} else { ; we do know this loop
						if tape[dataPointer] == 0 { ; if 0, jump to end of loop
							nestedLoopStartIndices.Pop()
							instructionPointer := nestedLoopEndIndices.Pop()
						}
						; if nonzero, just continue by ++ at end of switch
					}
				case "]":
					if !currentLoopNestLevel
						throw(Error("Invalid Syntax: ] encountered with no matching ["))
					if tape[dataPointer] == 0 {
						nestedLoopStartIndices.Pop()
						nestedLoopEndIndices.Pop()
						currentLoopNestLevel--
					} else {
						if !nestedLoopEndIndices.Has(currentLoopNestLevel)
							nestedLoopEndIndices.Push(instructionPointer)
						instructionPointer := nestedLoopStartIndices[currentLoopNestLevel]
						continue
					}
			}
			instructionPointer++
			; NOTE: WHAT IF [aosidasd] IS ENCOUNTERED AND tape[datapointer] IS 0 BEFORE EVEN ONE LOOP ITERATION 
		}
		return output
	}

	static CallbackInputBox(num?) {
		if this is Integer
			num := this
		return Integer(InputBox("Enter Input #" . num).Value)
	}

	class Examples {
		static HelloWorld := "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++."
		static OhNo := "-[--->+<]>------.-[--->++++<]>.--[--->+<]>--.+[----->+<]>+.+.[--->+<]>-----.--[->++++<]>-.+[->+++<]>.-------.--[--->+<]>-.[---->+<]>+++.---[->++++<]>.------------.---.--[--->+<]>-.++[->+++<]>.-[--->+<]>--.+[->+++<]>+.++++++++.-[++>---<]>+.-[--->++<]>-.++++++++++.+[---->+<]>+++.-[--->++<]>--.-------.-[++>-----<]>..-----------.+++++++++.-----.+++++.-------."
		static addTwoValues := ",>,<[->+<]>."

	}
}