describe("codeexplorer.ui interactions", function()
  local ui
  local source_win
  local source_buf

  local function press(keys)
    local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
    vim.api.nvim_feedkeys(termcodes, "x", false)
  end

  local function symbol_names(entries)
    return vim.tbl_map(function(entry)
      return entry.symbol.name
    end, entries)
  end

  local function sample_symbols()
    return {
      { name = "ClassA", kind = "Class", position = { row = 1, col = 1 }, depth = 0 },
      { name = "method_a", kind = "Method", position = { row = 2, col = 5 }, depth = 1 },
      { name = "ClassB", kind = "Class", position = { row = 5, col = 1 }, depth = 0 },
    }
  end

  before_each(function()
    package.loaded["codeexplorer.ui"] = nil
    ui = require "codeexplorer.ui"

    vim.cmd "enew"
    source_win = vim.api.nvim_get_current_win()
    source_buf = vim.api.nvim_get_current_buf()

    vim.api.nvim_buf_set_name(source_buf, string.format("%s/tests/fixtures/sample_%d.py", vim.fn.getcwd(), vim.uv.hrtime()))
    vim.api.nvim_buf_set_lines(source_buf, 0, -1, false, {
      "class ClassA:",
      "    def method_a(self):",
      "        pass",
      "",
      "class ClassB:",
      "    pass",
    })
  end)

  after_each(function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local config = vim.api.nvim_win_get_config(win)
      if config.relative ~= "" and vim.api.nvim_win_is_valid(win) then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end

    if vim.api.nvim_win_is_valid(source_win) then
      vim.api.nvim_set_current_win(source_win)
    end
  end)

  it("expands and collapses with expected keymaps", function()
    ui:open(sample_symbols(), vim.api.nvim_buf_get_name(source_buf))

    assert.are.same({ "ClassA", "ClassB" }, symbol_names(ui.visible_symbols))

    press "l"
    assert.are.same({ "ClassA", "method_a", "ClassB" }, symbol_names(ui.visible_symbols))

    press "<Left>"
    assert.are.same({ "ClassA", "ClassB" }, symbol_names(ui.visible_symbols))

    press "<Right>"
    assert.are.same({ "ClassA", "method_a", "ClassB" }, symbol_names(ui.visible_symbols))

    press "h"
    assert.are.same({ "ClassA", "ClassB" }, symbol_names(ui.visible_symbols))
  end)

  it("jumps to expanded symbol position on enter", function()
    ui:open(sample_symbols(), vim.api.nvim_buf_get_name(source_buf))

    press "l"
    vim.api.nvim_win_set_cursor(0, { ui.header_height + 2, 0 })
    press "<CR>"

    assert.are.equal(source_win, vim.api.nvim_get_current_win())

    local cursor = vim.api.nvim_win_get_cursor(0)
    assert.are.same({ 2, 4 }, cursor)
  end)

  it("renders default kind icons in symbol lines", function()
    ui:open(sample_symbols(), vim.api.nvim_buf_get_name(source_buf))

    local line = vim.api.nvim_buf_get_lines(ui.buf, ui.header_height, ui.header_height + 1, false)[1]
    assert.are.equal(" ▶ 󰠱 ClassA (Class)", line)
  end)

  it("renders without icons when disabled", function()
    ui:set_config { icons = false }
    ui:open(sample_symbols(), vim.api.nvim_buf_get_name(source_buf))

    local line = vim.api.nvim_buf_get_lines(ui.buf, ui.header_height, ui.header_height + 1, false)[1]
    assert.are.equal(" ▶ ClassA (Class)", line)
  end)

  it("renders overridden icon when icons is a table", function()
    ui:set_config {
      icons = {
        Class = "C",
      },
    }
    ui:open(sample_symbols(), vim.api.nvim_buf_get_name(source_buf))

    local line = vim.api.nvim_buf_get_lines(ui.buf, ui.header_height, ui.header_height + 1, false)[1]
    assert.are.equal(" ▶ C ClassA (Class)", line)
  end)

  it("disables icon for a specific kind when override is false", function()
    ui:set_config {
      icons = {
        Method = false,
      },
    }
    ui:open(sample_symbols(), vim.api.nvim_buf_get_name(source_buf))

    press "l"

    local first = vim.api.nvim_buf_get_lines(ui.buf, ui.header_height, ui.header_height + 1, false)[1]
    local second = vim.api.nvim_buf_get_lines(ui.buf, ui.header_height + 1, ui.header_height + 2, false)[1]

    assert.are.equal(" ▼ 󰠱 ClassA (Class)", first)
    assert.are.equal("     method_a (Method)", second)
  end)
end)
