-- lua/plugins/lsp.lua
--
-- Neovim 0.12 configures servers natively via vim.lsp.config, so there's no
-- lspconfig.setup() wrapper here; mason-lspconfig only handles installing
-- servers and calling vim.lsp.enable() on them. Per-server settings live in
-- lua/lang/lsp.lua and must be registered *before* mason-lspconfig enables
-- them -- hence the single config function below.

return {
	{ "neovim/nvim-lspconfig" },
	{ "mason-org/mason.nvim", opts = {} },
	{ "b0o/schemastore.nvim" },

	{
		"mason-org/mason-lspconfig.nvim",
		dependencies = {
			"mason-org/mason.nvim",
			"neovim/nvim-lspconfig",
			"b0o/schemastore.nvim",
			-- capabilities() in lua/lang/lsp.lua picks this up when present.
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			local lsp = require("lang.lsp")
			lsp.setup()

			vim.lsp.config("asm_lsp", {
				filetypes = { "asm", "nasm", "vmasm", "s", "S" },
				root_markers = { ".asm-lsp.toml", ".git" },
			})

			require("mason-lspconfig").setup({
				ensure_installed = lsp.servers,
				automatic_enable = { exclude = lsp.ignore_automatic_enable },
			})
		end,
	},

	-- Formatters, linters and debug adapters (Mason package names).
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "mason-org/mason.nvim" },
		opts = {
			ensure_installed = {
				-- debug adapters
				"debugpy", -- Python
				"delve", -- Go
				"codelldb", -- Rust / C / C++
				"js-debug-adapter", -- JavaScript / TypeScript
				-- formatters
				"stylua",
				"black",
				"isort",
				"prettier",
				"shfmt",
				"clang-format",
				"gofumpt",
				"goimports",
				"taplo",
				-- linters
				"shellcheck",
				"golangci-lint",
			},
			run_on_start = true,
			auto_update = false,
		},
	},

	-- Diagnostics / references / quickfix in one navigable list.
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		cmd = "Trouble",
		opts = { focus = true },
	},
}
