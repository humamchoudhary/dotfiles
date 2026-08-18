-- GENERAL SETTINGS
vim.opt.shiftwidth = 4
vim.g.mapleader = " " -- Set leader key
vim.opt.nu = true -- Line numbers
vim.opt.relativenumber = true -- Relative numbers
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.updatetime = 50
vim.opt.fsync = false
vim.opt.clipboard = "unnamedplus" -- Use system clipboard
vim.opt.fixeol = false -- Don't add newline at end of file
vim.o.winhighlight = "Visual:Visual"
vim.opt.virtualedit = ""
vim.g.autoformat = false

-- Folding settings for nvim-ufo
vim.o.foldcolumn = "1" -- Show fold column
vim.o.foldlevel = 99 -- Open most folds by default
vim.o.foldlevelstart = 99
vim.o.foldenable = true -- Enable folding
vim.o.fillchars = [[eob: ,fold: ,foldopen:▾,foldsep: ,foldclose:▸]]

-- HELP
vim.api.nvim_create_user_command("HKL", "help keymap-help", {})

vim.diagnostic.config({
	virtual_text = true, -- show inline messages
	signs = true, -- show gutter signs
	underline = true, -- show underline
	update_in_insert = false,
	severity_sort = true,
	float = { border = "rounded" },
})

