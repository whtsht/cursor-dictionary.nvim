local dict  = require("cursor-dictionary.dict")
local win = require("cursor-dictionary.win")

local M = {}

local enabled = false

local function plugin_root()
  local src = debug.getinfo(1, "S").source:sub(2)
  return vim.fn.fnamemodify(src, ":h:h:h")
end

function M.toggle()
  enabled = not enabled
  if not enabled then win.close() end
  vim.notify("cursor-dictionary: " .. (enabled and "enabled" or "disabled"), vim.log.levels.INFO)
end

function M.setup(opts)
  opts = opts or {}

  if opts.dict then
    local cfg = opts.dict
    local dir = cfg.dir
    local cdict_path = dir .. "/dict.cdict"
    local source_file = dir .. "/dict.cdict.source"
    local f = io.open(source_file, "r")
    local stored = f and f:read("*l") or nil
    if f then f:close() end

    if vim.fn.filereadable(cdict_path) == 0 or stored ~= cfg.source then
      vim.fn.mkdir(dir, "p")
      require("cursor-dictionary.build").build(cfg.format, cfg.source, cdict_path)
      local fw = io.open(source_file, "w")
      if fw then fw:write(cfg.source); fw:close() end
    end
    dict.load(cdict_path)
  else
    dict.load(plugin_root() .. "/default-dict.cdict")
  end

  if opts.enabled then
    enabled = true
  end

  vim.api.nvim_create_user_command("CursorDictToggle", function()
    M.toggle()
  end, {})

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
