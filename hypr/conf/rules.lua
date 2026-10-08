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
	match = { class = "elio" },   -- or initial_class, depending on the wrapper's naming
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
