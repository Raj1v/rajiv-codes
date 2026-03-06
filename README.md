# Personal Monorepo

A home for all Rajiv's configurations.

## Prerequisites (install manually)

### macOS
```bash
xcode-select --install   # git, curl, etc.
```

### Linux
```bash
sudo apt install git curl zsh
chsh -s $(which zsh)     # set zsh as default shell
```

## Bootstrap

Fresh machine? One command:

```bash
curl -sL https://raw.githubusercontent.com/Raj1v/rajiv-codes/main/bootstrap.sh | sh
```

## What gets installed

| Tool | How |
|------|-----|
| Homebrew | bootstrap.sh |
| oh-my-zsh | bootstrap.sh |
| chezmoi | Homebrew |
| 1Password CLI | Homebrew |
| fzf | Homebrew |
| zoxide | Homebrew |
| uv | Homebrew |
| lsd | Homebrew |
| workmux | Homebrew |
| nvim config | chezmoi dotfiles |
| gitconfig | chezmoi dotfiles |
| zshrc | chezmoi dotfiles |

## Secrets

Create a `~/.secrets` file (not tracked in git) with your tokens:

```bash
export GITHUB_TOKEN="your-token"
export LINEAR_API_KEY="your-key"
export SENTRY_AUTH_TOKEN="your-token"
```

The zshrc will source this file if it exists.

## Not managed (install via Homebrew/apt)

- [ ] neovim
- [ ] zsh (Linux only, macOS has it)
- [ ] git (Linux only)

## Plans

- [ ] DNS Management of rajiv.codes
- [ ] Declarative configurations of tools
  - Nix Packages
  - Terminal etc
- [ ] Add nix-darwin for Homebrew management
