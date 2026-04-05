---@type LazySpec
return {
  {
    "AstroNvim/astrolsp",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      if not vim.tbl_contains(opts.servers, "vtsls") then table.insert(opts.servers, "vtsls") end

      opts.handlers = opts.handlers or {}
      opts.handlers.ts_ls = false
      opts.handlers.tsserver = false

      opts.config = opts.config or {}
      opts.config.vtsls = vim.tbl_deep_extend("force", opts.config.vtsls or {}, {
        settings = {
          vtsls = {
            autoUseWorkspaceTsdk = true,
          },
        },
      })
    end,
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      if not vim.tbl_contains(opts.ensure_installed, "vtsls") then
        table.insert(opts.ensure_installed, "vtsls")
      end
    end,
  },
}
