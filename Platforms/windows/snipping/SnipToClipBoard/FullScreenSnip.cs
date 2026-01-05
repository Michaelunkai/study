using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using Microsoft.Win32;
using System.Threading;

class FullScreenSnip : Form
{
    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool UnregisterHotKey(IntPtr hWnd, int id);

    [DllImport("kernel32.dll")]
    private static extern uint GetLastError();

    [DllImport("user32.dll")]
    private static extern bool SetProcessDPIAware();

    [DllImport("shcore.dll")]
    private static extern int SetProcessDpiAwareness(int awareness);

    [DllImport("user32.dll")]
    private static extern int GetSystemMetrics(int nIndex);

    [DllImport("user32.dll")]
    private static extern IntPtr MonitorFromPoint(POINT pt, uint dwFlags);

    [DllImport("shcore.dll")]
    private static extern int GetDpiForMonitor(IntPtr hmonitor, int dpiType, out uint dpiX, out uint dpiY);

    [DllImport("user32.dll")]
    private static extern bool EnumDisplayMonitors(IntPtr hdc, IntPtr lprcClip, MonitorEnumProc lpfnEnum, IntPtr dwData);

    [DllImport("user32.dll")]
    private static extern bool GetMonitorInfo(IntPtr hMonitor, ref MONITORINFO lpmi);

    private delegate bool MonitorEnumProc(IntPtr hMonitor, IntPtr hdcMonitor, ref RECT lprcMonitor, IntPtr dwData);

    [StructLayout(LayoutKind.Sequential)]
    private struct POINT { public int X; public int Y; }

    [StructLayout(LayoutKind.Sequential)]
    private struct RECT { public int Left; public int Top; public int Right; public int Bottom; }

    [StructLayout(LayoutKind.Sequential)]
    private struct MONITORINFO
    {
        public int cbSize;
        public RECT rcMonitor;
        public RECT rcWork;
        public uint dwFlags;
    }

    private const int SM_CXSCREEN = 0;
    private const int SM_CYSCREEN = 1;
    private const int SM_XVIRTUALSCREEN = 76;
    private const int SM_YVIRTUALSCREEN = 77;
    private const int SM_CXVIRTUALSCREEN = 78;
    private const int SM_CYVIRTUALSCREEN = 79;
    private const uint MONITOR_DEFAULTTONEAREST = 2;

    private const int HOTKEY_FULLSCREEN = 9002;
    private const int HOTKEY_FREESNIP = 9003;
    private const uint MOD_CTRL = 0x0002;
    private const uint MOD_ALT = 0x0001;
    private const uint MOD_NOREPEAT = 0x4000;
    private const uint VK_S = 0x53;
    private const int WM_HOTKEY = 0x0312;

    private NotifyIcon trayIcon;
    private static Mutex mutex;
    private bool hotkeyFullscreenRegistered = false;
    private bool hotkeyFreesnipRegistered = false;
    private bool saveAsPath = false;
    private bool runAtStartup = true;
    private string screenshotFolder;
    private MenuItem saveAsPathMenuItem;
    private MenuItem startupMenuItem;

