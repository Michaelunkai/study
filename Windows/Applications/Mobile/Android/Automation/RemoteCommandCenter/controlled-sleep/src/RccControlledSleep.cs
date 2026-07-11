using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Net;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Windows.Forms;

internal static class RccControlledSleep
{
    private const int WM_SYSCOMMAND = 0x0112;
    private static readonly IntPtr HWND_BROADCAST = new IntPtr(0xffff);
    private static readonly IntPtr SC_MONITORPOWER = new IntPtr(0xF170);
    private static volatile string exitReason;
    private static readonly List<Form> forms = new List<Form>();
    private static string signalPath;
    private static string markerPath;
    private static string logPath;
    private static string sharedKey;
    private static string commandTopic;
    private static readonly List<string> relayBases = new List<string>();

    [DllImport("user32.dll", SetLastError = true)]
    private static extern IntPtr SendMessage(IntPtr hWnd, int msg, IntPtr wParam, IntPtr lParam);

    [DllImport("powrprof.dll", SetLastError = true)]
    private static extern bool SetSuspendState(bool hibernate, bool forceCritical, bool disableWakeEvent);

    [STAThread]
    private static int Main(string[] args)
    {
        string configPath = GetArg(args, "--config", Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..", "..", "scripts", "rcc-config.json"));
        string nonce = GetArg(args, "--nonce", "");
        bool proofOnly = HasArg(args, "--proof");
        bool actualSleep = HasArg(args, "--actual-sleep");

        LoadConfig(configPath);
        Directory.CreateDirectory(Path.GetDirectoryName(logPath));
        Directory.CreateDirectory(Path.GetDirectoryName(signalPath));
        Log("CONTROLLED_SLEEP_EXE_START nonce=" + nonce + " proofOnly=" + proofOnly + " actualSleep=" + actualSleep);
        Log("CONTROLLED_SLEEP_EXE_SIGNAL path=\"" + signalPath + "\"");

        if (proofOnly)
        {
            if (actualSleep)
            {
                Log("CONTROLLED_SLEEP_EXE_PROOF_READY mode=actual-windows-suspend api=powrprof.SetSuspendState hibernate=False forceCritical=True disableWakeEvent=False");
            }
            else
            {
                Log("CONTROLLED_SLEEP_EXE_PROOF_READY mode=compiled-winforms-overlay exit=space-or-double-click-or-android-signal-or-relay trueWindowsSleep=False");
            }
            return 0;
        }

        File.Delete(signalPath);
        File.WriteAllText(markerPath, "{\"pid\":" + GetCurrentProcessId() + ",\"startedAt\":\"" + DateTimeOffset.UtcNow.ToString("o") + "\",\"signalPath\":\"" + JsonEscape(signalPath) + "\"}", Encoding.UTF8);

        if (actualSleep)
        {
            Log("CONTROLLED_SLEEP_EXE_ACTUAL_SLEEP_CALL api=powrprof.SetSuspendState hibernate=False forceCritical=True disableWakeEvent=False");
            bool ok = SetSuspendState(false, true, false);
            int error = Marshal.GetLastWin32Error();
            Log("CONTROLLED_SLEEP_EXE_ACTUAL_SLEEP_RETURN ok=" + ok + " lastError=" + error);
            TryDelete(markerPath);
            return ok ? 0 : 2;
        }

        Thread relayThread = new Thread(RelayPollLoop);
        relayThread.IsBackground = true;
        relayThread.Start();

        try
        {
            Application.EnableVisualStyles();
            Cursor.Hide();
            CreateForms();
            System.Windows.Forms.Timer timer = new System.Windows.Forms.Timer();
            timer.Interval = 100;
            timer.Tick += delegate
            {
                if (File.Exists(signalPath))
                {
                    RequestExit("android-wake-signal");
                    return;
                }
                foreach (Form form in forms)
                {
                    if (!form.IsDisposed && exitReason == null)
                    {
                        form.TopMost = true;
                        form.BringToFront();
                    }
                }
            };

            foreach (Form form in forms)
            {
                form.Show();
                form.Activate();
            }
            timer.Start();
            TryMonitorPower(2, "CONTROLLED_SLEEP_EXE_MONITOR_OFF_SENT");
            Log("CONTROLLED_SLEEP_EXE_RUNNING screens=" + forms.Count);

            while (exitReason == null)
            {
                Application.DoEvents();
                Thread.Sleep(30);
            }

            CloseForms();
            return 0;
        }
        finally
        {
            TryMonitorPower(-1, "CONTROLLED_SLEEP_EXE_MONITOR_ON_SENT");
            try { Cursor.Show(); } catch { }
            TryDelete(markerPath);
            TryDelete(signalPath);
            Log("CONTROLLED_SLEEP_EXE_DONE reason=" + exitReason);
        }
    }

    private static void CreateForms()
    {
        foreach (Screen screen in Screen.AllScreens)
        {
            Form form = new Form();
            form.Text = "RemoteCommandCenter Controlled Sleep";
            form.FormBorderStyle = FormBorderStyle.None;
            form.StartPosition = FormStartPosition.Manual;
            form.Bounds = screen.Bounds;
            form.BackColor = Color.Black;
            form.TopMost = true;
            form.ShowInTaskbar = false;
            form.KeyPreview = true;

            Label label = new Label();
            label.Dock = DockStyle.Fill;
            label.TextAlign = ContentAlignment.MiddleCenter;
            label.ForeColor = Color.FromArgb(35, 35, 35);
            label.BackColor = Color.Black;
            label.Font = new Font("Segoe UI", 18, FontStyle.Regular);
            label.Text = "Controlled Sleep";
            form.Controls.Add(label);

            form.KeyDown += delegate(object sender, KeyEventArgs e)
            {
                if (e.KeyCode == Keys.Space)
                {
                    RequestExit("space-key");
                }
                else
                {
                    e.SuppressKeyPress = true;
                    e.Handled = true;
                }
            };
            form.MouseDoubleClick += delegate { RequestExit("mouse-double-click"); };
            form.FormClosing += delegate(object sender, FormClosingEventArgs e)
            {
                if (exitReason == null) e.Cancel = true;
            };
            form.Deactivate += delegate(object sender, EventArgs e)
            {
                if (exitReason == null)
                {
                    Form f = (Form)sender;
                    f.TopMost = true;
                    f.Activate();
                }
            };
            forms.Add(form);
        }
    }

    private static void RelayPollLoop()
    {
        long since = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        while (exitReason == null)
        {
            foreach (string relayBase in relayBases)
            {
                if (exitReason != null) break;
                try
                {
                    string url = relayBase.TrimEnd('/') + "/" + commandTopic + "/json?poll=1&since=" + since;
                    string text = new TimeoutWebClient(3500).DownloadString(url);
                    since = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
                    foreach (Match match in Regex.Matches(text, "\"message\"\\s*:\\s*\"((?:\\\\.|[^\"])*)\""))
                    {
                        string message = Regex.Unescape(match.Groups[1].Value);
                        if (IsValidWakeCommand(message))
                        {
                            Log("CONTROLLED_SLEEP_EXE_RELAY_WAKE_ACCEPTED");
                            RequestExit("relay-wake-command");
                            return;
                        }
                    }
                }
                catch (Exception ex)
                {
                    Log("CONTROLLED_SLEEP_EXE_RELAY_POLL_SKIPPED error=\"" + ex.Message.Replace("\"", "'") + "\"");
                }
            }
            Thread.Sleep(400);
        }
    }

    private static bool IsValidWakeCommand(string json)
    {
        string action = JsonString(json, "action");
        if (action != "wake_pc" && action != "wake_controlled_sleep") return false;
        string type = JsonString(json, "type");
        string nonce = JsonString(json, "nonce");
        string confirm = JsonString(json, "confirm");
        string signature = JsonString(json, "signature");
        string createdAt = JsonNumber(json, "createdAt");
        string dryRun = JsonBool(json, "dryRun");
        if (type != "rcc" || confirm != "REMOTE_COMMAND_CENTER_CONFIRM" || nonce == "" || signature == "" || createdAt == "" || dryRun == "") return false;

        string canonical = "rcc|" + createdAt + "|" + nonce + "|" + dryRun + "|" + action + "|" + confirm;
        string expected = HmacBase64Url(canonical, sharedKey);
        return FixedEquals(signature, expected);
    }

    private static string HmacBase64Url(string text, string key)
    {
        byte[] keyBytes = Base64UrlDecode(key);
        using (HMACSHA256 hmac = new HMACSHA256(keyBytes))
        {
            return Base64UrlEncode(hmac.ComputeHash(Encoding.UTF8.GetBytes(text)));
        }
    }

    private static byte[] Base64UrlDecode(string value)
    {
        string s = value.Replace('-', '+').Replace('_', '/');
        while (s.Length % 4 != 0) s += "=";
        return Convert.FromBase64String(s);
    }

    private static string Base64UrlEncode(byte[] value)
    {
        return Convert.ToBase64String(value).TrimEnd('=').Replace('+', '-').Replace('/', '_');
    }

    private static bool FixedEquals(string a, string b)
    {
        if (a.Length != b.Length) return false;
        int diff = 0;
        for (int i = 0; i < a.Length; i++) diff |= a[i] ^ b[i];
        return diff == 0;
    }

    private static void LoadConfig(string configPath)
    {
        string json = File.ReadAllText(configPath, Encoding.UTF8);
        string stateDir = JsonString(json, "StateDir");
        string logDir = JsonString(json, "LogDir");
        if (stateDir == "") stateDir = JsonString(json, "stateDir");
        if (logDir == "") logDir = JsonString(json, "logDir");
        sharedKey = JsonString(json, "SharedKey");
        commandTopic = JsonString(json, "CommandTopic");
        if (sharedKey == "") sharedKey = JsonString(json, "sharedKey");
        if (commandTopic == "") commandTopic = JsonString(json, "commandTopic");
        foreach (string relay in JsonArray(json, "RelayBases")) relayBases.Add(relay);
        foreach (string relay in JsonArray(json, "relayBases")) if (!relayBases.Contains(relay)) relayBases.Add(relay);
        signalPath = Path.Combine(stateDir, "controlled-sleep-wake.signal");
        markerPath = Path.Combine(stateDir, "controlled-sleep-running.json");
        logPath = Path.Combine(logDir, "controlled-sleep.log");
    }

    private static string JsonString(string json, string name)
    {
        Match m = Regex.Match(json, "\"" + Regex.Escape(name) + "\"\\s*:\\s*\"((?:\\\\.|[^\"])*)\"");
        return m.Success ? Regex.Unescape(m.Groups[1].Value) : "";
    }

    private static string JsonNumber(string json, string name)
    {
        Match m = Regex.Match(json, "\"" + Regex.Escape(name) + "\"\\s*:\\s*([0-9]+)");
        return m.Success ? m.Groups[1].Value : "";
    }

    private static string JsonBool(string json, string name)
    {
        Match m = Regex.Match(json, "\"" + Regex.Escape(name) + "\"\\s*:\\s*(true|false)");
        return m.Success ? m.Groups[1].Value : "";
    }

    private static IEnumerable<string> JsonArray(string json, string name)
    {
        Match m = Regex.Match(json, "\"" + Regex.Escape(name) + "\"\\s*:\\s*\\[(.*?)\\]", RegexOptions.Singleline);
        if (!m.Success) yield break;
        foreach (Match item in Regex.Matches(m.Groups[1].Value, "\"((?:\\\\.|[^\"])*)\""))
        {
            yield return Regex.Unescape(item.Groups[1].Value);
        }
    }

    private static void RequestExit(string reason)
    {
        if (exitReason != null) return;
        exitReason = reason;
        Log("CONTROLLED_SLEEP_EXE_EXIT_REQUEST reason=" + reason);
        CloseForms();
    }

    private static void CloseForms()
    {
        foreach (Form form in forms.ToArray())
        {
            try
            {
                if (!form.IsDisposed) form.Close();
            }
            catch { }
        }
    }

    private static void TryMonitorPower(int state, string logMessage)
    {
        try
        {
            SendMessage(HWND_BROADCAST, WM_SYSCOMMAND, SC_MONITORPOWER, new IntPtr(state));
            Log(logMessage);
        }
        catch (Exception ex)
        {
            Log(logMessage.Replace("_SENT", "_FAILED") + " error=\"" + ex.Message.Replace("\"", "'") + "\"");
        }
    }

    private static string GetArg(string[] args, string name, string defaultValue)
    {
        for (int i = 0; i < args.Length - 1; i++)
        {
            if (args[i].Equals(name, StringComparison.OrdinalIgnoreCase)) return args[i + 1];
        }
        return defaultValue;
    }

    private static bool HasArg(string[] args, string name)
    {
        foreach (string arg in args) if (arg.Equals(name, StringComparison.OrdinalIgnoreCase)) return true;
        return false;
    }

    private static void Log(string message)
    {
        string line = "[" + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff") + "] " + message;
        File.AppendAllText(logPath, line + Environment.NewLine, Encoding.UTF8);
        Console.WriteLine(line);
    }

    private static string JsonEscape(string value)
    {
        return value.Replace("\\", "\\\\").Replace("\"", "\\\"");
    }

    private static void TryDelete(string path)
    {
        try { if (File.Exists(path)) File.Delete(path); } catch { }
    }

    private static int GetCurrentProcessId()
    {
        return System.Diagnostics.Process.GetCurrentProcess().Id;
    }

    private sealed class TimeoutWebClient : WebClient
    {
        private readonly int timeoutMs;
        public TimeoutWebClient(int timeoutMs)
        {
            this.timeoutMs = timeoutMs;
            Encoding = Encoding.UTF8;
        }

        protected override WebRequest GetWebRequest(Uri address)
        {
            WebRequest request = base.GetWebRequest(address);
            request.Timeout = timeoutMs;
            return request;
        }
    }
}
