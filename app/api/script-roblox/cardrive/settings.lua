-- ⚙️ HipHub CDID — Settings & Configuration Manager
-- Handles config persistence, performance booster, UI toggle keybind, and settings tab UI

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local HttpService = game:GetService("HttpService")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local Lighting = game:GetService("Lighting")
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer

	local CONFIG_FILE = "HipHub/cdid_config.json"
	if isfile and not isfile(CONFIG_FILE) and isfile("cdid_config.json") then
		CONFIG_FILE = "cdid_config.json"
	end

	-- Default Configuration Schema
	local Config = {
		main = {
			walkSpeed = 16,
			jumpPower = 50,
			infiniteStamina = false,
			noclip = false,
			fly = false,
			flySpeed = 50,
			antiAfk = true,
			antiRagdoll = true,
			instantPrompt = true
		},
		farm = {
			siLambat = false,
			siLambatDelay = 1.0,
			janjiJiwa = false,
			janjiJiwaDelay = 1.2,
			ems = false,
			emsDelay = 1.5,
			taxi = false,
			truck = false,
			bcaCourier = false,
			bcaCourierDelay = 1.0,
			bcaTargetEarning = 0,
			odometer = false,
			odometerSpeed = 120,
			autoClaimBox = true,
			autoDailyQuest = true,
			safeMode = true,
			autoFlip = true
		},
		vehicle = {
			speedMultiplier = 1.0,
			torqueMultiplier = 1.0,
			topSpeedOverride = 0,
			instantBrake = false,
			driftMode = false,
			flyVehicle = false,
			flyVehicleSpeed = 60,
			noclipVehicle = false,
			infiniteFuel = false,
			autoRefuel = false,
			autoFlipCar = true,
			noCarCollision = false,
			autoToll = false,
			autoWash = false,
			autoOil = false
		},
		visuals = {
			carEsp = false,
			playerEsp = false,
			jobEsp = false,
			dealershipEsp = false,
			fullbright = false,
			noFog = false,
			speedometer = true
		},
		settings = {
			uiKeybind = "RightShift",
			blackScreen = false,
			capFps = 60,
			lowGraphics = false,
			autoSave = true
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
				writefile("HipHub/cdid_config.json", encoded)
				UI.Notify("Config Saved", "Configuration successfully written to disk.", 2, "success")
			end)
		end
	end

	loadConfig()
	_G.HipHubConfig = Config
	_G.HipHubSaveConfig = saveConfig

	------------------------------------------------
	-- 🎨 BUILD SETTINGS TAB
	------------------------------------------------
	local settingsFrame = UI.tabs["Settings"].Frame

	-- Profile / Config Section
	local configSec = UI.AddSection(settingsFrame, "Configuration Management", 1)
	UI.AddButton(configSec, "💾 Save Configuration", function()
		saveConfig()
	end, 1)

	UI.AddButton(configSec, "🔄 Reset Configuration to Default", function()
		if delfile and isfile and isfile(CONFIG_FILE) then
			pcall(delfile, CONFIG_FILE)
		end
		UI.Notify("Config Reset", "Default settings restored. Re-execute to refresh values.", 3, "warning")
	end, 2)

	UI.AddToggle(configSec, "Auto Save Changes", Config.settings.autoSave, function(v)
		Config.settings.autoSave = v
		if v then saveConfig() end
	end, 3)

	-- Performance & Boost Section
	local perfSec = UI.AddSection(settingsFrame, "Performance & Optimization", 2)

	UI.AddToggle(perfSec, "Black Screen (Low CPU/GPU for Overnight)", Config.settings.blackScreen, function(v)
		Config.settings.blackScreen = v
		pcall(function()
			RunService:Set3dRenderingEnabled(not v)
		end)
		if v then
			UI.Notify("Black Screen Enabled", "3D rendering disabled to save CPU/GPU.", 3, "success")
		else
			UI.Notify("Black Screen Disabled", "3D rendering restored.", 3, "success")
		end
		if Config.settings.autoSave then saveConfig() end
	end, 1)

	UI.AddSlider(perfSec, "FPS Limit Cap", 15, 240, Config.settings.capFps, function(v)
		Config.settings.capFps = v
		if setfpscap then pcall(setfpscap, v) end
		if Config.settings.autoSave then saveConfig() end
	end, 2, " FPS")

	UI.AddToggle(perfSec, "Low Graphics / Anti-Lag", Config.settings.lowGraphics, function(v)
		Config.settings.lowGraphics = v
		pcall(function()
			for _, obj in pairs(workspace:GetDescendants()) do
				if v then
					if obj:IsA("BasePart") and not obj:IsA("MeshPart") then
						obj.Material = Enum.Material.SmoothPlastic
					elseif obj:IsA("Decal") or obj:IsA("Texture") then
						obj.Transparency = 1
					elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") then
						obj.Enabled = false
					end
				end
			end
			if v then
				Lighting.GlobalShadows = false
				Lighting.FogEnd = 9e9
				settings().Rendering.QualityLevel = 1
			end
		end)
		if v then
			UI.Notify("Anti-Lag Enabled", "Optimized textures and world rendering.", 2, "success")
		end
	end, 3)

	-- UI Controls & Keybinds
	local uiSec = UI.AddSection(settingsFrame, "UI Controls & Keybind", 3)

	local currentKey = Enum.KeyCode[Config.settings.uiKeybind] or Enum.KeyCode.RightShift
	local keybindBtn
	keybindBtn = UI.AddButton(uiSec, "Toggle UI Keybind: [" .. currentKey.Name .. "]", function()
		keybindBtn.Text = "Press any key to bind..."
		local conn
		conn = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				conn:Disconnect()
				currentKey = input.KeyCode
				Config.settings.uiKeybind = currentKey.Name
				keybindBtn.Text = "Toggle UI Keybind: [" .. currentKey.Name .. "]"
				UI.Notify("Keybind Updated", "UI toggle set to " .. currentKey.Name, 2, "success")
				if Config.settings.autoSave then saveConfig() end
			end
		end)
	end, 1)

	-- UI Toggle Listener
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == currentKey then
			UI.mainFrame.Visible = not UI.mainFrame.Visible
			UI.shadowFrame.Visible = UI.mainFrame.Visible
		end
	end)

	UI.AddButton(uiSec, "❌ Close / Destroy UI", function()
		if UI.gui then UI.gui:Destroy() end
	end, 2, Color3.fromRGB(180, 40, 40))
end)

if not success then
	warn("[HipHub CDID Settings Error]:", err)
end
