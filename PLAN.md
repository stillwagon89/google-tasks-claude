# Architecture plan — Google Tasks ↔ Claude, on every surface

## Diagnosis

The current installer (`install.sh` / `install.ps1`) runs
`smithery mcp add googletasks --client claude`, which writes a server entry
into **Claude Desktop's local config file**. That file only exists on the
one machine it's written to — Claude on the web, the iOS/Android apps, and
Cowork sessions never read it, because they don't run on that machine and
have no way to see it. That's the whole gap: not a bug to patch, but a
layer mismatch. On top of that, Smithery sits as a third-party broker
between the user and Google — task data and the OAuth grant depend on
Smithery's hosted server and uptime, not something we control.

## The fix

Claude supports **custom connectors over remote MCP**: a server we host,
registered once in the Claude account (claude.ai → Settings → Connectors →
Add custom connector). Anthropic's cloud reaches that server directly, so
every surface that authenticates as the user gets it automatically —
Claude web, Claude Desktop, the Claude mobile apps (added via web, syncs
automatically), and Cowork. One registration, one OAuth grant, every
surface.

For the phone's native **Google Tasks app**, nothing needs to be built —
it already reads and writes the same account data as the Tasks API. The
moment the connector creates or completes a task through the real API,
it's on the phone, in the Gmail sidebar, and on Calendar. Same mechanism
that syncs Apple Notes to Reminders on iOS, one layer down: the account's
own data store, not a bespoke bridge between two apps.

## Options weighed

| Option | Verdict |
|---|---|
| Smithery-hosted MCP (current) | Reject — Desktop-only by construction, third-party OAuth broker |
| Zapier / IFTTT bridge | Reject — automations, not conversational read/write |
| Google Apps Script Web App | Fallback — avoids external hosting, but request limits & cold starts make it secondary |
| Self-hosted remote MCP connector | **Recommended** — direct to Google Tasks API, one account-level registration covers every Claude surface |

## The build

Don't write a Tasks↔MCP bridge from scratch — fork one built for this
deployment shape:

- **ebmurha/google-tasks-mcp** (primary pick) — built specifically for
  self-host: your own Google Cloud OAuth client, streamable HTTP mode,
  bearer-token or OAuth-gateway auth, a token store you control.
- **taylorwilsdon/google_workspace_mcp** — broader Workspace coverage
  (Tasks plus Gmail/Calendar/Drive), OAuth 2.1 multi-user, stateless
  container deploy. Worth switching to if scope grows beyond Tasks.
- **zcaceres/gtasks-mcp** — clean full-CRUD tool set, but built for local
  stdio; would need its transport swapped to streamable HTTP first.

**Hosting:** Cloudflare Workers — free tier easily covers single-user
traffic, no server to patch, and Cloudflare documents this exact pattern
(remote MCP server behind an OAuth provider). Fly.io/Render as fallback if
the forked project needs a real filesystem for its token store.

**Auth:** a Google Cloud project the user creates and owns. Enable the
Tasks API, create a web-application OAuth client, point its redirect URI
at the deployed server. Left in *Testing* mode with the owner as the only
test user, it never needs Google's verification review — and unlike the
Smithery route, credentials are owned end to end.

**Tool surface** (12 tools): `list_task_lists`, `create_task_list`,
`delete_task_list`, `list_tasks`, `get_task`, `create_task`,
`update_task`, `complete_task`, `reopen_task`, `delete_task`, `move_task`,
`clear_completed`.

## Rollout

1. Create the Google Cloud project, enable the Tasks API, generate a
   web-application OAuth client (Testing mode, owner as sole test user).
2. Fork `ebmurha/google-tasks-mcp`, wire in the OAuth client, confirm the
   12 tools above are present, set token storage to something durable.
3. Deploy to Cloudflare Workers (or Fly.io/Render). Verify the HTTPS
   endpoint answers the MCP handshake with an MCP inspector before
   touching Claude.
4. Register once: claude.ai → Settings → Connectors → Add custom
   connector → the deployed URL. Complete the Google OAuth consent here.
5. Confirm on every surface: ask the same question ("what's overdue on my
   task lists") from Claude web, Desktop, the phone app, and a Cowork
   session — no further setup on any of them.
6. Retire `install.sh` / `install.ps1` and the Smithery instructions —
   superseded, and leaving them risks someone reinstalling the broken
   path.

## Staying stable

| Concern | Mitigation |
|---|---|
| Token expiry | Refresh token stored encrypted at rest; server refreshes the access token itself |
| Third-party outage | Removed entirely — no Smithery, no broker between user and Google |
| Server downtime | Workers has no idle "down" state; on Fly.io/Render, enable auto-restart + health check |
| Quota | Tasks API allows ~50,000 requests/day per project — no realistic ceiling for single-user use |
| Drift from Google's API | Pin the forked server's dependency versions; re-test all 12 tools before redeploying after any upstream update |

## Status

This document is the design pass. Building it requires accounts this
session doesn't have: a Google Cloud project and a hosting account
(Cloudflare/Fly.io/Render). Once those exist, the fork-and-deploy work in
"Rollout" steps 1–4 is a single follow-up session.
