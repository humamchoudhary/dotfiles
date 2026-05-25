import app from "ags/gtk4/app"
import Gtk from "gi://Gtk?version=4.0"
import GLib from "gi://GLib"
import Astal from "gi://Astal"
import AstalNetwork from "gi://AstalNetwork"
import NM from "gi://NM"

// ── Icons ─────────────────────────────────────────────────────────────────────

const ICON_WIFI_FULL = "\udb82\udd28"
const ICON_WIFI_3    = "\udb82\udd25"
const ICON_WIFI_2    = "\udb82\udd22"
const ICON_WIFI_1    = "\udb82\udd1f"
const ICON_WIFI_NONE = "\udb82\udd2f"
const ICON_WIFI_OFF  = "\udb82\udd2d"
const ICON_LOCK      = "\udb80\udf06"
const ICON_REFRESH   = "\uf021"

// ── Helpers ───────────────────────────────────────────────────────────────────

function strengthToLabel(s: number): string {
    if (s >= 80) return "Excellent"
    if (s >= 60) return "Good"
    if (s >= 40) return "Fair"
    if (s >= 20) return "Weak"
    return "Poor"
}

function strengthToIcon(s: number): string {
    if (s >= 80) return ICON_WIFI_FULL
    if (s >= 60) return ICON_WIFI_3
    if (s >= 40) return ICON_WIFI_2
    if (s >= 20) return ICON_WIFI_1
    return ICON_WIFI_NONE
}

function wifiStrengthIcon(s: number): string {
    if (s >= 80) return "\udb82\udd28"
    if (s >= 60) return "\udb82\udd25"
    if (s >= 40) return "\udb82\udd22"
    if (s >= 20) return "\udb82\udd1f"
    return "\udb82\udd27"
}

function freqToGhz(freq: number): string {
    return freq >= 4900 ? "5 GHz" : "2.4 GHz"
}

function flagsToSecurity(flags: number, wpa: number, rsn: number): string {
    if (rsn !== 0)   return "WPA2"
    if (wpa !== 0)   return "WPA"
    if (flags & 0x1) return "WEP"
    return "Open"
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

// ── Password row ──────────────────────────────────────────────────────────────

function PasswordRow(opts: {
    ssid: string
    onConnect: (pw: string) => void
    onCancel: () => void
}): Gtk.Widget {
    const box = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 10 })
    box.get_style_context().add_class("password-row")

    const lbl = new Gtk.Label({ xalign: 0 })
    lbl.set_label(`Password for "${opts.ssid}"`)
    lbl.get_style_context().add_class("pw-label")

    const entry = new Gtk.Entry()
    entry.set_visibility(false)
    entry.set_placeholder_text("Enter password…")
    entry.get_style_context().add_class("pw-entry")

    const show = new Gtk.CheckButton({ label: "Show password" })
    show.get_style_context().add_class("pw-check")
    show.connect("toggled", () => entry.set_visibility(show.get_active()))

    const btnRow = new Gtk.Box({ spacing: 8, homogeneous: true })

    const cancel = new Gtk.Button()
    cancel.get_style_context().add_class("net-action-btn")
    cancel.set_child(new Gtk.Label({ label: "Cancel" }))

    const connect = new Gtk.Button()
    connect.get_style_context().add_class("net-action-btn")
    connect.get_style_context().add_class("accent")
    connect.set_child(new Gtk.Label({ label: "Connect" }))

    cancel.connect("clicked", opts.onCancel)
    connect.connect("clicked", () => opts.onConnect(entry.get_text()))
    entry.connect("activate",  () => opts.onConnect(entry.get_text()))

    btnRow.append(cancel)
    btnRow.append(connect)
    box.append(lbl)
    box.append(entry)
    box.append(show)
    box.append(btnRow)
    return box
}

// ── Network row ───────────────────────────────────────────────────────────────

