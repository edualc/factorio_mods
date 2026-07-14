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

### Known limitations / future work

- **Kill count should be per item instance, not per weapon type.** Currently a
  single kill counter per player per weapon name is shared across all copies of
  that item (e.g. a stack of 10 personal tesla defenses all read the same count).
  Ideally each slottable item in the armor grid tracks its own kills independently,
  so two equipped copies of the same equipment can be at different ranks.
  CustomHeroTurrets solves this the same way: it reads `entity.kills` (a native
  engine counter on the placed turret) and persists it through pickup/placement via
  item tags (`item.set_tag("kills", entity.kills)` on deconstruct,
  `entity.kills = stack.get_tag("kills")` on place). Equipment items in the armor
  grid are also LuaItemStacks, so the same tag approach should transfer directly —
  store kills in the item tag, read it back when the equipment is placed into a grid.

- **Audit CustomRPGsystem magic for the same on_entity_died performance problem.**
  The rpg_fireball / rpg_hadouken spells likely fire many kills per cast via splash,
  each triggering on_entity_died. Check whether the magic kill handler has the same
  all-players grid-scan issue that was found and fixed in CustomHeroWeapons, and
  apply the same caching approach if so.

