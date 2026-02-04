-- Hide tmux status bar while nvim is open
if vim.env.TMUX then
  vim.fn.system("tmux set status off")
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      vim.fn.system("tmux set status on")
    end,
  })
end

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
