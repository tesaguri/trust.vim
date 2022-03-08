NVIM_NAME ?= nvim
VIM_NAME ?= vim
THEMIS_NAME ?= themis

test: test-nvim test-vim

test-nvim:
	THEMIS_VIM=$(NVIM_NAME) $(THEMIS_NAME)
	$(NVIM_NAME) --headless -u NONE +'luafile test/init.lua' +q

test-vim:
	THEMIS_VIM=$(VIM_NAME) $(THEMIS_NAME)
	$(VIM_NAME) -u NONE +'luafile test/init.lua' +q

lint: format selene

format:
	stylua --check .

selene:
	selene lua
	cd tests && selene .
