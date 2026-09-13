-- ⚙️ HipHub TR Legacy — Settings & Configuration Manager

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
            raceUnderground = true,
            raceDepth = 25,
            raceTrack = "1",
            raceDelay = 0.05,
            autoDrive = false,
            driveUnderground = true,
            driveDepth = 25,
            driveSpeed = 120,
            circleRadius = 50,
        },
        vehicle = {
            targetVehicle = "Kasaki z800 2015",
            autoMount = true,
            antiFall = true,
            speedMultiplier = 1.0,
        },
        settings = {
            antiAfk = true,
            blackScreen = false,
            fpsCap = 60,
            lowGraphics = false,
            uiKeybind = "RightShift",
        }
    }

    -- Load saved config if available
    local function loadConfig()
        if readfile and isfile and isfile(CONFIG_FILE) then
            pcall(function()
                local raw = readfile(CONFIG_FILE)
                local decoded = HttpService:JSONDecode(raw)
                if decoded then
                    for category, items in pairs(decoded) do
                        if Config[category] then
                            for k, v in pairs(items) do
                                Config[category][k] = v
                            end
                        end
                    end
                end
            end)
        end
    end

    local function saveConfig()
        if writefile then
            pcall(function()
                if makefolder then pcall(makefolder, "HipHub") end
                local encoded = HttpService:JSONEncode(Config)
                writefile(CONFIG_FILE, encoded)
                UI.Notify("Settings", "Pengaturan berhasil disimpan ke disk.", 2, "success")
            end)
        end
    end

    loadConfig()
    _G.HipHubConfig = Config
    _G.HipHubSaveConfig = saveConfig

    ------------------------------------------------
    -- 🛡️ ANTI-AFK SYSTEM
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
    -- 🎨 UI INTEGRATION
    ------------------------------------------------
    local sFrame = UI.Tabs.Settings
    if not sFrame then return end

    -- Config Management Section
    local cfgSec = UI.AddSection(sFrame, "Configuration & Profiles", 1)
    UI.AddButton(cfgSec, "💾 Save Configuration", function()
        saveConfig()
    end, 1)

    UI.AddButton(cfgSec, "🔄 Reset Configuration to Default", function()
        if delfile and isfile and isfile(CONFIG_FILE) then
            pcall(delfile, CONFIG_FILE)
        end
        UI.Notify("Settings", "Konfigurasi direset ke default.", 2, "warning")
    end, 2)

    -- Performance & Optimization Section
    local perfSec = UI.AddSection(sFrame, "Performance & AFK Farming", 2)
    UI.AddToggle(perfSec, "Anti-AFK Protection (No 20m Kick)", Config.settings.antiAfk, function(v)
        Config.settings.antiAfk = v
    end, 1)

    UI.AddToggle(perfSec, "Black Screen (Low CPU/GPU for Overnight)", Config.settings.blackScreen, function(v)
        Config.settings.blackScreen = v
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
        if setfpscap then pcall(setfpscap, v) end
    end, 3)

    UI.AddToggle(perfSec, "Low Graphics / Anti-Lag Mode", Config.settings.lowGraphics, function(v)
        Config.settings.lowGraphics = v
        pcall(function()
            for _, obj in pairs(workspace:GetDescendants()) do
                if v then
                    if obj:IsA("BasePart") and not obj:IsA("MeshPart") then
                        obj.Material = Enum.Material.SmoothPlastic
                    elseif obj:IsA("Decal") or obj:IsA("Texture") then
                        obj.Transparency = 1
                    elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                        obj.Enabled = false
                    end
                end
            end
            if v then
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 1e6
                if settings and settings().Rendering then
                    settings().Rendering.QualityLevel = 1
                end
            end
        end)
        if v then
            UI.Notify("Optimization", "Material dan efek diturunkan untuk performa.", 2, "success")
        end
    end, 4)

    -- UI Keybind Section
    local uiSec = UI.AddSection(sFrame, "Interface Controls", 3)
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

    UI.AddButton(uiSec, "❌ Destroy / Unload UI", function()
        if UI.gui then UI.gui:Destroy() end
        _G.HipHubUI = nil
        _G.HipHubLoaded = nil
    end, 2)
end)

if not success then
    warn("[HipHub TR Legacy Settings Error]:", err)
end
