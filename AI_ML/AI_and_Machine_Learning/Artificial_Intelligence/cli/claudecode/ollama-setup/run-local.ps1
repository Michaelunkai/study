# run-local.ps1 - Launch Claude Code with LOCAL Ollama
# Cleans up env vars on exit so normal 'claude' is never broken.

param(
    [string]$Model = "qwen3-coder"
)

# --- Performance env vars (session only) ---
$env:OLLAMA_FLASH_ATTENTION   = "1"
$env:OLLAMA_KV_CACHE_TYPE     = "q8_0"
$env:OLLAMA_NUM_PARALLEL      = "1"
$env:OLLAMA_MAX_LOADED_MODELS = "1"
$env:OLLAMA_KEEP_ALIVE        = "60m"
$env:OLLAMA_GPU_OVERHEAD      = "268435456"
$env:CUDA_VISIBLE_DEVICES     = "0"
$env:OLLAMA_NUM_GPU           = "999"
$env:OLLAMA_MODELS            = "F:\backup\LocalAI\ollama\models"
$env:OLLAMA_HOME              = "F:\backup\LocalAI\ollama"

# --- Check Ollama is alive, start if needed ---
$ollamaUp = $false
try {
    Invoke-WebRequest -Uri "http://localhost:11434" -Method Head -TimeoutSec 3 -UseBasicParsing | Out-Null
    $ollamaUp = $true
} catch {}

if (-not $ollamaUp) {
    Write-Host "Ollama not running. Starting it..." -ForegroundColor Yellow
    $ollamaExe = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
    if (-not (Test-Path $ollamaExe)) {
        $ollamaExe = "$env:ProgramFiles\Ollama\ollama.exe"
    }
    if (Test-Path $ollamaExe) {
        $p = Start-Process -FilePath $ollamaExe -ArgumentList "serve" -WindowStyle Hidden -PassThru
        try { $p.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High } catch {}
        Start-Sleep -Seconds 5
    } else {
        Write-Error "Cannot find ollama.exe. Run a.ps1 first."
        exit 1
    }
}

# --- Set Ollama process to High priority ---
$ollamaProc = Get-Process -Name "ollama" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($ollamaProc) {
    try { $ollamaProc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High } catch {}
}

$thisScript = $MyInvocation.MyCommand.Definition
Write-Host "" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Claude Code - LOCAL MODEL" -ForegroundColor Cyan
Write-Host "  Model: $Model" -ForegroundColor Green
Write-Host "  Script: $thisScript" -ForegroundColor DarkGray
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# --- Set ANTHROPIC env vars (the original working method) ---
$env:ANTHROPIC_AUTH_TOKEN = "ollama"
$env:ANTHROPIC_API_KEY = ""
$env:ANTHROPIC_BASE_URL = "http://localhost:11434"

# --- Launch claude ---
claude --model $Model @args

# --- CLEANUP: remove ANTHROPIC vars so normal 'claude' works after ---
Remove-Item Env:\ANTHROPIC_AUTH_TOKEN -ErrorAction SilentlyContinue
Remove-Item Env:\ANTHROPIC_API_KEY -ErrorAction SilentlyContinue
Remove-Item Env:\ANTHROPIC_BASE_URL -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Local session ended. ANTHROPIC vars cleaned up." -ForegroundColor Green
Write-Host "Normal 'claude' command will work normally now." -ForegroundColor Green
