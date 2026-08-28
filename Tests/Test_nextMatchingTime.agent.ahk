#Include Tester.ahk
#Include ..\LibrariesV2
#Include TimeUtilities.ahk
testNextMatchingTime()

testNextMatchingTime() {
	offset1 := "20260828220124" ; 2026, 28th August, 22:01:24
	offset2 := "20231227171634" ; 27th December, 2023, 17:16:34
	offset3 := "20250228235944" ; Friday, 28.02.2025, 23:59:44
	offset4 := "20240228235944" ; Wednesday, 28.02.2024, 23:59:44
	assert := Tester.assert.bind(Tester)
	assert(nextMatchingTime, [offset2], offset2)
	assert(nextMatchingTime, [offset2,2023,12], offset2)
	assert(nextMatchingTime, [offset2,2023, , 27], offset2)
	assert(nextMatchingTime, [offset2,2023, , 28], "20231228000000")
	assert(nextMatchingTime, [offset2,, 2, 29], "20240229000000")
	assert(nextMatchingTime, [offset2,2022], 0)
	assert(nextMatchingTime, [offset2,2025, 02, 29], ValueError("Invalid date specified"))
	assert(nextMatchingTime, [offset2, , 1, , , 19], "20240101001900")

	assert(nextMatchingTime, [offset2, ,,,16,,], "20231228160000")
	assert(nextMatchingTime, [offset2, ,,,17,,], "20231227171634")
	assert(nextMatchingTime, [offset2, ,,,18,,], "20231227180000")
	assert(nextMatchingTime, [offset2, ,,,16,15,23], "20231228161523")
	assert(nextMatchingTime, [offset2, ,,,17,15,], "20231228171500")
	assert(nextMatchingTime, [offset2, ,,,18,15,], "20231227181500")
	assert(nextMatchingTime, [offset2, ,,,17,16,], "20231227171634")
	assert(nextMatchingTime, [offset2, ,,,18,16,], "20231227181600")
	assert(nextMatchingTime, [offset2, ,,,17,17,], "20231227171700")
	assert(nextMatchingTime, [offset2, ,,,18,17,], "20231227181700")
	assert(nextMatchingTime, [offset2, ,,,17,,33], "20231227171733")
	assert(nextMatchingTime, [offset2, ,,,18,,33], "20231227180033")
	assert(nextMatchingTime, [offset2, ,,,17,,34], "20231227171634")
	assert(nextMatchingTime, [offset2, ,,,18,,34], "20231227180034")
	assert(nextMatchingTime, [offset2, ,,,17,,35], "20231227171635")
	assert(nextMatchingTime, [offset2, ,,,18,,35], "20231227180035")
	assert(nextMatchingTime, [offset2, ,,,17,16,34], "20231227171634")
	assert(nextMatchingTime, [offset2, ,,,17,16,35], "20231227171635")
	assert(nextMatchingTime, [offset2, ,,,17,16,33], "20231228171633")

	assert(nextMatchingTime, [offset2, ,,,, 15,], "20231227181500")
	assert(nextMatchingTime, [offset2, ,,,, 16,], "20231227171634")
	assert(nextMatchingTime, [offset2, ,,,, 17,], "20231227171700")
	assert(nextMatchingTime, [offset2, ,,,, 15,33], "20231227181533")
	assert(nextMatchingTime, [offset2, ,,,, 16,33], "20231227181633")
	assert(nextMatchingTime, [offset2, ,,,, 17,33], "20231227171733")
	assert(nextMatchingTime, [offset2, ,,,, 15,34], "20231227181534")
	assert(nextMatchingTime, [offset2, ,,,, 16,34], "20231227171634")
	assert(nextMatchingTime, [offset2, ,,,, 17,34], "20231227171734")
	assert(nextMatchingTime, [offset2, ,,,, 15,35], "20231227181535")
	assert(nextMatchingTime, [offset2, ,,,, 16,35], "20231227171635")
	assert(nextMatchingTime, [offset2, ,,,, 17,35], "20231227171735")

	assert(nextMatchingTime, [offset2, ,,,,,33], "20231227171733")
	assert(nextMatchingTime, [offset2, ,,,,,34], "20231227171634")
	assert(nextMatchingTime, [offset2, ,,,,,35], "20231227171635")

	assert(nextMatchingTime, [offset3, ,,,,,44], "20250228235944")
	assert(nextMatchingTime, [offset3, ,,,,,43], "20250301000043")
	assert(nextMatchingTime, [offset4, ,,,,,44], "20240228235944")
	assert(nextMatchingTime, [offset4, ,,,,,43], "20240229000043")

	assert(nextMatchingTime, [offset4, ,,29,,,], "20240229000000")
	assert(nextMatchingTime, [offset3, ,,29,,,], "20250329000000")
}