    public FullScreenSnip()
    {
        this.ShowInTaskbar = false;
        this.WindowState = FormWindowState.Minimized;
        this.FormBorderStyle = FormBorderStyle.None;
        this.Opacity = 0;
        this.Size = new Size(1, 1);
        this.Load += FullScreenSnip_Load;

        screenshotFolder = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "Screenshots");
        if (!Directory.Exists(screenshotFolder))
        {
            Directory.CreateDirectory(screenshotFolder);
        }
    }

    private void FullScreenSnip_Load(object sender, EventArgs e)
    {
        try
        {
            LoadSettings();
            SetupTrayIcon();
            if (runAtStartup) AddToStartup(); else RemoveFromStartup();
            RegisterHotkeys();
            this.Hide();
        }
        catch (Exception ex)
        {
            MessageBox.Show("Startup error: " + ex.Message, "FullScreenSnip Error",
                MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }

    private void LoadSettings()
    {
        try
        {
            using (RegistryKey key = Registry.CurrentUser.OpenSubKey(@"SOFTWARE\FullScreenSnip", false))
            {
                if (key != null)
                {
                    saveAsPath = ((int)key.GetValue("SaveAsPath", 0)) == 1;
                    runAtStartup = ((int)key.GetValue("RunAtStartup", 1)) == 1;
                    string folder = key.GetValue("ScreenshotFolder", "") as string;
                    if (!string.IsNullOrEmpty(folder) && Directory.Exists(folder))
                    {
                        screenshotFolder = folder;
                    }
                }
            }
        }
        catch { }
    }

    private void SaveSettings()
    {
        try
        {
            using (RegistryKey key = Registry.CurrentUser.CreateSubKey(@"SOFTWARE\FullScreenSnip"))
            {
                if (key != null)
                {
                    key.SetValue("SaveAsPath", saveAsPath ? 1 : 0);
                    key.SetValue("RunAtStartup", runAtStartup ? 1 : 0);
                    key.SetValue("ScreenshotFolder", screenshotFolder);
                }
            }
        }
        catch { }
    }

    private void SetupTrayIcon()
    {
        trayIcon = new NotifyIcon();
        trayIcon.Icon = SystemIcons.Application;
        trayIcon.Text = "FullScreenSnip\nCtrl+Alt+S: Full Screen\nAlt+S: Free Snip";
        trayIcon.Visible = true;
        trayIcon.DoubleClick += OnCaptureClick;

        ContextMenu menu = new ContextMenu();
        menu.MenuItems.Add("Full Screen Capture (Ctrl+Alt+S)", OnCaptureClick);
        menu.MenuItems.Add("Free Snip (Alt+S)", OnFreeSnipClick);
        menu.MenuItems.Add("-");

        saveAsPathMenuItem = new MenuItem("Save as PNG Path (for AI CLI)");
        saveAsPathMenuItem.Checked = saveAsPath;
        saveAsPathMenuItem.Click += OnToggleSaveAsPath;
        menu.MenuItems.Add(saveAsPathMenuItem);

        menu.MenuItems.Add("Change Screenshot Folder...", OnChangeFolderClick);
        menu.MenuItems.Add("-");

        startupMenuItem = new MenuItem("Run at Startup");
        startupMenuItem.Checked = runAtStartup;
        startupMenuItem.Click += OnToggleStartup;
        menu.MenuItems.Add(startupMenuItem);

        menu.MenuItems.Add("-");
        menu.MenuItems.Add("Re-register Hotkeys", OnReregisterClick);
        menu.MenuItems.Add("Exit", OnExitClick);
        trayIcon.ContextMenu = menu;
    }

    private void RegisterHotkeys()
    {
        UnregisterHotKey(this.Handle, HOTKEY_FULLSCREEN);
        UnregisterHotKey(this.Handle, HOTKEY_FREESNIP);
        Thread.Sleep(100);

        hotkeyFullscreenRegistered = RegisterHotKey(this.Handle, HOTKEY_FULLSCREEN, MOD_CTRL | MOD_ALT | MOD_NOREPEAT, VK_S);
        hotkeyFreesnipRegistered = RegisterHotKey(this.Handle, HOTKEY_FREESNIP, MOD_ALT | MOD_NOREPEAT, VK_S);

        string msg = "";
        if (hotkeyFullscreenRegistered && hotkeyFreesnipRegistered)
        {
            msg = "Ctrl+Alt+S: Full Screen\nAlt+S: Free Snip";
            trayIcon.ShowBalloonTip(3000, "FullScreenSnip Ready!", msg, ToolTipIcon.Info);
        }
        else
        {
            if (!hotkeyFullscreenRegistered) msg += "Ctrl+Alt+S failed. ";
            if (!hotkeyFreesnipRegistered) msg += "Alt+S failed. ";
            trayIcon.ShowBalloonTip(5000, "FullScreenSnip Warning", msg + "Use tray menu.", ToolTipIcon.Warning);
        }
    }

    private void OnCaptureClick(object sender, EventArgs e) { CaptureFullScreen(); }
    private void OnFreeSnipClick(object sender, EventArgs e) { StartFreeSnip(); }

    private void OnToggleSaveAsPath(object sender, EventArgs e)
    {
        saveAsPath = !saveAsPath;
        saveAsPathMenuItem.Checked = saveAsPath;
        SaveSettings();
        string mode = saveAsPath ? "PNG file path (for AI CLI)" : "Clipboard image";
        trayIcon.ShowBalloonTip(2000, "Mode Changed", "Screenshots saved as: " + mode, ToolTipIcon.Info);
    }

    private void OnToggleStartup(object sender, EventArgs e)
    {
        runAtStartup = !runAtStartup;
        startupMenuItem.Checked = runAtStartup;
        if (runAtStartup) AddToStartup(); else RemoveFromStartup();
        SaveSettings();
        trayIcon.ShowBalloonTip(2000, "Startup Changed",
            runAtStartup ? "Will run at Windows startup" : "Removed from startup", ToolTipIcon.Info);
    }

    private void OnChangeFolderClick(object sender, EventArgs e)
    {
        using (FolderBrowserDialog fbd = new FolderBrowserDialog())
        {
            fbd.Description = "Select folder for screenshots";
            fbd.SelectedPath = screenshotFolder;
            if (fbd.ShowDialog() == DialogResult.OK)
            {
                screenshotFolder = fbd.SelectedPath;
                SaveSettings();
                trayIcon.ShowBalloonTip(2000, "Folder Changed", screenshotFolder, ToolTipIcon.Info);
            }
        }
    }

    private void OnReregisterClick(object sender, EventArgs e)
    {
        UnregisterHotKey(this.Handle, HOTKEY_FULLSCREEN);
        UnregisterHotKey(this.Handle, HOTKEY_FREESNIP);
        Thread.Sleep(200);
        RegisterHotkeys();
    }

    private void OnExitClick(object sender, EventArgs e)
    {
        trayIcon.Visible = false;
        Application.Exit();
    }

    private void AddToStartup()
    {
        try
        {
            string exePath = Application.ExecutablePath;
            using (RegistryKey key = Registry.CurrentUser.OpenSubKey(
                @"SOFTWARE\Microsoft\Windows\CurrentVersion\Run", true))
            {
                if (key != null)
                {
                    key.SetValue("FullScreenSnip", "\"" + exePath + "\"");
                }
            }
        }
        catch { }
    }

    private void RemoveFromStartup()
    {
        try
        {
            using (RegistryKey key = Registry.CurrentUser.OpenSubKey(
                @"SOFTWARE\Microsoft\Windows\CurrentVersion\Run", true))
            {
                if (key != null)
                {
                    key.DeleteValue("FullScreenSnip", false);
                }
            }
        }
        catch { }
    }

    protected override void WndProc(ref Message m)
    {
        if (m.Msg == WM_HOTKEY)
        {
            int id = m.WParam.ToInt32();
            if (id == HOTKEY_FULLSCREEN) CaptureFullScreen();
            else if (id == HOTKEY_FREESNIP) StartFreeSnip();
        }
        base.WndProc(ref m);
    }

    private void CaptureFullScreen()
    {
        try
        {
            // Use GetSystemMetrics for accurate physical resolution (DPI-aware)
            int minX = GetSystemMetrics(SM_XVIRTUALSCREEN);
            int minY = GetSystemMetrics(SM_YVIRTUALSCREEN);
            int width = GetSystemMetrics(SM_CXVIRTUALSCREEN);
            int height = GetSystemMetrics(SM_CYVIRTUALSCREEN);

            // Fallback if virtual screen metrics fail
            if (width <= 0 || height <= 0)
            {
                width = GetSystemMetrics(SM_CXSCREEN);
                height = GetSystemMetrics(SM_CYSCREEN);
                minX = 0;
                minY = 0;
            }

            using (Bitmap bmp = new Bitmap(width, height))
            {
                using (Graphics g = Graphics.FromImage(bmp))
                {
                    g.CopyFromScreen(minX, minY, 0, 0, new Size(width, height), CopyPixelOperation.SourceCopy);
                }
                SaveOrCopy(bmp, width, height);
            }
        }
        catch (Exception ex)
        {
            trayIcon.ShowBalloonTip(3000, "Screenshot Error", ex.Message, ToolTipIcon.Error);
        }
    }

    private void StartFreeSnip()
    {
        SnipOverlay overlay = new SnipOverlay(this);
        overlay.Show();
    }

    public void ProcessSnip(Rectangle selection)
    {
        if (selection.Width <= 0 || selection.Height <= 0) return;

        try
        {
            using (Bitmap bmp = new Bitmap(selection.Width, selection.Height))
            {
                using (Graphics g = Graphics.FromImage(bmp))
                {
                    g.CopyFromScreen(selection.X, selection.Y, 0, 0, selection.Size, CopyPixelOperation.SourceCopy);
                }
                SaveOrCopy(bmp, selection.Width, selection.Height);
            }
        }
        catch (Exception ex)
        {
            trayIcon.ShowBalloonTip(3000, "Snip Error", ex.Message, ToolTipIcon.Error);
        }
    }

    private void SaveOrCopy(Bitmap bmp, int width, int height)
    {
        if (saveAsPath)
        {
            string filename = "screenshot_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".png";
            string fullPath = Path.Combine(screenshotFolder, filename);
            bmp.Save(fullPath, System.Drawing.Imaging.ImageFormat.Png);
            Clipboard.SetText(fullPath);
            trayIcon.ShowBalloonTip(2000, "Screenshot Saved!",
                "Path copied to clipboard:\n" + fullPath, ToolTipIcon.Info);
        }
        else
        {
            Clipboard.SetImage(bmp);
            trayIcon.ShowBalloonTip(1500, "Screenshot Captured!",
                "Copied to clipboard (" + width + "x" + height + ")", ToolTipIcon.Info);
        }
    }

    protected override void OnFormClosing(FormClosingEventArgs e)
    {
        if (hotkeyFullscreenRegistered) UnregisterHotKey(this.Handle, HOTKEY_FULLSCREEN);
        if (hotkeyFreesnipRegistered) UnregisterHotKey(this.Handle, HOTKEY_FREESNIP);
        if (trayIcon != null)
        {
            trayIcon.Visible = false;
            trayIcon.Dispose();
        }
        base.OnFormClosing(e);
    }

    [STAThread]
    static void Main()
    {
        bool createdNew;
        mutex = new Mutex(true, "Global\\FullScreenSnipMutex2025v3", out createdNew);

        if (!createdNew) return;

        // Enable DPI awareness BEFORE any UI - try modern API first, fallback to legacy
        try { SetProcessDpiAwareness(2); } // PROCESS_PER_MONITOR_DPI_AWARE
        catch { try { SetProcessDPIAware(); } catch { } }

        try
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new FullScreenSnip());
        }
        finally
        {
            if (mutex != null)
            {
                mutex.ReleaseMutex();
                mutex.Dispose();
            }
        }
    }
}

