-- Usage: lua scripts/build_json.lua <input.json> <output.cdict>
-- JSON format: {"word": "translation", ...}
-- Requires Lua 5.3+ (uses string.pack)

local input_path  = arg[1]
local output_path = arg[2]
if not input_path or not output_path then
  print("Usage: lua build_json.lua <input.json> <output.cdict>")
  os.exit(1)
end

-- ── helpers ────────────────────────────────────────────────────────────────

local function pack_u32(n)
  return string.char(
    n % 256,
    math.floor(n / 256) % 256,
    math.floor(n / 65536) % 256,
    math.floor(n / 16777216) % 256
  )
end

local function pack_u16(n)
  return string.char(n % 256, math.floor(n / 256) % 256)
end

-- ── minimal JSON parser (string values only) ─────────────────────────────

local function parse_json_string(s, pos)
  -- pos points to the opening "
  pos = pos + 1  -- skip "
  local parts = {}
  while pos <= #s do
    local c = s:sub(pos, pos)
    if c == '"' then
      return table.concat(parts), pos + 1
    elseif c == '\\' then
      local esc = s:sub(pos + 1, pos + 1)
      if     esc == '"'  then table.insert(parts, '"');  pos = pos + 2
      elseif esc == '\\' then table.insert(parts, '\\'); pos = pos + 2
      elseif esc == '/'  then table.insert(parts, '/');  pos = pos + 2
      elseif esc == 'n'  then table.insert(parts, '\n'); pos = pos + 2
      elseif esc == 'r'  then table.insert(parts, '\r'); pos = pos + 2
      elseif esc == 't'  then table.insert(parts, '\t'); pos = pos + 2
      elseif esc == 'u'  then
        -- decode \uXXXX as UTF-8
        local hex = s:sub(pos + 2, pos + 5)
        local cp  = tonumber(hex, 16) or 0
        if cp < 0x80 then
          table.insert(parts, string.char(cp))
        elseif cp < 0x800 then
          table.insert(parts, string.char(
            0xC0 + math.floor(cp / 64),
            0x80 + cp % 64))
        else
          table.insert(parts, string.char(
            0xE0 + math.floor(cp / 4096),
            0x80 + math.floor(cp / 64) % 64,
            0x80 + cp % 64))
        end
        pos = pos + 6
      else
        table.insert(parts, esc); pos = pos + 2
      end
    else
      table.insert(parts, c); pos = pos + 1
    end
  end
  error("unterminated string")
end

local function skip_ws(s, pos)
  while pos <= #s and s:sub(pos, pos):match("%s") do pos = pos + 1 end
  return pos
end

local function parse_json_object(s)
  local tbl = {}
  local pos = skip_ws(s, 1)
  assert(s:sub(pos, pos) == '{', "expected '{'")
  pos = pos + 1
  pos = skip_ws(s, pos)
  if s:sub(pos, pos) == '}' then return tbl end
  while true do
    pos = skip_ws(s, pos)
    assert(s:sub(pos, pos) == '"', "expected '\"' for key at pos " .. pos)
    local key; key, pos = parse_json_string(s, pos)
    pos = skip_ws(s, pos)
    assert(s:sub(pos, pos) == ':', "expected ':' at pos " .. pos)
    pos = skip_ws(s, pos + 1)
    assert(s:sub(pos, pos) == '"', "expected '\"' for value at pos " .. pos)
    local val; val, pos = parse_json_string(s, pos)
    tbl[key:lower()] = val
    pos = skip_ws(s, pos)
    local ch = s:sub(pos, pos)
    if ch == '}' then break end
    assert(ch == ',', "expected ',' or '}' at pos " .. pos)
    pos = pos + 1
  end
  return tbl
end

-- ── read input ─────────────────────────────────────────────────────────────

local fin = io.open(input_path, "r")
if not fin then
  io.stderr:write("cannot open " .. input_path .. "\n")
  os.exit(1)
end
local content = fin:read("*a")
fin:close()

io.write("parsing " .. input_path .. " ...\n")
io.flush()
local tbl = parse_json_object(content)

-- ── write .cdict ────────────────────────────────────────────────────────────

local MAGIC       = "CDICT\x01\x00\x00"
local HEADER_SIZE = 24
local RECORD_SIZE = 12

local keys = {}
for k in pairs(tbl) do table.insert(keys, k) end
table.sort(keys)
local N = #keys

local key_pool_size = 0
for _, k in ipairs(keys) do key_pool_size = key_pool_size + #k end

local key_index_start = HEADER_SIZE
local key_pool_start  = key_index_start + N * RECORD_SIZE
local val_pool_start  = key_pool_start  + key_pool_size

io.write("building " .. output_path .. " ...\n")
io.flush()

local fout = io.open(output_path, "wb")
if not fout then
  io.stderr:write("cannot create " .. output_path .. "\n")
  os.exit(1)
end

fout:write(MAGIC)
fout:write(pack_u32(N) .. pack_u32(key_index_start) .. pack_u32(key_pool_start) .. pack_u32(val_pool_start))

local k_off, v_off = 0, 0
for _, k in ipairs(keys) do
  local v = tbl[k]
  fout:write(pack_u32(k_off) .. pack_u16(#k) .. pack_u32(v_off) .. pack_u16(#v))
  k_off = k_off + #k
  v_off = v_off + #v
end

for _, k in ipairs(keys) do fout:write(k) end
for _, k in ipairs(keys) do fout:write(tbl[k]) end

fout:close()
print(string.format("done (%d entries) → %s", N, output_path))
