local M = {}

local defaults = {
  split = "horizontal", -- "horizontal" | "vertical" | "float"
  ---When split is "vertical", place the AI CLI column left or right of the current window (`:leftabove vsplit` / `:rightbelow vsplit`).
  vertical_side = "right", -- "left" | "right"
  size = 0.3,
  float = {
    width = 0.9,
    height = 0.85,
    border = "rounded",
  },
  focus_after_send = false,
  ---Optional: lhs for Terminal mode to leave insert-terminal (same as `<C-\\><C-n>`). Example: `"jj"` or `"<Esc>"`. If nil/omitted, no mapping is created.
  escape_codex = nil,
  default_provider = "codex",
  providers = {
    codex = {
      cmd = { "codex" },
      auto_status_delay_ms = 0,
      status_message = "/status",
      filetype = "codex",
      display_name = "Codex",
    },
    cursor = {
      cmd = { "cursor-agent" },
      auto_status_delay_ms = 0,
      status_message = nil,
      filetype = "cursor",
      display_name = "Cursor",
    },
  },
}

local options = vim.deepcopy(defaults)

local function normalize_legacy_options(conf)
  if conf.codex_cmd then
    conf.providers = conf.providers or {}
    conf.providers.codex = vim.tbl_deep_extend("force", {}, conf.providers.codex or {}, {
      cmd = conf.codex_cmd,
    })
    conf.codex_cmd = nil
  end

  if conf.auto_status_delay_ms ~= nil then
    conf.providers = conf.providers or {}
    conf.providers.codex = vim.tbl_deep_extend("force", {}, conf.providers.codex or {}, {
      auto_status_delay_ms = conf.auto_status_delay_ms,
    })
    conf.auto_status_delay_ms = nil
  end
end

local function normalize_providers(conf)
  if type(conf.providers) ~= "table" then
    conf.providers = vim.deepcopy(defaults.providers)
  end

  for name, provider in pairs(conf.providers) do
    if type(provider) ~= "table" then
      conf.providers[name] = vim.deepcopy(defaults.providers[name] or {})
      provider = conf.providers[name]
    end

    if type(provider.cmd) ~= "table" or vim.tbl_isempty(provider.cmd) then
      local fallback = defaults.providers[name] and defaults.providers[name].cmd or { name }
      provider.cmd = vim.deepcopy(fallback)
    end

    if type(provider.filetype) ~= "string" or provider.filetype == "" then
      provider.filetype = name
    end

    if type(provider.display_name) ~= "string" or provider.display_name == "" then
      provider.display_name = name
    end
  end

  if type(conf.default_provider) ~= "string" or conf.default_provider == "" then
    conf.default_provider = defaults.default_provider
  end

  if conf.providers[conf.default_provider] == nil then
    vim.notify(
      ("ai-cli.nvim: default_provider=%s is not configured; using codex"):format(tostring(conf.default_provider)),
      vim.log.levels.WARN
    )
    conf.default_provider = "codex"
  end
end

---@param opts table|nil
function M.setup(opts)
  if opts and type(opts) == "table" then
    options = vim.tbl_deep_extend("force", {}, defaults, opts)
  else
    options = vim.deepcopy(defaults)
  end

  normalize_legacy_options(options)

  if options.split ~= "horizontal" and options.split ~= "vertical" and options.split ~= "float" then
    vim.notify(
      ("ai-cli.nvim: split=%s is not supported (use horizontal, vertical, or float); using horizontal"):format(
        tostring(options.split)
      ),
      vim.log.levels.WARN
    )
    options.split = "horizontal"
  end
  if options.vertical_side ~= "left" and options.vertical_side ~= "right" then
    vim.notify(
      ("ai-cli.nvim: vertical_side=%s is not supported (use left or right); using right"):format(
        tostring(options.vertical_side)
      ),
      vim.log.levels.WARN
    )
    options.vertical_side = "right"
  end

  normalize_providers(options)
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

---@param name string|nil
---@return table|nil
function M.get_provider(name)
  local conf = M.get()
  local provider_name = name or conf.default_provider
  return conf.providers[provider_name]
end

return M
