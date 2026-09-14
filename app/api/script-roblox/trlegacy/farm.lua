-- 🏁 HipHub TR Legacy — Auto Race Underground & Circular Auto Drive Suite
-- Smooth underground flight traversal between checkpoints and circular underground odometer farm

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local tab = UI.tabs["Farm"] and UI.tabs["Farm"].Frame
	if not tab then return end

	local Config = _G.HipHubConfig and _G.HipHubConfig.farm or {
		autoRace = false,
		selectedRace = "Race 2 (Small Circuit - RM 11,000)",
		undergroundDepth = 25,
		raceFlySpeed = 260,
		checkpointDelay = 0.02,
		returnToSurface = true,
		autoDriveCircle = false,
		circleRadius = 65,
		circleSpeed = 150,
		antiStuck = true,
		autoLoop = true
	}

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

	-- Race definitions with IDs and rewards (Updated for current TR Legacy map)
	local RaceOptions = {
		["Race 2 (Small Circuit - RM 11,000)"]     = { id = "2", modelName = "Race2", reward = 11000, maxTime = 35 },
		["Race 8 (Around The World - RM 38,000)"] = { id = "8", modelName = "Race8", reward = 38000, maxTime = 100 },
		["Race 4 (Highway - RM 27,000)"]           = { id = "4", modelName = "Race4", reward = 27000, maxTime = 90 },
		["Race 3 (GP Track - RM 18,500)"]          = { id = "3", modelName = "Race3", reward = 18500, maxTime = 60 },
		["Race 6 (Lake Race - RM 9,500)"]          = { id = "6", modelName = "Race6", reward = 9500,  maxTime = 40 },
		["Race 7 (Side Street - RM 7,300)"]        = { id = "7", modelName = "Race7", reward = 7300,  maxTime = 40 },
		["Race 5 (Drag - RM 1,500)"]               = { id = "5", modelName = "Race5", reward = 1500,  maxTime = 30 },
	}

	local raceDropdownList = {
		"Race 2 (Small Circuit - RM 11,000)",
		"Race 8 (Around The World - RM 38,000)",
		"Race 4 (Highway - RM 27,000)",
		"Race 3 (GP Track - RM 18,500)",
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
			local ray = workspace:Raycast(Vector3.new(curPos.X, 250, curPos.Z), Vector3.new(0, -500, 0), rayParams)
			local groundY = (ray and ray.Position.Y > -5) and (ray.Position.Y + 2.5) or 2.5
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

	-- 2. AUTO DRIVE MEMUTAR SECTION (KHUSUS DI ATAS TANAH)
	local driveSection = UI.AddSection(tab, "Auto Drive Memutar (Khusus Di Atas Tanah)", 9)

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

	local antiStuckToggle = UI.AddToggle(driveSection, "Anti-Stuck & Ghost Noclip (Tembus Rintangan)", Config.antiStuck ~= false, function(v)
		Config.antiStuck = v
	end, 16)

	local unstuckBtn = UI.AddButton(driveSection, "🚨 Unstuck Manual (Lepaskan Motor)", function()
		local bike, _, primary = _G.HipHub_GetPlayerBike and _G.HipHub_GetPlayerBike()
		if bike and primary then
			local look = primary.CFrame.LookVector
			bike:PivotTo(bike:GetPivot() + Vector3.new(0, 4, 0) + (look * 10))
			primary.AssemblyLinearVelocity = look * 120 + Vector3.new(0, 15, 0)
			UI.Notify("Anti-Stuck", "Motor dilepaskan dari rintangan!", 2, "success")
		end
	end, 17)

	local autoDriveToggle = UI.AddToggle(driveSection, "Enable Auto Drive Memutar (Di Atas Tanah)", Config.autoDriveCircle, function(enabled)
		Config.autoDriveCircle = enabled
		_G.HipHub_IsAutoDriving = enabled
		if enabled then
			circleDriveStartTime = os.clock()
			startDriveCash = nil
			startDriveMiles = nil
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
	end, 18)

	------------------------------------------------
	-- 🏁 UNDERGROUND AUTO RACE LOGIC
	------------------------------------------------

	local function getCheckpointsForRace(raceModel)
		local ordered = nil
		pcall(function()
			local getOrdered = require(ReplicatedStorage.Modules.UI.Racing.Utility.getOrderedCheckpoints)
			ordered = getOrdered(raceModel)
		end)
		if ordered and #ordered > 0 then return ordered end

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

		local res = {}
		for _, item in ipairs(list) do
			table.insert(res, item.part)
		end
		return res
	end

	local function runRaceCycle()
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

		-- Step 3: Teleport bike to StartingArea bounding box
		local startArea = raceModel:FindFirstChild("StartingArea") or raceModel:GetPivot()
		raceStatusCard.Set("Menuju Starting Area " .. raceData.modelName .. "...")
		for _, p in ipairs(bike:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = false end
		end
		local startCF = (startArea:IsA("BasePart") and startArea.CFrame or startArea) + Vector3.new(0, 1.5, 0)
		bike:PivotTo(startCF)
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
			task.wait(0.2)
			if racingUI and racingUI:FindFirstChild("MainFrame") then
				menuPanel = racingUI.MainFrame:FindFirstChild("MenuPanel")
			end
		end

		-- Step 5: Hook RaceStartLights for strict countdown synchronization
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
		raceStatusCard.Set("Mendaftarkan Solo Race...")
		local footer = menuPanel and menuPanel:FindFirstChild("Footer")
		local quickBtn = footer and footer:FindFirstChild("Quick")
		if quickBtn then
			local tQuick = os.clock()
			while not quickBtn.Interactable and (os.clock() - tQuick) < 3 and Config.autoRace do
				task.wait(0.1)
			end
			for _, c in ipairs(getconnections(quickBtn.Activated)) do c:Fire() end
		else
			fireWarp("RaceSessionAction", true, "create", {
				zoneId = raceData.id,
				config = { Mode = "TimeTrial", Laps = 1, MaxPlayers = 1 }
			})
		end

		-- Check if a start card appeared in active sessions
		task.wait(0.8)
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

		-- Step 7: STRICT ANTICHEAT COUNTDOWN - Wait until lights go OUT!
		raceStatusCard.Set("Menunggu countdown lampu race (GO)...")
		local tWaitLights = os.clock()
		while not lightsOut and (os.clock() - tWaitLights) < 14 and Config.autoRace do
			task.wait(0.1)
		end

		-- STRICT FAIL-SAFE: If the race did not legitimately start, ABORT IMMEDIATELY!
		-- NEVER fly or touch checkpoints if not in an active race session!
		local activeRaceId = player:GetAttribute("InRace")
		if not lightsOut or not activeRaceId then
			raceStatusCard.Set("Gagal mulai: Sesi balapan tidak aktif / sedang dipakai. Membatalkan...")
			if lightsConn and startLightsClient then
				pcall(function() startLightsClient:Disconnect(lightsConn) end)
			end
			task.wait(3.0)
			return false
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

		local flySpeed = math.clamp(Config.raceFlySpeed or 260, 100, 450)
		local initialCash = (player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Cash")) and player.leaderstats.Cash.Value or totalRaceCash

		for i, cp in ipairs(checkpoints) do
			if not Config.autoRace then break end

			local targetPos = cp.Position
			local arrived = false
			local cpTimeout = os.clock() + 12.0

			while not arrived and Config.autoRace and os.clock() < cpTimeout do
				local dt = RunService.Heartbeat:Wait()
				local cur = primary.Position
				local diff = targetPos - cur
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

				bike:PivotTo(CFrame.lookAt(newPos, newPos + dir * 10))
				primary.AssemblyLinearVelocity = dir * flySpeed
				primary.AssemblyAngularVelocity = Vector3.zero
				seat.Throttle = 1

				if dist < 25 and firetouchinterest then
					pcall(function()
						firetouchinterest(seat, cp, 0)
						firetouchinterest(primary, cp, 0)
						firetouchinterest(seat, cp, 1)
						firetouchinterest(primary, cp, 1)
					end)
				end

				raceStatusCard.Set(string.format("Checkpoint %d / %d (%.0fm | %d studs/s)", i, #checkpoints, dist, flySpeed))
			end

			if firetouchinterest then
				pcall(function()
					firetouchinterest(seat, cp, 0)
					firetouchinterest(primary, cp, 0)
					task.wait(0.02)
					firetouchinterest(seat, cp, 1)
					firetouchinterest(primary, cp, 1)
				end)
			end

			if Config.checkpointDelay and Config.checkpointDelay > 0 then
				task.wait(Config.checkpointDelay)
			end
		end

		if lightsConn and startLightsClient then
			pcall(function() startLightsClient:Disconnect(lightsConn) end)
		end

		-- Step 9: Race finished and payout verification
		task.wait(2.0)
		local currentCash = (player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Cash")) and player.leaderstats.Cash.Value or initialCash
		local earned = math.max(currentCash - initialCash, raceData.reward)

		totalRacesWon = totalRacesWon + 1
		totalRaceCash = totalRaceCash + earned
		raceEarningsCard.Set(string.format("RM %s (%d Wins)", string.format("%.0f", totalRaceCash):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""), totalRacesWon))
		raceStatusCard.Set(string.format("Selesai! Menang RM %d", earned))

		UI.Notify("Auto Race", string.format("Finish %s (+RM %d)", raceData.modelName, earned), 3, "success")

		task.wait(1.5)
		return true
	end

	local currentSessionToken = os.clock()
	_G.HipHub_FarmSessionToken = currentSessionToken

	_G.HipHub_ToggleAutoRace = function(val)
		Config.autoRace = val
		_G.HipHub_IsAutoRacing = val
	end

	_G.HipHub_ToggleAutoDrive = function(val)
		Config.autoDriveCircle = val
		_G.HipHub_IsAutoDriving = val
	end

	-- Background Auto Race Routine
	task.spawn(function()
		while _G.HipHub_FarmSessionToken == currentSessionToken do
			task.wait(0.5)
			if Config.autoRace or _G.HipHub_IsAutoRacing then
				local ok, err = pcall(runRaceCycle)
				if not ok then
					warn("[HipHub AutoRace Loop Error]:", err)
				end
			end
		end
	end)

	------------------------------------------------
	-- 🔄 CIRCULAR AUTO DRIVE (ODOMETER & CASH)
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
		if not circleCenter then
			local curPos = primary.Position
			local right = primary.CFrame.RightVector
			circleCenter = curPos + Vector3.new(right.X, 0, right.Z).Unit * radius
			noclipBikeBody(bike)
		end

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
						driveStatusCard.Set("🚨 Meloloskan dari rintangan...")
						
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
				driveCashCard.Set(string.format("RM %s (+RM %d)", string.format("%.0f", curCash):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""), diffCash))
				driveMilesCard.Set(string.format("%d mi (+%d mi)", curMiles, diffMiles))
			end
		end)

		local elapsed = math.floor(os.clock() - circleDriveStartTime)
		driveStatusCard.Set(string.format("Di Atas Tanah | R: %d | %d km/h (%02d:%02d)", radius, speed, math.floor(elapsed / 60), elapsed % 60))
	end)
end)

if not success then
	warn("[HipHub TR Legacy Farm Error]:", err)
end
