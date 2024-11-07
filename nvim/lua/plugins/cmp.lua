return {
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "saadparwaiz1/cmp_luasnip",
            "L3MON4D3/LuaSnip",
        },
        config = function ()
            local luasnip = require("luasnip")
            local cmp = require("cmp")
            cmp.setup({
                snippet = {
                    expand = function(args)
                        require('luasnip').lsp_expand(args.body)
                    end,
                },
                sources = cmp.config.sources({
                    {name = 'nvim_lsp'},
                    {name = 'luasnip'},
                    {name = 'buffer'},
                }),
                mapping = cmp.mapping.preset.insert({
                    ['<CR>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            if luasnip.expandable() then
                                luasnip.expand()
                            else
                                cmp.confirm({
                                    select = true,
                                })
                            end
                        else
                            fallback()
                        end
                    end),
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.locally_jumpable(1) then
                            luasnip.jump(1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),

                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.locally_jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                })
            })
            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            local lsp = require('lspconfig')
            lsp["clangd"].setup({capabilities = capabilities})
            lsp["lua_ls"].setup({capabilities = capabilities})
            lsp["harper_ls"].setup({capabilities = capabilities})
        end,
    },
    {
        "saadparwaiz1/cmp_luasnip",
        dependencies = {"L3MON4D3/LuaSnip"},
    },
    {
        "L3MON4D3/LuaSnip",
        version = "v2.*",
        config = function ()
            require("luasnip").setup()
        end

    },
}
