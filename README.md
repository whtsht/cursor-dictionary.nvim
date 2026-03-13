# cursor-dictionary.nvim

A Neovim plugin that displays dictionary translations for the word under the cursor in a window.

## Features

- Looks up the word under the cursor and shows its translation in a floating popup
- Loads any CSV-format dictionary file
- Toggle on/off with a single command

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "whtsht/cursor-dictionary.nvim",
  config = function()
    require("cursor-dictionary").setup({
      dict = "/path/to/your/dictionary.csv",
    })
  end,
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  "whtsht/cursor-dictionary.nvim",
  config = function()
    require("cursor-dictionary").setup({
      dict = "/path/to/your/dictionary.csv",
    })
  end,
}
```

## Configuration

```lua
require("cursor-dictionary").setup({
  dict = "/path/to/your/dictionary.csv", -- path to your CSV dictionary file
})
```

## Dictionary Format

The dictionary file must be a CSV file with one entry per line in the format `word,translation`:

```
hello,こんにちは
world,世界
function,関数
variable,変数
```

A sample dictionary is included at `sample.csv`.

## Usage

| Command            | Description                        |
|--------------------|------------------------------------|
| `:CursorDictToggle` | Toggle the dictionary popup on/off |

When enabled, moving the cursor over a word will display its translation in a floating popup above the cursor. Moving to a word with no entry closes the popup.
