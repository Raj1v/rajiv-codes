Update dotfiles: edit on filesystem, test, apply to chezmoi, commit and push.

## Arguments

$ARGUMENTS: Description of what to change (e.g. "add alias ll='lsd -la' to zshrc", "update tmux prefix to C-a"). If empty, check for existing filesystem changes.

## Workflow

### 1. Identify the target file(s)

- Map the user's request to the relevant dotfile(s) in `~/` (e.g. `~/.zshrc`, `~/.tmux.conf`, `~/.gitconfig`, `~/.config/nvim/...`)
- Read the current file on the filesystem to understand context

### 2. Make the edit on the filesystem

- Edit the **live file** directly (e.g. `~/.zshrc`, NOT `home/dot_zshrc`)
- This lets the user test immediately without chezmoi apply

### 3. Test with the user

- Tell the user what was changed and how to test it:
  - For shell config: "Run `source ~/.zshrc` or open a new terminal to test"
  - For tmux: "Run `tmux source ~/.tmux.conf` to reload"
  - For nvim: "Restart nvim to pick up changes"
  - For git config: changes take effect immediately
- Ask the user to confirm the change works before proceeding
- **STOP HERE and wait for user confirmation.** Do NOT proceed to step 4 until the user says it's good.

### 4. Apply to chezmoi source

- Run `chezmoi re-add <file>` to update the source repo to match the live file
- Verify with `chezmoi diff` that there are no remaining mismatches for that file

### 5. Commit and push

- Stage the changed file(s) in the chezmoi source repo
- Create a descriptive commit (e.g. "zshrc: add ll alias")
- Push to origin

### 6. Check for other drifted files

- Run the `/chezmoi-sync` skill to check for any other outstanding mismatches
- Report findings to the user

## Chezmoi path mapping

| Filesystem path | Source path (in repo) |
|---|---|
| `~/.zshrc` | `home/dot_zshrc` |
| `~/.gitconfig` | `home/dot_gitconfig` |
| `~/.tmux.conf` | `home/dot_tmux.conf` |
| `~/.config/nvim/...` | `home/dot_config/nvim/...` |
| `~/bin/...` | `home/bin/...` |

For other files, use `chezmoi source-path <file>` to find the mapping.

## Important

- Always edit the **live filesystem file first**, not the chezmoi source — this enables immediate testing
- Never proceed past step 3 without user confirmation that the change works
- The chezmoi source directory is this repo: `~/repos/rajiv-codes`
- Use `chezmoi re-add` (not manual copy) to sync filesystem → source
