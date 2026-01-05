@echo off
cd /d F:\tovplay\tovplay-frontend
set PATH=C:\Program Files\nodejs;%PATH%
echo Installing frontend dependencies...
call npm install --legacy-peer-deps 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo npm install failed, trying with --ignore-scripts
    call npm install --legacy-peer-deps --ignore-scripts 2>&1
    echo Installing dev dependencies separately...
    call npm install vite @vitejs/plugin-react esbuild tailwindcss autoprefixer postcss --save-dev --legacy-peer-deps --ignore-scripts 2>&1
)
echo Done.
dir node_modules\vite /b 2>&1
