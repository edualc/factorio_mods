-- Safe-zone overlay. Draws a semi-transparent green circle (radius = LAMP_BLOCK_RADIUS
-- from horde.lua) around every powered lamp near each player character, showing
-- exactly which areas are protected from zombie night-trickle spawning.
-- Toggled on/off via the "zomtorio-safe-zones" shortcut. Refreshes every
-- REFRESH_PERIOD ticks so power-loss / new lamps are reflected automatically.

local planets = require("lib.planets")
local util    = require("lib.util")

local safezones = {}

local LAMP_RADIUS    = 12      -- matches LAMP_BLOCK_RADIUS in horde.lua
local SCAN_RADIUS    = 160     -- tiles from each player to search for lamps
local MAX_LAMPS      = 200     -- cap on rendered circles per refresh
local REFRESH_PERIOD = 5 * 60  -- re-scan every 5 seconds of game time

local function state()
  storage.zomtorio = storage.zomtorio or {}
  storage.zomtorio.safezones = storage.zomtorio.safezones or { renders = {}, last_refresh = 0 }
  return storage.zomtorio.safezones
end

local function clear_renders(s)
  for _, r in pairs(s.renders) do
    if r and r.valid then pcall(function() r.destroy() end) end
  end
  s.renders = {}
end

local function any_player_has_overlay()
  for _, player in pairs(game.players) do
    if player.valid and player.is_shortcut_toggled("zomtorio-safe-zones") then
      return true
    end
  end
  return false
end

local function refresh_overlay(surface)
  local s = state()
  clear_renders(s)
  local seen  = {}
  local count = 0
  for _, player in pairs(game.players) do
    if not (player.valid and player.character and player.character.valid) then goto next_player end
    if player.character.surface ~= surface then goto next_player end
    local lamps = surface.find_entities_filtered{
      type = "lamp", position = player.character.position, radius = SCAN_RADIUS,
    }
    for _, lamp in ipairs(lamps) do
      if count >= MAX_LAMPS then break end
      if lamp.valid and lamp.energy > 0 and not seen[lamp.unit_number] then
        seen[lamp.unit_number] = true
        local ok, r = pcall(function()
          return rendering.draw_circle{
            color   = { r = 0.1, g = 0.9, b = 0.1, a = 0.18 },
            radius  = LAMP_RADIUS,
            width   = 1,
            filled  = true,
            target  = lamp.position,
            surface = surface,
          }
        end)
        if ok and r then
          s.renders[#s.renders + 1] = r
          count = count + 1
        end
      end
    end
    ::next_player::
  end
  s.last_refresh = game.tick
end

function safezones.on_toggle(event)
  if event.prototype_name ~= "zomtorio-safe-zones" then return end
  local player = game.players[event.player_index]
  if not (player and player.valid) then return end
  local now_on = not player.is_shortcut_toggled("zomtorio-safe-zones")
  player.set_shortcut_toggled("zomtorio-safe-zones", now_on)
  if now_on then
    if player.surface and planets.is_active(player.surface) then
      refresh_overlay(player.surface)
    end
  else
    if not any_player_has_overlay() then
      clear_renders(state())
    end
  end
end

function safezones.on_tick(event)
  if not any_player_has_overlay() then return end
  local s = state()
  if (event.tick - s.last_refresh) < REFRESH_PERIOD then return end
  local surface = game.surfaces[util.HOME_SURFACE]
  if surface and surface.valid and planets.is_active(surface) then
    refresh_overlay(surface)
  end
end

function safezones.on_init()
  state()
end

return safezones
