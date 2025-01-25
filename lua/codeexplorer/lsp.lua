local M = {}

M.get_kind_name = function(self, kind)
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

--- Query the Language Server for the document symbols
---@param callback function
M.query_symbols = function(self, callback)
  local symbols = {}

  local request_handler = function(err, result, _, _)
    if err ~= nil then
      vim.notify("Error when requesting symbols: " .. err.message)
      return
    end

    local new_symbol = { name = nil, kind = nil, position = { -1, -1 } }

    for _, symbol in ipairs(result) do
      new_symbol = {
        name = symbol.name,
        kind = self:get_kind_name(symbol.kind),
        position = { row = symbol.selectionRange.start.line + 1, col = symbol.selectionRange.start.character + 1 },
      }
      table.insert(symbols, new_symbol)
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

return M