class SnipOverlay : Form
{
    [DllImport("user32.dll")]
    private static extern int GetSystemMetrics(int nIndex);

    private const int SM_XVIRTUALSCREEN = 76;
    private const int SM_YVIRTUALSCREEN = 77;
    private const int SM_CXVIRTUALSCREEN = 78;
    private const int SM_CYVIRTUALSCREEN = 79;

    private FullScreenSnip parent;
    private Point startPoint;
    private Rectangle selection;
    private bool isSelecting = false;
    private Bitmap screenCapture;

    public SnipOverlay(FullScreenSnip parent)
    {
        this.parent = parent;

        // Use GetSystemMetrics for accurate physical resolution (DPI-aware)
        int minX = GetSystemMetrics(SM_XVIRTUALSCREEN);
        int minY = GetSystemMetrics(SM_YVIRTUALSCREEN);
        int width = GetSystemMetrics(SM_CXVIRTUALSCREEN);
        int height = GetSystemMetrics(SM_CYVIRTUALSCREEN);

        this.FormBorderStyle = FormBorderStyle.None;
        this.StartPosition = FormStartPosition.Manual;
        this.Location = new Point(minX, minY);
        this.Size = new Size(width, height);
        this.TopMost = true;
        this.ShowInTaskbar = false;
        this.DoubleBuffered = true;
        this.Cursor = Cursors.Cross;
        this.BackColor = Color.Black;
        this.Opacity = 1.0;

        screenCapture = new Bitmap(width, height);
        using (Graphics g = Graphics.FromImage(screenCapture))
        {
            g.CopyFromScreen(minX, minY, 0, 0, new Size(width, height), CopyPixelOperation.SourceCopy);
        }

        this.MouseDown += OnMouseDown;
        this.MouseMove += OnMouseMove;
        this.MouseUp += OnMouseUp;
        this.KeyDown += OnKeyDown;
        this.Paint += OnPaint;
    }

