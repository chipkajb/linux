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

--- herdr and SSH panes have no usable local xclip; herdr intercepts OSC 52 from the pane PTY.
local function use_osc52()
  if in_herdr() then
    return true
  end
  if on_remote_ssh() then
    return true
  end
  return not has_x11_display()
end

local function write_osc52_seq(seq)
  if in_herdr() or in_tmux() then
    local fd = io.open("/dev/tty", "w")
    if fd then
      fd:write(seq)
      fd:close()
      return true
    end
  end

  if in_tmux() and not in_herdr() then
    local tty = vim.fn.system('tmux display -p "#{client_tty}"'):gsub("%s+", "")
    if tty ~= "" then
      local fd = io.open(tty, "w")
      if fd then
        fd:write(seq)
        fd:close()
        return true
      end
    end
  end

  return false
end

local function osc52_write(text)
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
end

return M
