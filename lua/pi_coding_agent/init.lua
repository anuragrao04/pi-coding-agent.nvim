local config = require("pi_coding_agent.config")
local terminal = require("pi_coding_agent.terminal")

local M = {}

---@type table|nil
M.config = nil

---@param opts? table
function M.setup(opts)
  M.config = config.apply(opts)
  terminal.setup(M.config)
  M._create_commands()
end

---Format a file path relative to cwd when possible.
---@param abs_path string
---@return string
local function format_path(abs_path)
  local cwd = vim.fn.getcwd()
  if vim.startswith(abs_path, cwd .. "/") then
    return abs_path:sub(#cwd + 2)
  end
  return abs_path
end

---@param path string
---@return string
local function maybe_add_trailing_slash(path)
  if vim.fn.isdirectory(path) == 1 and not path:match("/$") then
    return path .. "/"
  end
  return path
end

---@return string|nil
local function get_browser_path()
  local ft = vim.bo.filetype

  if ft == "NvimTree" then
    local ok, api = pcall(require, "nvim-tree.api")
    if ok then
      local node = api.tree.get_node_under_cursor()
      if node and node.absolute_path then
        return format_path(maybe_add_trailing_slash(node.absolute_path))
      end
    end
  elseif ft == "oil" then
    local ok, oil = pcall(require, "oil")
    if ok then
      local entry = oil.get_cursor_entry()
      local current_dir = oil.get_current_dir()
      if entry and current_dir then
        return format_path(maybe_add_trailing_slash(current_dir .. entry.name))
      end
    end
  elseif ft == "minifiles" then
    local ok, mini_files = pcall(require, "mini.files")
    if ok then
      local entry = mini_files.get_fs_entry()
      if entry and entry.path then
        return format_path(maybe_add_trailing_slash(entry.path))
      end
    end
  elseif ft == "neo-tree" then
    vim.notify("[pi-coding-agent] Cannot send from file browser", vim.log.levels.WARN)
    return nil
  end

  return nil
end

---@return string|nil
local function get_buffer_path()
  local browser_path = get_browser_path()
  if browser_path then
    return browser_path
  end

  local ft = vim.bo.filetype
  if ft == "NvimTree" or ft == "oil" or ft == "minifiles" or ft == "neo-tree" then
    vim.notify("[pi-coding-agent] Cannot send from file browser", vim.log.levels.WARN)
    return nil
  end

  local abs = vim.fn.expand("%:p")
  if abs == "" then
    vim.notify("[pi-coding-agent] Cannot send unnamed buffer", vim.log.levels.WARN)
    return nil
  end

  return format_path(abs)
end

---Send current buffer reference to pi input.
function M.send_buffer()
  local path = get_buffer_path()
  if not path then
    return
  end

  if not terminal.is_alive() then
    vim.notify("[pi-coding-agent] No pi session running. Use :PiToggle to start.", vim.log.levels.WARN)
    return
  end

  local jid = terminal.get_jobid()
  -- Use bracketed paste so pi's editor calls handlePaste(), which cancels any
  -- pending autocomplete timers and inserts without triggering the file picker.
  vim.fn.chansend(jid, "\x1b[200~@" .. path .. " \x1b[201~")
end

---Open pi's model selector overlay.
function M.select_model()
  if not terminal.is_alive() then
    terminal.open()
  else
    terminal.show()
  end

  if not terminal.focus() then
    vim.notify("[pi-coding-agent] No pi session running. Use :PiToggle to start.", vim.log.levels.WARN)
    return
  end

  local jid = terminal.get_jobid()
  vim.fn.chansend(jid, "\x0c")
end

---@param mode string
local function open_session_mode(mode)
  if terminal.is_alive() then
    vim.notify("[pi-coding-agent] pi session already running, use PiToggle to switch to it", vim.log.levels.WARN)
    return
  end

  terminal.open(mode)
end

---Send visual selection reference to pi input.
function M.send_selection()
  local path = get_buffer_path()
  if not path then
    return
  end

  if vim.bo.modified then
    vim.notify(
      "[pi-coding-agent] Buffer is modified. Save first to send accurate line numbers.",
      vim.log.levels.WARN
    )
    return
  end

  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")

  if not start_line or not end_line or start_line == 0 or end_line == 0 then
    vim.notify("[pi-coding-agent] No visual selection", vim.log.levels.WARN)
    return
  end

  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  if not terminal.is_alive() then
    vim.notify("[pi-coding-agent] No pi session running. Use :PiToggle to start.", vim.log.levels.WARN)
    return
  end

  local ref
  if start_line == end_line then
    ref = "@" .. path .. ":" .. start_line
  else
    ref = "@" .. path .. ":" .. start_line .. "-" .. end_line
  end

  local jid = terminal.get_jobid()
  vim.fn.chansend(jid, "\x1b[200~" .. ref .. " \x1b[201~")

  -- Exit visual mode after sending
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
end

function M._create_commands()
  local cmds = {
    PiToggle = {
      fn = function(opts)
        terminal.toggle(opts.args)
      end,
      opts = { nargs = "*", desc = "Toggle pi coding agent terminal pane" },
    },
    PiContinue = {
      fn = function()
        open_session_mode("--continue")
      end,
      opts = { desc = "Start pi with --continue" },
    },
    PiResume = {
      fn = function()
        open_session_mode("--resume")
      end,
      opts = { desc = "Start pi with --resume" },
    },
    PiSelectModel = {
      fn = function()
        M.select_model()
      end,
      opts = { desc = "Open pi model selector" },
    },
    PiSendBuffer = {
      fn = function()
        M.send_buffer()
      end,
      opts = { desc = "Send current buffer reference to pi" },
    },
    PiSendSelection = {
      fn = function()
        M.send_selection()
      end,
      opts = { desc = "Send visual selection reference to pi" },
    },
  }

  for name, def in pairs(cmds) do
    local ok = pcall(vim.api.nvim_get_user_command, name)
    if not ok then
      vim.api.nvim_create_user_command(name, def.fn, def.opts)
    end
  end
end

return M
