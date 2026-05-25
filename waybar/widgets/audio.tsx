import app from "ags/gtk4/app"
import Gtk from "gi://Gtk?version=4.0"
import GLib from "gi://GLib"
import Astal from "gi://Astal"
import AstalWp from "gi://AstalWp"


// Speaker icons
const ICON_VOL_HIGH   = "\uf028"  // 󰕾 nf-md-volume_high
const ICON_VOL_OFF    = "\ueee8"  // 󰝟 nf-md-volume_off
const ICON_VOL_MED    = "\uf027"  // 󰕽 nf-md-volume_medium  
const ICON_MIC        = "\uf130"  // 󰍬 nf-md-microphone
const ICON_MIC_OFF    = "\uf131"  // 󰍭 nf-md-microphone_off
const ICON_HEADPHONES = "\uf025"  // 󰋋 nf-md-headphones
const ICON_SPEAKER    = "\uf026"  // 󰕃 nf-md-speaker  (wait, double check)

// App icons
const ICON_FIREFOX    = "\uf269"  // 󰈹 nf-md-firefox
const ICON_CHROME     = "\uf268"  // 󰊯 nf-md-google_chrome
const ICON_SPOTIFY    = "\uf1bc"  // 󰓇 nf-md-spotify
const ICON_DISCORD    = "\uf1ff"  // 󰙯 nf-md-discord
const ICON_SLACK      = "\uf198"  // 󰒱 nf-md-slack
const ICON_MPV        = "\uf03d"  // 󰎁 nf-md-music_box
const ICON_VLC        = "\udb81\udd7c"  // 󰕼 nf-md-vlc
const ICON_STEAM      = "\uf1b6"  // 󰓓 nf-md-steam
const ICON_TELEGRAM   = "\uf2c6"  // 󰔁 nf-md-telegram
const ICON_VSCODE     = "\ue8da"  // 󰨞 nf-md-visual_studio_code
const ICON_MUSIC      = "\uf001"  // 󰝚 nf-md-music_note
const ICON_MONITOR    = "\udb80\udf79"  // 󰍹 nf-md-monitor

// ── Helpers ───────────────────────────────────────────────────────────────────

function appIcon(name: string): string {
    const n = (name ?? "").toLowerCase()
    if (n.includes("firefox"))                      return ICON_FIREFOX
    if (n.includes("chrome"))                       return ICON_CHROME
    if (n.includes("chromium"))                     return ICON_CHROME
    if (n.includes("spotify"))                      return ICON_SPOTIFY
    if (n.includes("discord"))                      return ICON_DISCORD
    if (n.includes("slack"))                        return ICON_SLACK
    if (n.includes("mpv"))                          return ICON_MPV
    if (n.includes("vlc"))                          return ICON_VLC
    if (n.includes("steam"))                        return ICON_STEAM
    if (n.includes("telegram"))                     return ICON_TELEGRAM
    if (n.includes("code") || n.includes("vscode")) return ICON_VSCODE
    return ICON_MUSIC
}

function deviceIcon(description: string): string {
    const d = (description ?? "").toLowerCase()
    if (
        d.includes("headphone") || d.includes("headset") ||
        d.includes("wh-")       || d.includes("wf-")    ||
        d.includes("airpod")    || d.includes("buds")   ||
        d.includes("bluetooth") || d.includes("bt ")
    ) return ICON_HEADPHONES
    if (d.includes("hdmi") || d.includes("display") || d.includes("monitor")) return ICON_MONITOR
    if (d.includes("usb")) return ICON_VOL_HIGH
    return ICON_SPEAKER
}

function micIcon(description: string): string {
    const d = (description ?? "").toLowerCase()
    if (
        d.includes("headphone") || d.includes("headset") ||
        d.includes("airpod")    || d.includes("buds")    ||
        d.includes("bluetooth") || d.includes("bt ")
    ) return ICON_HEADPHONES
    return ICON_MIC
}

function pct(v: number) { return `${Math.round(v * 100)}%` }

function clamp(v: number, min = 0, max = 1.5) {
    return Math.max(min, Math.min(max, v))
}

// ── Slider row ────────────────────────────────────────────────────────────────

