# codex.nvim

Neovim companion for the **Codex CLI**: open Codex in a regular **split terminal** (horizontal or vertical only) and send buffer text from the editor.

## Requirements

- Neovim **0.8+**
- `codex` on your `$PATH` (or override `codex_cmd` in setup)

## Installation (lazy.nvim, local development)

Point lazy at this repo with `dir`:

```lua
{
  dir = "/home/ali/Projects/other/codex.nvim",
  name = "codex.nvim",
  config = function()
    require("codex").setup({
      split = "horizontal", -- "horizontal" | "vertical"
      size = 0.3,
      codex_cmd = { "codex" },
    })
  end,
}
```

A ready-made spec lives in this machine’s config as `lua/plugins/codex-local.lua` (toggle `<leader>cc`, send selection in visual mode `<leader>cs`).

## Usage

| Action            | Lua                                              |
|-------------------|--------------------------------------------------|
| Open              | `require("codex").open()`                        |
| Close (stop job)  | `require("codex").close()`                       |
| Toggle window     | `require("codex").toggle()`                      |
| Send selection    | `require("codex").send_selection()`              |
| Send raw text     | `require("codex").send("hello", { submit = false, open_window = true, focus_terminal = true })` |

`require("codex").actions.*` mirrors the same functions.

## Configuration

Defaults:

```lua
{
  split = "horizontal", -- "horizontal" | "vertical"
  size = 0.3,
  codex_cmd = { "codex" },
  focus_after_send = false,
  auto_status_delay_ms = 0,
}
```

- **split** `horizontal`: `botright` + height (bottom terminal-style split).
- **split** `vertical`: `:vsp` then `vertical resize` to `size` (new column, Codex buffer shown there).
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

1. Change files under this repo.
2. In Neovim: `:Lazy reload codex.nvim`
3. If Lua modules seem stale: `:lua for k,_ in pairs(package.loaded) do if k:match('^codex') then package.loaded[k]=nil end end` then `:Lazy reload codex.nvim`

### Smoke checks

- `:lua require('codex').toggle()` — window opens/closes.
- Visually select lines, `:lua require('codex').send_selection()` — text is sent to the Codex channel (metadata header + selection).
- Change `split` to `vertical` in setup and reload (expect `:vsp`-style column).
- With Codex running, quit Neovim and confirm no stray `codex` process (e.g. `pgrep -a codex`).

## License

MIT
