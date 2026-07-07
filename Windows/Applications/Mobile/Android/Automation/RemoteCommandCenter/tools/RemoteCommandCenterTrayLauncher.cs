using System;
using System.Diagnostics;
using System.IO;
using System.Linq;

internal static class RemoteCommandCenterTrayLauncher
{
    private static int Main(string[] args)
    {
        string exeDir = AppDomain.CurrentDomain.BaseDirectory.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
        string root = string.Equals(Path.GetFileName(exeDir), "dist", StringComparison.OrdinalIgnoreCase)
            ? Directory.GetParent(exeDir).FullName
            : exeDir;

        string configPath = Path.Combine(root, "scripts", "rcc-config.json");
        for (int i = 0; i < args.Length - 1; i++)
        {
            if (string.Equals(args[i], "-ConfigPath", StringComparison.OrdinalIgnoreCase))
            {
                configPath = args[i + 1];
            }
        }

        string psExe = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows), "System32", "WindowsPowerShell", "v1.0", "powershell.exe");
        string trayScript = Path.Combine(root, "scripts", "Start-RemoteCommandCenterTray.ps1");
        if (!File.Exists(trayScript))
        {
            Console.Error.WriteLine("Missing tray script: " + trayScript);
            return 2;
        }
        if (!File.Exists(configPath))
        {
            Console.Error.WriteLine("Missing config: " + configPath);
            return 3;
        }

        string arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File " + Quote(trayScript) + " -ConfigPath " + Quote(configPath);
        var startInfo = new ProcessStartInfo(psExe, arguments)
        {
            UseShellExecute = false,
            CreateNoWindow = true,
            WindowStyle = ProcessWindowStyle.Hidden
        };

        using (Process process = Process.Start(startInfo))
        {
            process.WaitForExit();
            return process.ExitCode;
        }
    }

    private static string Quote(string value)
    {
        return "\"" + value.Replace("\"", "\\\"") + "\"";
    }
}

