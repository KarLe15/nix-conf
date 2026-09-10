-- Turns the generated data.lua bind records into hl.bind() calls.
--
-- This file is checked in and reviewable as Lua: Nix emits only data, so the
-- hl API surface lives here in one place. Adding a dispatcher means adding a
-- case below and naming it in the shortcuts preset — an unknown name raises a
-- Lua error identifying the bind, rather than silently producing nothing.
--
-- NOTE: the Lua API accepts and ignores unrecognised table fields, so every
-- field used here must be checked against src/config/lua/bindings/ in the
-- Hyprland source. See docs/HYPRLAND-LUA-MIGRATION.md.

local d = require("data")

local function dispatcher(b)
  local a = b.args or {}
  local k = b.dispatcher

  if k == "exec"                   then return hl.dsp.exec_cmd(a.cmd) end
  if k == "killactive"             then return hl.dsp.window.close() end
  if k == "forcekillactive"        then return hl.dsp.window.kill() end
  if k == "togglefloating"         then return hl.dsp.window.float({ action = "toggle" }) end
  if k == "fullscreen"             then return hl.dsp.window.fullscreen({ mode = a.mode, action = "toggle" }) end
  if k == "togglespecialworkspace" then return hl.dsp.workspace.toggle_special() end
  -- follow = false is Hyprland's "silent" move: the window goes, focus stays.
  if k == "movetoworkspace"        then return hl.dsp.window.move({ workspace = a.workspace, follow = a.follow }) end
  if k == "focus-workspace"        then return hl.dsp.focus({ workspace = a.workspace }) end
  if k == "focus-direction"        then return hl.dsp.focus({ direction = a.direction }) end
  if k == "move-direction"         then return hl.dsp.window.move({ direction = a.direction }) end
  if k == "resize"                 then return hl.dsp.window.resize({ x = a.x, y = a.y }) end
  if k == "window-resize-mouse"    then return hl.dsp.window.resize() end
  if k == "window-drag"            then return hl.dsp.window.drag() end
  if k == "submap-enter"           then return hl.dsp.submap(a.submap) end

  error(string.format("hyprland: unknown dispatcher %q for bind %q",
                      tostring(k), tostring(b.keys)))
end

local function bind(b)
  hl.bind(b.keys, dispatcher(b), b.opts)
end

for _, b in ipairs(d.binds) do
  bind(b)
end

-- Submaps: every bind naming a submap in the shortcuts preset is scoped here.
for name, binds in pairs(d.submaps or {}) do
  hl.define_submap(name, function()
    for _, b in ipairs(binds) do
      bind(b)
    end
  end)
end
