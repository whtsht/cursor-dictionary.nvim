# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`cursor-dictionary.nvim` is a Neovim plugin that displays dictionary translations for the word under the cursor in a split window. It loads a `.cdict` binary dictionary file and shows translations as the cursor moves.

## Architecture

```
plugin/cursor-dictionary.lua       # Entry point (loaded by Neovim)
lua/cursor-dictionary/
  init.lua                         # Orchestration: setup, toggle, autocmd, commands
  dict.lua                         # Data layer: .cdict loading and word lookup
  win.lua                          # UI layer: split window management
  build.lua                        # Build tool: CSV/EIJIRO → .cdict conversion
```

**Data flow:** On `CursorMoved`, `init.lua` calls `vim.fn.expand("<cword>")`, looks up the word via `dict.lookup()`, then shows the result via `win.show()`. The split window is skipped (`win.is_dict_win()`) to avoid reacting to cursor movement within it.

## .cdict Binary Format

The custom dictionary format used for fast, low-memory lookups. All integers are little-endian.

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

At startup, Key Index and Key Pool are loaded entirely into memory. Val Pool is accessed on-demand via file seek. Binary search runs entirely in memory; only the matched translation requires a file read.

**Lua version note:** Neovim embeds LuaJIT, which implements Lua 5.1. `string.pack`/`string.unpack` were introduced in Lua 5.3 and are therefore unavailable. Use `string.byte` for reading (see `u32`/`u16` in `dict.lua`) and `string.char` for writing (see `pack_u32`/`pack_u16` in `build.lua`).

## Testing

No test framework. Tests run via a standalone Lua script (requires Lua 5.3+ on the system, not LuaJIT):

```bash
lua scripts/test_cdict.lua
```

Building a `.cdict` for manual testing in Neovim:

```
:CursorDictBuild /path/to/dict.csv /path/to/output.cdict
:CursorDictBuild /path/to/EIJIRO.TXT /path/to/output.cdict eijiro
```

## Key Module APIs

- `init.lua`: `M.setup(opts)` — opts: `{ dict = "path/to/file.cdict", enabled = bool }`
- `dict.lua`: `M.load(filepath)`, `M.lookup(word)` — case-insensitive, LRU cache (100 entries)
- `win.lua`: `M.show(text)`, `M.close()`, `M.is_dict_win()` — botright split, max 12 lines tall
- `build.lua`: `M.build(filetype, input_path, output_path)` — filetype: `"eijiro"` or nil (CSV)
