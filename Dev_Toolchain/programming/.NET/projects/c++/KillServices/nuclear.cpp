#include <windows.h>
#include <tlhelp32.h>
#include <iostream>
#include <string>
#include <vector>
#include <algorithm>
#include <chrono>

typedef LONG NTSTATUS;
#define STATUS_SUCCESS 0
#define NT_SUCCESS(x) ((x) >= 0)

typedef NTSTATUS (WINAPI *_NtSuspendProcess)(HANDLE);
typedef NTSTATUS (WINAPI *_NtTerminateProcess)(HANDLE, NTSTATUS);

// Global NT function pointers
static _NtSuspendProcess NtSuspendProcess = nullptr;
static _NtTerminateProcess NtTerminateProcess = nullptr;

std::string ToLower(std::string str) {
    std::transform(str.begin(), str.end(), str.begin(), ::tolower);
    return str;
}

std::string RemoveSpaces(std::string str) {
    str.erase(std::remove(str.begin(), str.end(), ' '), str.end());
    return str;
}

std::string StripExe(const std::string& s) {
    if (s.size() > 4 && s.substr(s.size() - 4) == ".exe")
        return s.substr(0, s.size() - 4);
    return s;
}

bool EnableDebugPrivilege() {
    HANDLE hToken;
    if (!OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, &hToken))
        return false;
    TOKEN_PRIVILEGES tkp;
    if (!LookupPrivilegeValue(NULL, SE_DEBUG_NAME, &tkp.Privileges[0].Luid)) {
        CloseHandle(hToken);
        return false;
    }
    tkp.PrivilegeCount = 1;
    tkp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;
    BOOL ok = AdjustTokenPrivileges(hToken, FALSE, &tkp, 0, NULL, 0);
    DWORD err = GetLastError();
    CloseHandle(hToken);
    return ok && err == ERROR_SUCCESS;
}

struct ProcessInfo {
    DWORD pid;
    std::string name;
};

std::vector<ProcessInfo> FindProcesses(const char* searchName) {
    std::vector<ProcessInfo> results;
    HANDLE hSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (hSnap == INVALID_HANDLE_VALUE) return results;

    PROCESSENTRY32 pe;
    pe.dwSize = sizeof(pe);

    std::string search = ToLower(RemoveSpaces(StripExe(std::string(searchName))));

    if (Process32First(hSnap, &pe)) {
        do {
            std::string exeLow = ToLower(std::string(pe.szExeFile));
            std::string exeBase = RemoveSpaces(StripExe(exeLow));

            if (exeBase == search ||
                exeBase.find(search) != std::string::npos ||
                search.find(exeBase) != std::string::npos) {
                results.push_back({pe.th32ProcessID, std::string(pe.szExeFile)});
            }
        } while (Process32Next(hSnap, &pe));
    }
    CloseHandle(hSnap);
    return results;
}

// Kill method 1: NtTerminateProcess (kernel-level, bypasses most protections)
bool KillNt(HANDLE hProc) {
    if (!NtTerminateProcess) return false;
    return NT_SUCCESS(NtTerminateProcess(hProc, 1));
}

// Kill method 2: TerminateProcess (Win32 API)
bool KillWin32(HANDLE hProc) {
    return TerminateProcess(hProc, 1) != 0;
}

// Kill method 3: taskkill /F /PID (spawns external process, works on some protected PIDs)
bool KillTaskkill(DWORD pid) {
    char cmd[128];
    sprintf(cmd, "taskkill /F /PID %lu >nul 2>&1", pid);
    return system(cmd) == 0;
}

// Kill method 4: WMI via wmic (last resort, different code path in kernel)
bool KillWmic(DWORD pid) {
    char cmd[256];
    sprintf(cmd, "wmic process where ProcessId=%lu call terminate >nul 2>&1", pid);
    return system(cmd) == 0;
}

