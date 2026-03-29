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

local MAX_PHRASE_WORDS = 5

local function get_phrase_candidates(col, line)
  local tokens = {}
  for s, w, e in line:gmatch("()([%a%-%']+)()") do
    tokens[#tokens + 1] = { s = s, e = e, word = w }
  end

  local idx = nil
  for i, tok in ipairs(tokens) do
    if col >= tok.s - 1 and col <= tok.e - 2 then
      idx = i; break
    end
  end

  if not idx then return nil end

  local n = #tokens
  local candidates = {}

  for len = MAX_PHRASE_WORDS, 1, -1 do
    local a_min = math.max(1, idx - len + 1)
    local a_max = math.min(idx, n - len + 1)
    for a = a_min, a_max do
      local b = a + len - 1
      candidates[#candidates + 1] = line:sub(tokens[a].s, tokens[b].e - 1)
    end
  end

  return candidates
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

      local pos  = vim.api.nvim_win_get_cursor(0)
      local line = vim.api.nvim_get_current_line()
      local candidates = get_phrase_candidates(pos[2], line)

      if not candidates then return end

      for _, phrase in ipairs(candidates) do
        local translation = dict.lookup(phrase)
        if translation then
          win.show(translation)
          return
        end
      end
    end,
  })
end

return M
