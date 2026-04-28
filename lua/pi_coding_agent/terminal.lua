local M = {}

-- Module-local state
local bufnr = nil
local jobid = nil
local winid = nil
local config = nil
local augroup = nil

---@param cfg table
function M.setup(cfg)
  config = cfg
  augroup = vim.api.nvim_create_augroup("PiCodingAgentTerminal", { clear = true })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = augroup,
    callback = function()
      M.close()
    end,
  })
end

---@return boolean
function M.is_alive()
  if not jobid then
    return false
  end
  local pid = vim.fn.jobpid(jobid)
  return pid > 0
end

---@return number|nil
function M.get_jobid()
  return jobid
end

---@return number|nil
function M.get_bufnr()
  return bufnr
end

---@return number|nil
function M.get_winid()
  return winid
end

---@return boolean
function M.is_visible()
  return winid ~= nil and vim.api.nvim_win_is_valid(winid)
end

---Open or show the terminal.
---@param extra_args? string Optional args appended to cmd
function M.open(extra_args)
  if winid and vim.api.nvim_win_is_valid(winid) then
    return
  end

  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    M._show_buffer()
    return
  end

  -- Create new terminal
  local original_win = vim.api.nvim_get_current_win()
  local width = math.floor(vim.o.columns * config.split_width_percentage)
  local modifier = config.split_side == "left" and "topleft " or "botright "
  vim.cmd(modifier .. width .. "vsplit")
  winid = vim.api.nvim_get_current_win()

  bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(winid, bufnr)

  local cmd = config.cmd
  if extra_args and extra_args ~= "" then
    cmd = cmd .. " " .. extra_args
  end

  jobid = vim.fn.termopen(cmd, {
    on_exit = function()
      bufnr = nil
      jobid = nil
      winid = nil
    end,
  })

  vim.bo[bufnr].bufhidden = "hide"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = "pi-coding-agent"

  if config.auto_insert then
    vim.cmd("startinsert")
  else
    vim.api.nvim_set_current_win(original_win)
  end
end

---Hide the terminal window (keep buffer + job alive).
function M.close()
  if winid and vim.api.nvim_win_is_valid(winid) then
    vim.api.nvim_win_close(winid, true)
    winid = nil
  end
end

---Show the hidden terminal buffer in a new split.
function M._show_buffer()
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  if winid and vim.api.nvim_win_is_valid(winid) then
    return
  end

  local original_win = vim.api.nvim_get_current_win()
  local width = math.floor(vim.o.columns * config.split_width_percentage)
  local modifier = config.split_side == "left" and "topleft " or "botright "
  vim.cmd(modifier .. width .. "vsplit")
  winid = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(winid, bufnr)
  vim.api.nvim_set_current_win(original_win)
end

---Show the terminal window if a terminal buffer exists.
function M.show()
  M._show_buffer()
end

---Focus the terminal window, showing it if needed.
---@return boolean
function M.focus()
  if not M.is_alive() then
    return false
  end

  if not M.is_visible() then
    M._show_buffer()
  end

  if not M.is_visible() then
    return false
  end

  vim.api.nvim_set_current_win(winid)
  if config.auto_insert then
    vim.cmd("startinsert")
  end
  return true
end

---Toggle the terminal pane.
---@param extra_args? string
function M.toggle(extra_args)
  if winid and vim.api.nvim_win_is_valid(winid) then
    M.close()
  else
    M.open(extra_args)
  end
end

return M
