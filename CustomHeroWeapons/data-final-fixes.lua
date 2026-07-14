-- Per-rank multipliers: index 1 = base (rank 1), index 2/3/4 = upgraded ranks.
-- Cooldown shrinks (faster fire), range and damage grow.
local RANK_COOLDOWN_MULT = {1.0, 0.85, 0.70, 0.55}
local RANK_RANGE_MULT    = {1.0, 1.15, 1.30, 1.50}
local RANK_DAMAGE_MULT   = {1.0, 1.20, 1.40, 1.60}

-- Chain lightning parameters for the personal tesla defense per rank.
-- All ranks use hw-specific chain prototypes so max_jumps and fork_chance
-- can both scale independently of the vanilla chain-tesla-gun-chain.
local TESLA_DEFENSE_MAX_JUMPS   = {4, 6, 9, 12}
-- Half the vanilla tesla-gun fork_chance (0.3) at rank 1, then +5% per rank.
local TESLA_DEFENSE_FORK_CHANCE = {0.15, 0.20, 0.25, 0.30}

local function ranked_name(base, rank)
    return "hw-" .. base .. "-rank-" .. rank
end

local function apply_gun_rank(item, rank)
    local ap = item.attack_parameters
    if not ap then return end
    ap.cooldown = math.max(1, math.floor(ap.cooldown * RANK_COOLDOWN_MULT[rank]))
    ap.range = ap.range * RANK_RANGE_MULT[rank]
    ap.damage_modifier = (ap.damage_modifier or 1) * RANK_DAMAGE_MULT[rank]
end

local function apply_equipment_rank(item, rank)
    local ap = item.attack_parameters
    if not ap then return end
    ap.cooldown = math.max(1, math.floor(ap.cooldown * RANK_COOLDOWN_MULT[rank]))
    ap.range = ap.range * RANK_RANGE_MULT[rank]
    ap.damage_modifier = (ap.damage_modifier or 1) * RANK_DAMAGE_MULT[rank]
    local delivery = ap.ammo_type and ap.ammo_type.action and ap.ammo_type.action.action_delivery
    if delivery and delivery.max_length then
        delivery.max_length = delivery.max_length * RANK_RANGE_MULT[rank]
    end
end

-- Build a layered icon for the inventory item showing the base icon with a
-- rank badge overlay.  Requires CustomHeroTurrets for the badge sprites.
local function ranked_icons(base_item, rank)
    if not mods["CustomHeroTurrets"] then return nil end
    local badge = math.min(rank - 1, 4)
    return {
        {icon = base_item.icon, icon_size = base_item.icon_size or 64},
        {
            icon = "__CustomHeroTurrets__/graphics/icons/hero-" .. badge .. "-icon.png",
            icon_size = 64,
            scale = 0.35,
            shift = {8, 8},
        },
    }
end

-- ── Ranked gun variants ───────────────────────────────────────────────────────
-- Guns are plain items (type = "gun") so one prototype covers both inventory
-- and firing behaviour.

-- Copy weight/stack fields so ranked items aren't affected by Factorio's
-- recipe-based weight fallback (ranked items have no recipe, so without an
-- explicit weight they get a different default than originals that do).
local function copy_transport_fields(src, dst)
    dst.stack_size = src.stack_size
    dst.weight = src.weight or math.floor(1000 / src.stack_size * kg)
end

local function rank_desc_params(rank)
    local rate_pct   = math.floor((1 / RANK_COOLDOWN_MULT[rank] - 1) * 100 + 0.5)
    local range_pct  = math.floor((RANK_RANGE_MULT[rank]  - 1) * 100 + 0.5)
    local damage_pct = math.floor((RANK_DAMAGE_MULT[rank] - 1) * 100 + 0.5)
    return tostring(rank), tostring(rate_pct), tostring(range_pct), tostring(damage_pct)
end

