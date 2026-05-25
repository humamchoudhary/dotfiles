import app from "ags/gtk4/app"
import Gtk from "gi://Gtk?version=4.0"
import GLib from "gi://GLib"
import Astal from "gi://Astal"
import Pango from "gi://Pango"
import { createState, createBinding, createComputed, onCleanup, With } from "ags"
import Mpris from "gi://AstalMpris"
import Cava from "gi://AstalCava"
import Gio from "gi://Gio"
import Gdk from "gi://Gdk?version=4.0"

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const COVER = "\uf001"

// Format microseconds (MPRIS position/length unit) into m:ss
function fmtTime(seconds: number) {
    if (!isFinite(seconds) || seconds < 0) seconds = 0
    const m = Math.floor(seconds / 60)
    const s = Math.floor(seconds % 60)
    return `${m}:${s.toString().padStart(2, "0")}`
}

// Pick the "best" active player: prefer one that is playing, else the first.
function pickPlayer(players: Mpris.Player[]): Mpris.Player | null {
    if (!players || players.length === 0) return null
    const playing = players.find(
        (p) => p.playbackStatus === Mpris.PlaybackStatus.PLAYING,
    )
    return playing ?? players[0]
}

// ---------------------------------------------------------------------------
// Cava visualizer — draws bars with GTK4 snapshot via DrawingArea
// ---------------------------------------------------------------------------

function CavaBars() {
    const cava = Cava.get_default()

    // Configure the cava instance. These are the standard AstalCava knobs.
    if (cava) {
        cava.set_bars(24)
        cava.set_stereo(false)
        cava.set_noise_reduction(0.77)
    }

    // values is an Accessor<number[]> where each entry is 0..1
    const values = cava
        ? createBinding(cava, "values")
        : createState<number[]>([])[0]

    return (
        <drawingarea
            cssClasses={["cava"]}
            hexpand
            heightRequest={70}
            $={(self) => {
                // Repaint whenever cava emits new values.
                const unsub = values.subscribe(() => self.queue_draw())
                onCleanup(unsub)

                self.set_draw_func((area, cr, width, height) => {
                    let bars = values.peek() ?? []
                    const total = bars.length
                    if (total === 0) return

                    // Cava sometimes outputs stereo data (left then right) even with
                    // set_stereo(false). If the second half mirrors the first, drop it.
                    if (total > 24 && total % 2 === 0) {
                        const half = total / 2
                        let mirrored = true
                        for (let i = 0; i < half; i++) {
                            if (Math.abs(bars[i] - bars[half + i]) > 0.05) {
                                mirrored = false
                                break
                            }
                        }
                        if (mirrored) bars = bars.slice(0, half)
                    }

                    const n = Math.min(bars.length, 24)

                    // Pull accent color from the widget's CSS `color` property.
                    const color = area.get_style_context().get_color(Gtk.StateFlags.NORMAL)

                    const gap = 2
                    const barW = Math.max(4, (width - gap * (n - 1)) / n)
                    const radius = Math.min(barW / 2, 4)

                    for (let i = 0; i < n; i++) {
                        const v = Math.max(0, Math.min(1, bars[i]))
                        const barH = Math.max(2, v * height)
                        const x = i * (barW + gap)
                        const y = height - barH

                        // brighter toward the top of each bar
                        const alpha = 0.45 + 0.55 * v
                        cr.setSourceRGBA(color.red, color.green, color.blue, alpha)

                        // rounded-top bar
                        cr.newSubPath()
                        cr.arc(x + radius, y + radius, radius, Math.PI, 1.5 * Math.PI)
                        cr.arc(x + barW - radius, y + radius, radius, 1.5 * Math.PI, 2 * Math.PI)
                        cr.lineTo(x + barW, height)
                        cr.lineTo(x, height)
                        cr.closePath()
                        cr.fill()
                    }
                })
            }}
        />
    )
}

// ---------------------------------------------------------------------------
// Album art with a graceful fallback
// ---------------------------------------------------------------------------

