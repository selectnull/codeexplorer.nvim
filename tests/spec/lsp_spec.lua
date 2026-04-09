describe("codeexplorer.lsp", function()
  it("maps known LSP kinds", function()
    local lsp = require "codeexplorer.lsp"
    assert.are.equal("Function", lsp.get_kind_name(12))
    assert.are.equal("Unknown", lsp.get_kind_name(999))
  end)
end)
