NVIM_NAME ?= nvim
VIM_NAME ?= vim
THEMIS_NAME ?= vim-themis/bin/themis

test: test-nvim test-vim

test-nvim:
	THEMIS_VIM=$(NVIM_NAME) $(THEMIS_NAME)
	$(NVIM_NAME) --headless -u NONE +'luafile test/init.lua' +q

test-vim:
	THEMIS_VIM=$(VIM_NAME) $(THEMIS_NAME)
	$(VIM_NAME) -u NONE +"try | execute 'luafile test/init.lua' | catch | echo v:exception | cquit! | endtry | q"

lint: format selene vint

format:
	stylua --check lua test

selene:
	selene lua
	cd test && selene .

vint:
	vint --warning --verbose autoload/{trust/,trust.vim} plugin/
