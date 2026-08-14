-- Text-only statusline modules (no nerd-font glyphs).
local utils = require("nvchad.stl.utils")

local function bufnr()
  return utils.stbufnr()
end

return {
  separator_style = { left = "", right = "" },
  modules = {
    mode = function()
      if not utils.is_activewin() then
        return ""
      end

      local m = vim.api.nvim_get_mode().mode
      local modes = utils.modes
      return "%#St_" .. modes[m][2] .. "Mode# " .. modes[m][1] .. " "
    end,

    file = function()
      local path = vim.api.nvim_buf_get_name(bufnr())
      local name = (path == "" and "Empty") or path:match "([^/\\]+)[/\\]*$" or path
      return "%#St_file# " .. name .. " "
    end,

    git = function()
      local nr = bufnr()
      if not vim.b[nr].gitsigns_head or vim.b[nr].gitsigns_git_status then
        return ""
      end

      local status = vim.b[nr].gitsigns_status_dict
      local added = (status.added and status.added ~= 0) and (" +" .. status.added) or ""
      local changed = (status.changed and status.changed ~= 0) and (" ~" .. status.changed) or ""
      local removed = (status.removed and status.removed ~= 0) and (" -" .. status.removed) or ""

      return "%#St_gitIcons# " .. status.head .. added .. changed .. removed .. " "
    end,

    lsp_msg = function()
      return ""
    end,

    diagnostics = function()
      if not rawget(vim, "lsp") then
        return ""
      end

      local nr = bufnr()
      local err = #vim.diagnostic.get(nr, { severity = vim.diagnostic.severity.ERROR })
      local warn = #vim.diagnostic.get(nr, { severity = vim.diagnostic.severity.WARN })
      local hints = #vim.diagnostic.get(nr, { severity = vim.diagnostic.severity.HINT })
      local info = #vim.diagnostic.get(nr, { severity = vim.diagnostic.severity.INFO })

      err = (err > 0) and ("%#St_lspError# E:" .. err .. " ") or ""
      warn = (warn > 0) and ("%#St_lspWarning# W:" .. warn .. " ") or ""
      hints = (hints > 0) and ("%#St_lspHints# H:" .. hints .. " ") or ""
      info = (info > 0) and ("%#St_lspInfo# I:" .. info .. " ") or ""

      return err .. warn .. hints .. info
    end,

    lsp = function()
      if not rawget(vim, "lsp") then
        return ""
      end

      for _, client in ipairs(vim.lsp.get_clients()) do
        if client.attached_buffers[bufnr()] then
          return (vim.o.columns > 100 and (" LSP:" .. client.name .. " ")) or " LSP "
        end
      end

      return ""
    end,

    cwd = function()
      if vim.o.columns <= 85 then
        return ""
      end

      local name = vim.uv.cwd()
      name = name:match "([^/\\]+)[/\\]*$" or name
      return "%#St_cwd_text# " .. name .. " "
    end,

    cursor = "%#St_pos_text# %l:%c ",
  },
}