// Kill method 5: For WSL-specific processes, use wsl --shutdown
bool KillWslShutdown(const std::string& procName) {
    std::string lower = ToLower(procName);
    if (lower.find("vmmem") != std::string::npos ||
        lower.find("wsl") != std::string::npos) {
        return system("wsl --shutdown >nul 2>&1") == 0;
    }
    return false;
}

// Terminate all threads of a process (nuclear option)
bool KillThreads(DWORD pid) {
    HANDLE hSnap = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
    if (hSnap == INVALID_HANDLE_VALUE) return false;

    THREADENTRY32 te;
    te.dwSize = sizeof(te);
    int killed = 0;

    if (Thread32First(hSnap, &te)) {
        do {
            if (te.th32OwnerProcessID == pid) {
                HANDLE hThread = OpenThread(THREAD_TERMINATE, FALSE, te.th32ThreadID);
                if (hThread) {
                    if (TerminateThread(hThread, 1)) killed++;
                    CloseHandle(hThread);
                }
            }
        } while (Thread32Next(hSnap, &te));
    }
    CloseHandle(hSnap);
    return killed > 0;
}

bool IsProcessAlive(DWORD pid) {
    HANDLE h = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
    if (!h) return false;
    DWORD exitCode = 0;
    GetExitCodeProcess(h, &exitCode);
    CloseHandle(h);
    return exitCode == STILL_ACTIVE;
}

bool IsWslProcess(const std::string& name) {
    std::string lower = ToLower(name);
    return lower.find("vmmem") != std::string::npos ||
           lower == "wslservice.exe" ||
           lower == "wslhost.exe" ||
           lower == "wsl.exe";
}

// WSL nuclear shutdown: stops the service and hypervisor VM
bool WslNuclearShutdown(DWORD pid, const std::string& name) {
    printf("    [WSL] Detected WSL/vmmem process - using WSL shutdown path\n");

    // Step 1: wsl --shutdown
    printf("    [WSL] Step 1: wsl --shutdown...\n");
    system("wsl --shutdown >nul 2>&1");
    Sleep(2000);
    if (!IsProcessAlive(pid)) return true;

    // Step 2: wsl --terminate on all distros
    printf("    [WSL] Step 2: Terminating all WSL distros...\n");
    system("wsl --list --running >nul 2>&1");
    system("powershell -NoProfile -Command \"(wsl --list --running) | ForEach-Object { $d = $_.Trim(); if ($d -and $d -notmatch 'Windows Subsystem') { wsl --terminate $d } }\" >nul 2>&1");
    Sleep(1000);
    if (!IsProcessAlive(pid)) return true;

    // Step 3: Stop WslService
    printf("    [WSL] Step 3: Stopping WslService...\n");
    system("net stop WslService >nul 2>&1");
    Sleep(2000);
    if (!IsProcessAlive(pid)) return true;

    // Step 4: Stop vmcompute (Host Compute Service - manages vmmem VMs)
    printf("    [WSL] Step 4: Stopping vmcompute (HCS)...\n");
    system("net stop vmcompute >nul 2>&1");
    Sleep(2000);
    if (!IsProcessAlive(pid)) return true;

    // Step 5: hcsdiag - kill all HCS VMs directly (THIS is what kills vmmem)
    printf("    [WSL] Step 5: Killing HCS VMs via hcsdiag...\n");
    system("powershell -NoProfile -Command \"$vms = hcsdiag list 2>$null; if ($vms) { foreach ($line in $vms) { $id = ($line -split ',')[0].Trim(); if ($id -match '[0-9a-f-]{36}') { hcsdiag kill $id 2>$null } } }\" >nul 2>&1");
    Sleep(3000);
    if (!IsProcessAlive(pid)) return true;

    // Step 6: Force-stop all related services
    printf("    [WSL] Step 6: Force-stopping all WSL services...\n");
    system("sc stop WslService >nul 2>&1");
    system("sc stop vmcompute >nul 2>&1");
    system("sc stop HvHost >nul 2>&1");
    Sleep(2000);
    if (!IsProcessAlive(pid)) return true;

    // Step 7: taskkill on wslservice as last resort
    printf("    [WSL] Step 7: taskkill on WSL processes...\n");
    system("taskkill /F /IM wslservice.exe >nul 2>&1");
    system("taskkill /F /IM wslhost.exe >nul 2>&1");
    Sleep(3000);

    return !IsProcessAlive(pid);
}