    private void OnMouseDown(object sender, MouseEventArgs e)
    {
        if (e.Button == MouseButtons.Left)
        {
            isSelecting = true;
            startPoint = e.Location;
            selection = new Rectangle(e.Location, Size.Empty);
        }
    }

    private void OnMouseMove(object sender, MouseEventArgs e)
    {
        if (isSelecting)
        {
            int x = Math.Min(startPoint.X, e.X);
            int y = Math.Min(startPoint.Y, e.Y);
            int w = Math.Abs(e.X - startPoint.X);
            int h = Math.Abs(e.Y - startPoint.Y);
            selection = new Rectangle(x, y, w, h);
            this.Invalidate();
        }
    }

    private void OnMouseUp(object sender, MouseEventArgs e)
    {
        if (e.Button == MouseButtons.Left && isSelecting)
        {
            isSelecting = false;
            if (selection.Width > 5 && selection.Height > 5)
            {
                Rectangle screenRect = new Rectangle(
                    this.Location.X + selection.X,
                    this.Location.Y + selection.Y,
                    selection.Width,
                    selection.Height);
                this.Close();
                parent.ProcessSnip(screenRect);
            }
            else
            {
                this.Close();
            }
        }
    }

    private void OnKeyDown(object sender, KeyEventArgs e)
    {
        if (e.KeyCode == Keys.Escape)
        {
            this.Close();
        }
    }

