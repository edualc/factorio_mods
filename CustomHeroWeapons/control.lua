-- CustomHeroWeapons – runtime kill tracking and rank-up logic.
--
-- Storage layout:
--   storage.heroweapons[player_index][base_weapon_name] = kill_count   (int, guns only)
--   storage.eq_data[player_index][pos_key] = {base=name, kills=N}     (per equipment grid slot)
--   storage.equipped_players[player_index][pos_key] = base_name        (all tracked slots currently equipped)
--
-- Equipment kills are tracked per armor grid slot while the item is equipped.
-- On removal the counter is discarded; on re-placement the counter resets to
-- the minimum kill threshold for the item's current rank (so a rank-2 item
-- placed in the grid starts at the rank-2 threshold, not zero).  Progress
-- within a rank is lost on pickup — you earn a rank by wearing the item.
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
    ["railgun"]          = true,
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
    ["railgun"]         = "physical",   -- same as bullets; tier-1 ammo cache disambiguates
}

-- Per-weapon multiplier on the shared kill thresholds.
local KILL_THRESHOLD_MULT = {
    ["personal-tesla-defense-equipment"] = 10,
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

local function pos_key(pos)
    return pos.x .. "," .. pos.y
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

local function target_rank(base_name, kills)
    local mult = KILL_THRESHOLD_MULT[base_name] or 1
    local t = thresholds()
    for rank = 4, 2, -1 do
        if kills >= t[rank] * mult then return rank end
    end
    return 1
end

-- Minimum kill count to have reached `rank` (the floor applied on re-placement).
local function kills_floor_for_rank(base_name, rank)
    if rank <= 1 then return 0 end
    return thresholds()[rank] * (KILL_THRESHOLD_MULT[base_name] or 1)
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

local function get_slot_kills(pi, pk)
    local d = storage.eq_data[pi]
    return d and d[pk] and d[pk].kills or 0
end

local function set_slot_data(pi, pk, base_name, kills)
    storage.eq_data[pi] = storage.eq_data[pi] or {}
    storage.eq_data[pi][pk] = { base = base_name, kills = kills }
end

-- Snapshot ammo counts for a player and return the base gun name of the slot
-- whose ammo just decreased (nil if no decrease or no tracked gun there).
local function update_ammo_snapshot(player_index, gun_inv, ammo_inv)
    local n = #ammo_inv
    local prev = storage.ammo_snapshot[player_index]
    local fired_base = nil

    local cur = {}
    for i = 1, n do
        cur[i] = ammo_inv[i].valid_for_read and ammo_inv[i].count or 0
    end

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
                    local quality = stack.quality.name
                    stack.set_stack({name = new_name, count = 1, quality = quality})
                    player.print({"heroweapons.rankup-message", {"item-name." .. base_name}, tostring(new_rank)})
                end
                return
            end
        end
    end
end

-- Replace personal defense equipment at grid position pk with a higher rank.
-- eq_data[pi][pk] is preserved across the swap since the position key is unchanged.
local function upgrade_equipment(player, base_name, pk, new_rank)
    local armor_inv = player.get_inventory(defines.inventory.character_armor)
    if not armor_inv then return end
    local armor = armor_inv[1]
    if not (armor and armor.valid_for_read) then return end
    local grid = armor.grid
    if not grid then return end

    local x_str, y_str = pk:match("^(-?%d+),(-?%d+)$")
    local px, py = tonumber(x_str), tonumber(y_str)

    for _, eq in pairs(grid.equipment) do
        if eq.position.x == px and eq.position.y == py then
            local base, cur_rank = parse_item(eq.name)
            if base == base_name and cur_rank < new_rank then
                local new_name = "hw-" .. base_name .. "-rank-" .. new_rank
                if prototypes.equipment[new_name] then
                    local pos = eq.position
                    local quality = eq.quality.name
                    local ok = pcall(function()
                        grid.take({equipment = eq})
                        grid.put({name = new_name, position = pos, quality = quality})
                    end)
                    if ok then
                        player.print({"heroweapons.rankup-message", {"equipment-name." .. base_name}, tostring(new_rank)})
                    end
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
    local tr = target_rank(base_name, kills)
    if tr > 1 then upgrade_gun(player, base_name, tr) end
end

-- Attribute one kill to a specific equipped slot, already chosen by
-- attribute_equipment_kill for proximity and even distribution across slots.
local function add_equipment_kill(player, pk, base_name)
    local armor_inv = player.get_inventory(defines.inventory.character_armor)
    if not armor_inv then return end
    local armor = armor_inv[1]
    if not (armor and armor.valid_for_read) then return end
    local grid = armor.grid
    if not grid then return end

    local x_str, y_str = pk:match("^(-?%d+),(-?%d+)$")
    local px, py = tonumber(x_str), tonumber(y_str)

    for _, eq in pairs(grid.equipment) do
        if eq.position.x == px and eq.position.y == py then
            local base, cur_rank = parse_item(eq.name)
            if base == base_name then
                local pi = player.index
                local kills = get_slot_kills(pi, pk) + 1
                set_slot_data(pi, pk, base_name, kills)
                local tr = target_rank(base_name, kills)
                if tr > cur_rank then upgrade_equipment(player, base_name, pk, tr) end
            end
            return
        end
    end
end

-- Rebuild the equipped_players cache entry for one player by scanning their grid.
-- Stores every tracked slot (pos_key -> base name), not just the first match,
-- so multiple equipped types/copies are all eligible for kill credit.
local function refresh_equipped_cache(player)
    storage.equipped_players = storage.equipped_players or {}
    local pi = player.index
    local slots = nil
    local armor_inv = player.get_inventory(defines.inventory.character_armor)
    if armor_inv then
        local armor = armor_inv[1]
        if armor and armor.valid_for_read and armor.grid then
            for _, eq in pairs(armor.grid.equipment) do
                local base = parse_item(eq.name)
                if base and IS_TRACKED_EQUIPMENT[base] then
                    slots = slots or {}
                    slots[pos_key(eq.position)] = base
                end
            end
        end
    end
    storage.equipped_players[pi] = slots
end

-- Check all players' personal defense equipment for proximity to a killed
-- enemy.  Attributes the kill to the closest player with equipment equipped,
-- up to EQUIPMENT_RANGE_SQ distance; among that player's equipped slots,
-- credits whichever currently has the fewest kills so multiple items (same
-- or different type) level up evenly instead of one slot hogging every kill.
-- Hot path: only arithmetic and table lookups — no inventory or grid API calls,
-- except the single targeted grid lookup once a slot has been chosen.
local function attribute_equipment_kill(pos, surface)
    if not storage.equipped_players or not next(storage.equipped_players) then return end

    local best_player = nil
    local best_slots  = nil
    local best_dist   = EQUIPMENT_RANGE_SQ + 1

    for pi, slots in pairs(storage.equipped_players) do
        local player = game.players[pi]
        if not player then goto continue end
        local char = player.character
        if char and char.valid and char.surface == surface then
            local cp = char.position
            local dx, dy = pos.x - cp.x, pos.y - cp.y
            local dist_sq = dx * dx + dy * dy
            if dist_sq < best_dist then
                best_player = player
                best_slots  = slots
                best_dist   = dist_sq
            end
        end
        ::continue::
    end

    if not best_player then return end

    -- Deterministic tie-break on pos_key so all clients pick the same slot.
    local pi = best_player.index
    local best_pk, best_base, least_kills = nil, nil, nil
    for pk, base in pairs(best_slots) do
        local k = get_slot_kills(pi, pk)
        if least_kills == nil or k < least_kills or (k == least_kills and pk < best_pk) then
            best_pk, best_base, least_kills = pk, base, k
        end
    end

    if best_pk then add_equipment_kill(best_player, best_pk, best_base) end
end

-- ── Event handlers ────────────────────────────────────────────────────────────

script.on_init(function()
    storage.heroweapons      = {}
    storage.active_gun       = {}
    storage.ammo_snapshot    = {}
    storage.equipped_players = {}
    storage.eq_data          = {}   -- [pi][pos_key] = {base, kills}; cleared on removal
end)

script.on_configuration_changed(function()
    storage.heroweapons      = storage.heroweapons      or {}
    storage.active_gun       = storage.active_gun       or {}
    storage.ammo_snapshot    = storage.ammo_snapshot    or {}
    storage.equipped_players = storage.equipped_players or {}
    storage.eq_data          = storage.eq_data          or {}
    -- Clear any leftover eq_kills that used to live in heroweapons for equipment types.
    for pi, tbl in pairs(storage.heroweapons) do
        for base in pairs(IS_TRACKED_EQUIPMENT) do
            tbl[base] = nil
        end
    end
    -- Seed eq_data for equipment already in armor grids (existing saves / mod updates).
    for _, player in pairs(game.players) do
        local pi = player.index
        storage.eq_data[pi] = storage.eq_data[pi] or {}
        local armor_inv = player.get_inventory(defines.inventory.character_armor)
        if armor_inv then
            local armor = armor_inv[1]
            if armor and armor.valid_for_read and armor.grid then
                for _, eq in pairs(armor.grid.equipment) do
                    local base, cur_rank = parse_item(eq.name)
                    if base and IS_TRACKED_EQUIPMENT[base] then
                        local pk = pos_key(eq.position)
                        if not storage.eq_data[pi][pk] then
                            set_slot_data(pi, pk, base, kills_floor_for_rank(base, cur_rank))
                        end
                    end
                end
            end
        end
        refresh_equipped_cache(player)
    end
end)

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
    if entity.force.name ~= "enemy" then return end

    local cause = event.cause

    -- ── Gun kill: the direct cause is a player character ──────────────────────
    if cause and cause.valid and cause.type == "character" then
        local player = cause.player
        if not player then return end

        local gun_inv = cause.get_inventory(defines.inventory.character_guns)
        if not gun_inv then return end

        local active_base = nil

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

    -- ── Possible equipment kill: attribute by proximity ────────────────────────
    attribute_equipment_kill(entity.position, entity.surface)
end)

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
                local tr = target_rank(base, kills)
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
    storage.eq_data[pi]       = storage.eq_data[pi]       or {}
    local player = game.players[pi]
    local armor_inv = player.get_inventory(defines.inventory.character_armor)
    if armor_inv then
        local armor = armor_inv[1]
        if armor and armor.valid_for_read and armor.grid then
            for _, eq in pairs(armor.grid.equipment) do
                local base, cur_rank = parse_item(eq.name)
                if base and IS_TRACKED_EQUIPMENT[base] then
                    local pk = pos_key(eq.position)
                    if not storage.eq_data[pi][pk] then
                        set_slot_data(pi, pk, base, kills_floor_for_rank(base, cur_rank))
                    end
                end
            end
        end
    end
    refresh_equipped_cache(player)
