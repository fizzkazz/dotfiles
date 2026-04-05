-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- Compatibility alias for setups that no longer provide :LspInfo
if vim.fn.exists ":LspInfo" == 0 then
  vim.api.nvim_create_user_command("LspInfo", function() vim.cmd "checkhealth vim.lsp" end, {
    desc = "Show built-in LSP health information",
  })
end
