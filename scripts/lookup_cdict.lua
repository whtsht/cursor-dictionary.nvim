-- Usage: lua scripts/lookup_cdict.lua <path.cdict> <word>
local filepath = arg[1]
local word     = arg[2] and arg[2]:lower()

if not filepath or not word then
  io.stderr:write("Usage: lua lookup_cdict.lua <path.cdict> <word>\n")
  os.exit(1)
end

local RECORD_SIZE = 12

local function u32(s, pos)
  local a, b, c, d = string.byte(s, pos, pos + 3)
  return a + b * 256 + c * 65536 + d * 16777216
end

local function u16(s, pos)
  local a, b = string.byte(s, pos, pos + 1)
  return a + b * 256
end

local f = io.open(filepath, "rb")
if not f then io.stderr:write("cannot open: " .. filepath .. "\n"); os.exit(1) end

local header = f:read(24)
if not header or #header < 24 or header:sub(1, 8) ~= "CDICT\x01\x00\x00" then
  io.stderr:write("invalid cdict file\n"); os.exit(1)
end

local entry_count     = u32(header,  9)
local key_index_start = u32(header, 13)
local key_pool_start  = u32(header, 17)
local val_pool_start  = u32(header, 21)

io.stderr:write(string.format("entries=%d  key_index=0x%x  key_pool=0x%x  val_pool=0x%x\n",
  entry_count, key_index_start, key_pool_start, val_pool_start))

f:seek("set", key_index_start)
local key_index = f:read(entry_count * RECORD_SIZE)

f:seek("set", key_pool_start)
local key_pool = f:read(val_pool_start - key_pool_start)

-- binary search
local lo, hi = 0, entry_count - 1
local found = false
while lo <= hi do
  local mid     = math.floor((lo + hi) / 2)
  local rec_pos = mid * RECORD_SIZE + 1
  local key_offset = u32(key_index, rec_pos)
  local key_len    = u16(key_index, rec_pos + 4)
  local val_offset = u32(key_index, rec_pos + 6)
  local val_len    = u16(key_index, rec_pos + 10)
  local key = key_pool:sub(key_offset + 1, key_offset + key_len)

  if key == word then
    io.stderr:write(string.format(
      "found at index %d: key_offset=%d key_len=%d val_offset=%d val_len=%d\n",
      mid, key_offset, key_len, val_offset, val_len))
    f:seek("set", val_pool_start + val_offset)
    local val = f:read(val_len)
    print(val)
    found = true
    break
  elseif key < word then
    lo = mid + 1
  else
    hi = mid - 1
  end
end

if not found then
  io.stderr:write("not found: " .. word .. "\n")
end

f:close()
