local M = {}

local function set_current_line()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local line_content = vim.api.nvim_buf_get_lines(0, current_line - 1, current_line, false)[1]

  local row, col = string.match(line_content, "- (%d+):(%d+)$")

  -- close the floating window
  vim.api.nvim_win_close(0, false)

  -- set the cursor position
  vim.api.nvim_win_set_cursor(0, { tonumber(row), tonumber(col) - 1 })
end

local function create_window(output)
  -- Display in a floating window
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)

  local width = 60
  local height = #output
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
  })

  -- Set buffer options
  local opts = { buf = 0 }
  vim.api.nvim_set_option_value("modifiable", false, opts)
  vim.api.nvim_set_option_value("buftype", "nofile", opts)

  -- close
  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { silent = true, noremap = true })
  -- close and go to symbol
  vim.keymap.set("n", "<CR>", set_current_line, { buffer = true })
end

local function get_kind_name(kind)
  local kinds = {
    [1] = "File",
    [2] = "Module",
    [3] = "Namespace",
    [4] = "Package",
    [5] = "Class",
    [6] = "Method",
    [7] = "Property",
    [8] = "Field",
    [9] = "Constructor",
    [10] = "Enum",
    [11] = "Interface",
    [12] = "Function",
    [13] = "Variable",
    [14] = "Constant",
    [15] = "String",
    [16] = "Number",
    [17] = "Boolean",
    [18] = "Array",
    [19] = "Object",
    [20] = "Key",
    [21] = "Null",
    [22] = "EnumMember",
    [23] = "Struct",
    [24] = "Event",
    [25] = "Operator",
    [26] = "TypeParameter",
  }
  return kinds[kind] or "Unknown"
end

-- Function to get and print document symbols
local function list_symbols(callback)
  local request_handler = function(err, result, ctx, _)
    local symbols = {}
    if err ~= nil then
      vim.notify("Error when requesting symbols: " .. err.message)
      return
    end

    for _, symbol in ipairs(result) do
      local line = "("
        .. get_kind_name(symbol.kind)
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

local function show_code_explorer()
  list_symbols(create_window)
end

-- Command to display the results
vim.api.nvim_create_user_command("CodeExplorer", show_code_explorer, {})

return M
