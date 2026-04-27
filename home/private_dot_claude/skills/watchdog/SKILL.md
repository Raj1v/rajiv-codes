---
name: watchdog
description: Monitor a running worktree agent on a recurring interval. Check progress, flag rabbit holes, and send feedback if the agent drifts.
allowed-tools: Bash, CronCreate, CronDelete, Read
---

# Agent Watchdog

You monitor one or more running worktree agents. Your job is to
understand what each agent is trying to accomplish, then check in
periodically to ensure it stays on track, is efficient, and doesn't go
down rabbit holes.

Target: $ARGUMENTS

## Step 1 — Understand the agent

Before setting up monitoring, get oriented:

```bash
# What is the agent working on?
workmux status <handle>

# Read recent terminal output to understand its purpose and current state
workmux capture <handle> -n 200
```

From this output, determine:

1. **Goal**: What is the agent trying to accomplish?
2. **Approach**: What strategy is it using?
3. **Progress**: How far along is it?
4. **Health**: Is it stuck, looping, or going off-track?

Summarize this to the user before starting the monitoring loop.

## Step 2 — Set up the monitoring loop

Create a recurring cron job to check in on the agent. Default interval
is **7 minutes** unless the user specifies otherwise.

The cron prompt should instruct you to:

1. Run `workmux status <handle>` and `workmux capture <handle> -n 150`
2. Assess the agent on three dimensions (see "What to look for" below)
3. If off-track or inefficient, send feedback via `workmux send`
4. If the agent is done (`status=done`), report final state and delete
   the cron job
5. Give the user a brief status update each check-in

## What to look for

### Progress
- Is the agent making forward progress since last check?
- Has it committed or pushed changes?
- Is it moving toward the stated goal?

### Rabbit holes
- Is it investigating something tangential to the core task?
- Is it refactoring or "improving" code unrelated to the goal?
- Is it reading/exploring files that aren't relevant?
- Is it stuck in a loop — retrying the same failing approach?

### Efficiency
- Is it doing unnecessary work (e.g., running full test suites when only
  one test matters)?
- Is it over-engineering a solution when a simpler fix exists?
- Is it making multiple small commits when one would do?
- Is it re-reading files it already read?

## Sending feedback

When you spot an issue, send concise, actionable feedback:

```bash
workmux send <handle> "You're going down a rabbit hole investigating X. The actual issue is Y — focus on that instead."
workmux send <handle> "You've been stuck on this for 2 check-ins. Try a different approach: ..."
workmux send <handle> "This is over-engineered. A simpler fix would be ..."
```

Rules for feedback:
- Be direct and specific — say what's wrong and what to do instead
- Don't send feedback if the agent is on track — unnecessary messages
  break its flow
- If the agent is stuck, suggest a concrete alternative approach
- If the agent is done but missed something, point it out

## When the agent finishes

When `workmux status` shows `done`:

1. Capture final output: `workmux capture <handle> -n 100`
2. Assess whether the goal was achieved
3. Report the outcome to the user
4. Delete the monitoring cron job with `CronDelete`

## Flags

**`--interval <minutes>`**: Override the default 7-minute check-in
interval.

**`--strict`**: Lower the threshold for sending feedback — call out
even minor inefficiencies.

**`--quiet`**: Only report to the user when there's a problem or the
agent finishes. Skip routine "on track" updates.

## Multiple agents

If given multiple handles (space-separated), monitor all of them in a
single cron job. Report status for each agent at every check-in.

```
/watchdog agent-a agent-b agent-c
```
