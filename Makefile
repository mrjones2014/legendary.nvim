.PHONY: ensure-test-deps
ensure-test-deps:
	@mkdir -p vendor
	@if test ! -d ./vendor/plenary.nvim; then git clone git@github.com:nvim-lua/plenary.nvim.git ./vendor/plenary.nvim/; fi
	@if test ! -d ./vendor/luassert; then git clone git@github.com:Olivine-Labs/luassert.git ./vendor/luassert/; fi

.PHONY: update-test-deps
update-test-deps: ensure-test-deps
	@cd ./vendor/plenary.nvim/ && git pull && cd ..
	@cd ./vendor/luassert/ && git pull && cd ..

.PHONY: test
test: ensure-test-deps
	nvim --headless --noplugin -u tests/testrc.lua -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/testrc.lua' }"

.PHONY: check-teal
check-teal:
	@echo "Running \`tl check\`..."
	@cd ./teal/ && \
	tl check ./**/*.tl && \
	echo "No type errors found" && \
	cd .. && \
	echo ""

.PHONY: check-luacheck
check-luacheck:
	@echo "Running \`luacheck\`..."
	@luacheck tests/
	@echo ""

.PHONY: check-stylua # stylua gets run through a separate GitHub Action in CI
check-stylua:
	@if test -z "$$CI"; then echo "Running \`stylua\`..." && stylua tests/ && echo "No stylua errors found.\n"; fi

.PHONY: check
check: check-teal
check: check-luacheck
check: check-stylua

.PHONY: gen-types
gen-types:
	@if test ! -d ./vendor/teal-types/; then git clone git@github.com:teal-language/teal-types.git ./vendor/teal-types/; fi
	@cd ./vendor/teal-types/types/neovim/ && \
	git reset --hard && \
	git clean -f && \
	git pull origin master && \
	chmod +x autogen && \
	./autogen && \
	cd ../../../../
	cp ./vendor/teal-types/types/neovim/vim.d.tl ./teal/vim.d.tl

.PHONY: build
build:
	@rm -rf lua/ && \
	cd ./teal/ && \
	tl build && \
	mv dist/ ../lua/ && \
	cd ..

.PHONY: init
init:
	git config core.hooksPath .githooks
