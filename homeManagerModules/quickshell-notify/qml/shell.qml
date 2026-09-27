import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "root:/"
import "root:/widgets"

// The notification server (docs/NOTIFICATIONS.md).
//
// Phase 2: it receives, and it draws the toast stack. It still stores nothing, has
// no systemd unit, and does not reach the real session bus — swaync keeps serving
// real notifications until the phase 8 flag day. Run it through the
// `quickshell-notify-dev` wrapper, which starts a throwaway bus where the name is
// free (D3).
ShellRoot {
    NotificationServer {
        id: server

        // Survives a QML reload within this process. It does nothing across a
        // process restart — that is what D1's separate unit and D2's history are
        // for, and neither exists yet.
        keepOnReload: true

        // Advertised capabilities (D6): a flag is turned on in the same commit that
        // implements its rendering, never before. Applications read these from
        // GetCapabilities() and genuinely withhold what is not advertised — an
        // un-advertised action is dropped by the sender, silently.
        //
        // Live now, because the toast renders them: the app icon, and the action
        // buttons the expanded card shows.
        imageSupported: true
        actionsSupported: true
        actionIconsSupported: true

        // Still off. inlineReply waits for the chat-style card (4a) that draws the
        // reply field; persistence waits for the history (phase 3). Advertising
        // either now would be a promise this server does not yet keep.
        inlineReplySupported: false
        persistenceSupported: false

        // Without `tracked = true` the server discards the notification as soon as
        // this handler returns and `trackedNotifications` stays empty.
        onNotification: notification => {
            notification.tracked = true;
            Toasts.add(notification);
            console.log(JSON.stringify({
                id:           notification.id,
                app:          notification.appName,
                desktopEntry: notification.desktopEntry,
                summary:      notification.summary,
                urgency:      NotificationUrgency.toString(notification.urgency),
                actions:      notification.actions.map(a => a.identifier),
                hints:        Object.keys(notification.hints)
            }));
        }
    }

    // One stack per screen; only the one matching Config.screen draws (4a).
    Variants {
        model: Quickshell.screens
        ToastStack { }
    }
}