function CoverArt({ player }: { player: Mpris.Player }) {
    const cover = createBinding(player, "coverArt")
    const COVER = "\udb81\udf5a"

    return (
        <overlay cssClasses={["cover"]} widthRequest={96} heightRequest={96}>
            <box
                cssClasses={["cover-fallback"]}
                halign={Gtk.Align.FILL}
                valign={Gtk.Align.FILL}
                visible={cover((c) => !c)}
            >
                <label
                    label={COVER}
                    cssClasses={["cover-glyph"]}
                    halign={Gtk.Align.CENTER}
                    valign={Gtk.Align.CENTER}
                    hexpand
                    vexpand
                />
            </box>
            <Gtk.Picture
                $type="overlay"
                cssClasses={["cover-img"]}
                halign={Gtk.Align.FILL}
                valign={Gtk.Align.FILL}
                hexpand
                vexpand
                contentFit={Gtk.ContentFit.COVER}
                visible={cover((c) => !!c)}
                $={(self: Gtk.Picture) => {
                    const load = (path: string | null) => {
                        if (!path) {
                            self.set_paintable(null)
                            return
                        }
                        // build a fresh texture from the file so we never serve a
                        // stale cache for a reused path
                        try {
                            const file = Gio.File.new_for_path(path)
                            const texture = Gdk.Texture.new_from_file(file)
                            self.set_paintable(texture)
                        } catch (e) {
                            self.set_paintable(null)
                        }
                    }
                    load(cover.peek())
                    const unsub = cover.subscribe(() => load(cover.peek()))
                    onCleanup(unsub)
                }}
            />
        </overlay>
    )
}

// ---------------------------------------------------------------------------
// Transport / progress
// ---------------------------------------------------------------------------

function Controls({ player }: { player: Mpris.Player }) {
    const status = createBinding(player, "playbackStatus")
    const canGoNext = createBinding(player, "canGoNext")
    const canGoPrev = createBinding(player, "canGoPrevious")
    const canPlay = createBinding(player, "canPlay")

    const playIcon = status((s) =>
        s === Mpris.PlaybackStatus.PLAYING ? "\uF04C" : "\uF04B",
    )
    const NEXT_ICON = "\udb81\udcad"
    const PREV_ICON = "\udb81\udcae"

    return (
        <box cssClasses={["controls"]} halign={Gtk.Align.CENTER} spacing={10}>
            <button
                cssClasses={["ctrl", "ctrl-side"]}
                sensitive={canGoPrev}
                onClicked={() => player.previous()}
            >
                <label label={PREV_ICON} />
            </button>
            <button
                cssClasses={["ctrl", "ctrl-play"]}
                sensitive={canPlay}
                onClicked={() => player.play_pause()}
            >
                <label label={playIcon} />
            </button>
            <button
                cssClasses={["ctrl", "ctrl-side"]}
                sensitive={canGoNext}
                onClicked={() => player.next()}
            >
                <label label={NEXT_ICON} />
            </button>
        </box>
    )
}

function Progress({ player }: { player: Mpris.Player }) {
    const length = createBinding(player, "length")

    const [position, setPosition] = createState(player.position)
    // true while the user is holding/dragging the slider, so the 1s poll
    // doesn't yank the handle out from under them
    let dragging = false

    const tick = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000, () => {
        if (!dragging) setPosition(player.position)
        return GLib.SOURCE_CONTINUE
    })
    onCleanup(() => GLib.source_remove(tick))

    return (
        <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
            <slider
                cssClasses={["seek"]}
                hexpand
                drawValue={false}
                min={0}
                max={1}
                value={createComputed(() => {
                    const len = length()
                    const pos = position()
                    if (!len || len <= 0) return 0
                    return Math.max(0, Math.min(1, pos / len))
                })}
                $={(self: Gtk.Scale) => {
                    // know when the user is actively interacting
                    const press = new Gtk.GestureClick()
                    press.connect("pressed", () => { dragging = true })
                    press.connect("released", () => { dragging = false })
                    self.add_controller(press)

                    // commit on release / any user-driven value change
                    const id = self.connect("change-value", (_s, _scroll, val) => {
                        const len = length.peek()
                        if (len > 0) {
                            const target = Math.round(val * len)
                            player.set_position(target)
                            setPosition(target)
                        }
                        return false // let default handling update the visual too
                    })
                    onCleanup(() => self.disconnect(id))
                }}
            />
            <box>
                <label cssClasses={["time"]} halign={Gtk.Align.START} hexpand
                    label={position((p) => fmtTime(p))} />
                <label cssClasses={["time"]} halign={Gtk.Align.END}
                    label={length((l) => fmtTime(l))} />
            </box>
        </box>
    )
}