end)

-- On placement: initialize the slot's kill counter to the floor for the item's
-- current rank.  A rank-2 item placed in the grid starts at the rank-2 kill
-- threshold, not zero.  Progress above the floor is not preserved on pickup.
script.on_event(defines.events.on_player_placed_equipment, function(event)
    local base, cur_rank = parse_item(event.equipment.name)
    if not base or not IS_TRACKED_EQUIPMENT[base] then return end

    local pi = event.player_index
    local pk = pos_key(event.equipment.position)
    set_slot_data(pi, pk, base, kills_floor_for_rank(base, cur_rank))
    refresh_equipped_cache(game.players[pi])
end)

-- On removal: discard the slot's kill counter.  The rank is preserved in the
-- item name; progress within the current rank is intentionally lost.
script.on_event(defines.events.on_player_removed_equipment, function(event)
    local base = parse_item(event.equipment)  -- equipment is a string on this event
    if not base or not IS_TRACKED_EQUIPMENT[base] then return end

    local pi = event.player_index
    -- Clear any slots for this base that are no longer in the grid.
    local grid = event.grid
    local current_pks = {}
    for _, eq in pairs(grid.equipment) do
        local b = parse_item(eq.name)
        if b == base then current_pks[pos_key(eq.position)] = true end
    end
    for pk, data in pairs(storage.eq_data[pi] or {}) do
        if data.base == base and not current_pks[pk] then
            storage.eq_data[pi][pk] = nil
        end
    end

    refresh_equipped_cache(game.players[pi])
end)
