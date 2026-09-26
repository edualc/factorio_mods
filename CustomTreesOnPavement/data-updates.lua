-- The Nauvis tree seed's planting restriction lives on the plant entity, not the seed item:
-- tree-plant.autoplace.tile_restriction is the list shown in the Factoriopedia and consulted by
-- agricultural towers and manual planting. Extend it with the paved/landfilled tiles.
local restriction = data.raw["plant"]["tree-plant"].autoplace.tile_restriction
for _, name in ipairs({
  "landfill",
  "stone-path",
  "concrete", "hazard-concrete-left", "hazard-concrete-right",
  "refined-concrete", "refined-hazard-concrete-left", "refined-hazard-concrete-right",
}) do
  table.insert(restriction, name)
end
