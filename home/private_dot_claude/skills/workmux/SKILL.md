---
name: workmux
description: Reference for the workmux CLI that manages git worktrees and
  tmux windows as isolated development environments. Use when the user
  mentions workmux, worktrees, or parallel agent workflows.
disable-model-invocation: true
---

# workmux

workmux manages git worktrees paired with tmux windows for parallel
development. Each worktree is an isolated workspace with its own branch,
terminal state, and AI agent.

**If the user asks you to create worktrees or dispatch tasks (e.g.,
"/workmux add ..."), you are a dispatcher.** Write prompt files and run
commands. Do NOT explore, read, or research the codebase first. Use
context you already have. The worktree agent does all the work.

## Key Concepts

- **Handle**: the worktree directory name, derived from the branch name
  (slugified). Used to identify worktrees in all commands
- **Worktree directory**: defaults to `<project>__worktrees/<handle>` as a
  sibling of the project root
- **Window prefix**: tmux windows are named `wm-<handle>` by default
  (configurable via `window_prefix`)
- **Agent status**: agents report status via hooks: working, waiting (needs
  input), done (finished)

## Commands

### Create a worktree

```bash
workmux add <branch-name>
```

Creates a git worktree, runs file operations and hooks, creates a tmux
window with configured pane layout, and switches to it.

Key flags:
- `-b, --background`: create without switching to it
- `-p <text>`: inline prompt for AI agent panes
- `-P <file>`: prompt from file
- `-e, --prompt-editor`: write prompt in $EDITOR
- `-A, --auto-name`: generate branch name from prompt via LLM
- `-a <agent>`: override the agent (can specify multiple for multi-worktree)
- `-w, --with-changes`: move uncommitted changes to the new worktree
- `--base <branch>`: branch from a specific base
- `--name <name>`: override the handle name
- `-o, --open-if-exists`: open existing worktree if it exists (idempotent)
- `-W, --wait`: block until the tmux window is closed
- `-n, --count <N>`: create N worktree instances
- `--foreach <matrix>`: create worktrees from variable matrix
- `--no-hooks, --no-file-ops, --no-pane-cmds`: skip setup steps

### List worktrees

```bash
workmux list          # all worktrees
workmux list --pr     # with GitHub PR status
workmux list <name>   # filter by handle or branch
```

Shows branch, agent status, tmux window status, and unmerged commits.

### Merge a branch

```bash
workmux merge                 # merge current branch into main
workmux merge <branch>        # merge specific branch
workmux merge --rebase        # rebase before merging (linear history)
workmux merge --squash        # squash all commits into one
workmux merge --into <branch> # merge into a different target branch
workmux merge --keep          # merge but keep worktree/window/branch
workmux merge --notification  # show system notification on success
```

Merges the branch, deletes the tmux window, removes the worktree, and
deletes the local branch. Use the `/merge` skill for the full workflow
(commit, rebase, then merge).

### Remove worktrees

```bash
workmux remove                # current worktree
workmux remove <name>...      # specific worktrees
workmux rm --gone             # worktrees whose remote branch was deleted
workmux rm --all              # all worktrees
workmux rm -f <name>          # force, skip confirmation
workmux rm --keep-branch      # keep the branch, remove worktree + window
```

### Open / close windows

```bash
workmux open <name>           # open or switch to tmux window
workmux open --new            # force a new window (creates suffix -2, -3)
workmux open <name> -p "..."  # open with a prompt for agent panes
workmux close <name>          # close tmux window, keep worktree
```

### Interact with other agents

These commands target agents by their worktree handle. If the handle is
not found in the current repo, workmux searches all active agents globally.
Use `project:handle` syntax to disambiguate when names collide.

```bash
# Check agent statuses
workmux status                          # all agents
workmux status auth api-tests           # specific agents

# Wait for agents
workmux wait agent-a agent-b            # block until done
workmux wait agent-a --timeout 3600     # with timeout (seconds)
workmux wait agent-a agent-b --any      # wait for first to finish
workmux wait agent-a --status working   # wait for specific status

# Read agent terminal output
workmux capture agent-a                 # last 200 lines (default)
workmux capture agent-a -n 50           # last 50 lines

# Send instructions to an agent
workmux send agent-a "fix the tests"    # short message
workmux send agent-a "/merge"           # send a skill command
workmux send agent-a -f followup.md     # from file
workmux send myproject:docs "update the API section"  # cross-project

# Run shell commands in an agent's worktree
workmux run agent-a -- pytest tests/    # wait and stream output
workmux run agent-a -b -- npm run build # run in background
```

