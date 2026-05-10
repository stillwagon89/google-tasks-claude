# ─────────────────────────────────────────────────────────────────────────────
# Google Tasks × Claude — one-command installer (Windows)
# https://github.com/stillwagon89/google-tasks-claude
# ─────────────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "Google Tasks x Claude Installer" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "──────────────────────────────────────"
Write-Host ""

# ── 1. Check for Node.js ──────────────────────────────────────────────────────
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "✖ Node.js is not installed." -ForegroundColor Red
    Write-Host ""
    Write-Host "Install it from: https://nodejs.org/en/download"
    Write-Host "Then re-run this script."
    exit 1
}

$nodeVersion = node --version
Write-Host "✔ Node.js found ($nodeVersion)" -ForegroundColor Green

# ── 2. Check for npm ──────────────────────────────────────────────────────────
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Host "✖ npm not found. Reinstall Node.js from https://nodejs.org" -ForegroundColor Red
    exit 1
}

$npmVersion = npm --version
Write-Host "✔ npm found ($npmVersion)" -ForegroundColor Green
Write-Host ""

# ── 3. Check Claude Desktop ───────────────────────────────────────────────────
$claudeConfig = "$env:APPDATA\Claude"
if (-not (Test-Path $claudeConfig)) {
    Write-Host "✖ Claude Desktop not found." -ForegroundColor Red
    Write-Host "Install it from https://claude.ai/download and sign in first."
    exit 1
}
Write-Host "✔ Claude Desktop found" -ForegroundColor Green
Write-Host ""

# ── 4. Log in to Smithery ─────────────────────────────────────────────────────
Write-Host "Step 1 of 2 — Log in to Smithery" -ForegroundColor Yellow
Write-Host "A browser window will open to create a free Smithery account (or sign in)."
Write-Host ""
npx -y smithery login

Write-Host ""
Write-Host "✔ Smithery login complete" -ForegroundColor Green
Write-Host ""

# ── 5. Add Google Tasks to Claude ─────────────────────────────────────────────
Write-Host "Step 2 of 2 — Connect Google Tasks to Claude" -ForegroundColor Yellow
Write-Host "A browser window will open to authorize your Google account."
Write-Host ""
npx -y smithery mcp add googletasks --client claude

Write-Host ""
Write-Host "✔ Google Tasks connected!" -ForegroundColor Green
Write-Host ""

# ── 6. Done ───────────────────────────────────────────────────────────────────
Write-Host "──────────────────────────────────────"
Write-Host "All done!" -ForegroundColor Green
Write-Host ""
Write-Host "  Next step: Quit and reopen Claude Desktop."
Write-Host ""
Write-Host "  Then try asking Claude:"
Write-Host "    • 'What tasks do I have due this week?'"
Write-Host "    • 'Add a task to call the bank tomorrow'"
Write-Host "    • 'Mark my grocery task as done'"
Write-Host ""
