using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;
using System.Text;

class Launcher
{
    [DllImport("user32.dll")] static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] static extern bool EnumWindows(EnumWindowsProc p, IntPtr l);
    [DllImport("user32.dll", CharSet = CharSet.Auto)] static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
    [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("kernel32.dll")] static extern uint GetCurrentThreadId();
    [DllImport("user32.dll")] static extern bool BringWindowToTop(IntPtr hWnd);
    [DllImport("user32.dll")] static extern bool SetActiveWindow(IntPtr hWnd);

    delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    const byte VK_NUMPAD0 = 0x60;
    const byte VK_NUMPAD1 = 0x61;
    const byte VK_NUMPAD2 = 0x62;
    const byte VK_NUMPAD3 = 0x63;
    const byte VK_NUMPAD4 = 0x64;
    const byte VK_NUMPAD5 = 0x65;
    const byte VK_NUMPAD6 = 0x66;
    const byte VK_NUMPAD7 = 0x67;
    const byte VK_NUMPAD8 = 0x68;
    const byte VK_CONTROL = 0x11;
    const byte VK_NUMLOCK = 0x90;
    const uint KEYUP      = 0x0002;
    const int  SW_MINIMIZE = 6;
    const int  SW_RESTORE  = 9;

    static IntPtr FindWindow(string mustContain1, string mustContain2)
    {
        IntPtr found = IntPtr.Zero;
        EnumWindows((h, l) => {
            var sb = new StringBuilder(256);
            GetWindowText(h, sb, 256);
            string t = sb.ToString();
            if (t.Contains(mustContain1) && t.Contains(mustContain2) && IsWindowVisible(h))
            { found = h; return false; }
            return true;
        }, IntPtr.Zero);
        return found;
    }

    static IntPtr FindWindowExact(string exact)
    {
        IntPtr found = IntPtr.Zero;
        EnumWindows((h, l) => {
            var sb = new StringBuilder(256);
            GetWindowText(h, sb, 256);
            if (sb.ToString() == exact && IsWindowVisible(h))
            { found = h; return false; }
            return true;
        }, IntPtr.Zero);
        return found;
    }

    // Force focus using AttachThreadInput — bypasses Windows foreground lock
    static void ForceFocus(IntPtr hwnd)
    {
        uint myTid    = GetCurrentThreadId();
        uint pid;
        uint targetTid = GetWindowThreadProcessId(hwnd, out pid);

        AttachThreadInput(myTid, targetTid, true);
        ShowWindow(hwnd, SW_RESTORE);
        BringWindowToTop(hwnd);
        SetForegroundWindow(hwnd);
        SetActiveWindow(hwnd);
        AttachThreadInput(myTid, targetTid, false);

        Thread.Sleep(120);
    }

    static void Tap(byte vk)
    {
        keybd_event(vk, 0, 0, UIntPtr.Zero);
        Thread.Sleep(50);
        keybd_event(vk, 0, KEYUP, UIntPtr.Zero);
        Thread.Sleep(200);
    }

    static void CtrlTap(IntPtr hwnd, byte vk)
    {
        ForceFocus(hwnd);
        keybd_event(VK_CONTROL, 0, 0, UIntPtr.Zero);
        Thread.Sleep(40);
        keybd_event(vk, 0, 0, UIntPtr.Zero);
        Thread.Sleep(50);
        keybd_event(vk, 0, KEYUP, UIntPtr.Zero);
        Thread.Sleep(40);
        keybd_event(VK_CONTROL, 0, KEYUP, UIntPtr.Zero);
        Thread.Sleep(200);
    }

    static void Main()
    {
        string trainerPath = @"E:\games\The Witcher 3- Wild Hunt\Witcher3_FLiNG_Trainer_v4.04.exe";
        string gamePath    = @"E:\games\The Witcher 3- Wild Hunt\bin\x64\witcher3.exe";

        // Kill leftovers
        foreach (var n in new[] { "Witcher3_FLiNG_Trainer_v4.04", "witcher3" })
            foreach (var p in Process.GetProcessesByName(n))
                try { p.Kill(); p.WaitForExit(2000); } catch { }
        Thread.Sleep(1000);

        // Launch trainer
        var tp = new Process();
        tp.StartInfo.FileName = trainerPath;
        tp.StartInfo.WorkingDirectory = System.IO.Path.GetDirectoryName(trainerPath);
        tp.Start();

        IntPtr trainerHwnd = IntPtr.Zero;
        for (int i = 0; i < 30; i++)
        {
            Thread.Sleep(500);
            trainerHwnd = FindWindow("Witcher 3", "Trainer");
            if (trainerHwnd != IntPtr.Zero) break;
        }
        if (trainerHwnd == IntPtr.Zero) { Console.WriteLine("Trainer not found!"); return; }

        // Launch game
        var gp = new Process();
        gp.StartInfo.FileName = gamePath;
        gp.StartInfo.WorkingDirectory = System.IO.Path.GetDirectoryName(gamePath);
        gp.Start();

        Console.WriteLine("Waiting for game window...");
        IntPtr gameHwnd = IntPtr.Zero;
        for (int i = 0; i < 120; i++)
        {
            Thread.Sleep(1000);
            gameHwnd = FindWindowExact("The Witcher 3");
            if (gameHwnd != IntPtr.Zero) break;
        }
        if (gameHwnd == IntPtr.Zero) { Console.WriteLine("Game window not found!"); return; }

        // Wait for trainer to hook the game process
        Console.WriteLine("Game up. Waiting 15s for trainer hook...");
        Thread.Sleep(15000);

        // Minimize game so it can't steal focus
        ShowWindow(gameHwnd, SW_MINIMIZE);
        Thread.Sleep(1000);

        // Ensure NumLock ON
        if (!Control.IsKeyLocked(Keys.NumLock))
        {
            keybd_event(VK_NUMLOCK, 0, 0, UIntPtr.Zero);
            Thread.Sleep(50);
            keybd_event(VK_NUMLOCK, 0, KEYUP, UIntPtr.Zero);
            Thread.Sleep(100);
        }

        Console.WriteLine("Activating all mods...");

        // Fire every mod — AttachThreadInput forces real focus each time
        ForceFocus(trainerHwnd); Tap(VK_NUMPAD1); // Infinite Health
        ForceFocus(trainerHwnd); Tap(VK_NUMPAD2); // Infinite Stamina
        ForceFocus(trainerHwnd); Tap(VK_NUMPAD3); // Infinite Adrenaline
        ForceFocus(trainerHwnd); Tap(VK_NUMPAD4); // Zero Toxicity
        ForceFocus(trainerHwnd); Tap(VK_NUMPAD5); // Infinite Oxygen
        ForceFocus(trainerHwnd); Tap(VK_NUMPAD6); // Infinite Horse Stamina
        ForceFocus(trainerHwnd); Tap(VK_NUMPAD7); // Minimize Horse Fear Level
        ForceFocus(trainerHwnd); Tap(VK_NUMPAD8); // Drain Enemies Stamina
        ForceFocus(trainerHwnd); Tap(VK_NUMPAD0); // One Hit Kill
        CtrlTap(trainerHwnd, VK_NUMPAD5);          // Infinite Equipment Durability
        CtrlTap(trainerHwnd, VK_NUMPAD6);          // Zero Weight
        CtrlTap(trainerHwnd, VK_NUMPAD7);          // Infinite Potions & Bombs

        Console.WriteLine("All 12 mods ON. Restoring game...");
        Thread.Sleep(300);

        // Restore game
        ShowWindow(gameHwnd, SW_RESTORE);
        SetForegroundWindow(gameHwnd);

        Console.WriteLine("Done.");
        Thread.Sleep(1000);
    }
}
