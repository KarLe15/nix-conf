import QtQuick
import Quickshell

// Stage 2 entry point — one solid "Screen Bars" top bar per connected monitor.
// Colors/fonts/metrics come from the generated Theme singleton; the per-monitor
// workspace layout comes from the generated Config singleton. Live workspace and
// system state is read at runtime (Hyprland IPC + small pollers). Each surface is
// split into its own component under widgets/ so later stages can grow it.
ShellRoot {
    Variants {
        // One Bar (PanelWindow) per screen — mirrors the 3-monitor desktop layout.
        model: Quickshell.screens

        Bar {}
    }
}
