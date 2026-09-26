-- Resources converted to infinite in data-final-fixes.lua carry this marker
-- minimum (vanilla infinite resources use much larger minimums), which lets
-- us tell them apart from resources that were already infinite in vanilla
local CONVERTED_MINIMUM = 1

local function is_converted_resource(entity)
  local prototype = entity.prototype
  return prototype.infinite_resource and prototype.minimum_resource_amount == CONVERTED_MINIMUM
end

-- Forces this entity's yield to a flat 100%, matching vanilla's constant
-- per-swing mining rate. Yield% scales with amount/normal, and a patch's
-- actual generated richness (tens to hundreds of thousands) is nowhere near
-- the shared `normal` placeholder set in data-final-fixes.lua, so pinning
-- `initial_amount` to the patch's own amount still left yield scaling wildly
-- per patch. Overwriting `amount` itself down to `normal` (also writable)
-- pins the ratio to exactly 1 regardless of which field the engine actually
-- reads as the live reference, and is safe to do on an already-placed entity
-- since it doesn't destroy/recreate it (mining drills keep their target)
local function pin_yield(entity)
  if entity.valid and is_converted_resource(entity) then
    local normal = entity.prototype.normal_resource_amount
    entity.amount = normal
    entity.initial_amount = normal
  end
end

local function pin_all_resources()
  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered{type = "resource"}) do
      pin_yield(entity)
    end
  end
end

-- New save, and mod added to (or updated on) an existing save
script.on_init(pin_all_resources)
script.on_configuration_changed(pin_all_resources)

-- Newly generated map chunks (ore patches placed by autoplace as the map expands)
script.on_event(defines.events.on_chunk_generated, function(event)
  for _, entity in pairs(event.surface.find_entities_filtered{area = event.area, type = "resource"}) do
    pin_yield(entity)
  end
end)
