return {
	"Aietes/esp32.nvim",
	dependencies = { "nvim-lua/plenary.nvim", "echasnovski/mini.snippets" },
	config = function()
		require("esp32").setup({
			build_dir = "build.clang", -- Target directory for Clang database builds
		})
	end,
}
