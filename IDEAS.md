# Future Ideas

Potential improvements to investigate and implement later.

---

## CustomHeroWeapons (new mod idea)

### Hero-rank upgrades for player weapons
Mirror the CustomHeroTurrets rank system but for handheld weapons. Weapons gain
XP from kills and progress through tiers (e.g. rank 1–4), each rank increasing
damage, fire rate, magazine size, or range depending on weapon type.

Weapons to cover (at minimum):
- Flamethrower (fluid ammo, fire damage)
- Tesla gun (electric damage)
- Rocket launcher / Rocket (explosive splash)
- Shotgun / Combat shotgun (physical, spread)
- Submachine gun / Pistol (basic physical)
- Personal laser defense equipment (electric, auto-targeting)

Implementation notes:
- XP tracking per weapon type stored in `storage` per player, similar to how
  HeroTurrets tracks kill counts per turret entity.
- Rank-up replaces the item in the player's inventory/gun slot with a ranked
  variant (e.g. `flamethrower-rank-2`), same approach as HeroTurrets swapping
  entities on level-up.
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

Options:
- In `on_entity_damaged`, skip or cancel damage when the damaged entity is a
  friendly robot (`entity.type == 'construction-robot'` / `'logistic-robot'` /
  `'combat-robot'`) and the cause is a player character on the same force.
- Alternatively, give robot prototypes a resistance entry for `rpg-magic` damage
  types in `data-final-fixes.lua` (similar to how CustomRobotsResistFire handles
  fire resistance) — cleaner if rpg magic uses a dedicated damage type.
- Check whether `rpg-magic-shock` (ShockNear) can also reach robots: it uses
  `force=entity.force` (enemy force) so it currently cannot, but worth verifying
  if that filter ever changes.
