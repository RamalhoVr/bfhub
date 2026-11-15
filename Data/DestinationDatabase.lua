-- DestinationDatabase.lua
local DestinationDatabase = {}

DestinationDatabase.Destinations = {
    -- FIRST SEA
    { name="Starter Island",     sea="FirstSea",  position=Vector3.new(980,  19,  1310) },
    { name="Marine Starter",     sea="FirstSea",  position=Vector3.new(-880, 5,   1437) },
    { name="Jungle",             sea="FirstSea",  position=Vector3.new(1518, 190, 1553) },
    { name="Pirate Village",     sea="FirstSea",  position=Vector3.new(-1340,5,   215)  },
    { name="Desert",             sea="FirstSea",  position=Vector3.new(940,  61,  -960) },
    { name="Snow Island",        sea="FirstSea",  position=Vector3.new(1057, 263,-3220) },
    { name="Marine Fortress",    sea="FirstSea",  position=Vector3.new(-936, 15, -3615) },
    { name="Skylands",           sea="FirstSea",  position=Vector3.new(-5075,1105,-4855)},
    { name="Prison",             sea="FirstSea",  position=Vector3.new(5110, 15,  1830) },
    { name="Colosseum",          sea="FirstSea",  position=Vector3.new(685,  16,  1540) },
    { name="Magma Village",      sea="FirstSea",  position=Vector3.new(-3350,22,  -2600)},
    { name="Upper Skylands",     sea="FirstSea",  position=Vector3.new(-10100,1680,-5900)},
    -- SECOND SEA
    { name="Kingdom of Rose",    sea="SecondSea", position=Vector3.new(-5160,20,  -3610)},
    { name="Green Zone",         sea="SecondSea", position=Vector3.new(-3150,80,  -6900)},
    { name="Graveyard",          sea="SecondSea", position=Vector3.new(-8830,13,  -6475)},
    { name="Snow Mountain",      sea="SecondSea", position=Vector3.new(-8530,750, -4000)},
    { name="Hot & Cold",         sea="SecondSea", position=Vector3.new(-10840,310,-5165)},
    { name="Cursed Ship",        sea="SecondSea", position=Vector3.new(-11240,237,-4530)},
    { name="Ice Castle",         sea="SecondSea", position=Vector3.new(-10240,900,-3730)},
    { name="Forgotten Island",   sea="SecondSea", position=Vector3.new(-14100,70, -5090)},
    -- THIRD SEA
    { name="Floating Turtle",    sea="ThirdSea",  position=Vector3.new(-15785,345,-6535)},
    { name="Hydra Island",       sea="ThirdSea",  position=Vector3.new(5830,  400,-13470)},
    { name="Great Tree",         sea="ThirdSea",  position=Vector3.new(-3615, 23, -15285)},
    { name="Haunted Castle",     sea="ThirdSea",  position=Vector3.new(5130,  30, -17045)},
    { name="Sea of Treats",      sea="ThirdSea",  position=Vector3.new(-10580,20, -16550)},
    { name="Cocoa Island",       sea="ThirdSea",  position=Vector3.new(-11130,22, -17695)},
}

function DestinationDatabase:GetBySea(sea)
    local out = {}
    for _, d in ipairs(self.Destinations) do
        if d.sea == sea then table.insert(out, d) end
    end
    return out
end

function DestinationDatabase:GetByName(name)
    for _, d in ipairs(self.Destinations) do
        if d.name:lower() == name:lower() then return d end
    end
    return nil
end

function DestinationDatabase:GetAll()
    return self.Destinations
end

return DestinationDatabase
