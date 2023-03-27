return function()
  require('legendary.extensions').pre_ui_hook(function()
    local ok, cmds = pcall(require, 'smart-splits.commands')
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
    return true
  end)
end
