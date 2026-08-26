# Architecture plan — Google Tasks ↔ Claude, on every surface

> Revised 2026-08-17 against `HISTORY.md` (prior session track record). The
> revision changes the primary recommendation from "self-host a server" to
> "connect Composio's existing Google Tasks MCP toolkit" — see below.

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

`HISTORY.md` confirms this is more than a theory: a `googletasks:*` tool —
almost certainly this same Smithery listing — worked in two sessions in
May 2026, then was unreachable in every session since, including direct
registry searches. Community-hosted MCP registry listings can disappear
without notice; that is very likely exactly what happened.

## The fix

Claude supports **custom connectors over remote MCP**: a server, registered
once in the Claude account (claude.ai → Settings → Connectors → Add custom
connector). Anthropic's cloud reaches that server directly, so every
surface that authenticates as the user gets it automatically — Claude web,
Claude Desktop, the Claude mobile apps (added via web, syncs
automatically), and Cowork. One registration, one OAuth grant, every
surface.

For the phone's native **Google Tasks app**, nothing needs to be built —
it already reads and writes the same account data as the Tasks API. The
moment the connector creates or completes a task through the real API,
it's on the phone, in the Gmail sidebar, and on Calendar. Same mechanism
that syncs Apple Notes to Reminders on iOS, one layer down: the account's
own data store, not a bespoke bridge between two apps.

The question is *which* remote MCP server sits behind that connector —
one we host, or one that already exists.

## Options weighed

| Option | Verdict |
|---|---|
| Smithery-hosted MCP (current) | Reject — confirmed unreliable by `HISTORY.md`; Desktop-only, community registry listing |
| Zapier / Pipedream MCP | Maybe — hosted and easy to add, but their Google Tasks actions lean automation-flavored (create/update/list), no confirmed delete |
| **Composio's Google Tasks MCP** | **Recommended** — purpose-built toolkit, full CRUD, documented Claude Cowork guide, no code or hosting |
| Self-hosted remote MCP connector | Alternative — full control over the pipe, more setup |
| Google Apps Script Web App | Fallback only — avoids external hosting, but request limits & cold starts make it secondary |

## The build

### Fast path — Composio's Google Tasks MCP (recommended)

Composio maintains Google Tasks as a first-party toolkit — not a fork we'd
own — with a documented Claude Cowork integration guide
(composio.dev/toolkits/googletasks/framework/claude-cowork). Confirmed
actions include create/delete task, create/delete task list,
clear-completed, and batch operations; verify list/get/update/complete
land the same way in their dashboard before relying on read-heavy flows.

Setup: create a Composio account → connect the Google account to the
Google Tasks toolkit → copy the MCP server URL → add it as a custom
connector in claude.ai. No Google Cloud project, no hosting, no code.

### Full-control path — self-host instead

Skip unless the priority is nothing sitting between the user and Google
for this data.

- **ebmurha/google-tasks-mcp** (primary pick) — built specifically for
  self-host: own Google Cloud OAuth client, streamable HTTP mode,
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
test user, it never needs Google's verification review.

### Tool surface (target shape, either path)

`list_task_lists`, `create_task_list`, `delete_task_list`, `list_tasks`,
`get_task`, `create_task`, `update_task`, `complete_task`, `reopen_task`,
`delete_task`, `move_task`, `clear_completed`.

## Known gotchas, carried over from `HISTORY.md`

- **Silent hangs on the list call.** The old `googletasks` tool had
  `list_task_lists` hang for ~4 minutes with no error, more than once — a
  bare retry or a disconnect/reconnect in Settings cleared it both times.
  If this recurs on Composio's server, retry once before treating it as
  broken.
- **`tasklist_id`, not `@default`.** `@default` only resolves the actual
  default list — named/custom lists need the real ID from
  `list_task_lists` first.
- **Stale connector URL.** Re-adding a disconnected connector has thrown
  "server with this URL already exists" before (seen on the Gmail
  connector, same failure class) — a hard refresh or full logout/login
  cleared it.

## Rollout

1. Connect Google Tasks to Composio (or, full-control path: create the
   Google Cloud project, enable the Tasks API, generate a web-application
   OAuth client in Testing mode).
2. Get the MCP server URL from Composio (or: fork `ebmurha/google-tasks-mcp`,
   wire in the OAuth client, deploy to Cloudflare Workers, verify the
   handshake with an MCP inspector).
3. Register once: claude.ai → Settings → Connectors → Add custom
   connector → paste the URL. Complete the Google OAuth consent here.
4. Confirm on every surface: ask the same question ("what's overdue on my
   task lists") from Claude web, Desktop, the phone app, and a Cowork
   session — no further setup on any of them. Retry once if a list call
   hangs.
5. Retire `install.sh` / `install.ps1` and the Smithery instructions —
   superseded, and leaving them risks someone reinstalling the broken
   path.

## Staying stable

| Concern | Mitigation |
|---|---|
| Token expiry | Composio refreshes on its side; if self-hosting, store the refresh token encrypted and refresh access tokens server-side |
| Listing churn (the May 2026 disappearance) | Composio is a maintained product with published docs and framework guides, not a community registry entry — worth a periodic sanity check regardless |
| Server downtime | Composio's uptime becomes the dependency on the fast path; on the full-control path, enable auto-restart + health check |
| Quota | Tasks API allows ~50,000 requests/day per project — no realistic ceiling for single-user use, either path |
| If MCP access stays flaky | **TaskBrief** — a standalone React component from a prior session that authenticates against Google OAuth directly and hands data to the Claude API, bypassing the connector layer entirely. Read-oriented, outside the chat itself, but a real fallback worth reviving if connector reliability doesn't hold up. |

## Status

This document is the design pass. The fast path (Composio) needs a
Composio account and a few minutes in claude.ai Settings → Connectors —
no code from this session. The full-control path additionally needs a
Google Cloud project and a hosting account. Either way, actually flipping
the switch in Claude's connector settings is a step only the account owner
can take.
