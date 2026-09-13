-- 🏁 HipHub TR Legacy — Auto Race Underground & Circular Auto Drive Suite
-- Smooth underground flight traversal between checkpoints and circular underground odometer farm

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local tab = UI.tabs["Farm"] and UI.tabs["Farm"].Frame
	if not tab then return end

	local Config = _G.HipHubConfig and _G.HipHubConfig.farm or {
		autoRace = false,
		selectedRace = "Race 1 (Mountain Race - RM 53,000)",
		undergroundDepth = 25,
		raceFlySpeed = 260,
		checkpointDelay = 0.02,
		returnToSurface = true,
		autoDriveCircle = false,
		circleRadius = 65,
		circleSpeed = 150,
		driveDepth = 25,
		autoLoop = true
	}

	if Config.driveUnderground == nil then Config.driveUnderground = true end
	if Config.driveDepth == nil then Config.driveDepth = 25 end
	if Config.circleRadius == nil then Config.circleRadius = 65 end
	if Config.circleSpeed == nil then Config.circleSpeed = 150 end

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
	local circleDriveStartTime = 0
	local startDriveCash = nil
	local startDriveMiles = nil

	-- Helper: Safely return bike to ground surface
	local function returnBikeToSurface(bike, primary)
		if not bike or not primary then return end
		pcall(function()
			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = { bike, player.Character }
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			local curPos = primary.Position
			local ray = workspace:Raycast(Vector3.new(curPos.X, curPos.Y + 150, curPos.Z), Vector3.new(0, -300, 0), rayParams)
			local groundY = ray and (ray.Position.Y + 3.0) or (curPos.Y + (Config.undergroundDepth or 25) + 3.0)
			bike:PivotTo(CFrame.new(curPos.X, groundY, curPos.Z))
			primary.AssemblyLinearVelocity = Vector3.zero
			primary.AssemblyAngularVelocity = Vector3.zero
		end)
	end

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

	local flySpeedSlider = UI.AddSlider(raceSection, "Kecepatan Fly Race", 100, 500, Config.raceFlySpeed or 260, function(val)
		Config.raceFlySpeed = val
	end, 10, " studs/s", 6)

	local delaySlider = UI.AddSlider(raceSection, "Checkpoint Delay", 0.00, 0.30, Config.checkpointDelay or 0.02, function(val)
		Config.checkpointDelay = val
	end, 0.01, "s", 7)

	local autoRaceToggle = UI.AddToggle(raceSection, "Enable Auto Race Underground", Config.autoRace, function(enabled)
		Config.autoRace = enabled
		_G.HipHub_IsAutoRacing = enabled
		if enabled then
			UI.Notify("Auto Race", "Memulai race bawah tanah (Fly ke tiap checkpoint)...", 3, "success")
		else
			UI.Notify("Auto Race", "Menghentikan auto race.", 2, "info")
			raceStatusCard.Set("Stopped")
			if Config.returnToSurface then
				local bike, _, primary = _G.HipHub_GetPlayerBike and _G.HipHub_GetPlayerBike()
				returnBikeToSurface(bike, primary)
			end
		end
	end, 8)

	-- 2. AUTO DRIVE MEMUTAR SECTION
	local driveSection = UI.AddSection(tab, "Auto Drive Memutar (Odometer & Cash Farm)", 9)

	local driveStatusCard = UI.AddStatsCard(driveSection, "Drive Status", "Idle", 10)
	local driveCashCard = UI.AddStatsCard(driveSection, "Live Cash / Balance", "RM 0 (+RM 0)", 11)
	local driveMilesCard = UI.AddStatsCard(driveSection, "Odometer Miles", "0 mi (+0 mi)", 12)
	local driveDistCard = UI.AddStatsCard(driveSection, "Distance Traveled", "0.00 km", 13)

	local radiusSlider = UI.AddSlider(driveSection, "Ruas Lingkaran (Radius)", 15, 300, Config.circleRadius or 65, function(val)
		Config.circleRadius = val
	end, 5, " studs", 14)

	local driveSpeedSlider = UI.AddSlider(driveSection, "Kecepatan Memutar", 50, 300, Config.circleSpeed or 150, function(val)
		Config.circleSpeed = val
	end, 5, " km/h", 15)

	local driveDepthSlider = UI.AddSlider(driveSection, "Drive Underground Depth", 10, 60, Config.driveDepth or 25, function(val)
		Config.driveDepth = val
	end, 1, " studs", 16)

	local driveUgToggle = UI.AddToggle(driveSection, "Drive Underground (Sembunyi Bawah Tanah)", Config.driveUnderground ~= false, function(v)
		Config.driveUnderground = v
	end, 17)

	local autoDriveToggle = UI.AddToggle(driveSection, "Enable Auto Drive Memutar", Config.autoDriveCircle, function(enabled)
		Config.autoDriveCircle = enabled
		_G.HipHub_IsAutoDriving = enabled
		if enabled then
			circleDriveStartTime = os.clock()
			startDriveCash = nil
			startDriveMiles = nil
			UI.Notify("Auto Drive", "Memulai circular drive (Radius: " .. Config.circleRadius .. " studs)", 3, "success")
		else
			UI.Notify("Auto Drive", "Menghentikan circular drive.", 2, "info")
			driveStatusCard.Set("Stopped")
			startDriveCash = nil
			startDriveMiles = nil
			local bike, _, primary = _G.HipHub_GetPlayerBike and _G.HipHub_GetPlayerBike()
			returnBikeToSurface(bike, primary)
		end
	end, 18)

	------------------------------------------------
	-- 🏁 UNDERGROUND AUTO RACE LOGIC
	------------------------------------------------

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

	local function runRaceCycle()
		if not Config.autoRace then return false end

		local raceData = RaceOptions[Config.selectedRace] or RaceOptions[raceDropdownList[1]]
		local raceModel = workspace:FindFirstChild(raceData.modelName)
		if not raceModel then
			raceStatusCard.Set("Error: Track model not found")
			return false
		end

		-- Step 1: Ensure Kasaki z800 2015 is spawned and player is seated
		raceStatusCard.Set("Memeriksa motor & driver...")
		local seated = false
		if _G.HipHubVehicle and _G.HipHubVehicle.EnsureDriverSeated then
			seated = _G.HipHubVehicle.EnsureDriverSeated(true)
		end
		if not seated then
			task.wait(1.0)
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
				raceStatusCard.Set(string.format("Cooldown: %d s", rem))
				task.wait(1.0)
				return true
			end
		end

		-- Step 3: Descend underground at starting area
		local startArea = raceModel:FindFirstChild("StartingArea")
		local startPos = startArea and startArea.Position or raceModel:GetPivot().Position
		local depth = Config.undergroundDepth or 25
		local undergroundStartPos = Vector3.new(startPos.X, startPos.Y - depth, startPos.Z)

		raceStatusCard.Set("Menyelam ke bawah tanah...")
		
		-- Smooth vertical descent
		local curPos = primary.Position
		local tDescend = 0.35
		local t0 = os.clock()
		while (os.clock() - t0) < tDescend and Config.autoRace do
			local alpha = (os.clock() - t0) / tDescend
			local interpY = curPos.Y + (undergroundStartPos.Y - curPos.Y) * alpha
			for _, p in ipairs(bike:GetDescendants()) do
				if p:IsA("BasePart") then p.CanCollide = false end
			end
			bike:PivotTo(CFrame.new(startPos.X, interpY, startPos.Z))
			RunService.Heartbeat:Wait()
		end
		bike:PivotTo(CFrame.new(undergroundStartPos))
		task.wait(0.2)

		-- Step 4: Request solo race start via Warp
		raceStatusCard.Set("Mendaftarkan Solo TimeTrial...")
		fireWarp("RaceSessionAction", true, "create", {
			zoneId = raceData.id,
			config = {
				Mode = "TimeTrial",
				Laps = 1,
				MaxPlayers = 1
			}
		})

		-- Step 5: Wait for race countdown / active status
		local waitStart = os.clock()
		local started = false
		while (os.clock() - waitStart) < 7.0 do
			if not Config.autoRace then return false end
			local inRace = player:GetAttribute("InRace") or player:GetAttribute("lap") or player:GetAttribute("checkpoint")
			if inRace then
				started = true
				break
			end
			for _, p in ipairs(bike:GetDescendants()) do
				if p:IsA("BasePart") then p.CanCollide = false end
			end
			bike:PivotTo(CFrame.new(undergroundStartPos))
			primary.AssemblyLinearVelocity = Vector3.zero
			task.wait(0.2)
		end

		raceStatusCard.Set("Race Dimulai! Terbang ke tiap checkpoint...")

		-- Step 6: Smoothly FLY underground towards each checkpoint
		local checkpoints = getCheckpointsForRace(raceModel)
		if #checkpoints == 0 then
			raceStatusCard.Set("Tidak ada checkpoint ditemukan.")
			task.wait(2.0)
			return false
		end

		local flySpeed = math.clamp(Config.raceFlySpeed or 260, 80, 600)

		for i, cp in ipairs(checkpoints) do
			if not Config.autoRace then break end

			local cpPos = cp.Position
			local targetUnderground = Vector3.new(cpPos.X, cpPos.Y - depth, cpPos.Z)

			-- Smooth fly loop towards target checkpoint
			local arrived = false
			local timeout = os.clock() + 15.0

			while not arrived and Config.autoRace and os.clock() < timeout do
				local dt = RunService.Heartbeat:Wait()
				local cur = primary.Position
				local diff = (targetUnderground - cur)
				local dist = diff.Magnitude

				if dist <= 12 then
					arrived = true
					break
				end

				for _, p in ipairs(bike:GetDescendants()) do
					if p:IsA("BasePart") then p.CanCollide = false end
				end

				local dir = diff.Unit
				local step = math.min(flySpeed * dt, dist)
				local newPos = cur + dir * step

				local lookAhead = newPos + dir * 10
				bike:PivotTo(CFrame.lookAt(newPos, lookAhead))

				primary.AssemblyLinearVelocity = dir * flySpeed
				primary.AssemblyAngularVelocity = Vector3.zero
				seat.Throttle = 1

				if dist < 25 then
					pcall(function()
						if firetouchinterest then
							firetouchinterest(seat, cp, 0)
							firetouchinterest(seat, cp, 1)
						end
					end)
				end

				raceStatusCard.Set(string.format("Checkpoint %d / %d (%.0fm | %d studs/s)", i, #checkpoints, dist, flySpeed))
			end

			pcall(function()
				if firetouchinterest then
					firetouchinterest(seat, cp, 0)
					task.wait(0.02)
					firetouchinterest(seat, cp, 1)
				end
			end)

			if Config.checkpointDelay and Config.checkpointDelay > 0 then
				task.wait(Config.checkpointDelay)
			end
		end

		-- Step 7: Completed race
		totalRacesWon = totalRacesWon + 1
		totalRaceCash = totalRaceCash + raceData.reward
		raceEarningsCard.Set(string.format("RM %s (%d Wins)", string.format("%.0f", totalRaceCash):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""), totalRacesWon))
		raceStatusCard.Set("Selesai! Menang RM " .. raceData.reward)

		UI.Notify("Auto Race", string.format("Finish %s (+RM %d)", raceData.modelName, raceData.reward), 3, "success")

		task.wait(2.0)
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
	-- 🔄 CIRCULAR AUTO DRIVE (ODOMETER & CASH)
	------------------------------------------------

	local circleCenter = nil
	local lastDrivePos = nil
	local undergroundTrack = nil

	-- Raycast surface finder
	local function getGroundSurfaceY(posX, posZ, ignoreBike)
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = { ignoreBike, player.Character }
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local ray = workspace:Raycast(Vector3.new(posX, 250, posZ), Vector3.new(0, -500, 0), rayParams)
		return ray and ray.Position.Y or 0.5
	end

	_G.HipHub_FarmCleanup = _G.HipHub_FarmCleanup or {}
	if _G.HipHub_FarmCleanup.DriveConn then
		pcall(function() _G.HipHub_FarmCleanup.DriveConn:Disconnect() end)
		_G.HipHub_FarmCleanup.DriveConn = nil
	end

	_G.HipHub_FarmCleanup.DriveConn = RunService.Heartbeat:Connect(function(dt)
		if not Config.autoDriveCircle or Config.autoRace then
			if circleCenter then
				circleCenter = nil
				lastDrivePos = nil
				if undergroundTrack and undergroundTrack.Parent then
					pcall(function() undergroundTrack:Destroy() end)
					undergroundTrack = nil
				end
				if Config.driveUnderground and Config.returnToSurface ~= false then
					local bike, _, primary = _G.HipHub_GetPlayerBike and _G.HipHub_GetPlayerBike()
					returnBikeToSurface(bike, primary)
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
		if not hum or hum.SeatPart ~= seat then
			driveStatusCard.Set("Mendudukkan driver...")
			if _G.HipHubVehicle and _G.HipHubVehicle.EnsureDriverSeated then
				_G.HipHubVehicle.EnsureDriverSeated(true)
			end
			return
		end

		-- Set circle center upon first run using surface raycast
		if not circleCenter then
			local curPos = primary.Position
			local surfaceY = getGroundSurfaceY(curPos.X, curPos.Z, bike)
			local depth = Config.driveUnderground and (Config.driveDepth or Config.undergroundDepth or 25) or 0
			local targetY = Config.driveUnderground and (surfaceY - depth) or (surfaceY + 1.2)
			circleCenter = Vector3.new(curPos.X, targetY, curPos.Z)

			local radius = math.max(Config.circleRadius or 65, 15)

			-- Spawn massive invisible client-side road platform for realistic grounded tire traction & suspension
			if Config.driveUnderground then
				if undergroundTrack and undergroundTrack.Parent then
					pcall(function() undergroundTrack:Destroy() end)
				end
				undergroundTrack = Instance.new("Part")
				undergroundTrack.Name = "HipHub_UndergroundTrack"
				undergroundTrack.Size = Vector3.new(2048, 2, 2048)
				undergroundTrack.Position = Vector3.new(circleCenter.X, targetY - 1, circleCenter.Z)
				undergroundTrack.Anchored = true
				undergroundTrack.CanCollide = true
				undergroundTrack.Transparency = 1
				undergroundTrack.Material = Enum.Material.Asphalt
				undergroundTrack.Friction = 0.8
				undergroundTrack.Parent = workspace
			end

			local initialPos = Vector3.new(circleCenter.X + radius, targetY + 1.2, circleCenter.Z)
			local initialLook = Vector3.new(0, 0, 1)
			bike:PivotTo(CFrame.lookAt(initialPos, initialPos + initialLook))

			-- Enable collisions so wheels physically grip the road
			for _, desc in ipairs(bike:GetDescendants()) do
				if desc:IsA("BasePart") then
					desc.CanCollide = true
				end
			end
		end

		local curPos = primary.Position
		local radius = math.max(Config.circleRadius or 65, 15)
		local speed = math.max(Config.circleSpeed or 120, 40)
		local baseOmega = speed / radius

		-- Distance from circle center & proportional steering feedback
		local diff = Vector3.new(curPos.X - circleCenter.X, 0, curPos.Z - circleCenter.Z)
		local currentDist = diff.Magnitude
		local distErr = radius - currentDist
		local steerAdj = math.clamp(-distErr * 0.05, -0.6, 0.6)
		local activeOmega = baseOmega + steerAdj

		-- Vertical height lock (underground road contact or surface gravity)
		local vy
		if Config.driveUnderground then
			local targetSurfaceY = circleCenter.Y + 1.2
			local yErr = targetSurfaceY - curPos.Y
			if curPos.Y < circleCenter.Y then
				vy = 20
			else
				vy = math.clamp(yErr * 6.0, -25, 25)
			end
		else
			vy = primary.AssemblyLinearVelocity.Y
		end

		-- Pure physics velocity along LookVector: NEVER assigns CFrame or calls PivotTo
		local look = primary.CFrame.LookVector
		seat.Throttle = 1
		primary.AssemblyLinearVelocity = Vector3.new(look.X * speed, vy, look.Z * speed)
		primary.AssemblyAngularVelocity = Vector3.new(0, activeOmega, 0)

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
				driveCashCard.Set(string.format("RM %s (+RM %d)", string.format("%.0f", curCash):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""), diffCash))
				driveMilesCard.Set(string.format("%d mi (+%d mi)", curMiles, diffMiles))
			end
		end)

		local elapsed = math.floor(os.clock() - circleDriveStartTime)
		local locStr = Config.driveUnderground and "Bawah Tanah" or "Permukaan"
		driveStatusCard.Set(string.format("%s | R: %d | %d km/h (%02d:%02d)", locStr, radius, speed, math.floor(elapsed / 60), elapsed % 60))
	end)
end)

if not success then
	warn("[HipHub TR Legacy Farm Error]:", err)
end
