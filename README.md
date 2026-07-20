# Factorio Mods — Custom Forks

Personal forks of several Factorio mods, updated for compatibility with Factorio **2.1** and extended with additional features and fixes.

## Mods

### CustomHeroTurrets `2.1.4`
Turrets that level up based on kills, with a rank insignia overlay and per-rank stat buffs. Works across modded turrets, not just vanilla ones.

**Original mod:** [HeroTurrets](https://mods.factorio.com/mod/HeroTurrets) by **PixelWhipped**

**Changes from original:**
- Ported to Factorio 2.0/2.1: renamed `global` to `storage`, updated recipe ingredient format, removed deprecated `hr_version` sprite definitions and `icon_mipmaps`, fixed `on_player_joined_game` missing `defines.events` prefix, removed stale `landmine_on_gui_click` reference that was silently breaking GUI click handling
- Fixed flame (flamethrower) turrets not receiving hero rank variants: `is_unkown_nesw()` only covered `ammo-turret` and `electric-turret`; Factorio 2.x flamethrower turrets use `graphics_set` instead of the legacy NESW `base_picture` format, so they were silently skipped and never appeared in the Factoriopedia. Adding `fluid-turret` to the guard lets them go through the badge-overlay path like other turrets
- Fixed turrets appearing to lose health on level-up: the old entity's raw HP was transferred directly to the new (higher max-health) entity, so a full-health turret would show e.g. 400/600 after upgrading. Turrets now restore to full HP on rank-up
- Fixed generated hero-turret recipes silently landing in the default `crafting` category instead of the source turret's actual recipe category: `RecipePrototype.category` was merged into a `categories` array in Factorio 2.1; now copies `turret.recipe.categories` instead of the no-longer-existing `turret.recipe.category`

**v2.1.2:**
- Fixed turrets losing their enable/disable state and circuit network connections on rank-up: the entity swap now saves `disabled_by_script`, `circuit_connection_definitions`, and the circuit control behavior (enable condition) before destroying the old entity, then re-applies them to the new one

**v2.1.3:**
- Fixed turrets losing their priority target list on rank-up: the entity swap now reads `priority_targets` (array of `LuaEntityPrototype`) and `ignore_unprioritised_targets` before destroying the old entity, then replays them on the new one via `set_priority_target` — preserves e.g. a rocket turret on Aquilo configured to only shoot medium asteroids

**v2.1.4:**
- Fixed rank-up resetting a turret's quality tier back to normal: the entity swap creates the higher-rank replacement via `surface.create_entity` without a `quality` field, which defaults to `normal`, so a legendary turret silently lost its quality every time it ranked up. Now reads `entity.quality` before destroying the old entity and passes it to `create_entity` explicitly

---

### CustomLiborio `2.1.0`
Shared library used by CustomHeroTurrets and potentially other mods in this collection.

**Original mod:** [Liborio](https://mods.factorio.com/mod/Liborio) by **PixelWhipped**

**Changes from original:**
- Ported to Factorio 2.0/2.1: removed `on_robot_mined` from `pick_up_item` events (event was removed from the 2.0 API)

---

### CustomRPGsystem `2.1.2`
Adds a basic RPG system to the game — XP gain, level-ups, and skills for the player character.

**Original mod:** [RPGsystem](https://mods.factorio.com/mod/RPGsystem) by **MFerrari**

**Changes from original:**
- Ported to Factorio 2.1
- CustomZomboid integration: when a Zomtorio swarm cluster is killed, XP is calculated from the cluster's full zombie population (via the `CustomZomboid.get_cluster_kills` remote call) multiplied by a single zombie's XP value, rather than counting the cluster as one kill. Covers all swarm variants including their faster night forms, which map back to the same base zombie type for XP purposes.
- Fixed RPG magic effects (rpg_fireaball, rpg_hadouken) dealing unmitigated friendly-fire splash damage despite 100% armor: explosion entities are already gone by the time `on_entity_damaged` fires, making `cause.valid` false and skipping the armor heal-back. Armor now applies unconditionally before the cause guard.

**v2.1.2:**
- Fixed rpg_hadouken and rpg_fireaball area splash hitting friendly robots (construction, logistic, combat — including modded ones): magic projectiles are created with `force=player.force`, so `event.force` in `on_entity_damaged` equals the robot's own force even after the projectile entity is gone; any damage dealt to a friendly robot by its own force is healed back

---

### CustomZomboid `2.0.8`
Turns biters into a zombie horde. Destroyed buildings spawn new zombies, infection spreads through your logistics network, and corpses reanimate. Requires Space Age.

**Original mod:** [Zomboid](https://mods.factorio.com/mod/Zomboid) by **Martin Howarth**

**Changes from original (up to v2.0.2):**
- Complete rewrite for Factorio 2.1 + Space Age
- Biters become an overwhelming zombie horde represented by swarm clusters — one entity standing in for many zombies — so enormous numbers remain UPS-cheap. Each cluster tracks its true population, which is used as the authoritative enemy count for kill accounting, XP, and horde warnings
- When a cluster is destroyed, the attacker (turret or player) receives explicit kill credit via `cause.kills = cause.kills + 1`, since scripted entity death bypasses the engine's normal kill tracking. A remote interface (`CustomZomboid.get_cluster_kills`) exposes the full cluster population to other mods (used by CustomRPGsystem for correct XP)
- Night trickle spawns are suppressed in areas covered by powered lamps (12-tile radius) or paved with concrete/hazard-concrete, giving players a way to secure areas against ambient night pressure
- Buildings destroyed by the horde spawn zombies scaled to the building's total raw resource cost
- Infection and contagion system: horde hits infect buildings, robots, belts, inserters and pipes with damage-over-time; infection spreads downstream through the factory along the flow of goods. Full repair cures infection. Player is only infected by a direct bite and is cured by any net healing
- Corpse reanimation via the Space Age spoilage system: killed zombies drop burnable corpses that hatch into shamblers; shamblers drop no corpse, ending the chain at one generation
- Telegraphed, evolution-scaling horde events at night on top of pollution-driven attacks; a horde advances as a wall from one direction targeting your factory
- Spitter swarms: engine-spawned spitters form their own swarm clusters alongside biters
- Corpse disposal: zombie pyre (burns inserted corpses, no power) and corpse kiln (converts corpses into storable fuel)
- Melee technologies: Tier 1 unlocks swarm multi-kill, Tier 2 strengthens it and adds Corpse-free melee toggle (no corpse on melee kill = no reanimation risk, on by default once researched)
- Zombies and swarms move faster at night (configurable); unit speed change is implemented via a day/night prototype swap since runtime speed writes are ignored by the AI
- Denser, more aggressive nests and base expansion; pollution recruits far more attackers
- Console command `/zomtorio-horde [minutes]` to trigger a horde on demand without disabling achievements
- Extensive configuration options: horde size, active zombie cap, building infection, post-repair immunity window, player infection, night speedup, corpse reanimation, bot corpse collection, pollution cost per zombie, nest spawn rate, base expansion rate, and horde event intensity/frequency
- Fixed mod failing to load due to asset path prefix casing (`__zomtorio__` → `__Zomtorio__`)
- Fixed contagion spreading sluggishly along belts when only a single item was in transit
- Performance: `swarm.fold()` cache TTL extended from 1 tick to 60 ticks — the cache now stays warm across the entire spoilage burst when thousands of corpses expire over many consecutive ticks, not just within a single tick. Only the first fold per 8×8 grid cell per TTL window pays the `find_entities_filtered` cost; stale entries are safe because validity is checked before use
- Performance: night-variant sweep period raised 30→60 ticks, sweep radius reduced 48→32 tiles (~56% smaller search area), and a per-anchor swap cap of 150 units added — together these cut the worst-case entity-recreation cost by ~75% during large horde assaults at night
- Performance: horde warning map tag is now updated in-place (`.text` / `.position` writes) instead of destroy+create every 60 ticks, eliminating repeated map-chart sync operations during active horde events
- Performance: `horde_population()` result is cached for 120 ticks so the full iteration over the live-horde table runs at most once per 2 seconds instead of once per second, reducing cost during long high-evolution hordes with thousands of tracked units
- Performance: factory centroid scan in `factory_reference` now excludes characters, units, item entities, resources, and corpses at the API level, avoiding a large intermediate table in megabase saves
- Performance: character health snapshot in `process_players` uses a cached entity table (rebuilt only on player join/leave/death) instead of `find_entities_filtered` every tick, reducing per-tick cost in multiplayer or with modded NPC characters
- Balance: nest spawns accumulate in a per-spawner bucket before flushing into a cluster; threshold scales with evolution (1 at evo 0 → 15 at evo 1.0, ~8 at evo 0.5) so nest clusters grow to meaningful sizes rather than 1-pop entities — total zombie count unchanged, just batched into fewer larger clusters
- Balance: cluster member effective HP uses a ×4 multiplier (restoring ~vanilla HP per member so attack damage is meaningful, not just attack speed); evolution difficulty scaling uses Factorio's `result_units`-style probabilistic tier mix — small clusters dominate early game, medium clusters phase in from evo 0.2, big clusters from evo 0.4, with overlapping probability windows so the shift is gradual rather than a hard switch at fixed thresholds
- Fixed spitter cluster max_health incorrectly divided by 4 (1000→250): spitter cluster names contain "spitter" which caused the individual-health divisor loop to hit them, making them one-shottable by high-damage hero turrets before the damage handler could run
- Balance: biter and spitter movement speed divisor reduced 4→2 (half vanilla day speed; night speedup brings them to full vanilla at night) — previously too slow to close the gap or reposition against long-range turrets
- Balance: spitter attack range boosted to minimum 20 tiles (was ~15 vanilla) — matches hero turret range (18-27+) so spitters can fire back instead of being kited
- Fixed horde and night-trickle zombies spawning on water tiles: added a `WATER_TILES` name lookup (covering all vanilla water variants and `out-of-map`) checked before spawning in both `is_safe_spawn()` (night trickle) and `spawn_horde()` (directional horde wall columns)
- Physical and laser damage (gun turrets, laser turrets, player melee) leave a corpse that can reanimate; fire, explosion, electric, poison, and any unknown/modded type destroy the zombie utterly — whitelist so new damage types default to no-corpse
- Fixed: `dtype` was never set in `swarm.on_entity_damaged`, so the damage-type corpse filter never applied to cluster kills — every cluster hit dropped corpses regardless of weapon type
- Fixed multiplayer desync: `fold_cache` in `swarm.lua` was module-local; joining clients started with an empty cache while the server had a warm cache, causing divergent `swarm.fold()` behavior and RNG drift. Cache now stored in `storage` as unit_numbers so both sides see the same state
- Fixed multiplayer desync: `swarm_tier()` was using `math.random()` which is not synchronised across clients in Factorio; replaced with a `LuaRandomGenerator` stored in `storage` so all clients roll the same tier sequence
- Fixed crash when horde spawns beyond the generated map edge: `surface.get_tile()` can return a non-nil but invalid LuaTile for ungenerated chunks; accessing `.name` on it threw a non-recoverable error in `is_water_tile`. Invalid tiles are now treated as unwalkable so `find_land_near` keeps scanning for solid ground
- Fixed large hordes freezing when units cluster: each burst was creating a new unit group per column, flooding the spawn corridor with hundreds of simultaneous groups competing for the same path and deadlocking the engine's unit-group pathfinder. Groups are now reused across bursts (one per column); new members join the already-marching group instead of forming their own
- Performance: large horde spawns (9k+) no longer lag the game; bursts are queued and drained at 50 entities per tick instead of all at once, spreading the `find_non_colliding_position` cost across ~12 ticks rather than spiking a single tick
- Performance: per-column march targets are now precomputed once at horde-event start and cached in `s.column_targets`, eliminating the `nearest_building` O(N_buildings) scan that previously ran per column per drain tick (up to 9 × 12 = 108 scans per burst)
- Performance: `factory_reference` result is cached for 5 minutes so rapid `/zomtorio-horde` invocations do not each pay the full `find_entities_filtered` player-force scan
- Fixed night-trickle zombies potentially spawning on concrete via position drift
- Fixed night-trickle concrete check: `is_safe_spawn` previously checked only the exact ring point, but `find_non_colliding_position` can move the actual spawn up to 16 tiles away. Now uses `find_tiles_filtered` with a 16-tile buffer so any concrete within drift range suppresses the spawn
- Fixed lag when horde spawn corridors overlap water: `find_non_colliding_position` avoids entity bounding-box collisions but is tile-unaware, so it could return a water-tile position near the coast. Two-level fix: at the column level, `spawn_horde` now redirects water columns to the nearest land tile (up to 128 tiles away) via `util.find_land_near` rather than skipping them; at the entity level, a `safe_place` helper in `swarm.lua` validates the resolved position and retries with progressively wider scans (32 tiles → 128 tiles, 16-tile steps — analogous to picking a fresh horde spawn origin) before giving up. `WATER_TILES`, `is_water_tile`, and `find_land_near` are shared via `util.lua`
- Horde swarm clusters scale in density with estimated horde size and evolution: per-column drain-tick allotments accumulate in per-column buckets and only flush once the bucket reaches the size threshold (5 for <300, 15 for ≥300, 30 for ≥1000, 50 for ≥3000, 80 for ≥9000); evolution sets a floor of `⌊50 × evo⌋` so endgame clusters are always ≥50 members regardless of horde size. Partial buckets are flushed when the event ends so no zombies are silently discarded

**v2.0.3:**
- Fixed hordes accumulating at spawn without marching: column unit groups now have their march command re-issued on every burst so they keep advancing after reaching a target area or entering distraction-fight mode between bursts; a 15-minute periodic sweep re-commands both active column groups AND up to 300 wandering/stuck enemy units from dissolved past-event groups (one `find_entities_filtered` + capped `set_command` calls — trivially cheap), and prints a notification when stray zombies are redirected
- Fixed horde arriving as several small waves instead of one mass: per-burst re-command now checks the unit group's state and only re-issues the march order when the group is idle (`finished` or `wander_in_group`); interrupting an actively moving or fighting group caused it to re-gather at the spawn origin, producing the split-wave effect
- Fixed horde stopping at the factory walls: march command now targets the factory centre rather than the nearest wall building; targeting the wall edge allowed groups to satisfy `attack_area`'s 24-tile arrival radius while still outside the perimeter
- Fixed hordes spawning stranded behind large lakes: `begin_active` now tries up to 8 origin angles (45° apart) and picks the first whose straight-line path to the factory contains no confirmed water tiles; ungenerated chunks are skipped rather than rejected so the check stays cheap (at most 48 `get_tile` calls per event). Falls back to the base angle if all eight are water-blocked
- Console command `/zomtorio-sweep` to force the wander sweep immediately — re-commands stuck or wandering zombies toward the factory without waiting for the 15-minute periodic sweep

**v2.0.4:**
- Horde now spawns as a full wave before marching: unit groups gather during the entire spawning period with their march destination pre-set but `start_moving()` deferred until `end_active` fires, so all columns advance together as one mass rather than trickling in burst-by-burst
- `/zomtorio-sweep` accepts an optional entity cap (e.g. `/zomtorio-sweep 500`); with no argument both the command and the automatic 15-minute sweep redirect all stray units uncapped. Count is number of entities, not population — three clusters of 100 each count as 3, not 300
- Laser turret kills no longer leave reanimatable corpses: removed `laser` from the `CORPSE_DAMAGE` whitelist in `corpses.lua` — only physical damage (gun turrets, player melee) now spawns corpses

**v2.0.5:**
- Automatic 15-minute sweep and `/zomtorio-sweep` are both uncapped by default; sweep message now reports redirected cluster count, their total zombie population, and total stray units on the map
- Horde map marker now shows `X / ~Y spawning` (live count vs estimated total) while the event is active, and `X remaining` once spawning ends
- Removed horde approach-corridor path visualisation (it always printed a false "uncharted territory" error because the spawn origin is reliably 10 chunks into ungenerated terrain)

**v2.0.6:**
- Version bump to correct zip/folder labelling: previous deploys packaged the mod under the old folder name (`CustomZomboid_2.0.2`) so Factorio loaded it as v2.0.2 regardless of `info.json`; no code changes

**v2.0.7:**
- Fixed multiplayer desync: `factory_reference`'s 5-minute result cache (`factory_cache_tick/center/radius/buildings` in `horde.lua`) was module-local instead of stored in `storage`, so a freshly-joined client's Lua VM started with a cold cache while the host's stayed warm — the two could return different factory center/radius/buildings for the same tick whenever a cached read raced a join. Same root cause class as the `fold_cache` fix in `swarm.lua` (v2.0.2). Exposure increased sharply in v2.0.3 with the unconditional 15-minute periodic sweep and the on-demand `/zomtorio-sweep` command, both of which call `factory_reference` regardless of whether a horde event is active — making the stale-cache-vs-cold-cache race far more likely to be hit in a real session. Cache now lives in `storage.zomtorio.factory_cache`, identical on all clients

**v2.0.8:**
- Performance: `nest.on_entity_spawned` now caches `local_swarm_pop` (find_entities_filtered), `nest_budget` (get_pollution), and `nest_evo` (get_evolution_factor) per spawner with TTLs of 1 s / 5 s / 5 s respectively — once the global zombie cap is full (the normal state in large games), every engine nest spawn previously paid all three API calls; with hundreds of nests this was hundreds of find_entities_filtered per second. Caches are stored in `storage` (same fix class as fold_cache v2.0.2 and factory_cache v2.0.7) so joining clients share the host's warm cache. Bucket key computation is also moved before the pop/budget check so it is shared with the accumulator flush rather than recomputed
- Performance: `character_near` in `swarm.on_entity_damaged` now uses a cached character-position list (TTL 30 ticks, stored in `storage`) instead of calling `find_entities_filtered` per damage event — with laser turrets firing at many clusters simultaneously this was the dominant hot path during combat. Cache hits do only O(player count) distance² comparisons
- Performance: infection building DoT in `process()` now writes `entity.health` directly and calls `entity.die()` on death instead of `entity.damage()` — `entity.damage()` fires `on_entity_damaged` on every DoT tick (up to 256 per tick with a large infected factory), sending each through the engine resistance pipeline and the Lua damage handler fan-out for no net effect since `INFECTION_DAMAGE_TYPE` has no building resistances. `spawning.on_entity_died` still triggers zombie spawning on infected-building death because it checks `event.force`, which `entity.die(enemy_force())` sets correctly
- Performance: `on_entity_damaged` fan-out in `control.lua` now skips calling `swarm.on_entity_damaged` and `melee.on_entity_damaged` for non-unit entities (buildings, robots, characters hit by zombie attacks etc.) — both handlers categorically ignore non-unit entities but were being invoked for every building-damage event anyway, including any remaining non-DoT hits from zombies attacking structures

---

### CustomPUMP `2.2.1`
Adds a selection tool to auto-plan pumpjack and pipe layouts for oil fields. Select wells, PUMP places everything optimally using A* pathfinding.

**Original mod:** [P.U.M.P.](https://mods.factorio.com/mod/pump) by **Xcone**

**Changes from original:**
- A* node key changed from string concatenation (`x .. "," .. y`) to integer arithmetic (`x + y * 1e9`): eliminates a heap string allocation on every node visit during pathfinding, reducing GC pressure proportionally to field size. No behavioral change — keys remain unique for all valid map coordinates

---

### CustomCheevos `2.1.0`
Removes all map-setting restrictions on achievements. Peaceful mode, disabled enemies, custom evolution — all achievements still unlock regardless of map configuration.

**Original mods:** [cheevos_base](https://mods.factorio.com/mod/cheevos_base) and [cheevos_spage](https://mods.factorio.com/mod/cheevos_spage) by **dupraz**

**Changes from original:**
- Merges cheevos_base and cheevos_spage into one mod — cheevos_spage was deprecated in 2.0.77 because base-game and Space Age achievements share the same `allowed_without_fight` flag; a single data-final-fixes pass after all DLC prototypes load covers both
- Ported to Factorio 2.1

---

### CustomRobotsResistFire `2.1.0`
Makes all robots and belts completely immune to fire damage.

**Original mod:** [RobotsResistFire](https://mods.factorio.com/mod/RobotsResistFire) by **Gerkiz**

**Changes from original:**
- Increased fire resistance from 95% to 100% (true immunity instead of near-immunity)
- Extended fire immunity to belts: transport-belt, underground-belt, splitter, linked-belt, loader, loader-1x1 — all tiers covered
- Refactored repeated resistance logic into a helper function

---

### CustomLavafill `2.1.4`
Allows placing lava just like landfill.

**Original mod:** [Lavafill](https://mods.factorio.com/mod/lavafill) by **Junsung Cho**

**Changes from original:**
- Ported to Factorio 2.1: bumped `factorio_version` and dependency floors from `2.0` to `2.1`
- Fixed the mod failing to load: `RecipePrototype.category` was merged into a `categories` array in Factorio 2.1; the recipe now uses `categories = {"crafting-with-fluid"}` instead of `category = "crafting-with-fluid"`

**v2.1.2:**
- Fixed lavafill failing to place on tiles occupied by a resource entity (ore, oil, etc.): resource entities get the engine-default `collision_mask = {layers={resource=true}}` unless overridden, and `place_as_tile.condition` only permits overriding the collision layers it explicitly lists. The condition previously listed only `lava_tile`, so lavafill could be placed on existing lava but never on ore patches. Added `resource` to the condition layers
- Added `control.lua` as a belt-and-suspenders fix for the same issue, covering both placement paths: direct player placement destroys the resource on `on_pre_build` (before the engine's own tile placement check runs), and blueprint/construction-robot placement — which always goes through a tile-ghost first, since robots have no pre-build hook of their own — destroys the resource as soon as the lavafill tile-ghost is created

**v2.1.3:**
- Fixed direct player placement of lavafill still failing on resource-covered tiles despite v2.1.2: `on_pre_build` fires before the engine resolves the *current* build attempt, so this click's placement validity already appears to be decided by the time the handler runs — destroying the resource there only unblocked the next click on the same tile, not the one in progress. `on_pre_build` now places the tile itself via `LuaSurface.set_tiles` (which also drops any colliding entity) and consumes the item by hand whenever a resource is found, instead of relying on the native `place_as_tile` follow-up. The blueprint/construction-robot path is unaffected — robots build on a later tick, well after the resource was already removed at ghost-creation time

**v2.1.4:**
- Fixed offshore pumps sometimes not starting when placed together with lavafill in the same blueprint, requiring the pump to be manually removed and re-placed: an offshore pump resolves its connection to the fluid tile beneath it once, at creation time, and construction robots can finish building the pump before the lava tile underneath it is actually built, leaving it permanently unconnected. `control.lua` now listens for the lava tile itself being built (`on_robot_built_tile` / `on_player_built_tile` / `on_space_platform_built_tile`) and, if an offshore pump is already sitting on that tile, destroys and recreates it (preserving position, direction, force, and quality) so it re-resolves its connection against the now-correct tile

---

### CustomGlebaSoilAnywhere `2.1.1`
Removes placement restrictions for Overgrowth yumako/jellynut soil on Gleba. Plain artificial soil keeps the base game's default restriction.

**Original mod:** [Gleba Soil Anywhere](https://mods.factorio.com/mod/gleba-soil-anywhere) by **Sauravisus**

**Changes from original:**
- Ported to Factorio 2.1: bumped `factorio_version` and dependency floors from `2.0`/`2.0.2` to `2.1`; no prototype code changes needed
- Restricted unrestricted placement to only the Overgrowth soil variants; the plain artificial soil variants were dropped and keep the base game's default tile restriction

---

### CustomInfiniteOresAndOil `2.2.5`
Prevents ore patches from running out and keeps oil at its initial yield. Works with modded resources.

**Original mod:** [Infinite Ores and Oil](https://mods.factorio.com/mod/InfiniteOresAndOil) by **indiset**

**Changes from original:**
- Fixed finite resources (iron/copper/coal/stone/uranium ore, calcite, tungsten ore, scrap, lithium brine, and modded ores) not actually being infinite: the original `data-final-fixes.lua` only set `infinite_depletion_amount = 0`, which only has an effect on resources that already have `infinite = true` in vanilla (crude oil and the Space Age geysers/vents) - every other resource was untouched by that line. For those, the mod instead relied on a `control.lua` `on_resource_depleted` handler that refilled a depleted entity's amount to a single counter shared across every resource type and patch on the entire map, incremented by only 1 per depletion event anywhere - so patches refilled to trivially small amounts (1, 2, 3, ...) that were immediately exhausted again. This is why scrap and Aquilo resources (calcite, tungsten ore, lithium brine) in particular never felt infinite despite their settings being enabled
- Finite resources whose setting is enabled are now converted to `infinite = true` with `infinite_depletion_amount = 0` directly in `data-final-fixes.lua` - the same mechanism vanilla already uses natively for crude oil - so they never run out and never lose yield, instead of being refilled reactively after depletion. The old `on_resource_depleted` refill logic in `control.lua` was removed entirely, since converted resources' amount no longer decreases from mining at all
- Since the actual richness a specific ore patch was generated with isn't known at the data stage, `control.lua` pins each converted resource entity's yield to exactly its own current amount (`LuaEntity::initial_amount`) on init, on mod-configuration-changed, and as new chunks are generated, instead of a shared placeholder value
- Per-resource settings (`refill-coal`, `refill-iron`, ..., `refill-modded-ores`) are now startup settings instead of runtime-global, since `data-final-fixes.lua` only has access to `settings.startup`; toggling one now requires a mod settings reload (or a new save) to take effect

**v2.2.5:**
- Fixed converted resources (ores, scrap, lithium brine) mining at wildly inflated, per-patch-inconsistent rates instead of the vanilla constant rate: an infinite resource's yield percentage scales with `amount`/`normal`, and a patch's actual generated richness (tens to hundreds of thousands) is nowhere near the shared `normal` placeholder set in `data-final-fixes.lua`, so pinning `initial_amount` to the patch's own amount (as done in 2.2.4) left that ratio far above 100% and inconsistent from patch to patch. `control.lua` now overwrites the entity's actual `amount` (also writable) down to match the prototype's `normal` value instead, pinning the ratio to exactly 100% for every entity regardless of which field the engine reads as the live reference - restoring a flat, unchanged mining rate identical to the original finite behaviour

---

### CustomHeroWeapons `1.0.6`
Handheld weapons and power armor equipment that level up through kills, gaining fire rate, range, and damage bonuses at each rank. Includes a new Personal Tesla Defense equipment module.

**Original concept:** New mod (no upstream)

**Weapons and equipment covered:**
- Guns: Pistol, Submachine gun, Shotgun, Combat shotgun, Rocket launcher, Flamethrower, Tesla gun, Railgun (Space Age)
- Equipment: Personal Laser Defense, Personal Tesla Defense (new, Space Age)

**Rank system:**
- Gun kills are tracked per player per weapon type; equipment kills are tracked per armor grid slot
- Thresholds default to 50 / 250 / 1000 kills for ranks 2, 3, 4 (configurable via mod settings)
- On rank-up, the item in the gun slot (or equipment grid slot) is replaced in-place with the ranked variant
- Ranked guns carry 15% / 30% / 45% faster fire rate, 15% / 30% / 50% longer range, and 20% / 40% / 60% more damage per shot compared to the base weapon
- Switching to a tracked gun auto-upgrades it if saved kill count already qualifies
- Two copies of the same equipment in the armor grid level up independently
- On pickup, in-rank progress is intentionally lost; re-placing a ranked item resets its counter to the floor threshold for that rank (rank-2 item placed back in the grid starts at the rank-2 kill threshold)
- Badge overlay on ranked item icons shown when CustomHeroTurrets is also installed

**Personal Tesla Defense equipment (new item):**
- Active-defense equipment analogous to personal laser defense, targeting nearby enemies automatically
- Fires twice as hard but at 2/3 the fire rate; uses laser-category energy-powered ammo (no physical ammo needed)
- Recipe: 20 processing units + 5 low-density structures + 5 tesla turrets; unlocked by `tesla-weapons` technology

**v1.0.0:**
- Initial release
- Fixed mod failing to load: in Factorio 2.x, `active-defense-equipment` is not automatically registered as an item — the base game ships a separate `type = "item"` prototype with `place_as_equipment_result` for each equipment piece. `data-final-fixes.lua` now creates both the equipment prototype and the matching item prototype when generating personal-tesla-defense-equipment and all ranked equipment variants
- Personal Tesla Defense equipment fires chain lightning instead of a sustained laser beam: uses a tesla `instant` delivery nesting a `chain-tesla-gun-chain` trigger (12 jumps, 12-tile jump range, 0.3 fork chance) and the `chain-tesla-gun-beam-start` visual, matching the handheld tesla gun's behavior
- Fixed ranked equipment items showing "Unknown key: equipment-name.X" — item and equipment prototypes now both resolve the display name from the `[equipment-name]` locale section instead of `[item-name]`
- Rank tooltips now show actual stat values (e.g. "+18% fire rate, +15% range, +20% damage") instead of generic text
- Personal Tesla Defense chain lightning scales with rank: all four ranks use dedicated `chain-active-trigger` prototypes so both max_jumps (4→6→9→12) and fork_chance (0.05→0.20→0.40→0.75) grow independently; base cooldown raised to 120 ticks (from 60) so rank 1 feels earned and rank 4 (~66 ticks with multiplier) becomes the payoff
- Ranked variants now sort after the original in the Factoriopedia: a `-[rank-N]` suffix is appended to each ranked item's `order` field so originals (unchanged name) appear first, followed by Rank 2, 3, 4
- Fixed ranked guns and equipment showing incorrect stack/rocket-stack sizes: Factorio computes item weight from the recipe of the original but falls back to a different formula for items with no recipe; ranked items now have `weight` explicitly set (copied from the base or computed as `1000/stack_size * kg`) so rocket cargo capacity matches the original

**v1.0.1:**
- Equipment kill counts (Personal Laser Defense, Personal Tesla Defense) are now tracked per armor grid slot rather than per player per equipment type: two copies of the same equipment equipped simultaneously level up independently. On pickup the in-rank counter is discarded; re-placing a ranked item resets its counter to the kill threshold for that rank, so a rank-2 item placed back in the grid resumes from the rank-2 floor rather than zero

**v1.0.2:**
- Personal Tesla Defense now has a distinct icon: the laser defense equipment silhouette tinted electric blue, with a small tesla orb overlaid in the corner. The armor-grid sprite uses the same tinted laser defense artwork. Both make it clearly recognizable as a tesla-family defense item rather than a reuse of the tesla gun icon

**v1.0.3:**
- Personal Tesla Defense armor-grid sprite is now a layered sprite matching the inventory icon: tinted blue laser-defense body with the tesla orb overlaid in the bottom-right corner, rather than the body tint alone

**v1.0.4:**
- Fixed Personal Tesla Defense armor-grid sprite second layer (tesla orb) not rendering: `ammo-category/tesla.png` is a grayscale+alpha PNG which the Sprite layer system renders as invisible; switched to `tesla-ammo.png` (RGBA) which displays correctly

**v1.0.5:**
- Fixed rank-up resetting item/equipment quality back to normal: both `upgrade_gun` (`LuaItemStack.set_stack`) and `upgrade_equipment` (`LuaEquipmentGrid.put`) create the higher-rank replacement without ever reading the original's `quality` — both APIs default to `normal` when the field is omitted, so a legendary weapon or equipment piece silently lost its quality tier every time it ranked up. Both now capture `quality` from the original stack/equipment before the swap and pass it through explicitly

**v1.0.6:**
- Fixed equipped defense equipment only ever leveling up one type, and only one instance of that type: `storage.equipped_players` cached a single base equipment name per player (whichever tracked item the grid scan found first), so kills near a player with e.g. both Personal Laser Defense and Personal Tesla Defense equipped were only ever credited to the first-found type — the other never accumulated kills. Separately, `add_equipment_kill` always credited the first matching grid slot it found, so two copies of the same equipment did not level up independently as documented. The cache now stores every tracked slot per player (`pos_key -> base_name`), and kill attribution picks whichever equipped slot on the closest player currently has the fewest kills, so multiple equipped items (same or different type) level up evenly

---

## Credits

All original mods and their concepts belong to their respective authors. These forks exist solely for personal use to bring the mods up to date with Factorio 2.1 and to add quality-of-life changes.
