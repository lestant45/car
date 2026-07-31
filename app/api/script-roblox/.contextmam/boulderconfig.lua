-- Script Path: game:GetService("ReplicatedStorage").Modules.Boulders.BoulderConfig
-- Took 0s to decompile.
-- Executor: Potassium (v2.3.5)

-- Decompiled with Potassium's decompiler.

return {
    ORDER = { "Mossite", "Voltite", "Gildrite", "Rimeveil", "Nocturnite" },
    Boulders = {
        Mossite = {
            rarity = "Common",
            minPickaxeId = "TitaniumSpike",
            swingsAtGate = 240,
            countRange = { 8, 10 },
            scaleRange = { 1.4, 2.2 },
            crystalCount = { 8, 11 },
            tierWeights = { 0, 0, 0, 45, 45, 10 },
            runes = { {
                    id = "Luck",
                    weight = 50
                }, {
                    id = "Haste",
                    weight = 50
                } },
            runeCountWeights = {
                [4] = 35,
                [5] = 35,
                [6] = 20,
                [7] = 10
            }
        },
        Voltite = {
            rarity = "Uncommon",
            minPickaxeId = "CelestialApex",
            swingsAtGate = 400,
            countRange = { 5, 6 },
            scaleRange = { 1.5, 2.4 },
            crystalCount = { 10, 14 },
            tierWeights = { 0, 0, 0, 0, 65, 35 },
            runes = { {
                    id = "Storm",
                    weight = 40
                }, {
                    id = "Weight",
                    weight = 40
                }, {
                    id = "Luck",
                    weight = 10
                }, {
                    id = "Haste",
                    weight = 10
                } },
            runeCountWeights = {
                [5] = 30,
                [6] = 30,
                [7] = 25,
                [8] = 15
            }
        },
        Gildrite = {
            rarity = "Rare",
            minPickaxeId = "EclipseFang",
            swingsAtGate = 600,
            countRange = { 3, 3 },
            scaleRange = { 1.6, 2.6 },
            crystalCount = { 11, 15 },
            tierWeights = { 0, 0, 0, 0, 45, 55 },
            runes = { {
                    id = "Fortune",
                    weight = 32
                }, {
                    id = "Detonation",
                    weight = 32
                }, {
                    id = "Storm",
                    weight = 13
                }, {
                    id = "Weight",
                    weight = 13
                }, {
                    id = "Luck",
                    weight = 5
                }, {
                    id = "Haste",
                    weight = 5
                } },
            runeCountWeights = {
                [6] = 30,
                [7] = 30,
                [8] = 25,
                [9] = 15
            }
        },
        Rimeveil = {
            rarity = "Epic",
            minPickaxeId = "Voidreign",
            swingsAtGate = 910,
            countRange = { 2, 2 },
            scaleRange = { 1.7, 2.8 },
            crystalCount = { 13, 18 },
            tierWeights = { 0, 0, 0, 0, 55, 45 },
            runes = { {
                    id = "Preservation",
                    weight = 28
                }, {
                    id = "Warmth",
                    weight = 28
                }, {
                    id = "Fortune",
                    weight = 13
                }, {
                    id = "Detonation",
                    weight = 13
                }, {
                    id = "Storm",
                    weight = 6
                }, {
                    id = "Weight",
                    weight = 6
                }, {
                    id = "Luck",
                    weight = 3
                }, {
                    id = "Haste",
                    weight = 3
                } },
            runeCountWeights = {
                [8] = 30,
                [9] = 30,
                [10] = 25,
                [11] = 15
            }
        },
        Nocturnite = {
            rarity = "Legendary",
            minPickaxeId = "TheTerminus",
            swingsAtGate = 1440,
            countRange = { 1, 1 },
            scaleRange = { 1.9, 3.2 },
            crystalCount = { 16, 22 },
            tierWeights = { 0, 0, 0, 0, 45, 55 },
            runes = { {
                    id = "Excavator",
                    weight = 39
                }, {
                    id = "Colossus",
                    weight = 39
                }, {
                    id = "Preservation",
                    weight = 5
                }, {
                    id = "Warmth",
                    weight = 5
                }, {
                    id = "Fortune",
                    weight = 3
                }, {
                    id = "Detonation",
                    weight = 3
                }, {
                    id = "Storm",
                    weight = 1.5
                }, {
                    id = "Weight",
                    weight = 1.5
                }, {
                    id = "Luck",
                    weight = 1.5
                }, {
                    id = "Haste",
                    weight = 1.5
                } },
            runeCountWeights = {
                [9] = 25,
                [10] = 25,
                [11] = 20,
                [12] = 15,
                [13] = 10,
                [14] = 5
            }
        }
    },
    Spawn = {
        maxAttempts = 40,
        edgeMargin = 24,
        minYAboveBase = 8,
        burialMargin = 6,
        solidOccupancy = 0.92,
        minDistBetween = 60
    },
    Peek = {
        playerRange = 90,
        checkInterval = 2,
        exposedDrop = 0.75,
        releaseDrop = 0.12,
        settleSpeed = 0.6,
        settleTime = 1.5
    },
    Break = {
        milestones = 10,
        pieceFadeDelay = 4,
        pieceFadeTime = 2,
        wrongPickaxeMsg = "You need %s or better to break %s!",
        burstImpulse = { 18, 30 },
        finaleImpulse = { 45, 75 }
    },
    RuneDrop = {
        holdDuration = 1,
        popImpulse = { 12, 20 }
    },
    Sledge = {
        damageMult = 0.1,
        immuneMsg = "The Sledge Hammer can\'t break %s -- you need a pickaxe!",
        immune = {
            Nocturnite = true
        }
    }
};
