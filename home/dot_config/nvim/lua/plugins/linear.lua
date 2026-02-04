return {
  "rmanocha/linear-nvim",
  dir = "~/repos/linear-nvim",
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
