using System.Threading;
using System.Windows.Forms;

namespace ClawdBotManagerApp;

internal static class Program
{
    [STAThread]
    private static int Main(string[] args)
    {
        var paths = RuntimePaths.CreateDefault();
        AppLogger.Configure(paths.ManagerLogPath);
        AppDomain.CurrentDomain.UnhandledException += (_, eventArgs) =>
        {
            if (eventArgs.ExceptionObject is Exception exception)
            {
                AppLogger.Error("unhandled", exception);
            }
        };

        Application.ThreadException += (_, eventArgs) => AppLogger.Error("ui", eventArgs.Exception);

        var headlessAction = CommandLine.ParseHeadlessAction(args);
        if (!string.IsNullOrWhiteSpace(headlessAction))
        {
            return HeadlessActions.RunAsync(headlessAction, paths).GetAwaiter().GetResult();
        }

        using var mutex = new Mutex(true, @"Local\ClawdBotManager.SingleInstance", out var createdNew);
        if (!createdNew)
        {
            AppLogger.Info("startup", "visible manager already running");
            return 0;
        }

        ApplicationConfiguration.Initialize();
        using var context = new TrayApplicationContext(paths);
        Application.Run(context);
        return 0;
    }
}

internal static class CommandLine
{
    public static string ParseHeadlessAction(string[] args)
    {
        for (var i = 0; i < args.Length; i++)
        {
            var arg = args[i];
            if (string.Equals(arg, "--headless-action", StringComparison.OrdinalIgnoreCase) && i + 1 < args.Length)
            {
                return args[i + 1].Trim();
            }

            const string prefix = "--headless-action=";
            if (arg.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
            {
                return arg[prefix.Length..].Trim();
            }
        }

        return string.Empty;
    }
}
