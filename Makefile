NVIM_NAME ?= nvim
VIM_NAME ?= vim

test: test-nvim test-vim

test-nvim:
	$(NVIM_NAME) --headless -u NONE +'luafile tests/init.lua' +q

test-vim:
	$(VIM_NAME) -u NONE +'luafile tests/init.lua' +q

lint: format selene

format:
	stylua --check .

selene:
	selene lua
	cd tests && selene .
