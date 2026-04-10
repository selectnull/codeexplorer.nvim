local M = {
  config = {
    key = nil,
    icons = true,
  },
}

local run = function()
  local lsp = require "codeexplorer.lsp"
  local ui = require "codeexplorer.ui"
  ui:set_config(M.config)

  local filename = vim.api.nvim_buf_get_name(0)
  lsp:query_symbols(function(symbols)
    ui:open(symbols, filename)
  end)
end

M.run = function()
  run()
end

M.setup = function(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  if M.config.key then
    vim.keymap.set("n", M.config.key, function()
      run()
    end, { desc = "Open CodeExplorer" })
  end

  --- CodeExplorer user command
  vim.api.nvim_create_user_command("CodeExplorer", function()
    run()
  end, {})
end

return M
