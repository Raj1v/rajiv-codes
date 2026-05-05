return {
  "pwntester/octo.nvim",
  cmd = "Octo",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "folke/snacks.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    picker = "snacks",
  },
  keys = {
    { "<leader>gi", "<cmd>Octo issue list<cr>", desc = "Octo: issues" },
    { "<leader>gp", "<cmd>Octo pr list<cr>", desc = "Octo: PRs" },
  },
}
