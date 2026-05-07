namespace ClawdBotManagerApp;

internal sealed class PermissionsProbe
{
    public PermissionsResult Check(OpenClawConfig config)
    {
        var problems = new List<string>();
        if (!string.Equals(config.ToolsProfile, "full", StringComparison.OrdinalIgnoreCase))
        {
            problems.Add("global tools.profile is not full");
        }

        if (!string.Equals(config.ExecAsk, "off", StringComparison.OrdinalIgnoreCase))
        {
            problems.Add("global tools.exec.ask is not off");
        }

        if (!config.ElevatedEnabled)
        {
            problems.Add("global elevated tools disabled");
        }

        if (!config.BrowserEnabled)
        {
            problems.Add("browser tool disabled");
        }

        foreach (var agent in config.Agents)
        {
            if (!string.Equals(agent.ToolsProfile, "full", StringComparison.OrdinalIgnoreCase))
            {
                problems.Add(agent.Id + " tools.profile is not full");
            }

            if (!agent.ElevatedEnabled)
            {
                problems.Add(agent.Id + " elevated tools disabled");
            }

            if (!agent.TelegramAllowFrom.Contains("*"))
            {
                problems.Add(agent.Id + " Telegram allowFrom does not include *");
            }
        }

        return new PermissionsResult(problems.Count == 0, problems, Array.Empty<string>());
    }
}

internal sealed record PermissionsResult(bool Ready, IReadOnlyList<string> Problems, IReadOnlyList<string> Warnings);
