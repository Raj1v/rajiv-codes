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
- A single ticket from a working session still gets its own folder `.claude/ticket-drafts/<slug>/`.
- One file per ticket/project: `NN-<slug>.md`, metadata lines on top (`project`, `assignee`, `cycle`, `priority`, `blocked by` / `related`), then the native template headings.
- Draft in parallel with `ticket-drafter` agents, one per ticket. Every prompt states: the exact output path in the batch folder; **only content the source (or the approved proposal) says — no inferred requirements, no implementation choices** (those belong to the assignee); every SFD key/PR as a link; no Niko weekly-plan Notion link in Resources.
- Audit each returned draft against the source before review; strip anything that isn't sourced.
- Parked items go to `.claude/ticket-drafts/parked/`.
- Ticket born from a working session: write its `/handoff` as `NN-<slug>.handoff.md` in the same folder (not the OS temp dir), so the Plannotator session reviews draft and handoff together.

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
- Ticket born from a working session: attach its `NN-<slug>.handoff.md` from the draft folder, uploaded as `handoff.md`, under Relevant Resources (see below). The handoff carries the agent context (files, current state, gotchas); the body stays terse. Never fold handoff content into Requirements.

### Attaching a file to an issue

"Attach X to the ticket" means the file sits **inside the description**, under the `### 📚 Relevant Resources` heading. Not an Attachment entity — `create_attachment_from_upload` makes a link chip outside the body, which is the wrong thing ("you didnt use an attachment, you use da 'resource' in linear", SFD-3784, 2026-10-02).

1. `prepare_attachment_upload` (issue, filename, contentType, size) → gives `assetUrl` + a signed `uploadRequest`.
2. PUT the raw bytes to `uploadRequest.url` within 60s, sending every header in `uploadRequest.headers` verbatim — any omitted or re-cased header gives 403. `curl -X PUT --data-binary @<file>`.
3. Do **not** call `create_attachment_from_upload`. Instead `save_issue` with a `patch` that inserts this after the Resources heading, with `href` set to the `assetUrl` from step 1:

```
<linear-embed node-type="file">{"uploadState":"finished","uploadId":"upload-<ms>-<rand>","href":"<assetUrl>","name":"<filename>","size":<bytes>,"mimetype":"<mime>"}</linear-embed>
```

Linear re-signs `href` on read, so the signature in the stored node expiring is fine. Verify with `get_issue`: the file must show up inside `description`, not only in `attachments[]`.

## 7. Wrap-up (when asked)

- Cycle Goals canvas: one section per week, `![](slack_date:start) → ![](slack_date:end)` then a `Project | Team | Goal` table with Linear-linked, emoji-prefixed project names. Read the canvas first; an empty canvas needs a placeholder character before the API can write.
- Messages to people: draft only, copy to his Mac clipboard with `tmux load-buffer -w <file>`; never send.