-- LAZY INSTALLATION
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- PLUGINS
local plugins = {
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

	{ "neovim/nvim-lspconfig" },

	{
		"catgoose/nvim-colorizer.lua",
		event = "BufReadPre",
		opts = {},
	},

	{
		"nvim-treesitter/nvim-treesitter",
		branch = "master", -- ADD THIS LINE
		build = ":TSUpdate",
		lazy = false,
		config = function()
			require("nvim-treesitter").setup({ -- CHANGE: was require("nvim-treesitter")
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

	{
		"nvim-lualine/lualine.nvim",
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
								readonly = " ",
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

	{
		"nvim-tree/nvim-tree.lua",
		version = "*",
		lazy = false,
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("nvim-tree").setup({
				renderer = {
					highlight_git = true,
					highlight_opened_files = "name",
					indent_markers = { enable = true },
				},
			})
		end,
	},

	{
		"nvim-telescope/telescope.nvim",
		version = "*",
		dependencies = {
			"nvim-lua/plenary.nvim",
			-- optional but recommended
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
	},

	{ "ThePrimeagen/harpoon", dependencies = { "nvim-lua/plenary.nvim" } },

	-- ── LSP / completion stack ───────────────────────────────────────────────
	-- Neovim 0.12 configures servers natively via vim.lsp.config, so there's no
	-- lspconfig.setup() wrapper here; mason-lspconfig only handles installing
	-- servers and calling vim.lsp.enable() on them. See lua/lang/lsp.lua.
	{ "mason-org/mason.nvim", opts = {} },
	{ "mason-org/mason-lspconfig.nvim" },
	{ "WhoIsSethDaniel/mason-tool-installer.nvim" },
	{ "b0o/schemastore.nvim" },
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
		},
	},

	-- LSP progress in the corner instead of silent multi-second startups.
	{ "j-hui/fidget.nvim", opts = { notification = { window = { winblend = 0 } } } },

	-- Diagnostics / references / quickfix in one navigable list.
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		cmd = "Trouble",
		opts = { focus = true },
	},

	-- ── Rust ─────────────────────────────────────────────────────────────────
	-- rustaceanvim starts and owns rust-analyzer itself (that's why
	-- lang/lsp.lua excludes rust_analyzer from mason-lspconfig's auto-enable).
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

	-- ── Debugging (DAP) ──────────────────────────────────────────────────────
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			{ "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
			"theHamsta/nvim-dap-virtual-text",
			"mfussenegger/nvim-dap-python",
			"leoluz/nvim-dap-go",
		},
		config = function()
			require("lang.dap").setup()
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

	{ "meatballs/notebook.nvim" },

	{ "folke/which-key.nvim", event = "VeryLazy" },
	{ "stevearc/conform.nvim", cmd = { "ConformInfo" } },
	{ "numToStr/Comment.nvim" },

	-- Git with vim-fugitive
	{ "tpope/vim-fugitive" },

	-- Hop.nvim for fast navigation
	{
		"smoka7/hop.nvim",
		version = "*",
		opts = {
			keys = "etovxqpdygfblzhckisuran",
		},
	},

	-- Code folding with nvim-ufo
	{
		"kevinhwang91/nvim-ufo",
		dependencies = {
			"kevinhwang91/promise-async",
			"kevinhwang91/nvim-ufo",
		},
		config = function()
			require("ufo").setup({
				provider_selector = function(bufnr, filetype, buftype)
					return { "treesitter", "indent" }
				end,
			})
		end,
	},

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

	-- Aerial for tags/code navigation
	{
		"stevearc/aerial.nvim",
		opts = {},
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
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
		"L3MON4D3/LuaSnip",
		version = "v2.*",
		build = "make install_jsregexp",
		dependencies = { "rafamadriz/friendly-snippets" },
	},

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

	{
		"nyoom-engineering/oxocarbon.nvim",
		lazy = false,
		priority = 1000,
	},
	{
		"amrbashir/nvim-docs-view",
		lazy = true,
		cmd = "DocsViewToggle",
		opts = {
			position = "bottom",
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
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			signs = {
				add = { text = "┃" },
				change = { text = "┃" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
				untracked = { text = "┆" },
			},
			signs_staged = {
				add = { text = "┃" },
				change = { text = "┃" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
				untracked = { text = "┆" },
			},
			signs_staged_enable = true,
			signcolumn = true,
			numhl = false,
			linehl = false,
			word_diff = false,

			watch_gitdir = {
				follow_files = true,
			},

			auto_attach = true,
			attach_to_untracked = false,

			current_line_blame = false,
			current_line_blame_opts = {
				virt_text = true,
				virt_text_pos = "eol",
				delay = 1000,
				ignore_whitespace = false,
				virt_text_priority = 100,
				use_focus = true,
			},

			current_line_blame_formatter = "<author>, <author_time:%R> - <summary>",

			sign_priority = 6,
			update_debounce = 100,
			status_formatter = nil,
			max_file_length = 40000,

			preview_config = {
				style = "minimal",
				relative = "cursor",
				row = 0,
				col = 1,
			},
		},
	},
	{
		"OXY2DEV/markview.nvim",
		lazy = false,

		-- Completion for `blink.cmp`
		-- dependencies = { "saghen/blink.cmp" },
	},
	-- {
	-- 	"milanglacier/minuet-ai.nvim",
	-- 	event = "InsertEnter",
	-- 	lazy = false,
	-- 	notify = "debug",
	-- 	config = function()
	-- 		require("minuet").setup({
	-- 			provider = "openai_fim_compatible",
	-- 			n_completions = 1,
	-- 			context_window = , -- the README's own starting point; raise as your hardware allows
	-- 			provider_options = {
	-- 				openai_fim_compatible = {
	-- 					api_key = "TERM",
	-- 					name = "Ollama",
	-- 					end_point = "http://localhost:11434/v1/completions",
	-- 					model = "qwen3-coder-next:cloud",
	-- 				},
	-- 			},
	-- 			virtualtext = {
	-- 				auto_trigger_ft = { "*" },
	-- 				keymap = {
	-- 					accept = "<A-A>",
	-- 					accept_line = "<A-a>",
	-- 					prev = "<A-[>",
	-- 					next = "<A-]>",
	-- 					dismiss = "<A-e>",
	-- 				},
	-- 			},
	-- 		})
	-- 	end,
	-- },
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
		"kristijanhusak/vim-dadbod-ui",
		dependencies = {
			{ "tpope/vim-dadbod", lazy = true },
			{
				"kristijanhusak/vim-dadbod-completion",
                 lazy = true, ft = { "sql", "mysql", "plsql" }
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
}

require("lazy").setup(plugins)

vim.opt.termguicolors = true
vim.o.background = "dark"

-- Base colorscheme
vim.cmd("colorscheme oxocarbon")

require("colors").apply()

-- Re-apply custom highlights after any colorscheme change
vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "*",
	callback = function()
		require("colors").apply()
	end,
})

require("colorizer").setup()
require("luasnip.loaders.from_vscode").lazy_load()

-- DOCVIEWER SETUP
require("docviewer").setup({
	width = 60,
	position = "right", -- or "left"
})

-- TELESCOPE CONFIG
local builtin = require("telescope.builtin")

-- NVIM TREE CONFIG
require("nvim-tree").setup({
	sort_by = "case_sensitive",
	view = {
		width = 30,
	},
	renderer = {
		group_empty = true,
	},
	filters = {
		dotfiles = false,
	},
	on_attach = function(bufnr)
		local api = require("nvim-tree.api")
		local function opts(desc)
			return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
		end
		api.config.mappings.default_on_attach(bufnr)
	end,
})

-- TREESITTER CONFIG

-- COMMENT CONFIG
require("Comment").setup()

-- LSP CONFIG
-- Per-server settings live in lua/lang/lsp.lua. They must be registered with
-- vim.lsp.config() *before* mason-lspconfig enables the servers.
local lsp = require("lang.lsp")
lsp.setup()

require("mason-lspconfig").setup({
	ensure_installed = lsp.servers,
	automatic_enable = { exclude = lsp.ignore_automatic_enable },
})

-- Formatters, linters and debug adapters (Mason package names).
require("mason-tool-installer").setup({
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
})

-- AUTOCOMPLETE CONFIG
local cmp = require("cmp")
local luasnip = require("luasnip")
local cmp_select = { behavior = cmp.SelectBehavior.Select }

require("luasnip.loaders.from_vscode").lazy_load()

-- Insert the matching pair after confirming a function completion.
require("cmp").event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done())

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "sql", "mysql", "plsql" },
	callback = function()
		require("cmp").setup.buffer({
			sources = {
				{ name = "vim-dadbod-completion" },
				{ name = "buffer" },
			},
		})
	end,
})

-- 2. Your global cmp setup
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

-- AUTOFORMAT CONFIG (Conform)
-- Format ONLY on <leader>f keypress, NOT on save
require("conform").setup({
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
})

-- JUPYTER NOTEBOOK (notebook.nvim) CONFIG
require("notebook").setup()

-- KEYBINDINGS - Load centralized keymap configuration
require("keymaps").setup()
