' Based on the asynchronous WUA callback pattern from:
' https://gist.github.com/nicholasdille/71c23b3772bd4e871225
' Local changes: per-update KB/title reporting, once-per-second real WUA polling,
' Microsoft Update service selection, preview mode, and machine-readable output.

Option Explicit

Dim gShell, gComputerName, gSession, gUpdates, gPreviewOnly, gAllowReboot, gRound, gSearchMode
Set gShell = WScript.CreateObject("WScript.Shell")
gComputerName = gShell.ExpandEnvironmentStrings("%ComputerName%")
gPreviewOnly = ReadBoolArg("PreviewOnly", False)
gAllowReboot = ReadBoolArg("AllowReboot", False)
gRound = ReadTextArg("Round", "1")
gSearchMode = LCase(ReadTextArg("SearchMode", "all"))

On Error Resume Next
Set gSession = CreateObject("Microsoft.Update.Session")
If Err.Number <> 0 Then
    Emit "error stage=session hresult=" & HexErr(Err.Number) & " message=" & Clean(Err.Description)
    WScript.Quit 1
End If
On Error GoTo 0

gSession.ClientApplicationID = "CodexFastWindowsUpdateVbs"

Emit "round=" & gRound & " initializing WUA async VBS searchMode=" & gSearchMode
EnableMicrosoftUpdate

Dim searchResult
Set searchResult = SearchUpdates()
If searchResult Is Nothing Then
    WScript.Quit 1
End If

Emit "found=" & searchResult.Updates.Count
If searchResult.Updates.Count < 1 Then
    Emit "round-result=NO_UPDATES"
    WScript.Quit 0
End If

Set gUpdates = CreateObject("Microsoft.Update.UpdateColl")
QueueUpdates searchResult.Updates

If gPreviewOnly Then
    Emit "round-result=PREVIEW_ONLY"
    WScript.Quit 0
End If

Dim downloadResult
Set downloadResult = DownloadUpdates(gUpdates)
If downloadResult Is Nothing Then
    WScript.Quit 1
End If
Emit "download-result resultCode=" & downloadResult.ResultCode & " hresult=" & downloadResult.HResult

Dim installable
Set installable = CreateObject("Microsoft.Update.UpdateColl")
CollectInstallable installable, gUpdates
If installable.Count < 1 Then
    Emit "round-result=DOWNLOAD_INCOMPLETE"
    WScript.Quit 2
End If

Set gUpdates = installable
Dim installResult
Set installResult = InstallUpdates(installable)
If installResult Is Nothing Then
    WScript.Quit 1
End If

Emit "install-result resultCode=" & installResult.ResultCode & " hresult=" & installResult.HResult & " rebootRequired=" & LCase(CStr(installResult.RebootRequired))
EmitInstalledItems installable, installResult
If installResult.RebootRequired And gAllowReboot Then
    Emit "reboot-allowed-but-not-forced restart manually when ready to complete servicing"
End If
Emit "round-result=INSTALL_ATTEMPT_COMPLETE"
WScript.Quit 0

Function ReadBoolArg(ByVal name, ByVal fallback)
    On Error Resume Next
    If WScript.Arguments.Named.Exists(name) Then
        Dim raw
        raw = LCase(CStr(WScript.Arguments.Named.Item(name)))
        ReadBoolArg = (raw = "" Or raw = "1" Or raw = "true" Or raw = "yes")
    Else
        ReadBoolArg = fallback
    End If
    On Error GoTo 0
End Function

Function ReadTextArg(ByVal name, ByVal fallback)
    On Error Resume Next
    If WScript.Arguments.Named.Exists(name) Then
        ReadTextArg = CStr(WScript.Arguments.Named.Item(name))
    Else
        ReadTextArg = fallback
    End If
    On Error GoTo 0
End Function

Sub EnableMicrosoftUpdate()
    On Error Resume Next
    Dim manager
    Set manager = CreateObject("Microsoft.Update.ServiceManager")
    manager.ClientApplicationID = "CodexFastWindowsUpdateVbs"
    manager.AddService2 "7971f918-a847-4430-9279-4a52d1efe18d", 7, ""
    If Err.Number = 0 Then
        Emit "Microsoft Update service enabled"
    Else
        Emit "Microsoft Update service enable skipped hresult=" & HexErr(Err.Number) & " message=" & Clean(Err.Description)
    End If
    Err.Clear
    On Error GoTo 0
End Sub