### Other commands

```bash
workmux path <name>           # print worktree filesystem path
workmux dashboard             # TUI dashboard of all active agents
workmux config edit           # open global config in $EDITOR
workmux config reference      # print default config with all options documented
workmux init                  # generate .workmux.yaml in current project
```

## Configuration

Two levels: global (`~/.config/workmux/config.yaml`) and project
(`.workmux.yaml`). Project overrides global.

### Key options

```yaml
agent: claude                    # default agent for <agent> placeholder
merge_strategy: rebase           # merge, rebase, or squash
mode: window                     # window or session

panes:
  - command: <agent>             # <agent> resolves to configured agent
    focus: true
  - split: horizontal            # second pane with shell

files:
  copy:
    - .env                       # copy from main worktree
  symlink:
    - node_modules               # symlink from main worktree

post_create:
  - '<global>'                   # include global hooks
  - npm install                  # project-specific setup

base_branch: develop             # default base for new worktrees
window_prefix: wm-               # tmux window name prefix
```

Use `'<global>'` in project config arrays to include global values.

For the full configuration reference with all options documented, run
`workmux config reference`.

### Agent detection

Built-in agents (`claude`, `gemini`, `codex`, `opencode`, `kiro-cli`,
`vibe`) are auto-detected in pane commands and receive prompt injection
automatically. The `<agent>` placeholder resolves to the configured agent.

## Common Workflows

### Finishing work: direct merge

Use `/merge` to commit, rebase onto the base branch, and merge in one
step. This cleans up the worktree, tmux window, and branch.

### Finishing work: PR-based

1. Commit changes
2. `git push -u origin HEAD`
3. Use `/open-pr` to write a PR description and open in browser
4. After PR is merged remotely, clean up with `workmux rm --gone`

### Delegating tasks

Use `/worktree` to spin off tasks into parallel worktree agents. The
agent writes a prompt file and runs `workmux add -b -P <file>`.

For full lifecycle orchestration (spawn, monitor, merge), use
`/coordinator`.

### Cross-project worktree creation

`workmux add` creates worktrees in the current git repo and adds the
window to the current tmux session. To create a worktree in a different
project, run `workmux add` inside that project's tmux session.

Discover project paths from existing sessions:

```bash
tmux list-sessions -F '#{session_name} #{session_path}'
```

Then create the worktree in the target session:

```bash
# If the session exists:
tmux new-window -t <session> -c <project-path> \
  "workmux add <branch> -b -P <prompt-file>; exit"

# If the session does not exist, create it first:
tmux new-session -d -s <session> -c <project-path> && \
tmux new-window -t <session> -c <project-path> \
  "workmux add <branch> -b -P <prompt-file>; exit"
```

The temporary window closes when `workmux add` finishes; the worktree
window that workmux creates stays in the session.

Do NOT research before dispatching. Use context you already have, but
do not explore or read code just to write the prompt. Worktree agents
can read files from other projects via absolute paths, so reference
other projects by path and let the agent explore on its own.

## GitHub inbox drain

