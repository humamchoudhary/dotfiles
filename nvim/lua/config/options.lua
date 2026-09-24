-- lua/config/options.lua
-- Editor options. Loaded first, before lazy and before any plugin.

-- Leader must be set before lazy.nvim loads anything that maps keys.
vim.g.mapleader = " "

-- Indentation
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-- Line numbers
vim.opt.nu = true
vim.opt.relativenumber = true

-- Editing behaviour
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.updatetime = 50
vim.opt.fsync = false
vim.opt.clipboard = "unnamedplus" -- Use system clipboard
vim.opt.fixeol = false -- Don't add newline at end of file
vim.opt.virtualedit = ""
vim.o.winhighlight = "Visual:Visual"
vim.g.autoformat = false

-- Folding (driven by nvim-ufo, see lua/plugins/editor.lua)
vim.o.foldcolumn = "1" -- Show fold column
vim.o.foldlevel = 99 -- Open most folds by default
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.o.fillchars = [[eob: ,fold: ,foldopen:▾,foldsep: ,foldclose:▸]]

-- Colours. termguicolors must be on before the colorscheme is applied.
vim.opt.termguicolors = true
vim.o.background = "dark"

vim.diagnostic.config({
	virtual_text = true, -- show inline messages
	signs = true, -- show gutter signs
	underline = true, -- show underline
	update_in_insert = false,
	severity_sort = true,
	float = { border = "rounded" },
})

-- HELP
vim.api.nvim_create_user_command("HKL", "help keymap-help", {})
