# pi-coding-agent.nvim

A minimal, dependency-free Neovim plugin for the [pi coding agent](https://pi.dev). It gives you a terminal pane and keybindings to send file references — nothing more, nothing less.

## Philosophy

Other neovim plugins exist but they do different things than what I wanted. [pablopunk/pi.nvim](https://github.com/pablopunk/pi.nvim) is great but it provides an ephemeral prompt -> code change workflow. There is no conversation history. There's also [carderne/pi-nvim](https://github.com/carderne/pi-nvim) which comes close to what I want but I can't go about pointing at specific lines to PI. It bundles a prompt requirement along with the selection. It also requires an extra extension on the PI side. 

This extension follows the unix philosophy of doing one thing and doing it well. It provides a terminal pane and a way to send file references. It has some nicities like toggling the PI pane in neovim, hiding it, shortcuts to continue previous sessions, etc. 

## Installation

### lazy.nvim

```lua
{
  "anuragrao04/pi-coding-agent.nvim",
  opts = {},
  keys = {
    { "<leader>at", "<cmd>PiToggle<cr>", desc = "Toggle pi" },
    { "<leader>ac", "<cmd>PiContinue<cr>", desc = "Continue pi session" },
    { "<leader>ar", "<cmd>PiResume<cr>", desc = "Resume pi session" },
    { "<leader>am", "<cmd>PiSelectModel<cr>", desc = "Select pi model" },
    { "<leader>ab", "<cmd>PiSendBuffer<cr>", desc = "Send buffer to pi" },
    { "<leader>as", "<cmd>PiSendSelection<cr>", mode = "v", desc = "Send selection to pi" },
  },
  config = function()
    require("pi_coding_agent").setup()
  end,
}
```

### vim.pack (Neovim 0.12+)

```lua
vim.pack.add({
  { src = "https://github.com/anuragrao04/pi-coding-agent.nvim" },
})

require("pi_coding_agent").setup()
```

### packer.nvim

```lua
use {
  "anuragrao04/pi-coding-agent.nvim",
  config = function()
    require("pi_coding_agent").setup()
  end,
}
```

### mini.deps

```lua
MiniDeps.add({
  source = "anuragrao04/pi-coding-agent.nvim",
})

require("pi_coding_agent").setup()
```

### Manual

Clone into your `packpath` and call setup:

```sh
git clone https://github.com/anuragrao04/pi-coding-agent.nvim \
  ~/.local/share/nvim/site/pack/plugins/start/pi-coding-agent.nvim
```

```lua
require("pi_coding_agent").setup()
```

The plugin registers user commands on setup. Keymaps are <leader> a * be default. You may remap them to whatever fits your workflow.

## Commands

| Command | Description |
|---------|-------------|
| `:PiToggle [args]` | Show or hide the pi terminal pane. Passes optional args to `pi` on first spawn (e.g., `:PiToggle --model sonnet:high`). |
| `:PiContinue` | Start a new pi session with `--continue`. Warns if a session is already running. |
| `:PiResume` | Start pi with `--resume` to pick a previous session. Warns if a session is already running. |
| `:PiSelectModel` | Focus the pi pane and send `Ctrl+L` to open pi's built-in model selector. |
| `:PiSendBuffer` | Send the current file (or file under cursor in a tree browser) as `@path/to/file` to pi's input. |
| `:PiSendSelection` | Send the visual selection as `@path/to/file:10-20` to pi's input. |


## Tree browser support

`:PiSendBuffer` works from file browsers too:

| Browser | Sent value |
|---------|-----------|
| [nvim-tree](https://github.com/nvim-tree/nvim-tree.lua) | `@path/to/file` or `@path/to/dir/` |
| [oil.nvim](https://github.com/stevearc/oil.nvim) | `@path/to/file` or `@path/to/dir/` |
| [mini.files](https://github.com/echasnovski/mini.nvim) | `@path/to/file` or `@path/to/dir/` |

A trailing slash is appended to directories so pi treats them as directory references.

## Configuration

```lua
require("pi_coding_agent").setup({
  cmd = "pi",                      -- command to run in the terminal
  split_side = "right",            -- "left" or "right"
  split_width_percentage = 0.30,     -- 0 < n < 1
  auto_insert = true,              -- enter insert mode when focusing the terminal
})
```

## Requirements

- Neovim >= 0.10.0
- [pi](https://pi.dev) installed and on `$PATH`

## License

GPL-3.0 License. See [LICENSE](./LICENSE) for details.
