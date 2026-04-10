# CodeExplorer.nvim

Simple LSP symbols code explorer Neovim plugin.

Requires Neovim 0.12+ (might work in previous versions, did not test it).

## Configuration

```lua
vim.pack.add {"https://github.com/selectnull/codeexplorer.nvim"}
require("codeexplorer").setup {
  key: string?
  icons = table|boolean|nil,
}
```

`key` is any valid Vim keymap and if left out, the keymap will not be set.
`icons` controls symbol kind icons:
* `true` (default): show built-in icons
* `false`: disable icons
* table: show icons and override specific ones (e.g. `{ Class = "C" }`)
* table values can also be `false` to hide that specific icon (e.g. `{ Method = false }`)

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
