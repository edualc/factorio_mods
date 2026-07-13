# CustomHeroTurrets `2.1.1`

Turrets that level up based on kills, with a rank insignia overlay and per-rank stat buffs. Works across modded turrets, not just vanilla ones.

**Original mod:** [HeroTurrets](https://mods.factorio.com/mod/HeroTurrets) by **PixelWhipped**

## Changes from original

- Ported to Factorio 2.0/2.1: renamed `global` to `storage`, updated recipe ingredient format, removed deprecated `hr_version` sprite definitions and `icon_mipmaps`, fixed `on_player_joined_game` missing `defines.events` prefix, removed stale `landmine_on_gui_click` reference that was silently breaking GUI click handling
- Fixed flame (flamethrower) turrets not receiving hero rank variants: `is_unkown_nesw()` only covered `ammo-turret` and `electric-turret`; Factorio 2.x flamethrower turrets use `graphics_set` instead of the legacy NESW `base_picture` format, so they were silently skipped and never appeared in the Factoriopedia. Adding `fluid-turret` to the guard lets them go through the badge-overlay path like other turrets
- Fixed turrets appearing to lose health on level-up: the old entity's raw HP was transferred directly to the new (higher max-health) entity, so a full-health turret would show e.g. 400/600 after upgrading. Turrets now restore to full HP on rank-up
- Fixed generated hero-turret recipes silently landing in the default `crafting` category instead of the source turret's actual recipe category: `RecipePrototype.category` was merged into a `categories` array in Factorio 2.1, so copying `turret.recipe.category` (absent on the source prototype) produced `nil` without erroring. Now copies `turret.recipe.categories` instead
