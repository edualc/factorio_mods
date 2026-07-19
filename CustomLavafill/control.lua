-- Placing lavafill on resource-covered tiles.
--
-- place_as_tile.condition lists "resource" (see prototypes/item.lua), which
-- should be enough on its own, but in practice it still isn't: on_pre_build
-- fires before the engine resolves the *current* build attempt, so whether
-- this exact click can place a tile already appears to be decided by the
-- time the event handler runs. Destroying the resource there only clears the
-- way for the *next* click on the same tile, not the one in progress.
--
-- Two placement paths need covering:
--   1. Player places lavafill directly (no ghost stage): since we can't
--      trust the native place_as_tile follow-up to see our change in time,
--      place the tile ourselves via LuaSurface.set_tiles (which also drops
--      any colliding entity on its own) and consume the item by hand,
--      instead of destroying the resource and hoping the built-in system
--      picks it up afterward.
--   2. Blueprint / construction-robot placement always goes through a
--      tile-ghost first, and the robot's actual build happens on a later
--      tick - by then the resource we destroy at ghost-creation time is long
--      gone, so the native placement resolves normally with no timing issue.
local LAVAFILL_ITEM = "lavafill"
local LAVAFILL_TILE = "lava"

local function find_resources_in_area(surface, position)
    local area = {
        {position.x - 0.5, position.y - 0.5},
        {position.x + 0.5, position.y + 0.5},
    }
    return surface.find_entities_filtered({area = area, type = "resource"})
end

local function clear_resources_in_area(surface, position)
    for _, resource in pairs(find_resources_in_area(surface, position)) do
        resource.destroy()
    end
end

script.on_event(defines.events.on_pre_build, function(event)
    local player = game.get_player(event.player_index)
    if not player then return end

    local cursor = player.cursor_stack
    if not (cursor and cursor.valid_for_read and cursor.name == LAVAFILL_ITEM) then return end

    local surface = player.surface
    local resources = find_resources_in_area(surface, event.position)
    if #resources == 0 then return end -- nothing blocking; let native placement handle it as usual

    for _, resource in pairs(resources) do
        resource.destroy()
    end

    local tile_position = {x = math.floor(event.position.x), y = math.floor(event.position.y)}
    surface.set_tiles({{name = LAVAFILL_TILE, position = tile_position}}, true, true, true, true)
    cursor.count = cursor.count - 1
end)

local function on_tile_ghost_built(event)
    local entity = event.entity
    if not (entity and entity.valid and entity.type == "tile-ghost") then return end
    if entity.ghost_name ~= LAVAFILL_TILE then return end

    clear_resources_in_area(entity.surface, entity.position)
end

local TILE_GHOST_FILTER = {{filter = "type", type = "tile-ghost"}}
script.on_event(defines.events.on_built_entity, on_tile_ghost_built, TILE_GHOST_FILTER)
script.on_event(defines.events.on_robot_built_entity, on_tile_ghost_built, TILE_GHOST_FILTER)
script.on_event(defines.events.script_raised_built, on_tile_ghost_built, TILE_GHOST_FILTER)
script.on_event(defines.events.script_raised_revive, on_tile_ghost_built, TILE_GHOST_FILTER)
if defines.events.on_space_platform_built_entity then
    script.on_event(defines.events.on_space_platform_built_entity, on_tile_ghost_built, TILE_GHOST_FILTER)
end
