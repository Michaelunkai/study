# AUTH_TOKEN Rotation Guide

## When to rotate
- After sharing the token with someone
- If you suspect the token was compromised
- Regular security maintenance (monthly recommended)

## How to rotate
1. Stop the server: kill node process on port 3099
2. Edit .env: change AUTH_TOKEN to new value
3. Restart server: `npm start` or `start-all.bat`
4. Update token in browser: open Netlify site, clear localStorage, re-enter new token
   - DevTools: `localStorage.clear()` then refresh

## Token format recommendations
- At least 20 characters
- Mix of letters, numbers, symbols
- Example generator: `[System.Web.Security.Membership]::GeneratePassword(24,4)`
