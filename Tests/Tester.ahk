#Include ..\LibrariesV2
#Include BasicUtilities.ahk

class Tester {
	static count := 0
	static assert(fn, params, expectedValue) {
		this.count++
		try res := fn(params*)
		catch as e {
			if Type(expectedValue) == Type(e) && e.Message == expectedValue.Message {
				print(this.count ": Test passed")
				return 1
			}
			str := expectedValue is Object ? (expectedValue.HasOwnProp("Message") ? expectedValue.Message : toString(expectedValue)) : expectedValue
			print(this.count ": Test failed. Expected value " Type(expectedValue) ": " str " for params " toString(params) ", got " Type(e) ": " e.Message)
			return 0
		}
		if Type(res) == Type(expectedValue) && res == expectedValue {
			print(this.count ": Test passed")
			return 1
		}
		str := expectedValue is Object ? (expectedValue.HasOwnProp("Message") ? expectedValue.Message : toString(expectedValue)) : expectedValue
		print(this.count ": Test failed. Expected value " Type(expectedValue) ": " str " for params " toString(params) ", got " res)
		return 0
	}
}