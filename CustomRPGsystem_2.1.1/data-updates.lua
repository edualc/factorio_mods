
if settings.startup["charxpmod_enable_potion_loot"].value then
for _, spawner in pairs(data.raw["unit-spawner"]) do
	local loot = spawner.loot or {}
	table.insert ( loot , {type="item", name="rpg_level_up_potion",  amount_min = 1,  amount_max = 1,  independent_probability = 0.005}) 
	table.insert ( loot , {type="item", name="rpg_amnesia_potion",  amount_min = 1,  amount_max = 1,  independent_probability = 0.003})
	table.insert ( loot , {type="item", name="rpg_small_xp_potion",  amount_min = 1,  amount_max = 1,  independent_probability = 0.015})
	table.insert ( loot , {type="item", name="rpg_big_xp_potion",  amount_min = 1,  amount_max = 1,  independent_probability = 0.01})
	table.insert ( loot , {type="item", name="rpg_small_healing_potion",  amount_min = 1,  amount_max = 1,  independent_probability = 0.02})
	table.insert ( loot , {type="item", name="rpg_big_healing_potion",  amount_min = 1,  amount_max = 2,  independent_probability = 0.01})
	table.insert ( loot , {type="item", name="rpg_crafting_potion",  amount_min = 1,  amount_max = 2,  independent_probability = 0.01})
	table.insert ( loot , {type="item", name="rpg_speed_potion",  amount_min = 1,  amount_max = 2,  independent_probability = 0.01})
	if mods['death_curses'] then table.insert ( loot , {type="item", name="rpg_curse_cure_potion",  amount_min = 1,  amount_max = 1,  independent_probability = 0.02}) end
	spawner.loot = loot
	end
end
