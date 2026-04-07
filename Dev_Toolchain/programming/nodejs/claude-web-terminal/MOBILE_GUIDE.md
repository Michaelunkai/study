# Mobile Access Guide for Claude Web Terminal

## Access from Phone

1. Start backend on your PC:
   - Run `start-all.bat` in F:\study\Dev_Toolchain\programming\nodejs\claude-web-terminal\
   - Or Task Scheduler auto-starts on logon

2. Get the tunnel URL:
   - cloudflared prints: `https://xxxx.trycloudflare.com`
   - Copy this URL

3. Open on phone:
   - Go to: https://claude-web-terminal.netlify.app
   - In Advanced settings, enter: `wss://xxxx.trycloudflare.com`
   - Enter token: (your AUTH_TOKEN from .env)
   - Tap Connect

4. Use the terminal:
   - Tap to focus keyboard
   - Type commands normally
   - Ctrl+C -> send interrupt
   - Font size: use A- / A+ buttons

## Tips
- Token is saved in localStorage after first login
- Connection shows elapsed time in topbar
- wsUrl is also saved - update when tunnel URL changes
- On mobile data, tunnel may have 100-200ms latency
