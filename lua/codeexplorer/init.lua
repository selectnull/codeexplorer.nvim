local lsp = require "codeexplorer.lsp"

--- Close the CodeExplorer window and move the cursor to selected symbol
local function set_current_line()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local line_content = vim.api.nvim_buf_get_lines(0, current_line - 1, current_line, false)[1]

  local row, col = string.match(line_content, "- (%d+):(%d+)$")

  -- close the CodeExplorer window
  vim.api.nvim_win_close(0, false)

  -- set the cursor position
  if row and col then
    vim.api.nvim_win_set_cursor(0, { tonumber(row), tonumber(col) - 1 })
  end
end

--- Create a CodeExplorer window
---@param output [string] The text content (a list of lines) of the window
local function create_window(output)
  local buf = vim.api.nvim_create_buf(false, true)
  local width = 60
  local header_height = 2
  local height = #output + header_height

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "CodeExplorer", string.rep("—", width) })
  vim.api.nvim_buf_set_lines(buf, header_height + 1, -1, false, output)

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

  -- Set buffer options
  local opts = { buf = 0 }
  vim.api.nvim_set_option_value("modifiable", false, opts)
  vim.api.nvim_set_option_value("buftype", "nofile", opts)

  -- close
  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { silent = true, noremap = true })
  -- close and go to symbol
  vim.keymap.set("n", "<CR>", set_current_line, { buffer = true })
end

--- Query the Language Server for the document symbols
---@param callback function
local function query_symbols(callback)
  local request_handler = function(err, result, _, _)
    local symbols = {}
    if err ~= nil then
      vim.notify("Error when requesting symbols: " .. err.message)
      return
    end

    for _, symbol in ipairs(result) do
      local line = "("
        .. lsp.get_kind_name(symbol.kind)
        .. ") "
        .. symbol.name
        .. " - "
        .. symbol.selectionRange.start.line + 1
        .. ":"
        .. symbol.selectionRange.start.character + 1
      table.insert(symbols, line)
    end
    callback(symbols)
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
  query_symbols(create_window)
end, {})
