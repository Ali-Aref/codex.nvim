local terminal = require("codex.terminal")

local M = {}

function M.open()
  terminal.open()
end

function M.close()
  terminal.close()
end

function M.toggle()
  terminal.toggle()
end

---@param text string
---@param opts table|nil
function M.send(text, opts)
  terminal.send(text, opts)
end

function M.send_selection()
  terminal.send_selection()
end

return M
