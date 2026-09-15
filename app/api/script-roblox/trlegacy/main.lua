-- HipHub TR Legacy — Main Controller, Window Interactions & Player Mods

local success, err = pcall(function()
    local UI = _G.HipHubUI
    if not UI then return end

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local TeleportService = game:GetService("TeleportService")
    local ProximityPromptService = game:GetService("ProximityPromptService")
    local player = Players.LocalPlayer

    local mainFrame = UI.mainFrame or UI.MainFrame
    local topBar = UI.topBar
    local closeButton = UI.closeButton
    local minimizeButton = UI.minimizeButton
    local fullscreenButton = UI.fullscreenButton
    local syncShadow = UI.SyncShadow

    ------------------------------------------------
    -- ️ WINDOW INTERACTIONS
    ------------------------------------------------
    -- Window controls (dragging, close, minimize, fullscreen) are initialized in ui.lua

    ------------------------------------------------
    -- CHARACTER MODIFICATIONS
    ------------------------------------------------
    local walkSpeed = 16
    local jumpPower = 50
    local noclipActive = false
    local flyActive = false
    local flySpeed = 60
    local infJump = false
    local instantPrompt = true

    RunService.RenderStepped:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            local hum = char.Humanoid
            if walkSpeed > 16 then hum.WalkSpeed = walkSpeed end
            if jumpPower > 50 then hum.JumpPower = jumpPower end
        end
    end)

    RunService.Stepped:Connect(function()
        if noclipActive and player.Character then
            for _, p in pairs(player.Character:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = false
                end
            end
        end
    end)

    UserInputService.JumpRequest:Connect(function()
        if infJump and player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)

    -- Instant Proximity Prompts
    ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
        if instantPrompt and prompt and prompt.Enabled then
            pcall(function()
                if fireproximityprompt then
                    fireproximityprompt(prompt, 0)
                end
            end)
        end
    end)

    ------------------------------------------------
    -- ️ CHARACTER FLY
    ------------------------------------------------
    local charBv, charBg
    local function toggleCharFly(enable)
        flyActive = enable
        local char = player.Character
        if not enable then
            if charBv then charBv:Destroy(); charBv = nil end
            if charBg then charBg:Destroy(); charBg = nil end
            return
        end

        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local root = char.HumanoidRootPart

        charBv = Instance.new("BodyVelocity")
        charBv.Velocity = Vector3.zero
        charBv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        charBv.Parent = root

        charBg = Instance.new("BodyGyro")
        charBg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        charBg.P = 9000
        charBg.CFrame = root.CFrame
        charBg.Parent = root

        task.spawn(function()
            local cam = workspace.CurrentCamera
            while flyActive and char and char.Parent and root and root.Parent do
                local moveDir = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

                if charBv and charBg then
                    charBv.Velocity = moveDir.Magnitude > 0 and (moveDir.Unit * flySpeed) or Vector3.zero
                    charBg.CFrame = cam.CFrame
                end
                RunService.RenderStepped:Wait()
            end
            if charBv then charBv:Destroy(); charBv = nil end
            if charBg then charBg:Destroy(); charBg = nil end
        end)
    end

    ------------------------------------------------
    -- BUILD MAIN TAB UI
    ------------------------------------------------
    local mFrame = UI.Tabs.Main
    if not mFrame then return end

    -- Welcome Banner Card
    local banner = Instance.new("Frame")
    banner.Size = UDim2.new(1, 0, 0, 70)
    banner.BackgroundColor3 = UI.COLORS.glassCard
    banner.BackgroundTransparency = UI.TRANSPARENCY.glassCard
    banner.BorderSizePixel = 0
    banner.LayoutOrder = 1
    banner.Parent = mFrame

    local bannerCorner = Instance.new("UICorner")
    bannerCorner.CornerRadius = UI.CORNER.medium
    bannerCorner.Parent = banner

    local bannerStroke = Instance.new("UIStroke")
    bannerStroke.Color = UI.COLORS.borderGlass
    bannerStroke.Thickness = 1
    bannerStroke.Transparency = 0.6
    bannerStroke.Parent = banner

    local bTitle = Instance.new("TextLabel")
    bTitle.Size = UDim2.new(1, -20, 0, 22)
    bTitle.Position = UDim2.new(0, 12, 0, 8)
    bTitle.BackgroundTransparency = 1
    bTitle.Text = "Selamat Datang, " .. player.DisplayName .. "!"
    bTitle.TextColor3 = UI.COLORS.textWhite
    bTitle.Font = Enum.Font.GothamBold
    bTitle.TextSize = 13
    bTitle.TextXAlignment = Enum.TextXAlignment.Left
    bTitle.Parent = banner

    local bSub = Instance.new("TextLabel")
    bSub.Size = UDim2.new(1, -20, 0, 32)
    bSub.Position = UDim2.new(0, 12, 0, 30)
    bSub.BackgroundTransparency = 1
    bSub.Text = "HipHub TR Legacy - Auto Race & Circular Auto Drive\nStatus: Siap Digunakan"
    bSub.TextColor3 = UI.COLORS.textSecondary
    bSub.Font = Enum.Font.Gotham
    bSub.TextSize = 10
    bSub.TextXAlignment = Enum.TextXAlignment.Left
    bSub.TextWrapped = true
    bSub.Parent = banner

    -- Quick Actions Section
    local quickSec = UI.AddSection(mFrame, "Quick Shortcuts & Vehicle Controls", 2)

    UI.AddButton(quickSec, "Spawn & Mount Motor", function()
        if _G.HipHubVehicle and _G.HipHubVehicle.SpawnBike then
            _G.HipHubVehicle.SpawnBike()
        else
            UI.Notify("Vehicle", "Spawning motor...", 2, "info")
        end
    end, 1)

    UI.AddButton(quickSec, "Mount / Duduk ke Motor", function()
        if _G.HipHubVehicle and _G.HipHubVehicle.MountBike then
            _G.HipHubVehicle.MountBike()
        end
    end, 2)

    -- Character Physics Section
    local charSec = UI.AddSection(mFrame, "Player Character Modifications", 3)

    UI.AddSlider(charSec, "WalkSpeed Modifier", 16, 120, walkSpeed, 1, function(v)
        walkSpeed = v
    end, 1)

    UI.AddSlider(charSec, "JumpPower Modifier", 50, 200, jumpPower, 1, function(v)
        jumpPower = v
    end, 2)

    UI.AddToggle(charSec, "Character Noclip", noclipActive, function(v)
        noclipActive = v
    end, 3)

    UI.AddToggle(charSec, "Infinite Jump", infJump, function(v)
        infJump = v
    end, 4)

    UI.AddToggle(charSec, "Instant Proximity Prompts (0 Detik Hold)", instantPrompt, function(v)
        instantPrompt = v
    end, 5)

    -- Flight Section
    local flySec = UI.AddSection(mFrame, "Character Flight", 4)

    UI.AddToggle(flySec, "Aktifkan Mode Terbang (Fly)", flyActive, function(v)
        toggleCharFly(v)
    end, 1)

    UI.AddSlider(flySec, "Kecepatan Terbang (Fly Speed)", 20, 150, flySpeed, 5, function(v)
        flySpeed = v
    end, 2)

    -- Utilities Section
    local srvSec = UI.AddSection(mFrame, "Server & Diagnostics", 5)

    UI.AddButton(srvSec, "Rejoin Current Server", function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
    end, 1)

    UI.AddButton(srvSec, "Hop Server", function()
        TeleportService:Teleport(game.PlaceId, player)
    end, 2)
end)

if not success then
    warn("[HipHub TR Legacy Main Error]:", err)
end
