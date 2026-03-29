# cursor-dictionary.nvim

A Neovim plugin that displays dictionary translations for the word under the cursor in a split window.

## Features

- Looks up the word under the cursor and shows its translation in a bottom split window
- Supports CSV and EIJIRO dictionary formats (converted to `.cdict` binary format)
- Toggle on/off with a single command

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "whtsht/cursor-dictionary.nvim",
  config = function()
    require("cursor-dictionary").setup({})
  end,
}
```

A bundled English-Japanese dictionary (`default-dict.cdict`, ~46,000 entries) is used automatically when no `dict` is configured. Source: [EJDict](https://kujirahand.com/web-tools/EJDictFreeDL.php).

To use [EIJIRO](https://www.eijiro.jp/textfiles.htm) instead:

```lua
return {
  "whtsht/cursor-dictionary.nvim",
  config = function()
    require("cursor-dictionary").setup({
      dict = {
        source = vim.fn.expand("~/Downloads/EIJIRO-1448.TXT"),
        dir = vim.fn.expand("~/.local/share/nvim/cursor-dictionary/"),
        format = "eijiro",
      },
      enabled = false,
    })
  end,
}
```

On first startup, the source file is automatically converted to `.cdict` and saved to `<dir>/dict.cdict`. Subsequent startups skip the build and load the cached file directly.

## Dictionary Setup

### Supported formats

**CSV** — two-column format:

```
hello,こんにちは
world,世界
function,関数
```

**EIJIRO** — set `format = "eijiro"` and point `source` at the `.TXT` file (CP932 encoding). Requires `iconv` to be available on `$PATH`.

## Configuration

```lua
require("cursor-dictionary").setup({
  -- omit `dict` to use the bundled default dictionary
  dict = {
    source = "/path/to/source",  -- path to CSV or EIJIRO .TXT file
    dir    = "/path/to/dir",     -- output directory; dict.cdict is saved here
    format = "csv",              -- "csv" or "eijiro"
  },
  enabled = false,  -- start disabled (default: false)
})
```

## Commands

| Command | Description |
|---------|-------------|
| `:CursorDictToggle` | Toggle the dictionary window on/off |

## .cdict Format

`.cdict` is a custom binary format for fast, low-memory lookups. All integers are little-endian.

```
Header (24 bytes):
  magic[8]:           "CDICT\x01\x00\x00"
  entry_count[4]:     uint32
  key_index_start[4]: uint32  (absolute offset)
  key_pool_start[4]:  uint32  (absolute offset)
  val_pool_start[4]:  uint32  (absolute offset)

Key Index (entry_count × 12 bytes, sorted lexicographically):
  key_offset[4]: uint32  (offset into key pool)
  key_len[2]:    uint16
  val_offset[4]: uint32  (offset into val pool)
  val_len[2]:    uint16

Key Pool: concatenated lowercase key strings
Val Pool: concatenated translation strings (newline-separated when multiple definitions)
```

At startup, the Key Index and Key Pool are loaded into memory. The Val Pool is accessed on-demand via file seek. Lookup uses binary search entirely in memory; only the matched translation requires a file read.

## Acknowledgements

Inspired by [mouse-dictionary](https://github.com/wtetsu/mouse-dictionary), a browser extension that displays dictionary definitions for words under the mouse cursor. This plugin brings the same concept to Neovim.
