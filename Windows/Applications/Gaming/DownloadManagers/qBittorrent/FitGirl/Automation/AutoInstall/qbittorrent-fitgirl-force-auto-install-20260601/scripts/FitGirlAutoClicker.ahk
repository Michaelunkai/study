#Requires AutoHotkey v2.0
; Safe FitGirl/Inno dialog helper for qBittorrent FitGirl Force AutoInstall.
; Run with --selftest to verify syntax without clicking anything.

if (A_Args.Length >= 1 && A_Args[1] = "--selftest") {
    FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " SELFTEST OK`n", A_Temp "\qbit-fitgirl-ahk-selftest.log")
    ExitApp(0)
}

SetTitleMatchMode 2
Persistent
LogFile := "F:\Downloads\.fitgirl_tmp\qbit-force-auto-install\fitgirl-ahk-watchdog.log"
DirCreate "F:\Downloads\.fitgirl_tmp\qbit-force-auto-install"

Log(msg) {
    global LogFile
    FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " " msg "`n", LogFile)
}

GetSecondaryBounds() {
    try {
        count := MonitorGetCount()
        primary := MonitorGetPrimary()
        Loop count {
            if (A_Index != primary) {
                MonitorGet(A_Index, &l, &t, &r, &b)
                return {L:l, T:t, R:r, B:b, W:r-l, H:b-t}
            }
        }
    } catch as e {
    }
    return false
}

MoveToSecondMonitor(hwnd) {
    b := GetSecondaryBounds()
    if (!b)
        return false
    try {
        WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
        nw := Min(w ? w : 1000, b.W - 80)
        nh := Min(h ? h : 700, b.H - 80)
        nx := b.L + 40
        ny := b.T + 40
        if (x < b.L || x > b.R || y < b.T || y > b.B) {
            WinMove(nx, ny, nw, nh, "ahk_id " hwnd)
            Log("MOVE_TO_MONITOR2 hwnd=" hwnd " x=" nx " y=" ny " w=" nw " h=" nh)
        }
        return true
    } catch as e {
        Log("MOVE_ERR hwnd=" hwnd " error=" e.Message)
        return false
    }
}


SafeClickText(winTitle, labels*) {
    for label in labels {
        try {
            ctrls := WinGetControls(winTitle)
            for ctrl in ctrls {
                ; Only click actual buttons. Never click static text just because it contains words like Next/Install.
                if (!RegExMatch(ctrl, "i)(Button|TNewButton)"))
                    continue
                txt := ""
                try txt := ControlGetText(ctrl, winTitle)
                norm := StrLower(Trim(StrReplace(txt, "&", "")))
                wanted := StrLower(label)
                if (norm = wanted || (StrLen(wanted) > 3 && InStr(norm, wanted))) {
                    WinActivate(winTitle)
                    Sleep(80)
                    ControlClick(ctrl, winTitle)
                    Sleep(80)
                    Send("{Enter}")
                    Log("CLICK_BUTTON_ENTER title=" winTitle " ctrl=" ctrl " text=" txt)
                    return true
                }
            }
        } catch as e {
        }
    }
    return false
}

WindowTextContains(winTitle, needles*) {
    text := ""
    try {
        ctrls := WinGetControls(winTitle)
        for ctrl in ctrls {
            try text .= "`n" ControlGetText(ctrl, winTitle)
        }
    } catch as e {
    }
    low := StrLower(text "`n" WinGetTitle(winTitle))
    for n in needles {
        if InStr(low, StrLower(n))
            return true
    }
    return false
}

HandleOptionalDownloadError(winTitle) {
    ; Legacy entry point kept for older wrappers: delegate to the guarded handler so
    ; normal FitGirl wizard pages are never cancelled just because they mention websites.
    return HandleOptionalOnlineFailure(winTitle)
}

