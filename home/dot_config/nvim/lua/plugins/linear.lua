local dir = vim.fn.expand("~/repos/linear-nvim")
if vim.fn.isdirectory(dir) == 0 then
  return {}
end

return {
  "rmanocha/linear-nvim",
  dir = dir,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "stevearc/dressing.nvim",
  },
  config = function()
    require("linear-nvim").setup()
  end,
  keys = {
    {
      "<leader>lm",
      function()
        require("linear-nvim").show_assigned_issues()
      end,
      desc = "Linear: My Issues",
    },
    {
      "<leader>lc",
      function()
        require("linear-nvim").create_issue()
      end,
      desc = "Linear: Create Issue",
    },
    {
      "<leader>lt",
      function()
        require("linear-nvim").show_team_issues()
      end,
      desc = "Linear: Team Issues",
    },
  },
}
