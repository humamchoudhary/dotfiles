-- # ── Float these ────────────────────────────────────────────────────────────────
-- windowrulev2 = float, class:^(pavucontrol)$
-- windowrulev2 = float, class:^(blueman-manager)$
-- windowrulev2 = float, class:^(nm-connection-editor)$
--
-- ── Picture-in-Picture ──────────────────────────────────────────────────────
-- Floats, pins, and sizes the PiP window; opens bottom-right. Dragging is
-- handled by scripts/pip-snap.sh, which clips it to the nearest corner.

hl.window_rule({
	match = { title = "Picture-in-Picture" },
	float = true,
	pin = true,
	size = "(monitor_w*0.25) (monitor_h*0.25)",
	move = "monitor_w-window_w-10  monitor_h-window_h-10",
})

hl.window_rule({
	match = { class = "elio" }, -- or initial_class, depending on the wrapper's naming
	float = true,
	size = "(monitor_w*0.65) (monitor_h*0.65)",
	center = true,
})

hl.window_rule({
	match = { class = "firefox", title = "Library" },
	float = true,
	size = "(monitor_w*0.6) (monitor_h*0.6)",
	center = true,
})

hl.window_rule({
	match = { class = "DesktopEditors" },
	float = true,
	center = true,
})

hl.on("window.title", function(w)
	if not w or not w.title then
		return
	end
	if not w.title:lower():find("extension", 1, true) then
		return
	end

	-- 1. Correct the action to "on" and target this specific window
	hl.dispatch(hl.dsp.window.float({ action = "on", window = w }))

	-- 2. Resize the targeted window
	hl.dispatch(hl.dsp.window.resize({ x = "500", y = "800", window = w }))

	-- 3. Pinning only works AFTER the window is successfully floating
	hl.dispatch(hl.dsp.window.pin({ action = "on", window = w }))

	-- 4. Center the window on the screen
	hl.dispatch(hl.dsp.window.center({ window = w }))
end)

hl.window_rule({
	match = {
		title = "Extension",
	},
	float = true,
	pin = true,
	size = "(monitor_w*0.6) (monitor_h*0.6)",
	center = true,
})

hl.window_rule({
	match = { class = "qemu" },
	float = true,
	size = "(monitor_w*0.6) (monitor_h*0.6)",
	center = true,
})

hl.window_rule({
	match = { class = "hyprland-share-picker" },
	float = true,
	size = "(monitor_w*0.4) (monitor_h*0.4)",
	center = true,
})

--
-- # ── Terminal opacity ──────────────────────────────────────────────────────────
-- windowrulev2 = opacity 1.0, class:^(kitty)$
--
-- # ── Rofi ──────────────────────────────────────────────────────────────────────
-- windowrulev2 = float,    class:^(Rofi)$
-- windowrulev2 = pin,      class:^(Rofi)$
-- windowrulev2 = stayfullscreen, class:^(Rofi)$

-- ── TUI popups (hosted in kitty via scripts/tui.sh) ─────────────────────────
-- Sizes are tuned to the 11pt JetBrains Mono kitty font (~9x19 px per cell);
-- adjust together with the size in each TUI's config if the font changes.
-- Bar: 40px tall with 10px top margin, so popups anchored below it start at y=56.

-- fsel — app launcher (centered, opened from waybar launcher / SUPER+x)
hl.window_rule({
	match = { class = "fsel" },
	float = true,
	pin = true,
	size = "483 628",
	center = true,
})

-- cclip — clipboard history (centered, SUPER+v); big enough for inline
-- image previews and readable text rows (Alt+i opens the fullscreen preview)
hl.window_rule({
	match = { class = "cclip" },
	float = true,
	pin = true,
	size = "700 560",
	center = true,
})

-- powermenu — fsel dmenu power options (centered, SUPER+ALT+p)
hl.window_rule({
	match = { class = "powermenu" },
	float = true,
	pin = true,
	size = "380 300",
	center = true,
})

-- themepick — theme switcher via fsel dmenu (centered, SUPER+ALT+t)
hl.window_rule({
	match = { class = "themepick" },
	float = true,
	pin = true,
	size = "330 460",
	center = true,
})

-- wallpick — wallpaper picker via fsel dmenu (centered, SUPER+ALT+w)
hl.window_rule({
	match = { class = "wallpick" },
	float = true,
	pin = true,
	size = "365 460",
	center = true,
})

-- hexowl — calculator (centered, SUPER+equal)
hl.window_rule({
	match = { class = "hexowl" },
	float = true,
	pin = true,
	size = "520 380",
	center = true,
})

-- wiremix — audio mixer, opens under the waybar volume module (right side)
hl.window_rule({
	match = { class = "wiremix" },
	float = true,
	pin = true,
	size = "610 510",
	move = "1300 50",
})

-- linktui — wifi/eth/bluetooth, opens under the waybar network modules (right side)
hl.window_rule({
	match = { class = "linktui" },
	float = true,
	pin = true,
	size = "660 585",
	move = "1250 50",
})

-- fum — MPRIS music client, opens under the waybar music module (left side)
hl.window_rule({
	match = { class = "fum" },
	float = true,
	pin = true,
	size = "410 500",
	move = "230 50",
})

-- mirador — calendar/dashboard, opens under the waybar clock, near full size
hl.window_rule({
	match = { class = "mirador" },
	float = true,
	pin = true,
	size = "(monitor_w*0.92) (monitor_h*0.87)",
	move = "85 50",
})

-- ── Scratchpad terminal ──────────────────────────────────────────────────────
-- Routes the persistent scratchpad kitty (class "scratch-term") onto the
-- `scratch` special workspace as a centred floating window.

hl.window_rule({
	match = { title = "scratch-term" },
	float = true,
	pin = true,
	center = true,
	size = "(monitor_w*0.5) (monitor_h*0.5)",
})

hl.window_rule({
	match = {
		class = "steam_app",
	},
	fullscreen = true,
	confine_pointer = true,
})
