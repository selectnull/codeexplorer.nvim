describe("codeexplorer.ui visibility", function()
  local ui

  before_each(function()
    package.loaded["codeexplorer.ui"] = nil
    ui = require "codeexplorer.ui"
    ui.symbols = {
      { name = "ClassA", kind = "Class", position = { row = 1, col = 1 }, depth = 0 },
      { name = "method_a", kind = "Method", position = { row = 2, col = 1 }, depth = 1 },
      { name = "inner", kind = "Function", position = { row = 3, col = 1 }, depth = 2 },
      { name = "ClassB", kind = "Class", position = { row = 6, col = 1 }, depth = 0 },
      { name = "method_b", kind = "Method", position = { row = 7, col = 1 }, depth = 1 },
      { name = "top_fn", kind = "Function", position = { row = 10, col = 1 }, depth = 0 },
    }
    ui.expanded = {}
  end)

  it("shows only first-level symbols by default", function()
    local visible = ui:build_visible_symbols()
    local names = vim.tbl_map(function(entry)
      return entry.symbol.name
    end, visible)

    assert.are.same({ "ClassA", "ClassB", "top_fn" }, names)
  end)

  it("shows children only for expanded parents", function()
    ui.expanded[1] = true
    local visible = ui:build_visible_symbols()
    local names = vim.tbl_map(function(entry)
      return entry.symbol.name
    end, visible)

    assert.are.same({ "ClassA", "method_a", "ClassB", "top_fn" }, names)
  end)

  it("shows nested children when intermediate symbol is expanded", function()
    ui.expanded[1] = true
    ui.expanded[2] = true

    local visible = ui:build_visible_symbols()
    local names = vim.tbl_map(function(entry)
      return entry.symbol.name
    end, visible)

    assert.are.same({ "ClassA", "method_a", "inner", "ClassB", "top_fn" }, names)
  end)
end)
