# CustomRPGsystem `2.1.2`

Adds a basic RPG system to the game — XP gain, level-ups, and skills for the player character.

**Original mod:** [RPGsystem](https://mods.factorio.com/mod/RPGsystem) by **MFerrari**

## Changes from original

- Ported to Factorio 2.1
- CustomZomboid integration: when a Zomtorio swarm cluster is killed, XP is calculated from the cluster's full zombie population (via the `CustomZomboid.get_cluster_kills` remote call) multiplied by a single zombie's XP value, rather than counting the cluster as one kill. Covers all swarm variants including their faster night forms, which map back to the same base zombie type for XP purposes
- Fixed RPG magic effects (rpg_fireaball, rpg_hadouken) dealing unmitigated friendly-fire splash damage despite 100% armor: explosion entities are already gone by the time `on_entity_damaged` fires, making `cause.valid` false and skipping the armor heal-back. Armor now applies unconditionally before the cause guard
- Fixed rpg_fireaball and rpg_hadouken splash damage hitting the caster's own construction/logistic/combat robots: the nested area-damage trigger had no force filter, so it hit every entity in radius regardless of allegiance. Both spells' area splash now uses `force = "enemy"` (a `ForceCondition` matching only forces that would attack the caster's force), the same mechanism vanilla area weapons use to avoid friendly fire — robots are excluded at the source instead of needing an after-the-fact heal-back like the character mitigation above
