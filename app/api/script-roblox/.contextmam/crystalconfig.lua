-- Script Path: game:GetService("ReplicatedStorage").Modules.Crystals.CrystalConfig
-- Took 0.01s to decompile.
-- Executor: Potassium (v2.3.5)

-- Decompiled with Potassium's decompiler.

local u26 = {
    Tiers = {
        {
            name = "Common",
            glow = 0,
            pickupHold = 1,
            value = 10,
            color = Color3.fromRGB(220, 195, 140),
            material = Enum.Material.Sand
        },
        {
            name = "Uncommon",
            glow = 0.4,
            pickupHold = 1.5,
            value = 70,
            color = Color3.fromRGB(110, 190, 240),
            material = Enum.Material.Glass
        },
        {
            name = "Rare",
            glow = 0.7,
            pickupHold = 2,
            value = 500,
            color = Color3.fromRGB(80, 240, 220),
            material = Enum.Material.Glass
        },
        {
            name = "Epic",
            glow = 1,
            pickupHold = 2.8,
            value = 4500,
            color = Color3.fromRGB(170, 100, 255),
            material = Enum.Material.Neon
        },
        {
            name = "Legendary",
            glow = 1.5,
            pickupHold = 4,
            value = 73291,
            color = Color3.fromRGB(255, 80, 180),
            material = Enum.Material.Neon
        },
        {
            name = "Mythic",
            glow = 2.2,
            pickupHold = 5,
            value = 2588162,
            color = Color3.fromRGB(190, 70, 255),
            material = Enum.Material.Neon
        }
    },
    ThunderPool = { { 2, 20 }, { 3, 240 }, { 4, 470 }, { 5, 210 }, { 6, 8 } },
    AgonyPool = { { 4, 120 }, { 5, 560 }, { 6, 320 } },
    TimePool = { { 4, 180 }, { 5, 560 }, { 6, 90 } },
    MaterialPools = {
        [Enum.Material.Grass] = { { 1, 1000 }, { 2, 120 }, { 3, 25 }, { 4, 4 }, { 5, 1 }, { 6, 0.04 } },
        [Enum.Material.Ground] = { { 1, 1000 }, { 2, 120 }, { 3, 25 }, { 4, 4 }, { 5, 1 }, { 6, 0.04 } },
        [Enum.Material.Sand] = { { 1, 900 }, { 2, 160 }, { 3, 40 }, { 4, 8 }, { 5, 1 }, { 6, 0.04 } },
        [Enum.Material.Mud] = { { 1, 700 }, { 2, 220 }, { 3, 70 }, { 4, 18 }, { 5, 3 }, { 6, 0.05 } },
        [Enum.Material.Rock] = { { 1, 750 }, { 2, 200 }, { 3, 60 }, { 4, 14 }, { 5, 2 }, { 6, 0.05 } },
        [Enum.Material.Sandstone] = { { 1, 820 }, { 2, 170 }, { 3, 45 }, { 4, 10 }, { 5, 1 }, { 6, 0.04 } },
        [Enum.Material.Slate] = { { 1, 450 }, { 2, 320 }, { 3, 160 }, { 4, 55 }, { 5, 12 }, { 6, 0.08 } },
        [Enum.Material.Basalt] = { { 2, 300 }, { 3, 420 }, { 4, 140 }, { 5, 30 } },
        [Enum.Material.Snow] = { { 1, 150 }, { 2, 300 }, { 3, 330 }, { 4, 120 }, { 5, 25 }, { 6, 0.1 } },
        [Enum.Material.Glacier] = { { 2, 260 }, { 3, 420 }, { 4, 180 }, { 5, 55 }, { 6, 1 } },
        [Enum.Material.CrackedLava] = { { 2, 10 }, { 3, 200 }, { 4, 470 }, { 5, 320 }, { 6, 12 } },
        [Enum.Material.Limestone] = { { 4, 120 }, { 5, 400 }, { 6, 480 } },
        [Enum.Material.Pavement] = { { 1, 80 }, { 2, 250 }, { 3, 300 }, { 4, 120 }, { 5, 30 } },
        [Enum.Material.Salt] = { { 1, 70 }, { 2, 240 }, { 3, 310 }, { 4, 130 }, { 5, 35 } },
        [Enum.Material.Ice] = { { 2, 120 }, { 3, 300 }, { 4, 300 }, { 5, 120 }, { 6, 20 } },
        [Enum.Material.LeafyGrass] = { { 2, 110 }, { 3, 290 }, { 4, 310 }, { 5, 130 }, { 6, 25 } },
        [Enum.Material.Asphalt] = { { 3, 150 }, { 4, 330 }, { 5, 330 }, { 6, 90 } },
        [Enum.Material.Concrete] = { { 3, 80 }, { 4, 300 }, { 5, 400 }, { 6, 180 } },
        [Enum.Material.Cobblestone] = { { 4, 150 }, { 5, 420 }, { 6, 330 } },
        [Enum.Material.Brick] = { { 4, 80 }, { 5, 380 }, { 6, 560 } }
    },
    SpawnChance = {
        [Enum.Material.Grass] = 0.015,
        [Enum.Material.Ground] = 0.02,
        [Enum.Material.Sand] = 0.03,
        [Enum.Material.Mud] = 0.04,
        [Enum.Material.Rock] = 0.07,
        [Enum.Material.Sandstone] = 0.1,
        [Enum.Material.Slate] = 0.13,
        [Enum.Material.Basalt] = 0.15,
        [Enum.Material.Snow] = 0.09,
        [Enum.Material.Glacier] = 0.18,
        [Enum.Material.CrackedLava] = 0.22,
        [Enum.Material.Limestone] = 0.3,
        [Enum.Material.Pavement] = 0.35,
        [Enum.Material.Salt] = 0.35,
        [Enum.Material.Ice] = 0.4,
        [Enum.Material.LeafyGrass] = 0.4,
        [Enum.Material.Asphalt] = 0.45,
        [Enum.Material.Concrete] = 0.5,
        [Enum.Material.Cobblestone] = 0.55,
        [Enum.Material.Brick] = 0.65
    },
    MountainModifiers = {
        Dunesea = {
            spawnChanceMult = 1,
            tierWeights = { 1, 1, 1, 1, 1, 1 }
        },
        SinkholeFlats = {
            spawnChanceMult = 1.8,
            tierWeights = { 0.4, 0.8, 1.5, 3.5, 4.5, 1.3 }
        },
        Tuskrows = {
            spawnChanceMult = 1.8,
            tierWeights = { 0.4, 0.8, 1.5, 3.5, 4.5, 1.3 }
        },
        Archgate = {
            spawnChanceMult = 1,
            tierWeights = { 1, 1, 1, 1, 1, 1 }
        },
        AuroralShelf = {
            spawnChanceMult = 1.3,
            tierWeights = { 1, 1, 1, 1.5, 1.4, 1 }
        },
        FungalRise = {
            spawnChanceMult = 1,
            tierWeights = { 1, 1, 1, 1, 1, 1 }
        },
        Shatterpeak = {
            spawnChanceMult = 1.4,
            tierWeights = { 0.55, 1, 1, 2.4, 2.4, 0.9 }
        },
        EmberveilSpire = {
            spawnChanceMult = 1.4,
            tierWeights = { 0.55, 1, 1, 2.4, 2.4, 0.9 }
        },
        Coilhorn = {
            spawnChanceMult = 1.3,
            tierWeights = { 1, 1, 1, 1.5, 1.4, 1 }
        },
        HollowCrown = {
            spawnChanceMult = 1.4,
            tierWeights = { 0.55, 1, 1, 2.4, 2.4, 0.9 }
        },
        Rimefire = {
            spawnChanceMult = 3,
            tierWeights = { 0.15, 0.4, 1.5, 6, 10, 2.5 }
        },
        CrystalPeak = {
            spawnChanceMult = 1.8,
            tierWeights = { 0.4, 0.8, 1.5, 3.5, 4.5, 1.3 }
        },
        Everest = {
            spawnChanceMult = 3,
            tierWeights = { 0.15, 0.4, 1.5, 6, 10, 2.5 }
        },
        K2 = {
            spawnChanceMult = 3,
            tierWeights = { 0.12, 0.35, 1.4, 6.5, 12, 3.2 }
        },
        TheMaw = {
            spawnChanceMult = 1.8,
            tierWeights = { 0.4, 0.8, 1.5, 3.5, 4.5, 1.3 }
        },
        Thornspire = {
            spawnChanceMult = 1.35,
            tierWeights = { 0.55, 0.85, 1.5, 2.4, 2.4, 0.9 }
        },
        Bonewhite = {
            spawnChanceMult = 1.3,
            tierWeights = {
                [3] = 1.3,
                [4] = 1.5,
                [5] = 1.4
            }
        },
        VolcanicCaldera = {
            spawnChanceMult = 1.3,
            tierWeights = { 1.5, 1.3, 1.1 }
        },
        ObsidianCrag = {
            spawnChanceMult = 1.35,
            tierWeights = { 0.55, 0.85, 1.5, 2.4, 2.4, 0.9 }
        },
        Frosthorn = {
            spawnChanceMult = 1.3,
            tierWeights = {
                [3] = 1.3,
                [4] = 1.5,
                [5] = 1.4
            }
        },
        DolomiteMassive = {
            spawnChanceMult = 1,
            tierWeights = {}
        },
        Volcano = {
            spawnChanceMult = 0.9,
            tierWeights = { 1.4, 1 }
        },
        Mesa = {
            spawnChanceMult = 0.95,
            tierWeights = { 1.5, 1.1 }
        },
        Spire = {
            spawnChanceMult = 1.2,
            tierWeights = {
                [3] = 1.4,
                [4] = 1.6,
                [5] = 1.5,
                [6] = 0.5
            }
        },
        TwinPeaks = {
            spawnChanceMult = 1,
            tierWeights = {}
        },
        Massif = {
            spawnChanceMult = 1,
            tierWeights = {}
        },
        KarstSpire = {
            spawnChanceMult = 1,
            tierWeights = {}
        }
    },

    getDepthHeightMods = function(p1, p2) -- Line: 219, Name: getDepthHeightMods
        local v3 = p1 or 0;
        local v4 = math.clamp(p2 or 0, 0, 1);
        local v5 = {
            1.2 - v4 * 1.1,
            1,
            v4 * 1 + 0.6,
            v4 ^ 2.6 * 3.2 + 0.04,
            v4 ^ 3.2 * 4.5 + 0.02,
            v4 ^ 4.5 * 57.6 + 0.002
        };

        if v3 <= 18 then
            if v3 > 8 then
                v5[1] = v5[1] * 0.85;
                v5[3] = v5[3] * 1.2;
                v5[4] = v5[4] * 1.3;
            end;

            return v5;
        end;

        v5[1] = v5[1] * 0.6;
        v5[3] = v5[3] * 1.4;
        v5[4] = v5[4] * 1.7;
        v5[5] = v5[5] * 2;
        v5[6] = v5[6] * 1.4;

        return v5;
    end,

    getMeshPoolForTier = function(p6, p7) -- Line: 244, Name: getMeshPoolForTier
        local v8 = "T" .. p7 .. "_";
        local v9 = {};

        for _, child in ipairs(p6:GetChildren()) do
            if child:IsA("MeshPart") then
                local v10 = child:GetAttribute("Tier");

                if v10 == nil then
                    if child.Name:sub(1, #v8) == v8 then
                        table.insert(v9, child);
                    end;
                elseif v10 == p7 then
                    table.insert(v9, child);
                end;
            end;
        end;

        return v9;
    end,

    rollTier = function(p11, p12, p13, p14) -- Line: 265, Name: rollTier
        if not p11 or #p11 == 0 then
            return nil;
        end;

        local v15 = p14 or Random.new();
        local v16 = {};
        local v17 = 0;

        for _, v in ipairs(p11) do
            local v18 = v[1];
            local v19 = v[2];

            if p12 and (p12.tierWeights and p12.tierWeights[v18]) then
                v19 = v19 * p12.tierWeights[v18];
            end;

            if p13 and p13[v18] then
                v19 = v19 * p13[v18];
            end;

            table.insert(v16, { v18, v19 });
            v17 = v17 + v19;
        end;

        if v17 <= 0 then
            return nil;
        end;

        local v20 = v15:NextNumber(0, v17);
        local v21 = 0;

        for _, v in ipairs(v16) do
            v21 = v21 + v[2];

            if v20 <= v21 then
                return v[1];
            end;
        end;

        return v16[#v16][1];
    end,

    getSurfacePool = function(p22) -- Line: 302, Name: getSurfacePool
        local v23 = math.clamp(p22, 0, 1);
        local v24 = math.abs(v23 - 0.55) / 0.55;
        local v25 = 1 - math.min(1, v24);

        return {
            { 1, math.floor(900 * (1 - v23) ^ 1.5) + 10 },
            { 2, math.floor(280 * (1 - v23) ^ 0.7) + 12 },
            { 3, math.floor(v25 * 320) + 6 },
            { 4, math.floor(420 * v23 ^ 1.6) + 3 },
            { 5, math.floor(340 * v23 ^ 2.4) + 1 },
            { 6, (math.floor(9 * v23 ^ 4.5)) }
        };
    end
};

function u26.tierForHeight(p27) -- Line: 325
    -- upvalues: u26 (copy)
    local v28 = #u26.Tiers;
    local v29 = math.clamp(p27, 0, 1) * v28;
    local v30 = math.floor(v29) + 1;

    if v28 < v30 then
        v30 = v28;
    end;

    return v30;
end;

function u26.classByKg(p31) -- Line: 339
    if p31 >= 25000 then
        return "Behemoth", "Behemoth";
    end;

    if p31 >= 8000 then
        return "Leviathan", "Leviathan";
    end;

    if p31 >= 3000 then
        return "Titan", "Titan";
    end;

    if p31 >= 1000 then
        return "Colossal", "Colossal";
    end;

    if p31 >= 200 then
        return "Giant", "Giant";
    end;

    if p31 >= 90 then
        return "XL", "Extra Large";
    end;

    if p31 >= 30 then
        return "L", "Large";
    end;

    if p31 >= 8 then
        return "M", "Medium";
    end;

    return "S", "Small";
end;

return u26;