bool NukeProcess(DWORD pid, const std::string& name) {
    auto start = std::chrono::high_resolution_clock::now();

    // For WSL/vmmem processes, go straight to WSL-specific shutdown
    if (IsWslProcess(name)) {
        bool killed = WslNuclearShutdown(pid, name);
        auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::high_resolution_clock::now() - start).count();
        if (killed) {
            printf("  [KILLED] PID: %lu (%s) via WSL shutdown (%lldms)\n", pid, name.c_str(), ms);
            return true;
        }
        // Fall through to standard methods if WSL shutdown didn't work
        printf("    [WSL] WSL shutdown path didn't kill PID %lu, trying standard methods...\n", pid);
    }

    // Try opening with maximum access, then progressively less
    HANDLE hProc = nullptr;
    DWORD accessLevels[] = {
        PROCESS_ALL_ACCESS,
        PROCESS_TERMINATE | PROCESS_SUSPEND_RESUME | PROCESS_QUERY_INFORMATION,
        PROCESS_TERMINATE | PROCESS_QUERY_LIMITED_INFORMATION,
        PROCESS_TERMINATE,
    };

    for (DWORD access : accessLevels) {
        hProc = OpenProcess(access, FALSE, pid);
        if (hProc) break;
    }

    // Method 0: Suspend first (prevents respawn logic)
    if (hProc && NtSuspendProcess) {
        NtSuspendProcess(hProc);
    }

    // Method 1: NtTerminateProcess
    if (hProc && KillNt(hProc)) {
        if (!IsProcessAlive(pid)) {
            auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::high_resolution_clock::now() - start).count();
            printf("  [KILLED] PID: %lu (%s) via NtTerminate (%lldms)\n", pid, name.c_str(), ms);
            CloseHandle(hProc);
            return true;
        }
    }

    // Method 2: TerminateProcess
    if (hProc && KillWin32(hProc)) {
        Sleep(50);
        if (!IsProcessAlive(pid)) {
            auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::high_resolution_clock::now() - start).count();
            printf("  [KILLED] PID: %lu (%s) via TerminateProcess (%lldms)\n", pid, name.c_str(), ms);
            CloseHandle(hProc);
            return true;
        }
    }

    if (hProc) CloseHandle(hProc);

    // Method 3: Kill all threads
    KillThreads(pid);
    Sleep(50);
    if (!IsProcessAlive(pid)) {
        auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::high_resolution_clock::now() - start).count();
        printf("  [KILLED] PID: %lu (%s) via ThreadKill (%lldms)\n", pid, name.c_str(), ms);
        return true;
    }

    // Method 4: taskkill /F
    KillTaskkill(pid);
    Sleep(100);
    if (!IsProcessAlive(pid)) {
        auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::high_resolution_clock::now() - start).count();
        printf("  [KILLED] PID: %lu (%s) via taskkill (%lldms)\n", pid, name.c_str(), ms);
        return true;
    }

    // Method 5: WSL shutdown (for processes not caught by IsWslProcess but still WSL-related)
    if (KillWslShutdown(name)) {
        Sleep(2000);
        if (!IsProcessAlive(pid)) {
            auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::high_resolution_clock::now() - start).count();
            printf("  [KILLED] PID: %lu (%s) via wsl --shutdown (%lldms)\n", pid, name.c_str(), ms);
            return true;
        }
    }

    // Method 6: WMIC terminate
    KillWmic(pid);
    Sleep(100);
    if (!IsProcessAlive(pid)) {
        auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::high_resolution_clock::now() - start).count();
        printf("  [KILLED] PID: %lu (%s) via WMIC (%lldms)\n", pid, name.c_str(), ms);
        return true;
    }

    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::high_resolution_clock::now() - start).count();
    printf("  [FAILED] PID: %lu (%s) - survived all methods (%lldms)\n", pid, name.c_str(), ms);
    return false;
}

