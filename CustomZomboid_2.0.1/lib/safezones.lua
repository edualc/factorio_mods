-- Safe zone overlay. Visualises both horde.lua is_safe_spawn() rules:
--   GREEN outlines = powered lamp zones (radius 12 per lamp)
--   CYAN outlines  = concrete buffer zones (radius 16 per 8×8 boundary cell)
--
-- No filled circles: overlapping fills stack alpha and wash out large bases.
-- Concrete shows only boundary cells (cells adjacent to non-concrete) so a
-- solid floor produces a perimeter ring rather than thousands of interior circles.
--
-- Refreshes when a player moves > MOVE_THRESHOLD tiles or after REFRESH_PERIOD.
-- Toggle button in mod-gui top-right flow (biter icon).

local planets  = require("lib.planets")
local util     = require("lib.util")
local mod_gui  = require("mod-gui")

local safezones = {}

local LAMP_RADIUS      = 12    -- horde.lua LAMP_BLOCK_RADIUS
local CONCRETE_BUFFER  = 16    -- horde.lua SAFE_TILE_BUFFER
local CONCRETE_CELL    = 8     -- group concrete tiles into N×N cells
local SCAN_RADIUS      = 160
local REFRESH_PERIOD   = 5 * 60
local MOVE_THRESHOLD   = 50    -- tiles before a position-triggered refresh fires

