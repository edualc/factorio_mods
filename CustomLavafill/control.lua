-- Belt-and-suspenders for placing lavafill on resource-covered tiles.
--
-- place_as_tile.condition now lists "resource" (see prototypes/item.lua), which
-- should be enough on its own, but resource entities are destructible objects,
-- not just a collision layer - if anything about that placement path still
-- rejects the tile in practice, the fix is to remove the obstacle before the
-- engine's own placement check runs rather than debug the condition further.
--
-- Two placement paths need covering:
--   1. Player places lavafill directly (no ghost stage) - on_pre_build fires
--      before the engine's own tile placement check, so destroying the
--      resource here lets placement succeed immediately afterward.
--   2. Blueprint / construction-robot placement always goes through a
--      tile-ghost first - robots have no "pre-build" hook of their own, so
--      the resource is cleared as soon as the ghost is created instead. By
--      the time a robot (or a player finishing the ghost by hand) actually
--      builds it, the tile is already clear.
local LAVAFILL_ITEM = "lavafill"
local LAVAFILL_TILE = "lava"

local function clear_resources_in_area(surface, position)
    local area = {
        {position.x - 0.5, position.y - 0.5},
        {position.x + 0.5, position.y + 0.5},
    }
    for _, resource in pairs(surface.find_entities_filtered({area = area, type = "resource"})) do
        resource.destroy()
    end
end

script.on_event(defines.events.on_pre_build, function(event)
    local player = game.get_player(event.player_index)
    if not player then return end

    local cursor = player.cursor_stack
    if not (cursor and cursor.valid_for_read and cursor.name == LAVAFILL_ITEM) then return end

    clear_resources_in_area(player.surface, event.position)
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
