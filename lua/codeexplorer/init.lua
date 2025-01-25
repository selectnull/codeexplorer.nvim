local M = {}

local lsp = require "codeexplorer.lsp"
local ui = require "codeexplorer.ui"

---@class codeexplorer.Position
---@field row integer
---@field col integer

---@class codeexplorer.Symbol
---@field name string
---@field kind string
---@field position codeexplorer.Position

--- CodeExplorer user command
vim.api.nvim_create_user_command("CodeExplorer", function()
  local filename = vim.api.nvim_buf_get_name(0)
  lsp:query_symbols(function(symbols)
    ui:render_symbols(symbols, filename)
  end)
end, {})

return M
