import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "root:/"
import "root:/widgets"

// Command palette (design "App Launcher" · id 2a).
//
// NB: this type must NOT be called `Palette`. QtQuick exposes a built-in `Palette`
// value type, which shadows a same-named component — the symptom is
// "Palette does not have a property called modelData" and a surface that never
// appears. A centred modal surface: mode
// badge, search field, rich-row list, keybind footer, over a dimmed desktop.
//
// The design's framing is "one component, every mode". Only Apps is implemented;
// a mode supplies { id, badge, hint, search(text) -> [rows], activate(row) } and
// nothing else in this file changes. Clipboard, Emoji and Pass slot in beside it.
//
// This is the first surface in the shell that takes KEYBOARD FOCUS. Bars,
// popovers and the OSD are all deliberately non-focusable; a palette cannot be.
// keyboardFocus is Exclusive only while open, and the window is destroyed on
// close so the keyboard is always handed back.
PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    readonly property var cfg: Config.palette

    // "focused" follows the focused monitor; anything else pins to that role.
    readonly property bool isTarget:
        cfg.monitor === "focused"
            ? (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name === modelData.name : false)
            : (Config.roles[modelData.name] || "other") === cfg.monitor

    readonly property color accent:
        Theme[cfg.accent] !== undefined ? Theme[cfg.accent] : Theme.mauve

    property bool open: false
    property string query: ""
    property int index: 0

    // ---- modes -------------------------------------------------------------
    // Apps: backed by Quickshell's DesktopEntries, so launching is entry.execute()
    // rather than a shell-out. noDisplay entries are hidden, as in any launcher.
    readonly property var appsMode: ({
        id: "apps",
        badge: "Apps",
        hint: "↵",
        unit: "apps",
        search: function (text) {
            const q = text.toLowerCase().trim();
            const out = [];
            const all = DesktopEntries.applications.values;
            for (let i = 0; i < all.length; i++) {
                const e = all[i];
                if (e.noDisplay)
                    continue;
                const name = (e.name || "");
                const generic = (e.genericName || "");
                const exec = (e.execString || "");
                let rank = -1;
                if (q === "")
                    rank = 2;
                else if (name.toLowerCase().startsWith(q))
                    rank = 0;                                   // prefix wins
                else if (name.toLowerCase().indexOf(q) >= 0)
                    rank = 1;
                else if (generic.toLowerCase().indexOf(q) >= 0
                      || exec.toLowerCase().indexOf(q) >= 0)
                    rank = 2;
                if (rank < 0)
                    continue;
                out.push({
                    rank: rank,
                    tile: name.substring(0, 2),
                    // check = true returns "" rather than a broken-image texture,
                    // so the row can fall back to its initials tile.
                    icon: e.icon ? Quickshell.iconPath(e.icon, true) : "",
                    title: name,
                    subtitle: generic !== "" ? (generic + (exec ? " · " + exec : "")) : exec,
                    entry: e
                });
            }
            out.sort((a, b) => a.rank !== b.rank ? a.rank - b.rank
                                                 : a.title.localeCompare(b.title));
            return out;
        },
        activate: function (row) { if (row && row.entry) row.entry.execute(); }
    })

    // ---- clipboard mode ----------------------------------------------------
    // Option A from the plan: cliphist keeps doing capture and storage (it already
    // runs from the launchers preset autostart and holds image entries, which
    // Quickshell's text-only clipboardText could not represent). The palette
    // replaces only the rofi -dmenu picker.
    property var clipboardEntries: []

    // `cliphist list` emits "<id>\t<preview>", newest first — which is the order
    // we want, so no sorting.
    Process {
        id: clipList
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n");
                const out = [];
                for (let i = 0; i < lines.length; i++) {
                    const tab = lines[i].indexOf("\t");
                    if (tab < 0) continue;
                    const preview = lines[i].substring(tab + 1);
                    out.push({
                        cid: lines[i].substring(0, tab),
                        preview: preview,
                        binary: preview.startsWith("[[ binary data")
                    });
                }
                root.clipboardEntries = out;
            }
        }
    }

    // Decoding goes through sh because of the pipe; the id is passed as an
    // argument rather than interpolated into the script.
    Process { id: clipCopy }

    readonly property var clipboardMode: ({
        id: "clipboard",
        badge: "Clipboard",
        hint: "↵ copy",
        unit: "entries",
        search: function (text) {
            const q = text.toLowerCase().trim();
            const all = root.clipboardEntries;
            const out = [];
            for (let i = 0; i < all.length; i++) {
                const e = all[i];
                if (q !== "" && e.preview.toLowerCase().indexOf(q) < 0)
                    continue;
                out.push({
                    tile: e.binary ? "img" : "“",
                    title: e.preview,
                    subtitle: "",
                    icon: "",
                    cid: e.cid
                });
            }
            return out;                       // already newest-first
        },
        activate: function (row) {
            if (!row || !row.cid) return;
            clipCopy.command = ["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", row.cid];
            clipCopy.running = true;
        }
    })

    // DesktopEntries scans lazily — only once a BINDING observes it — and fills in
    // incrementally. Evaluating this once at startup starts the scan, so the first
    // open shows a complete list instead of one growing under the cursor.
    readonly property int entryCount: DesktopEntries.applications.values.length
    Component.onCompleted: root.entryCount

    readonly property var modes: [ appsMode, clipboardMode ]
    property int modeIndex: 0
    readonly property var mode: modes[modeIndex]
    readonly property var rows: root.open ? root.mode.search(root.query) : []
    readonly property int count: rows.length

    // ---- open / close ------------------------------------------------------
    function show(modeId) {
        if (!root.isTarget) return;
        for (let i = 0; i < root.modes.length; i++)
            if (root.modes[i].id === modeId) root.modeIndex = i;
        root.query = "";
        root.index = 0;
        // Clipboard contents change constantly, so re-read on every open.
        if (root.mode.id === "clipboard") clipList.running = true;
        root.open = true;
    }

    function cycleMode(delta) {
        root.modeIndex = (root.modeIndex + delta + root.modes.length) % root.modes.length;
        root.query = "";
        root.index = 0;
        if (root.mode.id === "clipboard") clipList.running = true;
    }
    function hide() { root.open = false; }

    function move(delta) {
        if (root.count === 0) return;
        root.index = (root.index + delta + root.count) % root.count;
    }
    function activate() {
        const row = root.rows[root.index];
        if (!row) return;
        root.hide();
        root.mode.activate(row);
    }

    // Hyprland binds SUPER+P to hl.dsp.global("quickshell:palette"); this is the
    // other half of that pair, so no shelling out to `qs ipc`.
    GlobalShortcut {
        appid: "quickshell"
        name: "palette"
        description: "Open the command palette (apps)"
        onPressed: root.open && root.mode.id === "apps" ? root.hide() : root.show("apps")
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "clipboard"
        description: "Open the command palette (clipboard)"
        onPressed: root.open && root.mode.id === "clipboard" ? root.hide() : root.show("clipboard")
    }

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    visible: root.open
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive
                                           : WlrKeyboardFocus.None

    // Scrim — dims the desktop and closes on an outside click (design 2a).
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.crust.r, Theme.crust.g, Theme.crust.b, root.cfg.scrim)
        TapHandler { onTapped: root.hide() }
    }

    FocusScope {
        anchors.fill: parent
        focus: root.open

        Keys.onPressed: function (event) {
            if (event.key === Qt.Key_Escape)                  { root.hide(); event.accepted = true; }
            else if (event.key === Qt.Key_Down)               { root.move(1);  event.accepted = true; }
            else if (event.key === Qt.Key_Up)                 { root.move(-1); event.accepted = true; }
            else if (event.key === Qt.Key_Return
                  || event.key === Qt.Key_Enter)              { root.activate(); event.accepted = true; }
            else if (event.key === Qt.Key_Tab)                { root.cycleMode(1); event.accepted = true; }
            else if (event.key === Qt.Key_Backtab)            { root.cycleMode(-1); event.accepted = true; }
            else if (event.key === Qt.Key_Backspace)          { root.query = root.query.slice(0, -1); root.index = 0; event.accepted = true; }
            else if (event.text && event.text.length === 1
                  && event.text.charCodeAt(0) >= 0x20)        { root.query += event.text; root.index = 0; event.accepted = true; }
        }

        Rectangle {
            id: box
            width: root.cfg.width
            // The artboard is horizontally centred but top-anchored at 64px — which
            // reads as centred on its 576px mock and near the edge on a real
            // screen. "center" is the default here; "top" keeps the design literal.
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: root.cfg.position === "center" ? parent.verticalCenter : undefined
            anchors.top: root.cfg.position === "center" ? undefined : parent.top
            anchors.topMargin: root.cfg.position === "center" ? 0 : root.cfg.topMargin
            implicitHeight: layout.implicitHeight
            radius: 18
            color: Theme.mantle
            border.width: 1
            border.color: Theme.surface1
            clip: true

            Column {
                id: layout
                width: parent.width

                // ---- search header ----
                Item {
                    width: parent.width
                    height: 54
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 13

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: badgeRow.implicitWidth + 24
                            implicitHeight: 28
                            radius: 10
                            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
                            border.width: 1
                            border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.44)
                            Row {
                                id: badgeRow
                                anchors.centerIn: parent
                                spacing: 8
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 6; height: 6; radius: 3
                                    color: root.accent
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.mode.badge
                                    font.family: Theme.fontUi
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: root.accent
                                }
                            }
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 200
                            spacing: 2
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.query
                                font.family: Theme.fontUi
                                font.pixelSize: 18
                                color: Theme.fg
                            }
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 2; height: 20
                                color: root.accent
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    running: root.open
                                    NumberAnimation { to: 0; duration: 500 }
                                    NumberAnimation { to: 1; duration: 500 }
                                }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.count + " " + root.mode.unit
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: Theme.overlay0
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Theme.surface0 }

                // ---- rows ----
                Item {
                    width: parent.width
                    // Fixed by default: a height that tracks the result count makes the
                    // box jump on every keystroke, and re-centre with it.
                    implicitHeight: (root.cfg.fixedHeight
                        ? root.cfg.maxRows
                        : Math.min(root.count, root.cfg.maxRows)) * 60 + 16
                    ListView {
                        id: list
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 2
                        clip: true
                        model: root.rows
                        currentIndex: root.index
                        highlightMoveDuration: 90
                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                        delegate: PaletteRow {
                            required property var modelData
                            required property int index
                            width: list.width
                            tile: modelData.tile
                            iconSource: modelData.icon || ""
                            title: modelData.title
                            subtitle: modelData.subtitle
                            hint: index === root.index ? root.mode.hint
                                : (root.cfg.quickKeys && index < 9) ? String(index + 1) : ""
                            selected: index === root.index
                            accent: root.accent
                            selectionStyle: root.cfg.selectionStyle
                            onActivated: { root.index = index; root.activate(); }
                        }
                    }
                }

                // ---- footer ----
                Rectangle {
                    width: parent.width
                    height: 38
                    color: Theme.crust
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 18
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "↑↓ navigate   " + root.mode.hint + "   ⇥ switch mode"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: Theme.overlay0
                        }
                        Item { width: parent.width - 320; height: 1 }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "esc close"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: Theme.overlay0
                        }
                    }
                }
            }
        }
    }
}
