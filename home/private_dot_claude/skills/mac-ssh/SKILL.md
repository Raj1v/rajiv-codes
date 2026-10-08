---
name: mac-ssh
description: Run commands on Rajiv's Mac from this devbox over SSH (Tailscale). Use when a task needs the Mac itself — macOS-only tools, Xcode/iOS simulator, Mac apps, files that live on the Mac — or when Rajiv says "ssh into my mac" or "use my mac".
allowed-tools: Bash
---

# SSH to Rajiv's Mac

```sh
ssh rajiv@100.84.27.10 '<command>'
```

Always the IP, never the MagicDNS name.

## Only up while he runs `agent-ssh`

Full access exists only while Rajiv has `agent-ssh` running in a terminal on the Mac; Ctrl-C revokes it. Without it, the devbox key falls back to the e2e gate, which allows only `maestro …`, `xcrun simctl …` and maestro rsync.

- Output `denied: <command>` → no grant. Ask Rajiv to run `agent-ssh` on the Mac, then retry. Don't try to work around the gate.
- Timeout / connection refused → Mac asleep, offline, or Tailscale down. Ask him.

Check before a longer job:

```sh
ssh -o ConnectTimeout=5 rajiv@100.84.27.10 'echo ok'
```

## Rules

- It's his personal Mac with his real accounts and files. Read freely; ask before deleting, moving, or overwriting anything, installing software (no `brew install` without explicit permission), or changing system settings.
- Use `pnpm`, never `npm`.
- The grant can disappear mid-task. Prefer short, idempotent commands; run long jobs in `tmux` on the devbox side, not detached on the Mac.
- Copy files with `scp`/`rsync` against the same host, e.g. `rsync -av rajiv@100.84.27.10:~/path ./`.
