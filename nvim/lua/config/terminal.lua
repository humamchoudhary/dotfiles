-- lua/config/terminal.lua
-- Terminal ANSI palette for :terminal buffers (including the floating terminal
-- in plugin/floaterminal.lua).
--
-- oxocarbon ships a decorative terminal palette that ignores what the ANSI
-- slots MEAN: it puts a blue in slot 1 (red), a purple in slot 2 (green) and a
-- green in slot 3 (yellow). The result is that an error log prints blue, a
-- warning prints green and a success prints purple -- unreadable.
--
-- Slots 1-6 therefore keep conventional hues so logs stay legible. The
-- neutrals and magenta come from lua/theme.lua, so the palette still follows
-- whatever dotthemes/rofi-theme-switcher.sh last wrote.

local p = require("theme")

local M = {}

function M.apply()
	local ansi = {
		[0] = p.overlay, -- black (lifted off the bg so it's not invisible)
		[1] = "#ff5c57", -- red
		[2] = "#5af78e", -- green
		[3] = "#f3f99d", -- yellow
		[4] = "#57c7ff", -- blue
		[5] = p.accent, -- magenta -> theme accent
		[6] = "#9aedfe", -- cyan
		[7] = p.text, -- white
		[8] = p.subtext, -- bright black
		[9] = "#ff6e67", -- bright red
		[10] = "#5af78e", -- bright green
		[11] = "#f4f99d", -- bright yellow
		[12] = "#57c7ff", -- bright blue
		[13] = p.accent, -- bright magenta
		[14] = "#9aedfe", -- bright cyan
		[15] = p.bright, -- bright white
	}

	for i = 0, 15 do
		vim.g["terminal_color_" .. i] = ansi[i]
	end
end

return M
