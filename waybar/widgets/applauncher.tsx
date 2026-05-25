import app from "ags/gtk4/app"
import Gtk from "gi://Gtk?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import GLib from "gi://GLib"
import Gio from "gi://Gio"
import Astal from "gi://Astal"

// ── API types ─────────────────────────────────────────────────────────────────

interface AppEntry {
    id: string
    name: string
    generic_name: string
    exec: string
    icon: string
    categories: string[]
}

interface AppResult   { entry: AppEntry; score: number }
interface CalcResult  { expression: string; value: number; formatted: string }
interface ShellResult { command: string; output: string; exit_code: number }
interface WinResult   { address: string; class: string; title: string; workspace_id: number }

type QueryResponse =
    | { type: "apps";    apps: AppResult[] }
    | { type: "calc";    calc: CalcResult }
    | { type: "shell";   shell: ShellResult }
    | { type: "windows"; windows: { windows: WinResult[]; match: string } }

// ── RPC via direct Gio.Socket (synchronous, deferred to idle) ─────────────────

function rpc(method: string, params: any, cb: (res: any) => void) {
    GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
        try {
            const sockPath = `${GLib.get_user_runtime_dir()}/app-launcher/socket`

            const sock = new Gio.Socket({
                family:   Gio.SocketFamily.UNIX,
                type:     Gio.SocketType.STREAM,
                protocol: Gio.SocketProtocol.DEFAULT,
            })
            sock.set_timeout(3)
            sock.connect(new Gio.UnixSocketAddress({ path: sockPath }), null)

            // Write request then close the write half so the server knows we're done
            const os = new Gio.UnixOutputStream({ fd: sock.get_fd(), close_fd: false })
            os.write_all(new TextEncoder().encode(JSON.stringify({ id: "1", method, params })), null)
            os.flush(null)
            sock.shutdown(false, true, null)

            // Read one response line
            const dis = new Gio.DataInputStream({
                base_stream: new Gio.UnixInputStream({ fd: sock.get_fd(), close_fd: false }),
            })
            const [line] = dis.read_line_utf8(null)
            sock.close(null)

            cb(line ? JSON.parse(line) : null)
        } catch (_e) {
            cb(null)
        }
        return GLib.SOURCE_REMOVE
    })
}

// ── Icon helper ───────────────────────────────────────────────────────────────

function sysIcon(name: string, size: number): Gtk.Image {
    const img = new Gtk.Image({ icon_name: name || "application-x-executable", pixel_size: size })
    return img
}

// ── Widget ────────────────────────────────────────────────────────────────────

