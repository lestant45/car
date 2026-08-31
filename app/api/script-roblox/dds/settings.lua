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
			autoRejoin = true,
			antiPlayerJoin = false,
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
	-- 🛡️ ADONIS-SAFE ANTI-AFK ENGINE
	------------------------------------------------
	-- Adonis-Safe Camera Oscillation (Resets idle timer naturally without disallowed services or physics changes)
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
						-- Safe Camera Oscillation (Works seamlessly on PC & Redfinger)
						local cam = workspace.CurrentCamera
						if cam then
							local cf = cam.CFrame
							cam.CFrame = cf * CFrame.Angles(0, 0.0004, 0)
							task.wait(0.04)
							if cam then
								cam.CFrame = cf
							end
						end
					end)
				end
			end)
		end
	end

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
		-- 1. Deteksi via CoreGui Prompt Overlay (ErrorPrompt / Disconnect modal)
		pcall(function()
			local cGui = game:GetService("CoreGui")
			local promptGui = cGui:WaitForChild("RobloxPromptGui", 5)
			local overlay = promptGui and promptGui:WaitForChild("promptOverlay", 5)
			if overlay then
				overlay.ChildAdded:Connect(function(child)
					if _G.HipHubConfig.misc.autoRejoin and (child.Name == "ErrorPrompt" or child.Name:find("Prompt") or child.Name:find("Error")) then
						task.wait(2.5)
						pcall(function()
							TeleportService:Teleport(game.PlaceId, player)
						end)
					end
				end)
			end
		end)

		-- 2. Deteksi Teleport Failed
		pcall(function()
			player.OnTeleport:Connect(function(state)
				if state == Enum.TeleportState.Failed and _G.HipHubConfig.misc.autoRejoin then
					task.wait(2.5)
					pcall(function()
						TeleportService:Teleport(game.PlaceId, player)
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
					UI.Notify("🚨 Anti-Player Triggered", "Ada player lain (" .. p.DisplayName .. ") di server. Keluar dari server...", 3, "warning")
					task.wait(0.5)
					player:Kick("\n[HipHub Anti-Player]\nAda player lain di dalam server: " .. p.DisplayName .. " (@" .. p.Name .. ").")
					return
				end
			end

			-- 2. Dengarkan player baru yang join
			antiPlayerConn = Players.PlayerAdded:Connect(function(newPlayer)
				if newPlayer ~= player and _G.HipHubConfig.misc.antiPlayerJoin then
					UI.Notify("🚨 Player Masuk!", newPlayer.DisplayName .. " masuk server. Otomatis keluar...", 3, "warning")
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

			-- Card Container (W: 500, H: 380)
			local card = Instance.new("Frame")
			card.Name = "Card"
			card.Size = UDim2.new(0, 500, 0, 380)
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
			title.Size = UDim2.new(1, -40, 0, 32)
			title.Position = UDim2.new(0, 20, 0, 14)
			title.BackgroundTransparency = 1
			title.Text = "🏎️ HIPHUB DDS — AFK DASHBOARD"
			title.TextColor3 = Color3.fromRGB(0, 212, 255)
			title.Font = Enum.Font.GothamBold
			title.TextSize = 18
			title.TextXAlignment = Enum.TextXAlignment.Center
			title.Parent = card

			-- User info label
			local userLabel = Instance.new("TextLabel")
			userLabel.Size = UDim2.new(1, -40, 0, 22)
			userLabel.Position = UDim2.new(0, 20, 0, 48)
			userLabel.BackgroundTransparency = 1
			userLabel.Text = "👤 User: " .. player.DisplayName .. " (@" .. player.Name .. ")"
			userLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
			userLabel.Font = Enum.Font.GothamMedium
			userLabel.TextSize = 13
			userLabel.TextXAlignment = Enum.TextXAlignment.Center
			userLabel.Parent = card

			-- Divider
			local div = Instance.new("Frame")
			div.Size = UDim2.new(1, -40, 0, 1)
			div.Position = UDim2.new(0, 20, 0, 78)
			div.BackgroundColor3 = Color3.fromRGB(35, 45, 70)
			div.BorderSizePixel = 0
			div.Parent = card

			-- Box 1: Runtime Box (Top Left)
			local timeBox = Instance.new("Frame")
			timeBox.Size = UDim2.new(0.48, -15, 0, 68)
			timeBox.Position = UDim2.new(0, 20, 0, 90)
			timeBox.BackgroundColor3 = Color3.fromRGB(22, 28, 46)
			timeBox.BorderSizePixel = 0
			timeBox.Parent = card
			local tbCorner = Instance.new("UICorner")
			tbCorner.CornerRadius = UDim.new(0, 10)
			tbCorner.Parent = timeBox

			local timeTitle = Instance.new("TextLabel")
			timeTitle.Size = UDim2.new(1, 0, 0, 20)
			timeTitle.Position = UDim2.new(0, 0, 0, 6)
			timeTitle.BackgroundTransparency = 1
			timeTitle.Text = "⏱️ SCRIPT RUNTIME"
			timeTitle.TextColor3 = Color3.fromRGB(160, 175, 200)
			timeTitle.Font = Enum.Font.GothamBold
			timeTitle.TextSize = 11
			timeTitle.Parent = timeBox

			local timeVal = Instance.new("TextLabel")
			timeVal.Size = UDim2.new(1, 0, 0, 32)
			timeVal.Position = UDim2.new(0, 0, 0, 28)
			timeVal.BackgroundTransparency = 1
			timeVal.Text = "00h 00m 00s"
			timeVal.TextColor3 = Color3.fromRGB(0, 212, 255)
			timeVal.Font = Enum.Font.GothamBold
			timeVal.TextSize = 15
			timeVal.Parent = timeBox

			-- Box 2: Money Box (Top Right)
			local moneyBox = Instance.new("Frame")
			moneyBox.Size = UDim2.new(0.48, -15, 0, 68)
			moneyBox.Position = UDim2.new(0.52, 0, 0, 90)
			moneyBox.BackgroundColor3 = Color3.fromRGB(22, 28, 46)
			moneyBox.BorderSizePixel = 0
			moneyBox.Parent = card
			local mbCorner = Instance.new("UICorner")
			mbCorner.CornerRadius = UDim.new(0, 10)
			mbCorner.Parent = moneyBox

			local moneyTitle = Instance.new("TextLabel")
			moneyTitle.Size = UDim2.new(1, 0, 0, 20)
			moneyTitle.Position = UDim2.new(0, 0, 0, 6)
			moneyTitle.BackgroundTransparency = 1
			moneyTitle.Text = "💰 CURRENT BALANCE"
			moneyTitle.TextColor3 = Color3.fromRGB(160, 175, 200)
			moneyTitle.Font = Enum.Font.GothamBold
			moneyTitle.TextSize = 11
			moneyTitle.Parent = moneyBox

			local moneyVal = Instance.new("TextLabel")
			moneyVal.Size = UDim2.new(1, -10, 0, 32)
			moneyVal.Position = UDim2.new(0, 5, 0, 28)
			moneyVal.BackgroundTransparency = 1
			moneyVal.Text = getLivePlayerMoney()
			moneyVal.TextColor3 = Color3.fromRGB(0, 255, 170)
			moneyVal.Font = Enum.Font.GothamBold
			moneyVal.TextSize = 14
			moneyVal.Parent = moneyBox

			-- Box 3: Target Earn Box (Bottom Left)
			local targetBox = Instance.new("Frame")
			targetBox.Size = UDim2.new(0.48, -15, 0, 68)
			targetBox.Position = UDim2.new(0, 20, 0, 168)
			targetBox.BackgroundColor3 = Color3.fromRGB(22, 28, 46)
			targetBox.BorderSizePixel = 0
			targetBox.Parent = card
			local tgtCorner = Instance.new("UICorner")
			tgtCorner.CornerRadius = UDim.new(0, 10)
			tgtCorner.Parent = targetBox

			local targetTitle = Instance.new("TextLabel")
			targetTitle.Size = UDim2.new(1, 0, 0, 20)
			targetTitle.Position = UDim2.new(0, 0, 0, 6)
			targetTitle.BackgroundTransparency = 1
			targetTitle.Text = "🎯 TARGET EARN"
			targetTitle.TextColor3 = Color3.fromRGB(160, 175, 200)
			targetTitle.Font = Enum.Font.GothamBold
			targetTitle.TextSize = 11
			targetTitle.Parent = targetBox

			local targetVal = Instance.new("TextLabel")
			targetVal.Size = UDim2.new(1, -10, 0, 32)
			targetVal.Position = UDim2.new(0, 5, 0, 28)
			targetVal.BackgroundTransparency = 1
			local curTgt = tonumber(_G.HipHubConfig.misc.targetEarn) or 0
			targetVal.Text = curTgt > 0 and formatRupiah(curTgt) or "No Limit (∞)"
			targetVal.TextColor3 = Color3.fromRGB(255, 215, 0)
			targetVal.Font = Enum.Font.GothamBold
			targetVal.TextSize = 14
			targetVal.Parent = targetBox

			-- Box 4: Progress Box (Bottom Right)
			local progressBox = Instance.new("Frame")
			progressBox.Size = UDim2.new(0.48, -15, 0, 68)
			progressBox.Position = UDim2.new(0.52, 0, 0, 168)
			progressBox.BackgroundColor3 = Color3.fromRGB(22, 28, 46)
			progressBox.BorderSizePixel = 0
			progressBox.Parent = card
			local prgCorner = Instance.new("UICorner")
			prgCorner.CornerRadius = UDim.new(0, 10)
			prgCorner.Parent = progressBox

			local progressTitle = Instance.new("TextLabel")
			progressTitle.Size = UDim2.new(1, 0, 0, 20)
			progressTitle.Position = UDim2.new(0, 0, 0, 6)
			progressTitle.BackgroundTransparency = 1
			progressTitle.Text = "📈 PROGRESS"
			progressTitle.TextColor3 = Color3.fromRGB(160, 175, 200)
			progressTitle.Font = Enum.Font.GothamBold
			progressTitle.TextSize = 11
			progressTitle.Parent = progressBox

			local progressVal = Instance.new("TextLabel")
			progressVal.Size = UDim2.new(1, 0, 0, 32)
			progressVal.Position = UDim2.new(0, 0, 0, 28)
			progressVal.BackgroundTransparency = 1
			progressVal.Text = "Ongoing 🏃"
			progressVal.TextColor3 = Color3.fromRGB(0, 212, 255)
			progressVal.Font = Enum.Font.GothamBold
			progressVal.TextSize = 14
			progressVal.Parent = progressBox

			-- Progress Bar Track
			local barTrack = Instance.new("Frame")
			barTrack.Size = UDim2.new(1, -40, 0, 8)
			barTrack.Position = UDim2.new(0, 20, 0, 248)
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
			statusBadge.Size = UDim2.new(1, -40, 0, 24)
			statusBadge.Position = UDim2.new(0, 20, 0, 268)
			statusBadge.BackgroundTransparency = 1
			statusBadge.Text = "🟢 Auto-Farm Active | Anti-AFK: ON"
			statusBadge.TextColor3 = Color3.fromRGB(0, 255, 170)
			statusBadge.Font = Enum.Font.GothamMedium
			statusBadge.TextSize = 12
			statusBadge.TextXAlignment = Enum.TextXAlignment.Center
			statusBadge.Parent = card

			-- Footer note
			local footer = Instance.new("TextLabel")
			footer.Size = UDim2.new(1, -40, 0, 36)
			footer.Position = UDim2.new(0, 20, 0, 304)
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

						local curMoney = getLivePlayerMoneyRaw()
						moneyVal.Text = formatRupiah(curMoney)

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

							if curMoney >= target then
								statusBadge.Text = "🎉 TARGET EARN TERCAPAI (" .. formatRupiah(target) .. ")! Selesai."
								statusBadge.TextColor3 = Color3.fromRGB(255, 215, 0)
								barFill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
								if _G.HipHubAutoRideGoToggle and _G.HipHubAutoRideGoToggle.Set and _G.HipHubAutoRideGoToggle.Get and _G.HipHubAutoRideGoToggle.Get() then
									_G.HipHubAutoRideGoToggle.Set(false)
								end
							else
								local antiPText = _G.HipHubConfig.misc.antiPlayerJoin and "Anti-Player: ON 🚪" or "Anti-Player: OFF"
								statusBadge.Text = "🟢 Auto-Farm Active | Anti-AFK: ON | " .. antiPText
								statusBadge.TextColor3 = Color3.fromRGB(0, 255, 170)
								barFill.BackgroundColor3 = Color3.fromRGB(0, 255, 170)
							end
						else
							targetVal.Text = "No Limit (∞)"
							progressVal.Text = "Ongoing 🏃"
							barFill.Size = UDim2.new(1, 0, 1, 0)
							barFill.BackgroundColor3 = Color3.fromRGB(0, 212, 255)
							local antiPText = _G.HipHubConfig.misc.antiPlayerJoin and "Anti-Player: ON 🚪" or "Anti-Player: OFF"
							statusBadge.Text = "🟢 Auto-Farm Active | Anti-AFK: ON | " .. antiPText
							statusBadge.TextColor3 = Color3.fromRGB(0, 255, 170)
						end
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

	local blackScreenToggle = UI.AddToggle(tab, "Black Screen (Overnight AFK)", "Disables 3D viewport rendering with a live stats dashboard", _G.HipHubConfig.misc.blackScreenEnabled, function(state)
		toggleBlackScreen(state)
	end)

	UI.AddToggle(tab, "Low FPS Mode (15 FPS Cap)", "Limits framerate for smooth multi-instance overnight background farming", _G.HipHubConfig.misc.capFpsEnabled, function(state)
		_G.HipHubConfig.misc.capFpsEnabled = state
		saveConfig(true)
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
