.PHONY: test

test:
	nvim --headless --clean -u tests/minimal_init.lua -c "luafile tests/plenary_runner.lua" -c "qa"
