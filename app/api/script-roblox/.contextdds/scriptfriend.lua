--[[
    JAWADEOBF
--]]

--=====================================================================
-- ANTI-CHEAT / ANTI-TAMPER DETECTION
--=====================================================================
local JAWADEOBF_hookedThreads = {}

-- Deteksi thread yang berjalan di Core.Anti / Plugins.Anti_Cheat
local JAWADEOBF_detectAntiCheat = function()
    if not getreg or not getgc or not isfunctionhooked then
        return false
    end

    local JAWADEOBF_found = false
    for JAWADEOBF_idx, JAWADEOBF_thread in getreg() do
        if typeof(JAWADEOBF_thread) ~= "thread" then
            continue
        end

        local JAWADEOBF_info = debug.info(JAWADEOBF_thread, 1, "s")
        if JAWADEOBF_info
            and (JAWADEOBF_info:match(".Core.Anti")
                or JAWADEOBF_info:match(".Plugins.Anti_Cheat")) then
            JAWADEOBF_found = true
            table.insert(JAWADEOBF_hookedThreads, JAWADEOBF_thread)
        end
    end

    return JAWADEOBF_found
end

-- Netralkan fungsi anti-cheat dengan hookfunction
local JAWADEOBF_neutralizeAntiCheat = function()
    for JAWADEOBF_i, JAWADEOBF_thread in JAWADEOBF_hookedThreads do
        pcall(coroutine.close, JAWADEOBF_thread)
    end

    local JAWADEOBF_targets = {}

    if filtergc then
        local JAWADEOBF_tables = filtergc("table", {
            Keys = { "Detected", "RLocked" },
        }, false)

        for JAWADEOBF_i, JAWADEOBF_tbl in JAWADEOBF_tables do
            if typeof(rawget(JAWADEOBF_tbl, "Detected")) ~= "function" then
                continue
            end
            table.insert(JAWADEOBF_targets, JAWADEOBF_tbl)
        end
    else
        for JAWADEOBF_i, JAWADEOBF_tbl in getgc(true) do
            if typeof(JAWADEOBF_tbl) ~= "table" then
                continue
            end

            local JAWADEOBF_isTarget =
                typeof(rawget(JAWADEOBF_tbl, "Detected")) == "function"
                and rawget(JAWADEOBF_tbl, "RLocked")

            if not JAWADEOBF_isTarget then
                continue
            end
            table.insert(JAWADEOBF_targets, JAWADEOBF_tbl)
        end
    end

    local JAWADEOBF_count = 0
    for JAWADEOBF_i, JAWADEOBF_tbl in JAWADEOBF_targets do
        for JAWADEOBF_k, JAWADEOBF_fn in JAWADEOBF_tbl do
            if typeof(JAWADEOBF_fn) ~= "function"
                or isfunctionhooked(JAWADEOBF_fn) then
                continue
            end

            hookfunction(JAWADEOBF_fn, function(...)
                coroutine.yield(coroutine.running())
                return task.wait(9000000000)
            end)

            JAWADEOBF_count = JAWADEOBF_count + 1
        end
    end

    return true
end

if JAWADEOBF_detectAntiCheat() then
    JAWADEOBF_neutralizeAntiCheat()
end

--=====================================================================
-- ADONIS REMOTE SECURITY
--=====================================================================
pcall(secureAdonisRemote)
task.spawn(function()
    while task.wait(2) do
        pcall(secureAdonisRemote)
    end
end)

--=====================================================================
-- ANTI-IDLE
--=====================================================================
local JAWADEOBF_enableAntiIdle = true
if JAWADEOBF_enableAntiIdle then
    local JAWADEOBF_Players = game:GetService("Players")
    local JAWADEOBF_LP = JAWADEOBF_Players.LocalPlayer
    local JAWADEOBF_hooked = false

    if getconnections then
        pcall(function()
            for JAWADEOBF_i, JAWADEOBF_conn in pairs(getconnections(JAWADEOBF_LP.Idled)) do
                if JAWADEOBF_conn.Disable then
                    JAWADEOBF_conn:Disable()
                    JAWADEOBF_hooked = true
                elseif JAWADEOBF_conn.Disconnect then
                    JAWADEOBF_conn:Disconnect()
                    JAWADEOBF_hooked = true
                end
            end
        end)
    end

    if not JAWADEOBF_hooked then
        JAWADEOBF_LP.Idled:Connect(function()
            pcall(function()
                local JAWADEOBF_VU = game:FindService("VirtualUser")
                    or game:GetService("VirtualUser")
                if JAWADEOBF_VU then
                    JAWADEOBF_VU:CaptureController()
                    JAWADEOBF_VU:ClickButton2(Vector2.new())
                end
            end)
        end)
    end
end

--=====================================================================
-- MAIN MENU BYPASS
--=====================================================================
local JAWADEOBF_bypassMainMenu = function()
    pcall(function()
        -- Matikan blur menu
        local JAWADEOBF_Lighting = game:GetService("Lighting")
        local JAWADEOBF_blur = JAWADEOBF_Lighting:FindFirstChild("menuBlur")
        if JAWADEOBF_blur then
            JAWADEOBF_blur.Enabled = false
            JAWADEOBF_blur.Size = 0
        end

        -- Sembunyikan main menu, tampilkan MainUI
        local JAWADEOBF_Players = game:GetService("Players")
        local JAWADEOBF_LP = JAWADEOBF_Players.LocalPlayer
        local JAWADEOBF_PG = JAWADEOBF_LP and JAWADEOBF_LP:FindFirstChild("PlayerGui")
        if JAWADEOBF_PG then
            local JAWADEOBF_menu = JAWADEOBF_PG:FindFirstChild("mainMenuSystem")
            if JAWADEOBF_menu then
                JAWADEOBF_menu.Enabled = false

                local JAWADEOBF_base = JAWADEOBF_menu:FindFirstChild("baseFrame")
                if JAWADEOBF_base then
                    JAWADEOBF_base.Visible = false

                    local JAWADEOBF_snd = JAWADEOBF_base:FindFirstChild("SoundHome")
                    if JAWADEOBF_snd and JAWADEOBF_snd:IsA("Sound") then
                        JAWADEOBF_snd:Stop()
                    end
                end

                local JAWADEOBF_inter = JAWADEOBF_menu:FindFirstChild("intermissionFrame")
                if JAWADEOBF_inter then
                    JAWADEOBF_inter.Visible = false
                end
            end

            local JAWADEOBF_mainUI = JAWADEOBF_PG:FindFirstChild("MainUI")
            if JAWADEOBF_mainUI then
                JAWADEOBF_mainUI.Enabled = true
            end
        end

        -- Kamera
        local JAWADEOBF_cam = workspace.CurrentCamera
        if JAWADEOBF_cam then
            JAWADEOBF_cam.CameraType = Enum.CameraType.Custom
        end

        -- Tampilkan CoreGui
        pcall(function()
            game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
        end)

        -- Trigger menu toggle
        local JAWADEOBF_toggle = game:GetService("ReplicatedStorage")
            :FindFirstChild("menuToggleRequest")
        if JAWADEOBF_toggle and JAWADEOBF_toggle:IsA("RemoteEvent") then
            JAWADEOBF_toggle:FireServer()
        end
    end)
end

task.spawn(function()
    JAWADEOBF_bypassMainMenu()

    local JAWADEOBF_Players = game:GetService("Players")
    local JAWADEOBF_LP = JAWADEOBF_Players.LocalPlayer
    local JAWADEOBF_PG = JAWADEOBF_LP
        and JAWADEOBF_LP:WaitForChild("PlayerGui", 10)

    if JAWADEOBF_PG then
        JAWADEOBF_PG.ChildAdded:Connect(function(JAWADEOBF_child)
            if JAWADEOBF_child.Name == "mainMenuSystem" then
                task.wait(0.1)
                JAWADEOBF_bypassMainMenu()
            end
        end)
    end
end)

--=====================================================================
-- WINDUI INIT
--=====================================================================
local JAWADEOBF_WindUI = loadstring(
    game:HttpGet(
        "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
    )
)()

