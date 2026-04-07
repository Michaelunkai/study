# Claude Web Terminal

A browser-based terminal using xterm.js + WebSocket + Node.js PTY. Access your Windows terminal from anywhere.

## Setup

1. Install dependencies: `npm install`
2. Copy `.env.example` to `.env` and set your `AUTH_TOKEN`
3. Start server: `npm start`
4. Start cloudflare tunnel: `cloudflared tunnel --url http://localhost:3099`
5. Open Netlify frontend, enter tunnel URL + token

## Features
- xterm.js with GitHub Dark theme
- WebSocket PTY (node-pty with child_process fallback)
- Token authentication with rate limiting
- Font size controls (Ctrl+= / Ctrl+-)
- Search (Ctrl+F)
- Connection elapsed timer
- Cloudflare tunnel for remote access
- Auto-start via Task Scheduler

## Security
- Set a strong `AUTH_TOKEN` in .env
- Never commit .env to git
- Max 3 failed auth attempts per IP

## Quick Start
Run `start-all.bat` to launch server and tunnel.
