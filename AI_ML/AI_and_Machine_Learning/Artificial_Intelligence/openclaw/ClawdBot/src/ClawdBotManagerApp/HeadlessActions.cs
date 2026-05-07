using System.Windows.Forms;

namespace ClawdBotManagerApp;

internal static class HeadlessActions
{
    public static async Task<int> RunAsync(string actionName, RuntimePaths paths)
    {
        try
        {
            if (string.Equals(actionName, "self-test", StringComparison.OrdinalIgnoreCase))
            {
                return SelfTestRunner.Run();
            }

            var gatewaySupervisor = new GatewaySupervisor(paths);
            var monitor = new HealthMonitor(paths, gatewaySupervisor);
            var snapshot = await monitor.EvaluateAsync();
            var text = HealthReportBuilder.BuildText(snapshot);

            if (string.Equals(actionName, "health-json", StringComparison.OrdinalIgnoreCase))
            {
                Console.WriteLine(HealthReportBuilder.BuildJson(snapshot));
                return snapshot.Problems.Count == 0 ? 0 : 2;
            }

            if (string.Equals(actionName, "copy-health", StringComparison.OrdinalIgnoreCase))
            {
                Clipboard.SetText(text);
                Console.WriteLine(text);
                return snapshot.Problems.Count == 0 ? 0 : 2;
            }

            if (IsHealthAlias(actionName))
            {
                Console.WriteLine(text);
                return snapshot.Problems.Count == 0 ? 0 : 2;
            }

            Console.Error.WriteLine("Unknown headless action: " + actionName);
            return 64;
        }
        catch (Exception exception)
        {
            Console.Error.WriteLine(exception.Message);
            AppLogger.Error("headless", exception);
            return 1;
        }
    }

    private static bool IsHealthAlias(string actionName)
    {
        return string.Equals(actionName, "full-health-report", StringComparison.OrdinalIgnoreCase) ||
               string.Equals(actionName, "command-surface-health", StringComparison.OrdinalIgnoreCase) ||
               string.Equals(actionName, "telegram-readiness-health", StringComparison.OrdinalIgnoreCase) ||
               string.Equals(actionName, "permissions-health", StringComparison.OrdinalIgnoreCase) ||
               string.Equals(actionName, "skills-health", StringComparison.OrdinalIgnoreCase);
    }
}
