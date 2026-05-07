using System.Drawing;
using System.Windows.Forms;

namespace ClawdBotManagerApp;

internal sealed class TrayApplicationContext : ApplicationContext
{
    private const int HardGatewayFailureThreshold = 12;
    private static readonly TimeSpan GreenLatchWindow = TimeSpan.FromSeconds(120);
    private readonly RuntimePaths _paths;
    private readonly GatewaySupervisor _gatewaySupervisor;
    private readonly HealthMonitor _healthMonitor;
    private readonly NotifyIcon _notifyIcon;
    private readonly System.Windows.Forms.Timer _timer;
    private readonly Icon _greenIcon;
    private readonly Icon _yellowIcon;
    private readonly Icon _redIcon;
    private HealthSnapshot? _latestSnapshot;
    private bool _monitorRunning;
    private int _hardFailureCount;
    private DateTime _lastOperationalReadyUtc = DateTime.MinValue;
    private string _lastOperationalStatusText = "Ready: gateway + 4/4 Telegram bots";

    public TrayApplicationContext(RuntimePaths paths)
    {
        _paths = paths;
        _gatewaySupervisor = new GatewaySupervisor(paths);
        _healthMonitor = new HealthMonitor(paths, _gatewaySupervisor);
        _greenIcon = CreateStatusIcon(Color.LimeGreen);
        _yellowIcon = CreateStatusIcon(Color.Goldenrod);
        _redIcon = CreateStatusIcon(Color.Firebrick);
        _notifyIcon = new NotifyIcon
        {
            Visible = true,
            Icon = _yellowIcon,
            Text = "Starting: gateway",
            ContextMenuStrip = BuildMenu()
        };
        _notifyIcon.DoubleClick += (_, _) => OpenDashboard();
        _timer = new System.Windows.Forms.Timer { Interval = 5000 };
        _timer.Tick += async (_, _) => await MonitorAsync();
        _timer.Start();
        Task.Run(() => _gatewaySupervisor.EnsureStarted("startup"));
        Task.Run(async () => await MonitorAsync());
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            _timer.Dispose();
            _notifyIcon.Visible = false;
            _notifyIcon.Dispose();
            _greenIcon.Dispose();
            _yellowIcon.Dispose();
            _redIcon.Dispose();
        }

        base.Dispose(disposing);
    }

    private ContextMenuStrip BuildMenu()
    {
        var menu = new ContextMenuStrip();
        menu.Items.Add("Copy health report", null, (_, _) => CopyHealthReport());
        menu.Items.Add("Open dashboard", null, (_, _) => OpenDashboard());
        menu.Items.Add("Restart gateway", null, (_, _) => RestartGateway());
        menu.Items.Add("Exit", null, (_, _) => Exit());
        return menu;
    }

    private async Task MonitorAsync()
    {
        if (_monitorRunning)
        {
            return;
        }

        _monitorRunning = true;
        try
        {
            var snapshot = await _healthMonitor.EvaluateAsync();
            _latestSnapshot = snapshot;
            ApplySnapshot(snapshot);
        }
        catch (Exception exception)
        {
            AppLogger.Error("monitor", exception);
            SetState("Blocked: monitor error", _redIcon);
        }
        finally
        {
            _monitorRunning = false;
        }
    }

    private void ApplySnapshot(HealthSnapshot snapshot)
    {
        if (snapshot.OperationalReady)
        {
            _hardFailureCount = 0;
            _lastOperationalReadyUtc = DateTime.UtcNow;
            _lastOperationalStatusText = snapshot.StatusText;
            SetState(snapshot.StatusText, _greenIcon);
            return;
        }

        if (ShouldHoldGreen(snapshot))
        {
            _hardFailureCount = 0;
            SetState(_lastOperationalStatusText, _greenIcon);
            return;
        }

        if (snapshot.StartupPending)
        {
            SetState(snapshot.StatusText, _yellowIcon);
            return;
        }

        if (!snapshot.GatewayReady)
        {
            _hardFailureCount++;
            if (_hardFailureCount >= HardGatewayFailureThreshold)
            {
                SetState("Recovering: gateway", _yellowIcon);
                Task.Run(() =>
                {
                    _gatewaySupervisor.StopOwnedGateway();
                    _gatewaySupervisor.Start("health-recovery");
                });
                _hardFailureCount = 0;
                return;
            }
        }

        SetState(snapshot.StatusText, snapshot.GatewayReady ? _yellowIcon : _redIcon);
    }

    private bool ShouldHoldGreen(HealthSnapshot snapshot)
    {
        if (_lastOperationalReadyUtc == DateTime.MinValue ||
            DateTime.UtcNow - _lastOperationalReadyUtc > GreenLatchWindow)
        {
            return false;
        }

        if (!snapshot.CommandSurfaceReady || !snapshot.PermissionsReady || !snapshot.SkillsReady)
        {
            return false;
        }

        if (snapshot.Problems.Any(IsHardProblem))
        {
            return false;
        }

        return snapshot.StartupPending || !snapshot.GatewayReady || !snapshot.TelegramReady;
    }

    private static bool IsHardProblem(string problem)
    {
        return problem.Contains("Telegram runtime failure", StringComparison.OrdinalIgnoreCase) ||
               problem.Contains("token missing", StringComparison.OrdinalIgnoreCase) ||
               problem.Contains("disabled", StringComparison.OrdinalIgnoreCase) ||
               problem.Contains("accounts mismatch", StringComparison.OrdinalIgnoreCase) ||
               problem.Contains("channel disabled", StringComparison.OrdinalIgnoreCase);
    }

    private void SetState(string text, Icon icon)
    {
        var display = text.Length > 63 ? text[..63] : text;
        if (!string.Equals(_notifyIcon.Text, display, StringComparison.Ordinal))
        {
            AppLogger.Write("tray", display);
        }

        _notifyIcon.Text = display;
        _notifyIcon.Icon = icon;
    }

    private void CopyHealthReport()
    {
        if (_latestSnapshot == null)
        {
            return;
        }

        Clipboard.SetText(HealthReportBuilder.BuildText(_latestSnapshot));
    }

    private void OpenDashboard()
    {
        try
        {
            using var process = new System.Diagnostics.Process();
            process.StartInfo.FileName = "http://127.0.0.1:18789/__openclaw__/canvas/";
            process.StartInfo.UseShellExecute = true;
            process.Start();
        }
        catch (Exception exception)
        {
            AppLogger.Error("dashboard", exception);
        }
    }

    private void RestartGateway()
    {
        Task.Run(() =>
        {
            _gatewaySupervisor.StopOwnedGateway();
            _gatewaySupervisor.Start("menu-restart");
        });
    }

    private void Exit()
    {
        _gatewaySupervisor.StopOwnedGateway();
        ExitThread();
    }

    private static Icon CreateStatusIcon(Color color)
    {
        using var bitmap = new Bitmap(16, 16);
        using (var graphics = Graphics.FromImage(bitmap))
        {
            graphics.Clear(Color.Transparent);
            using var brush = new SolidBrush(color);
            graphics.FillEllipse(brush, 1, 1, 14, 14);
            using var pen = new Pen(Color.White, 2);
            graphics.DrawEllipse(pen, 3, 3, 10, 10);
        }

        return Icon.FromHandle(bitmap.GetHicon());
    }
}
