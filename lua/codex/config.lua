local M = {}

local defaults = {
  split = "horizontal", -- "horizontal" | "vertical" | "float"
  ---When split is "vertical", place the Codex column left or right of the current window (`:leftabove vsplit` / `:rightbelow vsplit`).
  vertical_side = "right", -- "left" | "right"
  size = 0.3,
  float = {
    width = 0.9,
    height = 0.85,
    border = "rounded",
  },
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
  if options.split ~= "horizontal" and options.split ~= "vertical" and options.split ~= "float" then
    vim.notify(
      ("codex.nvim: split=%s is not supported (use horizontal, vertical, or float); using horizontal"):format(
        tostring(options.split)
      ),
      vim.log.levels.WARN
    )
    options.split = "horizontal"
  end
  if options.vertical_side ~= "left" and options.vertical_side ~= "right" then
    vim.notify(
      ("codex.nvim: vertical_side=%s is not supported (use left or right); using right"):format(
        tostring(options.vertical_side)
      ),
      vim.log.levels.WARN
    )
    options.vertical_side = "right"
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
