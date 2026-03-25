local M = {}

local cdict = {
  file           = nil,
  entry_count    = 0,
  val_pool_start = 0,
  key_index      = nil,
  key_pool       = nil,
}

local CACHE_MAX  = 100
local cache      = {}
local cache_keys = {}

local function cache_get(word)
  return cache[word]
end

local function cache_put(word, translation)
  if cache[word] == nil then
    if #cache_keys >= CACHE_MAX then
      local oldest = table.remove(cache_keys, 1)
      cache[oldest] = nil
    end
    table.insert(cache_keys, word)
  end
  cache[word] = translation
end

local function u32(s, pos)
  local a, b, c, d = string.byte(s, pos, pos + 3)
  return a + b * 256 + c * 65536 + d * 16777216
end

local function u16(s, pos)
  local a, b = string.byte(s, pos, pos + 1)
  return a + b * 256
end

local RECORD_SIZE = 12

local function binary_search(word)
  local lo, hi = 0, cdict.entry_count - 1
  while lo <= hi do
    local mid     = math.floor((lo + hi) / 2)
    local rec_pos = mid * RECORD_SIZE + 1
    local key_offset = u32(cdict.key_index, rec_pos)
    local key_len    = u16(cdict.key_index, rec_pos + 4)
    local val_offset = u32(cdict.key_index, rec_pos + 6)
    local val_len    = u16(cdict.key_index, rec_pos + 10)
    local key = cdict.key_pool:sub(key_offset + 1, key_offset + key_len)
    if key == word then
      cdict.file:seek("set", cdict.val_pool_start + val_offset)
      return cdict.file:read(val_len)
    elseif key < word then
      lo = mid + 1
    else
      hi = mid - 1
    end
  end
  return nil
end

function M.load(filepath)
  if cdict.file then
    cdict.file:close()
    cdict.file = nil
  end
  cache      = {}
  cache_keys = {}

  local f = io.open(filepath, "rb")
  if not f then
    vim.notify("cursor-dictionary: cannot open " .. filepath, vim.log.levels.ERROR)
    return
  end

  local header = f:read(24)
  if not header or #header < 24 or header:sub(1, 8) ~= "CDICT\x01\x00\x00" then
    vim.notify("cursor-dictionary: invalid cdict file", vim.log.levels.ERROR)
    f:close()
    return
  end

  local entry_count     = u32(header, 9)
  local key_index_start = u32(header, 13)
  local key_pool_start  = u32(header, 17)
  local val_pool_start  = u32(header, 21)

  f:seek("set", key_index_start)
  local key_index = f:read(entry_count * RECORD_SIZE)

  f:seek("set", key_pool_start)
  local key_pool = f:read(val_pool_start - key_pool_start)

  cdict.file           = f
  cdict.entry_count    = entry_count
  cdict.val_pool_start = val_pool_start
  cdict.key_index      = key_index
  cdict.key_pool       = key_pool
end

function M.lookup(word)
  if not cdict.file then return nil end
  local lower = word:lower()
  local cached = cache_get(lower)
  if cached then return cached end
  local result = binary_search(lower)
  if result then cache_put(lower, result) end
  return result
end

return M