// ---------------------------------------------------------------------------
// The actual player card (rendered only when a player exists)
// ---------------------------------------------------------------------------

function PlayerCard({ player }: { player: Mpris.Player }) {
    const title = createBinding(player, "title")
    const artist = createBinding(player, "artist")

    return (
        <box cssClasses={["card"]} orientation={Gtk.Orientation.VERTICAL} spacing={12}>
            <label cssClasses={["music-tag"]} halign={Gtk.Align.START} label="MUSIC" />
            <box spacing={14}>
                <CoverArt player={player} />
                <box orientation={Gtk.Orientation.VERTICAL} valign={Gtk.Align.CENTER} hexpand spacing={2}>
                    <label
                        cssClasses={["title"]}
                        halign={Gtk.Align.START}
                        maxWidthChars={20}
                        ellipsize={Pango.EllipsizeMode.END}
                        label={title((t) => t || "Nothing playing")}
                    />
                    <label
                        cssClasses={["artist"]}
                        halign={Gtk.Align.START}
                        maxWidthChars={24}
                        ellipsize={Pango.EllipsizeMode.END}
                        label={artist((a) => a || "Unknown artist")}
                    />
                </box>
            </box>

            <Progress player={player} />
            <Controls player={player} />
            <CavaBars />
        </box>
    )
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

function EmptyCard() {
    return (
        <box cssClasses={["card", "card-empty"]} orientation={Gtk.Orientation.VERTICAL} spacing={12} valign={Gtk.Align.CENTER}>
            <label cssClasses={["music-tag"]} halign={Gtk.Align.START} label="MUSIC" />
            <box orientation={Gtk.Orientation.VERTICAL} spacing={10} hexpand vexpand valign={Gtk.Align.CENTER}>
                <label cssClasses={["empty-glyph"]} halign={Gtk.Align.CENTER} label={COVER} />
                <label cssClasses={["empty-text"]} halign={Gtk.Align.CENTER} label="No active media" />
            </box>
        </box>
    )
}

// ---------------------------------------------------------------------------
// Window
// ---------------------------------------------------------------------------


export function Music(monitor = 0) {
    const mpris = Mpris.get_default()
    const players = createBinding(mpris, "players")

    // The single player we display, derived reactively from the player list.
    const active = players((list) => pickPlayer(list as Mpris.Player[]))

    function handleBackdropClick(self: Astal.Window) {
        const click = new Gtk.GestureClick()
        click.connect("pressed", (_g, _n, x, y) => {
            const child = self.get_child()
            if (!child) return
            const alloc = child.get_allocation()
            const outside =
                x < alloc.x || x > alloc.x + alloc.width ||
                y < alloc.y || y > alloc.y + alloc.height
            if (outside) app.toggle_window("Music")
        })
        self.add_controller(click)
    }

    return (
        <window
            name="Music"
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
                halign={Gtk.Align.START}
                valign={Gtk.Align.START}
                css={`margin-top: 45px; margin-left: 250px;`}
            >
                <With value={active}>
                    {(player) =>
                        player ? <PlayerCard player={player} /> : <EmptyCard />
                    }
                </With>
            </box>
        </window>
    )
}