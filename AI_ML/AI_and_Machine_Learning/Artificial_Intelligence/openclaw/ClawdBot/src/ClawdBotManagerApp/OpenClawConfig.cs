using System.Text.Json;

namespace ClawdBotManagerApp;

internal sealed class OpenClawConfigReader
{
    private readonly RuntimePaths _paths;

    public OpenClawConfigReader(RuntimePaths paths)
    {
        _paths = paths;
    }

    public OpenClawConfig Read()
    {
        var text = File.ReadAllText(_paths.ConfigPath);
        using var document = JsonDocument.Parse(text);
        var root = document.RootElement;
        var gateway = root.GetPropertyOrDefault("gateway");
        var channels = root.GetPropertyOrDefault("channels");
        var telegram = channels.GetPropertyOrDefault("telegram");
        var tools = root.GetPropertyOrDefault("tools");
        var agents = root.GetPropertyOrDefault("agents");

        return new OpenClawConfig(
            GatewayPort: gateway.GetInt32OrDefault("port", 18789),
            GatewayToken: gateway.GetPropertyOrDefault("auth").GetStringOrDefault("token"),
            TelegramEnabled: telegram.GetBoolOrDefault("enabled", true),
            Accounts: ReadAccounts(telegram),
            Agents: ReadAgents(agents),
            CustomCommands: ReadCustomCommands(telegram),
            ToolsProfile: tools.GetStringOrDefault("profile"),
            ExecAsk: tools.GetPropertyOrDefault("exec").GetStringOrDefault("ask"),
            ElevatedEnabled: tools.GetPropertyOrDefault("elevated").GetBoolOrDefault("enabled", false),
            BrowserEnabled: root.GetPropertyOrDefault("browser").GetBoolOrDefault("enabled", false),
            BrowserEvaluateEnabled: root.GetPropertyOrDefault("browser").GetBoolOrDefault("evaluateEnabled", false),
            CrossContextAllow: tools.GetPropertyOrDefault("message").GetBoolOrDefault("allowCrossContextSend", false),
            CrossContextWithinProvider: tools.GetPropertyOrDefault("message").GetPropertyOrDefault("crossContext").GetBoolOrDefault("allowWithinProvider", false),
            CrossContextAcrossProviders: tools.GetPropertyOrDefault("message").GetPropertyOrDefault("crossContext").GetBoolOrDefault("allowAcrossProviders", false));
    }

    private static IReadOnlyList<TelegramAccount> ReadAccounts(JsonElement telegram)
    {
        var accounts = new List<TelegramAccount>();
        var accountsElement = telegram.GetPropertyOrDefault("accounts");
        if (accountsElement.ValueKind != JsonValueKind.Object)
        {
            return accounts;
        }

        foreach (var accountProperty in accountsElement.EnumerateObject())
        {
            var value = accountProperty.Value;
            accounts.Add(new TelegramAccount(
                Id: accountProperty.Name,
                Name: value.GetStringOrDefault("name"),
                Enabled: value.GetBoolOrDefault("enabled", true),
                BotTokenPresent: !string.IsNullOrWhiteSpace(value.GetStringOrDefault("botToken")),
                DmPolicy: value.GetStringOrDefault("dmPolicy"),
                GroupPolicy: value.GetStringOrDefault("groupPolicy")));
        }

        return accounts;
    }

    private static IReadOnlyList<AgentBinding> ReadAgents(JsonElement agents)
    {
        var list = new List<AgentBinding>();
        var listElement = agents.GetPropertyOrDefault("list");
        if (listElement.ValueKind != JsonValueKind.Array)
        {
            return list;
        }

        foreach (var agent in listElement.EnumerateArray())
        {
            var heartbeat = agent.GetPropertyOrDefault("heartbeat");
            var tools = agent.GetPropertyOrDefault("tools");
            var elevated = tools.GetPropertyOrDefault("elevated");
            var allowFrom = new List<string>();
            var telegramAllow = elevated.GetPropertyOrDefault("allowFrom").GetPropertyOrDefault("telegram");
            if (telegramAllow.ValueKind == JsonValueKind.Array)
            {
                allowFrom.AddRange(telegramAllow.EnumerateArray().Select(item => item.GetString() ?? string.Empty).Where(item => item.Length > 0));
            }

            list.Add(new AgentBinding(
                Id: agent.GetStringOrDefault("id"),
                Workspace: agent.GetStringOrDefault("workspace"),
                HeartbeatAccountId: heartbeat.GetStringOrDefault("accountId"),
                HeartbeatEvery: heartbeat.GetStringOrDefault("every"),
                HeartbeatPrompt: heartbeat.GetStringOrDefault("prompt"),
                ToolsProfile: tools.GetStringOrDefault("profile"),
                ElevatedEnabled: elevated.GetBoolOrDefault("enabled", false),
                TelegramAllowFrom: allowFrom));
        }

        return list;
    }

    private static IReadOnlyList<CustomCommandEntry> ReadCustomCommands(JsonElement telegram)
    {
        var commands = new List<CustomCommandEntry>();
        var customCommands = telegram.GetPropertyOrDefault("customCommands");
        if (customCommands.ValueKind != JsonValueKind.Array)
        {
            return commands;
        }

        foreach (var command in customCommands.EnumerateArray())
        {
            commands.Add(new CustomCommandEntry(
                Command: command.GetStringOrDefault("command"),
                Description: command.GetStringOrDefault("description")));
        }

        return commands;
    }
}

internal sealed record OpenClawConfig(
    int GatewayPort,
    string GatewayToken,
    bool TelegramEnabled,
    IReadOnlyList<TelegramAccount> Accounts,
    IReadOnlyList<AgentBinding> Agents,
    IReadOnlyList<CustomCommandEntry> CustomCommands,
    string ToolsProfile,
    string ExecAsk,
    bool ElevatedEnabled,
    bool BrowserEnabled,
    bool BrowserEvaluateEnabled,
    bool CrossContextAllow,
    bool CrossContextWithinProvider,
    bool CrossContextAcrossProviders);

internal sealed record TelegramAccount(
    string Id,
    string Name,
    bool Enabled,
    bool BotTokenPresent,
    string DmPolicy,
    string GroupPolicy);

internal sealed record AgentBinding(
    string Id,
    string Workspace,
    string HeartbeatAccountId,
    string HeartbeatEvery,
    string HeartbeatPrompt,
    string ToolsProfile,
    bool ElevatedEnabled,
    IReadOnlyList<string> TelegramAllowFrom);

internal sealed record CustomCommandEntry(string Command, string Description);

internal static class JsonExtensions
{
    public static JsonElement GetPropertyOrDefault(this JsonElement element, string name)
    {
        if (element.ValueKind is JsonValueKind.Object && element.TryGetProperty(name, out var value))
        {
            return value;
        }

        return default;
    }

    public static string GetStringOrDefault(this JsonElement element, string name)
    {
        var value = element.GetPropertyOrDefault(name);
        return value.ValueKind == JsonValueKind.String ? value.GetString() ?? string.Empty : string.Empty;
    }

    public static bool GetBoolOrDefault(this JsonElement element, string name, bool fallback)
    {
        var value = element.GetPropertyOrDefault(name);
        return value.ValueKind == JsonValueKind.True || (value.ValueKind != JsonValueKind.False && fallback);
    }

    public static int GetInt32OrDefault(this JsonElement element, string name, int fallback)
    {
        var value = element.GetPropertyOrDefault(name);
        return value.ValueKind == JsonValueKind.Number && value.TryGetInt32(out var parsed) ? parsed : fallback;
    }
}
