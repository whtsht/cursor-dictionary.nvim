-- Usage: lua scripts/inspect_cdict.lua <file.cdict>

local filepath = arg[1]
if not filepath then
  print("Usage: lua inspect_cdict.lua <file.cdict>")
  os.exit(1)
end

local f = io.open(filepath, "rb")
if not f then
  print("Cannot open: " .. filepath)
  os.exit(1)
end

local function u32(s, pos)
  local a, b, c, d = string.byte(s, pos, pos + 3)
  return a + b * 256 + c * 65536 + d * 16777216
end

local function u16(s, pos)
  local a, b = string.byte(s, pos, pos + 1)
  return a + b * 256
end

-- Header
local header = f:read(24)
local magic           = header:sub(1, 8)
local entry_count     = u32(header, 9)
local key_index_start = u32(header, 13)
local key_pool_start  = u32(header, 17)
local val_pool_start  = u32(header, 21)

local file_size = f:seek("end")

local key_index_size = entry_count * 12
local key_pool_size  = val_pool_start - key_pool_start
local val_pool_size  = file_size - val_pool_start

print("=== Header ===")
print(string.format("  magic:           %q", magic))
print(string.format("  entry_count:     %d", entry_count))
print(string.format("  key_index_start: %d (0x%x)", key_index_start, key_index_start))
print(string.format("  key_pool_start:  %d (0x%x)", key_pool_start, key_pool_start))
print(string.format("  val_pool_start:  %d (0x%x)", val_pool_start, val_pool_start))
print(string.format("  file_size:       %d bytes", file_size))

print("")
print("=== Section Sizes ===")
print(string.format("  Key Index: %d bytes (%d entries x 12)", key_index_size, entry_count))
print(string.format("  Key Pool:  %d bytes", key_pool_size))
print(string.format("  Val Pool:  %d bytes", val_pool_size))

-- Load key index and key pool
f:seek("set", key_index_start)
local key_index = f:read(key_index_size)
f:seek("set", key_pool_start)
local key_pool = f:read(key_pool_size)

local SAMPLE = 5
print("")
print(string.format("=== Key Index (first %d entries) ===", SAMPLE))
for i = 0, SAMPLE - 1 do
  local rec = i * 12 + 1
  local k_off = u32(key_index, rec)
  local k_len = u16(key_index, rec + 4)
  local v_off = u32(key_index, rec + 6)
  local v_len = u16(key_index, rec + 10)
  local key = key_pool:sub(k_off + 1, k_off + k_len)
  print(string.format("  [%d] key=%-20s k_off=%d k_len=%d v_off=%d v_len=%d",
    i, string.format("%q", key), k_off, k_len, v_off, v_len))
end

print("")
print(string.format("=== Val Pool (first %d entries) ===", SAMPLE))
for i = 0, SAMPLE - 1 do
  local rec = i * 12 + 1
  local k_off = u32(key_index, rec)
  local k_len = u16(key_index, rec + 4)
  local v_off = u32(key_index, rec + 6)
  local v_len = u16(key_index, rec + 10)
  local key = key_pool:sub(k_off + 1, k_off + k_len)
  f:seek("set", val_pool_start + v_off)
  local val = f:read(v_len)
  print(string.format("  [%d] key=%q", i, key))
  print(string.format("       val=%q", val))
end

f:close()
