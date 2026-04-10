# CodeExplorer.nvim

Simple LSP symbols code explorer Neovim plugin.

Requires Neovim 0.12+ (might work in previous versions, did not test it).

## Configuration

```lua
vim.pack.add {"https://github.com/selectnull/codeexplorer.nvim"}
require("codeexplorer").setup { key = "<C-CR>" }
```

`key` is any valid Vim keymap and if left out, the keymap will not be set.
Calling `setup` is not required, you can always always
`:lua require('codeexplorer').run()` and bind to a key yourself.

## Development

From the project root:

```bash
make test
```

`make test` will clone `plenary.nvim` into `.deps/` on the first run.

## LICENSE

MIT.
