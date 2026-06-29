local api = vim.api
local fn = vim.fn

local ui = require("codex.ui")
local config = require("codex.config")

local M = {}

local state = {
  providers = {},
  current_provider = nil,
}

local function provider_state(name)
  local provider = state.providers[name]
  if provider then
    return provider
  end

  provider = {
    job_id = nil,
    bufnr = nil,
    running = false,
  }
  state.providers[name] = provider
  return provider
end

local function enter_terminal_mode(bufnr)
  if not bufnr or not api.nvim_buf_is_valid(bufnr) then
    return
  end
  if not ui.is_open() then
    return
  end
  local winid = ui.state.winid
  if not winid or not api.nvim_win_is_valid(winid) then
    return
  end
  if api.nvim_win_get_buf(winid) ~= bufnr then
    return
  end
  local current_win = api.nvim_get_current_win()
  if current_win ~= winid then
    api.nvim_set_current_win(winid)
  end
  vim.cmd("startinsert")
end

local function reset_provider_state(name)
  local provider = provider_state(name)
  provider.job_id = nil
  provider.running = false
  if provider.bufnr and api.nvim_buf_is_valid(provider.bufnr) then
    if not vim.bo[provider.bufnr].modified then
      pcall(api.nvim_buf_delete, provider.bufnr, { force = true })
    else
      api.nvim_buf_set_option(provider.bufnr, "bufhidden", "hide")
    end
  end
  provider.bufnr = nil
end

local function handle_exit(_, _, _, provider_name)
  reset_provider_state(provider_name)
end

local function ensure_terminal_buffer(conf, provider_name)
  local provider = provider_state(provider_name)
  if provider.bufnr and api.nvim_buf_is_valid(provider.bufnr) then
    return provider.bufnr
  end
  local bufnr = api.nvim_create_buf(false, true)
  api.nvim_buf_set_option(bufnr, "bufhidden", "hide")
  api.nvim_buf_set_option(bufnr, "filetype", conf.filetype or provider_name)
  provider.bufnr = bufnr
  return bufnr
end

local function resolve_provider_name(provider_name)
  local conf = config.get()
  local name = provider_name or state.current_provider or conf.default_provider
  if conf.providers[name] == nil then
    vim.notify(("ai-cli.nvim: provider '%s' is not configured"):format(tostring(name)), vim.log.levels.ERROR)
    return nil, nil, nil
  end

  state.current_provider = name
  return name, conf, conf.providers[name]
end

---@param conf table
---@param provider_name string
---@param opts { open_window?: boolean }|nil
---@return boolean
local function start_job(conf, provider_name, opts)
  opts = opts or {}
  local open_window = opts.open_window
  if open_window == nil then
    open_window = true
  end

  local provider = provider_state(provider_name)
  local provider_conf = conf.providers[provider_name]
  local bufnr = ensure_terminal_buffer(provider_conf, provider_name)

  if open_window then
    ui.open_window(conf, bufnr)
    api.nvim_set_current_win(ui.state.winid)
  end

  api.nvim_buf_call(bufnr, function()
    provider.job_id = fn.termopen(provider_conf.cmd, {
      on_exit = function(...)
        handle_exit(..., provider_name)
      end,
    })
  end)

  if not provider.job_id or provider.job_id <= 0 then
    vim.notify(
      ("ai-cli.nvim: failed to start %s command"):format(provider_conf.display_name or provider_name),
      vim.log.levels.ERROR
    )
    reset_provider_state(provider_name)
    return false
  end

  provider.running = true
  vim.bo[bufnr].buflisted = false
  vim.b[bufnr].ai_cli_terminal = true
  vim.b[bufnr].ai_cli_provider = provider_name

  if open_window then
    enter_terminal_mode(bufnr)
  end

  local chan = provider.job_id
  if provider_conf.status_message and provider_conf.auto_status_delay_ms and provider_conf.auto_status_delay_ms > 0 then
    api.nvim_chan_send(chan, provider_conf.status_message)
    vim.defer_fn(function()
      local running_provider = provider_state(provider_name)
      if running_provider.running and running_provider.job_id == chan then
        api.nvim_chan_send(chan, "\r")
      end
    end, provider_conf.auto_status_delay_ms)
  end

  return true
