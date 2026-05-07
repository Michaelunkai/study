using System.Text;

namespace ClawdBotManagerApp;

internal static class AppLogger
{
    private static readonly object Sync = new();
    private static string _logPath = Path.Combine(Path.GetTempPath(), "openclaw", "clawdbot-manager.log");

    public static void Configure(string logPath)
    {
        _logPath = logPath;
        Directory.CreateDirectory(Path.GetDirectoryName(_logPath)!);
    }

    public static void Info(string source, string message)
    {
        Write(source, message);
    }

    public static void Error(string source, Exception exception)
    {
        Write(source, exception.Message + Environment.NewLine + exception);
    }

    public static void Write(string source, string message)
    {
        try
        {
            lock (Sync)
            {
                Directory.CreateDirectory(Path.GetDirectoryName(_logPath)!);
                var line = $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] [{source}] {message}{Environment.NewLine}";
                File.AppendAllText(_logPath, line, Encoding.UTF8);
            }
        }
        catch
        {
            // Logging must never break the tray manager.
        }
    }
}
