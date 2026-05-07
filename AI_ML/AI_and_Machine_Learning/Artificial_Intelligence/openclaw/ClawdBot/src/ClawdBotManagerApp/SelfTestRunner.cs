namespace ClawdBotManagerApp;

internal static class SelfTestRunner
{
    public static int Run()
    {
        var failures = new List<string>();
        Check(failures, "green status text", new HealthSnapshot { OperationalReady = true }.StatusText == "Ready: gateway + 4/4 Telegram bots");
        Check(failures, "startup status text", new HealthSnapshot { StartupPending = true }.StatusText == "Starting: gateway");
        Check(failures, "problem status text", new HealthSnapshot { Problems = new[] { "sample blocker" } }.StatusText == "Blocked: sample blocker");
        var report = HealthReportBuilder.BuildText(new HealthSnapshot
        {
            OperationalReady = true,
            GatewayReady = true,
            TelegramReady = true,
            CommandSurfaceReady = true,
            PermissionsReady = true,
            SkillsReady = true,
            TelegramReadyCount = 4,
            TelegramExpectedCount = 4,
            CommandCount = 469
        });
        Check(failures, "report problems none", report.Contains("Problems requiring fixes:" + Environment.NewLine + "- none", StringComparison.Ordinal));
        Check(failures, "report green", report.Contains("Operational readiness: green", StringComparison.Ordinal));

        if (failures.Count == 0)
        {
            Console.WriteLine("SELF_TEST_PASS");
            return 0;
        }

        Console.WriteLine("SELF_TEST_FAIL");
        foreach (var failure in failures)
        {
            Console.WriteLine("- " + failure);
        }

        return 1;
    }

    private static void Check(List<string> failures, string name, bool condition)
    {
        if (!condition)
        {
            failures.Add(name);
        }
    }
}
