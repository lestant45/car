-- Script Path: game:GetService("ReplicatedStorage").Modules.Crystals.CrystalConfig
-- Took 0.01s to decompile.
-- Executor: Potassium (v2.4.2)

-- Decompiled with Potassium's decompiler.

local u1 = {};
local GradientText = require(script.Parent.GradientText);
u1.Tiers = {
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
    },
    {
        name = "Empyrean",
        glow = 2.6,
        pickupHold = 5.5,
        value = 41000000,
        color = Color3.fromRGB(255, 225, 150),
        material = Enum.Material.Neon,
        gradient = { Color3.fromRGB(255, 247, 200), Color3.fromRGB(255, 205, 90), Color3.fromRGB(255, 150, 40) }
    },
    {
        name = "Pulsar",
        glow = 3,
        pickupHold = 6,
        value = 660000000,
        color = Color3.fromRGB(90, 210, 255),
        material = Enum.Material.Neon,
        gradient = { Color3.fromRGB(210, 250, 255), Color3.fromRGB(70, 200, 255), Color3.fromRGB(70, 110, 255) }
    },
    {
        name = "Quasar",
        glow = 3.4,
        pickupHold = 6.5,
        value = 10600000000,
        color = Color3.fromRGB(255, 90, 220),
        material = Enum.Material.Neon,
        gradient = { Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 80, 210), Color3.fromRGB(150, 60, 255) }
    }
};
u1.ThunderPool = { { 2, 20 }, { 3, 240 }, { 4, 470 }, { 5, 210 }, { 6, 8 } };
u1.AgonyPool = { { 4, 120 }, { 5, 560 }, { 6, 320 } };
u1.TimePool = { { 4, 180 }, { 5, 560 }, { 6, 90 }, { 7, 18 }, { 8, 3 } };
u1.MaterialPools = {
    [Enum.Material.Grass] = { { 1, 1000 }, { 2, 120 }, { 3, 25 }, { 4, 4 }, { 5, 1 }, { 6, 0.04 } },
    [Enum.Material.Ground] = { { 1, 1000 }, { 2, 120 }, { 3, 25 }, { 4, 4 }, { 5, 1 }, { 6, 0.04 } },
    [Enum.Material.Sand] = { { 1, 900 }, { 2, 160 }, { 3, 40 }, { 4, 8 }, { 5, 1 }, { 6, 0.04 } },
    [Enum.Material.Mud] = { { 1, 700 }, { 2, 220 }, { 3, 70 }, { 4, 18 }, { 5, 3 }, { 6, 0.05 } },
    [Enum.Material.Rock] = { { 1, 750 }, { 2, 200 }, { 3, 60 }, { 4, 14 }, { 5, 2 }, { 6, 0.05 } },
    [Enum.Material.Sandstone] = { { 1, 820 }, { 2, 170 }, { 3, 45 }, { 4, 10 }, { 5, 1 }, { 6, 0.04 } },
    [Enum.Material.Slate] = { { 1, 450 }, { 2, 320 }, { 3, 160 }, { 4, 55 }, { 5, 12 }, { 6, 0.08 } },
    [Enum.Material.Basalt] = { { 2, 300 }, { 3, 420 }, { 4, 140 }, { 5, 30 }, { 6, 0.05 } },
    [Enum.Material.Snow] = { { 1, 150 }, { 2, 300 }, { 3, 330 }, { 4, 120 }, { 5, 25 }, { 6, 0.1 } },
    [Enum.Material.Glacier] = { { 2, 260 }, { 3, 420 }, { 4, 180 }, { 5, 55 }, { 6, 1 } },
    [Enum.Material.CrackedLava] = { { 2, 10 }, { 3, 200 }, { 4, 470 }, { 5, 320 }, { 6, 12 } },
    [Enum.Material.Limestone] = { { 4, 120 }, { 5, 400 }, { 6, 480 } },
    [Enum.Material.WoodPlanks] = { { 5, 300 }, { 6, 700 } },
    [Enum.Material.Pavement] = { { 1, 80 }, { 2, 250 }, { 3, 300 }, { 4, 120 }, { 5, 30 }, { 6, 0.04 } },
    [Enum.Material.Salt] = { { 1, 70 }, { 2, 240 }, { 3, 310 }, { 4, 130 }, { 5, 35 }, { 6, 0.04 } },
    [Enum.Material.Ice] = { { 2, 120 }, { 3, 300 }, { 4, 300 }, { 5, 120 }, { 6, 20 } },
    [Enum.Material.LeafyGrass] = { { 2, 110 }, { 3, 290 }, { 4, 310 }, { 5, 130 }, { 6, 25 } },
    [Enum.Material.Asphalt] = { { 3, 150 }, { 4, 330 }, { 5, 330 }, { 6, 90 } },
    [Enum.Material.Concrete] = { { 3, 80 }, { 4, 300 }, { 5, 400 }, { 6, 180 } },
    [Enum.Material.Cobblestone] = { { 4, 150 }, { 5, 420 }, { 6, 330 } },
    [Enum.Material.Brick] = { { 4, 80 }, { 5, 380 }, { 6, 560 } }
};
u1.SpawnChance = {
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
    [Enum.Material.WoodPlanks] = 0.35,
    [Enum.Material.Pavement] = 0.35,
    [Enum.Material.Salt] = 0.35,
    [Enum.Material.Ice] = 0.4,
    [Enum.Material.LeafyGrass] = 0.4,
    [Enum.Material.Asphalt] = 0.45,
    [Enum.Material.Concrete] = 0.5,
    [Enum.Material.Cobblestone] = 0.55,
    [Enum.Material.Brick] = 0.65
};
u1.MountainModifiers = {
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
};

