return function()
  local autocmd_id
  autocmd_id = vim.api.nvim_create_autocmd('User', {
    pattern = 'LegendaryUiPre',
    callback = function()
      local ok, cmds = pcall(require, 'op.commands')
      if not ok then
        return
      end

      local legendary_commands = vim.tbl_map(function(cmd)
        return {
          cmd[1],
          description = cmd[3].desc,
        }
      end, cmds)
      require('legendary').commands(legendary_commands)
      -- once we've got the commands registered, stop looking for them
      vim.api.nvim_del_autocmd(autocmd_id)
    end,
  })
end
