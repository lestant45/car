-- ⚙️ HipHub BXI — Settings, Configuration Persistence & Discord Webhooks
-- Bus X Indonesia (Place ID: 137806249434874)

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

	local CONFIG_PATH = "HipHub/bxi_config.json"
	local DEFAULT_CONFIG = {
		main = {
			walkSpeed = 16,
			jumpPower = 50,
			flySpeed = 60,
			noclip = false,
			infiniteStamina = false,
			antiAfk = true,
			hideNametag = false
		},
		farm = {
			autoBusJob = false,
			selectedRoute = "Baranangsiang_ke_Rambutan",
			targetSpeed = 95,
			arriveDelay = 65,
			jobCooldown = 3,
			autoNextJob = true,
			autoRespawnLoop = true,
			autoClaimQuests = true,
			autoSpinBox = false,
			selectedBox = "Event",
			targetEarn = 0
		},
		vehicle = {
			speedMultiplier = 1.0,
			instantBrake = true,
			antiFlip = true,
			vehicleFly = false,
			flySpeed = 80
		},
		visuals = {
			checkpointEsp = true,
			terminalEsp = true,
			playerEsp = false,
			vehicleEsp = false,
			fullBright = false,
			customFov = 70,
			speedometerHud = true
		},
		misc = {
			webhookUrl = "",
			webhookEnabled = false,
			webhookJobComplete = true,
			webhookQuestClaim = true,
			webhookSpinReward = true,
			blackScreen = false,
			capFps = false,
			targetFps = 30,
			autoRejoin = true
		}
	}

	_G.HipHubConfig = _G.HipHubConfig or DEFAULT_CONFIG

	------------------------------------------------
	-- 💾 CONFIG PERSISTENCE (SAVE & LOAD)
	------------------------------------------------
	local function saveConfig(silent)
		if not writefile then return end
		pcall(function()
			if not isfolder or not isfolder("HipHub") then
				if makefolder then makefolder("HipHub") end
			end
			local encoded = HttpService:JSONEncode(_G.HipHubConfig)
			writefile(CONFIG_PATH, encoded)
			if not silent then
				UI.Notify("Config Saved", "Your settings have been saved successfully.", 2, "success")
			end
		end)
	end
	_G.HipHubSaveConfig = saveConfig

	local function loadConfig(silent)
		if not readfile then return end
		pcall(function()
			if isfile and isfile(CONFIG_PATH) then
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
					if not silent then
						UI.Notify("Config Loaded", "Loaded previous config successfully.", 2, "success")
					end
				end
			end
		end)
	end
	_G.HipHubLoadConfig = loadConfig

	loadConfig(true)

	------------------------------------------------
	-- 📡 DISCORD WEBHOOK INTEGRATION
	------------------------------------------------
	local function sendWebhook(title, description, fields, color)
		local config = _G.HipHubConfig.misc
		if not config.webhookEnabled or config.webhookUrl == "" then return end

		local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
		if not req then return end

		task.spawn(function()
			pcall(function()
				local embed = {
					title = title or "🚌 HipHub BXI Notification",
					description = description or "",
					color = color or 0x00DCFF,
					fields = fields or {},
					footer = {
						text = "HipHub BXI • " .. os.date("%Y-%m-%d %H:%M:%S")
					}
				}

				local payload = HttpService:JSONEncode({
					username = "HipHub BXI Bot",
					avatar_url = "https://cdn.discordapp.com/emojis/1102927237890199653.webp",
					embeds = { embed }
				})

				req({
					Url = config.webhookUrl,
					Method = "POST",
					Headers = { ["Content-Type"] = "application/json" },
					Body = payload
				})
			end)
		end)
	end
	_G.HipHubSendWebhook = sendWebhook

	------------------------------------------------
	-- ⚙️ SETTINGS UI BUILDER
	------------------------------------------------

	-- 1. Configuration Section
	UI.AddSection(tab, "Profile & Config Manager")

	UI.AddButton(tab, "💾 Save Configuration Now", function()
		saveConfig(false)
	end, "success")

	UI.AddButton(tab, "📂 Reload Configuration", function()
		loadConfig(false)
	end, "cyan")

	UI.AddButton(tab, "🔄 Reset to Factory Defaults", function()
		_G.HipHubConfig = DEFAULT_CONFIG
		saveConfig(true)
		UI.Notify("Defaults Restored", "Settings reset to default values.", 2, "warning")
	end, "danger")

	-- 2. Discord Webhook Section
	UI.AddSection(tab, "Discord Webhook Logging")

	local webhookToggle = UI.AddToggle(tab, "Enable Discord Webhook", _G.HipHubConfig.misc.webhookEnabled, function(state)
		_G.HipHubConfig.misc.webhookEnabled = state
		saveConfig(true)
	end)

	UI.AddTextbox(tab, "Webhook URL", "Paste Discord Webhook URL here...", _G.HipHubConfig.misc.webhookUrl, function(text)
		_G.HipHubConfig.misc.webhookUrl = text
		saveConfig(true)
		UI.Notify("Webhook Updated", "Webhook URL saved.", 2, "success")
	end)

	UI.AddToggle(tab, "Notify on Bus Route Completed", _G.HipHubConfig.misc.webhookJobComplete, function(state)
		_G.HipHubConfig.misc.webhookJobComplete = state
		saveConfig(true)
	end)

	UI.AddToggle(tab, "Notify on Quest Reward Claimed", _G.HipHubConfig.misc.webhookQuestClaim, function(state)
		_G.HipHubConfig.misc.webhookQuestClaim = state
		saveConfig(true)
	end)

	UI.AddToggle(tab, "Notify on Spin Box Rewards", _G.HipHubConfig.misc.webhookSpinReward, function(state)
		_G.HipHubConfig.misc.webhookSpinReward = state
		saveConfig(true)
	end)

	UI.AddButton(tab, "🧪 Test Discord Webhook", function()
		sendWebhook("🧪 Test Webhook Delivery", "Your Discord Webhook is configured properly and active!", {
			{ name = "Player", value = player.Name .. " (" .. player.DisplayName .. ")", inline = true },
			{ name = "Game", value = "Bus X Indonesia (Jawa Barat)", inline = true },
			{ name = "Status", value = "✅ Online & Operational", inline = false }
		}, 0x00E68C)
		UI.Notify("Test Webhook", "Sent test embed to Discord.", 2, "success")
	end, "cyan")

	-- 3. Optimization & Anti-AFK Section
	UI.AddSection(tab, "Performance & Overnight AFK")

	UI.AddToggle(tab, "Anti-AFK Protection (No 20m Kick)", _G.HipHubConfig.main.antiAfk, function(state)
		_G.HipHubConfig.main.antiAfk = state
		saveConfig(true)
	end)

	UI.AddToggle(tab, "Auto Reconnect on Disconnect", _G.HipHubConfig.misc.autoRejoin, function(state)
		_G.HipHubConfig.misc.autoRejoin = state
		saveConfig(true)
	end)

	-- Black Screen GPU Saver
	local blackScreenFrame = nil
	local function toggleBlackScreen(state)
		_G.HipHubConfig.misc.blackScreen = state
		saveConfig(true)

		if state then
			if not blackScreenFrame then
				blackScreenFrame = Instance.new("Frame")
				blackScreenFrame.Name = "HipHub_GPU_Saver"
				blackScreenFrame.Size = UDim2.new(1, 0, 1, 0)
				blackScreenFrame.Position = UDim2.new(0, 0, 0, 0)
				blackScreenFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				blackScreenFrame.ZIndex = 999990
				blackScreenFrame.Parent = UI.gui

				local msg = Instance.new("TextLabel")
				msg.Size = UDim2.new(1, 0, 0, 60)
				msg.Position = UDim2.new(0, 0, 0.5, -30)
				msg.BackgroundTransparency = 1
				msg.Text = "🌙 HipHub BXI GPU Saver Active\nPress [Right Shift] to toggle UI."
				msg.TextColor3 = Color3.fromRGB(0, 220, 255)
				msg.Font = Enum.Font.GothamBold
				msg.TextSize = 18
				msg.ZIndex = 999991
				msg.Parent = blackScreenFrame
			end
			blackScreenFrame.Visible = true
		else
			if blackScreenFrame then
				blackScreenFrame.Visible = false
			end
		end
	end

	UI.AddToggle(tab, "Black Screen Mode (Save GPU during Farm)", _G.HipHubConfig.misc.blackScreen, function(state)
		toggleBlackScreen(state)
	end)

	UI.AddToggle(tab, "Cap FPS (Lower CPU/GPU load)", _G.HipHubConfig.misc.capFps, function(state)
		_G.HipHubConfig.misc.capFps = state
		saveConfig(true)
		if setfpscap then
			setfpscap(state and _G.HipHubConfig.misc.targetFps or 60)
		end
	end)

	UI.AddSlider(tab, "Target FPS Cap", 10, 60, _G.HipHubConfig.misc.targetFps, function(val)
		_G.HipHubConfig.misc.targetFps = math.floor(val)
		saveConfig(true)
		if _G.HipHubConfig.misc.capFps and setfpscap then
			setfpscap(math.floor(val))
		end
	end, "FPS")

	-- 4. Server Management
	UI.AddSection(tab, "Server Utilities")

	UI.AddButton(tab, "🔄 Rejoin Same Server", function()
		UI.Notify("Rejoining", "Rejoining the current server...", 3, "warning")
		task.wait(0.5)
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
	end, "warning")

	UI.AddButton(tab, "🌐 Server Hop (Find New Server)", function()
		UI.Notify("Server Hop", "Searching for available public server...", 3, "cyan")
		task.spawn(function()
			pcall(function()
				local Http = game:GetService("HttpService")
				local servers = Http:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
				if servers and servers.data then
					for _, s in ipairs(servers.data) do
						if s.playing and s.playing < s.maxPlayers and s.id ~= game.JobId then
							TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, player)
							return
						end
					end
				end
				TeleportService:Teleport(game.PlaceId, player)
			end)
		end)
	end, "cyan")
end)

if not success then
	warn("[HipHub BXI Settings Error]:", err)
end
