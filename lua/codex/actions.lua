local terminal = require("codex.terminal")

local M = {}

---@param provider_name string|nil
function M.open(provider_name)
  terminal.open(provider_name)
end

---@param provider_name string|nil
function M.close(provider_name)
  terminal.close(provider_name)
end

---@param provider_name string|nil
function M.toggle(provider_name)
  terminal.toggle(provider_name)
end

---@param text string
---@param opts table|nil
---@param provider_name string|nil
function M.send(text, opts, provider_name)
  terminal.send(text, opts, provider_name)
end

---@param provider_name string|nil
function M.send_selection(provider_name)
  terminal.send_selection(provider_name)
end

---@param provider_name string
---@return boolean
function M.select_provider(provider_name)
  return terminal.select_provider(provider_name)
end

function M.pick_provider()
  terminal.pick_provider()
end

---@return string|nil
function M.get_current_provider()
  return terminal.get_current_provider()
end

return M
