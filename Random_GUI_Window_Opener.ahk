#NoEnv

Start:
j:=0
i:=0
InputBox, winVar, Window Amount, How many Windows do you want to open?
if winVar is not Integer
	Goto Start
while (i <= winVar) {
		Random, xcoord, 10, % A_ScreenWidth - 120
		Random, ycoord, 10, % A_ScreenHeight - 150
		Gui, asd%i%:New, -MinimizeBox -MaximizeBox
		Gui, asd%i%:Add , Text , w70 h20 x30 y15, %i%
		Gui, asd%i%:Show, x%xcoord% y%ycoord% , Window No %i%
		i:=i+1
		}
return

GuiEscape:
GuiClose:
WinGetTitle, asd
if(j=winVar) {
	ExitApp 	
	}
j=j+1
asd := winVar - asd
Gui, asd%asd%:Destroy
return