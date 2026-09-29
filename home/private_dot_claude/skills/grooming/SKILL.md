---
name: grooming
description: Rajiv's ticket-grooming workflow for studyflash — turn a plan (Niko's weekly Notion page, a spec, a brain dump, a handover) into Linear projects/tickets via drafts in one folder, a visual overview next to them, and live Plannotator review; push to Linear only on "push". Use for "/grooming", "groom X", "prepare next week's schedule", "turn this into tickets".
---

# Grooming

Draft → review in Plannotator → push. Nothing reaches Linear until Rajiv says "push".

Before anything, re-read the memory rules this workflow depends on (they are the source of truth for style, don't restate them in drafts): `feedback_grooming_style`, `feedback_approved_proposal_counts_as_said`, `feedback_ticket_format`, `feedback_batch_drafts_one_folder`, `feedback_link_every_sfd_key`, `feedback_no_notion_weekly_plan_links`, `feedback_never_reassign_linear_without_ask`, `plannotator-live-anchor-replies`, `feedback_chris_not_my_resource`. Structure and writing rules: `docs/agents/issue-tracker.md`.

## 1. Gather

- Read the source in full, **including its comments** (Notion `notion-get-comments` with `include_all_blocks`), linked sub-pages, linked Figma, and related Slack threads. He notices every skipped source.
- Check Linear before proposing: existing projects/issues (avoid duplicates), current cycle (`list_cycles`), each owner's open load.
- Heavy lookups go to background subagents (one question each); relay conclusions, not dumps.

## 2. Propose in chat

A short list: projects, tickets, owner per ticket, what's skipped and why. Initials from the source map to Linear users (verify with `list_users`). Wait for the go. His approved proposal then counts as his words.

## 3. Draft into one folder

- Folder: `.claude/ticket-drafts/<batch-slug>/` (e.g. `week-2026-09-28`). Everything for the batch lives here so one Plannotator session shows it all.
- One file per ticket/project: `NN-<slug>.md`, metadata lines on top (`project`, `assignee`, `cycle`, `priority`, `blocked by` / `related`), then the native template headings.
- Draft in parallel with `ticket-drafter` agents, one per ticket. Every prompt states: the exact output path in the batch folder; **only content the source (or the approved proposal) says — no inferred requirements, no implementation choices** (those belong to the assignee); every SFD key/PR as a link; no Niko weekly-plan Notion link in Resources.
- Audit each returned draft against the source before review; strip anything that isn't sourced.
- Parked items go to `.claude/ticket-drafts/parked/`.

## 4. Visual overview next to the drafts

`_overview.html` in the batch folder (Plannotator theme tokens + `<meta name="plannotator-theme" content="host">`, see `plannotator-visual-explainer`). Contents:
- Summary numbers (drafts, in grooming, blocked, open load that matters).
- Workstream table grouped: *In Linear* · *Drafted* · *Won't groom tonight* · *Not drafted* (with the blocker) · *Parked/Skipped*. Owner and next step per row.
- Heads-up (real risks only), decisions that are genuinely his (each with an owner), proposed cleanup (never executed without a go).
- Every SFD key and PR linked. No Chris.
Private per-person notes (e.g. `_niko.md`: message gist, notes to pass on, drafted answers) live in the same folder.

## 5. Live review

- One session over the whole folder: `PLANNOTATOR_REMOTE=1 PLANNOTATOR_PORT=<free port from plannotator sessions> PLANNOTATOR_READY_FILE=<scratchpad>/plannotator-ready plannotator annotate <batch-folder> --gate --json` in the background. Hand him `http://<tailscale-ip>:<port>`.
- Watch with the `plannotator-live` skill (Monitor on `watch.sh`, max timeout, re-arm on expiry; replays of handled ids are ignored).
- Per comment, immediately: edit the file (draft or overview), then reply on the commented text via `reply.sh` — short: the answer, or "Done: <what changed>".
- "Won't groom tonight" / owner changes / removals → update the overview right away too.

## 6. Push (only on "push")

- Projects: `save_project` with the project template id, then set the description. No lead unless he names one, no milestones unless asked, no Out-of-scope section.
- Issues: `save_issue` with the issue template id, then the description; set assignee, cycle, project, priority, relations (`blockedBy`, `relatedTo`) from the metadata lines. States by **ID** (`reference_linear_state_ids`).
- Skip everything under "Won't groom tonight" or parked.
- Never change assignee, priority or status on existing issues unless he names the issue and the value; keep existing priorities when bulk-moving.
- After pushing: put the Linear links into the overview, report the created keys in a table.

## 7. Wrap-up (when asked)

- Cycle Goals canvas: one section per week, `![](slack_date:start) → ![](slack_date:end)` then a `Project | Team | Goal` table with Linear-linked, emoji-prefixed project names. Read the canvas first; an empty canvas needs a placeholder character before the API can write.
- Messages to people: draft only, copy to his Mac clipboard with `tmux load-buffer -w <file>`; never send.
