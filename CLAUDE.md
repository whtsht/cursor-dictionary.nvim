# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`cursor-dictionary.nvim` is a Neovim plugin that displays dictionary translations for the word under the cursor in a floating popup window. It loads a user-provided CSV dictionary file and shows translations as the cursor moves.

## Architecture

Three-module architecture with a clean separation of concerns:

```
plugin/cursor-dictionary.lua       # Entry point (loaded by Neovim)
lua/cursor-dictionary/
  init.lua                         # Orchestration: setup, toggle, autocmd
  dict.lua                         # Data layer: CSV loading and word lookup
  popup.lua                        # UI layer: floating window management
```

**Data flow:** On `CursorMoved`, `init.lua` calls `vim.fn.expand("<cword>")`, looks up the word via `dict.lookup()`, then either shows or closes the popup via `popup.show()`/`popup.close()`.

### Key module APIs

- `init.lua`: `M.setup(opts)` (opts: `{ dict_path = "path/to/file.csv" }`), `M.toggle()`
- `dict.lua`: `M.load(filepath)`, `M.lookup(word)` — case-insensitive, CSV format `word,translation`
- `popup.lua`: `M.show(text)`, `M.close()` — floating window 2 lines above cursor, rounded border

## Development

This plugin has no build process, no external dependencies, and no test framework. Development is done by editing Lua files directly and testing in Neovim.

The `.luarc.json` disables `undefined-global` diagnostics to allow Neovim global APIs (`vim.*`) without warnings in the Lua language server.

The `sample.csv` contains 10 English-to-Japanese entries as a reference for the expected CSV format.
