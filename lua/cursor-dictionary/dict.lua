local M = {}

local entries = {}

function M.load(filepath)
  entries = {}
  local f = io.open(filepath, "r")
  if not f then
    vim.notify("cursor-dictionary: cannot open " .. filepath, vim.log.levels.ERROR)
    return
  end
  for line in f:lines() do
    local word, translation = line:match("^([^,]+),(.+)$")
    if word and translation then
      entries[word:lower()] = translation
    end
  end
  f:close()
end

function M.lookup(word)
  return entries[word:lower()]
end

return M
