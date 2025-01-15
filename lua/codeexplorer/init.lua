local M = {}

local lsp = require "codeexplorer.lsp"

---@class codeexplorer.Position
---@field row integer
---@field col integer

---@class codeexplorer.Symbol
---@field name string
---@field kind string
---@field position codeexplorer.Position

--- Close the CodeExplorer window and/or move the cursor to selected symbol
local function set_current_line()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]

  -- close the CodeExplorer window
  vim.api.nvim_win_close(0, false)

  -- set the cursor position
  -- header height is 2 lines, skip it
  if current_line > 2 then
    local selected = M._symbols[current_line - 2]
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
local function create_window(buf, width, height)
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
local function render_symbols(symbols)
  local buf = vim.api.nvim_create_buf(false, true)
  local width = 60
  local header_height = 2
  local height = #symbols + header_height

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "CodeExplorer", string.rep("—", width) })
  local lines = {}
  for _, symbol in ipairs(symbols) do
    local line = symbol.name .. " (" .. symbol.kind .. ")"
    table.insert(lines, line)
  end
  vim.api.nvim_buf_set_lines(buf, header_height + 1, -1, false, lines)

  create_window(buf, width, height)

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

--- Query the Language Server for the document symbols
---@param render_callback function
local function query_symbols(render_callback)
  M._filename = vim.api.nvim_buf_get_name(0)
  local request_handler = function(err, result, _, _)
    local symbols = {}
    if err ~= nil then
      vim.notify("Error when requesting symbols: " .. err.message)
      return
    end

    local new_symbol = { name = nil, kind = nil, position = { -1, -1 } }

    for _, symbol in ipairs(result) do
      new_symbol = {
        name = symbol.name,
        kind = lsp.get_kind_name(symbol.kind),
        position = { row = symbol.selectionRange.start.line + 1, col = symbol.selectionRange.start.character + 1 },
      }
      table.insert(symbols, new_symbol)
    end
    M._symbols = symbols
    render_callback(symbols)
  end

  vim.lsp.buf_request(
    0,
    "textDocument/documentSymbol",
    { textDocument = vim.lsp.util.make_text_document_params() },
    request_handler
  )
end

--- CodeExplorer command
vim.api.nvim_create_user_command("CodeExplorer", function()
  query_symbols(render_symbols)
end, {})

return M
