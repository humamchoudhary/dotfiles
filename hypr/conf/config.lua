local colors = require("conf.colors")

-- general {
--     gaps_in     = 2
--     gaps_out    = 2
--     border_size = 1
--     col.active_border   = rgb(0a0a0a)
--     col.inactive_border = rgb(050505)
--
--     resize_on_border     = true
--     hover_icon_on_border = false
-- }
--
-- decoration {
--     rounding         = 0
--     active_opacity   = 1.0
--     inactive_opacity = 0.95
--
--     dim_inactive         = true
--     dim_strength         = 0.1
--     dim_special          = 0.2
--
--     blur {
--         enabled = false
--     }
--
--     shadow {
--         enabled = false
--     }
-- }
--
hl.config({
    general = {
            border_size = 1,
    gaps_in = 5,
    gaps_out = 10,
    layout =        "master",
    resize_on_border= true,
    extend_border_grab_area = true,
    resize_corner = true,
    snap = {
        enabled = true,
        respect_gaps = true
    },
    allow_tearing = true
    },
    decoration = {
        rounding = 10,
        rounding_power = 5.0,
        inactive_opacity = 0.95,
        dim_inactive=true,
        dim_strength = 0.1
    },
    binds={
        drag_threshold = 10 
    },
    cursor = {
        no_hardware_cursors = 1,
    },
})