ClearOptionalOnlineSelections(winTitle) {
    ; Disable optional online dependency downloads before pressing Next, so cert/TLS failures cannot loop.
    changed := false
    try {
        ctrls := WinGetControls(winTitle)
        for ctrl in ctrls {
            txt := ""
            try txt := ControlGetText(ctrl, winTitle)
            if (txt = "")
                continue
            if (RegExMatch(ctrl, "i)(Button|Check|TNewCheck|TCheck|List)") && RegExMatch(txt, "i)(download|additional files|DirectX|Visual C|Visual C\+\+|VC\+\+|vcredist|vc_redist|redistributable|redist|web setup)") && !RegExMatch(txt, "i)^(Next|Install|Finish|OK|Yes|No|Cancel|Retry|Details|Back)")) {
                try {
                    ControlSetChecked(0, ctrl, winTitle)
                    Log("UNCHECK_OPTIONAL_ONLINE title=" winTitle " ctrl=" ctrl " text=" txt)
                    changed := true
                } catch as e {
                }
            }
        }
    } catch as e {
    }
    return changed
}

ForceInstallPath(winTitle) {
    ; If an installer shows a destination folder edit box, push it back to the target marker from its setup folder.
    try {
        pid := WinGetPID(winTitle)
        query := ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process where ProcessId=" pid)
        for proc in query {
            exe := proc.ExecutablePath
            if (!exe)
                return
            SplitPath exe,, &dir
            marker := dir "\.qbit-force-install-target.txt"
            if (!FileExist(marker))
                return
            data := FileRead(marker)
            if RegExMatch(data, "im)install_dir=(.+)$", &m) {
                target := Trim(m[1])
                ctrls := WinGetControls(winTitle)
                for ctrl in ctrls {
                    txt := ""
                    try txt := ControlGetText(ctrl, winTitle)
                    if (RegExMatch(txt, "i)^[A-Z]:\\") || InStr(txt, "Program Files")) {
                        try ControlSetText(target, ctrl, winTitle)
                        Log("SETDIR title=" winTitle " ctrl=" ctrl " target=" target)
                    }
                }
            }
        }
    } catch as e {
    }
}

GetWindowTextBlob(winTitle) {
    blob := ""
    try blob .= WinGetTitle(winTitle) "`n"
    try blob .= WinGetText(winTitle) "`n"
    try {
        ctrls := WinGetControls(winTitle)
        for ctrl in ctrls {
            txt := ""
            try txt := ControlGetText(ctrl, winTitle)
            if (txt != "")
                blob .= ctrl ": " txt "`n"
        }
    } catch as e {
    }
    return blob
}

IsHardFailureText(text) {
    t := StrLower(text)
    return RegExMatch(t, "(isdone|unarc|checksum|crc|archive.*corrupt|corrupt|not enough disk|disk full|write error|decompression failed|failed to unpack|file .* missing)")
}

HandleExitSetupConfirmation(winTitle) {
    text := GetWindowTextBlob(winTitle)
    low := StrLower(text)
    if (RegExMatch(low, "(exit setup\?|setup is not complete|program will not be installed)") && !IsHardFailureText(text)) {
        Log("EXIT_SETUP_CONFIRMATION title=" WinGetTitle(winTitle))
        if SafeClickText(winTitle, "no") {
            Log("EXIT_SETUP_CONFIRMATION_HANDLED action=no")
            return true
        }
    }
    return false
}

