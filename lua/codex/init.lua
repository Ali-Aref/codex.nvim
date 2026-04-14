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
    vim.keymap.set("t", lhs, "<C-\\><C-n>", { desc = "Codex: exit terminal mode" })
    _escape_terminal_lhs = lhs
  end
end

local function ensure_vim_leave_autocmd()
  local group = api.nvim_create_augroup("CodexVimLeave", { clear = true })
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

function M.open()
  actions.open()
end

function M.close()
  actions.close()
end

function M.toggle()
  actions.toggle()
end

---@param text string
---@param opts table|nil
function M.send(text, opts)
  actions.send(text, opts)
end

function M.send_selection()
  actions.send_selection()
end

M.actions = actions

return M
