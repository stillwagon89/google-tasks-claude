# Google Tasks MCP Integration — Complete Diagnostic Report

**Generated:** 2026-08-26  
**Repository:** stillwagon89/google-tasks-claude  
**Current Status:** Design complete, implementation pending  
**Difficulty:** Medium (known architecture, reliable solutions exist)

---

## Executive Summary

The Google Tasks integration **worked** in May 2026 (2 sessions), then **failed** in July 2026 when the Smithery registry listing disappeared. The original installer architecture was also flawed: **Desktop-only**, never reaching web/mobile/Cowork surfaces.

**The good news:** The failure is well-understood, well-documented, and has multiple proven solutions. PLAN.md recommends a clear path forward using Composio's hosted MCP or self-hosting with full control.

---

## Historical Timeline & What Worked

| Date | What Happened | Status |
|------|---------------|--------|
| 2026-05-10 | Smithery installer created (install.sh, install.ps1) | ✓ Works |
| 2026-05-11 | First session: `googletasks:list_task_lists`, `googletasks:list_tasks` | ✓ Works (but 4-min hang on first call) |
| 2026-05-17 | Second session: same tools, same hang pattern | ✓ Works (retry resolves hang) |
| 2026-07-04 | Smithery registry listing disappears | ✗ BREAKS |
| 2026-07-04+ | Every MCP registry search for "google tasks" returns zero results | ✗ Broken for 50+ days |
| 2026-08-17 | PLAN.md + HISTORY.md written (diagnosis complete) | ⏳ Design only |
| 2026-08-26 | **You are here** (diagnostic report compiled) | ⏳ Awaiting implementation |

### What Succeeded: May 2026 Sessions

**Session 1 (2026-05-11): "Prioritizing today's tasks"**
- Tools: `googletasks:list_task_lists`, `googletasks:list_tasks`
- Retrieved 5 task lists successfully
- Issue: First call hung 4 minutes, retry succeeded
- Artifact created: **TaskBrief** (React component with direct Google OAuth — works independently of MCP)

**Session 2 (2026-05-17): "London shows and events"**
- Same tools, same hang pattern (4 min)
- Workaround discovered: disconnect/reconnect in Settings resolves it
- Retrieved 7 task lists
- Secondary bug found: Re-adding connector threw "server already exists" (stale cache)

### What Failed: July 2026 Onward

**Smithery Listing Disappeared**
- Last working: 2026-05-17
- First confirmed missing: 2026-07-04 (~50 days later)
- Every search since (5+ sessions, multiple years) returns zero Google Tasks results
- Root cause: Smithery is a community registry, not a maintained product

**MCP Registry Searches: Consistent Pattern**
```
search_mcp_registry(['google tasks']) → Returns: Todoist, TickTick, Asana, ClickUp, Wrike
search_mcp_registry(['tasks']) → Same result (Todoist, Asana, etc.) — NEVER Google Tasks
search_mcp_registry(['todo']) → Same result
```
Conclusion: **No official Google Tasks MCP exists in Anthropic's registry or Google's official products.**

---

## Root Causes of Failure

### Root Cause #1: Architectural Layer Mismatch

**The Problem:**
```
install.sh/install.ps1 writes to: ~/Library/Application Support/Claude
Only Claude Desktop reads this file.
Never reached: Web (claude.ai), mobile (iOS/Android), Cowork sessions
```

**Why This Matters:**
- Desktop has local filesystem access
- Cloud services (web, mobile, Cowork) cannot access local files
- Each surface needs independent configuration OR account-level sync

**Solution:** Use account-level custom connectors (Settings → Connectors in Claude), which sync automatically to all surfaces.

### Root Cause #2: Smithery Dependency & Registry Unreliability

**The Problem:**
- Smithery is a **community marketplace**, not Anthropic infrastructure
- No SLA, no maintenance guarantee
- Listings can disappear without notice or explanation
- No direct fallback or mirror

**Evidence:**
- The googletasks listing worked May 11-17
- Disappeared by July 4
- Never reappeared despite direct searches for 50+ days
- This is the documented pattern for community registry entries

**Solution:** Use a reliable hosted MCP (Composio) or self-host with own Google Cloud credentials.

