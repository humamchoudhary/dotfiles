import app from "ags/gtk4/app"
import Gtk from "gi://Gtk?version=4.0"
import GLib from "gi://GLib"
import Astal from "gi://Astal"
import AstalBluetooth from "gi://AstalBluetooth?version=0.1"
import Gio from "gi://Gio"                          // ← add

// ── Icons ─────────────────────────────────────────────────────────────────────

const ICON_BT_ON      = "\uf294"
const ICON_BT_OFF     = "\udb80\udcb2"
const ICON_BT_CONNECT = "\udb80\udcb3"
const ICON_HEADPHONES = "\udb80\udecb"
const ICON_HEADSET    = "\udb80\udecc"
const ICON_SPEAKER    = "\udb81\udd43"
const ICON_KEYBOARD   = "\udb82\udd8b"
const ICON_MOUSE      = "\udb82\udd96"
const ICON_PHONE      = "\udb80\udff3"
const ICON_WATCH      = "\udb81\udc67"
const ICON_GAMEPAD    = "\udb80\udce5"
const ICON_UNKNOWN    = "\uf294"
const ICON_REFRESH    = "\uf021"



// ── Bluetooth singleton ───────────────────────────────────────────────────────

const bluetooth = AstalBluetooth.get_default()

// ── Helpers ───────────────────────────────────────────────────────────────────

function log(tag: string, msg: string) {
    print(`[BT][${tag}] ${msg}`)
}

function logError(tag: string, msg: string, err?: any) {
    print(`[BT][${tag}][ERR] ${msg}${err !== undefined ? `: ${err}` : ""}`)
}

function deviceIcon(device: AstalBluetooth.Device): string {
    const name = (device.name ?? "").toLowerCase()
    const type = (device.icon ?? "").toLowerCase()

    if (name.includes("headphone") || name.includes("headset") ||
        name.includes("airpod")    || name.includes("buds")    ||
        type.includes("headphone") || type.includes("headset") ||
        type.includes("audio-headset")) {
        return name.includes("mic") ? ICON_HEADSET : ICON_HEADPHONES
    }
    if (name.includes("speaker")    || type.includes("speaker"))    return ICON_SPEAKER
    if (name.includes("keyboard")   || type.includes("keyboard"))   return ICON_KEYBOARD
    if (name.includes("mouse")      || type.includes("mouse"))      return ICON_MOUSE
    if (name.includes("phone")      || type.includes("phone")       ||
        name.includes("mobile")     || name.includes("iphone")      ||
        name.includes("android"))                                    return ICON_PHONE
    if (name.includes("watch")      || name.includes("band") ||
        type.includes("wearable"))                                   return ICON_WATCH
    if (name.includes("controller") || name.includes("gamepad") ||
        name.includes("joystick"))                                   return ICON_GAMEPAD
    return ICON_UNKNOWN
}

