-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("i", "<A-h>", "<C-o>b", { desc = "Move left by word" })
vim.keymap.set("i", "<A-l>", "<C-o>w", { desc = "Move right by word" })
