data:extend(
    {
        {
            type = "item",
            name = "lavafill",
            icon = "__space-age__/graphics/icons/fluid/lava.png",
            icon_size = 64,
            subgroup = "terrain",
            order = "c[landfill]-a[dirt]",
            stack_size = 200,
            place_as_tile = {
                result = "lava",
                condition_size = 1,
                -- "resource" must be included alongside lava_tile: resource entities
                -- (ore, oil, etc.) get the engine-default collision_mask
                -- {layers={resource=true}} (data/core/lualib/collision-mask-defaults.lua),
                -- which blocks tile placement unless explicitly permitted here. Without it,
                -- lavafill can only be placed on already-existing lava, never on ore patches.
                condition = {layers = {lava_tile = true, resource = true}}
            }
        }
    }
)
