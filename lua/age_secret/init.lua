local M = {}

function M.setup(user_config)
  local defaults = {
    identity = vim.fn.getenv("AGE_IDENTITY"),
    recipient = vim.fn.getenv("AGE_RECIPIENT"),
    executable = "age",
  }
  local config = vim.tbl_extend("keep", user_config, defaults)

  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "*.age",
    callback = function()
      vim.bo.filetype = "age"
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "age",
    callback = function()
      vim.o.backup = false
      vim.o.writebackup = false
      vim.o.shada = ""
    end,
  })

  vim.api.nvim_create_autocmd({ "BufReadPre", "FileReadPre" }, {
    pattern = "*.age",
    callback = function()
      vim.bo.swapfile = false
      vim.bo.binary = true
      vim.bo.undofile = false
    end,
  })

  vim.api.nvim_create_autocmd({ "BufReadPost", "FileReadPost" }, {
    pattern = "*.age",
    callback = function()
      if config.identity == vim.NIL then
        vim.api.nvim_err_writeln("No identity: set the identity option or the AGE_IDENTITY environment variable")
        return
      end
      vim.cmd(string.format("silent '[,']!%s --decrypt -i %s", config.executable, config.identity))
      if vim.v.shell_error ~= 0 then
        vim.cmd("silent undo")
        return vim.notify("decryption failed", vim.log.levels.ERROR)
      end
      vim.bo.binary = false
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWriteCmd", "FileWriteCmd" }, {
    pattern = "*.age",
    callback = function()
      if config.recipient == vim.NIL then
        vim.api.nvim_err_writeln("No recipient: set the recipient option or the AGE_RECIPIENT environment variable")
        return
      end

      vim.cmd(
        string.format(
          "silent '[,']w !%s --encrypt -r %s -a -o %s",
          config.executable,
          config.recipient,
          vim.fn.expand("%")
        )
      )
      if vim.v.shell_error ~= 0 then
        vim.api.nvim_err_writeln("encryption failed")
        return
      end
      vim.api.nvim_buf_set_option(0, "modified", false)
    end,
  })
end

return M
