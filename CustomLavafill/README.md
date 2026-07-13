# CustomLavafill `2.1.1`

Allows the placement of lava just like landfill.

**Original mod:** [Lavafill](https://mods.factorio.com/mod/lavafill) by **Junsung Cho** ([source](https://github.com/junsung-cho/lavafill))

## Changes from original

- Ported to Factorio 2.1: bumped `factorio_version` and dependency floors from `2.0`/`base >= 2.0.0`/`space-age >= 2.0.0` to `2.1`/`base >= 2.1`/`space-age >= 2.1`
- Fixed the mod failing to load: `RecipePrototype.category` was merged into a `categories` array in Factorio 2.1 (this is a separate field from `place_as_tile.condition`, which is unchanged). The recipe now uses `categories = {"crafting-with-fluid"}` instead of `category = "crafting-with-fluid"`
