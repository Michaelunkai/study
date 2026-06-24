Set wshShell = WScript.CreateObject("WScript.Shell")
strComputerName = wshShell.ExpandEnvironmentStrings("%ComputerName%")

Set updateSession = CreateObject("Microsoft.Update.Session")

WScript.StdOut.WriteLine "Activity=""Processing Windows Updates on " & strComputerName & """ Status=""Searching for updates"" Percentage=0"
Set SearchResult = Search
WScript.StdOut.WriteLine "Activity=""Processing Windows Updates on " & strComputerName & """ Status=""Searching for updates"" Percentage=100"
WScript.StdOut.WriteLine "SearchResultCode=" & SearchResult.ResultCode
WScript.StdOut.WriteLine "UpdatesFound=" & SearchResult.Updates.Count

If SearchResult.ResultCode = 2 And SearchResult.Updates.Count > 0 Then
    Set DownloadResult = Download(SearchResult.Updates)
    WScript.StdOut.WriteLine "DownloadResultCode=" & DownloadResult.ResultCode

    If DownloadResult.ResultCode = 2 Then
        Set InstallResult = Install(SearchResult.Updates)
        WScript.StdOut.WriteLine "InstallResultCode=" & InstallResult.ResultCode
        WScript.StdOut.WriteLine "RebootRequired=" & InstallResult.RebootRequired
    End If
End If

Function Search
    Dim Result

    Set updateSearcher = updateSession.CreateupdateSearcher()
    Set searchResult = updateSearcher.Search("IsInstalled=0 and Type='Software' and AutoSelectOnWebsites=1")

    Set Search = searchResult
End Function

Function Download(Byval hCollection)
    Dim Result

    Set Downloader = updateSession.CreateUpdateDownloader()
    Downloader.Updates = hCollection

    Set DownloadJob = Downloader.BeginDownload(GetRef("Download_OnProgressChanged"), GetRef("Download_OnCompleted"), "")
    If Not Err.Number = 0 Then
        WScript.StdOut.WriteLine "Error " & Err.Number & ": " & Err.Description
    End If
 
    Do Until DownloadJob.IsCompleted
        WScript.Sleep 1000
    Loop

    Set Download = Downloader.EndDownload(DownloadJob)
End Function

Sub Download_OnProgressChanged(ByVal hDownloadJob, ByVal hArguments)
    WScript.StdOut.WriteLine "Activity=""Processing Windows Updates on " & strComputerName & """ Status=""Downloading updates"" Percentage=" & hArguments.Progress.PercentComplete
End Sub

Sub Download_OnCompleted(ByVal hInstallJob, ByVal hArguments)
    WScript.StdOut.WriteLine "Activity=""Processing Windows Updates on " & strComputerName & """ Status=""Downloading updates"" Percentage=100"
End Sub

Function Install(Byval hCollection)
    Dim Result

    Set Installer = updateSession.CreateUpdateInstaller()
    Installer.Updates = hCollection

    Set InstallJob = Installer.BeginInstall(GetRef("Install_OnProgressChanged"), GetRef("Install_OnCompleted"), "")
    If Not Err.Number = 0 Then
        WScript.StdOut.WriteLine "Error " & Err.Number & ": " & Err.Description
    End If
 
    Do Until InstallJob.IsCompleted
        WScript.Sleep 1000
    Loop

    Set Install = Installer.EndInstall(InstallJob)
End Function

Sub Install_OnProgressChanged(ByVal hInstallJob, ByVal hArguments)
    WScript.StdOut.WriteLine "Activity=""Processing Windows Updates on " & strComputerName & """ Status=""Installing updates"" Percentage=" & hArguments.Progress.PercentComplete
End Sub

Sub Install_OnCompleted(ByVal hInstallJob, ByVal hArguments)
    WScript.StdOut.WriteLine "Activity=""Processing Windows Updates on " & strComputerName & """ Status=""Installing updates"" Percentage=100"
End Sub