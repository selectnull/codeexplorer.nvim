local run = function()
  local lsp = require "codeexplorer.lsp"
  local ui = require "codeexplorer.ui"

  local filename = vim.api.nvim_buf_get_name(0)
  lsp:query_symbols(function(symbols)
    ui:open(symbols, filename)
  end)
end

local M = {}

M.run = function()
  run()
end

M.setup = function(opts)
  if opts.key then
    vim.keymap.set("n", opts.key, function()
      run()
    end, { desc = "Open CodeExplorer" })
  end

  --- CodeExplorer user command
  vim.api.nvim_create_user_command("CodeExplorer", function()
    run()
  end, {})
end

return M