local JAWADEOBF_Window = JAWADEOBF_WindUI:CreateWindow({
    Title = "DDS",
    Icon = "van",
    Author = "DX-SR Hub",
    Folder = "DX-SR",
    Size = UDim2.fromOffset(580, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    ToggleKey = Enum.KeyCode.V,
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = false,
    ScrollBarEnabled = false,
})

JAWADEOBF_Window:Tag({
    Title = "v0.0.0.14",
    Icon = "github",
    Color = Color3.fromHex("#30ff6a"),
    Radius = 13,
})

JAWADEOBF_Window:Tag({
    Title = "DX-SR Hub",
    Icon = "text-cursor",
    Color = Color3.fromHex("#1E3A8A"),
    Radius = 13,
})

JAWADEOBF_WindUI:Popup({
    Title = "Update logs",
    Icon = "info",
    Content = "Added Various config save",
    Buttons = {
        {
            Title = "Continue",
            Icon = "arrow-right",
            Callback = function() end,
            Variant = "Primary",
        },
    },
})

--=====================================================================
-- SECTION: FARMING
--=====================================================================
local JAWADEOBF_FarmingSection = JAWADEOBF_Window:Section({
    Title = "Farming",
    Icon = "car",
    Opened = true,
})

--=====================================================================
-- TAB: RIDEGO
--=====================================================================
local JAWADEOBF_RidegoTab = JAWADEOBF_FarmingSection:Tab({
    Title = "Ridego",
    Icon = "car",
})

local JAWADEOBF_RidegoSection = JAWADEOBF_RidegoTab:Section({
    Title = "Ridego Farming",
})

local JAWADEOBF_tweenSpeed = 200
local JAWADEOBF_tweenHeight = 20

JAWADEOBF_RidegoTab:Slider({
    Title = "Tween Speed",
    Desc = "Kecepatan terbang",
    Step = 10,
    Flag = "RidegoTweenSpeed",
    Value = { Min = 0, Max = 500, Default = 200 },
    Callback = function(JAWADEOBF_v)
        JAWADEOBF_tweenSpeed = JAWADEOBF_v
    end,
})

JAWADEOBF_RidegoTab:Slider({
    Title = "Tween Height",
    Desc = "Ketinggian dari tanah",
    Step = 1,
    Flag = "RidegoTweenHeight",
    Value = { Min = 0, Max = 100, Default = 50 },
    Callback = function(JAWADEOBF_v)
        JAWADEOBF_tweenHeight = JAWADEOBF_v
    end,
})

local JAWADEOBF_vehicleList = { "Sizuki-SatriaFU(Drag)" }
local JAWADEOBF_selectedVehicle = JAWADEOBF_vehicleList[1]

local JAWADEOBF_fetchVehicles = function()
    local JAWADEOBF_list = {}

    pcall(function()
        local JAWADEOBF_RS = game:GetService("ReplicatedStorage")
        local JAWADEOBF_DE = JAWADEOBF_RS:FindFirstChild("DealershipEvents")

        if JAWADEOBF_DE and JAWADEOBF_DE:FindFirstChild("InitializeCarData") then
            local JAWADEOBF_data = JAWADEOBF_DE.InitializeCarData:InvokeServer()
            if type(JAWADEOBF_data) == "table" then
                for JAWADEOBF_i, JAWADEOBF_car in ipairs(JAWADEOBF_data) do
                    if JAWADEOBF_car.Name then
                        table.insert(JAWADEOBF_list, JAWADEOBF_car.Name)
                    end
                end
            end
        end
    end)

    if #JAWADEOBF_list == 0 then
        table.insert(JAWADEOBF_list, "Sizuki-SatriaFU(Drag)")
    end

    return JAWADEOBF_list
end

JAWADEOBF_vehicleList = JAWADEOBF_fetchVehicles()

local JAWADEOBF_vehicleDropdown = JAWADEOBF_RidegoTab:Dropdown({
    Title = "Select Vehicle",
    Desc = "Choose a vehicle to spawn",
    Multi = false,
    Flag = "RidegoSelectedVehicle",
    Value = JAWADEOBF_selectedVehicle,
    Values = JAWADEOBF_vehicleList,
    Callback = function(JAWADEOBF_v)
        JAWADEOBF_selectedVehicle = JAWADEOBF_v
    end,
})

JAWADEOBF_RidegoTab:Button({
    Title = "Refresh Vehicles",
    Desc = "Refresh your vehicle list",
    Callback = function()
        JAWADEOBF_vehicleList = JAWADEOBF_fetchVehicles()
        pcall(function()
            JAWADEOBF_vehicleDropdown:Refresh(JAWADEOBF_vehicleList)
        end)
        JAWADEOBF_WindUI:Notify({
            Title = "Refresh",
            Content = "Vehicle list updated!",
            Duration = 3,
        })
    end,
})

-- State Ridego
local JAWADEOBF_ridegoEnabled = false
local JAWADEOBF_ridegoBusy = false

-- Teleport via Seat (Ridego)
local JAWADEOBF_seatTeleport = function(JAWADEOBF_cf)
    local JAWADEOBF_LP = game:GetService("Players").LocalPlayer
    local JAWADEOBF_char = JAWADEOBF_LP.Character
    local JAWADEOBF_hrp = JAWADEOBF_char and JAWADEOBF_char:FindFirstChild("HumanoidRootPart")
    local JAWADEOBF_hum = JAWADEOBF_char and JAWADEOBF_char:FindFirstChildOfClass("Humanoid")
    local JAWADEOBF_anim = JAWADEOBF_char and JAWADEOBF_char:FindFirstChild("Animate")

    if not JAWADEOBF_hrp or not JAWADEOBF_hum then
        return
    end

    if JAWADEOBF_hum.Sit then
        JAWADEOBF_hum.Sit = false
        task.wait(0.1)
    end

    if JAWADEOBF_anim then
        JAWADEOBF_anim.Disabled = true
    end

    local JAWADEOBF_seat = Instance.new("Seat")
    JAWADEOBF_seat.Size = Vector3.new(2, 0.2, 2)
    JAWADEOBF_seat.Transparency = 1
    JAWADEOBF_seat.CanCollide = false
    JAWADEOBF_seat.Anchored = true
    JAWADEOBF_seat.CFrame = JAWADEOBF_hrp.CFrame
    JAWADEOBF_seat.Parent = workspace

    JAWADEOBF_hum.Sit = true
    JAWADEOBF_seat:Sit(JAWADEOBF_hum)

    local JAWADEOBF_bv = Instance.new("BodyVelocity")
    JAWADEOBF_bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    JAWADEOBF_bv.Velocity = Vector3.new(0, 0, 0)
    JAWADEOBF_bv.Parent = JAWADEOBF_hrp

    task.wait(0.5)

    JAWADEOBF_seat.Anchored = false
    local JAWADEOBF_target = JAWADEOBF_cf * CFrame.new(0, 0.01, 0)
    local JAWADEOBF_mid = JAWADEOBF_hrp.CFrame:Lerp(JAWADEOBF_target, 0.5)

    JAWADEOBF_seat.CFrame = JAWADEOBF_mid
    JAWADEOBF_hrp.CFrame = JAWADEOBF_mid
    task.wait(0.1)

    JAWADEOBF_seat.CFrame = JAWADEOBF_target
    JAWADEOBF_hrp.CFrame = JAWADEOBF_target
    JAWADEOBF_seat.Anchored = true

    task.wait(1.6)
    if JAWADEOBF_bv then
        JAWADEOBF_bv:Destroy()
    end

    JAWADEOBF_hum.Sit = false
    if JAWADEOBF_anim then
        JAWADEOBF_anim.Disabled = false
    end

    task.wait(0.3)
    if JAWADEOBF_seat then
        JAWADEOBF_seat:Destroy()
    end

    JAWADEOBF_hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    workspace.CurrentCamera.CameraSubject = JAWADEOBF_hum
end

-- Fly ke target dengan kendaraan (Ridego)
local JAWADEOBF_vehicleFly = function(JAWADEOBF_targetCF)
    local JAWADEOBF_LP = game:GetService("Players").LocalPlayer
    local JAWADEOBF_char = JAWADEOBF_LP.Character

    if not (JAWADEOBF_char
        and JAWADEOBF_char:FindFirstChild("Humanoid")
        and JAWADEOBF_char.Humanoid.Sit) then
        return
    end

    local JAWADEOBF_seatPart = JAWADEOBF_char.Humanoid.SeatPart
    if not JAWADEOBF_seatPart then
        return
    end

    local JAWADEOBF_primary = JAWADEOBF_seatPart
    local JAWADEOBF_model = JAWADEOBF_seatPart:FindFirstAncestorOfClass("Model")
    if JAWADEOBF_model and JAWADEOBF_model.PrimaryPart then
        JAWADEOBF_primary = JAWADEOBF_model.PrimaryPart
    end

    local JAWADEOBF_targetPos = JAWADEOBF_targetCF.Position
    local JAWADEOBF_RunService = game:GetService("RunService")

    local JAWADEOBF_conn = JAWADEOBF_RunService.Stepped:Connect(function()
        if JAWADEOBF_model then
            for JAWADEOBF_i, JAWADEOBF_p in ipairs(JAWADEOBF_model:GetDescendants()) do
                if JAWADEOBF_p:IsA("BasePart") then
                    JAWADEOBF_p.CanCollide = false
                end
            end
        end

        if JAWADEOBF_char then
            for JAWADEOBF_i, JAWADEOBF_p in ipairs(JAWADEOBF_char:GetDescendants()) do
                if JAWADEOBF_p:IsA("BasePart") then
                    JAWADEOBF_p.CanCollide = false
                end
            end
        end

        pcall(function()
            local JAWADEOBF_missions = workspace:FindFirstChild("ActiveMissions")
            if JAWADEOBF_missions then
                local JAWADEOBF_pass = JAWADEOBF_missions:FindFirstChild("RideGO_Passenger")
                if JAWADEOBF_pass then
                    for JAWADEOBF_i, JAWADEOBF_p in ipairs(JAWADEOBF_pass:GetDescendants()) do
                        if JAWADEOBF_p:IsA("BasePart") then
                            JAWADEOBF_p.CanCollide = false
                        end
                    end
                end
            end
        end)
    end)

    local JAWADEOBF_gyro = Instance.new("BodyGyro")
    JAWADEOBF_gyro.P = 90000
    JAWADEOBF_gyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    JAWADEOBF_gyro.D = 50
    JAWADEOBF_gyro.Parent = JAWADEOBF_primary

    local JAWADEOBF_bv = Instance.new("BodyVelocity")
    JAWADEOBF_bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    JAWADEOBF_bv.Velocity = Vector3.zero
    JAWADEOBF_bv.Parent = JAWADEOBF_primary

    if JAWADEOBF_model then
        for JAWADEOBF_i, JAWADEOBF_p in ipairs(JAWADEOBF_model:GetDescendants()) do
            if JAWADEOBF_p:IsA("BasePart") then
                JAWADEOBF_p.Anchored = false
            end
        end
    end

    local JAWADEOBF_speed = 230
    local JAWADEOBF_startTime = os.clock()

    while JAWADEOBF_ridegoEnabled do
        if not JAWADEOBF_primary or not JAWADEOBF_primary.Parent then
            break
        end

        local JAWADEOBF_cur = JAWADEOBF_primary.Position
        local JAWADEOBF_delta = JAWADEOBF_targetPos - JAWADEOBF_cur
        local JAWADEOBF_dist = JAWADEOBF_delta.Magnitude

        if JAWADEOBF_dist < 15 then
            break
        end
        if (os.clock() - JAWADEOBF_startTime) > 120 then
            break
        end

        JAWADEOBF_gyro.CFrame = JAWADEOBF_targetCF
        JAWADEOBF_bv.Velocity = JAWADEOBF_delta.Unit * JAWADEOBF_speed
        task.wait()
    end

    if JAWADEOBF_conn then
        JAWADEOBF_conn:Disconnect()
    end

    if JAWADEOBF_primary and JAWADEOBF_primary.Parent then
        pcall(function() JAWADEOBF_gyro:Destroy() end)
        pcall(function() JAWADEOBF_bv:Destroy() end)

        if JAWADEOBF_model then
            for JAWADEOBF_i, JAWADEOBF_p in ipairs(JAWADEOBF_model:GetDescendants()) do
                if JAWADEOBF_p:IsA("BasePart") then
                    JAWADEOBF_p.CanCollide = true
                    JAWADEOBF_p.Anchored = false
                end
            end

            local JAWADEOBF_driveSeat = JAWADEOBF_model:FindFirstChild("DriveSeat")
            if JAWADEOBF_driveSeat then
                JAWADEOBF_driveSeat.CanCollide = false
            end

            task.wait(0.5)

            -- Final approach: dorong kendaraan agar menempel ke posisi target
            if JAWADEOBF_primary and JAWADEOBF_primary.Parent then
                local JAWADEOBF_tpos = JAWADEOBF_targetCF.Position
                local JAWADEOBF_ppos = JAWADEOBF_primary.Position
                local JAWADEOBF_flat = (Vector3.new(JAWADEOBF_tpos.X, 0, JAWADEOBF_tpos.Z)
                    - Vector3.new(JAWADEOBF_ppos.X, 0, JAWADEOBF_ppos.Z)).Magnitude

                if JAWADEOBF_flat > 3 then
                    local JAWADEOBF_fbv = Instance.new("BodyVelocity")
                    JAWADEOBF_fbv.MaxForce = Vector3.new(1e9, 0, 1e9)
                    JAWADEOBF_fbv.Velocity = Vector3.zero
                    JAWADEOBF_fbv.Parent = JAWADEOBF_primary

                    local JAWADEOBF_fgyro = Instance.new("BodyGyro")
                    JAWADEOBF_fgyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
                    JAWADEOBF_fgyro.CFrame = JAWADEOBF_targetCF
                    JAWADEOBF_fgyro.Parent = JAWADEOBF_primary

                    local JAWADEOBF_t0 = os.clock()
                    while JAWADEOBF_ridegoEnabled
                        and JAWADEOBF_primary
                        and JAWADEOBF_primary.Parent do

                        local JAWADEOBF_p = JAWADEOBF_primary.Position
                        local JAWADEOBF_d = (Vector3.new(JAWADEOBF_tpos.X, 0, JAWADEOBF_tpos.Z)
                            - Vector3.new(JAWADEOBF_p.X, 0, JAWADEOBF_p.Z)).Magnitude

                        if JAWADEOBF_d <= 3 or (os.clock() - JAWADEOBF_t0) > 3 then
                            break
                        end

                        local JAWADEOBF_delta2 = JAWADEOBF_tpos - JAWADEOBF_p
                        JAWADEOBF_delta2 = Vector3.new(JAWADEOBF_delta2.X, 0, JAWADEOBF_delta2.Z)

                        if JAWADEOBF_delta2.Magnitude > 0 then
                            JAWADEOBF_fbv.Velocity = JAWADEOBF_delta2.Unit * 30
                        end

                        JAWADEOBF_fgyro.CFrame = JAWADEOBF_targetCF
                        task.wait()
                    end

                    pcall(function() JAWADEOBF_fbv:Destroy() end)
                    pcall(function() JAWADEOBF_fgyro:Destroy() end)
                end
            end
        end
    end

    if JAWADEOBF_char then
        for JAWADEOBF_i, JAWADEOBF_p in ipairs(JAWADEOBF_char:GetDescendants()) do
            if JAWADEOBF_p:IsA("BasePart") then
                JAWADEOBF_p.CanCollide = true
            end
        end
    end
end

-- Listen TaxiEvent untuk order Ridego
task.spawn(function()
    pcall(function()
        local JAWADEOBF_RS = game:GetService("ReplicatedStorage")
        local JAWADEOBF_taxiEvent = JAWADEOBF_RS:WaitForChild("TaxiAssets")
            :WaitForChild("Events")
            :WaitForChild("TaxiEvent")

        JAWADEOBF_taxiEvent.OnClientEvent:Connect(function(JAWADEOBF_action, JAWADEOBF_data)
            if not JAWADEOBF_ridegoEnabled then
                return
            end

            -- Auto-accept order
            if JAWADEOBF_action == "OrderOffer"
                and type(JAWADEOBF_data) == "table"
                and JAWADEOBF_data.Token then
                task.wait(1)
                JAWADEOBF_taxiEvent:FireServer("AcceptOrder", JAWADEOBF_data.Token)
                pcall(function()
                    JAWADEOBF_WindUI:Notify({
                        Title = "RideGO",
                        Content = "Auto-accepted order!",
                        Duration = 3,
                    })
                end)

            -- Order diterima: teleport ke pickup, spawn mobil, masuk
            elseif JAWADEOBF_action == "OrderAccepted"
                and type(JAWADEOBF_data) == "table" then

                local JAWADEOBF_pickup = JAWADEOBF_data.PickupAddr or "Unknown"
                local JAWADEOBF_dropoff = JAWADEOBF_data.DropAddr or "Unknown"

                pcall(function()
                    JAWADEOBF_WindUI:Notify({
                        Title = "Order Accepted",
                        Content = "Pickup: " .. JAWADEOBF_pickup .. "\nDropoff: " .. JAWADEOBF_dropoff,
                        Duration = 5,
                    })
                end)

                if JAWADEOBF_data.PickupPos then
                    task.spawn(function()
                        JAWADEOBF_ridegoBusy = true

                        -- Despawn mobil lama
                        pcall(function()
                            local JAWADEOBF_rs = game:GetService("ReplicatedStorage")
                            local JAWADEOBF_spawnEvents = JAWADEOBF_rs:FindFirstChild("SpawnCarEvents")
                            local JAWADEOBF_despawn = JAWADEOBF_spawnEvents
                                and JAWADEOBF_spawnEvents:FindFirstChild("DespawnCar")
                            if JAWADEOBF_despawn then
                                JAWADEOBF_despawn:FireServer()
                            end
                        end)

                        task.wait(0.9)

                        local JAWADEOBF_pickupCF = CFrame.new(JAWADEOBF_data.PickupPos)
                        if JAWADEOBF_data.PickupLook then
                            JAWADEOBF_pickupCF = CFrame.lookAt(
                                JAWADEOBF_data.PickupPos,
                                JAWADEOBF_data.PickupPos + JAWADEOBF_data.PickupLook
                            )
                        end

                        JAWADEOBF_seatTeleport(JAWADEOBF_pickupCF)
                        task.wait(0.5)

                        -- Spawn kendaraan
                        local JAWADEOBF_rs = game:GetService("ReplicatedStorage")
                        local JAWADEOBF_spawnEvents = JAWADEOBF_rs:FindFirstChild("SpawnCarEvents")
                        if JAWADEOBF_spawnEvents
                            and JAWADEOBF_spawnEvents:FindFirstChild("SpawnCar") then
                            JAWADEOBF_spawnEvents.SpawnCar:FireServer(JAWADEOBF_selectedVehicle)
                        end

                        -- Tunggu mobil muncul
                        local JAWADEOBF_LP = game:GetService("Players").LocalPlayer
                        local JAWADEOBF_myCar = nil

                        for JAWADEOBF_i = 1, 10 do
                            task.wait(0.5)
                            for JAWADEOBF_k, JAWADEOBF_obj in ipairs(workspace:GetChildren()) do
                                if string.match(JAWADEOBF_obj.Name,
                                    "^" .. JAWADEOBF_LP.Name .. "Montors_") then
                                    JAWADEOBF_myCar = JAWADEOBF_obj
                                    break
                                end
                            end
                            if JAWADEOBF_myCar then break end
                        end

                        if JAWADEOBF_myCar then
                            local JAWADEOBF_driveSeat = JAWADEOBF_myCar:FindFirstChild("DriveSeat")
                            if JAWADEOBF_driveSeat then
                                local JAWADEOBF_prompt = JAWADEOBF_driveSeat
                                    :FindFirstChildWhichIsA("ProximityPrompt")

                                if JAWADEOBF_prompt and JAWADEOBF_prompt.Enabled then
                                    local JAWADEOBF_front = JAWADEOBF_myCar:FindFirstChild("FrontSection")
                                    local JAWADEOBF_rear = JAWADEOBF_myCar:FindFirstChild("RearSection")

                                    if JAWADEOBF_front then
                                        pcall(function() JAWADEOBF_front:Destroy() end)
                                    end
                                    if JAWADEOBF_rear then
                                        pcall(function() JAWADEOBF_rear:Destroy() end)
                                    end

                                    local JAWADEOBF_hrp = JAWADEOBF_char
                                        and JAWADEOBF_char:FindFirstChild("HumanoidRootPart")
                                    if JAWADEOBF_hrp then
                                        JAWADEOBF_hrp.CFrame = JAWADEOBF_driveSeat.CFrame
                                        fireproximityprompt(JAWADEOBF_prompt)
                                    end
                                end
                            end
                        end

                        JAWADEOBF_ridegoBusy = false
                    end)
                end

            -- Trip dimulai: fly ke dropoff
            elseif JAWADEOBF_action == "TripStarted"
                and type(JAWADEOBF_data) == "table" then

                local JAWADEOBF_drop = JAWADEOBF_data.DropAddr or "Unknown"
                pcall(function()
                    JAWADEOBF_WindUI:Notify({
                        Title = "Trip Started",
                        Content = "Heading to Dropoff: " .. JAWADEOBF_drop,
                        Duration = 5,
                    })
                end)

                if JAWADEOBF_data.DropPos then
                    task.spawn(function()
                        JAWADEOBF_vehicleFly(CFrame.new(JAWADEOBF_data.DropPos))
                    end)
                end
            end
        end)
    end)
end)

-- Toggle Auto Farm Ridego
local JAWADEOBF_ridegoToggle = JAWADEOBF_RidegoTab:Toggle({
    Title = "Auto Farm Ridego",
    Flag = "RidegoAutoFarm",
    Callback = function(JAWADEOBF_state)
        JAWADEOBF_ridegoEnabled = JAWADEOBF_state

        if JAWADEOBF_state then
            local JAWADEOBF_RS = game:GetService("ReplicatedStorage")
            local JAWADEOBF_teamReq = JAWADEOBF_RS.JobEvents.TeamChangeRequest
            JAWADEOBF_teamReq:FireServer("RideGO Driver", 11378976, 1, 0, "Detector")

            task.spawn(function()
                while JAWADEOBF_ridegoEnabled do
                    if not JAWADEOBF_ridegoBusy then
                        local JAWADEOBF_LP = game:GetService("Players").LocalPlayer
                        local JAWADEOBF_char = JAWADEOBF_LP.Character

                        if JAWADEOBF_char
                            and JAWADEOBF_char:FindFirstChild("HumanoidRootPart")
                            and JAWADEOBF_char:FindFirstChild("Humanoid") then

                            local JAWADEOBF_hrp = JAWADEOBF_char.HumanoidRootPart
                            local JAWADEOBF_hum = JAWADEOBF_char.Humanoid
                            local JAWADEOBF_myCar = nil

                            for JAWADEOBF_i, JAWADEOBF_obj in ipairs(workspace:GetChildren()) do
                                if string.match(JAWADEOBF_obj.Name,
                                    "^" .. JAWADEOBF_LP.Name .. "Montors_") then
                                    JAWADEOBF_myCar = JAWADEOBF_obj
                                    break
                                end
                            end

                            if not JAWADEOBF_myCar then
                                local JAWADEOBF_rs = game:GetService("ReplicatedStorage")
                                local JAWADEOBF_spawnEvents = JAWADEOBF_rs
                                    :FindFirstChild("SpawnCarEvents")
                                if JAWADEOBF_spawnEvents
                                    and JAWADEOBF_spawnEvents:FindFirstChild("SpawnCar") then
                                    JAWADEOBF_spawnEvents.SpawnCar
                                        :FireServer(JAWADEOBF_selectedVehicle)
                                end
                                task.wait(1.5)
                            else
                                local JAWADEOBF_driveSeat = JAWADEOBF_myCar
                                    :FindFirstChild("DriveSeat")
                                if JAWADEOBF_driveSeat then
                                    local JAWADEOBF_prompt = JAWADEOBF_driveSeat
                                        :FindFirstChildWhichIsA("ProximityPrompt")

                                    if not JAWADEOBF_hum.Sit
                                        and JAWADEOBF_prompt
                                        and JAWADEOBF_prompt.Enabled then

                                        local JAWADEOBF_front = JAWADEOBF_myCar
                                            :FindFirstChild("FrontSection")
                                        local JAWADEOBF_rear = JAWADEOBF_myCar
                                            :FindFirstChild("RearSection")

                                        if JAWADEOBF_front then
                                            pcall(function() JAWADEOBF_front:Destroy() end)
                                        end
                                        if JAWADEOBF_rear then
                                            pcall(function() JAWADEOBF_rear:Destroy() end)
                                        end

                                        JAWADEOBF_hrp.CFrame = JAWADEOBF_driveSeat.CFrame
                                        fireproximityprompt(JAWADEOBF_prompt)

                                        task.spawn(function()
                                            task.wait(0.5)
                                            if JAWADEOBF_char
                                                and JAWADEOBF_char:FindFirstChild("Humanoid")
                                                and JAWADEOBF_char.Humanoid.Sit then

                                                local JAWADEOBF_rs = game:GetService("ReplicatedStorage")
                                                local JAWADEOBF_taxi = JAWADEOBF_rs:FindFirstChild("TaxiAssets")
                                                if JAWADEOBF_taxi
                                                    and JAWADEOBF_taxi:FindFirstChild("Events")
                                                    and JAWADEOBF_taxi.Events:FindFirstChild("TaxiEvent") then
                                                    JAWADEOBF_taxi.Events.TaxiEvent:FireServer("GoOnline")
                                                end
                                            end
                                        end)
                                    end
                                end
                            end
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end,
    Default = false,
})
JAWADEOBF_ridegoToggle:Lock()

--=====================================================================
-- WEBHOOK HELPER
--=====================================================================
local JAWADEOBF_request = request or http_request
    or (syn and syn.request)
    or (http and http.request)

getgenv().WEBHOOK_MSG_IDS = getgenv().WEBHOOK_MSG_IDS or {}
local JAWADEOBF_webhookIds = getgenv().WEBHOOK_MSG_IDS

local JAWADEOBF_sendWebhook = function(JAWADEOBF_url, JAWADEOBF_payload, JAWADEOBF_forceNew)
    if not JAWADEOBF_url or JAWADEOBF_url == "" or not JAWADEOBF_request then
        return
    end

    task.spawn(function()
        pcall(function()
            local JAWADEOBF_http = game:GetService("HttpService")
            local JAWADEOBF_base = string.gsub(JAWADEOBF_url, "%?.*$", "")
            local JAWADEOBF_existing = JAWADEOBF_webhookIds[JAWADEOBF_base]
            local JAWADEOBF_edited = false

            if not JAWADEOBF_forceNew and JAWADEOBF_existing and JAWADEOBF_existing ~= "" then
                local JAWADEOBF_editUrl = JAWADEOBF_base .. "/messages/" .. tostring(JAWADEOBF_existing)
                local JAWADEOBF_res = JAWADEOBF_request({
                    Url = JAWADEOBF_editUrl,
                    Method = "PATCH",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = JAWADEOBF_http:JSONEncode(JAWADEOBF_payload),
                })

                if JAWADEOBF_res
                    and (JAWADEOBF_res.StatusCode == 200
                        or JAWADEOBF_res.StatusCode == 204
                        or (JAWADEOBF_res.Status
                            and string.match(tostring(JAWADEOBF_res.Status), "^2"))) then
                    JAWADEOBF_edited = true
                end
            end

            if not JAWADEOBF_edited then
                local JAWADEOBF_postUrl = JAWADEOBF_base .. "?wait=true"
                local JAWADEOBF_res = JAWADEOBF_request({
                    Url = JAWADEOBF_postUrl,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = JAWADEOBF_http:JSONEncode(JAWADEOBF_payload),
                })

                if not JAWADEOBF_forceNew and JAWADEOBF_res and JAWADEOBF_res.Body then
                    local JAWADEOBF_ok, JAWADEOBF_parsed = pcall(function()
                        return JAWADEOBF_http:JSONDecode(JAWADEOBF_res.Body)
                    end)
                    if JAWADEOBF_ok
                        and type(JAWADEOBF_parsed) == "table"
                        and JAWADEOBF_parsed.id then
                        JAWADEOBF_webhookIds[JAWADEOBF_base] = tostring(JAWADEOBF_parsed.id)
                    end
                end
            end
        end)
    end)
end

-- Format detik ke HH:MM:SS
local JAWADEOBF_formatTime = function(JAWADEOBF_sec)
    local JAWADEOBF_h = math.floor(JAWADEOBF_sec / 3600)
    local JAWADEOBF_m = math.floor((JAWADEOBF_sec % 3600) / 60)
    local JAWADEOBF_s = math.floor(JAWADEOBF_sec % 60)
    return string.format("%02dh %02dm %02ds", JAWADEOBF_h, JAWADEOBF_m, JAWADEOBF_s)
end

--=====================================================================
-- TELEPORT DATA PERSISTENCE (untuk auto-rejoin)
--=====================================================================
local JAWADEOBF_rejoinPayload = [[
-- Langsung hilangkan GUI main menu & trigger spawn saat reconnect
task.spawn(function()
    pcall(function()
        local Lighting = game:GetService("Lighting")
        local blur = Lighting:FindFirstChild("menuBlur")
        if blur then
            blur.Enabled = false
            blur.Size = 0
        end

        local player = game:GetService("Players").LocalPlayer
        if player and player:FindFirstChild("PlayerGui") then
            local mainUI = player.PlayerGui:FindFirstChild("MainUI")
            if mainUI and mainUI:FindFirstChild("Holder") then
                mainUI.Holder.Visible = false
            end
        end

        pcall(function()
            local menuEvent = game:GetService("ReplicatedStorage"):WaitForChild("menuToggleRequest", 5)
            if menuEvent and menuEvent:IsA("RemoteEvent") then
                menuEvent:FireServer()
            end
        end)

        pcall(function()
            game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
        end)

        local cam = workspace.CurrentCamera
        if cam then
            cam.CameraType = Enum.CameraType.Custom
        end
    end)
end)

local ok, data = pcall(function()
    return game:GetService("TeleportService"):GetLocalPlayerTeleportData()
end)
if ok and typeof(data) == "CFrame" then
    local Players = game:GetService("Players")
    local ME = Players.LocalPlayer
    while not ME do
        Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
        ME = Players.LocalPlayer
    end

    local Character = ME.Character or ME.CharacterAdded:Wait()
    Character:WaitForChild("HumanoidRootPart")

    local t = tick()
    while (tick() - t) <= 0.3 do
        Character:PivotTo(data)
        task.wait()
    end
end
]]

-- Rejoin server (dengan simpan state auto-resume)
local JAWADEOBF_rejoinServer = function(JAWADEOBF_reason)
    local JAWADEOBF_TP = game:GetService("TeleportService")
    local JAWADEOBF_Players = game:GetService("Players")
    local JAWADEOBF_LP = JAWADEOBF_Players.LocalPlayer
    local JAWADEOBF_placeId = game.PlaceId
    local JAWADEOBF_jobId = game.JobId
    local JAWADEOBF_pivot = nil

    local JAWADEOBF_queue = (syn and syn.queue_on_teleport)
        or queue_on_teleport
        or (fluxus and fluxus.queue_on_teleport)

    if JAWADEOBF_queue and JAWADEOBF_LP and JAWADEOBF_LP.Character then
        pcall(function()
            JAWADEOBF_pivot = JAWADEOBF_LP.Character:GetPivot()

            local JAWADEOBF_payload = ""
            if getgenv().WEBHOOK_MSG_IDS then
                for JAWADEOBF_k, JAWADEOBF_v in pairs(getgenv().WEBHOOK_MSG_IDS) do
                    JAWADEOBF_payload = JAWADEOBF_payload .. string.format(
                        "getgenv().WEBHOOK_MSG_IDS = getgenv().WEBHOOK_MSG_IDS or {}; getgenv().WEBHOOK_MSG_IDS[%q] = %q\n",
                        JAWADEOBF_k, JAWADEOBF_v
                    )
                end
            end

            if isBaristaFarming or baristaRejoining then
                JAWADEOBF_payload = JAWADEOBF_payload
                    .. "getgenv().AUTO_RESUME_BARISTA = true\n"
            end
            if isCourierFarming or courierRejoining then
                JAWADEOBF_payload = JAWADEOBF_payload
                    .. "getgenv().AUTO_RESUME_COURIER = true\n"
            end

            JAWADEOBF_queue(JAWADEOBF_payload .. JAWADEOBF_rejoinPayload)
        end)
    end

    if #JAWADEOBF_Players:GetPlayers() <= 1 then
        pcall(function()
            JAWADEOBF_LP:Kick(JAWADEOBF_reason or "\n[DX-SR] Rejoining Server...")
        end)
        task.wait(0.3)
        JAWADEOBF_TP:Teleport(JAWADEOBF_placeId, JAWADEOBF_LP, JAWADEOBF_pivot)
    else
        JAWADEOBF_TP:TeleportToPlaceInstance(
            JAWADEOBF_placeId, JAWADEOBF_jobId, JAWADEOBF_LP, nil, JAWADEOBF_pivot
        )
    end
end

--=====================================================================
-- TAB: COURIER (COURIR)
--=====================================================================
local JAWADEOBF_CourierTab = JAWADEOBF_FarmingSection:Tab({
    Title = "Courir",
    Icon = "box",
})

local JAWADEOBF_CourierSection = JAWADEOBF_CourierTab:Section({
    Title = "Courier Farming",
    Opened = true,
})

-- State Courier
local JAWADEOBF_courierEnabled = false
local JAWADEOBF_courierSpeed = 230
local JAWADEOBF_courierDropDelay = 5
local JAWADEOBF_courierJobId = nil
local JAWADEOBF_courierStartTime = nil
local JAWADEOBF_courierDistance = 0
local JAWADEOBF_courierResetFlag = false
local JAWADEOBF_courierLastJobTime = os.clock()
local JAWADEOBF_courierRestarting = false
local JAWADEOBF_courierTotalEarn = 0
local JAWADEOBF_courierJobCount = 0
local JAWADEOBF_courierLastNotif = ""
local JAWADEOBF_courierShiftLimit = false
local JAWADEOBF_courierRejoinWarned = false
local JAWADEOBF_courierRejoinDone = false
local JAWADEOBF_courierLimitSeconds = 3 * 3600

local JAWADEOBF_courierToggle = JAWADEOBF_CourierSection:Toggle({
    Title = "Autofarm Courier",
    Desc = "Auto delivery courir",
    Flag = "CourierAutoFarm",
    Callback = function(JAWADEOBF_state)
        JAWADEOBF_courierEnabled = JAWADEOBF_state

        if JAWADEOBF_state then
            JAWADEOBF_courierResetFlag = true
            JAWADEOBF_courierStartTime = os.clock()
            JAWADEOBF_courierRejoinWarned = false
            JAWADEOBF_courierRejoinDone = false

            game:GetService("ReplicatedStorage").JobEvents.TeamChangeRequest
                :FireServer("Courier", 11378976, 0, 0, "Detector")
        else
            JAWADEOBF_courierStartTime = nil
            JAWADEOBF_courierRejoinWarned = false
            JAWADEOBF_courierRejoinDone = false
            pcall(function()
                InfoTime:SetDesc("00h 00m 00s")
                InfoCountdown:SetDesc("03h 00m 00s")
            end)
        end
    end,
    Default = false,
})

JAWADEOBF_CourierSection:Slider({
    Title = "Courier Speed",
    Desc = "Adjust the courier delays",
    Step = 10,
    Flag = "CourierSpeed",
    Value = { Min = 0, Max = 500, Default = 230 },
    Callback = function(JAWADEOBF_v)
        JAWADEOBF_courierSpeed = JAWADEOBF_v
    end,
})

JAWADEOBF_CourierSection:Slider({
    Title = "Dropoff Delay",
    Desc = "Wait time (seconds) at delivery location",
    Step = 1,
    Flag = "CourierDropoffDelay",
    Value = { Min = 0, Max = 10, Default = 5 },
    Callback = function(JAWADEOBF_v)
        JAWADEOBF_courierDropDelay = JAWADEOBF_v
    end,
})

local JAWADEOBF_courierWebhook = ""
local JAWADEOBF_courierWebhookOn = false

JAWADEOBF_CourierSection:Input({
    Title = "Webhook URL",
    Desc = "Enter Discord Webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    Flag = "CourierWebhookUrl",
    Callback = function(JAWADEOBF_v)
        JAWADEOBF_courierWebhook = JAWADEOBF_v
    end,
})

JAWADEOBF_CourierSection:Toggle({
    Title = "Enable Webhook",
    Desc = "Send courier notifications to Discord",
    Flag = "CourierWebhookEnabled",
    Default = false,
    Callback = function(JAWADEOBF_v)
        JAWADEOBF_courierWebhookOn = JAWADEOBF_v
    end,
})

local JAWADEOBF_CourierInfo = JAWADEOBF_CourierTab:Section({
    Title = "Information",
    Opened = true,
})

local JAWADEOBF_infoTime = JAWADEOBF_CourierInfo:Paragraph({
    Title = "Time Elapsed",
    Desc = "00h 00m 00s",
})
local JAWADEOBF_infoRejoin = JAWADEOBF_CourierInfo:Paragraph({
    Title = "Rejoin in",
    Desc = "03h 00m 00s",
})
local JAWADEOBF_infoDest = JAWADEOBF_CourierInfo:Paragraph({
    Title = "Next Destination",
    Desc = "-",
})
local JAWADEOBF_infoDist = JAWADEOBF_CourierInfo:Paragraph({
    Title = "Distance",
    Desc = "0 studs",
})
local JAWADEOBF_infoEarn = JAWADEOBF_CourierInfo:Paragraph({
    Title = "Total Earning",
    Desc = "Rp. 0",
})
local JAWADEOBF_infoJobs = JAWADEOBF_CourierInfo:Paragraph({
    Title = "Total Job Done",
    Desc = "0",
})

-- Format angka ke Rp. 1,234,567
local JAWADEOBF_formatRupiah = function(JAWADEOBF_n)
    return "Rp. " .. tostring(JAWADEOBF_n):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

-- Kirim notif webhook courier
local JAWADEOBF_courierWebhookSend = function(JAWADEOBF_isStuck, JAWADEOBF_isRejoin)
    if not JAWADEOBF_courierWebhookOn or JAWADEOBF_courierWebhook == "" then
        return
    end

    local JAWADEOBF_elapsed = JAWADEOBF_courierStartTime
        and JAWADEOBF_formatTime(os.clock() - JAWADEOBF_courierStartTime)
        or "00h 00m 00s"

    local JAWADEOBF_remain = JAWADEOBF_courierStartTime
        and JAWADEOBF_formatTime(math.max(0,
            JAWADEOBF_courierLimitSeconds - (os.clock() - JAWADEOBF_courierStartTime)))
        or "03h 00m 00s"

    local JAWADEOBF_destName = "-"
    pcall(function()
        local JAWADEOBF_liv = workspace:FindFirstChild("Livrason")
            and workspace.Livrason:FindFirstChild("Location")
        if JAWADEOBF_courierJobId and JAWADEOBF_liv
            and JAWADEOBF_liv:FindFirstChild(JAWADEOBF_courierJobId) then
            JAWADEOBF_destName = JAWADEOBF_liv[JAWADEOBF_courierJobId]
                .POINT.billboardgui:GetChildren()[2].Text
        elseif JAWADEOBF_courierJobId then
            JAWADEOBF_destName = "Location " .. JAWADEOBF_courierJobId
        end
    end)

    local JAWADEOBF_money = JAWADEOBF_formatRupiah(JAWADEOBF_courierTotalEarn)
    local JAWADEOBF_msg = { username = "DX-SR Courier" }

    if JAWADEOBF_isRejoin then
        JAWADEOBF_msg.embeds = {{
            title = "🔁 Courier Auto Rejoin (3 Hours Limit Reached)",
            description = "Farming Courier telah mencapai batas aman 3 jam. Melakukan auto rejoin server untuk mereset session & anti-cheat!",
            color = 16711680,
            fields = {
                { name = "⏳ Time Elapse", value = "`" .. JAWADEOBF_elapsed .. "`", inline = true },
                { name = "💰 Total Earning", value = "`" .. JAWADEOBF_money .. "`", inline = true },
                { name = "📦 Total Job Done", value = "`" .. tostring(JAWADEOBF_courierJobCount) .. "`", inline = true },
            },
            footer = { text = "DX-SR Hub • Courier System" },
            timestamp = DateTime.now():ToIsoDate(),
        }}
    elseif JAWADEOBF_isStuck then
        JAWADEOBF_msg.embeds = {{
            title = "🚨 Stuck (job restarted)",
            description = "Courier mendeteksi stuck / limit shift dan telah me-restart job dari awal!",
            color = 16731469,
            fields = {
                { name = "⏳ Time Elapse", value = "`" .. JAWADEOBF_elapsed .. "`", inline = true },
                { name = "🔁 Rejoin in", value = "`" .. JAWADEOBF_remain .. "`", inline = true },
                { name = "📍 Next Destination", value = "`" .. JAWADEOBF_destName .. "`", inline = true },
                { name = "💰 Total Earning", value = "`" .. JAWADEOBF_money .. "`", inline = true },
                { name = "📦 Total Job Done", value = "`" .. tostring(JAWADEOBF_courierJobCount) .. "`", inline = true },
            },
            footer = { text = "DX-SR Hub • Courier System" },
            timestamp = DateTime.now():ToIsoDate(),
        }}
    else
        JAWADEOBF_msg.embeds = {{
            title = "📦 Courier Delivery Completed",
            color = 54478,
            fields = {
                { name = "⏳ Time Elapse", value = "`" .. JAWADEOBF_elapsed .. "`", inline = true },
                { name = "🔁 Rejoin in", value = "`" .. JAWADEOBF_remain .. "`", inline = true },
                { name = "📍 Next Destination", value = "`" .. JAWADEOBF_destName .. "`", inline = true },
                { name = "💰 Total Earning", value = "`" .. JAWADEOBF_money .. "`", inline = true },
                { name = "📦 Total Job Done", value = "`" .. tostring(JAWADEOBF_courierJobCount) .. "`", inline = true },
            },
            footer = { text = "DX-SR Hub • Courier System" },
            timestamp = DateTime.now():ToIsoDate(),
        }}
    end

    JAWADEOBF_sendWebhook(JAWADEOBF_courierWebhook, JAWADEOBF_msg)
end

-- Warning 10 detik sebelum rejoin
local JAWADEOBF_courierRejoinWarning = function()
    if not JAWADEOBF_courierWebhookOn or JAWADEOBF_courierWebhook == "" then
        return
    end

    local JAWADEOBF_elapsed = JAWADEOBF_courierStartTime
        and JAWADEOBF_formatTime(os.clock() - JAWADEOBF_courierStartTime)
        or "02h 59m 50s"
    local JAWADEOBF_money = JAWADEOBF_formatRupiah(JAWADEOBF_courierTotalEarn)

    JAWADEOBF_sendWebhook(JAWADEOBF_courierWebhook, {
        content = "@everyone",
        username = "DX-SR Courier",
        embeds = {{
            title = "🚨 Courier Auto Rejoin Warning (10 Detik Tersisa)",
            description = "Waktu farming Courier telah mencapai batas aman 3 jam. Client akan melakukan **Auto Rejoin dalam 10 detik**!",
            color = 16711680,
            fields = {
                { name = "⏳ Time Elapse", value = "`" .. JAWADEOBF_elapsed .. "`", inline = true },
                { name = "🔁 Rejoin in", value = "`10 Detik`", inline = true },
                { name = "💰 Total Earning", value = "`" .. JAWADEOBF_money .. "`", inline = true },
                { name = "📦 Total Job Done", value = "`" .. tostring(JAWADEOBF_courierJobCount) .. "`", inline = true },
            },
            footer = { text = "DX-SR Hub • Courier Rejoin Alert" },
            timestamp = DateTime.now():ToIsoDate(),
        }},
    }, true)
end

-- Timer loop courier
task.spawn(function()
    while task.wait(1) do
        if JAWADEOBF_courierEnabled and JAWADEOBF_courierStartTime then
            local JAWADEOBF_elapsed = os.clock() - JAWADEOBF_courierStartTime
            local JAWADEOBF_remain = math.max(0,
                JAWADEOBF_courierLimitSeconds - JAWADEOBF_elapsed)

            pcall(function()
                JAWADEOBF_infoTime:SetDesc(JAWADEOBF_formatTime(JAWADEOBF_elapsed))
                JAWADEOBF_infoRejoin:SetDesc(JAWADEOBF_formatTime(JAWADEOBF_remain))
            end)

            if JAWADEOBF_remain <= 10 and not JAWADEOBF_courierRejoinDone then
                JAWADEOBF_courierRejoinDone = true
                pcall(function() JAWADEOBF_courierRejoinWarning() end)
            end

            if JAWADEOBF_elapsed >= JAWADEOBF_courierLimitSeconds
                and not JAWADEOBF_courierRejoinWarned then
                JAWADEOBF_courierRejoinWarned = true
                pcall(function() JAWADEOBF_courierWebhookSend(false, true) end)
                task.wait(0.5)
                JAWADEOBF_rejoinServer(
                    "\n[DX-SR] Courier 3 Hours Limit Reached - Auto Rejoining..."
                )
            end
        else
            pcall(function()
                JAWADEOBF_infoTime:SetDesc("00h 00m 00s")
                JAWADEOBF_infoRejoin:SetDesc("03h 00m 00s")
            end)
        end
    end
end)

-- Handle shift limit courier
local JAWADEOBF_courierHandleShiftLimit = function()
    if JAWADEOBF_courierShiftLimit then return end
    JAWADEOBF_courierShiftLimit = true
    JAWADEOBF_courierLastNotif = os.date("%H:%M:%S")

    JAWADEOBF_courierWebhookSend(true)
    pcall(function()
        JAWADEOBF_WindUI:Notify({
            Title = "Courier Shift Limit",
            Content = "Limit shift tercapai! Berpindah ke Civilian...",
            Duration = 3,
        })
    end)

    JAWADEOBF_courierJobId = nil
    JAWADEOBF_courierResetFlag = false
    pcall(function() JAWADEOBF_infoDest:SetDesc("-") end)

    pcall(function()
        local JAWADEOBF_teamReq = game:GetService("ReplicatedStorage")
            :WaitForChild("JobEvents"):WaitForChild("TeamChangeRequest")
        JAWADEOBF_teamReq:FireServer("Civilian", 0, 0, 0, "MainMenu")
    end)

    task.wait(3)

    pcall(function()
        JAWADEOBF_WindUI:Notify({
            Title = "Courier Shift Limit",
            Content = "Masuk kembali ke job Courier...",
            Duration = 3,
        })
        local JAWADEOBF_teamReq = game:GetService("ReplicatedStorage")
            :WaitForChild("JobEvents"):WaitForChild("TeamChangeRequest")
        JAWADEOBF_teamReq:FireServer("Courier", 11378976, 1, 0, "Detector")
    end)

    local JAWADEOBF_LP = game:GetService("Players").LocalPlayer
    local JAWADEOBF_char = JAWADEOBF_LP.Character
    if not JAWADEOBF_char
        or not JAWADEOBF_char:FindFirstChild("Humanoid")
        or JAWADEOBF_char.Humanoid.Health <= 0 then
        JAWADEOBF_LP.CharacterAdded:Wait()
    end

    task.wait(2)
    JAWADEOBF_courierResetFlag = true
    JAWADEOBF_courierRestarting = false
    JAWADEOBF_courierJobId = nil
    JAWADEOBF_courierLastJobTime = os.clock()
    JAWADEOBF_courierShiftLimit = false
end

-- Deteksi shift limit via NotifEvent
task.spawn(function()
    pcall(function()
        local JAWADEOBF_notif = game:GetService("ReplicatedStorage")
            :WaitForChild("Notification", 9e9)
            :WaitForChild("NotifEvent", 9e9)

        JAWADEOBF_notif.OnClientEvent:Connect(function(JAWADEOBF_key, JAWADEOBF_val)
            if not JAWADEOBF_courierEnabled then return end

            local JAWADEOBF_isLimit = false

            if typeof(JAWADEOBF_val) == "string" then
                if JAWADEOBF_val:find("NC_SHIFT_LIMIT")
                    or JAWADEOBF_val:find("shift kurir tercapai")
                    or JAWADEOBF_val:lower():find("courier shift limit") then
                    JAWADEOBF_isLimit = true
                end
            elseif typeof(JAWADEOBF_val) == "table" then
                if JAWADEOBF_val.k == "NC_SHIFT_LIMIT"
                    or (JAWADEOBF_val.a
                        and tostring(JAWADEOBF_val.a):find("NC_SHIFT_LIMIT")) then
                    JAWADEOBF_isLimit = true
                end
            end

            if typeof(JAWADEOBF_key) == "string"
                and (JAWADEOBF_key:find("NC_SHIFT_LIMIT")
                    or JAWADEOBF_key:lower():find("courier shift")) then
                JAWADEOBF_isLimit = true
            end

            if JAWADEOBF_isLimit then
                task.spawn(JAWADEOBF_courierHandleShiftLimit)
            end
        end)
    end)
end)

-- Monitor notif UI untuk total earning & job count
task.spawn(function()
    local JAWADEOBF_LP = game:GetService("Players").LocalPlayer
    local JAWADEOBF_PG = JAWADEOBF_LP:WaitForChild("PlayerGui", 9e9)
        :WaitForChild("MainUI", 9e9)
    local JAWADEOBF_Frame4 = JAWADEOBF_PG:WaitForChild("Frame4", 9e9)
    local JAWADEOBF_NOTIF = JAWADEOBF_Frame4:WaitForChild("NOTIF", 9e9)

    JAWADEOBF_NOTIF:GetPropertyChangedSignal("Text"):Connect(function()
        if not JAWADEOBF_courierEnabled then return end

        local JAWADEOBF_text = JAWADEOBF_NOTIF.Text
        if JAWADEOBF_text == "" or JAWADEOBF_text == JAWADEOBF_courierLastNotif then
            return
        end

        JAWADEOBF_courierLastNotif = JAWADEOBF_text

        if JAWADEOBF_text:find("NC_SHIFT_LIMIT")
            or JAWADEOBF_text:find("shift kurir tercapai")
            or JAWADEOBF_text:lower():find("courier shift limit") then
            task.spawn(JAWADEOBF_courierHandleShiftLimit)
            return
        end

        local JAWADEOBF_digits = JAWADEOBF_text:gsub("[^%d]", "")
        if JAWADEOBF_digits ~= "" then
            local JAWADEOBF_amount = tonumber(JAWADEOBF_digits) or 0
            JAWADEOBF_courierTotalEarn = JAWADEOBF_courierTotalEarn + JAWADEOBF_amount
            JAWADEOBF_courierJobCount = JAWADEOBF_courierJobCount + 1

            pcall(function()
                JAWADEOBF_infoEarn:SetDesc(JAWADEOBF_formatRupiah(JAWADEOBF_courierTotalEarn))
            end)
            pcall(function()
                JAWADEOBF_infoJobs:SetDesc(tostring(JAWADEOBF_courierJobCount))
            end)

            JAWADEOBF_courierWebhookSend(false)
        end
    end)
end)

-- Listen job baru dari ServiceEvent
game:GetService("ReplicatedStorage")
    :WaitForChild("Delivery System")
    .Settings.ServiceEvent.OnClientEvent:Connect(function(JAWADEOBF_evt, JAWADEOBF_act, JAWADEOBF_id)
        if JAWADEOBF_evt == "ServiceEvent"
            and JAWADEOBF_act == "Create"
            and JAWADEOBF_id then

            JAWADEOBF_courierJobId = tostring(JAWADEOBF_id)
            JAWADEOBF_courierLastJobTime = os.clock()
            JAWADEOBF_courierResetFlag = false

            pcall(function()
                local JAWADEOBF_liv = workspace:FindFirstChild("Livrason")
                    and workspace.Livrason:FindFirstChild("Location")
                if JAWADEOBF_liv and JAWADEOBF_liv:FindFirstChild(JAWADEOBF_courierJobId) then
                    local JAWADEOBF_name = JAWADEOBF_liv[JAWADEOBF_courierJobId]
                        .POINT.billboardgui:GetChildren()[2].Text
                    JAWADEOBF_infoDest:SetDesc(JAWADEOBF_name)
                else
                    JAWADEOBF_infoDest:SetDesc("Location " .. JAWADEOBF_courierJobId)
                end
            end)
        end
    end)

-- Fly ke posisi (Courier) via seat + BodyVelocity
local JAWADEOBF_courierFlyTo = function(JAWADEOBF_targetCF)
    local JAWADEOBF_LP = game:GetService("Players").LocalPlayer
    local JAWADEOBF_char = JAWADEOBF_LP.Character
    local JAWADEOBF_hrp = JAWADEOBF_char and JAWADEOBF_char:FindFirstChild("HumanoidRootPart")
    local JAWADEOBF_hum = JAWADEOBF_char and JAWADEOBF_char:FindFirstChildOfClass("Humanoid")

    if not JAWADEOBF_hrp or not JAWADEOBF_hum then return end

    JAWADEOBF_hum.AutoRotate = false

    local JAWADEOBF_seat = Instance.new("Seat")
    JAWADEOBF_seat.Name = "courier_seat"
    JAWADEOBF_seat.Size = Vector3.new(1, 1, 1)
    JAWADEOBF_seat.Transparency = 1
    JAWADEOBF_seat.CanCollide = false
    JAWADEOBF_seat.CFrame = JAWADEOBF_hrp.CFrame
    JAWADEOBF_seat.Parent = workspace

    local JAWADEOBF_weld = Instance.new("WeldConstraint")
    JAWADEOBF_weld.Part0 = JAWADEOBF_seat
    JAWADEOBF_weld.Part1 = JAWADEOBF_hrp
    JAWADEOBF_weld.Parent = JAWADEOBF_seat

    local JAWADEOBF_bv = Instance.new("BodyVelocity")
    JAWADEOBF_bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    JAWADEOBF_bv.Velocity = Vector3.new(0, 0, 0)
    JAWADEOBF_bv.Parent = JAWADEOBF_seat

    local JAWADEOBF_gyro = Instance.new("BodyGyro")
    JAWADEOBF_gyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    JAWADEOBF_gyro.CFrame = JAWADEOBF_hrp.CFrame
    JAWADEOBF_gyro.Parent = JAWADEOBF_seat

    local JAWADEOBF_seatConn
    JAWADEOBF_seatConn = game:GetService("RunService").Stepped:Connect(function()
        if JAWADEOBF_hum.SeatPart ~= JAWADEOBF_seat then
            JAWADEOBF_hum.Sit = true
            JAWADEOBF_seat:Sit(JAWADEOBF_hum)
        end
    end)

    local JAWADEOBF_origCollide = {}
    local JAWADEOBF_collideConn = game:GetService("RunService").Stepped:Connect(function()
        if JAWADEOBF_char then
            for JAWADEOBF_i, JAWADEOBF_p in ipairs(JAWADEOBF_char:GetDescendants()) do
                if JAWADEOBF_p:IsA("BasePart") and JAWADEOBF_p.CanCollide then
                    JAWADEOBF_p.CanCollide = false
                    JAWADEOBF_origCollide[JAWADEOBF_p] = true
                end
            end
        end
    end)

    -- Animasi duduk
    local JAWADEOBF_animator = JAWADEOBF_hum:FindFirstChildOfClass("Animator")
    local JAWADEOBF_animTrack
    if JAWADEOBF_animator then
        pcall(function()
            local JAWADEOBF_anim = Instance.new("Animation")
            JAWADEOBF_anim.AnimationId = "rbxassetid://507766388"
            JAWADEOBF_animTrack = JAWADEOBF_animator:LoadAnimation(JAWADEOBF_anim)
            JAWADEOBF_animTrack.Priority = Enum.AnimationPriority.Action
            JAWADEOBF_animTrack:Play()
        end)
    end

    local JAWADEOBF_targetPos = JAWADEOBF_targetCF.Position
    local JAWADEOBF_startTime = os.clock()

    while JAWADEOBF_courierEnabled and JAWADEOBF_hrp do
        local JAWADEOBF_cur = JAWADEOBF_hrp.Position
        local JAWADEOBF_delta = JAWADEOBF_targetPos - JAWADEOBF_cur
        local JAWADEOBF_dist = JAWADEOBF_delta.Magnitude

        JAWADEOBF_courierDistance = math.floor(JAWADEOBF_dist)
        pcall(function()
            JAWADEOBF_infoDist:SetDesc(tostring(JAWADEOBF_courierDistance) .. " studs")
        end)

        if JAWADEOBF_dist < 8 then break end
        if (os.clock() - JAWADEOBF_startTime) > 180 then break end

        JAWADEOBF_bv.Velocity = JAWADEOBF_delta.Unit * JAWADEOBF_courierSpeed
        JAWADEOBF_gyro.CFrame = CFrame.lookAt(JAWADEOBF_cur, JAWADEOBF_targetPos)
        task.wait()
    end

    JAWADEOBF_seatConn:Disconnect()
    JAWADEOBF_collideConn:Disconnect()

    for JAWADEOBF_part, JAWADEOBF_ in pairs(JAWADEOBF_origCollide) do
        if typeof(JAWADEOBF_part) == "Instance"
            and JAWADEOBF_part:IsA("BasePart")
            and JAWADEOBF_part.Parent then
            JAWADEOBF_part.CanCollide = true
        end
    end

    if JAWADEOBF_bv then
        JAWADEOBF_bv.Velocity = Vector3.new(0, 0, 0)
    end
    JAWADEOBF_hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

    task.wait(0.1)
    JAWADEOBF_hum.Sit = false
    if JAWADEOBF_seat then JAWADEOBF_seat:Destroy() end
    if JAWADEOBF_animTrack then
        pcall(function() JAWADEOBF_animTrack:Stop() end)
    end
    JAWADEOBF_hum.AutoRotate = true
    JAWADEOBF_hum:ChangeState(Enum.HumanoidStateType.Running)

    pcall(function()
        JAWADEOBF_infoDist:SetDesc("0 studs")
    end)
end

-- Loop utama courier
task.spawn(function()
    JAWADEOBF_courierRestarting = false
    while task.wait(1) do
        if not JAWADEOBF_courierEnabled then continue end

        if JAWADEOBF_courierResetFlag then
            task.wait(2)
            JAWADEOBF_courierResetFlag = false
            JAWADEOBF_courierRestarting = false
            JAWADEOBF_courierJobId = nil
        end

        local JAWADEOBF_LP = game:GetService("Players").LocalPlayer
        local JAWADEOBF_char = JAWADEOBF_LP.Character
        if not JAWADEOBF_char
            or not JAWADEOBF_char:FindFirstChild("Humanoid")
            or JAWADEOBF_char.Humanoid.Health <= 0
            or JAWADEOBF_courierShiftLimit then
            continue
        end

        if not JAWADEOBF_courierJobId then
            -- Ambil job baru
            if not JAWADEOBF_courierRestarting then
                local JAWADEOBF_takeCF = CFrame.new(-5108, 5, -3759)
                JAWADEOBF_courierFlyTo(JAWADEOBF_takeCF)

                if not JAWADEOBF_courierEnabled or JAWADEOBF_courierShiftLimit then
                    continue
                end

                task.wait(0.5)
                pcall(function()
                    local JAWADEOBF_prompt = workspace.Livrason.Take1.Take.ProximityPrompt
                    if JAWADEOBF_prompt then
                        JAWADEOBF_prompt.HoldDuration = 0
                        fireproximityprompt(JAWADEOBF_prompt)
                    end
                end)
                JAWADEOBF_courierRestarting = true
            end

            local JAWADEOBF_waited = 0
            while JAWADEOBF_courierEnabled
                and not JAWADEOBF_courierJobId
                and not JAWADEOBF_courierShiftLimit
                and JAWADEOBF_waited < 6 do
                task.wait(0.5)
                JAWADEOBF_waited = JAWADEOBF_waited + 0.5
            end

            if JAWADEOBF_courierEnabled
                and not JAWADEOBF_courierJobId
                and not JAWADEOBF_courierShiftLimit then
                JAWADEOBF_courierRestarting = false
            end

            if JAWADEOBF_courierEnabled and not JAWADEOBF_courierJobId then
                local JAWADEOBF_idle = os.clock() - JAWADEOBF_courierLastJobTime
                if JAWADEOBF_idle > 15 and not JAWADEOBF_courierResetFlag then
                    JAWADEOBF_courierResetFlag = true
                end
                if JAWADEOBF_idle > 30 then
                    pcall(function()
                        game:GetService("ReplicatedStorage")
                            :WaitForChild("Delivery System")
                            .Settings.ServiceEvent:FireServer("RequestJobUpdate")
                    end)
                    JAWADEOBF_courierLastJobTime = os.clock()
                end
            end
        else
            -- Ambil paket di lokasi job
            local JAWADEOBF_pickupCF = nil
            pcall(function()
                local JAWADEOBF_block = workspace.Livrason.Location[JAWADEOBF_courierJobId].Block
                local JAWADEOBF_crate = JAWADEOBF_block:FindFirstChild("Dust Food Crates 56")
                    or JAWADEOBF_block:FindFirstChild("Meshes/Rac1ks_Cylinder.023")
                if JAWADEOBF_crate then
                    JAWADEOBF_pickupCF = JAWADEOBF_crate.CFrame
                end
            end)

            if JAWADEOBF_pickupCF then
                JAWADEOBF_courierFlyTo(JAWADEOBF_pickupCF)
                if not JAWADEOBF_courierEnabled then continue end

                task.wait(JAWADEOBF_courierDropDelay)

                pcall(function()
                    local JAWADEOBF_hum = JAWADEOBF_char:FindFirstChildOfClass("Humanoid")
                    if JAWADEOBF_hum then
                        local JAWADEOBF_box = JAWADEOBF_LP.Backpack:FindFirstChild("Box")
                        if JAWADEOBF_box and JAWADEOBF_box:IsA("Tool") then
                            JAWADEOBF_hum:EquipTool(JAWADEOBF_box)
                        end
                    end
                end)

                task.wait(0.5)
                pcall(function()
                    local JAWADEOBF_prompt = workspace.Livrason.Location[JAWADEOBF_courierJobId]
                        .Block.ProximityPrompt
                    if JAWADEOBF_prompt then
                        JAWADEOBF_prompt.HoldDuration = 0
                        fireproximityprompt(JAWADEOBF_prompt)
                    end
                end)

                task.wait(1)
                JAWADEOBF_courierJobId = nil
                pcall(function() JAWADEOBF_infoDest:SetDesc("-") end)
            else
                JAWADEOBF_courierJobId = nil
            end
        end
    end
end)

--=====================================================================
-- TAB: BARISTA
--=====================================================================
local JAWADEOBF_BaristaTab = JAWADEOBF_FarmingSection:Tab({
    Title = "Barista",
    Icon = "coffee",
})

local JAWADEOBF_BaristaSection = JAWADEOBF_BaristaTab:Section({
    Title = "Barista Farming",
    Opened = true,
})

-- State Barista
local JAWADEOBF_baristaEnabled = false
local JAWADEOBF_baristaWorking = false
local JAWADEOBF_baristaStartTime = nil
local JAWADEOBF_baristaJobCount = 0
local JAWADEOBF_baristaLastAction = os.clock()
local JAWADEOBF_baristaRejoinWarned = false
local JAWADEOBF_baristaRejoinDone = false
local JAWADEOBF_baristaLimitSeconds = 3 * 3600
local JAWADEOBF_baristaWebhook = ""
local JAWADEOBF_baristaWebhookOn = false
local JAWADEOBF_baristaStuckCount = 0

local JAWADEOBF_baristaToggle = JAWADEOBF_BaristaSection:Toggle({
    Title = "Autofarm Barista",
    Desc = "Auto barista job (Brew & Serve)",
    Flag = "BaristaAutoFarm",
    Callback = function(JAWADEOBF_state)
        JAWADEOBF_baristaEnabled = JAWADEOBF_state
        JAWADEOBF_baristaWorking = false

        if JAWADEOBF_state then
            JAWADEOBF_baristaStartTime = os.clock()
            JAWADEOBF_baristaLastAction = os.clock()
            JAWADEOBF_baristaRejoinWarned = false
            JAWADEOBF_baristaRejoinDone = false
        else
            JAWADEOBF_baristaStartTime = nil
            JAWADEOBF_baristaRejoinWarned = false
            JAWADEOBF_baristaRejoinDone = false
            pcall(function()
                BaristaInfoTime:SetDesc("00h 00m 00s")
                BaristaInfoCountdown:SetDesc("03h 00m 00s")
            end)
        end
    end,
    Default = false,
})

JAWADEOBF_BaristaSection:Input({
    Title = "Webhook URL",
    Desc = "Enter Discord Webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    Flag = "BaristaWebhookUrl",
    Callback = function(JAWADEOBF_v)
        JAWADEOBF_baristaWebhook = JAWADEOBF_v
    end,
})

JAWADEOBF_BaristaSection:Toggle({
    Title = "Enable Webhook",
    Desc = "Send barista notifications to Discord",
    Flag = "BaristaWebhookEnabled",
    Default = false,
    Callback = function(JAWADEOBF_v)
        JAWADEOBF_baristaWebhookOn = JAWADEOBF_v
    end,
})

local JAWADEOBF_BaristaInfo = JAWADEOBF_BaristaTab:Section({
    Title = "Information",
    Opened = true,
})

local JAWADEOBF_baristaTime = JAWADEOBF_BaristaInfo:Paragraph({
    Title = "Timestamp",
    Desc = "00h 00m 00s",
})
local JAWADEOBF_baristaRejoin = JAWADEOBF_BaristaInfo:Paragraph({
    Title = "Auto Rejoin In",
    Desc = "03h 00m 00s",
})
local JAWADEOBF_baristaJobs = JAWADEOBF_BaristaInfo:Paragraph({
    Title = "Job Done",
    Desc = "0",
})
local JAWADEOBF_baristaStuck = JAWADEOBF_BaristaInfo:Paragraph({
    Title = "Stuck Count",
    Desc = "0",
})

local JAWADEOBF_baristaWebhookSend = function(JAWADEOBF_isStuck, JAWADEOBF_isRejoin)
    if not JAWADEOBF_baristaWebhookOn or JAWADEOBF_baristaWebhook == "" then
        return
    end

    local JAWADEOBF_elapsed = JAWADEOBF_baristaStartTime
        and JAWADEOBF_formatTime(os.clock() - JAWADEOBF_baristaStartTime)
        or "00h 00m 00s"
    local JAWADEOBF_msg = { username = "DX-SR Barista" }

    if JAWADEOBF_isRejoin then
        JAWADEOBF_msg.embeds = {{
            title = "🔁 Barista Auto Rejoin (3 Hours Limit Reached)",
            description = "Farming barista telah mencapai batas aman 3 jam. Melakukan auto rejoin server untuk mereset session & anti-cheat!",
            color = 16711680,
            fields = {
                { name = "⏳ Time Elapse", value = "`" .. JAWADEOBF_elapsed .. "`", inline = true },
                { name = "☕ Total Job Done", value = "`" .. tostring(JAWADEOBF_baristaJobCount) .. "`", inline = true },
                { name = "⚠️ Stuck Count", value = "`" .. tostring(JAWADEOBF_baristaStuckCount) .. "`", inline = true },
            },
            footer = { text = "DX-SR Hub • Barista System" },
            timestamp = DateTime.now():ToIsoDate(),
        }}
    elseif JAWADEOBF_isStuck then
        JAWADEOBF_msg.embeds = {{
            title = "🔄 Barista Shift Refreshed (Server Limit Recovered)",
            description = "Server stop melayani pelanggan (limit shift). Shift telah di-refresh secara otomatis!",
            color = 16753920,
            fields = {
                { name = "⏳ Time Elapse", value = "`" .. JAWADEOBF_elapsed .. "`", inline = true },
                { name = "☕ Total Job Done", value = "`" .. tostring(JAWADEOBF_baristaJobCount) .. "`", inline = true },
                { name = "⚠️ Stuck Count", value = "`" .. tostring(JAWADEOBF_baristaStuckCount) .. "`", inline = true },
            },
            footer = { text = "DX-SR Hub • Barista System" },
            timestamp = DateTime.now():ToIsoDate(),
        }}
    else
        JAWADEOBF_msg.embeds = {{
            title = "☕ Barista Order Served",
            color = 54478,
            fields = {
                { name = "⏳ Time Elapse", value = "`" .. JAWADEOBF_elapsed .. "`", inline = true },
                { name = "☕ Total Job Done", value = "`" .. tostring(JAWADEOBF_baristaJobCount) .. "`", inline = true },
                { name = "⚠️ Stuck Count", value = "`" .. tostring(JAWADEOBF_baristaStuckCount) .. "`", inline = true },
            },
            footer = { text = "DX-SR Hub • Barista System" },
            timestamp = DateTime.now():ToIsoDate(),
        }}
    end

    JAWADEOBF_sendWebhook(JAWADEOBF_baristaWebhook, JAWADEOBF_msg)
end

local JAWADEOBF_baristaRejoinWarning = function()
    if not JAWADEOBF_baristaWebhookOn or JAWADEOBF_baristaWebhook == "" then
        return
    end

    local JAWADEOBF_elapsed = JAWADEOBF_baristaStartTime
        and JAWADEOBF_formatTime(os.clock() - JAWADEOBF_baristaStartTime)
        or "02h 59m 50s"

    JAWADEOBF_sendWebhook(JAWADEOBF_baristaWebhook, {
        content = "@everyone",
        username = "DX-SR Barista",
        embeds = {{
            title = "🚨 Barista Auto Rejoin Warning (10 Detik Tersisa)",
            description = "Waktu farming Barista telah mencapai batas aman 3 jam. Client akan melakukan **Auto Rejoin dalam 10 detik**!",
            color = 16711680,
            fields = {
                { name = "⏳ Time Elapse", value = "`" .. JAWADEOBF_elapsed .. "`", inline = true },
                { name = "🔁 Rejoin in", value = "`10 Detik`", inline = true },
                { name = "☕ Total Job Done", value = "`" .. tostring(JAWADEOBF_baristaJobCount) .. "`", inline = true },
                { name = "⚠️ Stuck Count", value = "`" .. tostring(JAWADEOBF_baristaStuckCount) .. "`", inline = true },
            },
            footer = { text = "DX-SR Hub • Barista Rejoin Alert" },
            timestamp = DateTime.now():ToIsoDate(),
        }},
    }, true)
end

-- Timer loop barista
task.spawn(function()
    while task.wait(1) do
        if JAWADEOBF_baristaEnabled and JAWADEOBF_baristaStartTime then
            local JAWADEOBF_elapsed = os.clock() - JAWADEOBF_baristaStartTime
            local JAWADEOBF_remain = math.max(0,
                JAWADEOBF_baristaLimitSeconds - JAWADEOBF_elapsed)

            pcall(function()
                JAWADEOBF_baristaTime:SetDesc(JAWADEOBF_formatTime(JAWADEOBF_elapsed))
                JAWADEOBF_baristaRejoin:SetDesc(JAWADEOBF_formatTime(JAWADEOBF_remain))
            end)

            if JAWADEOBF_remain <= 10 and not JAWADEOBF_baristaRejoinDone then
                JAWADEOBF_baristaRejoinDone = true
                pcall(function() JAWADEOBF_baristaRejoinWarning() end)
            end

            if JAWADEOBF_elapsed >= JAWADEOBF_baristaLimitSeconds
                and not JAWADEOBF_baristaRejoinWarned then
                JAWADEOBF_baristaRejoinWarned = true
                pcall(function() JAWADEOBF_baristaWebhookSend(false, true) end)
                task.wait(0.5)
                JAWADEOBF_rejoinServer(
                    "\n[DX-SR] Barista 3 Hours Limit Reached - Auto Rejoining..."
                )
            end
        else
            pcall(function()
                JAWADEOBF_baristaTime:SetDesc("00h 00m 00s")
                JAWADEOBF_baristaRejoin:SetDesc("03h 00m 00s")
            end)
        end
    end
end)

-- Konstanta tuning Barista
local JAWADEOBF_baristaTweenMax = 60
local JAWADEOBF_baristaTweenShort = 0.08
local JAWADEOBF_baristaTweenMed = 0.1
local JAWADEOBF_baristaTweenLong = 0.1

-- Teleport barista (tween smooth, bukan seat)
local JAWADEOBF_baristaTeleport = function(JAWADEOBF_targetCF)
    local JAWADEOBF_LP = game:GetService("Players").LocalPlayer
    local JAWADEOBF_char = JAWADEOBF_LP.Character
    local JAWADEOBF_hrp = JAWADEOBF_char and JAWADEOBF_char:FindFirstChild("HumanoidRootPart")
    local JAWADEOBF_hum = JAWADEOBF_char and JAWADEOBF_char:FindFirstChildOfClass("Humanoid")

    if not JAWADEOBF_hrp or not JAWADEOBF_hum then return end

    local JAWADEOBF_curPos = JAWADEOBF_hrp.Position
    local JAWADEOBF_tgtPos = JAWADEOBF_targetCF.Position
    local JAWADEOBF_dist3D = (JAWADEOBF_tgtPos - JAWADEOBF_curPos).Magnitude
    local JAWADEOBF_distFlat = (Vector3.new(JAWADEOBF_tgtPos.X, 0, JAWADEOBF_tgtPos.Z)
        - Vector3.new(JAWADEOBF_curPos.X, 0, JAWADEOBF_curPos.Z)).Magnitude

    if JAWADEOBF_dist3D < 3.5 or JAWADEOBF_distFlat < 2.5 then
        return
    end

    if JAWADEOBF_hum.Sit then
        JAWADEOBF_hum.Sit = false
        task.wait(0.02)
    end

    JAWADEOBF_hum.AutoRotate = false
    JAWADEOBF_hrp.AssemblyLinearVelocity = Vector3.zero
    JAWADEOBF_hrp.AssemblyAngularVelocity = Vector3.zero

    local JAWADEOBF_y = JAWADEOBF_tgtPos.Y
    local JAWADEOBF_startPos = Vector3.new(JAWADEOBF_hrp.Position.X, JAWADEOBF_y, JAWADEOBF_hrp.Position.Z)
    local JAWADEOBF_endPos = Vector3.new(JAWADEOBF_tgtPos.X, JAWADEOBF_y, JAWADEOBF_tgtPos.Z)

    local JAWADEOBF_seat = Instance.new("Seat")
    JAWADEOBF_seat.Name = "pria_solo_part"
    JAWADEOBF_seat.Size = Vector3.new(1, 1, 1)
    JAWADEOBF_seat.Transparency = 1
    JAWADEOBF_seat.CanCollide = false
    JAWADEOBF_seat.CFrame = CFrame.new(JAWADEOBF_startPos) * JAWADEOBF_targetCF.Rotation
    JAWADEOBF_seat.Parent = workspace

    local JAWADEOBF_weld = Instance.new("WeldConstraint")
    JAWADEOBF_weld.Part0 = JAWADEOBF_seat
    JAWADEOBF_weld.Part1 = JAWADEOBF_hrp
    JAWADEOBF_weld.Parent = JAWADEOBF_seat

    local JAWADEOBF_bv = Instance.new("BodyVelocity")
    JAWADEOBF_bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    JAWADEOBF_bv.Velocity = Vector3.zero
    JAWADEOBF_bv.Parent = JAWADEOBF_seat

    local JAWADEOBF_seatConn = game:GetService("RunService").Stepped:Connect(function()
        if JAWADEOBF_hrp then
            JAWADEOBF_hrp.AssemblyLinearVelocity = Vector3.zero
            JAWADEOBF_hrp.AssemblyAngularVelocity = Vector3.zero
        end
        if JAWADEOBF_seat and JAWADEOBF_seat.Parent then
            JAWADEOBF_seat.AssemblyLinearVelocity = Vector3.zero
            JAWADEOBF_seat.AssemblyAngularVelocity = Vector3.zero
        end
        if JAWADEOBF_hum.SeatPart ~= JAWADEOBF_seat then
            JAWADEOBF_hum.Sit = true
            JAWADEOBF_seat:Sit(JAWADEOBF_hum)
        end
    end)

    local JAWADEOBF_origCollide = {}
    local JAWADEOBF_collideConn = game:GetService("RunService").Stepped:Connect(function()
        if JAWADEOBF_char then
            for JAWADEOBF_i, JAWADEOBF_p in ipairs(JAWADEOBF_char:GetDescendants()) do
                if JAWADEOBF_p:IsA("BasePart") and JAWADEOBF_p.CanCollide then
                    JAWADEOBF_p.CanCollide = false
                    JAWADEOBF_origCollide[JAWADEOBF_p] = true
                end
            end
        end
    end)

    -- Durasi tween proporsional jarak, dibatasi
    local JAWADEOBF_duration = math.clamp(JAWADEOBF_distFlat / JAWADEOBF_baristaTweenMax, 0.02, 1)
    local JAWADEOBF_t0 = os.clock()

    while JAWADEOBF_baristaEnabled
        and JAWADEOBF_hrp
        and JAWADEOBF_char.Parent
        and (os.clock() - JAWADEOBF_t0) < JAWADEOBF_duration do

        local JAWADEOBF_alpha = math.min((os.clock() - JAWADEOBF_t0) / JAWADEOBF_duration, 1)
        local JAWADEOBF_pos = JAWADEOBF_startPos:Lerp(JAWADEOBF_endPos, JAWADEOBF_alpha)
        local JAWADEOBF_cf = CFrame.new(JAWADEOBF_pos) * JAWADEOBF_targetCF.Rotation

        JAWADEOBF_seat.CFrame = JAWADEOBF_cf
        JAWADEOBF_hrp.CFrame = JAWADEOBF_cf
        task.wait()
    end

    JAWADEOBF_seatConn:Disconnect()
    JAWADEOBF_collideConn:Disconnect()

    for JAWADEOBF_part, JAWADEOBF_ in pairs(JAWADEOBF_origCollide) do
        if typeof(JAWADEOBF_part) == "Instance"
            and JAWADEOBF_part:IsA("BasePart")
            and JAWADEOBF_part.Parent then
            JAWADEOBF_part.CanCollide = true
        end
    end

    if JAWADEOBF_bv then JAWADEOBF_bv:Destroy() end
    JAWADEOBF_hrp.AssemblyLinearVelocity = Vector3.zero
    JAWADEOBF_hrp.AssemblyAngularVelocity = Vector3.zero
    JAWADEOBF_hum.Sit = false
    if JAWADEOBF_seat then JAWADEOBF_seat:Destroy() end

    JAWADEOBF_hum.AutoRotate = true
    JAWADEOBF_hum:ChangeState(Enum.HumanoidStateType.Running)
    JAWADEOBF_hrp.CFrame = CFrame.new(JAWADEOBF_endPos) * JAWADEOBF_targetCF.Rotation
    JAWADEOBF_hrp.AssemblyLinearVelocity = Vector3.zero
    JAWADEOBF_hrp.AssemblyAngularVelocity = Vector3.zero
end

-- Branding GUI Barista (replace gradient, tampilkan "DX-SR")
task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            local JAWADEOBF_LP = game:GetService("Players").LocalPlayer
            local JAWADEOBF_PG = JAWADEOBF_LP:FindFirstChild("PlayerGui")
            local JAWADEOBF_gui = JAWADEOBF_PG and JAWADEOBF_PG:FindFirstChild("BaristaGUI")

            if JAWADEOBF_gui and JAWADEOBF_gui.Enabled then
                local JAWADEOBF_mini = JAWADEOBF_gui:FindFirstChild("MinigameFrame")
                if JAWADEOBF_mini and JAWADEOBF_mini.Visible then
                    -- Stroke warna teal
                    local JAWADEOBF_stroke = JAWADEOBF_mini:FindFirstChildWhichIsA("UIStroke")
                    if JAWADEOBF_stroke then
                        JAWADEOBF_stroke.Color = Color3.fromRGB(0, 212, 206)
                    end

                    -- Sembunyikan progress bar & tapzone
                    local JAWADEOBF_bar = JAWADEOBF_mini:FindFirstChild("ProgressBar")
                    if JAWADEOBF_bar and JAWADEOBF_bar:IsA("GuiObject") and JAWADEOBF_bar.Visible then
                        JAWADEOBF_bar.Visible = false
                    end

                    local JAWADEOBF_tap = JAWADEOBF_mini:FindFirstChild("TapZone")
                    if JAWADEOBF_tap then
                        local JAWADEOBF_kids = JAWADEOBF_tap:GetChildren()
                        if JAWADEOBF_kids[4] and JAWADEOBF_kids[4]:IsA("GuiObject") and JAWADEOBF_kids[4].Visible then
                            JAWADEOBF_kids[4].Visible = false
                        end
                        if JAWADEOBF_kids[5] and JAWADEOBF_kids[5]:IsA("GuiObject") and JAWADEOBF_kids[5].Visible then
                            JAWADEOBF_kids[5].Visible = false
                        end
                        for JAWADEOBF_i, JAWADEOBF_k in ipairs(JAWADEOBF_kids) do
                            if JAWADEOBF_k:IsA("TextLabel") and JAWADEOBF_k.Visible then
                                JAWADEOBF_k.Visible = false
                            end
                        end
                    end

                    -- BackgroundBar → branding DX-SR
                    local JAWADEOBF_bg = JAWADEOBF_mini:FindFirstChild("BackgroundBar")
                    if JAWADEOBF_bg then
                        if JAWADEOBF_bg.BackgroundTransparency ~= 1 then
                            JAWADEOBF_bg.BackgroundTransparency = 1
                        end

                        local JAWADEOBF_cursor = JAWADEOBF_bg:FindFirstChild("PlayerCursor")
                        if JAWADEOBF_cursor and JAWADEOBF_cursor:IsA("GuiObject") and JAWADEOBF_cursor.Visible then
                            JAWADEOBF_cursor.Visible = false
                        end

                        local JAWADEOBF_target = JAWADEOBF_bg:FindFirstChild("TargetZone")
                        if JAWADEOBF_target then
                            if JAWADEOBF_target.BackgroundTransparency ~= 1 then
                                JAWADEOBF_target.BackgroundTransparency = 1
                            end

                            if JAWADEOBF_baristaEnabled and JAWADEOBF_target.Size.Y.Scale < 1.5 then
                                JAWADEOBF_target.Size = UDim2.new(1, 0, 1, 0)
                            end

                            for JAWADEOBF_i, JAWADEOBF_k in ipairs(JAWADEOBF_target:GetChildren()) do
                                if JAWADEOBF_k:IsA("UIGradient") then
                                    JAWADEOBF_k:Destroy()
                                end
                            end

                            local JAWADEOBF_label = JAWADEOBF_target:FindFirstChild("DXSRLabel")
                                or JAWADEOBF_target:FindFirstChildWhichIsA("TextLabel")
                            if not JAWADEOBF_label then
                                JAWADEOBF_label = Instance.new("TextLabel")
                                JAWADEOBF_label.Name = "DXSRLabel"
                                JAWADEOBF_label.Parent = JAWADEOBF_target
                            end

                            JAWADEOBF_label.Name = "DXSRLabel"
                            JAWADEOBF_label.Text = "DX-SR"
                            JAWADEOBF_label.Font = Enum.Font.GothamBold
                            JAWADEOBF_label.Position = UDim2.new(0.5, 0, 0.1, 170)
                            JAWADEOBF_label.AnchorPoint = Vector2.new(0.5, 0.5)
                            JAWADEOBF_label.Size = UDim2.new(0, 200, 0, 50)
                            JAWADEOBF_label.TextSize = 40
                            JAWADEOBF_label.TextColor3 = Color3.fromRGB(0, 235, 255)
                            JAWADEOBF_label.TextXAlignment = Enum.TextXAlignment.Center
                            JAWADEOBF_label.TextYAlignment = Enum.TextYAlignment.Bottom
                            JAWADEOBF_label.BackgroundTransparency = 1
                            JAWADEOBF_label.Visible = true
                        end
                    end
                end

                local JAWADEOBF_mission = JAWADEOBF_PG and JAWADEOBF_PG:FindFirstChild("BaristaMissionUI")
                if JAWADEOBF_mission then
                    local JAWADEOBF_container = JAWADEOBF_mission:FindFirstChild("Container")
                    if JAWADEOBF_container then
                        local JAWADEOBF_btnFrame = JAWADEOBF_container:FindFirstChild("ButtonFrame")
                        local JAWADEOBF_btn = JAWADEOBF_btnFrame
                            and JAWADEOBF_btnFrame:FindFirstChild("TextButton")

                        if JAWADEOBF_btn then
                            for JAWADEOBF_i, JAWADEOBF_k in ipairs(JAWADEOBF_btn:GetChildren()) do
                                if JAWADEOBF_k:IsA("UIGradient") then
                                    JAWADEOBF_k:Destroy()
                                end
                            end

                            JAWADEOBF_btn.BackgroundColor3 = Color3.fromRGB(0, 212, 206)

                            local JAWADEOBF_title = JAWADEOBF_btn:FindFirstChild("TitleLabel")
                            if JAWADEOBF_title and JAWADEOBF_title.Text ~= "DX-SR COMPANY" then
                                JAWADEOBF_title.Text = "DX-SR COMPANY"
                            end
                        end

                        local JAWADEOBF_main = JAWADEOBF_container:FindFirstChild("MainFrame")
                        if JAWADEOBF_main then
                            local JAWADEOBF_grad = JAWADEOBF_main:FindFirstChild("UIGradient")
                                or JAWADEOBF_main:FindFirstChildWhichIsA("UIGradient")
                            if not JAWADEOBF_grad then
                                JAWADEOBF_grad = Instance.new("UIGradient")
                                JAWADEOBF_grad.Name = "UIGradient"
                                JAWADEOBF_grad.Parent = JAWADEOBF_main
                            end

                            if JAWADEOBF_main.BackgroundColor3 ~= Color3.fromRGB(255, 255, 255) then
                                JAWADEOBF_main.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                            end

                            JAWADEOBF_grad.Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 22, 40)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 42, 70)),
                            })
                            JAWADEOBF_grad.Rotation = 45
                        end
                    end
                end
            end
        end)
    end
