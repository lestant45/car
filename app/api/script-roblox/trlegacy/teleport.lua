-- HipHub TR Legacy — Teleportation System
-- Supports Race Starting Areas, Dealership, Customization Garage, Daily Reward Pad, and Player Teleportation

local success, err = pcall(function()
    local UI = _G.HipHubUI
    if not UI then return end

    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local player = Players.LocalPlayer

    local tpWithVehicle = true
    local tpSmooth = false
    local tpSpeed = 200

    -- Helper to get player's active vehicle
    local function getPlayerVehicle()
        if _G.HipHubVehicle and _G.HipHubVehicle.GetActiveVehicle then
            local veh = _G.HipHubVehicle.GetActiveVehicle()
            if veh then return veh end
        end
        local vehFolder = workspace:FindFirstChild("Vehicles")
        if vehFolder and vehFolder:FindFirstChild(player.Name) then
            for _, child in pairs(vehFolder[player.Name]:GetChildren()) do
                if child:IsA("Model") and (child:FindFirstChild("DriveSeat") or child.PrimaryPart) then
                    return child
                end
            end
        end
        return nil
    end

    -- Universal Teleport Function
    local function teleportTo(cframe)
        local char = player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local veh = tpWithVehicle and getPlayerVehicle() or nil
        local targetPart = (veh and (veh:FindFirstChild("DriveSeat") or veh.PrimaryPart)) or root

        if tpSmooth then
            local dist = (targetPart.Position - cframe.Position).Magnitude
            local t = math.clamp(dist / tpSpeed, 0.2, 6)
            local tw = TweenService:Create(targetPart, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = cframe + Vector3.new(0, 3, 0) })
            tw:Play()
            tw.Completed:Wait()
        else
            if veh then
                if veh.PrimaryPart then
                    veh:SetPrimaryPartCFrame(cframe + Vector3.new(0, 3, 0))
                elseif veh:FindFirstChild("DriveSeat") then
                    veh.DriveSeat.CFrame = cframe + Vector3.new(0, 3, 0)
                end
                -- Zero velocities to prevent physics flings
                pcall(function()
                    for _, p in pairs(veh:GetDescendants()) do
                        if p:IsA("BasePart") then
                            p.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            p.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                        end
                    end
                end)
            else
                root.CFrame = cframe + Vector3.new(0, 3, 0)
                root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
        end
    end

    ------------------------------------------------
    -- LOCATIONS DATA
    ------------------------------------------------
    local RaceLocations = {
        ["Race 1: Mountain Race (RM 53,000)"] = Vector3.new(89.16, 15.06, -173.03),
        ["Race 8: Around The World (RM 38,000)"] = Vector3.new(16790.18, 87.91, -15229.59),
        ["Race 4: Highway (RM 27,000)"] = Vector3.new(-7403.89, 200.68, -149.44),
        ["Race 3: GP Track (RM 18,500)"] = Vector3.new(13297.52, 88.10, -3617.81),
        ["Race 2: Small Circuit (RM 11,000)"] = Vector3.new(3867.74, 254.60, 11767.41),
        ["Race 6: Lake Race (RM 9,500)"] = Vector3.new(-1431.17, 15.79, -228.83),
        ["Race 7: Side Street (RM 7,300)"] = Vector3.new(-576.54, 15.46, 774.85),
        ["Race 5: Drag (RM 1,500)"] = Vector3.new(-9481.66, 228.62, 332.21),
    }

    local LandmarkLocations = {
        ["Dealership Showroom"] = Vector3.new(-5.99, -48.57, 81.89),
        ["Customization Garage"] = Vector3.new(-1553.01, -60.44, -1239.70),
        ["Dyno Tuning Area"] = Vector3.new(-1510.50, -60.44, -1200.00),
        ["Daily Reward Pad"] = Vector3.new(14.60, 6.86, 65.88),
        ["Mountain Summit Point"] = Vector3.new(150.00, 120.00, -850.00),
    }

    ------------------------------------------------
    -- UI INTEGRATION
    ------------------------------------------------
    local tpFrame = UI.Tabs.Teleport
    if not tpFrame then return end

    -- Config Section
    local cfgSec = UI.AddSection(tpFrame, "Teleport Configuration", 1)
    UI.AddToggle(cfgSec, "Teleport With Active Vehicle", tpWithVehicle, function(v)
        tpWithVehicle = v
    end, 1)

    UI.AddToggle(cfgSec, "Smooth Tween Interpolation", tpSmooth, function(v)
        tpSmooth = v
    end, 2)

    -- Race Starting Line Section
    local raceSec = UI.AddSection(tpFrame, "Race Starting Lines", 2)
    local raceNames = {}
    for name, _ in pairs(RaceLocations) do table.insert(raceNames, name) end
    table.sort(raceNames)

    local selectedRace = raceNames[1]
    UI.AddDropdown(raceSec, "Select Race Track", raceNames, selectedRace, function(v)
        selectedRace = v
    end, 1)

    UI.AddButton(raceSec, "Teleport to Race Area", function()
        local pos = RaceLocations[selectedRace]
        if pos then
            teleportTo(CFrame.new(pos))
            UI.Notify("Teleport", "Tiba di area " .. selectedRace, 2, "success")
        end
    end, 2)

    -- Landmarks & Hubs Section
    local lmSec = UI.AddSection(tpFrame, "Landmarks & Facilities", 3)
    local lmNames = {}
    for name, _ in pairs(LandmarkLocations) do table.insert(lmNames, name) end
    table.sort(lmNames)

    local selectedLm = lmNames[1]
    UI.AddDropdown(lmSec, "Select Landmark", lmNames, selectedLm, function(v)
        selectedLm = v
    end, 1)

    UI.AddButton(lmSec, "Teleport to Landmark", function()
        local pos = LandmarkLocations[selectedLm]
        if pos then
            teleportTo(CFrame.new(pos))
            UI.Notify("Teleport", "Tiba di " .. selectedLm, 2, "success")
        end
    end, 2)

    -- Player Teleports Section
    local plySec = UI.AddSection(tpFrame, "Player Teleportation", 4)
    local playerList = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then table.insert(playerList, p.Name) end
    end
    if #playerList == 0 then table.insert(playerList, "No other players") end

    local selectedPlayer = playerList[1]
    local playerDrop = UI.AddDropdown(plySec, "Select Target Player", playerList, selectedPlayer, function(v)
        selectedPlayer = v
    end, 1)

    UI.AddButton(plySec, "Refresh Player List", function()
        local updated = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player then table.insert(updated, p.Name) end
        end
        if #updated == 0 then table.insert(updated, "No other players") end
        playerDrop.Refresh(updated)
        UI.Notify("Player List", "Daftar pemain diperbarui.", 1, "success")
    end, 2)

    UI.AddButton(plySec, "Teleport to Selected Player", function()
        local target = Players:FindFirstChild(selectedPlayer)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            teleportTo(CFrame.new(target.Character.HumanoidRootPart.Position + Vector3.new(0, 3, 3)))
            UI.Notify("Teleport", "Teleport ke " .. selectedPlayer, 2, "success")
        else
            UI.Notify("Teleport", "Karakter pemain tidak ditemukan.", 2, "warning")
        end
    end, 3)

    -- Export global table
    _G.HipHubTeleport = {
        TeleportTo = teleportTo,
        RaceLocations = RaceLocations,
        LandmarkLocations = LandmarkLocations,
    }
end)

if not success then
    warn("[HipHub TR Legacy Teleport Error]:", err)
end
