local M = {}

M.parsers = {
  "lua",
  "luadoc",
  "printf",
  "vim",
  "vimdoc",
  "markdown",
  "markdown_inline",
}

function M.setup()
  require("nvim-treesitter").setup({
    install_dir = vim.fn.stdpath("data") .. "/site",
  })
end

function M.install_parsers()
  local ok, err = pcall(function()
    require("nvim-treesitter").install(M.parsers):wait(300000)
  end)
  if not ok then
    vim.notify("treesitter parser install: " .. tostring(err), vim.log.levels.WARN)
  end
end

return M
