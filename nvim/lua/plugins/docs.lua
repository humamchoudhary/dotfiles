-- lua/plugins/docs.lua
-- The in-panel LSP doc view. The home-grown DocViewer under lua/docviewer/ is
-- set up from init.lua.

return {
	{
		"amrbashir/nvim-docs-view",
		lazy = true,
		cmd = "DocsViewToggle",
		opts = {
			position = "bottom",
		},
	},
}
