# Google Tasks MCP — Full History & Known Issues

Compiled 2026-08-17 from past Claude.ai conversations. Purpose: give Claude Code
the real track record before it tries to build or wire up Google Tasks access,
so it doesn't repeat dead ends.

## TL;DR for Claude Code

- A `googletasks:*` MCP tool **did exist and work** in three sessions between
  2026-05-11 and 2026-05-17, then **disappeared** — every attempt to find it
  since 2026-07-04 has failed, including direct MCP registry searches.
- **No official Google-published Tasks MCP exists** (confirmed via web research
  July 2026). Google's Workspace MCP developer preview covers Gmail, Drive,
  Calendar, Chat, and People — Tasks is explicitly not included.
- The registry (`search_mcp_registry`) has never once returned a Google Tasks
  result for keywords `google tasks`, `tasks`, or `todo` — it surfaces
  Todoist, TickTick, Asana, ClickUp, Wrike, etc. instead, never Google Tasks.
- Working alternatives that exist **today** and don't depend on Anthropic's
  connector catalog: Zapier MCP, Pipedream MCP, Composio MCP (all hosted,
  OAuth-based), or the open-source `gtasks-mcp` (self-hosted Node.js server).

---

## Timeline

### 2026-05-11 — "Prioritizing today's tasks" (working)
- Tools used: `googletasks:list_task_lists`, `googletasks:list_tasks`
- **Issue:** `list_task_lists` timed out after 4 minutes on first call. Retrying
  the identical call ("try again") succeeded — no reconnect needed that time.
- **Behavior notes once working:**
  - `list_tasks` requires the exact `tasklist_id` string returned by
    `list_task_lists`. Passing `@default` only works for the actual default
    list, not named/custom lists.
  - Reliable call pattern: `list_tasks(tasklist_id=..., showCompleted=false,
    maxResults=100)`, run in parallel across all lists.
  - Successfully pulled 5 lists (Today - Priority, This Week - Priority, Two
    Weeks Out, Job Hunt, Junk List) and produced a prioritized breakdown.