### Root Cause #3: Silent Failures Without Error Handling

**The Problem:**
- `list_task_lists` silently hangs for ~4 minutes
- NO error message, NO exception, NO timeout constant
- Same pattern seen on Apple Reminders tool (reminder_search_v0)
- Users see spinner forever, assume broken, give up

**Pattern Observed:**
- 2026-05-11: Hang, retry works
- 2026-05-17: Hang, disconnect/reconnect works
- 2026-08-17: Apple Reminders tool exhibits identical hang
- Unknown cause: connection pool exhaustion? rate limiting? DNS issue?

**Solution:** Implement timeout (30 sec) + automatic retry + clear error message.

### Root Cause #4: Missing OAuth Token Management

**The Problem:**
- OAuth access tokens expire (typically 1 hour)
- Refresh tokens must be stored securely
- Smithery handled this server-side (but is now gone)
- No documented token lifecycle for Composio or self-hosted alternatives

**Solution:** Implement token refresh strategy in chosen MCP server.

---

## Current Codebase State

### Files
```
/home/user/google-tasks-claude/
├── .gitignore (standard)
├── README.md (Smithery instructions — outdated)
├── install.sh (Smithery installer — broken path)
├── install.ps1 (Smithery installer — broken path)
├── PLAN.md ⭐ (Architecture plan, recommendations)
├── HISTORY.md ⭐ (Full track record, root causes)
└── DIAGNOSTIC_REPORT.md (this file)
```

### Branches
- **claude/google-tasks-integration-il9fug** (current): Contains diagnosis + plan (design complete)
- **main**: Contains original broken installer (should be deprecated)

### Commits
```
2026-05-10 17:02:31 - Add .gitignore
2026-05-10 17:03:52 - Add README (Smithery approach)
2026-05-10 17:04:36 - Add installer (Smithery approach)
2026-05-10 17:05:08 - Add PowerShell installer
2026-08-17 18:41:25 - Add architecture plan
2026-08-17 18:47:07 - Revise plan (recommend Composio)
```

**Key Insight:** The feature branch contains DIAGNOSIS. The main branch contains the BROKEN INSTALLER. Neither branch has implementation code.

---

## Known Gotchas & Workarounds

### Gotcha #1: Silent 4-Minute Hangs on list_task_lists

**Symptom:**
- Spinner spinning forever
- No error message or timeout
- ~4 minute wait, then either succeeds or fails silently

**Workarounds:**
1. Simple retry ("try again") — often works immediately
2. Disconnect/reconnect in Settings → always resolves it

**Prevention for Next Developer:**
- Add timeout constant (30 seconds recommended)
- Implement automatic retry (one attempt)
- Add clear error message if both fail: "Tasks API timeout; please try again or disconnect/reconnect in Settings"
- Log the timeout event for debugging

### Gotcha #2: tasklist_id Resolution vs @default

**Symptom:**
- `list_tasks(@default)` works for the default list
- `list_tasks(@default)` fails for custom/named lists

**Root Cause:**
- `@default` only resolves to the actual default list
- Named lists require their real ID from `list_task_lists` response

**Solution:**
- Always call `list_task_lists` first
- Extract the actual `tasklist_id` from response
- Use that ID for all subsequent `list_tasks` calls
- Never hardcode `@default` for non-default lists

### Gotcha #3: Stale Connector URL Cache Bug

**Symptom:**
- Re-adding a connector throws: "server with this URL already exists"
- Happens after disconnecting/reconnecting
- Seen on Gmail connector (same failure class)

**Cause:**
- Stale cached server URL in Anthropic's cloud infrastructure

**Workarounds:**
1. Hard refresh browser (Cmd+Shift+R or Ctrl+Shift+R)
2. Full logout/login to Claude
3. Wait 24 hours (likely transient)

**For Implementation:**
- Add UI messaging: "If 'server already exists' error appears, try refreshing the page or logging back in"

### Gotcha #4: Desktop-Local Config Doesn't Sync

**Symptom:**
- Works on Claude Desktop
- Doesn't work on claude.ai (web)
- Doesn't work on mobile apps
- Doesn't work in Cowork sessions

