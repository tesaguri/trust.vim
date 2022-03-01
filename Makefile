test:
	vim -u NONE +'luafile tests/init.lua' +q
	nvim --headless -u NORC +'luafile tests/init.lua' +q

lint:
	stylua --check .
	selene lua
	cd tests && selene .
