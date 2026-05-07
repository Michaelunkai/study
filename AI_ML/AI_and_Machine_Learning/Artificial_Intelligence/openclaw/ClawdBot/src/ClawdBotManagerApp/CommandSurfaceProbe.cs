using System.Text.Json;

namespace ClawdBotManagerApp;

internal sealed class CommandSurfaceProbe
{
    private static readonly string[] RequiredCommands = { "all", "clu", "snap", "nnew", "slash", "job", "news", "start" };
    private static readonly string[] DirectCommands = { "clu", "snap", "slash" };
    private readonly RuntimePaths _paths;

    public CommandSurfaceProbe(RuntimePaths paths)
    {
        _paths = paths;
    }

    public CommandSurfaceResult Check(OpenClawConfig config)
    {
        var problems = new List<string>();
        var warnings = new List<string>();
        var customCommandNames = config.CustomCommands
            .Select(command => command.Command.Trim().ToLowerInvariant())
            .Where(command => command.Length > 0)
            .ToArray();

        if (customCommandNames.Length != config.CustomCommands.Count)
        {
            problems.Add("custom command with empty name");
        }

        var duplicates = customCommandNames.GroupBy(command => command).Where(group => group.Count() > 1).Select(group => group.Key).ToArray();
        if (duplicates.Length > 0)
        {
            problems.Add("duplicate commands: " + string.Join(",", duplicates));
        }

        if (customCommandNames.Contains("new"))
        {
            problems.Add("custom command /new shadows native Telegram command");
        }

        if (config.CustomCommands.Count > 100)
        {
            warnings.Add("Telegram menu can show only first 100 commands; typed dispatch must cover " + config.CustomCommands.Count + " commands");
        }

        using var catalog = ReadJsonDocument(_paths.CommandCatalogPath, problems, "command catalog");
        var catalogCommands = catalog?.RootElement.GetPropertyOrDefault("entries").ValueKind == JsonValueKind.Array
            ? catalog.RootElement.GetPropertyOrDefault("entries").EnumerateArray()
                .Select(entry => entry.GetStringOrDefault("command").Trim().ToLowerInvariant())
                .Where(command => command.Length > 0)
                .ToHashSet(StringComparer.OrdinalIgnoreCase)
            : new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (var command in RequiredCommands)
        {
            if (!customCommandNames.Contains(command) && !catalogCommands.Contains(command))
            {
                problems.Add("required command missing from catalog/config: " + command);
            }

            foreach (var workspace in _paths.WorkspaceRoots)
            {
                var skillPath = Path.Combine(workspace, "skills", command, "SKILL.md");
                if (!File.Exists(skillPath))
                {
                    problems.Add("workspace mirror missing: " + Path.GetFileName(workspace) + "/" + command);
                }
            }
        }

        foreach (var command in DirectCommands)
        {
            var skillPath = command == "slash"
                ? Path.Combine(_paths.WorkspaceRoots[0], "skills", command, "SKILL.md")
                : Path.Combine(_paths.GeneratedCustomCommandsRoot, command, "SKILL.md");
            if (!File.Exists(skillPath))
            {
                problems.Add("direct command skill missing: " + command);
                continue;
            }

            var text = File.ReadAllText(skillPath);
            if (!text.Contains("command-dispatch: tool", StringComparison.OrdinalIgnoreCase) ||
                !text.Contains("command-tool: exec", StringComparison.OrdinalIgnoreCase))
            {
                problems.Add("direct command metadata missing: " + command);
            }
        }

        var menuCommands = ReadMenuPriorityCommands(warnings);
        if (menuCommands.Contains("new", StringComparer.OrdinalIgnoreCase))
        {
            problems.Add("menu priority contains native /new shadow");
        }

        var routedAccounts = ReadRouteAccounts(warnings);
        foreach (var account in new[] { "bot1", "bot2", "openclaw", "openclaw4" })
        {
            if (!routedAccounts.Contains(account))
            {
                warnings.Add("route registry missing direct route for " + account);
            }
        }

        return new CommandSurfaceResult(problems.Count == 0, config.CustomCommands.Count, problems, warnings);
    }

    private static JsonDocument? ReadJsonDocument(string path, List<string> problems, string label)
    {
        try
        {
            return JsonDocument.Parse(File.ReadAllText(path));
        }
        catch (Exception exception)
        {
            problems.Add(label + " unreadable: " + exception.Message);
            return null;
        }
    }

    private IReadOnlyList<string> ReadMenuPriorityCommands(List<string> warnings)
    {
        try
        {
            using var document = JsonDocument.Parse(File.ReadAllText(_paths.MenuPriorityPath));
            var commands = document.RootElement.GetPropertyOrDefault("commands");
            return commands.ValueKind == JsonValueKind.Array
                ? commands.EnumerateArray().Select(item => item.GetString() ?? string.Empty).Where(item => item.Length > 0).ToArray()
                : Array.Empty<string>();
        }
        catch (Exception exception)
        {
            warnings.Add("menu priority unreadable: " + exception.Message);
            return Array.Empty<string>();
        }
    }

    private IReadOnlySet<string> ReadRouteAccounts(List<string> warnings)
    {
        try
        {
            using var document = JsonDocument.Parse(File.ReadAllText(_paths.RouteRegistryPath));
            var routes = document.RootElement.GetPropertyOrDefault("routes");
            if (routes.ValueKind != JsonValueKind.Array)
            {
                return new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            }

            return routes.EnumerateArray()
                .Select(route => route.GetStringOrDefault("accountId"))
                .Where(account => account.Length > 0)
                .ToHashSet(StringComparer.OrdinalIgnoreCase);
        }
        catch (Exception exception)
        {
            warnings.Add("route registry unreadable: " + exception.Message);
            return new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        }
    }
}

internal sealed record CommandSurfaceResult(
    bool Ready,
    int CommandCount,
    IReadOnlyList<string> Problems,
    IReadOnlyList<string> Warnings);
