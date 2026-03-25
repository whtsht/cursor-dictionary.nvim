local M = {}

local buf_id = nil
local win_id = nil

local function get_or_create_buf()
  if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
    return buf_id
  end
  buf_id = vim.api.nvim_create_buf(false, true)
  vim.bo[buf_id].buftype  = "nofile"
  vim.bo[buf_id].swapfile = false
  return buf_id
end

function M.show(text)
  local lines = vim.split(text, "\n", { plain = true })
  local buf   = get_or_create_buf()

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  if win_id and vim.api.nvim_win_is_valid(win_id) then
    return
  end

  local current_win = vim.api.nvim_get_current_win()
  local height      = math.min(#lines, 12)
  vim.cmd("noautocmd botright " .. height .. "split")
  win_id = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win_id, buf)
  vim.wo[win_id].winfixheight    = true
  vim.wo[win_id].wrap            = true
  vim.wo[win_id].number          = false
  vim.wo[win_id].relativenumber  = false
  vim.wo[win_id].signcolumn      = "no"
  vim.api.nvim_set_current_win(current_win)
end

function M.is_dict_win()
  return win_id ~= nil and vim.api.nvim_get_current_win() == win_id
end

function M.close()
  if win_id and vim.api.nvim_win_is_valid(win_id) then
    vim.api.nvim_win_close(win_id, true)
  end
  win_id = nil
end

return M
