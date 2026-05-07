$ErrorActionPreference = 'Stop'
$target = 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\npm-global\node_modules\openclaw\dist\get-reply-Cld8oTG6.js'
$dts = 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\npm-global\node_modules\openclaw\dist\plugin-sdk\src\auto-reply\reply\prompt-prelude.d.ts'

if (-not (Test-Path $target)) { throw "Missing target file: $target" }
if (-not (Test-Path $dts)) { throw "Missing d.ts file: $dts" }

$js = Get-Content $target -Raw
$js = [regex]::Replace($js, 'const REPLY_MEDIA_HINT = "[^"]*";', 'const REPLY_MEDIA_HINT = void 0;', 1)
Set-Content -Path $target -Value $js -NoNewline

$types = Get-Content $dts -Raw
$types = [regex]::Replace($types, 'export declare const REPLY_MEDIA_HINT = "[^"]*";', 'export declare const REPLY_MEDIA_HINT: undefined;', 1)
Set-Content -Path $dts -Value $types -NoNewline

Write-Host 'Patched OpenClaw media hint successfully.'
