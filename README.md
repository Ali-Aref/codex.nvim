# ai-nvim

[![Neovim](https://img.shields.io/badge/Neovim-0.8%2B-57A143?logo=neovim&logoColor=white)](https://neovim.io/)
[![License](https://img.shields.io/github/license/Ali-Aref/ai-nvim)](./LICENSE)
[![Stars](https://img.shields.io/github/stars/Ali-Aref/ai-nvim?style=social)](https://github.com/Ali-Aref/ai-nvim/stargazers)
[![Issues](https://img.shields.io/github/issues/Ali-Aref/ai-nvim)](https://github.com/Ali-Aref/ai-nvim/issues)

Neovim companion for AI terminal agents: open **Codex CLI** or **Cursor CLI** in a split or floating terminal and send buffer text from the editor.

<a href="https://i.ibb.co/rG1yts43/Screenshot-20260414-140758.png">
  <img
    src="https://i.ibb.co/rG1yts43/Screenshot-20260414-140758.png"
    alt="ai-nvim running an AI CLI in Neovim"
    style="border-radius: 30px;"
  />
</a>

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
- `codex` and/or `cursor-agent` on your `$PATH`

## Installation

Repository: [https://github.com/Ali-Aref/ai-nvim](https://github.com/Ali-Aref/ai-nvim)

The repository is named `ai-nvim`; the Lua module remains `codex` for compatibility with existing configurations.

### lazy.nvim

Add a plugin spec (for example under `lua/plugins/ai-nvim.lua` if you import `lua/plugins`):

```lua
{
  "Ali-Aref/ai-nvim",
  config = function()
    require("codex").setup({
      split = "float", -- "horizontal" | "vertical" | "float"
      float = {
        width = 0.9,
        height = 0.85,
        border = "rounded",
      },
      default_provider = "codex",
      providers = {
        codex = {
          cmd = { "codex" },
        },
        cursor = {
          cmd = { "cursor-agent" },
        },
      },
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
      desc = "AI CLI: toggle terminal",
    },
    {
      "<leader>aa",
      function()
        require("codex").pick_provider()
      end,
      desc = "AI CLI: pick provider",
    },
    {
      "ge", -- your own shortcut, I prefer ge
      "<Cmd>lua require('codex').send_selection()<CR>",
      mode = "x",
      desc = "AI CLI: send visual selection",
    },
  },
}
```

Recommended flow: keep your existing toggle/send mappings targeting the current provider, and use `<leader>aa` to switch between Codex and Cursor.

Adjust `keys` to your taste. If the GitHub default branch is not `main`, set `branch` explicitly (for example `branch = "dev"`).

## Usage


| Action           | Lua                                                                                             |
| ---------------- | ----------------------------------------------------------------------------------------------- |
| Open             | `require("codex").open()`                                                                       |
| Close (stop job) | `require("codex").close()`                                                                      |
| Toggle window    | `require("codex").toggle()`                                                                     |
| Pick provider    | `require("codex").pick_provider()`                                                              |
| Set provider     | `require("codex").select_provider("cursor")`                                                    |
| Send selection   | `require("codex").send_selection()`                                                             |
| Send raw text    | `require("codex").send("hello", { submit = false, open_window = true, focus_terminal = true })` |

Provider-specific calls are also supported:

```lua
require("codex").toggle("codex")
require("codex").toggle("cursor")
require("codex").send_selection("cursor")
```

Commands:

- `:AiCliToggle[ provider]`
- `:AiCliOpen[ provider]`
- `:AiCliClose[ provider]`
- `:AiCliSelectProvider[ provider]`

If `:AiCliSelectProvider` is called without an argument, it opens a picker via `vim.ui.select()`.


`require("codex").actions.*` mirrors the same functions.

## Configuration

Defaults:

```lua
{
  split = "horizontal", -- "horizontal" | "vertical" | "float"
  vertical_side = "right", -- "left" | "right" (only for split = "vertical")
  size = 0.3,
  float = {
    width = 0.9,
    height = 0.85,
    border = "rounded",
  },
  focus_after_send = false,
  default_provider = "codex",
  providers = {
    codex = {
      cmd = { "codex" },
      auto_status_delay_ms = 0,
      status_message = "/status",
      filetype = "codex",
      display_name = "Codex",
    },
    cursor = {
      cmd = { "cursor-agent" },
      auto_status_delay_ms = 0,
      filetype = "cursor",
      display_name = "Cursor",
    },
  },
  -- escape_codex = "jj", -- optional: Terminal-mode lhs to send <C-\><C-n> (omit to disable)
}
```

- **escape_codex**: optional string. When set (non-empty), registers a **global** Terminal-mode mapping from that lhs to `<C-\><C-n>` (leave terminal mode). Use any lhs Neovim accepts, for example `"jj"` or `"<Esc>"`. Omit the key or leave it unset to register nothing. If you change the value between `setup()` calls, the previous mapping is removed.
- **default_provider**: provider used by `open()`, `toggle()`, `send()`, and `send_selection()` unless you explicitly pass another provider or switch via `pick_provider()`.
- **providers**: table keyed by provider name.
- **providers.<name>.cmd**: command array passed to `termopen()`.
- **providers.<name>.auto_status_delay_ms**: optional startup submit delay for that provider.
- **providers.<name>.status_message**: optional startup text to send before the delayed Enter. This is useful for Codex and omitted for Cursor by default.
- **providers.<name>.filetype**: terminal buffer filetype for that provider.
- **providers.<name>.display_name**: label shown in the provider picker.
- **split** `horizontal`: `botright` + height (bottom terminal-style split).
- **split** `vertical`: `:leftabove vsplit` or `:rightbelow vsplit` (see **vertical_side**), then `vertical resize` to **size** (AI CLI column beside the editor).
- **split** `float`: opens a centered floating window using **float.width**, **float.height**, and **float.border**.
- **vertical_side**: `"left"` or `"right"`. Puts the AI CLI column **left** or **right** of the window that was current when it opened. Ignored when **split** is `horizontal`. Invalid values fall back to `"right"`.
- **size**: for splits, a fraction `≤ 1` is a percentage of lines/columns; `> 1` is a fixed height/width.
- **float.width** / **float.height**: for floating windows, fraction `≤ 1` means percent of editor width/height; `> 1` is fixed columns/lines.
- **float.border**: any `nvim_open_win()` border style such as `"rounded"` or `"single"`.
- **focus_after_send**: after `send(...)` (not `send_selection`), jump to the active provider window and enter terminal mode when the window is open.
- **`send_selection()`** always opens the active provider window if it was hidden, pastes the payload without pressing Enter for you, then focuses the terminal so you can review and press Enter in the CLI yourself.

Legacy compatibility:

- `codex_cmd` still maps to `providers.codex.cmd`
- top-level `auto_status_delay_ms` still maps to `providers.codex.auto_status_delay_ms`

Global config before `setup()` (optional). From Lua in `init.lua`:

```lua
vim.g.codex_config = {
  split = "float",
  float = {
    width = 0.9,
    height = 0.85,
    border = "rounded",
  },
}
```

## Behavior notes

- **Toggle** hides or shows the window; the active provider's job keeps running in the background while the window is closed.
- **Close** stops one provider if you pass a provider name, or all providers if you call `close()` with no argument.
- **Pick provider** changes which backend your existing toggle/send mappings target.
- **Quit Neovim**: a `VimLeavePre` autocommand calls `close()` so no managed CLI process is left running.

## Development / testing loop

For **local hacking**, point lazy at a clone with `dir` instead of the GitHub spec:

```lua
{ dir = "~/path/to/ai-nvim", name = "ai-nvim", config = function() require("codex").setup({}) end }
```

Then:

1. Change files in the clone.
2. In Neovim: `:Lazy reload ai-nvim`
3. If Lua modules seem stale: `:lua for k,_ in pairs(package.loaded) do if k:match('^codex') then package.loaded[k]=nil end end` then `:Lazy reload ai-nvim`

### Smoke checks

- `:lua require('codex').toggle()` — window opens/closes.
- `:lua require('codex').pick_provider()` — picker opens and changes the active provider.
- Visually select lines, `:lua require('codex').send_selection()` — text is sent to the active provider channel (metadata header + selection).
- `:lua require('codex').toggle('cursor')` — opens Cursor directly.
- Change `split` to `vertical` in setup and reload (expect `:vsp`-style column).
- Change `split` to `float` in setup and reload (expect a centered floating terminal).
- With a provider running, quit Neovim and confirm no stray process (e.g. `pgrep -a codex` or `pgrep -a cursor-agent`).

## License

MIT

Contributions are welcome. Feel free to open an issue or submit a pull request.
