-- Remove the tile_condition whitelist from both overgrowth soil items so they
-- can be placed on any tile on Gleba, not only the handful of natural tiles
-- the base game allows. The tile prototypes themselves have no placement guards;
-- the restriction lives entirely in item.place_as_tile.tile_condition.
for _, item_name in ipairs({ "overgrowth-yumako-soil", "overgrowth-jellynut-soil" }) do
  local item = data.raw["item"][item_name]
  if item and item.place_as_tile then
    item.place_as_tile.tile_condition = nil
  end
end