function u1.getDepthHeightMods(p2, p3) -- Line: 242
    local v4 = p2 or 0;
    local v5 = math.clamp(p3 or 0, 0, 1);
    local v6 = {
        1.2 - v5 * 1.1,
        1,
        v5 * 1 + 0.6,
        v5 ^ 2.6 * 3.2 + 0.04,
        v5 ^ 3.2 * 4.5 + 0.02,
        v5 ^ 4.5 * 57.6 + 0.002
    };

    if v4 <= 18 then
        if v4 > 8 then
            v6[1] = v6[1] * 0.85;
            v6[3] = v6[3] * 1.2;
            v6[4] = v6[4] * 1.3;
        end;

        return v6;
    end;

    v6[1] = v6[1] * 0.6;
    v6[3] = v6[3] * 1.4;
    v6[4] = v6[4] * 1.7;
    v6[5] = v6[5] * 2;
    v6[6] = v6[6] * 1.4;

    return v6;
end;

function u1.getMeshPoolForTier(p7, p8) -- Line: 267
    local v9 = "T" .. p8 .. "_";
    local v10 = {};

    for _, child in ipairs(p7:GetChildren()) do
        if child:IsA("MeshPart") then
            local v11 = child:GetAttribute("Tier");

            if v11 == nil then
                if child.Name:sub(1, #v9) == v9 then
                    table.insert(v10, child);
                end;
            elseif v11 == p8 then
                table.insert(v10, child);
            end;
        end;
    end;

    return v10;
end;

function u1.rollTier(p12, p13, p14, p15, p16, p17, p18) -- Line: 288
    if not p12 or #p12 == 0 then
        return nil;
    end;

    local v19 = p15 or Random.new();
    local v20 = {};
    local v21 = 0;

    for _, v in ipairs(p12) do
        local v22 = v[1];
        local v23 = v[2];

        if p13 and (p13.tierWeights and p13.tierWeights[v22]) then
            v23 = v23 * p13.tierWeights[v22];
        end;

        if p14 and p14[v22] then
            v23 = v23 * p14[v22];
        end;

        table.insert(v20, { v22, v23 });
        v21 = v21 + v23;
    end;

    if v21 <= 0 then
        local v24 = (-1 / 0);
        local v25 = nil;

        for i, v in ipairs(v20) do
            if v24 < v[1] then
                v24 = v[1];
                v25 = i;
            end;
        end;

        if v25 then
            v20[v25][2] = 1;
            v21 = 1;
        end;
    end;

    local v26 = false;

    for _, v in ipairs(v20) do
        if v[1] == 6 then
            v26 = true;
            break;
        end;
    end;

    local u27 = tonumber(p16) or 0;
    local v28;

    if v26 and (u27 > 0 and v21 > 0) then
        local v29 = tonumber(p18) or 1;

        local function frac(p30, p31) -- Line: 342
            -- upvalues: u27 (copy)
            return p30 * u27 / (u27 + p31);
        end;

        local v32;

        if p17 then
            v32 = {
                [7] = 0.55 * u27 / (u27 + 300),
                [8] = 0.28 * u27 / (u27 + 800),
                [9] = 0.14 * u27 / (u27 + 2500)
            };
        else
            v32 = {
                [7] = 0.16 * u27 / (u27 + 12000) * v29,
                [8] = 0.018 * u27 / (u27 + 12000) * v29,
                [9] = 0.0018 * u27 / (u27 + 12000) * v29
            };
        end;

        v28 = v21;

        for _, v in ipairs({ 7, 8, 9 }) do
            local v33 = v21 * v32[v];

            if v33 > 0 then
                table.insert(v20, { v, v33 });
                v28 = v28 + v33;
            end;
        end;
    else
        v28 = v21;
    end;

    if v28 <= 0 then
        return nil;
    end;

    local v34 = v19:NextNumber(0, v28);
    local v35 = 0;

    for _, v in ipairs(v20) do
        v35 = v35 + v[2];

        if v34 <= v35 then
            return v[1];
        end;
    end;

    return v20[#v20][1];
end;

function u1.tailScaleForMaterial(p36) -- Line: 382
    -- upvalues: u1 (copy)
    local v37 = u1.SpawnChance and u1.SpawnChance[p36];

    if not v37 then
        return 1;
    end;

    local v38 = v37 / 0.3;
    local v39 = v38 > 1 and 1 or v38;

    return v39 < 0 and 0 or v39;
end;

function u1.getSurfacePool(p40) -- Line: 395
    local v41 = math.clamp(p40, 0, 1);
    local v42 = math.abs(v41 - 0.55) / 0.55;
    local v43 = 1 - math.min(1, v42);

    return {
        { 1, math.floor(900 * (1 - v41) ^ 1.5) + 10 },
        { 2, math.floor(280 * (1 - v41) ^ 0.7) + 12 },
        { 3, math.floor(v43 * 320) + 6 },
        { 4, math.floor(420 * v41 ^ 1.6) + 3 },
        { 5, math.floor(340 * v41 ^ 2.4) + 1 },
        { 6, (math.floor(9 * v41 ^ 4.5)) }
    };
end;

function u1.tierForHeight(p44) -- Line: 418
    local v45 = math.clamp(p44, 0, 1) * 6;
    local v46 = math.floor(v45) + 1;

    return v46 > 6 and 6 or v46;
end;

function u1.classByKg(p47) -- Line: 435
    if p47 >= 25000 then
        return "Behemoth", "Behemoth";
    end;

    if p47 >= 8000 then
        return "Leviathan", "Leviathan";
    end;

    if p47 >= 3000 then
        return "Titan", "Titan";
    end;

    if p47 >= 1000 then
        return "Colossal", "Colossal";
    end;

    if p47 >= 200 then
        return "Giant", "Giant";
    end;

    if p47 >= 90 then
        return "XL", "Extra Large";
    end;

    if p47 >= 30 then
        return "L", "Large";
    end;

    if p47 >= 8 then
        return "M", "Medium";
    end;

    return "S", "Small";
end;

function u1.tierColor(p48) -- Line: 450
    -- upvalues: u1 (copy)
    if p48 then
        p48 = u1.Tiers[p48];
    end;

    return p48 and p48.color or Color3.fromRGB(220, 195, 140);
end;

function u1.tierHasGradient(p49) -- Line: 456
    -- upvalues: u1 (copy)
    if p49 then
        p49 = u1.Tiers[p49];
    end;

    local v50;

    if p49 == nil then
        v50 = false;
    else
        v50 = p49.gradient ~= nil;
    end;

    return v50;
end;

function u1.tierDisplayName(p51, p52) -- Line: 465
    -- upvalues: u1 (copy), GradientText (copy)
    if p51 then
        p51 = u1.Tiers[p51];
    end;

    local v53 = p52 or (p51 and (p51.name or "Crystal") or "Crystal");

    if p51 and p51.gradient then
        return GradientText.build(v53, p51.gradient), true;
    end;

    return v53, false;
end;

u1.RarityModifierPreset = {
    Common = "Dunesea",
    Uncommon = "Archgate",
    Rare = "AuroralShelf",
    Epic = "Shatterpeak",
    Legendary = "SinkholeFlats",
    Mythic = "Everest",
    MYTHIC = "Everest"
};

function u1.resolveMountainModifier(p54, p55) -- Line: 492
    -- upvalues: u1 (copy)
    if p54 and u1.MountainModifiers[p54] then
        return u1.MountainModifiers[p54];
    end;

    if p55 then
        local v56 = u1.RarityModifierPreset[p55];

        if v56 and u1.MountainModifiers[v56] then
            return u1.MountainModifiers[v56];
        end;
    end;

    return nil;
end;

return u1;