local function create_ranked_gun(base_name, rank)
    local base = data.raw["gun"][base_name]
    if not base then return end

    local ranked = table.deepcopy(base)
    ranked.name = ranked_name(base_name, rank)
    ranked.localised_name = {"heroweapons.ranked-item-name", {"item-name." .. base_name}, tostring(rank)}
    ranked.localised_description = {"heroweapons.ranked-gun-desc", rank_desc_params(rank)}

    apply_gun_rank(ranked, rank)
    copy_transport_fields(base, ranked)

    if ranked.order then ranked.order = ranked.order .. "-[rank-" .. rank .. "]" end

    local icons = ranked_icons(base, rank)
    if icons then
        ranked.icons = icons
        ranked.icon = nil
        ranked.icon_size = nil
    end

    data:extend({ranked})
end

-- ── Ranked equipment variants ─────────────────────────────────────────────────
-- In Factorio 2.x, equipment is split into two prototypes:
--   active-defense-equipment  – grid stats (sprite, attack parameters, energy)
--   item                      – inventory object (icon, place_as_equipment_result)
-- Both must share the same name so the game can pair them.

local function create_ranked_equipment(base_name, rank)
    local rname = ranked_name(base_name, rank)

    -- Equipment prototype (grid behaviour and stats)
    local base_eq = data.raw["active-defense-equipment"][base_name]
    if not base_eq then return end

    local ranked_eq = table.deepcopy(base_eq)
    ranked_eq.name = rname
    ranked_eq.localised_name = {"heroweapons.ranked-item-name", {"equipment-name." .. base_name}, tostring(rank)}
    ranked_eq.localised_description = {"heroweapons.ranked-equipment-desc", rank_desc_params(rank)}
    apply_equipment_rank(ranked_eq, rank)

    -- Swap in the rank-specific chain for personal tesla defense.
    if base_name == "personal-tesla-defense-equipment" then
        local effects = ranked_eq.attack_parameters.ammo_type.action.action_delivery.target_effects
        for _, effect in ipairs(effects) do
            if effect.action.action_delivery.type == "chain" then
                effect.action.action_delivery.chain = "hw-personal-tesla-defense-chain-rank-" .. rank
                break
            end
        end
    end

    if ranked_eq.order then ranked_eq.order = ranked_eq.order .. "-[rank-" .. rank .. "]" end
    data:extend({ranked_eq})

    -- Item prototype (inventory icon, place_as_equipment_result)
    local base_item = data.raw["item"][base_name]
    if not base_item then return end

    local ranked_item = table.deepcopy(base_item)
    ranked_item.name = rname
    ranked_item.localised_name = {"heroweapons.ranked-item-name", {"equipment-name." .. base_name}, tostring(rank)}
    ranked_item.localised_description = {"heroweapons.ranked-equipment-desc", rank_desc_params(rank)}
    ranked_item.place_as_equipment_result = rname
    copy_transport_fields(base_item, ranked_item)
    if ranked_item.order then ranked_item.order = ranked_item.order .. "-[rank-" .. rank .. "]" end

    local icons = ranked_icons(base_item, rank)
    if icons then
        ranked_item.icons = icons
        ranked_item.icon = nil
        ranked_item.icon_size = nil
    end

    data:extend({ranked_item})
end

-- ── Personal Tesla Defense Equipment (Space Age only) ────────────────────────

