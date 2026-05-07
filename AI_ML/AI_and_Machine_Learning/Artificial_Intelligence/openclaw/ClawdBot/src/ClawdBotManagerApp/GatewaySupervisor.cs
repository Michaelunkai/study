using System.Diagnostics;
using System.Text;
using System.Text.Json;

namespace ClawdBotManagerApp;

internal sealed class GatewaySupervisor
{
    private readonly RuntimePaths _paths;
    private Process? _gatewayProcess;
    private DateTime _lastLaunchUtc = DateTime.MinValue;

    public GatewaySupervisor(RuntimePaths paths)
    {
        _paths = paths;
    }

    public DateTime LastLaunchUtc => _lastLaunchUtc == DateTime.MinValue ? ReadLeaseGeneratedAtUtc() : _lastLaunchUtc;

    public bool HasOwnedProcess
    {
        get
        {
            if (_gatewayProcess is { HasExited: false })
            {
                return true;
            }

            var leasedPid = ReadLeaseGatewayPid();
            return ProcessUtilities.ProcessExists(leasedPid);
        }
    }

    public void EnsureStarted(string reason)
    {
        var listenerPids = ProcessUtilities.GetListeningPids(18789);
        if (listenerPids.Count > 0)
        {
            AppLogger.Info("gateway", "listener already present pid=" + string.Join(",", listenerPids));
            return;
        }

        Start(reason);
    }

    public void Start(string reason)
    {
        if (!File.Exists(_paths.RuntimeScriptPath))
        {
            throw new InvalidOperationException("OpenClaw runtime script missing: " + _paths.RuntimeScriptPath);
        }

        Directory.CreateDirectory(_paths.TempRoot);
        var startInfo = new ProcessStartInfo
        {
            FileName = _paths.NodeExePath,
            Arguments = "\"" + _paths.RuntimeScriptPath + "\" gateway run --port 18789",
            WorkingDirectory = _paths.RuntimeRoot,
            UseShellExecute = false,
            CreateNoWindow = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true
        };

        SetEnvironment(startInfo);
        _gatewayProcess = Process.Start(startInfo) ?? throw new InvalidOperationException("Failed to start gateway process.");
        _lastLaunchUtc = DateTime.UtcNow;
        _gatewayProcess.OutputDataReceived += (_, args) => { if (!string.IsNullOrWhiteSpace(args.Data)) AppLogger.Write("gateway:stdout", args.Data); };
        _gatewayProcess.ErrorDataReceived += (_, args) => { if (!string.IsNullOrWhiteSpace(args.Data)) AppLogger.Write("gateway:stderr", args.Data); };
        _gatewayProcess.EnableRaisingEvents = true;
        _gatewayProcess.Exited += (_, _) => AppLogger.Write("gateway", "child exited pid=" + _gatewayProcess.Id);
        _gatewayProcess.BeginOutputReadLine();
        _gatewayProcess.BeginErrorReadLine();
        PersistLease(_gatewayProcess.Id, reason);
        AppLogger.Info("gateway", "started pid=" + _gatewayProcess.Id + " reason=" + reason);
    }

    public void StopOwnedGateway()
    {
        var candidates = new HashSet<int>();
        if (_gatewayProcess is { HasExited: false })
        {
            candidates.Add(_gatewayProcess.Id);
        }

        var leasedPid = ReadLeaseGatewayPid();
        if (leasedPid > 0)
        {
            candidates.Add(leasedPid);
        }

        foreach (var pid in ProcessUtilities.GetListeningPids(18789))
        {
            var commandLine = ProcessUtilities.GetCommandLine(pid);
            if (commandLine.Contains(_paths.RuntimeScriptPath, StringComparison.OrdinalIgnoreCase) ||
                commandLine.Contains("gateway run --port 18789", StringComparison.OrdinalIgnoreCase))
            {
                candidates.Add(pid);
            }
        }

        foreach (var pid in candidates)
        {
            try
            {
                using var process = Process.GetProcessById(pid);
                if (!process.HasExited)
                {
                    process.Kill();
                    process.WaitForExit(5000);
                    AppLogger.Info("gateway", "stopped pid=" + pid);
                }
            }
            catch (Exception exception)
            {
                AppLogger.Write("gateway", "stop failed pid=" + pid + " " + exception.Message);
            }
        }

        _gatewayProcess = null;
    }

