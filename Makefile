.PHONY: ensure-test-deps
ensure-test-deps:
	mkdir -p vendor
	if test ! -d ./vendor/plenary.nvim; then git clone git@github.com:nvim-lua/plenary.nvim.git ./vendor/plenary.nvim/; fi
	if test ! -d ./vendor/luassert; then git clone git@github.com:Olivine-Labs/luassert.git ./vendor/luassert/; fi

.PHONY: update-test-deps
update-test-deps: ensure-test-deps
	cd ./vendor/plenary.nvim/ && git pull && cd ..
	cd ./vendor/luassert/ && git pull && cd ..

.PHONY: test
test: ensure-test-deps
	nvim --headless --noplugin -u tests/testrc.lua -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/testrc.lua' }"

.PHONY: lint
lint:
	luacheck lua/ tests/
	stylua --check lua/ tests/

.PHONY: check
check: test
check: lint
