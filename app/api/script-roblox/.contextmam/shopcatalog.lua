-- Script Path: game:GetService("ReplicatedStorage").Modules.Shop.ShopCatalog
-- Took 0s to decompile.
-- Executor: Potassium (v2.3.5)

-- Decompiled with Potassium's decompiler.

local u1 = {
    Pickaxes = {
        {
            id = "RustyScrapper",
            toolName = "Rusty Scrapper",
            name = "Rusty Scrapper",
            desc = "A bent shard of scrap metal. Embarrassing but it works.",
            price = 0,
            stats = {
                DigPower = 1,
                MaterialTier = 1
            }
        },
        {
            id = "WeatheredWood",
            toolName = "Weathered Wood",
            name = "Weathered Wood",
            desc = "Splinters in your palm. Still better than the scrap.",
            price = 25,
            stats = {
                DigPower = 1.2,
                MaterialTier = 1
            }
        },
        {
            id = "ChippedStone",
            toolName = "Chipped Stone",
            name = "Chipped Stone",
            desc = "Cave-man tech. Knapped from a rock face.",
            price = 250,
            stats = {
                DigPower = 1.4,
                MaterialTier = 1
            }
        },
        {
            id = "HardenedIron",
            toolName = "Hardened Iron",
            name = "Hardened Iron",
            desc = "First real metal. Bites into slate and basalt now.",
            price = 2500,
            stats = {
                DigPower = 1.6,
                MaterialTier = 2
            }
        },
        {
            id = "CopperPick",
            toolName = "Copper Pick",
            name = "Copper Pick",
            desc = "Shines orange in the cave light. Solid mid-tier swing.",
            price = 24000,
            stats = {
                DigPower = 1.8,
                MaterialTier = 2
            }
        },
        {
            id = "ReinforcedSteel",
            toolName = "Reinforced Steel",
            name = "Reinforced Steel",
            desc = "Machined edge. Sturdy through long sessions.",
            price = 220000,
            stats = {
                DigPower = 2,
                MaterialTier = 2
            }
        },
        {
            id = "TitaniumSpike",
            toolName = "Titanium Spike",
            name = "Titanium Spike",
            desc = "Aerospace-grade. Light, fast, surgical.",
            price = 1900000,
            stats = {
                DigPower = 2.2,
                MaterialTier = 2
            }
        },
        {
            id = "FrostbitePick",
            toolName = "Frostbite Pick",
            name = "Frostbite Pick",
            desc = "Cold-forged for the death zone. Glaciers crack open.",
            price = 16000000,
            stats = {
                DigPower = 2.4,
                MaterialTier = 3
            }
        },
        {
            id = "EmeraldCarver",
            toolName = "Emerald Carver",
            name = "Emerald Carver",
            desc = "Gemstone edge that never dulls. Carves through anything.",
            price = 40000000,
            stats = {
                DigPower = 2.6,
                MaterialTier = 3
            }
        },
        {
            id = "VolcanoBasalt",
            toolName = "Volcano Basalt",
            name = "Volcano Basalt",
            desc = "Forged in lava veins. The mountain trembles.",
            price = 90000000,
            stats = {
                DigPower = 2.8,
                MaterialTier = 3
            }
        },
        {
            id = "ObsidianEdge",
            toolName = "Obsidian Edge",
            name = "Obsidian Edge",
            desc = "Volcanic glass honed to a razor. Cuts where basalt cracks.",
            price = 200000000,
            stats = {
                DigPower = 3,
                MaterialTier = 3
            }
        },
        {
            id = "TempestPick",
            toolName = "Tempest Pick",
            name = "Tempest Pick",
            desc = "Crackles with raw solar-storm energy. Strikes like thunder.",
            price = 450000000,
            stats = {
                DigPower = 3.2,
                MaterialTier = 3
            }
        },
        {
            id = "CelestialApex",
            toolName = "Celestial Apex",
            name = "Celestial Apex",
            desc = "Forged from condensed starlight. The peak. Nothing surpasses it.",
            price = 1000000000,
            stats = {
                DigPower = 4,
                MaterialTier = 3
            }
        },
        {
            id = "AstralRend",
            toolName = "Astral Rend",
            name = "Astral Rend",
            desc = "Tears the veil between stone and stars. Reality frays at its edge.",
            price = 5000000000,
            stats = {
                DigPower = 5,
                MaterialTier = 3
            }
        },
        {
            id = "EclipseFang",
            toolName = "Eclipse Fang",
            name = "Eclipse Fang",
            desc = "A bite of pure shadow stolen from a dying sun.",
            price = 25000000000,
            stats = {
                DigPower = 6,
                MaterialTier = 3
            }
        },
        {
            id = "NebularThrone",
            toolName = "Nebular Throne",
            name = "Nebular Throne",
            desc = "Carved from a collapsed nebula. Whole galaxies bow to its swing.",
            price = 100000000000,
            stats = {
                DigPower = 7.5,
                MaterialTier = 3
            }
        },
        {
            id = "Voidreign",
            toolName = "Voidreign",
            name = "Voidreign",
            desc = "The void does not dig. It simply removes.",
            price = 500000000000,
            stats = {
                DigPower = 9,
                MaterialTier = 3
            }
        },
        {
            id = "Singularity",
            toolName = "Singularity",
            name = "Singularity",
            desc = "Infinite mass, zero mercy. The mountain falls INTO it.",
            price = 2500000000000,
            stats = {
                DigPower = 10.5,
                MaterialTier = 3
            }
        },
        {
            id = "TheTerminus",
            toolName = "The Terminus",
            name = "The Terminus",
            desc = "The last pickaxe. After this, there is nothing left to mine.",
            price = 10000000000000,
            stats = {
                DigPower = 12,
                MaterialTier = 3
            }
        },
        {
            id = "SharkPickaxe",
            toolName = "Shark Pickaxe",
            name = "Shark Pickaxe",
            desc = "CHOMP. An admin\'s apex predator. Bites through anything.",
            price = 0,
            adminOnly = true,
            stats = {
                DigPower = 5.5,
                MaterialTier = 3
            }
        },
        {
            id = "DiamondPickaxe",
            toolName = "Diamond Pickaxe",
            name = "Diamond Pickaxe",
            desc = "Gamepass exclusive. Cuts cleaner than the rest.",
            price = 0,
            stats = {
                DigPower = 2.5,
                MaterialTier = 3
            }
        }
    },
    Shovels = {
        {
            id = "SplinteredPaddle",
            toolName = "Splintered Paddle",
            name = "Splintered Paddle",
            desc = "A snapped boat oar. Barely scoops dirt.",
            price = 0,
            stats = {
                DigPower = 1
            }
        },
        {
            id = "HubcapScooper",
            toolName = "Hubcap Scooper",
            name = "Hubcap Scooper",
            desc = "Stripped hubcap on a stick. Surprisingly effective.",
            price = 400,
            stats = {
                DigPower = 1.2
            }
        },
        {
            id = "TrenchTrowel",
            toolName = "Trench Trowel",
            name = "Trench Trowel",
            desc = "Wartime gardener\'s pick. Sharp at the tip.",
            price = 1000,
            stats = {
                DigPower = 1.4
            }
        },
        {
            id = "FarmsteaderSpade",
            toolName = "Farmsteader Spade",
            name = "Farmsteader Spade",
            desc = "The real deal. Worked a hundred acres before you got it.",
            price = 2500,
            stats = {
                DigPower = 1.7
            }
        },
        {
            id = "AvalancheBlade",
            toolName = "Avalanche Blade",
            name = "Avalanche Blade",
            desc = "Wide blade for snow work. Moves piles fast.",
            price = 5000,
            stats = {
                DigPower = 2
            }
        },
        {
            id = "FossilExcavator",
            toolName = "Fossil Excavator",
            name = "Fossil Excavator",
            desc = "Archaeologist\'s tool. Precise, doesn\'t break what you uncover.",
            price = 9000,
            stats = {
                DigPower = 2.3
            }
        },
        {
            id = "CarbonTrowel",
            toolName = "Carbon Trowel",
            name = "Carbon Trowel",
            desc = "Carbon-fiber composite. Weighs nothing, swings forever.",
            price = 14000,
            stats = {
                DigPower = 2.6
            }
        },
        {
            id = "PlasmaExcavator",
            toolName = "Plasma Excavator",
            name = "Plasma Excavator",
            desc = "Glowing edge. Vaporizes soft soil on contact.",
            price = 22000,
            stats = {
                DigPower = 2.9
            }
        },
        {
            id = "SapphireShard",
            toolName = "Sapphire Shard",
            name = "Sapphire Shard",
            desc = "Crystalline blade. Mirror-clean cuts through any soil.",
            price = 38000,
            stats = {
                DigPower = 3.2
            }
        },
        {
            id = "HellfireSpade",
            toolName = "Hellfire Spade",
            name = "Hellfire Spade",
            desc = "Burns through dirt like it owes the spade money. Endgame.",
            price = 75000,
            stats = {
                DigPower = 3.5
            }
        }
    },
    Backpacks = {
        {
            id = "MountainPack",
            accessoryName = "Mountain Pack",
            name = "Mountain Pack",
            desc = "Classic canvas. The one you start with.",
            price = 0,
            backpackIndex = 1,
            stats = {
                WeightLimit = 25
            }
        },
        {
            id = "RidgeRucksack",
            accessoryName = "Ridge Rucksack",
            name = "Ridge Rucksack",
            desc = "Tan leather. Holds more than it looks.",
            price = 400,
            backpackIndex = 2,
            stats = {
                WeightLimit = 45
            }
        },
        {
            id = "ScoutSatchel",
            accessoryName = "Scout Satchel",
            name = "Scout Satchel",
            desc = "Two-tone with a strap dagger. Light and quick.",
            price = 1000,
            backpackIndex = 3,
            stats = {
                WeightLimit = 75
            }
        },
        {
            id = "CliffTactical",
            accessoryName = "Cliff Tactical",
            name = "Cliff Tactical",
            desc = "Camo MOLLE. Strapped for serious hauls.",
            price = 2500,
            backpackIndex = 4,
            stats = {
                WeightLimit = 120
            }
        },
        {
            id = "MidnightOperator",
            accessoryName = "Midnight Operator",
            name = "Midnight Operator",
            desc = "Stealth black. Cold-night climber\'s pick.",
            price = 5000,
            backpackIndex = 5,
            stats = {
                WeightLimit = 170
            }
        },
        {
            id = "PeakExpedition",
            accessoryName = "Peak Expedition",
            name = "Peak Expedition",
            desc = "Tall reinforced frame. Long-haul ready.",
            price = 9000,
            backpackIndex = 6,
            stats = {
                WeightLimit = 230
            }
        },
        {
            id = "SummitCamper",
            accessoryName = "Summit Camper",
            name = "Summit Camper",
            desc = "Comes with the bedroll. Built for overnight summits.",
            price = 14000,
            backpackIndex = 7,
            stats = {
                WeightLimit = 290
            }
        },
        {
            id = "ForestHiker",
            accessoryName = "Forest Hiker",
            name = "Forest Hiker",
            desc = "Wide camo frame. Stable carry on uneven ground.",
            price = 22000,
            backpackIndex = 8,
            stats = {
                WeightLimit = 360
            }
        },
        {
            id = "RescuePack",
            accessoryName = "Rescue Pack",
            name = "Rescue Pack",
            desc = "Comes with a strapped axe. Built for the worst.",
            price = 38000,
            backpackIndex = 9,
            stats = {
                WeightLimit = 460
            }
        },
        {
            id = "AlpineMonster",
            accessoryName = "Alpine Monster",
            name = "Alpine Monster",
            desc = "The biggest. Carries a small mountain on its own.",
            price = 75000,
            backpackIndex = 10,
            stats = {
                WeightLimit = 600
            }
        },
        {
            id = "BedrockHauler",
            accessoryName = "Bedrock Hauler",
            name = "Bedrock Hauler",
            desc = "Reinforced to haul boulder-sized hauls without a groan.",
            price = 250000,
            backpackIndex = 11,
            stats = {
                WeightLimit = 850
            }
        },
        {
            id = "BadlandsPack",
            accessoryName = "Badlands Pack",
            name = "Badlands Pack",
            desc = "Built for the deep hunt. Swallows a full boulder\'s shower.",
            price = 750000,
            backpackIndex = 12,
            stats = {
                WeightLimit = 1200
            }
        },
        {
            id = "FrostbitePack",
            accessoryName = "Frostbite Pack",
            name = "Frostbite Pack",
            desc = "The apex hauler. Nothing you dig will ever fill it.",
            price = 2000000,
            backpackIndex = 13,
            stats = {
                WeightLimit = 1700
            }
        }
    },
    Gear = { {
            id = "JacketBasic",
            name = "Wool Jacket",
            desc = "Cheap but gets you started. Good up to mid-altitude.",
            price = 250,
            stats = {
                Warmth = 1,
                IceGrip = 0
            }
        }, {
            id = "JacketInsulated",
            name = "Insulated Parka",
            desc = "Down-filled. Keeps you alive past the snow line.",
            price = 1500,
            stats = {
                Warmth = 2,
                IceGrip = 0
            }
        }, {
            id = "JacketExpedition",
            name = "Expedition Suit",
            desc = "Summit-grade. Endure the Death Zone.",
            price = 7500,
            stats = {
                Warmth = 3,
                IceGrip = 0
            }
        }, {
            id = "BootsBasic",
            name = "Hiking Boots",
            desc = "Standard footing. Slips on glacier.",
            price = 150,
            stats = {
                Warmth = 0,
                IceGrip = 1
            }
        }, {
            id = "BootsCrampons",
            name = "Crampons",
            desc = "Metal spikes grip ice. Much less sliding.",
            price = 1200,
            stats = {
                Warmth = 0,
                IceGrip = 2
            }
        }, {
            id = "BootsAlpine",
            name = "Alpine Boots",
            desc = "Pro-grade. Glaciers can\'t stop you.",
            price = 5000,
            stats = {
                Warmth = 1,
                IceGrip = 3
            }
        } },
    RarityNames = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Empyrean", "Zenith", "Infinity", "Ultima" },
    PickaxeRarityRank = {
        RustyScrapper = 1,
        WeatheredWood = 1,
        ChippedStone = 2,
        HardenedIron = 3,
        CopperPick = 3,
        ReinforcedSteel = 4,
        TitaniumSpike = 4,
        FrostbitePick = 5,
        EmeraldCarver = 5,
        VolcanoBasalt = 6,
        ObsidianEdge = 6,
        TempestPick = 7,
        CelestialApex = 7,
        AstralRend = 8,
        EclipseFang = 8,
        NebularThrone = 9,
        Voidreign = 9,
        Singularity = 10,
        TheTerminus = 11,
        DiamondPickaxe = 5
    }
};

function u1.getRarityRank(p2) -- Line: 405
    -- upvalues: u1 (copy)
    return u1.PickaxeRarityRank[p2] or 1;
end;

function u1.rarityName(p3) -- Line: 408
    -- upvalues: u1 (copy)
    return u1.RarityNames[p3] or "Common";
end;

function u1.getCategory(p4) -- Line: 412
    -- upvalues: u1 (copy)
    if p4 == "Pickaxes" then
        return u1.Pickaxes;
    end;

    if p4 == "Shovels" then
        return u1.Shovels;
    end;

    if p4 == "Backpacks" then
        return u1.Backpacks;
    end;

    if p4 == "Gear" then
        return u1.Gear;
    end;

    return nil;
end;

function u1.findItem(p5) -- Line: 420
    -- upvalues: u1 (copy)
    for _, v in ipairs({
        u1.Pickaxes,
        u1.Shovels,
        u1.Backpacks,
        u1.Gear
    }) do
        for _, v2 in ipairs(v) do
            if v2.id == p5 then
                return v2;
            end;
        end;
    end;

    return nil;
end;

return u1;
