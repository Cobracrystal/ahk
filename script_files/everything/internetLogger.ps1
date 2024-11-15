param(
	[string]$path
)
$stop = 0
$attempt = 1
if($path) {
	$logfile = $path
} else {
	$logFile = $home + "\Desktop\internetlog.txt"
}
$currentTimestamp = Get-Date
$lastLoopTimestamp = $currentTimestamp
$lastPingTimestamp = (Get-Date 0)
$connectedSince = 0
$secondsConnected = 0
$totalSecondsConnected = 0
$disconnectedSince = 0
$secondsDisconnected = 0
$totalSecondsDisconnected = 0
$previousStatus = "None"

mode con: cols=70 lines=10
$Host.UI.RawUI.WindowTitle = "INTERNET_LOGGER"
[console]::CursorVisible = $false

[System.Management.Automation.Runspaces.Runspace]::DefaultRunspace

Register-EngineEvent -SourceIdentifier PowerShell.Exiting -SupportEvent -Action {
	"`nExited:`t`t`t" + (Get-Date).ToString('T') | Out-File $logfile -Append -NoNewline
}
Clear-Host

Write-Host ""
Write-Host " Started at" (get-date).ToString('T') -ForegroundColor White -BackgroundColor Blue
Write-Host ""
$cursorResetPosition = $host.UI.RawUI.CursorPosition
$cursorCurrentPosition = $host.UI.RawUI.CursorPosition
$cursorExitPosition = $host.UI.RawUI.CursorPosition

"`n------------------------------------------------" | Out-File $logFile -Append
"Script started monitoring at " + (get-date).ToString() | Out-File $logFile -Append
"------------------------------------------------" | Out-File $logFile -Append

do {
	### Start ping
	$host.UI.RawUI.CursorPosition = $cursorResetPosition
	Write-Host " Pinging google.com... " -NoNewLine -ForegroundColor Yellow
	$cursorCurrentPosition = $host.UI.RawUI.CursorPosition
	$host.UI.RawUI.CursorPosition = $cursorExitPosition
	if ((New-TimeSpan -Start $lastPingTimestamp -End $currentTimestamp).TotalMilliseconds -gt 1000) {
		$lastPingTimestamp = Get-Date
		$ping = test-connection -comp www.google.com -Quiet -Count 1
	}
	$host.UI.RawUI.CursorPosition = $cursorCurrentPosition

	### Update result
	$currentTimestamp = Get-Date
	if ($ping) {
		if ($previousStatus -ne "Connected") {
			if (!(test-connection -comp www.google.com -Quiet -Count 1)) {
				continue
			}
			$connectedSince = Get-Date
			if ($previousStatus -eq "Disconnected") {
				"`t(~" + $secondsDisconnected + " seconds)" | Out-File $logFile -Append
			}
			"Connected:`t`t" + $connectedSince.toString('T') | Out-File $logFile -NoNewLine -Append
		}
		$secondsConnected = [math]::Round((New-TimeSpan -Start $connectedSince -End $currentTimestamp).TotalSeconds)
		$totalSecondsConnected += (New-TimeSpan -Start $lastLoopTimestamp -End $currentTimestamp).TotalSeconds # this is a double
		Write-Host "[ Connected ]" -NoNewLine -ForegroundColor Black -BackgroundColor Green
		Write-Host " since " -NoNewLine -ForegroundColor Yellow
		$connectedSince.ToString('T') + " (" + $secondsConnected + "s ago)" | Write-Host -NoNewLine -ForegroundColor Black -BackgroundColor Yellow
		Write-Host "              "
		$previousStatus = "Connected"
	} else {
		if ($previousStatus -ne "Disconnected") {
			if (test-connection -comp www.google.com -Quiet -Count 1) {
				continue
			}
			$disconnectedSince = Get-Date
			if ($previousStatus -eq "Connected") {
				"`t(~" + $secondsConnected + " seconds)" | Out-File $logfile -Append
			}
			"Disconnected:`t" + $disconnectedSince.toString('T') | Out-File $logfile -NoNewLine -Append
		}
		$totalSecondsDisconnected += (New-TimeSpan -Start $lastLoopTimestamp -End $currentTimestamp).TotalSeconds # this is a double
		$secondsDisconnected = [math]::Round((New-TimeSpan -Start $disconnectedSince -End $currentTimestamp).TotalSeconds)
		Write-Host "[ Disconnected ]" -NoNewLine -ForegroundColor Black -BackgroundColor Red
		Write-Host " since " -NoNewLine -ForegroundColor Yellow
		$disconnectedSince.ToString('T') + " (" + $secondsDisconnected + "s ago)" | Write-Host -NoNewLine -ForegroundColor Black -BackgroundColor Yellow
		Write-Host "              "
		$previousStatus = "Disconnected"
	}

	### Display status bar, taken from stackexchange
	$statusBarLength = 10
	$connectedPercentage = ($totalSecondsConnected / ($totalSecondsConnected + $totalSecondsDisconnected)) * 100
	$connectedPercentageLength = ($connectedPercentage / 100) * $statusBarLength
	$disconnectedPercentageLength = $statusBarLength - $connectedPercentageLength
	Write-Host " Uptime: [" -NoNewLine
	for ($i = 0; $i -lt $connectedPercentageLength; $i++) {
		Write-Host " " -NoNewLine -BackgroundColor Green
	}
	Write-Host "|" -NoNewLine -BackgroundColor Yellow -ForegroundColor White
	for ($i = 0; $i -lt $disconnectedPercentageLength; $i++) {
		Write-Host " " -NoNewLine -BackgroundColor Red
	}
	$roundedConnectedPercentage = [math]::Round($connectedPercentage)
	"]  " + $roundedConnectedPercentage.ToString().PadLeft(3,' ') + "%" | Write-Host 
	$roundedTotalSecondsConnected = [math]::Round($totalSecondsConnected)
	$roundedTotalSecondsDisconnected = [math]::Round($totalSecondsDisconnected)
	Write-Host " Connected for" $roundedTotalSecondsConnected"s, disconnected for" $roundedTotalSecondsDisconnected"s"

	### Reset
	Write-Host "" -NoNewLine
	$lastLoopTimestamp = $currentTimestamp
	$attempt++
	$cursorExitPosition = $host.UI.RawUI.CursorPosition
#	Start-Sleep -Milliseconds 1000
} until ($stop -eq 1)
