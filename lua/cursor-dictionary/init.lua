local dict = require("cursor-dictionary.dict")
local popup = require("cursor-dictionary.popup")

local M = {}

local enabled = false
local popup_position = "cursor"

function M.toggle()
  enabled = not enabled
  if not enabled then
    popup.close()
  end
  vim.notify("cursor-dictionary: " .. (enabled and "enabled" or "disabled"))
end

function M.setup(opts)
  opts = opts or {}

  if opts.dict then
    dict.load(opts.dict, opts.dict_type)
  end

  if opts.enabled then
    enabled = true
  end

  if opts.popup_position then
    popup_position = opts.popup_position
  end

  vim.api.nvim_create_user_command("CursorDictToggle", function()
    M.toggle()
  end, {})

  vim.api.nvim_create_autocmd({ "CursorMoved" }, {
    callback = function()
      if not enabled then
        return
      end

      local word = vim.fn.expand("<cword>")
      if word == "" then
        popup.close()
        return
      end
      local translation = dict.lookup(word)
      if translation then
        popup.show(translation, popup_position)
      else
        popup.close()
      end
    end,
  })
end

return M
