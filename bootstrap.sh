#!/bin/sh
set -e

# Install Homebrew if not present
if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv 2>/dev/null || /opt/homebrew/bin/brew shellenv)"
fi

# Install chezmoi if not present
if ! command -v chezmoi >/dev/null 2>&1; then
  echo "Installing chezmoi..."
  brew install chezmoi
fi

# Apply dotfiles (triggers run_onchange scripts to install everything else)
echo "Applying dotfiles..."
chezmoi init --apply --ssh Raj1v/rajiv-codes
