import QtQuick
import "root:/"

// The month-at-a-glance calendar body (Calendar Widget · 7b). Display only — no
// event backend. Monday-first; today filled with the accent, weekends and
// other-month days dimmed. Sizes here are the mockup's real (1x) values, not the
// bar-scaled Theme metrics, since this renders in its own popover window.
Rectangle {
    id: root

    // Displayed month (defaults to the current month on creation).
    property int viewYear: 0
    property int viewMonth: 0        // 0-11
    property bool showWeekNumbers: false

    color: Theme.mantle
    border.color: Theme.surface
    border.width: 1
    radius: 16

    implicitWidth: layout.implicitWidth + 32
    implicitHeight: layout.implicitHeight + 32

    readonly property var _weekdays: ["lu", "ma", "me", "je", "ve", "sa", "di"]
    property var _now: new Date()
    property var cells: []

    function _isToday(d) {
        return d.getFullYear() === root._now.getFullYear()
            && d.getMonth() === root._now.getMonth()
            && d.getDate() === root._now.getDate();
    }

    // Build a Monday-first grid padded to whole weeks, each cell a real Date so
    // other-month / weekend / today are unambiguous.
    function rebuild() {
        const first = new Date(root.viewYear, root.viewMonth, 1);
        const startDow = (first.getDay() + 6) % 7;               // Mon=0 .. Sun=6
        const daysInMonth = new Date(root.viewYear, root.viewMonth + 1, 0).getDate();
        const total = Math.ceil((startDow + daysInMonth) / 7) * 7;
        const out = [];
        for (let i = 0; i < total; i++) {
            const dt = new Date(root.viewYear, root.viewMonth, 1 - startDow + i);
            out.push({
                day: dt.getDate(),
                other: dt.getMonth() !== root.viewMonth,
                weekend: (i % 7) >= 5,
                today: root._isToday(dt),
                date: dt
            });
        }
        root.cells = out;
    }

    // ISO-8601 week number (for the optional week column).
    function _isoWeek(d) {
        const dt = new Date(d.getFullYear(), d.getMonth(), d.getDate());
        dt.setDate(dt.getDate() + 3 - ((dt.getDay() + 6) % 7));
        const week1 = new Date(dt.getFullYear(), 0, 4);
        return 1 + Math.round(((dt - week1) / 86400000 - 3 + ((week1.getDay() + 6) % 7)) / 7);
    }

    function goToday() {
        root._now = new Date();
        root.viewYear = root._now.getFullYear();
        root.viewMonth = root._now.getMonth();
    }
    function shift(delta) {
        let m = root.viewMonth + delta;
        let y = root.viewYear;
        while (m < 0) { m += 12; y--; }
        while (m > 11) { m -= 12; y++; }
        root.viewMonth = m;
        root.viewYear = y;
    }

    Component.onCompleted: {
        if (root.viewYear === 0)
            root.goToday();
        else
            root.rebuild();
    }
    onViewYearChanged: rebuild()
    onViewMonthChanged: rebuild()

    Column {
        id: layout
        x: 16
        y: 16
        spacing: 14

        // ---- Month nav header ----
        Item {
            width: body.width
            height: 26

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 7
                Text {
                    // French month names are lowercase; capitalise for the header.
                    text: {
                        const m = new Date(root.viewYear, root.viewMonth, 1)
                            .toLocaleDateString(Qt.locale(Theme.locale), "MMMM");
                        return m.charAt(0).toUpperCase() + m.slice(1);
                    }
                    font.family: Theme.fontUi
                    font.pixelSize: 16
                    font.bold: true
                    color: Theme.fg
                }
                Text {
                    text: root.viewYear
                    font.family: Theme.fontUi
                    font.pixelSize: 16
                    color: Theme.overlay1
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 8
                    color: Qt.alpha(Theme.accent, 0.14)
                    implicitWidth: todayLabel.implicitWidth + 18
                    implicitHeight: 24
                    Text {
                        id: todayLabel
                        anchors.centerIn: parent
                        text: "AUJ."
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.accent
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.goToday()
                    }
                }

                Repeater {
                    model: [{ g: "‹", d: -1 }, { g: "›", d: 1 }]
                    Rectangle {
                        required property var modelData
                        width: 26
                        height: 26
                        radius: 8
                        color: navArea.containsMouse ? Theme.surface : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData.g
                            font.family: Theme.fontUi
                            font.pixelSize: 15
                            color: navArea.containsMouse ? Theme.fg : Theme.subtext0
                        }
                        MouseArea {
                            id: navArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.shift(parent.modelData.d)
                        }
                    }
                }
            }
        }

        // ---- Week numbers + weekday headers + day grid ----
        Row {
            id: body
            spacing: 7

            // Optional ISO week-number column.
            Column {
                visible: root.showWeekNumbers
                spacing: 4
                Item { width: 22; height: 26 }   // clears the weekday header row
                Repeater {
                    model: Math.floor(root.cells.length / 7)
                    Text {
                        required property int index
                        width: 22
                        height: 38
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: root.cells.length ? root._isoWeek(root.cells[index * 7].date) : ""
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        color: Theme.overlay0
                    }
                }
            }

            Column {
                spacing: 6

                // Weekday headers (weekend dimmed).
                Row {
                    spacing: 4
                    Repeater {
                        model: root._weekdays
                        Text {
                            required property var modelData
                            required property int index
                            width: 38
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                            color: index >= 5 ? Theme.overlay0 : Theme.overlay1
                        }
                    }
                }

                // Day grid.
                Grid {
                    columns: 7
                    spacing: 4
                    Repeater {
                        model: root.cells
                        Rectangle {
                            id: cell
                            required property var modelData
                            width: 38
                            height: 38
                            radius: 9
                            color: modelData.today ? Theme.accent
                                 : (dayArea.containsMouse && !modelData.other) ? Theme.surface
                                 : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: cell.modelData.day
                                font.family: Theme.fontMono
                                font.pixelSize: 13
                                font.bold: cell.modelData.today
                                color: cell.modelData.today ? Theme.onAccent
                                     : cell.modelData.other  ? Theme.overlay0
                                     : cell.modelData.weekend ? Theme.overlay1
                                     : Theme.fg
                            }
                            MouseArea {
                                id: dayArea
                                anchors.fill: parent
                                hoverEnabled: !cell.modelData.other
                                cursorShape: cell.modelData.other ? Qt.ArrowCursor : Qt.PointingHandCursor
                            }
                        }
                    }
                }
            }
        }
    }
}
