using System.Diagnostics;
using System.Management;

namespace ClawdBotManagerApp;

internal static class ProcessUtilities
{
    public static IReadOnlyList<int> GetListeningPids(int port)
    {
        var pids = new HashSet<int>();
        var result = RunProcess(GetNetstatPath(), "-ano -p tcp", TimeSpan.FromSeconds(5));
        if (!result.Success)
        {
            return Array.Empty<int>();
        }

        foreach (var line in result.Output.Split(new[] { "\r\n", "\n" }, StringSplitOptions.RemoveEmptyEntries))
        {
            var parts = line.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length >= 5 &&
                string.Equals(parts[0], "TCP", StringComparison.OrdinalIgnoreCase) &&
                parts[1].EndsWith(":" + port, StringComparison.OrdinalIgnoreCase) &&
                string.Equals(parts[3], "LISTENING", StringComparison.OrdinalIgnoreCase) &&
                int.TryParse(parts[^1], out var pid))
            {
                pids.Add(pid);
            }
        }

        return pids.OrderBy(pid => pid).ToArray();
    }

    private static string GetNetstatPath()
    {
        var systemRoot = Environment.GetEnvironmentVariable("SystemRoot");
        if (string.IsNullOrWhiteSpace(systemRoot))
        {
            systemRoot = @"C:\Windows";
        }

        var system32 = Path.Combine(systemRoot, "System32", "netstat.exe");
        if (File.Exists(system32))
        {
            return system32;
        }

        return "netstat.exe";
    }

    public static bool ProcessExists(int pid)
    {
        if (pid <= 0)
        {
            return false;
        }

        try
        {
            using var process = Process.GetProcessById(pid);
            return !process.HasExited;
        }
        catch
        {
            return false;
        }
    }

    public static string GetCommandLine(int pid)
    {
        try
        {
            using var searcher = new ManagementObjectSearcher("SELECT CommandLine FROM Win32_Process WHERE ProcessId = " + pid);
            foreach (ManagementObject process in searcher.Get())
            {
                return process["CommandLine"]?.ToString() ?? string.Empty;
            }
        }
        catch
        {
            return string.Empty;
        }

        return string.Empty;
    }

    public static int GetParentProcessId(int pid)
    {
        try
        {
            using var searcher = new ManagementObjectSearcher("SELECT ParentProcessId FROM Win32_Process WHERE ProcessId = " + pid);
            foreach (ManagementObject process in searcher.Get())
            {
                return Convert.ToInt32(process["ParentProcessId"]);
            }
        }
        catch
        {
            return 0;
        }

        return 0;
    }

    public static ProcessRunResult RunProcess(string fileName, string arguments, TimeSpan timeout)
    {
        try
        {
            using var process = new Process();
            process.StartInfo.FileName = fileName;
            process.StartInfo.Arguments = arguments;
            process.StartInfo.UseShellExecute = false;
            process.StartInfo.CreateNoWindow = true;
            process.StartInfo.RedirectStandardOutput = true;
            process.StartInfo.RedirectStandardError = true;
            process.Start();
            var outputTask = process.StandardOutput.ReadToEndAsync();
            var errorTask = process.StandardError.ReadToEndAsync();
            if (!process.WaitForExit((int)timeout.TotalMilliseconds))
            {
                try
                {
                    process.Kill();
                }
                catch
                {
                    // The process may have exited between timeout and kill.
                }

                return new ProcessRunResult(false, string.Empty, "timeout");
            }

            var output = outputTask.GetAwaiter().GetResult();
            var error = errorTask.GetAwaiter().GetResult();
            return new ProcessRunResult(process.ExitCode == 0, output, error);
        }
        catch (Exception exception)
        {
            return new ProcessRunResult(false, string.Empty, exception.Message);
        }
    }
}

internal sealed record ProcessRunResult(bool Success, string Output, string Error);
