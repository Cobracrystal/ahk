#SingleInstance Force
Loop parse, A_Clipboard, "`n", "`r"
	{
		Result := MsgBox("File number " A_Index " is " A_LoopField ".`n`nContinue?",, "y/n")
	}
	until Result = "No"

/*
commandLine:= winmgmt("CommandLine", "Where ProcessId = " 17008)
msgbox(commandLine[1])
return


winmgmt(v, w:="", d:="Win32_Process", m:="winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2"){
	local i, s:=[]
	for i in ComObjGet(m).ExecQuery("Select " (v?v:"*") " from " d  (w ? " " w :""))
		s.push(i.%v%)
	return s
}


/*
function() {
	/*
	Process, Exist, myprog.exe
	pid := ErrorLevel

	; Replace the WinTitle with the correct one
	WinGet, pid, PID, ahk_class TTOTAL_CMD

	VarSetCapacity(sFilePath, 260)
	VarSetCapacity(sCmdLine, 512)

	pFunc := DllCall("GetProcAddress"
		, "Uint", DllCall("GetModuleHandle", "str", "kernel32.dll")
		, "str", "GetCommandLineA")

	hProc := DllCall("OpenProcess", "Uint", 0x043A, "int", 0, "Uint", pid)

	hThrd := DllCall("CreateRemoteThread", "Uint", hProc, "Uint", 0, "Uint", 0
		, "Uint", pFunc, "Uint", 0, "Uint", 0, "Uint", 0)

	DllCall("WaitForSingleObject", "Uint", hThrd, "Uint", 0xFFFFFFFF)
	DllCall("GetExitCodeThread", "Uint", hThrd, "UintP", pcl)
	DllCall("ReadProcessMemory", "Uint", hProc, "Uint", pcl, "str", sCmdLine, "Uint", 512, "Uint", 0)

	DllCall("psapi\GetModuleFileNameExA", "Uint", hProc, "Uint", 0, "str", sFilePath, "Uint", 260)
	; DllCall("psapi\GetProcessImageFileNameA", "Uint", hProc, "str", sFilePath, "Uint", 281)

	DllCall("CloseHandle", "Uint", hThrd)
	DllCall("CloseHandle", "Uint", hProc)

	MsgBox % sFilePath . " | " . sCmdLine
}


; The following function can convert the obtained command line into pipe delimited string to ease Loop, Parse or StringSplit
DelimitParameters( CommandLine,D="|" ) {     ; Supplementary function for GetCommandLine()
	tempVar := CommandLine           ; www.autohotkey.com/forum/viewtopic.php?p=232199#232199
	Loop {
	StringReplace,tempVar,tempVar,%Param%
	CommandLine := DllCall( "shlwapi\PathGetArgsA", Str,CommandLine,Str )
	StringReplace,Param,tempVar,%CommandLine%
	DllCall( "shlwapi\PathUnquoteSpacesA", Str,Param )
	IfEqual,Param,,Return SubStr(DelimitedString,2)
	DelimitedString = %DelimitedString%%D%%Param%
   }}

GetCommandLine( PID ) { ;  by Sean          www.autohotkey.com/forum/viewtopic.php?t=16575 
Static pFunc 
If ! ( hProcess := DllCall( "OpenProcess", UInt,0x043A, Int,0, UInt, PID ) ) 
		Return  
If pFunc= 
	pFunc := DllCall( "GetProcAddress", UInt 
			, DllCall( "GetModuleHandle", Str,"kernel32.dll" ), Str,"GetCommandLineA" ) 
hThrd := DllCall( "CreateRemoteThread", UInt,hProcess, UInt,0, UInt,0, UInt,pFunc, UInt,0 
		, UInt,0, UInt,0 ),  DllCall( "WaitForSingleObject", UInt,hThrd, UInt,0xFFFFFFFF ) 
DllCall( "GetExitCodeThread", UInt,hThrd, UIntP,pcl ), VarSetCapacity( sCmdLine,512 ) 
DllCall( "ReadProcessMemory", UInt,hProcess, UInt,pcl, Str,sCmdLine, UInt,512, UInt,0 ) 
DllCall( "CloseHandle", UInt,hThrd ), DllCall( "CloseHandle", UInt,hProcess ) 
Return sCmdLine 
} 

SetDebugPrivilege() {
;PROCESS_QUERY_INFORMATION=[color=red]0x400[/color], TOKEN_ADJUST_PRIVILEGES=[color=red]0x20[/color], SE_PRIVILEGE_ENABLED:=[color=red]0x2[/color]
hProcess := DllCall( "OpenProcess", UInt,[color=red]0x400[/color],Int,0,UInt,DllCall("GetCurrentProcessId"))
DllCall( "Advapi32.dll\LookupPrivilegeValueA", UInt,0, Str,"[color=red]SeDebugPrivilege[/color]", UIntP,lu )
	; TOKEN_PRIVILEGES Structure : www.msdn.microsoft.com/en-us/library/aa379630(VS.85).aspx
VarSetCapacity( TP,16,0), NumPut( 1,TP,0,4 ),  NumPut( lu,TP,4,8 ), NumPut( [color=red]0x2[/color],TP,12,4 ) 
DllCall( "Advapi32.dll\OpenProcessToken", UInt,hProcess, UInt,[color=red]0x20[/color], UIntP,hToken )
Result :=  DllCall( "Advapi32.dll\AdjustTokenPrivileges"
				, UInt,hToken, UInt,0, UInt,&TP, UInt,0, UInt,0, UInt,0 )
DllCall( "CloseHandle", UInt,hProcess ), DllCall( "CloseHandle", UInt,hToken )
Return Result 
}

SetDebugPrivilege() 
MsgBox, % GetCommandLine( DllCall( "GetCurrentProcessId" ) ) 
Process, Exist, svchost.exe 
MsgBox,0, %errorLevel%, % GetCommandLine( errorLevel )
*/