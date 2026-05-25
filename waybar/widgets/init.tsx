import app from "ags/gtk4/app"
import {Clock} from "../widgets/clock.tsx"
import {Audio} from "../widgets/audio.tsx"
import {Wifi} from "../widgets/wifi.tsx"
import { Ethernet } from "./eth.tsx"
import { Bluetooth } from "./bluetooth.tsx"
import style from "./style.css"
import  {Music } from "./musicplayer.tsx"
import { AppLauncher } from "./applauncher.tsx"
import { createState } from "ags"
import Hyprland from "gi://AstalHyprland"

app.apply_css("../colors/colors.css")


const [monitor, setMonitor] = createState(0)
const hyprland = Hyprland.get_default()
const hypr_monitor = hyprland.get_focused_monitor()
hyprland.connect("notify::focused-monitor", () => {
    const monitor = hyprland.get_focused_monitor()
    print(`Focused monitor: ${monitor.get_id()}`)
    setMonitor(monitor.get_id())
})



app.start({
    css:style,
  main() {
    Clock(monitor)
    Audio(monitor)
    Wifi(monitor)
    Ethernet(monitor)
    Bluetooth(monitor)
    Music(monitor)
    AppLauncher(monitor)
  },
})

