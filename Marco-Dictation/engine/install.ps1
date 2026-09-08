# =====================================================================
#  MARCO DICTATION - installer
#  Turns F9 into a hands-free dictation switch (Windows Voice Typing).
#  No admin rights needed. Everything is installed for the current user.
#  Uninstall at any time with UNINSTALL.bat.
# =====================================================================

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}

$Src     = Split-Path -Parent $MyInvocation.MyCommand.Path          # ...\engine
$Pkg     = Split-Path -Parent $Src                                  # package root
$Target  = Join-Path $env:LOCALAPPDATA 'MarcoDictation'
$Startup = [Environment]::GetFolderPath('Startup')
if ([string]::IsNullOrWhiteSpace($Startup)) { $Startup = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup' }
New-Item -ItemType Directory -Path $Startup -Force | Out-Null
$Lnk     = Join-Path $Startup 'Marco Dictation.lnk'
$Ahk     = Join-Path $Target 'AutoHotkey64.exe'
$Script  = Join-Path $Target 'voice-latch.ahk'

# Absolute paths are too long for a console line and wrap mid-filename, which
# breaks the report's column rhythm. Show a short, still-unambiguous form.
function Short($p) {
    if (-not $p) { return $p }
    $p = $p -replace [regex]::Escape($Startup), 'Startup folder'
    $p = $p -replace [regex]::Escape($env:LOCALAPPDATA), '%LOCALAPPDATA%'
    return $p
}

$report = [System.Collections.Generic.List[object]]::new()
function Step($name, $ok, $detail) {
    $report.Add([pscustomobject]@{ Step = $name; OK = $ok; Detail = $detail })
    $mark = if ($ok) { '[ OK ]' } else { '[FAIL]' }
    # leading 2 spaces so the rows sit on the same left edge as the header.
    # A failing row is printed in red: in a wall of identical white lines a
    # bare [FAIL] marker is easy to scroll past, and it is the one thing the
    # reader must not miss.
    $colour = if ($ok) { 'Gray' } else { 'Red' }
    Write-Host ("  {0}  {1,-24} {2}" -f $mark, $name, $detail) -ForegroundColor $colour
}

Write-Host ''
Write-Host '  MARCO DICTATION' -ForegroundColor Cyan
Write-Host '  F9 = dictate in English, Shift+F9 = in French. F9 or Esc to stop.'
Write-Host '  ---------------------------------------------------------------'
Write-Host ''

# --- 0. Windows version -----------------------------------------------
$os    = Get-CimInstance Win32_OperatingSystem
$build = [int]$os.BuildNumber
if ($build -ge 22000) {
    Step 'Windows version' $true "$($os.Caption) (build $build)"
} elseif ($build -ge 19041) {
    Step 'Windows version' $true "$($os.Caption) - Win10, dictation works but is less accurate than Win11"
} else {
    Step 'Windows version' $false "$($os.Caption) - too old for Voice Typing, needs Win10 2004+ or Win11"
    Write-Host ''
    Write-Host '  Stopping here: this PC cannot run Windows Voice Typing.' -ForegroundColor Red
    Read-Host '  Press Enter to close'
    exit 1
}

# --- 1. Install folder ------------------------------------------------
New-Item -ItemType Directory -Path $Target -Force | Out-Null
Step 'Install folder' (Test-Path $Target) (Short $Target)

# --- 2. Stop any previous copy of THIS tool only ----------------------
# Deliberately NOT "kill every AutoHotkey process": the user may run other
# AutoHotkey scripts of their own. Match on our own script path instead.
function Get-OurInstances($scriptPath) {
    Get-CimInstance Win32_Process -Filter "Name='AutoHotkey64.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -and $_.CommandLine -like ('*' + $scriptPath + '*') }
}
$mine   = @(Get-OurInstances $Script)
$others = @(Get-Process -Name 'AutoHotkey64' -ErrorAction SilentlyContinue).Count - $mine.Count
$killed = 0
foreach ($p in $mine) {
    try { Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop; $killed++ } catch {}
}
if ($killed) { Start-Sleep -Milliseconds 700 }
# Kept short on purpose: this is the longest detail string in the report and
# it must not push the row past the console width. Real plurals, not "(ies)".
$prevMsg = if ($killed) { "stopped $killed old cop" + $(if ($killed -eq 1) { 'y' } else { 'ies' }) } else { 'none running' }
if ($others -gt 0) { $prevMsg += "; left $others other AutoHotkey script" + $(if ($others -eq 1) { '' } else { 's' }) + ' alone' }
Step 'Previous copy' $true $prevMsg

# --- 3. Copy the engine + the script ----------------------------------
$bundled = Join-Path $Src 'AutoHotkey64.exe'
if (Test-Path $bundled) {
    Copy-Item $bundled $Ahk -Force
} else {
    # fallback: fetch the portable engine from the official site.
    # Say so: this can take 30s on a slow line and a silent window reads as frozen.
    Write-Host '  ...  downloading the dictation engine, one moment' -ForegroundColor DarkGray
    $zip = Join-Path $env:TEMP 'ahk-v2.zip'
    $ext = Join-Path $env:TEMP 'ahk-v2-extract'
    Invoke-WebRequest -Uri 'https://www.autohotkey.com/download/ahk-v2.zip' -OutFile $zip -UseBasicParsing -TimeoutSec 120
    Remove-Item $ext -Recurse -Force -ErrorAction SilentlyContinue
    Expand-Archive $zip -DestinationPath $ext -Force
    Copy-Item (Join-Path $ext 'AutoHotkey64.exe') $Ahk -Force
}
Step 'Dictation engine' (Test-Path $Ahk) (Short $Ahk)

Copy-Item (Join-Path $Pkg 'voice-latch.ahk') $Script -Force
$lic = Join-Path $Src 'AutoHotkey-license.txt'
if (Test-Path $lic) { Copy-Item $lic (Join-Path $Target 'AutoHotkey-license.txt') -Force }
# Strip the "downloaded from the internet" mark, otherwise SmartScreen can
# block the engine when the zip was extracted with Windows Explorer.
Get-ChildItem $Target -File | Unblock-File -ErrorAction SilentlyContinue
Step 'Hotkey script' (Test-Path $Script) (Short $Script)

# --- 4. Windows speech settings (the accuracy jump) -------------------
# Online speech recognition = the cloud engine. Much more accurate than the
# offline one. Personalization = it learns your vocabulary over time.
function SetReg($path, $name, $value) {
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    New-ItemProperty -Path $path -Name $name -Value $value -PropertyType DWord -Force | Out-Null
}
SetReg 'HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' 'HasAccepted' 1
SetReg 'HKCU:\Software\Microsoft\Personalization\Settings' 'AcceptedPrivacyPolicy' 1
SetReg 'HKCU:\Software\Microsoft\InputPersonalization' 'RestrictImplicitTextCollection' 0
SetReg 'HKCU:\Software\Microsoft\InputPersonalization' 'RestrictImplicitInkCollection' 0
SetReg 'HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore' 'HarvestContacts' 1

$online = (Get-ItemProperty 'HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' -Name HasAccepted).HasAccepted
$pers   = (Get-ItemProperty 'HKCU:\Software\Microsoft\InputPersonalization' -Name RestrictImplicitTextCollection).RestrictImplicitTextCollection
Step 'Cloud speech engine' ($online -eq 1) ("online recognition = {0}" -f $(if ($online -eq 1) { 'ON' } else { 'OFF' }))
Step 'Learns your vocabulary' ($pers -eq 0) ("personalization = {0}" -f $(if ($pers -eq 0) { 'ON' } else { 'OFF' }))

# --- 5. Start with Windows -------------------------------------------
$sh = New-Object -ComObject WScript.Shell
$sc = $sh.CreateShortcut($Lnk)
$sc.TargetPath       = $Ahk
$sc.Arguments        = '"' + $Script + '"'
$sc.WorkingDirectory = $Target
$sc.Description      = 'Marco Dictation - F9 toggles Windows Voice Typing'
$sc.Save()
Step 'Starts with Windows' (Test-Path $Lnk) (Short $Lnk)

# --- 6. Launch it now -------------------------------------------------
Start-Process -FilePath $Ahk -ArgumentList ('"' + $Script + '"') -WorkingDirectory $Target
Start-Sleep -Seconds 2
$running = @(Get-OurInstances $Script)
Step 'Running now' ($running.Count -eq 1) ("{0} copy of this tool running" -f $running.Count)

# --- 7. Verdict -------------------------------------------------------
$failed = @($report | Where-Object { -not $_.OK })
Write-Host ''
Write-Host '  ---------------------------------------------------------------'
if ($failed.Count -eq 0) {
    Write-Host '  INSTALLED. F9 is live right now.' -ForegroundColor Green
    Write-Host ''
    Write-Host '  Try it: click inside any text box (Notepad, a browser, an email),'
    Write-Host '  press F9, and start talking. Press F9 again (or Esc) to stop.'
    Write-Host '  Shift+F9 does the same in French.'
    Write-Host ''
    Write-Host '  Both languages need to be in your input list (Settings > Time &'
    Write-Host '  language > Language & region). If one dictates garbage, run'
    Write-Host '  "INSTALL-SPEECH-LANGUAGES (optional).bat" once.'
    Write-Host '  Gear icon on the microphone bar = automatic punctuation.'
} else {
    Write-Host ('  PARTIAL INSTALL - {0} step(s) failed:' -f $failed.Count) -ForegroundColor Yellow
    $failed | ForEach-Object { Write-Host ('   - {0}: {1}' -f $_.Step, $_.Detail) -ForegroundColor Yellow }
    Write-Host '  Send this screen to Joseph, he will fix it.'
}
Write-Host '  ---------------------------------------------------------------'
Write-Host ''
Read-Host '  Press Enter to close'