function SliderRow(opts: {
    icon: string
    label: string
    getVol: () => number
    getMute: () => boolean
    setVol: (v: number) => void
    setMute: (m: boolean) => void
    accent?: boolean
    small?: boolean
}) {
    const { icon, label, getVol, getMute, setVol, setMute, accent, small } = opts

    const muteBtn = new Gtk.Button()
    muteBtn.get_style_context().add_class("audio-mute-btn")

    const muteIcon = new Gtk.Label()
    muteIcon.get_style_context().add_class("audio-mute-icon")
    muteBtn.set_child(muteIcon)

    const pctLbl = new Gtk.Label()
    pctLbl.get_style_context().add_class("audio-pct")
    pctLbl.set_xalign(1)

    const slider = new Gtk.Scale({
        orientation: Gtk.Orientation.HORIZONTAL,
        draw_value:  false,
        hexpand:     true,
    })
    slider.set_range(0, 1.5)
    slider.set_increments(0.01, 0.1)
    slider.add_mark(1.0, Gtk.PositionType.BOTTOM, null)
    slider.get_style_context().add_class("audio-slider")
    if (accent) slider.get_style_context().add_class("accent")
    if (small)  slider.get_style_context().add_class("small")

    const nameLbl = new Gtk.Label({ xalign: 0, hexpand: true })
    nameLbl.set_label(label)
    nameLbl.set_ellipsize(3)
    nameLbl.get_style_context().add_class("audio-stream-name")

    const iconLbl = new Gtk.Label({ label: icon })
    iconLbl.get_style_context().add_class("audio-app-icon")

    function refresh() {
        const muted = getMute()
        const vol   = getVol()
        muteIcon.set_label(muted ? ICON_VOL_OFF : ICON_VOL_HIGH)
        muteBtn.get_style_context()[muted ? "add_class" : "remove_class"]("muted")
        slider.set_value(vol)
        slider.get_style_context()[muted ? "add_class" : "remove_class"]("muted")
        pctLbl.set_label(pct(vol))
    }

    muteBtn.connect("clicked", () => {
        const newMuted = !getMute()
        setMute(newMuted)
        muteIcon.set_label(newMuted ? ICON_VOL_OFF : ICON_VOL_HIGH)
        muteBtn.get_style_context()[newMuted ? "add_class" : "remove_class"]("muted")
        slider.get_style_context()[newMuted ? "add_class" : "remove_class"]("muted")
    })

    slider.connect("value-changed", () => {
        setVol(clamp(slider.get_value()))
        pctLbl.set_label(pct(slider.get_value()))
    })

    refresh()

    const topRow = new Gtk.Box({ spacing: 6 })
    topRow.append(iconLbl)
    topRow.append(nameLbl)
    topRow.append(pctLbl)

    const ctrlRow = new Gtk.Box({ spacing: 6 })
    ctrlRow.append(muteBtn)
    ctrlRow.append(slider)

    const col = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 4 })
    col.get_style_context().add_class("audio-row")
    col.append(topRow)
    col.append(ctrlRow)

    return col
}

// ── Device button ─────────────────────────────────────────────────────────────

function DeviceBtn(opts: {
    label: string
    icon: string
    isDefault: boolean
    onSelect: () => void
}) {
    const btn = new Gtk.Button()
    btn.get_style_context().add_class("audio-device-btn")
    if (opts.isDefault) btn.get_style_context().add_class("active")

    const dot = new Gtk.Label({ label: opts.isDefault ? "●" : "○" })
    dot.get_style_context().add_class("audio-device-dot")

    const iconLbl = new Gtk.Label({ label: opts.icon })
    iconLbl.get_style_context().add_class("audio-device-icon")
    if (opts.isDefault) iconLbl.get_style_context().add_class("active")

    const lbl = new Gtk.Label({ xalign: 0, hexpand: true })
    lbl.set_label(opts.label)
    lbl.set_ellipsize(3)
    lbl.get_style_context().add_class("audio-device-name")

    const row = new Gtk.Box({ spacing: 10 })
    row.append(dot)
    row.append(iconLbl)
    row.append(lbl)
    btn.set_child(row)
    btn.connect("clicked", opts.onSelect)
    return btn
}

// ── Section label / divider ───────────────────────────────────────────────────

