-- Small shared helpers used across the runtime modules.

local util = {}

-- v1 is Nauvis-only (R-SCOPE-1). Every gameplay hook guards on this so other
-- planets are untouched and per-planet mechanics can slot in later.
util.HOME_SURFACE = "nauvis"

function util.is_active_surface(surface)
  return surface and surface.valid and surface.name == util.HOME_SURFACE
end

-- The infected force is vanilla's "enemy" force. Centralised so intent reads
-- clearly and a future split (e.g. a dedicated zombie force) is a one-line change.
util.ENEMY_FORCE = "enemy"

function util.is_enemy_force(force)
  return force and force.valid and force.name == util.ENEMY_FORCE
end

-- Tiles zombies cannot stand on. Name-based to stay compatible with Factorio 2.x
-- (LuaTilePrototype has no walkable_speed_modifier in 2.x).
util.WATER_TILES = {
  ["water"]           = true,
  ["deepwater"]       = true,
  ["water-green"]     = true,
  ["deepwater-green"] = true,
  ["water-shallow"]   = true,
  ["water-mud"]       = true,
  ["out-of-map"]      = true,
}

--- True if `pos` is on a tile zombies can't walk on (water, void, out-of-map).
--- An invalid LuaTile (ungenerated chunk) is treated as unwalkable so callers
--- like find_land_near keep scanning rather than accepting a void position.
function util.is_water_tile(surface, pos)
  local tile = surface.get_tile(pos)
  if not (tile and tile.valid) then return true end
  return util.WATER_TILES[tile.name] == true
end

--- Scan outward from `pos` in eight directions (cardinal + diagonal) for the
--- first non-water tile within `radius` tiles, stepping by `step` (default 4).
--- Cheap: only get_tile calls, no entity search.
local SCAN_DIRS = { {1,0},{-1,0},{0,1},{0,-1},{1,1},{-1,1},{1,-1},{-1,-1} }
function util.find_land_near(surface, pos, radius, step)
  step = step or 4
  for dist = step, radius, step do
    for _, d in ipairs(SCAN_DIRS) do
      local p = { x = pos.x + d[1] * dist, y = pos.y + d[2] * dist }
      if not util.is_water_tile(surface, p) then return p end
    end
  end
  return nil
end

return util
