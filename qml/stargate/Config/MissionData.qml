pragma Singleton
import QtQuick

// Mission flavour for the two ambience screens — the DHD's address book and the
// E2PZ/MALP board. None of it is real machine state: the greeter runs as the
// `sddm` user with no network, no sensors and no session history, so this is set
// dressing and is written here rather than in a Nix preset precisely because it
// is content, not configuration.
//
// Hand-written, unlike its two neighbours in this directory. Edit freely.
//
// `color`/`tone` values are Theme palette names, resolved as Theme[name] at the
// use site so a theme flavor change carries through. Glyphs are Nerd Font
// codepoints.
QtObject {

    // ---- DHD · saved gate addresses ----------------------------------------
    readonly property var addresses: [
        { "name": "Abydos",   "code": "27 · 07 · 15 · 32 · 12 · 30 · 01", "state": "Stable",      "color": "green",  "note": "dernier contact 3 j" },
        { "name": "Chulak",   "code": "09 · 02 · 23 · 15 · 37 · 20 · 01", "state": "Stable",      "color": "green",  "note": "dernier contact 12 j" },
        { "name": "Dakara",   "code": "29 · 03 · 06 · 09 · 12 · 16 · 01", "state": "Instable",    "color": "yellow", "note": "fluctuations sous-spatiales" },
        { "name": "Tollana",  "code": "04 · 29 · 08 · 22 · 18 · 25 · 01", "state": "Perdue",      "color": "red",    "note": "aucune réponse" },
        { "name": "Atlantis", "code": "8 chevrons · Pégase",              "state": "E2PZ requis", "color": "mauve",  "note": "puissance insuffisante" }
    ]

    // ---- DHD · last login ---------------------------------------------------
    readonly property var lastLogin: ({
        "who": "rukmini · Hyprland",
        "when": "hier 23:41 · durée 4 h 12"
    })

    // ---- E2PZ · zero point modules -----------------------------------------
    // Facet colours are the crystal's own orange, deliberately outside the
    // Catppuccin palette: a ZPM does not belong to the desktop's colour scheme.
    readonly property var zpmTones: ({
        "full": {
            "facetDeep": "#b8552f", "facetDark": "#d9733f",
            "facetMid":  "#f0995f", "facetLight": "#fbc38a",
            "core": "#fff4d6", "coreAlpha": 0.95,
            "halo": "#f5a97f", "haloAlpha": 0.38,
            "arch": "#e98a52", "green": "#2f9a63", "red": "#d8465c",
            "base": "#e5704f", "tone": "yellow"
        },
        "low": {
            "facetDeep": "#5a3226", "facetDark": "#74412d",
            "facetMid":  "#8e5536", "facetLight": "#a86b45",
            "core": "#fac896", "coreAlpha": 0.40,
            "halo": "#f5a97f", "haloAlpha": 0.10,
            "arch": "#8a5033", "green": "#2d5a44", "red": "#7a3440",
            "base": "#834834", "tone": "peach"
        },
        "dead": {
            "facetDeep": "#24273a", "facetDark": "#2a2b3d",
            "facetMid":  "#363a4f", "facetLight": "#494d64",
            "core": "#000000", "coreAlpha": 0.0,
            "halo": "#000000", "haloAlpha": 0.0,
            "arch": "#363a4f", "green": "#2c3d3f", "red": "#3d3043",
            "base": "#363a4f", "tone": "surface2"
        }
    })

    readonly property var zpms: [
        { "label": "Module 1", "pct": "68 %", "tone": "full" },
        { "label": "Module 2", "pct": "9 %",  "tone": "low" },
        { "label": "Épuisé",   "pct": "0 %",  "tone": "dead" }
    ]

    readonly property string zpmActive: "1 / 3 actif"
    readonly property string zpmAutonomyLead: "Autonomie estimée au rythme actuel : "
    readonly property string zpmAutonomy: "11 ans 4 mois"

    // ---- MALP · environment readout ----------------------------------------
    // `fill` is the bar's fraction, 0..1.
    readonly property var telemetry: [
        { "icon": "\uf21e", "label": "Saturation en oxygène · O₂", "value": "20,8 %",     "fill": 0.87, "color": "teal" },
        { "icon": "\uf2c9", "label": "Température ambiante",       "value": "−12 °C",     "fill": 0.28, "color": "blue" },
        { "icon": "\uf0e4", "label": "Pression atmosphérique",     "value": "0,94 atm",   "fill": 0.72, "color": "lavender" },
        { "icon": "\uf185", "label": "Radiations · naquadah",      "value": "0,3 mSv/h",  "fill": 0.12, "color": "green" },
        { "icon": "\uf043", "label": "Humidité relative",          "value": "34 %",       "fill": 0.34, "color": "mauve" },
        { "icon": "\uf012", "label": "Signal MALP · P3X-984",      "value": "−71 dBm",    "fill": 0.58, "color": "peach" }
    ]

    readonly property string telemetryState: "nominal"

    readonly property var cards: [
        { "kicker": "Iris",         "icon": "\uf132", "value": "Fermé",       "color": "blue" },
        { "kicker": "Alerte · SGC", "icon": "\uf058", "value": "Niveau vert", "color": "green" }
    ]

    // ---- Headings -----------------------------------------------------------
    readonly property string autonomyIcon: "\uf0e7"
}
