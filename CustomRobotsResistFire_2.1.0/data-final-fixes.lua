local fire_resistance = 100

local function apply_fire_immunity(entity_type)
    for _, entity in pairs(data.raw[entity_type] or {}) do
        entity.resistances = entity.resistances or {}
        local inserted = false
        for _, resistance in pairs(entity.resistances) do
            if resistance.type == 'fire' then
                resistance.percent = fire_resistance
                inserted = true
                break
            end
        end
        if not inserted then
            table.insert(entity.resistances, { type = 'fire', percent = fire_resistance })
        end
    end
end

apply_fire_immunity('logistic-robot')
apply_fire_immunity('combat-robot')
apply_fire_immunity('construction-robot')
apply_fire_immunity('transport-belt')
apply_fire_immunity('underground-belt')
apply_fire_immunity('splitter')
apply_fire_immunity('linked-belt')
apply_fire_immunity('loader')
apply_fire_immunity('loader-1x1')
