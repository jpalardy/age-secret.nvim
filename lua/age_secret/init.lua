local M = {}

function M.setup(user_config)
  local config = {
    recipient = vim.fn.getenv("AGE_RECIPIENT"),
    identity = vim.fn.getenv("AGE_IDENTITY"),
  }

  if user_config ~= nil then
    config.recipient = user_config.recipient or config.recipient
    config.identity = user_config.identity or config.identity
  end

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
      vim.opt.shada = ""
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
        error("Identity file not found. Please set the AGE_IDENTITY environment variable.")
      end

      vim.cmd(string.format("silent '[,']!rage --decrypt -i %s", config.identity))
      vim.bo.binary = false

      local filename = vim.fn.expand("%:r")
      vim.cmd(string.format("doautocmd BufReadPost %s", filename))
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWritePre", "FileWritePre" }, {
    pattern = "*.age",
    callback = function()
      if config.recipient == vim.NIL then
        error("Recipient not specified. Please set the AGE_RECIPIENT environment variable.")
      end

      vim.bo.binary = true
      vim.cmd(string.format("silent '[,']!rage --encrypt -r %s -a", config.recipient))
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWritePost", "FileWritePost" }, {
    pattern = "*.age",
    callback = function()
      -- undo the last change (which is the encryption)
      vim.cmd("silent undo")
      vim.bo.binary = false
    end,
  })
end

return M
