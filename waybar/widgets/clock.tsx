import app from "ags/gtk4/app"
import Gtk from "gi://Gtk?version=4.0"
import GLib from "gi://GLib"
import Astal from "gi://Astal"




export function Clock(monitor = 0) {



    let current = new Date()
    const today = new Date()

    // --- Grid cells (6 rows × 7 cols = 42) ---
    const dayCells: Gtk.Button[] = []
    for (let i = 0; i < 42; i++) {
        const btn = new Gtk.Button({
            css_name: "day-cell",
        })
        btn.get_style_context().add_class("day-cell")
        dayCells.push(btn)
    }

    const dateLabel = new Gtk.Label({ xalign: 0 })
    const monthLabel = new Gtk.Label({ halign: Gtk.Align.CENTER })
    const weekdayLabel = new Gtk.Label({ xalign: 0 })

    function updateUI() {
        // Header labels
        weekdayLabel.set_label(
            current.toLocaleDateString("en-US", { weekday: "long" }).toUpperCase()
        )
        dateLabel.set_label(
            current.toLocaleDateString("en-US", {
                year: "numeric",
                month: "long",
                day: "numeric",
            })
        )
        monthLabel.set_label(
            current.toLocaleDateString("en-US", { month: "long", year: "numeric" })
        )

        // Calendar grid
        const year = current.getFullYear()
        const month = current.getMonth()
        const firstDay = new Date(year, month, 1).getDay() // 0=Sun
        const daysInMonth = new Date(year, month + 1, 0).getDate()
        const daysInPrev = new Date(year, month, 0).getDate()

        dayCells.forEach((btn, i) => {
            const ctx = btn.get_style_context()
            // Remove all state classes
            for (const cls of ["today", "selected", "other-month", "in-month"]) {
                ctx.remove_class(cls)
            }

            let day: number
            let inMonth = true

            if (i < firstDay) {
                day = daysInPrev - firstDay + i + 1
                inMonth = false
            } else if (i >= firstDay + daysInMonth) {
                day = i - firstDay - daysInMonth + 1
                inMonth = false
            } else {
                day = i - firstDay + 1
            }

            const child = btn.get_child() as Gtk.Label | null
            const lbl = child ?? new Gtk.Label()
            lbl.set_label(String(day))
            if (!child) btn.set_child(lbl)

            if (!inMonth) {
                ctx.add_class("other-month")
            } else {
                ctx.add_class("in-month")
                const isToday =
                    day === today.getDate() &&
                    month === today.getMonth() &&
                    year === today.getFullYear()
                const isSelected =
                    day === current.getDate() &&
                    month === current.getMonth() &&
                    year === current.getFullYear()
                if (isToday) ctx.add_class("today")
                if (isSelected) ctx.add_class("selected")

                btn.connect("clicked", () => {
                    current = new Date(year, month, day)
                    updateUI()
                })
            }
        })
    }

    function changeMonth(offset: number) {
        current = new Date(current.getFullYear(), current.getMonth() + offset, 1)
        updateUI()
    }

    function changeYear(offset: number) {
        current = new Date(current.getFullYear() + offset, current.getMonth(), 1)
        updateUI()
    }

    updateUI()

    function handleBackdropClick(self: Astal.Window) {
        const click = new Gtk.GestureClick()
        click.connect("pressed", (_gesture, _n, x, y) => {
            const child = self.get_child()
            if (!child) return
            const alloc = child.get_allocation()
            const outside =
                x < alloc.x ||
                x > alloc.x + alloc.width ||
                y < alloc.y ||
                y > alloc.y + alloc.height
            if (outside) app.toggle_window("Clock")
        })
        self.add_controller(click)
    }

    function navBtn(label: string, onClick: () => void) {
        const btn = new Gtk.Button()
        btn.set_child(new Gtk.Label({ label }))
        btn.connect("clicked", onClick)
        btn.get_style_context().add_class("nav-btn")
        return btn
    }

    // Build the 7-column grid
    const gridBox = new Gtk.Box({
        orientation: Gtk.Orientation.VERTICAL,
        spacing: 2,
    })

    // Day-of-week headers
    const DOW = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    const headerRow = new Gtk.Box({ spacing: 2, homogeneous: true })
    for (const d of DOW) {
        const lbl = new Gtk.Label({ label: d })
        lbl.get_style_context().add_class("dow-header")
        headerRow.append(lbl)
    }
    gridBox.append(headerRow)

    // 6 rows of day cells
    for (let row = 0; row < 6; row++) {
        const rowBox = new Gtk.Box({ spacing: 2, homogeneous: true })
        for (let col = 0; col < 7; col++) {
            rowBox.append(dayCells[row * 7 + col])
        }
        gridBox.append(rowBox)
    }

    return (
        <window
            name="Clock"
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
                orientation={Gtk.Orientation.VERTICAL}
                halign={Gtk.Align.CENTER}
                valign={Gtk.Align.START}
                css={`margin-top: 45px;`}
            >
                <box
                    orientation={Gtk.Orientation.VERTICAL}
                    spacing={0}
                    css={`
                        border-radius: 20px;
                        background: @base;
                        border: 1px solid @border;
                        min-width: 320px;
                    `}
                >
                    {/* Date header */}
                    <box
                        orientation={Gtk.Orientation.VERTICAL}
                        spacing={4}
                        css={`
                            padding: 20px 20px 16px 20px;
                            border-bottom: 1px solid @border;
                        `}
                    >
                        {weekdayLabel}
                        {dateLabel}
                    </box>

                    {/* Month nav */}
                    <box
                        spacing={6}
                        css={`padding: 12px 14px 8px 14px;`}
                    >
                        {navBtn("«", () => changeYear(-1))}
                        {navBtn("‹", () => changeMonth(-1))}
                        <box hexpand halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
                            {monthLabel}
                        </box>
                        {navBtn("›", () => changeMonth(1))}
                        {navBtn("»", () => changeYear(1))}
                    </box>

                    {/* Custom calendar grid */}
                    <box css={`padding: 0 12px 16px 12px;`}>
                        {gridBox}
                    </box>
                </box>
            </box>
        </window>
    )
}
