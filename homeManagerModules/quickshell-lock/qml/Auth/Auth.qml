pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import "../Config"

// Everything the lock knows: whether the session is locked, how far the dial has
// got, and what PAM last said. The screens read it; nothing else writes it.
//
// Kept in one place rather than threaded through the surfaces because all three
// screens want the same answer and this process owns all of them.
QtObject {
    id: auth

    // ---- Session state ------------------------------------------------------
    // WlSessionLock binds to this. Nothing else may set it: locking is a one-way
    // door until PAM says otherwise.
    property bool locked: false

    // Set by Main when STARGATE_PREVIEW is in the environment — the screens render
    // in ordinary windows and nothing ever grabs the session.
    property bool previewing: false

    // ---- Dial state ---------------------------------------------------------
    property string password: ""
    property bool failed: false
    // Chevrons engaged when the password was refused, captured before the field is
    // cleared so the gate can show how far the dial got.
    property int failedAt: 0
    // Enter has been pressed and PAM has not answered: the seventh chevron reads as
    // engaged while the machine thinks.
    property bool verifying: false
    // Authenticated. Held briefly so the vortex is actually visible — the one place
    // in this design where it can be, since the SDDM greeter's views close instantly.
    property bool vortex: false
    property string info: ""

    readonly property string user: String(Quickshell.env("USER") || "")

    // Quickshell has no hostname API and the service environment carries no
    // HOSTNAME, so it comes off disk. Preloaded and blocking: it is 20 bytes and
    // the gate wants it on the first frame.
    property FileView hostFile: FileView {
        path: "/etc/hostname"
        preload: true
        blockLoading: true
    }

    readonly property string host: auth.hostFile.text().trim()

    // ---- Caps lock ----------------------------------------------------------
    // Quickshell exposes no keyboard LED state, so this reads the LEDs directly.
    // Polled only while the lock is up, and silent if the glob matches nothing —
    // a wrong caps indicator is worse than none.
    property bool capsOn: false

    function lock() {
        if (auth.locked)
            return
        auth.reset()
        auth.locked = true
    }

    function reset() {
        auth.password = ""
        auth.failed = false
        auth.failedAt = 0
        auth.verifying = false
        auth.info = ""
        if (auth.pam.active)
            auth.pam.abort()
    }

    function submit() {
        if (auth.password.length === 0 || auth.verifying || auth.vortex)
            return
        auth.failed = false
        auth.info = ""
        auth.verifying = true

        // PAM drives the conversation: it asks for a response, we answer. If it has
        // already asked, answer now; otherwise open a transaction and answer when
        // the prompt arrives.
        if (auth._promptPending) {
            auth._promptPending = false
            auth.pam.respond(auth.password)
        } else if (!auth.pam.active && !auth.pam.start()) {
            auth.verifying = false
            auth.failed = true
            auth.info = "Authentification indisponible"
        }
    }

    // True when PAM has asked for a response and the user has not pressed Enter yet.
    property bool _promptPending: false

    property PamContext pam: PamContext {
        config: Config.lock.pamService
        user: auth.user

        // pamMessage carries no arguments — the conversation state is on the
        // context itself, so it is read rather than received.
        onPamMessage: {
            if (auth.pam.responseRequired) {
                if (auth.verifying)
                    auth.pam.respond(auth.password)
                else
                    auth._promptPending = true
                return
            }
            // A message with nothing to answer is PAM talking: an expired account, a
            // lockout notice. Worth more than the generic refusal, so it is kept.
            if (auth.pam.message.length > 0)
                auth.info = auth.pam.message
        }

        onCompleted: function (result) {
            auth.verifying = false
            auth._promptPending = false

            if (result === PamResult.Success) {
                auth.vortex = true
                auth.unlockTimer.start()
                return
            }

            auth.failedAt = Math.min(auth.password.length, 7)
            auth.password = ""
            auth.failed = true
        }

        onError: function (error) {
            auth.verifying = false
            auth._promptPending = false
            auth.failed = true
            auth.info = "PAM : " + PamError.toString(error)
        }
    }

    // The vortex holds for a beat before the surfaces go, so the kawoosh is seen.
    property Timer unlockTimer: Timer {
        interval: Config.lock.unlockDelayMs
        onTriggered: {
            auth.locked = false
            auth.vortex = false
            auth.reset()
        }
    }

    property Timer capsTimer: Timer {
        interval: 500
        repeat: true
        running: auth.locked || auth.previewing
        triggeredOnStart: true
        onTriggered: auth.capsReader.running = true
    }

    property Process capsReader: Process {
        command: [ "sh", "-c", "cat " + Config.lock.capsLedGlob + " 2>/dev/null" ]
        stdout: StdioCollector {
            onStreamFinished: auth.capsOn = text.indexOf("1") >= 0
        }
    }
}
