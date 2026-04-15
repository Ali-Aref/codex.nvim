local api = vim.api

local M = {}

M.state = {
  bufnr = nil,
  winid = nil,
  layout = nil,
}

local function normalized_size(size, total, fallback)
  total = math.max(total, 1)
  if type(size) ~= "number" then
    size = fallback
  end
  if type(size) ~= "number" then
    size = math.floor(total * 0.3)
  end
  if size > 0 and size <= 1 then
    size = total * size
  end
  size = math.floor(size + 0.5)
  size = math.max(1, size)
  size = math.min(size, math.max(total - 1, 1))
  return size
end

---@param conf table
---@param bufnr integer|nil
---@return integer winid
---@return integer bufnr
function M.open_window(conf, bufnr)
  local state = M.state
  if not bufnr or not api.nvim_buf_is_valid(bufnr) then
    bufnr = api.nvim_create_buf(false, true)
    api.nvim_buf_set_option(bufnr, "bufhidden", "hide")
  end

  if state.winid and api.nvim_win_is_valid(state.winid) then
    if api.nvim_win_get_buf(state.winid) ~= bufnr then
      api.nvim_win_set_buf(state.winid, bufnr)
    end
    state.bufnr = bufnr
    return state.winid, bufnr
  end

  local layout = conf.split or "horizontal"
  local winid

  if layout == "horizontal" then
    -- Bottom split terminal (same idea as `:split` / `:botright split` + height).
    local height = normalized_size(conf.size or 0.3, vim.o.lines, 10)
    vim.cmd("botright " .. height .. "split")
    winid = api.nvim_get_current_win()
  elseif layout == "vertical" then
    -- New column left or right of the current window (does not depend on global 'splitright').
    local width = normalized_size(conf.size or 0.3, vim.o.columns, math.floor(vim.o.columns * 0.3))
    local side = conf.vertical_side or "right"
    if side == "left" then
      vim.cmd("leftabove vsplit")
    else
      vim.cmd("rightbelow vsplit")
    end
    winid = api.nvim_get_current_win()
    api.nvim_win_set_buf(winid, bufnr)
    api.nvim_set_current_win(winid)
    vim.cmd("vertical resize " .. width)
    state.winid = winid
    state.bufnr = bufnr
    state.layout = layout
    return winid, bufnr
  else
    error("codex.nvim: invalid split option '" .. tostring(layout) .. "'")
  end

  api.nvim_win_set_buf(winid, bufnr)
  api.nvim_set_current_win(winid)

  state.winid = winid
  state.bufnr = bufnr
  state.layout = layout

  return winid, bufnr
end

function M.close_window()
  local state = M.state
  if state.winid and api.nvim_win_is_valid(state.winid) then
    pcall(api.nvim_win_close, state.winid, true)
  end
  state.winid = nil
end

function M.is_open()
  return M.state.winid ~= nil and api.nvim_win_is_valid(M.state.winid)
end

function M.focus()
  local winid = M.state.winid
  if winid and api.nvim_win_is_valid(winid) then
    api.nvim_set_current_win(winid)
  end
end

return M
