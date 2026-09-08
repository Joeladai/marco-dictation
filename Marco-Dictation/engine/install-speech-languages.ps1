# =====================================================================
#  MARCO DICTATION - optional speech language installer  (needs admin)
#  Makes sure Windows has a speech RECOGNIZER for both English and
#  French, so F9 (English) and Shift+F9 (French) both actually work.
#
#  Why the whole language and not just the speech capability: the speech
#  pack is a SUB-feature of a language. On a machine where a language
#  exists only as a keyboard entry, "Add-WindowsCapability
#  Language.Speech~~~xx-XX" silently no-ops. Install-Language installs
#  the PARENT with every feature, which is what actually produces a
#  recognizer token.
#
#  It does NOT touch the Windows display language: your Windows stays in
#  whatever language it is in today.
#
#  Everything is written to a timestamped log so progress is PROVABLE
#  from the outside: a frozen log means a dead operation, whatever a
#  spinner shows.
# =====================================================================

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}

$LogDir  = Join-Path $env:LOCALAPPDATA 'MarcoDictation'
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
$LogPath = Join-Path $LogDir 'install-speech-languages.log'

function Log([string]$msg) {
    $line = '{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg
    try { Add-Content -Path $LogPath -Value $line -Encoding UTF8 } catch { }
    Write-Host ('  ' + $msg)
}

# Recognizer tokens are named MS-<decimal LCID>-...: 1033 = en-US,
# 2057 = en-GB, 1036 = fr-FR. Any token of the family counts.
function Get-Recognizers([string[]]$lcids) {
    try {
        $tokens = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Speech_OneCore\Recognizers\Tokens' -ErrorAction Stop |
                  Select-Object -ExpandProperty PSChildName
        $tokens | Where-Object { $tok = $_; ($lcids | Where-Object { $tok -like ('MS-' + $_ + '-*') }).Count -gt 0 }
    } catch { $null }
}

$targets = @(
    @{ Label = 'English'; Install = 'en-US'; Lcids = @('1033','2057') },
    @{ Label = 'French';  Install = 'fr-FR'; Lcids = @('1036') }
)

Log '================ START ================'

$isAdmin = ([Security.Principal.WindowsPrincipal] `
            [Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Log ("elevated = $isAdmin")
if (-not $isAdmin) {
    Log 'Not elevated, relaunching with the admin prompt...'
    Start-Process powershell.exe -Verb RunAs -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "' + $MyInvocation.MyCommand.Path + '"')
    exit 0
}

# --- remember the display language so we can prove we did not change it -----
$uiBefore = (Get-ItemProperty 'HKCU:\Control Panel\Desktop' -Name PreferredUILanguages -ErrorAction SilentlyContinue).PreferredUILanguages
Log ("display language BEFORE = " + ($uiBefore -join ','))

$allOk = $true
foreach ($t in $targets) {
    $have = Get-Recognizers $t.Lcids
    if ($have) {
        Log ($t.Label + ' recognizer ALREADY present (' + ($have -join ',') + '), nothing to install')
        continue
    }

    Log ($t.Label + ': no recognizer found. Installing language ' + $t.Install + ' (this can download a few hundred MB, watch this log, not a spinner)')
    try {
        Import-Module LanguagePackManagement -ErrorAction Stop
        Install-Language -Language $t.Install -ErrorAction Stop | Out-Null
        Log ('Install-Language ' + $t.Install + ' returned OK')
    } catch {
        Log ('Install-Language ' + $t.Install + ' FAILED: ' + $_.Exception.Message)
    }

    if (-not (Get-Recognizers $t.Lcids)) {
        Log ('Door 2: Add-WindowsCapability Language.Speech~~~' + $t.Install)
        try {
            $cap = Get-WindowsCapability -Online -Name ('Language.Speech~~~' + $t.Install + '*') -ErrorAction Stop |
                   Select-Object -First 1
            if ($cap) {
                Log ('found capability ' + $cap.Name + ' state=' + $cap.State)
                if ($cap.State -ne 'Installed') {
                    Add-WindowsCapability -Online -Name $cap.Name -ErrorAction Stop | Out-Null
                    Log 'Add-WindowsCapability returned OK'
                }
            } else {
                Log ('no Language.Speech capability for ' + $t.Install + ' offered by this image')
            }
        } catch {
            Log ('Add-WindowsCapability FAILED: ' + $_.Exception.Message)
        }
    }

    # --- verify on the DESTINATION, not on the installer's word -------------
    $rec = Get-Recognizers $t.Lcids
    if ($rec) {
        Log ('VERIFIED: ' + $t.Label + ' recognizer token = ' + ($rec -join ','))
    } else {
        Log ('NOT INSTALLED: no ' + $t.Label + ' recognizer token found')
        $allOk = $false
    }
}

$uiAfter = (Get-ItemProperty 'HKCU:\Control Panel\Desktop' -Name PreferredUILanguages -ErrorAction SilentlyContinue).PreferredUILanguages
Log ("display language AFTER  = " + ($uiAfter -join ','))

Log '================ END ================'
Write-Host ''
if ($allOk) {
    Write-Host '  DONE. Both English and French speech recognizers are present.' -ForegroundColor Green
} else {
    Write-Host '  PARTIAL. See the log above; a language may still be downloading' -ForegroundColor Yellow
    Write-Host '  or this Windows edition may not offer the pack. Log file:' -ForegroundColor Yellow
    Write-Host ('  ' + $LogPath) -ForegroundColor Yellow
}
Read-Host '  Press Enter to close'
if ($allOk) { exit 0 } else { exit 1 }
