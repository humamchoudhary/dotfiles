-- lua/plugins/dap.lua
-- Adapter and UI wiring lives in lua/lang/dap.lua.

return {
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
}