- Also produced a **separate, non-MCP artifact**: "TaskBrief", a standalone
  React component that authenticates directly against Google OAuth (not
  through Claude's MCP connector) and calls the Tasks API client-side, then
  sends the data to the Claude API for analysis. Requires the end user to
  create their own Google Cloud project, enable the Tasks API, and generate
  an OAuth Client ID (Web application, `https://claude.ai` as authorized
  origin). Read-only scope, no server-side storage. This approach is
  independent of Anthropic's connector infrastructure entirely — worth
  revisiting if MCP access stays unavailable.

### 2026-05-17 — "London shows and events" (working, but flaky)
- Same `googletasks:*` tools used again.
- **Issue:** `list_task_lists` timed out again (4 min hang, no error message —
  a silent hang rather than a thrown error). Same for a parallel Gmail MCP
  failure in the same session.
- **Fix that worked:** disconnecting and reconnecting the integration in
  Claude Settings resolved it. A bare retry ("try now") also worked without
  reconnecting, so the failure mode seems intermittent/session-based rather
  than a hard break.
- **Side note (Gmail, same session):** re-adding a disconnected connector
  sometimes throws "server with this URL already exists" — fixed by a hard
  refresh (Cmd+Shift+R) or full logout/login. Likely a stale cached server
  URL on Anthropic's side. Flagging in case Tasks hits the same bug.
- Once stable, `list_task_lists(maxResults=50)` returned **7 lists**.

### 2026-07-04 — "Atomizing air in spray glazing" (tool gone, researched alternatives)
- No `googletasks:*` tool available at all this time — not found via
  `tool_search`, not in the connector list.
- Directed to do deep research. Findings:
  - **No official Google Tasks MCP exists** (checked Google's own Workspace
    MCP developer-preview docs — Tasks is not one of the covered products).
  - **Working third-party options identified:**
    1. **Zapier MCP** — Zapier hosts a personal MCP URL, handles Google OAuth.
       Add via claude.ai → Settings → Connectors → Add custom connector.
    2. **Pipedream MCP** — same pattern, hosted, one static URL.
    3. **Composio MCP** — hosted/managed, markets itself specifically for
       Claude integration.
    4. **`gtasks-mcp` (GitHub, open source)** — self-hosted, full control,
       but requires running a Node.js server and managing your own Google
       Cloud OAuth credentials. Not something you do from a phone — a
       once-on-a-laptop setup. **This is the one most relevant to Claude
       Code**, since Code runs in an environment where standing up a local
       MCP server is actually feasible.
  - Custom connectors (Zapier/Pipedream/Composio) require claude.ai
    desktop/web (not mobile) and a Pro/Max/Team/Enterprise plan.
- Conversation ended before setup was completed — offered to walk through
  Zapier or Pipedream but user hadn't confirmed which by session end.

### 2026-07-30 — "Initial contact" (tool gone, pushback)
- User was confident a custom Google Tasks integration had been built
  previously and should still be available.
- Checked memory (`/topics/side-projects.md`), Apple Reminders — found
  nothing relevant either way (list itself wasn't there, and no integration
  record).
- Confirmed connector set at the time: Calendar, Drive, Gmail, Notion, Slack,
  Apple Reminders. No Google Tasks. Unresolved by end of session.

### 2026-08-04 — "Integrating calendar and email into daily briefing" (confirmed hard gap)
- Wanted a daily brief pulling from Calendar, Gmail, Slack, Apple Notes, and
  Google Tasks.
- `search_mcp_registry(['apple notes', 'notes'])` → zero results.
- `search_mcp_registry(['google tasks', 'tasks', 'todo'])` → zero results.
- Conclusion reached: **Apple Notes has no cloud API an MCP server could
  reach at all** (hard OS-level gap, not a config issue). Google Tasks
  registered as similarly unavailable, though for Tasks the gap is "no
  registry listing," not "no API" — Google does have a public Tasks API,
  which is exactly why `gtasks-mcp` and the Zapier/Pipedream/Composio
  wrappers above can work.
- Proposed and left pending: build the daily-brief skill against Calendar/
  Gmail/Slack now, architect it to pick up Apple Notes/Google Tasks
  automatically once connectors exist, use Drive/Notion as an interim bridge.

### 2026-08-17 (this repo's planning session) — reconfirmed gap
- `search_skills` and `search_plugins` for "google tasks" → no Google Tasks
  skill or plugin either (only a generic `productivity:task-management`
  plugin that manages a local `TASKS.md` file, unrelated to Google Tasks).
- `search_mcp_registry(['google tasks','tasks','todo'])` → returned Todoist,
  Wispr Flow, Asana, TickTick, Teamtailor, Craft, ClickUp, Attio, Wrike —
  task-adjacent products, never Google Tasks itself.
- `reminder_search_v0` (Apple Reminders — a different tool, but same
  "task list" category) also failed today: no response after a 4-minute
  wait, client-side tool unresponsive. Noting the pattern since it's the
  second task-list-shaped tool to hang exactly like the old `googletasks`
  calls used to before they'd eventually resolve.
- Separately in the same session, `event_create_v1` (Calendar) failed with
  `app_permission_denied` / "Calendar access was denied" even though
  `list_events` and the older `event_create_v0` both worked fine — flagging
  in case it's the same underlying permission-scoping issue rather than
  three unrelated bugs.
- Follow-up research (same day, PLAN.md revision) confirmed Composio
  publishes a first-party Google Tasks MCP toolkit with a documented
  Claude Cowork integration guide, with a fuller CRUD surface than
  Zapier/Pipedream's more automation-flavored action sets. See `PLAN.md`
  for the resulting recommendation.

---

## What this means for Claude Code

1. **Don't assume `googletasks:*` tools exist.** They worked in two sessions
   in mid-May 2026 and have not been reachable since, across ~4 separate
   later sessions and explicit registry searches. Treat it as gone unless
   proven otherwise in a fresh check.
2. **If you need Google Tasks read/write from Claude Code specifically**,
   the self-hosted `gtasks-mcp` (GitHub, Node.js, own Google Cloud OAuth
   credentials) is the most Code-appropriate option — Code can run and
   manage a local/background server in a way claude.ai chat can't.
3. **If a hosted option is acceptable**, Composio's Google Tasks MCP toolkit
   is the strongest lowest-setup-effort route — purpose-built, full CRUD,
   documented Claude Cowork support. Zapier/Pipedream MCP are viable but
   thinner (no confirmed delete). All three are configured through claude.ai
   Settings → Connectors (desktop/web, paid plan required), not something
   Claude Code can wire up unilaterally.
4. **Known transient failure mode**, seen repeatedly across the working
   period: `list_task_lists` silently hangs (~4 min) with no error, then
   either a bare retry or a disconnect/reconnect in Settings resolves it.
   If you rebuild this, add a timeout + one automatic retry before
   surfacing a hard failure to the user.
5. **`tasklist_id` gotcha**: never assume `@default` covers a named list —
   always resolve the real ID via `list_task_lists` first.
6. **TaskBrief** (the standalone React/OAuth artifact from 2026-05-11) is a
   working proof-of-concept for a fully independent path that sidesteps
   Anthropic's connector layer entirely — worth pulling up again if MCP
   access remains unreliable.

See `PLAN.md` in this repo for the architecture plan built from this
history.
