# Factorio Mods — Custom Forks

Personal forks of several Factorio mods, updated for compatibility with Factorio **2.1** and extended with additional features and fixes.

## Mods

### CustomHeroTurrets `2.1.0`
Turrets that level up based on kills, with a rank insignia overlay and per-rank stat buffs. Works across modded turrets, not just vanilla ones.

**Original mod:** [HeroTurrets](https://mods.factorio.com/mod/HeroTurrets) by **PixelWhipped**

**Changes from original:**
- Ported to Factorio 2.0/2.1: renamed `global` to `storage`, updated recipe ingredient format, removed deprecated `hr_version` sprite definitions and `icon_mipmaps`, fixed `on_player_joined_game` missing `defines.events` prefix, removed stale `landmine_on_gui_click` reference that was silently breaking GUI click handling
- Fixed flame (flamethrower) turrets not receiving hero rank variants: `is_unkown_nesw()` only covered `ammo-turret` and `electric-turret`; Factorio 2.x flamethrower turrets use `graphics_set` instead of the legacy NESW `base_picture` format, so they were silently skipped and never appeared in the Factoriopedia. Adding `fluid-turret` to the guard lets them go through the badge-overlay path like other turrets
- Fixed turrets appearing to lose health on level-up: the old entity's raw HP was transferred directly to the new (higher max-health) entity, so a full-health turret would show e.g. 400/600 after upgrading. Turrets now restore to full HP on rank-up

---

### CustomLiborio `2.1.0`
Shared library used by CustomHeroTurrets and potentially other mods in this collection.

**Original mod:** [Liborio](https://mods.factorio.com/mod/Liborio) by **PixelWhipped**

**Changes from original:**
- Ported to Factorio 2.0/2.1: removed `on_robot_mined` from `pick_up_item` events (event was removed from the 2.0 API)

---

### CustomRPGsystem `2.1.1`
Adds a basic RPG system to the game — XP gain, level-ups, and skills for the player character.

**Original mod:** [RPGsystem](https://mods.factorio.com/mod/RPGsystem) by **MFerrari**

**Changes from original:**
- Ported to Factorio 2.1
- CustomZomboid integration: when a Zomtorio swarm cluster is killed, XP is calculated from the cluster's full zombie population (via the `CustomZomboid.get_cluster_kills` remote call) multiplied by a single zombie's XP value, rather than counting the cluster as one kill. Covers all swarm variants including their faster night forms, which map back to the same base zombie type for XP purposes.
- Fixed RPG magic effects (rpg_fireaball, rpg_hadouken) dealing unmitigated friendly-fire splash damage despite 100% armor: explosion entities are already gone by the time `on_entity_damaged` fires, making `cause.valid` false and skipping the armor heal-back. Armor now applies unconditionally before the cause guard.

---

### CustomZomboid `2.0.2`
Turns biters into a zombie horde. Destroyed buildings spawn new zombies, infection spreads through your logistics network, and corpses reanimate. Requires Space Age.

**Original mod:** [Zomboid](https://mods.factorio.com/mod/Zomboid) by **Martin Howarth**

**Changes from original:**
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
- Fixed spitter cluster max_health incorrectly divided by 4 (1000→250): spitter cluster names contain "spitter" which caused the individual-health divisor loop to hit them, making them one-shottable by high-damage hero turrets before the damage handler could run
- Balance: biter and spitter movement speed divisor reduced 4→2 (half vanilla day speed; night speedup brings them to full vanilla at night) — previously too slow to close the gap or reposition against long-range turrets
- Balance: spitter attack range boosted to minimum 20 tiles (was ~15 vanilla) — matches hero turret range (18-27+) so spitters can fire back instead of being kited
- Fixed horde and night-trickle zombies spawning on water tiles: added a `WATER_TILES` name lookup (covering all vanilla water variants and `out-of-map`) checked before spawning in both `is_safe_spawn()` (night trickle) and `spawn_horde()` (directional horde wall columns)
- Fixed large hordes freezing when units cluster: each burst was creating a new unit group per column, flooding the spawn corridor with hundreds of simultaneous groups competing for the same path and deadlocking the engine's unit-group pathfinder. Groups are now reused across bursts (one per column); new members join the already-marching group instead of forming their own
- Performance: large horde spawns (9k+) no longer lag the game; bursts are queued and drained at 50 entities per tick instead of all at once, spreading the `find_non_colliding_position` cost across ~12 ticks rather than spiking a single tick
- Performance: per-column march targets are now precomputed once at horde-event start and cached in `s.column_targets`, eliminating the `nearest_building` O(N_buildings) scan that previously ran per column per drain tick (up to 9 × 12 = 108 scans per burst)
- Performance: `factory_reference` result is cached for 5 minutes so rapid `/zomtorio-horde` invocations do not each pay the full `find_entities_filtered` player-force scan
- Fixed night-trickle zombies potentially spawning on concrete via position drift
- Fixed night-trickle concrete check: `is_safe_spawn` previously checked only the exact ring point, but `find_non_colliding_position` can move the actual spawn up to 16 tiles away. Now uses `find_tiles_filtered` with a 16-tile buffer so any concrete within drift range suppresses the spawn
- Fixed lag when horde spawn corridors overlap water: `find_non_colliding_position` avoids entity bounding-box collisions but is tile-unaware, so it could return a water-tile position near the coast. Two-level fix: at the column level, `spawn_horde` now redirects water columns to the nearest land tile (up to 128 tiles away) via `util.find_land_near` rather than skipping them; at the entity level, a `safe_place` helper in `swarm.lua` validates the resolved position and retries with progressively wider scans (32 tiles → 128 tiles, 16-tile steps — analogous to picking a fresh horde spawn origin) before giving up. `WATER_TILES`, `is_water_tile`, and `find_land_near` are shared via `util.lua`
- Horde swarm clusters now scale in density with estimated horde size: per-column drain-tick allotments (~5-6 zombies) accumulate in per-column buckets and only flush into a cluster when the bucket reaches a size threshold — 10 for hordes ≥300, 20 for ≥1000, 40 for ≥3000, 80 for ≥9000. Small hordes (below 300) flush every tick as before. Partial buckets are flushed when the event ends so no zombies are silently discarded

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

## Credits

All original mods and their concepts belong to their respective authors. These forks exist solely for personal use to bring the mods up to date with Factorio 2.1 and to add quality-of-life changes.
