local M = {}

local MAGIC = "CDICT\x01\x00\x00"
local HEADER_SIZE = 24
local RECORD_SIZE = 12

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

local function parse_csv(filepath)
  local f = io.open(filepath, "r")
  if not f then
    vim.notify("cursor-dictionary: cannot open " .. filepath, vim.log.levels.ERROR)
    return nil
  end
  local content = f:read("*a")
  f:close()

  local tbl = {}
  local pos = 1
  local len = #content

  local function parse_field()
    if pos > len then return nil end
    if content:sub(pos, pos) == '"' then
      pos = pos + 1
      local parts = {}
      while pos <= len do
        local c = content:sub(pos, pos)
        if c == '"' then
          if content:sub(pos + 1, pos + 1) == '"' then
            table.insert(parts, '"')
            pos = pos + 2
          else
            pos = pos + 1
            break
          end
        else
          table.insert(parts, c)
          pos = pos + 1
        end
      end
      return table.concat(parts)
    else
      local start = pos
      while pos <= len do
        local c = content:sub(pos, pos)
        if c == "," or c == "\n" or c == "\r" then break end
        pos = pos + 1
      end
      return content:sub(start, pos - 1)
    end
  end

  while pos <= len do
    local word = parse_field()
    if word == nil then break end
    if pos <= len and content:sub(pos, pos) == "," then pos = pos + 1 end
    local translation = parse_field()
    if word ~= "" and translation then
      local lower = word:lower()
      if not tbl[lower] then tbl[lower] = {} end
      table.insert(tbl[lower], translation)
    end
    if pos <= len and content:sub(pos, pos) == "\r" then pos = pos + 1 end
    if pos <= len and content:sub(pos, pos) == "\n" then pos = pos + 1 end
  end
  return tbl
end

local HEADWORD_MARKER = "■"
local SPECIAL_DELIMITERS = { "  {", "〔", " {" }

local function parse_eijiro_line(line)
  if not line:match("^" .. HEADWORD_MARKER) then return nil, nil end
  local rest = line:sub(#HEADWORD_MARKER + 1)
  local delim_pos = rest:find(" : ", 1, true)
  if not delim_pos then return nil, nil end
  local first_half = rest:sub(1, delim_pos - 1)
  local description = rest:sub(delim_pos + 3)
  local headword = first_half
  for _, delim in ipairs(SPECIAL_DELIMITERS) do
    local p = first_half:find(delim, 1, true)
    if p then
      headword = first_half:sub(1, p - 1)
      description = first_half:sub(p) .. " : " .. description
      break
    end
  end
  return headword:match("^%s*(.-)%s*$"), description
end

local function parse_eijiro(filepath)
  local cmd = string.format("iconv -f CP932 -t UTF-8 %q", filepath)
  local f = io.popen(cmd, "r")
  if not f then
    vim.notify("cursor-dictionary: cannot open " .. filepath, vim.log.levels.ERROR)
    return nil
  end
  local tbl = {}
  local current_lower = nil
  for raw_line in f:lines() do
    local line = raw_line:gsub("\r$", "")
    local headword, description = parse_eijiro_line(line)
    if headword then
      local lower = headword:lower()
      if not tbl[lower] then tbl[lower] = {} end
      current_lower = lower
      table.insert(tbl[current_lower], description)
    end
  end
  f:close()
  return tbl
end

local function write_cdict(tbl, output_path)
  local keys = {}
  for k in pairs(tbl) do table.insert(keys, k) end
  table.sort(keys)
  local N = #keys

  local translations = {}
  local key_pool_size = 0
  for _, k in ipairs(keys) do
    local t = table.concat(tbl[k], "\n")
    translations[k] = t
    key_pool_size = key_pool_size + #k
  end

  local key_index_start = HEADER_SIZE
  local key_pool_start  = key_index_start + N * RECORD_SIZE
  local val_pool_start  = key_pool_start + key_pool_size

  local f = io.open(output_path, "wb")
  if not f then
    vim.notify("cursor-dictionary: cannot create " .. output_path, vim.log.levels.ERROR)
    return 0
  end

  f:write(MAGIC)
  f:write(pack_u32(N) .. pack_u32(key_index_start) .. pack_u32(key_pool_start) .. pack_u32(val_pool_start))

  local k_off, v_off = 0, 0
  for _, k in ipairs(keys) do
    f:write(pack_u32(k_off) .. pack_u16(#k) .. pack_u32(v_off) .. pack_u16(#translations[k]))
    k_off = k_off + #k
    v_off = v_off + #translations[k]
  end

  for _, k in ipairs(keys) do f:write(k) end
  for _, k in ipairs(keys) do f:write(translations[k]) end

  f:close()
  return N
end

function M.build(filetype, input_path, output_path)
  vim.notify("cursor-dictionary: parsing " .. input_path .. " ...")

  local tbl
  if filetype == "eijiro" then
    tbl = parse_eijiro(input_path)
  else
    tbl = parse_csv(input_path)
  end
  if not tbl then return end

  vim.notify("cursor-dictionary: building " .. output_path .. " ...")
  local n = write_cdict(tbl, output_path)
  if n > 0 then
    vim.notify(string.format("cursor-dictionary: done (%d entries) → %s", n, output_path))
  end
end

return M