end)

-- Handle shift start/end untuk Barista (klik "End Shift" atau "Start Shift")
local JAWADEOBF_baristaPromptHandler = function(JAWADEOBF_parent)
    if not JAWADEOBF_parent then return false end

    local JAWADEOBF_prompt = JAWADEOBF_parent:FindFirstChildWhichIsA("ProximityPrompt")
    if not JAWADEOBF_prompt then return false end

    -- Tunggu prompt enable
    if not JAWADEOBF_prompt.Enabled then
        local JAWADEOBF_t0 = os.clock()
        while JAWADEOBF_baristaEnabled
            and not JAWADEOBF_prompt.Enabled
            and (os.clock() - JAWADEOBF_t0) < 2.5 do
            task.wait(0.2)
            if not JAWADEOBF_prompt.Parent then
                JAWADEOBF_prompt = JAWADEOBF_parent:FindFirstChildWhichIsA("ProximityPrompt")
            end
        end
    end

    if not JAWADEOBF_prompt or not JAWADEOBF_prompt.Enabled then
        return false
    end

    JAWADEOBF_prompt.HoldDuration = 0

    -- Handle "End Shift"
    if JAWADEOBF_prompt.ActionText == "End Shift" then
        local JAWADEOBF_t0 = os.clock()
        local JAWADEOBF_lastClick = 0
        while JAWADEOBF_baristaEnabled and (os.clock() - JAWADEOBF_t0) < 6 do
            if not JAWADEOBF_prompt.Parent then
                JAWADEOBF_prompt = JAWADEOBF_parent:FindFirstChildWhichIsA("ProximityPrompt")
            end
            if not JAWADEOBF_prompt then break end
            if JAWADEOBF_prompt.ActionText == "Start Shift" then break end

            if (os.clock() - JAWADEOBF_lastClick) > 1.2 then
                JAWADEOBF_lastClick = os.clock()
                pcall(function()
                    JAWADEOBF_prompt.HoldDuration = 0
                    fireproximityprompt(JAWADEOBF_prompt)
                end)
            end
            task.wait(0.2)
        end
        task.wait(0.3)
    end

    if not JAWADEOBF_prompt or not JAWADEOBF_prompt.Parent then
        JAWADEOBF_prompt = JAWADEOBF_parent:FindFirstChildWhichIsA("ProximityPrompt")
    end

    -- Handle "Start Shift"
    if JAWADEOBF_prompt and JAWADEOBF_prompt.ActionText == "Start Shift" then
        local JAWADEOBF_t0 = os.clock()
        local JAWADEOBF_lastClick = 0
        while JAWADEOBF_baristaEnabled and (os.clock() - JAWADEOBF_t0) < 6 do
            if not JAWADEOBF_prompt.Parent then
                JAWADEOBF_prompt = JAWADEOBF_parent:FindFirstChildWhichIsA("ProximityPrompt")
            end
            if not JAWADEOBF_prompt then break end
            if JAWADEOBF_prompt.ActionText == "End Shift" then break end

            if (os.clock() - JAWADEOBF_lastClick) > 1.2 then
                JAWADEOBF_lastClick = os.clock()
                pcall(function()
                    JAWADEOBF_prompt.HoldDuration = 0
                    fireproximityprompt(JAWADEOBF_prompt)
                end)
            end
            task.wait(0.2)
        end
        task.wait(0.3)
    end

    if not JAWADEOBF_prompt or not JAWADEOBF_prompt.Parent then
        JAWADEOBF_prompt = JAWADEOBF_parent:FindFirstChildWhichIsA("ProximityPrompt")
    end

    return JAWADEOBF_prompt and JAWADEOBF_prompt.ActionText == "End Shift"
