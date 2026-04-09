# CodeExplorer.nvim

Simple LSP symbols code explorer Neovim plugin.

Requires Neovim 0.12+ (might work in previous versions, did not test it).

## Configuration

```lua
vim.pack.add {"https://github.com/selectnull/codeexplorer.nvim"}

vim.keymap.set("n", "<c-cr>", function()
  require "codeexplorer"
  vim.cmd.codeexplorer()
end, { desc = "open codeexplorer" })

```
## Development

From the project root:

```bash
make test
```

`make test` will clone `plenary.nvim` into `.deps/` on first run.

## LICENSE

MIT.
