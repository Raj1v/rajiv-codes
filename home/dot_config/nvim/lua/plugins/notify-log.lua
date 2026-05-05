vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    local log_path = vim.fn.stdpath("state") .. "/notify.log"
    local levels = { [0] = "TRACE", [1] = "DEBUG", [2] = "INFO", [3] = "WARN", [4] = "ERROR" }
    local orig = vim.notify
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.notify = function(msg, level, opts)
      local lvl = type(level) == "number" and (levels[level] or tostring(level)) or tostring(level or "INFO")
      local text = type(msg) == "string" and msg or vim.inspect(msg)
      local f = io.open(log_path, "a")
      if f then
        f:write(string.format("[%s] %s | %s\n", os.date("%Y-%m-%d %H:%M:%S"), lvl, text))
        f:close()
      end
      return orig(msg, level, opts)
    end
  end,
})

return {}