end

-- Loop utama Barista
task.spawn(function()
    while task.wait(JAWADEOBF_baristaTweenLong) do
        if not JAWADEOBF_baristaEnabled then continue end

        local JAWADEOBF_LP = game:GetService("Players").LocalPlayer
        local JAWADEOBF_char = JAWADEOBF_LP.Character
        local JAWADEOBF_hrp = JAWADEOBF_char and JAWADEOBF_char:FindFirstChild("HumanoidRootPart")
        local JAWADEOBF_hum = JAWADEOBF_char and JAWADEOBF_char:FindFirstChildOfClass("Humanoid")

        if not JAWADEOBF_char or not JAWADEOBF_hrp or not JAWADEOBF_hum
            or JAWADEOBF_hum.Health <= 0 then
            task.wait(0.5)
            continue
        end

        -- Pastikan team Barista
        if not JAWADEOBF_LP.Team or JAWADEOBF_LP.Team.Name ~= "Barista" then
            pcall(function()
                JAWADEOBF_WindUI:Notify({
                    Title = "Barista Job",
                    Content = "Masuk ke job Barista...",
                    Duration = 3,
                })
            end)

            local JAWADEOBF_oldChar = JAWADEOBF_LP.Character
            local JAWADEOBF_teamReq = game:GetService("ReplicatedStorage")
                :WaitForChild("JobEvents"):WaitForChild("TeamChangeRequest")
            JAWADEOBF_teamReq:FireServer("Barista", 11378976, 1, 0, "Detector")

            local JAWADEOBF_t0 = os.clock()
            while (not JAWADEOBF_LP.Character
                or JAWADEOBF_LP.Character == JAWADEOBF_oldChar
                or not JAWADEOBF_LP.Character:FindFirstChild("HumanoidRootPart"))
                and (os.clock() - JAWADEOBF_t0) < 5 do
                task.wait(0.2)
            end

            task.wait(1.5)
            local JAWADEOBF_newChar = JAWADEOBF_LP.Character
            local JAWADEOBF_newHrp = JAWADEOBF_newChar
                and JAWADEOBF_newChar:FindFirstChild("HumanoidRootPart")
            if JAWADEOBF_newHrp then
                JAWADEOBF_hrp = JAWADEOBF_newHrp
                JAWADEOBF_seatTeleport(CFrame.new(-4989.8, 5.5, -715))
                task.wait(0.5)
            end
            continue
        end

        -- Dapatkan referensi part Barista
        local JAWADEOBF_job = workspace:FindFirstChild("BaristaJob")
        local JAWADEOBF_interactions = JAWADEOBF_job and JAWADEOBF_job:FindFirstChild("Interactions")
        if not JAWADEOBF_interactions then continue end

        local JAWADEOBF_startPart = JAWADEOBF_interactions:FindFirstChild("StartPart")
            and JAWADEOBF_interactions.StartPart:FindFirstChild("StartPart")
        local JAWADEOBF_machinePart = JAWADEOBF_interactions:FindFirstChild("MachinePart")
            and JAWADEOBF_interactions.MachinePart:FindFirstChild("MachinePart")
        local JAWADEOBF_registerPart = JAWADEOBF_interactions:FindFirstChild("RegisterPart")
            and JAWADEOBF_interactions.RegisterPart:FindFirstChild("RegisterPart")
        local JAWADEOBF_supplyPart = JAWADEOBF_interactions:FindFirstChild("SupplyPart")
            and JAWADEOBF_interactions.SupplyPart:FindFirstChild("SupplyPart")

        local JAWADEOBF_startPrompt = JAWADEOBF_startPart
            and JAWADEOBF_startPart:FindFirstChildWhichIsA("ProximityPrompt")
        local JAWADEOBF_machinePrompt = JAWADEOBF_machinePart
            and JAWADEOBF_machinePart:FindFirstChildWhichIsA("ProximityPrompt")
        local JAWADEOBF_registerPrompt = JAWADEOBF_registerPart
            and JAWADEOBF_registerPart:FindFirstChildWhichIsA("ProximityPrompt")
        local JAWADEOBF_supplyPrompt = JAWADEOBF_supplyPart
            and JAWADEOBF_supplyPart:FindFirstChildWhichIsA("ProximityPrompt")

        local JAWADEOBF_dropPos = Vector3.new(-5000, 5.5, -760)
        local JAWADEOBF_distToDrop = (Vector3.new(JAWADEOBF_dropPos.X, 0, JAWADEOBF_dropPos.Z)
            - Vector3.new(JAWADEOBF_hrp.Position.X, 0, JAWADEOBF_hrp.Position.Z)).Magnitude

        local JAWADEOBF_startPos = Vector3.new(-4989.8, 5.5, -715)
        local JAWADEOBF_distToStart = (Vector3.new(JAWADEOBF_startPos.X, 0, JAWADEOBF_startPos.Z)
            - Vector3.new(JAWADEOBF_hrp.Position.X, 0, JAWADEOBF_hrp.Position.Z)).Magnitude

        local JAWADEOBF_canStart = JAWADEOBF_startPrompt
            and JAWADEOBF_startPrompt.Enabled
            and JAWADEOBF_startPrompt.ActionText == "Start Shift"

        -- Kalau belum working atau jauh dari start atau bisa start shift
        if not JAWADEOBF_baristaWorking
            or JAWADEOBF_distToDrop > 80
            or JAWADEOBF_canStart then

            if JAWADEOBF_distToDrop > 80 then
                JAWADEOBF_seatTeleport(CFrame.new(JAWADEOBF_startPos))
                task.wait(0.5)
            elseif JAWADEOBF_distToStart > 6 then
                JAWADEOBF_baristaTeleport(CFrame.new(JAWADEOBF_startPos))
                task.wait(0.3)
            end

            if JAWADEOBF_startPart then
                JAWADEOBF_startPrompt = JAWADEOBF_startPart:FindFirstChildWhichIsA("ProximityPrompt")
            end

            local JAWADEOBF_ok = JAWADEOBF_baristaPromptHandler(JAWADEOBF_startPart)
            if not JAWADEOBF_ok then
                task.wait(0.5)
                continue
            end

            JAWADEOBF_baristaWorking = true
            JAWADEOBF_baristaLastAction = os.clock()
            JAWADEOBF_baristaTeleport(CFrame.new(-5000.2, 5.6, -792))
            task.wait(JAWADEOBF_baristaTweenShort)
            continue
        end

        -- Supply ambil bahan
        if JAWADEOBF_supplyPrompt and JAWADEOBF_supplyPrompt.Enabled then
            JAWADEOBF_baristaLastAction = os.clock()
            JAWADEOBF_seatTeleport(CFrame.new(-5116.8, 5.8, -670.9))
            task.wait(0.4)

            if JAWADEOBF_supplyPrompt and JAWADEOBF_supplyPrompt.Enabled then
                pcall(function()
                    JAWADEOBF_supplyPrompt.HoldDuration = 0
                    fireproximityprompt(JAWADEOBF_supplyPrompt)
                end)
            end

            task.wait(0.6)
            JAWADEOBF_seatTeleport(CFrame.new(-5000.2, 5.6, -792))
            task.wait(0.4)
            continue
        end

        -- Register / serve order
        if JAWADEOBF_registerPrompt and JAWADEOBF_registerPrompt.Enabled then
            JAWADEOBF_baristaLastAction = os.clock()
            JAWADEOBF_baristaTeleport(CFrame.new(-4997.1, 5.6, -755))
            task.wait(JAWADEOBF_baristaTweenShort)

            if JAWADEOBF_registerPrompt and JAWADEOBF_registerPrompt.Enabled then
                pcall(function()
                    JAWADEOBF_registerPrompt.HoldDuration = 0
                    fireproximityprompt(JAWADEOBF_registerPrompt)
                end)
            end

            task.wait(JAWADEOBF_baristaTweenMed)

            JAWADEOBF_baristaJobCount = JAWADEOBF_baristaJobCount + 1
            pcall(function()
                JAWADEOBF_baristaJobs:SetDesc(tostring(JAWADEOBF_baristaJobCount))
            end)
            JAWADEOBF_baristaWebhookSend(false)

            JAWADEOBF_baristaTeleport(CFrame.new(-5000.2, 5.6, -792))
            task.wait(JAWADEOBF_baristaTweenShort)
            continue
        end

        -- Machine / brew
        if JAWADEOBF_machinePrompt and JAWADEOBF_machinePrompt.Enabled then
            JAWADEOBF_baristaLastAction = os.clock()

            local JAWADEOBF_brewPos = Vector3.new(-5000.2, 5.6, -792)
            local JAWADEOBF_dist = (JAWADEOBF_brewPos - JAWADEOBF_hrp.Position).Magnitude
            if JAWADEOBF_dist > 3 then
                JAWADEOBF_baristaTeleport(CFrame.new(JAWADEOBF_brewPos))
                task.wait(JAWADEOBF_baristaTweenShort)
            end

            if JAWADEOBF_machinePrompt and JAWADEOBF_machinePrompt.Enabled then
                pcall(function()
                    JAWADEOBF_machinePrompt.HoldDuration = 0
                    fireproximityprompt(JAWADEOBF_machinePrompt)
                end)
            end

            -- Tunggu sampai register prompt muncul / minigame selesai
            local JAWADEOBF_t0 = os.clock()
            while JAWADEOBF_baristaEnabled and (os.clock() - JAWADEOBF_t0) < 6 do
                JAWADEOBF_baristaLastAction = os.clock()
                if JAWADEOBF_registerPrompt and JAWADEOBF_registerPrompt.Enabled then
                    break
                end

                local JAWADEOBF_gui = JAWADEOBF_LP.PlayerGui:FindFirstChild("BaristaGUI")
                local JAWADEOBF_mini = JAWADEOBF_gui and JAWADEOBF_gui:FindFirstChild("MinigameFrame")

                if not (JAWADEOBF_mini and JAWADEOBF_mini.Visible)
                    and (os.clock() - JAWADEOBF_t0) > 1 then
                    break
                end
                task.wait(0.08)
            end
            continue
        end

        -- Idle / tidak ada aksi
        local JAWADEOBF_brewPos = CFrame.new(-5000.2, 5.6, -792)
        local JAWADEOBF_distIdle = (Vector3.new(JAWADEOBF_brewPos.Position.X, 0, JAWADEOBF_brewPos.Position.Z)
            - Vector3.new(JAWADEOBF_hrp.Position.X, 0, JAWADEOBF_hrp.Position.Z)).Magnitude

        if JAWADEOBF_distIdle > 3.5 then
            JAWADEOBF_baristaTeleport(JAWADEOBF_brewPos)
        end

        -- Deteksi stuck / limit shift
        local JAWADEOBF_idleTime = os.clock() - JAWADEOBF_baristaLastAction
        if JAWADEOBF_idleTime > 18 then
            JAWADEOBF_baristaLastAction = os.clock()
            JAWADEOBF_baristaStuckCount = JAWADEOBF_baristaStuckCount + 1
            pcall(function()
                JAWADEOBF_baristaStuck:SetDesc(tostring(JAWADEOBF_baristaStuckCount))
            end)
            JAWADEOBF_baristaWebhookSend(true)

            pcall(function()
                JAWADEOBF_WindUI:Notify({
                    Title = "Barista Limit Recovery",
                    Content = "Server stop melayani pelanggan. Me-refresh shift barista...",
                    Duration = 3,
                })
            end)

            JAWADEOBF_baristaTeleport(CFrame.new(-4989.8, 5.5, -715))
            task.wait(0.3)
            JAWADEOBF_baristaWorking = false

            if JAWADEOBF_startPart then
                JAWADEOBF_startPrompt = JAWADEOBF_startPart:FindFirstChildWhichIsA("ProximityPrompt")
            end

            local JAWADEOBF_ok = JAWADEOBF_baristaPromptHandler(JAWADEOBF_startPart)
            if not JAWADEOBF_ok then
                task.wait(0.5)
                continue
            end

            JAWADEOBF_baristaWorking = true
            JAWADEOBF_baristaLastAction = os.clock()
            JAWADEOBF_baristaTeleport(CFrame.new(-5000.2, 5.6, -792))
            task.wait(JAWADEOBF_baristaTweenShort)
            continue
        end
    end
end)