Function SearchUpdates()
    On Error Resume Next
    Dim searcher
    Dim criteria
    Set searcher = gSession.CreateUpdateSearcher()
    searcher.ServerSelection = 3
    searcher.ServiceID = "7971f918-a847-4430-9279-4a52d1efe18d"
    criteria = BuildSearchCriteria()
    Emit "searching: " & criteria
    Set SearchUpdates = searcher.Search(criteria)
    If Err.Number <> 0 Then
        Emit "error stage=search hresult=" & HexErr(Err.Number) & " message=" & Clean(Err.Description)
        Set SearchUpdates = Nothing
    End If
    Err.Clear
    On Error GoTo 0
End Function

Function BuildSearchCriteria()
    Select Case gSearchMode
        Case "standard"
            BuildSearchCriteria = "IsInstalled=0 and IsHidden=0 and BrowseOnly=0"
        Case "optional"
            BuildSearchCriteria = "IsInstalled=0 and IsHidden=0 and BrowseOnly=1"
        Case Else
            BuildSearchCriteria = "IsInstalled=0 and IsHidden=0"
    End Select
End Function

Sub QueueUpdates(ByVal foundUpdates)
    Dim i, update, kb
    For i = 0 To foundUpdates.Count - 1
        Set update = foundUpdates.Item(i)
        On Error Resume Next
        If Not update.EulaAccepted Then update.AcceptEula
        Err.Clear
        On Error GoTo 0
        gUpdates.Add update
        kb = GetKb(update)
        Emit "queued=" & (i + 1) & "/" & foundUpdates.Count & " kb=" & kb & " title=" & Clean(update.Title)
    Next
End Sub

Function DownloadUpdates(ByVal updates)
    On Error Resume Next
    Dim downloader, job
    Set downloader = gSession.CreateUpdateDownloader()
    downloader.Updates = updates
    downloader.Priority = 3
    Emit "download-start count=" & updates.Count
    Set job = downloader.BeginDownload(GetRef("Download_OnProgressChanged"), GetRef("Download_OnCompleted"), "codex-download")
    If Err.Number <> 0 Then
        Emit "error stage=begin-download hresult=" & HexErr(Err.Number) & " message=" & Clean(Err.Description)
        Set DownloadUpdates = Nothing
        Err.Clear
        Exit Function
    End If
    PollJob "download", job
    Set DownloadUpdates = downloader.EndDownload(job)
    If Err.Number <> 0 Then
        Emit "error stage=end-download hresult=" & HexErr(Err.Number) & " message=" & Clean(Err.Description)
        Set DownloadUpdates = Nothing
        Err.Clear
    End If
    On Error GoTo 0
End Function

Sub Download_OnProgressChanged(ByVal job, ByVal args)
    EmitProgress "download", args.Progress
End Sub

Sub Download_OnCompleted(ByVal job, ByVal args)
    EmitProgressComplete "download"
End Sub

Function InstallUpdates(ByVal updates)
    On Error Resume Next
    Dim installer, job
    Set installer = gSession.CreateUpdateInstaller()
    installer.Updates = updates
    installer.ForceQuiet = True
    Emit "install-start count=" & updates.Count
    Set job = installer.BeginInstall(GetRef("Install_OnProgressChanged"), GetRef("Install_OnCompleted"), "codex-install")
    If Err.Number <> 0 Then
        Emit "error stage=begin-install hresult=" & HexErr(Err.Number) & " message=" & Clean(Err.Description)
        Set InstallUpdates = Nothing
        Err.Clear
        Exit Function
    End If
    PollJob "install", job
    Set InstallUpdates = installer.EndInstall(job)
    If Err.Number <> 0 Then
        Emit "error stage=end-install hresult=" & HexErr(Err.Number) & " message=" & Clean(Err.Description)
        Set InstallUpdates = Nothing
        Err.Clear
    End If
    On Error GoTo 0
End Function

Sub Install_OnProgressChanged(ByVal job, ByVal args)
    EmitProgress "install", args.Progress
End Sub

Sub Install_OnCompleted(ByVal job, ByVal args)
    EmitProgressComplete "install"
End Sub

Sub PollJob(ByVal phase, ByVal job)
    Do Until job.IsCompleted
        On Error Resume Next
        EmitProgress phase, job.GetProgress()
        Err.Clear
        On Error GoTo 0
        WScript.Sleep 1000
    Loop
End Sub