function NetworkRow(opts: {
    ap: AstalNetwork.AccessPoint
    isActive: boolean
    isSaved: boolean
    onSelect: () => void
}): Gtk.Widget {
    const { ap, isActive, isSaved, onSelect } = opts
    const ssid     = ap.ssid ?? "Hidden Network"
    const strength = ap.strength ?? 0
    const secured  = (ap.flags & 0x1) || ap.wpa_flags || ap.rsn_flags

    const btn = new Gtk.Button()
    btn.get_style_context().add_class("net-row-btn")
    if (isActive)     btn.get_style_context().add_class("active")
    else if (isSaved) btn.get_style_context().add_class("saved")

    // Left — name only
    const nameLbl = new Gtk.Label({ xalign: 0, hexpand: true, label: ssid })
    nameLbl.set_ellipsize(3)
    nameLbl.get_style_context().add_class("net-row-name")

    // Right — lock + strength icon
    const rightBox = new Gtk.Box({ spacing: 6, valign: Gtk.Align.CENTER })

    if (secured) {
        const lock = new Gtk.Label({ label: ICON_LOCK })
        lock.get_style_context().add_class("net-lock")
        rightBox.append(lock)
    }

    const wifiIcon = new Gtk.Label({ label: wifiStrengthIcon(strength) })
    wifiIcon.get_style_context().add_class("net-row-wifi-icon")
    if (isActive) wifiIcon.get_style_context().add_class("active")
    rightBox.append(wifiIcon)

    const row = new Gtk.Box({ spacing: 8 })
    row.append(nameLbl)
    row.append(rightBox)
    btn.set_child(row)
    btn.connect("clicked", onSelect)
    return btn
}

// ── Connected card ────────────────────────────────────────────────────────────

function buildConnectedCard(
    wifi: AstalNetwork.Wifi,
    nmClient: NM.Client | null,
    rebuild: () => void
): Gtk.Widget {
    const ap       = wifi.active_access_point
    const strength = ap?.strength ?? 0
    const freq     = ap?.frequency ?? 0
    const flags    = ap?.flags    ?? 0
    const wpa      = ap?.wpa_flags ?? 0
    const rsn      = ap?.rsn_flags ?? 0
    const ssid     = ap?.ssid     ?? "Unknown"

    let ipAddr = ""
    let gw     = ""
    let dns    = ""
    let mac    = ""

    try {
        const nmDev = wifi.device as unknown as NM.DeviceWifi
        const ip4   = nmDev?.ip4_config
        if (ip4) {
            const addrs = ip4.get_addresses()
            if (addrs?.length > 0) ipAddr = addrs[0].get_address() ?? ""
            gw = ip4.get_gateway() ?? ""
            const ns = ip4.get_nameservers()
            if (ns?.length > 0) dns = ns[0]
        }
        mac = nmDev?.hw_address ?? ""
    } catch (e) {
        print(`IP info error: ${e}`)
    }

    const outer = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 12 })
    outer.get_style_context().add_class("connected-card")

    // SSID row
    const ssidRow = new Gtk.Box({ spacing: 10, valign: Gtk.Align.CENTER })

    const iconLbl = new Gtk.Label({
        label:  strengthToIcon(strength),
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
    const ssidLbl = new Gtk.Label({ xalign: 0, label: ssid })
    ssidLbl.get_style_context().add_class("conn-ssid")
    const badge = new Gtk.Label({ label: "CONNECTED" })
    badge.get_style_context().add_class("conn-badge")
    nameRow.append(ssidLbl)
    nameRow.append(badge)

    const metaLbl = new Gtk.Label({ xalign: 0 })
    metaLbl.set_label(`${flagsToSecurity(flags, wpa, rsn)} · ${freqToGhz(freq)} · ${strength}%`)
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

    col0.append(InfoCell("IP ADDRESS", ipAddr, true))
    col1.append(InfoCell("GATEWAY",    gw))
    col0.append(InfoCell("DNS",        dns))
    col1.append(InfoCell("MAC",        mac))

    grid.append(col0)
    grid.append(col1)
    outer.append(grid)

    // Action buttons
    const actionRow = new Gtk.Box({ spacing: 8 })

    const disconnBtn = new Gtk.Button()
    disconnBtn.get_style_context().add_class("net-action-btn")
    disconnBtn.get_style_context().add_class("danger")
    disconnBtn.set_hexpand(true)
    disconnBtn.set_child(new Gtk.Label({ label: "Disconnect" }))

    const forgetBtn = new Gtk.Button()
    forgetBtn.get_style_context().add_class("net-action-btn")
    forgetBtn.set_hexpand(true)
    forgetBtn.set_child(new Gtk.Label({ label: "Forget" }))

    disconnBtn.connect("clicked", () => {
        try {
            const nmDev = wifi.device as unknown as NM.DeviceWifi
            nmDev?.disconnect_async(null, null)
        } catch (e) { print(`Disconnect: ${e}`) }
        GLib.timeout_add(GLib.PRIORITY_DEFAULT, 400, () => { rebuild(); return GLib.SOURCE_REMOVE })
    })

    forgetBtn.connect("clicked", () => {
        try {
            const nmDev = wifi.device as unknown as NM.DeviceWifi
            const ac    = nmDev?.active_connection
            const conn  = ac?.get_connection()
            if (conn) conn.delete_async(null, null)
        } catch (e) { print(`Forget: ${e}`) }
        GLib.timeout_add(GLib.PRIORITY_DEFAULT, 400, () => { rebuild(); return GLib.SOURCE_REMOVE })
    })

    actionRow.append(disconnBtn)
    actionRow.append(forgetBtn)
    outer.append(actionRow)

    return outer
}

// ── Disconnected card ─────────────────────────────────────────────────────────

function buildDisconnectedCard(): Gtk.Widget {
    const box = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 6 })
    box.get_style_context().add_class("connected-card")
    box.get_style_context().add_class("disconnected")
    box.set_halign(Gtk.Align.CENTER)

    const icon = new Gtk.Label({ label: ICON_WIFI_OFF })
    icon.get_style_context().add_class("disconn-icon")
    icon.set_halign(Gtk.Align.CENTER)

    const lbl = new Gtk.Label({ label: "Not connected" })
    lbl.get_style_context().add_class("disconn-label")

    const sub = new Gtk.Label({ label: "Select a network below" })
    sub.get_style_context().add_class("disconn-sub")

    box.append(icon)
    box.append(lbl)
    box.append(sub)
    return box
}

