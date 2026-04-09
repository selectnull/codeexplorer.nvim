# CodeExplorer

Simple LSP symbols code explorer.

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

Clone locally plenary.nvim `git clone https://github.com/nvim-lua/plenary.nvim`.

From the project root:

```bash
export PLENARY_PATH="/path/to/plenary.nvim"
make test
```
