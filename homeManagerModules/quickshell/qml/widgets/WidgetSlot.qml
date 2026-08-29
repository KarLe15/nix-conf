import QtQuick
import "root:/"
import "root:/widgets"

// Dispatches one bar-layout entry ({ w, ... } from Config.barLayout) to the matching
// widget. Real widgets get their props from the entry + bar context; any name not in
// the registry (notably "stub") falls back to a StubPill built from the entry's
// icon/label/color — so the design's not-yet-built modules render with no backend.
// Adding a real widget = a new case here + a case in Config's layout preset.
Loader {
    id: slot
    property var entry: ({})
    property string screenName: ""
    property bool isHub: false
    property string role: "other"

    sourceComponent: {
        switch (entry.w) {
        case "clock":      return clockC;
        case "workspaces": return workspacesC;
        case "system":     return systemC;
        case "systemp":    return sysTempC;
        case "network":    return networkC;
        case "volume":     return volumeC;
        case "avatar":     return avatarC;
        case "action":     return actionC;
        default:           return stubC;   // "stub" or anything unrecognised
        }
    }

    Component { id: clockC;      Clock { compact: slot.entry.compact === true } }
    Component { id: workspacesC; Workspaces { screenName: slot.screenName } }
    Component { id: systemC;     SystemModule {} }
    Component { id: sysTempC;    SysTemp {} }
    Component { id: networkC;    Network {} }
    Component { id: volumeC;     VolumeBluetooth {} }
    Component { id: avatarC;     Avatar {} }
    Component {
        id: actionC
        LaunchButton {
            icon: slot.entry.icon || ""
            colorName: slot.entry.color || "surface"
            command: slot.entry.command || ""
        }
    }
    Component {
        id: stubC
        StubPill {
            icon: slot.entry.icon || ""
            label: slot.entry.label || ""
            colorName: slot.entry.color || "surface"
            dashed: slot.entry.dashed === true
        }
    }
}