Invoked from a scheduled trigger (or manually when the user asks to "drain
the inbox" / "check notifications"). The job is to route new GitHub
notifications to the worktree agents that are already working on the
relevant PR or issue. **You are a dispatcher here too** — read the inbox,
match, `workmux send`, done. Do not explore code or draft replies yourself.

### Inputs and files

- `~/.claude/inboxes/github/inbox.jsonl` — append-only feed written by
  `~/.claude/scripts/gh-inbox-poll.sh`. One notification per line.
- `~/.claude/inboxes/github/processed.jsonl` — your dedupe ledger. One line
  per handled notification: `{"id","updated_at","handle","action"}`.
- `~/.claude/inboxes/github/orphans.jsonl` — items you couldn't match to a
  worktree. Left here for the user to triage manually.

Always run the poller first so the inbox is current (it is flock-protected
and will no-op if another session is already polling):

```bash
~/.claude/scripts/gh-inbox-poll.sh
```

### Concurrency guard — check before draining

Two Claude sessions in the same main repo could both fire the drain cron
within seconds of each other and double-send the same `workmux send`.
Guard against this with a stale-tolerant marker file:

```bash
LOCK="$HOME/.claude/inboxes/github/drain.lock"
if [ -f "$LOCK" ]; then
  AGE=$(( $(date +%s) - $(stat -c %Y "$LOCK") ))
  if [ "$AGE" -lt 90 ]; then
    echo "skip: another drain started ${AGE}s ago"
    exit 0
  fi
fi
date +%s > "$LOCK"
```

Run this as the very first step. If the check fails (another drain is
active), stop immediately — do not poll, do not read the inbox, do not
send anything. On successful drain completion (or any early exit after
claiming the lock), remove it:

```bash
rm -f "$HOME/.claude/inboxes/github/drain.lock"
```

The 90-second window is long enough for a healthy drain to finish and
short enough that a crashed drain unblocks the next scheduled fire.

### Scope to the current repo only

The drain runs per-repo. Detect the current repo from cwd and ignore every
inbox item that belongs to a different `.repo`. Drain runs in other repos
handle their own notifications.

```bash
CURRENT_REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
```

### Dedupe against `processed.jsonl`

An inbox item is **new** if no entry in `processed.jsonl` matches both its
`id` and `updated_at`. A re-updated thread (same id, newer `updated_at`)
counts as new work — a fresh comment or review landed on it.

### Matching a PR notification → existing worktree

For items where `.type == "PullRequest"`:

1. Extract the PR number `<N>` from `.api_url` (pattern: `.../pulls/<N>`).
2. Try in order — stop at the first hit:
   a. `workmux list --pr` — worktree whose tracked PR matches `<N>`.
   b. `workmux list "pr-<N>"` — handle collision (a worktree we spawned
      earlier for this PR that hasn't pushed yet).
   c. `workmux list "pr-<N>-review"` — review worktree we spawned earlier.
3. If matched, fetch the latest payload so the downstream agent has
   context — `gh pr view <N> --json title,author,reviews,comments` plus
   `.latest_comment_url` when present.
4. `workmux send <handle> "GitHub: <reason> on PR #<N> — <title>. <1-line summary of what the agent should do next>"`.
5. Record in `processed.jsonl` with `action: "sent"`.

No match → fall through to **Dispatching unmatched items** below.

### Matching an issue notification → existing worktree

For items where `.type == "Issue"`, matching is best-effort. Try in order:

1. Extract the issue number `<N>` from `.api_url` (`.../issues/<N>`).
2. **Handle name**: `workmux list "issue-<N>"` — a worktree we previously
   spawned for this issue.
3. **PR closing-link**: for each worktree PR from `workmux list --pr`, check
   whether it closes the issue:
   ```bash
   gh pr view <pr> --json closingIssuesReferences \
     -q '.closingIssuesReferences[].number' | grep -qx "<N>"
   ```
4. **Branch/handle name fuzzy**: worktree whose handle or branch contains
   the issue number (e.g. `fix-123-login` for issue #123).
5. **Commit trailer scan**: last resort,
   `git -C <worktree-path> log --format=%B main..HEAD | grep -Ei "#<N>\b"`.

If matched, `workmux send <handle> "GitHub: <reason> on issue #<N> — <title>. ..."` and record with `action: "sent"`.

No match → fall through to **Dispatching unmatched items** below.

### Dispatching unmatched items as new worktrees

The listener is a dispatcher — for actionable unmatched notifications it
spawns a fresh worktree following the `/worktree` skill's conventions.
Read `~/.claude/skills/worktree/SKILL.md` once at the start of the drain
so you have the dispatcher rules in working memory (mandatory setup line,
relative paths only, kebab-case handle, write-all-prompts-then-spawn).

**Decision table.** Spawn iff the row matches; otherwise orphan.

| type        | reason            | handle          | task                                                     |
|-------------|-------------------|-----------------|----------------------------------------------------------|
| PullRequest | review_requested  | `pr-<N>-review` | review the diff, leave inline comments, don't merge      |
| PullRequest | assign            | `pr-<N>`        | finish the PR we've been assigned                        |
| PullRequest | mention           | `pr-<N>`        | address the @mention                                     |
| PullRequest | author            | `pr-<N>`        | respond to activity on our own PR (worktree was removed) |
| PullRequest | comment           | `pr-<N>`        | respond to the new comment                               |
| Issue       | assign            | `issue-<N>`     | implement the issue end-to-end, open PR via `/open-pr`   |
| Issue       | mention           | `issue-<N>`     | investigate and respond                                  |

**Always orphan** (`action: "orphan"`, append to `orphans.jsonl`, don't
spawn): `reason` in {`subscribed`, `manual`, `team_mention`,
`state_change`, `ci_activity`}, `type` in {`Discussion`, `CheckSuite`,
`Release`, `RepositoryInvitation`}, and any Issue with `reason: "comment"`
where we're not assigned/mentioned.

**Spawn procedure** — follow `/worktree`'s workflow exactly:

1. **Gather context** (one `gh` call per item):
   ```bash
   gh pr view <N> --json number,title,author,body,url,headRefName,comments,reviews
   # or
   gh issue view <N> --json number,title,author,body,url,comments,labels,assignees
   ```

2. **Write a temp prompt file** per item (`mktemp --suffix=.md`). Template:
   ```
   Before starting, run: source .env.workmux 2>/dev/null && gh auth setup-git && git fetch origin main && git rebase origin/main && pnpm install

   ## Context

   GitHub <type> #<N> — <title>
   Notification reason: <reason>
   URL: <html_url>

   ### Body
   <PR or issue body, trimmed to ~80 lines>

   ### Latest activity that triggered this notification
   <the latest comment/review body, with author and timestamp>

   ## Your task

   <one paragraph tailored to the decision-table row, e.g.:
    - "Review PR #<N>. Read the diff with `gh pr diff <N>`, check it
      against repo conventions in AGENTS.md, and leave inline comments via
      `gh pr review <N> --comment -b '...'`. Do NOT approve or merge.
      When finished, stop — the human will decide on merge."
    - "Implement issue #<N>. Investigate the codebase as needed, make the
      change on this worktree's branch, run the relevant tests, commit,
      push, and use /open-pr to open a pull request. Use relative paths
      only.">

   Relative paths only. This worktree's branch is already created for you.
   ```

3. **Write all prompt files first**, then run `workmux add` for each in
   parallel (same workflow as `/worktree`):
   ```bash
   workmux add <handle> -b -P <tmpfile>
   # for review-only work, consider: workmux add <handle> -b --base main -P ...
   ```

   `-b` means background — do NOT switch the user's tmux focus. The
   listener session stays put.

4. **Record in `processed.jsonl`** with `action: "spawned"` and the handle.

**Collision safety.** Never spawn more than one worktree per `<N>` per
drain run. If the new-items set contains two notifications for the same
PR/issue, dispatch the first one and `workmux send <handle>` the second
after `workmux add` returns — the handle exists synchronously once the
command completes.

**Hand-off discipline.** The dispatcher does NOT read code, write tests,
or reason about the PR/issue itself. It gathers context via `gh`, writes
the prompt, runs `workmux add`, records, and moves on. The worktree agent
does all the actual work. Re-read the "You are a dispatcher, not an
implementer" section of `/worktree` SKILL.md if you're tempted to
investigate.

### After handling each item

- Append a line to `processed.jsonl`:
  `{"id","updated_at","handle","action"}` where `action` is one of
  `sent`, `spawned`, `orphan`, or `skipped`.
- Do **not** mark the GitHub thread as read — leave that to the user's
  normal inbox flow. Local dedupe is `processed.jsonl`'s job.

## Related Skills

- **`/merge`**: commit, rebase, and merge the current branch
- **`/rebase`**: rebase with smart conflict resolution
- **`/worktree`**: delegate tasks to parallel worktree agents
- **`/coordinator`**: orchestrate multiple agents (spawn, monitor, merge)
- **`/open-pr`**: write PR description and open in browser
