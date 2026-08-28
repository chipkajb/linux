local dap = require("dap")
local dapui = require("dapui")
local pyenv = require("custom.python_env")

-- Adapter = mason debugpy; debuggee python = conda/venv when present
local debugpy = pyenv.mason_debugpy()
if vim.fn.executable(debugpy) == 0 then
  vim.notify("debugpy missing — run :MasonInstall debugpy", vim.log.levels.WARN)
end
require("dap-python").setup(debugpy)
require("dap-python").resolve_python = function()
  return pyenv.detect(0) or "python3"
end

-- ASCII gutter signs (no nerd font)
vim.fn.sign_define("DapBreakpoint", { text = "B", texthl = "DiagnosticError", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointCondition", { text = "C", texthl = "DiagnosticWarn", linehl = "", numhl = "" })
vim.fn.sign_define("DapLogPoint", { text = "L", texthl = "DiagnosticInfo", linehl = "", numhl = "" })
vim.fn.sign_define("DapStopped", { text = ">", texthl = "DiagnosticWarn", linehl = "Visual", numhl = "" })
vim.fn.sign_define("DapBreakpointRejected", { text = "X", texthl = "DiagnosticError", linehl = "", numhl = "" })

dapui.setup({
  icons = { expanded = "v", collapsed = ">", current_frame = ">" },
  controls = {
    icons = {
      pause = "||",
      play = ">",
      step_into = "v",
      step_over = "->",
      step_out = "^",
      step_back = "<-",
      run_last = "R",
      terminate = "X",
      disconnect = "D",
    },
  },
})

dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end

-- F-keys (VS Code muscle memory) + <leader>d* (waits after <leader>d delete map)
local map = vim.keymap.set
map("n", "<F5>", dap.continue, { desc = "DAP continue" })
map("n", "<F9>", dap.toggle_breakpoint, { desc = "DAP toggle breakpoint" })
map("n", "<F10>", dap.step_over, { desc = "DAP step over" })
map("n", "<F11>", dap.step_into, { desc = "DAP step into" })
map("n", "<F12>", dap.step_out, { desc = "DAP step out" })

map("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP toggle breakpoint" })
map("n", "<leader>dB", function()
  dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "DAP conditional breakpoint" })
map("n", "<leader>dc", dap.continue, { desc = "DAP continue / start" })
map("n", "<leader>do", dap.step_over, { desc = "DAP step over" })
map("n", "<leader>di", dap.step_into, { desc = "DAP step into" })
map("n", "<leader>dO", dap.step_out, { desc = "DAP step out" })
map("n", "<leader>dr", dap.repl.toggle, { desc = "DAP REPL" })
map("n", "<leader>dl", dap.run_last, { desc = "DAP run last" })
map("n", "<leader>du", dapui.toggle, { desc = "DAP UI toggle" })
map("n", "<leader>dt", dap.terminate, { desc = "DAP terminate" })
map("n", "<leader>dp", function()
  require("dap-python").test_method()
end, { desc = "DAP debug test method" })
