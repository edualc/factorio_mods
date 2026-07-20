# CustomInfiniteOresAndOil `2.2.4`

Prevents ore patches from running out and keeps oil at its initial yield. Works with modded resources.

**Original mod:** [Infinite Ores and Oil](https://mods.factorio.com/mod/InfiniteOresAndOil) by **indiset** ([source](https://github.com/ryan-tock/InfiniteOresAndOil))

## Changes from original

- Fixed finite resources (iron/copper/coal/stone/uranium ore, calcite, tungsten ore, scrap, lithium brine, and modded ores) not actually being infinite: they're now converted to `infinite = true` with `infinite_depletion_amount = 0` in `data-final-fixes.lua`, the same mechanism vanilla already uses for crude oil, instead of relying on a broken `on_resource_depleted` refill handler that shared a single slowly-incrementing counter across every resource type and patch on the map
- `control.lua` pins each converted entity's yield to its own current amount (`LuaEntity::initial_amount`) on init, mod-configuration-changed, and as new chunks generate, since the real richness a patch was generated with isn't known at the data stage
- Per-resource settings (`refill-coal`, `refill-iron`, ..., `refill-modded-ores`) are now startup settings instead of runtime-global, since `data-final-fixes.lua` only has access to `settings.startup`
