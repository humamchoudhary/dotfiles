-- lua/plugins/ui.lua
-- Statusline, dashboard, keymap hints and other chrome.

return {
	{ "nvim-tree/nvim-web-devicons" },

	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("lualine").setup({
				options = {
					theme = require("colors").lualine_theme,
					component_separators = "|",
					section_separators = "",
				},
				sections = {
					lualine_c = {
						{
							"filename",
							path = 1, -- Show relative path
							shorting_target = 40, -- Minimum width before shortening
							symbols = {
								modified = " ●",
								readonly = " ",
								unnamed = "[No Name]",
							},
						},
					},
				},
			})
		end,
	},

	{
		"goolord/alpha-nvim",
		event = "VimEnter",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = function()
			local dashboard = require("alpha.themes.dashboard")
			require("alpha.term")
			local arttoggle = false

			local logo = {
				[[                                                    ]],
				[[ ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ]],
				[[ ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ]],
				[[ ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ]],
				[[ ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ]],
				[[ ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ]],
				[[ ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ]],
				[[                                                    ]],
			}

			local art = {
				{ "tohru", 62, 17 },
			}

			if arttoggle == true then
				dashboard.opts.opts.noautocmd = true
				dashboard.section.terminal.opts.redraw = true
				local path = vim.fn.stdpath("config") .. "/assets/"
				local currentart = art[1]
				dashboard.section.terminal.command = "cat " .. path .. currentart[1]
				dashboard.section.terminal.width = currentart[2]
				dashboard.section.terminal.height = currentart[3]
				dashboard.opts.layout = {
					dashboard.section.terminal,
					{ type = "padding", val = 2 },
					dashboard.section.buttons,
					dashboard.section.footer,
				}
			else
				dashboard.section.header.val = logo
			end

			dashboard.section.buttons.val = {
				dashboard.button("f", " " .. "Find files", ":Telescope find_files <CR>"),
			}

			for _, button in ipairs(dashboard.section.buttons.val) do
				button.opts.hl = "AlphaButtons"
				button.opts.hl_shortcut = "AlphaShortcut"
			end

			dashboard.section.header.opts.hl = "Function"
			dashboard.section.buttons.opts.hl = "Identifier"
			dashboard.section.footer.opts.hl = "Function"
			dashboard.opts.layout[1].val = 4
			return dashboard
		end,
		config = function(_, dashboard)
			if vim.o.filetype == "lazy" then
				vim.cmd.close()
				vim.api.nvim_create_autocmd("User", {
					pattern = "AlphaReady",
					callback = function()
						require("lazy").show()
					end,
				})
			end

			require("alpha").setup(dashboard.opts)

			vim.api.nvim_create_autocmd("User", {
				pattern = "LazyVimStarted",
				callback = function()
					local v = vim.version()
					local dev = ""
					if v.prerelease == "dev" then
						dev = "-dev+" .. v.build
					else
						dev = ""
					end
					local version = v.major .. "." .. v.minor .. "." .. v.patch .. dev
					local stats = require("lazy").stats()
					local plugins_count = stats.loaded .. "/" .. stats.count
					local ms = math.floor(stats.startuptime + 0.5)
					local time = vim.fn.strftime("%H:%M:%S")
					local date = vim.fn.strftime("%d.%m.%Y")
					local line1 = " " .. plugins_count .. " plugins loaded in " .. ms .. "ms"
					local line2 = "󰃭 " .. date .. "  " .. time
					local line3 = " " .. version

					local line1_width = vim.fn.strdisplaywidth(line1)
					local line2Padded = string.rep(" ", (line1_width - vim.fn.strdisplaywidth(line2)) / 2) .. line2
					local line3Padded = string.rep(" ", (line1_width - vim.fn.strdisplaywidth(line3)) / 2) .. line3

					dashboard.section.footer.val = {
						line1,
						line2Padded,
						line3Padded,
					}
					pcall(vim.cmd.AlphaRedraw)
				end,
			})
		end,
	},

	-- Keymaps are registered in lua/config/keymaps.lua, which also calls
	-- wk.setup() -- so which-key must be loadable by then.
	{ "folke/which-key.nvim", event = "VeryLazy" },

	-- LSP progress in the corner instead of silent multi-second startups.
	{ "j-hui/fidget.nvim", opts = { notification = { window = { winblend = 0 } } } },

	-- Status column for fold indicators
	{
		"luukvbaal/statuscol.nvim",
		config = function()
			local builtin = require("statuscol.builtin")
			require("statuscol").setup({
				relculright = true,
				segments = {
					{ text = { builtin.foldfunc }, click = "v:lua.ScFa" },
					{ text = { "%s" }, click = "v:lua.ScSa" },
					{ text = { builtin.lnumfunc, " " }, condition = { true, builtin.not_empty }, click = "v:lua.ScLa" },
				},
			})
		end,
	},

	{
		"OXY2DEV/markview.nvim",
		lazy = false,
	},
}
