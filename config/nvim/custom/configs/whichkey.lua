local wk = require("which-key")

wk.add({
  { "<leader>f", group = "find" },
  { "<leader>g", group = "git" },
  { "<leader>x", group = "trouble" },
  { "<leader>w", group = "workspace" },
  { "<leader>m", group = "markdown" },
  { "<leader>c", group = "chad / code" },
  { "<leader>p", group = "python / paste" },
  {
    "<leader>?",
    function()
      require("custom.cheatsheet").open()
    end,
    desc = "IDE cheat sheet",
  },
  {
    "<leader>ch",
    "<cmd>NvCheatsheet<CR>",
    desc = "NvChad cheatsheet",
  },
})
