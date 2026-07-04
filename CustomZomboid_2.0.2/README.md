# CustomZomboid `2.0.2`

Turns biters into a zombie horde. Destroyed buildings spawn new zombies, infection spreads through your logistics network, and corpses reanimate. Requires Space Age.

**Original mod:** [Zomboid](https://mods.factorio.com/mod/Zomboid) by **Martin Howarth**

## Changes from original

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
- Fixed horde and night-trickle zombies spawning on water tiles: added a `WATER_TILES` name lookup (covering all vanilla water variants and `out-of-map`) checked before spawning in both `is_safe_spawn()` (night trickle) and `spawn_horde()` (directional horde wall columns)
- Fixed horde warning marker pointing at water: `begin_active()` now redirects the origin to the nearest land tile before placing the marker and printing the GPS message
- Fixed large hordes freezing when units cluster: groups are now reused across bursts (one per column); new members join the already-marching group instead of forming their own
- Fixed night-trickle zombies potentially spawning on concrete via position drift
- Fixed night-trickle concrete check: `is_safe_spawn` previously checked only the exact ring point, but `find_non_colliding_position` can move the actual spawn up to 16 tiles away. Now uses `find_tiles_filtered` with a 16-tile buffer so any concrete within drift range suppresses the spawn
- Balance: swarm cluster kills now scale with damage for all weapon types — `floor(dealt / single_health)` kills per hit instead of always 1; attack damage and attack speed are now both meaningful instead of only attack speed mattering
- Fixed spitter cluster max_health incorrectly divided by 4 (1000→250): spitter cluster names contain "spitter" which caused the individual-health divisor loop to hit them, making them one-shottable by high-damage hero turrets before the damage handler could run
- Balance: biter and spitter movement speed divisor reduced 4→2 (half vanilla day speed; night speedup brings them to full vanilla at night) — previously too slow to close the gap or reposition against long-range turrets
- Balance: spitter attack range boosted to minimum 20 tiles (was ~15 vanilla) — matches hero turret range (18-27+) so spitters can fire back instead of being kited
- Fixed `on_configuration_changed` mid-horde state: `s.pending_spawn` and `s.origin` are now cleared so a save loaded mid-forced-horde doesn't keep draining into the old origin
- Performance: `swarm.fold()` cache TTL extended from 1 tick to 60 ticks — the cache now stays warm across the entire spoilage burst when thousands of corpses expire over many consecutive ticks
- Performance: night-variant sweep period raised 30→60 ticks, sweep radius reduced 48→32 tiles (~56% smaller search area), and a per-anchor swap cap of 150 units added — together these cut the worst-case entity-recreation cost by ~75% during large horde assaults at night
- Performance: horde warning map tag is now updated in-place (`.text` / `.position` writes) instead of destroy+create every 60 ticks
- Performance: `horde_population()` result is cached for 120 ticks so the full iteration over the live-horde table runs at most once per 2 seconds
- Performance: factory centroid scan in `factory_reference` now excludes characters, units, item entities, resources, and corpses at the API level
- Performance: character health snapshot in `process_players` uses a cached entity table (rebuilt only on player join/leave/death) instead of `find_entities_filtered` every tick
- Performance: large horde spawns (9k+) no longer lag the game; bursts are queued and drained at 50 entities per tick, spreading the `find_non_colliding_position` cost across ~12 ticks
- Performance: per-column march targets are now precomputed once at horde-event start and cached in `s.column_targets`, eliminating the `nearest_building` O(N_buildings) scan per column per drain tick
- Performance: `factory_reference` result is cached for 5 minutes so rapid `/zomtorio-horde` invocations do not each pay the full `find_entities_filtered` scan
- Horde swarm clusters now scale in density with estimated horde size: per-column drain-tick allotments accumulate in per-column buckets and only flush into a cluster when the bucket reaches a size threshold (10 for ≥300, 20 for ≥1000, 40 for ≥3000, 80 for ≥9000)
