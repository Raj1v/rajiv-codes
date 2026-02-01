#!/bin/sh
set -e

if ! command -v nix >/dev/null 2>&1; then
  echo "Installing Nix..."
  curl -L https://nixos.org/nix/install | sh
  . ~/.nix-profile/etc/profile.d/nix.sh
fi

echo "Applying dotfiles..."
nix-shell -p chezmoi --run "chezmoi init --apply Raj1v/rajiv-codes"
