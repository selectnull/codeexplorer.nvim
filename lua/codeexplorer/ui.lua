local M = {
  header_height = 3,
  symbols = nil,
  visible_symbols = nil,
  expanded = nil,
  filename = nil,
  buf = nil,
}

local utils = require "codeexplorer.utils"

---@param entry codeexplorer.SymbolEntry
---@return string
local function format_symbol(entry)
  local symbol = entry.symbol
  local indent = string.rep("  ", symbol.depth or 0)
  local marker = "  "

  if entry.has_children then
    marker = entry.expanded and "v " or "> "
  end

  return indent .. marker .. symbol.name .. " (" .. symbol.kind .. ")"
end

---@param line integer
---@return codeexplorer.SymbolEntry|nil
local function get_symbol_entry_for_line(line)
  if line <= M.header_height then
    return nil
  end

  return M.visible_symbols[line - M.header_height]
end

---@param index integer
---@return boolean
local function symbol_has_children(index)
  local symbol = M.symbols[index]
  local next_symbol = M.symbols[index + 1]

  if symbol == nil or next_symbol == nil then
    return false
  end

  return (next_symbol.depth or 0) > (symbol.depth or 0)
end

---@param child_index integer
---@return integer|nil
local function find_parent_index(child_index)
  local child = M.symbols[child_index]
  if child == nil then
    return nil
  end

  local child_depth = child.depth or 0
  if child_depth == 0 then
    return nil
  end

  for i = child_index - 1, 1, -1 do
    local candidate = M.symbols[i]
    if (candidate.depth or 0) < child_depth then
      return i
    end
  end

  return nil
end

function M:build_visible_symbols()
  local visible = {}
  local can_show_children_by_depth = {}

  for i, symbol in ipairs(self.symbols) do
    local depth = symbol.depth or 0
    local include = depth == 0 or can_show_children_by_depth[depth - 1] == true

    local has_children = symbol_has_children(i)
    local expanded = self.expanded[i] == true
    can_show_children_by_depth[depth] = include and (not has_children or expanded)

    if include then
      table.insert(visible, {
        symbol = symbol,
        index = i,
        has_children = has_children,
        expanded = expanded,
      })
    end
  end

  return visible
end

function M:refresh_symbols()
  if self.buf == nil then
    return
  end

  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  self.visible_symbols = self:build_visible_symbols()
  self:set_buf_modifiable(self.buf, true)
  self:render_symbols(self.buf, self.visible_symbols)
  self:set_buf_modifiable(self.buf, false)
  vim.api.nvim_win_set_cursor(0, { math.min(cursor_line, self.header_height + #self.visible_symbols), 0 })
end

--- Close the CodeExplorer window and/or move the cursor to selected symbol
local function set_current_line()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local selected = get_symbol_entry_for_line(current_line)

  -- close the CodeExplorer window
  vim.api.nvim_win_close(0, false)

  -- set the cursor position
  if selected ~= nil then
    vim.api.nvim_win_set_cursor(0, { selected.symbol.position.row, selected.symbol.position.col - 1 })
  end
end

local function set_quickfix()
  local line = { filename = "", lnum = nil, col = nil, text = "" }
  local qf = {}
  for _, entry in ipairs(M.visible_symbols) do
    local symbol = entry.symbol
    line = {
      filename = M.filename,
      lnum = symbol.position.row,
      col = symbol.position.col,
      text = format_symbol(entry),
      type = "I",
    }
    table.insert(qf, line)
  end
  vim.fn.setqflist(qf, "r")

  -- close the CodeExplorer window
  vim.api.nvim_win_close(0, false)

  vim.cmd "copen"
end

local function expand_current_symbol()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local selected = get_symbol_entry_for_line(current_line)

  if selected == nil or not selected.has_children then
    return
  end

  M.expanded[selected.index] = true
  M:refresh_symbols()
  vim.api.nvim_win_set_cursor(0, { current_line, 0 })
end

local function collapse_current_symbol()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local selected = get_symbol_entry_for_line(current_line)

  if selected == nil then
    return
  end

  local collapse_index = nil

  if selected.has_children and selected.expanded then
    collapse_index = selected.index
  else
    local parent_index = find_parent_index(selected.index)
    if parent_index ~= nil and M.expanded[parent_index] == true then
      collapse_index = parent_index
    end
  end

  if collapse_index == nil then
    return
  end

  M.expanded[collapse_index] = false
  M:refresh_symbols()
  vim.api.nvim_win_set_cursor(0, { math.min(current_line, M.header_height + #M.visible_symbols), 0 })
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
  vim.api.nvim_win_set_cursor(win, { self.header_height + 1, 0 })

  return win
end

function M:create_buffer()
  local buf = vim.api.nvim_create_buf(false, true)

  -- set buffer options
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })

  return buf
end

function M:set_buf_modifiable(buf, modifiable)
  vim.api.nvim_set_option_value("modifiable", modifiable, { buf = buf })
end

function M:set_keymaps(buf)
  -- close
  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { silent = true, noremap = true })
  -- set keyboard shortcut to fill the quickfix list
  vim.keymap.set("n", "<C-q>", set_quickfix, { buffer = true })
  -- close and go to symbol
  vim.keymap.set("n", "<CR>", set_current_line, { buffer = true })
  -- expand current symbol
  vim.keymap.set("n", "l", expand_current_symbol, { buffer = true })
  vim.keymap.set("n", "<Right>", expand_current_symbol, { buffer = true })
  -- collapse current symbol
  vim.keymap.set("n", "h", collapse_current_symbol, { buffer = true })
  vim.keymap.set("n", "<Left>", collapse_current_symbol, { buffer = true })
end

--- Render window header
function M:render_header(buf, width)
  local header = { "CodeExplorer", " " .. utils.get_relative_path(self.filename), string.rep("─", width) }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, header)
end

--- Render symbols
function M:render_symbols(buf, symbols)
  local lines = {}
  for _, entry in ipairs(symbols) do
    local line = " " .. format_symbol(entry)
    table.insert(lines, line)
  end
  vim.api.nvim_buf_set_lines(buf, M.header_height, -1, false, lines)
end

--- Render symbols
---@param symbols codeexplorer.Symbol[] The list of symbols to render
---@param filename string Filename
function M:open(symbols, filename)
  self.symbols = symbols
  self.expanded = {}
  self.filename = filename
  self.visible_symbols = self:build_visible_symbols()

  local width = math.min(math.floor(vim.api.nvim_win_get_width(0) * 0.8), 120)
  local height = #symbols + M.header_height

  local buf = self:create_buffer()

  self:render_header(buf, width)
  self:render_symbols(buf, self.visible_symbols)

  self:create_window(buf, width, height)
  self.buf = buf
  self:set_buf_modifiable(buf, false)
  self:set_keymaps(buf)
end

return M
