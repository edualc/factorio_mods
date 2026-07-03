-- Safe zone overlay. Two protection rules visualised (both match horde.lua is_safe_spawn):
--   GREEN circles = powered lamp zones (radius 12, one circle per lamp)
--   CYAN circles  = concrete buffer zones (radius 16, one circle per 8×8 tile cell)
-- Toggle button lives in player.gui.top (mod-gui flow, top-right corner).

local planets  = require("lib.planets")
local util     = require("lib.util")
local mod_gui  = require("mod-gui")

local safezones = {}

local LAMP_RADIUS     = 12  -- horde.lua LAMP_BLOCK_RADIUS
local CONCRETE_BUFFER = 16  -- horde.lua SAFE_TILE_BUFFER
local CONCRETE_CELL   = 8   -- group concrete tiles into N×N cells to limit circles
local SCAN_RADIUS     = 160
local REFRESH_PERIOD  = 5 * 60

-- Concrete tile name list, built once at load time (same logic as horde.lua).
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
    storage.zomtorio.safezones = { renders = {}, last_refresh = 0, enabled = {} }
  elseif not storage.zomtorio.safezones.enabled then
    storage.zomtorio.safezones.enabled = {}
  end
  return storage.zomtorio.safezones
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

-- Draws a filled + outlined circle pair. Low fill alpha, visible border.
local function add_circle(renders, surface, pos, radius, r, g, b)
  local ok1, c1 = pcall(rendering.draw_circle, {
    color = { r=r, g=g, b=b, a=0.06 }, radius = radius,
    width = 1, filled = true, target = pos, surface = surface,
  })
  if ok1 and c1 then renders[#renders + 1] = c1 end
  local ok2, c2 = pcall(rendering.draw_circle, {
    color = { r=r, g=g, b=b, a=0.55 }, radius = radius,
    width = 2, filled = false, target = pos, surface = surface,
  })
  if ok2 and c2 then renders[#renders + 1] = c2 end
end

local function refresh_overlay(surface)
  local s = state()
  clear_renders(s)
  local renders = {}

  local positions = {}
  for _, player in pairs(game.players) do
    if player.valid and player.character and player.character.valid
        and player.character.surface == surface then
      positions[#positions + 1] = player.character.position
    end
  end
  if #positions == 0 then
    s.renders = renders; s.last_refresh = game.tick; return
  end

  -- GREEN: one circle pair per powered lamp (no cap — deduplication via unit_number).
  local seen_lamps = {}
  for _, pos in ipairs(positions) do
    local lamps = surface.find_entities_filtered{
      type = "lamp", position = pos, radius = SCAN_RADIUS,
    }
    for _, lamp in ipairs(lamps) do
      if not (lamp.valid and lamp.energy > 0) then goto skip_lamp end
      if seen_lamps[lamp.unit_number] then goto skip_lamp end
      seen_lamps[lamp.unit_number] = true
      add_circle(renders, surface, lamp.position, LAMP_RADIUS, 0.15, 0.9, 0.15)
      ::skip_lamp::
    end
  end

  -- CYAN: one circle pair per occupied CONCRETE_CELL×CONCRETE_CELL grid cell.
  -- One find_tiles_filtered call per player covers the whole scan area efficiently;
  -- tiles are then bucketed into cells so a large concrete floor produces O(area/cell²)
  -- circles rather than one per tile.
  if #CONCRETE_NAMES > 0 then
    local seen_cells = {}
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
        if seen_cells[key] then goto skip_tile end
        seen_cells[key] = true
        local center = { x = cx + CONCRETE_CELL * 0.5, y = cy + CONCRETE_CELL * 0.5 }
        add_circle(renders, surface, center, CONCRETE_BUFFER, 0.1, 0.65, 0.9)
        ::skip_tile::
      end
    end
  end

  s.renders = renders
  s.last_refresh = game.tick
end

-- Ensures the toggle button exists in the mod-gui top-right flow.
local function ensure_button(player)
  if not (player.valid and player.gui and player.gui.top) then return end
  local flow = mod_gui.get_button_flow(player)
  if flow[BTN] then return end
  flow.add{
    type    = "sprite-button",
    name    = BTN,
    sprite  = "entity/small-lamp",
    tooltip = "Safe zone overlay\nGreen = powered lamp zones (radius 12)\nCyan = concrete buffer zones (radius 16)",
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
  if player and player.valid then
    ensure_button(player)
    -- Restore visual toggle state after reconnect.
    local s = state()
    set_button_state(player, s.enabled[player.index] or false)
  end
end

function safezones.on_gui_click(event)
  if not (event.element and event.element.valid) then return end
  if event.element.name ~= BTN then return end
  local player = game.players[event.player_index]
  if not (player and player.valid) then return end
  local s    = state()
  local on   = not (s.enabled[player.index])
  s.enabled[player.index] = on
  set_button_state(player, on)
  if on then
    if player.surface and planets.is_active(player.surface) then
      refresh_overlay(player.surface)
    end
  elseif not any_enabled(s) then
    clear_renders(s)
  end
end

function safezones.on_tick(event)
  local s = state()
  if not any_enabled(s) then return end
  if (event.tick - s.last_refresh) < REFRESH_PERIOD then return end
  local surface = game.surfaces[util.HOME_SURFACE]
  if surface and surface.valid and planets.is_active(surface) then
    refresh_overlay(surface)
  end
end

function safezones.on_init()
  local s = state()  -- ensure storage exists
  for _, player in pairs(game.players) do
    if player.valid then ensure_button(player) end
  end
end

return safezones