end

---@param provider_name string
---@param opts { open_window?: boolean }|nil
---@return boolean
local function ensure_job(provider_name, opts)
  opts = opts or {}
  local open_window = opts.open_window
  if open_window == nil then
    open_window = true
  end

  local conf = config.get()
  local provider = provider_state(provider_name)
  if provider.running and provider.job_id ~= nil then
    if open_window and provider.bufnr then
      ui.open_window(conf, provider.bufnr)
      enter_terminal_mode(provider.bufnr)
    end
    return true
  end
  return start_job(conf, provider_name, opts)
end

function M.select_provider(provider_name)
  local name = resolve_provider_name(provider_name)
  if not name then
    return false
  end
  state.current_provider = name
  return true
end

function M.get_current_provider()
  local name = resolve_provider_name(nil)
  return name
end

function M.pick_provider()
  local conf = config.get()
  local provider_names = vim.tbl_keys(conf.providers)
  table.sort(provider_names)

  vim.ui.select(provider_names, {
    prompt = "Select AI provider",
    format_item = function(item)
      local provider = conf.providers[item]
      return provider.display_name or item
    end,
  }, function(choice)
    if choice then
      M.select_provider(choice)
    end
  end)
end

function M.open(provider_name)
  local name = resolve_provider_name(provider_name)
  if not name then
    return
  end
  ensure_job(name, { open_window = true })
end

function M.close(provider_name)
  if provider_name then
    local name = resolve_provider_name(provider_name)
    if not name then
      return
    end
    local provider = provider_state(name)
    if provider.running and provider.job_id then
      fn.jobstop(provider.job_id)
    end
    if ui.is_open() and provider.bufnr and ui.state.bufnr == provider.bufnr then
      ui.close_window()
    end
    reset_provider_state(name)
    return
  end

  for name, provider in pairs(state.providers) do
    if provider.running and provider.job_id then
      fn.jobstop(provider.job_id)
    end
  end
  ui.close_window()
  for name in pairs(state.providers) do
    reset_provider_state(name)
  end
end

function M.toggle(provider_name)
  local name = resolve_provider_name(provider_name)
  if not name then
    return
  end
  local provider = provider_state(name)
  if ui.is_open() then
    if provider.bufnr and ui.state.bufnr == provider.bufnr then
      ui.close_window()
      return
    end
    if provider.bufnr and api.nvim_buf_is_valid(provider.bufnr) then
      ui.open_window(config.get(), provider.bufnr)
      enter_terminal_mode(provider.bufnr)
      return
    end
  else
    ensure_job(name, { open_window = true })
    return
  end
  ensure_job(name, { open_window = true })
end

---@param text string
---@param opts { submit?: boolean, submit_delay_ms?: number, focus?: boolean, open_window?: boolean, focus_terminal?: boolean }|nil
function M.send(text, opts, provider_name)
  opts = opts or {}
  if not text or text == "" then
    return
  end
  local name, conf = resolve_provider_name(provider_name)
  if not name then
    return
  end
  local open_window = opts.open_window == true
  if not ensure_job(name, { open_window = open_window }) then
    return
  end

  local submit = opts.submit
  if submit == nil then
    submit = true
  end

  local provider = provider_state(name)
  local provider_conf = conf.providers[name]
  local chan = provider.job_id
  api.nvim_chan_send(chan, text)

  if submit then
    local delay = opts.submit_delay_ms or provider_conf.auto_status_delay_ms or 150
    vim.defer_fn(function()
      local running_provider = provider_state(name)
      if running_provider.running and running_provider.job_id == chan then
        api.nvim_chan_send(chan, "\r")
      end
    end, delay)
  end

  local want_provider_focus = opts.focus_terminal
    or (conf.focus_after_send and opts.focus ~= false)
  if want_provider_focus and provider.running and provider.bufnr and api.nvim_buf_is_valid(provider.bufnr) then
    ui.focus()
    enter_terminal_mode(provider.bufnr)
  end
