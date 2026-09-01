local M = {}

local function env(name)
  local value = vim.env[name]
  if value == nil or value == "" then
    return nil
  end
  return value
end

local function has_x11_display()
  return env("DISPLAY") ~= nil
end

local function in_herdr()
  return env("HERDR_ENV") ~= nil
end

local function on_remote_ssh()
  return env("SSH_CONNECTION") ~= nil or env("SSH_CLIENT") ~= nil
end

--- Inside herdr, xclip is always wrong: panes inherit the herdr *server* environment,
--- which is detached from the desktop session and has no DISPLAY, and under
--- `herdr --remote` the X server would be the wrong machine anyway. OSC 52 travels
--- out through the pane to whichever client is attached, so herdr and SSH both use it.
local function use_osc52()
  return on_remote_ssh() or in_herdr() or not has_x11_display()
end

local function osc52_sequence(text)
  return string.format("\027]52;c;%s\027\\", vim.base64.encode(text))
end

--- Neovim's TUI has no controlling terminal, so io.open("/dev/tty") fails with ENXIO
--- and writing to stdout races the renderer. nvim_ui_send is the supported way to push
--- raw bytes to the attached UI.
local function send_to_terminal(text)
  local sequence = osc52_sequence(text)
  if pcall(vim.api.nvim_ui_send, sequence) then
    return
  end

  io.stdout:write(sequence)
  io.stdout:flush()
end

--- vim.ui.clipboard.osc52.copy is curried: copy(reg) returns the function that takes
--- lines. Calling it with the lines directly returns an unused closure and copies nothing.
local function osc52_copier(register)
  local ok, builtin = pcall(require, "vim.ui.clipboard.osc52")
  if ok and type(builtin.copy) == "function" then
    local writer = builtin.copy(register)
    if type(writer) == "function" then
      return writer
    end
  end

  return function(lines)
    send_to_terminal(table.concat(lines, "\n"))
  end
end

--- Terminals answer OSC 52 reads inconsistently and a query can block for ten seconds,
--- so serve pastes from the unnamed register instead (the recipe in :h clipboard-osc52).
local function register_paste()
  return { vim.fn.split(vim.fn.getreg('"'), "\n"), vim.fn.getregtype('"') }
end

--- Safety net for when 'clipboard' loses unnamedplus (a plugin or a stray :set), which
--- would otherwise leave y/yy/visual-y touching only the unnamed register.
local function setup_yank_autocmd(copy_to_clipboard)
  vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("CustomClipboardYank", { clear = true }),
    callback = function()
      local event = vim.v.event
      if event.operator ~= "y" then
        return
      end

      if vim.o.clipboard:find("unnamedplus", 1, true) then
        return
      end

      local regname = event.regname
      if regname ~= "" and regname ~= "+" and regname ~= "*" then
        return
      end

      local text = vim.fn.getreg(regname == "" and '"' or regname)
      if text ~= "" then
        copy_to_clipboard(vim.split(text, "\n", { plain = true }))
      end
    end,
  })
end

function M.setup()
  local copy_to_clipboard

  if use_osc52() then
    local copy_clipboard = osc52_copier("+")
    local copy_primary = osc52_copier("*")
    copy_to_clipboard = copy_clipboard

    vim.g.clipboard = {
      name = in_herdr() and "OSC 52 (herdr)" or "OSC 52",
      copy = {
        ["+"] = copy_clipboard,
        ["*"] = copy_primary,
      },
      paste = {
        ["+"] = register_paste,
        ["*"] = register_paste,
      },
      cache_enabled = 0,
    }
  else
    copy_to_clipboard = function(lines)
      vim.fn.system({ "xclip", "-quiet", "-i", "-selection", "clipboard" }, table.concat(lines, "\n"))
    end

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

  setup_yank_autocmd(copy_to_clipboard)
end

return M
