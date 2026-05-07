namespace ClawdBotManagerApp;

internal sealed class SkillsMirrorProbe
{
    private static readonly string[] RequiredCommands = { "all", "clu", "snap", "nnew", "slash", "job", "news", "start" };
    private readonly RuntimePaths _paths;

    public SkillsMirrorProbe(RuntimePaths paths)
    {
        _paths = paths;
    }

    public SkillsMirrorResult Check(OpenClawConfig config)
    {
        var problems = new List<string>();
        var warnings = new List<string>();
        var counts = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
        foreach (var workspace in _paths.WorkspaceRoots)
        {
            var skillsRoot = Path.Combine(workspace, "skills");
            if (!Directory.Exists(skillsRoot))
            {
                problems.Add("skills root missing: " + workspace);
                continue;
            }

            counts[Path.GetFileName(workspace)] = Directory.GetFiles(skillsRoot, "SKILL.md", SearchOption.AllDirectories).Length;
            foreach (var command in RequiredCommands)
            {
                var skillPath = Path.Combine(skillsRoot, command, "SKILL.md");
                if (!File.Exists(skillPath))
                {
                    problems.Add(Path.GetFileName(workspace) + " missing skill " + command);
                }
            }
        }

        var distinctCounts = counts.Values.Distinct().ToArray();
        if (distinctCounts.Length > 1)
        {
            warnings.Add("workspace skill counts differ: " + string.Join(", ", counts.Select(pair => pair.Key + "=" + pair.Value)));
        }

        foreach (var agent in config.Agents)
        {
            if (!Directory.Exists(agent.Workspace))
            {
                problems.Add(agent.Id + " workspace missing");
            }

            if (!File.Exists(Path.Combine(agent.Workspace, "HEARTBEAT.md")))
            {
                problems.Add(agent.Id + " HEARTBEAT.md missing");
            }

            if (!string.Equals(agent.HeartbeatEvery, "30s", StringComparison.OrdinalIgnoreCase))
            {
                problems.Add(agent.Id + " heartbeat is not 30s");
            }

            if (!agent.HeartbeatPrompt.Contains("active work", StringComparison.OrdinalIgnoreCase) ||
                !agent.HeartbeatPrompt.Contains("30 seconds", StringComparison.OrdinalIgnoreCase))
            {
                problems.Add(agent.Id + " heartbeat prompt missing active-work/30-second contract");
            }
        }

        return new SkillsMirrorResult(problems.Count == 0, counts, problems, warnings);
    }
}

internal sealed record SkillsMirrorResult(
    bool Ready,
    IReadOnlyDictionary<string, int> SkillCounts,
    IReadOnlyList<string> Problems,
    IReadOnlyList<string> Warnings);
