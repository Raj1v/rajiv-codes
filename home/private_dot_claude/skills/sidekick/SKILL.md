---
name: sidekick
description: Launch one or more tasks in a new tmux pane in the current window, sharing the same worktree.
disable-model-invocation: true
allowed-tools: Bash, Write
---

Launch one or more tasks as sidekick agents in new tmux panes alongside the
current one. Same git worktree, same working directory — just a fresh pane
running Claude on the given prompt.

Tasks: $ARGUMENTS

## You are a dispatcher, not an implementer

**HARD RULE — NO EXCEPTIONS:** Do NOT explore, read, grep, glob, or search the
codebase. Do NOT use the Task/Explore agent. Do NOT investigate the problem.
You are a thin dispatcher — your ONLY job is to write prompt files and run
`tmux split-window`. The sidekick agent will do all the exploration and
implementation.

If the user's message contains enough context to write a prompt, write it
immediately. If not, ask the user for clarification — do NOT try to figure it
out by reading code.

If tasks reference earlier conversation (e.g., "do option 2"), include all
relevant context in each prompt you write — the sidekick sees nothing of this
conversation.

If tasks reference a markdown file (e.g., a plan or spec), re-read the file
to ensure you have the latest version before writing prompts.

## Why this differs from /worktree

`/worktree` creates a fresh git worktree on a new branch. `/sidekick` does
NOT — it spawns a pane in the same window, same working directory, same
branch. Use it when you want a parallel agent that:

- Works on the same files you're working on
- Should see your uncommitted changes
- Doesn't need branch isolation (read-only investigation, codegen scratch,
  running long commands, drafting docs alongside your edits)

If branch isolation matters, use `/worktree` instead.

## Workflow

For each task:

1. Write a detailed implementation prompt to a temp file.
2. Run `tmux split-window` with `claude "$(cat <file>)"` to spawn the pane.

Write ALL prompt files first, THEN run all `tmux split-window` commands in
parallel.

### Step 1 — write prompt files

```bash
tmpfile=$(mktemp --suffix=.md)
cat > "$tmpfile" << 'EOF'
[detailed prompt here]
EOF
echo "$tmpfile"
```

### Step 2 — spawn panes

```bash
tmux split-window -d -h -t "$TMUX_PANE" -c "$PWD" "claude \"\$(cat /tmp/tmp.abc123.md)\""
```

Flags used:
- `-t "$TMUX_PANE"` — **target the dispatcher's own pane**, not whichever
  pane happens to be active. tmux sets `$TMUX_PANE` in every pane; without
  this, switching windows mid-task causes the sidekick to spawn in the
  wrong window.
- `-d` — do not switch focus to the new pane (user keeps working)
- `-h` — horizontal split (side-by-side); use `-v` for top/bottom
- `-c "$PWD"` — start in the current directory
- The command runs `claude` with the prompt file's content as its first
  argument, opening an interactive session pre-seeded with the prompt.

If `$TMUX_PANE` is empty (the dispatcher isn't running inside tmux), stop
and tell the user — `/sidekick` requires a tmux session.

## Prompt content

The prompt file should:

- Include the full task description (the sidekick sees no prior context).
- Use RELATIVE paths — the sidekick starts in the same `$PWD` as you.
- Be specific about what the agent should accomplish.
- State whether the agent should commit/push or leave changes uncommitted.
  Default to **leave uncommitted** since you're sharing the worktree — let
  the user decide what to keep.

Do NOT include the worktree setup line from `/worktree` (no fetch/rebase/
install) — this is the same worktree, already set up.

## Skill delegation

If the user passes a skill reference (e.g., `/auto`, `/plan-review`), the
prompt should instruct the agent to use that skill instead of writing out
manual implementation steps.

**Skills can have flags.** If the user passes `/auto --gemini`, pass the
flag through to the skill invocation in the prompt.

Example prompt:
```
[Task description here]

Use the skill: /skill-name [flags if any] [task description]
```

## Flags

**`--horizontal`** (or **`-v`**): split top/bottom instead of side-by-side.
Pass `-v` to `tmux split-window` instead of `-h`.

**`--focus`**: switch focus to the new pane. Omit the `-d` flag.

**`--read-only`**: append to the prompt:

```
Do not modify any files. Investigate and report findings only.
```

Use this for sidekicks that should investigate alongside the user without
risking conflicting edits in the shared worktree.

## After spawning

Tell the user which pane(s) were created. Your task is COMPLETE once the
panes are spawned. Do NOT implement anything yourself.

## Related skills

- **`/worktree`**: spawn agents in isolated git worktrees on new branches.
- **`/workmux`**: full reference for workmux's worktree+tmux integration.
