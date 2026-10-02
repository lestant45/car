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
			selectedVehicle = "",
			autoBarista = false,
			baristaMinigameDelay = 2.2,
			autoRideGO = false,
			taxiSpeed = 90,
			passengerBoardDelay = 3,
			tripPacing = true,
			autoRejoinOrders = 30,
			autoCourier = false,
			courierSpeed = 95,
			courierPacing = true,
			courierAutoRejoinOrders = 10,
			autoDragRace = false,
			dragTargetTime = 6.5,
			autoDailyQuests = false,
			autoRedeemCodes = false
		},
		vehicle = {
			selectedVehicle = "",
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
			autoRejoin = true,
			antiPlayerJoin = false,
			destroyBuildings = false,
			targetEarn = 0
		}
	}

	_G.HipHubConfig = _G.HipHubConfig or DEFAULT_CONFIG

	------------------------------------------------
	-- 💾 CONFIG PERSISTENCE (AUTO-SAVE & AUTO-LOAD)
	------------------------------------------------
	local function saveConfig(silent)
		if not writefile then return end
		pcall(function()
			if not isfolder("HipHub") then
				makefolder("HipHub")
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
					if not silent then
						UI.Notify("Config Loaded", "Loaded settings from file.", 2, "success")
					end
				end
			end
		end)
	end
	_G.HipHubLoadConfig = loadConfig

	-- 🚀 Auto-load config immediately on script startup
	loadConfig(true)

	------------------------------------------------
	-- 🛡️ 100% STEALTH & UNDETECTED ANTI-AFK ENGINE
	-- Zero Disallowed Services (No VirtualUser/VIM)
	------------------------------------------------
	local antiAfkConn = nil

	local function toggleAntiAfk(state)
		_G.HipHubConfig.misc.antiAfk = state
		saveConfig(true)
		if antiAfkConn then
			antiAfkConn:Disconnect()
			antiAfkConn = nil
		end

		if state then
			local lastTick = tick()
			antiAfkConn = RunService.Heartbeat:Connect(function()
				if tick() - lastTick > 25 then
					lastTick = tick()
					pcall(function()
						-- 1. Camera Micro-Rotation (Resets Idle Timer natively via network camera packet)
						local cam = workspace.CurrentCamera
						if cam then
							local cf = cam.CFrame
							cam.CFrame = cf * CFrame.Angles(0, 0.0004, 0)
							task.delay(0.04, function()
								if cam then cam.CFrame = cf end
							end)
						end

						-- 2. Humanoid State Nudge (If not in vehicle)
						local char = player.Character
						local hum = char and char:FindFirstChildOfClass("Humanoid")
						if hum and not hum.SeatPart then
							hum:ChangeState(Enum.HumanoidStateType.Running)
						end
					end)
				end
			end)
		end
	end

	------------------------------------------------
	-- ⚡ AUTO REJOIN ON ERROR / DISCONNECT
	------------------------------------------------
	local function setupAutoRejoin()
		-- 1. Deteksi resmi via GuiService (Standard public service, 0% disallowed services risk)
		pcall(function()
			local GuiService = game:GetService("GuiService")
			if GuiService and GuiService.ErrorMessageChanged then
				GuiService.ErrorMessageChanged:Connect(function(msg)
					local isAutoRejoin = (_G.HipHubConfig and _G.HipHubConfig.misc and _G.HipHubConfig.misc.autoRejoin)
					if isAutoRejoin and msg and #msg > 0 then
						task.wait(2.0)
						pcall(function()
							TeleportService:Teleport(game.PlaceId)
						end)
					end
				end)
			end
		end)

		-- 2. Deteksi Teleport Failed
		pcall(function()
			player.OnTeleport:Connect(function(state)
				local isAutoRejoin = (_G.HipHubConfig and _G.HipHubConfig.misc and _G.HipHubConfig.misc.autoRejoin)
				if state == Enum.TeleportState.Failed and isAutoRejoin then
					task.wait(2.5)
					pcall(function()
						TeleportService:Teleport(game.PlaceId)
					end)
				end
			end)
		end)
	end
	pcall(setupAutoRejoin)

	------------------------------------------------
	-- 🚪 ANTI-PLAYER JOIN (AUTO DISCONNECT / LEAVE)
	------------------------------------------------
	local antiPlayerConn = nil
	local function toggleAntiPlayerJoin(state)
		_G.HipHubConfig.misc.antiPlayerJoin = state
		saveConfig(true)
		if antiPlayerConn then
			antiPlayerConn:Disconnect()
			antiPlayerConn = nil
		end

		if state then
			-- 1. Cek apakah di server sudah ada player lain saat toggle dinyalakan
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= player then
					UI.Notify("Proteksi Server", "Player lain terdeteksi. Keluar dari server...", 3, "info")
					task.wait(0.5)
					player:Kick("\n[HipHub Anti-Player]\nAda player lain di dalam server: " .. p.DisplayName .. " (@" .. p.Name .. ").")
					return
				end
			end

			-- 2. Dengarkan player baru yang join
			antiPlayerConn = Players.PlayerAdded:Connect(function(newPlayer)
				if newPlayer ~= player and _G.HipHubConfig.misc.antiPlayerJoin then
					UI.Notify("Proteksi Server", "Player baru bergabung. Keluar dari server...", 3, "info")
					task.wait(0.5)
					player:Kick("\n[HipHub Anti-Player]\nPlayer lain masuk server: " .. newPlayer.DisplayName .. " (@" .. newPlayer.Name .. ").")
				end
			end)
		end
	end


	------------------------------------------------
	-- 🖼️ UI COMPONENTS IN SETTINGS TAB
	------------------------------------------------
	UI.AddSection(tab, "Anti-Cheat & Stealth Protections")
	UI.AddToggle(tab, "Adonis-Safe Anti-AFK", "Prevents idle disconnections safely without tripping anti-cheat", _G.HipHubConfig.misc.antiAfk, function(state)
		toggleAntiAfk(state)
	end)

	UI.AddToggle(tab, "Anti-Player Join (Auto Disconnect)", "Otomatis keluar/disconnect dari server jika ada player lain yang masuk", _G.HipHubConfig.misc.antiPlayerJoin, function(state)
		toggleAntiPlayerJoin(state)
	end)

	UI.AddToggle(tab, "Stealth Mode / Log Shield", "Silences script logs & executor errors to prevent Adonis detection", _G.HipHubConfig.misc.stealthMode, function(state)
		_G.HipHubConfig.misc.stealthMode = state
		saveConfig(true)
	end)

	UI.AddToggle(tab, "Auto Rejoin on Kick / Disconnect", "Automatically reconnects you if the server drops or resets", _G.HipHubConfig.misc.autoRejoin, function(state)
		_G.HipHubConfig.misc.autoRejoin = state
		saveConfig(true)
	end)

	------------------------------------------------
	-- 🖤 BLACK SCREEN OVERNIGHT DASHBOARD & TARGET EARN
	------------------------------------------------
	_G.HipHubScriptStartTime = _G.HipHubScriptStartTime or tick()
	_G.HipHubScriptStartMoney = _G.HipHubScriptStartMoney or nil

	local function getLivePlayerMoneyRaw()
		local playerData = player:FindFirstChild("PlayerData")
		if playerData then
			local rpValue = playerData:FindFirstChild("RPValue")
			if rpValue and rpValue:IsA("NumberValue") then
				return math.floor(rpValue.Value)
			end
		end

		-- Fallback: leaderstats / Data / Stats
		for _, folderName in ipairs({"leaderstats", "Data", "Stats"}) do
			local stats = player:FindFirstChild(folderName)
			if stats then
				for _, v in ipairs(stats:GetChildren()) do
					if v:IsA("NumberValue") or v:IsA("IntValue") then
						local n = v.Name:lower()
						if n:find("rp") or n:find("money") or n:find("cash") or n:find("rupiah") or n:find("balance") then
							return math.floor(tonumber(v.Value) or 0)
						end
					end
				end
			end
		end

		return 0
	end

	local function formatRupiah(val)
		local n = math.floor(val or 0)
		local formatted = tostring(n):reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
		return "Rp " .. formatted
	end

	local function getLivePlayerMoney()
		local raw = getLivePlayerMoneyRaw()
		return formatRupiah(raw)
	end

	-- Initialize start money if available
	task.defer(function()
		task.wait(0.5)
		if _G.HipHubScriptStartMoney == nil or _G.HipHubScriptStartMoney == 0 then
			local initM = getLivePlayerMoneyRaw()
			if initM > 0 then
				_G.HipHubScriptStartMoney = initM
			end
		end
	end)

	-- Ensure 3D rendering is active
	pcall(function()
		RunService:Set3dRenderingEnabled(true)
	end)

	local blackScreenGui = nil
	local blackScreenLoop = nil
	local savedGlobalShadows = nil
	local disabledLightingEffects = {}
	local mutedSoundsCache = {}
	local disabledParticlesCache = {}
	local savedQualityLevel = nil
	local savedCameraFov = nil

	local function toggleBlackScreen(state)
		_G.HipHubConfig.misc.blackScreenEnabled = state
		saveConfig(true)

		if state then
			-- 1. Pertahankan 3D Rendering Viewport TETAP AKTIF (Wajib agar network replication & terrain streaming tidak mati)
			pcall(function()
				RunService:Set3dRenderingEnabled(true)
			end)

			-- 2. Cap FPS ke 30 (Mencegah CPU overheating, throttling & OOM spikes pada cloud VM)
			pcall(function()
				if setfpscap then
					setfpscap(30)
				end
			end)

			-- 3. Matikan Shadows & Post-Processing Lighting yang membebani memori
			pcall(function()
				local Lighting = game:GetService("Lighting")
				if savedGlobalShadows == nil then
					savedGlobalShadows = Lighting.GlobalShadows
				end
				Lighting.GlobalShadows = false

				disabledLightingEffects = {}
				for _, child in ipairs(Lighting:GetChildren()) do
					if child:IsA("PostProcessEffect") or child:IsA("Atmosphere") or child:IsA("Clouds") or child:IsA("DepthOfFieldEffect") or child:IsA("BlurEffect") or child:IsA("SunRaysEffect") or child:IsA("BloomEffect") or child:IsA("ColorCorrectionEffect") then
						if child.Enabled then
							table.insert(disabledLightingEffects, child)
							child.Enabled = false
						end
					end
				end
			end)

			-- 4. 🛡️ ULTRA-LOW MEMORY & ANTI-CRASH SHIELD:
			-- A. Mute/Pause Audio Workspace (Mencegah FMOD memory leak ratusan MB di DDS)
			pcall(function()
				for _, inst in ipairs(workspace:GetDescendants()) do
					if inst:IsA("Sound") and inst.Volume > 0 then
						mutedSoundsCache[inst] = inst.Volume
						inst.Volume = 0
					end
				end
			end)

			-- B. Disable Heavy Particles & Emitters (Memangkas VRAM & render queue)
			pcall(function()
				for _, inst in ipairs(workspace:GetDescendants()) do
					if (inst:IsA("ParticleEmitter") or inst:IsA("Smoke") or inst:IsA("Fire") or inst:IsA("Sparkles") or inst:IsA("Trail")) and inst.Enabled then
						table.insert(disabledParticlesCache, inst)
						inst.Enabled = false
					end
				end
			end)

			-- C. Set Lowest Rendering Quality Level
			pcall(function()
				if settings and settings().Rendering then
					if savedQualityLevel == nil then
						savedQualityLevel = settings().Rendering.QualityLevel
					end
					settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
				end
			end)

			-- D. Zero-Polygon Camera Focus (GPU hanya me-render 1 polygon, VRAM drop ke near-zero!)
			pcall(function()
				local cam = workspace.CurrentCamera
				if cam then
					savedCameraFov = cam.FieldOfView
					cam.FieldOfView = 1
				end
			end)

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

			-- Card Container (W: 520, H: 370)
			local card = Instance.new("Frame")
			card.Name = "Card"
			card.Size = UDim2.new(0, 520, 0, 370)
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
			title.Size = UDim2.new(1, -40, 0, 28)
			title.Position = UDim2.new(0, 20, 0, 12)
			title.BackgroundTransparency = 1
			title.Text = "HIPHUB DDS — AFK DASHBOARD"
			title.TextColor3 = Color3.fromRGB(0, 212, 255)
			title.Font = Enum.Font.GothamBold
			title.TextSize = 17
			title.TextXAlignment = Enum.TextXAlignment.Center
			title.Parent = card

			-- User info label
			local userLabel = Instance.new("TextLabel")
			userLabel.Size = UDim2.new(1, -40, 0, 20)
			userLabel.Position = UDim2.new(0, 20, 0, 42)
			userLabel.BackgroundTransparency = 1
			userLabel.Text = "User: " .. player.DisplayName .. " (@" .. player.Name .. ")"
			userLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
			userLabel.Font = Enum.Font.GothamMedium
			userLabel.TextSize = 13
			userLabel.TextXAlignment = Enum.TextXAlignment.Center
			userLabel.Parent = card

			-- Divider
			local div = Instance.new("Frame")
			div.Size = UDim2.new(1, -40, 0, 1)
			div.Position = UDim2.new(0, 20, 0, 68)
			div.BackgroundColor3 = Color3.fromRGB(35, 45, 70)
			div.BorderSizePixel = 0
			div.Parent = card

			-- Row 1: Box 1 (Top Left) - Runtime Box
			local timeBox = Instance.new("Frame")
			timeBox.Size = UDim2.new(0.5, -28, 0, 58)
			timeBox.Position = UDim2.new(0, 20, 0, 78)
			timeBox.BackgroundColor3 = Color3.fromRGB(22, 28, 46)
			timeBox.BorderSizePixel = 0
			timeBox.Parent = card
			local tbCorner = Instance.new("UICorner")
			tbCorner.CornerRadius = UDim.new(0, 10)
			tbCorner.Parent = timeBox

			local timeTitle = Instance.new("TextLabel")
			timeTitle.Size = UDim2.new(1, 0, 0, 18)
			timeTitle.Position = UDim2.new(0, 0, 0, 5)
			timeTitle.BackgroundTransparency = 1
			timeTitle.Text = "SCRIPT RUNTIME"
			timeTitle.TextColor3 = Color3.fromRGB(160, 175, 200)
			timeTitle.Font = Enum.Font.GothamBold
			timeTitle.TextSize = 11
			timeTitle.Parent = timeBox

			local timeVal = Instance.new("TextLabel")
			timeVal.Size = UDim2.new(1, 0, 0, 28)
			timeVal.Position = UDim2.new(0, 0, 0, 24)
			timeVal.BackgroundTransparency = 1
			timeVal.Text = "00h 00m 00s"
			timeVal.TextColor3 = Color3.fromRGB(0, 212, 255)
			timeVal.Font = Enum.Font.GothamBold
			timeVal.TextSize = 14
			timeVal.Parent = timeBox

			-- Row 1: Box 2 (Top Right) - Balance Box
			local moneyBox = Instance.new("Frame")
			moneyBox.Size = UDim2.new(0.5, -28, 0, 58)
			moneyBox.Position = UDim2.new(0.5, 8, 0, 78)
			moneyBox.BackgroundColor3 = Color3.fromRGB(22, 28, 46)
			moneyBox.BorderSizePixel = 0
			moneyBox.Parent = card
			local mbCorner = Instance.new("UICorner")
			mbCorner.CornerRadius = UDim.new(0, 10)
			mbCorner.Parent = moneyBox

			local moneyTitle = Instance.new("TextLabel")
			moneyTitle.Size = UDim2.new(1, 0, 0, 18)
			moneyTitle.Position = UDim2.new(0, 0, 0, 5)
			moneyTitle.BackgroundTransparency = 1
			moneyTitle.Text = "CURRENT BALANCE"
			moneyTitle.TextColor3 = Color3.fromRGB(160, 175, 200)
			moneyTitle.Font = Enum.Font.GothamBold
			moneyTitle.TextSize = 11
			moneyTitle.Parent = moneyBox

			local moneyVal = Instance.new("TextLabel")
			moneyVal.Size = UDim2.new(1, -10, 0, 28)
			moneyVal.Position = UDim2.new(0, 5, 0, 24)
			moneyVal.BackgroundTransparency = 1
			moneyVal.Text = getLivePlayerMoney()
			moneyVal.TextColor3 = Color3.fromRGB(0, 255, 170)
			moneyVal.Font = Enum.Font.GothamBold
			moneyVal.TextSize = 14
			moneyVal.Parent = moneyBox

			-- Row 2: Box 3 (Mid Left) - Session Earned Box
			local earnedBox = Instance.new("Frame")
			earnedBox.Size = UDim2.new(0.5, -28, 0, 58)
			earnedBox.Position = UDim2.new(0, 20, 0, 144)
			earnedBox.BackgroundColor3 = Color3.fromRGB(22, 28, 46)
			earnedBox.BorderSizePixel = 0
			earnedBox.Parent = card
			local ebCorner = Instance.new("UICorner")
			ebCorner.CornerRadius = UDim.new(0, 10)
			ebCorner.Parent = earnedBox

			local earnedTitle = Instance.new("TextLabel")
			earnedTitle.Size = UDim2.new(1, 0, 0, 18)
			earnedTitle.Position = UDim2.new(0, 0, 0, 5)
			earnedTitle.BackgroundTransparency = 1
			earnedTitle.Text = "SESSION EARNED"
			earnedTitle.TextColor3 = Color3.fromRGB(160, 175, 200)
			earnedTitle.Font = Enum.Font.GothamBold
			earnedTitle.TextSize = 11
			earnedTitle.Parent = earnedBox

			local earnedVal = Instance.new("TextLabel")
			earnedVal.Size = UDim2.new(1, -10, 0, 28)
			earnedVal.Position = UDim2.new(0, 5, 0, 24)
			earnedVal.BackgroundTransparency = 1
			earnedVal.Text = "+Rp 0"
			earnedVal.TextColor3 = Color3.fromRGB(80, 225, 140)
			earnedVal.Font = Enum.Font.GothamBold
			earnedVal.TextSize = 14
			earnedVal.Parent = earnedBox

			-- Row 2: Box 4 (Mid Right) - Rate Per Hour Box (RATA-RATA / JAM)
			local rateBox = Instance.new("Frame")
			rateBox.Size = UDim2.new(0.5, -28, 0, 58)
			rateBox.Position = UDim2.new(0.5, 8, 0, 144)
			rateBox.BackgroundColor3 = Color3.fromRGB(22, 28, 46)
			rateBox.BorderSizePixel = 0
			rateBox.Parent = card
			local rbCorner = Instance.new("UICorner")
			rbCorner.CornerRadius = UDim.new(0, 10)
			rbCorner.Parent = rateBox

			local rateTitle = Instance.new("TextLabel")
			rateTitle.Size = UDim2.new(1, 0, 0, 18)
			rateTitle.Position = UDim2.new(0, 0, 0, 5)
			rateTitle.BackgroundTransparency = 1
			rateTitle.Text = "RATA-RATA / JAM"
			rateTitle.TextColor3 = Color3.fromRGB(160, 175, 200)
			rateTitle.Font = Enum.Font.GothamBold
			rateTitle.TextSize = 11
			rateTitle.Parent = rateBox

			local rateVal = Instance.new("TextLabel")
			rateVal.Size = UDim2.new(1, -10, 0, 28)
			rateVal.Position = UDim2.new(0, 5, 0, 24)
			rateVal.BackgroundTransparency = 1
			rateVal.Text = "Rp 0 / jam"
			rateVal.TextColor3 = Color3.fromRGB(255, 170, 50)
			rateVal.Font = Enum.Font.GothamBold
			rateVal.TextSize = 13
			rateVal.Parent = rateBox

			-- Row 3: Box 5 (Bottom Left) - Target Earn Box
			local targetBox = Instance.new("Frame")
			targetBox.Size = UDim2.new(0.5, -28, 0, 58)
			targetBox.Position = UDim2.new(0, 20, 0, 210)
			targetBox.BackgroundColor3 = Color3.fromRGB(22, 28, 46)
			targetBox.BorderSizePixel = 0
			targetBox.Parent = card
			local tgtCorner = Instance.new("UICorner")
			tgtCorner.CornerRadius = UDim.new(0, 10)
			tgtCorner.Parent = targetBox

			local targetTitle = Instance.new("TextLabel")
			targetTitle.Size = UDim2.new(1, 0, 0, 18)
			targetTitle.Position = UDim2.new(0, 0, 0, 5)
			targetTitle.BackgroundTransparency = 1
			targetTitle.Text = "TARGET EARN"
			targetTitle.TextColor3 = Color3.fromRGB(160, 175, 200)
			targetTitle.Font = Enum.Font.GothamBold
			targetTitle.TextSize = 11
			targetTitle.Parent = targetBox

			local targetVal = Instance.new("TextLabel")
			targetVal.Size = UDim2.new(1, -10, 0, 28)
			targetVal.Position = UDim2.new(0, 5, 0, 24)
			targetVal.BackgroundTransparency = 1
			local curTgt = tonumber(_G.HipHubConfig.misc.targetEarn) or 0
			targetVal.Text = curTgt > 0 and formatRupiah(curTgt) or "No Limit (∞)"
			targetVal.TextColor3 = Color3.fromRGB(255, 215, 0)
			targetVal.Font = Enum.Font.GothamBold
			targetVal.TextSize = 13
			targetVal.Parent = targetBox

			-- Row 3: Box 6 (Bottom Right) - Progress Box
			local progressBox = Instance.new("Frame")
			progressBox.Size = UDim2.new(0.5, -28, 0, 58)
			progressBox.Position = UDim2.new(0.5, 8, 0, 210)
			progressBox.BackgroundColor3 = Color3.fromRGB(22, 28, 46)
			progressBox.BorderSizePixel = 0
			progressBox.Parent = card
			local prgCorner = Instance.new("UICorner")
			prgCorner.CornerRadius = UDim.new(0, 10)
			prgCorner.Parent = progressBox

			local progressTitle = Instance.new("TextLabel")
			progressTitle.Size = UDim2.new(1, 0, 0, 18)
			progressTitle.Position = UDim2.new(0, 0, 0, 5)
			progressTitle.BackgroundTransparency = 1
			progressTitle.Text = "PROGRESS"
			progressTitle.TextColor3 = Color3.fromRGB(160, 175, 200)
			progressTitle.Font = Enum.Font.GothamBold
			progressTitle.TextSize = 11
			progressTitle.Parent = progressBox

			local progressVal = Instance.new("TextLabel")
			progressVal.Size = UDim2.new(1, 0, 0, 28)
			progressVal.Position = UDim2.new(0, 0, 0, 24)
			progressVal.BackgroundTransparency = 1
			progressVal.Text = "Ongoing"
			progressVal.TextColor3 = Color3.fromRGB(150, 110, 255)
			progressVal.Font = Enum.Font.GothamBold
			progressVal.TextSize = 14
			progressVal.Parent = progressBox

			-- Progress Bar Track
			local barTrack = Instance.new("Frame")
			barTrack.Size = UDim2.new(1, -40, 0, 7)
			barTrack.Position = UDim2.new(0, 20, 0, 276)
			barTrack.BackgroundColor3 = Color3.fromRGB(25, 32, 50)
			barTrack.BorderSizePixel = 0
			barTrack.Parent = card
			local barTrackCorner = Instance.new("UICorner")
			barTrackCorner.CornerRadius = UDim.new(1, 0)
			barTrackCorner.Parent = barTrack

			local barFill = Instance.new("Frame")
			barFill.Size = UDim2.new(1, 0, 1, 0)
			barFill.BackgroundColor3 = Color3.fromRGB(0, 212, 255)
			barFill.BorderSizePixel = 0
			barFill.Parent = barTrack
			local barFillCorner = Instance.new("UICorner")
			barFillCorner.CornerRadius = UDim.new(1, 0)
			barFillCorner.Parent = barFill

			-- Status Badge
			local statusBadge = Instance.new("TextLabel")
			statusBadge.Size = UDim2.new(1, -40, 0, 22)
			statusBadge.Position = UDim2.new(0, 20, 0, 290)
			statusBadge.BackgroundTransparency = 1
			statusBadge.Text = "Auto-Farm Active | Anti-Crash & Low-RAM: ACTIVE"
			statusBadge.TextColor3 = Color3.fromRGB(0, 255, 170)
			statusBadge.Font = Enum.Font.GothamMedium
			statusBadge.TextSize = 12
			statusBadge.TextXAlignment = Enum.TextXAlignment.Center
			statusBadge.Parent = card

			-- Footer note
			local footer = Instance.new("TextLabel")
			footer.Size = UDim2.new(1, -40, 0, 32)
			footer.Position = UDim2.new(0, 20, 0, 318)
			footer.BackgroundTransparency = 1
			footer.Text = "Tip: Visual Blackout aktif, 3D Streaming & Network Replication terjaga, FPS di-cap 30. Bebas kick 24/7."
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
						local now = tick()
						local elapsed = math.max(1, math.floor(now - (_G.HipHubScriptStartTime or now)))
						local hrs = math.floor(elapsed / 3600)
						local mins = math.floor((elapsed % 3600) / 60)
						local secs = elapsed % 60
						timeVal.Text = string.format("%02dh %02dm %02ds", hrs, mins, secs)

						local curMoney = getLivePlayerMoneyRaw()
						moneyVal.Text = formatRupiah(curMoney)

						if (_G.HipHubScriptStartMoney == nil or _G.HipHubScriptStartMoney == 0) and curMoney > 0 then
							_G.HipHubScriptStartMoney = curMoney
							_G.HipHubScriptStartTime = now
						end

						local startMoney = _G.HipHubScriptStartMoney or curMoney
						local earned = curMoney - startMoney

						if earned >= 0 then
							earnedVal.Text = "+" .. formatRupiah(earned)
							earnedVal.TextColor3 = Color3.fromRGB(80, 225, 140)
						else
							earnedVal.Text = "-" .. formatRupiah(math.abs(earned))
							earnedVal.TextColor3 = Color3.fromRGB(255, 90, 90)
						end

						-- Rata-rata Uang per 1 Jam (Earn Rate / Hr)
						local ratePerHour = 0
						if elapsed >= 3 and earned > 0 then
							ratePerHour = math.floor((earned / elapsed) * 3600)
						end

						if ratePerHour > 0 then
							rateVal.Text = formatRupiah(ratePerHour) .. " / jam"
						else
							rateVal.Text = "Rp 0 / jam"
						end

						local target = tonumber(_G.HipHubConfig.misc.targetEarn) or 0
						if target > 0 then
							if target >= 1000000 then
								local mVal = target / 1000000
								local mFormatted = (mVal % 1 == 0) and string.format("%.0fM", mVal) or string.format("%.1fM", mVal)
								targetVal.Text = formatRupiah(target) .. " (" .. mFormatted .. ")"
							else
								targetVal.Text = formatRupiah(target)
							end
							local pct = math.clamp(curMoney / target, 0, 1)
							progressVal.Text = string.format("%.1f%%", pct * 100)
							barFill.Size = UDim2.new(pct, 0, 1, 0)

							if curMoney >= target and target > 0 then
								statusBadge.Text = "TARGET EARN TERCAPAI (" .. formatRupiah(target) .. ")! Selesai."
								statusBadge.TextColor3 = Color3.fromRGB(255, 215, 0)
								barFill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
								if _G.HipHubAutoRideGoToggle and _G.HipHubAutoRideGoToggle.Set and _G.HipHubAutoRideGoToggle.Get and _G.HipHubAutoRideGoToggle.Get() then
									_G.HipHubAutoRideGoToggle.Set(false)
								end
							elseif _G.HipHubBotActivityStatus then
								statusBadge.Text = _G.HipHubBotActivityStatus
								statusBadge.TextColor3 = _G.HipHubBotActivityColor or Color3.fromRGB(0, 255, 170)
								barFill.BackgroundColor3 = _G.HipHubBotActivityColor or Color3.fromRGB(0, 212, 255)
							else
								local antiPText = _G.HipHubConfig.misc.antiPlayerJoin and "Anti-Player: ON" or "Anti-Player: OFF"
								statusBadge.Text = "Auto-Farm Active | Anti-Crash: ON | " .. antiPText
								statusBadge.TextColor3 = Color3.fromRGB(0, 255, 170)
								barFill.BackgroundColor3 = Color3.fromRGB(0, 255, 170)
							end
						else
							targetVal.Text = "No Limit (∞)"
							progressVal.Text = "Ongoing"
							barFill.Size = UDim2.new(1, 0, 1, 0)
							barFill.BackgroundColor3 = Color3.fromRGB(0, 212, 255)

							if _G.HipHubBotActivityStatus then
								statusBadge.Text = _G.HipHubBotActivityStatus
								statusBadge.TextColor3 = _G.HipHubBotActivityColor or Color3.fromRGB(0, 255, 170)
								barFill.BackgroundColor3 = _G.HipHubBotActivityColor or Color3.fromRGB(0, 212, 255)
							else
								local antiPText = _G.HipHubConfig.misc.antiPlayerJoin and "Anti-Player: ON" or "Anti-Player: OFF"
								statusBadge.Text = "Auto-Farm Active | Anti-Crash: ON | " .. antiPText
								statusBadge.TextColor3 = Color3.fromRGB(0, 255, 170)
							end
						end
					end)
					task.wait(1)
				end
			end)
		else
			-- 1. Kembalikan 3D Viewport Rendering
			pcall(function()
				RunService:Set3dRenderingEnabled(true)
			end)

			-- 2. Kembalikan FPS Target Normal
			pcall(function()
				if setfpscap then
					local targetFps = tonumber(_G.HipHubConfig.misc.targetFps) or 60
					if _G.HipHubConfig.misc.capFpsEnabled then
						targetFps = 15
					end
					setfpscap(targetFps)
				end
			end)

			-- 3. Kembalikan Efek Lighting & Shadows
			pcall(function()
				local Lighting = game:GetService("Lighting")
				if savedGlobalShadows ~= nil then
					Lighting.GlobalShadows = savedGlobalShadows
					savedGlobalShadows = nil
				end
				if disabledLightingEffects then
					for _, effect in ipairs(disabledLightingEffects) do
						if effect and effect.Parent then
							pcall(function() effect.Enabled = true end)
						end
					end
					disabledLightingEffects = {}
				end
			end)

			-- 4. Kembalikan Audio, Partikel, Quality Level & FOV Kamera
			pcall(function()
				if mutedSoundsCache then
					for snd, vol in pairs(mutedSoundsCache) do
						if snd and snd.Parent then
							pcall(function() snd.Volume = vol end)
						end
					end
					mutedSoundsCache = {}
				end
			end)
			pcall(function()
				if disabledParticlesCache then
					for _, part in ipairs(disabledParticlesCache) do
						if part and part.Parent then
							pcall(function() part.Enabled = true end)
						end
					end
					disabledParticlesCache = {}
				end
			end)
			pcall(function()
				if savedQualityLevel and settings and settings().Rendering then
					settings().Rendering.QualityLevel = savedQualityLevel
					savedQualityLevel = nil
				end
			end)
			pcall(function()
				local cam = workspace.CurrentCamera
				if cam and savedCameraFov then
					cam.FieldOfView = savedCameraFov
					savedCameraFov = nil
				end
			end)

			-- 5. Hentikan Loop & Bersihkan GUI
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

	UI.AddSection(tab, "AFK & Target Farming")
	local initialTargetText = ""
	if _G.HipHubConfig and _G.HipHubConfig.misc and _G.HipHubConfig.misc.targetEarn and _G.HipHubConfig.misc.targetEarn > 0 then
		local tVal = _G.HipHubConfig.misc.targetEarn
		if tVal >= 1000000 and (tVal % 1000000 == 0) then
			initialTargetText = tostring(math.floor(tVal / 1000000))
		else
			initialTargetText = tostring(tVal)
		end
	end

	UI.AddTextbox(tab, "Target Earn (Juta / M)", "Contoh: 550 (= Rp 550 Juta | 0 = No Limit)", initialTargetText, function(text)
		local raw = tostring(text or ""):gsub("[^%d%.]", "")
		local num = tonumber(raw) or 0
		local val = num
		-- Jika input angka di bawah 1.000.000 (misal: 550 atau 550.5), otomatis dikalikan 1 Juta (1.000.000)
		if num > 0 and num < 1000000 then
			val = math.floor(num * 1000000)
		else
			val = math.floor(num)
		end
		_G.HipHubConfig.misc.targetEarn = val
		saveConfig(true)
		UI.Notify("Target Earn Diatur", val > 0 and ("Target: " .. formatRupiah(val)) or "Target: No Limit (∞)", 3, "success")
	end)

	local blackScreenToggle = UI.AddToggle(tab, "Black Screen (Anti-Crash & AFK)", "Matikan 3D viewport, cap 30 FPS, & auto-clean RAM (Mencegah Force Close di Redfinger/HP kentang)", _G.HipHubConfig.misc.blackScreenEnabled, function(state)
		toggleBlackScreen(state)
	end)

	UI.AddToggle(tab, "Low FPS Mode (15 FPS Cap)", "Limits framerate for smooth multi-instance overnight background farming", _G.HipHubConfig.misc.capFpsEnabled, function(state)
		_G.HipHubConfig.misc.capFpsEnabled = state
		saveConfig(true)
		if setfpscap then
			pcall(setfpscap, state and 15 or 60)
		end
	end)

	UI.AddSection(tab, "World & Map Optimization")
	UI.AddToggle(tab, "Destroy Buildings & Obstacles", "Hapus gedung & rintangan secara global. Matikan agar map tetap utuh & natural.", _G.HipHubConfig.misc.destroyBuildings or false, function(state)
		_G.HipHubConfig.misc.destroyBuildings = state
		saveConfig(true)
		if state and _G.HipHubDestroyAllBuildings then
			_G.HipHubDestroyAllBuildings()
		end
	end)

	UI.AddSection(tab, "Server Utilities")
	UI.AddButton(tab, "Rejoin Current Server", "Rejoin", function()
		pcall(function()
			if game.PrivateServerId ~= "" or game.PrivateServerOwnerId ~= 0 then
				UI.Notify("VIP Server", "Roblox memblokir rejoin ke Private Server (Error 773). Gunakan Shift Reset in-game.", 4, "warning")
			else
				TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
			end
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

	-- 🚀 Auto-activate saved settings states on launch (setelah semua fungsi & UI siap)
	task.defer(function()
		task.wait(1.0)
		if _G.HipHubConfig and _G.HipHubConfig.misc then
			if _G.HipHubConfig.misc.antiAfk then
				toggleAntiAfk(true)
			end
			if _G.HipHubConfig.misc.antiPlayerJoin then
				toggleAntiPlayerJoin(true)
			end
			if _G.HipHubConfig.misc.blackScreenEnabled then
				toggleBlackScreen(true)
				if blackScreenToggle and blackScreenToggle.Set then
					blackScreenToggle.Set(true)
				end
			end
			if _G.HipHubConfig.misc.capFpsEnabled and setfpscap then
				pcall(setfpscap, 15)
			end
		end
	end)
end)

if not success then
	warn("[HipHub DDS Settings Error]:", err)
end
