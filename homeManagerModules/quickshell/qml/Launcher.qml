pragma Singleton
import Quickshell

// Every app the shell starts that is meant to outlive it goes through here.
//
// `Quickshell.execDetached` alone is not enough: it detaches from the *parent
// process*, but cgroup membership is inherited across fork, so the child stays in
// quickshell.service — where `KillMode=mixed` SIGKILLs it the next time a rebuild
// restarts the shell. `uwsm app` puts each one in its own scope under
// app-graphical.slice instead, the same treatment homeManagerModules/hyprland
// gives every keybind launch. See docs/QUICKSHELL-SHELL.md.
//
// Short-lived one-shots (swaync-client, hyprctl, cliphist) deliberately do not use
// this — they finish in milliseconds and own no window.
Singleton {
    // Run a shell command string. `sh -c` because the command may carry arguments
    // and quoting from the preset; `-a` then names the scope after the binary, or
    // every one of them would land as `app-sh-<id>.scope`.
    function app(command) {
        if (!command || command.trim() === "")
            return;
        const name = (command.trim().split(/\s+/)[0] || "app").split("/").pop();
        Quickshell.execDetached(["uwsm", "app", "-a", name, "--", "sh", "-c", command]);
    }

    // Launch a desktop entry by id — what DesktopEntry.id gives, with no .desktop
    // suffix. uwsm resolves the entry itself, so Terminal= and TryExec= still apply.
    function entry(id) {
        if (!id)
            return;
        Quickshell.execDetached(["uwsm", "app", "--", id + ".desktop"]);
    }
}
