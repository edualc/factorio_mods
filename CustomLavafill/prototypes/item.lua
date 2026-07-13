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
                condition = {layers = {lava_tile = true}}
            }
        }
    }
)
