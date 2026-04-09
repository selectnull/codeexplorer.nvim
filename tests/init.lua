vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

local project_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(project_root)

local function add_plenary_to_rtp()
  local env_path = os.getenv("PLENARY_PATH")
  if env_path ~= nil and env_path ~= "" then
    vim.opt.runtimepath:prepend(env_path)
    return
  end

  local lazy_path = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"
  if vim.uv.fs_stat(lazy_path) ~= nil then
    vim.opt.runtimepath:prepend(lazy_path)
    return
  end

  local matches = vim.fn.glob(vim.fn.stdpath("data") .. "/site/pack/*/start/plenary.nvim", false, true)
  if #matches > 0 then
    vim.opt.runtimepath:prepend(matches[1])
  end
end

add_plenary_to_rtp()
