-- Runs after all mods (including Space Age DLC) have finished loading their
-- prototypes. At that point data.raw contains every achievement type from both
-- base and Space Age, so a single pass is enough to cover both — no separate
-- "spage" mod needed (cheevos_spage was deprecated in 2.0.77 for the same reason).
--
-- allowed_without_fight = false is what Factorio uses to gate achievements behind
-- "no peaceful mode / no disabled enemies / default map settings" checks. Flipping
-- it to true for every achievement lets them unlock regardless of map settings.

for _, achievement_type in pairs(data.raw) do
	for _, achievement in pairs(achievement_type) do
		if achievement.allowed_without_fight == false then
			achievement.allowed_without_fight = true
		end
	end
end
