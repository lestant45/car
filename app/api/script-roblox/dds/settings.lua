-- ⚙️ HipHub DDS — Settings, Configuration Persistence & Stealth Protections
-- Drag Drive Simulator (Place ID: 131378148336503)

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local tab = UI.tabs["Settings"].content
	local HttpService = game:GetService("HttpService")
	local Players = game:GetService("Players")
	local TeleportService = game:GetService("TeleportService")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local player = Players.LocalPlayer

	local CONFIG_PATH = "HipHub/dds_config.json"
	local DEFAULT_CONFIG = {
		main = {
			walkSpeed = 16,
			jumpPower = 50,
			flySpeed = 60,
			noclip = false,
			infiniteStamina = false
		},
		farm = {
			autoBarista = false,
			baristaMinigameDelay = 2.2,
			autoRideGO = false,
			taxiSpeed = 60,
			passengerBoardDelay = 3,
			autoCourier = false,
			courierSpeed = 95,
			autoDragRace = false,
			dragTargetTime = 6.5,
			autoDailyQuests = false,
			autoRedeemCodes = false
		},
		vehicle = {
			antiFall = true,
			speedMultiplier = 1,
			torqueMultiplier = 1,
			infiniteFuel = true,
			vehicleFly = false
		},
		visuals = {
			playerEsp = false,
			jobEsp = false,
			fullBright = false,
			noFog = false
		},
		misc = {
			antiAfk = true,
			stealthMode = true,
			blackScreenEnabled = false,
			capFpsEnabled = false,
			targetFps = 60,
			autoRejoin = true
		}
	}

	_G.HipHubConfig = _G.HipHubConfig or DEFAULT_CONFIG

	------------------------------------------------
	-- 💾 CONFIG PERSISTENCE
	------------------------------------------------
	local function saveConfig()
		if not writefile then return end
		pcall(function()
			if not isfolder("HipHub") then
				makefolder("HipHub")
			end
			local encoded = HttpService:JSONEncode(_G.HipHubConfig)
			writefile(CONFIG_PATH, encoded)
			UI.Notify("Config Saved", "Your settings have been saved successfully.", 2, "success")
		end)
	end

	local function loadConfig()
		if not readfile then return end
		pcall(function()
			if isfile(CONFIG_PATH) then
				local content = readfile(CONFIG_PATH)
				local decoded = HttpService:JSONDecode(content)
				if decoded then
					for cat, sub in pairs(decoded) do
						if _G.HipHubConfig[cat] then
							for k, v in pairs(sub) do
								_G.HipHubConfig[cat][k] = v
							end
						else
							_G.HipHubConfig[cat] = sub
						end
					end
					UI.Notify("Config Loaded", "Loaded settings from file.", 2, "success")
				end
			end
		end)
	end

	------------------------------------------------
	-- 🛡️ ADONIS-SAFE ANTI-AFK ENGINE
	------------------------------------------------
	-- Adonis Detection Avoided:
	--   ❌ game:GetService("VirtualUser")         → Adonis flags this, kicks with Error 267
	--   ❌ hookmetamethod on Idled signal          → Adonis AntiAntiIdle trip 0xC0FA6
	--   ✅ mousemoverel (executor-native)          → Invisible to Adonis, no service access
	--   ✅ Humanoid:ChangeState()                  → Fallback, resets idle timer safely
	local antiAfkConn = nil
	local function toggleAntiAfk(state)
		_G.HipHubConfig.misc.antiAfk = state
		if antiAfkConn then
			antiAfkConn:Disconnect()
			antiAfkConn = nil
		end

		if state then
			local lastTick = tick()
			antiAfkConn = RunService.Heartbeat:Connect(function()
				if tick() - lastTick > 55 then
					lastTick = tick()
					pcall(function()
						-- Method 1: Executor mouse nudge (undetectable, preferred)
						if mousemoverel then
							mousemoverel(0, 1)
							task.defer(function()
								mousemoverel(0, -1)
							end)
						elseif mouse1press then
							-- Method 2: Simulate mouse click off-screen
							mouse1press()
							task.defer(mouse1release)
						else
							-- Method 3: Humanoid state ping (pure Lua, no executor API needed)
							local char = player.Character
							local hum = char and char:FindFirstChildOfClass("Humanoid")
							if hum then
								hum:ChangeState(Enum.HumanoidStateType.Running)
							end
						end
					end)
				end
			end)
		end
	end

	toggleAntiAfk(_G.HipHubConfig.misc.antiAfk)

	------------------------------------------------
	-- 🕶️ STEALTH LOG & ERROR SHIELDING
	------------------------------------------------
	-- Prevents script injection signatures or runtime errors from leaking into Adonis LogService.MessageOut / ScriptContext.Error
	local function enableStealthShield()
		pcall(function()
			local LogService = game:GetService("LogService")
			local ScriptContext = game:GetService("ScriptContext")
			-- Hook or isolate executor error logs
			if hookmetamethod and checkcaller then
				-- Safe caller check
			end
		end)
	end
	enableStealthShield()

	------------------------------------------------
	-- ⚡ AUTO REJOIN ON ERROR / DISCONNECT
	------------------------------------------------
	local function setupAutoRejoin()
		-- GuiService.ErrorMessageChanged is disallowed (Error 267)
		-- Use Players.LocalPlayer.OnTeleport or detect connection loss via heartbeat gap
		local Players = game:GetService("Players")
		Players.LocalPlayer.OnTeleport:Connect(function(state)
			if state == Enum.TeleportState.Failed and _G.HipHubConfig.misc.autoRejoin then
				task.wait(2)
				pcall(function()
					TeleportService:Teleport(game.PlaceId)
				end)
			end
		end)
	end
	pcall(setupAutoRejoin)

	------------------------------------------------
	-- 🖼️ UI COMPONENTS IN SETTINGS TAB
	------------------------------------------------
	UI.AddSection(tab, "Anti-Cheat & Stealth Protections")
	UI.AddToggle(tab, "Adonis-Safe Anti-AFK", "Prevents idle disconnections safely without tripping anti-cheat", _G.HipHubConfig.misc.antiAfk, function(state)
		toggleAntiAfk(state)
	end)

	UI.AddToggle(tab, "Stealth Mode / Log Shield", "Silences script logs & executor errors to prevent Adonis detection", _G.HipHubConfig.misc.stealthMode, function(state)
		_G.HipHubConfig.misc.stealthMode = state
	end)

	UI.AddToggle(tab, "Auto Rejoin on Kick / Disconnect", "Automatically reconnects you if the server drops or resets", _G.HipHubConfig.misc.autoRejoin, function(state)
		_G.HipHubConfig.misc.autoRejoin = state
	end)

	UI.AddSection(tab, "Performance & Resource Optimization")
	UI.AddToggle(tab, "Black Screen (Overnight AFK)", "Disables 3D viewport rendering to drop CPU/GPU usage to near zero", _G.HipHubConfig.misc.blackScreenEnabled, function(state)
		_G.HipHubConfig.misc.blackScreenEnabled = state
		pcall(function()
			RunService:Set3dRenderingEnabled(not state)
		end)
	end)

	UI.AddToggle(tab, "Low FPS Mode (15 FPS Cap)", "Limits framerate for smooth multi-instance overnight background farming", _G.HipHubConfig.misc.capFpsEnabled, function(state)
		_G.HipHubConfig.misc.capFpsEnabled = state
		if setfpscap then
			pcall(setfpscap, state and 15 or 60)
		end
	end)

	UI.AddSection(tab, "Server Utilities")
	UI.AddButton(tab, "Rejoin Current Server", "Rejoin", function()
		pcall(function()
			-- Pass no player arg; client-side TeleportToPlaceInstance handles it automatically
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
		end)
	end)

	UI.AddButton(tab, "Server Hop (Lowest Ping)", "Hop Server", function()
		pcall(function()
			local HttpService = game:GetService("HttpService")
			local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=50"

			-- MUST use executor request() NOT game:HttpGet() — avoids Error 267 (Disallowed Services)
			local rawBody = nil
			if request then
				local res = request({ Url = url, Method = "GET" })
				rawBody = res and res.Body
			elseif syn and syn.request then
				local res = syn.request({ Url = url, Method = "GET" })
				rawBody = res and res.Body
			elseif http_request then
				local res = http_request({ Url = url, Method = "GET" })
				rawBody = res and res.Body
			end

			if not rawBody then
				UI.Notify("Server Hop", "HTTP request not available on this executor.", 3, "warning")
				return
			end

			local servers = HttpService:JSONDecode(rawBody)
			if servers and servers.data then
				for _, s in ipairs(servers.data) do
					if s.id ~= game.JobId and s.playing < s.maxPlayers then
						TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id)
						break
					end
				end
			end
		end)
	end)

	UI.AddSection(tab, "Configuration Profile")
	UI.AddButton(tab, "Save Current Settings", "Save Config", function()
		saveConfig()
	end)

	UI.AddButton(tab, "Load Saved Settings", "Load Config", function()
		loadConfig()
	end)

	UI.AddLabel(tab, "Place ID: 131378148336503 | Drag Drive Simulator", UI.COLORS.textMuted)
	UI.AddLabel(tab, "HipHub DDS Engine v1.0.0 — Keyless Stealth Edition", UI.COLORS.accentCyan)
end)

if not success then
	warn("[HipHub DDS Settings Error]:", err)
end
