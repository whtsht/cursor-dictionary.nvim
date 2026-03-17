local M = {}

local win_id = nil

function M.show(text, position)
  M.close()

  local lines = vim.split(text, "\n", { plain = true })
  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, #l)
  end
  width = math.max(width + 2, 10)
  local height = #lines
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local win_opts
  if position == "fixed" then
    win_opts = {
      relative = "editor",
      row = vim.o.lines - 4,
      col = math.floor((vim.o.columns - width) / 2),
      width = width,
      height = height,
      style = "minimal",
      border = "rounded",
    }
  else
    win_opts = {
      relative = "cursor",
      row = -(height + 2),
      col = 0,
      width = width,
      height = height,
      style = "minimal",
      border = "rounded",
    }
  end

  win_id = vim.api.nvim_open_win(buf, false, win_opts)
end

function M.close()
  if win_id and vim.api.nvim_win_is_valid(win_id) then
    vim.api.nvim_win_close(win_id, true)
  end
  win_id = nil
end

return M
