namespace ClawdBotManagerApp;

internal sealed class HealthSnapshot
{
    public bool OperationalReady { get; init; }
    public bool GatewayReady { get; init; }
    public bool TelegramReady { get; init; }
    public bool CommandSurfaceReady { get; init; }
    public bool PermissionsReady { get; init; }
    public bool SkillsReady { get; init; }
    public bool StartupPending { get; init; }
    public int TelegramReadyCount { get; init; }
    public int TelegramExpectedCount { get; init; }
    public int CommandCount { get; init; }
    public IReadOnlyList<int> ListenerPids { get; init; } = Array.Empty<int>();
    public IReadOnlyList<string> Problems { get; init; } = Array.Empty<string>();
    public IReadOnlyList<string> Warnings { get; init; } = Array.Empty<string>();
    public IReadOnlyList<string> Evidence { get; init; } = Array.Empty<string>();

    public string StatusText
    {
        get
        {
            if (OperationalReady)
            {
                return "Ready: gateway + 4/4 Telegram bots";
            }

            if (StartupPending)
            {
                return GatewayReady ? "Waiting: Telegram providers" : "Starting: gateway";
            }

            return Problems.Count > 0 ? "Blocked: " + Problems[0] : "Waiting: OpenClaw readiness";
        }
    }
}
