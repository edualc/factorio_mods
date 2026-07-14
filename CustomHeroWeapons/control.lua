-- CustomHeroWeapons – runtime kill tracking and rank-up logic.
--
-- Storage layout:
--   storage.heroweapons[player_index][base_weapon_name] = kill_count   (int)
--
-- Multiplayer notes:
--   * All state lives in `storage` → identical on every client.
--   * game.players is iterated by pairs() which, for a LuaCustomTable with
--     integer keys, iterates in ascending key order → deterministic.
--   * settings.startup values are identical on all clients.

-- ── Weapon registries ─────────────────────────────────────────────────────────

local IS_TRACKED_GUN = {
    ["pistol"]           = true,
    ["submachine-gun"]   = true,
    ["shotgun"]          = true,
    ["combat-shotgun"]   = true,
    ["rocket-launcher"]  = true,
    ["flamethrower"]     = true,
    ["teslagun"]         = true,
}

local IS_TRACKED_EQUIPMENT = {
    ["personal-laser-defense-equipment"]  = true,
    ["personal-tesla-defense-equipment"]  = true,
}

-- Entity types that represent player turrets; kills by these are not attributed
-- to personal defense equipment even if the player is nearby.
local IS_TURRET_TYPE = {
    ["ammo-turret"]      = true,
    ["electric-turret"]  = true,
    ["fluid-turret"]     = true,
    ["artillery-turret"] = true,
}

-- Damage type produced by each tracked gun (the damage type present on
-- on_entity_died).  Used to resolve which gun in the player's inventory
-- was actually shooting when there are multiple tracked guns equipped.
-- Physical guns are grouped together because their ammo all deals "physical"
-- damage — in that case we still fall back to first-found in slot order.
local GUN_DAMAGE_TYPE = {
    ["pistol"]          = "physical",
    ["submachine-gun"]  = "physical",
    ["shotgun"]         = "physical",
    ["combat-shotgun"]  = "physical",
    ["rocket-launcher"] = "explosion",
    ["flamethrower"]    = "fire",
    ["teslagun"]        = "electric",
}

-- Maximum distance (squared, in tiles) within which an equipment kill is
-- attributed to a nearby player.  20 tiles ≈ max personal-laser-defense range
-- after rank-4 scaling.
local EQUIPMENT_RANGE_SQ = 20 * 20

-- ── Name helpers ──────────────────────────────────────────────────────────────

-- "hw-pistol-rank-2"  → "pistol", 2
-- "pistol"            → "pistol", 1
-- anything else       → nil, nil
local function parse_item(item_name)
    local base, rank_str = item_name:match("^hw%-(.+)%-rank%-(%d+)$")
    if base then return base, tonumber(rank_str) end
    if IS_TRACKED_GUN[item_name] or IS_TRACKED_EQUIPMENT[item_name] then
        return item_name, 1
    end
    return nil, nil
end

-- ── Rank thresholds ───────────────────────────────────────────────────────────

local _thresholds = nil
local function thresholds()
    if not _thresholds then
        _thresholds = {
            [2] = settings.startup["heroweapons-kills-rank-2"].value,
            [3] = settings.startup["heroweapons-kills-rank-3"].value,
            [4] = settings.startup["heroweapons-kills-rank-4"].value,
        }
    end
    return _thresholds
end

local function target_rank(kills)
    local t = thresholds()
    for rank = 4, 2, -1 do
        if kills >= t[rank] then return rank end
    end
    return 1
end

-- ── Storage helpers ───────────────────────────────────────────────────────────

local function get_kills(player_index, base_name)
    local tbl = storage.heroweapons[player_index]
    return tbl and tbl[base_name] or 0
end

local function set_kills(player_index, base_name, kills)
    if not storage.heroweapons[player_index] then
        storage.heroweapons[player_index] = {}
    end
    storage.heroweapons[player_index][base_name] = kills
end

-- Snapshot ammo counts for a player and return the base gun name of the slot
-- whose ammo just decreased (nil if no decrease or no tracked gun there).
-- Reuses the existing snapshot table in place to avoid allocation each call.
local function update_ammo_snapshot(player_index, gun_inv, ammo_inv)
    local n = #ammo_inv
    local prev = storage.ammo_snapshot[player_index]
    local fired_base = nil

    -- Build current counts.
    local cur = {}
    for i = 1, n do
        cur[i] = ammo_inv[i].valid_for_read and ammo_inv[i].count or 0
    end

    -- Diff against previous snapshot to find which slot fired.
    if prev then
        for i = 1, n do
            if cur[i] < (prev[i] or 0) then
                local gun_stack = gun_inv[i]
                if gun_stack.valid_for_read then
                    local base = parse_item(gun_stack.name)
                    if base and IS_TRACKED_GUN[base] then
                        fired_base = base
                    end
                end
            end
        end
    end

    storage.ammo_snapshot[player_index] = cur
    return fired_base