**Root Cause:**
- Original install.sh writes to `~/Library/Application Support/Claude`
- This is Claude Desktop's **local** config file
- Web/mobile/Cowork services can't access local filesystem

**Solution:**
- **Don't** use Desktop-local config
- **Do** use account-level custom connectors (Settings → Connectors)
- This automatically syncs to all surfaces

---

## What's Missing (Gap Analysis)

### Missing #1: Account-Level Cloud Configuration

**Current:** Desktop-only (local config file)  
**Needed:** Cloud-level (Settings → Connectors)  
**Impact:** Desktop only → All surfaces automatically

Anthropic already provides this infrastructure. The original installer just didn't use it.

### Missing #2: Reliable Google Tasks MCP Server

**Options Evaluated:**

| Option | Status | Setup Time | CRUD | Recommendation |
|--------|--------|-----------|------|-----------------|
| Smithery-hosted (current) | ✗ Broken (registry gone) | N/A | Full | DO NOT USE |
| **Composio-hosted** | ✓ Working | 10 min | Full | ⭐ RECOMMENDED |
| Zapier-hosted | ✓ Working | 15 min | Partial | Alternative |
| Pipedream-hosted | ✓ Working | 15 min | Partial | Alternative |
| **Self-host (ebmurha)** | ✓ Working | 1-2 hrs | Full | ⭐ ALTERNATIVE |
| Self-host (taylorwilsdon) | ✓ Working | 1-2 hrs | Full | Broad (Gmail+Tasks) |
| Google Apps Script | ✓ Working | 1-2 hrs | Partial | Last resort |

**Recommended: Composio** (purpose-built for Claude, full CRUD, no code needed)

### Missing #3: Error Handling & Timeout Strategy

**Current behavior:** Hang 4 minutes, no error  
**Needed:**
- Configurable timeout (30 seconds)
- Automatic retry once
- Clear error message to user
- Logging for debugging

### Missing #4: Fallback Layer Documentation

**TaskBrief** (2026-05-11 session artifact):
- Standalone React component
- Direct Google OAuth (no MCP)
- Calls Tasks API client-side
- Sends results to Claude API
- Status: Proven working, not currently implemented
- Use case: If MCP remains unreliable

### Missing #5: Implementation & Testing

**Status:** Design pass complete (PLAN.md), implementation not started

---

## Recommended Path Forward

### Option A: Composio (Fastest, Recommended)

**Setup time:** ~10 minutes  
**Effort:** No code needed

1. Go to composio.dev, create free account
2. Find "Google Tasks" toolkit
3. Connect your Google account (complete OAuth)
4. Copy the MCP server URL from Composio dashboard
5. In Claude: Settings → Connectors → Add custom connector
6. Paste URL, complete Google OAuth consent
7. Done — works on Desktop, web, mobile, Cowork

**Why Recommended:**
- Purpose-built for Claude
- Full CRUD support (create/read/update/delete)
- Documented Cowork integration guide
- No code or infrastructure setup needed
- Reliable hosted provider

### Option B: Self-Host (Full Control)

**Setup time:** 1-2 hours  
**Effort:** Requires Google Cloud project + deployment

**Pick a repo:**
1. **ebmurha/google-tasks-mcp** (PRIMARY) — built for self-host
2. **taylorwilsdon/google_workspace_mcp** — broader Workspace coverage
3. **zcaceres/gtasks-mcp** — minimal clean implementation

**Steps:**
1. Create Google Cloud project (free tier)
2. Enable Google Tasks API
3. Create OAuth 2.0 Web Application client
4. Fork repo, configure with Google Cloud credentials
5. Deploy to Cloudflare Workers (free tier) or Fly.io
6. Register MCP server URL in Claude Settings → Connectors
7. Complete OAuth consent

**Why Consider:**
- Full control over your data
- No dependency on third-party SaaS
- Can customize if needed

### Option C: Fallback (If MCP Stays Unreliable)

**TaskBrief artifact** (from 2026-05-11 session):
- Standalone React component
- Direct Google OAuth, no MCP layer
- Calls Tasks API client-side
- Status: Read-only, UI outside chat, proven working
- Use only: If Composio/self-host don't work

---

## Critical Success Factors for Implementation

