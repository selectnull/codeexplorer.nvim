local M = {
  header_height = 3,
  symbols = nil,
  visible_symbols = nil,
  expanded = nil,
  filename = nil,
  buf = nil,
  config = {
    icons = true,
  },
}

local utils = require "codeexplorer.utils"
local highlights_ns = vim.api.nvim_create_namespace "codeexplorer_highlights"

local kind_highlights = {
  File = "CodeExplorerKindFile",
  Module = "CodeExplorerKindModule",
  Namespace = "CodeExplorerKindNamespace",
  Package = "CodeExplorerKindPackage",
  Class = "CodeExplorerKindClass",
  Method = "CodeExplorerKindMethod",
  Property = "CodeExplorerKindProperty",
  Field = "CodeExplorerKindField",
  Constructor = "CodeExplorerKindConstructor",
  Enum = "CodeExplorerKindEnum",
  Interface = "CodeExplorerKindInterface",
  Function = "CodeExplorerKindFunction",
  Variable = "CodeExplorerKindVariable",
  Constant = "CodeExplorerKindConstant",
  String = "CodeExplorerKindString",
  Number = "CodeExplorerKindNumber",
  Boolean = "CodeExplorerKindBoolean",
  Array = "CodeExplorerKindArray",
  Object = "CodeExplorerKindObject",
  Key = "CodeExplorerKindKey",
  Null = "CodeExplorerKindNull",
  EnumMember = "CodeExplorerKindEnumMember",
  Struct = "CodeExplorerKindStruct",
  Event = "CodeExplorerKindEvent",
  Operator = "CodeExplorerKindOperator",
  TypeParameter = "CodeExplorerKindTypeParameter",
}

local default_kind_icons = {
  File = "󰈙",
  Module = "󰆧",
  Namespace = "󰅩",
  Package = "󰏗",
  Class = "󰠱",
  Method = "󰊕",
  Property = "󰜢",
  Field = "󰜢",
  Constructor = "",
  Enum = "󰕘",
  Interface = "",
  Function = "󰊕",
  Variable = "󰀫",
  Constant = "󰏿",
  String = "󰀬",
  Number = "󰎠",
  Boolean = "󰨙",
  Array = "󰅪",
  Object = "󰅩",
  Key = "󰌋",
  Null = "󰟢",
  EnumMember = "󰕘",
  Struct = "󰠱",
  Event = "",
  Operator = "󰆕",
  TypeParameter = "󰊄",
}

---@param kind string
---@return string
local function get_icon(kind)
  if M.config.icons == false then
    return ""
  end

  if type(M.config.icons) == "table" then
    local override = M.config.icons[kind]
    if override ~= nil then
      if override == false then
        return ""
      end

      if type(override) == "string" then
        return override
      end
    end
  end

  return default_kind_icons[kind] or "*"
end

local function define_highlights()
  local links = {
    CodeExplorerKindFile = "Directory",
    CodeExplorerKindModule = "Include",
    CodeExplorerKindNamespace = "Include",
    CodeExplorerKindPackage = "Include",
    CodeExplorerKindClass = "Type",
    CodeExplorerKindMethod = "Function",
    CodeExplorerKindProperty = "Identifier",
    CodeExplorerKindField = "Identifier",
    CodeExplorerKindConstructor = "Function",
    CodeExplorerKindEnum = "Type",
    CodeExplorerKindInterface = "Type",
    CodeExplorerKindFunction = "Function",
    CodeExplorerKindVariable = "Identifier",
    CodeExplorerKindConstant = "Constant",
    CodeExplorerKindString = "String",
    CodeExplorerKindNumber = "Number",
    CodeExplorerKindBoolean = "Boolean",
    CodeExplorerKindArray = "Type",
    CodeExplorerKindObject = "Type",
    CodeExplorerKindKey = "Identifier",
    CodeExplorerKindNull = "Comment",
    CodeExplorerKindEnumMember = "Constant",
    CodeExplorerKindStruct = "Type",
    CodeExplorerKindEvent = "Special",
    CodeExplorerKindOperator = "Operator",
    CodeExplorerKindTypeParameter = "Type",
  }

  for group, target in pairs(links) do
    vim.api.nvim_set_hl(0, group, { link = target, default = true })
  end
end

---@param entry codeexplorer.SymbolEntry
---@return string
local function format_symbol(entry)
  local symbol = entry.symbol
  local indent = string.rep("  ", symbol.depth or 0)
  local marker = "  "

  if entry.has_children then
    marker = entry.expanded and "▼ " or "▶ "
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
  local line_segments = {}

  vim.api.nvim_buf_clear_namespace(buf, highlights_ns, 0, -1)

  for _, entry in ipairs(symbols) do
    local symbol = entry.symbol
    local indent = string.rep("  ", symbol.depth or 0)
    local marker = "  "

    if entry.has_children then
      marker = entry.expanded and "▼ " or "▶ "
    end

    local icon = get_icon(symbol.kind)
    local icon_segment = icon ~= "" and (icon .. " ") or ""
    local prefix = " " .. indent .. marker .. icon_segment
    local line = prefix .. symbol.name .. " (" .. symbol.kind .. ")"
    local name_start_col = #prefix
    local name_end_col = name_start_col + #symbol.name
    local icon_start_col = #(" " .. indent .. marker)
    local icon_end_col = icon_start_col + #icon

    table.insert(lines, line)
    table.insert(line_segments, {
      group = kind_highlights[symbol.kind] or "Identifier",
      start_col = name_start_col,
      end_col = name_end_col,
      icon_start_col = icon_start_col,
      icon_end_col = icon_end_col,
    })
  end

  vim.api.nvim_buf_set_lines(buf, M.header_height, -1, false, lines)

  for i, segment in ipairs(line_segments) do
    if segment.icon_end_col > segment.icon_start_col then
      vim.api.nvim_buf_add_highlight(
        buf,
        highlights_ns,
        segment.group,
        M.header_height + i - 1,
        segment.icon_start_col,
        segment.icon_end_col
      )
    end

    vim.api.nvim_buf_add_highlight(
      buf,
      highlights_ns,
      segment.group,
      M.header_height + i - 1,
      segment.start_col,
      segment.end_col
    )
  end
end

---@param config table|nil
function M:set_config(config)
  self.config = vim.tbl_deep_extend("force", {
    icons = true,
  }, config or {})
end

--- Render symbols
---@param symbols codeexplorer.Symbol[] The list of symbols to render
---@param filename string Filename
function M:open(symbols, filename)
  define_highlights()

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
