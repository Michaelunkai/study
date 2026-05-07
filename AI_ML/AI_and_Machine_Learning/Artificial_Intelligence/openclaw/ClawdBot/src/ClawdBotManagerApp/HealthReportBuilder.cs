using System.Text;
using System.Text.Json;

namespace ClawdBotManagerApp;

internal static class HealthReportBuilder
{
    public static string BuildText(HealthSnapshot snapshot)
    {
        var report = new StringBuilder();
        report.AppendLine("OpenClaw tray health report");
        report.AppendLine("Generated: " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"));
        report.AppendLine("Current status: " + snapshot.StatusText);
        report.AppendLine("Operational readiness: " + (snapshot.OperationalReady ? "green" : snapshot.StartupPending ? "starting" : "not ready"));
        report.AppendLine("Gateway: " + (snapshot.GatewayReady ? "connected on port 18789" : "not ready"));
        report.AppendLine("Telegram bots: " + snapshot.TelegramReadyCount + "/" + snapshot.TelegramExpectedCount + " providers ready");
        report.AppendLine("Command surface: " + (snapshot.CommandSurfaceReady ? "ready" : "needs repair") + " (" + snapshot.CommandCount + " commands)");
        report.AppendLine("Tools/permissions: " + (snapshot.PermissionsReady ? "ready" : "needs repair"));
        report.AppendLine("Skills/workspaces: " + (snapshot.SkillsReady ? "ready" : "needs repair"));
        report.AppendLine("Problems requiring fixes:");
        if (snapshot.Problems.Count == 0)
        {
            report.AppendLine("- none");
        }
        else
        {
            foreach (var problem in snapshot.Problems)
            {
                report.AppendLine("- " + problem);
            }
        }

        report.AppendLine("Diagnostic warnings not blocking bot readiness:");
        if (snapshot.Warnings.Count == 0)
        {
            report.AppendLine("- none");
        }
        else
        {
            foreach (var warning in snapshot.Warnings)
            {
                report.AppendLine("- " + warning);
            }
        }

        if (snapshot.Evidence.Count > 0)
        {
            report.AppendLine("Evidence:");
            foreach (var evidence in snapshot.Evidence)
            {
                report.AppendLine("- " + evidence);
            }
        }

        return report.ToString().TrimEnd();
    }

    public static string BuildJson(HealthSnapshot snapshot)
    {
        return JsonSerializer.Serialize(snapshot, JsonOptions.Indented);
    }
}
