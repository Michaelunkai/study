@echo off
REM Add Node.js to PATH globally for this session
set PATH=C:\Program Files\nodejs;%PATH%

REM Start Backend in new window
echo Starting Backend (Flask) in new window...
start "TovPlay Backend" powershell -NoExit -Command "cd F:\tovplay\tovplay-backend && . .\venv\Scripts\Activate.ps1 && echo Backend venv activated && python --version && flask run --host=0.0.0.0 --port=5001"

REM Wait 2 seconds before starting frontend
timeout /t 2 /nobreak

REM Start Frontend in new window
echo Starting Frontend (Vite) in new window...
start "TovPlay Frontend" powershell -NoExit -Command "set PATH=C:\Program Files\nodejs;!PATH! && cd F:\tovplay\tovplay-frontend && npm run dev"

echo.
echo Both servers started!
echo Backend:  http://localhost:5001
echo Frontend: http://localhost:3000
echo.
pause
