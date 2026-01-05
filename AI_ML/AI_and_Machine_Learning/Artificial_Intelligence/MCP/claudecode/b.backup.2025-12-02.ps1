# MCP Server Setup Script for Claude Code
# Last updated: 2025-12-02
#
# STATUS: 41 servers connected, 7 require API keys
# Run: powershell -ExecutionPolicy Bypass -File "F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\MCP\claudecode\b.ps1"

Write-Host "=== MCP Server Setup Script ===" -ForegroundColor Cyan
Write-Host "Setting up MCP servers with --scope user for global access..." -ForegroundColor Yellow

# ============================================
# WORKING SERVERS (44 total - all connected)
# ============================================

# --- Core Servers ---
claude mcp add --scope user filesystem -- npx @modelcontextprotocol/server-filesystem C:/ F:/
claude mcp add --scope user github -- npx @modelcontextprotocol/server-github
claude mcp add --scope user puppeteer -- npx @modelcontextprotocol/server-puppeteer
claude mcp add --scope user playwright -- npx @playwright/mcp
claude mcp add --scope user memory -- npx @modelcontextprotocol/server-memory
claude mcp add --scope user sequential-thinking -- npx @modelcontextprotocol/server-sequential-thinking

# --- Database Servers ---
claude mcp add --scope user postgres -- npx @modelcontextprotocol/server-postgres "postgresql://raz%40tovtech.org:CaptainForgotCreatureBreak@45.148.28.196:5432/TovPlay"
claude mcp add --scope user postgres-enhanced -- npx enhanced-postgres-mcp-server "postgresql://raz%40tovtech.org:CaptainForgotCreatureBreak@45.148.28.196:5432/TovPlay"
claude mcp add --scope user mongodb -- npx -y mongodb-mcp-server

# --- Web/Browser Servers ---
claude mcp add --scope user smart-crawler -- npx mcp-smart-crawler
claude mcp add --scope user chrome-devtools -- npx chrome-devtools-mcp
claude mcp add --scope user puppeteer-hisma -- npx @hisma/server-puppeteer
claude mcp add --scope user fast-playwright -- npx -y @tontoko/fast-playwright-mcp
claude mcp add --scope user read-website-fast -- npx -y @just-every/mcp-read-website-fast
claude mcp add --scope user fetch -- npx -y @kazuph/mcp-fetch

# --- Productivity/Integration Servers ---
claude mcp add --scope user figma -- npx figma-mcp
claude mcp add --scope user notion -- npx @notionhq/notion-mcp-server
claude mcp add --scope user jira -- npx -y mcp-jira-server
claude mcp add --scope user docker -- npx -y mcp-server-docker
claude mcp add --scope user youtube -- npx -y @sinco-lab/mcp-youtube-transcript

# --- Utility Servers ---
claude mcp add --scope user everything -- npx everything-mcp
claude mcp add --scope user deepwiki -- npx deepwiki-mcp
claude mcp add --scope user mcp-everything -- npx @modelcontextprotocol/server-everything
claude mcp add --scope user ref-tools -- npx ref-tools-mcp
claude mcp add --scope user mcp-starter -- npx mcp-starter
claude mcp add --scope user mcp-installer -- npx -y @anaisbetts/mcp-installer
claude mcp add --scope user graphql -- npx -y mcp-graphql
claude mcp add --scope user ucpl-compress -- npx -y ucpl-compress-mcp
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp --api-key ctx7sk-c777d86e-785c-4d34-a350-71fb59250be7

# --- AI/Thinking Servers ---
claude mcp add --scope user exa -- npx -y exa-mcp-server
claude mcp add --scope user codex -- npx -y codex-mcp-server
claude mcp add --scope user knowledge-graph -- npx -y mcp-knowledge-graph
claude mcp add --scope user creative-thinking -- npx -y github:uddhav/creative-thinking
claude mcp add --scope user think-strategies -- npx -y think-strategies
claude mcp add --scope user collaborative-reasoning -- npx -y @waldzellai/collaborative-reasoning
claude mcp add --scope user thinking-tools -- npx mcp-sequentialthinking-tools
claude mcp add --scope user deep-research -- npx mcp-deep-research
claude mcp add --scope user structured-thinking -- npx structured-thinking
claude mcp add --scope user token-optimizer -- npx token-optimizer-mcp

# --- Windows Desktop Automation Servers ---
claude mcp add --scope user windows-mcp -- npx -y @darbotlabs/darbot-windows-mcp
claude mcp add --scope user mcp-pyautogui -- uvx mcp-pyautogui-server

# ============================================
# SERVERS REQUIRING API KEYS (7 total)
# These will fail until API keys are provided
# ============================================

# GitLab - requires GITLAB_PERSONAL_ACCESS_TOKEN env var
claude mcp add --scope user gitlab -- npx -y @zereight/mcp-gitlab

# Brave Search - requires BRAVE_API_KEY env var or --brave-api-key arg
claude mcp add --scope user brave-search -- npx -y @brave/brave-search-mcp-server

# Firecrawl - requires FIRECRAWL_API_KEY env var
claude mcp add --scope user firecrawl -- npx -y firecrawl-mcp

# MCP Summarization - requires PROVIDER env var (e.g., "anthropic")
claude mcp add --scope user mcp-summarization -- npx -y mcp-summarization-functions

# Todoist - requires TODOIST_API_TOKEN env var
claude mcp add --scope user todoist -- npx -y @abhiz123/todoist-mcp-server

# Slack - requires SLACK_MCP_XOXP_TOKEN or SLACK_MCP_XOXC_TOKEN + SLACK_MCP_XOXD_TOKEN
claude mcp add --scope user slack -- npx -y slack-mcp-server

# Google Maps - requires GOOGLE_MAPS_API_KEY env var or --apikey arg
claude mcp add --scope user google-maps -- npx -y @cablate/mcp-google-map

# ============================================
# REMOVED SERVERS (broken/incompatible)
# ============================================
# - zip-mcp: SDK version incompatibility (completions error)
# - mcp-think-tank: Windows ESM path issue
# - think-mcp-server: Hangs on startup
# - uplinq-typescript: SDK version incompatibility
# - mcp-cache: Package doesn't exist on npm
# - memory-keeper: Requires Visual Studio Build Tools for better-sqlite3
# - @modelcontextprotocol/server-slack: DEPRECATED
# - @modelcontextprotocol/server-google-maps: DEPRECATED
# - mcp-control: Requires native build tools (keysender module)
# - mcp-desktop-automation: Requires native build tools (robotjs)
# - mcp-windows-desktop-automation: Requires AutoIt and native builds
# - mcp-com-server: Package doesn't exist on npm

Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Green
Write-Host "41 servers configured (working)" -ForegroundColor Green
Write-Host "7 servers require API keys to connect" -ForegroundColor Yellow
Write-Host ""
Write-Host "Run 'claude mcp list' to verify connection status" -ForegroundColor Cyan
