NVIM_PATH ?= nvim
VIM_PATH ?= vim
THEMIS_PATH ?= vim-themis/bin/themis

test: test-nvim test-vim

test-nvim:
	THEMIS_ARGS='-e -s --headless -V1' THEMIS_VIM=$(NVIM_PATH) $(THEMIS_PATH)

test-vim:
	THEMIS_ARGS='-e -s -V1' THEMIS_VIM=$(VIM_PATH) $(THEMIS_PATH)

lint: format selene vint

format:
	stylua --check lua/ test/

selene:
	selene lua/
	cd test && selene .

vint:
	vint --warning --verbose autoload/trust.vim autoload/trust/ plugin/