end

local function normalize_column(bufnr, line, col, is_end)
  if col < 0 then
    return col
  end
  local line_text = api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ""
  if col == 2147483647 then
    return #line_text
  end
  local zero_based = math.max(col - 1, 0)
  if is_end then
    zero_based = math.min(zero_based + 1, #line_text)
  else
    zero_based = math.min(zero_based, #line_text)
  end
  return zero_based
end

local function exit_visual_mode()
  -- Leave visual mode synchronously (ASCII ESC). nvim_exec works on 0.8+.
  pcall(api.nvim_exec, "normal! \27", false)
end

---Capture visual selection text from current buffer (visual mode or last visual via gv).
---@return { bufnr: integer, start_line: integer, end_line: integer, text: string }|nil
function M._get_visual_selection()
  local bufnr = api.nvim_get_current_buf()
  local mode = fn.mode()

  if not mode:match("^[vV\22]") then
    local ok = pcall(vim.cmd, "normal! gv")
    if not ok then
      return nil
    end
    mode = fn.mode()
  end

  if not mode:match("^[vV\22]") then
    return nil
  end

  local selection_type = fn.visualmode() or mode or "v"
  local start_pos = fn.getpos("v")
  local end_pos = fn.getpos(".")

  if start_pos[2] == 0 or end_pos[2] == 0 then
    exit_visual_mode()
    return nil
  end

  exit_visual_mode()

  local start_line, start_col = start_pos[2], start_pos[3]
  local end_line, end_col = end_pos[2], end_pos[3]

  if start_line > end_line or (start_line == end_line and start_col > end_col) then
    start_line, end_line = end_line, start_line
    start_col, end_col = end_col, start_col
  end

  local text
  if selection_type == "V" then
    local lines = api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
    text = table.concat(lines, "\n")
  elseif selection_type == "\22" then
    local left = math.min(start_col, end_col) - 1
    local right = math.max(start_col, end_col) - 1
    local pieces = {}
    for row = start_line - 1, end_line - 1 do
      local line = api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
      pieces[#pieces + 1] = line:sub(left + 1, math.min(right + 1, #line))
    end
    text = table.concat(pieces, "\n")
  else
    local start_c = normalize_column(bufnr, start_line, start_col, false)
    local end_c = normalize_column(bufnr, end_line, end_col, true)
    local lines = api.nvim_buf_get_text(bufnr, start_line - 1, start_c, end_line - 1, end_c, {})
    text = table.concat(lines, "\n")
  end

  if text == "" then
    return nil
  end

  if vim.bo[bufnr].expandtab and vim.bo[bufnr].tabstop and vim.bo[bufnr].tabstop > 0 then
    local spaces = string.rep(" ", vim.bo[bufnr].tabstop)
    text = text:gsub("\t", spaces)
  end

  return {
    bufnr = bufnr,
    start_line = start_line,
    end_line = end_line,
    text = text,
  }
end

local function format_metadata(bufnr, start_line, end_line)
  local filename = api.nvim_buf_get_name(bufnr)
  if filename == "" then
    filename = "[No Name]"
  else
    filename = fn.fnamemodify(filename, ":t")
  end
  return string.format("File: %s:%d-%d\n\n", filename, start_line, end_line)
end

local function ensure_trailing_newline(text)
  if text:sub(-1) ~= "\n" then
    return text .. "\n"
  end
  return text
end

function M.send_selection(provider_name)
  local selection = M._get_visual_selection()
  if not selection or not selection.text or selection.text == "" then
    vim.notify("ai-cli.nvim: visual selection is empty", vim.log.levels.WARN)
    return
  end
  local payload = format_metadata(selection.bufnr, selection.start_line, selection.end_line) .. selection.text
  payload = ensure_trailing_newline(payload)
  -- Show the current provider and focus it so pasted input is visible; user presses Enter in the CLI to submit.
  M.send(payload, { submit = false, open_window = true, focus_terminal = true }, provider_name)
end

return M
