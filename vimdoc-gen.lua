local DOC_FILES = {
  ['./README.md'] = './doc/legendary.txt',
  ['./doc/API.md'] = './doc/legendary-lua-api.txt',
  ['./doc/MAPPING_DEVELOPMENT.md'] = './doc/legendary-mapping-development.txt',
  ['./doc/FILTERS.md'] = './doc/legendary-filters.txt',
  ['./doc/USAGE_EXAMPLES.md'] = './doc/legendary-usage-examples.txt',
  ['./doc/WHICH_KEY.md'] = './doc/legendary-which-key.txt',
  ['./doc/table_structures/README.md'] = './doc/legendary-tables.txt',
  ['./doc/table_structures/KEYMAPS.md'] = './doc/legendary-keymap-tables.txt',
  ['./doc/table_structures/COMMANDS.md'] = './doc/legendary-command-tables.txt',
  ['./doc/table_structures/FUNCTIONS.md'] = './doc/legendary-function-tables.txt',
  ['./doc/table_structures/AUTOCMDS.md'] = './doc/legendary-autocmd-tables.txt',
}

for input, output in pairs(DOC_FILES) do
  require('ts-vimdoc').docgen({
    input_file = input,
    output_file = output,
    project_name = 'legendary',
  })
  print(string.format('Wrote %s from source file %s', output, input))
end
print('\n')

vim.cmd('qa')
