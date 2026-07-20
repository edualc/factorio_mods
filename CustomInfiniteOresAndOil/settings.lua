-- setting_name, setting_order, is_space_age
local mod_settings = {
  { "refill-coal"       , "ca", false },
  { "refill-copper"     , "cb", false },
  { "refill-iron"       , "cc", false },
  { "refill-stone"      , "cd", false },
  { "refill-uranium"    , "ce", false },
  { "refill-calcite"    , "cf", true  },
  { "refill-tungsten"   , "cg", true  },
  { "refill-scrap"      , "ch", true  },
  { "refill-lithium"    , "ci", true  },
  { "refill-modded-ores", "cz", false }
}

-- These need to be startup settings (not runtime-global) because they are
-- read from data-final-fixes.lua, which only has access to settings.startup
local function add_bool_setting(setting_name, setting_order, is_space_age)
  if is_space_age and not mods['space-age'] then
    return
  end
  data:extend({{
    name = setting_name,
    type = "bool-setting",
    setting_type = "startup",
    default_value = true,
    order = setting_order
  }})
end

for setting = 1, #mod_settings do
  add_bool_setting(
    mod_settings[setting][1], -- setting_name
    mod_settings[setting][2], -- setting_order
    mod_settings[setting][3]  -- is_space_age
  )
end
