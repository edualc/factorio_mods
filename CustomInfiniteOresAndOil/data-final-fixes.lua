-- Maps a vanilla ore to its corresponding mod setting
local resource_setting_map = {
    ["coal"]          = "refill-coal"    ,
    ["iron-ore"]      = "refill-iron"    ,
    ["copper-ore"]    = "refill-copper"  ,
    ["stone"]         = "refill-stone"   ,
    ["uranium-ore"]   = "refill-uranium" ,
    ["calcite"]       = "refill-calcite" ,
    ["tungsten-ore"]  = "refill-tungsten",
    ["scrap"]         = "refill-scrap"   ,
    ["lithium-brine"] = "refill-lithium"
}

-- Checks whether a resource's setting is enabled, falling back to the modded
-- ores setting for unknown ores, or when this ore's own setting isn't
-- registered (e.g. a space age ore added to a base game by another mod)
local function is_enabled(resource_name)
  local setting_name = resource_setting_map[resource_name]
  if setting_name == nil or settings.startup[setting_name] == nil then
    setting_name = "refill-modded-ores"
  end
  local setting = settings.startup[setting_name]
  return setting ~= nil and setting.value
end

-- Marker minimum for resources this mod converts to infinite below - distinct
-- from any vanilla infinite resource's own minimum (crude-oil/sulfuric-acid-
-- geyser/fluorine-vent use 20000-60000), so control.lua can tell which
-- entities it should pin to their own current amount (see control.lua)
local CONVERTED_MINIMUM = 1

-- Finds all resources at the data-final-fixes loading step
for name, resource in pairs(data.raw.resource) do
  if resource.infinite then
    -- Already-infinite vanilla resources (crude oil, geysers): never lose yield
    resource.infinite_depletion_amount = 0
  elseif is_enabled(name) then
    -- Finite resources (ores, scrap, lithium brine, modded ores): make them
    -- infinite the same way crude oil already works natively, instead of
    -- trying to refill entities after they run out
    resource.infinite = true
    resource.minimum = CONVERTED_MINIMUM
    resource.normal = 1000
    resource.infinite_depletion_amount = 0
  end
end
