Check chezmoi sync status and resolve any mismatches.

## Steps

1. Run `chezmoi status` to check for file mismatches between source and home
2. Run `git -C $(chezmoi source-path) fetch --quiet origin 2>/dev/null` then check:
   - `git status --porcelain` for uncommitted changes
   - `git rev-list --count @{u}..HEAD` for unpushed commits
   - `git rev-list --count HEAD..@{u}` for commits behind origin
3. Report findings to the user clearly:
   - For each file in `chezmoi status`, explain the mismatch direction (MM = modified in both, " M" = source changed, "M " = home changed)
   - Show any git sync issues (dirty, unpushed, behind)
4. If there are file mismatches, run `chezmoi diff` to show the actual differences
5. Ask the user what to do for each mismatch. Common actions:
   - **Apply** (`chezmoi apply <file>`): overwrite a home file with source version
   - **Re-add** (`chezmoi re-add <file>`): update source to match a home file
   - **Apply all** (`chezmoi apply`): apply all non-conflicting changes at once
   - **Re-add all** (`chezmoi re-add`): re-add all changed home files to source
6. If there are git issues, offer to commit and/or push changes

## Non-interactive shell constraints
- The Bash tool has no TTY/stdin, so chezmoi commands that prompt will fail
- For MM (modified in both) conflicts: show the diff, get user confirmation in chat, then run `chezmoi apply --force <specific-file>` or `chezmoi re-add <specific-file>` on only the approved files
- Only use `--force` on individual files the user has explicitly approved, never on a blanket `chezmoi apply --force`
- Non-conflicting operations (`chezmoi re-add`, `chezmoi status`, `chezmoi diff`) work fine without flags

## Important
- The chezmoi source directory is this repo: `~/repos/rajiv-codes`
- Managed files live under `home/` with chezmoi naming (e.g. `dot_config` -> `.config`)
- Always show the diff and ask which direction to resolve before taking action
