-- FruitDatabase.lua
local FruitDatabase = {}

FruitDatabase.Fruits = {
    -- Common
    { name="Bomb",       rarity="Common",    type="Paramecia", value=5000    },
    { name="Spike",      rarity="Common",    type="Paramecia", value=7500    },
    { name="Chop",       rarity="Common",    type="Paramecia", value=30000   },
    { name="Spring",     rarity="Common",    type="Paramecia", value=60000   },
    { name="Kilo",       rarity="Common",    type="Paramecia", value=5000    },
    { name="Smoke",      rarity="Uncommon",  type="Logia",     value=100000  },
    { name="Spin",       rarity="Common",    type="Paramecia", value=7500    },
    -- Uncommon
    { name="Flame",      rarity="Uncommon",  type="Logia",     value=250000  },
    { name="Ice",        rarity="Uncommon",  type="Logia",     value=350000  },
    { name="Sand",       rarity="Uncommon",  type="Logia",     value=420000  },
    { name="Dark",       rarity="Rare",      type="Logia",     value=500000  },
    { name="Diamond",    rarity="Rare",      type="Paramecia", value=600000  },
    { name="Light",      rarity="Rare",      type="Logia",     value=650000  },
    { name="Rubber",     rarity="Rare",      type="Paramecia", value=750000  },
    { name="Barrier",    rarity="Rare",      type="Paramecia", value=800000  },
    -- Rare
    { name="Magma",      rarity="Rare",      type="Logia",     value=850000  },
    { name="Quake",      rarity="Rare",      type="Paramecia", value=1000000 },
    { name="Human",      rarity="Rare",      type="Paramecia", value=1000000 },
    { name="Buddha",     rarity="Legendary", type="Zoan",      value=1200000 },
    { name="Love",       rarity="Legendary", type="Paramecia", value=1300000 },
    -- Legendary
    { name="Spider",     rarity="Legendary", type="Paramecia", value=1500000 },
    { name="Sound",      rarity="Legendary", type="Paramecia", value=1900000 },
    { name="Phoenix",    rarity="Legendary", type="Zoan",      value=1800000 },
    { name="Rumble",     rarity="Legendary", type="Logia",     value=2100000 },
    { name="Pain",       rarity="Legendary", type="Paramecia", value=2300000 },
    { name="Blizzard",   rarity="Legendary", type="Logia",     value=2400000 },
    -- Mythical
    { name="Gravity",    rarity="Mythical",  type="Paramecia", value=2500000 },
    { name="Mammoth",    rarity="Mythical",  type="Zoan",      value=2700000 },
    { name="T-Rex",      rarity="Mythical",  type="Zoan",      value=2750000 },
    { name="Shadow",     rarity="Mythical",  type="Paramecia", value=2900000 },
    { name="Venom",      rarity="Mythical",  type="Paramecia", value=3000000 },
    { name="Control",    rarity="Mythical",  type="Paramecia", value=3200000 },
    { name="Spirit",     rarity="Mythical",  type="Paramecia", value=3400000 },
    { name="Dragon",     rarity="Mythical",  type="Zoan",      value=3500000 },
    { name="Leopard",    rarity="Mythical",  type="Zoan",      value=5000000 },
}

function FruitDatabase:GetByName(name)
    for _, f in ipairs(self.Fruits) do
        if f.name:lower() == name:lower() then return f end
    end
    return nil
end

function FruitDatabase:GetByRarity(rarity)
    local out = {}
    for _, f in ipairs(self.Fruits) do
        if f.rarity == rarity then table.insert(out, f) end
    end
    return out
end

function FruitDatabase:GetAll() return self.Fruits end

function FruitDatabase:GetRarityOrder()
    return { "Common", "Uncommon", "Rare", "Legendary", "Mythical" }
end

return FruitDatabase
