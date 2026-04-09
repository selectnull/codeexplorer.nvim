.PHONY: test

test:
	nvim --headless --clean -u tests/init.lua -c "luafile tests/plenary_runner.lua" -c "qa"