local CONCRETE_NAMES = {}
for name in pairs(prototypes.tile) do
  if name:find("concrete", 1, true) then
    CONCRETE_NAMES[#CONCRETE_NAMES + 1] = name
  end
end

local BTN = "zomtorio-safe-zones-btn"

local function state()
  storage.zomtorio = storage.zomtorio or {}
  local sz = storage.zomtorio.safezones
  if not sz then
    storage.zomtorio.safezones = {
      renders = {}, last_refresh = 0, enabled = {}, last_positions = {},
    }
    sz = storage.zomtorio.safezones
  end
  if not sz.enabled        then sz.enabled = {}        end
  if not sz.last_positions then sz.last_positions = {} end
  return sz
end

local function clear_renders(s)
  for _, r in pairs(s.renders) do
    if r and r.valid then pcall(function() r.destroy() end) end
  end
  s.renders = {}
end

local function any_enabled(s)
  for _, v in pairs(s.enabled) do
    if v then return true end
  end
  return false
end

local function add_outline(renders, surface, pos, radius, r, g, b, a)
  local ok, c = pcall(rendering.draw_circle, {
    color = {r=r, g=g, b=b, a=a}, radius = radius,
    width = 2, filled = false, target = pos, surface = surface,
  })
  if ok and c then renders[#renders + 1] = c end
end

local function refresh_overlay(surface, s)
  clear_renders(s)
  local renders = {}

  local positions = {}
  for _, player in pairs(game.players) do
    if player.valid and player.character and player.character.valid
        and player.character.surface == surface then
      local pos = player.character.position
      positions[#positions + 1] = pos
      s.last_positions[player.index] = { x = pos.x, y = pos.y }
    end
  end
  if #positions == 0 then
    s.renders = renders; s.last_refresh = game.tick; return
  end

  -- GREEN: outline circle per powered lamp (no cap — deduped by unit_number).
  local seen_lamps = {}
  for _, pos in ipairs(positions) do
    local lamps = surface.find_entities_filtered{
      type = "lamp", position = pos, radius = SCAN_RADIUS,
    }
    for _, lamp in ipairs(lamps) do
      if not (lamp.valid and lamp.energy > 0) then goto skip_lamp end
      if seen_lamps[lamp.unit_number] then goto skip_lamp end
      seen_lamps[lamp.unit_number] = true
      add_outline(renders, surface, lamp.position, LAMP_RADIUS, 0.1, 0.9, 0.1, 0.70)
      ::skip_lamp::
    end
  end

  -- CYAN: outline circles for concrete boundary cells only.
  -- Building all_cells first, then drawing only cells where at least one
  -- 4-neighbour is absent — avoids interior-fill stacking on large floors.
  if #CONCRETE_NAMES > 0 then
    local all_cells = {}
    for _, pos in ipairs(positions) do
      local area = {
        { pos.x - SCAN_RADIUS, pos.y - SCAN_RADIUS },
        { pos.x + SCAN_RADIUS, pos.y + SCAN_RADIUS },
      }
      local tiles = surface.find_tiles_filtered{ area = area, name = CONCRETE_NAMES }
      for _, tile in ipairs(tiles) do
        local tp = tile.position
        local cx = math.floor(tp.x / CONCRETE_CELL) * CONCRETE_CELL
        local cy = math.floor(tp.y / CONCRETE_CELL) * CONCRETE_CELL
        local key = cx .. "," .. cy
        if not all_cells[key] then
          all_cells[key] = {
            center = { x = cx + CONCRETE_CELL * 0.5, y = cy + CONCRETE_CELL * 0.5 },
            cx = cx, cy = cy,
          }
        end
      end
    end

    for _, cell in pairs(all_cells) do
      local cx, cy = cell.cx, cell.cy
      local on_edge = (
        not all_cells[(cx + CONCRETE_CELL) .. "," .. cy] or
        not all_cells[(cx - CONCRETE_CELL) .. "," .. cy] or
        not all_cells[cx .. "," .. (cy + CONCRETE_CELL)] or
        not all_cells[cx .. "," .. (cy - CONCRETE_CELL)]
      )
      if on_edge then
        add_outline(renders, surface, cell.center, CONCRETE_BUFFER, 0.1, 0.7, 0.9, 0.65)
      end
    end
  end

  s.renders = renders
  s.last_refresh = game.tick
end

-- True if any enabled player has moved more than MOVE_THRESHOLD tiles since last refresh.
local function players_moved(s)
  for _, player in pairs(game.players) do
    if not (s.enabled[player.index] and player.valid
        and player.character and player.character.valid) then goto next end
    local pos  = player.character.position
    local last = s.last_positions[player.index]
    if not last then return true end
    local dx, dy = pos.x - last.x, pos.y - last.y
    if dx*dx + dy*dy > MOVE_THRESHOLD * MOVE_THRESHOLD then return true end
    ::next::
  end
  return false
end

local function ensure_button(player)
  if not (player.valid and player.gui and player.gui.top) then return end
  local flow = mod_gui.get_button_flow(player)
  if flow[BTN] then return end
  flow.add{
    type    = "sprite-button",
    name    = BTN,
    sprite  = "zomtorio-safezones-icon",
    tooltip = "Safe zone overlay\nGreen  = powered lamp zones (radius 12)\nCyan   = concrete buffer zones (radius 16)",
    style   = mod_gui.button_style,
    toggled = false,
  }
end

local function set_button_state(player, active)
  local flow = mod_gui.get_button_flow(player)
  local btn  = flow and flow[BTN]
  if btn then btn.toggled = active end
end

function safezones.on_player_created(event)
  local player = game.players[event.player_index]
  if player and player.valid then ensure_button(player) end
end

function safezones.on_player_joined(event)
  local player = game.players[event.player_index]
  if not (player and player.valid) then return end
  ensure_button(player)
  local s = state()
  set_button_state(player, s.enabled[player.index] or false)
end

function safezones.on_gui_click(event)
  if not (event.element and event.element.valid) then return end
  if event.element.name ~= BTN then return end
  local player = game.players[event.player_index]
  if not (player and player.valid) then return end
  local s  = state()
  local on = not (s.enabled[player.index])
  s.enabled[player.index] = on
  set_button_state(player, on)
  if on then
    if player.surface and planets.is_active(player.surface) then
      refresh_overlay(player.surface, s)
    end
  elseif not any_enabled(s) then
    clear_renders(s)
  end
end

function safezones.on_tick(event)
  local s = state()
  if not any_enabled(s) then return end
  local due = (event.tick - s.last_refresh) >= REFRESH_PERIOD
  if not due and not players_moved(s) then return end
  local surface = game.surfaces[util.HOME_SURFACE]
  if surface and surface.valid and planets.is_active(surface) then
    refresh_overlay(surface, s)
  end
end

function safezones.on_init()
  local s = state()
  for _, player in pairs(game.players) do
    if player.valid then ensure_button(player) end
  end
end

return safezones
