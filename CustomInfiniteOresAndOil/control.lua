-- Resources converted to infinite in data-final-fixes.lua carry this marker
-- minimum (vanilla infinite resources use much larger minimums), which lets
-- us tell them apart from resources that were already infinite in vanilla
local CONVERTED_MINIMUM = 1

local function is_converted_resource(entity)
  local prototype = entity.prototype
  return prototype.infinite_resource and prototype.minimum_resource_amount == CONVERTED_MINIMUM
end

-- Pins this entity's yield at 100% of its own current amount, since the
-- prototype's shared `normal` value (set in data-final-fixes.lua) can't know
-- the actual richness any specific map/patch was generated with
local function pin_yield(entity)
  if entity.valid and is_converted_resource(entity) then
    entity.initial_amount = entity.amount
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
