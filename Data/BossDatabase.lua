-- BossDatabase.lua
-- Banco de dados de bosses do Blox Fruits com posições aproximadas

local BossDatabase = {}

BossDatabase.Bosses = {
    -- FIRST SEA
    {
        name = "Gorilla King",
        sea = "FirstSea",
        level = 25,
        location = "Jungle",
        spawnFolder = "Jungle",
        position = Vector3.new(1518, 190, 1553),
        respawnTime = 300,
        drops = { "Exp", "Beli" },
    },
    {
        name = "Bobby",
        sea = "FirstSea",
        level = 35,
        location = "Pirate Village",
        spawnFolder = "PirateVillage",
        position = Vector3.new(-1340, 5, 215),
        respawnTime = 300,
        drops = { "Exp", "Beli" },
    },
    {
        name = "Yeti",
        sea = "FirstSea",
        level = 85,
        location = "Snow Island",
        spawnFolder = "SnowIsland",
        position = Vector3.new(1057, 263, -3220),
        respawnTime = 300,
        drops = { "Exp", "Beli" },
    },
    {
        name = "Mob Leader",
        sea = "FirstSea",
        level = 100,
        location = "Marine Fortress",
        spawnFolder = "MarineFortress",
        position = Vector3.new(-936, 15, -3615),
        respawnTime = 300,
        drops = { "Exp", "Beli" },
    },
    {
        name = "CyBorg",
        sea = "FirstSea",
        level = 125,
        location = "Skylands",
        spawnFolder = "Skylands",
        position = Vector3.new(-5075, 1105, -4855),
        respawnTime = 300,
        drops = { "Exp", "Beli" },
    },
    -- SECOND SEA
    {
        name = "Darkbeard",
        sea = "SecondSea",
        level = 1000,
        location = "Dark Arena",
        spawnFolder = "DarkArena",
        position = Vector3.new(-11200, 712, 2900),
        respawnTime = 3600,
        drops = { "Exp", "Dark Fragment", "Rumble" },
        requires = "Dark Scroll",
    },
    {
        name = "Order",
        sea = "SecondSea",
        level = 1250,
        location = "Cursed Ship",
        spawnFolder = "CursedShip",
        position = Vector3.new(-11240, 237, -4530),
        respawnTime = 1800,
        drops = { "Exp", "Beli", "Order Fist" },
    },
    -- THIRD SEA
    {
        name = "Stone",
        sea = "ThirdSea",
        level = 1500,
        location = "Floating Turtle",
        spawnFolder = "FloatingTurtle",
        position = Vector3.new(-15785, 345, -6535),
        respawnTime = 1200,
        drops = { "Exp", "Beli", "Tushita scroll" },
    },
    {
        name = "Island Empress",
        sea = "ThirdSea",
        level = 1875,
        location = "Hydra Island",
        spawnFolder = "HydraIsland",
        position = Vector3.new(5830, 400, -13470),
        respawnTime = 1800,
        drops = { "Exp", "Beli", "Fruit" },
    },
}

function BossDatabase:GetBySea(sea)
    local out = {}
    for _, b in ipairs(self.Bosses) do
        if b.sea == sea then table.insert(out, b) end
    end
    return out
end

function BossDatabase:GetByName(name)
    for _, b in ipairs(self.Bosses) do
        if b.name:lower() == name:lower() then return b end
    end
    return nil
end

function BossDatabase:GetAll()
    return self.Bosses
end

return BossDatabase
