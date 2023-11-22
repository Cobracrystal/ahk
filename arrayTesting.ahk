#Requires Autohotkey 2.0
#Warn Unreachable, StdOut
TransparentTaskbar.TransparentTaskbar(1,,,50)
return


^+H::{ ; Make Taskbar invisible 
	TransparentTaskbar.setInvisibility("T", 0)
}

^+K::{ ; Toggle Taskbar Transparency
	TransparentTaskbar.transparentTaskbar("T")
}

^+R::{
	Reload()
}


#Include "%A_ScriptDir%\LibrariesV2\TransparentTaskbar.ahk"