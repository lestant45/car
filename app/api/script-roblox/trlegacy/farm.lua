-- HipHub TR Legacy — Auto Race Underground & Circular Auto Drive Suite
-- Smooth underground flight traversal between checkpoints and circular underground odometer farm

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local tab = UI.tabs["Farm"] and UI.tabs["Farm"].Frame
	if not tab then return end

	local Config = _G.HipHubConfig and _G.HipHubConfig.farm or {
		autoRace = false,
		selectedRace = "Race 1 (Mountain Race - RM 26,500 Solo)",
		targetEarnEnabled = false,
		targetEarnAmount = 100000,
		checkpointDelay = 0.02,
		returnToSurface = true,
		autoDriveCircle = false,
		circleRadius = 65,
		circleSpeed = 150,
		antiStuck = true,
		autoLoop = true
	}

	if Config.targetEarnEnabled == nil then Config.targetEarnEnabled = false end
	if Config.targetEarnAmount == nil or Config.targetEarnAmount <= 0 then Config.targetEarnAmount = 100000 end
	if Config.circleRadius == nil then Config.circleRadius = 65 end
	if Config.circleSpeed == nil then Config.circleSpeed = 150 end
	if Config.antiStuck == nil then Config.antiStuck = true end

	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Workspace = game:GetService("Workspace")
	local player = Players.LocalPlayer

	-- Global state
	_G.HipHub_IsAutoRacing = false
	_G.HipHub_IsAutoDriving = false

	-- Safe Warp Remote Dispatcher
	local function fireWarp(clientName, ...)
		local args = {...}
		local ok = pcall(function()
			local old = (getthreadidentity and getthreadidentity()) or 8
			if setthreadidentity then setthreadidentity(2) end
			local Warp = require(ReplicatedStorage.Modules.Warp)
			local client = Warp.Client(clientName)
			client:Fire(table.unpack(args))
			if setthreadidentity then setthreadidentity(old) end
		end)
		return ok
	end

	-- Anti-Leak Ghost Replay Blocker: Blocks RaceGhostSubmit & GhostRecorder during auto race
	pcall(function()
		local old = (getthreadidentity and getthreadidentity()) or 8
		if setthreadidentity then setthreadidentity(2) end
		local Warp = require(ReplicatedStorage.Modules.Warp)
		local ghostClient = Warp.Client("RaceGhostSubmit")
		if ghostClient and ghostClient.Fire then
			local originalGhostFire = ghostClient.Fire
			ghostClient.Fire = function(self, ...)
				if _G.HipHub_IsAutoRacing or (Config and Config.autoRace) then
					-- Block sending flying ghost trajectory replay to prevent server ban
					return nil
				end
				return originalGhostFire(self, ...)
			end
		end
		local okRecorder, GhostRecorder = pcall(function()
			return require(ReplicatedStorage.Modules.UI.Racing.Ghost.GhostRecorder)
		end)
		if okRecorder and GhostRecorder and GhostRecorder.update then
			local oldUpdate = GhostRecorder.update
			GhostRecorder.update = function(self, ...)
				if _G.HipHub_IsAutoRacing or (Config and Config.autoRace) then
					self.frames = {}
					return
				end
				return oldUpdate(self, ...)
			end
		end
		if setthreadidentity then setthreadidentity(old) end
	end)

	-- Race definitions with verified IDs, rewards (Solo TimeTrial is 50% of Multi), and Base World Records
	-- Real-time WR is dynamically queried via Warp remote: RaceLeaderboardQuery with +10% Dynamic Pacing
	local RaceOptions = {
		["Race 1 (Mountain Race - RM 26,500 Solo)"]   = { id = "1", modelName = "Race1", reward = 26500, maxTime = 75,  wrTime = 201.62, minSafeDuration = 221.8 }, -- Official WR 03:21.62 (Maple) -> Target +10%: 03:41.8
		["Race 8 (Around The World - RM 19,000 Solo)"] = { id = "8", modelName = "Race8", reward = 19000, maxTime = 100, wrTime = 227.93, minSafeDuration = 250.7 }, -- Official WR 03:47.93 (Levi)  -> Target +10%: 04:10.7
		["Race 4 (Highway - RM 13,500 Solo)"]         = { id = "4", modelName = "Race4", reward = 13500, maxTime = 90,  wrTime = 142.92, minSafeDuration = 157.2 }, -- Official WR 02:22.92 (Levi)  -> Target +10%: 02:37.2
		["Race 3 (GP Track - RM 9,250 Solo)"]         = { id = "3", modelName = "Race3", reward = 9250,  maxTime = 60,  wrTime = 71.94,  minSafeDuration = 79.1 },  -- Official WR 01:11.94 (n3b)   -> Target +10%: 01:19.1
		["Race 2 (Small Circuit - RM 5,500 Solo)"]    = { id = "2", modelName = "Race2", reward = 5500,  maxTime = 35,  wrTime = 44.90,  minSafeDuration = 49.4 },  -- Official WR 00:44.90 (n3b)   -> Target +10%: 00:49.4
		["Race 6 (Lake Race - RM 4,750 Solo)"]        = { id = "6", modelName = "Race6", reward = 4750,  maxTime = 40,  wrTime = 35.93,  minSafeDuration = 39.5 },  -- Official WR 00:35.93 (100perc) -> Target +10%: 00:39.5
		["Race 7 (Side Street - RM 3,650 Solo)"]      = { id = "7", modelName = "Race7", reward = 3650,  maxTime = 40,  wrTime = 34.55,  minSafeDuration = 38.0 },  -- Official WR 00:34.55 (UMA_m0Nd) -> Target +10%: 00:38.0
		["Race 5 (Drag - RM 750 Solo)"]               = { id = "5", modelName = "Race5", reward = 750,   maxTime = 30,  wrTime = 4.22,   minSafeDuration = 9.0 },   -- Official WR 00:04.22 (ALANSINHAO) -> Min Safe: 9.0s
		-- Backwards compatibility aliases
		["Race 8 (Around The World - RM 38,000)"]     = { id = "8", modelName = "Race8", reward = 19000, maxTime = 100, wrTime = 227.93, minSafeDuration = 250.7 },
		["Race 2 (Small Circuit - RM 11,000)"]        = { id = "2", modelName = "Race2", reward = 5500,  maxTime = 35,  wrTime = 44.90,  minSafeDuration = 49.4 },
		["Race 4 (Highway - RM 27,000)"]              = { id = "4", modelName = "Race4", reward = 13500, maxTime = 90,  wrTime = 142.92, minSafeDuration = 157.2 },
		["Race 3 (GP Track - RM 18,500)"]             = { id = "3", modelName = "Race3", reward = 9250,  maxTime = 60,  wrTime = 71.94,  minSafeDuration = 79.1 },
		["Race 6 (Lake Race - RM 9,500)"]             = { id = "6", modelName = "Race6", reward = 4750,  maxTime = 40,  wrTime = 35.93,  minSafeDuration = 39.5 },
		["Race 7 (Side Street - RM 7,300)"]           = { id = "7", modelName = "Race7", reward = 3650,  maxTime = 40,  wrTime = 34.55,  minSafeDuration = 38.0 },
		["Race 5 (Drag - RM 1,500)"]                  = { id = "5", modelName = "Race5", reward = 750,   maxTime = 30,  wrTime = 4.22,   minSafeDuration = 9.0 },
	}

	local raceDropdownList = {
		"Race 1 (Mountain Race - RM 26,500 Solo)",
		"Race 8 (Around The World - RM 19,000 Solo)",
		"Race 4 (Highway - RM 13,500 Solo)",
		"Race 3 (GP Track - RM 9,250 Solo)",
		"Race 2 (Small Circuit - RM 5,500 Solo)",
		"Race 6 (Lake Race - RM 4,750 Solo)",
		"Race 7 (Side Street - RM 3,650 Solo)",
		"Race 5 (Drag - RM 750 Solo)",
	}

	-- Auto WR + 10% Dynamic Pacing with Humanized Jitter: Prevents identical millisecond lap bot detection
	local function getRaceTargetDuration(raceId, fallbackWR)
		local wrTime = fallbackWR or 60.0
		local riderName = "Server Record"
		pcall(function()
			local old = (getthreadidentity and getthreadidentity()) or 8
			if setthreadidentity then setthreadidentity(2) end
			local Warp = require(ReplicatedStorage.Modules.Warp)
			local client = Warp.Client("RaceLeaderboardQuery")
			local res = client:Invoke(10, tostring(raceId))
			if type(res) == "table" and #res > 0 and res[1] and type(res[1].time) == "number" and res[1].time > 0 then
				wrTime = res[1].time
				riderName = tostring(res[1].name or res[1].rawName or "Server Record")
			end
			if setthreadidentity then setthreadidentity(old) end
		end)
		-- Base +10% target with natural human jitter variance (+3.0 to +8.5 seconds random)
		local jitter = math.random(300, 850) / 100
		local targetDuration = (wrTime * 1.10) + jitter
		return targetDuration, wrTime, riderName, jitter
	end

	-- Telemetry Stats & Formatting Helpers
	local totalRacesWon = 0
	local totalRaceCash = 0
	local totalDistanceTraveled = 0
	local circleDriveStartTime = 0
	local startDriveCash = nil
	local startDriveMiles = nil
	local sessionStartCash = nil

	local function formatCash(amount)
		return string.format("%.0f", amount or 0):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	end

	-- Forward declarations for UI elements
	local targetProgressCard = nil
	local targetInput = nil
	local targetToggle = nil
	local raceStatusCard = nil
	local raceEarningsCard = nil
	local autoRaceToggle = nil
	local driveStatusCard = nil
	local driveCashCard = nil
	local driveMilesCard = nil
	local driveDistCard = nil
	local autoDriveToggle = nil

	-- Helper: Safely return bike to ground surface
	local function returnBikeToSurface(bike, primary)
		if not bike or not primary then return end
		pcall(function()
			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = { bike, player.Character }
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			local curPos = primary.Position
			local ray = workspace:Raycast(Vector3.new(curPos.X, 250, curPos.Z), Vector3.new(0, -500, 0), rayParams)
			local groundY = (ray and ray.Position.Y > -5) and (ray.Position.Y + 2.5) or 2.5
			bike:PivotTo(CFrame.new(curPos.X, groundY, curPos.Z))
			primary.AssemblyLinearVelocity = Vector3.zero
			primary.AssemblyAngularVelocity = Vector3.zero
		end)
	end

	-- Dynamic Target Earn Progress Updater & Auto-Stop Controller
	local function updateTargetProgress(currentCash)
		local curCash = currentCash
		if not curCash then
			local ls = player:FindFirstChild("leaderstats")
			curCash = ls and ls:FindFirstChild("Cash") and ls.Cash.Value or 0
		end

		if not sessionStartCash then
			sessionStartCash = curCash
		end

		local targetAmount = math.max(tonumber(Config.targetEarnAmount) or 100000, 1000)
		local earned = math.max(0, curCash - sessionStartCash)
		local pct = math.clamp(math.floor((earned / targetAmount) * 100), 0, 100)

		if targetProgressCard and targetProgressCard.Set then
			if Config.targetEarnEnabled then
				if earned >= targetAmount then
					targetProgressCard.Set(string.format("TARGET TERCAPAI (+RM %s / RM %s)", formatCash(earned), formatCash(targetAmount)))
				else
					targetProgressCard.Set(string.format("+RM %s / RM %s (%d%% | Saldo: RM %s)", formatCash(earned), formatCash(targetAmount), pct, formatCash(curCash)))
				end
			else
				targetProgressCard.Set(string.format("Nonaktif (+RM %s / RM %s | Saldo: RM %s)", formatCash(earned), formatCash(targetAmount), formatCash(curCash)))
			end
		end

		-- Check auto-stop condition: stop farming immediately when target net profit is reached
		if Config.targetEarnEnabled and earned >= targetAmount then
			if Config.autoRace or Config.autoDriveCircle or _G.HipHub_IsAutoRacing or _G.HipHub_IsAutoDriving then
				Config.autoRace = false
				Config.autoDriveCircle = false
				_G.HipHub_IsAutoRacing = false
				_G.HipHub_IsAutoDriving = false

				if autoRaceToggle and autoRaceToggle.Set then
					autoRaceToggle.Set(false)
				end
				if autoDriveToggle and autoDriveToggle.Set then
					autoDriveToggle.Set(false)
				end

				if raceStatusCard and raceStatusCard.Set then
					raceStatusCard.Set(string.format("Target RM %s Tercapai! Farming Berhenti.", formatCash(targetAmount)))
				end
				if driveStatusCard and driveStatusCard.Set then
					driveStatusCard.Set(string.format("Target RM %s Tercapai! Farming Berhenti.", formatCash(targetAmount)))
				end

				local bike, seat, primary = _G.HipHub_GetPlayerBike and _G.HipHub_GetPlayerBike()
				if bike and primary then
					returnBikeToSurface(bike, primary)
					primary.AssemblyLinearVelocity = Vector3.zero
					primary.AssemblyAngularVelocity = Vector3.zero
					if seat then seat.Throttle = 0 end
				end

				if UI and UI.Notify then
					UI.Notify("Target Profit Tercapai", string.format("Farming selesai! Total profit: +RM %s (Saldo: RM %s)", formatCash(earned), formatCash(curCash)), 5, "success")
				end
			end
		end
	end

	------------------------------------------------
	-- UI: FARM TAB
	------------------------------------------------

	-- 0. TARGET PROFIT & SAFETY LIMITER SECTION
	local targetSection = UI.AddSection(tab, "Target Profit & Safety Limiter", 1)

	targetProgressCard = UI.AddStatsCard(targetSection, "Target Profit Progress", "Nonaktif (Target: RM 100,000)", 2)

	targetInput = UI.AddInput(targetSection, "Target Profit (RM)", "Contoh: 100000", tostring(Config.targetEarnAmount or 100000), function(text)
		local cleaned = text:gsub("[^%d]", "")
		local num = tonumber(cleaned)
		if num and num > 0 then
			Config.targetEarnAmount = num
			if _G.HipHubAutoSave then _G.HipHubAutoSave() end
			updateTargetProgress()
			UI.Notify("Target Profit", "Target profit diatur ke RM " .. formatCash(num), 2, "info")
		end
	end, 3)

	targetToggle = UI.AddToggle(targetSection, "Enable Auto-Stop Saat Target Tercapai", Config.targetEarnEnabled, function(enabled)
		Config.targetEarnEnabled = enabled
		if _G.HipHubAutoSave then _G.HipHubAutoSave() end
		updateTargetProgress()
		UI.Notify("Target Earn", enabled and ("Auto-Stop aktif jika profit mencapai RM " .. formatCash(Config.targetEarnAmount)) or "Auto-Stop dinonaktifkan", 3, "info")
	end, 4)

	local resetTargetBtn = UI.AddButton(targetSection, "Reset Hitungan Profit Sesi", function()
		local ls = player:FindFirstChild("leaderstats")
		local cur = ls and ls:FindFirstChild("Cash") and ls.Cash.Value or 0
		sessionStartCash = cur
		totalRacesWon = 0
		totalRaceCash = 0
		if raceEarningsCard and raceEarningsCard.Set then
			raceEarningsCard.Set("RM 0 (0 Wins)")
		end
		updateTargetProgress(cur)
		UI.Notify("Target Profit", "Hitungan profit sesi di-reset ke RM 0!", 2, "info")
	end, 5, "secondary")

	-- 1. AUTO RACE SECTION
	local raceSection = UI.AddSection(tab, "Auto Race Track Farm", 6)

	raceStatusCard = UI.AddStatsCard(raceSection, "Race Status", "Idle", 7)
	raceEarningsCard = UI.AddStatsCard(raceSection, "Race Earnings", "RM 0 (0 Wins)", 8)

	local raceDropdown = UI.AddDropdown(raceSection, "Select Track Target", raceDropdownList, Config.selectedRace, function(selected)
		Config.selectedRace = selected
		if _G.HipHubAutoSave then _G.HipHubAutoSave() end
	end, 9)

	local delaySlider = UI.AddSlider(raceSection, "Checkpoint Delay", 0.00, 0.30, Config.checkpointDelay or 0.02, function(val)
		Config.checkpointDelay = val
		if _G.HipHubAutoSave then _G.HipHubAutoSave() end
	end, 0.01, "s", 10)

	autoRaceToggle = UI.AddToggle(raceSection, "Enable Auto Race (WR + 10% Dynamic Pacing)", Config.autoRace, function(enabled)
		Config.autoRace = enabled
		_G.HipHub_IsAutoRacing = enabled
		if enabled then
			if not sessionStartCash then
				local ls = player:FindFirstChild("leaderstats")
				sessionStartCash = ls and ls:FindFirstChild("Cash") and ls.Cash.Value or 0
			end
			updateTargetProgress()
			UI.Notify("Auto Race", "Memulai auto race (WR + 10% Dynamic Pacing)...", 3, "success")
		else
			UI.Notify("Auto Race", "Menghentikan auto race.", 2, "info")
			raceStatusCard.Set("Stopped")
			if Config.returnToSurface then
				local bike, _, primary = _G.HipHub_GetPlayerBike and _G.HipHub_GetPlayerBike()
				returnBikeToSurface(bike, primary)
			end
		end
	end, 11)

	-- 2. AUTO DRIVE MEMUTAR SECTION (KHUSUS DI ATAS TANAH)
	local driveSection = UI.AddSection(tab, "Auto Drive Memutar (Khusus Di Atas Tanah)", 12)

	driveStatusCard = UI.AddStatsCard(driveSection, "Drive Status", "Idle", 13)
	driveCashCard = UI.AddStatsCard(driveSection, "Live Cash / Balance", "RM 0 (+RM 0)", 14)
	driveMilesCard = UI.AddStatsCard(driveSection, "Odometer Miles", "0 mi (+0 mi)", 15)
	driveDistCard = UI.AddStatsCard(driveSection, "Distance Traveled", "0.00 km", 16)

	local radiusSlider = UI.AddSlider(driveSection, "Ruas Lingkaran (Radius)", 15, 300, Config.circleRadius or 65, function(val)
		Config.circleRadius = val
		if _G.HipHubAutoSave then _G.HipHubAutoSave() end
	end, 5, " studs", 17)

	local driveSpeedSlider = UI.AddSlider(driveSection, "Kecepatan Memutar", 50, 300, Config.circleSpeed or 150, function(val)
		Config.circleSpeed = val
		if _G.HipHubAutoSave then _G.HipHubAutoSave() end
	end, 5, " km/h", 18)

	local antiStuckToggle = UI.AddToggle(driveSection, "Anti-Stuck & Ghost Noclip (Tembus Rintangan)", Config.antiStuck ~= false, function(v)
		Config.antiStuck = v
		if _G.HipHubAutoSave then _G.HipHubAutoSave() end
	end, 19)

	local unstuckBtn = UI.AddButton(driveSection, "Unstuck Manual (Lepaskan Motor)", function()
		local bike, _, primary = _G.HipHub_GetPlayerBike and _G.HipHub_GetPlayerBike()
		if bike and primary then
			local look = primary.CFrame.LookVector
			bike:PivotTo(bike:GetPivot() + Vector3.new(0, 4, 0) + (look * 10))
			primary.AssemblyLinearVelocity = look * 120 + Vector3.new(0, 15, 0)
			UI.Notify("Anti-Stuck", "Motor dilepaskan dari rintangan!", 2, "success")
		end
	end, 20)

	autoDriveToggle = UI.AddToggle(driveSection, "Enable Auto Drive Memutar (Di Atas Tanah)", Config.autoDriveCircle, function(enabled)
		Config.autoDriveCircle = enabled
		_G.HipHub_IsAutoDriving = enabled
		if enabled then
			circleDriveStartTime = os.clock()
			startDriveCash = nil
			startDriveMiles = nil
			if not sessionStartCash then
				local ls = player:FindFirstChild("leaderstats")
				sessionStartCash = ls and ls:FindFirstChild("Cash") and ls.Cash.Value or 0
			end
			updateTargetProgress()
			UI.Notify("Auto Drive", "Memulai circular drive di atas tanah (Radius: " .. Config.circleRadius .. " studs)", 3, "success")
		else
			UI.Notify("Auto Drive", "Menghentikan circular drive.", 2, "info")
			driveStatusCard.Set("Stopped")
			startDriveCash = nil
			startDriveMiles = nil
			local bike, seat, primary = _G.HipHub_GetPlayerBike and _G.HipHub_GetPlayerBike()
			if bike and primary then
				primary.AssemblyLinearVelocity = Vector3.zero
				primary.AssemblyAngularVelocity = Vector3.zero
				if seat then seat.Throttle = 0 end
			end
		end
	end, 21)

	------------------------------------------------
	-- UNDERGROUND AUTO RACE LOGIC
	------------------------------------------------

	local function getCheckpointsForRace(raceModel)
		local ordered = nil
		pcall(function()
			local getOrdered = require(ReplicatedStorage.Modules.UI.Racing.Utility.getOrderedCheckpoints)
			ordered = getOrdered(raceModel)
		end)
		if ordered and #ordered > 0 then return ordered end

		local folder = raceModel:FindFirstChild("Checkpoints")
		if folder then
			local list = {}
			for _, child in ipairs(folder:GetChildren()) do
				if child:IsA("BasePart") then
					local num = tonumber(child.Name:match("%d+"))
					if num then
						table.insert(list, { part = child, index = num })
					end
				end
			end

			table.sort(list, function(a, b) return a.index < b.index end)

			if #list > 0 then
				local res = {}
				for _, item in ipairs(list) do
					table.insert(res, item.part)
				end
				return res
			end
		end

		-- Fallback: MinimapPath attribute (exact deobfuscated showcase logic)
		local minimapAttr = raceModel:GetAttribute("MinimapPath")
		if minimapAttr and type(minimapAttr) == "string" then
			local pathCheckpoints = {}
			for seg in minimapAttr:gmatch("[^|]+") do
				local x, y, z = seg:match("([^,]+),([^,]+),([^,]+)")
				if x and y and z then
					table.insert(pathCheckpoints, { Position = Vector3.new(tonumber(x), tonumber(y), tonumber(z)) })
				end
			end
			if #pathCheckpoints > 0 then
				return pathCheckpoints
			end
		end

		return {}
	end

	-- Helper: Safe Noclip during race flight (only modify vehicle parts, never modify character parts)
	local function setFullFlightNoclip(b, char, enableNoclip)
		pcall(function()
			if b then
				for _, desc in ipairs(b:GetDescendants()) do
					if desc:IsA("BasePart") then
						if enableNoclip then
							desc.CanCollide = false
						else
							desc.CanCollide = true
						end
					end
				end
			end
		end)
	end

	local function setBikeNoclipSafe(b, enableNoclip)
		setFullFlightNoclip(b, player.Character, enableNoclip)
	end

	local function runRaceCycle()
		if not Config.autoRace then return false end

		-- Pre-Race Safety: Anti-Staff Scan
		if _G.HipHub_AntiStaff and _G.HipHub_AntiStaff.scanForStaff then
			local staffFound = _G.HipHub_AntiStaff.scanForStaff()
			if staffFound then return false end
		end

		local cur = (player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Cash")) and player.leaderstats.Cash.Value or nil
		if cur then updateTargetProgress(cur) end
		if not Config.autoRace then return false end

		local raceData = RaceOptions[Config.selectedRace] or RaceOptions[raceDropdownList[1]]
		local raceModel = workspace:FindFirstChild(raceData.modelName)
		if not raceModel then
			raceStatusCard.Set("Error: Track " .. tostring(raceData.modelName) .. " tidak ditemukan")
			return false
		end

		-- Step 1: Ensure Kasaki z800 2015 is spawned and player is seated
		raceStatusCard.Set("Memeriksa motor & driver...")
		local seated = false
		if _G.HipHubVehicle and _G.HipHubVehicle.EnsureDriverSeated then
			seated = _G.HipHubVehicle.EnsureDriverSeated(true)
		end
		-- Auto-Respawn Recovery: If seating failed (e.g. fresh respawn after death), force spawn fresh bike and retry
		if not seated then
			if _G.HipHub_SpawnKasaki then
				_G.HipHub_SpawnKasaki()
				task.wait(2.0)
				if _G.HipHubVehicle and _G.HipHubVehicle.EnsureDriverSeated then
					seated = _G.HipHubVehicle.EnsureDriverSeated(true)
				end
			end
		end
		if not seated then
			raceStatusCard.Set("Menunggu driver duduk di motor...")
			task.wait(1.5)
			return false
		end

		local bike, seat, primary = nil, nil, nil
		if _G.HipHub_GetPlayerBike then
			bike, seat, primary = _G.HipHub_GetPlayerBike()
		end
		if not bike or not seat or not primary then
			raceStatusCard.Set("Menunggu motor Kasaki z800...")
			task.wait(1.0)
			return false
		end

		-- Step 2: Check for post-race cooldown
		local cooldownAttr = player:GetAttribute("RaceCooldownUntil")
		if type(cooldownAttr) == "number" then
			local rem = math.ceil(cooldownAttr - Workspace:GetServerTimeNow())
			if rem > 0 then
				raceStatusCard.Set(string.format("Cooldown: %d s...", rem))
				task.wait(1.0)
				return true
			end
		end

		-- Step 3: Position bike at StartingArea (only teleport if far away)
		local startArea = raceModel:FindFirstChild("StartingArea") or raceModel:GetPivot()
		raceStatusCard.Set("Menuju Starting Area " .. raceData.modelName .. "...")

		-- Matikan No-Clip di StartingArea agar motor berdiri kokoh di atas aspal (tidak tembus tanah!)
		setBikeNoclipSafe(bike, false)
		local oldBV = primary:FindFirstChild("FarmBV")
		if oldBV then pcall(function() oldBV:Destroy() end) end

		local startAreaPos = typeof(startArea) == "CFrame" and startArea.Position or (startArea:IsA("BasePart") and startArea.Position or (startArea.Position or primary.Position))
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = { bike, player.Character }
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local groundRay = workspace:Raycast(startAreaPos + Vector3.new(0, 10, 0), Vector3.new(0, -30, 0), rayParams)
		local groundY = groundRay and (groundRay.Position.Y + 2.8) or (startAreaPos.Y + 2.8)
		local rotCF = typeof(startArea) == "CFrame" and (startArea - startArea.Position) or (startArea:IsA("BasePart") and (startArea.CFrame - startArea.CFrame.Position) or CFrame.identity)
		local startCF = CFrame.new(startAreaPos.X, groundY, startAreaPos.Z) * rotCF

		local distToStart = (primary.Position - startCF.Position).Magnitude
		if distToStart > 25 then
			bike:PivotTo(startCF)
		end
		primary.AssemblyLinearVelocity = Vector3.zero
		primary.AssemblyAngularVelocity = Vector3.zero

		-- Step 4: Wait for RacingUI MenuPanel to open
		local racingUI = player.PlayerGui:WaitForChild("RacingUI", 5)
		local menuPanel = nil
		if racingUI and racingUI:FindFirstChild("MainFrame") then
			menuPanel = racingUI.MainFrame:FindFirstChild("MenuPanel")
		end
		local tWaitMenu = os.clock()
		while (not menuPanel or not menuPanel.Visible) and (os.clock() - tWaitMenu) < 4 and Config.autoRace do
			if (primary.Position - startCF.Position).Magnitude > 25 then
				bike:PivotTo(startCF)
			end
			primary.AssemblyLinearVelocity = Vector3.zero
			primary.AssemblyAngularVelocity = Vector3.zero
			task.wait(0.25)
			if racingUI and racingUI:FindFirstChild("MainFrame") then
				menuPanel = racingUI.MainFrame:FindFirstChild("MenuPanel")
			end
		end

		-- Step 5: Hook RaceStartLights for countdown synchronization
		local lightsOut = false
		local lightsConn = nil
		local startLightsClient = nil
		pcall(function()
			local old = (getthreadidentity and getthreadidentity()) or 8
			if setthreadidentity then setthreadidentity(2) end
			local Warp = require(ReplicatedStorage.Modules.Warp)
			startLightsClient = Warp.Client("RaceStartLights")
			lightsConn = startLightsClient:Connect(function(status)
				if tostring(status) == "out" then
					lightsOut = true
				end
			end)
			if setthreadidentity then setthreadidentity(old) end
		end)

		-- Step 6: Trigger solo race creation
		raceStatusCard.Set("Mendaftarkan race di StartingArea...")
		local footer = menuPanel and menuPanel:FindFirstChild("Footer")
		local quickBtn = footer and footer:FindFirstChild("Quick")
		if quickBtn then
			local tQuick = os.clock()
			while not quickBtn.Interactable and (os.clock() - tQuick) < 3 and Config.autoRace do
				task.wait(0.1)
			end
			for _, c in ipairs(getconnections(quickBtn.Activated)) do c:Fire() end
			for _, c in ipairs(getconnections(quickBtn.MouseButton1Click)) do c:Fire() end
		else
			fireWarp("RaceSessionAction", true, "create", {
				zoneId = raceData.id,
				config = { Mode = "TimeTrial", Laps = 1, MaxPlayers = 1 }
			})
		end

		-- Check if a start card appeared in active sessions
		task.wait(0.5)
		local active = menuPanel and menuPanel:FindFirstChild("Active")
		local sessions = active and active:FindFirstChild("Sessions")
		if sessions then
			for _, card in ipairs(sessions:GetChildren()) do
				if card:IsA("Frame") and card:FindFirstChild("Start") then
					local startBtn = card.Start
					local label = startBtn:FindFirstChild("Label") and startBtn.Label.Text or startBtn.Text
					if tostring(label):upper():find("START") or tostring(label):upper():find("BALAP") then
						for _, c in ipairs(getconnections(startBtn.Activated)) do c:Fire() end
						for _, c in ipairs(getconnections(startBtn.MouseButton1Click)) do c:Fire() end
					end
				end
			end
		end

		-- Step 7: Wait for InRace and enforce server countdown synchronization
		local tWaitInRace = os.clock()
		while not player:GetAttribute("InRace") and (os.clock() - tWaitInRace) < 6 and Config.autoRace do
			primary.AssemblyLinearVelocity = Vector3.zero
			primary.AssemblyAngularVelocity = Vector3.zero
			task.wait(0.2)
		end

		if not player:GetAttribute("InRace") and not lightsOut then
			raceStatusCard.Set("Race belum mulai. Mencoba lagi...")
			if lightsConn and startLightsClient then
				pcall(function() startLightsClient:Disconnect(lightsConn) end)
			end
			task.wait(2.0)
			return false
		end

		-- Anti-cheat delay: Hold position until countdown light goes out
		local tPreRun = os.clock()
		while (os.clock() - tPreRun) < 9.0 and not lightsOut and Config.autoRace do
			local remaining = math.ceil(9.0 - (os.clock() - tPreRun))
			raceStatusCard.Set(string.format("Menunggu countdown lampu (%d s)...", remaining))
			primary.AssemblyLinearVelocity = Vector3.zero
			primary.AssemblyAngularVelocity = Vector3.zero
			task.wait(0.25)
		end

		if not Config.autoRace then
			if lightsConn and startLightsClient then
				pcall(function() startLightsClient:Disconnect(lightsConn) end)
			end
			return false
		end

		-- Step 8: Smooth flight through ordered checkpoints
		local checkpoints = getCheckpointsForRace(raceModel)
		if #checkpoints == 0 then
			raceStatusCard.Set("Tidak ada checkpoint ditemukan.")
			if lightsConn then pcall(function() lightsConn:Disconnect() end) end
			task.wait(2.0)
			return false
		end

		-- Dedicated State Manager: Mengatur Noclip hanya saat transisi state (efisien & bebas lag)
		local currentFlightNoclip = nil
		local function setFlightNoclipState(enable)
			if currentFlightNoclip ~= enable then
				currentFlightNoclip = enable
				setFullFlightNoclip(bike, player.Character, enable)
			end
		end

		-- Bangun daftar titik awal, akhir, dan jarak tiap segmen checkpoint
		local legStartPositions = {}
		local legDistances = {}
		local totalTrackDist = 0

		local prevPos = primary.Position
		for idx, cp in ipairs(checkpoints) do
			local curCPPos = cp.Position
			local d = (curCPPos - prevPos).Magnitude
			table.insert(legStartPositions, prevPos)
			table.insert(legDistances, d)
			totalTrackDist = totalTrackDist + d
			prevPos = curCPPos
		end

		-- Auto WR + 10% Dynamic Pacing Calculation (Garansi Waktu Terikat Jam Server)
		local targetDuration, wrTime, wrRider = getRaceTargetDuration(raceData.id, raceData.wrTime or raceData.minSafeDuration)
		if not targetDuration or targetDuration < 5 then targetDuration = 10 end

		local initialCash = (player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Cash")) and player.leaderstats.Cash.Value or totalRaceCash

		-- Create FarmBV velocity stabilizer (Hanya untuk menahan gravitasi, Velocity = 0)
		local farmBV = primary:FindFirstChild("FarmBV") or Instance.new("BodyVelocity")
		farmBV.Name = "FarmBV"
		farmBV.MaxForce = Vector3.new(4e5, 4e5, 4e5)
		farmBV.Velocity = Vector3.zero
		farmBV.Parent = primary

		local raceStartTime = os.clock()

		for i, cp in ipairs(checkpoints) do
			if not Config.autoRace then break end

			local startPos = legStartPositions[i]
			local endPos = cp.Position
			local legDist = legDistances[i]
			-- Alokasi waktu presisi untuk checkpoint ini berdasarkan proporsi jaraknya terhadap total track
			local legDuration = (totalTrackDist > 0) and ((legDist / totalTrackDist) * targetDuration) or (targetDuration / #checkpoints)
			if legDuration < 0.05 then legDuration = 0.05 end

			local legStartTime = os.clock()

			-- USER REQUIREMENT:
			-- 1. Checkpoint 1 s/d (#checkpoints - 1): Saat motor sudah jalan, aktifkan Full Ghost Noclip (tembus bukit, gunung, pohon, rintangan)
			-- 2. Checkpoint terakhir (garis finish): Matikan No-Clip agar motor mendarat menapak tanah sebelum finish
			if i < #checkpoints then
				setFlightNoclipState(true)
			else
				setFlightNoclipState(false)
			end

			local diff = endPos - startPos
			local dir = (diff.Magnitude > 0.01) and diff.Unit or Vector3.new(0, 0, 1)

			while Config.autoRace do
				local now = os.clock()
				local legElapsed = now - legStartTime
				local alpha = math.clamp(legElapsed / legDuration, 0, 1)

				local currentPos = startPos:Lerp(endPos, alpha)

				-- Terrain-Surface Gliding: Motor selalu meluncur di atas kontur permukaan lereng bukit/tanah
				local rayParams = RaycastParams.new()
				rayParams.FilterDescendantsInstances = { bike, player.Character }
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				local groundRay = workspace:Raycast(Vector3.new(currentPos.X, math.max(currentPos.Y + 200, 350), currentPos.Z), Vector3.new(0, -700, 0), rayParams)

				if groundRay and groundRay.Position then
					local minSurfaceY = groundRay.Position.Y + 3.0
					if i == #checkpoints and alpha > 0.6 then
						-- Saat mendekati garis finish: mendarat mulus menapak di permukaan aspal
						setFlightNoclipState(false)
						currentPos = Vector3.new(currentPos.X, groundRay.Position.Y + 2.8, currentPos.Z)
					elseif minSurfaceY > currentPos.Y then
						-- Mengikuti kontur lereng bukit: angkat motor di atas permukaan lereng
						currentPos = Vector3.new(currentPos.X, minSurfaceY, currentPos.Z)
					end
				end

				bike:PivotTo(CFrame.lookAt(currentPos, currentPos + dir * 10))
				farmBV.Velocity = Vector3.zero
				primary.AssemblyLinearVelocity = Vector3.zero
				primary.AssemblyAngularVelocity = Vector3.zero
				seat.Throttle = 1

				local totalElapsed = now - raceStartTime
				local speedDisplay = (totalTrackDist > 0 and targetDuration > 0) and (totalTrackDist / targetDuration) or 0
				raceStatusCard.Set(string.format("Checkpoint %d / %d (%.0f%% | %d studs/s | %02d:%02d / %02d:%02d)", i, #checkpoints, alpha * 100, math.floor(speedDisplay), math.floor(totalElapsed / 60), math.floor(totalElapsed % 60), math.floor(targetDuration / 60), math.floor(targetDuration % 60)))

				if alpha >= 1 then
					break
				end

				RunService.Heartbeat:Wait()
			end

			-- Pastikan motor persis di atas checkpoint di akhir segmen
			bike:PivotTo(CFrame.lookAt(endPos, endPos + (cp:IsA("BasePart") and cp.CFrame.LookVector or dir)))

			if Config.checkpointDelay and Config.checkpointDelay > 0 then
				task.wait(Config.checkpointDelay)
			end
		end

		-- Step 9: Natural Finish Line Crossing & Validation Wait
		-- USER REQUIREMENT:
		-- 1. Jangan langsung berpindah ke area masuk race (StartingArea).
		-- 2. Tahan motor stabil di garis finish dengan farmBV agar tidak jatuh ke void.
		-- 3. No-Clip sudah dimatikan saat mendarat di garis finish agar validasi finish sah.
		-- 4. Game akan men-teleport sendiri pemain dan motor kembali ke area pendaftaran race.
		raceStatusCard.Set("Garis finish! Menunggu game memvalidasi balapan...")
		if lightsConn and startLightsClient then
			pcall(function() startLightsClient:Disconnect(lightsConn) end)
		end

		-- Pastikan No-Clip mati saat mendarat di finish
		setFlightNoclipState(false)

		local finishPos = checkpoints[#checkpoints].Position
		-- Tahan motor stabil di koordinat finish line (mencegah jatuh ke void/bawah tanah)
		if farmBV and farmBV.Parent then
			farmBV.Velocity = Vector3.zero
		end
		primary.AssemblyLinearVelocity = Vector3.zero
		primary.AssemblyAngularVelocity = Vector3.zero

		-- Tunggu game memvalidasi dan men-teleport kita kembali ke area race secara otomatis
		local tWaitFinish = os.clock()
		while player:GetAttribute("InRace") and (os.clock() - tWaitFinish) < 10 and Config.autoRace do
			-- Cek apakah game sudah men-teleport motor kita jauh dari garis finish (kembali ke StartingArea / Pits)
			local distFromFinish = (primary.Position - finishPos).Magnitude
			if distFromFinish > 50 then
				break
			end
			-- Jaga motor tetap melayang stabil di garis finish selama validasi
			if farmBV and farmBV.Parent then
				farmBV.Velocity = Vector3.zero
			end
			primary.AssemblyLinearVelocity = Vector3.zero
			primary.AssemblyAngularVelocity = Vector3.zero
			task.wait(0.2)
		end

		-- Balapan telah selesai divalidasi dan motor sudah berada di area masuk race
		raceStatusCard.Set("Balapan selesai divalidasi! Menyiapkan race...")
		task.wait(0.5)

		-- Pulihkan tabrakan motor dan lepas stabilizer farmBV
		setBikeNoclipSafe(bike, false)
		if farmBV then pcall(function() farmBV:Destroy() end) end

		-- Step 10: Race finished and payout verification
		task.wait(1.5)
		local currentCash = (player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Cash")) and player.leaderstats.Cash.Value or initialCash
		local earned = math.max(currentCash - initialCash, raceData.reward)

		totalRacesWon = totalRacesWon + 1
		totalRaceCash = totalRaceCash + earned
		raceEarningsCard.Set(string.format("RM %s (%d Wins)", formatCash(totalRaceCash), totalRacesWon))
		raceStatusCard.Set(string.format("Selesai! Menang RM %s", formatCash(earned)))

		UI.Notify("Auto Race", string.format("Finish %s (+RM %s)", raceData.modelName, formatCash(earned)), 3, "success")

		updateTargetProgress(currentCash)

		-- Wait for server cooldown (RaceCooldownUntil) + Natural Human Rest Buffer (10-15s)
		local tCooldown = os.clock()
		local naturalRest = math.random(10, 15)
		while Config.autoRace do
			local elapsed = os.clock() - tCooldown
			local cd = player:GetAttribute("RaceCooldownUntil")
			local remServer = (type(cd) == "number") and math.ceil(cd - Workspace:GetServerTimeNow()) or 0
			local remaining = math.max(remServer, math.ceil(naturalRest - elapsed))
			if remaining > 0 then
				raceStatusCard.Set(string.format("Jeda Aman Server: %d s...", remaining))
				task.wait(1.0)
			else
				break
			end
		end

		return true
	end

	local currentSessionToken = os.clock()
	_G.HipHub_FarmSessionToken = currentSessionToken

	_G.HipHub_ToggleAutoRace = function(val)
		Config.autoRace = val
		_G.HipHub_IsAutoRacing = val
		if not val then
			pcall(function()
				local b = _G.HipHub_GetPlayerBike and select(1, _G.HipHub_GetPlayerBike())
				if b then
					setFullFlightNoclip(b, player.Character, false)
					local farmBV = b:FindFirstChild("FarmBV", true)
					if farmBV then farmBV:Destroy() end
				end
			end)
		end
	end

	_G.HipHub_ToggleAutoDrive = function(val)
		Config.autoDriveCircle = val
		_G.HipHub_IsAutoDriving = val
	end

	-- Background Auto Race Routine with clean inter-race pause
	task.spawn(function()
		while _G.HipHub_FarmSessionToken == currentSessionToken do
			task.wait(1.5)
			if Config.autoRace or _G.HipHub_IsAutoRacing then
				local ok, err = pcall(runRaceCycle)
				if not ok then
					warn("[HipHub AutoRace Loop Error]:", err)
				end
			end
		end
	end)

	------------------------------------------------
	-- CIRCULAR AUTO DRIVE (ODOMETER & CASH)
	------------------------------------------------

	local circleCenter = nil
	local lastDrivePos = nil
	local undergroundTrack = nil
	local lastWatchdogPos = nil
	local lastWatchdogTime = 0
	local stuckSeconds = 0

	-- Raycast surface finder
	local function getGroundSurfaceY(posX, posZ, ignoreBike)
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = { ignoreBike, player.Character }
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local ray = workspace:Raycast(Vector3.new(posX, 250, posZ), Vector3.new(0, -500, 0), rayParams)
		return ray and ray.Position.Y or 0.5
	end

	-- Safely noclip ONLY obstacle props (fences, walls, barriers, poles, trees, furniture, bus stops)
	-- NEVER noclip terrain, ground, grass, floors, road, spawn, or baseplate
	local function noclipSurroundings(bikeRef, pos, radius)
		pcall(function()
			local overlap = OverlapParams.new()
			overlap.FilterDescendantsInstances = { bikeRef, player.Character, undergroundTrack }
			overlap.FilterType = Enum.RaycastFilterType.Exclude
			overlap.MaxParts = 50
			local hits = workspace:GetPartBoundsInRadius(pos, radius or 25, overlap)
			for _, hit in ipairs(hits) do
				if hit:IsA("BasePart") and hit.CanCollide then
					local n = hit.Name:lower()
					-- NEVER disable collision on ground/floor/terrain/road/spawn/baseplate
					local isGround = n:find("road") or n:find("ground") or n:find("grass") or n:find("floor") or n:find("spawn") or n:find("terrain") or n:find("baseplate") or n:find("plate") or n:find("walk") or n:find("asphalt")
					if not isGround then
						local isObstacle = n:find("fence") or n:find("rail") or n:find("wall") or n:find("barrier") or n:find("post") or n:find("pole") or n:find("tree") or n:find("stop") or n:find("shelf") or n:find("sign") or n:find("light") or n:find("prop") or n:find("decor") or n:find("curb")
						if isObstacle then
							hit.CanCollide = false
						end
					end
				end
			end
		end)
	end

	-- Noclip bike frame/exhaust/pegs so they don't catch on curbs (wheels MUST stay collidable)
	-- NEVER noclip the player character!
	local function noclipBikeBody(b)
		if not b then return end
		pcall(function()
			for _, desc in ipairs(b:GetDescendants()) do
				if desc:IsA("BasePart") then
					local n = desc.Name:lower()
					local isWheel = n:find("wheel") or n:find("tire") or desc.CollisionGroup == "BikeWheel"
					if isWheel then
						desc.CanCollide = true
					else
						desc.CanCollide = false
					end
				end
			end
		end)
	end

	_G.HipHub_FarmCleanup = _G.HipHub_FarmCleanup or {}

	-- Anti-Void Guardian: Runs continuously to protect the player from falling into the void
	if _G.HipHub_FarmCleanup.VoidConn then
		pcall(function() _G.HipHub_FarmCleanup.VoidConn:Disconnect() end)
		_G.HipHub_FarmCleanup.VoidConn = nil
	end

	_G.HipHub_FarmCleanup.VoidConn = RunService.Heartbeat:Connect(function()
		pcall(function()
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if root and hum and hum.Health > 0 then
				local isSeated = hum.SeatPart ~= nil
				local threshold = isSeated and -120 or -8
				if root.Position.Y < threshold then
					root.AssemblyLinearVelocity = Vector3.zero
					root.AssemblyAngularVelocity = Vector3.zero
					char:PivotTo(CFrame.new(-93, 3.5, -43))
					
					_G.HipHub_IsAutoDriving = false
					_G.HipHub_IsAutoRacing = false
					if Config then
						Config.autoDriveCircle = false
						Config.autoRace = false
					end
					
					local bike, _, primary = _G.HipHub_GetPlayerBike and _G.HipHub_GetPlayerBike()
					if bike and primary then
						returnBikeToSurface(bike, primary)
					end
					
					if UI and UI.Notify then
						UI.Notify("Safety", "Anti-Void Guardian: Pemain diselamatkan ke permukaan jalan!", 3, "warning")
					end
				end
			end
		end)
	end)

	if _G.HipHub_FarmCleanup.DriveConn then
		pcall(function() _G.HipHub_FarmCleanup.DriveConn:Disconnect() end)
		_G.HipHub_FarmCleanup.DriveConn = nil
	end

	_G.HipHub_FarmCleanup.DriveConn = RunService.Heartbeat:Connect(function(dt)
		if not Config.autoDriveCircle or Config.autoRace then
			if circleCenter then
				circleCenter = nil
				lastDrivePos = nil
				lastWatchdogPos = nil
				stuckSeconds = 0
				local bike, seat, primary = _G.HipHub_GetPlayerBike and _G.HipHub_GetPlayerBike()
				if bike and primary then
					primary.AssemblyLinearVelocity = Vector3.zero
					primary.AssemblyAngularVelocity = Vector3.zero
					if seat then seat.Throttle = 0 end
				end
			end
			return
		end

		local bike, seat, primary = nil, nil, nil
		if _G.HipHub_GetPlayerBike then
			bike, seat, primary = _G.HipHub_GetPlayerBike()
		end

		if not bike or not seat or not primary then
			driveStatusCard.Set("Menunggu Kasaki z800...")
			return
		end

		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then
			if circleCenter then
				circleCenter = nil
				lastDrivePos = nil
			end
			return
		end

		if hum.SeatPart ~= seat then
			driveStatusCard.Set("Mendudukkan driver di permukaan...")
			if circleCenter then
				circleCenter = nil
				lastDrivePos = nil
			end
			if _G.HipHubVehicle and _G.HipHubVehicle.EnsureDriverSeated then
				_G.HipHubVehicle.EnsureDriverSeated(true)
			end
			return
		end

		local radius = math.max(Config.circleRadius or 65, 15)
		local speed = math.max(Config.circleSpeed or 120, 40)

		-- Set circle center upon first run directly relative to bike's current surface position
		if not circleCenter and primary then
			local curPos = primary.Position
			local right = primary.CFrame.RightVector
			circleCenter = curPos + Vector3.new(right.X, 0, right.Z).Unit * radius
			noclipBikeBody(bike)
		end

		if not circleCenter or not primary then return end

		local curPos = primary.Position

		-- Noclip bike body & obstacles if anti-stuck is enabled
		if Config.antiStuck ~= false then
			noclipBikeBody(bike)
			noclipSurroundings(bike, curPos, 35)
		end

		-- Distance from circle center & proportional steering
		local diff = Vector3.new(curPos.X - circleCenter.X, 0, curPos.Z - circleCenter.Z)
		local currentDist = diff.Magnitude
		local distErr = radius - currentDist
		local baseOmega = -(speed / radius)
		local steerAdj = math.clamp(distErr * 0.05, -0.8, 0.8)
		local activeOmega = baseOmega - steerAdj

		-- Forward velocity along LookVector with natural surface gravity
		local look = primary.CFrame.LookVector
		local vy = primary.AssemblyLinearVelocity.Y

		-- Front obstacle / curb-hop raycast to glide smoothly over jagged curb seams
		local frontRayParams = RaycastParams.new()
		frontRayParams.FilterDescendantsInstances = { bike, player.Character }
		frontRayParams.FilterType = Enum.RaycastFilterType.Exclude
		local frontRay = workspace:Raycast(curPos + Vector3.new(0, 0.6, 0), look * 6, frontRayParams)
		if frontRay and frontRay.Instance then
			local n = frontRay.Instance.Name:lower()
			local isGround = n:find("road") or n:find("ground") or n:find("terrain") or n:find("asphalt") or n:find("baseplate")
			if not isGround then
				frontRay.Instance.CanCollide = false
				vy = math.max(vy, 8)
			end
		end

		-- Pure physics velocity: tires stay firmly on the road surface
		seat.Throttle = 1
		primary.AssemblyLinearVelocity = Vector3.new(look.X * speed, vy, look.Z * speed)
		primary.AssemblyAngularVelocity = Vector3.new(0, activeOmega, 0)

		-- Real-time Anti-Stuck Watchdog
		local now = os.clock()
		if now - lastWatchdogTime >= 0.8 then
			if lastWatchdogPos and _G.HipHub_IsAutoDriving then
				local dist = (curPos - lastWatchdogPos).Magnitude
				if dist < 4.0 then
					stuckSeconds = stuckSeconds + (now - lastWatchdogTime)
					if stuckSeconds >= 1.5 then
						noclipSurroundings(bike, curPos, 45)
						noclipBikeBody(bike)
						bike:PivotTo(bike:GetPivot() + Vector3.new(0, 3.5, 0) + (look * 8))
						primary.AssemblyLinearVelocity = look * speed + Vector3.new(0, 15, 0)
						driveStatusCard.Set("Meloloskan dari rintangan...")
						
						if stuckSeconds >= 4.0 then
							local shift = look * 35
							circleCenter = circleCenter + Vector3.new(shift.X, 0, shift.Z)
							stuckSeconds = 0
						end
					end
				else
					stuckSeconds = 0
				end
			end
			lastWatchdogPos = curPos
			lastWatchdogTime = now
		end

		-- Distance telemetry
		if lastDrivePos then
			local d = (curPos - lastDrivePos).Magnitude
			totalDistanceTraveled = totalDistanceTraveled + d
			local km = totalDistanceTraveled * 0.00028
			driveDistCard.Set(string.format("%.2f km", km))
		end
		lastDrivePos = curPos

		-- Live leaderstats tracking for real cash and miles
		pcall(function()
			local ls = player:FindFirstChild("leaderstats")
			if ls then
				local curCash = ls:FindFirstChild("Cash") and ls.Cash.Value or 0
				local curMiles = ls:FindFirstChild("Miles") and ls.Miles.Value or 0
				if not startDriveCash then
					startDriveCash = curCash
					startDriveMiles = curMiles
				end
				local diffCash = curCash - startDriveCash
				local diffMiles = curMiles - startDriveMiles
				driveCashCard.Set(string.format("RM %s (+RM %s)", formatCash(curCash), formatCash(diffCash)))
				driveMilesCard.Set(string.format("%d mi (+%d mi)", curMiles, diffMiles))

				updateTargetProgress(curCash)
			end
		end)

		local elapsed = math.floor(os.clock() - circleDriveStartTime)
		driveStatusCard.Set(string.format("Di Atas Tanah | R: %d | %d km/h (%02d:%02d)", radius, speed, math.floor(elapsed / 60), elapsed % 60))
	end)

	-- Initialize session cash and connect real-time leaderstats listener
	pcall(function()
		local ls = player:FindFirstChild("leaderstats") or player:WaitForChild("leaderstats", 5)
		if ls then
			local cashVal = ls:FindFirstChild("Cash") or ls:WaitForChild("Cash", 5)
			if cashVal then
				sessionStartCash = cashVal.Value
				updateTargetProgress(cashVal.Value)
				cashVal.Changed:Connect(function(newVal)
					updateTargetProgress(newVal)
				end)
			end
		end
	end)
end)

if not success then
	warn("[HipHub TR Legacy Farm Error]:", err)
end
