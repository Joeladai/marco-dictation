#Requires AutoHotkey v2.0
#SingleInstance Force

; MARCO DICTATION  (voice-latch, bilingual) - Windows Voice Typing on F9.
;
; F9        = start / stop dictation in ENGLISH.
; Shift+F9  = start / stop dictation in FRENCH.
; Esc       = close the voice bar when it's open, so you never hunt for the
;             little X. Esc is hooked ONLY while the bar is open (voiceOpen),
;             so the rest of the time Escape stays 100% normal.
;
; Dictation is OS-level: it types into the focused field, so you can scroll
; and move the mouse while talking without ever cutting the take.
;
; LANGUAGE: Windows Voice Typing follows the ACTIVE INPUT LANGUAGE, so to
; dictate in French we switch the input language first, then open the bar.
; Both languages must be in your input list (Settings > Time & language >
; Language & region) for the switch to have somewhere to land.
;
; We do not blind-press Win+Space and hope: we READ the current language with
; GetKeyboardLayout and cycle until it actually matches the target, then give
; up after a few tries rather than opening the bar in the wrong language.
; Matching is on the PRIMARY language (any English, any French), so en-US,
; en-GB, fr-FR and fr-CA all work.
;
; Why a tracked flag and not window-detection: the Win+H bar can't be probed
; reliably from a script (it won't even open without a focused field), so we
; track open/closed from the hotkey itself. Keep it in sync by closing the
; bar with Esc or the hotkey, NOT the mouse X (an X-close would leave the
; flag stuck "open"; press the hotkey twice to resync).
;
; CLAUDE CODE BONUS: while the bar is open we drop a flag file at
; %USERPROFILE%\.claude\voice\dictating.flag. If you have a notification
; script at %USERPROFILE%\.claude\notify-approval-needed.ps1 it is called
; with -Flush when dictation ends, so popups can queue instead of stealing
; focus mid-sentence. If you don't have that script, nothing happens and
; nothing breaks.

; NB: AutoHotkey v2 has no A_UserProfile built-in, it must be read from the
; environment. Using it directly gives an empty string and silently breaks
; every path below.
UserProfile  := EnvGet("USERPROFILE")
VoiceDir     := UserProfile . "\.claude\voice"
VoiceFlag    := VoiceDir . "\dictating.flag"
NotifyScript := UserProfile . "\.claude\notify-approval-needed.ps1"

; PRIMARY language IDs (low word of the HKL, masked to the primary part):
; any English = 0x09, any French = 0x0C. Exact variants (en-US vs en-GB)
; deliberately not required.
LANG_EN := 0x09
LANG_FR := 0x0C

voiceOpen := false

; --- primary input language of the focused window ---------------------------
CurrentPrimaryLang() {
    hwnd := DllCall("GetForegroundWindow", "Ptr")
    tid  := DllCall("GetWindowThreadProcessId", "Ptr", hwnd, "Ptr", 0, "UInt")
    hkl  := DllCall("GetKeyboardLayout", "UInt", tid, "Ptr")
    return hkl & 0x3FF
}

; --- cycle input languages until we REACH the target ------------------------
; Returns true only if the language actually ended up on target. Win+Space
; cycles the list, so with two entries this settles in at most one press; the
; loop keeps it correct if more languages are installed.
EnsureLang(target) {
    if (CurrentPrimaryLang() = target)
        return true
    loop 4 {
        Send("#{Space}")
        Sleep(220)
        if (CurrentPrimaryLang() = target)
            return true
    }
    return false
}

MarkDictating() {
    global VoiceDir, VoiceFlag
    try {
        if !DirExist(VoiceDir)
            DirCreate(VoiceDir)
        if FileExist(VoiceFlag)
            FileDelete(VoiceFlag)          ; rewrite so the timestamp is fresh
        FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss"), VoiceFlag)
    }
}

ClearDictating() {
    global VoiceFlag, NotifyScript
    try {
        if FileExist(VoiceFlag)
            FileDelete(VoiceFlag)
    }
    try {
        if FileExist(NotifyScript)
            Run('powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File "' NotifyScript '" -Flush', , "Hide")
    }
}

CloseBar() {
    global voiceOpen
    Send("#h")
    voiceOpen := false
    ClearDictating()
}

; Open the bar in a given language. If the language switch fails we say so
; instead of silently dictating in the wrong one (a wrong-language take looks
; identical to a broken mic until you read the garbage it typed).
OpenBar(target, label) {
    global voiceOpen
    if !EnsureLang(target) {
        TrayTip("Marco Dictation", "Could not switch the input language to " label ". Add it in Settings > Time & language > Language & region, then try again.", 1)
        return
    }
    MarkDictating()                ; hold notifications BEFORE the bar opens
    Send("#h")
    voiceOpen := true
}

; --- F9 = English -----------------------------------------------------------
F9:: {
    global voiceOpen, LANG_EN
    if (voiceOpen)
        CloseBar()
    else
        OpenBar(LANG_EN, "English")
}

; --- Shift+F9 = French ------------------------------------------------------
+F9:: {
    global voiceOpen, LANG_FR
    if (voiceOpen)
        CloseBar()
    else
        OpenBar(LANG_FR, "French")
}

; --- Esc closes the bar, but ONLY while we believe it is open ---------------
#HotIf voiceOpen
Esc:: {
    CloseBar()
    ; Esc is swallowed here (bar was open) - press Esc again for a normal
    ; Escape now that the bar is closed.
}
#HotIf