end

-- ── Rank-up helpers ───────────────────────────────────────────────────────────

-- Replace the first gun slot containing base_name (or any ranked version) with
-- the new_rank variant, if current rank is lower.
local function upgrade_gun(player, base_name, new_rank)
    local char = player.character
    if not (char and char.valid) then return end
    local gun_inv = char.get_inventory(defines.inventory.character_guns)
    if not gun_inv then return end

    for i = 1, #gun_inv do
        local stack = gun_inv[i]
        if stack.valid_for_read then
            local base, cur_rank = parse_item(stack.name)
            if base == base_name and cur_rank < new_rank then
                local new_name = "hw-" .. base_name .. "-rank-" .. new_rank
                if prototypes.item[new_name] then
                    stack.set_stack({name = new_name, count = 1})
                    player.print({"heroweapons.rankup-message", {"item-name." .. base_name}, new_rank})
                end
                return
            end
        end
    end
end

-- Replace personal defense equipment in the armor grid with a higher rank.
local function upgrade_equipment(player, base_name, new_rank)
    local armor_inv = player.get_inventory(defines.inventory.character_armor)
    if not armor_inv then return end
    local armor = armor_inv[1]
    if not (armor and armor.valid_for_read) then return end
    local grid = armor.grid
    if not grid then return end

    for _, eq in pairs(grid.equipment) do
        local base, cur_rank = parse_item(eq.name)
        if base == base_name and cur_rank < new_rank then
            local new_name = "hw-" .. base_name .. "-rank-" .. new_rank
            if prototypes.equipment[new_name] then
                local pos = {x = eq.position.x, y = eq.position.y}
                local ok = pcall(function()
                    grid.take({equipment = eq})
                    grid.put({name = new_name, position = pos})
                end)
                if ok then
                    player.print({"heroweapons.rankup-message", {"equipment-name." .. base_name}, new_rank})
                end
            end
            return
        end
    end
end

-- ── Kill attribution ──────────────────────────────────────────────────────────

local function add_gun_kill(player, base_name)
    local pi = player.index
    local kills = get_kills(pi, base_name) + 1
    set_kills(pi, base_name, kills)
    local tr = target_rank(kills)
    if tr > 1 then upgrade_gun(player, base_name, tr) end
end

local function add_equipment_kill(player, base_name)
    local pi = player.index
    local kills = get_kills(pi, base_name) + 1
    set_kills(pi, base_name, kills)
    local tr = target_rank(kills)
    if tr > 1 then upgrade_equipment(player, base_name, tr) end
end

-- Check all players' personal defense equipment for proximity to a killed
-- enemy.  Attributes the kill to the closest player with equipment equipped,
-- up to EQUIPMENT_RANGE_SQ distance.
local function attribute_equipment_kill(pos, surface)
    local best_player = nil
    local best_base   = nil
    local best_dist   = EQUIPMENT_RANGE_SQ + 1

    for _, player in pairs(game.players) do
        local char = player.character
        if char and char.valid and char.surface == surface then
            local cp = char.position
            local dx, dy = pos.x - cp.x, pos.y - cp.y
            local dist_sq = dx * dx + dy * dy
            if dist_sq < best_dist then
                local armor_inv = player.get_inventory(defines.inventory.character_armor)
                if armor_inv then
                    local armor = armor_inv[1]
                    if armor and armor.valid_for_read and armor.grid then
                        for _, eq in pairs(armor.grid.equipment) do
                            local base = parse_item(eq.name)
                            if base and IS_TRACKED_EQUIPMENT[base] then
                                best_player = player
                                best_base   = base
                                best_dist   = dist_sq
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    if best_player then
        add_equipment_kill(best_player, best_base)
    end
end

-- ── Event handlers ────────────────────────────────────────────────────────────

script.on_init(function()
    storage.heroweapons    = {}
    storage.active_gun     = {}   -- [player_index] = base_weapon_name last fired
    storage.ammo_snapshot  = {}   -- [player_index] = {[slot] = count}
end)

