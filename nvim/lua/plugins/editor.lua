-- lua/plugins/editor.lua
-- Navigation, file tree, search/replace, folds and editing helpers.

return {
	{
		"nvim-telescope/telescope.nvim",
		version = "*",
		dependencies = {
			"nvim-lua/plenary.nvim",
			-- optional but recommended
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
	},

	{
		"nvim-tree/nvim-tree.lua",
		version = "*",
		lazy = false,
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("nvim-tree").setup({
				sort_by = "case_sensitive",
				view = {
					width = 30,
				},
				renderer = {
					group_empty = true,
					highlight_git = true,
					highlight_opened_files = "name",
					indent_markers = { enable = true },
				},
				filters = {
					dotfiles = false,
				},
				on_attach = function(bufnr)
					require("nvim-tree.api").config.mappings.default_on_attach(bufnr)
				end,
			})
		end,
	},

	{ "ThePrimeagen/harpoon", dependencies = { "nvim-lua/plenary.nvim" } },

	-- Hop.nvim for fast navigation
	{
		"smoka7/hop.nvim",
		version = "*",
		opts = {
			keys = "etovxqpdygfblzhckisuran",
		},
	},

	{
		"nvim-pack/nvim-spectre",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			require("spectre").setup()
		end,
	},

	{
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	},

	-- ── Editing helpers that are language-aware ──────────────────────────────
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = { check_ts = true },
	},
	{
		"windwp/nvim-ts-autotag",
		ft = {
			"html",
			"htmldjango",
			"jinja",
			"xml",
			"javascript",
			"javascriptreact",
			"typescript",
			"typescriptreact",
			"vue",
			"svelte",
			"markdown",
		},
		opts = {},
	},

	-- Code folding with nvim-ufo
	{
		"kevinhwang91/nvim-ufo",
		dependencies = { "kevinhwang91/promise-async" },
		config = function()
			require("ufo").setup({
				provider_selector = function(bufnr, filetype, buftype)
					return { "treesitter", "indent" }
				end,
			})
		end,
	},

	-- Aerial for tags/code navigation
	{
		"stevearc/aerial.nvim",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
			"nvim-telescope/telescope.nvim",
		},
		config = function()
			require("aerial").setup({
				layout = {
					default_direction = "right",
				},
			})
			-- Telescope aerial extension
			require("telescope").load_extension("aerial")
		end,
	},
}
