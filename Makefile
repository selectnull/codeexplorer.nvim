.PHONY: test

PLENARY_DIR := .deps/plenary.nvim

test: $(PLENARY_DIR)
	PLENARY_PATH="$(abspath $(PLENARY_DIR))" nvim --headless --clean -u tests/init.lua -c "luafile tests/plenary_runner.lua" -c "qa"

$(PLENARY_DIR):
	mkdir -p .deps
	git clone --depth 1 https://github.com/nvim-lua/plenary.nvim "$(PLENARY_DIR)"
