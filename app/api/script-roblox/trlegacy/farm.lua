-- 🏁 HipHub TR Legacy — Auto Race Underground & Circular Auto Drive Suite
-- High performance farming with invisible underground racing and circular odometer automation

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local tab = UI.tabs["Farm"] and UI.tabs["Farm"].Frame
	if not tab then return end

	local Config = _G.HipHubConfig and _G.HipHubConfig.farm or {
		autoRace = false,
		selectedRace = "Race 1 (Mountain Race - RM 53,000)",
		undergroundDepth = 25,
		checkpointDelay = 0.15,
		autoDriveCircle = false,
		circleRadius = 65,
		circleSpeed = 130,
		autoLoop = true
	}

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

	-- Race definitions with IDs and rewards
	local RaceOptions = {
		["Race 1 (Mountain Race - RM 53,000)"]  = { id = "1", modelName = "Race1", reward = 53000, maxTime = 75 },
		["Race 8 (Around The World - RM 38,000)"] = { id = "8", modelName = "Race8", reward = 38000, maxTime = 100 },
		["Race 4 (Highway - RM 27,000)"]           = { id = "4", modelName = "Race4", reward = 27000, maxTime = 90 },
		["Race 3 (GP Track - RM 18,500)"]          = { id = "3", modelName = "Race3", reward = 18500, maxTime = 60 },
		["Race 2 (Small Circuit - RM 11,000)"]     = { id = "2", modelName = "Race2", reward = 11000, maxTime = 35 },
		["Race 6 (Lake Race - RM 9,500)"]          = { id = "6", modelName = "Race6", reward = 9500,  maxTime = 40 },
		["Race 7 (Side Street - RM 7,300)"]        = { id = "7", modelName = "Race7", reward = 7300,  maxTime = 40 },
		["Race 5 (Drag - RM 1,500)"]               = { id = "5", modelName = "Race5", reward = 1500,  maxTime = 30 },
	}

	local raceDropdownList = {
		"Race 1 (Mountain Race - RM 53,000)",
		"Race 8 (Around The World - RM 38,000)",
		"Race 4 (Highway - RM 27,000)",
		"Race 3 (GP Track - RM 18,500)",
		"Race 2 (Small Circuit - RM 11,000)",
		"Race 6 (Lake Race - RM 9,500)",
		"Race 7 (Side Street - RM 7,300)",
		"Race 5 (Drag - RM 1,500)",
	}

	-- Telemetry Stats
	local totalRacesWon = 0
	local totalRaceCash = 0
	local totalDistanceTraveled = 0
	local totalDriveCash = 0
	local circleDriveStartTime = 0

	------------------------------------------------
	-- 🎛️ UI: FARM TAB
	------------------------------------------------

	-- 1. AUTO RACE UNDERGROUND SECTION
	local raceSection = UI.AddSection(tab, "Auto Race Underground (Stealth Farm)", 1)

	local raceStatusCard = UI.AddStatsCard(raceSection, "Race Status", "Idle", 2)
	local raceEarningsCard = UI.AddStatsCard(raceSection, "Race Earnings", "RM 0 (0 Wins)", 3)

	local raceDropdown = UI.AddDropdown(raceSection, "Select Track Target", raceDropdownList, Config.selectedRace, function(selected)
		Config.selectedRace = selected
	end, 4)

	local depthSlider = UI.AddSlider(raceSection, "Underground Depth", 10, 60, Config.undergroundDepth or 25, function(val)
		Config.undergroundDepth = val
	end, 1, " studs", 5)

	local delaySlider = UI.AddSlider(raceSection, "Checkpoint Delay", 0.05, 1.0, Config.checkpointDelay or 0.15, function(val)
		Config.checkpointDelay = val
	end, 0.05, "s", 6)

	local autoRaceToggle = UI.AddToggle(raceSection, "Enable Auto Race Underground", Config.autoRace, function(enabled)
		Config.autoRace = enabled
		_G.HipHub_IsAutoRacing = enabled
		if enabled then
			UI.Notify("Auto Race", "Started underground race farming!", 3, "success")
		else
			UI.Notify("Auto Race", "Stopped auto race.", 2, "info")
			raceStatusCard.Set("Stopped")
		end
	end, 7)

	-- 2. AUTO DRIVE MEMUTAR SECTION
	local driveSection = UI.AddSection(tab, "Auto Drive Memutar (Circular Odometer Farm)", 8)

	local driveStatusCard = UI.AddStatsCard(driveSection, "Drive Status", "Idle", 9)
	local driveDistCard = UI.AddStatsCard(driveSection, "Distance Traveled", "0.00 km", 10)

	local radiusSlider = UI.AddSlider(driveSection, "Ruas Lingkaran (Radius)", 15, 300, Config.circleRadius or 65, function(val)
		Config.circleRadius = val
	end, 5, " studs", 11)

	local speedSlider = UI.AddSlider(driveSection, "Kecepatan Memutar", 50, 250, Config.circleSpeed or 130, function(val)
		Config.circleSpeed = val
	end, 5, " km/h", 12)

	local autoDriveToggle = UI.AddToggle(driveSection, "Enable Auto Drive Memutar", Config.autoDriveCircle, function(enabled)
		Config.autoDriveCircle = enabled
		_G.HipHub_IsAutoDriving = enabled
		if enabled then
			circleDriveStartTime = os.clock()
			UI.Notify("Auto Drive", "Circular driving active (Radius: " .. Config.circleRadius .. " studs)", 3, "success")
		else
			UI.Notify("Auto Drive", "Stopped circular drive.", 2, "info")
			driveStatusCard.Set("Stopped")
		end
	end, 13)

	------------------------------------------------
	-- 🏁 UNDERGROUND AUTO RACE LOGIC
	------------------------------------------------

	-- Sort and get ordered checkpoints for a race model
	local function getCheckpointsForRace(raceModel)
		local folder = raceModel:FindFirstChild("Checkpoints")
		if not folder then return {} end

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

		local ordered = {}
		for _, item in ipairs(list) do
			table.insert(ordered, item.part)
		end
		return ordered
	end

	-- Execute one complete race cycle underground
	local function runRaceCycle()
		local raceData = RaceOptions[Config.selectedRace] or RaceOptions[raceDropdownList[1]]
		local raceModel = workspace:FindFirstChild(raceData.modelName)
		if not raceModel then
			raceStatusCard.Set("Error: Track model not found")
			return false
		end

		-- Step 1: Ensure Kasaki z800 2015 is spawned and player is seated
		raceStatusCard.Set("Ensuring driver seated...")
		local seated = false
		if _G.HipHub_EnsureSeated then
			seated = _G.HipHub_EnsureSeated(true)
		end
		if not seated then
			task.wait(1.0)
			return false
		end

		local bike, seat, primary = nil, nil, nil
		if _G.HipHub_GetPlayerBike then
			bike, seat, primary = _G.HipHub_GetPlayerBike()
		end
		if not bike or not seat then
			raceStatusCard.Set("Waiting for bike...")
			task.wait(1.0)
			return false
		end

		-- Step 2: Check for post-race cooldown
		local cooldownAttr = player:GetAttribute("RaceCooldownUntil")
		if type(cooldownAttr) == "number" then
			local rem = math.ceil(cooldownAttr - Workspace:GetServerTimeNow())
			if rem > 0 then
				raceStatusCard.Set(string.format("Cooldown: %d s", rem))
				task.wait(1.0)
				return true
			end
		end

		-- Step 3: Move bike to start area underground
		local startArea = raceModel:FindFirstChild("StartingArea")
		local startPos = startArea and startArea.Position or raceModel:GetPivot().Position
		local depth = Config.undergroundDepth or 25
		local undergroundStartCF = CFrame.new(startPos.X, startPos.Y - depth, startPos.Z)

		raceStatusCard.Set("Positioning at " .. raceData.modelName)
		bike:PivotTo(undergroundStartCF)
		task.wait(0.3)

		-- Step 4: Request solo race start via Warp
		raceStatusCard.Set("Starting Solo TimeTrial...")
		fireWarp("RaceSessionAction", true, "create", {
			zoneId = raceData.id,
			config = {
				Mode = "TimeTrial",
				Laps = 1,
				MaxPlayers = 1
			}
		})

		-- Step 5: Wait for race active / countdown
		local waitStart = os.clock()
		local started = false
		while (os.clock() - waitStart) < 8.0 do
			if not Config.autoRace then return false end
			local inRace = player:GetAttribute("InRace") or player:GetAttribute("lap") or player:GetAttribute("checkpoint")
			if inRace then
				started = true
				break
			end
			task.wait(0.25)
		end

		raceStatusCard.Set("Race Active! Traversing checkpoints...")

		-- Step 6: Traverse all checkpoints underground
		local checkpoints = getCheckpointsForRace(raceModel)
		if #checkpoints == 0 then
			raceStatusCard.Set("No checkpoints found in track")
			task.wait(2.0)
			return false
		end

		for i, cp in ipairs(checkpoints) do
			if not Config.autoRace then break end

			local nextCp = checkpoints[i + 1] or checkpoints[1]
			local cpPos = cp.Position
			local nextPos = nextCp and nextCp.Position or cpPos

			-- Move bike directly beneath checkpoint
			local undergroundPos = Vector3.new(cpPos.X, cpPos.Y - depth, cpPos.Z)
			local lookTarget = Vector3.new(nextPos.X, nextPos.Y - depth, nextPos.Z)
			local targetCF = CFrame.lookAt(undergroundPos, lookTarget)

			bike:PivotTo(targetCF)

			-- Trigger checkpoint via touch event while maintaining underground position
			pcall(function()
				if firetouchinterest then
					firetouchinterest(seat, cp, 0)
					task.wait(0.04)
					firetouchinterest(seat, cp, 1)
				end
			end)

			raceStatusCard.Set(string.format("Checkpoint %d / %d (Underground)", i, #checkpoints))

			task.wait(Config.checkpointDelay or 0.15)
		end

		-- Step 7: Completed race
		totalRacesWon = totalRacesWon + 1
		totalRaceCash = totalRaceCash + raceData.reward
		raceEarningsCard.Set(string.format("RM %s (%d Wins)", string.format("%.0f", totalRaceCash):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""), totalRacesWon))
		raceStatusCard.Set("Race Completed! Won RM " .. raceData.reward)

		UI.Notify("Auto Race", string.format("Completed %s (+RM %d)", raceData.modelName, raceData.reward), 3, "success")

		-- Wait brief pause before next loop
		task.wait(2.5)
		return true
	end

	-- Background Auto Race Routine
	task.spawn(function()
		while true do
			task.wait(0.5)
			if Config.autoRace then
				pcall(runRaceCycle)
			end
		end
	end)

	------------------------------------------------
	-- 🔄 CIRCULAR AUTO DRIVE (ODOMETER FARM)
	------------------------------------------------

	local circleCenter = nil
	local circleAngle = 0
	local lastDrivePos = nil

	-- Safety ground platform underneath bike
	local function ensureSafetyPlatform(pos)
		local plat = workspace:FindFirstChild("__HipHub_RoadPlat")
		if not plat then
			plat = Instance.new("Part")
			plat.Name = "__HipHub_RoadPlat"
			plat.Anchored = true
			plat.CanCollide = true
			plat.Transparency = 1
			plat.Size = Vector3.new(60, 2, 60)
			plat.Parent = workspace
		end
		plat.CFrame = CFrame.new(pos.X, pos.Y - 1.5, pos.Z)
		return plat
	end

	RunService.Heartbeat:Connect(function(dt)
		if not Config.autoDriveCircle or Config.autoRace then return end

		local bike, seat, primary = nil, nil, nil
		if _G.HipHub_GetPlayerBike then
			bike, seat, primary = _G.HipHub_GetPlayerBike()
		end

		if not bike or not seat or not primary then
			driveStatusCard.Set("Waiting for Kasaki z800...")
			return
		end

		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.SeatPart ~= seat then
			driveStatusCard.Set("Mounting bike...")
			if _G.HipHub_EnsureSeated then _G.HipHub_EnsureSeated(true) end
			return
		end

		-- Set circle center upon first run
		if not circleCenter then
			circleCenter = primary.Position
			circleAngle = 0
		end

		-- Circular motion mathematics
		local radius = math.max(Config.circleRadius or 65, 10)
		local speed = math.max(Config.circleSpeed or 130, 20) -- studs/s

		-- Angular speed omega = v / R
		local omega = speed / radius
		circleAngle = (circleAngle + omega * dt) % (2 * math.pi)

		local targetX = circleCenter.X + radius * math.cos(circleAngle)
		local targetZ = circleCenter.Z + radius * math.sin(circleAngle)

		-- Raycast to align with road surface
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = { bike, char, workspace:FindFirstChild("__HipHub_RoadPlat") }
		rayParams.FilterType = Enum.RaycastFilterType.Exclude

		local rayHit = workspace:Raycast(Vector3.new(targetX, circleCenter.Y + 15, targetZ), Vector3.new(0, -40, 0), rayParams)
		local groundY = rayHit and (rayHit.Position.Y + 2.4) or circleCenter.Y

		local targetPos = Vector3.new(targetX, groundY, targetZ)

		-- Tangent vector for forward look orientation
		local tangent = Vector3.new(-math.sin(circleAngle), 0, math.cos(circleAngle))
		local targetCF = CFrame.lookAt(targetPos, targetPos + tangent)

		-- Apply transform and maintain active throttle for odometer accumulation
		bike:PivotTo(targetCF)
		seat.Throttle = 1
		primary.AssemblyLinearVelocity = tangent * speed
		primary.AssemblyAngularVelocity = Vector3.new(0, omega, 0)

		ensureSafetyPlatform(targetPos)

		-- Distance telemetry
		if lastDrivePos then
			local d = (targetPos - lastDrivePos).Magnitude
			totalDistanceTraveled = totalDistanceTraveled + d
			local km = totalDistanceTraveled * 0.00028 -- Roblox studs to km
			driveDistCard.Set(string.format("%.2f km", km))
		end
		lastDrivePos = targetPos

		local elapsed = math.floor(os.clock() - circleDriveStartTime)
		driveStatusCard.Set(string.format("Radius: %d studs | %d km/h (%02d:%02d)", radius, math.floor(speed * 1.6), math.floor(elapsed / 60), elapsed % 60))
	end)

	-- Reset center on toggle off
	UI.tabs["Farm"].button.MouseButton1Click:Connect(function()
		if not Config.autoDriveCircle then
			circleCenter = nil
			lastDrivePos = nil
		end
	end)
end)

if not success then
	warn("[HipHub TR Legacy Farm Error]:", err)
end