    private void SetEnvironment(ProcessStartInfo startInfo)
    {
        startInfo.Environment["OPENCLAW_STATE_DIR"] = _paths.StateRoot;
        startInfo.Environment["OPENCLAW_REPO_ROOT"] = _paths.RepoRoot;
        startInfo.Environment["OPENCLAW_CONFIG_PATH"] = _paths.ConfigPath;
        startInfo.Environment["OPENCLAW_TMP_DIR"] = _paths.TempRoot;
        startInfo.Environment["OPENCLAW_AUTHORITY_MANIFEST_PATH"] = _paths.AuthorityManifestPath;
        startInfo.Environment["OPENCLAW_RUNTIME_COMMAND_ROOT"] = _paths.RuntimeRoot;
        startInfo.Environment["OPENCLAW_DISABLE_BONJOUR"] = "1";
        startInfo.Environment["OPENCLAW_DISABLE_MODEL_PRICING"] = "1";
        startInfo.Environment["OPENCLAW_STARTUP_SIDECARS_WAIT_MS"] = "0";
        startInfo.Environment["OPENCLAW_SKIP_STARTUP_MODEL_PREWARM"] = "1";
        startInfo.Environment["OPENCLAW_SKIP_TELEGRAM_MENU_SYNC"] = "1";
        startInfo.Environment["OPENCLAW_SKIP_STARTUP_INTERNAL_HOOKS"] = "1";
        startInfo.Environment["OPENCLAW_SKIP_STARTUP_OPTIONAL_SIDECARS"] = "1";
        startInfo.Environment["OPENCLAW_SKIP_STARTUP_HEARTBEATS"] = "1";
        startInfo.Environment["OPENCLAW_TELEGRAM_LIGHT_POLLING"] = "0";
        startInfo.Environment["OPENCLAW_TELEGRAM_MAX_COMMAND_HANDLERS"] = "100";
        startInfo.Environment["TEMP"] = _paths.TempRoot;
        startInfo.Environment["TMP"] = _paths.TempRoot;
        startInfo.Environment["SystemRoot"] = Environment.GetEnvironmentVariable("SystemRoot") ?? @"C:\Windows";
        startInfo.Environment["ComSpec"] = Environment.GetEnvironmentVariable("ComSpec") ?? @"C:\Windows\System32\cmd.exe";
        var userProfile = Environment.GetEnvironmentVariable("USERPROFILE") ?? Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
        startInfo.Environment["USERPROFILE"] = userProfile;
        startInfo.Environment["LOCALAPPDATA"] = Environment.GetEnvironmentVariable("LOCALAPPDATA") ?? Path.Combine(userProfile, "AppData", "Local");
        startInfo.Environment["APPDATA"] = Environment.GetEnvironmentVariable("APPDATA") ?? Path.Combine(userProfile, "AppData", "Roaming");
    }

    private void PersistLease(int gatewayPid, string reason)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(_paths.RuntimeLeasePath)!);
        var payload = new
        {
            generatedAt = DateTimeOffset.UtcNow.ToString("O"),
            managerPid = Environment.ProcessId,
            gatewayPid,
            reason,
            repoRoot = _paths.RepoRoot,
            configPath = _paths.ConfigPath,
            runtimeScriptPath = _paths.RuntimeScriptPath
        };
        File.WriteAllText(_paths.RuntimeLeasePath, JsonSerializer.Serialize(payload, JsonOptions.Indented), Encoding.UTF8);
    }

    private int ReadLeaseGatewayPid()
    {
        try
        {
            using var document = JsonDocument.Parse(File.ReadAllText(_paths.RuntimeLeasePath));
            return document.RootElement.GetInt32OrDefault("gatewayPid", 0);
        }
        catch
        {
            return 0;
        }
    }

    private DateTime ReadLeaseGeneratedAtUtc()
    {
        try
        {
            using var document = JsonDocument.Parse(File.ReadAllText(_paths.RuntimeLeasePath));
            var raw = document.RootElement.GetStringOrDefault("generatedAt");
            return DateTimeOffset.TryParse(raw, out var parsed) ? parsed.UtcDateTime : DateTime.MinValue;
        }
        catch
        {
            return DateTime.MinValue;
        }
    }
}

internal static class JsonOptions
{
    public static readonly JsonSerializerOptions Indented = new() { WriteIndented = true };
}
