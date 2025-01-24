local M = {}

--- Create a floating window
---@param buf integer Buffer number
---@param width integer Window width
---@param height integer Window height
function M:create_window(buf, width, height)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
  })
  vim.api.nvim_win_set_cursor(win, { 3, 0 })

  return win
end

--- Get projectroot directory
function M.get_root()
  local patterns = { ".git", "package.json", "Cargo.toml", "Makefile" }
  local current = vim.fn.getcwd()

  for _, pattern in ipairs(patterns) do
    local match = vim.fn.finddir(pattern, current .. ";")
    if match ~= "" then
      return vim.fn.fnamemodify(match .. "/..", ":p")
    end

    match = vim.fn.findfile(pattern, current .. ";")
    if match ~= "" then
      return vim.fn.fnamemodify(match .. "/..", ":p")
    end
  end

  return current
end

--- Get path relative to project root
---@param absolute_dir string Absolute directory path
---@return string
function M.get_relative_path(absolute_dir)
  local root = M.get_root()
  local current = vim.fn.getcwd()

  -- TODO: this doesn't work outside the project root
  return "~/" .. string.sub(absolute_dir, #root + 1)
end

return M
