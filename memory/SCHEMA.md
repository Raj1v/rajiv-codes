# Total Recall Memory Schema

## Four-Tier Architecture

1. **Daily Logs** (`memory/daily/YYYY-MM-DD.md`) — raw capture, written during sessions
2. **Registers** (`memory/registers/`) — curated domain knowledge, loaded on demand
3. **Working Memory** (`CLAUDE.local.md`) — auto-loaded every session, behavior-critical facts only
4. **Archive** (`memory/archive/`) — completed projects, superseded decisions

## Write Gate

Before writing anything, ask: **"Does this change future behavior?"**
- Yes → write it
- No → skip it

## Read Rules

| Source | When Loaded |
|--------|-------------|
| `CLAUDE.local.md` | Every session (auto) |
| `memory/registers/_index.md` | Every session (auto) |
| `memory/registers/open-loops.md` | Every session (auto) |
| Other registers | On demand, when topic is triggered |
| Daily logs | On demand, via /recall-search |
| Archive | Rarely, when historical context needed |

## Routing Table

| Trigger | Destination |
|---------|-------------|
| Person mentioned | `registers/people.md` |
| Project discussed | `registers/projects.md` |
| Past choice questioned | `registers/decisions.md` |
| Style/workflow preference | `registers/preferences.md` |
| Tech tool/framework | `registers/tech-stack.md` |
| Follow-up / deadline | `registers/open-loops.md` |
| Raw session note | `daily/YYYY-MM-DD.md` |

## Contradiction Protocol

Never silently overwrite. When new info conflicts with existing:
1. Mark old entry as `~~superseded~~`
2. Add new entry with date
3. Note what changed and why

## Correction Handling

User corrections are highest priority. Propagate immediately to:
1. Working memory (CLAUDE.local.md)
2. Relevant register
3. Today's daily log

## Maintenance Cadences

- **Immediate**: corrections, open loops, new decisions
- **End of session**: promote key daily log entries to registers
- **Periodic**: trim working memory to ~1500 words
- **Quarterly**: archive completed projects, prune stale entries

## Notes

- Working memory lives in `CLAUDE.local.md` (auto-loaded)
- Protocol lives in `.claude/rules/total-recall.md` (auto-loaded if present)