function SectionLabel(text: string) {
    const lbl = new Gtk.Label({ xalign: 0, label: text })
    lbl.get_style_context().add_class("audio-section-lbl")
    return lbl
}

function Divider() {
    const sep = new Gtk.Separator({ orientation: Gtk.Orientation.HORIZONTAL })
    sep.get_style_context().add_class("audio-sep")
    return sep
}

// ── Tab builders ──────────────────────────────────────────────────────────────

function buildOutput(audio: AstalWp.Audio): Gtk.Widget {
    const box = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 10 })
    box.get_style_context().add_class("tab-body")

    const sink = audio.default_speaker
    if (sink) {
        const desc = sink.description ?? sink.name ?? "Speaker"
        box.append(SectionLabel("Master Output"))
        box.append(SliderRow({
            icon:    deviceIcon(desc),
            label:   desc,
            getVol:  () => audio.default_speaker?.volume ?? 0,
            getMute: () => audio.default_speaker?.mute ?? false,
            setVol:  (v) => { const s = audio.default_speaker; if (s) s.volume = v },
            setMute: (m) => { const s = audio.default_speaker; if (s) s.mute = m },
            accent:  true,
        }))
    }
    return box
}

function buildInput(audio: AstalWp.Audio): Gtk.Widget {
    const box = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 10 })
    box.get_style_context().add_class("tab-body")

    const src = audio.default_microphone
    if (src) {
        const desc = src.description ?? src.name ?? "Microphone"
        box.append(SectionLabel("Microphone"))
        box.append(SliderRow({
            icon:    micIcon(desc),
            label:   desc,
            getVol:  () => audio.default_microphone?.volume ?? 0,
            getMute: () => audio.default_microphone?.mute ?? false,
            setVol:  (v) => { const s = audio.default_microphone; if (s) s.volume = v },
            setMute: (m) => { const s = audio.default_microphone; if (s) s.mute = m },
        }))
    }
    return box
}

function buildDevices(audio: AstalWp.Audio, fullRebuild: () => void): Gtk.Widget {
    const box = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 8 })
    box.get_style_context().add_class("tab-body")

    const sinks   = audio.speakers    ?? []
    const sources = audio.microphones ?? []

    if (sinks.length > 0) {
        box.append(SectionLabel("Output Devices"))
        for (const s of sinks) {
            const desc = s.description ?? s.name ?? "Unknown"
            box.append(DeviceBtn({
                label:     desc,
                icon:      deviceIcon(desc),
                isDefault: s.id === audio.default_speaker?.id,
                onSelect:  () => {
                    s.set_is_default(true)
                    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 50, () => {
                        fullRebuild()
                        return GLib.SOURCE_REMOVE
                    })
                },
            }))
        }
    }

    if (sources.length > 0) {
        if (sinks.length > 0) box.append(Divider())
        box.append(SectionLabel("Input Devices"))
        for (const s of sources) {
            const desc = s.description ?? s.name ?? "Unknown"
            box.append(DeviceBtn({
                label:     desc,
                icon:      micIcon(desc),
                isDefault: s.id === audio.default_microphone?.id,
                onSelect:  () => {
                    s.set_is_default(true)
                    GLib.timeout_add(GLib.PRIORITY_DEFAULT, 50, () => {
                        fullRebuild()
                        return GLib.SOURCE_REMOVE
                    })
                },
            }))
        }
    }

    return box
}

function buildApps(audio: AstalWp.Audio): Gtk.Widget {
    const box = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 10 })
    box.get_style_context().add_class("tab-body")

    const streams = audio.streams ?? []

    if (streams.length === 0) {
        const empty = new Gtk.Label({ label: "No applications playing audio" })
        empty.get_style_context().add_class("audio-empty")
        box.append(empty)
        return box
    }

    box.append(SectionLabel("Applications"))
    for (const s of streams) {
        const name = s.description ?? s.name ?? "Unknown"
        box.append(SliderRow({
            icon:    appIcon(name),
            label:   name,
            getVol:  () => s.volume,
            getMute: () => s.mute,
            setVol:  (v) => { s.volume = v },
            setMute: (m) => { s.mute = m },
            small:   true,
        }))
    }
    return box
}

// ── Main widget ───────────────────────────────────────────────────────────────

