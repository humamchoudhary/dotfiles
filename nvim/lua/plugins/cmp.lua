-- lua/plugins/cmp.lua
-- Completion and snippets.

return {
	{
		"L3MON4D3/LuaSnip",
		version = "v2.*",
		build = "make install_jsregexp",
		dependencies = { "rafamadriz/friendly-snippets" },
	},

	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-calc",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"windwp/nvim-autopairs",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			local cmp_select = { behavior = cmp.SelectBehavior.Select }

			require("luasnip.loaders.from_vscode").lazy_load()

			-- Insert the matching pair after confirming a function completion.
			cmp.event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done())

			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "sql", "mysql", "plsql" },
				callback = function()
					cmp.setup.buffer({
						sources = {
							{
								name = "vim-dadbod-completion",
								-- Lets <C-l>/<C-k> cycle which kind of
								-- suggestion is shown. See lua/lang/sql.lua.
								entry_filter = function(entry, ctx)
									return require("lang.sql").entry_filter(entry, ctx)
								end,
							},
							{ name = "buffer" },
						},
					})
				end,
			})

			cmp.setup({
				sources = {
					{ name = "path" },
					{ name = "nvim_lsp", priority = 100 },
					{ name = "luasnip", keyword_length = 2 },
					{ name = "buffer", keyword_length = 3 },
					{ name = "nvim_lsp_signature_help" },
					{ name = "calc" },
				},
				mapping = cmp.mapping.preset.insert({
					["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
					["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
					["<C-y>"] = cmp.mapping.confirm({ select = true }),
					["<C-Space>"] = cmp.mapping.complete(),
					-- Same behaviour lsp-zero's cmp_action.tab_complete() gave us:
					-- cycle the menu, else jump the snippet, else fall through to a real Tab.
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item(cmp_select)
						elseif luasnip.locally_jumpable(1) then
							luasnip.jump(1)
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item(cmp_select)
						elseif luasnip.locally_jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
					["<CR>"] = cmp.mapping.confirm({ select = false }),
				}),
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				formatting = {
					fields = { "abbr", "kind", "menu" },
					format = function(entry, item)
						local menu_icon = {
							nvim_lsp = "λ",
							luasnip = "⋗",
							buffer = "Ω",
							path = "🖫",
							["vim-dadbod-completion"] = "🗄️", -- Added icon to prevent the nil crash
						}
						-- Fallback to a default string if a source isn't explicitly mapped
						item.menu = menu_icon[entry.source.name] or entry.source.name
						return item
					end,
				},
			})
		end,
	},
}
