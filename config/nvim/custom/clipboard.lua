local M = {}

local function has_x11_display()
  return vim.fn.exists("$DISPLAY") == 1 and vim.env.DISPLAY ~= nil and vim.env.DISPLAY ~= ""
end

local function in_herdr()
  return vim.env.HERDR_ENV ~= nil
end

local function in_tmux()
  return vim.env.TMUX ~= nil
end

local function on_remote_ssh()
  return vim.env.SSH_CONNECTION ~= nil or vim.env.SSH_CLIENT ~= nil
end

--- Remote/headless panes need OSC 52 so yanks reach the host clipboard (herdr bridges it).
--- Local herdr with DISPLAY can use xclip directly.
local function use_osc52()
  if on_remote_ssh() then
    return true
  end
  if in_herdr() and not has_x11_display() then
    return true
  end
  if in_herdr() and has_x11_display() then
    return false
  end
  return not has_x11_display()
end

local function osc52_tty()
  if in_tmux() then
    local tty = vim.fn.system('tmux display -p "#{client_tty}"'):gsub("%s+", "")
    if tty ~= "" then
      return tty
    end
  end

  if vim.env.TTY and vim.env.TTY ~= "" then
    return vim.env.TTY
  end

  return "/dev/tty"
end

local function write_osc52_seq(seq)
  local tty = osc52_tty()
  local fd = io.open(tty, "w")
  if fd then
    fd:write(seq)
    fd:close()
    return true
  end

  return false
end

local function osc52_write(text)
  if text == "" then
    return
  end

  local encoded = vim.base64.encode(text)
  local seq = string.format("\027]52;c;%s\027\\", encoded)

  if not write_osc52_seq(seq) then
    require("vim.ui.clipboard.osc52").copy(vim.split(text, "\n", { plain = true }), "+")
  end
end

local function osc52_copy(lines, _)
  osc52_write(table.concat(lines, "\n"))
end

local function osc52_paste()
  return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
end

--- Belt-and-suspenders: unnamedplus should call g.clipboard, but ensure every
--- y/yy/visual-y (etc.) reaches the host clipboard in herdr/SSH sessions.
local function setup_yank_autocmd()
  vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("CustomClipboardYank", { clear = true }),
    callback = function()
      if not use_osc52() then
        return
      end

      local event = vim.v.event
      if event.operator ~= "y" then
        return
      end

      local regname = event.regname
      if regname ~= "" and regname ~= "+" and regname ~= "*" then
        return
      end

      local text = vim.fn.getreg(regname == "" and "+" or regname)
      osc52_write(text)
    end,
  })
end

function M.setup()
  if use_osc52() then
    vim.g.clipboard = {
      name = in_herdr() and "OSC 52 (herdr)" or "OSC 52",
      copy = {
        ["+"] = osc52_copy,
        ["*"] = osc52_copy,
      },
      paste = {
        ["+"] = osc52_paste,
        ["*"] = osc52_paste,
      },
      cache_enabled = 0,
    }
  else
    vim.g.clipboard = {
      name = "xclip-quiet",
      copy = {
        ["+"] = { "xclip", "-quiet", "-i", "-selection", "clipboard" },
        ["*"] = { "xclip", "-quiet", "-i", "-selection", "primary" },
      },
      paste = {
        ["+"] = { "xclip", "-quiet", "-o", "-selection", "clipboard" },
        ["*"] = { "xclip", "-quiet", "-o", "-selection", "primary" },
      },
      cache_enabled = 1,
    }
  end

  setup_yank_autocmd()
end

return M