export function Audio(monitor = 0, xOffset = 0) {
    const wp    = AstalWp.get_default()!
    const audio = wp.audio

    let expanded  = false
    let activeTab = 0

    let speakerVolumeHandler = 0
    let speakerMuteHandler   = 0
    let micVolumeHandler     = 0
    let micMuteHandler       = 0

    // ── compact speaker widgets ───────────────────────────────────────────────

    const compactMuteIcon = new Gtk.Label()
    compactMuteIcon.get_style_context().add_class("audio-mute-icon")

    const compactMuteBtn = new Gtk.Button()
    compactMuteBtn.get_style_context().add_class("audio-mute-btn")
    compactMuteBtn.set_child(compactMuteIcon)

    const compactVolLbl = new Gtk.Label()
    compactVolLbl.get_style_context().add_class("audio-pct")

    const compactSlider = new Gtk.Scale({
        orientation: Gtk.Orientation.HORIZONTAL,
        draw_value:  false,
        hexpand:     true,
    })
    compactSlider.set_range(0, 1.5)
    compactSlider.set_increments(0.01, 0.1)
    compactSlider.add_mark(1.0, Gtk.PositionType.BOTTOM, null)
    compactSlider.get_style_context().add_class("audio-slider")
    compactSlider.get_style_context().add_class("accent")

    // ── compact mic widgets ───────────────────────────────────────────────────

    const compactMicMuteIcon = new Gtk.Label()
    compactMicMuteIcon.get_style_context().add_class("audio-mute-icon")

    const compactMicMuteBtn = new Gtk.Button()
    compactMicMuteBtn.get_style_context().add_class("audio-mute-btn")
    compactMicMuteBtn.set_child(compactMicMuteIcon)

    const compactMicVolLbl = new Gtk.Label()
    compactMicVolLbl.get_style_context().add_class("audio-pct")

    const compactMicSlider = new Gtk.Scale({
        orientation: Gtk.Orientation.HORIZONTAL,
        draw_value:  false,
        hexpand:     true,
    })
    compactMicSlider.set_range(0, 1.5)
    compactMicSlider.set_increments(0.01, 0.1)
    compactMicSlider.add_mark(1.0, Gtk.PositionType.BOTTOM, null)
    compactMicSlider.get_style_context().add_class("audio-slider")
    compactMicSlider.get_style_context().add_class("mic")

    // ── adv button ────────────────────────────────────────────────────────────

    const advBtnLbl = new Gtk.Label()
    advBtnLbl.get_style_context().add_class("audio-adv-lbl")

    const advBtn = new Gtk.Button()
    advBtn.get_style_context().add_class("audio-adv-btn")
    advBtn.set_child(advBtnLbl)
    advBtn.set_hexpand(true)

    // ── expanded area ─────────────────────────────────────────────────────────

    const tabBar = new Gtk.Box({ spacing: 0, homogeneous: true })
    tabBar.get_style_context().add_class("audio-tab-bar")

    const tabBody = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL })
    tabBody.get_style_context().add_class("audio-tab-body-wrap")

    const scrolled = new Gtk.ScrolledWindow({
        hscrollbar_policy: Gtk.PolicyType.NEVER,
        vscrollbar_policy: Gtk.PolicyType.AUTOMATIC,
    })
    scrolled.set_child(tabBody)
    scrolled.set_size_request(-1, 380)
    scrolled.get_style_context().add_class("audio-scroll")

    const expandedBox = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL })
    expandedBox.get_style_context().add_class("audio-expanded")
    expandedBox.append(tabBar)
    expandedBox.append(scrolled)

    // ── tab buttons ───────────────────────────────────────────────────────────

    const TABS    = ["OUTPUT", "INPUT", "DEVICES", "APPS"]
    const tabBtns: Gtk.Button[] = []

    for (let i = 0; i < TABS.length; i++) {
        const btn = new Gtk.Button()
        btn.get_style_context().add_class("audio-tab-btn")
        const lbl = new Gtk.Label({ label: TABS[i] })
        lbl.get_style_context().add_class("audio-tab-lbl")
        btn.set_child(lbl)
        const idx = i
        btn.connect("clicked", () => { activeTab = idx; renderTab() })
        tabBar.append(btn)
        tabBtns.push(btn)
    }

    // ── render active tab ─────────────────────────────────────────────────────

    function renderTab() {
        let c = tabBody.get_first_child()
        while (c) { const n = c.get_next_sibling(); tabBody.remove(c); c = n }

        tabBtns.forEach((b, i) => {
            b.get_style_context()[i === activeTab ? "add_class" : "remove_class"]("active")
        })

        let content: Gtk.Widget
        if      (activeTab === 0) content = buildOutput(audio)
        else if (activeTab === 1) content = buildInput(audio)
        else if (activeTab === 2) content = buildDevices(audio, fullRebuild)
        else                      content = buildApps(audio)

        tabBody.append(content)
    }

    // ── refresh compact bar ───────────────────────────────────────────────────

    function refreshCompact() {
        const sink = audio.default_speaker
        const src  = audio.default_microphone

        const sinkMuted = sink?.mute   ?? false
        const sinkVol   = sink?.volume ?? 0
        compactMuteIcon.set_label(sinkMuted ? ICON_VOL_OFF : deviceIcon(sink?.description ?? ""))
        compactMuteBtn.get_style_context()[sinkMuted ? "add_class" : "remove_class"]("muted")
        compactSlider.set_value(sinkVol)
        compactSlider.get_style_context()[sinkMuted ? "add_class" : "remove_class"]("muted")
        compactVolLbl.set_label(pct(sinkVol))

        const micMuted = src?.mute   ?? false
        const micVol   = src?.volume ?? 0
        compactMicMuteIcon.set_label(micMuted ? ICON_MIC_OFF : ICON_MIC)
        compactMicMuteBtn.get_style_context()[micMuted ? "add_class" : "remove_class"]("muted")
        compactMicSlider.set_value(micVol)
        compactMicSlider.get_style_context()[micMuted ? "add_class" : "remove_class"]("muted")
        compactMicVolLbl.set_label(pct(micVol))
    }

    // ── reconnect signals ─────────────────────────────────────────────────────

    function connectSpeakerSignals() {
        const sink = audio.default_speaker
        if (!sink) return
        if (speakerVolumeHandler) try { sink.disconnect(speakerVolumeHandler) } catch (_) {}
        if (speakerMuteHandler)   try { sink.disconnect(speakerMuteHandler)   } catch (_) {}
        speakerVolumeHandler = sink.connect("notify::volume", refreshCompact)
        speakerMuteHandler   = sink.connect("notify::mute",   refreshCompact)
    }

    function connectMicSignals() {
        const src = audio.default_microphone
        if (!src) return
        if (micVolumeHandler) try { src.disconnect(micVolumeHandler) } catch (_) {}
        if (micMuteHandler)   try { src.disconnect(micMuteHandler)   } catch (_) {}
        micVolumeHandler = src.connect("notify::volume", () => {
            refreshCompact()
            if (expanded && activeTab === 1) renderTab()
        })
        micMuteHandler = src.connect("notify::mute", () => {
            refreshCompact()
            if (expanded && activeTab === 1) renderTab()
        })
    }

    // ── full rebuild ──────────────────────────────────────────────────────────

    function fullRebuild() {
        connectSpeakerSignals()
        connectMicSignals()
        refreshCompact()
        if (expanded) renderTab()
    }

    // ── toggle expanded ───────────────────────────────────────────────────────

    function setExpanded(val: boolean) {
        expanded = val
        expandedBox.set_visible(val)
        advBtn.get_style_context()[val ? "add_class" : "remove_class"]("active")
        advBtnLbl.set_label(val ? "LESS" : "MORE")
        if (val) renderTab()
    }

    // ── compact interactions ──────────────────────────────────────────────────

    compactSlider.connect("value-changed", () => {
        const sink = audio.default_speaker
        if (!sink) return
        sink.volume = clamp(compactSlider.get_value())
        compactVolLbl.set_label(pct(compactSlider.get_value()))
    })

    compactMuteBtn.connect("clicked", () => {
        const sink = audio.default_speaker
        if (!sink) return
        const newMuted = !sink.mute
        sink.mute = newMuted
        compactMuteIcon.set_label(newMuted ? ICON_VOL_OFF : deviceIcon(sink.description ?? ""))
        compactMuteBtn.get_style_context()[newMuted ? "add_class" : "remove_class"]("muted")
        compactSlider.get_style_context()[newMuted ? "add_class" : "remove_class"]("muted")
    })

    compactMicSlider.connect("value-changed", () => {
        const src = audio.default_microphone
        if (!src) return
        src.volume = clamp(compactMicSlider.get_value())
        compactMicVolLbl.set_label(pct(compactMicSlider.get_value()))
    })

    compactMicMuteBtn.connect("clicked", () => {
        const src = audio.default_microphone
        if (!src) return
        const newMuted = !src.mute
        src.mute = newMuted
        compactMicMuteIcon.set_label(newMuted ? ICON_MIC_OFF : ICON_MIC)
        compactMicMuteBtn.get_style_context()[newMuted ? "add_class" : "remove_class"]("muted")
        compactMicSlider.get_style_context()[newMuted ? "add_class" : "remove_class"]("muted")
    })

    advBtn.connect("clicked", () => setExpanded(!expanded))

    // ── AstalWp signals ───────────────────────────────────────────────────────

    audio.connect("notify::default-speaker",    fullRebuild)
    audio.connect("notify::default-microphone", fullRebuild)
    audio.connect("notify::speakers",           fullRebuild)
    audio.connect("notify::microphones",        fullRebuild)
    audio.connect("notify::streams",            fullRebuild)

    // ── init ──────────────────────────────────────────────────────────────────

    connectSpeakerSignals()
    connectMicSignals()
    refreshCompact()
    setExpanded(false)

    // ── compact bar layout ────────────────────────────────────────────────────

    const speakerTag = new Gtk.Label({ label: "OUTPUT" })
    speakerTag.get_style_context().add_class("audio-compact-tag")

    const speakerSliderRow = new Gtk.Box({ spacing: 6 })
    speakerSliderRow.append(compactMuteBtn)
    speakerSliderRow.append(compactSlider)
    speakerSliderRow.append(compactVolLbl)

    const micTag = new Gtk.Label({ label: "INPUT" })
    micTag.get_style_context().add_class("audio-compact-tag")
    micTag.get_style_context().add_class("mic")

    const micSliderRow = new Gtk.Box({ spacing: 6 })
    micSliderRow.append(compactMicMuteBtn)
    micSliderRow.append(compactMicSlider)
    micSliderRow.append(compactMicVolLbl)

    const compactDivider = new Gtk.Separator({ orientation: Gtk.Orientation.HORIZONTAL })
    compactDivider.get_style_context().add_class("audio-sep")

    // sliders stacked vertically, full width
    const sliderWrap = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 6 })
    sliderWrap.append(speakerTag)
    sliderWrap.append(speakerSliderRow)
    sliderWrap.append(compactDivider)
    sliderWrap.append(micTag)
    sliderWrap.append(micSliderRow)

    const compactBar = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL, spacing: 10 })
    compactBar.get_style_context().add_class("audio-compact-bar")
    compactBar.append(sliderWrap)

    // adv button sits below, full width, centered label
    const advBtnRow = new Gtk.Box()
    advBtnRow.get_style_context().add_class("audio-adv-row")
    advBtnRow.append(advBtn)

    // ── card ──────────────────────────────────────────────────────────────────

    const card = new Gtk.Box({ orientation: Gtk.Orientation.VERTICAL })
    card.get_style_context().add_class("audio-card")
    card.set_size_request(360, -1)
    card.append(compactBar)
    card.append(advBtnRow)
    card.append(expandedBox)

    // ── backdrop click ────────────────────────────────────────────────────────

    function handleBackdropClick(self: Astal.Window) {
        const click = new Gtk.GestureClick()
        click.connect("pressed", (_g, _n, x, y) => {
            const child = self.get_child()
            if (!child) return
            const alloc = child.get_allocation()
            const outside =
                x < alloc.x || x > alloc.x + alloc.width ||
                y < alloc.y || y > alloc.y + alloc.height
            if (outside) app.toggle_window("Audio")
        })
        self.add_controller(click)
    }

    return (
        <window
            name="Audio"
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
                css={`margin-top: 45px; margin-right: 150px;`}
            >
                {card}
            </box>
        </window>
    )
}
