namespace ClawdBotManagerApp;

internal sealed class TelegramReadinessProbe
{
    private static readonly string[] ExpectedAccounts = { "bot1", "bot2", "openclaw", "openclaw4" };
    private static readonly string[] FailurePatterns =
    {
        "sendMessage failed",
        "sendChatAction failed",
        "Polling stall detected",
        "polling error",
        "provider failed",
        "telegram token",
        "401 Unauthorized",
        "409 Conflict"
    };

    private readonly RuntimePaths _paths;

    public TelegramReadinessProbe(RuntimePaths paths)
    {
        _paths = paths;
    }

    public TelegramProbeResult Check(OpenClawConfig config, DateTime gatewayLaunchUtc)
    {
        var problems = new List<string>();
        var warnings = new List<string>();
        var accountIds = config.Accounts.Select(account => account.Id).OrderBy(id => id, StringComparer.OrdinalIgnoreCase).ToArray();
        var missingAccounts = ExpectedAccounts.Where(expected => !accountIds.Contains(expected, StringComparer.OrdinalIgnoreCase)).ToArray();
        if (!config.TelegramEnabled)
        {
            problems.Add("Telegram channel disabled");
        }

        if (missingAccounts.Length > 0 || config.Accounts.Count != 4)
        {
            problems.Add("Telegram accounts mismatch: " + string.Join(",", missingAccounts.DefaultIfEmpty("count=" + config.Accounts.Count)));
        }

        foreach (var account in config.Accounts)
        {
            if (!account.Enabled)
            {
                problems.Add(account.Id + " disabled");
            }

            if (!account.BotTokenPresent)
            {
                problems.Add(account.Id + " token missing");
            }
        }

        var recentLog = ReadRecentGatewayLog(gatewayLaunchUtc);
        var failure = FailurePatterns.FirstOrDefault(pattern => recentLog.Contains(pattern, StringComparison.OrdinalIgnoreCase));
        if (!string.IsNullOrWhiteSpace(failure))
        {
            problems.Add("Telegram runtime failure: " + failure);
        }

        var readyAccounts = new List<string>();
        foreach (var accountId in ExpectedAccounts)
        {
            if (HasProviderStart(recentLog, accountId))
            {
                readyAccounts.Add(accountId);
            }
        }

        var missingProviders = ExpectedAccounts.Where(accountId => !readyAccounts.Contains(accountId, StringComparer.OrdinalIgnoreCase)).ToArray();
        if (missingProviders.Length > 0)
        {
            problems.Add("Telegram providers missing: " + string.Join(",", missingProviders));
        }

        if (recentLog.Contains("Telegram limits bots to 100 commands", StringComparison.OrdinalIgnoreCase))
        {
            warnings.Add("Telegram menu limited to 100 visible commands; typed dispatch remains required");
        }

        return new TelegramProbeResult(problems.Count == 0, readyAccounts.Count, ExpectedAccounts.Length, problems, warnings);
    }

    private static bool HasProviderStart(string logText, string accountId)
    {
        return logText.Contains("[" + accountId + "] starting provider", StringComparison.OrdinalIgnoreCase) ||
               logText.Contains("[telegram] [" + accountId + "] starting provider", StringComparison.OrdinalIgnoreCase);
    }

    private string ReadRecentGatewayLog(DateTime gatewayLaunchUtc)
    {
        try
        {
            var files = Directory.GetFiles(_paths.TempRoot, "openclaw-*.log")
                .Select(path => new FileInfo(path))
                .OrderByDescending(file => file.LastWriteTimeUtc)
                .Take(3)
                .ToArray();

            var combined = string.Join(Environment.NewLine, files.Select(ReadTail));
            var lastRunIndex = Math.Max(
                combined.LastIndexOf("\"loading configuration", StringComparison.OrdinalIgnoreCase),
                combined.LastIndexOf("loading configuration", StringComparison.OrdinalIgnoreCase));
            if (lastRunIndex >= 0)
            {
                combined = combined[lastRunIndex..];
            }

            return combined;
        }
        catch
        {
            return string.Empty;
        }
    }

    private static string ReadTail(FileInfo file)
    {
        const int maxBytes = 512 * 1024;
        using var stream = File.Open(file.FullName, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
        var start = Math.Max(0, stream.Length - maxBytes);
        stream.Seek(start, SeekOrigin.Begin);
        using var reader = new StreamReader(stream);
        return reader.ReadToEnd();
    }
}

internal sealed record TelegramProbeResult(
    bool Ready,
    int ReadyCount,
    int ExpectedCount,
    IReadOnlyList<string> Problems,
    IReadOnlyList<string> Warnings);
