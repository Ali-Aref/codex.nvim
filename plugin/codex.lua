if vim.g.loaded_codex_plugin then
  return
end
vim.g.loaded_codex_plugin = true

local ok, codex = pcall(require, "codex")
if not ok then
  vim.notify("ai-cli.nvim: failed to load core module: " .. tostring(codex), vim.log.levels.ERROR)
  return
end

local function complete_providers()
  local conf = require("codex.config").get()
  return vim.tbl_keys(conf.providers or {})
end

if vim.g.codex_config then
  codex.setup(vim.g.codex_config)
else
  codex.setup()
end

vim.api.nvim_create_user_command("AiCliToggle", function(opts)
  codex.toggle(opts.args ~= "" and opts.args or nil)
end, {
  nargs = "?",
  complete = complete_providers,
})

vim.api.nvim_create_user_command("AiCliOpen", function(opts)
  codex.open(opts.args ~= "" and opts.args or nil)
end, {
  nargs = "?",
  complete = complete_providers,
})

vim.api.nvim_create_user_command("AiCliClose", function(opts)
  codex.close(opts.args ~= "" and opts.args or nil)
end, {
  nargs = "?",
  complete = complete_providers,
})

vim.api.nvim_create_user_command("AiCliSelectProvider", function(opts)
  if opts.args == "" then
    codex.pick_provider()
    return
  end
  codex.select_provider(opts.args)
end, {
  nargs = "?",
  complete = complete_providers,
})
