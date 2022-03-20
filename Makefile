NVIM_NAME ?= nvim
VIM_NAME ?= vim
THEMIS_NAME ?= vim-themis/bin/themis

test: test-nvim test-vim

test-nvim:
	THEMIS_ARGS='-e -s --headless' THEMIS_VIM=$(NVIM_NAME) $(THEMIS_NAME)

test-vim:
	THEMIS_VIM=$(VIM_NAME) $(THEMIS_NAME)

lint: format selene vint

format:
	stylua --check lua/ test/

selene:
	selene lua/
	cd test && selene .

vint:
	vint --warning --verbose autoload/trust.vim autoload/trust/ plugin/
