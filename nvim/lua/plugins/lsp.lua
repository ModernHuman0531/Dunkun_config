local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- c++ part
vim.lsp.config('clangd', {
    capabilities = capabilities
})
vim.lsp.enable("clangd")

-- Python part
vim.lsp.config('pyright', {
    capabilities = capabilities
})
vim.lsp.enable("pyright")


