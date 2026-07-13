# CustomGlebaSoilAnywhere `2.1.1`

Lets you place Overgrowth soil (jellynut and yumako) anywhere on Gleba. Plain artificial soil keeps the base game's default placement restriction.

**Original mod:** [Gleba Soil Anywhere](https://mods.factorio.com/mod/gleba-soil-anywhere) by **Sauravisus** ([source](https://github.com/AlexHaible/gleba-soil-anywhere))

## Changes from original

- Ported to Factorio 2.1: bumped `factorio_version` and dependency floors from `2.0`/`base >= 2.0.2`/`space-age >= 2.0.2` to `2.1`/`base >= 2.1`/`space-age >= 2.1`. No prototype code changes were needed.
- Restricted the unrestricted-placement effect to only the Overgrowth soil variants (`overgrowth-jellynut-soil`, `overgrowth-yumako-soil`); the plain artificial variants (`artificial-jellynut-soil`, `artificial-yumako-soil`) were dropped from `data-updates.lua` and keep the base game's default tile restriction
