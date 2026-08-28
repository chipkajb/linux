-- Kill nerd-font / private-use glyphs (rects + CJK mojibake without a patched font).
local M = {}

local ascii_kinds = {
  Array = "[] ",
  Boolean = "B ",
  Class = "C ",
  Constant = "k ",
  Constructor = "cn ",
  Enum = "E ",
  EnumMember = "em ",
  Event = "ev ",
  Field = "f ",
  File = "F ",
  Function = "fn ",
  Interface = "I ",
  Key = "K ",
  Method = "m ",
  Module = "M ",
  Namespace = "ns ",
  Null = "? ",
  Number = "# ",
  Object = "{} ",
  Operator = "op ",
  Package = "pkg ",
  Property = "p ",
  String = "s ",
  Struct = "S ",
  TypeParameter = "T ",
  Variable = "v ",
}

-- Call AFTER NvChad lsp defaults() — that overwrites signs/virtual_text with nerd glyphs.
function M.diagnostic_signs()
  local x = vim.diagnostic.severity
  vim.diagnostic.config({
    virtual_text = { prefix = "•" },
    signs = {
      text = {
        [x.ERROR] = "E",
        [x.WARN] = "W",
        [x.INFO] = "I",
        [x.HINT] = "H",
      },
    },
    underline = true,
    float = { border = "single" },
  })
end

function M.neuter_devicons()
  local ok, di = pcall(require, "nvim-web-devicons")
  if not ok then
    return
  end
  -- return ASCII so tabufline `if devicon then` uses this instead of nerd fallback
  local function ascii_icon()
    return "-", "DevIconDefault"
  end
  di.setup({ color_icons = false, default = true })
  di.get_icon = ascii_icon
  di.get_icon_by_filetype = ascii_icon
  if di.get_icon_with_highlight_group then
    di.get_icon_with_highlight_group = function()
      return "-", "DevIconDefault", "DevIconDefault"
    end
  end
end

-- Tabufline hardcodes nerd close/modified glyphs — replace style_buf.
function M.patch_tabufline()
  local ok, utils = pcall(require, "nvchad.tabufline.utils")
  if not ok then
    return
  end
  local api = vim.api
  local get_opt = api.nvim_get_option_value
  local strep = string.rep
  local cur_buf = api.nvim_get_current_buf
  local buf_name = api.nvim_buf_get_name
  local get_hl = api.nvim_get_hl
  local btn = utils.btn
  local txt = utils.txt

  local function filename(str)
    return str:match("([^/\\]+)[/\\]*$")
  end

  local function new_hl(group1, group2)
    local fg = get_hl(0, { name = group1 }).fg
    local bg = get_hl(0, { name = "Tb" .. group2 }).bg
    api.nvim_set_hl(0, group1 .. group2, { fg = fg, bg = bg })
    return "%#" .. group1 .. group2 .. "#"
  end

  local function gen_unique_name(name, index)
    for i2, nr2 in ipairs(vim.t.bufs or {}) do
      local filepath = filename(buf_name(nr2))
      if index ~= i2 and filepath == name then
        return vim.fn.fnamemodify(buf_name(vim.t.bufs[index]), ":h:t") .. "/" .. name
      end
    end
  end

  utils.style_buf = function(nr, i, w)
    local is_curbuf = cur_buf() == nr
    local tbHlName = "BufO" .. (is_curbuf and "n" or "ff")
    local name = filename(buf_name(nr))
    name = name and (gen_unique_name(name, i) or name) or " No Name "

    local maxname_len = w - 5
    name = string.sub(name, 1, maxname_len - 2) .. (#name > maxname_len and ".." or "")
    name = txt(name, tbHlName)

    local pad = math.floor((w - #name - 5) / 2)
    pad = pad <= 0 and 1 or pad
    -- no file-type icon
    name = strep(" ", pad) .. name .. strep(" ", pad)

    local close_btn = btn(" x ", nil, "KillBuf", nr)
    name = btn(name, nil, "GoToBuf", nr)

    local mod = get_opt("mod", { buf = nr })
    local cur_mod = get_opt("mod", { buf = 0 })
    if is_curbuf then
      close_btn = cur_mod and txt(" * ", "BufOnModified") or txt(close_btn, "BufOnClose")
    else
      close_btn = mod and txt(" * ", "BufOffModified") or txt(close_btn, "BufOffClose")
    end

    name = txt(name .. close_btn, "BufO" .. (is_curbuf and "n" or "ff"))
    return name
  end
end

function M.trouble_icons()
  return {
    indent = {
      top = "| ",
      middle = "|-",
      last = "+-",
      fold_open = "v ",
      fold_closed = "> ",
      ws = "  ",
    },
    folder_closed = "[+] ",
    folder_open = "[-] ",
    kinds = ascii_kinds,
  }
end

function M.nvim_tree_icons()
  return {
    show = {
      file = false,
      folder = true,
      folder_arrow = true,
      git = false,
    },
    glyphs = {
      default = "",
      symlink = "",
      folder = {
        default = "+",
        open = "-",
        empty = "+",
        empty_open = "-",
        symlink = "+",
        symlink_open = "-",
        arrow_open = "v",
        arrow_closed = ">",
      },
      git = {
        unstaged = "~",
        staged = "+",
        unmerged = "!",
        renamed = ">",
        untracked = "?",
        deleted = "-",
        ignored = ".",
      },
    },
  }
end

function M.apply()
  M.diagnostic_signs()
  M.neuter_devicons()
  M.patch_tabufline()
end

return M