function formatAddress(addr: string): string {
    return (addr ?? "").toUpperCase()
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

// ── Device row ────────────────────────────────────────────────────────────────

function DeviceRow(opts: {
    device:       AstalBluetooth.Device
    onConnect:    () => void
    onDisconnect: () => void
}): Gtk.Widget {
    const { device, onConnect, onDisconnect } = opts
    const isConnected = device.connected

    // ← outer is a BOX not a button — no event swallowing
    const outer = new Gtk.Box({ spacing: 10 })
    outer.get_style_context().add_class("bt-device-btn")
    if (isConnected) outer.get_style_context().add_class("connected")

    const iconLbl = new Gtk.Label({ label: deviceIcon(device) })
    iconLbl.get_style_context().add_class("bt-device-icon")
    if (isConnected) iconLbl.get_style_context().add_class("connected")

    const nameCol = new Gtk.Box({
        orientation: Gtk.Orientation.VERTICAL,
        spacing:     2,
        hexpand:     true,
        valign:      Gtk.Align.CENTER,
    })

    const nameLbl = new Gtk.Label({ xalign: 0, label: device.name ?? "Unknown" })
    nameLbl.set_ellipsize(3)
    nameLbl.get_style_context().add_class("bt-device-name")
    if (isConnected) nameLbl.get_style_context().add_class("connected")

    const pct = device.battery_percentage ?? -1
    const battStr = pct > 0 ? ` · ${Math.round(pct * 100)}%` : ""
    const addrLbl = new Gtk.Label({ xalign: 0, label: formatAddress(device.address) + battStr })
    addrLbl.get_style_context().add_class("bt-device-addr")

    nameCol.append(nameLbl)
    nameCol.append(addrLbl)

    const rightBox = new Gtk.Box({ spacing: 6, valign: Gtk.Align.CENTER })

    if (isConnected) {
        const badge = new Gtk.Label({ label: "CONNECTED" })
        badge.get_style_context().add_class("bt-conn-badge")
        rightBox.append(badge)
    }

    const actionBtn = new Gtk.Button()
    actionBtn.get_style_context().add_class("bt-action-btn")
    if (isConnected) actionBtn.get_style_context().add_class("danger")
    actionBtn.set_child(new Gtk.Label({ label: isConnected ? "Disconnect" : "Connect" }))
    actionBtn.connect("clicked", () => {
        log("DeviceRow", `${isConnected ? "Disconnect" : "Connect"} clicked for "${device.name}"`)
        if (isConnected) onDisconnect()
        else onConnect()
    })
    rightBox.append(actionBtn)

    outer.append(iconLbl)
    outer.append(nameCol)
    outer.append(rightBox)

    return outer
}

// ── Connected card ────────────────────────────────────────────────────────────

function buildConnectedCard(rebuild: () => void): Gtk.Widget {
    const devices   = bluetooth.devices ?? []
    const connected = devices.filter(d => d.connected)

    log("buildConnectedCard", `${connected.length} connected device(s)`)

    if (connected.length === 0) {
        const box = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 6 })
        box.get_style_context().add_class("connected-card")
        box.get_style_context().add_class("disconnected")
        box.set_halign(Gtk.Align.CENTER)

        const icon = new Gtk.Label({ label: ICON_BT_CONNECT, halign: Gtk.Align.CENTER })
        icon.get_style_context().add_class("disconn-icon")
        const lbl = new Gtk.Label({ label: "No connected devices" })
        lbl.get_style_context().add_class("disconn-label")
        const sub = new Gtk.Label({ label: "Connect a device below" })
        sub.get_style_context().add_class("disconn-sub")

        box.append(icon)
        box.append(lbl)
        box.append(sub)
        return box
    }

    const first   = connected[0]
    const pct     = first.battery_percentage ?? -1
    const battStr = pct > 0 ? `${Math.round(pct * 100)}%` : "N/A"

    const outer = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 12 })
    outer.get_style_context().add_class("connected-card")

    // Header
    const ssidRow = new Gtk.Box({ spacing: 10, valign: Gtk.Align.CENTER })

    const iconLbl = new Gtk.Label({
        label:  deviceIcon(first),
        halign: Gtk.Align.CENTER,
        valign: Gtk.Align.CENTER,
    })
    iconLbl.get_style_context().add_class("conn-icon")
    iconLbl.set_size_request(38, 38)

    const ssidCol = new Gtk.Box({
        orientation: Gtk.Orientation.VERTICAL,
        spacing:     4,
        hexpand:     true,
        valign:      Gtk.Align.CENTER,
    })

    const nameRow = new Gtk.Box({ spacing: 8, valign: Gtk.Align.CENTER })
    const nameLbl = new Gtk.Label({ xalign: 0, label: first.name ?? "Unknown" })
    nameLbl.get_style_context().add_class("conn-ssid")
    const badge = new Gtk.Label({ label: "CONNECTED" })
    badge.get_style_context().add_class("conn-badge")
    nameRow.append(nameLbl)
    nameRow.append(badge)

    const metaLbl = new Gtk.Label({ xalign: 0, label: formatAddress(first.address) })
    metaLbl.get_style_context().add_class("conn-meta")

    ssidCol.append(nameRow)
    ssidCol.append(metaLbl)
    ssidRow.append(iconLbl)
    ssidRow.append(ssidCol)
    outer.append(ssidRow)

    // Info grid
    const grid = new Gtk.Box({ spacing: 8 })
    const col0 = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 8, hexpand: true })
    const col1 = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 8, hexpand: true })

    col0.append(InfoCell("ADDRESS", formatAddress(first.address)))
    col1.append(InfoCell("BATTERY", battStr))
    col0.append(InfoCell("TYPE",    first.icon ?? "Unknown"))
    if (connected.length > 1) {
        col1.append(InfoCell("ALSO CONNECTED", `${connected.length - 1} more`))
    }

    grid.append(col0)
    grid.append(col1)
    outer.append(grid)

    // Actions
    const actionRow = new Gtk.Box({ spacing: 8 })

    const disconnBtn = new Gtk.Button()
    disconnBtn.get_style_context().add_class("net-action-btn")
    disconnBtn.get_style_context().add_class("danger")
    disconnBtn.set_hexpand(true)
    disconnBtn.set_child(new Gtk.Label({ label: "Disconnect" }))
    disconnBtn.connect("clicked", () => {
        log("buildConnectedCard", `Disconnect clicked for "${first.name}"`)
        // Use same pattern as their working code
        first.disconnect_device((_, err) => {
            if (err) logError("disconnect", `Failed for "${first.name}"`, err)
            else log("disconnect", `Success for "${first.name}"`)
            GLib.timeout_add(GLib.PRIORITY_DEFAULT, 500, () => { rebuild(); return GLib.SOURCE_REMOVE })
        })
    })
    actionRow.append(disconnBtn)

    if (connected.length > 1) {
        const disconnAllBtn = new Gtk.Button()
        disconnAllBtn.get_style_context().add_class("net-action-btn")
        disconnAllBtn.set_hexpand(true)
        disconnAllBtn.set_child(new Gtk.Label({ label: "Disconnect All" }))
        disconnAllBtn.connect("clicked", () => {
            log("buildConnectedCard", `Disconnect All: ${connected.length} devices`)
            for (const d of connected) {
                d.disconnect_device((_, err) => {
                    if (err) logError("disconnect", `Failed for "${d.name}"`, err)
                })
            }
            GLib.timeout_add(GLib.PRIORITY_DEFAULT, 500, () => { rebuild(); return GLib.SOURCE_REMOVE })
        })
        actionRow.append(disconnAllBtn)
    }

    outer.append(actionRow)
    return outer
}

