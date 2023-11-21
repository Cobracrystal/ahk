
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

;// open Standard Internet Explorer
wb := ComObjCreate("InternetExplorer.Application") ;// create IE
wb.Visible := true ;// show IE
wb.GoHome() ;// Navigate Home

;// the ReadyState will be 4 when the page is loaded
while wb.ReadyState <> 4
    continue

;// get the Name & URL of the site
MsgBox % "Name: " wb.LocationName
    . "`nURL: " wb.LocationURL
    . "`n`nLet's Navigate to Autohotkey.com..."

;// get the Document - which is the webpage
document := wb.document
 
;// Navigate to AutoHotkey.com
wb.Navigate("www.AutoHotkey.com") ;// 2nd param - see NavConstants

;// the Busy property will be true while the page is loading
while wb.Busy
    continue
MsgBox Page Loaded...Going Back Now

;// Go Back
wb.GoBack()

while wb.Busy
    continue
MsgBox The page is loaded - now we will refresh it...

;// Refresh the page
wb.Refresh()
while wb.Busy
    continue
MsgBox Now that the page is Refreshed, we will Select All (^a)...

;// Execute Commands with ExecWB()
SelectAll := 17 ;// see CMD IDs
wb.ExecWB(SelectAll,0) ;// second param as "0" uses default options

Sleep 2000
MsgBox Now that we are done, we will exit Interent Explorer

;// Quit Internet Explorer
wb.Quit()