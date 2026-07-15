# Future Ideas

Potential improvements to investigate and implement later.

---

## Performance investigations

### a) Gleba enemies leaking into Zomboid handlers
`on_entity_damaged` is unfiltered and the new control.lua guard passes events to
`swarm.on_entity_damaged` and `melee.on_entity_damaged` whenever `entity.type == "unit"`.
Gleba pentapods are enemy units — they will pass this guard and invoke both handlers
(each exits quickly at the name-lookup early-out, but the calls still fire).

With heavy Gleba combat this could add measurable overhead. Check whether adding a
`planets.is_active(entity.surface)` guard at the top of `swarm.on_entity_damaged` and
`melee.on_entity_damaged` (or in the control.lua fan-out before calling them) would
eliminate Gleba event noise. The infection handler already has this guard.

### b) CustomRPGsystem — magic spell kill-handler performance
`rpg_fireball` and `rpg_hadouken` deal splash damage that can kill many enemies per
cast. Each killed entity fires `on_entity_died`. If the RPG kill handler does a
full player-grid scan per kill (the pattern that was fixed in CustomHeroWeapons), a
single spell cast in a dense horde could trigger dozens of expensive scans.

Audit `CustomRPGsystem/control.lua` (or wherever the kill-XP handler lives) for the
same all-players-grid-scan issue. Apply the same fix if found: cache the active
player → weapon/equipment mapping rather than scanning every player's armor grid on
each entity death.

### c) CustomHeroWeapons — personal tesla defense attack lag
The personal tesla defense fires chain lightning that jumps across many nearby
targets. Each jump may fire `on_entity_damaged` or `on_entity_died` for each hit
target. If the CustomHeroWeapons kill handler attributes hits per-target and
recomputes the grid slot lookup on each, a single tesla burst in a dense cluster
could fire many expensive callbacks.

Profile kill attribution cost during tesla defense use against large swarms. Check
whether the equipment kill counter is incremented once per attack cycle or once per
individual hit/kill, and whether any grid scan happens per kill.

### d) Reduce total Zomboid entity count on Nauvis
The sustained 5.5ms "Unit" engine cost scales directly with how many unit entities
are alive on Nauvis at once (clusters + individuals). Approaches to investigate:

- **Larger cluster floor**: raise the `⌊50 × evo⌋` horde cluster floor or
  `NEST_CLUSTER_MAX` so the same zombie population fits in fewer, denser entities.
  e.g. doubling the floor halves entity count at the cost of coarser cluster granularity.

- **Distant-cluster merging**: periodically scan for clusters that are far from the
  factory and from any player, and fold them into nearby clusters. Stranded zombies
  from past hordes contribute to entity count without causing gameplay pressure.

- **Hard cap on live cluster count**: track total cluster entity count in storage and
  refuse to create new clusters beyond a ceiling, folding overflow into existing ones.
  Complements the individual zombie cap already in place.

- **Faster sweep cadence for stranded units**: the 15-minute periodic sweep
  re-commands wandering units but doesn't eliminate them. A separate, more frequent
  scan (every 2–3 minutes) that merges clusters outside a radius of the factory
  centroid into nearby survivors could trim persistent stragglers without touching
  the active combat zone.

---

## CustomZomboid — minor known issues

*(low priority, no active work planned)*

- Night-variant sweep still creates/destroys entities for clusters near players at
  dusk/dawn (up to 150 per anchor per 60 ticks). Skipping the swap for clusters
  that are already charging a target (command state = attacking) would avoid
  unnecessary churn during active combat.
