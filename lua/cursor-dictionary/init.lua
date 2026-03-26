local dict  = require("cursor-dictionary.dict")
local win = require("cursor-dictionary.win")

local M = {}

local enabled = false

function M.toggle()
  enabled = not enabled
  if not enabled then win.close() end
  vim.notify("cursor-dictionary: " .. (enabled and "enabled" or "disabled"), vim.log.levels.INFO)
end

function M.setup(opts)
  opts = opts or {}

  if opts.dict then
    dict.load(opts.dict)
  end

  if opts.enabled then
    enabled = true
  end

  vim.api.nvim_create_user_command("CursorDictToggle", function()
    M.toggle()
  end, {})

  vim.api.nvim_create_user_command("CursorDictBuild", function(o)
    local args = o.fargs
    if #args < 2 or #args > 3 then
      vim.notify(
        "Usage: CursorDictBuild {input} {output} [eijiro]",
        vim.log.levels.ERROR
      )
      return
    end
    local input, output   = args[1], args[2]
    local filetype        = args[3]
    require("cursor-dictionary.build").build(filetype, input, output)
  end, { nargs = "+", complete = "file" })

  vim.api.nvim_create_autocmd({ "CursorMoved" }, {
    callback = function()
      if not enabled then return end
      if win.is_dict_win() then return end
      local word = vim.fn.expand("<cword>")
      if word == "" then return end
      local translation = dict.lookup(word)
      if translation then
        win.show(translation)
      end
    end,
  })
end

return M
