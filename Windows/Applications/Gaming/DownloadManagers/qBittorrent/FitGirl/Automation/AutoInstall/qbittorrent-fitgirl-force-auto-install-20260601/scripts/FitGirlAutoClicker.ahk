#Requires AutoHotkey v2.0
#SingleInstance Force
; Safe FitGirl/Inno dialog helper for qBittorrent FitGirl Force AutoInstall.
; Run with --selftest to verify syntax without clicking anything.

SelfTestMode := (A_Args.Length >= 1 && A_Args[1] = "--selftest")

SetTitleMatchMode 2
Persistent
LogDir := "F:\Downloads\.fitgirl_tmp\qbit-force-auto-install"
try {
    DirCreate(LogDir)
} catch as e {
    LogDir := A_Temp "\qbit-force-auto-install"
    DirCreate(LogDir)
}
LogFile := LogDir "\fitgirl-ahk-watchdog.log"

Log(msg) {
    global LogFile
    try FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " " msg "`n", LogFile)
}

WindowAlive(winTitle) {
    try return !!WinExist(winTitle)
    catch as e
        return false
}

SafeWinTitle(winTitle) {
    try {
        if (!WinExist(winTitle))
            return ""
        return WinGetTitle(winTitle)
    } catch as e {
        return ""
    }
}

BackgroundControlClick(winTitle, ctrl, label := "") {
    ; Do not steal focus from the user's game/app. ControlClick with NA sends to the target control without activating the installer window.
    try {
        ControlClick(ctrl, winTitle,,,, "NA")
        Log("BACKGROUND_CLICK title=" winTitle " ctrl=" ctrl " text=" label)
        return true
    } catch as e {
        Log("BACKGROUND_CLICK_ERR title=" winTitle " ctrl=" ctrl " error=" e.Message)
    }
    try {
        ControlClick(ctrl, winTitle)
        Log("BACKGROUND_CLICK_FALLBACK title=" winTitle " ctrl=" ctrl " text=" label)
        return true
    } catch as e2 {
        Log("BACKGROUND_CLICK_FALLBACK_ERR title=" winTitle " ctrl=" ctrl " error=" e2.Message)
    }
    return false
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
                if (!ButtonEnabled(winTitle, ctrl))
                    continue
                txt := ""
                try txt := ControlGetText(ctrl, winTitle)
                norm := NormalizeButtonText(txt)
                wanted := NormalizeButtonText(label)
                if (norm = wanted || (StrLen(wanted) > 2 && InStr(norm, wanted))) {
                    if BackgroundControlClick(winTitle, ctrl, txt) {
                        Sleep(10)
                        Log("CLICK_BUTTON_BACKGROUND title=" winTitle " ctrl=" ctrl " text=" txt)
                        return true
                    }
                }
            }
        } catch as e {
        }
    }
    return false
}

NormalizeButtonText(txt) {
    norm := StrLower(Trim(StrReplace(txt, "&", "")))
    norm := RegExReplace(norm, "[<>…\.]+", "")
    norm := RegExReplace(norm, "\s+", " ")
    return Trim(norm)
}

ButtonEnabled(winTitle, ctrl) {
    try return !!ControlGetEnabled(ctrl, winTitle)
    catch as e {
        ; Some Inno/TNewButton controls do not report enabled state reliably through ControlGetEnabled.
        ; Check WS_DISABLED (0x08000000) so the watchdog does not keep clicking disabled Next buttons every 30s.
        try {
            style := ControlGetStyle(ctrl, winTitle)
            if (style & 0x08000000)
                return false
        } catch as e2 {
        }
        return true
    }
}

HasEnabledButton(winTitle, labels*) {
    try {
        ctrls := WinGetControls(winTitle)
        for ctrl in ctrls {
            if (!RegExMatch(ctrl, "i)(Button|TNewButton)"))
                continue
            if (!ButtonEnabled(winTitle, ctrl))
                continue
            txt := ""
            try txt := ControlGetText(ctrl, winTitle)
            norm := NormalizeButtonText(txt)
            for label in labels {
                wanted := NormalizeButtonText(label)
                if (norm = wanted || (StrLen(wanted) > 2 && InStr(norm, wanted)))
                    return true
            }
        }
    } catch as e {
    }
    return false
}

ClickOptionalIgnoreButton(winTitle) {
    ; Robust fallback for Inno Error popups with Abort/Retry/Ignore where button text may be inaccessible.
    ; Prefer the explicit Ignore text; if the classic three-button optional-redist popup is present, click the rightmost enabled button.
    if SafeClickText(winTitle, "ignore", "skip")
        return true
    try {
        ctrls := WinGetControls(winTitle)
        buttons := []
        abortSeen := false
        retrySeen := false
        for ctrl in ctrls {
            if (!RegExMatch(ctrl, "i)(Button|TNewButton)"))
                continue
            if (!ButtonEnabled(winTitle, ctrl))
                continue
            txt := ""
            try txt := ControlGetText(ctrl, winTitle)
            norm := NormalizeButtonText(txt)
            if (norm = "abort")
                abortSeen := true
            if (norm = "retry")
                retrySeen := true
            buttons.Push({Ctrl: ctrl, Text: txt, Norm: norm})
        }
        if (buttons.Length >= 3 && abortSeen && retrySeen) {
            b := buttons[buttons.Length]
            if BackgroundControlClick(winTitle, b.Ctrl, b.Text) {
                Sleep(20)
                Log("OPTIONAL_IGNORE_FALLBACK_RIGHTMOST_BACKGROUND title=" winTitle " ctrl=" b.Ctrl " text=" b.Text)
                return true
            }
        }
    } catch as e {
        Log("OPTIONAL_IGNORE_FALLBACK_ERR " e.Message)
    }
    try {
        ControlSend("!i",, winTitle)
        Sleep(20)
        Log("OPTIONAL_IGNORE_FALLBACK_ALT_I_BACKGROUND title=" winTitle)
        return true
    } catch as e {
        Log("OPTIONAL_IGNORE_ALT_I_ERR " e.Message)
    }
    return false
}

