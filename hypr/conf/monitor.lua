-- monitor=eDP-1,1920x1080@144.00Hz,0x0,1
-- monitor=HDMI-A-2,1920x1080@60.00Hz,1920x0,1
--
-- env = WLR_DRM_NO_MODIFIERS,1
--
hl.monitor(
	{
		output="eDP-1",
		mode="1920x1080@144",
		position="0x0",
		scale= 1
	}
)

hl.monitor(
	{
		output="HDMI-A-2",
		mode="1920x1080@60.00Hz",
		position="1920x0",
		scale= 1
	}
)
