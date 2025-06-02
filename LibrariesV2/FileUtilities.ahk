; given two folders, compares files and removes duplicates based on size + name, keeping files in folder 1
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