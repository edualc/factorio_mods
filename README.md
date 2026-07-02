# Factorio Mods — Custom Forks

Personal forks of several Factorio mods, updated for compatibility with Factorio **2.1** and extended with additional features and fixes.

## Mods

### CustomHeroTurrets `2.1.0`
Turrets that level up based on kills, with a rank insignia overlay and per-rank stat buffs. Works across modded turrets, not just vanilla ones.

**Original mod:** [HeroTurrets](https://mods.factorio.com/mod/HeroTurrets) by **PixelWhipped**

**Changes from original:**
- Ported to Factorio 2.0/2.1: renamed `global` to `storage`, updated recipe ingredient format, removed deprecated `hr_version` sprite definitions and `icon_mipmaps`, fixed `on_player_joined_game` missing `defines.events` prefix, removed stale `landmine_on_gui_click` reference that was silently breaking GUI click handling
- Fixed flame (flamethrower) turrets not receiving hero rank variants: `is_unkown_nesw()` only covered `ammo-turret` and `electric-turret`; Factorio 2.x flamethrower turrets use `graphics_set` instead of the legacy NESW `base_picture` format, so they were silently skipped and never appeared in the Factoriopedia. Adding `fluid-turret` to the guard lets them go through the badge-overlay path like other turrets

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

---

### CustomZomboid `2.0.1`
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
- Melee technologies: Tier 1 unlocks swarm multi-kill, Tier 2 strengthens it and adds Double Tap toggle (corpse-free kills, on by default once researched)
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
- Fixed horde and night-trickle zombies spawning on water tiles: added a `WATER_TILES` name lookup (covering all vanilla water variants and `out-of-map`) checked before spawning in both `is_safe_spawn()` (night trickle) and `spawn_horde()` (directional horde wall columns)

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
