local M = {
  header_height = 3,
  _symbols = nil,
  _filename = nil,
}

local utils = require "codeexplorer.utils"

--- Close the CodeExplorer window and/or move the cursor to selected symbol
local function set_current_line()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]

  -- close the CodeExplorer window
  vim.api.nvim_win_close(0, false)

  -- set the cursor position
  -- skip header height lines
  if current_line > M.header_height then
    local selected = M._symbols[current_line - M.header_height]
    vim.api.nvim_win_set_cursor(0, { selected.position.row, selected.position.col - 1 })
  end
end

local function set_quickfix()
  local line = { filename = "", lnum = nil, col = nil, text = "" }
  local qf = {}
  for _, symbol in ipairs(M._symbols) do
    line = {
      filename = M._filename,
      lnum = symbol.position.row,
      col = symbol.position.col,
      text = symbol.name .. " (" .. symbol.kind .. ")",
      type = "I",
    }
    table.insert(qf, line)
  end
  vim.fn.setqflist(qf, "r")

  -- close the CodeExplorer window
  vim.api.nvim_win_close(0, false)

  vim.cmd "copen"
end

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

--- Render symbols
---@param symbols codeexplorer.Symbol[] The list of symbols to render
---@param filename string Filename
function M:render_symbols(symbols, filename)
  self._symbols = symbols
  self._filename = filename
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.min(math.floor(vim.api.nvim_win_get_width(0) * 0.8), 120)
  local height = #symbols + M.header_height

  local header = { "CodeExplorer", " " .. utils.get_relative_path(filename), string.rep("─", width) }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, header)
  local lines = {}
  for _, symbol in ipairs(symbols) do
    local line = " " .. symbol.name .. " (" .. symbol.kind .. ")"
    table.insert(lines, line)
  end
  vim.api.nvim_buf_set_lines(buf, M.header_height + 1, -1, false, lines)

  self:create_window(buf, width, height)

  -- Set buffer options
  local opts = { buf = 0 }
  vim.api.nvim_set_option_value("modifiable", false, opts)
  vim.api.nvim_set_option_value("buftype", "nofile", opts)

  -- close
  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { silent = true, noremap = true })
  -- set keyboard shortcut to fill the quickfix list
  vim.keymap.set("n", "<C-q>", set_quickfix, { buffer = true })
  -- close and go to symbol
  vim.keymap.set("n", "<CR>", set_current_line, { buffer = true })
end

return M
