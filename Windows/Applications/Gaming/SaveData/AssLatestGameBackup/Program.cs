using System.Diagnostics;
using System.Globalization;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Security.Principal;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.Win32;

namespace AssLatestGameBackup;

internal static class Program
{
    private const string BackupRoot = @"F:\backup\gamesaves";
    private static readonly StringComparer PathComparer = StringComparer.OrdinalIgnoreCase;
    private static readonly string Home = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
    private static readonly string LocalAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
    private static readonly string RoamingAppData = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
    private static readonly string Documents = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);

    public static int Main(string[] args)
    {
        try
        {
            if (args.Any(x => x.Equals("--watch", StringComparison.OrdinalIgnoreCase)))
            {
                return LaunchTracker.Run();
            }
            if (args.Any(x => x.Equals("--install-tracker", StringComparison.OrdinalIgnoreCase)))
            {
                LaunchTracker.InstallAndStart();
                Console.WriteLine($"TRACKER_OK ledger=\"{LaunchTracker.LedgerPath}\"");
                return 0;
            }

            var detectOnly = args.Any(x => x.Equals("--detect-only", StringComparison.OrdinalIgnoreCase));
            var jsonOnly = args.Any(x => x.Equals("--json", StringComparison.OrdinalIgnoreCase));
            WriteImmediateLine("ASS_PROGRESS stage=detecting-latest-game");
            var detector = new GameDetector();
            var selection = detector.DetectLatestGame();
            WriteImmediateLine(
                $"ASS_PROGRESS stage=game-resolved game=\"{selection.Title}\" " +
                $"detector={selection.PrimaryEvidence.Source} played_utc={selection.PrimaryEvidence.TimeUtc:O}");

            if (detectOnly)
            {
                Console.WriteLine(JsonSerializer.Serialize(selection.ToReport(), JsonOptions));
                return 0;
            }

            WriteImmediateLine("ASS_PROGRESS stage=creating-verified-backup");
            var receipt = BackupEngine.CreateVerifiedBackup(selection, BackupRoot);
            if (jsonOnly)
            {
                Console.WriteLine(JsonSerializer.Serialize(receipt, JsonOptions));
            }
            else
            {
                WriteImmediateLine(
                    $"DETECTED_GAME name=\"{selection.Title}\" detector={selection.PrimaryEvidence.Source} " +
                    $"played_utc={selection.PrimaryEvidence.TimeUtc:O} executable=\"{selection.ExecutablePath ?? ""}\"");
                WriteImmediateLine(
                    $"BACKUP_OK path={receipt.Path} files={receipt.Files} bytes={receipt.Bytes} " +
                    $"game=\"{selection.Title}\" played_utc={selection.PrimaryEvidence.TimeUtc:O}");
            }
            return 0;
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"BACKUP_FAILED {ex.Message}");
            Console.Error.Flush();
            return 1;
        }
    }

    internal static void WriteImmediateLine(string message)
    {
        Console.Out.WriteLine(message);
        Console.Out.Flush();
    }

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        WriteIndented = true
    };

    internal static class LaunchTracker
    {
        private const string RunValueName = "AssLatestGameTracker";
        private static readonly string StateRoot = Path.Combine(LocalAppData, "AssLatestGameBackup");
        public static readonly string LedgerPath = Path.Combine(StateRoot, "launch-history.jsonl");

        public static void InstallAndStart()
        {
            var executable = Environment.ProcessPath ??
                throw new InvalidOperationException("The tracker executable path could not be resolved.");
            var scriptPath = Path.Combine(Path.GetDirectoryName(executable)!, "AssLatestGameTracker.vbs");
            var script = "Set shell = CreateObject(\"WScript.Shell\")\r\n" +
                $"shell.Run \"\"\"{executable.Replace("\"", "\"\"")}\"\" --watch\", 0, False\r\n";
            File.WriteAllText(scriptPath, script, new UTF8Encoding(false));

            using (var run = Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\Run"))
            {
                run?.SetValue(RunValueName, $"wscript.exe //B //NoLogo \"{scriptPath}\"", RegistryValueKind.String);
            }

            Directory.CreateDirectory(StateRoot);
            Process.Start(new ProcessStartInfo
            {
                FileName = "wscript.exe",
                Arguments = $"//B //NoLogo \"{scriptPath}\"",
                UseShellExecute = false,
                CreateNoWindow = true,
                WindowStyle = ProcessWindowStyle.Hidden
            });
        }

        public static int Run()
        {
            using var mutex = new Mutex(true, @"Local\AssLatestGameBackup.LaunchTracker", out var ownsMutex);
            if (!ownsMutex)
            {
                return 0;
            }

            Directory.CreateDirectory(StateRoot);
            PruneLedger();
            var previous = new HashSet<int>();
            var nextPrune = DateTimeOffset.UtcNow.AddHours(12);
            while (true)
            {
                var current = new HashSet<int>();
                foreach (var process in Process.GetProcesses())
                {
                    try
                    {
                        current.Add(process.Id);
                        if (!previous.Contains(process.Id))
                        {
                            var launch = TryReadLaunch(process);
                            if (launch is not null)
                            {
                                Append(launch);
                            }
                        }
                    }
                    finally
                    {
                        process.Dispose();
                    }
                }
                previous = current;
                if (DateTimeOffset.UtcNow >= nextPrune)
                {
                    PruneLedger();
                    nextPrune = DateTimeOffset.UtcNow.AddHours(12);
                }
                Thread.Sleep(250);
            }
        }

        public static IReadOnlyList<LaunchRecord> ReadHistory()
        {
            if (!File.Exists(LedgerPath))
            {
                return [];
            }

            var records = new List<LaunchRecord>();
            try
            {
                using var stream = new FileStream(
                    LedgerPath, FileMode.Open, FileAccess.Read,
                    FileShare.ReadWrite | FileShare.Delete);
                using var reader = new StreamReader(stream, Encoding.UTF8, true);
                string? line;
                while ((line = reader.ReadLine()) is not null)
                {
                    try
                    {
                        var record = JsonSerializer.Deserialize<LaunchRecord>(line);
                        if (record is not null)
                        {
                            records.Add(record);
                        }
                    }
                    catch
                    {
                        // A partial final line can exist while the watcher is appending.
                    }
                }
            }
            catch
            {
                return [];
            }
            return records
                .GroupBy(
                    x => $"{x.ExecutablePath}|{x.StartedUtc.UtcTicks}",
                    StringComparer.OrdinalIgnoreCase)
                .Select(x => x.First())
                .OrderByDescending(x => x.StartedUtc)
                .ToArray();
        }

        private static LaunchRecord? TryReadLaunch(Process process)
        {
            try
            {
                var executablePath = process.MainModule?.FileName;
                if (!string.IsNullOrWhiteSpace(executablePath))
                {
                    return new LaunchRecord(
                        process.Id,
                        executablePath,
                        new DateTimeOffset(process.StartTime.ToUniversalTime(), TimeSpan.Zero));
                }
            }
            catch
            {
                // Protected and terminating processes are expected.
            }
            return null;
        }

        private static void Append(LaunchRecord launch)
        {
            try
            {
                var line = JsonSerializer.Serialize(launch) + Environment.NewLine;
                using var stream = new FileStream(
                    LedgerPath, FileMode.Append, FileAccess.Write,
                    FileShare.ReadWrite | FileShare.Delete);
                using var writer = new StreamWriter(stream, new UTF8Encoding(false));
                writer.Write(line);
            }
            catch
            {
                // The next Windows telemetry source remains available if one append fails.
            }
        }

        private static void PruneLedger()
        {
            var records = ReadHistory()
                .OrderBy(x => x.StartedUtc)
                .ToArray();
            var temporary = LedgerPath + ".tmp-" + Guid.NewGuid().ToString("N");
            try
            {
                using (var stream = new FileStream(temporary, FileMode.CreateNew, FileAccess.Write, FileShare.None))
                using (var writer = new StreamWriter(stream, new UTF8Encoding(false)))
                {
                    foreach (var record in records)
                    {
                        writer.WriteLine(JsonSerializer.Serialize(record));
                    }
                }
                File.Move(temporary, LedgerPath, true);
            }
            finally
            {
                if (File.Exists(temporary))
                {
                    File.Delete(temporary);
                }
            }
        }
    }

    internal sealed class GameDetector
    {
        private readonly Dictionary<string, Candidate> _candidates = new(StringComparer.OrdinalIgnoreCase);
        private readonly Dictionary<string, string> _deviceMap = BuildDeviceMap();
        private HashSet<string> _manifestExecutableNames = new(StringComparer.OrdinalIgnoreCase);

        public GameSelection DetectLatestGame()
        {
            var manifestPaths = FindManifestPaths();
            _manifestExecutableNames = ManifestMatcher.ReadLaunchExecutableNames(manifestPaths);
            CollectTrackerEvidence();
            CollectBamEvidence();
            CollectRunningProcesses();
            CollectUserAssistEvidence();
            CollectSteamEvidence();
            if (_candidates.Count == 0)
            {
                CollectInstalledDirectories();
            }
            CollectPrefetchEvidence();

            if (_candidates.Count == 0)
            {
                throw new InvalidOperationException("No game candidates were found in Windows launch history or installed game roots.");
            }

            if (manifestPaths.Count > 0)
            {
                ManifestMatcher.Match(_candidates.Values, manifestPaths);
            }
            foreach (var candidate in _candidates.Values)
            {
                ResolveSaveSources(candidate);
            }

            var launchBacked = _candidates.Values
                .Where(x => x.IsGameQualified && x.Evidence.Any(e => e.IsLaunchEvidence))
                .OrderByDescending(x => x.LatestLaunchEvidence!.TimeUtc)
                .ThenByDescending(x => x.LatestLaunchEvidence!.Priority)
                .ToList();
            var selected = launchBacked.FirstOrDefault();
            if (selected is null)
            {
                selected = _candidates.Values
                    .Where(x => x.SaveSources.Count > 0 || x.RegistryKeys.Count > 0)
                    .OrderByDescending(x => x.NewestSaveUtc)
                    .FirstOrDefault();
            }
            if (selected is null)
            {
                throw new InvalidOperationException("No game with launch or save activity could be selected.");
            }
            if (selected.SaveSources.Count == 0 && selected.RegistryKeys.Count == 0)
            {
                throw new InvalidOperationException(
                    $"The latest played game was '{selected.DisplayHint}', but no save files or save registry keys could be resolved automatically.");
            }
            var primary = selected.LatestLaunchEvidence ??
                new Evidence("save-activity", selected.NewestSaveUtc, 50, null, false);

            return new GameSelection(
                selected.Manifest?.Title ?? selected.DisplayHint,
                selected.InstallRoot,
                selected.ExecutablePath,
                primary,
                selected.Evidence.OrderByDescending(x => x.TimeUtc).ToArray(),
                selected.SaveSources.Distinct(PathComparer).ToArray(),
                selected.RegistryKeys.Distinct(StringComparer.OrdinalIgnoreCase).ToArray(),
                selected.Manifest?.Title);
        }

        private void CollectTrackerEvidence()
        {
            foreach (var launch in LaunchTracker.ReadHistory())
            {
                AddExecutableEvidence(launch.ExecutablePath, new Evidence(
                    "persistent-tracker", launch.StartedUtc, 105, launch.ExecutablePath, true));
            }
        }

        private void CollectInstalledDirectories()
        {
            foreach (var root in FindInstallRoots())
            {
                try
                {
                    if (!Directory.Exists(root))
                    {
                        continue;
                    }

                    foreach (var directory in Directory.EnumerateDirectories(root))
                    {
                        var name = Path.GetFileName(directory);
                        if (IsLauncherOrTool(name))
                        {
                            continue;
                        }
                        AddCandidate(name, directory, null, null);
                    }
                }
                catch
                {
                    // An unreadable library must not block other detectors.
                }
            }
        }

        private void CollectBamEvidence()
        {
            var sid = WindowsIdentity.GetCurrent().User?.Value;
            if (string.IsNullOrWhiteSpace(sid))
            {
                return;
            }

            using var key = Registry.LocalMachine.OpenSubKey(
                $@"SYSTEM\CurrentControlSet\Services\bam\State\UserSettings\{sid}");
            if (key is null)
            {
                return;
            }

            foreach (var name in key.GetValueNames())
            {
                if (key.GetValue(name) is not byte[] data || data.Length < 8)
                {
                    continue;
                }

                try
                {
                    var fileTime = BitConverter.ToInt64(data, 0);
                    if (fileTime <= 0)
                    {
                        continue;
                    }
                    var time = new DateTimeOffset(DateTime.FromFileTimeUtc(fileTime), TimeSpan.Zero);
                    if (!name.StartsWith(@"\Device\", StringComparison.OrdinalIgnoreCase))
                    {
                        AddPackagedGameEvidence(name, time);
                        continue;
                    }
                    var path = DevicePathToDosPath(name);
                    AddExecutableEvidence(path, new Evidence(
                        "bam", time,
                        95, path, true));
                }
                catch
                {
                    // Ignore malformed BAM values.
                }
            }
        }

        private void AddPackagedGameEvidence(string packageIdentity, DateTimeOffset time)
        {
            if (packageIdentity.StartsWith("Microsoft.Windows", StringComparison.OrdinalIgnoreCase) ||
                packageIdentity.StartsWith("MicrosoftCorporationII.", StringComparison.OrdinalIgnoreCase) ||
                packageIdentity.StartsWith("Microsoft.Xbox", StringComparison.OrdinalIgnoreCase) ||
                packageIdentity.StartsWith("Microsoft.Gaming", StringComparison.OrdinalIgnoreCase))
            {
                return;
            }

            var packagesRoot = Path.Combine(LocalAppData, "Packages");
            if (!Directory.Exists(packagesRoot))
            {
                return;
            }

            IEnumerable<string> matches;
            try
            {
                var family = packageIdentity.Split('!')[0];
                matches = Directory.EnumerateDirectories(packagesRoot, family + "*");
            }
            catch
            {
                return;
            }

            foreach (var packageRoot in matches)
            {
                var wgs = Path.Combine(packageRoot, "SystemAppData", "wgs");
                var localState = Path.Combine(packageRoot, "LocalState");
                var saveRoot = Directory.Exists(wgs) ? wgs : Directory.Exists(localState) ? localState : null;
                if (saveRoot is null)
                {
                    continue;
                }

                var hint = packageIdentity.Split('_', '!')[0];
                var candidate = AddCandidate(hint, packageRoot, null, new Evidence(
                    "bam-package", time, 96, packageIdentity, true));
                candidate.StrongGamePath |= Directory.Exists(wgs);
                candidate.SaveSources.Add(saveRoot);
            }
        }

        private void CollectRunningProcesses()
        {
            foreach (var process in Process.GetProcesses())
            {
                try
                {
                    var path = process.MainModule?.FileName;
                    if (string.IsNullOrWhiteSpace(path))
                    {
                        continue;
                    }
                    var started = process.StartTime.ToUniversalTime();
                    AddExecutableEvidence(path, new Evidence(
                        "running-process", new DateTimeOffset(started, TimeSpan.Zero),
                        110, path, true));
                }
                catch
                {
                    // Protected processes are expected.
                }
                finally
                {
                    process.Dispose();
                }
            }
        }

        private void CollectUserAssistEvidence()
        {
            using var root = Registry.CurrentUser.OpenSubKey(
                @"Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist");
            if (root is null)
            {
                return;
            }

            foreach (var guid in root.GetSubKeyNames())
            {
                using var count = root.OpenSubKey($@"{guid}\Count");
                if (count is null)
                {
                    continue;
                }

                foreach (var encodedName in count.GetValueNames())
                {
                    if (count.GetValue(encodedName) is not byte[] data || data.Length < 68)
                    {
                        continue;
                    }

                    try
                    {
                        var decoded = Rot13(encodedName);
                        var path = ExtractPathFromUserAssist(decoded);
                        if (path is null)
                        {
                            continue;
                        }
                        var fileTime = BitConverter.ToInt64(data, 60);
                        if (fileTime <= 0)
                        {
                            continue;
                        }
                        AddExecutableEvidence(path, new Evidence(
                            "userassist", new DateTimeOffset(DateTime.FromFileTimeUtc(fileTime), TimeSpan.Zero),
                            85, path, true));
                    }
                    catch
                    {
                        // UserAssist layouts vary across Windows builds.
                    }
                }
            }
        }

        private void CollectSteamEvidence()
        {
            var steamRoots = FindSteamRoots();
            var apps = new Dictionary<string, (string Name, string InstallRoot)>();
            foreach (var root in steamRoots)
            {
                var steamApps = Path.Combine(root, "steamapps");
                if (!Directory.Exists(steamApps))
                {
                    continue;
                }
                foreach (var manifest in Directory.EnumerateFiles(steamApps, "appmanifest_*.acf"))
                {
                    try
                    {
                        var text = File.ReadAllText(manifest);
                        var appId = Regex.Match(text, "\"appid\"\\s*\"(?<v>\\d+)\"", RegexOptions.IgnoreCase).Groups["v"].Value;
                        var name = Regex.Match(text, "\"name\"\\s*\"(?<v>[^\"]+)\"", RegexOptions.IgnoreCase).Groups["v"].Value;
                        var installDir = Regex.Match(text, "\"installdir\"\\s*\"(?<v>[^\"]+)\"", RegexOptions.IgnoreCase).Groups["v"].Value;
                        if (appId.Length > 0 && name.Length > 0)
                        {
                            apps[appId] = (name, Path.Combine(steamApps, "common", installDir));
                        }
                    }
                    catch
                    {
                        // Ignore incomplete Steam manifests.
                    }
                }
            }

            foreach (var root in steamRoots)
            {
                var userData = Path.Combine(root, "userdata");
                if (!Directory.Exists(userData))
                {
                    continue;
                }
                foreach (var localConfig in Directory.EnumerateFiles(userData, "localconfig.vdf", SearchOption.AllDirectories))
                {
                    try
                    {
                        var text = File.ReadAllText(localConfig);
                        var matches = Regex.Matches(
                            text,
                            "\"(?<id>\\d+)\"\\s*\\{(?<body>.*?)\\}",
                            RegexOptions.Singleline);
                        foreach (Match match in matches)
                        {
                            var lastPlayed = Regex.Match(
                                match.Groups["body"].Value,
                                "\"LastPlayed\"\\s*\"(?<ts>\\d+)\"",
                                RegexOptions.IgnoreCase);
                            if (!lastPlayed.Success ||
                                !long.TryParse(lastPlayed.Groups["ts"].Value, out var seconds) ||
                                seconds <= 0 ||
                                !apps.TryGetValue(match.Groups["id"].Value, out var app))
                            {
                                continue;
                            }
                            var evidence = new Evidence(
                                "steam-lastplayed", DateTimeOffset.FromUnixTimeSeconds(seconds),
                                90, null, true);
                            var candidate = AddCandidate(app.Name, app.InstallRoot, null, evidence);
                            candidate.SteamAppId = match.Groups["id"].Value;
                        }
                    }
                    catch
                    {
                        // One user's corrupt VDF must not block another.
                    }
                }
            }
        }

        private void CollectPrefetchEvidence()
        {
            const string prefetchRoot = @"C:\Windows\Prefetch";
            if (!Directory.Exists(prefetchRoot))
            {
                return;
            }

            var byExe = _candidates.Values
                .Where(x => !string.IsNullOrWhiteSpace(x.ExecutablePath))
                .GroupBy(x => Path.GetFileNameWithoutExtension(x.ExecutablePath!), StringComparer.OrdinalIgnoreCase)
                .ToDictionary(x => x.Key, x => x.ToArray(), StringComparer.OrdinalIgnoreCase);
            try
            {
                foreach (var file in Directory.EnumerateFiles(prefetchRoot, "*.pf"))
                {
                    var baseName = Path.GetFileNameWithoutExtension(file);
                    var dash = baseName.LastIndexOf('-');
                    if (dash > 0)
                    {
                        baseName = baseName[..dash];
                    }
                    if (!byExe.TryGetValue(baseName, out var candidates))
                    {
                        continue;
                    }
                    var time = new DateTimeOffset(File.GetLastWriteTimeUtc(file), TimeSpan.Zero);
                    foreach (var candidate in candidates)
                    {
                        candidate.Evidence.Add(new Evidence("prefetch", time, 75, candidate.ExecutablePath, true));
                    }
                }
            }
            catch
            {
                // Prefetch can be disabled or access-restricted.
            }
        }

        private void AddExecutableEvidence(string? executablePath, Evidence evidence)
        {
            if (string.IsNullOrWhiteSpace(executablePath) ||
                !executablePath.EndsWith(".exe", StringComparison.OrdinalIgnoreCase) ||
                IsExcludedExecutable(executablePath) ||
                IsKnownDesktopUtility(executablePath))
            {
                return;
            }

            var root = ExtractInstallRoot(executablePath);
            var strongGamePath = root is not null;
            if (root is null)
            {
                root = Path.GetDirectoryName(executablePath);
            }
            if (string.IsNullOrWhiteSpace(root))
            {
                return;
            }
            strongGamePath |= LooksLikeGameInstall(root, executablePath);
            if (!strongGamePath && !_manifestExecutableNames.Contains(Path.GetFileName(executablePath)))
            {
                return;
            }
            var hint = GetExecutableHint(executablePath, root);
            var candidate = AddCandidate(hint, root, executablePath, evidence);
            candidate.StrongGamePath |= strongGamePath;
        }

        private Candidate AddCandidate(string hint, string installRoot, string? executablePath, Evidence? evidence)
        {
            var fullRoot = SafeFullPath(installRoot) ?? installRoot;
            var key = Normalize(hint) + "|" + fullRoot.ToUpperInvariant();
            if (!_candidates.TryGetValue(key, out var candidate))
            {
                candidate = new Candidate(hint, fullRoot);
                _candidates[key] = candidate;
            }
            if (!string.IsNullOrWhiteSpace(executablePath))
            {
                candidate.ExecutablePath = executablePath;
            }
            if (evidence is not null)
            {
                candidate.Evidence.Add(evidence);
            }
            return candidate;
        }

        private static string GetExecutableHint(string executablePath, string root)
        {
            try
            {
                var info = FileVersionInfo.GetVersionInfo(executablePath);
                foreach (var value in new[] { info.ProductName, info.FileDescription })
                {
                    if (!string.IsNullOrWhiteSpace(value) && !IsGenericExecutableHint(value))
                    {
                        return value.Trim();
                    }
                }
            }
            catch
            {
                // File metadata is optional.
            }
            return Path.GetFileName(root.TrimEnd(Path.DirectorySeparatorChar));
        }

        private static bool IsGenericExecutableHint(string value) =>
            Regex.IsMatch(value, "(?i)^(application|launcher|game|shipping|client|win64|win32)$");

        private static bool LooksLikeGameInstall(string directory, string executablePath)
        {
            var normalized = executablePath.Replace('/', '\\');
            if (Regex.IsMatch(normalized, @"(?i)\\Binaries\\(Win64|Win32)\\[^\\]+\.exe$"))
            {
                return true;
            }
            foreach (var marker in new[]
            {
                "UnityPlayer.dll", "GameAssembly.dll", "steam_api.dll", "steam_api64.dll",
                "EOSSDK-Win64-Shipping.dll", "goggame-*.info"
            })
            {
                try
                {
                    if (Directory.EnumerateFiles(directory, marker, SearchOption.TopDirectoryOnly).Any())
                    {
                        return true;
                    }
                }
                catch
                {
                    return false;
                }
            }
            return false;
        }

        private void ResolveSaveSources(Candidate candidate)
        {
            if (candidate.Manifest is not null)
            {
                var saveSpecs = candidate.Manifest.Files.Where(x => x.IsSave).ToList();
                if (saveSpecs.Count == 0)
                {
                    saveSpecs = candidate.Manifest.Files;
                }
                foreach (var spec in saveSpecs)
                {
                    foreach (var path in ExpandManifestPath(spec.Path, candidate.InstallRoot))
                    {
                        if (File.Exists(path) || Directory.Exists(path))
                        {
                            candidate.SaveSources.Add(path);
                        }
                    }
                }
                candidate.RegistryKeys.AddRange(candidate.Manifest.RegistryKeys);
            }

            if (candidate.SaveSources.Count == 0)
            {
                foreach (var path in HeuristicSavePaths(candidate))
                {
                    if (File.Exists(path) || Directory.Exists(path))
                    {
                        candidate.SaveSources.Add(path);
                    }
                }
            }

            candidate.NewestSaveUtc = candidate.SaveSources
                .Select(GetNewestWriteUtc)
                .DefaultIfEmpty(DateTimeOffset.MinValue)
                .Max();
        }

        private IEnumerable<string> HeuristicSavePaths(Candidate candidate)
        {
            yield return Path.Combine(candidate.InstallRoot, "userdata", "saves");
            yield return Path.Combine(candidate.InstallRoot, "saves");
            yield return Path.Combine(candidate.InstallRoot, "save");
            yield return Path.Combine(candidate.InstallRoot, "Saved", "SaveGames");

            var hints = new[]
            {
                candidate.DisplayHint,
                candidate.Manifest?.Title ?? ""
            }.Where(x => x.Length > 0).Select(Normalize).Distinct().ToArray();

            foreach (var root in new[] { LocalAppData, RoamingAppData, Path.Combine(Documents, "My Games") })
            {
                if (!Directory.Exists(root))
                {
                    continue;
                }
                IEnumerable<string> children;
                try
                {
                    children = Directory.EnumerateDirectories(root);
                }
                catch
                {
                    continue;
                }
                foreach (var child in children)
                {
                    var normalized = Normalize(Path.GetFileName(child));
                    if (!hints.Any(h => h == normalized || h.Contains(normalized) || normalized.Contains(h)))
                    {
                        continue;
                    }
                    yield return Path.Combine(child, "Saved", "SaveGames");
                    yield return Path.Combine(child, "SaveGames");
                    yield return Path.Combine(child, "saves");
                    yield return child;
                }
            }
        }

        private IEnumerable<string> ExpandManifestPath(string value, string installRoot)
        {
            var path = value
                .Replace("<base>", installRoot, StringComparison.OrdinalIgnoreCase)
                .Replace("<root>", Path.GetDirectoryName(installRoot) ?? installRoot, StringComparison.OrdinalIgnoreCase)
                .Replace("<home>", Home, StringComparison.OrdinalIgnoreCase)
                .Replace("<winAppData>", RoamingAppData, StringComparison.OrdinalIgnoreCase)
                .Replace("<winLocalAppData>", LocalAppData, StringComparison.OrdinalIgnoreCase)
                .Replace("<winDocuments>", Documents, StringComparison.OrdinalIgnoreCase)
                .Replace("<osUserName>", Environment.UserName, StringComparison.OrdinalIgnoreCase)
                .Replace("<storeUserId>", "*", StringComparison.OrdinalIgnoreCase)
                .Replace('/', Path.DirectorySeparatorChar);
            path = Environment.ExpandEnvironmentVariables(path);
            if (Regex.IsMatch(path, "<[^>]+>"))
            {
                yield break;
            }
            if (!path.Contains('*') && !path.Contains('?'))
            {
                yield return path;
                yield break;
            }
            foreach (var match in ExpandGlob(path))
            {
                yield return match;
            }
        }

        private static IEnumerable<string> ExpandGlob(string pattern)
        {
            var wildcard = pattern.IndexOfAny(['*', '?']);
            if (wildcard < 0)
            {
                yield return pattern;
                yield break;
            }
            var separator = pattern.LastIndexOf(Path.DirectorySeparatorChar, wildcard);
            var fixedRoot = separator >= 0 ? pattern[..separator] : Path.GetPathRoot(pattern);
            if (string.IsNullOrWhiteSpace(fixedRoot) || !Directory.Exists(fixedRoot))
            {
                yield break;
            }
            var regex = new Regex(
                "^" + Regex.Escape(pattern)
                    .Replace("\\*", ".*")
                    .Replace("\\?", ".") + "$",
                RegexOptions.IgnoreCase);
            var seen = 0;
            var options = new EnumerationOptions
            {
                RecurseSubdirectories = true,
                IgnoreInaccessible = true,
                AttributesToSkip = FileAttributes.ReparsePoint
            };
            foreach (var entry in Directory.EnumerateFileSystemEntries(fixedRoot, "*", options))
            {
                if (++seen > 100000)
                {
                    yield break;
                }
                if (regex.IsMatch(entry))
                {
                    yield return entry;
                }
            }
        }

        private string DevicePathToDosPath(string path)
        {
            foreach (var pair in _deviceMap.OrderByDescending(x => x.Key.Length))
            {
                if (path.StartsWith(pair.Key, StringComparison.OrdinalIgnoreCase))
                {
                    return pair.Value + path[pair.Key.Length..];
                }
            }
            return path;
        }

        private static Dictionary<string, string> BuildDeviceMap()
        {
            var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            for (var letter = 'A'; letter <= 'Z'; letter++)
            {
                var drive = $"{letter}:";
                var buffer = new char[1024];
                var length = QueryDosDevice(drive, buffer, buffer.Length);
                if (length == 0)
                {
                    continue;
                }
                var target = new string(buffer, 0, (int)length).TrimEnd('\0');
                if (target.Length > 0)
                {
                    result[target] = drive;
                }
            }
            return result;
        }

        private static List<string> FindManifestPaths()
        {
            var root = Path.Combine(RoamingAppData, "ludusavi");
            if (!Directory.Exists(root))
            {
                return [];
            }
            return Directory.EnumerateFiles(root, "manifest*.yaml")
                .OrderByDescending(x => Path.GetFileName(x).Equals("manifest.yaml", StringComparison.OrdinalIgnoreCase))
                .ThenByDescending(File.GetLastWriteTimeUtc)
                .ToList();
        }

        private static IEnumerable<string> FindInstallRoots()
        {
            var roots = new HashSet<string>(PathComparer)
            {
                @"C:\Program Files\Epic Games",
                @"C:\Program Files\GOG Galaxy\Games",
                @"C:\GOG Games",
                @"C:\XboxGames",
                @"E:\games",
                @"E:\Games",
                @"E:\XboxGames",
                @"F:\games",
                @"F:\Games",
                @"F:\XboxGames"
            };
            foreach (var steam in FindSteamRoots())
            {
                roots.Add(Path.Combine(steam, "steamapps", "common"));
                var libraryFile = Path.Combine(steam, "steamapps", "libraryfolders.vdf");
                if (!File.Exists(libraryFile))
                {
                    continue;
                }
                try
                {
                    foreach (Match match in Regex.Matches(
                        File.ReadAllText(libraryFile),
                        "\"path\"\\s*\"(?<path>[^\"]+)\"",
                        RegexOptions.IgnoreCase))
                    {
                        roots.Add(Path.Combine(match.Groups["path"].Value.Replace(@"\\", @"\"), "steamapps", "common"));
                    }
                }
                catch
                {
                    // Ignore stale Steam metadata.
                }
            }
            return roots;
        }

        private static HashSet<string> FindSteamRoots()
        {
            var roots = new HashSet<string>(PathComparer)
            {
                @"C:\Program Files (x86)\Steam",
                @"C:\Program Files\Steam"
            };
            using var key = Registry.CurrentUser.OpenSubKey(@"Software\Valve\Steam");
            foreach (var name in new[] { "SteamPath", "InstallPath" })
            {
                if (key?.GetValue(name) is string path && path.Length > 0)
                {
                    roots.Add(path.Replace('/', '\\'));
                }
            }
            return roots;
        }

        private static string? ExtractInstallRoot(string path)
        {
            var normalized = path.Replace('/', '\\');
            foreach (var marker in new[]
            {
                @"\steamapps\common\",
                @"\Epic Games\",
                @"\GOG Games\",
                @"\XboxGames\",
                @"\games\"
            })
            {
                var index = normalized.IndexOf(marker, StringComparison.OrdinalIgnoreCase);
                if (index < 0)
                {
                    continue;
                }
                var start = index + marker.Length;
                var end = normalized.IndexOf('\\', start);
                if (end < 0)
                {
                    end = normalized.Length;
                }
                return normalized[..end];
            }
            return null;
        }

        private static bool IsExcludedExecutable(string path)
        {
            var normalizedPath = path.Replace('/', '\\');
            if (normalizedPath.StartsWith(Environment.GetFolderPath(Environment.SpecialFolder.Windows), StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }
            if (normalizedPath.Contains(@"\Program Files\WindowsApps\", StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }
            if (normalizedPath.Contains(@"\OpenAI\Codex\", StringComparison.OrdinalIgnoreCase) ||
                normalizedPath.Contains(@"\.codex\", StringComparison.OrdinalIgnoreCase) ||
                normalizedPath.Contains(@"\GitHub CLI\", StringComparison.OrdinalIgnoreCase) ||
                normalizedPath.Contains(@"\node_modules\", StringComparison.OrdinalIgnoreCase) ||
                normalizedPath.Contains(@"\Program Files\Sunshine\", StringComparison.OrdinalIgnoreCase) ||
                normalizedPath.Contains(@"\Program Files\Moonlight\", StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }
            var name = Path.GetFileNameWithoutExtension(path);
            return Regex.IsMatch(
                name,
                "(?i)(crash|crashhandler|reportclient|unitycrash|easyanticheat|battleye|launcher|setup|install|unins|redistribut|prereq|updater|overlay|helper|service|benchmark|configuration|sunshine|sunshinesvc|moonlight|asslatestgamebackup|powershell|pwsh|cmd|conhost|dotnet|msbuild|vstest|wscript|cscript|node|python|pythonw|java|javaw|electron|chrome|msedge|firefox)");
        }

        private static bool IsKnownDesktopUtility(string path)
        {
            try
            {
                var company = FileVersionInfo.GetVersionInfo(path).CompanyName;
                return string.Equals(company?.Trim(), "voidtools", StringComparison.OrdinalIgnoreCase);
            }
            catch
            {
                return false;
            }
        }

        private static bool IsLauncherOrTool(string name) =>
            Regex.IsMatch(name, "(?i)launcher|directx|redist|support|engine|common|tools|installer|sunshine|moonlight");

        private static string? ExtractPathFromUserAssist(string value)
        {
            var colon = value.IndexOf(':');
            if (value.StartsWith("UEME_", StringComparison.OrdinalIgnoreCase) && colon >= 0)
            {
                value = value[(colon + 1)..];
            }
            value = Environment.ExpandEnvironmentVariables(value.Trim('"'));
            return Regex.IsMatch(value, "^[A-Za-z]:\\\\.*\\.exe$", RegexOptions.IgnoreCase) ? value : null;
        }

        private static string Rot13(string value)
        {
            var chars = value.ToCharArray();
            for (var i = 0; i < chars.Length; i++)
            {
                var c = chars[i];
                if (c is >= 'a' and <= 'z')
                {
                    chars[i] = (char)('a' + (c - 'a' + 13) % 26);
                }
                else if (c is >= 'A' and <= 'Z')
                {
                    chars[i] = (char)('A' + (c - 'A' + 13) % 26);
                }
            }
            return new string(chars);
        }

        private static string? SafeFullPath(string path)
        {
            try
            {
                return Path.GetFullPath(path);
            }
            catch
            {
                return null;
            }
        }

        private static string Normalize(string value) =>
            Regex.Replace(value.ToLowerInvariant(), "[^a-z0-9]+", "");

        private static DateTimeOffset GetNewestWriteUtc(string path)
        {
            try
            {
                if (File.Exists(path))
                {
                    return new DateTimeOffset(File.GetLastWriteTimeUtc(path), TimeSpan.Zero);
                }
                if (!Directory.Exists(path))
                {
                    return DateTimeOffset.MinValue;
                }
                var newest = new DateTimeOffset(Directory.GetLastWriteTimeUtc(path), TimeSpan.Zero);
                var options = new EnumerationOptions
                {
                    RecurseSubdirectories = true,
                    IgnoreInaccessible = true,
                    AttributesToSkip = FileAttributes.ReparsePoint
                };
                foreach (var file in Directory.EnumerateFiles(path, "*", options))
                {
                    var time = new DateTimeOffset(File.GetLastWriteTimeUtc(file), TimeSpan.Zero);
                    if (time > newest)
                    {
                        newest = time;
                    }
                }
                return newest;
            }
            catch
            {
                return DateTimeOffset.MinValue;
            }
        }

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern uint QueryDosDevice(string lpDeviceName, char[] lpTargetPath, int ucchMax);
    }

    internal static class ManifestMatcher
    {
        public static HashSet<string> ReadLaunchExecutableNames(IReadOnlyList<string> manifestPaths)
        {
            var names = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach (var path in manifestPaths)
            {
                try
                {
                    using var reader = new StreamReader(path, Encoding.UTF8, true, 1024 * 64);
                    var section = "";
                    string? line;
                    while ((line = reader.ReadLine()) is not null)
                    {
                        var indent = line.TakeWhile(char.IsWhiteSpace).Count();
                        var trimmed = line.Trim();
                        if (indent == 2 && trimmed.EndsWith(':'))
                        {
                            section = trimmed[..^1];
                            continue;
                        }
                        if (indent == 4 &&
                            section.Equals("launch", StringComparison.OrdinalIgnoreCase) &&
                            TryReadYamlMapKey(trimmed, out var launch))
                        {
                            var name = Path.GetFileName(launch.Replace('/', '\\'));
                            if (name.EndsWith(".exe", StringComparison.OrdinalIgnoreCase))
                            {
                                names.Add(name);
                            }
                        }
                    }
                }
                catch
                {
                    // One unavailable manifest must not block the other local copies.
                }
            }
            return names;
        }

        public static void Match(IEnumerable<Candidate> candidates, IReadOnlyList<string> manifestPaths)
        {
            var list = candidates.ToArray();
            foreach (var path in manifestPaths)
            {
                try
                {
                    ScanManifest(path, list);
                }
                catch
                {
                    // A secondary manifest must not invalidate the primary manifest.
                }
            }
        }

        private static void ScanManifest(string path, IReadOnlyList<Candidate> candidates)
        {
            using var reader = new StreamReader(path, Encoding.UTF8, true, 1024 * 64);
            ManifestEntry? current = null;
            string section = "";
            SaveSpec? currentFile = null;
            string? line;
            while ((line = reader.ReadLine()) is not null)
            {
                if (TryReadTopLevelKey(line, out var title))
                {
                    if (current is not null)
                    {
                        Evaluate(current, candidates);
                    }
                    current = new ManifestEntry(title);
                    section = "";
                    currentFile = null;
                    continue;
                }
                if (current is null)
                {
                    continue;
                }

                var indent = line.TakeWhile(char.IsWhiteSpace).Count();
                var trimmed = line.Trim();
                if (indent == 2 && trimmed.EndsWith(':'))
                {
                    section = trimmed[..^1];
                    currentFile = null;
                    continue;
                }
                if (indent == 4 && section.Equals("files", StringComparison.OrdinalIgnoreCase) &&
                    TryReadYamlMapKey(trimmed, out var filePath))
                {
                    currentFile = new SaveSpec(filePath);
                    current.Files.Add(currentFile);
                    continue;
                }
                if (currentFile is not null && indent >= 6 && trimmed.Equals("- save", StringComparison.OrdinalIgnoreCase))
                {
                    currentFile.IsSave = true;
                    continue;
                }
                if (indent == 4 && section.Equals("installDir", StringComparison.OrdinalIgnoreCase) &&
                    TryReadYamlMapKey(trimmed, out var installDir))
                {
                    current.InstallDirs.Add(installDir);
                    continue;
                }
                if (indent == 4 && section.Equals("launch", StringComparison.OrdinalIgnoreCase) &&
                    TryReadYamlMapKey(trimmed, out var launch))
                {
                    current.LaunchPaths.Add(launch);
                    continue;
                }
                if (indent == 4 && section.Equals("registry", StringComparison.OrdinalIgnoreCase) &&
                    TryReadYamlMapKey(trimmed, out var registry))
                {
                    current.RegistryKeys.Add(registry);
                    continue;
                }
                if (indent == 4 && section.Equals("steam", StringComparison.OrdinalIgnoreCase) &&
                    trimmed.StartsWith("id:", StringComparison.OrdinalIgnoreCase))
                {
                    current.SteamAppId = trimmed[3..].Trim();
                }
            }
            if (current is not null)
            {
                Evaluate(current, candidates);
            }
        }

        private static void Evaluate(ManifestEntry entry, IReadOnlyList<Candidate> candidates)
        {
            var title = Normalize(entry.Title);
            var launchNames = entry.LaunchPaths
                .Select(x => Path.GetFileName(x.Replace('/', '\\')))
                .Where(x => x.EndsWith(".exe", StringComparison.OrdinalIgnoreCase))
                .ToHashSet(StringComparer.OrdinalIgnoreCase);
            foreach (var candidate in candidates.Where(candidate =>
            {
                if (!string.IsNullOrWhiteSpace(candidate.ExecutablePath) &&
                    launchNames.Contains(Path.GetFileName(candidate.ExecutablePath)))
                {
                    return true;
                }
                var hint = Normalize(candidate.DisplayHint);
                var folder = Normalize(Path.GetFileName(candidate.InstallRoot.TrimEnd('\\')));
                return title == hint || title == folder ||
                    (hint.Length >= 6 && (title.Contains(hint) || hint.Contains(title))) ||
                    (folder.Length >= 6 && (title.Contains(folder) || folder.Contains(title)));
            }))
            {
                var hint = Normalize(candidate.DisplayHint);
                var folder = Normalize(Path.GetFileName(candidate.InstallRoot.TrimEnd('\\')));
                var score = 0;
                var exactNameMatch = title.Length > 0 && (title == hint || title == folder);
                var fuzzyNameMatch =
                    (hint.Length >= 6 && title.Length >= 6 && (title.Contains(hint) || hint.Contains(title))) ||
                    (folder.Length >= 6 && title.Length >= 6 && (title.Contains(folder) || folder.Contains(title)));
                if (exactNameMatch)
                {
                    score = 1000;
                }
                else if (fuzzyNameMatch)
                {
                    score = 780;
                }
                var installDirectoryMatch = folder.Length > 0 &&
                    entry.InstallDirs.Any(x => Normalize(x) == folder);
                if (installDirectoryMatch)
                {
                    score = Math.Max(score, 1150);
                }
                if (!string.IsNullOrWhiteSpace(candidate.ExecutablePath))
                {
                    var exe = Path.GetFileName(candidate.ExecutablePath);
                    var matchingLaunch = entry.LaunchPaths.FirstOrDefault(
                        x => Path.GetFileName(x).Equals(exe, StringComparison.OrdinalIgnoreCase));
                    if (matchingLaunch is not null)
                    {
                        var derivedRoot = DeriveInstallRoot(candidate.ExecutablePath, matchingLaunch);
                        var suffix = GetBaseRelativeSuffix(matchingLaunch);
                        var nestedLaunchPath = suffix?.Contains('\\') == true;
                        var launchIsQualified =
                            candidate.StrongGamePath ||
                            exactNameMatch ||
                            fuzzyNameMatch ||
                            installDirectoryMatch ||
                            (nestedLaunchPath && derivedRoot is not null);
                        if (launchIsQualified)
                        {
                            score = Math.Max(score, 1250);
                            if (derivedRoot is not null)
                            {
                                candidate.InstallRoot = derivedRoot;
                                candidate.StrongGamePath = true;
                                score = Math.Max(score, 1500);
                            }
                        }
                    }
                }
                if (!string.IsNullOrWhiteSpace(candidate.SteamAppId) &&
                    candidate.SteamAppId == entry.SteamAppId)
                {
                    score = Math.Max(score, 1350);
                }
                if (score > candidate.ManifestScore)
                {
                    candidate.Manifest = entry.Clone();
                    candidate.ManifestScore = score;
                }
            }
        }

        private static string? DeriveInstallRoot(string executablePath, string launchPath)
        {
            var suffix = GetBaseRelativeSuffix(launchPath);
            if (string.IsNullOrWhiteSpace(suffix) ||
                !executablePath.EndsWith(suffix, StringComparison.OrdinalIgnoreCase))
            {
                return null;
            }
            var root = executablePath[..^suffix.Length].TrimEnd('\\');
            return Directory.Exists(root) ? root : null;
        }

        private static string? GetBaseRelativeSuffix(string launchPath)
        {
            var marker = launchPath.IndexOf("<base>", StringComparison.OrdinalIgnoreCase);
            if (marker < 0)
            {
                return null;
            }
            var suffix = launchPath[(marker + "<base>".Length)..]
                .Replace('/', '\\')
                .TrimStart('\\');
            return suffix.Length == 0 ? null : suffix;
        }

        private static bool TryReadTopLevelKey(string line, out string key)
        {
            key = "";
            if (line.Length == 0 || char.IsWhiteSpace(line[0]) || line is "---" or "...")
            {
                return false;
            }
            return TryReadYamlMapKey(line.Trim(), out key);
        }

        private static bool TryReadYamlMapKey(string text, out string key)
        {
            key = "";
            if (!text.EndsWith(':'))
            {
                return false;
            }
            var raw = text[..^1].Trim();
            if (raw.Length == 0)
            {
                return false;
            }
            key = Unquote(raw);
            return key.Length > 0;
        }

        private static string Unquote(string value)
        {
            if (value.Length >= 2 && value[0] == '"' && value[^1] == '"')
            {
                return Regex.Unescape(value[1..^1]);
            }
            if (value.Length >= 2 && value[0] == '\'' && value[^1] == '\'')
            {
                return value[1..^1].Replace("''", "'");
            }
            return value;
        }

        private static string Normalize(string value) =>
            Regex.Replace(value.ToLowerInvariant(), "[^a-z0-9]+", "");
    }

    internal static class BackupEngine
    {
        public static BackupReceipt CreateVerifiedBackup(GameSelection selection, string backupRoot)
        {
            Directory.CreateDirectory(backupRoot);
            Program.WriteImmediateLine($"ASS_PROGRESS stage=preparing-sources count={selection.SaveSources.Count}");
            var rootFull = Path.GetFullPath(backupRoot).TrimEnd('\\') + "\\";
            var safeGame = SanitizeFileName(selection.Title);
            var stamp = DateTime.Now.ToString("yyyy-MM-dd_HH-mm-ss", CultureInfo.InvariantCulture);
            var final = Path.Combine(backupRoot, $"{safeGame}_{stamp}");
            if (Directory.Exists(final))
            {
                final += "_" + DateTime.Now.ToString("fff", CultureInfo.InvariantCulture);
            }
            var partial = final + ".partial-" + Guid.NewGuid().ToString("N");
            EnsureUnderRoot(partial, rootFull);

            Exception? last = null;
            for (var attempt = 1; attempt <= 4; attempt++)
            {
                try
                {
                    if (Directory.Exists(partial))
                    {
                        Directory.Delete(partial, true);
                    }
                    Directory.CreateDirectory(partial);
                    var saveTarget = Path.Combine(partial, "SaveGames");
                    Directory.CreateDirectory(saveTarget);
                    var sourceSnapshots = SnapshotSources(selection.SaveSources);
                    Program.WriteImmediateLine(
                        $"ASS_PROGRESS stage=copying files={sourceSnapshots.Values.Sum(x => x.Files)} " +
                        $"bytes={sourceSnapshots.Values.Sum(x => x.Bytes)}");
                    var copied = CopySources(selection.SaveSources, saveTarget);
                    Program.WriteImmediateLine("ASS_PROGRESS stage=verifying-source-stability");
                    var afterSnapshots = SnapshotSources(selection.SaveSources);
                    VerifyStable(sourceSnapshots, afterSnapshots);
                    Program.WriteImmediateLine($"ASS_PROGRESS stage=verifying-copy files={copied.Count}");
                    VerifyCopiedFiles(copied);
                    var registryFiles = ExportRegistry(selection.RegistryKeys, Path.Combine(partial, "Registry"));
                    var registryRelativePaths = registryFiles
                        .Select(x => Path.GetRelativePath(partial, x))
                        .ToArray();

                    Directory.Move(partial, final);
                    var finalRegistryFiles = registryRelativePaths
                        .Select(x => Path.Combine(final, x))
                        .ToArray();
                    var audit = new
                    {
                        version = 1,
                        game = selection.Title,
                        manifestGame = selection.ManifestTitle,
                        detectedUtc = DateTimeOffset.UtcNow,
                        playedUtc = selection.PrimaryEvidence.TimeUtc,
                        detector = selection.PrimaryEvidence.Source,
                        executable = selection.ExecutablePath,
                        installRoot = selection.InstallRoot,
                        saveSources = selection.SaveSources,
                        registryKeys = selection.RegistryKeys,
                        evidence = selection.Evidence,
                        files = copied.Count,
                        bytes = copied.Sum(x => x.Length),
                        registryFiles = finalRegistryFiles
                    };
                    File.WriteAllText(
                        Path.Combine(final, "backup.json"),
                        JsonSerializer.Serialize(audit, JsonOptions),
                        new UTF8Encoding(true));
                    return new BackupReceipt(final, selection.Title, copied.Count, copied.Sum(x => x.Length));
                }
                catch (Exception ex)
                {
                    last = ex;
                    if (Directory.Exists(partial))
                    {
                        EnsureUnderRoot(partial, rootFull);
                        Directory.Delete(partial, true);
                    }
                    if (attempt < 4)
                    {
                        Thread.Sleep(750);
                    }
                }
            }
            throw new IOException($"Unable to produce a stable verified backup after four attempts: {last?.Message}", last);
        }

        private static List<FileSnapshot> CopySources(IReadOnlyList<string> sources, string targetRoot)
        {
            var copied = new List<FileSnapshot>();
            var multiple = sources.Count > 1;
            for (var index = 0; index < sources.Count; index++)
            {
                var source = sources[index];
                var destination = targetRoot;
                if (multiple)
                {
                    var leaf = SanitizeFileName(Path.GetFileName(source.TrimEnd('\\')));
                    destination = Path.Combine(targetRoot, $"{index + 1:D2}_{leaf}");
                }
                if (File.Exists(source))
                {
                    Directory.CreateDirectory(destination);
                    var target = Path.Combine(destination, Path.GetFileName(source));
                    copied.Add(CopyFileVerified(source, target));
                }
                else
                {
                    CopyDirectory(source, destination, copied);
                }
            }
            return copied;
        }

        private static void CopyDirectory(string source, string destination, List<FileSnapshot> copied)
        {
            Directory.CreateDirectory(destination);
            var options = new EnumerationOptions
            {
                RecurseSubdirectories = true,
                IgnoreInaccessible = false,
                AttributesToSkip = FileAttributes.ReparsePoint,
                ReturnSpecialDirectories = false
            };
            foreach (var directory in Directory.EnumerateDirectories(source, "*", options))
            {
                var relative = Path.GetRelativePath(source, directory);
                Directory.CreateDirectory(Path.Combine(destination, relative));
            }
            foreach (var file in Directory.EnumerateFiles(source, "*", options))
            {
                var relative = Path.GetRelativePath(source, file);
                copied.Add(CopyFileVerified(file, Path.Combine(destination, relative)));
            }
        }

        private static FileSnapshot CopyFileVerified(string source, string destination)
        {
            Directory.CreateDirectory(Path.GetDirectoryName(destination)!);
            byte[] sourceHash;
            long length;
            using (var input = new FileStream(
                source, FileMode.Open, FileAccess.Read,
                FileShare.ReadWrite | FileShare.Delete, 1024 * 128,
                FileOptions.SequentialScan))
            using (var output = new FileStream(
                destination, FileMode.Create, FileAccess.Write,
                FileShare.None, 1024 * 128, FileOptions.SequentialScan))
            using (var sha = SHA256.Create())
            {
                input.CopyTo(output);
                output.Flush(true);
                length = input.Length;
                input.Position = 0;
                sourceHash = sha.ComputeHash(input);
            }
            File.SetLastWriteTimeUtc(destination, File.GetLastWriteTimeUtc(source));
            byte[] destinationHash;
            using (var destinationStream = new FileStream(
                destination, FileMode.Open, FileAccess.Read,
                FileShare.Read, 1024 * 128, FileOptions.SequentialScan))
            {
                destinationHash = SHA256.HashData(destinationStream);
            }
            if (!sourceHash.AsSpan().SequenceEqual(destinationHash) ||
                new FileInfo(destination).Length != length)
            {
                throw new IOException($"Copy verification failed for '{source}'.");
            }
            return new FileSnapshot(source, destination, length, Convert.ToHexString(sourceHash));
        }

        private static Dictionary<string, SourceSnapshot> SnapshotSources(IReadOnlyList<string> sources)
        {
            var result = new Dictionary<string, SourceSnapshot>(PathComparer);
            foreach (var source in sources)
            {
                if (File.Exists(source))
                {
                    var info = new FileInfo(source);
                    result[source] = new SourceSnapshot(1, info.Length, info.LastWriteTimeUtc.Ticks);
                    continue;
                }
                long count = 0;
                long bytes = 0;
                long newest = 0;
                var options = new EnumerationOptions
                {
                    RecurseSubdirectories = true,
                    IgnoreInaccessible = false,
                    AttributesToSkip = FileAttributes.ReparsePoint
                };
                foreach (var file in Directory.EnumerateFiles(source, "*", options))
                {
                    var info = new FileInfo(file);
                    count++;
                    bytes += info.Length;
                    newest = Math.Max(newest, info.LastWriteTimeUtc.Ticks);
                }
                result[source] = new SourceSnapshot(count, bytes, newest);
            }
            return result;
        }

        private static void VerifyStable(
            IReadOnlyDictionary<string, SourceSnapshot> before,
            IReadOnlyDictionary<string, SourceSnapshot> after)
        {
            foreach (var pair in before)
            {
                if (!after.TryGetValue(pair.Key, out var current) || pair.Value != current)
                {
                    throw new IOException($"Save source changed during backup: {pair.Key}");
                }
            }
        }

        private static void VerifyCopiedFiles(IEnumerable<FileSnapshot> copied)
        {
            foreach (var file in copied)
            {
                if (!File.Exists(file.Destination) ||
                    new FileInfo(file.Destination).Length != file.Length ||
                    !HashFile(file.Destination).Equals(file.Sha256, StringComparison.OrdinalIgnoreCase))
                {
                    throw new IOException($"Post-copy verification failed: {file.Destination}");
                }
            }
        }

        private static List<string> ExportRegistry(IReadOnlyList<string> keys, string target)
        {
            var exported = new List<string>();
            foreach (var raw in keys)
            {
                var key = raw.Replace('/', '\\');
                key = key
                    .Replace("HKEY_CURRENT_USER", "HKCU", StringComparison.OrdinalIgnoreCase)
                    .Replace("HKEY_LOCAL_MACHINE", "HKLM", StringComparison.OrdinalIgnoreCase);
                if (!key.StartsWith("HKCU\\", StringComparison.OrdinalIgnoreCase) &&
                    !key.StartsWith("HKLM\\", StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }
                Directory.CreateDirectory(target);
                var file = Path.Combine(target, $"{exported.Count + 1:D2}_{SanitizeFileName(key)}.reg");
                using var process = Process.Start(new ProcessStartInfo
                {
                    FileName = Path.Combine(Environment.SystemDirectory, "reg.exe"),
                    UseShellExecute = false,
                    CreateNoWindow = true,
                    ArgumentList = { "export", key, file, "/y" }
                });
                process?.WaitForExit(15000);
                if (process?.ExitCode == 0 && File.Exists(file))
                {
                    exported.Add(file);
                }
                else if (File.Exists(file))
                {
                    File.Delete(file);
                }
            }
            return exported;
        }

        private static string SanitizeFileName(string value)
        {
            var invalid = new string(Path.GetInvalidFileNameChars());
            var clean = Regex.Replace(value, $"[{Regex.Escape(invalid)}]", "_").Trim().TrimEnd('.');
            return clean.Length == 0 ? "UnknownGame" : clean;
        }

        private static void EnsureUnderRoot(string path, string root)
        {
            var full = Path.GetFullPath(path);
            if (!full.StartsWith(root, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException($"Refusing unsafe backup path: {full}");
            }
        }

        private static string HashFile(string path)
        {
            using var stream = new FileStream(
                path, FileMode.Open, FileAccess.Read,
                FileShare.Read, 1024 * 128, FileOptions.SequentialScan);
            return Convert.ToHexString(SHA256.HashData(stream));
        }
    }

    internal sealed class Candidate(string displayHint, string installRoot)
    {
        public string DisplayHint { get; } = displayHint;
        public string InstallRoot { get; set; } = installRoot;
        public string? ExecutablePath { get; set; }
        public string? SteamAppId { get; set; }
        public bool StrongGamePath { get; set; }
        public List<Evidence> Evidence { get; } = [];
        public ManifestEntry? Manifest { get; set; }
        public int ManifestScore { get; set; }
        public List<string> SaveSources { get; } = [];
        public List<string> RegistryKeys { get; } = [];
        public DateTimeOffset NewestSaveUtc { get; set; }
        public bool IsGameQualified =>
            StrongGamePath || ManifestScore > 0 || RegistryKeys.Count > 0;
        public Evidence? LatestLaunchEvidence => Evidence
            .Where(x => x.IsLaunchEvidence)
            .OrderByDescending(x => x.TimeUtc)
            .ThenByDescending(x => x.Priority)
            .FirstOrDefault();
    }

    internal sealed class ManifestEntry(string title)
    {
        public string Title { get; } = title;
        public List<SaveSpec> Files { get; } = [];
        public List<string> InstallDirs { get; } = [];
        public List<string> LaunchPaths { get; } = [];
        public List<string> RegistryKeys { get; } = [];
        public string? SteamAppId { get; set; }

        public ManifestEntry Clone()
        {
            var copy = new ManifestEntry(Title) { SteamAppId = SteamAppId };
            copy.Files.AddRange(Files.Select(x => new SaveSpec(x.Path) { IsSave = x.IsSave }));
            copy.InstallDirs.AddRange(InstallDirs);
            copy.LaunchPaths.AddRange(LaunchPaths);
            copy.RegistryKeys.AddRange(RegistryKeys);
            return copy;
        }
    }

    internal sealed class SaveSpec(string path)
    {
        public string Path { get; } = path;
        public bool IsSave { get; set; }
    }

    internal sealed record Evidence(
        string Source,
        DateTimeOffset TimeUtc,
        int Priority,
        string? ExecutablePath,
        bool IsLaunchEvidence);

    internal sealed record LaunchRecord(int ProcessId, string ExecutablePath, DateTimeOffset StartedUtc);

    internal sealed record GameSelection(
        string Title,
        string InstallRoot,
        string? ExecutablePath,
        Evidence PrimaryEvidence,
        IReadOnlyList<Evidence> Evidence,
        IReadOnlyList<string> SaveSources,
        IReadOnlyList<string> RegistryKeys,
        string? ManifestTitle)
    {
        public object ToReport() => new
        {
            title = Title,
            installRoot = InstallRoot,
            executable = ExecutablePath,
            playedUtc = PrimaryEvidence.TimeUtc,
            detector = PrimaryEvidence.Source,
            saveSources = SaveSources,
            registryKeys = RegistryKeys,
            manifestTitle = ManifestTitle,
            evidence = Evidence
        };
    }

    internal sealed record BackupReceipt(string Path, string Game, int Files, long Bytes);
    internal sealed record FileSnapshot(string Source, string Destination, long Length, string Sha256);
    internal sealed record SourceSnapshot(long Files, long Bytes, long NewestWriteTicks);
}