// ── Networks list ─────────────────────────────────────────────────────────────

function buildNetworksList(
    wifi: AstalNetwork.Wifi,
    network: AstalNetwork.Network,
    nmClient: NM.Client | null,
    rebuild: () => void,
    rebuildNetworks: () => void
): Gtk.Widget {
    const outer = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 10 })
    outer.get_style_context().add_class("networks-section")

    // Header
    const headerRow = new Gtk.Box({ spacing: 8 })
    const headerLbl = new Gtk.Label({ xalign: 0, hexpand: true, label: "AVAILABLE NETWORKS" })
    headerLbl.get_style_context().add_class("section-label")

    const scanBtn = new Gtk.Button()
    scanBtn.get_style_context().add_class("scan-btn")
    const scanLbl = new Gtk.Label({ label: `${ICON_REFRESH}  SCAN` })
    scanLbl.get_style_context().add_class("scan-btn-lbl")
    scanBtn.set_child(scanLbl)
    scanBtn.connect("clicked", () => {
        try { wifi.scan() } catch (e) { print(`Scan: ${e}`) }
        GLib.timeout_add(GLib.PRIORITY_DEFAULT, 2000, () => { rebuildNetworks(); return GLib.SOURCE_REMOVE })
    })

    headerRow.append(headerLbl)
    headerRow.append(scanBtn)
    outer.append(headerRow)

    // Password container
    const pwBox = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL })
    pwBox.set_visible(false)
    outer.append(pwBox)

    function clearPw() {
        let c = pwBox.get_first_child()
        while (c) { const n = c.get_next_sibling(); pwBox.remove(c); c = n }
        pwBox.set_visible(false)
    }

    // Deduplicate APs by SSID, keep strongest
    const aps      = wifi.access_points ?? []
    const activeAp = wifi.active_access_point
    const seen     = new Map<string, AstalNetwork.AccessPoint>()
    for (const ap of aps) {
        const s = ap.ssid ?? ""
        if (!s) continue
        const ex = seen.get(s)
        if (!ex || (ap.strength ?? 0) > (ex.strength ?? 0)) seen.set(s, ap)
    }

    const sorted = [...seen.values()].sort((a, b) => {
        const aA = a.ssid === activeAp?.ssid ? 1 : 0
        const bA = b.ssid === activeAp?.ssid ? 1 : 0
        if (aA !== bA) return bA - aA
        return (b.strength ?? 0) - (a.strength ?? 0)
    })

    // Saved SSIDs — use the passed nmClient
    const savedSsids = new Set<string>()
    try {
        if (nmClient) {
            for (const conn of nmClient.get_connections()) {
                const ws = conn.get_setting_wireless()
                if (ws) {
                    const bytes = ws.get_ssid()
                    if (bytes) savedSsids.add(new TextDecoder().decode(bytes.toArray()))
                }
            }
        }
    } catch (_) {}

    const listBox = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 3 })

    for (const ap of sorted) {
        const ssid    = ap.ssid ?? "Hidden Network"
        const isActive = ssid === activeAp?.ssid
        const isSaved  = savedSsids.has(ssid)
        const secured  = (ap.flags & 0x1) || ap.wpa_flags || ap.rsn_flags

        listBox.append(NetworkRow({
            ap, isActive, isSaved,
            onSelect: () => {
                if (isActive) return
                clearPw()

const doConnect = (password?: string) => {
    try {
        if (!nmClient) { print("No NM client"); return }
        const nmDev = wifi.device as unknown as NM.DeviceWifi
        if (!nmDev) { print("No NM device"); return }

        // Use the AP's object path, NOT bssid
        // bssid is a MAC address string, not a D-Bus object path
        const apPath = (ap as any).path ?? null

        if (isSaved) {
            for (const conn of nmClient.get_connections()) {
                const ws = conn.get_setting_wireless()
                if (ws) {
                    const bytes = ws.get_ssid()
                    if (bytes) {
                        const decoded = new TextDecoder().decode(bytes.toArray())
                        if (decoded === ssid) {
                            nmClient.activate_connection_async(
                                conn, nmDev, apPath, null, null
                            )
                            break
                        }
                    }
                }
            }
        } else if (!secured) {
            nmClient.add_and_activate_connection_async(
                NM.SimpleConnection.new(),
                nmDev,
                apPath,
                null,
                null
            )
        } else if (password) {
            const conn = NM.SimpleConnection.new()
            const ws   = new NM.SettingWireless()
            ws.set_property("ssid", GLib.Bytes.new(new TextEncoder().encode(ssid)))
            const wsec = new NM.SettingWirelessSecurity()
            wsec.set_property("key-mgmt", "wpa-psk")
            wsec.set_property("psk", password)
            conn.add_setting(ws)
            conn.add_setting(wsec)
            nmClient.add_and_activate_connection_async(
                conn,
                nmDev,
                apPath,
                null,
                null
            )
        }
    } catch (e) { print(`Connect: ${e}`) }

    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 2000, () => {
        rebuild()
        return GLib.SOURCE_REMOVE
    })
}

                if (!secured || isSaved) {
                    doConnect()
                } else {
                    pwBox.set_visible(true)
                    pwBox.append(PasswordRow({
                        ssid,
                        onConnect: (pw) => { clearPw(); doConnect(pw) },
                        onCancel:  clearPw,
                    }))
                }
            },
        }))
    }

    if (sorted.length === 0) {
        const empty = new Gtk.Label({ label: "No networks found — press scan" })
        empty.get_style_context().add_class("empty-label")
        listBox.append(empty)
    }

    outer.append(listBox)
    return outer
}

