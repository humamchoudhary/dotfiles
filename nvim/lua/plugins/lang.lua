-- lua/plugins/lang.lua
-- Language-specific plugins that go beyond a plain LSP server.

return {
	-- ── Rust ─────────────────────────────────────────────────────────────────
	-- rustaceanvim starts and owns rust-analyzer itself (that's why
	-- lua/lang/lsp.lua excludes rust_analyzer from mason-lspconfig's auto-enable).
	{
		"mrcjkb/rustaceanvim",
		version = "^6",
		lazy = false,
		init = function()
			vim.g.rustaceanvim = {
				server = {
					default_settings = {
						["rust-analyzer"] = {
							cargo = { allFeatures = true, buildScripts = { enable = true } },
							checkOnSave = true,
							check = { command = "clippy", extraArgs = { "--no-deps" } },
							procMacro = { enable = true },
							inlayHints = {
								bindingModeHints = { enable = false },
								closureReturnTypeHints = { enable = "with_block" },
								lifetimeElisionHints = { enable = "skip_trivial" },
								parameterHints = { enable = true },
								typeHints = { enable = true },
							},
						},
					},
				},
				dap = {
					-- Picked up from Mason so `:RustLsp debuggables` just works.
					adapter = require("rustaceanvim.config").get_codelldb_adapter(
						vim.fn.stdpath("data") .. "/mason/bin/codelldb",
						vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/lldb/lib/liblldb.so"
					),
				},
			}
		end,
	},
	{ "saecki/crates.nvim", event = { "BufRead Cargo.toml" }, opts = {} },

	-- ── Go ───────────────────────────────────────────────────────────────────
	{
		"ray-x/go.nvim",
		dependencies = {
			"ray-x/guihua.lua",
			"neovim/nvim-lspconfig",
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {},
		config = function(lp, opts)
			require("go").setup(opts)
			local format_sync_grp = vim.api.nvim_create_augroup("GoFormat", {})
			vim.api.nvim_create_autocmd("BufWritePre", {
				pattern = "*.go",
				callback = function()
					require("go.format").goimports()
				end,
				group = format_sync_grp,
			})
		end,
		event = { "CmdlineEnter" },
		ft = { "go", "gomod" },
		build = ':lua require("go.install").update_all_sync()',
	},

	-- ── Python ───────────────────────────────────────────────────────────────
	{
		"linux-cultist/venv-selector.nvim",
		dependencies = {
			"neovim/nvim-lspconfig",
			{ "nvim-telescope/telescope.nvim", branch = "0.1.x", dependencies = { "nvim-lua/plenary.nvim" } },
		},
		ft = "python",
		opts = {
			search = {},
			options = {},
		},
	},

	-- ── Web ──────────────────────────────────────────────────────────────────
	{
		"luckasRanarison/tailwind-tools.nvim",
		name = "tailwind-tools",
		build = ":UpdateRemotePlugins",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-telescope/telescope.nvim",
			"neovim/nvim-lspconfig",
		},
		opts = {
			server = {
				override = false,
			},
			document_color = {
				enabled = true,
				kind = "inline",
				inline_symbol = "󰝤 ",
				debounce = 200,
			},
		},
	},
}
