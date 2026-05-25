import app from "ags/gtk4/app"
import Gtk from "gi://Gtk?version=4.0"
import GLib from "gi://GLib"
import Astal from "gi://Astal"
import AstalNetwork from "gi://AstalNetwork"
import NM from "gi://NM"

// ── Icons ─────────────────────────────────────────────────────────────────────

const ICON_ETH_CONNECTED    = "\udb80\udce3"  // 󰃣 nf-md-ethernet_cable
const ICON_ETH_DISCONNECTED = "\udb80\udce4"  // 󰃤 nf-md-ethernet_cable_off

// ── Helpers ───────────────────────────────────────────────────────────────────

function speedToLabel(speed: number): string {
    if (speed >= 1000) return `${speed / 1000} Gbps`
    if (speed > 0)     return `${speed} Mbps`
    return "Unknown"
}

// ── Info cell ─────────────────────────────────────────────────────────────────

function InfoCell(label: string, value: string, accent = false): Gtk.Widget {
    const box = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 3, hexpand: true })
    box.get_style_context().add_class("info-cell")

    const lbl = new Gtk.Label({ xalign: 0, label })
    lbl.get_style_context().add_class("info-label")

    const val = new Gtk.Label({ xalign: 0, label: value || "—" })
    val.set_ellipsize(3)
    val.get_style_context().add_class(accent ? "info-val accent" : "info-val")

    box.append(lbl)
    box.append(val)
    return box
}

// ── Stat row ──────────────────────────────────────────────────────────────────

function StatRow(icon: string, label: string, value: string): Gtk.Widget {
    const box = new Gtk.Box({ spacing: 10 })
    box.get_style_context().add_class("stat-row")

    const iconLbl = new Gtk.Label({ label: icon })
    iconLbl.get_style_context().add_class("stat-icon")

    const nameLbl = new Gtk.Label({ xalign: 0, hexpand: true, label })
    nameLbl.get_style_context().add_class("stat-name")

    const valLbl = new Gtk.Label({ xalign: 1, label: value })
    valLbl.get_style_context().add_class("stat-value")
    valLbl.set_ellipsize(3)

    box.append(iconLbl)
    box.append(nameLbl)
    box.append(valLbl)
    return box
}

function Divider(): Gtk.Widget {
    const sep = new Gtk.Separator({ orientation: Gtk.Orientation.HORIZONTAL })
    sep.get_style_context().add_class("eth-sep")
    return sep
}

// ── Connected view ────────────────────────────────────────────────────────────

function buildConnectedView(wired: AstalNetwork.Wired): Gtk.Widget {
    const nmDev = wired.device as unknown as NM.DeviceEthernet

    let ipAddr  = ""
    let ip6Addr = ""
    let gw      = ""
    let dns     = ""
    let mac     = ""
    let speed   = 0
    let iface   = ""
    let mask    = ""

    try {
        const ip4 = nmDev?.ip4_config
        if (ip4) {
            const addrs = ip4.get_addresses()
            if (addrs?.length > 0) {
                ipAddr = addrs[0].get_address() ?? ""
                const prefix = addrs[0].get_prefix()
                // Convert prefix to subnet mask
                const bits = 0xffffffff << (32 - prefix)
                mask = [
                    (bits >>> 24) & 0xff,
                    (bits >>> 16) & 0xff,
                    (bits >>> 8)  & 0xff,
                    bits & 0xff,
                ].join(".")
            }
            gw = ip4.get_gateway() ?? ""
            const ns = ip4.get_nameservers()
            if (ns?.length > 0) dns = ns[0]
        }

        const ip6 = nmDev?.ip6_config
        if (ip6) {
            const addrs = ip6.get_addresses()
            if (addrs?.length > 0) ip6Addr = addrs[0].get_address() ?? ""
        }

        mac   = nmDev?.hw_address ?? ""
        speed = nmDev?.speed ?? 0
        iface = nmDev?.interface ?? ""
    } catch (e) {
        print(`ETH info error: ${e}`)
    }

    const outer = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 0 })

    // ── Header
    const header = new Gtk.Box({ spacing: 12 })
    header.get_style_context().add_class("eth-header")

    const iconLbl = new Gtk.Label({
        label:  ICON_ETH_CONNECTED,
        halign: Gtk.Align.CENTER,
        valign: Gtk.Align.CENTER,
    })
    iconLbl.get_style_context().add_class("eth-icon connected")
    iconLbl.set_size_request(42, 42)

    const headerCol = new Gtk.Box({
        orientation: Gtk.Orientation.VERTICAL,
        spacing:     4,
        hexpand:     true,
        valign:      Gtk.Align.CENTER,
    })

    const nameRow = new Gtk.Box({ spacing: 8, valign: Gtk.Align.CENTER })
    const ifaceLbl = new Gtk.Label({ xalign: 0, label: iface || "Ethernet" })
    ifaceLbl.get_style_context().add_class("eth-iface")
    const badge = new Gtk.Label({ label: "CONNECTED" })
    badge.get_style_context().add_class("eth-badge")
    nameRow.append(ifaceLbl)
    nameRow.append(badge)

    const speedLbl = new Gtk.Label({ xalign: 0 })
    speedLbl.set_label(speedToLabel(speed))
    speedLbl.get_style_context().add_class("eth-speed")

    headerCol.append(nameRow)
    headerCol.append(speedLbl)
    header.append(iconLbl)
    header.append(headerCol)
    outer.append(header)

    // ── IPv4 section
    const ip4Section = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 8 })
    ip4Section.get_style_context().add_class("eth-section")

    const ip4Label = new Gtk.Label({ xalign: 0, label: "IPv4" })
    ip4Label.get_style_context().add_class("eth-section-label")
    ip4Section.append(ip4Label)

    const ip4Grid = new Gtk.Box({ spacing: 8 })
    const ip4Col0 = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 8, hexpand: true })
    const ip4Col1 = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 8, hexpand: true })

    ip4Col0.append(InfoCell("IP ADDRESS",   ipAddr, true))
    ip4Col1.append(InfoCell("GATEWAY",      gw))
    ip4Col0.append(InfoCell("SUBNET MASK",  mask))
    ip4Col1.append(InfoCell("DNS",          dns))

    ip4Grid.append(ip4Col0)
    ip4Grid.append(ip4Col1)
    ip4Section.append(ip4Grid)
    outer.append(ip4Section)

    outer.append(Divider())

    // ── IPv6 section
    const ip6Section = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 8 })
    ip6Section.get_style_context().add_class("eth-section")

    const ip6Label = new Gtk.Label({ xalign: 0, label: "IPv6" })
    ip6Label.get_style_context().add_class("eth-section-label")
    ip6Section.append(ip6Label)
    ip6Section.append(InfoCell("IP ADDRESS", ip6Addr || "Not available"))
    outer.append(ip6Section)

    outer.append(Divider())

    // ── Hardware section
    const hwSection = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 8 })
    hwSection.get_style_context().add_class("eth-section")

    const hwLabel = new Gtk.Label({ xalign: 0, label: "Hardware" })
    hwLabel.get_style_context().add_class("eth-section-label")
    hwSection.append(hwLabel)

    const hwGrid = new Gtk.Box({ spacing: 8 })
    const hwCol0 = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 8, hexpand: true })
    const hwCol1 = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 8, hexpand: true })

    hwCol0.append(InfoCell("MAC ADDRESS", mac))
    hwCol1.append(InfoCell("SPEED",       speedToLabel(speed)))
    hwCol0.append(InfoCell("INTERFACE",   iface))

    hwGrid.append(hwCol0)
    hwGrid.append(hwCol1)
    hwSection.append(hwGrid)
    outer.append(hwSection)

    return outer
}