export function AppLauncher(monitor = 0) {
    let query    = ""
    let seq      = 0
    let focusedIdx = 0
    const pinnedMap = new Map<string, AppEntry>()
    let resultApps: AppResult[] = []
    let resultWins: WinResult[] = []
    let resultCalc: CalcResult | null = null
    let btns: Gtk.Button[] = []
    let mode: "idle" | "apps" | "calc" | "shell" | "windows" = "idle"

    function clearBox(box: Gtk.Box) {
        let c = box.get_first_child()
        while (c) { const n = c.get_next_sibling(); box.remove(c); c = n }
    }

    function close() { app.toggle_window("AppLauncher") }

    function doLaunch(entry: AppEntry) {
        rpc("launch", { entry_id: entry.id, exec: entry.exec }, () => {})
        close()
    }

    function doFocus(address: string) {
        rpc("focus_window", { address }, () => {})
        close()
    }

    // ── Search bar ────────────────────────────────────────────────────────────

    const searchEntry = new Gtk.Entry()
    searchEntry.set_placeholder_text("Search, =calc, >shell, /window...")
    searchEntry.get_style_context().add_class("launcher-entry")
    searchEntry.set_hexpand(true)

    const searchWrap = new Gtk.Box({ spacing: 12 })
    searchWrap.get_style_context().add_class("launcher-search-wrap")
    searchWrap.append(sysIcon("system-search-symbolic", 16))
    searchWrap.append(searchEntry)

    // ── Pinned icon row ───────────────────────────────────────────────────────

    const pinnedLabel = new Gtk.Label({ xalign: 0, label: "PINNED" })
    pinnedLabel.get_style_context().add_class("launcher-section-lbl")
    pinnedLabel.get_style_context().add_class("accent")

    const pinnedIcons = new Gtk.Box({ spacing: 6 })
    pinnedIcons.get_style_context().add_class("launcher-icon-row")

    const pinnedBlock = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 10 })
    pinnedBlock.append(pinnedLabel)
    pinnedBlock.append(pinnedIcons)
    pinnedBlock.append(new Gtk.Separator({ orientation: Gtk.Orientation.HORIZONTAL }))
    pinnedBlock.set_visible(false)

    // ── Idle: most-used icon row ───────────────────────────────────────────────

    const mostUsedLabel = new Gtk.Label({ xalign: 0, label: "MOST USED" })
    mostUsedLabel.get_style_context().add_class("launcher-section-lbl")

    const mostUsedIcons = new Gtk.Box({ spacing: 6 })
    mostUsedIcons.get_style_context().add_class("launcher-icon-row")

    const idleBlock = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 10 })
    idleBlock.append(mostUsedLabel)
    idleBlock.append(mostUsedIcons)

    // ── Results container ─────────────────────────────────────────────────────

    const resultsBox = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 8 })
    resultsBox.get_style_context().add_class("launcher-inner")

    const scroll = new Gtk.ScrolledWindow({
        hscrollbar_policy: Gtk.PolicyType.NEVER,
        vscrollbar_policy: Gtk.PolicyType.AUTOMATIC,
    })
    scroll.get_style_context().add_class("launcher-scroll")
    scroll.set_child(resultsBox)
    scroll.set_size_request(-1, 340)
    scroll.set_visible(false)

    // ── Body / card ───────────────────────────────────────────────────────────

    const body = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 14 })
    body.get_style_context().add_class("launcher-body")
    body.append(pinnedBlock)
    body.append(idleBlock)
    body.append(scroll)

    const card = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL })
    card.get_style_context().add_class("launcher-card")
    card.set_size_request(500, -1)
    card.append(searchWrap)
    card.append(body)

    // ── Quick icon button ─────────────────────────────────────────────────────

    function makeIconBtn(entry: AppEntry): Gtk.Button {
        const btn = new Gtk.Button()
        btn.get_style_context().add_class("launcher-quick-btn")
        btn.set_child(sysIcon(entry.icon, 26))
        btn.set_tooltip_text(entry.name)
        btn.connect("clicked", () => doLaunch(entry))
        return btn
    }

    // ── App result row ────────────────────────────────────────────────────────

    function makeAppBtn(ar: AppResult): Gtk.Button {
        const e = ar.entry

        const img = sysIcon(e.icon, 20)
        img.get_style_context().add_class("launcher-app-icon")

        const name = new Gtk.Label({ xalign: 0, hexpand: true, label: e.name })
        name.get_style_context().add_class("launcher-app-name")

        const badge = e.generic_name || e.categories?.[0] || "App"
        const type = new Gtk.Label({ label: badge })
        type.get_style_context().add_class("launcher-app-type")

        const row = new Gtk.Box({ spacing: 12 })
        row.append(img)
        row.append(name)
        row.append(type)

        if (pinnedMap.has(e.id)) {
            const pin = new Gtk.Label({ label: "" })
            pin.get_style_context().add_class("launcher-pin-icon")
            row.append(pin)
        }

        const btn = new Gtk.Button()
        btn.get_style_context().add_class("launcher-btn")
        btn.set_child(row)
        btn.connect("clicked", () => doLaunch(e))
        return btn
    }

    // ── Window result row ─────────────────────────────────────────────────────

    function makeWinBtn(w: WinResult): Gtk.Button {
        const img = sysIcon(w.class, 20)
        img.get_style_context().add_class("launcher-app-icon")

        const title = new Gtk.Label({ xalign: 0, hexpand: true, label: w.title })
        title.set_ellipsize(3)
        title.get_style_context().add_class("launcher-app-name")

        const ws = new Gtk.Label({ label: `ws ${w.workspace_id}` })
        ws.get_style_context().add_class("launcher-app-type")

        const row = new Gtk.Box({ spacing: 12 })
        row.append(img)
        row.append(title)
        row.append(ws)

        const btn = new Gtk.Button()
        btn.get_style_context().add_class("launcher-btn")
        btn.set_child(row)
        btn.connect("clicked", () => doFocus(w.address))
        return btn
    }

    // ── Calc card ─────────────────────────────────────────────────────────────

    function makeCalcCard(c: CalcResult): Gtk.Box {
        const expr = new Gtk.Label({ xalign: 0, label: `= ${c.expression}` })
        expr.get_style_context().add_class("launcher-calc-expr")

        const val = new Gtk.Label({ xalign: 0, label: c.formatted })
        val.get_style_context().add_class("launcher-calc-val")

        const hint = new Gtk.Label({ xalign: 0, label: "Enter to copy" })
        hint.get_style_context().add_class("launcher-calc-hint")

        const card = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 4 })
        card.get_style_context().add_class("launcher-calc-card")
        card.append(expr)
        card.append(val)
        card.append(hint)
        return card
    }

    // ── Shell card ────────────────────────────────────────────────────────────

    function makeShellCard(s: ShellResult): Gtk.Box {
        const cmd = new Gtk.Label({ xalign: 0, label: `> ${s.command}` })
        cmd.get_style_context().add_class("launcher-shell-cmd")

        const out = new Gtk.Label({ xalign: 0, label: s.output || "(no output)", wrap: true })
        out.get_style_context().add_class("launcher-shell-output")
        if (s.exit_code !== 0) out.get_style_context().add_class("error")

        const exit = new Gtk.Label({ xalign: 0, label: `exit ${s.exit_code}` })
        exit.get_style_context().add_class("launcher-app-type")
        if (s.exit_code !== 0) exit.get_style_context().add_class("error")

        const card = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 6 })
        card.get_style_context().add_class("launcher-shell-card")
        card.append(cmd)
        card.append(out)
        card.append(exit)
        return card
    }

    // ── Render ────────────────────────────────────────────────────────────────

    function renderPinned() {
        clearBox(pinnedIcons)
        pinnedBlock.set_visible(pinnedMap.size > 0)
        for (const e of pinnedMap.values()) pinnedIcons.append(makeIconBtn(e))
    }

    function loadMostUsed() {
        rpc("query", { query: "", limit: 8 }, (res) => {
            if (!res?.result) return
            const data = res.result as QueryResponse
            if (data.type !== "apps") return
            clearBox(mostUsedIcons)
            for (const ar of data.apps.slice(0, 8)) {
                mostUsedIcons.append(makeIconBtn(ar.entry))
            }
        })
    }

    function renderResults(data: QueryResponse) {
        clearBox(resultsBox)
        btns = []
        focusedIdx = 0

        if (data.type === "apps") {
            mode = "apps"
            resultApps = data.apps

            const lbl = new Gtk.Label({ xalign: 0, label: "RESULTS" })
            lbl.get_style_context().add_class("launcher-section-lbl")
            resultsBox.append(lbl)

            if (data.apps.length === 0) {
                const empty = new Gtk.Label({ label: "No results" })
                empty.get_style_context().add_class("launcher-empty")
                resultsBox.append(empty)
                return
            }

            const list = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 2 })
            resultsBox.append(list)

            for (let i = 0; i < data.apps.length; i++) {
                const btn = makeAppBtn(data.apps[i])
                if (i === 0) btn.get_style_context().add_class("focused")
                list.append(btn)
                btns.push(btn)
            }
        }

        else if (data.type === "calc") {
            mode = "calc"
            resultCalc = data.calc
            resultsBox.append(makeCalcCard(data.calc))
        }

        else if (data.type === "shell") {
            mode = "shell"
            resultsBox.append(makeShellCard(data.shell))
        }

        else if (data.type === "windows") {
            mode = "windows"
            resultWins = data.windows.windows

            const lbl = new Gtk.Label({ xalign: 0, label: "WINDOWS" })
            lbl.get_style_context().add_class("launcher-section-lbl")
            resultsBox.append(lbl)

            const list = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 2 })
            resultsBox.append(list)

            for (let i = 0; i < resultWins.length; i++) {
                const btn = makeWinBtn(resultWins[i])
                if (i === 0) btn.get_style_context().add_class("focused")
                list.append(btn)
                btns.push(btn)
            }
        }
    }

    function doQuery(q: string) {
        const s = ++seq
        rpc("query", { query: q, limit: 20 }, (res) => {
            if (s !== seq || !res?.result) return
            renderResults(res.result as QueryResponse)
        })
    }

    // ── Keyboard nav ──────────────────────────────────────────────────────────

    function moveFocus(delta: number) {
        if (!btns.length) return
        btns[focusedIdx]?.get_style_context().remove_class("focused")
        focusedIdx = (focusedIdx + delta + btns.length) % btns.length
        btns[focusedIdx]?.get_style_context().add_class("focused")
    }

    function activateFocused() {
        if (mode === "calc" && resultCalc) {
            try {
                Gio.Subprocess.new(["wl-copy", resultCalc.formatted], Gio.SubprocessFlags.NONE)
            } catch {}
            close()
        } else if (mode === "apps" && focusedIdx < resultApps.length) {
            doLaunch(resultApps[focusedIdx].entry)
        } else if (mode === "windows" && focusedIdx < resultWins.length) {
            doFocus(resultWins[focusedIdx].address)
        }
    }

    function togglePin() {
        if (mode !== "apps" || !resultApps[focusedIdx]) return
        const e = resultApps[focusedIdx].entry
        const saved = focusedIdx
        if (pinnedMap.has(e.id)) pinnedMap.delete(e.id)
        else pinnedMap.set(e.id, e)
        renderPinned()
        renderResults({ type: "apps", apps: resultApps })
        btns[saved]?.get_style_context().add_class("focused")
        focusedIdx = saved
    }

    function setSearchMode(on: boolean) {
        idleBlock.set_visible(!on)
        scroll.set_visible(on)
    }

    function reset() {
        query = ""
        focusedIdx = 0
        seq++
        mode = "idle"
        searchEntry.set_text("")
        setSearchMode(false)
        renderPinned()
        loadMostUsed()
        GLib.timeout_add(GLib.PRIORITY_DEFAULT, 50, () => {
            searchEntry.grab_focus()
            return GLib.SOURCE_REMOVE
        })
    }

    searchEntry.connect("changed", () => {
        query = searchEntry.get_text()
        const searching = query.length > 0
        setSearchMode(searching)
        if (searching) doQuery(query)
    })

    // ── Window ────────────────────────────────────────────────────────────────

    return (
        <window
            name="AppLauncher"
            monitor={monitor}
            $={(self) => {
                app.add_window(self)

                const click = new Gtk.GestureClick()
                click.connect("pressed", (_g, _n, x, y) => {
                    const child = self.get_child()
                    if (!child) return
                    const alloc = child.get_allocation()
                    const outside =
                        x < alloc.x || x > alloc.x + alloc.width ||
                        y < alloc.y || y > alloc.y + alloc.height
                    if (outside) close()
                })
                self.add_controller(click)

                const key = new Gtk.EventControllerKey()
                key.set_propagation_phase(Gtk.PropagationPhase.CAPTURE)
                key.connect("key-pressed", (_c, keyval, _code, state) => {
                    const ctrl = (state & 4) !== 0
                    if (keyval === Gdk.KEY_Escape)                              { close();            return true }
                    if (keyval === Gdk.KEY_Down)                                { moveFocus(1);       return true }
                    if (keyval === Gdk.KEY_Up)                                  { moveFocus(-1);      return true }
                    if (keyval === Gdk.KEY_Return || keyval === Gdk.KEY_KP_Enter) { activateFocused(); return true }
                    if (ctrl && keyval === Gdk.KEY_p)                           { togglePin();        return true }
                    return false
                })
                self.add_controller(key)

                self.connect("notify::visible", () => {
                    if (self.get_visible()) reset()
                })
            }}
            anchor={
                Astal.WindowAnchor.TOP  | Astal.WindowAnchor.LEFT |
                Astal.WindowAnchor.RIGHT | Astal.WindowAnchor.BOTTOM
            }
            exclusivity={Astal.Exclusivity.IGNORE}
            keymode={Astal.Keymode.EXCLUSIVE}
            css={`all: unset; background: transparent;`}
        >
            <box halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
                {card}
            </box>
        </window>
    )
}