Sub EmitProgress(ByVal phase, ByVal progress)
    Dim overall, current, index, meta
    overall = 0
    current = 0
    index = 0
    On Error Resume Next
    overall = CDbl(progress.PercentComplete)
    current = CDbl(progress.CurrentUpdatePercentComplete)
    If Err.Number <> 0 Then
        current = overall
        Err.Clear
    End If
    index = CLng(progress.CurrentUpdateIndex)
    If Err.Number <> 0 Then
        index = 0
        Err.Clear
    End If
    On Error GoTo 0
    meta = GetMeta(index)
    Emit "progress: phase=" & phase & " update=" & MetaPart(meta, 0) & "/" & MetaPart(meta, 1) & " kb=" & MetaPart(meta, 2) & " updatePercent=" & FormatPct(current) & "% overallPercent=" & FormatPct(overall) & "% title=" & MetaPart(meta, 3)
End Sub

Sub EmitProgressComplete(ByVal phase)
    Dim meta
    meta = GetMeta(0)
    Emit "progress: phase=" & phase & " update=" & MetaPart(meta, 0) & "/" & MetaPart(meta, 1) & " kb=" & MetaPart(meta, 2) & " updatePercent=100.00% overallPercent=100.00% title=" & MetaPart(meta, 3)
End Sub

Function GetMeta(ByVal zeroIndex)
    Dim count, safeIndex, update, kb, title
    count = 0
    safeIndex = 0
    kb = "KBUNKNOWN"
    title = "Unknown update"
    On Error Resume Next
    count = gUpdates.Count
    If zeroIndex < 0 Then zeroIndex = 0
    If count > 0 And zeroIndex >= count Then zeroIndex = count - 1
    safeIndex = zeroIndex
    If count > 0 Then
        Set update = gUpdates.Item(safeIndex)
        kb = GetKb(update)
        title = Clean(update.Title)
    End If
    If count < 1 Then count = 1
    GetMeta = CStr(safeIndex + 1) & Chr(30) & CStr(count) & Chr(30) & kb & Chr(30) & title
    On Error GoTo 0
End Function

Function MetaPart(ByVal meta, ByVal part)
    Dim pieces
    pieces = Split(meta, Chr(30))
    If UBound(pieces) >= part Then
        MetaPart = pieces(part)
    Else
        MetaPart = ""
    End If
End Function

Function GetKb(ByVal update)
    On Error Resume Next
    Dim ids, i, text
    text = ""
    Set ids = update.KBArticleIDs
    For i = 0 To ids.Count - 1
        If Len(text) > 0 Then text = text & ","
        text = text & "KB" & ids.Item(i)
    Next
    If Len(text) = 0 Then text = "KBUNKNOWN"
    GetKb = text
    Err.Clear
    On Error GoTo 0
End Function

Sub CollectInstallable(ByVal target, ByVal source)
    Dim i, update
    For i = 0 To source.Count - 1
        Set update = source.Item(i)
        If update.IsDownloaded Then
            target.Add update
        Else
            Emit "not-downloaded title=" & Clean(update.Title)
        End If
    Next
End Sub

Sub EmitInstalledItems(ByVal updates, ByVal result)
    Dim i, update, itemResult
    For i = 0 To updates.Count - 1
        Set update = updates.Item(i)
        Set itemResult = result.GetUpdateResult(i)
        Emit "installed-item=" & (i + 1) & "/" & updates.Count & " resultCode=" & itemResult.ResultCode & " hresult=" & itemResult.HResult & " kb=" & GetKb(update) & " title=" & Clean(update.Title)
    Next
End Sub

Function FormatPct(ByVal value)
    If value < 0 Then value = 0
    If value > 100 Then value = 100
    FormatPct = Replace(FormatNumber(value, 2, -1, 0, 0), ",", "")
End Function

Sub Emit(ByVal text)
    WScript.StdOut.WriteLine "[child][" & TimeStamp() & "] " & text
End Sub

Function TimeStamp()
    TimeStamp = Right("0" & Hour(Now), 2) & ":" & Right("0" & Minute(Now), 2) & ":" & Right("0" & Second(Now), 2)
End Function

Function Clean(ByVal text)
    text = Replace(CStr(text), vbCr, " ")
    text = Replace(text, vbLf, " ")
    text = Replace(text, """", "'")
    Clean = Trim(text)
End Function

Function HexErr(ByVal number)
    Dim unsigned
    unsigned = CDbl(number)
    If unsigned < 0 Then unsigned = unsigned + 4294967296
    HexErr = "0x" & Right("00000000" & Hex(unsigned), 8)
End Function
