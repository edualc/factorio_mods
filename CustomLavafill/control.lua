-- Belt-and-suspenders for placing lavafill on resource-covered tiles.
--
-- place_as_tile.condition now lists "resource" (see prototypes/item.lua), which
-- should be enough on its own, but resource entities are destructible objects,
-- not just a collision layer - if anything about that placement path still
-- rejects the tile in practice, the fix is to remove the obstacle before the
-- engine's own placement check runs rather than debug the condition further.
-- on_pre_build fires before the built-in tile placement check, so destroying
-- any resource entity here lets the normal place_as_tile placement succeed
-- immediately afterward in the same tick.
local LAVAFILL_ITEM = "lavafill"

script.on_event(defines.events.on_pre_build, function(event)
    local player = game.get_player(event.player_index)
    if not player then return end

    local cursor = player.cursor_stack
    if not (cursor and cursor.valid_for_read and cursor.name == LAVAFILL_ITEM) then return end

    local surface = player.surface
    local area = {
        {event.position.x - 0.5, event.position.y - 0.5},
        {event.position.x + 0.5, event.position.y + 0.5},
    }
    for _, resource in pairs(surface.find_entities_filtered({area = area, type = "resource"})) do
        resource.destroy()
    end
end)
