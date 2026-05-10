#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Google Tasks × Claude — one-command installer
# https://github.com/stillwagon89/google-tasks-claude
# ─────────────────────────────────────────────────────────────────────────────

set -e

BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

echo ""
echo -e "${BOLD}Google Tasks × Claude Installer${RESET}"
echo "──────────────────────────────────────"
echo ""

# ── 1. Check for Node.js ──────────────────────────────────────────────────────
if ! command -v node &>/dev/null; then
  echo -e "${RED}✖ Node.js is not installed.${RESET}"
  echo ""
  echo "Install it in one of these ways:"
  echo ""
  echo "  Option A (recommended) — Homebrew:"
  echo "    brew install node"
  echo ""
  echo "  Option B — Official installer:"
  echo "    https://nodejs.org/en/download"
  echo ""
  echo "Then re-run this script."
  exit 1
fi

NODE_VERSION=$(node --version)
echo -e "${GREEN}✔ Node.js found${RESET} ($NODE_VERSION)"

# ── 2. Check for npm ──────────────────────────────────────────────────────────
if ! command -v npm &>/dev/null; then
  echo -e "${RED}✖ npm is not installed. It usually comes with Node.js.${RESET}"
  echo "Try reinstalling Node.js from https://nodejs.org"
  exit 1
fi

NPM_VERSION=$(npm --version)
echo -e "${GREEN}✔ npm found${RESET} ($NPM_VERSION)"
echo ""

# ── 3. Check Claude Desktop is installed ─────────────────────────────────────
CLAUDE_CONFIG_DIR="$HOME/Library/Application Support/Claude"
if [ ! -d "$CLAUDE_CONFIG_DIR" ]; then
  echo -e "${RED}✖ Claude Desktop config directory not found.${RESET}"
  echo "Please install Claude Desktop from https://claude.ai/download and sign in first."
  exit 1
fi
echo -e "${GREEN}✔ Claude Desktop found${RESET}"
echo ""

# ── 4. Log in to Smithery ─────────────────────────────────────────────────────
echo -e "${BOLD}Step 1 of 2 — Log in to Smithery${RESET}"
echo "This opens a browser window to create a free Smithery account (or sign in)."
echo "Smithery hosts the Google Tasks server — no Google Cloud Console required."
echo ""
npx -y smithery login

echo ""
echo -e "${GREEN}✔ Smithery login complete${RESET}"
echo ""

# ── 5. Add Google Tasks to Claude ─────────────────────────────────────────────
echo -e "${BOLD}Step 2 of 2 — Connect Google Tasks to Claude${RESET}"
echo "This opens a browser window to authorize access to your Google Tasks."
echo ""
npx -y smithery mcp add googletasks --client claude

echo ""
echo -e "${GREEN}✔ Google Tasks connected!${RESET}"
echo ""

# ── 6. Done ───────────────────────────────────────────────────────────────────
echo "──────────────────────────────────────"
echo -e "${BOLD}${GREEN}All done!${RESET}"
echo ""
echo "  Next step: ${BOLD}Quit and reopen Claude Desktop.${RESET}"
echo ""
echo "  Then try asking Claude:"
echo "    • \"What tasks do I have due this week?\""
echo "    • \"Add a task to call the bank tomorrow\""
echo "    • \"Mark my grocery task as done\""
echo ""
