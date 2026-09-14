-- ️ HipHub TR Legacy — Visuals, ESP & Lighting Suite

local success, err = pcall(function()
    local UI = _G.HipHubUI
    if not UI then return end

    local Players = game:GetService("Players")
    local Lighting = game:GetService("Lighting")
    local RunService = game:GetService("RunService")
    local Camera = workspace.CurrentCamera
    local player = Players.LocalPlayer

    local vehicleEspActive = false
    local playerEspActive = false
    local checkpointEspActive = false
    local fullbrightActive = false
    local noFogActive = false

    local espFolder = Instance.new("Folder")
    espFolder.Name = "HipHub_TR_ESP"
    espFolder.Parent = UI.gui

    ------------------------------------------------
    -- LIGHTING & FULLBRIGHT
    ------------------------------------------------
    local defaultBrightness = Lighting.Brightness
    local defaultClockTime = Lighting.ClockTime
    local defaultFogEnd = Lighting.FogEnd
    local defaultOutdoorAmbient = Lighting.OutdoorAmbient

    local function applyLightingMods()
        if fullbrightActive then
            Lighting.Brightness = 2.5
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
        end
        if noFogActive then
            Lighting.FogEnd = 1e6
        end
    end

    Lighting.Changed:Connect(function()
        if fullbrightActive or noFogActive then
            applyLightingMods()
        end
    end)

    ------------------------------------------------
    -- VEHICLE & PLAYER ESP
    ------------------------------------------------
    local function clearESP()
        espFolder:ClearAllChildren()
    end

    local function updateESP()
        clearESP()
        local myChar = player.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end

        -- Vehicle ESP
        if vehicleEspActive then
            local vehFolder = workspace:FindFirstChild("Vehicles")
            if vehFolder then
                for _, userFolder in pairs(vehFolder:GetChildren()) do
                    if userFolder.Name ~= player.Name then
                        for _, v in pairs(userFolder:GetChildren()) do
                            if v:IsA("Model") then
                                local seat = v:FindFirstChild("DriveSeat") or v.PrimaryPart
                                if seat then
                                    local dist = math.floor((seat.Position - myRoot.Position).Magnitude)
                                    if dist < 2500 then
                                        local bb = Instance.new("BillboardGui")
                                        bb.Name = "VehESP_" .. v.Name
                                        bb.Adornee = seat
                                        bb.Size = UDim2.new(0, 130, 0, 36)
                                        bb.StudsOffset = Vector3.new(0, 2.5, 0)
                                        bb.AlwaysOnTop = true
                                        bb.Parent = espFolder

                                        local f = Instance.new("Frame")
                                        f.Size = UDim2.new(1, 0, 1, 0)
                                        f.BackgroundColor3 = Color3.fromRGB(15, 20, 35)
                                        f.BackgroundTransparency = 0.25
                                        f.BorderSizePixel = 0
                                        f.Parent = bb

                                        local cr = Instance.new("UICorner")
                                        cr.CornerRadius = UDim.new(0, 6)
                                        cr.Parent = f

                                        local strk = Instance.new("UIStroke")
                                        strk.Color = Color3.fromRGB(0, 210, 255)
                                        strk.Thickness = 1
                                        strk.Parent = f

                                        local t1 = Instance.new("TextLabel")
                                        t1.Size = UDim2.new(1, -6, 0, 16)
                                        t1.Position = UDim2.new(0, 3, 0, 2)
                                        t1.BackgroundTransparency = 1
                                        t1.Text = v.Name
                                        t1.TextColor3 = Color3.fromRGB(255, 255, 255)
                                        t1.Font = Enum.Font.GothamBold
                                        t1.TextSize = 10
                                        t1.TextTruncate = Enum.TextTruncate.AtEnd
                                        t1.Parent = f

                                        local t2 = Instance.new("TextLabel")
                                        t2.Size = UDim2.new(1, -6, 0, 14)
                                        t2.Position = UDim2.new(0, 3, 0, 18)
                                        t2.BackgroundTransparency = 1
                                        t2.Text = userFolder.Name .. " • " .. tostring(dist) .. "m"
                                        t2.TextColor3 = Color3.fromRGB(0, 200, 255)
                                        t2.Font = Enum.Font.Gotham
                                        t2.TextSize = 9
                                        t2.Parent = f
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        -- Player ESP
        if playerEspActive then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local pRoot = p.Character.HumanoidRootPart
                    local dist = math.floor((pRoot.Position - myRoot.Position).Magnitude)
                    if dist < 2500 then
                        local bb = Instance.new("BillboardGui")
                        bb.Name = "PlayerESP_" .. p.Name
                        bb.Adornee = pRoot
                        bb.Size = UDim2.new(0, 120, 0, 34)
                        bb.StudsOffset = Vector3.new(0, 3.5, 0)
                        bb.AlwaysOnTop = true
                        bb.Parent = espFolder

                        local f = Instance.new("Frame")
                        f.Size = UDim2.new(1, 0, 1, 0)
                        f.BackgroundColor3 = Color3.fromRGB(15, 20, 35)
                        f.BackgroundTransparency = 0.25
                        f.BorderSizePixel = 0
                        f.Parent = bb

                        local cr = Instance.new("UICorner")
                        cr.CornerRadius = UDim.new(0, 6)
                        cr.Parent = f

                        local strk = Instance.new("UIStroke")
                        strk.Color = Color3.fromRGB(160, 120, 255)
                        strk.Thickness = 1
                        strk.Parent = f

                        local t1 = Instance.new("TextLabel")
                        t1.Size = UDim2.new(1, -6, 0, 16)
                        t1.Position = UDim2.new(0, 3, 0, 2)
                        t1.BackgroundTransparency = 1
                        t1.Text = p.DisplayName
                        t1.TextColor3 = Color3.fromRGB(255, 255, 255)
                        t1.Font = Enum.Font.GothamBold
                        t1.TextSize = 10
                        t1.TextTruncate = Enum.TextTruncate.AtEnd
                        t1.Parent = f

                        local t2 = Instance.new("TextLabel")
                        t2.Size = UDim2.new(1, -6, 0, 14)
                        t2.Position = UDim2.new(0, 3, 0, 16)
                        t2.BackgroundTransparency = 1
                        t2.Text = "@" .. p.Name .. " • " .. tostring(dist) .. "m"
                        t2.TextColor3 = Color3.fromRGB(180, 160, 255)
                        t2.Font = Enum.Font.Gotham
                        t2.TextSize = 9
                        t2.Parent = f
                    end
                end
            end
        end
    end

    -- Background loop for ESP update
    task.spawn(function()
        while true do
            if vehicleEspActive or playerEspActive then
                pcall(updateESP)
            end
            task.wait(1.5)
        end
    end)

    ------------------------------------------------
    -- UI INTEGRATION
    ------------------------------------------------
    local vFrame = UI.Tabs.Visuals
    if not vFrame then return end

    -- ESP Section
    local espSec = UI.AddSection(vFrame, "ESP & Object Highlights", 1)
    UI.AddToggle(espSec, "Other Vehicles ESP", vehicleEspActive, function(v)
        vehicleEspActive = v
        if not v then clearESP() end
    end, 1)

    UI.AddToggle(espSec, "Other Players ESP", playerEspActive, function(v)
        playerEspActive = v
        if not v then clearESP() end
    end, 2)

    -- Lighting Section
    local lightSec = UI.AddSection(vFrame, "World Lighting & Atmosphere", 2)
    UI.AddToggle(lightSec, "Fullbright (No Shadows / Bright Night)", fullbrightActive, function(v)
        fullbrightActive = v
        if v then
            applyLightingMods()
        else
            Lighting.Brightness = defaultBrightness
            Lighting.GlobalShadows = true
            Lighting.OutdoorAmbient = defaultOutdoorAmbient
        end
    end, 1)

    UI.AddToggle(lightSec, "Clear Sky / Remove Fog", noFogActive, function(v)
        noFogActive = v
        if v then
            Lighting.FogEnd = 1e6
        else
            Lighting.FogEnd = defaultFogEnd
        end
    end, 2)

    UI.AddButton(lightSec, "Set Time to Noon (14:00)", function()
        Lighting.ClockTime = 14
        UI.Notify("Atmosphere", "Waktu diubah ke Siang (14:00).", 1, "success")
    end, 3)

    UI.AddButton(lightSec, "Set Time to Midnight (00:00)", function()
        Lighting.ClockTime = 0
        UI.Notify("Atmosphere", "Waktu diubah ke Malam (00:00).", 1, "success")
    end, 4)

    -- Camera FOV Section
    local camSec = UI.AddSection(vFrame, "Camera & View Settings", 3)
    UI.AddSlider(camSec, "Field of View (FOV)", 70, 120, 70, 1, function(v)
        if Camera then
            Camera.FieldOfView = v
        end
    end, 1)

    -- Global Export
    _G.HipHubVisuals = {
        SetFullbright = function(v) fullbrightActive = v applyLightingMods() end,
        SetNoFog = function(v) noFogActive = v if v then Lighting.FogEnd = 1e6 else Lighting.FogEnd = defaultFogEnd end end,
    }
end)

if not success then
    warn("[HipHub TR Legacy Visuals Error]:", err)
end