For any solution to work, it MUST:

✓ **Move from Desktop-local → Cloud-level configuration**
  - So all 4 surfaces (Desktop, web, mobile, Cowork) work automatically

✓ **Use a reliable MCP server**
  - Composio (hosted) OR self-hosted with your control

✓ **Implement timeout + retry for list_task_lists**
  - To handle 4-minute hangs gracefully

✓ **Document tasklist_id vs @default gotcha**
  - To prevent silent failures on named lists

✓ **Add error messages (no silent failures)**
  - Users need to know what went wrong

✓ **Test on all 4 surfaces**
  - Desktop, claude.ai web, mobile app, Cowork

✓ **Maintain TaskBrief fallback**
  - As documented alternative if MCP fails

---

## Testing Checklist (After Implementation)

Before declaring success, verify:

- [ ] Works on Claude Desktop
- [ ] Works on claude.ai (web)
- [ ] Works on Claude mobile (iOS/Android)
- [ ] Works in Cowork sessions
- [ ] Can list tasks on default list
- [ ] Can list tasks on named custom list (NOT @default)
- [ ] Can create a new task
- [ ] Can update an existing task
- [ ] Can mark task as complete
- [ ] Can delete a task
- [ ] Handles 4-minute hang gracefully (timeout + retry)
- [ ] Automatic retry works when timeout occurs
- [ ] Error messages are clear (not silent failures)
- [ ] Continues working after OAuth token refresh

---

## Commands to Verify Current State

```bash
# Check current branch
git branch -a

# Verify files exist
ls -la PLAN.md HISTORY.md README.md install.sh install.ps1

# Check commit history
git log --oneline | head -10

# Search for any TODOs/FIXMEs
grep -r "TODO\|FIXME\|HACK" . --include="*.md" --include="*.sh" --include="*.ps1"
```

---

## For the Next Developer: How to Use This Report

### Reading Order (30 minutes)

1. **HISTORY.md** (5 min) — Understand what worked and when it broke
2. **PLAN.md** (10 min) — Understand architecture recommendations and gotchas
3. **This document** (10 min) — Full diagnostic context
4. **README.md** (2 min) — Note that current installer is broken
5. **Decide:** Composio (10 min) or self-host (2 hours)?

### Implementation Path

**If choosing Composio:**
- 10-minute setup (no code)
- Follow steps in "Option A" above
- Then test on all 4 surfaces
- Update README.md with new instructions
- Deprecate install.sh/install.ps1

**If choosing self-host:**
- Set up Google Cloud project (free)
- Choose repo, fork, configure, deploy (1-2 hours)
- Register URL in Claude Settings → Connectors
- Test on all 4 surfaces
- Add error handling for known gotchas

### Key Resources

| Resource | Purpose |
|----------|---------|
| HISTORY.md | What was tried, when, and why it failed |
| PLAN.md | Root causes, architecture recommendations, known gotchas |
| README.md | Current (broken) setup instructions — **needs update** |
| Composio docs | composio.dev/toolkits/googletasks/framework/claude-cowork |
| Self-host GitHub | github.com/ebmurha/google-tasks-mcp (or taylorwilsdon variant) |
| TaskBrief artifact | From 2026-05-11 session (fallback, read-only) |

---

## Summary Table

| Aspect | Status | Notes |
|--------|--------|-------|
| **Problem** | Well-understood | Smithery registry disappeared, Desktop-only config flaw |
| **Root causes** | Identified | 4 root causes documented with mitigation strategies |
| **Historical record** | Complete | 5+ sessions, 2 successes, 3+ failures all tracked |
| **Architecture fix** | Designed | PLAN.md recommends Composio or self-host |
| **Fallback** | Documented | TaskBrief artifact exists and works |
| **Gotchas** | Known | 4 gotchas with workarounds documented |
| **Implementation** | NOT STARTED | Design pass complete, code not written |
| **Testing** | NOT STARTED | Checklist prepared, awaiting implementation |
| **Difficulty** | Medium | Known solutions exist, good documentation, 10 min to 2 hrs depending on path |

---

**Generated by automated diagnostic agent, 2026-08-26**  
**For updates or corrections, see HISTORY.md and PLAN.md**
