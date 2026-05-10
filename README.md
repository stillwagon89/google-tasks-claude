# Google Tasks × Claude

Connect your Google Tasks to Claude Desktop in under 2 minutes — no Google Cloud Console, no API keys, no config files.

---

## What this does

Adds 14 Google Tasks tools to Claude so you can manage your tasks through natural conversation:

- **"What's on my plate this week?"** — Claude reads all your task lists and summarizes
- **"Add a task to call HSBC tomorrow"** — creates the task in Google Tasks
- **"Mark my rent task as done"** — updates task status
- **"Move my Africa trip task to Two Weeks Out"** — reorganizes across lists
- **"Clear all completed tasks from my grocery list"** — bulk cleanup

---

## Requirements

- [Claude Desktop](https://claude.ai/download) (Mac or Windows), signed in
- [Node.js](https://nodejs.org/en/download) v18 or later

---

## Install

### Mac / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/stillwagon89/google-tasks-claude/main/install.sh | bash
```

Or clone and run locally:

```bash
git clone https://github.com/stillwagon89/google-tasks-claude.git
cd google-tasks-claude
chmod +x install.sh
./install.sh
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/stillwagon89/google-tasks-claude/main/install.ps1 | iex
```

Or clone and run locally:

```powershell
git clone https://github.com/stillwagon89/google-tasks-claude.git
cd google-tasks-claude
.\install.ps1
```

---

## What happens during install

The script runs two commands:

1. **`npx smithery login`** — opens a browser to create/sign into a free [Smithery](https://smithery.ai) account. Smithery hosts the Google Tasks server so you don't need to set up anything in Google Cloud.

2. **`npx smithery mcp add googletasks --client claude`** — opens a browser to authorize Google Tasks access, then writes the server config to your Claude Desktop settings.

After that, quit and reopen Claude Desktop. Done.

---

## How it works

This installer connects Claude to the [verified Google Tasks MCP server](https://smithery.ai/servers/googletasks) hosted by Smithery. The server runs in Smithery's cloud infrastructure and connects to your Google account via OAuth — your credentials never touch this project.

Under the hood it uses Anthropic's [Model Context Protocol (MCP)](https://modelcontextprotocol.io), an open standard for giving AI assistants access to external tools and data.

---

## Uninstall

To remove Google Tasks from Claude:

```bash
npx smithery mcp remove googletasks --client claude
```

---

## Troubleshooting

**"Node.js is not installed"**
Install from [nodejs.org](https://nodejs.org/en/download) or via Homebrew: `brew install node`

**"Claude Desktop config directory not found"**
Install Claude Desktop from [claude.ai/download](https://claude.ai/download) and sign in before running this script.

**"No API key found. Run 'smithery login' to authenticate."**
Run `npx smithery login` first, then re-run the installer.

**Claude doesn't respond to task questions after install**
Make sure you fully quit and reopen Claude Desktop (Cmd+Q on Mac, not just close the window).

---

## Related

- [GitHub — google-tasks-claude](https://github.com/stillwagon89/google-tasks-claude)
- [Smithery — Google Tasks server](https://smithery.ai/servers/googletasks)
- [Model Context Protocol](https://modelcontextprotocol.io)
- [Claude Desktop](https://claude.ai/download)

---

## License

MIT