// ── Devices list ──────────────────────────────────────────────────────────────

function buildDevicesList(rebuild: () => void): Gtk.Widget {
    const devices = (bluetooth.devices ?? [])
        .filter(d => d.name !== null)
        .sort((a, b) => Number(b.connected) - Number(a.connected))

    log("buildDevicesList", `${devices.length} devices`)

    const outer = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 10 })
    outer.get_style_context().add_class("bt-networks-section")
    outer.set_vexpand(true)

    // Header
    const headerRow = new Gtk.Box({ spacing: 8 })
    const headerLbl = new Gtk.Label({ xalign: 0, hexpand: true, label: "AVAILABLE DEVICES" })
    headerLbl.get_style_context().add_class("section-label")

    const scanLbl = new Gtk.Label({
        label: `${ICON_REFRESH}  ${bluetooth.adapter?.discovering ? "STOP" : "SCAN"}`
    })
    scanLbl.get_style_context().add_class("scan-btn-lbl")

    const scanBtn = new Gtk.Button()
    scanBtn.get_style_context().add_class("scan-btn")
    if (bluetooth.adapter?.discovering) scanBtn.get_style_context().add_class("active")
    scanBtn.set_child(scanLbl)
    scanBtn.connect("clicked", () => {
        if (bluetooth.adapter?.discovering) {
            log("scan", "Stopping discovery")
            bluetooth.adapter.stop_discovery()
        } else {
            log("scan", "Starting discovery")
            bluetooth.adapter.start_discovery()
            // Auto stop after 30s
            GLib.timeout_add(GLib.PRIORITY_DEFAULT, 30000, () => {
                log("scan", "Auto-stopping discovery after 30s")
                try { bluetooth.adapter?.stop_discovery() } catch (_) {}
                return GLib.SOURCE_REMOVE
            })
        }
        // Rebuild after small delay to reflect new discovering state
        GLib.timeout_add(GLib.PRIORITY_DEFAULT, 200, () => { rebuild(); return GLib.SOURCE_REMOVE })
    })

    headerRow.append(headerLbl)
    headerRow.append(scanBtn)
    outer.append(headerRow)

    const listBox = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 3 })
    listBox.set_vexpand(true)

    if (devices.length === 0) {
        const empty = new Gtk.Label({ label: "No devices found — press scan" })
        empty.get_style_context().add_class("empty-label")
        listBox.append(empty)
    } else {
        for (const device of devices) {
            listBox.append(DeviceRow({
                device,
                onConnect: () => {
                    log("connect", `Connecting to "${device.name}"`)

                    // Power on if needed — exactly like their code
                    if (!bluetooth.isPowered) {
                        log("connect", "BT off — powering on first")
                        bluetooth.toggle()
                    }

                    // 100ms delay then connect — exactly like their code
                    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 100, () => {
                        device.connect_device((_, err) => {
                            if (err) {
                                logError("connect", `Failed for "${device.name}"`, err)
                            } else {
                                log("connect", `Success for "${device.name}"`)
                            }
                            GLib.timeout_add(GLib.PRIORITY_DEFAULT, 500, () => {
                                rebuild()
                                return GLib.SOURCE_REMOVE
                            })
                        })
                        return GLib.SOURCE_REMOVE
                    })
                },
                onDisconnect: () => {
                    log("disconnect", `Disconnecting "${device.name}"`)
                    device.disconnect_device((_, err) => {
                        if (err) logError("disconnect", `Failed for "${device.name}"`, err)
                        else log("disconnect", `Success for "${device.name}"`)
                        GLib.timeout_add(GLib.PRIORITY_DEFAULT, 500, () => {
                            rebuild()
                            return GLib.SOURCE_REMOVE
                        })
                    })
                },
            }))
        }
    }

    outer.append(listBox)
    return outer
}