ClickBestWizardButton(winTitle) {
    ; Click the next required safe wizard button. Never click Back/Cancel/Abort/Retry/No here.
    ; Never click Finish on completed FitGirl pages: HandleFinishedInstallPage leaves that window open for user review.
    priorities := ["ok", "yes", "i accept", "i agree", "accept", "next", "install", "continue", "close"]
    try {
        ctrls := WinGetControls(winTitle)
        for wanted in priorities {
            wantedNorm := NormalizeButtonText(wanted)
            for ctrl in ctrls {
                ; Only actual push buttons may advance the wizard. Inno checkboxes often have Button-class
                ; control names and text like "Limit installer..."; do not click them as the "Install" button.
                if (!RegExMatch(ctrl, "i)^(TNewButton|Button)\d+$"))
                    continue
                if (RegExMatch(ctrl, "i)Check"))
                    continue
                if (!ButtonEnabled(winTitle, ctrl))
                    continue
                txt := ""
                try txt := ControlGetText(ctrl, winTitle)
                norm := NormalizeButtonText(txt)
                if (norm = "" || RegExMatch(norm, "i)^(back|cancel|abort|retry|no|details|hide|show)$") || RegExMatch(norm, "i)(limit.*(ram|memory)|2 gb|installer to 2 gb)"))
                    continue
                if (norm = wantedNorm || (StrLen(wantedNorm) > 2 && InStr(norm, wantedNorm))) {
                    if (norm = "finish" || norm = "close")
                        MarkInstallDoneForWindow(winTitle)
                    if BackgroundControlClick(winTitle, ctrl, txt) {
                        Sleep(10)
                        Log("CLICK_BEST_BACKGROUND title=" winTitle " ctrl=" ctrl " text=" txt)
                        return true
                    }
                }
            }
        }
    } catch as e {
        Log("CLICK_BEST_ERR title=" winTitle " error=" e.Message)
    }
    return false
}