if mods["space-age"] and data.raw["gun"]["teslagun"] then
    local laser_eq   = data.raw["active-defense-equipment"]["personal-laser-defense-equipment"]
    local laser_item = data.raw["item"]["personal-laser-defense-equipment"]

    if laser_eq and laser_item then
        -- Equipment prototype (grid stats)
        local tesla_eq = table.deepcopy(laser_eq)
        tesla_eq.name = "personal-tesla-defense-equipment"
        tesla_eq.localised_name = nil
        tesla_eq.localised_description = nil
        tesla_eq.sprite = {
            filename = "__space-age__/graphics/icons/teslagun.png",
            width = 64,
            height = 64,
            priority = "medium",
            scale = 1.0,
        }
        tesla_eq.energy_source.buffer_capacity = "440kJ"
        tesla_eq.attack_parameters.cooldown = 120
        tesla_eq.attack_parameters.range = 14
        tesla_eq.attack_parameters.damage_modifier = 0.25
        tesla_eq.attack_parameters.ammo_category = "tesla"
        tesla_eq.attack_parameters.ammo_type = {
            energy_consumption = "100kJ",
            action = {
                type = "direct",
                action_delivery = {
                    type = "instant",
                    target_effects = {
                        -- Chain effect must go first in case the beam kills the target
                        {
                            type = "nested-result",
                            action = {
                                type = "direct",
                                action_delivery = {
                                    type = "chain",
                                    chain = "hw-personal-tesla-defense-chain-rank-1",
                                }
                            }
                        },
                        {
                            type = "nested-result",
                            action = {
                                type = "direct",
                                action_delivery = {
                                    type = "beam",
                                    beam = "chain-tesla-gun-beam-start",
                                    source_offset = {0, -1.31439},
                                    max_length = 30,
                                    duration = 30,
                                    add_to_shooter = false,
                                    destroy_with_source_or_target = false,
                                }
                            }
                        },
                    }
                }
            }
        }
        data:extend({tesla_eq})

        -- Rank-specific chain-active-trigger prototypes (ranks 1-4).
        -- Each rank has its own prototype so max_jumps and fork_chance both scale.
        for r = 1, 4 do
            data:extend({{
                type = "chain-active-trigger",
                name = "hw-personal-tesla-defense-chain-rank-" .. r,
                max_jumps = TESLA_DEFENSE_MAX_JUMPS[r],
                max_range_per_jump = 12,
                jump_delay_ticks = 6,
                fork_chance = TESLA_DEFENSE_FORK_CHANCE[r],
                fork_chance_increase_per_quality_level = 0.05,
                action = {
                    type = "direct",
                    action_delivery = {
                        type = "beam",
                        beam = "chain-tesla-gun-beam-bounce",
                        max_length = 12.5,
                        duration = 30,
                        add_to_shooter = false,
                        destroy_with_source_or_target = false,
                        source_offset = {0, 0},
                    },
                },
            }})
        end

        -- Item prototype (inventory object)
        local tesla_item = table.deepcopy(laser_item)
        tesla_item.name = "personal-tesla-defense-equipment"
        tesla_item.localised_name = nil
        tesla_item.localised_description = nil
        tesla_item.icon = "__space-age__/graphics/icons/teslagun.png"
        tesla_item.icon_size = 64
        tesla_item.place_as_equipment_result = "personal-tesla-defense-equipment"
        tesla_item.order = "b[active-defense]-b[personal-tesla-defense-equipment]"
        data:extend({tesla_item})

        -- Recipe
        data:extend({{
            type = "recipe",
            name = "personal-tesla-defense-equipment",
            ingredients = {
                {type = "item", name = "processing-unit",      amount = 20},
                {type = "item", name = "low-density-structure", amount = 5},
                {type = "item", name = "tesla-turret",         amount = 5},
            },
            results = {{type = "item", name = "personal-tesla-defense-equipment", amount = 1}},
            energy_required = 10,
            enabled = false,
        }})

        local tech = data.raw["technology"]["tesla-weapons"]
        if tech then
            table.insert(tech.effects, {type = "unlock-recipe", recipe = "personal-tesla-defense-equipment"})
        end
    end
end

-- ── Generate all ranked variants ──────────────────────────────────────────────

local GUNS = {"pistol", "submachine-gun", "shotgun", "combat-shotgun", "rocket-launcher", "flamethrower"}
if mods["space-age"] then
    table.insert(GUNS, "teslagun")
    table.insert(GUNS, "railgun")
end

for _, gun_name in ipairs(GUNS) do
    for rank = 2, 4 do
        create_ranked_gun(gun_name, rank)
    end
end

local EQUIPMENT = {"personal-laser-defense-equipment"}
if mods["space-age"] and data.raw["active-defense-equipment"]["personal-tesla-defense-equipment"] then
    table.insert(EQUIPMENT, "personal-tesla-defense-equipment")
end

for _, eq_name in ipairs(EQUIPMENT) do
    for rank = 2, 4 do
        create_ranked_equipment(eq_name, rank)
    end
end

