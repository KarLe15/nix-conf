-- Workspace sessions: one session is a complete instance of the 3x3 workspace
-- grid, so several projects can each own the whole grid and switching moves all
-- monitors at once. See docs/HYPRLAND_SESSIONS.md.
--
--   workspace id = (session - 1) * band + slot
--
-- Session 1 is therefore ids 1-9 — the historical layout, unchanged.
--
-- The live `session` value lives here as a Lua local: the workspace binds are
-- bound to functions that call wsFor() at press time, so a session switch rebinds
-- nothing. State is in-memory only (S14) — a compositor restart returns to the
-- default session.
--
-- NOTE: `goto` is a reserved word in Lua 5.4, hence `switchTo`.

local d = require("data")

local M = {}

M.count   = d.sessions.count
M.band    = d.sessions.band
M.session = d.sessions.default

-- lastSlot[session][monitorName] = slot, so returning to a session restores each
-- screen to the workspace it was left on rather than a fixed one.
local lastSlot = {}

-- ---------------------------------------------------------------- id helpers

-- Absolute workspace id for a slot (1-9) in the current session.
function M.wsFor(slot)
  return (M.session - 1) * M.band + slot
end

-- Same, as the string the dispatchers expect.
function M.wsName(slot)
  return tostring(M.wsFor(slot))
end

-- Inverse: which session and slot does an absolute id belong to? Quickshell does
-- the same arithmetic to derive the session from the workspace it already tracks.
function M.sessionOf(id) return math.floor((id - 1) / M.band) + 1 end
function M.slotOf(id)    return ((id - 1) % M.band) + 1 end

-- The first slot configured for a monitor, used the first time a session is
-- entered and there is nothing remembered.
local function firstSlotFor(monitorName)
  for _, s in ipairs(d.slots) do
    if s.monitor == monitorName then return s.slot end
  end
  return 1
end

-- ------------------------------------------------------------- open sessions

-- A session is "open" when it holds at least one window (S13), so it drops out
-- of the cycle ring as soon as its last window closes. Special workspaces have
-- non-positive ids and are ignored.
function M.open()
  local seen, out = {}, {}
  for _, w in ipairs(hl.get_windows()) do
    local ws = w.workspace
    local id = ws and ws.id
    if id and id > 0 then
      local s = M.sessionOf(id)
      if not seen[s] then
        seen[s] = true
        out[#out + 1] = s
      end
    end
  end
  table.sort(out)
  return out
end

-- ---------------------------------------------------------------- switching

-- Record where each monitor is sitting, so coming back restores it.
local function remember()
  local mem = lastSlot[M.session] or {}
  for _, m in ipairs(hl.get_monitors()) do
    local ws = m.active_workspace
    if ws and ws.id and ws.id > 0 then
      mem[m.name] = M.slotOf(ws.id)
    end
  end
  lastSlot[M.session] = mem
end

local function notify()
  local open = table.concat(M.open(), " ")
  hl.notification.create({
    text     = "Session " .. M.session .. (open ~= "" and ("    open: " .. open) or ""),
    duration = 1200,
  })
end

-- Switch every monitor at once (S6). monitor:set_workspace() creates the
-- workspace if it does not exist, so a new session costs nothing until entered,
-- and only the focused monitor takes focus.
function M.switchTo(n)
  if type(n) ~= "number" or n < 1 or n > M.count then return end
  if n == M.session then return end

  remember()
  M.session = n

  local mem = lastSlot[n] or {}
  for _, m in ipairs(hl.get_monitors()) do
    local slot = mem[m.name] or firstSlotFor(m.name)
    -- NB: the bare selector, not a table. hl.dsp.window.move takes { workspace = … },
    -- but HLMonitor.set_workspace takes the selector directly (a string, number or
    -- workspace object). See workspaceSelectorFromLuaSelectorOrObject.
    m:set_workspace(M.wsName(slot))
  end

  notify()
end

-- Cycle through the open sessions. If the current one holds no windows it is not
-- in the ring, so jump to the first open session instead.
function M.cycle(dir)
  local open = M.open()
  if #open == 0 then return end

  local idx
  for i, s in ipairs(open) do
    if s == M.session then idx = i end
  end
  if not idx then
    M.switchTo(open[1])
    return
  end

  M.switchTo(open[((idx - 1 + dir) % #open) + 1])
end

-- ------------------------------------------------------------------- submap

-- Bound with submap_universal (S16), so this is the single escape from *any*
-- submap as well as the way into this one — it is structurally impossible to be
-- stuck in a submap with no exit.
function M.toggleSubmap()
  local cur = hl.get_current_submap()
  if cur ~= nil and cur ~= "" then
    -- "reset" (or an empty string) is what clears the submap; there is no submap
    -- named "default" and asking for one raises a runtime error.
    -- See Actions::setSubmap in src/config/shared/actions/ConfigActions.cpp.
    hl.dispatch(hl.dsp.submap("reset"))
  else
    hl.dispatch(hl.dsp.submap("session"))
  end
end

return M
