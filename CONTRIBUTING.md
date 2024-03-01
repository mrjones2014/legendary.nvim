# Contributing

## Local Environment

For `lua-language-server` to pick up the testing libraries in use, you'll need to download the appropriate addons for
`lua-language-server`. This can be done automatically for you by running `make lsp-addons`. They can be updated by using
`make update-lsp-addons`.

You will also need `stylua` and `luacheck` installed to run formatting and linting. If you are a Nix + `direnv` user,
you can simply run `direnv allow` and have the `flake.nix` set up your environment for you (or run `nix develop` if you
prefer not to use `direnv`).

## Code Style

When contributing to `legendary.nvim`, please make sure your code passes all checks.
If you have [Stylua](https://github.com/johnnymorganz/stylua) and [Luacheck](https://github.com/mpeterv/luacheck)
installed, you can run the checks locally by running `make check`. This will run the linter, the style checker,
and all unit tests. Make sure to follow the code style found in the existing code.

## PRs

PR titles are now used to generate changelogs for GitHub Releases. Please try your best to title PRs according to [conventional commits](https://www.conventionalcommits.org/en/v1.0.0-beta.2/#summary).

## Issues vs. Discussions

- Missing built-in commands or keymaps? Comment on [this GitHub Discussion](https://github.com/mrjones2014/legendary.nvim/discussions/89) or submit a PR
- Have an idea for a new function for the `legendary.toolbox` module? Comment on [this GitHub Discussion](https://github.com/mrjones2014/legendary.nvim/discussions/90) or submit a PR
- Have a general question about how to use the plugin or configure it? [Create a new GitHub Discussion](https://github.com/mrjones2014/legendary.nvim/discussions/new).
- Everything else? Check for existing issues first, and if none describe your problem, then [open a new issue](https://github.com/mrjones2014/legendary.nvim/issues/new/choose).
