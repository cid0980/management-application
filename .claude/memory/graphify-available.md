---
name: graphify-available
description: graphify 0.9.114 (uv tool) and the fm_shop code graph — where it lives, how to rebuild it, what it says
metadata:
  type: reference
---

`graphify` 0.9.114 is at `~/.local/bin/graphify` (reinstalled 2026-11-21 with
`uv tool install graphifyy` after the old install vanished). It is
also installed as a Claude skill (`graphify install --platform claude` →
`~/.claude/skills/graphify/`), so `/graphify .` works in a fresh session.

## The fm_shop graph

Lives in `graphify-out/` (gitignored), rebuilt with `graphify update .` from
the project root. Last full build: **2682 nodes, 3946 edges, 130 communities**
over 165 files (2026-10-24); rebuilt 2026-11-21: **7228 nodes, 9134 edges, 152
communities** over 238 files. `.graphifyignore` excludes node_modules/, build/,
.dart_tool/ — without it test/rules/node_modules (183 MB) floods the graph.

It writes three things:

- `graph.json` — the data. **Edges are under `links`, not `edges`**; each node
  carries `source_file`. Counting in-degree per file is how to find anything
  orphaned.
- `GRAPH_REPORT.md` — the readable one. Sections worth knowing: *Community
  Hubs* (navigation), *God Nodes*, *Surprising Connections*, *Import Cycles*.
- `graph.html` — a visual map to open in a browser.

## What it says about this codebase

- **No import cycles.**
- **Every god node is a repository interface** — `DraftStore` (35 edges),
  `AuthState`, then `CustomerRepository`, `SettingsRepository`,
  `SecondHandRepository` and the rest. That is the repository boundary showing
  up as the core abstraction, which is what it was for. If a *screen* or a
  *model* ever tops that list, something has leaked.

## Two gotchas

- **No LLM backend is configured** (no `GOOGLE_API_KEY` etc., no `claude`
  binary on PATH), so communities stay named `Community N`. The *Community
  Hubs* list names the hub file instead, which carries the meaning — do not
  bother chasing labels.
- **`firestore.rules` is not in the graph.** graphify skips it as
  unclassified, so the tenant-isolation rules are invisible here. They are
  covered by `test/rules/` instead — see [[multi-tenant]].

**How to apply:** reach for it when tracing references across many files or
checking nothing new is orphaned after a batch of work, not for ordinary
edits. See [[fm-shop-architecture]] and [[no-apk-builds]].
