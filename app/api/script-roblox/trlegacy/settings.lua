-- ️ HipHub TR Legacy — Settings & Configuration Manager

local success, err = pcall(function()
    local UI = _G.HipHubUI
    if not UI then return end

    local HttpService = game:GetService("HttpService")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Lighting = game:GetService("Lighting")
    local Players = game:GetService("Players")
    local VirtualUser = game:GetService("VirtualUser")
    local player = Players.LocalPlayer

    local CONFIG_FILE = "HipHub/trlegacy_config.json"
    if isfile and not isfile(CONFIG_FILE) and isfile("trlegacy_config.json") then
        CONFIG_FILE = "trlegacy_config.json"
    end

    local Config = {
        farm = {
            autoRace = false,
            selectedRace = "Race 1 (Mountain Race - RM 26,500 Solo)",
            raceUnderground = true,
            targetEarnEnabled = false,
            targetEarnAmount = 100000,
            checkpointDelay = 0.02,
            returnToSurface = true,
            autoDriveCircle = false,
            driveUnderground = true,
            circleRadius = 65,
            circleSpeed = 150,
            antiStuck = true,
            autoLoop = true
        },
        vehicle = {
            selectedVehicle = "Kasaki z800 2015",
            autoMount = true,
            antiFall = true,
            speedMultiplier = 1.0,
            instantBrake = true,
            vehicleFly = false,
            flySpeed = 120,
            vehicleNoclip = false
        },
        settings = {
            antiAfk = true,
            antiStaff = true,
            staffAction = "Hentikan Farming Saja",
            minStaffRank = 248,
            blackScreen = false,
            fpsCap = 60,
            lowGraphics = false,
            uiKeybind = "RightShift",
        }
    }

    -- Load saved config if available
    local function loadConfig()
        pcall(function()
            if not readfile then return end
            local target = nil
            if isfile and isfile("HipHub/trlegacy_config.json") then
                target = "HipHub/trlegacy_config.json"
            elseif isfile and isfile("trlegacy_config.json") then
                target = "trlegacy_config.json"
            end
            if target then
                local raw = readfile(target)
                if raw and #raw > 2 then
                    local decoded = HttpService:JSONDecode(raw)
                    if decoded and type(decoded) == "table" then
                        for category, items in pairs(decoded) do
                            if Config[category] and type(items) == "table" then
                                for k, v in pairs(items) do
                                    Config[category][k] = v
                                end
                            else
                                Config[category] = items
                            end
                        end
                    end
                end
            end
        end)
    end

    local function saveConfig(silent)
        pcall(function()
            if not writefile then return end
            if makefolder then pcall(makefolder, "HipHub") end
            local encoded = HttpService:JSONEncode(Config)
            local ok = pcall(writefile, "HipHub/trlegacy_config.json", encoded)
            if not ok then
                pcall(writefile, "trlegacy_config.json", encoded)
            end
            if not silent and UI and UI.Notify then
                UI.Notify("Settings", "Pengaturan berhasil disimpan ke disk.", 2, "success")
            end
        end)
    end

    local autoSaveDebounce = false
    local function autoSave()
        if autoSaveDebounce then return end
        autoSaveDebounce = true
        task.delay(0.1, function()
            autoSaveDebounce = false
            saveConfig(true)
        end)
    end

    loadConfig()

    if Config.settings.antiStaff == nil then Config.settings.antiStaff = true end
    if Config.settings.staffAction == nil then Config.settings.staffAction = "Hentikan Farming Saja" end
    if Config.settings.minStaffRank == nil then Config.settings.minStaffRank = 248 end

    _G.HipHubConfig = Config
    _G.HipHubSaveConfig = saveConfig
    _G.HipHubAutoSave = autoSave

    ------------------------------------------------
    -- ULTIMATE FPS BOOSTER & GRAPHICS ENGINE
    ------------------------------------------------
    local lowGraphicsConn = nil
    local lowGraphicsLightingConn = nil

    local function optimizeObject(obj)
        if not Config.settings.lowGraphics then return end
        pcall(function()
            if obj:IsA("SurfaceAppearance") then
                obj:Destroy()
            elseif obj:IsA("BasePart") then
                obj.Material = Enum.Material.SmoothPlastic
                obj.CastShadow = false
                obj.Reflectance = 0
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 1
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                obj.Enabled = false
            elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                obj.Shadows = false
                obj.Range = math.min(obj.Range, 12)
            elseif obj:IsA("Highlight") then
                obj.Enabled = false
            elseif obj:IsA("PostEffect") or obj:IsA("BloomEffect") or obj:IsA("DepthOfFieldEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") or obj:IsA("ColorCorrectionEffect") then
                obj.Enabled = false
            elseif obj:IsA("Atmosphere") or obj:IsA("Clouds") then
                obj:Destroy()
            end
        end)
    end

    local function applyLowGraphics(enable)
        if enable then
            -- 1. Optimize all existing objects in workspace & Lighting safely in background
            task.spawn(function()
                pcall(function()
                    local count = 0
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if not Config.settings.lowGraphics then break end
                        optimizeObject(obj)
                        count = count + 1
                        if count % 250 == 0 then
                            task.wait()
                        end
                    end
                    for _, obj in ipairs(Lighting:GetDescendants()) do
                        if not Config.settings.lowGraphics then break end
                        optimizeObject(obj)
                    end
                end)
            end)

            -- 2. Strip Terrain decoration (3D grass) & water physics
            pcall(function()
                local terrain = workspace:FindFirstChildOfClass("Terrain") or workspace.Terrain
                if terrain then
                    terrain.Decoration = false
                    terrain.WaterWaveSize = 0
                    terrain.WaterWaveSpeed = 0
                    terrain.WaterReflectance = 0
                    terrain.WaterTransparency = 0
                end
            end)

            -- 3. Lighting settings
            pcall(function()
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 9e9
                Lighting.ShadowSoftness = 0
                Lighting.Brightness = 1
            end)

            -- 4. Set Roblox client rendering level to Level01 (Minimum)
            pcall(function()
                if settings and settings().Rendering then
                    settings().Rendering.QualityLevel = 1
                    settings().Rendering.EditQualityLevel = 1
                end
            end)

            -- 5. Real-time DescendantAdded listener for new cars / stream-in parts
            if not lowGraphicsConn then
                lowGraphicsConn = workspace.DescendantAdded:Connect(function(obj)
                    if Config.settings.lowGraphics then
                        optimizeObject(obj)
                    end
                end)
            end
            if not lowGraphicsLightingConn then
                lowGraphicsLightingConn = Lighting.DescendantAdded:Connect(function(obj)
                    if Config.settings.lowGraphics then
                        optimizeObject(obj)
                    end
                end)
            end
        else
            -- Disconnect listeners
            if lowGraphicsConn then
                lowGraphicsConn:Disconnect()
                lowGraphicsConn = nil
            end
            if lowGraphicsLightingConn then
                lowGraphicsLightingConn:Disconnect()
                lowGraphicsLightingConn = nil
            end

            -- Restore basic lighting & terrain decoration
            pcall(function()
                Lighting.GlobalShadows = true
                Lighting.FogEnd = 1e4
                local terrain = workspace:FindFirstChildOfClass("Terrain") or workspace.Terrain
                if terrain then
                    terrain.Decoration = true
                end
            end)
        end
    end

    _G.HipHubApplyLowGraphics = applyLowGraphics

    -- Apply initial performance settings
    task.spawn(function()
        if Config.settings.lowGraphics then
            task.wait(0.5)
            applyLowGraphics(true)
        end
        if Config.settings.fpsCap and setfpscap then
            pcall(setfpscap, Config.settings.fpsCap)
        end
    end)


    ------------------------------------------------
    -- ANTI-AFK SYSTEM
    ------------------------------------------------
    player.Idled:Connect(function()
        if Config.settings.antiAfk then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0, 0))
            end)
        end
    end)

    ------------------------------------------------
    -- ANTI-STAFF GUARDIAN SYSTEM
    ------------------------------------------------
    local STAFF_GROUP_ID = 33138186 -- TR Legacy Developer / Admin Group (exrgarage)
    local CREATOR_USER_ID = 5012440553 -- 6rfxn (Owner)

    local staffActionOptions = {
        "Keluar Game (Auto-Leave/Kick)",
        "Pindah Server (Server Hop)",
        "Hentikan Farming Saja"
    }

    local function isStaffMember(p)
        if not p or p == player then return false, nil, 0 end

        -- 1. Owner & Game Creator Check
        if p.UserId == CREATOR_USER_ID or (game.CreatorType == Enum.CreatorType.User and p.UserId == game.CreatorId) then
            return true, "Game Owner", 255
        end

        -- 2. Group Rank Check
        local rank = 0
        local role = "Guest"
        local ok = pcall(function()
            rank = p:GetRankInGroup(STAFF_GROUP_ID)
            role = p:GetRoleInGroup(STAFF_GROUP_ID)
        end)

        local minRank = Config.settings.minStaffRank or 248
        if ok and rank >= minRank then
            return true, role, rank
        end

        -- 3. Role Name Keyword Check
        if ok and role then
            local roleLower = role:lower()
            if roleLower:find("staff") or roleLower:find("admin") or roleLower:find("moderator")
               or roleLower:find("developer") or roleLower:find("manager") or roleLower:find("owner")
               or roleLower:find("holder") then
                return true, role, rank
            end
        end

        -- 4. In-Game Attribute / Admin Badge Check
        local isStaffAttr = p:GetAttribute("IsStaff") or p:GetAttribute("Admin")
        if isStaffAttr then
            return true, "Game Staff Attribute", 250
        end

        return false, nil, rank
    end

    local isEvasionExecuting = false
    local function executeStaffEvasion(staffPlayer, roleName, rankNum)
        if isEvasionExecuting then return end
        isEvasionExecuting = true

        -- Stop all active farming routines immediately
        if _G.HipHub_ToggleAutoRace then pcall(_G.HipHub_ToggleAutoRace, false) end
        if _G.HipHub_ToggleAutoDrive then pcall(_G.HipHub_ToggleAutoDrive, false) end
        if _G.HipHubConfig and _G.HipHubConfig.farm then
            _G.HipHubConfig.farm.autoRace = false
            _G.HipHubConfig.farm.autoDriveCircle = false
        end

        local action = Config.settings.staffAction or "Hentikan Farming Saja"

        if action == "Keluar Game (Auto-Leave/Kick)" then
            local kickMsg = string.format("[HipHub Anti-Staff Guardian]\n\nStaff Terdeteksi: %s (@%s)\nRole: %s (Rank %d)\n\nKeluar dari game secara otomatis untuk mencegah ban.", staffPlayer.DisplayName, staffPlayer.Name, tostring(roleName or "Staff"), rankNum or 0)
            player:Kick(kickMsg)
        elseif action == "Pindah Server (Server Hop)" then
            UI.Notify("Anti-Staff Guardian", "Staff terdeteksi: " .. staffPlayer.Name .. "! Memindahkan ke server lain...", 4, "warning")
            task.spawn(function()
                local TeleportService = game:GetService("TeleportService")
                local placeId = game.PlaceId
                local jobId = game.JobId
                local hopped = false
                pcall(function()
                    local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100", tostring(placeId))
                    local req = syn and syn.request or http and http.request or request or http_request
                    if req then
                        local res = req({ Url = url, Method = "GET" })
                        if res and res.Body then
                            local data = HttpService:JSONDecode(res.Body)
                            if data and data.data then
                                for _, s in ipairs(data.data) do
                                    if type(s) == "table" and s.id ~= jobId and s.playing < s.maxPlayers and s.playing > 0 then
                                        hopped = true
                                        TeleportService:TeleportToPlaceInstance(placeId, s.id, player)
                                        return
                                    end
                                end
                            end
                        end
                    end
                end)
                if not hopped then
                    TeleportService:Teleport(placeId, player)
                end
            end)
        else
            -- Hentikan Farming Saja
            UI.Notify("Anti-Staff Warning", "Peringatan: Staff " .. staffPlayer.Name .. " (" .. tostring(roleName) .. ") berada di server! Farming dihentikan.", 6, "warning")
            isEvasionExecuting = false
        end
    end

    local function scanForStaff()
        if not Config.settings.antiStaff then return false end
        local playersList = Players:GetPlayers()
        for _, p in ipairs(playersList) do
            if p ~= player then
                local isStaff, roleName, rankNum = isStaffMember(p)
                if isStaff then
                    executeStaffEvasion(p, roleName, rankNum)
                    return true, p, roleName, rankNum
                end
            end
        end
        return false
    end

    -- Listener: On Player Added (Instant check when anyone joins server)
    Players.PlayerAdded:Connect(function(newPlayer)
        if Config.settings.antiStaff and newPlayer ~= player then
            task.wait(0.5)
            local isStaff, roleName, rankNum = isStaffMember(newPlayer)
            if isStaff then
                executeStaffEvasion(newPlayer, roleName, rankNum)
            end
        end
    end)

    -- Background Sentinel Loop (Checks every 5 seconds)
    task.spawn(function()
        while true do
            task.wait(5)
            if Config.settings.antiStaff then
                pcall(scanForStaff)
            end
        end
    end)

    _G.HipHub_AntiStaff = {
        isStaffMember = isStaffMember,
        scanForStaff = scanForStaff,
        executeStaffEvasion = executeStaffEvasion
    }

    ------------------------------------------------
    -- UI INTEGRATION
    ------------------------------------------------
    local sFrame = UI.Tabs.Settings
    if not sFrame then return end

    -- 1. Safety & Anti-Staff Guardian Section
    local safetySec = UI.AddSection(sFrame, "Safety & Anti-Staff Guardian", 1)

    local totalPlayersCount = #Players:GetPlayers()
    local staffStatusCard = UI.AddStatsCard(safetySec, "Staff Detector Status", string.format("Aman (0 Staff | %d Pemain Aktif)", totalPlayersCount), 1)

    local function refreshStaffStatus()
        if not staffStatusCard then return end
        local staffCount = 0
        local totalCount = #Players:GetPlayers()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and isStaffMember(p) then
                staffCount = staffCount + 1
            end
        end
        if staffCount > 0 then
            staffStatusCard.Set(string.format("BAHAYA (%d Staff di Server!)", staffCount))
        else
            if Config.settings.antiStaff then
                staffStatusCard.Set(string.format("Aktif & Aman (0 Staff | %d Pemain)", totalCount))
            else
                staffStatusCard.Set(string.format("Nonaktif (0 Staff | %d Pemain)", totalCount))
            end
        end
    end

    UI.AddToggle(safetySec, "Enable Anti-Staff Guardian (Auto-Protect)", Config.settings.antiStaff ~= false, function(v)
        Config.settings.antiStaff = v
        autoSave()
        refreshStaffStatus()
        if v then
            UI.Notify("Anti-Staff", "Anti-Staff Guardian diaktifkan. Server dipantau secara otomatis.", 3, "success")
            scanForStaff()
        else
            UI.Notify("Anti-Staff", "Anti-Staff Guardian dinonaktifkan.", 2, "info")
        end
    end, 2)

    UI.AddDropdown(safetySec, "Aksi Saat Staff Terdeteksi", staffActionOptions, Config.settings.staffAction or staffActionOptions[1], function(selected)
        Config.settings.staffAction = selected
        autoSave()
        UI.Notify("Anti-Staff", "Aksi diatur ke: " .. selected, 2, "info")
    end, 3)

    UI.AddButton(safetySec, "Scan Server Sekarang (Manual Check)", function()
        local found, p, role, rank = scanForStaff()
        refreshStaffStatus()
        if not found then
            UI.Notify("Anti-Staff", string.format("Server Bersih! Tidak ada admin/staff dari %d pemain aktif.", #Players:GetPlayers()), 3, "success")
        end
    end, 4, "primary")

    UI.AddButton(safetySec, "Uji Coba Aksi (Test Run)", function()
        local dummyStaff = {
            DisplayName = "TestAdmin",
            Name = "TestAdmin_Roblox",
            UserId = 12345
        }
        UI.Notify("Anti-Staff Test", "Menjalankan simulasi aksi Anti-Staff...", 2, "warning")
        task.delay(1.5, function()
            executeStaffEvasion(dummyStaff, "Admin (Simulation)", 250)
        end)
    end, 5, "secondary")

    -- Update player count on connect/disconnect
    Players.PlayerAdded:Connect(function()
        task.wait(0.5)
        refreshStaffStatus()
    end)
    Players.PlayerRemoving:Connect(function()
        task.wait(0.5)
        refreshStaffStatus()
    end)

    -- 2. Config Management Section
    local cfgSec = UI.AddSection(sFrame, "Configuration & Profiles", 6)
    UI.AddButton(cfgSec, "Save Configuration", function()
        saveConfig()
    end, 1)

    UI.AddButton(cfgSec, "Reset Configuration to Default", function()
        if delfile and isfile and isfile(CONFIG_FILE) then
            pcall(delfile, CONFIG_FILE)
        end
        UI.Notify("Settings", "Konfigurasi direset ke default.", 2, "warning")
    end, 2)

    -- 3. Performance & Optimization Section
    local perfSec = UI.AddSection(sFrame, "Performance & AFK Farming", 7)
    UI.AddToggle(perfSec, "Anti-AFK Protection (No 20m Kick)", Config.settings.antiAfk, function(v)
        Config.settings.antiAfk = v
        autoSave()
    end, 1)

    UI.AddToggle(perfSec, "Black Screen (Low CPU/GPU for Overnight)", Config.settings.blackScreen, function(v)
        Config.settings.blackScreen = v
        autoSave()
        pcall(function()
            RunService:Set3dRenderingEnabled(not v)
        end)
        if v then
            UI.Notify("Black Screen", "3D rendering dimatikan untuk menghemat GPU/CPU.", 3, "success")
        else
            UI.Notify("Black Screen", "3D rendering dinyalakan kembali.", 2, "success")
        end
    end, 2)

    UI.AddSlider(perfSec, "FPS Limit Cap", 15, 240, Config.settings.fpsCap, 5, function(v)
        Config.settings.fpsCap = v
        autoSave()
        if setfpscap then pcall(setfpscap, v) end
    end, 3)

    UI.AddToggle(perfSec, "Low Graphics / Ultra FPS Boost", Config.settings.lowGraphics, function(v)
        Config.settings.lowGraphics = v
        autoSave()
        applyLowGraphics(v)
        if v then
            UI.Notify("FPS Booster", "Low Graphics aktif: PBR, Mesh, Shadow, Terrain & Partikel dibersihkan.", 3, "success")
        else
            UI.Notify("FPS Booster", "Low Graphics dinonaktifkan.", 2, "info")
        end
    end, 4)

    -- 4. UI Keybind Section
    local uiSec = UI.AddSection(sFrame, "Interface Controls", 8)
    local currentKey = Enum.KeyCode[Config.settings.uiKeybind] or Enum.KeyCode.RightShift
    local keybindBtn
    keybindBtn = UI.AddButton(uiSec, "Toggle UI Keybind: [" .. currentKey.Name .. "]", function()
        keybindBtn.Text = "Tekan tombol keyboard apa saja..."
        local conn
        conn = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                conn:Disconnect()
                currentKey = input.KeyCode
                Config.settings.uiKeybind = currentKey.Name
                autoSave()
                keybindBtn.Text = "Toggle UI Keybind: [" .. currentKey.Name .. "]"
                UI.Notify("Keybind", "UI Toggle diatur ke " .. currentKey.Name, 2, "success")
            end
        end)
    end, 1)

    -- Global Toggle Hotkey
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == currentKey then
            UI.MainFrame.Visible = not UI.MainFrame.Visible
        end
    end)

    UI.AddButton(uiSec, "Destroy / Unload UI", function()
        if UI.gui then UI.gui:Destroy() end
        _G.HipHubUI = nil
        _G.HipHubLoaded = nil
    end, 2, "danger")
end)

if not success then
    warn("[HipHub TR Legacy Settings Error]:", err)
end
