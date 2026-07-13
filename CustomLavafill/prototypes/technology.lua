data:extend(
    {
        {
            type = "technology",
            name = "lavafill",
            icon = "__space-age__/graphics/icons/fluid/lava.png",
            icon_size = 64,
            prerequisites = {"metallurgic-science-pack"},
            unit = {
                count = 300,
                ingredients = {
                    {"automation-science-pack", 1},
                    {"logistic-science-pack", 1},
                    {"chemical-science-pack", 1},
                    {"space-science-pack", 1},
                    {"metallurgic-science-pack", 1},
                },
                time = 30
            },
            effects = {
                {
                    type = "unlock-recipe",
                    recipe = "lavafill"
                }
            },
            order = "b-d"
        }
    }
)
