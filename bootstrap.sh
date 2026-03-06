#!/bin/sh
set -e

# Install Nix if not present
if ! command -v nix >/dev/null 2>&1; then
  echo "Installing Nix..."
  curl -L https://nixos.org/nix/install | sh
  . ~/.nix-profile/etc/profile.d/nix.sh
fi

# Enable nix-command and flakes
mkdir -p ~/.config/nix
grep -q 'experimental-features' ~/.config/nix/nix.conf 2>/dev/null || \
  echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# Source nix in current shell
. ~/.nix-profile/etc/profile.d/nix.sh

# Install packages via Nix
echo "Installing packages..."
nix profile install nixpkgs#oh-my-zsh
NIXPKGS_ALLOW_UNFREE=1 nix profile install --impure nixpkgs#_1password-cli

# Set up oh-my-zsh symlink (Nix installs to store, need to link it)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  ln -s $(nix eval --raw nixpkgs#oh-my-zsh.outPath)/share/oh-my-zsh ~/.oh-my-zsh
fi

# Install TPM (Tmux Plugin Manager)
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  echo "Installing TPM..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# Apply dotfiles
echo "Applying dotfiles..."
nix-shell -p chezmoi --run "chezmoi init --apply Raj1v/rajiv-codes"