-- Auto-resume Barista setelah rejoin
if getgenv().AUTO_RESUME_BARISTA then
    task.spawn(function()
        JAWADEOBF_bypassMainMenu()

        local JAWADEOBF_Players = game:GetService("Players")
        local JAWADEOBF_LP = JAWADEOBF_Players.LocalPlayer
        while not JAWADEOBF_LP do
            JAWADEOBF_Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
            JAWADEOBF_LP = JAWADEOBF_Players.LocalPlayer
        end

        local JAWADEOBF_char = JAWADEOBF_LP.Character or JAWADEOBF_LP.CharacterAdded:Wait()
        JAWADEOBF_char:WaitForChild("HumanoidRootPart", 15)
        task.wait(3)

        local JAWADEOBF_teamReq = game:GetService("ReplicatedStorage")
            :WaitForChild("JobEvents"):WaitForChild("TeamChangeRequest")
        JAWADEOBF_teamReq:FireServer("Barista", 11378976, 1, 0, "Detector")
        task.wait(1)

        local JAWADEOBF_c2 = JAWADEOBF_LP.Character or JAWADEOBF_LP.CharacterAdded:Wait()
        JAWADEOBF_c2:WaitForChild("HumanoidRootPart", 10)
        task.wait(0.2)

        JAWADEOBF_seatTeleport(CFrame.new(-4989.8, 5.5, -715))
        task.wait(0.5)

        local JAWADEOBF_job = workspace:FindFirstChild("BaristaJob")
        local JAWADEOBF_inter = JAWADEOBF_job and JAWADEOBF_job:FindFirstChild("Interactions")
        local JAWADEOBF_sp = JAWADEOBF_inter
            and JAWADEOBF_inter:FindFirstChild("StartPart")
            and JAWADEOBF_inter.StartPart:FindFirstChild("StartPart")
        if JAWADEOBF_sp then
            JAWADEOBF_baristaPromptHandler(JAWADEOBF_sp)
        end

        if JAWADEOBF_baristaToggle then
            pcall(function() JAWADEOBF_baristaToggle:SetValue(true) end)
            pcall(function() JAWADEOBF_baristaToggle:Set(true) end)
        else
            JAWADEOBF_baristaEnabled = true
            JAWADEOBF_baristaStartTime = os.clock()
            JAWADEOBF_baristaLastAction = os.clock()
        end

        getgenv().AUTO_RESUME_BARISTA = false
    end)
