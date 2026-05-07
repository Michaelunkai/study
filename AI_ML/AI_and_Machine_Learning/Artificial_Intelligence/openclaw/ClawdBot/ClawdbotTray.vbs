Option Explicit
On Error Resume Next

Dim shell
Dim fso
Dim managerPath
Dim processEnv
Dim powershellExe
Dim configPath
Dim syncCatalogScript
Dim menuSyncScript
Dim repoRoot
Dim canonicalRepoRoot
Dim stateRoot
Dim tempRoot
Dim bootstrapLogPath
Dim manifestPath
Dim authorityGeneration
Dim runtimeCommandRoot

Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
Set processEnv = shell.Environment("PROCESS")

managerPath = fso.GetParentFolderName(WScript.ScriptFullName) & "\ClawdBotManager.exe"
repoRoot = fso.GetParentFolderName(fso.GetParentFolderName(WScript.ScriptFullName))
canonicalRepoRoot = "F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw"
powershellExe = shell.ExpandEnvironmentStrings("%SystemRoot%") & "\System32\WindowsPowerShell\v1.0\powershell.exe"
stateRoot = fso.BuildPath(canonicalRepoRoot, "openclaw-home")
configPath = fso.BuildPath(stateRoot, "openclaw.json")
syncCatalogScript = fso.BuildPath(canonicalRepoRoot, "scripts\telegram-global\Sync-OpenClawCommandCatalog.ps1")
menuSyncScript = fso.BuildPath(canonicalRepoRoot, "scripts\telegram-global\Sync-TelegramMenu.ps1")
tempRoot = fso.BuildPath(stateRoot, "tmp")
manifestPath = fso.BuildPath(stateRoot, "authority\authority-manifest.json")
runtimeCommandRoot = fso.BuildPath(canonicalRepoRoot, "npm-global")
If Not fso.FolderExists(tempRoot) Then
    fso.CreateFolder tempRoot
End If
bootstrapLogPath = fso.BuildPath(tempRoot, "clawdbot-tray-bootstrap.log")
If LCase(repoRoot) <> LCase(canonicalRepoRoot) Then
    LogBootstrap "non-canonical-launch:" & repoRoot
    If fso.FileExists(fso.BuildPath(canonicalRepoRoot, "ClawdBot\ClawdbotTray.vbs")) Then
        shell.Run """" & fso.BuildPath(canonicalRepoRoot, "ClawdBot\ClawdbotTray.vbs") & """", 0, False
    End If
    WScript.Quit 0
End If
LogBootstrap "startup"
processEnv("OPENCLAW_STATE_DIR") = stateRoot
processEnv("OPENCLAW_REPO_ROOT") = canonicalRepoRoot
processEnv("OPENCLAW_CONFIG_PATH") = configPath
processEnv("OPENCLAW_TMP_DIR") = tempRoot
processEnv("OPENCLAW_AUTHORITY_MANIFEST_PATH") = manifestPath
processEnv("OPENCLAW_RUNTIME_COMMAND_ROOT") = runtimeCommandRoot
processEnv("OPENCLAW_DISABLE_BONJOUR") = "1"
processEnv("OPENCLAW_DISABLE_MODEL_PRICING") = "1"
processEnv("OPENCLAW_STARTUP_SIDECARS_WAIT_MS") = "0"
processEnv("OPENCLAW_SKIP_STARTUP_MODEL_PREWARM") = "1"
processEnv("OPENCLAW_SKIP_TELEGRAM_MENU_SYNC") = "1"
processEnv("OPENCLAW_SKIP_STARTUP_INTERNAL_HOOKS") = "1"
processEnv("OPENCLAW_SKIP_STARTUP_OPTIONAL_SIDECARS") = "1"
processEnv("OPENCLAW_SKIP_STARTUP_HEARTBEATS") = "1"
processEnv("OPENCLAW_TELEGRAM_LIGHT_POLLING") = "0"
processEnv("OPENCLAW_TELEGRAM_MAX_COMMAND_HANDLERS") = "100"
processEnv("TEMP") = tempRoot
processEnv("TMP") = tempRoot

If fso.FileExists(managerPath) Then
    LogBootstrap "launch-manager"
    shell.Run """" & managerPath & """", 0, False
End If

LogBootstrap "skip-bootstrap-menu-sync"

LogBootstrap "exit"
WScript.Quit 0

Sub LogBootstrap(message)
    Dim stream
    Set stream = fso.OpenTextFile(bootstrapLogPath, 8, True, 0)
    stream.WriteLine Now & " " & message
    stream.Close
End Sub
