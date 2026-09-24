-- lua/plugins/format.lua
-- Formatting is manual: <leader>f runs conform, nothing runs on save.
--
-- Two exceptions live elsewhere and DO run on save:
--   * go.nvim's goimports on *.go   (lua/plugins/lang.lua)
--   * LspEslintFixAll for eslint    (lua/lang/lsp.lua)

return {
	{
		"stevearc/conform.nvim",
		cmd = { "ConformInfo" },
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				-- ruff replaces isort+black and is far faster, but it's only installed
				-- via Mason's LSP package -- fall back to the system black/isort when
				-- the ruff binary isn't on PATH.
				python = function()
					if vim.fn.executable("ruff") == 1 then
						return { "ruff_organize_imports", "ruff_format" }
					end
					return { "isort", "black" }
				end,
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				vue = { "prettier" },
				svelte = { "prettier" },
				css = { "prettier" },
				scss = { "prettier" },
				less = { "prettier" },
				html = { "prettier" },
				htmldjango = { "djlint" },
				jinja = { "djlint" },
				json = { "prettier" },
				jsonc = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
				graphql = { "prettier" },
				go = { "goimports", "gofumpt" },
				rust = { "rustfmt" },
				sh = { "shfmt" },
				bash = { "shfmt" },
				zsh = { "shfmt" },
				c = { "clang-format" },
				cpp = { "clang-format" },
				objc = { "clang-format" },
				cuda = { "clang-format" },
				proto = { "clang-format" },
				toml = { "taplo" },
				sql = { "sql_formatter" },
				["_"] = { "trim_whitespace" },
			},
			formatters = {
				shfmt = { prepend_args = { "-i", "4", "-ci" } },
			},
			-- NO format_on_save - format manually with <leader>f
			default_format_opts = { lsp_format = "fallback" },
		},
	},
}