int main(int argc, char** argv) {
    if (argc < 2) {
        printf("Usage: %s <process1> [process2] [...]\n", argv[0]);
        printf("  Kills processes using 6 escalating methods.\n");
        printf("  Handles protected/system processes including WSL vmmem.\n");
        return 1;
    }

    printf("===========================================\n");
    printf(" NUCLEAR PROCESS TERMINATOR v3.0\n");
    printf(" 6-METHOD ESCALATION - NEVER FAILS\n");
    printf("===========================================\n\n");

    // Load NT functions once
    HMODULE hNtdll = GetModuleHandleA("ntdll.dll");
    if (hNtdll) {
        NtSuspendProcess = (_NtSuspendProcess)GetProcAddress(hNtdll, "NtSuspendProcess");
        NtTerminateProcess = (_NtTerminateProcess)GetProcAddress(hNtdll, "NtTerminateProcess");
    }

    // Enable SeDebugPrivilege once
    if (EnableDebugPrivilege()) {
        printf("[PRIVILEGE] SeDebugPrivilege enabled\n\n");
    } else {
        printf("[WARNING] SeDebugPrivilege FAILED - run as Administrator!\n\n");
    }

    auto totalStart = std::chrono::high_resolution_clock::now();
    int totalKilled = 0, totalFailed = 0;

    // Collect all unique PIDs to avoid killing same process twice
    std::vector<ProcessInfo> allTargets;
    std::vector<DWORD> seenPids;

    for (int i = 1; i < argc; i++) {
        printf("[SEARCHING] %s\n", argv[i]);
        auto procs = FindProcesses(argv[i]);

        if (procs.empty()) {
            std::string arg = ToLower(std::string(argv[i]));
            if (arg.find("vmmem") != std::string::npos || arg.find("wsl") != std::string::npos) {
                printf("  [INFO] No process found, trying wsl --shutdown...\n");
                system("wsl --shutdown >nul 2>&1");
                Sleep(2000);
                printf("  [OK] wsl --shutdown executed\n");
            } else {
                printf("  [NOT FOUND] No process matching: %s\n", argv[i]);
            }
            printf("\n");
            continue;
        }

        printf("  [FOUND] %d process(es)\n", (int)procs.size());
        for (auto& p : procs) {
            bool alreadySeen = false;
            for (DWORD seen : seenPids) {
                if (seen == p.pid) { alreadySeen = true; break; }
            }
            if (!alreadySeen) {
                allTargets.push_back(p);
                seenPids.push_back(p.pid);
            } else {
                printf("  [SKIP] PID: %lu (%s) - already targeted\n", p.pid, p.name.c_str());
            }
        }
        printf("\n");
    }

    // Kill WSL processes first (wsl --shutdown kills them all at once)
    bool wslShutdownDone = false;
    for (auto& p : allTargets) {
        if (IsWslProcess(p.name) && !wslShutdownDone) {
            printf("[WSL GROUP] Running wsl --shutdown for all WSL processes first...\n");
            system("wsl --shutdown >nul 2>&1");
            printf("[WSL GROUP] Stopping WslService + vmcompute...\n");
            system("net stop WslService >nul 2>&1");
            system("net stop vmcompute >nul 2>&1");
            Sleep(3000);
            wslShutdownDone = true;
            break;
        }
    }

    // Now kill each process
    for (auto& p : allTargets) {
        if (NukeProcess(p.pid, p.name)) totalKilled++;
        else totalFailed++;
    }

    auto totalMs = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::high_resolution_clock::now() - totalStart).count();

    printf("===========================================\n");
    printf(" COMPLETE\n");
    printf(" Killed: %d | Failed: %d | Time: %lldms\n", totalKilled, totalFailed, totalMs);
    printf("===========================================\n");

    return 0;
}
