import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Phase 1 scaffold (docs/NOTIFICATIONS.md): the notification server, receiving and
// logging, drawing nothing.
//
// This instance is NOT a systemd unit and is not meant to reach the real session bus
// yet — swaync still owns org.freedesktop.Notifications and keeps serving real
// notifications. Run it through the `quickshell-notify-dev` wrapper, which starts a
// throwaway bus with dbus-run-session where the name is free (D3). The unit, and the
// flag day that disables swaync, arrive at phase 7.
ShellRoot {
    NotificationServer {
        id: server

        // Survives a QML reload within this process. It does nothing across a
        // process restart — that is what D1's separate unit and D2's history are
        // for, and neither exists yet.
        keepOnReload: true

        // Every capability stays at its Quickshell default for now. Each one is a
        // promise to sending applications and gets flipped in the same commit that
        // implements its rendering (D6); nothing renders yet.

        // Without `tracked = true` the server discards the notification as soon as
        // this handler returns and `trackedNotifications` stays empty.
        //
        // The logged shape is deliberately the D2 history record, so phase 3 changes
        // the sink rather than rewriting this. It is also how the real appName and
        // summary of each application are discovered — which is what the D5 `unless`
        // patterns have to match.
        onNotification: notification => {
            notification.tracked = true;
            console.log(JSON.stringify({
                id:           notification.id,
                app:          notification.appName,
                desktopEntry: notification.desktopEntry,
                summary:      notification.summary,
                body:         notification.body,
                urgency:      NotificationUrgency.toString(notification.urgency),
                transient:    notification.transient,
                resident:     notification.resident,
                actions:      notification.actions.map(a => a.identifier),
                hints:        Object.keys(notification.hints)
            }));
        }
    }
}
