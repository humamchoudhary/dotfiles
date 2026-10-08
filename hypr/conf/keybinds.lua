-- ── Legend ─────────────────────────────────────────────────────────────────────
-- SUPER          = window action (same workspace)
-- ALT            = workspace action
-- SUPER + ALT    = window action (across workspaces/monitors)
-- CTRL           = focus (same workspace)
-- ALT + CTRL     = focus (across workspaces)
-- Modifier order in code: SUPER > ALT > CTRL

-- ── Apps ───────────────────────────────────────────────────────────────────────
hl.bind("SUPER + Return", hl.dsp.exec_cmd("kitty"), { description = "Open Terminal" })
-- hl.bind("SUPER + e", hl.dsp.exec_cmd("thunar"), { description = "Open Thunar" })
hl.bind("SUPER + e", hl.dsp.exec_cmd("kitty --class 'elio' elio ~/"), { description = "Open File Manager" })
hl.bind(
	"SUPER + x",
	hl.dsp.exec_cmd(
		"rofi -show drun -show-icons -icon-theme Papirus-Dark -drun-display-format '{name}' -theme ~/.config/rofi/launcher.rasi"
	),
	{ description = "App launcher" }
)
hl.bind("SUPER + v", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/clipboard.sh"), { description = "Clipboard history" })
hl.bind(
	"SUPER + equal",
	hl.dsp.exec_cmd("rofi -show calc -modi calc -no-show-match -no-sort -theme ~/.config/rofi/launcher.rasi"),
	{ description = "Calculator" }
)
hl.bind("SUPER + w", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/websearch.sh"), { description = "Web search / URL" })
hl.bind("SUPER + r", hl.dsp.exec_cmd("~/.config/hypr/scripts/reload.sh"))

-- ── Window actions ─────────────────────────────────────────────────────────────
hl.bind("SUPER + q", hl.dsp.window.close(), { description = "Kill active window" })

hl.bind("SUPER + f", function()
	hl.dispatch(hl.dsp.window.fullscreen({ action = "toggle" }))
end, { description = "Toggle Fullscreen" })

hl.bind("SUPER + m", function()
	hl.dispatch(hl.dsp.window.fullscreen({ mode = 1 }))
end, { description = "Toggle Maximize" })

hl.bind("SUPER + SHIFT + f", function()
	hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
end, { description = "Toggle Float" })

hl.bind("SUPER + c", hl.dsp.window.center(), { description = "Center window" })
hl.bind("SUPER + p", hl.dsp.window.pin(), { description = "Pin window" })

hl.bind("ALT + Tab", function()
	local active = hl.get_active_window()
	local was_fullscreen = active and active.fullscreen ~= 0
	hl.dispatch(hl.dsp.window.cycle_next())
	hl.dispatch(hl.dsp.window.bring_to_top())
	if was_fullscreen then
		hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen" }))
	end
end, { description = "Cycle windows" })

hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Drag window" })

-- ── Window movement (same workspace) ───────────────────────────────────────────
local directions = {
	l = { "A", "LEFT" },
	r = { "D", "RIGHT" },
	u = { "W", "UP" },
	d = { "S", "DOWN" },
}

for dir, keys in pairs(directions) do
	hl.bind("SUPER + " .. keys[1], hl.dsp.window.move({ direction = dir }), { description = "Move window " .. dir })
	hl.bind("SUPER + " .. keys[2], hl.dsp.window.move({ direction = dir }), { description = "Move window " .. dir })

	-- ── Window movement (across monitors) ──────────────────────────────────────
	hl.bind(
		"SUPER + ALT +" .. keys[2],
		hl.dsp.window.move({ monitor = dir }),
		{ description = "Move window to monitor " .. dir }
	)
	hl.bind(
		"SUPER + ALT + " .. keys[2],
		hl.dsp.window.move({ monitor = dir }),
		{ description = "Move window to monitor " .. dir }
	)

	-- ── Focus (same workspace) ─────────────────────────────────────────────────
	-- hl.bind("CTRL + " .. keys[1], hl.dsp.focus({ direction = dir }), { description = "Focus window " .. dir })
	-- hl.bind("CTRL + " .. keys[2], hl.dsp.focus({ direction = dir }), { description = "Focus window " .. dir })
end

-- ── Workspace actions ──────────────────────────────────────────────────────────
hl.bind("ALT + d", hl.dsp.focus({ workspace = "+1" }), { description = "Next workspace" })
hl.bind("ALT + a", hl.dsp.focus({ workspace = "-1" }), { description = "Prev workspace" })
hl.bind("ALT + RIGHT", hl.dsp.focus({ workspace = "+1" }), { description = "Next workspace" })
hl.bind("ALT + LEFT", hl.dsp.focus({ workspace = "-1" }), { description = "Prev workspace" })

hl.bind(
	"SUPER + TAB",
	hl.dsp.workspace.swap_monitors({ monitor1 = 0, monitor2 = 1 }),
	{ description = "Swap monitors" }
)

hl.bind("ALT + b", hl.dsp.workspace.toggle_special("bg"), { description = "Toggle bg scratchpad" })

-- hl.bind("SUPER + t", )

for i = 1, 10 do
	local key = i == 10 and "0" or tostring(i)
	-- switch to workspace
	hl.bind("ALT + " .. key, hl.dsp.focus({ workspace = i }), { description = "Switch to workspace " .. i })
	-- move window to workspace and follow
	hl.bind(
		"SUPER +  " .. key,
		hl.dsp.window.move({ workspace = i }),
		{ description = "Move window to workspace " .. i }
	)
	-- send window to workspace silently
	hl.bind(
		"SUPER +  SHIFT + " .. key,
		hl.dsp.window.move({ workspace = i, follow = false }),
		{ description = "Send window to workspace " .. i }
	)
end

-- send window to bg scratchpad
hl.bind("SUPER + b", hl.dsp.window.move({ workspace = "special:bg" }), { description = "Send window to bg scratchpad" })

-- ── System ─────────────────────────────────────────────────────────────────────
hl.bind("SUPER + ALT + l", hl.dsp.exec_cmd("hyprlock"), { description = "Lock screen" })
hl.bind("SUPER + ALT + p", hl.dsp.exec_cmd("~/.config/hypr/scripts/powermenu.sh"), { description = "Power menu" })
hl.bind(
	"SUPER + ALT + t",
	hl.dsp.exec_cmd("~/.config/dotthemes/rofi-theme-switcher.sh"),
	{ description = "Theme switcher" }
)
hl.bind(
	"SUPER + ALT + w",
	hl.dsp.exec_cmd("~/.config/dotthemes/rofi-wallpaper-picker.sh"),
	{ description = "Wallpaper picker" }
)
hl.bind("CTRL + n", hl.dsp.exec_cmd("~/.config/hypr/scripts/nightmode.sh"), { description = "Toggle night mode" })

-- ── Media ──────────────────────────────────────────────────────────────────────
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("swayosd-client --output-volume raise --max-volume 150"),
	{ repeating = true, locked = true }
)

hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("swayosd-client --output-volume lower"),
	{ repeating = true, locked = true }
)

hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness raise"), { repeating = true })

hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"), { repeating = true })

hl.bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | swappy -f -'))
