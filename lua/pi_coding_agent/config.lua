local M = {}

---@class PiCodingAgentConfig
M.defaults = {
  cmd = "pi",
  split_side = "right",
  split_width_percentage = 0.30,
  auto_insert = true,
}

---Validate configuration.
---@param cfg table
function M.validate(cfg)
  assert(
    cfg.split_side == "left" or cfg.split_side == "right",
    "[pi-coding-agent] split_side must be 'left' or 'right'"
  )
  assert(
    type(cfg.split_width_percentage) == "number"
      and cfg.split_width_percentage > 0
      and cfg.split_width_percentage < 1,
    "[pi-coding-agent] split_width_percentage must be between 0 and 1"
  )
  assert(type(cfg.auto_insert) == "boolean", "[pi-coding-agent] auto_insert must be a boolean")
  assert(type(cfg.cmd) == "string" and cfg.cmd ~= "", "[pi-coding-agent] cmd must be a non-empty string")
end

---Apply user config on top of defaults.
---@param user_config table|nil
---@return table
function M.apply(user_config)
  local cfg = vim.deepcopy(M.defaults)
  if user_config then
    cfg = vim.tbl_deep_extend("force", cfg, user_config)
  end
  M.validate(cfg)
  return cfg
end

return M
