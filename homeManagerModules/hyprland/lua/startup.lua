-- Startup commands, from the merged autostart lists of the defaults, launchers,
-- developpement, themes and cursors presets.
--
-- There is no hl.exec_once() in the Lua API despite it being documented; the
-- supported form is a hyprland.start event handler, which is also what Home
-- Manager and Stylix use internally.

local d = require("data")

hl.on("hyprland.start", function()
  for _, cmd in ipairs(d.startup) do
    hl.exec_cmd(cmd)
  end
end)
