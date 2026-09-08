# MARCO DICTATION - uninstaller. Removes everything this package installed.
$ErrorActionPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}

$Target  = Join-Path $env:LOCALAPPDATA 'MarcoDictation'
$Script  = Join-Path $Target 'voice-latch.ahk'
$Startup = [Environment]::GetFolderPath('Startup')
if ([string]::IsNullOrWhiteSpace($Startup)) { $Startup = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup' }
$Lnk     = Join-Path $Startup 'Marco Dictation.lnk'

Write-Host ''
Write-Host '  Removing Marco Dictation...'

# Stop ONLY our own instance. Other AutoHotkey scripts the user runs are
# none of our business and must survive this.
$mine = @(Get-CimInstance Win32_Process -Filter "Name='AutoHotkey64.exe'" |
          Where-Object { $_.CommandLine -and $_.CommandLine -like ('*' + $Script + '*') })
foreach ($p in $mine) { try { Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop } catch {} }
if ($mine.Count) { Start-Sleep -Milliseconds 700 }

Remove-Item $Lnk -Force
Remove-Item $Target -Recurse -Force

$stillMine = @(Get-CimInstance Win32_Process -Filter "Name='AutoHotkey64.exe'" |
               Where-Object { $_.CommandLine -and $_.CommandLine -like ('*' + $Script + '*') })
$okProc  = ($stillMine.Count -eq 0)
$okLnk   = -not (Test-Path $Lnk)
$okDir   = -not (Test-Path $Target)
$survived = @(Get-Process -Name 'AutoHotkey64' -ErrorAction SilentlyContinue).Count

Write-Host ("  [{0}] stopped" -f $(if ($okProc) { ' OK ' } else { 'FAIL' }))
Write-Host ("  [{0}] removed from startup" -f $(if ($okLnk) { ' OK ' } else { 'FAIL' }))
Write-Host ("  [{0}] files deleted" -f $(if ($okDir) { ' OK ' } else { 'FAIL' }))
if ($survived -gt 0) { Write-Host ("  [ OK ] left {0} unrelated AutoHotkey script(s) running" -f $survived) }
Write-Host ''
Write-Host '  Note: Windows Voice Typing itself stays available on Win+H.'
Write-Host '  The speech settings were not reverted (turn them off in'
Write-Host '  Settings > Privacy and security > Speech if you want).'
Write-Host ''
Read-Host '  Press Enter to close'
