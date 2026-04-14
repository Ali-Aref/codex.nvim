local api = vim.api
local config = require("codex.config")
local actions = require("codex.actions")

local M = {}

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
  config.setup(opts)
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