HandleOptionalOnlineFailure(winTitle) {
    ; FitGirl/Inno sometimes loops forever trying optional online DirectX/VC++/redist downloads.
    ; Guard certificate/TLS/revocation/download-failed popups while preserving real corruption/disk failures.
    text := GetWindowTextBlob(winTitle)
    low := StrLower(text)
    titleLow := StrLower(WinGetTitle(winTitle))
    fail := RegExMatch(titleLow "`n" low, "(cannot connect|can't connect|download failed|download error|supplied certificate is invalid|certificate (is )?(invalid|not trusted|expired|revoked)|certificate.*(invalid|trust|verify|revocation|chain)|tls|ssl|schannel|winhttp|revocation|unable to verify|connection failed|failed to connect|server returned)")
    optional := RegExMatch(low, "(additional files|optional|directx|visual c|visual c\+\+|vc\+\+|redistributable|redist|web download|online component|runtime component|download (additional|directx|visual|redist|component))")
    ; Some Inno optional-download popups only show title=Download failed/Error/Certificate plus certificate text, without naming DirectX/VC++.
    certOnlyOptionalPopup := fail && RegExMatch(titleLow, "(download failed|cannot connect|error|certificate|security warning|invalid certificate|supplied certificate)") && RegExMatch(low "`n" titleLow, "(certificate|tls|ssl|revocation|unable to verify|download failed|invalid certificate|supplied certificate)")
    ; Do not treat normal FitGirl intro/legal pages as failures just because they mention download sites.
    normalWizard := RegExMatch(low, "(welcome to the .* setup wizard|please read the following important information|click next to continue)") && !RegExMatch(low, "(downloading additional files|status:\s*cannot connect|status:\s*download failed|certificate)")
    if (!fail || (!(optional || certOnlyOptionalPopup)) || normalWizard || IsHardFailureText(text))
        return false
    compact := RegExReplace(text, "\s+", " ")
    if (StrLen(compact) > 650)
        compact := SubStr(compact, 1, 650)
    Log("OPTIONAL_ONLINE_FAILURE title=" WinGetTitle(winTitle) " text=" compact)
    ; On full Setup pages, first clear optional online checkboxes and never press the installer-wide Cancel button.
    if RegExMatch(titleLow, "^setup") {
        ClearOptionalOnlineSelections(winTitle)
        if SafeClickText(winTitle, "skip", "no", "ok", "continue", "ignore") {
            Log("OPTIONAL_ONLINE_FAILURE_HANDLED action=setup-safe-button")
            return true
        }
        return false
    }
    ; On the small Download failed/Error popup, Cancel/OK belongs to the popup, not the installer wizard.
    if SafeClickText(winTitle, "cancel", "ok", "skip", "no", "continue", "close", "finish") {
        Log("OPTIONAL_ONLINE_FAILURE_HANDLED action=popup-button")
        return true
    }
    try {
        WinActivate(winTitle)
        Sleep(80)
        ControlSend("{Esc}",, winTitle)
        Sleep(80)
        Log("OPTIONAL_ONLINE_FAILURE_HANDLED action=popup-escape")
        return true
    } catch as e {
        Log("OPTIONAL_ONLINE_FAILURE_HANDLE_ERR error=" e.Message)
    }
    return false
}

Tick() {
    titles := ["Folder Exists", "Exit Setup", "Cannot connect", "Download failed", "Downloading additional files", "The supplied certificate is invalid", "Invalid certificate", "Security Warning", "TLS", "SSL", "Error", "Certificate", "Select Setup Language", "Setup -", "Setup", "FitGirl", "QuickSFV", "ISDone", "Unarc.dll", "Finalization"]
    for pattern in titles {
        try ids := WinGetList(pattern)
        catch
            continue
        for hwnd in ids {
            title := WinGetTitle("ahk_id " hwnd)
            if (title = "")
                continue
            MoveToSecondMonitor(hwnd)
            ForceInstallPath("ahk_id " hwnd)
            ClearOptionalOnlineSelections("ahk_id " hwnd)
            if HandleExitSetupConfirmation("ahk_id " hwnd)
                continue
            if HandleOptionalOnlineFailure("ahk_id " hwnd)
                continue
            if WindowTextContains("ahk_id " hwnd, "downloading additional files", "please wait, while setup downloading")
                continue
            if SafeClickText("ahk_id " hwnd, "ok", "yes", "next", "install", "continue", "finish", "close")
                continue
            ; Fallback for language/Next-style dialogs where button text is inaccessible.
            if (InStr(StrLower(title), "select setup language") || InStr(StrLower(title), "setup -")) {
                try ControlSend("{Enter}",, "ahk_id " hwnd)
                Log("ENTER title=" title)
            }
        }
    }
}

Log("WATCHDOG START")
SetTimer(Tick, 1000)