end

-- Auto-resume Courier setelah rejoin
if getgenv().AUTO_RESUME_COURIER then
    task.spawn(function()
        JAWADEOBF_bypassMainMenu()

        local JAWADEOBF_Players = game:GetService("Players")
        local JAWADEOBF_LP = JAWADEOBF_Players.LocalPlayer
        while not JAWADEOBF_LP do
            JAWADEOBF_Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
            JAWADEOBF_LP = JAWADEOBF_Players.LocalPlayer
        end

        local JAWADEOBF_char = JAWADEOBF_LP.Character or JAWADEOBF_LP.CharacterAdded:Wait()
        JAWADEOBF_char:WaitForChild("HumanoidRootPart", 15)
        task.wait(3)

        local JAWADEOBF_teamReq = game:GetService("ReplicatedStorage")
            :WaitForChild("JobEvents"):WaitForChild("TeamChangeRequest")
        JAWADEOBF_teamReq:FireServer("Courier", 11378976, 0, 0, "Detector")
        task.wait(1)

        local JAWADEOBF_c2 = JAWADEOBF_LP.Character or JAWADEOBF_LP.CharacterAdded:Wait()
        JAWADEOBF_c2:WaitForChild("HumanoidRootPart", 10)
        task.wait(0.2)

        JAWADEOBF_seatTeleport(CFrame.new(-5108, 5, -3759))
        task.wait(0.5)

        if JAWADEOBF_courierToggle then
            pcall(function() JAWADEOBF_courierToggle:SetValue(true) end)
            pcall(function() JAWADEOBF_courierToggle:Set(true) end)
        else
            JAWADEOBF_courierEnabled = true
            JAWADEOBF_courierResetFlag = true
            JAWADEOBF_courierStartTime = os.clock()
        end

        getgenv().AUTO_RESUME_COURIER = false
    end)
end

--=====================================================================
-- TAB: TELEPORT
--=====================================================================
local JAWADEOBF_TeleportTab = JAWADEOBF_Window:Tab({
    Title = "Teleport",
    Icon = "map-pin",
})

-- Teleport umum (sama seperti seatTeleport Ridego)
local JAWADEOBF_genericTeleport = function(JAWADEOBF_cf)
    local JAWADEOBF_LP = game:GetService("Players").LocalPlayer
    local JAWADEOBF_char = JAWADEOBF_LP.Character
    local JAWADEOBF_hrp = JAWADEOBF_char and JAWADEOBF_char:FindFirstChild("HumanoidRootPart")
    local JAWADEOBF_hum = JAWADEOBF_char and JAWADEOBF_char:FindFirstChildOfClass("Humanoid")
    local JAWADEOBF_anim = JAWADEOBF_char and JAWADEOBF_char:FindFirstChild("Animate")

    if not JAWADEOBF_hrp or not JAWADEOBF_hum then return end
    if JAWADEOBF_anim then JAWADEOBF_anim.Disabled = true end

    local JAWADEOBF_seat = Instance.new("Seat")
    JAWADEOBF_seat.Size = Vector3.new(2, 0.2, 2)
    JAWADEOBF_seat.Transparency = 1
    JAWADEOBF_seat.CanCollide = false
    JAWADEOBF_seat.Anchored = true
    JAWADEOBF_seat.CFrame = JAWADEOBF_hrp.CFrame
    JAWADEOBF_seat.Parent = workspace

    JAWADEOBF_hum.Sit = true
    JAWADEOBF_seat:Sit(JAWADEOBF_hum)

    local JAWADEOBF_bv = Instance.new("BodyVelocity")
    JAWADEOBF_bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    JAWADEOBF_bv.Velocity = Vector3.new(0, 0, 0)
    JAWADEOBF_bv.Parent = JAWADEOBF_hrp

    task.wait(0.5)
    JAWADEOBF_seat.Anchored = false

    local JAWADEOBF_target = JAWADEOBF_cf * CFrame.new(0, 0.01, 0)
    local JAWADEOBF_mid = JAWADEOBF_hrp.CFrame:Lerp(JAWADEOBF_target, 0.5)

    JAWADEOBF_seat.CFrame = JAWADEOBF_mid
    JAWADEOBF_hrp.CFrame = JAWADEOBF_mid
    task.wait(0.1)

    JAWADEOBF_seat.CFrame = JAWADEOBF_target
    JAWADEOBF_hrp.CFrame = JAWADEOBF_target
    JAWADEOBF_seat.Anchored = true

    task.wait(1.6)
    if JAWADEOBF_bv then JAWADEOBF_bv:Destroy() end

    JAWADEOBF_hum.Sit = false
    if JAWADEOBF_anim then JAWADEOBF_anim.Disabled = false end
    task.wait(0.3)
    if JAWADEOBF_seat then JAWADEOBF_seat:Destroy() end

    JAWADEOBF_hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    workspace.CurrentCamera.CameraSubject = JAWADEOBF_hum
end

-- Section Dealership
local JAWADEOBF_DealershipSection = JAWADEOBF_TeleportTab:Section({
    Title = "Dealership",
})

local JAWADEOBF_dealerPositions = {
    ["Drag dealer"] = Vector3.new(-5018, 3, -5358),
    ["Yahamax dealer"] = Vector3.new(717, 3, -738),
    ["Premium dealer"] = Vector3.new(-4817, 4, -764),
    ["Kawzaki dealer"] = Vector3.new(-9500, 16, 956),
    ["Piazzo dealer"] = Vector3.new(-5752, 6, -3902),
    ["Hando dealer"] = Vector3.new(-5944, 5, -3903),
    ["Truck dealer"] = Vector3.new(-10252, 5, 1309),
    ["Bus dealer"] = Vector3.new(-16443, 105, 4632),
    ["Car dealer"] = Vector3.new(-6606, 4, -4206),
}

local JAWADEOBF_dealerList = {}
for JAWADEOBF_k, JAWADEOBF_ in pairs(JAWADEOBF_dealerPositions) do
    table.insert(JAWADEOBF_dealerList, JAWADEOBF_k)
end

local JAWADEOBF_selectedDealer = JAWADEOBF_dealerList[1]

JAWADEOBF_DealershipSection:Dropdown({
    Title = "Select dealership",
    Desc = "Choose a dealership to teleport to",
    Multi = false,
    Flag = "TeleportDealership",
    Value = JAWADEOBF_selectedDealer,
    Values = JAWADEOBF_dealerList,
    Callback = function(JAWADEOBF_v) JAWADEOBF_selectedDealer = JAWADEOBF_v end,
})

JAWADEOBF_DealershipSection:Button({
    Title = "Teleport now",
    Desc = "Bypass teleport to the dealership",
    Callback = function()
        if JAWADEOBF_dealerPositions[JAWADEOBF_selectedDealer] then
            JAWADEOBF_genericTeleport(
                CFrame.new(JAWADEOBF_dealerPositions[JAWADEOBF_selectedDealer])
            )
        end
    end,
})

-- Section Other Teleport
local JAWADEOBF_OtherTpSection = JAWADEOBF_TeleportTab:Section({
    Title = "Other teleport",
})

local JAWADEOBF_otherPositions = {
    ["Drag race"] = Vector3.new(-8903, 2, 742),
    ["Modification"] = Vector3.new(-8652, 6, 148),
    ["helmet shop"] = Vector3.new(-718, 5, -487),
    ["Town square"] = Vector3.new(-267, 6, -4244),
    ["Feva hotel"] = Vector3.new(-2721, 7, -4174),
    ["Clothing shop"] = Vector3.new(-4778, 5, -3895),
    ["Ngopi cafe"] = Vector3.new(-8294, 2, -3687),
    ["Starbook coffe"] = Vector3.new(-10262, 4, -4153),
}

local JAWADEOBF_otherList = {}
for JAWADEOBF_k, JAWADEOBF_ in pairs(JAWADEOBF_otherPositions) do
    table.insert(JAWADEOBF_otherList, JAWADEOBF_k)
end

local JAWADEOBF_selectedOther = JAWADEOBF_otherList[1]

JAWADEOBF_OtherTpSection:Dropdown({
    Title = "Select place",
    Desc = "Choose another place to teleport to",
    Multi = false,
    Flag = "TeleportOtherLocation",
    Value = JAWADEOBF_selectedOther,
    Values = JAWADEOBF_otherList,
    Callback = function(JAWADEOBF_v) JAWADEOBF_selectedOther = JAWADEOBF_v end,
})

JAWADEOBF_OtherTpSection:Button({
    Title = "Teleport now",
    Desc = "teleport to the selected place",
    Callback = function()
        if JAWADEOBF_otherPositions[JAWADEOBF_selectedOther] then
            JAWADEOBF_genericTeleport(
                CFrame.new(JAWADEOBF_otherPositions[JAWADEOBF_selectedOther])
            )
        end
    end,
})

JAWADEOBF_OtherTpSection:Button({
    Title = "Teleport to anomaly",
    Desc = "Teleport and interact with anomaly",
    Callback = function()
        task.spawn(function()
            JAWADEOBF_genericTeleport(CFrame.new(7828, 3, -470))
            task.wait(2)
            pcall(function()
                local JAWADEOBF_prompt = workspace["CHBZ3125E96vFxITe"]
                    ["CHBZ3125E96vFxITe_"]["Prompt"]["ProximityPrompt"]
                if JAWADEOBF_prompt then
                    JAWADEOBF_prompt.HoldDuration = 0
                    fireproximityprompt(JAWADEOBF_prompt)
                end
            end)
        end)
    end,
})

--=====================================================================
-- TAB: MISC (Avatar & Name Spoofer)
--=====================================================================
local JAWADEOBF_MiscTab = JAWADEOBF_Window:Tab({
    Title = "Misc",
    Icon = "box",
})

local JAWADEOBF_AvatarSection = JAWADEOBF_MiscTab:Section({
    Title = "Avatar & Name Spoofer",
})

local JAWADEOBF_avatarBackup = nil
local JAWADEOBF_spoofName = ""
local JAWADEOBF_spoofNameOn = false
local JAWADEOBF_spoofRank = ""
local JAWADEOBF_spoofRankOn = false
local JAWADEOBF_rankGradient = nil
local JAWADEOBF_prefixText = ""
local JAWADEOBF_prefixColor = Color3.fromRGB(24, 24, 24)
local JAWADEOBF_nameShadowColor = Color3.fromRGB(0, 0, 0)

