namespace ClawdBotManagerApp;

internal sealed class RuntimePaths
{
    public string RepoRoot { get; private init; } = string.Empty;
    public string StateRoot { get; private init; } = string.Empty;
    public string ConfigPath { get; private init; } = string.Empty;
    public string TempRoot { get; private init; } = string.Empty;
    public string RuntimeRoot { get; private init; } = string.Empty;
    public string RuntimeScriptPath { get; private init; } = string.Empty;
    public string NodeExePath { get; private init; } = string.Empty;
    public string ManagerLogPath { get; private init; } = string.Empty;
    public string RuntimeLeasePath { get; private init; } = string.Empty;
    public string AuthorityManifestPath { get; private init; } = string.Empty;
    public string CommandCatalogPath { get; private init; } = string.Empty;
    public string MenuPriorityPath { get; private init; } = string.Empty;
    public string SlashStatePath { get; private init; } = string.Empty;
    public string RouteRegistryPath { get; private init; } = string.Empty;
    public string GeneratedCustomCommandsRoot { get; private init; } = string.Empty;
    public string AgentsRoot { get; private init; } = string.Empty;
    public IReadOnlyList<string> WorkspaceRoots { get; private init; } = Array.Empty<string>();

    public static RuntimePaths CreateDefault()
    {
        var repoRoot = FirstNonEmpty(
            Environment.GetEnvironmentVariable("OPENCLAW_REPO_ROOT"),
            FindRepoRoot(AppContext.BaseDirectory),
            FindRepoRoot(Environment.CurrentDirectory),
            @"F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw");

        var stateRoot = FirstNonEmpty(
            Environment.GetEnvironmentVariable("OPENCLAW_STATE_DIR"),
            Path.Combine(repoRoot, "openclaw-home"));
        var tempRoot = FirstNonEmpty(
            Environment.GetEnvironmentVariable("OPENCLAW_TMP_DIR"),
            Path.Combine(stateRoot, "tmp"));
        var runtimeRoot = FirstNonEmpty(
            Environment.GetEnvironmentVariable("OPENCLAW_RUNTIME_COMMAND_ROOT"),
            Path.Combine(repoRoot, "npm-global"));
        var configPath = FirstNonEmpty(
            Environment.GetEnvironmentVariable("OPENCLAW_CONFIG_PATH"),
            Path.Combine(stateRoot, "openclaw.json"));
        var authorityManifestPath = FirstNonEmpty(
            Environment.GetEnvironmentVariable("OPENCLAW_AUTHORITY_MANIFEST_PATH"),
            Path.Combine(stateRoot, "authority", "authority-manifest.json"));
        var telegramRoot = Path.Combine(stateRoot, "telegram");

        Directory.CreateDirectory(tempRoot);
        Directory.CreateDirectory(Path.Combine(stateRoot, "authority"));

        return new RuntimePaths
        {
            RepoRoot = repoRoot,
            StateRoot = stateRoot,
            ConfigPath = configPath,
            TempRoot = tempRoot,
            RuntimeRoot = runtimeRoot,
            RuntimeScriptPath = Path.Combine(runtimeRoot, "node_modules", "openclaw", "dist", "index.js"),
            NodeExePath = ResolveNodeExePath(),
            ManagerLogPath = Path.Combine(tempRoot, "clawdbot-manager.log"),
            RuntimeLeasePath = Path.Combine(stateRoot, "authority", "manager-runtime-state.json"),
            AuthorityManifestPath = authorityManifestPath,
            CommandCatalogPath = Path.Combine(telegramRoot, "command-catalog.json"),
            MenuPriorityPath = Path.Combine(telegramRoot, "menu-priority.json"),
            SlashStatePath = Path.Combine(telegramRoot, "slash-state.json"),
            RouteRegistryPath = Path.Combine(telegramRoot, "route-registry.json"),
            GeneratedCustomCommandsRoot = Path.Combine(stateRoot, "generated-skills", "custom-commands"),
            AgentsRoot = Path.Combine(stateRoot, "agents"),
            WorkspaceRoots = new[]
            {
                Path.Combine(stateRoot, "workspace-openclaw-main"),
                Path.Combine(stateRoot, "workspace-moltbot2"),
                Path.Combine(stateRoot, "workspace-moltbot"),
                Path.Combine(stateRoot, "workspace-openclaw")
            }
        };
    }

    private static string FirstNonEmpty(params string?[] values)
    {
        foreach (var value in values)
        {
            if (!string.IsNullOrWhiteSpace(value))
            {
                return value;
            }
        }

        return string.Empty;
    }

    private static string? FindRepoRoot(string start)
    {
        try
        {
            var directory = new DirectoryInfo(start);
            while (directory != null)
            {
                if (Directory.Exists(Path.Combine(directory.FullName, "openclaw-home")) &&
                    Directory.Exists(Path.Combine(directory.FullName, "npm-global")))
                {
                    return directory.FullName;
                }

                directory = directory.Parent;
            }
        }
        catch
        {
            return null;
        }

        return null;
    }

    private static string ResolveNodeExePath()
    {
        var candidates = new[]
        {
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "nodejs", "node.exe"),
            @"C:\Program Files\nodejs\node.exe"
        };

        foreach (var candidate in candidates)
        {
            if (File.Exists(candidate))
            {
                return candidate;
            }
        }

        var path = Environment.GetEnvironmentVariable("PATH") ?? string.Empty;
        foreach (var directory in path.Split(Path.PathSeparator, StringSplitOptions.RemoveEmptyEntries))
        {
            var candidate = Path.Combine(directory.Trim(), "node.exe");
            if (File.Exists(candidate))
            {
                return candidate;
            }
        }

        return "node.exe";
    }
}
