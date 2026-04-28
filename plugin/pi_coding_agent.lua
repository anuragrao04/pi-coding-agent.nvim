if vim.fn.has("nvim-0.10.0") ~= 1 then
  vim.api.nvim_err_writeln("pi-coding-agent.nvim requires Neovim >= 0.10.0")
  return
end

if vim.g.loaded_pi_coding_agent then
  return
end
vim.g.loaded_pi_coding_agent = 1

if vim.g.pi_coding_agent_auto_setup then
  vim.defer_fn(function()
    require("pi_coding_agent").setup(vim.g.pi_coding_agent_auto_setup)
  end, 0)
end

local ok, err = pcall(require, "pi_coding_agent")
if not ok then
  vim.notify("pi-coding-agent: Failed to load main module: " .. tostring(err), vim.log.levels.ERROR)
end
