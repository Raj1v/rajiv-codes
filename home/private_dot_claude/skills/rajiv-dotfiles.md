# Rajiv's Dotfiles Setup

## Location
- **Monorepo:** `~/repos/rajiv-codes/home/`
- **Nvim config:** `~/repos/rajiv-codes/home/dot_config/nvim/`
- **Plugins directory:** `~/repos/rajiv-codes/home/dot_config/nvim/lua/plugins/`

## Structure
Uses **chezmoi** for dotfile management:
- `dot_config/` maps to `~/.config/`
- Files are synced via `chezmoi apply`

## Neovim Setup
- **Plugin manager:** lazy.nvim
- **Distribution:** LazyVim
- **Existing plugins:** avante.lua, linear.lua, snacks.lua, minuet.lua

## Workflow
1. Edit files in `~/repos/rajiv-codes/home/dot_config/nvim/`
2. Run `chezmoi apply` to sync to `~/.config/nvim/`
3. Run `:Lazy sync` in Neovim to install/update plugins

## Important
- Always write nvim config changes to the monorepo path, NOT directly to `~/.config/nvim/`
- The `~/.config/nvim/` directory is managed by chezmoi and should not be edited directly
