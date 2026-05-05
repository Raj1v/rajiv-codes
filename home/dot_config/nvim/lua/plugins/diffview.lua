return {
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles" },
    keys = {
      { "<leader>gv", "<cmd>DiffviewOpen origin/main...HEAD<cr>", desc = "Diff vs main (PR view)" },
      { "<leader>gV", "<cmd>DiffviewClose<cr>", desc = "Close diffview" },
      { "<leader>gH", "<cmd>DiffviewFileHistory %<cr>", desc = "File history (current file)" },
    },
  },
}
