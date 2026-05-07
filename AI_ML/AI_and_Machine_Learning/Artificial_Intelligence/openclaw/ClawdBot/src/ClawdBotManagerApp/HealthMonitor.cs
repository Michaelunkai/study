namespace ClawdBotManagerApp;

internal sealed class HealthMonitor
{
    private static readonly TimeSpan StartupWindow = TimeSpan.FromMinutes(10);
    private readonly RuntimePaths _paths;
    private readonly GatewaySupervisor _gatewaySupervisor;
    private readonly OpenClawConfigReader _configReader;
    private readonly GatewayProbe _gatewayProbe;
    private readonly TelegramReadinessProbe _telegramProbe;
    private readonly CommandSurfaceProbe _commandSurfaceProbe;
    private readonly PermissionsProbe _permissionsProbe;
    private readonly SkillsMirrorProbe _skillsMirrorProbe;
    private readonly DateTime _managerStartedUtc = DateTime.UtcNow;

    public HealthMonitor(RuntimePaths paths, GatewaySupervisor gatewaySupervisor)
    {
        _paths = paths;
        _gatewaySupervisor = gatewaySupervisor;
        _configReader = new OpenClawConfigReader(paths);
        _gatewayProbe = new GatewayProbe();
        _telegramProbe = new TelegramReadinessProbe(paths);
        _commandSurfaceProbe = new CommandSurfaceProbe(paths);
        _permissionsProbe = new PermissionsProbe();
        _skillsMirrorProbe = new SkillsMirrorProbe(paths);
    }

    public async Task<HealthSnapshot> EvaluateAsync()
    {
        var problems = new List<string>();
        var warnings = new List<string>();
        var evidence = new List<string>();
        try
        {
            var config = _configReader.Read();
            var gateway = await _gatewayProbe.CheckAsync(config);
            evidence.Add("listenerPids=" + string.Join(",", gateway.ListenerPids));
            var telegram = _telegramProbe.Check(config, _gatewaySupervisor.LastLaunchUtc);

            var gatewayReady = gateway.ProcessPresent && gateway.ListenerPresent && (gateway.HttpReady || telegram.Ready);
            if (!gatewayReady)
            {
                problems.Add(gateway.Message);
            }
            else if (!gateway.HttpReady)
            {
                warnings.AddRange(gateway.Warnings);
                evidence.Add("gatewayHttpProbe=slow-held-by-listener-and-telegram");
            }

            problems.AddRange(telegram.Problems);
            warnings.AddRange(telegram.Warnings);

            var commandSurface = _commandSurfaceProbe.Check(config);
            problems.AddRange(commandSurface.Problems);
            warnings.AddRange(commandSurface.Warnings);

            var permissions = _permissionsProbe.Check(config);
            problems.AddRange(permissions.Problems);
            warnings.AddRange(permissions.Warnings);

            var skills = _skillsMirrorProbe.Check(config);
            problems.AddRange(skills.Problems);
            warnings.AddRange(skills.Warnings);
            evidence.Add("workspaceSkillCounts=" + string.Join(",", skills.SkillCounts.Select(pair => pair.Key + ":" + pair.Value)));
            evidence.Add("commands=" + commandSurface.CommandCount);

            var operationalReady = gatewayReady && telegram.Ready && commandSurface.Ready && permissions.Ready && skills.Ready;
            var startupPending = !operationalReady && IsStartupPending();
            return new HealthSnapshot
            {
                OperationalReady = operationalReady,
                GatewayReady = gatewayReady,
                TelegramReady = telegram.Ready,
                CommandSurfaceReady = commandSurface.Ready,
                PermissionsReady = permissions.Ready,
                SkillsReady = skills.Ready,
                StartupPending = startupPending,
                TelegramReadyCount = telegram.ReadyCount,
                TelegramExpectedCount = telegram.ExpectedCount,
                CommandCount = commandSurface.CommandCount,
                ListenerPids = gateway.ListenerPids,
                Problems = problems.Distinct(StringComparer.OrdinalIgnoreCase).ToArray(),
                Warnings = warnings.Distinct(StringComparer.OrdinalIgnoreCase).ToArray(),
                Evidence = evidence
            };
        }
        catch (Exception exception)
        {
            return new HealthSnapshot
            {
                StartupPending = IsStartupPending(),
                Problems = new[] { exception.Message },
                Warnings = warnings,
                Evidence = evidence
            };
        }
    }

    private bool IsStartupPending()
    {
        var launchUtc = _gatewaySupervisor.LastLaunchUtc;
        var baseline = launchUtc == DateTime.MinValue ? _managerStartedUtc : launchUtc;
        return DateTime.UtcNow - baseline <= StartupWindow;
    }
}