// ── Main widget ───────────────────────────────────────────────────────────────

export function Wifi(monitor = 0, xOffset = 0) {
    const network = AstalNetwork.get_default()
    const wifi    = network.wifi

    // Single NM client created once at init
let nmClient: NM.Client | null = null
try {
    NM.Client.new_async(null, (_src, res) => {
        try {
            nmClient = NM.Client.new_finish(res)
        } catch (e) {
            print(`NM client async error: ${e}`)
        }
    })
} catch (e) {
    print(`NM client async start error: ${e}`)
}

    let expanded = false

    // Compact body
    const compactBody = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 10 })
    compactBody.get_style_context().add_class("wifi-compact-body")

    // Expanded (scrollable)
    const expandedBody = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL })
    expandedBody.get_style_context().add_class("wifi-expanded-body")

    const scrolled = new Gtk.ScrolledWindow({
        hscrollbar_policy: Gtk.PolicyType.NEVER,
        vscrollbar_policy: Gtk.PolicyType.AUTOMATIC,
    })
    scrolled.set_child(expandedBody)
    scrolled.set_size_request(-1, 360)
    scrolled.get_style_context().add_class("wifi-scroll")
    scrolled.set_visible(false)

    // Adv button
    const advBtnLbl = new Gtk.Label()
    advBtnLbl.get_style_context().add_class("wifi-adv-lbl")
    const advBtn = new Gtk.Button()
    advBtn.get_style_context().add_class("wifi-adv-btn")
    advBtn.set_child(advBtnLbl)
    advBtn.set_hexpand(true)

    function rebuildCompact() {
        let c = compactBody.get_first_child()
        while (c) { const n = c.get_next_sibling(); compactBody.remove(c); c = n }

        const tag = new Gtk.Label({ xalign: 0, label: "WIFI" })
        tag.get_style_context().add_class("wifi-tag")
        compactBody.append(tag)

        const connected = wifi?.internet === AstalNetwork.Internet.CONNECTED
        if (connected && wifi) {
            compactBody.append(buildConnectedCard(wifi, nmClient, rebuild))
        } else {
            compactBody.append(buildDisconnectedCard())
        }
    }

    function rebuildNetworks() {
        let c = expandedBody.get_first_child()
        while (c) { const n = c.get_next_sibling(); expandedBody.remove(c); c = n }
        if (!wifi) return

        const sep = new Gtk.Separator({ orientation: Gtk.Orientation.HORIZONTAL })
        sep.get_style_context().add_class("wifi-sep")
        expandedBody.append(sep)

        const wrap = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL })
        wrap.get_style_context().add_class("wifi-networks-wrap")
        wrap.append(buildNetworksList(wifi, network, nmClient, rebuild, rebuildNetworks))
        expandedBody.append(wrap)
    }

    function rebuild() {
        rebuildCompact()
        if (expanded) rebuildNetworks()
    }

    function setExpanded(val: boolean) {
        expanded = val
        scrolled.set_visible(val)
        advBtn.get_style_context()[val ? "add_class" : "remove_class"]("active")
        advBtnLbl.set_label(val ? "NETWORKS \u2191" : "NETWORKS \u2193")
        if (val) rebuildNetworks()
    }

    advBtn.connect("clicked", () => setExpanded(!expanded))

    if (wifi) {
        wifi.connect("notify::internet",            rebuild)
        wifi.connect("notify::active-access-point", rebuild)
        wifi.connect("notify::access-points",       () => { if (expanded) rebuildNetworks() })
    }
    network.connect("notify::primary", rebuild)

    rebuildCompact()
    setExpanded(false)

    const advRow = new Gtk.Box()
    advRow.get_style_context().add_class("wifi-adv-row")
    advRow.append(advBtn)

    const card = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL })
    card.get_style_context().add_class("wifi-card")
    card.set_size_request(360, -1)
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
            if (outside) app.toggle_window("Wifi")
        })
        self.add_controller(click)
    }

    return (
        <window
            name="Wifi"
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
