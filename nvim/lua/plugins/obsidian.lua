-- lua/plugins/obsidian.lua
-- Obsidian vault integration: note navigation, links, templates and search.

return {
	{
		"epwalsh/obsidian.nvim",
		version = "*",
		lazy = true,
		ft = "markdown",
		cmd = {
			"ObsidianBacklinks",
			"ObsidianCheck",
			"ObsidianDailies",
			"ObsidianDebug",
			"ObsidianExtractNote",
			"ObsidianFollowLink",
			"ObsidianLink",
			"ObsidianLinkNew",
			"ObsidianLinks",
			"ObsidianNew",
			"ObsidianNewFromTemplate",
			"ObsidianOpen",
			"ObsidianPasteImg",
			"ObsidianQuickSwitch",
			"ObsidianRename",
			"ObsidianSearch",
			"ObsidianTOC",
			"ObsidianTags",
			"ObsidianTemplate",
			"ObsidianToday",
			"ObsidianToggleCheckbox",
			"ObsidianTomorrow",
			"ObsidianWorkspace",
			"ObsidianYesterday",
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
		},
		opts = {
			workspaces = {
				{
					name = "personal",
					path = "~/Documents/Obsidian Vault",
				},
			},
			ui = {
				enable = false,
			},
			completion = {
				nvim_cmp = true,
				min_chars = 2,
			},
			notes_subdir = "notes",
			daily_notes = {
				folder = "daily",
				template = "daily.md",
			},
		},
	},
}
