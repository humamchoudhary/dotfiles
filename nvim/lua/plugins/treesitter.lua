-- lua/plugins/treesitter.lua

return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "master",
		build = ":TSUpdate",
		lazy = false,
		config = function()
			-- On the master branch the config table goes to
			-- nvim-treesitter.configs. require("nvim-treesitter").setup() takes
			-- no arguments and silently discards whatever you pass it, which
			-- leaves highlighting off and ensure_installed unread.
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					-- editor
					"lua",
					"luadoc",
					"vim",
					"vimdoc",
					"query",
					"regex",
					-- c family
					"c",
					"cpp",
					"cmake",
					"make",
					"objc",
					-- web
					"javascript",
					"jsdoc",
					"typescript",
					"tsx",
					"html",
					"css",
					"scss",
					"graphql",
					"prisma",
					-- python
					"python",
					"requirements",
					-- go
					"go",
					"gomod",
					"gosum",
					"gowork",
					"gotmpl",
					-- rust
					"rust",
					"ron",
					-- data / config
					"json",
					"jsonc",
					"json5",
					"yaml",
					"toml",
					"xml",
					"sql",
					-- shell / infra
					"bash",
					"dockerfile",
					"terraform",
					"hcl",
					-- docs / vcs
					"markdown",
					"markdown_inline",
					"gitcommit",
					"gitignore",
					"git_rebase",
					"diff",
					-- templating
					"htmldjango",
					"jinja",
				},
				highlight = { enable = true },
				indent = { enable = false },
			})
		end,
	},
}
