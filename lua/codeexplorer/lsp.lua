local M = {}

local lsp_kinds = {
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

M.get_kind_name = function(kind)
  return lsp_kinds[kind] or "Unknown"
end

---@param symbol lsp.DocumentSymbol
---@param depth integer
---@param out codeexplorer.Symbol[]
local function flatten_document_symbol(symbol, depth, out)
  table.insert(out, {
    name = symbol.name,
    kind = M.get_kind_name(symbol.kind),
    position = {
      row = symbol.selectionRange.start.line + 1,
      col = symbol.selectionRange.start.character + 1,
    },
    depth = depth,
  })

  if symbol.children == nil then
    return
  end

  for _, child in ipairs(symbol.children) do
    flatten_document_symbol(child, depth + 1, out)
  end
end

---@param symbols lsp.DocumentSymbol[]
---@return codeexplorer.Symbol[]
local function parse_document_symbols(symbols)
  local parsed_symbols = {}

  for _, symbol in ipairs(symbols) do
    flatten_document_symbol(symbol, 0, parsed_symbols)
  end

  return parsed_symbols
end

---@param symbols lsp.SymbolInformation[]
---@return codeexplorer.Symbol[]
local function parse_symbol_information(symbols)
  local parsed_symbols = {}

  for _, symbol in ipairs(symbols) do
    table.insert(parsed_symbols, {
      name = symbol.name,
      kind = M.get_kind_name(symbol.kind),
      position = {
        row = symbol.location.range.start.line + 1,
        col = symbol.location.range.start.character + 1,
      },
      depth = 0,
    })
  end

  return parsed_symbols
end

--- Query the Language Server for the document symbols
---@param callback function
function M:query_symbols(callback)
  local request_handler = function(err, result, _, _)
    if err ~= nil then
      vim.notify("Error when requesting symbols: " .. err.message)
      return
    end

    if result == nil or vim.tbl_isempty(result) then
      callback {}
      return
    end

    local first_item = result[1]

    if first_item.selectionRange ~= nil then
      callback(parse_document_symbols(result))
      return
    end

    callback(parse_symbol_information(result))
  end

  vim.lsp.buf_request(
    0,
    "textDocument/documentSymbol",
    { textDocument = vim.lsp.util.make_text_document_params() },
    request_handler
  )
end

return M