    private void OnPaint(object sender, PaintEventArgs e)
    {
        if (screenCapture != null)
        {
            e.Graphics.DrawImage(screenCapture, 0, 0);
        }

        using (SolidBrush dimBrush = new SolidBrush(Color.FromArgb(120, 0, 0, 0)))
        using (Region dimRegion = new Region(new Rectangle(0, 0, this.Width, this.Height)))
        {
            if (selection.Width > 0 && selection.Height > 0)
            {
                dimRegion.Exclude(selection);
            }
            e.Graphics.FillRegion(dimBrush, dimRegion);
        }

        if (selection.Width > 0 && selection.Height > 0)
        {
            using (Pen borderPen = new Pen(Color.Red, 2))
            {
                e.Graphics.DrawRectangle(borderPen, selection);
            }

            string sizeText = selection.Width + " x " + selection.Height;
            using (Font font = new Font("Segoe UI", 10, FontStyle.Bold))
            using (SolidBrush bgBrush = new SolidBrush(Color.FromArgb(200, 0, 0, 0)))
            using (SolidBrush textBrush = new SolidBrush(Color.White))
            {
                SizeF textSize = e.Graphics.MeasureString(sizeText, font);
                float textX = selection.X + (selection.Width - textSize.Width) / 2;
                float textY = selection.Y > 25 ? selection.Y - textSize.Height - 5 : selection.Bottom + 5;

                if (textY < 0) textY = selection.Bottom + 5;
                if (textY + textSize.Height > this.Height) textY = selection.Y + 5;

                e.Graphics.FillRectangle(bgBrush, textX - 3, textY - 2, textSize.Width + 6, textSize.Height + 4);
                e.Graphics.DrawString(sizeText, font, textBrush, textX, textY);
            }
        }

        using (Font helpFont = new Font("Segoe UI", 12, FontStyle.Bold))
        using (SolidBrush helpBg = new SolidBrush(Color.FromArgb(180, 0, 0, 0)))
        using (SolidBrush helpText = new SolidBrush(Color.White))
        {
            string help = "Drag to select area | ESC to cancel";
            SizeF helpSize = e.Graphics.MeasureString(help, helpFont);
            float hx = (this.Width - helpSize.Width) / 2;
            float hy = 20;
            e.Graphics.FillRectangle(helpBg, hx - 10, hy - 5, helpSize.Width + 20, helpSize.Height + 10);
            e.Graphics.DrawString(help, helpFont, helpText, hx, hy);
        }
    }

    protected override void OnFormClosing(FormClosingEventArgs e)
    {
        if (screenCapture != null)
        {
            screenCapture.Dispose();
            screenCapture = null;
        }
        base.OnFormClosing(e);
    }
}
