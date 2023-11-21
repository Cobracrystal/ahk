#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.

; The following folder will be the root folder for the TreeView. Note that loading might take a long
; time if an entire drive such as C:\ is specified:
InputBox, FolderPath, ConfirmDialog, Which Folder do you want to view?
if ErrorLevel
	ExitApp
TreeRoot := FolderPath
TreeViewWidth := 280
ListViewWidth := A_ScreenWidth - TreeViewWidth - 30

; Allow the user to maximize or drag-resize the window:
Gui +Resize

; Create an ImageList and put some standard system icons into it:
ImageListID := IL_Create(5)
Loop 5 
    IL_Add(ImageListID, "shell32.dll", A_Index)
; Create a TreeView and a ListView side-by-side to behave like Windows Explorer:
Gui, Add, TreeView, vMyTreeView r20 w%TreeViewWidth% gMyTreeView ImageList%ImageListID%
Gui, Add, ListView, vMyListView r20 w%ListViewWidth% x+10, Name|Modified

; Set the ListView's column widths (this is optional):
Col2Width := 70  ; Narrow to reveal only the YYYYMMDD part.
LV_ModifyCol(1, ListViewWidth - Col2Width - 30)  ; Allows room for vertical scrollbar.
LV_ModifyCol(2, Col2Width)

; Create a Status Bar to give info about the number of files and their total size:
Gui, Add, StatusBar
SB_SetParts(60, 85)  ; Create three parts in the bar (the third part fills all the remaining width).

; Add folders and their subfolders to the tree. Display the status in case loading takes a long time:
SplashTextOn, 200, 25, TreeView and StatusBar Example, Loading the tree...
AddSubFoldersToTree(TreeRoot)
SplashTextOff

; Display the window and return. The OS will notify the script whenever the user performs an eligible action:
Gui, Show,, %TreeRoot%  ; Display the source directory (TreeRoot) in the title bar.
return

AddSubFoldersToTree(Folder, ParentItemID = 0)
{
    ; This function adds to the TreeView all subfolders in the specified folder.
    ; It also calls itself recursively to gather nested folders to any depth.
    Loop %Folder%\*.*, 2  ; Retrieve all of Folder's sub-folders.
        AddSubFoldersToTree(A_LoopFileFullPath, TV_Add(A_LoopFileName, ParentItemID, "Icon4"))
}

MyTreeView:  ; This subroutine handles user actions (such as clicking).
if (A_GuiEvent <> "S")  ; i.e. an event other than "select new tree item".
    return  ; Do nothing.
; Otherwise, populate the ListView with the contents of the selected folder.
; First determine the full path of the selected folder:
TV_GetText(SelectedItemText, A_EventInfo)
ParentID := A_EventInfo
Loop  ; Build the full path to the selected folder.
{
    ParentID := TV_GetParent(ParentID)
    if not ParentID  ; No more ancestors.
        break
    TV_GetText(ParentText, ParentID)
    SelectedItemText := ParentText "\" SelectedItemText
}
SelectedFullPath := TreeRoot "\" SelectedItemText

; Put the files into the ListView:
LV_Delete()  ; Clear all rows.
GuiControl, -Redraw, MyListView  ; Improve performance by disabling redrawing during load.
FileCount := 0  ; Init prior to loop below.
TotalSize := 0
Loop %SelectedFullPath%\*.*  ; For simplicity, this omits folders so that only files are shown in the ListView.
{
    LV_Add("", A_LoopFileName, A_LoopFileTimeModified)
    FileCount += 1
    TotalSize += A_LoopFileSize
}
GuiControl, +Redraw, MyListView

; Update the three parts of the status bar to show info about the currently selected folder:
SB_SetText(FileCount . " files", 1)
SB_SetText(Round(TotalSize / 1024, 1) . " KB", 2)
SB_SetText(SelectedFullPath, 3)
return

GuiSize:  ; Expand/shrink the ListView and TreeView in response to user's resizing of window.
if (A_EventInfo = 1)  ; The window has been minimized. No action needed.
    return
; Otherwise, the window has been resized or maximized. Resize the controls to match.
GuiControl, Move, MyTreeView, % "H" . (A_GuiHeight - 30)  ; -30 for StatusBar and margins.
GuiControl, Move, MyListView, % "H" . (A_GuiHeight - 30) . " W" . (A_GuiWidth - TreeViewWidth - 30)
return

GuiClose:  ; Exit the script when the user closes the TreeView's GUI window.
ExitApp