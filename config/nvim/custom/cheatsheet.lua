-- curated IDE cheat sheet (fff, harpoon, lsp, …)
local M = {}

M.sections = {
  {
    title = "Help",
    rows = {
      { "<leader>?", "this cheat sheet" },
      { "<leader>ch", "NvChad cheatsheet" },
      { "<leader> …", "which-key popup (wait)" },
    },
  },
  {
    title = "Find (fff)",
    rows = {
      { "<leader>ff", "fuzzy find files" },
      { "<leader>fw", "live grep" },
      { "<leader>fz", "fuzzy live grep" },
      { "<leader>fW", "grep word / selection" },
    },
  },
  {
    title = "Harpoon",
    rows = {
      { "<leader>a", "add file" },
      { "<C-e>", "harpoon menu" },
      { "<leader>1-4", "jump to mark 1-4" },
    },
  },
  {
    title = "Files / buffers",
    rows = {
      { "-", "oil: edit parent dir" },
      { "<C-n>", "nvim-tree toggle" },
      { "<leader>e", "nvim-tree focus" },
      { "<leader>v / h", "vsplit / split" },
      { "<Tab> / <S-Tab>", "next / prev buffer tab" },
      { "<leader>bx", "close buffer tab" },
    },
  },
  {
    title = "LSP",
    rows = {
      { "gd / gD", "definition / declaration" },
      { "gr", "references" },
      { "gI", "implementation" },
      { "K", "hover" },
      { "<leader>ra", "rename" },
      { "<leader>ca", "code action" },
      { "[d / ]d", "prev / next diagnostic" },
      { "<leader>xx", "trouble diagnostics" },
      { "<leader>pv", "pick python env (or :PythonEnv)" },
      { ":TSStart", "force treesitter highlight" },
    },
  },
  {
    title = "Git / undo",
    rows = {
      { "<leader>gs", "fugitive status" },
      { "<leader>u", "undotree toggle" },
    },
  },
  {
    title = "Edit",
    rows = {
      { "ys / cs / ds", "surround add / change / delete" },
      { "<leader>/", "toggle comment" },
      { "<leader>s", "replace word in file" },
      { "<leader>y", "yank to system clipboard" },
      { "<leader>p", "paste without yank (visual)" },
    },
  },
  {
    title = "Markdown",
    rows = {
      { "<leader>m1-3", "H1 / H2 / H3" },
      { "<leader>md", "toggle render-markdown" },
    },
  },
}

function M.lines()
  local out = { "  NEOVIM IDE CHEAT SHEET  (q / <Esc> close)", "" }
  for _, section in ipairs(M.sections) do
    out[#out + 1] = "  " .. section.title
    out[#out + 1] = "  " .. string.rep("─", 40)
    for _, row in ipairs(section.rows) do
      out[#out + 1] = string.format("  %-14s  %s", row[1], row[2])
    end
    out[#out + 1] = ""
  end
  return out
end

function M.open()
  local lines = M.lines()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "cheatsheet"

  local width = math.min(56, vim.o.columns - 4)
  local height = math.min(#lines + 1, vim.o.lines - 4)
  local row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1)
  local col = math.max(0, math.floor((vim.o.columns - width) / 2))

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " cheat sheet ",
    title_pos = "center",
  })
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true

  local close = function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })
end

return M
