test:
	nvim --headless -u NONE +'luafile tests/init.lua' +q
	vim -u NONE +'luafile tests/init.lua' +q

lint:
	stylua --check .
	selene lua
	cd tests && selene .
