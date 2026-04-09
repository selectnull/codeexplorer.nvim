describe("codeexplorer.lsp query_symbols", function()
  local lsp
  local original_buf_request

  before_each(function()
    package.loaded["codeexplorer.lsp"] = nil
    lsp = require "codeexplorer.lsp"
    original_buf_request = vim.lsp.buf_request
  end)

  after_each(function()
    vim.lsp.buf_request = original_buf_request
  end)

  it("returns empty list for nil response", function()
    vim.lsp.buf_request = function(_, _, _, handler)
      handler(nil, nil, nil, nil)
    end

    local parsed = nil
    lsp:query_symbols(function(symbols)
      parsed = symbols
    end)

    assert.are.same({}, parsed)
  end)

  it("parses nested DocumentSymbol responses", function()
    vim.lsp.buf_request = function(_, _, _, handler)
      handler(nil, {
        {
          name = "MyClass",
          kind = 5,
          selectionRange = { start = { line = 1, character = 0 } },
          children = {
            {
              name = "method_a",
              kind = 6,
              selectionRange = { start = { line = 2, character = 2 } },
              children = {
                {
                  name = "inner",
                  kind = 12,
                  selectionRange = { start = { line = 3, character = 4 } },
                },
              },
            },
          },
        },
      }, nil, nil)
    end

    local parsed = nil
    lsp:query_symbols(function(symbols)
      parsed = symbols
    end)

    assert.are.same({
      { name = "MyClass", kind = "Class", position = { row = 2, col = 1 }, depth = 0 },
      { name = "method_a", kind = "Method", position = { row = 3, col = 3 }, depth = 1 },
      { name = "inner", kind = "Function", position = { row = 4, col = 5 }, depth = 2 },
    }, parsed)
  end)

  it("parses SymbolInformation responses", function()
    vim.lsp.buf_request = function(_, _, _, handler)
      handler(nil, {
        {
          name = "top_fn",
          kind = 12,
          location = { range = { start = { line = 9, character = 1 } } },
        },
      }, nil, nil)
    end

    local parsed = nil
    lsp:query_symbols(function(symbols)
      parsed = symbols
    end)

    assert.are.same({
      { name = "top_fn", kind = "Function", position = { row = 10, col = 2 }, depth = 0 },
    }, parsed)
  end)
end)