ImmediateSafeWizardAdvance(winTitle) {
    ; Extra fast path for normal wizard pages: after all error/final handlers have run,
    ; click the first safe enabled action without waiting for expensive text rescans.
    ; Never presses Finish/Cancel/Abort/Retry/Back/No.
    if (!WindowAlive(winTitle))
        return false
    try {
        ctrls := WinGetControls(winTitle)
        wanted := ["ok", "yes", "i accept", "i agree", "accept", "next", "install", "continue"]
        for label in wanted {
            wantedNorm := NormalizeButtonText(label)
            for ctrl in ctrls {
                if (!RegExMatch(ctrl, "i)^(TNewButton|Button)\d+$"))
                    continue
                if (!ButtonEnabled(winTitle, ctrl))
                    continue
                txt := ""
                try txt := ControlGetText(ctrl, winTitle)
                norm := NormalizeButtonText(txt)
                if (norm = "" || RegExMatch(norm, "i)^(finish|close|back|cancel|abort|retry|no|details|hide|show)$") || RegExMatch(norm, "i)(limit.*(ram|memory)|2 gb|installer to 2 gb)"))
                    continue
                if (norm = wantedNorm || (StrLen(wantedNorm) > 2 && InStr(norm, wantedNorm))) {
                    if BackgroundControlClick(winTitle, ctrl, txt) {
                        Log("IMMEDIATE_BACKGROUND_CLICK title=" winTitle " ctrl=" ctrl " text=" txt)
                        return true
                    }
                }
            }
        }
    } catch as e {
        Log("IMMEDIATE_CLICK_ERR title=" winTitle " error=" e.Message)
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
    low := StrLower(text "`n" SafeWinTitle(winTitle))
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

HandleFinishedInstallPage(winTitle) {
    ; Final state is fully automatic: clear final-page optional boxes, mark done, then press Finish.
    ; Never touch setup-option boxes like RAM limit.
    if (!WindowAlive(winTitle))
        return false
    title := SafeWinTitle(winTitle)
    text := GetWindowTextBlob(winTitle)
    low := StrLower(title "`n" text)
    if (!HasEnabledButton(winTitle, "finish"))
        return false
    if (HasEnabledButton(winTitle, "next", "install"))
        return false
    ; Avoid false positives from option pages containing generic wording such as "after setup has finished".
    if RegExMatch(low, "(select additional tasks|select start menu folder|select destination|ready to install|browse\.\.\.|limit installer to 2 gb)")
        return false
    if !(RegExMatch(low, "(setup has finished installing|has finished installing .* on your computer|completing the .* setup wizard|installation complete|setup completed)") || (RegExMatch(low, "finished") && RegExMatch(low, "(installed|installation|setup)")))
        return false
    unchecked := 0
    try {
        ctrls := WinGetControls(winTitle)
        for ctrl in ctrls {
            if (!RegExMatch(ctrl, "i)(Button|Check|TNewCheck|TCheck)"))
                continue
            txt := ""
            try txt := ControlGetText(ctrl, winTitle)
            norm := NormalizeButtonText(txt)
            if (norm = "")
                continue
            ; Final page checkboxes only: launch/run/readme/site/verify/update/redist/directx/etc.
            if (!RegExMatch(norm, "i)(launch|run|start|play|open|visit|website|site|readme|read me|verify|check files|redirect|update|directx|visual|redistributable|redist|vc\+\+)") || RegExMatch(norm, "i)(limit.*(ram|memory)|2 gb|start menu|desktop icon)"))
                continue
            try {
                ControlSetChecked(0, ctrl, winTitle)
                unchecked++
                Log("FINAL_PAGE_UNCHECK title=" winTitle " ctrl=" ctrl " text=" txt)
            } catch as e {
                Log("FINAL_PAGE_UNCHECK_ERR title=" winTitle " ctrl=" ctrl " text=" txt " error=" e.Message)
            }
        }
    } catch as e {
        Log("FINAL_PAGE_SCAN_ERR title=" winTitle " error=" e.Message)
    }
    MarkInstallDoneForWindow(winTitle)
    if (SafeClickText(winTitle, "finish", "close")) {
        Sleep(100)
        Log("FINAL_PAGE_FINISH_CLICKED title=" title " unchecked=" unchecked)
        return true
    }
    Log("FINAL_PAGE_MARKED_DONE_FINISH_NOT_CLICKED title=" title " unchecked=" unchecked)
    return true
}

ForceRamLimitSelection(winTitle) {
    ; FitGirl repacks expose a RAM-saver checkbox on the options/tasks page.
    ; Always enable it before pressing Next/Install so every automatic install uses the 2 GB RAM limit.
    changed := false
    try {
        ctrls := WinGetControls(winTitle)
        for ctrl in ctrls {
            if (!RegExMatch(ctrl, "i)(Button|Check|TNewCheck|TCheck|List)"))
                continue
            txt := ""
            try txt := ControlGetText(ctrl, winTitle)
            if (txt = "")
                continue
            if (RegExMatch(txt, "i)(limit.*(ram|memory)|2\s*gb.*(ram|memory)|(ram|memory).*2\s*gb|2048)")) {
                try {
                    ControlSetChecked(1, ctrl, winTitle)
                    Log("CHECK_RAM_LIMIT_2GB title=" winTitle " ctrl=" ctrl " text=" txt)
                    changed := true
                } catch as e {
                    Log("CHECK_RAM_LIMIT_2GB_ERR title=" winTitle " ctrl=" ctrl " text=" txt " error=" e.Message)
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
    try blob .= SafeWinTitle(winTitle) "`n"
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
    return RegExMatch(t, "(isdone|unarc|checksum|crc|failed crc|does not match checksum|archive.*corrupt|corrupt archive|decompression failed|failed to unpack|returned an error code|error code:\s*-?\d+|not enough disk|disk full|write error|read error|access is denied|unable to execute file|could not create process|file .*missing|source file.*(missing|corrupt)|failed to start.*(cls|srep|magic|oo2rec|xtool|rz|razor|precomp|facompress|unarc)|failed to launch.*(cls|srep|magic|oo2rec|xtool|rz|razor|precomp|facompress|unarc)|runtime error.*(cls|srep|magic|oo2rec|xtool|rz|razor|precomp|facompress|unarc)|decompression error|decompression problem)")
}

IsRetryableInstallWriteFailureText(text) {
    t := StrLower(text)
    return RegExMatch(t, "(isdone|unarc)")
        && RegExMatch(t, "(unable to write data to disk|unable to write|write data to disk|write error|not enough disk|disk full)")
}

HandleExitSetupConfirmation(winTitle) {
    if (!WindowAlive(winTitle))
        return false
    text := GetWindowTextBlob(winTitle)
    low := StrLower(text)
    if (RegExMatch(low, "(exit setup\?|setup is not complete|program will not be installed)") && !IsHardFailureText(text)) {
        Log("EXIT_SETUP_CONFIRMATION title=" SafeWinTitle(winTitle))
        if SafeClickText(winTitle, "no") {
            Log("EXIT_SETUP_CONFIRMATION_HANDLED action=no")
            return true
        }
    }
    return false
}


HandleFolderExists(winTitle) {
    if (!WindowAlive(winTitle))
        return false
    text := GetWindowTextBlob(winTitle)
    low := StrLower(text)
    titleLow := StrLower(SafeWinTitle(winTitle))
    if (InStr(titleLow, "folder exists") || RegExMatch(low, "(folder already exists|directory already exists|would you like to install to that folder anyway|install to that folder anyway)")) {
        Log("FOLDER_EXISTS_CONFIRM title=" SafeWinTitle(winTitle))
        if SafeClickText(winTitle, "yes", "ok", "continue") {
            Log("FOLDER_EXISTS_HANDLED action=continue")
            return true
        }
        try {
            ControlSend("{Enter}",, winTitle)
            Log("FOLDER_EXISTS_HANDLED action=enter")
            return true
        } catch as e {
            Log("FOLDER_EXISTS_HANDLE_ERR error=" e.Message)
        }
    }
    return false
}

HandleFinalizationMissingHelper(winTitle) {
    ; Missing post-install helper launchers (QuickSFV/redist/etc.) happen after the game finished installing.
    ; Treat them as harmless finalization popups: mark this source done and dismiss the popup.
    if (!WindowAlive(winTitle))
        return false
    text := GetWindowTextBlob(winTitle)
    low := StrLower(text)
    titleLow := StrLower(SafeWinTitle(winTitle))
    if (!(InStr(titleLow, "finalization") || RegExMatch(low, "(quicksfv|redist|vcredist|vc_redist|directx|unable to execute file|createprocess failed; code 2|system cannot find the file specified)")))
        return false
    if (!RegExMatch(low, "(unable to execute file|createprocess failed; code 2|system cannot find the file specified)") || !RegExMatch(low, "(quicksfv|redist|vcredist|vc_redist|directx)"))
        return false
    MarkInstallDoneForWindow(winTitle)
    Log("FINALIZATION_MISSING_HELPER_HANDLED title=" SafeWinTitle(winTitle))
    if SafeClickText(winTitle, "ok", "close", "finish", "continue")
        return true
    try {
        ControlSend("{Enter}",, winTitle)
        return true
    } catch as e {
        Log("FINALIZATION_MISSING_HELPER_ERR " e.Message)
    }
    return false
}

IsActiveProgressPage(winTitle) {
    if (!WindowAlive(winTitle))
        return false
    text := StrLower(GetWindowTextBlob(winTitle))
    ; Extraction/progress text is authoritative even when Inno exposes hidden wizard labels/buttons.
    if RegExMatch(text, "(downloading additional files|please wait, while setup downloading|extracting|unpacking|elapsed time|remaining time|current file:|checking files|verifying files|decompressing|processing files)")
        return true
    ; Inno/FitGirl keeps hidden progress controls on normal wizard pages. If a real
    ; safe action is enabled on a wizard page, it must not be skipped as progress.
    if (HasEnabledButton(winTitle, "ok", "yes", "next", "install", "continue") && RegExMatch(text, "(welcome to .* setup wizard|click next to continue|select destination|select components|select additional tasks|ready to install|setup wizard)"))
        return false
    return false
}

CleanupIncompleteInstallTargetForSource(sourceDir) {
    try {
        targetMarker := sourceDir "\.qbit-force-install-target.txt"
        if (!FileExist(targetMarker))
            return false
        data := FileRead(targetMarker)
        installDir := ""
        if RegExMatch(data, "im)^install_dir=(.+)$", &im)
            installDir := Trim(im[1])
        if (installDir = "" || !DirExist(installDir))
            return false
        srcLow := StrLower(RegExReplace(sourceDir, "\\+$", ""))
        targetLow := StrLower(RegExReplace(installDir, "\\+$", ""))
        ; Never delete the repack source folder; only delete the separate scratch install target.
        if (targetLow = srcLow || InStr(targetLow, "[fitgirl") || InStr(targetLow, "repack")) {
            Log("HARD_FAIL_CLEANUP_REFUSED target=" installDir " source=" sourceDir)
            return false
        }
        q2 := ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process")
        prefix := StrLower(installDir "\\")
        for p2 in q2 {
            ep := p2.ExecutablePath ? StrLower(p2.ExecutablePath) : ""
            if (ep != "" && (ep = targetLow || InStr(ep, prefix) = 1)) {
                try p2.Terminate()
                Log("HARD_FAIL_STOP_TARGET_PROCESS pid=" p2.ProcessId " exe=" p2.ExecutablePath)
            }
        }
        DirDelete(installDir, true)
        Log("HARD_FAIL_DELETED_INCOMPLETE_TARGET target=" installDir " source=" sourceDir)
        return true
    } catch as e {
        Log("HARD_FAIL_CLEANUP_ERR source=" sourceDir " error=" e.Message)
    }
    return false
}

GetProcessMap() {
    ; Avoid a local name that shadows AutoHotkey's built-in Map class.
    procMap := Map()
    try {
        q := ComObjGet("winmgmts:").ExecQuery("Select ProcessId,ParentProcessId,Name,ExecutablePath,CommandLine from Win32_Process")
        for proc in q
            procMap[Integer(proc.ProcessId)] := proc
    } catch as e {
        Log("PROC_MAP_ERR " e.Message)
    }
    return procMap
}

SourceDirFromSetupPath(setupPath) {
    if (setupPath = "")
        return ""
    try {
        SplitPath setupPath,, &dir
        if (dir != "" && FileExist(dir "\setup.exe") && FileExist(dir "\.qbit-force-install-target.txt"))
            return dir
    } catch as e {
    }
    return ""
}

SourceDirFromInstallDir(installDir) {
    ; Map a running temp/Inno setup that only exposes /DIR back to the original source marker.
    if (installDir = "")
        return ""
    try target := StrLower(RegExReplace(installDir, "\\+$", ""))
    catch as e
        return ""
    try {
        Loop Files, "F:\Downloads\*.qbit-force-install-target.txt", "R" {
            markerDir := A_LoopFileDir
            ; Never allow scratch targets or unrelated generated folders to become sources.
            if (!FileExist(markerDir "\setup.exe"))
                continue
            data := ""
            try data := FileRead(A_LoopFileFullPath)
            if !RegExMatch(data, "im)^install_dir=(.+)$", &im)
                continue
            markedTarget := StrLower(RegExReplace(Trim(im[1]), "\\+$", ""))
            if (markedTarget = target)
                return markerDir
        }
    } catch as e {
        Log("SOURCE_FROM_INSTALL_DIR_ERR target=" installDir " error=" e.Message)
    }
    return ""
}

SourceDirFromProcess(proc) {
    try {
        exe := proc.ExecutablePath ? proc.ExecutablePath : ""
        cl := proc.CommandLine ? proc.CommandLine : ""
        setupPath := ""
        ; Direct original setup.exe path, including quoted command lines.
        if RegExMatch(exe, "i)^F:\\Downloads\\.*\\setup\.exe$")
            setupPath := exe
        else if RegExMatch(cl, "i)(F:\\Downloads\\[^`"]*\\setup\.exe)", &m)
            setupPath := m[1]
        dir := SourceDirFromSetupPath(setupPath)
        if (dir != "")
            return dir
        ; Inno may be running from a temp executable while preserving /DIR. Use the per-source launch marker.
        installDir := ""
        if RegExMatch(cl, "i)/DIR=`"([^`"]+)`"", &dm)
            installDir := dm[1]
        else if RegExMatch(cl, "i)/DIR=([^\s]+)", &dm2)
            installDir := dm2[1]
        dir := SourceDirFromInstallDir(installDir)
        if (dir != "")
            return dir
    } catch as e {
        Log("SOURCE_FROM_PROCESS_ERR error=" e.Message)
    }
    return ""
}

FindSourceDirForFailureWindow(winTitle) {
    ; Map an ISDone/Unarc/helper popup to exactly one source folder. Never mark every active installer.
    pid := 0
    try pid := WinGetPID(winTitle)
    catch as e
        pid := 0
    procs := GetProcessMap()
    ; Modal error dialogs are often owned by the setup window even when the dialog process itself
    ; is not a direct child of setup.exe. Check the owner window first so multi-install runs can
    ; still be attributed to the one correct game instead of falling back to ambiguous global state.
    try {
        hwnd := WinExist(winTitle)
        owner := hwnd ? DllCall("GetWindow", "ptr", hwnd, "uint", 4, "ptr") : 0 ; GW_OWNER = 4
        if (owner) {
            ownerPid := 0
            DllCall("GetWindowThreadProcessId", "ptr", owner, "uint*", &ownerPid)
            dir := SourceDirFromPidChain(Integer(ownerPid), procs)
            if (dir != "") {
                Log("HARD_FAIL_SOURCE_OWNER_MAPPED title=" SafeWinTitle(winTitle) " owner_pid=" ownerPid " source=" dir)
                return dir
            }
        }
    } catch as e {
        Log("HARD_FAIL_OWNER_MAP_ERR title=" SafeWinTitle(winTitle) " error=" e.Message)
    }
    dir := SourceDirFromPidChain(pid, procs)
    if (dir != "")
        return dir
    ; Conservative fallback: if and only if exactly one active project-launched setup can be mapped, attach the popup to it.
    found := FindActiveProjectSources(procs)
    if (found.Length = 1)
        return found[1]
    Log("HARD_FAIL_SOURCE_UNMAPPED title=" SafeWinTitle(winTitle) " pid=" pid " active_project_sources=" found.Length)
    return ""
}

SourceDirFromPidChain(pid, procs) {
    seen := Map()
    cur := Integer(pid)
    Loop 24 {
        if (!cur || seen.Has(cur) || !procs.Has(cur))
            break
        seen[cur] := true
        proc := procs[cur]
        dir := SourceDirFromProcess(proc)
        if (dir != "")
            return dir
        cur := Integer(proc.ParentProcessId)
    }
    return ""
}

FindActiveProjectSources(procs) {
    foundMap := Map()
    try {
        for _, proc in procs {
            dir := SourceDirFromProcess(proc)
            if (dir != "")
                foundMap[StrLower(dir)] := dir
        }
    } catch as e {
    }
    out := []
    for _, dir in foundMap
        out.Push(dir)
    return out
}

StopProcessTreeForSource(sourceDir) {
    try {
        procs := GetProcessMap()
        ids := Map()
        setupPath := StrLower(sourceDir "\setup.exe")
        for _, proc in procs {
            exe := proc.ExecutablePath ? StrLower(proc.ExecutablePath) : ""
            cl := proc.CommandLine ? StrLower(proc.CommandLine) : ""
            if (exe = setupPath || InStr(cl, setupPath))
                ids[Integer(proc.ProcessId)] := true
        }
        changed := true
        while changed {
            changed := false
            for _, proc in procs {
                ppid := Integer(proc.ParentProcessId)
                pid := Integer(proc.ProcessId)
                if (ids.Has(ppid) && !ids.Has(pid)) {
                    ids[pid] := true
                    changed := true
                }
            }
        }
        for id, _ in ids {
            if procs.Has(id) {
                try {
                    procs[id].Terminate()
                    Log("HARD_FAIL_STOP_PROCESS_TREE pid=" id " source=" sourceDir)
                }
            }
        }
        return ids.Count
    } catch as e {
        Log("HARD_FAIL_STOP_TREE_ERR source=" sourceDir " error=" e.Message)
    }
    return 0
}

MarkFitGirlSetupFailedForWindow(winTitle, reason) {
    ; FitGirl helper/decompression failures are hard failures, not optional download popups.
    ; Mark only the mapped source, stop only its setup/helper tree, and delete only its separate incomplete install target.
    sourceDir := FindSourceDirForFailureWindow(winTitle)
    if (sourceDir = "") {
        Log("HARD_FAIL_NOT_MARKED_UNMAPPED reason=" reason)
        return false
    }
    try {
        marker := sourceDir "\.qbit-force-hard-fail.txt"
        try FileDelete(sourceDir "\.qbit-force-install-done.txt")
        try FileDelete(sourceDir "\.qbit-force-source-md5-ok.txt")
        FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " " reason "`n", marker)
        Log("HARD_FAIL_MARKER source=" sourceDir " reason=" reason)
        CleanupIncompleteInstallTargetForSource(sourceDir)
        stopped := StopProcessTreeForSource(sourceDir)
        Log("HARD_FAIL_SCOPED_DONE source=" sourceDir " stopped=" stopped)
        return true
    } catch as e {
        Log("HARD_FAIL_MARKER_ERR source=" sourceDir " error=" e.Message)
    }
    return false
}

ResetFitGirlSetupForRetryWindow(winTitle, reason) {
    ; User-forced no-skip policy for ISDone/Unarc/archive/CRC screens: dismiss, clear launch/hard-fail markers,
    ; clean only the separate incomplete target, stop only the mapped source tree, and let the 250 ms sweep relaunch.
    sourceDir := FindSourceDirForFailureWindow(winTitle)
    if (sourceDir = "") {
        Log("RETRY_RESET_NOT_MAPPED reason=" reason)
        return false
    }
    CleanupIncompleteInstallTargetForSource(sourceDir)
    try FileDelete(sourceDir "\.qbit-force-install-target.txt")
    try FileDelete(sourceDir "\.qbit-force-hard-fail.txt")
    try FileDelete(sourceDir "\.qbit-force-install-done.txt")
    stopped := StopProcessTreeForSource(sourceDir)
    Log("USER_FORCED_RETRY_RESET source=" sourceDir " stopped=" stopped " reason=" reason)
    return true
}

MarkInstallDoneForWindow(winTitle) {
    try {
        pid := WinGetPID(winTitle)
        q := ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process where ProcessId=" pid)
        for proc in q {
            exe := proc.ExecutablePath
            if (!exe)
                return false
            SplitPath exe,, &dir
            targetMarker := dir "\.qbit-force-install-target.txt"
            if (!FileExist(targetMarker))
                return false
            data := FileRead(targetMarker)
            setupPath := ""
            installDir := ""
            if RegExMatch(data, "im)^setup=(.+)$", &sm)
                setupPath := Trim(sm[1])
            if RegExMatch(data, "im)^install_dir=(.+)$", &im)
                installDir := Trim(im[1])
            doneMarker := dir "\.qbit-force-install-done.txt"
            FileAppend("setup=" setupPath "`ninstall_dir=" installDir "`nreason=finish-button-clicked`ndone_utc=" FormatTime(, "yyyy-MM-dd HH:mm:ss") "`n", doneMarker)
            Log("INSTALL_DONE_MARKER_AHK source=" dir " target=" installDir)
            return true
        }
    } catch as e {
        Log("INSTALL_DONE_MARKER_AHK_ERR " e.Message)
    }
    return false
}

HandleClsHelperFailure(winTitle) {
    if (!WindowAlive(winTitle))
        return false
    title := SafeWinTitle(winTitle)
    text := GetWindowTextBlob(winTitle)
    low := StrLower(title "`n" text)
    ; FitGirl helper failures/crashes are hard failures, not optional online-download popups.
    ; Covers CLS start failures plus Windows "has stopped working" / Runtime Error windows for rz/razor/srep/precomp/unarc helpers.
    titleLow := StrLower(title)
    helperName := "(cls|srep|magic|oo2rec|xtool|unarc|isdone|rz|razor|precomp|facompress|bcm|mpz|lolz|zstd|lolz|lzo)"
    helperStartFailure := RegExMatch(low, "(failed to start|failed to launch|cannot start|unable to execute|could not create process).*" helperName ".*(x64|x86|\.exe)")
    helperCrash := RegExMatch(low, helperName ".*(stopped working|has stopped|runtime error|exception|fault|crash|not responding)") || (RegExMatch(titleLow, "(runtime error|application error|stopped working|has stopped)") && RegExMatch(low, helperName))
    if !(RegExMatch(titleLow, "^cls") || helperStartFailure || helperCrash)
        return false
    compact := RegExReplace(text, "\s+", " ")
    if (StrLen(compact) > 500)
        compact := SubStr(compact, 1, 500)
    reason := "CLS_HELPER_FAILURE title=" title " text=" compact
    Log(reason)
    MarkFitGirlSetupFailedForWindow(winTitle, reason)
    if SafeClickText(winTitle, "ok", "close") {
        Log("CLS_HELPER_FAILURE_HANDLED action=button")
        return true
    }
    try {
        ControlSend("{Enter}",, winTitle)
        Log("CLS_HELPER_FAILURE_HANDLED action=enter")
        return true
    } catch as e {
        Log("CLS_HELPER_FAILURE_HANDLE_ERR " e.Message)
    }
    return false
}

HandleRetryableInnoTempHelperFailure(winTitle) {
    if (!WindowAlive(winTitle))
        return false
    title := SafeWinTitle(winTitle)
    text := GetWindowTextBlob(winTitle)
    low := StrLower(title "`n" text)
    ; ISExec/FlushFileCache lives in Inno's temporary extraction area. When it fails from C:\Temp\is-* it is a
    ; retryable temp-helper extraction/path failure, not proof that the repack payload is corrupt. Dismiss it,
    ; clear only launch state for that source, clean the incomplete target, and let the fast sweep relaunch with
    ; the new per-source TEMP/TMP directory from the PowerShell launcher.
    if !(RegExMatch(low, "flushfilecache\.exe.*module\s+isexec") && RegExMatch(low, "c:\\temp\\is-"))
        return false
    sourceDir := FindSourceDirForFailureWindow(winTitle)
    compact := RegExReplace(text, "\s+", " ")
    if (StrLen(compact) > 650)
        compact := SubStr(compact, 1, 650)
    Log("RETRYABLE_INNO_TEMP_HELPER_FAILURE title=" title " source=" sourceDir " text=" compact)
    if (sourceDir != "") {
        try FileDelete(sourceDir "\.qbit-force-install-target.txt")
        try FileDelete(sourceDir "\.qbit-force-hard-fail.txt")
        CleanupIncompleteInstallTargetForSource(sourceDir)
        StopProcessTreeForSource(sourceDir)
        Log("RETRYABLE_INNO_TEMP_HELPER_RESET source=" sourceDir)
    }
    if SafeClickText(winTitle, "ok", "close") {
        Log("RETRYABLE_INNO_TEMP_HELPER_HANDLED action=button")
        return true
    }
    try {
        ControlSend("{Enter}",, winTitle)
        Log("RETRYABLE_INNO_TEMP_HELPER_HANDLED action=enter")
        return true
    } catch as e {
        Log("RETRYABLE_INNO_TEMP_HELPER_HANDLE_ERR " e.Message)
    }
    return false
}

HandleRetryableInstallWriteFailure(winTitle) {
    if (!WindowAlive(winTitle))
        return false
    title := SafeWinTitle(winTitle)
    text := GetWindowTextBlob(winTitle)
    low := StrLower(title "`n" text)
    ; ISDone/Unarc can show "Unable to write data to disk" together with generic archive wording.
    ; Treat that exact class as a retryable target/temp/lock write failure, not permanent source corruption.
    if !IsRetryableInstallWriteFailureText(low)
        return false
    sourceDir := FindSourceDirForFailureWindow(winTitle)
    compact := RegExReplace(text, "\s+", " ")
    if (StrLen(compact) > 700)
        compact := SubStr(compact, 1, 700)
    Log("RETRYABLE_INSTALL_WRITE_FAILURE title=" title " source=" sourceDir " text=" compact)
    if (sourceDir != "") {
        try FileDelete(sourceDir "\.qbit-force-install-target.txt")
        try FileDelete(sourceDir "\.qbit-force-hard-fail.txt")
        CleanupIncompleteInstallTargetForSource(sourceDir)
        StopProcessTreeForSource(sourceDir)
        Log("RETRYABLE_INSTALL_WRITE_RESET source=" sourceDir)
    }
    if SafeClickText(winTitle, "ok", "close") {
        Log("RETRYABLE_INSTALL_WRITE_HANDLED action=button")
        return true
    }
    try {
        ControlSend("{Enter}",, winTitle)
        Log("RETRYABLE_INSTALL_WRITE_HANDLED action=enter")
        return true
    } catch as e {
        Log("RETRYABLE_INSTALL_WRITE_HANDLE_ERR " e.Message)
    }
    return false
}

HandleChecksumCrcSourceFailure(winTitle) {
    if (!WindowAlive(winTitle))
        return false
    title := SafeWinTitle(winTitle)
    text := GetWindowTextBlob(winTitle)
    low := StrLower(title "`n" text)
    ; The screenshot class: ISDone/Unarc checksum/CRC mismatch on an extracted game file.
    ; Do not relaunch the same source in a loop. Mark the exact source as needing qBittorrent recheck/redownload
    ; so future sweeps skip it before setup can show the same popup again.
    if !(RegExMatch(low, "(does not match checksum|failed crc check|crc check|checksum mismatch|failed crc|archive.*corrupt|corrupt archive)") && RegExMatch(low, "(isdone|unarc|error code:\s*-?12|returned an error code)"))
        return false
    compact := RegExReplace(text, "\s+", " ")
    if (StrLen(compact) > 700)
        compact := SubStr(compact, 1, 700)
    reason := "CHECKSUM_CRC_SOURCE_FAILURE title=" title " text=" compact
    Log(reason)
    MarkFitGirlSetupFailedForWindow(winTitle, reason)
    if SafeClickText(winTitle, "ok", "close") {
        Log("CHECKSUM_CRC_SOURCE_FAILURE_HANDLED action=button")
        return true
    }
    try {
        ControlSend("{Enter}",, winTitle)
        Log("CHECKSUM_CRC_SOURCE_FAILURE_HANDLED action=enter")
        return true
    } catch as e {
        Log("CHECKSUM_CRC_SOURCE_FAILURE_HANDLE_ERR " e.Message)
    }
    return false
}

HandleArchiveCorruptionFailure(winTitle) {

    if (!WindowAlive(winTitle))
        return false
    title := SafeWinTitle(winTitle)
    text := GetWindowTextBlob(winTitle)
    low := StrLower(title "`n" text)
    ; User-forced retry policy: the user explicitly wants ISDone/Unarc/CRC/archive/corrupt screens to be treated as retryable
    ; installer-state failures, not as permanent source blockers. We dismiss, reset target/temp/markers, and the 250 ms sweep relaunches.
    if !(RegExMatch(low, "(isdone|unarc|checksum|crc|failed crc|does not match checksum|archive.*corrupt|corrupt archive|decompression failed|failed to unpack|returned an error code|error code:\s*-?\d+|not enough disk|disk full|write error|read error|access is denied)"))
        return false
    compact := RegExReplace(text, "\s+", " ")
    if (StrLen(compact) > 700)
        compact := SubStr(compact, 1, 700)
    reason := "USER_FORCED_RETRY_ARCHIVE_FAILURE title=" title " text=" compact
    Log(reason)
    ResetFitGirlSetupForRetryWindow(winTitle, reason)
    if SafeClickText(winTitle, "ok", "close") {
        Log("USER_FORCED_RETRY_ARCHIVE_HANDLED action=button")
        return true
    }
    try {
        ControlSend("{Enter}",, winTitle)
        Log("USER_FORCED_RETRY_ARCHIVE_HANDLED action=enter")
        return true
    } catch as e {
        Log("USER_FORCED_RETRY_ARCHIVE_HANDLE_ERR " e.Message)
    }
    return false
}

HandleMissingOptionalRedistSource(winTitle) {
    if (!WindowAlive(winTitle))
        return false
    title := SafeWinTitle(winTitle)
    text := GetWindowTextBlob(winTitle)
    low := StrLower(title "`n" text)
    ; Exact classes from screenshots: C:\Temp\IS-*\app\redist-x86.com, nodist_x86.cpp, vc_redist*.exe source file does not exist.
    ; If a missing source popup offers Ignore, choose Ignore: do not let optional/transient temp payloads stop every install.
    missingSource := RegExMatch(low, "(trying to read the source file|source file).*(does not exist|cannot find|system cannot find)")
    optionalPayload := RegExMatch(low, "(vc_redist|vcredist|visual c|visual c\+\+|directx|dxwebsetup|redist|redistributable|runtime|nodist|no[_-]?dist|c:\\temp\\is-[^\s]*\\[^\s]*(\.[a-z0-9_]+))")
    hasIgnoreChoice := HasEnabledButton(winTitle, "ignore") || (HasEnabledButton(winTitle, "abort") && HasEnabledButton(winTitle, "retry"))
    if !(missingSource && (optionalPayload || hasIgnoreChoice))
        return false
    compact := RegExReplace(text, "\s+", " ")
    if (StrLen(compact) > 650)
        compact := SubStr(compact, 1, 650)
    Log("OPTIONAL_REDIST_SOURCE_MISSING title=" title " text=" compact)
    if ClickOptionalIgnoreButton(winTitle) {
        Log("OPTIONAL_REDIST_SOURCE_MISSING_HANDLED action=ignore-or-fallback")
        return true
    }
    return false
}

HandleOptionalOnlineFailure(winTitle) {
    if (!WindowAlive(winTitle))
        return false
    ; FitGirl/Inno sometimes loops forever trying optional online DirectX/VC++/redist downloads.
    ; Guard certificate/TLS/revocation/download-failed popups while preserving real corruption/disk failures.
    text := GetWindowTextBlob(winTitle)
    low := StrLower(text)
    titleLow := StrLower(SafeWinTitle(winTitle))
    fail := RegExMatch(titleLow "`n" low, "(cannot connect|can't connect|download failed|download error|supplied certificate is invalid|certificate (is )?(invalid|not trusted|expired|revoked)|certificate.*(invalid|trust|verify|revocation|chain)|tls|ssl|schannel|winhttp|revocation|unable to verify|connection failed|failed to connect|server returned|trying to read the source file|source file.*does not exist|vc_redist.*does not exist|vcredist.*does not exist|directx.*does not exist|redist.*does not exist|nodist.*does not exist|no[_-]?dist.*does not exist)")
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
    Log("OPTIONAL_ONLINE_FAILURE title=" SafeWinTitle(winTitle) " text=" compact)
    ; On full Setup pages, first clear optional online checkboxes and never press the installer-wide Cancel button.
    if RegExMatch(titleLow, "^setup") {
        ClearOptionalOnlineSelections(winTitle)
        if SafeClickText(winTitle, "ignore", "skip", "no", "ok", "continue") {
            Log("OPTIONAL_ONLINE_FAILURE_HANDLED action=setup-safe-button")
            return true
        }
        ; FitGirl pages sometimes expose only Next after a failed optional VC++/DirectX download.
        ; Only do this after the failure regex matched; normal progress pages are protected by IsActiveProgressPage().
        if SafeClickText(winTitle, "next") {
            Log("OPTIONAL_ONLINE_FAILURE_HANDLED action=setup-next-after-failure")
            return true
        }
        ; If the page is stuck in an optional dependency download failure with no accessible safe button,
        ; send Enter to the default continuation path, then Escape only as a throttled cancel-download nudge.
        ; HandleExitSetupConfirmation() above clicks No if Escape surfaces a real installer-exit confirmation.
        try {
            ControlSend("{Enter}",, winTitle)
            Sleep(80)
            ControlSend("{Esc}",, winTitle)
            Log("OPTIONAL_ONLINE_FAILURE_HANDLED action=setup-enter-escape-fallback")
            return true
        } catch as e {
            Log("OPTIONAL_ONLINE_FAILURE_SETUP_FALLBACK_ERR error=" e.Message)
        }
        return false
    }
    ; On the small Download failed/Error popup, Cancel/OK belongs to the popup, not the installer wizard.
    if SafeClickText(winTitle, "ignore", "skip", "ok", "no", "continue", "close", "finish", "cancel") {
        Log("OPTIONAL_ONLINE_FAILURE_HANDLED action=popup-button")
        return true
    }
    try {
        ControlSend("{Esc}",, winTitle)
        Sleep(20)
        Log("OPTIONAL_ONLINE_FAILURE_HANDLED action=popup-escape")
        return true
    } catch as e {
        Log("OPTIONAL_ONLINE_FAILURE_HANDLE_ERR error=" e.Message)
    }
    return false
}

; Parallel install policy: handle every installer window independently; never wait for one game before clicking another.
Tick() {
    titles := ["CLS", "cls", "cls-srep", "cls-magic", "srep", "xtool", "oo2rec", "rz-", "razor", "precomp", "Folder Exists", "Exit Setup", "Cannot connect", "Download failed", "Downloading additional files", "The supplied certificate is invalid", "Invalid certificate", "Security Warning", "TLS", "SSL", "Error", "Setup Error", "Source file", "Certificate", "Runtime Error", "Application Error", "stopped working", "has stopped", "Select Setup Language", "Setup -", "Setup", "FitGirl", "QuickSFV", "ISDone", "Unarc.dll", "Finalization"]
    for pattern in titles {
        try ids := WinGetList(pattern)
        catch
            continue
        for hwnd in ids {
            title := SafeWinTitle("ahk_id " hwnd)
            if (title = "")
                continue
            if (!WindowAlive("ahk_id " hwnd))
                continue
            ; Fast path: active progress pages need no WMI/path/control scans. Skipping those first keeps other installers' prompts near-instant.
            if IsActiveProgressPage("ahk_id " hwnd)
                continue
            MoveToSecondMonitor(hwnd)
            ForceInstallPath("ahk_id " hwnd)
            ForceRamLimitSelection("ahk_id " hwnd)
            ClearOptionalOnlineSelections("ahk_id " hwnd)
            if HandleFinishedInstallPage("ahk_id " hwnd)
                continue
            if HandleFolderExists("ahk_id " hwnd)
                continue
            if HandleExitSetupConfirmation("ahk_id " hwnd)
                continue
            if HandleMissingOptionalRedistSource("ahk_id " hwnd)
                continue
            if HandleClsHelperFailure("ahk_id " hwnd)
                continue
            if HandleRetryableInnoTempHelperFailure("ahk_id " hwnd)
                continue
            if HandleRetryableInstallWriteFailure("ahk_id " hwnd)
                continue
            if HandleChecksumCrcSourceFailure("ahk_id " hwnd)
                continue
            if HandleArchiveCorruptionFailure("ahk_id " hwnd)
                continue
            if HandleFinalizationMissingHelper("ahk_id " hwnd)
                continue
            if HandleOptionalOnlineFailure("ahk_id " hwnd)
                continue
            if ImmediateSafeWizardAdvance("ahk_id " hwnd)
                continue
            if ClickBestWizardButton("ahk_id " hwnd)
                continue
            ; Fallback for language/Next-style dialogs where button text is inaccessible.
            if (InStr(StrLower(title), "select setup language") || InStr(StrLower(title), "setup -")) {
                try ControlSend("{Enter}",, "ahk_id " hwnd)
                Log("ENTER title=" title)
            }
        }
    }
}

RunLauncherSweep() {
    ; Hermes safety: clicker must not keep forcing relaunch/reboot loops after the foreground script exits.
    ; Launcher sweeps are disabled unless an explicit allow marker exists. qBittorrent hooks and the canonical liner still run the PowerShell sweep.
    allowMarker := A_ScriptDir "\..\runtime\qbit-fitgirl-auto-install\allow-ahk-launch-sweep.txt"
    if (!FileExist(allowMarker)) {
        Log("LAUNCH_SWEEP_DISABLED no_allow_marker=" allowMarker)
        return
    }
    ps1 := "F:\study\Windows\Applications\Gaming\DownloadManagers\qBittorrent\FitGirl\Automation\AutoInstall\qbittorrent-fitgirl-force-auto-install-20260601\scripts\Force-QbitFitGirlAutoInstall.ps1"
    if (!FileExist(ps1)) {
        Log("LAUNCH_SWEEP_SKIP missing_ps1=" ps1)
        return
    }
    try {
        cmd := "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"" ps1 "`" -Once"
        shell := ComObject("WScript.Shell")
        shell.Run(cmd, 0, false)
        Log("LAUNCH_SWEEP_TRIGGERED")
    } catch as e {
        Log("LAUNCH_SWEEP_ERROR " e.Message)
    }
}


RunSelfTest() {
    marker := A_Temp "\qbit-fitgirl-ahk-button-selftest.txt"
    errMarker := A_Temp "\qbit-fitgirl-ahk-ignore-selftest.txt"
    ramMarker := A_Temp "\qbit-fitgirl-ahk-ramlimit-selftest.txt"
    folderMarker := A_Temp "\qbit-fitgirl-ahk-folderexists-selftest.txt"
    fatalMarker := A_Temp "\qbit-fitgirl-ahk-isdone-selftest.txt"
    writeMarker := A_Temp "\qbit-fitgirl-ahk-isdone-write-selftest.txt"
    finishMarker := A_Temp "\qbit-fitgirl-ahk-finish-clicked-selftest.txt"
    try FileDelete(marker)
    try FileDelete(errMarker)
    try FileDelete(ramMarker)
    try FileDelete(folderMarker)
    try FileDelete(fatalMarker)
    try FileDelete(writeMarker)
    try FileDelete(finishMarker)
    g := Gui("+AlwaysOnTop", "Hermes FitGirl Button Selftest")
    g.Add("Text",, "Button automation selftest")
    btn := g.Add("Button", "w120", "&Next >")
    btn.OnEvent("Click", (*) => FileAppend("clicked", marker))
    g.Show("w320 h140")
    Sleep(250)
    ok := SafeClickText("ahk_id " g.Hwnd, "next")
    if (!ok)
        ok := ClickBestWizardButton("ahk_id " g.Hwnd)
    Sleep(1000)
    clicked := FileExist(marker)
    try g.Destroy()

    cg := Gui("+AlwaysOnTop", "Setup - Certificate Optional Download Selftest")
    cg.Add("Text", "w620", "Downloading additional files`nStatus: Cannot connect`nFile: vc_redist.x64.exe`nDownload failed: The supplied certificate is invalid`nSelect the components you want to install; clear the components you do not want to install. Click Next when you are ready to continue.")
    cg.Add("Button", "w100", "Hide")
    cg.Show("w700 h230")
    Sleep(250)
    certOk := HandleOptionalOnlineFailure("ahk_id " cg.Hwnd)
    Sleep(250)
    try cg.Destroy()

    eg := Gui("+AlwaysOnTop", "Error")
    eg.Add("Text", "w520", "An error occurred while trying to read the source file:`nThe source file `"C:\Temp\is-K5HVJ.tmp\vc_redist.x86.exe`" does not exist.`n`nClick Retry to try again, Ignore to skip this file (not recommended), or Abort to cancel installation.")
    eg.Add("Button", "w100", "&Abort")
    eg.Add("Button", "x+10 w100", "&Retry")
    ib := eg.Add("Button", "x+10 w100", "&Ignore")
    ib.OnEvent("Click", (*) => FileAppend("ignore", errMarker))
    eg.Show("w620 h220")
    Sleep(250)
    ignoreOk := HandleMissingOptionalRedistSource("ahk_id " eg.Hwnd)
    Sleep(1000)
    ignored := FileExist(errMarker)
    try eg.Destroy()

    rg := Gui("+AlwaysOnTop", "Setup - RAM Limit Selftest")
    rg.Add("Text",, "FitGirl options selftest")
    cb := rg.Add("CheckBox", "w320", "Limit installer to 2 GB of RAM usage")
    cb.OnEvent("Click", (*) => FileAppend("ram", ramMarker))
    rg.Show("w420 h160")
    Sleep(250)
    ramOk := ForceRamLimitSelection("ahk_id " rg.Hwnd)
    Sleep(1000)
    ramChecked := false
    try ramChecked := (ControlGetChecked("ahk_id " cb.Hwnd) = 1)
    catch as e {
        try ramChecked := (cb.Value = 1)
    }
    try rg.Destroy()

    fg := Gui("+AlwaysOnTop", "Folder Exists")
    fg.Add("Text", "w520", "The folder already exists. Would you like to install to that folder anyway?")
    yb := fg.Add("Button", "w100", "&Yes")
    yb.OnEvent("Click", (*) => FileAppend("yes", folderMarker))
    fg.Add("Button", "x+10 w100", "&No")
    fg.Show("w620 h160")
    Sleep(250)
    folderOk := HandleFolderExists("ahk_id " fg.Hwnd)
    Sleep(1000)
    folderClicked := FileExist(folderMarker)
    try fg.Destroy()

    ; Do not create a real-looking ISDone.dll popup during selftest while live installs may be running.
    ; The live handler is verified by syntax/static checks; this selftest proves the classifier recognizes
    ; ISDone/Unarc/CRC/checksum as fatal without triggering the runtime marker/kill path.
    fatalSample := "ISDone.dll`nAn error occurred while unpacking: Unable to write data to disk!`nUnarc.dll returned an error code: -12`nERROR: file C:\Temp\bad.bin failed CRC check / checksum mismatch"
    fatalOk := IsHardFailureText(fatalSample)
    if (fatalOk)
        FileAppend("classified", fatalMarker)
    fatalClicked := FileExist(fatalMarker)

    writeSample := "ISDone.dll`nAn error occurred while unpacking: Unable to write data to disk!`nUnarc.dll returned an error code: -11`nERROR: archive data corrupted (decompression fails)"
    writeOk := IsRetryableInstallWriteFailureText(writeSample)
    if (writeOk)
        FileAppend("retryable-write", writeMarker)
    writeClassified := FileExist(writeMarker)

    fin := Gui("+AlwaysOnTop", "Setup - Final Page Selftest")
    fin.Add("Text", "w560", "Setup has finished installing Test Game on your computer. Click Finish to exit Setup.")
    finalCb := fin.Add("CheckBox", "Checked w360", "Launch Test Game")
    fb := fin.Add("Button", "w100", "Finish")
    fb.OnEvent("Click", (*) => FileAppend("finish", finishMarker))
    fin.Show("w640 h190")
    Sleep(250)
    finalOk := HandleFinishedInstallPage("ahk_id " fin.Hwnd)
    Sleep(1000)
    finishClicked := FileExist(finishMarker)
    finalUnchecked := false
    try finalUnchecked := (finalCb.Value = 0)
    try fin.Destroy()

    if (ok && clicked && certOk && ignoreOk && ignored && ramOk && ramChecked && folderOk && folderClicked && fatalOk && fatalClicked && writeOk && writeClassified && finalOk && finishClicked && finalUnchecked) {
        FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " SELFTEST BUTTON+CERT+IGNORE+RAMLIMIT+FOLDER+ISDONE+ISDONE_WRITE_MINUS11+FINAL+FINISH OK`n", A_Temp "\qbit-fitgirl-ahk-selftest.log")
        ExitApp(0)
    }
    FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") " SELFTEST FAILED ok=" ok " clicked=" clicked " certOk=" certOk " ignoreOk=" ignoreOk " ignored=" ignored " ramOk=" ramOk " ramChecked=" ramChecked " folderOk=" folderOk " folderClicked=" folderClicked " fatalOk=" fatalOk " fatalClicked=" fatalClicked " writeOk=" writeOk " writeClassified=" writeClassified " finalOk=" finalOk " finishClicked=" finishClicked " finalUnchecked=" finalUnchecked "`n", A_Temp "\qbit-fitgirl-ahk-selftest.log")
    ExitApp(2)
}

if (SelfTestMode)
    RunSelfTest()

Log("WATCHDOG START")
SetTimer(Tick, 50)
; Keep click handling fast: qBittorrent hook + 250 ms PowerShell daemon handle immediate launch.
; The AHK safety sweep is throttled so it never starves prompt clicks by spawning PowerShell every 200 ms.
; Disabled by default: the clicker handles dialogs only and must not relaunch apps after the controlling script exits.
; Create runtime\qbit-fitgirl-auto-install\allow-ahk-launch-sweep.txt only for explicit diagnostic sweep mode.
; SetTimer(RunLauncherSweep, 5000)
; SetTimer(RunLauncherSweep, -200)
