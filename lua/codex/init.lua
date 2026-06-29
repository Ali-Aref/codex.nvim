local api = vim.api
local config = require("codex.config")
local actions = require("codex.actions")

local M = {}

---@type string|nil
local _escape_terminal_lhs = nil

local function sync_escape_terminal_keymap(conf)
  if _escape_terminal_lhs then
    pcall(vim.keymap.del, "t", _escape_terminal_lhs)
    _escape_terminal_lhs = nil
  end
  local lhs = conf.escape_codex
  if type(lhs) == "string" and lhs ~= "" then
    vim.keymap.set("t", lhs, "<C-\\><C-n>", { desc = "AI CLI: exit terminal mode" })
    _escape_terminal_lhs = lhs
  end
end

local function ensure_vim_leave_autocmd()
  local group = api.nvim_create_augroup("AiCliVimLeave", { clear = true })
  api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      actions.close()
    end,
  })
end

---@param opts table|nil
function M.setup(opts)
  local conf = config.setup(opts)
  sync_escape_terminal_keymap(conf)
  ensure_vim_leave_autocmd()
  return config.get()
end

---@param provider_name string|nil
function M.open(provider_name)
  actions.open(provider_name)
end

---@param provider_name string|nil
function M.close(provider_name)
  actions.close(provider_name)
end

---@param provider_name string|nil
function M.toggle(provider_name)
  actions.toggle(provider_name)
end

---@param text string
---@param opts table|nil
---@param provider_name string|nil
function M.send(text, opts, provider_name)
  actions.send(text, opts, provider_name)
end

---@param provider_name string|nil
function M.send_selection(provider_name)
  actions.send_selection(provider_name)
end

---@param provider_name string
---@return boolean
function M.select_provider(provider_name)
  return actions.select_provider(provider_name)
end

function M.pick_provider()
  actions.pick_provider()
end

---@return string|nil
function M.get_current_provider()
  return actions.get_current_provider()
end

M.actions = actions

return M