-- Parser ColorSequence
local JAWADEOBF_parseColorSequence = function(JAWADEOBF_str)
    local JAWADEOBF_nums = {}
    for JAWADEOBF_tok in string.gmatch(JAWADEOBF_str, "%S+") do
        table.insert(JAWADEOBF_nums, tonumber(JAWADEOBF_tok))
    end

    local JAWADEOBF_keypoints = {}
    for JAWADEOBF_i = 1, #JAWADEOBF_nums, 5 do
        local JAWADEOBF_t = JAWADEOBF_nums[JAWADEOBF_i]
        local JAWADEOBF_r = JAWADEOBF_nums[JAWADEOBF_i + 1]
        local JAWADEOBF_g = JAWADEOBF_nums[JAWADEOBF_i + 2]
        local JAWADEOBF_b = JAWADEOBF_nums[JAWADEOBF_i + 3]

        if JAWADEOBF_t and JAWADEOBF_r and JAWADEOBF_g and JAWADEOBF_b then
            table.insert(JAWADEOBF_keypoints, ColorSequenceKeypoint.new(
                JAWADEOBF_t, Color3.new(JAWADEOBF_r, JAWADEOBF_g, JAWADEOBF_b)
            ))
        end
    end

    if #JAWADEOBF_keypoints > 0 then
        if JAWADEOBF_keypoints[1].Time > 0 then
            table.insert(JAWADEOBF_keypoints, 1,
                ColorSequenceKeypoint.new(0, JAWADEOBF_keypoints[1].Value))
        end
        if JAWADEOBF_keypoints[#JAWADEOBF_keypoints].Time < 1 then
            table.insert(JAWADEOBF_keypoints,
                ColorSequenceKeypoint.new(1, JAWADEOBF_keypoints[#JAWADEOBF_keypoints].Value))
        end
        return ColorSequence.new(JAWADEOBF_keypoints)
    end
    return nil
end

-- Spoof avatar via UserId
local JAWADEOBF_applyAvatarSpoof = function(JAWADEOBF_userId)
    local JAWADEOBF_LP = game:GetService("Players").LocalPlayer
    local JAWADEOBF_char = JAWADEOBF_LP.Character
    if not JAWADEOBF_char then return end

    local JAWADEOBF_hum = JAWADEOBF_char:FindFirstChildOfClass("Humanoid")
    if not JAWADEOBF_hum then return end

    local JAWADEOBF_r15Parts = {
        UpperTorso = Enum.BodyPartR15.UpperTorso,
        LowerTorso = Enum.BodyPartR15.LowerTorso,
        LeftUpperArm = Enum.BodyPartR15.LeftUpperArm,
        LeftLowerArm = Enum.BodyPartR15.LeftLowerArm,
        LeftHand = Enum.BodyPartR15.LeftHand,
        RightUpperArm = Enum.BodyPartR15.RightUpperArm,
        RightLowerArm = Enum.BodyPartR15.RightLowerArm,
        RightHand = Enum.BodyPartR15.RightHand,
        LeftUpperLeg = Enum.BodyPartR15.LeftUpperLeg,
        LeftLowerLeg = Enum.BodyPartR15.LeftLowerLeg,
        LeftFoot = Enum.BodyPartR15.LeftFoot,
        RightUpperLeg = Enum.BodyPartR15.RightUpperLeg,
        RightLowerLeg = Enum.BodyPartR15.RightLowerLeg,
        RightFoot = Enum.BodyPartR15.RightFoot,
    }

    -- Backup avatar pertama kali
    if not JAWADEOBF_avatarBackup then
        JAWADEOBF_avatarBackup = {
            body_parts = {}, accessories = {}, clothing = {},
            face = nil, head_mesh = nil, body_colors = nil, scales = {},
        }

        for JAWADEOBF_name, JAWADEOBF_ in pairs(JAWADEOBF_r15Parts) do
            local JAWADEOBF_part = JAWADEOBF_char:FindFirstChild(JAWADEOBF_name)
            if JAWADEOBF_part and JAWADEOBF_part:IsA("BasePart") then
                JAWADEOBF_avatarBackup.body_parts[JAWADEOBF_name] = JAWADEOBF_part:Clone()
            end
        end

        local JAWADEOBF_head = JAWADEOBF_char:FindFirstChild("Head")
        if JAWADEOBF_head and JAWADEOBF_head:IsA("BasePart") then
            JAWADEOBF_avatarBackup.body_parts["Head"] = JAWADEOBF_head:Clone()
        end

        for JAWADEOBF_i, JAWADEOBF_ch in ipairs(JAWADEOBF_char:GetChildren()) do
            if JAWADEOBF_ch:IsA("Accessory") then
                table.insert(JAWADEOBF_avatarBackup.accessories, JAWADEOBF_ch:Clone())
            elseif JAWADEOBF_ch:IsA("Shirt")
                or JAWADEOBF_ch:IsA("Pants")
                or JAWADEOBF_ch:IsA("ShirtGraphic") then
                table.insert(JAWADEOBF_avatarBackup.clothing, JAWADEOBF_ch:Clone())
            elseif JAWADEOBF_ch:IsA("BodyColors") then
                JAWADEOBF_avatarBackup.body_colors = JAWADEOBF_ch:Clone()
            end
        end

        if JAWADEOBF_head then
            for JAWADEOBF_i, JAWADEOBF_k in ipairs(JAWADEOBF_head:GetChildren()) do
                if JAWADEOBF_k:IsA("Decal")
                    and (JAWADEOBF_k.Name == "face" or JAWADEOBF_k.Name == "Face") then
                    JAWADEOBF_avatarBackup.face = JAWADEOBF_k:Clone()
                    break
                end
            end

            local JAWADEOBF_mesh = JAWADEOBF_head:FindFirstChildOfClass("SpecialMesh")
            if JAWADEOBF_mesh then
                JAWADEOBF_avatarBackup.head_mesh = {
                    MeshId = JAWADEOBF_mesh.MeshId,
                    TextureId = JAWADEOBF_mesh.TextureId,
                    Scale = JAWADEOBF_mesh.Scale,
                    Offset = JAWADEOBF_mesh.Offset,
                }
            end
            JAWADEOBF_avatarBackup.head_size = JAWADEOBF_head.Size
            JAWADEOBF_avatarBackup.head_color = JAWADEOBF_head.Color
        end

        for JAWADEOBF_name, JAWADEOBF_ in pairs({
            HeadScale = true, BodyDepthScale = true, BodyWidthScale = true,
            BodyHeightScale = true, BodyTypeScale = true, BodyProportionScale = true,
        }) do
            local JAWADEOBF_scale = JAWADEOBF_hum:FindFirstChild(JAWADEOBF_name)
            if JAWADEOBF_scale and JAWADEOBF_scale:IsA("NumberValue") then
                JAWADEOBF_avatarBackup.scales[JAWADEOBF_name] = JAWADEOBF_scale.Value
            end
        end
    end

    -- Load avatar target
    local JAWADEOBF_ok, JAWADEOBF_model = pcall(function()
        return game:GetService("Players"):CreateHumanoidModelFromUserIdAsync(JAWADEOBF_userId)
    end)

    if not JAWADEOBF_ok or not JAWADEOBF_model then
        JAWADEOBF_WindUI:Notify({
            Title = "Avatar Changer",
            Content = "Failed to load avatar",
            Duration = 3,
        })
        return
    end

    local JAWADEOBF_targetHum = JAWADEOBF_model:FindFirstChildOfClass("Humanoid")
    if not JAWADEOBF_targetHum then
        JAWADEOBF_model:Destroy()
        return
    end

    -- Replace body parts
    for JAWADEOBF_name, JAWADEOBF_enum in pairs(JAWADEOBF_r15Parts) do
        local JAWADEOBF_part = JAWADEOBF_model:FindFirstChild(JAWADEOBF_name)
        if JAWADEOBF_part and JAWADEOBF_part:IsA("BasePart") then
            pcall(function()
                JAWADEOBF_hum:ReplaceBodyPartR15(JAWADEOBF_enum, JAWADEOBF_part:Clone())
            end)
        end
    end

    -- Hapus accessories/clothing lama
    for JAWADEOBF_i, JAWADEOBF_ch in ipairs(JAWADEOBF_char:GetChildren()) do
        if JAWADEOBF_ch:IsA("Accessory")
            or JAWADEOBF_ch:IsA("Shirt")
            or JAWADEOBF_ch:IsA("Pants")
            or JAWADEOBF_ch:IsA("ShirtGraphic")
            or JAWADEOBF_ch:IsA("CharacterMesh") then
            JAWADEOBF_ch:Destroy()
        end
    end

    -- Face & head mesh
    local JAWADEOBF_head = JAWADEOBF_char:FindFirstChild("Head")
    local JAWADEOBF_targetHead = JAWADEOBF_model:FindFirstChild("Head")

    if JAWADEOBF_head then
        for JAWADEOBF_i, JAWADEOBF_k in ipairs(JAWADEOBF_head:GetChildren()) do
            if JAWADEOBF_k:IsA("Decal")
                and (JAWADEOBF_k.Name == "face" or JAWADEOBF_k.Name == "Face") then
                JAWADEOBF_k:Destroy()
            end
        end
    end

    if JAWADEOBF_head and JAWADEOBF_targetHead then
        for JAWADEOBF_i, JAWADEOBF_k in ipairs(JAWADEOBF_targetHead:GetChildren()) do
            if JAWADEOBF_k:IsA("Decal")
                and (JAWADEOBF_k.Name == "face" or JAWADEOBF_k.Name == "Face") then
                JAWADEOBF_k:Clone().Parent = JAWADEOBF_head
            end
        end

        local JAWADEOBF_tMesh = JAWADEOBF_targetHead:FindFirstChildOfClass("SpecialMesh")
        local JAWADEOBF_cMesh = JAWADEOBF_head:FindFirstChildOfClass("SpecialMesh")

        if JAWADEOBF_tMesh and JAWADEOBF_cMesh then
            JAWADEOBF_cMesh.MeshId = JAWADEOBF_tMesh.MeshId
            JAWADEOBF_cMesh.TextureId = JAWADEOBF_tMesh.TextureId
            JAWADEOBF_cMesh.Scale = JAWADEOBF_tMesh.Scale
            JAWADEOBF_cMesh.Offset = JAWADEOBF_tMesh.Offset
        elseif JAWADEOBF_tMesh and not JAWADEOBF_cMesh then
            JAWADEOBF_tMesh:Clone().Parent = JAWADEOBF_head
        end

        JAWADEOBF_head.Size = JAWADEOBF_targetHead.Size
        JAWADEOBF_head.Color = JAWADEOBF_targetHead.Color
    end

    -- Clothing & body colors
    for JAWADEOBF_i, JAWADEOBF_k in ipairs(JAWADEOBF_model:GetChildren()) do
        if JAWADEOBF_k:IsA("Shirt")
            or JAWADEOBF_k:IsA("Pants")
            or JAWADEOBF_k:IsA("ShirtGraphic") then
            JAWADEOBF_k:Clone().Parent = JAWADEOBF_char
        elseif JAWADEOBF_k:IsA("BodyColors") then
            local JAWADEOBF_bc = JAWADEOBF_char:FindFirstChildOfClass("BodyColors")
            if JAWADEOBF_bc then
                JAWADEOBF_bc.HeadColor3 = JAWADEOBF_k.HeadColor3
                JAWADEOBF_bc.TorsoColor3 = JAWADEOBF_k.TorsoColor3
                JAWADEOBF_bc.LeftArmColor3 = JAWADEOBF_k.LeftArmColor3
                JAWADEOBF_bc.RightArmColor3 = JAWADEOBF_k.RightArmColor3
                JAWADEOBF_bc.LeftLegColor3 = JAWADEOBF_k.LeftLegColor3
                JAWADEOBF_bc.RightLegColor3 = JAWADEOBF_k.RightLegColor3
            end
        end
    end

    -- Accessories dengan weld manual
    for JAWADEOBF_i, JAWADEOBF_acc in ipairs(JAWADEOBF_model:GetChildren()) do
        if JAWADEOBF_acc:IsA("Accessory") then
            local JAWADEOBF_clone = JAWADEOBF_acc:Clone()
            local JAWADEOBF_handle = JAWADEOBF_clone:FindFirstChild("Handle")
            if not JAWADEOBF_handle then continue end

            local JAWADEOBF_attach = JAWADEOBF_handle:FindFirstChildOfClass("Attachment")

            for JAWADEOBF_j, JAWADEOBF_k in ipairs(JAWADEOBF_handle:GetChildren()) do
                if JAWADEOBF_k:IsA("Weld")
                    or JAWADEOBF_k:IsA("Motor6D")
                    or JAWADEOBF_k:IsA("WeldConstraint") then
                    JAWADEOBF_k:Destroy()
                end
            end

            local JAWADEOBF_targetPart, JAWADEOBF_targetAttach = nil, nil
            if JAWADEOBF_attach then
                for JAWADEOBF_j, JAWADEOBF_part in ipairs(JAWADEOBF_char:GetChildren()) do
                    if JAWADEOBF_part:IsA("BasePart") then
                        for JAWADEOBF_jj, JAWADEOBF_a in ipairs(JAWADEOBF_part:GetChildren()) do
                            if JAWADEOBF_a:IsA("Attachment")
                                and JAWADEOBF_a.Name == JAWADEOBF_attach.Name then
                                JAWADEOBF_targetPart = JAWADEOBF_part
                                JAWADEOBF_targetAttach = JAWADEOBF_a
                                break
                            end
                        end
                    end
                    if JAWADEOBF_targetPart then break end
                end
            end

            if not JAWADEOBF_targetPart then
                JAWADEOBF_targetPart = JAWADEOBF_char:FindFirstChild("Head")
                    or JAWADEOBF_char:FindFirstChild("UpperTorso")
                    or JAWADEOBF_char:FindFirstChild("HumanoidRootPart")
                if not JAWADEOBF_targetPart then continue end
            end

            JAWADEOBF_clone.Parent = JAWADEOBF_char

            local JAWADEOBF_weld = Instance.new("Weld")
            JAWADEOBF_weld.Part0 = JAWADEOBF_targetPart
            JAWADEOBF_weld.Part1 = JAWADEOBF_handle

            if JAWADEOBF_targetAttach and JAWADEOBF_attach then
                JAWADEOBF_weld.C0 = JAWADEOBF_targetAttach.CFrame
                JAWADEOBF_weld.C1 = JAWADEOBF_attach.CFrame
            else
                JAWADEOBF_weld.C0 = CFrame.new(0, JAWADEOBF_targetPart.Size.Y / 2, 0)
                JAWADEOBF_weld.C1 = JAWADEOBF_attach and JAWADEOBF_attach.CFrame or CFrame.new()
            end
            JAWADEOBF_weld.Parent = JAWADEOBF_handle
        end
    end

    -- Scales
    local JAWADEOBF_targetDesc = JAWADEOBF_targetHum:FindFirstChildOfClass("HumanoidDescription")
    if JAWADEOBF_targetDesc then
        for JAWADEOBF_i, JAWADEOBF_name in ipairs({
            "HeadScale", "BodyDepthScale", "BodyWidthScale",
            "BodyHeightScale", "BodyTypeScale", "BodyProportionScale",
        }) do
            local JAWADEOBF_curScale = JAWADEOBF_hum:FindFirstChild(JAWADEOBF_name)
            local JAWADEOBF_tScale = JAWADEOBF_model:FindFirstChild("Humanoid")
                and JAWADEOBF_model.Humanoid:FindFirstChild(JAWADEOBF_name)
            if JAWADEOBF_curScale and JAWADEOBF_curScale:IsA("NumberValue")
                and JAWADEOBF_tScale and JAWADEOBF_tScale:IsA("NumberValue") then
                JAWADEOBF_curScale.Value = JAWADEOBF_tScale.Value
            end
        end
    end

    JAWADEOBF_model:Destroy()
    JAWADEOBF_WindUI:Notify({
        Title = "Avatar Changer",
        Content = "Avatar spoofed successfully!",
        Duration = 3,
    })
end

-- Restore avatar original
local JAWADEOBF_resetAvatar = function()
    local JAWADEOBF_LP = game:GetService("Players").LocalPlayer
    local JAWADEOBF_char = JAWADEOBF_LP.Character
    if not JAWADEOBF_char then return end

    local JAWADEOBF_hum = JAWADEOBF_char:FindFirstChildOfClass("Humanoid")
    if not JAWADEOBF_hum then return end

    local JAWADEOBF_bk = JAWADEOBF_avatarBackup
    if not JAWADEOBF_bk then return end

    local JAWADEOBF_r15Parts = {
        UpperTorso = Enum.BodyPartR15.UpperTorso,
        LowerTorso = Enum.BodyPartR15.LowerTorso,
        LeftUpperArm = Enum.BodyPartR15.LeftUpperArm,
        LeftLowerArm = Enum.BodyPartR15.LeftLowerArm,
        LeftHand = Enum.BodyPartR15.LeftHand,
        RightUpperArm = Enum.BodyPartR15.RightUpperArm,
        RightLowerArm = Enum.BodyPartR15.RightLowerArm,
        RightHand = Enum.BodyPartR15.RightHand,
        LeftUpperLeg = Enum.BodyPartR15.LeftUpperLeg,
        LeftLowerLeg = Enum.BodyPartR15.LeftLowerLeg,
        LeftFoot = Enum.BodyPartR15.LeftFoot,
        RightUpperLeg = Enum.BodyPartR15.RightUpperLeg,
        RightLowerLeg = Enum.BodyPartR15.RightLowerLeg,
        RightFoot = Enum.BodyPartR15.RightFoot,
    }

    for JAWADEOBF_name, JAWADEOBF_enum in pairs(JAWADEOBF_r15Parts) do
        local JAWADEOBF_part = JAWADEOBF_bk.body_parts[JAWADEOBF_name]
        if JAWADEOBF_part then
            pcall(function()
                JAWADEOBF_hum:ReplaceBodyPartR15(JAWADEOBF_enum, JAWADEOBF_part:Clone())
            end)
        end
    end

    local JAWADEOBF_head = JAWADEOBF_char:FindFirstChild("Head")
    if JAWADEOBF_head and JAWADEOBF_bk.head_mesh then
        local JAWADEOBF_mesh = JAWADEOBF_head:FindFirstChildOfClass("SpecialMesh")
        if JAWADEOBF_mesh then
            JAWADEOBF_mesh.MeshId = JAWADEOBF_bk.head_mesh.MeshId
            JAWADEOBF_mesh.TextureId = JAWADEOBF_bk.head_mesh.TextureId
            JAWADEOBF_mesh.Scale = JAWADEOBF_bk.head_mesh.Scale
            JAWADEOBF_mesh.Offset = JAWADEOBF_bk.head_mesh.Offset
        end
    end
    if JAWADEOBF_head and JAWADEOBF_bk.head_size then
        JAWADEOBF_head.Size = JAWADEOBF_bk.head_size
    end
    if JAWADEOBF_head and JAWADEOBF_bk.head_color then
        JAWADEOBF_head.Color = JAWADEOBF_bk.head_color
    end

    for JAWADEOBF_i, JAWADEOBF_ch in ipairs(JAWADEOBF_char:GetChildren()) do
        if JAWADEOBF_ch:IsA("Accessory")
            or JAWADEOBF_ch:IsA("Shirt")
            or JAWADEOBF_ch:IsA("Pants")
            or JAWADEOBF_ch:IsA("ShirtGraphic")
            or JAWADEOBF_ch:IsA("CharacterMesh") then
            JAWADEOBF_ch:Destroy()
        end
    end

    if JAWADEOBF_head then
        for JAWADEOBF_i, JAWADEOBF_k in ipairs(JAWADEOBF_head:GetChildren()) do
            if JAWADEOBF_k:IsA("Decal")
                and (JAWADEOBF_k.Name == "face" or JAWADEOBF_k.Name == "Face") then
                JAWADEOBF_k:Destroy()
            end
        end
        if JAWADEOBF_bk.face then
            JAWADEOBF_bk.face:Clone().Parent = JAWADEOBF_head
        end
    end

    for JAWADEOBF_i, JAWADEOBF_cl in ipairs(JAWADEOBF_bk.clothing) do
        JAWADEOBF_cl:Clone().Parent = JAWADEOBF_char
    end

    if JAWADEOBF_bk.body_colors then
        local JAWADEOBF_bc = JAWADEOBF_char:FindFirstChildOfClass("BodyColors")
        if JAWADEOBF_bc then
            JAWADEOBF_bc.HeadColor3 = JAWADEOBF_bk.body_colors.HeadColor3
            JAWADEOBF_bc.TorsoColor3 = JAWADEOBF_bk.body_colors.TorsoColor3
            JAWADEOBF_bc.LeftArmColor3 = JAWADEOBF_bk.body_colors.LeftArmColor3
            JAWADEOBF_bc.RightArmColor3 = JAWADEOBF_bk.body_colors.RightArmColor3
            JAWADEOBF_bc.LeftLegColor3 = JAWADEOBF_bk.body_colors.LeftLegColor3
            JAWADEOBF_bc.RightLegColor3 = JAWADEOBF_bk.body_colors.RightLegColor3
        end
    end

    for JAWADEOBF_i, JAWADEOBF_acc in ipairs(JAWADEOBF_bk.accessories) do
        local JAWADEOBF_clone = JAWADEOBF_acc:Clone()
        local JAWADEOBF_handle = JAWADEOBF_clone:FindFirstChild("Handle")
        if not JAWADEOBF_handle then continue end

        local JAWADEOBF_attach = JAWADEOBF_handle:FindFirstChildOfClass("Attachment")

        for JAWADEOBF_j, JAWADEOBF_k in ipairs(JAWADEOBF_handle:GetChildren()) do
            if JAWADEOBF_k:IsA("Weld")
                or JAWADEOBF_k:IsA("Motor6D")
                or JAWADEOBF_k:IsA("WeldConstraint") then
                JAWADEOBF_k:Destroy()
            end
        end

        local JAWADEOBF_targetPart, JAWADEOBF_targetAttach = nil, nil
        if JAWADEOBF_attach then
            for JAWADEOBF_j, JAWADEOBF_part in ipairs(JAWADEOBF_char:GetChildren()) do
                if JAWADEOBF_part:IsA("BasePart") then
                    for JAWADEOBF_jj, JAWADEOBF_a in ipairs(JAWADEOBF_part:GetChildren()) do
                        if JAWADEOBF_a:IsA("Attachment")
                            and JAWADEOBF_a.Name == JAWADEOBF_attach.Name then
                            JAWADEOBF_targetPart = JAWADEOBF_part
                            JAWADEOBF_targetAttach = JAWADEOBF_a
                            break
                        end
                    end
                end
                if JAWADEOBF_targetPart then break end
            end
        end

        if not JAWADEOBF_targetPart then
            JAWADEOBF_targetPart = JAWADEOBF_char:FindFirstChild("Head")
                or JAWADEOBF_char:FindFirstChild("UpperTorso")
                or JAWADEOBF_char:FindFirstChild("HumanoidRootPart")
            if not JAWADEOBF_targetPart then continue end
        end

        JAWADEOBF_clone.Parent = JAWADEOBF_char

        local JAWADEOBF_weld = Instance.new("Weld")
        JAWADEOBF_weld.Part0 = JAWADEOBF_targetPart
        JAWADEOBF_weld.Part1 = JAWADEOBF_handle

        if JAWADEOBF_targetAttach and JAWADEOBF_attach then
            JAWADEOBF_weld.C0 = JAWADEOBF_targetAttach.CFrame
            JAWADEOBF_weld.C1 = JAWADEOBF_attach.CFrame
        else
            JAWADEOBF_weld.C0 = CFrame.new(0, JAWADEOBF_targetPart.Size.Y / 2, 0)
            JAWADEOBF_weld.C1 = JAWADEOBF_handle.CFrame
        end
        JAWADEOBF_weld.Parent = JAWADEOBF_handle
    end

    for JAWADEOBF_name, JAWADEOBF_val in pairs(JAWADEOBF_bk.scales) do
        local JAWADEOBF_scale = JAWADEOBF_hum:FindFirstChild(JAWADEOBF_name)
        if JAWADEOBF_scale and JAWADEOBF_scale:IsA("NumberValue") then
            JAWADEOBF_scale.Value = JAWADEOBF_val
        end
    end

    JAWADEOBF_avatarBackup = nil
    JAWADEOBF_WindUI:Notify({
        Title = "Avatar Changer",
        Content = "Avatar reset successfully",
        Duration = 3,
    })
end

-- UI Avatar
JAWADEOBF_AvatarSection:Input({
    Title = "Spoof Avatar (Username)",
    PlaceholderText = "Target Username...",
    ClearTextOnFocus = false,
    Flag = "AvatarTargetUsername",
    Callback = function(JAWADEOBF_v)
        if JAWADEOBF_v and JAWADEOBF_v ~= "" then
            task.spawn(function()
                local JAWADEOBF_ok, JAWADEOBF_uid = pcall(function()
                    return game:GetService("Players"):GetUserIdFromNameAsync(JAWADEOBF_v)
                end)

                if JAWADEOBF_ok and JAWADEOBF_uid then
                    JAWADEOBF_applyAvatarSpoof(JAWADEOBF_uid)
                else
                    JAWADEOBF_WindUI:Notify({
                        Title = "Avatar Changer",
                        Content = "Player not found!",
                        Duration = 3,
                    })
                end
            end)
        end
    end,
})

JAWADEOBF_AvatarSection:Button({
    Title = "Reset Avatar",
    Desc = "Revert to your original avatar",
    Callback = function()
        JAWADEOBF_resetAvatar()
    end,
})

JAWADEOBF_AvatarSection:Input({
    Title = "Spoof Name (Local)",
    PlaceholderText = "Fake Name...",
    ClearTextOnFocus = false,
    Flag = "AvatarSpoofName",
    Callback = function(JAWADEOBF_v)
        JAWADEOBF_spoofName = JAWADEOBF_v
        if JAWADEOBF_v ~= "" then
            JAWADEOBF_spoofNameOn = true
            JAWADEOBF_WindUI:Notify({
                Title = "Name Spoofer",
                Content = "Spoofing name to: " .. JAWADEOBF_v,
                Duration = 3,
            })
        else
            JAWADEOBF_spoofNameOn = false
            JAWADEOBF_WindUI:Notify({
                Title = "Name Spoofer",
                Content = "Name spoofing disabled.",
                Duration = 3,
            })
        end
    end,
})

JAWADEOBF_AvatarSection:Input({
    Title = "Spoof Rank (Local)",
    PlaceholderText = "Fake Rank...",
    ClearTextOnFocus = false,
    Flag = "AvatarSpoofRank",
    Callback = function(JAWADEOBF_v)
        JAWADEOBF_spoofRank = JAWADEOBF_v
        if JAWADEOBF_v ~= "" then
            JAWADEOBF_spoofRankOn = true
            JAWADEOBF_WindUI:Notify({
                Title = "Rank Spoofer",
                Content = "Spoofing rank to: " .. JAWADEOBF_v,
                Duration = 3,
            })
        else
            JAWADEOBF_spoofRankOn = false
            JAWADEOBF_WindUI:Notify({
                Title = "Rank Spoofer",
                Content = "Rank spoofing disabled.",
                Duration = 3,
            })
        end
    end,
})

JAWADEOBF_AvatarSection:Input({
    Title = "Custom Prefix (Name)",
    PlaceholderText = "e.g. 505 (Leave blank to keep native)",
    ClearTextOnFocus = false,
    Flag = "AvatarCustomPrefix",
    Callback = function(JAWADEOBF_v)
        JAWADEOBF_prefixText = JAWADEOBF_v
    end,
})

JAWADEOBF_AvatarSection:Colorpicker({
    Title = "Prefix Color",
    Desc = "Color for the custom prefix",
    Default = Color3.fromRGB(24, 24, 24),
    Transparency = 0,
    Locked = false,
    Flag = "AvatarPrefixColor",
    Callback = function(JAWADEOBF_v)
        JAWADEOBF_prefixColor = JAWADEOBF_v
    end,
})

JAWADEOBF_AvatarSection:Colorpicker({
    Title = "Name Shadow Color",
    Desc = "Color for the name shadow",
    Default = Color3.fromRGB(0, 0, 0),
    Transparency = 0,
    Locked = false,
    Flag = "AvatarNameShadowColor",
    Callback = function(JAWADEOBF_v)
        JAWADEOBF_nameShadowColor = JAWADEOBF_v
    end,
})

JAWADEOBF_AvatarSection:Input({
    Title = "Rank Gradient Sequence",
    PlaceholderText = "Studio ColorSequence string...",
    ClearTextOnFocus = false,
    Flag = "AvatarRankGradient",
    Callback = function(JAWADEOBF_v)
        if JAWADEOBF_v ~= "" then
            local JAWADEOBF_seq = JAWADEOBF_parseColorSequence(JAWADEOBF_v)
            if JAWADEOBF_seq then
                JAWADEOBF_rankGradient = JAWADEOBF_seq
                JAWADEOBF_WindUI:Notify({
                    Title = "Rank Spoofer",
                    Content = "Gradient parsed successfully!",
                    Duration = 3,
                })
            else
                JAWADEOBF_WindUI:Notify({
                    Title = "Rank Spoofer",
                    Content = "Invalid Gradient format!",
                    Duration = 3,
                })
            end
        else
            JAWADEOBF_rankGradient = nil
        end
    end,
})

-- Loop Name/Rank Spoofer
task.spawn(function()
    while task.wait(1) do
        local JAWADEOBF_LP = game:GetService("Players").LocalPlayer
        if not JAWADEOBF_LP then continue end

        if JAWADEOBF_spoofNameOn and JAWADEOBF_spoofName ~= "" then
            pcall(function()
                local JAWADEOBF_realName = JAWADEOBF_LP.Name
                local JAWADEOBF_displayName = JAWADEOBF_LP.DisplayName

                local JAWADEOBF_replaceAll
                JAWADEOBF_replaceAll = function(JAWADEOBF_root)
                    if not JAWADEOBF_root then return end
                    for JAWADEOBF_i, JAWADEOBF_k in ipairs(JAWADEOBF_root:GetDescendants()) do
                        if JAWADEOBF_k:IsA("TextLabel")
                            or JAWADEOBF_k:IsA("TextButton")
                            or JAWADEOBF_k:IsA("TextBox") then
                            if JAWADEOBF_k.Text:find(JAWADEOBF_realName)
                                or JAWADEOBF_k.Text:find(JAWADEOBF_displayName) then
                                JAWADEOBF_k.Text = JAWADEOBF_k.Text
                                    :gsub(JAWADEOBF_realName, JAWADEOBF_spoofName)
                                    :gsub(JAWADEOBF_displayName, JAWADEOBF_spoofName)
                            end
                        end
                    end
                end

                JAWADEOBF_replaceAll(JAWADEOBF_LP:FindFirstChild("PlayerGui"))
                if JAWADEOBF_LP.Character then
                    JAWADEOBF_replaceAll(JAWADEOBF_LP.Character)
                end
            end)
        end

        -- Rank tag di atas kepala
        pcall(function()
            local JAWADEOBF_wsChar = workspace:FindFirstChild(JAWADEOBF_LP.Name)
                or JAWADEOBF_LP.Character
            if JAWADEOBF_wsChar then
                local JAWADEOBF_head = JAWADEOBF_wsChar:FindFirstChild("Head")
                if JAWADEOBF_head then
                    local JAWADEOBF_tags = JAWADEOBF_head:FindFirstChild("RankTags")
                    if JAWADEOBF_tags then
                        local JAWADEOBF_nameLbl = JAWADEOBF_tags:FindFirstChild("Player_Username")
                        local JAWADEOBF_rankLbl = JAWADEOBF_tags:FindFirstChild("Player_Rank")

                        if JAWADEOBF_spoofNameOn
                            and JAWADEOBF_spoofName ~= ""
                            and JAWADEOBF_nameLbl
                            and JAWADEOBF_nameLbl:IsA("TextLabel") then

                            local JAWADEOBF_tag = JAWADEOBF_nameLbl.Text
                                :match("^(<font.->%[.-%]%</font>)")

                            if JAWADEOBF_prefixText ~= "" then
                                JAWADEOBF_nameLbl.Text = string.format(
                                    "<font color=\"rgb(%d,%d,%d)\">[%s]</font> %s",
                                    math.floor(JAWADEOBF_prefixColor.R * 255),
                                    math.floor(JAWADEOBF_prefixColor.G * 255),
                                    math.floor(JAWADEOBF_prefixColor.B * 255),
                                    JAWADEOBF_prefixText,
                                    JAWADEOBF_spoofName
                                )
                            elseif JAWADEOBF_tag then
                                JAWADEOBF_nameLbl.Text = JAWADEOBF_tag
                                    .. " " .. JAWADEOBF_spoofName
                            else
                                JAWADEOBF_nameLbl.Text = JAWADEOBF_spoofName
                            end

                            local JAWADEOBF_shadow = JAWADEOBF_nameLbl:FindFirstChild("Shadow")
                            if JAWADEOBF_shadow and JAWADEOBF_shadow:IsA("TextLabel") then
                                JAWADEOBF_shadow.Text = JAWADEOBF_nameLbl.Text
                                JAWADEOBF_shadow.TextColor3 = JAWADEOBF_nameShadowColor
                            end
                        end

                        if JAWADEOBF_spoofRankOn
                            and JAWADEOBF_spoofRank ~= ""
                            and JAWADEOBF_rankLbl
                            and JAWADEOBF_rankLbl:IsA("TextLabel") then

                            JAWADEOBF_rankLbl.Text = JAWADEOBF_spoofRank

                            local JAWADEOBF_grad = JAWADEOBF_rankLbl:FindFirstChildOfClass("UIGradient")
                            if JAWADEOBF_grad and JAWADEOBF_rankGradient then
                                JAWADEOBF_grad.Color = JAWADEOBF_rankGradient
                            end
                        end
                    end
                end
            end
        end)
    end
end)

--=====================================================================
-- TAB: CONFIGURATION
--=====================================================================
local JAWADEOBF_ConfigTab = JAWADEOBF_Window:Tab({
    Title = "Configuration",
    Icon = "settings",
})

local JAWADEOBF_ThemeSection = JAWADEOBF_ConfigTab:Section({
    Title = "Theme",
})

local JAWADEOBF_themeList = {}
pcall(function()
    local JAWADEOBF_themes = JAWADEOBF_WindUI:GetThemes()
    if JAWADEOBF_themes then
        for JAWADEOBF_k, JAWADEOBF_v in pairs(JAWADEOBF_themes) do
            if type(JAWADEOBF_v) == "string" then
                table.insert(JAWADEOBF_themeList, JAWADEOBF_v)
            elseif type(JAWADEOBF_k) == "string" then
                table.insert(JAWADEOBF_themeList, JAWADEOBF_k)
            end
        end
    end
end)

if #JAWADEOBF_themeList == 0 then
    JAWADEOBF_themeList = {
        "Dark", "Light", "Rose", "Plant", "Red", "Indigo", "Sky", "Violet",
        "Amber", "Emerald", "Midnight", "Crimson", "Monokai Pro",
        "Cotton Candy", "Mellowsi", "Rainbow",
    }
end

JAWADEOBF_ConfigTab:Dropdown({
    Title = "Select Theme",
    Desc = "Choose UI Theme",
    Multi = false,
    Flag = "SelectedTheme",
    Value = JAWADEOBF_WindUI:GetCurrentTheme() or "Dark",
    Values = JAWADEOBF_themeList,
    Callback = function(JAWADEOBF_v)
        pcall(function() JAWADEOBF_WindUI:SetTheme(JAWADEOBF_v) end)
    end,
})

local JAWADEOBF_ConfigSection = JAWADEOBF_ConfigTab:Section({
    Title = "Config Manager",
})

local JAWADEOBF_selectedConfig = ""
local JAWADEOBF_configName = ""

local JAWADEOBF_getConfigs = function()
    local JAWADEOBF_list = {}
    pcall(function()
        local JAWADEOBF_all = JAWADEOBF_Window.ConfigManager:AllConfigs()
        if JAWADEOBF_all then
            for JAWADEOBF_i, JAWADEOBF_c in ipairs(JAWADEOBF_all) do
                table.insert(JAWADEOBF_list, JAWADEOBF_c)
            end
        end
    end)
    return JAWADEOBF_list
end

local JAWADEOBF_configDropdown = JAWADEOBF_ConfigTab:Dropdown({
    Title = "Select Config",
    Desc = "Choose saved config",
    Multi = false,
    Flag = "SelectedConfigDropdown",
    Value = "",
    Values = JAWADEOBF_getConfigs(),
    Callback = function(JAWADEOBF_v)
        JAWADEOBF_selectedConfig = JAWADEOBF_v
    end,
})

JAWADEOBF_ConfigTab:Input({
    Title = "Config Name",
    Desc = "New config name",
    PlaceholderText = "Enter config name...",
    Flag = "ConfigNameInput",
    Callback = function(JAWADEOBF_v)
        JAWADEOBF_configName = JAWADEOBF_v
    end,
})

JAWADEOBF_ConfigTab:Button({
    Title = "Save Config",
    Desc = "Save current settings to new config",
    Callback = function()
        if JAWADEOBF_configName == "" then
            JAWADEOBF_WindUI:Notify({
                Title = "Config",
                Content = "Enter config name first!",
                Duration = 3,
            })
            return
        end

        pcall(function()
            JAWADEOBF_selectedConfig = JAWADEOBF_configName
            pcall(function() JAWADEOBF_configDropdown:Select(JAWADEOBF_configName) end)

            local JAWADEOBF_cfg = JAWADEOBF_Window.ConfigManager:CreateConfig(JAWADEOBF_configName)
            JAWADEOBF_cfg:Save()
        end)

        JAWADEOBF_WindUI:Notify({
            Title = "Config",
            Content = "Config '" .. JAWADEOBF_configName .. "' saved successfully!",
            Duration = 3,
        })

        pcall(function()
            JAWADEOBF_configDropdown:Refresh(JAWADEOBF_getConfigs())
            JAWADEOBF_configDropdown:Select(JAWADEOBF_configName)
        end)
    end,
})

JAWADEOBF_ConfigTab:Button({
    Title = "Load Config",
    Desc = "Load selected config",
    Callback = function()
        if JAWADEOBF_selectedConfig == "" or JAWADEOBF_selectedConfig == "--" then
            JAWADEOBF_WindUI:Notify({
                Title = "Config",
                Content = "Select config first!",
                Duration = 3,
            })
            return
        end

        pcall(function()
            local JAWADEOBF_cfg = JAWADEOBF_Window.ConfigManager:CreateConfig(JAWADEOBF_selectedConfig)
            JAWADEOBF_cfg:Load()
            pcall(function() JAWADEOBF_configDropdown:Select(JAWADEOBF_selectedConfig) end)
        end)

        JAWADEOBF_WindUI:Notify({
            Title = "Config",
            Content = "Config '" .. JAWADEOBF_selectedConfig .. "' loaded successfully!",
            Duration = 3,
        })
    end,
})

JAWADEOBF_ConfigTab:Button({
    Title = "Rewrite Config",
    Desc = "Rewrite selected config",
    Callback = function()
        if JAWADEOBF_selectedConfig == "" or JAWADEOBF_selectedConfig == "--" then
            JAWADEOBF_WindUI:Notify({
                Title = "Config",
                Content = "Select config first!",
                Duration = 3,
            })
            return
        end

        local JAWADEOBF_path = "WindUI/DX-SR/config/" .. JAWADEOBF_selectedConfig .. ".json"
        local JAWADEOBF_http = game:GetService("HttpService")
        local JAWADEOBF_autoLoad = false
        local JAWADEOBF_customData = {}

        if isfile and isfile(JAWADEOBF_path) and readfile then
            pcall(function()
                local JAWADEOBF_data = JAWADEOBF_http:JSONDecode(readfile(JAWADEOBF_path))
                if type(JAWADEOBF_data) == "table" then
                    JAWADEOBF_autoLoad = JAWADEOBF_data.__autoload or false
                    JAWADEOBF_customData = JAWADEOBF_data.__custom or {}
                end
            end)
        end

        local JAWADEOBF_ok, JAWADEOBF_err = pcall(function()
            pcall(function() JAWADEOBF_configDropdown:Select(JAWADEOBF_selectedConfig) end)

            local JAWADEOBF_elements = {}
            local JAWADEOBF_parser = JAWADEOBF_Window.ConfigManager.Parser
            local JAWADEOBF_flags = JAWADEOBF_Window.PendingFlags or {}

            for JAWADEOBF_flag, JAWADEOBF_data in pairs(JAWADEOBF_flags) do
                if JAWADEOBF_data
                    and JAWADEOBF_data.__type
                    and JAWADEOBF_parser
                    and JAWADEOBF_parser[JAWADEOBF_data.__type] then

                    pcall(function()
                        JAWADEOBF_elements[tostring(JAWADEOBF_flag)] =
                            JAWADEOBF_parser[JAWADEOBF_data.__type].Save(JAWADEOBF_data)
                    end)
                end
            end

            local JAWADEOBF_payload = {
                __version = 1.2,
                __elements = JAWADEOBF_elements,
                __autoload = JAWADEOBF_autoLoad,
                __custom = JAWADEOBF_customData,
            }

            if writefile then
                writefile(JAWADEOBF_path, JAWADEOBF_http:JSONEncode(JAWADEOBF_payload))
            end

            if JAWADEOBF_Window.ConfigManager
                and JAWADEOBF_Window.ConfigManager.Configs
                and JAWADEOBF_Window.ConfigManager.Configs[JAWADEOBF_selectedConfig] then

                local JAWADEOBF_cfg = JAWADEOBF_Window.ConfigManager.Configs[JAWADEOBF_selectedConfig]
                JAWADEOBF_cfg.AutoLoad = JAWADEOBF_autoLoad
                JAWADEOBF_cfg.CustomData = JAWADEOBF_customData

                if JAWADEOBF_flags then
                    for JAWADEOBF_flag, JAWADEOBF_data in pairs(JAWADEOBF_flags) do
                        JAWADEOBF_cfg:Register(JAWADEOBF_flag, JAWADEOBF_data)
                    end
                end
            end
        end)

        if JAWADEOBF_ok then
            JAWADEOBF_WindUI:Notify({
                Title = "Config",
                Content = "Config '" .. JAWADEOBF_selectedConfig
                    .. "' rewritten successfully! (Not loaded)",
                Duration = 3,
            })
        else
            JAWADEOBF_WindUI:Notify({
                Title = "Config",
                Content = "Failed to rewrite config: " .. tostring(JAWADEOBF_err),
                Duration = 3,
            })
        end
    end,
})

JAWADEOBF_ConfigTab:Button({
    Title = "Delete Config",
    Desc = "Delete selected config",
    Callback = function()
        if JAWADEOBF_selectedConfig == "" or JAWADEOBF_selectedConfig == "--" then
            JAWADEOBF_WindUI:Notify({
                Title = "Config",
                Content = "Select config first!",
                Duration = 3,
            })
            return
        end

        pcall(function()
            local JAWADEOBF_cfg = JAWADEOBF_Window.ConfigManager
                :CreateConfig(JAWADEOBF_selectedConfig)
            JAWADEOBF_cfg:Delete()
        end)

        JAWADEOBF_WindUI:Notify({
            Title = "Config",
            Content = "Config '" .. JAWADEOBF_selectedConfig .. "' deleted successfully!",
            Duration = 3,
        })

        JAWADEOBF_selectedConfig = ""
        pcall(function()
            JAWADEOBF_configDropdown:Refresh(JAWADEOBF_getConfigs())
            JAWADEOBF_configDropdown:Select("")
        end)
    end,
})

JAWADEOBF_ConfigTab:Button({
    Title = "Set Auto Load",
    Desc = "Automatically load selected config on start",
    Callback = function()
        if JAWADEOBF_selectedConfig == "" or JAWADEOBF_selectedConfig == "--" then
            JAWADEOBF_WindUI:Notify({
                Title = "Config",
                Content = "Select config first!",
                Duration = 3,
            })
            return
        end

        pcall(function()
            local JAWADEOBF_http = game:GetService("HttpService")
            local JAWADEOBF_all = JAWADEOBF_Window.ConfigManager:AllConfigs()

            if JAWADEOBF_all
                and isfile and readfile and writefile then
                for JAWADEOBF_i, JAWADEOBF_c in ipairs(JAWADEOBF_all) do
                    local JAWADEOBF_p = "WindUI/DX-SR/config/" .. JAWADEOBF_c .. ".json"
                    if isfile(JAWADEOBF_p) then
                        pcall(function()
                            local JAWADEOBF_d = JAWADEOBF_http:JSONDecode(readfile(JAWADEOBF_p))
                            if type(JAWADEOBF_d) == "table" then
                                JAWADEOBF_d.__autoload =
                                    (JAWADEOBF_c == JAWADEOBF_selectedConfig)
                                writefile(JAWADEOBF_p, JAWADEOBF_http:JSONEncode(JAWADEOBF_d))
                            end
                        end)
                    end
                end
            end

            pcall(function() JAWADEOBF_configDropdown:Select(JAWADEOBF_selectedConfig) end)

            if JAWADEOBF_Window.ConfigManager
                and JAWADEOBF_Window.ConfigManager.Configs then
                for JAWADEOBF_name, JAWADEOBF_cfg in pairs(JAWADEOBF_Window.ConfigManager.Configs) do
                    if JAWADEOBF_cfg and JAWADEOBF_cfg.SetAutoLoad then
                        JAWADEOBF_cfg:SetAutoLoad(
                            JAWADEOBF_name == JAWADEOBF_selectedConfig
                        )
                    end
                end
            end
        end)

        JAWADEOBF_WindUI:Notify({
            Title = "Config",
            Content = "Auto load set to '" .. JAWADEOBF_selectedConfig .. "'!",
            Duration = 3,
        })
    end,
})

-- Auto-load config saat script jalan
pcall(function()
    local JAWADEOBF_http = game:GetService("HttpService")
    local JAWADEOBF_all = JAWADEOBF_Window.ConfigManager:AllConfigs()

    if JAWADEOBF_all and readfile and isfile then
        for JAWADEOBF_i, JAWADEOBF_c in pairs(JAWADEOBF_all) do
            local JAWADEOBF_p = "WindUI/DX-SR/config/" .. JAWADEOBF_c .. ".json"
            if isfile(JAWADEOBF_p) then
                local JAWADEOBF_ok, JAWADEOBF_data = pcall(function()
                    return JAWADEOBF_http:JSONDecode(readfile(JAWADEOBF_p))
                end)

                if JAWADEOBF_ok
                    and type(JAWADEOBF_data) == "table"
                    and JAWADEOBF_data.__autoload then

                    local JAWADEOBF_cfg = JAWADEOBF_Window.ConfigManager:CreateConfig(JAWADEOBF_c)
                    JAWADEOBF_cfg:Load()
                    JAWADEOBF_selectedConfig = JAWADEOBF_c

                    task.defer(function()
                        pcall(function()
                            JAWADEOBF_configDropdown:Select(JAWADEOBF_c)
                        end)
                    end)
                    break
                end
            end
        end
    end
end)

--=====================================================================
-- EDIT OPEN BUTTON
--=====================================================================
JAWADEOBF_Window:EditOpenButton({
    Title = "Open UI",
    Icon = "monitor",
    CornerRadius = UDim.new(0, 16),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("FF0F7B"),
        Color3.fromHex("F89B29")
    ),
    OnlyMobile = false,
    Enabled = true,
})