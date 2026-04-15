# codex.nvim

[![Neovim](https://img.shields.io/badge/Neovim-0.8%2B-57A143?logo=neovim&logoColor=white)](https://neovim.io/)
[![License](https://img.shields.io/github/license/Ali-Aref/codex.nvim)](./LICENSE)
[![Stars](https://img.shields.io/github/stars/Ali-Aref/codex.nvim?style=social)](https://github.com/Ali-Aref/codex.nvim/stargazers)
[![Issues](https://img.shields.io/github/issues/Ali-Aref/codex.nvim)](https://github.com/Ali-Aref/codex.nvim/issues)

Neovim companion for the **Codex CLI**: open Codex in a regular **split terminal** (horizontal or vertical only) and send buffer text from the editor.

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
  - [lazy.nvim](#lazynvim)
- [Usage](#usage)
- [Configuration](#configuration)
- [Behavior notes](#behavior-notes)
- [Development / testing loop](#development--testing-loop)
  - [Smoke checks](#smoke-checks)
- [License](#license)

## Requirements

- Neovim **0.8+**
- `codex` on your `$PATH` (or override `codex_cmd` in setup)

## Installation

Repository: [https://github.com/Ali-Aref/codex.nvim](https://github.com/Ali-Aref/codex.nvim)

### lazy.nvim

Add a plugin spec (for example under `lua/plugins/codex.lua` if you import `lua/plugins`):

```lua
{
  "Ali-Aref/codex.nvim",
  config = function()
    require("codex").setup({
      split = "vertical", -- "horizontal" | "vertical"
      vertical_side = "right", -- "left" | "right" when vertical
      size = 0.3,
      codex_cmd = { "codex" },
      -- escape_codex = "jj", -- optional Terminal-mode escape → <C-\><C-n>
    })
  end,
  keys = {
    {
      "<A-e>", -- your own shortcut, I prefer Alt + e
      function()
        require("codex").toggle()
      end,
      mode = { "n", "t" },
      desc = "Codex: toggle terminal",
    },
    {
      "ge", -- your own shortcut, I prefer ge
      "<Cmd>lua require('codex').send_selection()<CR>",
      mode = "x",
      desc = "Codex: send visual selection",
    },
  },
}
```

Adjust `keys` to your taste. If the GitHub default branch is not `main`, set `branch` explicitly (for example `branch = "dev"`).

## Usage


| Action           | Lua                                                                                             |
| ---------------- | ----------------------------------------------------------------------------------------------- |
| Open             | `require("codex").open()`                                                                       |
| Close (stop job) | `require("codex").close()`                                                                      |
| Toggle window    | `require("codex").toggle()`                                                                     |
| Send selection   | `require("codex").send_selection()`                                                             |
| Send raw text    | `require("codex").send("hello", { submit = false, open_window = true, focus_terminal = true })` |


`require("codex").actions.*` mirrors the same functions.

## Configuration

Defaults:

```lua
{
  split = "horizontal", -- "horizontal" | "vertical"
  vertical_side = "right", -- "left" | "right" (only for split = "vertical")
  size = 0.3,
  codex_cmd = { "codex" },
  focus_after_send = false,
  auto_status_delay_ms = 0,
  -- escape_codex = "jj", -- optional: Terminal-mode lhs to send <C-\><C-n> (omit to disable)
}
```

- **escape_codex**: optional string. When set (non-empty), registers a **global** Terminal-mode mapping from that lhs to `<C-\><C-n>` (leave terminal mode). Use any lhs Neovim accepts, for example `"jj"` or `"<Esc>"`. Omit the key or leave it unset to register nothing. If you change the value between `setup()` calls, the previous mapping is removed.
- **split** `horizontal`: `botright` + height (bottom terminal-style split).
- **split** `vertical`: `:leftabove vsplit` or `:rightbelow vsplit` (see **vertical_side**), then `vertical resize` to **size** (Codex column beside the editor).
- **vertical_side**: `"left"` or `"right"`. Puts the Codex column **left** or **right** of the window that was current when Codex opened. Ignored when **split** is `horizontal`. Invalid values fall back to `"right"`.
- **size**: for splits, a fraction `≤ 1` is a percentage of lines/columns; `> 1` is a fixed height/width.
- **focus_after_send**: after `send(...)` (not `send_selection`), jump to the Codex window and enter terminal mode when the window is open.
- **`send_selection()`** always opens the Codex window if it was hidden, pastes the payload without pressing Enter for you, then focuses the terminal so you can review and press Enter in the CLI yourself.
- **auto_status_delay_ms**: if `> 0`, after start sends `/status` then Enter after that delay (optional).

Global config before `setup()` (optional). From Lua in `init.lua`:

```lua
vim.g.codex_config = { split = "vertical" }
```

## Behavior notes

- **Toggle** hides or shows the window; the Codex job keeps running in the background while the window is closed.
- **Close** stops the Codex job, closes the window, and clears terminal state.
- **Quit Neovim**: a `VimLeavePre` autocommand calls `close()` so the Codex process is not left running.

## Development / testing loop

For **local hacking**, point lazy at a clone with `dir` instead of the GitHub spec:

```lua
{ dir = "~/path/to/codex.nvim", name = "codex.nvim", config = function() require("codex").setup({}) end }
```

Then:

1. Change files in the clone.
2. In Neovim: `:Lazy reload codex.nvim`
3. If Lua modules seem stale: `:lua for k,_ in pairs(package.loaded) do if k:match('^codex') then package.loaded[k]=nil end end` then `:Lazy reload codex.nvim`

### Smoke checks

- `:lua require('codex').toggle()` — window opens/closes.
- Visually select lines, `:lua require('codex').send_selection()` — text is sent to the Codex channel (metadata header + selection).
- Change `split` to `vertical` in setup and reload (expect `:vsp`-style column).
- With Codex running, quit Neovim and confirm no stray `codex` process (e.g. `pgrep -a codex`).

## License

MIT

Contributions are welcome. Feel free to open an issue or submit a pull request.
