# Contributing

## Setting Up

To contribute, you will need to install the [Teal compiler](https://github.com/teal-language/tl).

```sh
luarocks install tl
```

Then, run `make init` which will set up a pre-commit git hook to automatically recompile the Teal code
into Lua when you make a commit.

## Code Style

When contributing to `legendary.nvim`, please make sure your code passes all checks.
If you have [Stylua](https://github.com/johnnymorganz/stylua) and [Luacheck](https://github.com/mpeterv/luacheck)
installed, you can run the checks locally by running `make check`. This will run the linter, the style checker,
and all unit tests. Make sure to follow the code style found in the existing code.

## Issues vs. Discussions

- Missing built-in commands or keymaps? Comment on [this GitHub Discussion](https://github.com/mrjones2014/legendary.nvim/discussions/89) or submit a PR
- Have an idea for a new function for the `legendary.helpers` module? Comment on [this GitHub Discussion](https://github.com/mrjones2014/legendary.nvim/discussions/90) or submit a PR
- Have a general question about how to use the plugin or configure it? [Create a new GitHub Discussion](https://github.com/mrjones2014/legendary.nvim/discussions/new).
- Everything else? Check for existing issues first, and if none describe your problem, then [open a new issue](https://github.com/mrjones2014/legendary.nvim/issues/new/choose).
