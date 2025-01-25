local M = {}

--- Get project root directory
local function get_root()
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
  local root = get_root()

  -- FIX: this doesn't work outside the project root
  return "~/" .. string.sub(absolute_dir, #root + 1)
end

return M
