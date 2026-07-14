-- Per-rank multipliers: index 1 = base (rank 1), index 2/3/4 = upgraded ranks.
-- Cooldown shrinks (faster fire), range and damage grow.
local RANK_COOLDOWN_MULT = {1.0, 0.85, 0.70, 0.55}
local RANK_RANGE_MULT    = {1.0, 1.15, 1.30, 1.50}
local RANK_DAMAGE_MULT   = {1.0, 1.20, 1.40, 1.60}

local function ranked_name(base, rank)
    return "hw-" .. base .. "-rank-" .. rank
end

-- Apply scaled attack_parameters to a gun item copy.
local function apply_gun_rank(item, rank)
    local ap = item.attack_parameters
    if not ap then return end
    ap.cooldown = math.max(1, math.floor(ap.cooldown * RANK_COOLDOWN_MULT[rank]))
    ap.range = ap.range * RANK_RANGE_MULT[rank]
    ap.damage_modifier = (ap.damage_modifier or 1) * RANK_DAMAGE_MULT[rank]
end

-- Apply scaled attack_parameters to an active-defense-equipment copy.
-- Also scales the beam max_length so it visually matches the new range.
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

-- Build a layered icon that shows the base weapon icon with a rank badge overlay.
-- Falls back to just the base icon when CustomHeroTurrets is absent (badges won't show).
local function ranked_icons(base_item, rank)
    if not mods["CustomHeroTurrets"] then return nil end
    -- HeroTurrets ships hero-1 through hero-4 badge icons; badge rank is (rank-1) capped at 4.
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

local function create_ranked_gun(base_name, rank)
    local base = data.raw["gun"][base_name]
    if not base then return end

    local ranked = table.deepcopy(base)
    ranked.name = ranked_name(base_name, rank)
    ranked.localised_name = {"heroweapons.ranked-item-name", {"item-name." .. base_name}, rank}
    ranked.localised_description = {"heroweapons.ranked-gun-desc", rank}

    apply_gun_rank(ranked, rank)

    local icons = ranked_icons(base, rank)
    if icons then
        ranked.icons = icons
        ranked.icon = nil
        ranked.icon_size = nil
    end

    data:extend({ranked})
end

local function create_ranked_equipment(base_name, rank)
    local base = data.raw["active-defense-equipment"][base_name]
    if not base then return end

    local ranked = table.deepcopy(base)
    ranked.name = ranked_name(base_name, rank)
    ranked.localised_name = {"heroweapons.ranked-item-name", {"equipment-name." .. base_name}, rank}
    ranked.localised_description = {"heroweapons.ranked-equipment-desc", rank}

    apply_equipment_rank(ranked, rank)

    data:extend({ranked})
end

-- ── Personal Tesla Defense Equipment (Space Age only) ────────────────────────
-- Modelled after personal-laser-defense-equipment but hits harder and fires
-- more slowly.  Uses the same laser beam and energy-powered ammo_type so it
-- needs no physical ammo and benefits from laser-damage research.
if mods["space-age"] and data.raw["gun"]["teslagun"] then
    local laser = data.raw["active-defense-equipment"]["personal-laser-defense-equipment"]
    if laser then
        local tesla_eq = table.deepcopy(laser)
        tesla_eq.name = "personal-tesla-defense-equipment"
        tesla_eq.localised_name = nil   -- resolved from locale
        tesla_eq.localised_description = nil
        tesla_eq.sprite = {
            filename = "__space-age__/graphics/icons/teslagun.png",
            width = 64,
            height = 64,
            priority = "medium",
            scale = 1.0,
        }
        -- More powerful than laser defense: 2× damage, slower cooldown, slightly shorter range.
        tesla_eq.energy_source.buffer_capacity = "440kJ"
        tesla_eq.attack_parameters.cooldown = 60
        tesla_eq.attack_parameters.range = 14
        tesla_eq.attack_parameters.damage_modifier = 2
        tesla_eq.attack_parameters.ammo_type.energy_consumption = "100kJ"
        local delivery = tesla_eq.attack_parameters.ammo_type.action.action_delivery
        delivery.max_length = 14

        data:extend({tesla_eq})

        data:extend({{
            type = "recipe",
            name = "personal-tesla-defense-equipment",
            ingredients = {
                {type = "item", name = "processing-unit",    amount = 20},
                {type = "item", name = "low-density-structure", amount = 5},
                {type = "item", name = "tesla-turret",       amount = 5},
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

-- ── Ranked gun variants ───────────────────────────────────────────────────────
local GUNS = {"pistol", "submachine-gun", "shotgun", "combat-shotgun", "rocket-launcher", "flamethrower"}
if mods["space-age"] then table.insert(GUNS, "teslagun") end

for _, gun_name in ipairs(GUNS) do
    for rank = 2, 4 do
        create_ranked_gun(gun_name, rank)
    end
end

-- ── Ranked equipment variants ─────────────────────────────────────────────────
local EQUIPMENT = {"personal-laser-defense-equipment"}
if mods["space-age"] and data.raw["active-defense-equipment"]["personal-tesla-defense-equipment"] then
    table.insert(EQUIPMENT, "personal-tesla-defense-equipment")
end

for _, eq_name in ipairs(EQUIPMENT) do
    for rank = 2, 4 do
        create_ranked_equipment(eq_name, rank)
    end
end