script.on_configuration_changed(function()
    storage.heroweapons   = storage.heroweapons   or {}
    storage.active_gun    = storage.active_gun    or {}
    storage.ammo_snapshot = storage.ammo_snapshot or {}
end)

-- Track which gun was most recently fired by watching ammo consumption.
-- Fires on every shot for ammo-consuming guns (pistol/SMG/shotgun/rocket/tesla).
-- Flamethrower uses fluid and never triggers this; damage_type "fire" covers it.
script.on_event(defines.events.on_player_ammo_inventory_changed, function(event)
    local player = game.players[event.player_index]
    if not (player and player.character and player.character.valid) then return end
    local char = player.character

    local gun_inv  = char.get_inventory(defines.inventory.character_guns)
    local ammo_inv = char.get_inventory(defines.inventory.character_ammo)
    if not (gun_inv and ammo_inv) then return end

    local fired = update_ammo_snapshot(event.player_index, gun_inv, ammo_inv)
    if fired then
        storage.active_gun[event.player_index] = fired
    end
end)

script.on_event(defines.events.on_entity_died, function(event)
    local entity = event.entity
    if not entity.valid then return end
    -- Only care about enemy kills (biters, etc.).
    if entity.force.name ~= "enemy" then return end

    local cause = event.cause

    -- ── Gun kill: the direct cause is a player character ──────────────────────
    if cause and cause.valid and cause.type == "character" then
        local player = cause.player
        if not player then return end

        local gun_inv = cause.get_inventory(defines.inventory.character_guns)
        if not gun_inv then return end

        local active_base = nil

        -- Priority 1: ammo-consumption cache (most accurate; set on every shot).
        -- Validate the cached gun is still present — player may have dropped it.
        local cached = storage.active_gun[player.index]
        if cached then
            for i = 1, #gun_inv do
                local stack = gun_inv[i]
                if stack.valid_for_read and parse_item(stack.name) == cached then
                    active_base = cached
                    break
                end
            end
        end

        -- Priority 2: damage type (handles flamethrower "fire" and resolves
        -- cases where the ammo cache is stale or absent).
        if not active_base then
            local dmg_type = event.damage_type and event.damage_type.name
            if dmg_type then
                for i = 1, #gun_inv do
                    local stack = gun_inv[i]
                    if stack.valid_for_read then
                        local base = parse_item(stack.name)
                        if base and IS_TRACKED_GUN[base] and GUN_DAMAGE_TYPE[base] == dmg_type then
                            active_base = base
                            break
                        end
                    end
                end
            end
        end

        -- Priority 3: first tracked gun in slot order.
        if not active_base then
            for i = 1, #gun_inv do
                local stack = gun_inv[i]
                if stack.valid_for_read then
                    local base = parse_item(stack.name)
                    if base and IS_TRACKED_GUN[base] then
                        active_base = base
                        break
                    end
                end
            end
        end

        if active_base then add_gun_kill(player, active_base) end
        return
    end

    -- ── Turret kill: skip — CustomHeroTurrets handles these ───────────────────
    if cause and cause.valid and IS_TURRET_TYPE[cause.type] then return end

    -- ── Possible equipment kill: no identified cause or a beam entity ─────────
    -- Personal laser/tesla defense fires beams; their cause is the beam entity
    -- or nil.  We attribute by proximity.
    attribute_equipment_kill(entity.position, entity.surface)
end)

-- When a player's gun inventory changes (e.g. they pick up a new weapon),
-- upgrade any tracked guns that have already earned a higher rank.
script.on_event(defines.events.on_player_gun_inventory_changed, function(event)
    local player = game.players[event.player_index]
    if not (player and player.character and player.character.valid) then return end

    local gun_inv = player.character.get_inventory(defines.inventory.character_guns)
    if not gun_inv then return end

    for i = 1, #gun_inv do
        local stack = gun_inv[i]
        if stack.valid_for_read then
            local base, cur_rank = parse_item(stack.name)
            if base and IS_TRACKED_GUN[base] then
                local kills = get_kills(event.player_index, base)
                local tr = target_rank(kills)
                if tr > cur_rank then
                    upgrade_gun(player, base, tr)
                end
            end
        end
    end
end)

script.on_event(defines.events.on_player_joined_game, function(event)
    local pi = event.player_index
    storage.heroweapons[pi]   = storage.heroweapons[pi]   or {}
    storage.active_gun[pi]    = storage.active_gun[pi]    or nil
    storage.ammo_snapshot[pi] = storage.ammo_snapshot[pi] or nil
end)
