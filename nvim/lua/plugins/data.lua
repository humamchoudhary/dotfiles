-- lua/plugins/data.lua
-- Databases, CSV/XLSX and notebooks.

return {
	{
		"kndndrj/nvim-dbee",
		dependencies = { "MunifTanjim/nui.nvim" },
		build = function()
			require("dbee").install()
		end,
		config = function()
			require("dbee").setup({})
		end,
	},

	{
		"kristijanhusak/vim-dadbod-ui",
		dependencies = {
			{ "tpope/vim-dadbod", lazy = true },
			-- The completion source loads on its own for sql buffers, well before
			-- :DBUI would pull vim-dadbod in as a sibling. Without its own
			-- dependency it calls db#resolve() from a plugin that isn't loaded
			-- yet and throws E117 on the first keystroke in insert mode.
			{
				"kristijanhusak/vim-dadbod-completion",
				dependencies = { "tpope/vim-dadbod" },
				lazy = true,
				ft = { "sql", "mysql", "plsql" },
			},
		},
		cmd = {
			"DBUI",
			"DBUIToggle",
			"DBUIAddConnection",
			"DBUIFindBuffer",
		},
		init = function()
			vim.g.db_ui_use_nerd_fonts = 1
		end,
	},

	{
		"hat0uma/csvview.nvim",
		---@module "csvview"
		---@type CsvView.Options
		opts = {
			parser = { comments = { "#", "//" } },
			keymaps = {
				-- Text objects for selecting fields
				textobject_field_inner = { "if", mode = { "o", "x" } },
				textobject_field_outer = { "af", mode = { "o", "x" } },
				-- Excel-like navigation:
				-- Use <Tab> and <S-Tab> to move horizontally between fields.
				-- Use <Enter> and <S-Enter> to move vertically between rows and place the cursor at the end of the field.
				-- Note: In terminals, you may need to enable CSI-u mode to use <S-Tab> and <S-Enter>.
				jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
				jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
				jump_next_row = { "<Enter>", mode = { "n", "v" } },
				jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
			},
		},
		cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
	},

	{
		"beargruug/xls-viewer.nvim",
		config = function()
			require("xls-viewer").setup()
		end,
	},

	{
		"meatballs/notebook.nvim",
		config = function()
			require("notebook").setup()
		end,
	},
}
