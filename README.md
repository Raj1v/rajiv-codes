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
| Nix | bootstrap.sh |
| chezmoi | Nix |
| oh-my-zsh | chezmoi run_once script |
| nvim config | chezmoi dotfiles |
| gitconfig | chezmoi dotfiles |

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
