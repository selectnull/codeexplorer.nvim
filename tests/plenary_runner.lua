local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h") .. "/spec"
local ok, test_harness = pcall(require, "plenary.test_harness")

if not ok then
  error("plenary.nvim is required for tests. Install it or set PLENARY_PATH.")
end

test_harness.test_directory(tests_dir, {
  minimal_init = "tests/init.lua",
})
