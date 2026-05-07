using System.Net.Http.Headers;

namespace ClawdBotManagerApp;

internal sealed class GatewayProbe
{
    private static readonly string[] HealthPaths = { "/ready", "/readyz" };
    private static readonly HttpClient Http = new() { Timeout = TimeSpan.FromSeconds(5) };

    public async Task<GatewayProbeResult> CheckAsync(OpenClawConfig config)
    {
        var listenerPids = ProcessUtilities.GetListeningPids(config.GatewayPort);
        if (listenerPids.Count == 0)
        {
            return new GatewayProbeResult(false, false, false, Array.Empty<int>(), "port 18789 listener missing", Array.Empty<string>());
        }

        var httpReady = await ProbeHttpAsync(config);
        var warnings = httpReady.Ready
            ? Array.Empty<string>()
            : new[] { "Gateway HTTP readiness probe slow; listener stays trusted while Telegram providers are ready" };
        return new GatewayProbeResult(true, true, httpReady.Ready, listenerPids, httpReady.Ready ? "gateway ready" : httpReady.Message, warnings);
    }

    private static async Task<(bool Ready, string Message)> ProbeHttpAsync(OpenClawConfig config)
    {
        var checks = HealthPaths.Select(path => ProbePathAsync(config, path)).ToArray();
        var results = await Task.WhenAll(checks);
        var success = results.FirstOrDefault(result => result.Ready);
        if (success.Ready)
        {
            return success;
        }

        return (false, "gateway health or ready probe failed");
    }

    private static async Task<(bool Ready, string Message)> ProbePathAsync(OpenClawConfig config, string path)
    {
        try
        {
            using var request = new HttpRequestMessage(HttpMethod.Get, "http://127.0.0.1:" + config.GatewayPort + path);
            if (!string.IsNullOrWhiteSpace(config.GatewayToken))
            {
                request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", config.GatewayToken);
            }

            using var response = await Http.SendAsync(request, HttpCompletionOption.ResponseHeadersRead);
            if ((int)response.StatusCode is >= 200 and < 300)
            {
                return (true, path + " ok");
            }

            AppLogger.Write("gateway-probe", path + " returned " + (int)response.StatusCode);
        }
        catch (Exception exception)
        {
            AppLogger.Write("gateway-probe", path + " " + exception.Message);
        }

        return (false, path + " failed");
    }
}

internal sealed record GatewayProbeResult(
    bool ProcessPresent,
    bool ListenerPresent,
    bool HttpReady,
    IReadOnlyList<int> ListenerPids,
    string Message,
    IReadOnlyList<string> Warnings);
