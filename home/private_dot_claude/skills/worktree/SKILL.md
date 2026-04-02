---
name: worktree
description: Launch one or more tasks in new git worktrees using workmux.
disable-model-invocation: true
allowed-tools: Bash, Write
---

Launch one or more tasks in new git worktrees using workmux.

Tasks: $ARGUMENTS

## You are a dispatcher, not an implementer

**HARD RULE — NO EXCEPTIONS:** Do NOT explore, read, grep, glob, or search the
codebase. Do NOT use the Task/Explore agent. Do NOT investigate the problem. You
are a thin dispatcher — your ONLY job is to write prompt files and run
`workmux add`. The worktree agent will do all the exploration and implementation.

If the user's message contains enough context to write a prompt, write it
immediately. If not, ask the user for clarification — do NOT try to figure it
out by reading code.

If tasks reference earlier conversation (e.g., "do option 2"), include all
relevant context in each prompt you write.

If tasks reference a markdown file (e.g., a plan or spec), re-read the file to
ensure you have the latest version before writing prompts.

For each task:

1. Generate a short, descriptive worktree name (2-4 words, kebab-case)
2. Write a detailed implementation prompt to a temp file
3. Run `workmux add <worktree-name> -b -P <temp-file>` to create the worktree

The prompt file should:

- Include the full task description
- Use RELATIVE paths only (never absolute paths, since each worktree has its own
  root directory)
- Be specific about what the agent should accomplish
- Include this instruction at the top: `Before starting, run: source .env.workmux 2>/dev/null && gh auth setup-git && git fetch origin main && git rebase origin/main && pnpm install`

## Skill delegation

If the user passes a skill reference (e.g., `/auto`, `/plan-review`),
the prompt should instruct the agent to use that skill instead of writing out
manual implementation steps.

**Skills can have flags.** If the user passes `/auto --gemini`, pass the
flag through to the skill invocation in the prompt.

Example prompt:
```
[Task description here]

Use the skill: /skill-name [flags if any] [task description]
```

Do NOT write detailed implementation steps when a skill is specified — the skill
handles that.

## Flags

**`--pr`**: When passed, add instruction to open a pull request when done,
monitor CI, and poll for review comments. Append to the prompt:

```
When you are done, commit your changes and open a pull request using `gh pr create`.
After opening the PR, use `/loop 5m check PR CI status with gh pr checks. If any checks failed, investigate the failure, fix it, and push again.`
Then use `/loop 20m check for PR reviews from Rajiv using gh pr reviews and gh pr view --comments. If there are new review comments from Rajiv that have not been addressed yet, address each comment: make the requested changes, commit, and push. After addressing all comments, leave a reply on each resolved comment thread confirming the fix.`
```

**`--branch`**: When passed, the worktree branches off the current branch
instead of main. Add `--base <current-branch>` to the `workmux add` command.
If not passed, the default base is main (configured via `base_branch` in
`.workmux.yaml`).

**`--merge`**: When passed, add instruction to use `/merge` skill at the end to
commit, rebase, and merge the branch.

```
...
Then use the /merge skill to commit, rebase, and merge the branch.
```

## Workflow

Write ALL temp files first, THEN run all workmux commands.

Step 1 - Write all prompt files (in parallel):

```bash
tmpfile=$(mktemp).md
cat > "$tmpfile" << 'EOF'
Implement feature X...
EOF
echo "$tmpfile"  # Note the path for step 2
```

Step 2 - After ALL files are written, run workmux commands (in parallel):

```bash
workmux add feature-x -b -P /tmp/tmp.abc123.md
workmux add feature-y -b -P /tmp/tmp.def456.md
```

After creating the worktrees, inform the user which branches were created.

**Remember:** Your task is COMPLETE once worktrees are created. Do NOT implement
anything yourself.
