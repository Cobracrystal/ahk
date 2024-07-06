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
$code = @"
	using System;
	using System.IO;
	using System.Runtime.InteropServices;
	using System.Management.Automation;
	using System.Management.Automation.Runspaces;


	namespace PowershellExitLogger
	{
		public static class LoggerClass
		{
			private static HandlerRoutine static_routine;

			private static DateTime lastEventTime;

			public static void SetHandler()
			{
				if (static_routine == null)
				{
					static_routine = new HandlerRoutine(ConsoleCtrlCheck);
					SetConsoleCtrlHandler(static_routine, true);
				}
			}

			public static void updateLastEventTime() {
				lastEventTime = DateTime.Now;
			}

			private static bool ConsoleCtrlCheck(CtrlTypes ctrlType) {
				string path = @"$logfile"; 
				string message = "";
				DateTime currentTime = DateTime.Now;
				if (lastEventTime != DateTime.MinValue)
					message = "\t(~" + (int)DateTime.Now.Subtract(lastEventTime).TotalSeconds + " seconds)\n";
				message += "Exited: \t\t" + DateTime.Now.ToString("HH:mm:ss tt");
				switch (ctrlType) {
					case CtrlTypes.CTRL_C_EVENT:
					case CtrlTypes.CTRL_BREAK_EVENT:
					case CtrlTypes.CTRL_LOGOFF_EVENT:
					case CtrlTypes.CTRL_SHUTDOWN_EVENT:
						File.AppendAllText(path, message);
						return false;
					case CtrlTypes.CTRL_CLOSE_EVENT:
						File.AppendAllText(path, message);
						return true;
				}
				return false;
			}

			[DllImport("Kernel32")]
			public static extern bool SetConsoleCtrlHandler(HandlerRoutine Handler, bool Add);

			public delegate bool HandlerRoutine(CtrlTypes CtrlType);

			public enum CtrlTypes
			{
				CTRL_C_EVENT = 0,
				CTRL_BREAK_EVENT,
				CTRL_CLOSE_EVENT,
				CTRL_LOGOFF_EVENT = 5,
				CTRL_SHUTDOWN_EVENT
			}
		}
}
"@

mode con: cols=65 lines=10
$Host.UI.RawUI.WindowTitle = "INTERNET_LOGGER"
[console]::CursorVisible = $false

Add-Type  -TypeDefinition $code -Language CSharp
[System.Management.Automation.Runspaces.Runspace]::DefaultRunspace
[PowershellExitLogger.LoggerClass]::SetHandler()

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
			$connectedSince = Get-Date
			[PowershellExitLogger.LoggerClass]::updateLastEventTime()
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
			$disconnectedSince = Get-Date
			[PowershellExitLogger.LoggerClass]::updateLastEventTime()
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
