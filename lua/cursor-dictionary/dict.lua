local M = {}

local entries = {}

local function load_csv(filepath)
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

local HEADWORD_MARKER = "■"
local SPECIAL_DELIMITERS = { "  {", "〔", " {" }

local function parse_eijiro_line(line)
  if not line:match("^" .. HEADWORD_MARKER) then
    return nil, nil
  end
  local rest = line:sub(#HEADWORD_MARKER + 1)
  local delim_pos = rest:find(" : ", 1, true)
  if not delim_pos then
    return nil, nil
  end
  local first_half = rest:sub(1, delim_pos - 1)
  local description = rest:sub(delim_pos + 3)
  local headword = first_half
  for _, delim in ipairs(SPECIAL_DELIMITERS) do
    local pos = first_half:find(delim, 1, true)
    if pos then
      headword = first_half:sub(1, pos - 1)
      description = first_half:sub(pos) .. " : " .. description
      break
    end
  end
  headword = headword:match("^%s*(.-)%s*$")
  return headword, description
end

local function load_eijiro(filepath)
  local cmd = string.format("iconv -f CP932 -t UTF-8 %q", filepath)
  local f = io.popen(cmd, "r")
  if not f then
    vim.notify("cursor-dictionary: cannot open " .. filepath, vim.log.levels.ERROR)
    return
  end
  local current_head = nil
  local current_lines = {}
  for line in f:lines() do
    line = line:gsub("\r$", "")
    local headword, description = parse_eijiro_line(line)
    if headword then
      if headword ~= current_head then
        if current_head then
          entries[current_head:lower()] = table.concat(current_lines, "\n")
        end
        current_head = headword
        current_lines = { description }
      else
        table.insert(current_lines, description)
      end
    end
  end
  if current_head then
    entries[current_head:lower()] = table.concat(current_lines, "\n")
  end
  f:close()
end

function M.load(filepath, filetype)
  entries = {}
  if filetype == "eijiro" then
    load_eijiro(filepath)
  else
    load_csv(filepath)
  end
end

function M.lookup(word)
  return entries[word:lower()]
end

return M