// ── Main widget ───────────────────────────────────────────────────────────────

export function Bluetooth(monitor = 0, xOffset = 0) {
    log("init", "Bluetooth widget initializing")

    let expanded = false

    const compactBody = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 10 })
    compactBody.get_style_context().add_class("bt-compact-body")

    const expandedBody = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL })
    expandedBody.get_style_context().add_class("bt-expanded-body")
    expandedBody.set_vexpand(true)

    const scrolled = new Gtk.ScrolledWindow({
        hscrollbar_policy: Gtk.PolicyType.NEVER,
        vscrollbar_policy: Gtk.PolicyType.AUTOMATIC,
    })
    scrolled.set_child(expandedBody)
    scrolled.set_vexpand(true)
    scrolled.set_size_request(-1, 300)
    scrolled.get_style_context().add_class("bt-scroll")
    scrolled.set_visible(false)

    const advBtnLbl = new Gtk.Label()
    advBtnLbl.get_style_context().add_class("bt-adv-lbl")
    const advBtn = new Gtk.Button()
    advBtn.get_style_context().add_class("bt-adv-btn")
    advBtn.set_child(advBtnLbl)
    advBtn.set_hexpand(true)

    function rebuildCompact() {
        log("rebuildCompact", `powered: ${bluetooth.isPowered}`)

        let c = compactBody.get_first_child()
        while (c) { const n = c.get_next_sibling(); compactBody.remove(c); c = n }

        const powered = bluetooth.isPowered

        // Toggle row
        const toggleRow = new Gtk.Box({ spacing: 10 })
        toggleRow.get_style_context().add_class("bt-toggle-row")

        const tagLbl = new Gtk.Label({ xalign: 0, hexpand: true, label: "BLUETOOTH" })
        tagLbl.get_style_context().add_class("bt-compact-tag")

        const toggleBtn = new Gtk.Button()
        toggleBtn.get_style_context().add_class("bt-toggle-btn")
        if (powered) toggleBtn.get_style_context().add_class("active")

        const iconLbl = new Gtk.Label({ label: powered ? ICON_BT_ON : ICON_BT_OFF })
        iconLbl.get_style_context().add_class("bt-toggle-icon")
        if (powered) iconLbl.get_style_context().add_class("active")

        const textLbl = new Gtk.Label({ label: powered ? "ON" : "OFF" })
        textLbl.get_style_context().add_class("bt-toggle-text")
        if (powered) textLbl.get_style_context().add_class("active")

        const innerRow = new Gtk.Box({ spacing: 6 })
        innerRow.append(iconLbl)
        innerRow.append(textLbl)
        toggleBtn.set_child(innerRow)

        toggleBtn.connect("clicked", () => {
            log("toggle", `Setting powered to ${!powered}`)
            // Exactly like their code: adapter.set_powered()
            bluetooth.adapter.set_powered(!powered)
            GLib.timeout_add(GLib.PRIORITY_DEFAULT, 200, () => { rebuild(); return GLib.SOURCE_REMOVE })
        })

        toggleRow.append(tagLbl)
        toggleRow.append(toggleBtn)
        compactBody.append(toggleRow)

        if (powered) {
            compactBody.append(buildConnectedCard(rebuild))
        } else {
            const box = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 6 })
            box.get_style_context().add_class("connected-card")
            box.get_style_context().add_class("disconnected")
            box.set_halign(Gtk.Align.CENTER)

            const icon = new Gtk.Label({ label: ICON_BT_OFF, halign: Gtk.Align.CENTER })
            icon.get_style_context().add_class("disconn-icon")
            const lbl = new Gtk.Label({ label: "Bluetooth is off" })
            lbl.get_style_context().add_class("disconn-label")
            const sub = new Gtk.Label({ label: "Turn on to connect devices" })
            sub.get_style_context().add_class("disconn-sub")

            box.append(icon)
            box.append(lbl)
            box.append(sub)
            compactBody.append(box)
        }
    }

    function rebuildDevices() {
        log("rebuildDevices", "Rebuilding devices list")

        let c = expandedBody.get_first_child()
        while (c) { const n = c.get_next_sibling(); expandedBody.remove(c); c = n }

        const sep = new Gtk.Separator({ orientation: Gtk.Orientation.HORIZONTAL })
        sep.get_style_context().add_class("bt-sep")
        expandedBody.append(sep)

        const wrap = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL })
        wrap.get_style_context().add_class("bt-networks-wrap")
        wrap.set_vexpand(true)
        wrap.append(buildDevicesList(rebuild))
        expandedBody.append(wrap)
    }

    function rebuild() {
        log("rebuild", "Full rebuild")
        rebuildCompact()
        if (expanded) rebuildDevices()
    }

    function setExpanded(val: boolean) {
        log("setExpanded", `${expanded} → ${val}`)
        expanded = val
        scrolled.set_visible(val)
        advBtn.get_style_context()[val ? "add_class" : "remove_class"]("active")
        advBtnLbl.set_label(val ? "DEVICES \u2191" : "DEVICES \u2193")
        if (val) rebuildDevices()
    }

    advBtn.connect("clicked", () => setExpanded(!expanded))

    // ── Signals — using isPowered and devices like their code ─────────────────
    bluetooth.connect("notify::is-powered", () => {
        log("signal", `notify::is-powered → ${bluetooth.isPowered}`)
        rebuild()
    })

    bluetooth.connect("notify::devices", () => {
        log("signal", `notify::devices → ${bluetooth.devices?.length} devices`)
        rebuild()
    })

    // Also watch adapter discovering state
    try {
        bluetooth.adapter?.connect("notify::discovering", () => {
            log("signal", `notify::discovering → ${bluetooth.adapter?.discovering}`)
            if (expanded) rebuildDevices()
        })
    } catch (e) {
        logError("init", "Could not connect adapter signal", e)
    }

    rebuild()
    setExpanded(false)

    const advRow = new Gtk.Box()
    advRow.get_style_context().add_class("bt-adv-row")
    advRow.append(advBtn)

    const card = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL })
    card.get_style_context().add_class("bt-card")
    card.set_size_request(360, -1)
    card.set_vexpand(true)
    card.append(compactBody)
    card.append(advRow)
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
            if (outside) {
                log("backdrop", "Click outside — closing")
                app.toggle_window("Bluetooth")
            }
        })
        self.add_controller(click)
    }

    return (
        <window
            name="Bluetooth"
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