// ── Disconnected view ─────────────────────────────────────────────────────────

function buildDisconnectedView(): Gtk.Widget {
    const box = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 8 })
    box.get_style_context().add_class("eth-disconnected")

    const icon = new Gtk.Label({
        label:  ICON_ETH_DISCONNECTED,
        halign: Gtk.Align.CENTER,
    })
    icon.get_style_context().add_class("eth-icon disconnected")

    const lbl = new Gtk.Label({ label: "No cable connected" })
    lbl.get_style_context().add_class("eth-disconn-label")
    lbl.set_halign(Gtk.Align.CENTER)

    const sub = new Gtk.Label({ label: "Plug in an ethernet cable" })
    sub.get_style_context().add_class("eth-disconn-sub")
    sub.set_halign(Gtk.Align.CENTER)

    box.append(icon)
    box.append(lbl)
    box.append(sub)
    return box
}

// ── Main widget ───────────────────────────────────────────────────────────────

export function Ethernet(monitor = 0, xOffset = 0) {
    const network = AstalNetwork.get_default()
    const wired   = network.wired

    const body = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL })
    body.get_style_context().add_class("eth-body")

    function rebuild() {
        let c = body.get_first_child()
        while (c) { const n = c.get_next_sibling(); body.remove(c); c = n }

        const tag = new Gtk.Label({ xalign: 0, label: "ETHERNET" })
        tag.get_style_context().add_class("eth-tag")

        const tagWrap = new Gtk.Box()
        tagWrap.get_style_context().add_class("eth-tag-wrap")
        tagWrap.append(tag)
        body.append(tagWrap)

        const connected = wired?.internet === AstalNetwork.Internet.CONNECTED
        if (connected && wired) {
            body.append(buildConnectedView(wired))
        } else {
            body.append(buildDisconnectedView())
        }
    }

    rebuild()

    if (wired) {
        wired.connect("notify::internet", rebuild)
        wired.connect("notify::speed",    rebuild)
    }
    network.connect("notify::primary", rebuild)

    const scrolled = new Gtk.ScrolledWindow({
        hscrollbar_policy: Gtk.PolicyType.NEVER,
        vscrollbar_policy: Gtk.PolicyType.AUTOMATIC,
    })
    scrolled.set_child(body)
    scrolled.set_size_request(-1, 360)
    scrolled.get_style_context().add_class("eth-scroll")

    const card = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL })
    card.get_style_context().add_class("eth-card")
    card.set_size_request(360, -1)
    card.append(scrolled)

    function handleBackdropClick(self: Astal.Window) {
        const click = new Gtk.GestureClick()
        click.connect("pressed", (_g, _n, x, y) => {
            const child = self.get_child()
            if (!child) return
            const alloc = child.get_allocation()
            const outside =
                x < alloc.x || x > alloc.x + alloc.width ||
                y < alloc.y || y > alloc.y + alloc.height
            if (outside) app.toggle_window("Ethernet")
        })
        self.add_controller(click)
    }

    return (
        <window
            name="Ethernet"
            monitor={monitor}
            $={(self) => {
                app.add_window(self)
                handleBackdropClick(self)
            }}
            anchor={
                Astal.WindowAnchor.TOP |
                Astal.WindowAnchor.LEFT |
                Astal.WindowAnchor.RIGHT |
                Astal.WindowAnchor.BOTTOM
            }
            exclusivity={Astal.Exclusivity.IGNORE}
            keymode={Astal.Keymode.ON_DEMAND}
            css={`all: unset; background: transparent;`}
        >
            <box
                halign={Gtk.Align.END}
                valign={Gtk.Align.START}
                css={`margin-top: 50px; margin-right: 10px;`}
            >
                {card}
            </box>
        </window>
    )
}
