local M = {}

local win_id = nil

function M.show(text)
  M.close()

  local lines = { text }
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  win_id = vim.api.nvim_open_win(buf, false, {
    relative = "cursor",
    row = -2,
    col = 0,
    width = math.max(#text + 2, 10),
    height = 1,
    style = "minimal",
    border = "rounded",
  })
end

function M.close()
  if win_id and vim.api.nvim_win_is_valid(win_id) then
    vim.api.nvim_win_close(win_id, true)
  end
  win_id = nil
end

return M
