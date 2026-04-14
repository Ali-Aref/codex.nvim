local M = {}

local defaults = {
  ---Only regular split windows (no floating). Vertical uses `:vsp` then `vertical resize`.
  split = "horizontal", -- "horizontal" | "vertical"
  size = 0.3,
  codex_cmd = { "codex" },
  focus_after_send = false,
  ---If > 0, after job start sends `/status` then Enter after this many ms (reference behavior; optional).
  auto_status_delay_ms = 0,
  ---Optional: lhs for Terminal mode to leave insert-terminal (same as `<C-\\><C-n>`). Example: `"jj"` or `"<Esc>"`. If nil/omitted, no mapping is created.
  escape_codex = nil,
}

local options = vim.deepcopy(defaults)

---@param opts table|nil
function M.setup(opts)
  if opts and type(opts) == "table" then
    options = vim.tbl_deep_extend("force", {}, defaults, opts)
  else
    options = vim.deepcopy(defaults)
  end
  if options.split ~= "horizontal" and options.split ~= "vertical" then
    vim.notify(
      ("codex.nvim: split=%s is not supported (use horizontal or vertical); using horizontal"):format(
        tostring(options.split)
      ),
      vim.log.levels.WARN
    )
    options.split = "horizontal"
  end
  return options
end

---@return table
function M.get()
  return vim.deepcopy(options)
end

---@return table
function M.defaults()
  return vim.deepcopy(defaults)
end

return M
