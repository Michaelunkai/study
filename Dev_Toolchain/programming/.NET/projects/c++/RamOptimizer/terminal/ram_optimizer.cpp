#include <windows.h>
#include <psapi.h>
#include <stdio.h>

#pragma comment(lib, "psapi.lib")

static double usedMB() {
    MEMORYSTATUSEX ms;
    ms.dwLength = sizeof(ms);
    GlobalMemoryStatusEx(&ms);
    return (double)(ms.ullTotalPhys - ms.ullAvailPhys) / (1024.0 * 1024.0);
}

int main() {
    printf("=== RAM Optimizer ===\n\n");

    double before = usedMB();
    printf("RAM used before cleanup: %.0f MB\n", before);
    printf("Cleaning RAM...\n\n");

    /* 1. Empty working sets of all processes */
    DWORD pids[4096], needed;
    if (EnumProcesses(pids, sizeof(pids), &needed)) {
        DWORD count = needed / sizeof(DWORD);
        int cleaned = 0;
        for (DWORD i = 0; i < count; i++) {
            if (pids[i] == 0) continue;
            HANDLE h = OpenProcess(PROCESS_SET_QUOTA | PROCESS_QUERY_INFORMATION, FALSE, pids[i]);
            if (h) {
                if (EmptyWorkingSet(h)) cleaned++;
                CloseHandle(h);
            }
        }
        printf("[1/4] Emptied working sets: %d processes\n", cleaned);
    }

    /* 2. Empty system file cache via NtSetSystemInformation */
    typedef LONG (WINAPI *pNtSSI)(INT, PVOID, ULONG);
    HMODULE ntdll = GetModuleHandleA("ntdll.dll");
    if (ntdll) {
        pNtSSI NtSetSystemInformation = (pNtSSI)GetProcAddress(ntdll, "NtSetSystemInformation");
        if (NtSetSystemInformation) {
            /* SystemFileCacheInformation = 0x15 */
            typedef struct {
                SIZE_T CurrentSize;
                SIZE_T PeakSize;
                ULONG PageFaultCount;
                SIZE_T MinimumWorkingSet;
                SIZE_T MaximumWorkingSet;
                SIZE_T CurrentSizeIncludingTransitionInPages;
                SIZE_T PeakSizeIncludingTransitionInPages;
                ULONG TransitionRePurposeCount;
                ULONG Flags;
            } SYSTEM_FILECACHE_INFORMATION;
            SYSTEM_FILECACHE_INFORMATION sfc;
            memset(&sfc, 0, sizeof(sfc));
            sfc.MinimumWorkingSet = (SIZE_T)-1;
            sfc.MaximumWorkingSet = (SIZE_T)-1;
            LONG st = NtSetSystemInformation(0x15, &sfc, sizeof(sfc));
            printf("[2/4] System file cache flush: %s\n", st == 0 ? "OK" : "needs admin");

            /* SystemMemoryListInformation = 80, MemoryPurgeStandbyList = 4 */
            int cmd = 4;
            st = NtSetSystemInformation(80, &cmd, sizeof(cmd));
            printf("[3/4] Standby list purge: %s\n", st == 0 ? "OK" : "needs admin");

            /* MemoryPurgeLowPriorityStandbyList = 5 */
            cmd = 5;
            st = NtSetSystemInformation(80, &cmd, sizeof(cmd));
            printf("[4/4] Low-priority standby purge: %s\n", st == 0 ? "OK" : "needs admin");
        }
    }

    Sleep(500);
    double after = usedMB();
    double freed = before - after;
    if (freed < 0) freed = 0;

    printf("\n--- Results ---\n");
    printf("RAM used before: %.0f MB\n", before);
    printf("RAM used after:  %.0f MB\n", after);
    printf("RAM freed:       %.0f MB (%.1f GB)\n", freed, freed / 1024.0);
    printf("===============\n");

    return 0;
}
