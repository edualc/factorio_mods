# Future Ideas

Potential improvements to investigate and implement later.

---

## CustomHeroWeapons (new mod idea)

### Hero-rank upgrades for player weapons and armor equipment
Mirror the CustomHeroTurrets rank system but for handheld weapons and damage-dealing
power armor equipment. Weapons gain XP from kills and progress through tiers (e.g.
rank 1–4), each rank increasing damage, fire rate, magazine size, range, or
type-specific stats depending on weapon type.

Weapons to cover (at minimum):
- Flamethrower (fluid ammo, fire damage)
- Tesla gun (electric damage)
- Rocket launcher / Rocket (explosive splash)
- Shotgun / Combat shotgun (physical, spread)
- Submachine gun / Pistol (basic physical)
- Personal laser defense equipment (electric, auto-targeting) — ranks increase
  range and shooting speed
- Personal tesla defense equipment (see new item below) — ranks increase range,
  shooting speed, and lightning fork chance

### New item: Personal tesla defense equipment
A power armor module analogous to personal laser defense but dealing chained
electric damage — the armor equivalent of the tesla gun. Uses the same fork
mechanic as tesla gun ammo (lightning chains to nearby targets on hit).

Per-rank progression:
- Range increases each rank
- Shooting speed increases each rank
- Fork chance increases each rank (e.g. 30% → 45% → 60% → 80%)

Recipe (same structure as personal laser defense):
- 20 processing units
- 5 low-density structures
- 5 tesla turrets

Unlocked by: the same technology that unlocks the tesla turret (`tesla-turret`
research), so it becomes available at the same progression point.

Implementation notes:
- XP tracking per weapon/equipment type stored in `storage` per player, similar to how
  HeroTurrets tracks kill counts per turret entity.
- Rank-up replaces the item in the player's inventory/gun slot or armor grid with a
  ranked variant (e.g. `flamethrower-rank-2`), same approach as HeroTurrets swapping
  entities on level-up.
- For equipment grid items, watch for `on_player_armor_inventory_changed` or poll the
  grid to detect when a ranked item needs swapping — there is no direct "equipment
  damaged" event, but kills can still be attributed to the player owning the armor.
- Ranked weapon prototypes defined in `data-final-fixes.lua` after all DLC
  weapon prototypes are loaded — same pattern as HeroTurrets and CustomCheevos.
- Consider integrating with CustomRPGsystem XP so weapon kills feed both the
  weapon's own rank and the player's RPG level.
- Rank insignia shown via a custom item icon overlay or item description suffix.

---

## CustomRPGsystem

### Protect robots from magic friendly-fire
`rpg_hadouken` and `rpg_fireball` are spawned as explosion entities, so their splash
can hit friendly robots (construction, logistic, combat) standing nearby when the
player casts a spell. The `on_entity_damaged` armor handler in `control.lua:1530`
only covers `entity.type == 'character'`, so robots get no protection.

This includes robots from modded sources such as the **Robo Jumpstart Bot** mod
(starter robot), which is a construction robot and shares the same entity type.
Any fix must cover all friendly robots regardless of which mod registered them.

Options:
- In `on_entity_damaged`, skip or cancel damage when the damaged entity is a
  friendly robot (`entity.type == 'construction-robot'` / `'logistic-robot'` /
  `'combat-robot'`) and the cause is a player character on the same force.
  This naturally covers vanilla and modded robots alike since it checks entity
  type, not prototype name.
- Alternatively, give robot prototypes a resistance entry for `rpg-magic` damage
  types in `data-final-fixes.lua` (similar to how CustomRobotsResistFire handles
  fire resistance) — cleaner if rpg magic uses a dedicated damage type, but
  requires iterating all robot prototypes including those added by other mods.
- Check whether `rpg-magic-shock` (ShockNear) can also reach robots: it uses
  `force=entity.force` (enemy force) so it currently cannot, but worth verifying
  if that filter ever changes.
