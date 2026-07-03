# CustomPUMP `2.2.1`

Adds a selection tool to auto-plan pumpjack and pipe layouts for oil fields. Select wells, PUMP places everything optimally using A* pathfinding.

**Original mod:** [P.U.M.P.](https://mods.factorio.com/mod/pump) by **Xcone**

## Changes from original

- A* node key changed from string concatenation (`x .. "," .. y`) to integer arithmetic (`x + y * 1e9`): eliminates a heap string allocation on every node visit during pathfinding, reducing GC pressure proportionally to field size. No behavioral change — keys remain unique for all valid map coordinates
