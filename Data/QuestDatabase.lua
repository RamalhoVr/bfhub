-- QuestDatabase.lua
local QuestDatabase = {}

QuestDatabase.Quests = {
    -- FIRST SEA
    { name="Defeat Bandits",       sea="FirstSea", level=5,   target="Bandit",        count=8,  npc="Quest Giver", npcPos=Vector3.new(975,19,1304) },
    { name="Defeat Pirates",       sea="FirstSea", level=15,  target="Pirate",        count=8,  npc="Quest Giver", npcPos=Vector3.new(-1340,5,215) },
    { name="Defeat Monkeys",       sea="FirstSea", level=25,  target="Monkey",        count=10, npc="Quest Giver", npcPos=Vector3.new(1518,190,1553) },
    { name="Defeat Desert Bandits",sea="FirstSea", level=70,  target="Desert Bandit", count=10, npc="Quest Giver", npcPos=Vector3.new(940,61,-960) },
    { name="Defeat Snowmen",       sea="FirstSea", level=85,  target="Snowman",       count=10, npc="Quest Giver", npcPos=Vector3.new(1057,263,-3220) },
    { name="Defeat Prisoners",     sea="FirstSea", level=90,  target="Prisoner",      count=10, npc="Quest Giver", npcPos=Vector3.new(5110,15,1830) },
    -- SECOND SEA
    { name="Defeat Toga Warriors", sea="SecondSea",level=1000,target="Toga Warrior",  count=10, npc="Quest Giver", npcPos=Vector3.new(-5160,20,-3610) },
    { name="Defeat Forest Pirates",sea="SecondSea",level=1050,target="Forest Pirate", count=10, npc="Quest Giver", npcPos=Vector3.new(-3150,80,-6900) },
    -- THIRD SEA
    { name="Defeat Monsterocean",  sea="ThirdSea", level=1500,target="Monsterocean",  count=10, npc="Quest Giver", npcPos=Vector3.new(-15785,345,-6535) },
    { name="Defeat Island Natives",sea="ThirdSea", level=1875,target="Island Native", count=10, npc="Quest Giver", npcPos=Vector3.new(5830,400,-13470) },
}

function QuestDatabase:GetBySea(sea)
    local out = {}
    for _, q in ipairs(self.Quests) do
        if q.sea == sea then table.insert(out, q) end
    end
    return out
end

function QuestDatabase:GetByLevel(level)
    local best = nil
    for _, q in ipairs(self.Quests) do
        if q.level <= level then
            if not best or q.level > best.level then best = q end
        end
    end
    return best
end

function QuestDatabase:GetAll() return self.Quests end

return QuestDatabase
