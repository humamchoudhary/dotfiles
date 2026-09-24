-- lua/plugins/sqlc.lua
-- Query navigation and `sqlc vet` diagnostics for sqlc projects.
--
-- Not an LSP: it shells out to the sqlc binary and publishes the results as
-- diagnostics. It finds sqlc.yaml itself and reads the schema from the
-- migrations listed there, so no database connection is involved.
--
-- Column/table *completion* is a separate problem and this doesn't do it --
-- that still needs a live DB via postgres_lsp or vim-dadbod-completion.

return {
	{
		"0xveya/sqlc.nvim",
		ft = { "sql", "mysql", "plsql" },
		cmd = {
			"SqlcQueries",
			"SqlcPackages",
			"SqlcQueryCommands",
			"SqlcGroup",
			"SqlcVet",
			"SqlcDiagnosticsClear",
		},
		dependencies = { "nvim-telescope/telescope.nvim" },
		config = function()
			-- The main module is sqlc_nvim, not sqlc, so don't rely on lazy's
			-- name-based main-module guess here.
			require("sqlc_nvim").setup({
				lint_on_save = true,
				lint_debounce_ms = 250,
				picker = {
					-- snacks isn't installed; telescope is.
					prefer = { "telescope", "vim_ui" },
					group_by = "file",
				},
				-- Disabled on purpose: every mapping in this config is declared
				-- in lua/config/keymaps.lua. map() skips falsy lhs values.
				keymaps = {
					pick = false,
					pick_last = false,
					pick_package = false,
					pick_command = false,
					group = false,
					vet = false,
				},
			})
		end,
	},
}
