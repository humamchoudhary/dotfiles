-- lua/plugins/colorscheme.lua
-- The colorscheme itself is applied in lua/config/colorscheme.lua, after lazy
-- has finished, so the palette overrides in lua/colors.lua land on top of it.

return {
	{
		"nyoom-engineering/oxocarbon.nvim",
		lazy = false,
		priority = 1000,
	},

	{
		"catgoose/nvim-colorizer.lua",
		event = "BufReadPre",
		opts = {},
	},
}
