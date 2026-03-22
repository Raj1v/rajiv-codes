#!/bin/sh
set -e

# Install Homebrew if not present
if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv 2>/dev/null || /opt/homebrew/bin/brew shellenv)"
fi

# Install packages
echo "Installing packages..."
brew install chezmoi fzf zoxide uv lsd raine/workmux/workmux 1password-cli sesh gum

# Install oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing oh-my-zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Install TPM (Tmux Plugin Manager)
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  echo "Installing TPM..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# Install nvm and Node.js
if [ ! -d "$HOME/.nvm" ]; then
  echo "Installing nvm..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
fi
export NVM_DIR="$HOME/.nvm"
. "$NVM_DIR/nvm.sh"
echo "Installing Node.js..."
nvm install 24
corepack enable pnpm

# Install Deno
if ! command -v deno >/dev/null 2>&1; then
  echo "Installing Deno..."
  curl -fsSL https://deno.land/install.sh | sh
fi

# Install fzf-tab oh-my-zsh plugin
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab" ]; then
  echo "Installing fzf-tab..."
  git clone https://github.com/Aloxaf/fzf-tab "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab"
fi

# Set zsh as default shell
if [ "$(basename "$SHELL")" != "zsh" ]; then
  echo "Setting zsh as default shell..."
  sudo chsh -s "$(which zsh)" "$(whoami)"
fi

# Apply dotfiles
echo "Applying dotfiles..."
chezmoi init --apply --ssh Raj1v/rajiv-codes
