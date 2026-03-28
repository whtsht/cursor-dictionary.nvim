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
    require("cursor-dictionary").setup({
      dict = "/path/to/your/dictionary.cdict",
    })
  end,
}
```

## Dictionary Setup

Dictionaries must be converted to `.cdict` format before use.

**From CSV:**
```
:CursorDictBuild /path/to/dict.csv /path/to/output.cdict csv
```

**From EIJIRO (.TXT):**
```
:CursorDictBuild /path/to/EIJIRO.TXT /path/to/output.cdict eijiro
```

### CSV Format

```
hello,こんにちは
world,世界
function,関数
```


## Configuration

```lua
require("cursor-dictionary").setup({
  dict    = "/path/to/dictionary.cdict",
  enabled = false,  -- start disabled (default: false)
})
```

## Commands

| Command | Description |
|---------|-------------|
| `:CursorDictToggle` | Toggle the dictionary window on/off |
| `:CursorDictBuild {input} {output} {format}` | Convert a dictionary file to `.cdict` format (`format`: `csv` \| `eijiro`) |

## Acknowledgements

Inspired by [mouse-dictionary](https://github.com/wtetsu/mouse-dictionary), a browser extension that displays dictionary definitions for words under the mouse cursor. This plugin brings the same concept to Neovim.
