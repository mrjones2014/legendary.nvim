# Download lua-language-server addon for luassert and busted
.PHONY: lua-lsp-addon
lsp-addon:
	@mkdir -p vendor/addons/
	@if test ! -d ./vendor/luassert-addon; then git clone git@github.com:LuaCATS/luassert.git ./vendor/addons/luassert-addon/; fi
	@if test ! -d ./vendor/busted-addon; then git clone git@github.com:LuaCATS/busted.git ./vendor/addons/busted-addon/; fi

.PHONY: update-lsp-addon
update-lsp-addon:
	@cd ./vendor/addons/luassert-addon && git pull && cd ../..
	@cd ./vendor/addons/busted-addon && git pull && cd ../..

.PHONY: ensure-test-deps
ensure-test-deps:
	@mkdir -p vendor
	@if test ! -d ./vendor/plenary.nvim; then git clone git@github.com:nvim-lua/plenary.nvim.git ./vendor/plenary.nvim/; fi
	@if test ! -d ./vendor/luassert; then git clone git@github.com:Olivine-Labs/luassert.git ./vendor/luassert/; fi

.PHONY: update-test-deps
update-test-deps: ensure-test-deps
	@cd ./vendor/plenary.nvim/ && git pull && cd ..
	@cd ./vendor/luassert/ && git pull && cd ..

.PHONY: ensure-doc-deps
ensure-doc-deps:
	@mkdir -p vendor
	@if test ! -d ./vendor/ts-vimdoc.nvim; then git clone  git@github.com:ibhagwan/ts-vimdoc.nvim.git ./vendor/ts-vimdoc.nvim/; fi
	@if test ! -d ./vendor/nvim-treesitter; then git clone git@github.com:nvim-treesitter/nvim-treesitter.git ./vendor/nvim-treesitter/; fi

.PHONY: update-doc-deps
update-doc-deps: ensure-doc-deps
	@echo "Updating ts-vimdoc.nvim..."
	@cd ./vendor/ts-vimdoc.nvim/ && git pull && cd ..
	@echo "updating nvim-treesitter..."
	@cd ./vendor/nvim-treesitter/ && git pull && cd ..

.PHONY: gen-vimdoc
gen-vimdoc: update-doc-deps
	@echo 'Installing Treesitter parsers...'
	@nvim --headless -u ./vimdocrc.lua -c 'TSUpdateSync markdown' -c 'TSUpdateSync markdown_inline' -c 'qa'
	@echo 'Generating vimdocs...'
	@nvim --headless -u ./vimdocrc.lua -c 'luafile ./vimdoc-gen.lua' -c 'qa'
	@nvim --headless -u ./vimdocrc.lua -c 'helptags doc' -c 'qa'

.PHONY: test
test: ensure-test-deps
	nvim --headless --noplugin -u tests/testrc.lua -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/testrc.lua' }"

.PHONY: check-luacheck
check-luacheck:
	@echo "Running \`luacheck\`..."
	@luacheck lua/legendary/ tests/
	@echo ""

.PHONY: check-stylua # stylua gets run through a separate GitHub Action in CI
check-stylua:
	@if test -z "$$CI"; then echo "Running \`stylua\`..." && stylua tests/ && echo "No stylua errors found.\n"; fi

.PHONY: check
check: check-luacheck check-stylua

.PHONY: api-docs
api-docs:
	./gen-api-docs.bash

.PHONY: init
init:
	git config core.hooksPath .githooks
