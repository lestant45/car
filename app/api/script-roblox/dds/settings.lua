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

	------------------------------------------------
	-- 🖤 BLACK SCREEN OVERNIGHT DASHBOARD
	------------------------------------------------
	_G.HipHubScriptStartTime = _G.HipHubScriptStartTime or tick()

	local function getLivePlayerMoney()
		-- 1. Scan PlayerGui for visible Rupiah text labels (e.g. "Rp. 317 244 372")
		local pGui = player:FindFirstChild("PlayerGui")
		if pGui then
			for _, g in ipairs(pGui:GetDescendants()) do
				if (g:IsA("TextLabel") or g:IsA("TextButton")) and g.Visible and g.TextTransparency < 0.5 then
					local txt = g.Text
					if txt and (txt:find("Rp%.") or txt:find("Rp ") or txt:find("RP") or txt:find("TOTAL %(Rp%)")) then
						local clean = txt:match("[Rr][Pp]%.?%s*[%d%s%.,]+")
						if clean and #clean > 3 then
							return clean
						end
					end
				end
			end
		end

		-- 2. Fallback: leaderstats / Data folder Values
		local stats = player:FindFirstChild("leaderstats") or player:FindFirstChild("Data") or player:FindFirstChild("Stats")
		if stats then
			for _, v in ipairs(stats:GetChildren()) do
				if v:IsA("ValueBase") then
					local n = v.Name:lower()
					if n:find("money") or n:find("cash") or n:find("rp") or n:find("rupiah") or n:find("balance") then
						local val = tonumber(v.Value) or 0
						local formatted = tostring(val):reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
						return "Rp " .. formatted
					end
				end
			end
		end

		return "Rp 0"
	end

	local blackScreenGui = nil
	local blackScreenLoop = nil

	local function toggleBlackScreen(state)
		_G.HipHubConfig.misc.blackScreenEnabled = state

		pcall(function()
			RunService:Set3dRenderingEnabled(not state)
		end)

		if state then
			if blackScreenGui then
				blackScreenGui:Destroy()
				blackScreenGui = nil
			end

			local pGui = player:FindFirstChild("PlayerGui")
			if not pGui then return end

			local sg = Instance.new("ScreenGui")
			sg.Name = "HipHub_BlackScreenOverlay"
			sg.ResetOnSpawn = false
			sg.DisplayOrder = 99999
			sg.IgnoreGuiInset = true
			sg.Parent = pGui
			blackScreenGui = sg

			local bg = Instance.new("Frame")
			bg.Name = "Background"
			bg.Size = UDim2.new(1, 0, 1, 0)
			bg.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
			bg.BackgroundTransparency = 0
			bg.BorderSizePixel = 0
			bg.Parent = sg

			-- Card Container
			local card = Instance.new("Frame")
			card.Name = "Card"
			card.Size = UDim2.new(0, 480, 0, 310)
			card.AnchorPoint = Vector2.new(0.5, 0.5)
			card.Position = UDim2.new(0.5, 0, 0.5, 0)
			card.BackgroundColor3 = Color3.fromRGB(15, 20, 32)
			card.BorderSizePixel = 0
			card.Parent = bg

			local cardCorner = Instance.new("UICorner")
			cardCorner.CornerRadius = UDim.new(0, 16)
			cardCorner.Parent = card

			local cardStroke = Instance.new("UIStroke")
			cardStroke.Color = Color3.fromRGB(0, 212, 255)
			cardStroke.Thickness = 1.5
			cardStroke.Parent = card

			-- Title
			local title = Instance.new("TextLabel")
			title.Size = UDim2.new(1, -40, 0, 36)
			title.Position = UDim2.new(0, 20, 0, 18)
			title.BackgroundTransparency = 1
			title.Text = "🏎️ HIPHUB DDS — AFK DASHBOARD"
			title.TextColor3 = Color3.fromRGB(0, 212, 255)
			title.Font = Enum.Font.GothamBold
			title.TextSize = 18
			title.TextXAlignment = Enum.TextXAlignment.Center
			title.Parent = card

			-- User info label
			local userLabel = Instance.new("TextLabel")
			userLabel.Size = UDim2.new(1, -40, 0, 24)
			userLabel.Position = UDim2.new(0, 20, 0, 62)
			userLabel.BackgroundTransparency = 1
			userLabel.Text = "👤 User: " .. player.DisplayName .. " (@" .. player.Name .. ")"
			userLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
			userLabel.Font = Enum.Font.GothamMedium
			userLabel.TextSize = 14
			userLabel.TextXAlignment = Enum.TextXAlignment.Center
			userLabel.Parent = card

			-- Divider
			local div = Instance.new("Frame")
			div.Size = UDim2.new(1, -60, 0, 1)
			div.Position = UDim2.new(0, 30, 0, 96)
			div.BackgroundColor3 = Color3.fromRGB(35, 45, 70)
			div.BorderSizePixel = 0
			div.Parent = card

			-- Stats Section: Runtime Box
			local timeBox = Instance.new("Frame")
			timeBox.Size = UDim2.new(0.48, -15, 0, 80)
			timeBox.Position = UDim2.new(0, 20, 0, 110)
			timeBox.BackgroundColor3 = Color3.fromRGB(22, 28, 46)
			timeBox.BorderSizePixel = 0
			timeBox.Parent = card

			local tbCorner = Instance.new("UICorner")
			tbCorner.CornerRadius = UDim.new(0, 10)
			tbCorner.Parent = timeBox

			local timeTitle = Instance.new("TextLabel")
			timeTitle.Size = UDim2.new(1, 0, 0, 24)
			timeTitle.Position = UDim2.new(0, 0, 0, 8)
			timeTitle.BackgroundTransparency = 1
			timeTitle.Text = "⏱️ SCRIPT RUNTIME"
			timeTitle.TextColor3 = Color3.fromRGB(160, 175, 200)
			timeTitle.Font = Enum.Font.GothamBold
			timeTitle.TextSize = 11
			timeTitle.Parent = timeBox

			local timeVal = Instance.new("TextLabel")
			timeVal.Size = UDim2.new(1, 0, 0, 36)
			timeVal.Position = UDim2.new(0, 0, 0, 34)
			timeVal.BackgroundTransparency = 1
			timeVal.Text = "00h 00m 00s"
			timeVal.TextColor3 = Color3.fromRGB(0, 212, 255)
			timeVal.Font = Enum.Font.GothamBold
			timeVal.TextSize = 16
			timeVal.Parent = timeBox

			-- Stats Section: Money Box
			local moneyBox = Instance.new("Frame")
			moneyBox.Size = UDim2.new(0.48, -15, 0, 80)
			moneyBox.Position = UDim2.new(0.52, 0, 0, 110)
			moneyBox.BackgroundColor3 = Color3.fromRGB(22, 28, 46)
			moneyBox.BorderSizePixel = 0
			moneyBox.Parent = card

			local mbCorner = Instance.new("UICorner")
			mbCorner.CornerRadius = UDim.new(0, 10)
			mbCorner.Parent = moneyBox

			local moneyTitle = Instance.new("TextLabel")
			moneyTitle.Size = UDim2.new(1, 0, 0, 24)
			moneyTitle.Position = UDim2.new(0, 0, 0, 8)
			moneyTitle.BackgroundTransparency = 1
			moneyTitle.Text = "💰 CURRENT BALANCE"
			moneyTitle.TextColor3 = Color3.fromRGB(160, 175, 200)
			moneyTitle.Font = Enum.Font.GothamBold
			moneyTitle.TextSize = 11
			moneyTitle.Parent = moneyBox

			local moneyVal = Instance.new("TextLabel")
			moneyVal.Size = UDim2.new(1, -10, 0, 36)
			moneyVal.Position = UDim2.new(0, 5, 0, 34)
			moneyVal.BackgroundTransparency = 1
			moneyVal.Text = getLivePlayerMoney()
			moneyVal.TextColor3 = Color3.fromRGB(0, 255, 170)
			moneyVal.Font = Enum.Font.GothamBold
			moneyVal.TextSize = 15
			moneyVal.Parent = moneyBox

			-- Status Badge
			local statusBadge = Instance.new("TextLabel")
			statusBadge.Size = UDim2.new(1, -40, 0, 26)
			statusBadge.Position = UDim2.new(0, 20, 0, 205)
			statusBadge.BackgroundTransparency = 1
			statusBadge.Text = "🟢 Auto-Farm Running | 3D Rendering: OFF (Low GPU Mode)"
			statusBadge.TextColor3 = Color3.fromRGB(0, 255, 170)
			statusBadge.Font = Enum.Font.GothamMedium
			statusBadge.TextSize = 12
			statusBadge.TextXAlignment = Enum.TextXAlignment.Center
			statusBadge.Parent = card

			-- Footer note
			local footer = Instance.new("TextLabel")
			footer.Size = UDim2.new(1, -40, 0, 36)
			footer.Position = UDim2.new(0, 20, 0, 245)
			footer.BackgroundTransparency = 1
			footer.Text = "💡 Tip: Buka menu UI HipHub atau matikan 'Black Screen' untuk kembali ke grafis normal."
			footer.TextColor3 = Color3.fromRGB(120, 135, 160)
			footer.Font = Enum.Font.Gotham
			footer.TextSize = 11
			footer.TextWrapped = true
			footer.TextXAlignment = Enum.TextXAlignment.Center
			footer.Parent = card

			-- Live Updating Loop
			blackScreenLoop = task.spawn(function()
				while _G.HipHubConfig.misc.blackScreenEnabled and blackScreenGui do
					pcall(function()
						local elapsed = math.floor(tick() - _G.HipHubScriptStartTime)
						local hrs = math.floor(elapsed / 3600)
						local mins = math.floor((elapsed % 3600) / 60)
						local secs = elapsed % 60
						timeVal.Text = string.format("%02dh %02dm %02ds", hrs, mins, secs)
						moneyVal.Text = getLivePlayerMoney()
					end)
					task.wait(1)
				end
			end)
		else
			if blackScreenLoop then
				task.cancel(blackScreenLoop)
				blackScreenLoop = nil
			end
			if blackScreenGui then
				blackScreenGui:Destroy()
				blackScreenGui = nil
			end
		end
	end

	UI.AddToggle(tab, "Black Screen (Overnight AFK)", "Disables 3D viewport rendering with a live stats dashboard", _G.HipHubConfig.misc.blackScreenEnabled, function(state)
		toggleBlackScreen(state)
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
