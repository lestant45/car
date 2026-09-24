-- 💰 HipHub BXI — Auto Farm, AssemblyLinearVelocity Driving & Money Generation System
-- Bus X Indonesia (Place ID: 137806249434874)
-- High-Performance Road Physics Engine: AssemblyLinearVelocity Driving (No Teleportation)

local success, err = pcall(function()
	local UI = _G.HipHubUI
	if not UI then return end

	local tab = UI.tabs["Farm"].content
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local TweenService = game:GetService("TweenService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local player = Players.LocalPlayer

	local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	local Config = _G.HipHubConfig and _G.HipHubConfig.farm or {
		autoBusJob = false,
		selectedRoute = "Baranangsiang_ke_Rambutan",
		targetSpeed = 80,
		tripPacing = true,
		arriveDelay = 180,
		jobCooldown = 5,
		autoNextJob = true,
		autoClaimQuests = true,
		autoSpinBox = false,
		selectedBox = "Event",
		targetEarn = 0
	}
	if Config.tripPacing == nil then Config.tripPacing = true end
	if Config.targetSpeed == nil then Config.targetSpeed = 80 end

	------------------------------------------------
	-- 📊 AUTO FARM STATE & METRICS
	------------------------------------------------
	local FARM_STATE = {
		IDLE = "Idle",
		PREPARING_BUS = "PreparingBus",
		STARTING_JOB = "StartingJob",
		DRIVING_CHECKPOINT = "DrivingToCheckpoint",
		PACING = "Pacing",
		WAITING_PASSENGERS = "WaitingPassengers",
		DRIVING_FINAL = "DrivingToFinal",
		JOB_COMPLETED = "JobCompleted"
	}

	local currentFarmState = FARM_STATE.IDLE
	local isFarmRunning = false
	local currentRouteId = Config.selectedRoute or "Baranangsiang_ke_Rambutan"
	local currentTerminalId = "Baranangsiang"

	-- Live Stats
	local totalEarnings = 0
	local totalRoutesDone = 0
	local farmStartTime = os.clock()
	local currentActivityText = "Idle"
	local currentCheckpointText = "None"

	-- Dashboard UI References
	local statEarnCard = nil
	local statRouteCard = nil
	local statCheckpointCard = nil
	local statUptimeCard = nil
	local activityLabel = nil

	local function setFarmState(newState, reason)
		local newText = tostring(newState) .. (reason and (" (" .. reason .. ")") or "")
		if currentFarmState ~= newState or currentActivityText ~= newText then
			currentFarmState = newState
			currentActivityText = newText
			if activityLabel then
				pcall(function() activityLabel.Set("📍 Status: " .. currentActivityText) end)
			end
		end
	end

	local function formatRp(amount)
		amount = math.floor(tonumber(amount) or 0)
		local str = tostring(amount):reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
		return "Rp " .. str
	end

	-- Clean up any legacy artificial plate that may block ground triggers
	pcall(function()
		local oldPlate = workspace:FindFirstChild("__SafetyPlate")
		if oldPlate then oldPlate:Destroy() end
	end)

	local function requestStreamAsync(pos)
		pcall(function()
			if player and player.RequestStreamAroundAsync then
				task.spawn(function()
					pcall(function() player:RequestStreamAroundAsync(pos, 2) end)
				end)
			end
		end)
	end

	------------------------------------------------
	-- 🚌 BUS SPAWN & MOUNT HELPERS
	------------------------------------------------
	local BUS_SEAT_GROUND_OFFSET = 6.02 -- Measured exact factory height of Jetbus DriveSeat above road asphalt

	local function getMyBus()
		local spawned = workspace:FindFirstChild("SpawnedVehicles")
		if not spawned then return nil end

		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local currentSeat = hum and hum.SeatPart
		if currentSeat then
			for _, v in ipairs(spawned:GetChildren()) do
				if currentSeat:IsDescendantOf(v) then
					return v
				end
			end
		end

		local buses = spawned:GetChildren()
		return buses[1]
	end

	local function getDriverSeat(bus)
		bus = bus or getMyBus()
		if not bus then return nil end
		local seat = bus:FindFirstChild("DriveSeat", true) or bus:FindFirstChildWhichIsA("VehicleSeat", true)
		if seat and bus.PrimaryPart ~= seat then
			pcall(function() bus.PrimaryPart = seat end)
		end
		return seat
	end

	local function ensureBusAndSeat()
		local bus = getMyBus()
		if not bus then
			setFarmState(FARM_STATE.PREPARING_BUS, "Spawning Bus")
			if Remotes:FindFirstChild("SpawnCar") then
				Remotes.SpawnCar:FireServer("Jetbus_3_RM _SHD")
				task.wait(1.5)
			end
			bus = getMyBus()
		end

		if not bus then return nil, nil end

		local seat = getDriverSeat(bus)
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")

		if seat and hum and hrp then
			if bus.PrimaryPart ~= seat then
				pcall(function() bus.PrimaryPart = seat end)
			end
			if hum.SeatPart ~= seat then
				hrp.CFrame = seat.CFrame + Vector3.new(0, 2, 0)
				task.wait(0.2)
				seat:Sit(hum)
				task.wait(0.3)
			end
		end

		return bus, seat
	end

	------------------------------------------------
	-- 🛑 HANDBRAKE & ANTI-ROLL POSITION LOCK
	------------------------------------------------
	local checkpointHoldConn = nil

	local function ensureEngineOn()
		pcall(function()
			local achassisGui = player.PlayerGui:FindFirstChild("A-Chassis Interface")
			if achassisGui then
				local isOn = achassisGui:FindFirstChild("IsOn", true)
				if isOn and not isOn.Value then
					isOn.Value = true
				end
				local pbrake = achassisGui:FindFirstChild("Values") and achassisGui.Values:FindFirstChild("PBrake")
				if pbrake and pbrake.Value then
					pbrake.Value = false
				end
			end
		end)
	end

	local function setHandbrake(enabled)
		pcall(function()
			local achassisGui = player.PlayerGui:FindFirstChild("A-Chassis Interface")
			local pbrakeVal = achassisGui and achassisGui:FindFirstChild("Values") and achassisGui.Values:FindFirstChild("PBrake")
			if pbrakeVal and pbrakeVal.Value ~= enabled then
				local vim = game:GetService("VirtualInputManager")
				if vim then
					vim:SendKeyEvent(true, Enum.KeyCode.P, false, game)
					task.wait(0.04)
					vim:SendKeyEvent(false, Enum.KeyCode.P, false, game)
				end
			end

			-- Double sync all PBrake value instances in bus & gui
			if pbrakeVal then pbrakeVal.Value = enabled end
			local curBus = getMyBus()
			if curBus then
				for _, d in ipairs(curBus:GetDescendants()) do
					if d.Name == "PBrake" and d:IsA("BoolValue") then
						d.Value = enabled
					end
				end
			end
		end)
	end

	local function holdCheckpointPosition()
		if checkpointHoldConn then
			checkpointHoldConn:Disconnect()
			checkpointHoldConn = nil
		end
		setHandbrake(true)

		checkpointHoldConn = RunService.Heartbeat:Connect(function()
			if not isFarmRunning then return end
			local curBus = getMyBus()
			local curSeat = getDriverSeat(curBus)
			if not (curBus and curSeat) then return end

			curSeat.AssemblyLinearVelocity = Vector3.zero
			curSeat.AssemblyAngularVelocity = Vector3.zero
			curSeat.Throttle = 0
			curSeat.Steer = 0
		end)
	end

	local function releaseCheckpointHold()
		if checkpointHoldConn then
			checkpointHoldConn:Disconnect()
			checkpointHoldConn = nil
		end
		setHandbrake(false)
	end

	------------------------------------------------
	-- 🏎️ ASSEMBLY LINEAR VELOCITY ROAD DRIVING ENGINE
	------------------------------------------------
	local isDrivingActive = false
	local currentDriveConn = nil

	local function probeGround(pos, fallbackY)
		local char = player.Character
		local bus = getMyBus()

		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local filterList = { char, bus }

		local spawned = workspace:FindFirstChild("SpawnedVehicles")
		if spawned then table.insert(filterList, spawned) end
		local checkpoints = workspace:FindFirstChild("Checkpoints")
		if checkpoints then table.insert(filterList, checkpoints) end
		local triggers = workspace:FindFirstChild("BusJobTriggers")
		if triggers then table.insert(filterList, triggers) end
		local endTriggers = workspace:FindFirstChild("BusJobEndTriggers")
		if endTriggers then table.insert(filterList, endTriggers) end
		local safety = workspace:FindFirstChild("__SafetyPlate")
		if safety then table.insert(filterList, safety) end
		local esp = workspace.CurrentCamera:FindFirstChild("HipHub_BXI_ESP")
		if esp then table.insert(filterList, esp) end
		local cam = workspace.CurrentCamera
		if cam then table.insert(filterList, cam) end

		rayParams.FilterDescendantsInstances = filterList

		-- Safe downwards probe: ray starts at pos.Y (near seat height, ~6 studs above road) and casts down 45 studs
		local rayOrigin = Vector3.new(pos.X, pos.Y, pos.Z)
		local rayDir = Vector3.new(0, -45, 0)
		local hit = workspace:Raycast(rayOrigin, rayDir, rayParams)

		-- Strictly accept only surfaces below ray origin to filter out overhead roofs, overpasses, and signs
		if hit and hit.Position.Y <= (pos.Y - 1.0) then
			return hit.Position.Y
		end
		return fallbackY
	end

	-- Helper: determine exact physical road surface under a checkpoint or terminal trigger part
	local function getPartGroundY(part)
		if not (part and part:IsA("BasePart")) then return nil end
		-- Checkpoint/trigger parts have Size.Y ~ 15-20 studs, with center suspended 8-10 studs in air.
		-- The exact physical road surface is at the bottom face of the part:
		local bottomY = part.Position.Y - (part.Size.Y / 2)
		local probed = probeGround(Vector3.new(part.Position.X, part.Position.Y, part.Position.Z), bottomY)
		return probed or bottomY
	end

	-- Helper: map terminal name to legitimate in-game RequestTeleport fast-travel destination key
	local function getTeleportLocationKey(termId)
		local t = tostring(termId or ""):lower()
		if t:find("baranangsiang") or t:find("bogor") then
			return "Bogor"
		elseif t:find("rambutan") then
			return "Rambutan"
		elseif t:find("cirebon") then
			return "Cirebon"
		elseif t:find("cikampek") then
			return "Cikampek"
		elseif t:find("depok") or t:find("jatijajar") then
			return "Depok"
		elseif t:find("bekasi") then
			return "Bekasi"
		elseif t:find("tjpriuk") or t:find("priuk") then
			return "Tjpriuk"
		end
		return "Bogor"
	end

	-- (Pure physics driving functions declared below after Route System)

	------------------------------------------------
	-- 🛣️ ROAD-FOLLOWING WAYPOINT SYSTEM & HIGHWAY BACKBONE
	------------------------------------------------
	local HttpService = game:GetService("HttpService")
	local ROUTES_DIR = "HipHub/bxi_routes"
	pcall(function()
		if not isfolder or not isfolder("HipHub") then
			if makefolder then makefolder("HipHub") end
		end
		if not isfolder or not isfolder(ROUTES_DIR) then
			if makefolder then makefolder(ROUTES_DIR) end
		end
	end)

	local function saveRouteWaypoints(routeName, waypoints)
		if not writefile then return false end
		local successSave, _ = pcall(function()
			local filePath = ROUTES_DIR .. "/" .. routeName .. ".json"
			local encoded = HttpService:JSONEncode(waypoints)
			writefile(filePath, encoded)
		end)
		return successSave
	end

	local function loadRouteWaypoints(routeName)
		if not readfile or not isfile then return nil end
		local filePath = ROUTES_DIR .. "/" .. routeName .. ".json"
		local points = nil
		pcall(function()
			if isfile(filePath) then
				local content = readfile(filePath)
				points = HttpService:JSONDecode(content)
			end
		end)
		return points
	end

	-- Pre-mapped Highway Backbone Nodes along the Trans-Java / Cipali Toll Road
	-- Ensures the bus naturally follows the asphalt corridor rather than cutting across mountains/void
	local HIGHWAY_BACKBONE = {
		{ name = "Baranangsiang_Exit",      x = 22487.6, y = 286.9, z = -39420.7 },
		{ name = "Gerbang_Bogor_Approach", x = 21000.0, y = 287.0, z = -38800.0 },
		{ name = "Gerbang_Tol_Bogor_Bayar", x = 20128.6, y = 296.0, z = -38073.1, isToll = true },
		{ name = "Bogor_Tol_Plaza_Exit",   x = 20080.0, y = 288.0, z = -37900.0 },
		{ name = "Bogor_Tol_Curve_1",      x = 20035.0, y = 285.8, z = -37700.0 },
		{ name = "Bogor_Tol_Curve_2",      x = 19165.0, y = 285.7, z = -37500.0 },
		{ name = "Tol_Sentul_Selatan",      x = 19340.0, y = 282.7, z = -36700.0 },
		{ name = "Tol_Sentul_Mid",          x = 19380.0, y = 282.7, z = -35000.0 },
		{ name = "Tol_Sentul_Utara",        x = 19340.0, y = 283.1, z = -31500.0 },
		{ name = "Citeureup_Approach",      x = 20140.0, y = 282.7, z = -29500.0 },
		{ name = "Citeureup",               x = 20380.0, y = 275.1, z = -27765.0 },
		{ name = "Gunung_Putri",            x = 22000.0, y = 250.0, z = -25500.0 },
		{ name = "Jatijajar_Depok",         x = 24322.9, y = 228.5, z = -23148.8 },
		{ name = "Cibubur",                 x = 26000.0, y = 180.0, z = -14000.0 },
		{ name = "Rambutan",                x = 27536.3, y = 130.1, z = -3746.6 },
		{ name = "Cakung",                  x = 16053.0, y = 37.9,  z = 7200.0 },
		{ name = "Pulogebang",              x = 20100.0, y = 65.2,  z = 12000.0 },
		{ name = "Bekasi_Timur",            x = 6316.3,  y = -60.0, z = 20584.1 },
		{ name = "Cikampek",                x = -2200.0, y = -138.9, z = 25000.0 },
		{ name = "Cikamurang",              x = -15721.1, y = -212.6, z = 30866.7 },
		{ name = "Patrol",                  x = -18500.0, y = -215.0, z = 32000.0 },
		{ name = "Cirebon_A",               x = -22296.7, y = -186.1, z = 31104.1 },
		{ name = "Cirebon_Term",            x = -26300.5, y = -212.7, z = 33449.8 }
	}

	-- Calculate road path between start and destination following highway curves
	local function getRoutePath(startPos, destPos, routeName)
		-- 1. Check if user has saved custom recorded waypoints for this route
		local customWaypoints = loadRouteWaypoints(routeName or currentRouteId)
		if customWaypoints and #customWaypoints > 1 then
			local startIndex, destIndex = 1, #customWaypoints
			local minStartDist, minDestDist = 999999, 999999
			for idx, pt in ipairs(customWaypoints) do
				local sDist = (Vector3.new(pt.x - startPos.X, 0, pt.z - startPos.Z)).Magnitude
				local dDist = (Vector3.new(pt.x - destPos.X, 0, pt.z - destPos.Z)).Magnitude
				if sDist < minStartDist then minStartDist = sDist; startIndex = idx end
				if dDist < minDestDist then minDestDist = dDist; destIndex = idx end
			end

			if math.abs(destIndex - startIndex) >= 1 then
				local path = {}
				local step = destIndex > startIndex and 1 or -1
				for i = startIndex, destIndex, step do
					table.insert(path, customWaypoints[i])
				end
				table.insert(path, { x = destPos.X, y = destPos.Y, z = destPos.Z })
				return path
			end
		end

		-- 2. Build road path using Highway Corridor Backbone
		local flatDist = (Vector3.new(destPos.X - startPos.X, 0, destPos.Z - startPos.Z)).Magnitude
		if flatDist <= 500 then
			return { { x = destPos.X, y = destPos.Y, z = destPos.Z } }
		end

		local path = {}
		local corridorDir = destPos.Z > startPos.Z and 1 or -1
		for _, node in ipairs(HIGHWAY_BACKBONE) do
			local isBetween = false
			if corridorDir == 1 then
				isBetween = node.z > (startPos.Z + 150) and node.z < (destPos.Z - 150)
			else
				isBetween = node.z < (startPos.Z - 150) and node.z > (destPos.Z + 150)
			end
			if isBetween then
				table.insert(path, { x = node.x, y = node.y, z = node.z })
			end
		end

		if corridorDir == -1 then
			local rev = {}
			for i = #path, 1, -1 do table.insert(rev, path[i]) end
			path = rev
		end

		table.insert(path, { x = destPos.X, y = destPos.Y, z = destPos.Z })
		return path
	end

	-- 🏎️ PURE PHYSICS ROAD DRIVING ENGINE (ZERO TELEPORT, ZERO ANCHOR, ZERO NOCLIP)
	local function driveAlongWaypoints(waypoints, targetCruiseSpeed, arrivalThreshold)
		if not waypoints or #waypoints == 0 then return false end

		targetCruiseSpeed = targetCruiseSpeed or (Config.targetSpeed or 80)
		arrivalThreshold = arrivalThreshold or 18

		local bus, seat = ensureBusAndSeat()
		if not (bus and seat) then return false end

		-- Ensure vehicle is completely unanchored with full physics replication
		ensureEngineOn()
		setHandbrake(false)
		seat.Anchored = false
		for _, part in ipairs(bus:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
			end
		end

		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")

		isDrivingActive = true
		local driveFinished = false
		local currentWpIndex = 1
		local totalWps = #waypoints

		-- A-Chassis GUI values reference
		local achassisGui = player.PlayerGui:FindFirstChild("A-Chassis Interface")
		local aValues = achassisGui and achassisGui:FindFirstChild("Values")

		local driveStartTime = os.clock()
		local lastStuckTime = os.clock()
		local lastStuckPos = seat.Position
		local isUnsticking = false
		local unstickStartTime = 0

		if waypoints[1] then
			requestStreamAsync(Vector3.new(waypoints[1].x, waypoints[1].y or seat.Position.Y, waypoints[1].z))
		end

		if currentDriveConn then
			currentDriveConn:Disconnect()
			currentDriveConn = nil
		end

		local lastStatusTick = 0
		currentDriveConn = RunService.Heartbeat:Connect(function(dt)
			if not isDrivingActive or not isFarmRunning then
				driveFinished = true
				return
			end

			local curBus = getMyBus()
			local curSeat = getDriverSeat(curBus)
			if not (curBus and curSeat) then
				driveFinished = true
				return
			end

			local seatPos = curSeat.Position
			local targetWp = waypoints[currentWpIndex]
			if not targetWp then
				driveFinished = true
				return
			end

			local wpVec = Vector3.new(targetWp.x - seatPos.X, 0, targetWp.z - seatPos.Z)
			local distToWp = wpVec.Magnitude

			-- Advance to next waypoint along road curve
			local isLastWp = (currentWpIndex == totalWps)
			local switchRadius = isLastWp and arrivalThreshold or (targetWp.isToll and 14 or 32)
			if distToWp <= switchRadius then
				if targetWp.isToll then
					-- Stop inside Toll TriggerZone to pay toll fee and allow gate to open
					setFarmState(FARM_STATE.DRIVING_CHECKPOINT, "Membayar Tiket Masuk Tol (Rp 200.000)...")
					curSeat.Throttle = 0
					curSeat.Steer = 0
					setHandbrake(true)
					curSeat.AssemblyLinearVelocity = Vector3.zero
					task.wait(2.2)
					setHandbrake(false)
				end

				if currentWpIndex < totalWps then
					currentWpIndex = currentWpIndex + 1
					targetWp = waypoints[currentWpIndex]
					wpVec = Vector3.new(targetWp.x - seatPos.X, 0, targetWp.z - seatPos.Z)
					distToWp = wpVec.Magnitude
					requestStreamAsync(Vector3.new(targetWp.x, targetWp.y or seatPos.Y, targetWp.z))
				else
					driveFinished = true
					return
				end
			end

			-- Anti-Stuck Check: if vehicle is wedged (< 3 studs in 2s while driving)
			local now = os.clock()
			if not isUnsticking then
				if (now - lastStuckTime) >= 2.0 then
					local moved = (Vector3.new(seatPos.X - lastStuckPos.X, 0, seatPos.Z - lastStuckPos.Z)).Magnitude
					if moved < 3.0 and distToWp > arrivalThreshold then
						isUnsticking = true
						unstickStartTime = now
					end
					lastStuckTime = now
					lastStuckPos = seatPos
				end
			else
				-- Pure physics reverse maneuver to clear curbs / guardrails
				if (now - unstickStartTime) < 1.4 then
					curSeat.Throttle = -1
					curSeat.Steer = -1
					if aValues and aValues:FindFirstChild("Throttle") then aValues.Throttle.Value = -1 end
					if aValues and aValues:FindFirstChild("Gear") then aValues.Gear.Value = "R" end
					return
				else
					isUnsticking = false
					lastStuckTime = now
					lastStuckPos = seatPos
					if aValues and aValues:FindFirstChild("Gear") then aValues.Gear.Value = "D" end
				end
			end

			-- Steering calculation: heading error between bus and target waypoint
			local look = curSeat.CFrame.LookVector
			local busHeading = math.atan2(-look.X, -look.Z)
			local targetHeading = math.atan2(-wpVec.X, -wpVec.Z)
			local angleDiff = (targetHeading - busHeading + math.pi) % (2 * math.pi) - math.pi

			-- Pure physics steering input
			local steerVal = math.clamp(angleDiff * 2.2, -1, 1)
			curSeat.Steer = steerVal
			curSeat.SteerFloat = steerVal
			if aValues and aValues:FindFirstChild("Steer") then
				aValues.Steer.Value = steerVal
			end

			-- Cornering and arrival speed damping
			local maxSpeed = targetCruiseSpeed
			if isLastWp and distToWp < 75 then
				maxSpeed = math.max(20, (distToWp / 75) * targetCruiseSpeed)
			elseif math.abs(angleDiff) > 0.65 then
				maxSpeed = math.min(maxSpeed, 38)
			end

			local curVel = curSeat.AssemblyLinearVelocity
			local currentFlatSpeed = Vector3.new(curVel.X, 0, curVel.Z).Magnitude
			local forwardDir = Vector3.new(look.X, 0, look.Z).Unit

			-- Pure physics throttle & forward propulsion assist
			if currentFlatSpeed < maxSpeed then
				curSeat.Throttle = 1
				curSeat.ThrottleFloat = 1
				if aValues and aValues:FindFirstChild("Throttle") then aValues.Throttle.Value = 1 end
				if aValues and aValues:FindFirstChild("Brake") then aValues.Brake.Value = 0 end
				if aValues and aValues:FindFirstChild("PBrake") then aValues.PBrake.Value = false end

				local speedDeficit = maxSpeed - currentFlatSpeed
				local forwardThrust = math.clamp(speedDeficit * 1.0, 0, 25)
				curSeat.AssemblyLinearVelocity = curVel + (forwardDir * (forwardThrust * dt * 4.0))
			elseif currentFlatSpeed > (maxSpeed + 6) then
				curSeat.Throttle = 0
				curSeat.ThrottleFloat = 0
				if aValues and aValues:FindFirstChild("Throttle") then aValues.Throttle.Value = 0 end
				if aValues and aValues:FindFirstChild("Brake") then aValues.Brake.Value = 0.5 end
				curSeat.AssemblyLinearVelocity = Vector3.new(curVel.X * 0.96, curVel.Y, curVel.Z * 0.96)
			else
				curSeat.Throttle = 1
				curSeat.ThrottleFloat = 1
			end

			-- Pure physics yaw turning & anti-roll stability (Prevents bus tipping over on road)
			local targetYawRate = math.clamp(angleDiff * 2.8, -1.8, 1.8)
			local curAngVel = curSeat.AssemblyAngularVelocity
			curSeat.AssemblyAngularVelocity = Vector3.new(curAngVel.X * 0.7, targetYawRate, curAngVel.Z * 0.7)

			if hum then
				hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			end

			-- Status telemetry update
			if (now - lastStatusTick) >= 0.4 then
				lastStatusTick = now
				local remDist = distToWp
				for i = currentWpIndex, totalWps - 1 do
					remDist = remDist + (Vector3.new(waypoints[i+1].x - waypoints[i].x, 0, waypoints[i+1].z - waypoints[i].z)).Magnitude
				end
				local estSec = math.ceil(remDist / math.max(currentFlatSpeed, 30))
				setFarmState(FARM_STATE.DRIVING_CHECKPOINT, string.format("%s (%dm | ~%ds)", nextDestinationName or "Menuju Checkpoint", math.floor(remDist), estSec))
			end
		end)

		while not driveFinished and isDrivingActive and isFarmRunning do
			task.wait(0.05)
		end

		if currentDriveConn then
			currentDriveConn:Disconnect()
			currentDriveConn = nil
		end

		-- Settle bus upon arrival: cut throttle, apply brakes
		pcall(function()
			local curBus = getMyBus()
			local curSeat = getDriverSeat(curBus)
			if curSeat then
				curSeat.Throttle = 0
				curSeat.ThrottleFloat = 0
				curSeat.Steer = 0
				curSeat.SteerFloat = 0
				curSeat.AssemblyLinearVelocity = Vector3.new(0, curSeat.AssemblyLinearVelocity.Y, 0)
				curSeat.AssemblyAngularVelocity = Vector3.zero
			end
			if aValues then
				if aValues:FindFirstChild("Throttle") then aValues.Throttle.Value = 0 end
				if aValues:FindFirstChild("Brake") then aValues.Brake.Value = 1 end
			end
		end)

		isDrivingActive = false
		return true
	end

	-- Single-destination pure physics drive helper
	local function driveToDestination(destPos, targetCruiseSpeed, arrivalThreshold)
		return driveAlongWaypoints({ { x = destPos.X, y = destPos.Y, z = destPos.Z } }, targetCruiseSpeed, arrivalThreshold)
	end

	-- Master Drive Function: Chooses road curve pathing when enabled
	local function navigateToDestination(destPos, targetCruiseSpeed, arrivalThreshold)
		local bus, seat = ensureBusAndSeat()
		if not (bus and seat) then return false end

		if Config.followRoadCurves ~= false then
			local path = getRoutePath(seat.Position, destPos, currentRouteId)
			if path and #path > 1 then
				return driveAlongWaypoints(path, targetCruiseSpeed, arrivalThreshold)
			end
		end
		return driveToDestination(destPos, targetCruiseSpeed, arrivalThreshold)
	end

	------------------------------------------------
	-- 📹 LIVE ROUTE WAYPOINT RECORDER
	------------------------------------------------
	local isRecordingRoute = false
	local recordedWaypoints = {}
	local recordConn = nil
	local recordStatusLabel = nil

	local function startRecordingRoute()
		isRecordingRoute = true
		recordedWaypoints = {}
		local bus, seat = ensureBusAndSeat()
		local lastRecordedPos = seat and seat.Position or Vector3.zero
		local lastHeading = seat and seat.CFrame.LookVector or Vector3.zero

		if seat then
			table.insert(recordedWaypoints, {
				x = math.floor(seat.Position.X * 10) / 10,
				y = math.floor(seat.Position.Y * 10) / 10,
				z = math.floor(seat.Position.Z * 10) / 10
			})
		end

		if recordConn then recordConn:Disconnect(); recordConn = nil end
		recordConn = RunService.Heartbeat:Connect(function()
			if not isRecordingRoute then return end
			local curBus = getMyBus()
			local curSeat = getDriverSeat(curBus)
			if not (curBus and curSeat) then return end

			local pos = curSeat.Position
			local dist = (Vector3.new(pos.X - lastRecordedPos.X, 0, pos.Z - lastRecordedPos.Z)).Magnitude
			local heading = curSeat.CFrame.LookVector
			local dot = math.clamp(heading:Dot(lastHeading), -1, 1)
			local angleChange = math.deg(math.acos(dot))

			if dist >= 40 or (dist >= 15 and angleChange >= 5) then
				lastRecordedPos = pos
				lastHeading = heading
				table.insert(recordedWaypoints, {
					x = math.floor(pos.X * 10) / 10,
					y = math.floor(pos.Y * 10) / 10,
					z = math.floor(pos.Z * 10) / 10
				})
				if recordStatusLabel then
					pcall(function() recordStatusLabel.Set(string.format("🔴 Recording: %d curve points", #recordedWaypoints)) end)
				end
			end
		end)
	end

	local function stopAndSaveRecording(routeName)
		isRecordingRoute = false
		if recordConn then recordConn:Disconnect(); recordConn = nil end
		if #recordedWaypoints > 0 then
			saveRouteWaypoints(routeName or currentRouteId, recordedWaypoints)
			UI.Notify("Route Saved", string.format("Saved %d points for %s!", #recordedWaypoints, routeName or currentRouteId), 3, "success")
			if recordStatusLabel then
				pcall(function() recordStatusLabel.Set(string.format("✅ Saved: %d points (%s)", #recordedWaypoints, routeName or currentRouteId)) end)
			end
		else
			UI.Notify("Recording Empty", "No waypoints recorded.", 2, "warning")
			if recordStatusLabel then pcall(function() recordStatusLabel.Set("Route Recorder: Idle") end) end
		end
	end

	------------------------------------------------
	-- 🏁 FULL BUS JOB AUTO FARM PIPELINE
	------------------------------------------------
	local currentJobActive = false
	local waitingForCheckpointCountdown = false
	local isInCheckpointZone = true
	local nextCheckpointPartName = nil
	local nextDestinationName = nil
	local endTriggerPartName = nil
	local currentCheckpointIndex = 0
	local totalCheckpoints = 0

	-- Helper: Physically drive and dock bus inside checkpoint zone without PivotTo
	local function dockAtCheckpointPhysically(cpPart, forwardOffset)
		if not (cpPart and cpPart:IsA("BasePart")) then return false end
		local snapBus, snapSeat = ensureBusAndSeat()
		if not (snapBus and snapSeat) then return false end

		local cpCF = cpPart.CFrame
		local dot = snapSeat.CFrame.LookVector:Dot(cpCF.LookVector)
		local approachDir = dot < -0.2 and (cpCF * CFrame.Angles(0, math.pi, 0)).LookVector or cpCF.LookVector
		local offset = forwardOffset or 14
		local targetX = cpPart.Position.X + (approachDir.X * offset)
		local targetZ = cpPart.Position.Z + (approachDir.Z * offset)
		local targetPos = Vector3.new(targetX, cpPart.Position.Y, targetZ)

		-- Pure physics crawl into checkpoint zone at low docking speed (~20 studs/s)
		setFarmState(FARM_STATE.DRIVING_CHECKPOINT, "Docking Checkpoint...")
		driveToDestination(targetPos, 20, 6)

		-- Halt naturally and engage handbrake
		holdCheckpointPosition()
		return true
	end

	-- Listen for Server Job Updates
	if Remotes:FindFirstChild("BusJobUpdate") then
		Remotes.BusJobUpdate.OnClientEvent:Connect(function(eventName, eventData)
			if not isFarmRunning then return end

			if eventName == "StartCheckpointWait" then
				waitingForCheckpointCountdown = true
				isInCheckpointZone = true
				currentCheckpointIndex = eventData.checkpointIndex or currentCheckpointIndex
				totalCheckpoints = eventData.totalCheckpoints or totalCheckpoints
				currentCheckpointText = string.format("%d / %d", currentCheckpointIndex, totalCheckpoints)
				if statCheckpointCard then statCheckpointCard.Set(currentCheckpointText) end
				setFarmState(FARM_STATE.WAITING_PASSENGERS, eventData.checkpointName or "Checkpoint Zone")

			elseif eventName == "CheckpointZoneExit" then
				isInCheckpointZone = false

			elseif eventName == "CheckpointZoneEnter" then
				isInCheckpointZone = true

			elseif eventName == "WaitCompleted" then
				waitingForCheckpointCountdown = false
				isInCheckpointZone = true
				setFarmState(FARM_STATE.DRIVING_CHECKPOINT, "Passenger Loading Complete")

			elseif eventName == "NextCheckpoint" then
				waitingForCheckpointCountdown = false
				isInCheckpointZone = true
				nextCheckpointPartName = eventData.nextCheckpointPartName
				nextDestinationName = eventData.nextDestinationName
				currentCheckpointIndex = eventData.checkpointIndex or currentCheckpointIndex
				totalCheckpoints = eventData.totalCheckpoints or totalCheckpoints
				currentCheckpointText = string.format("%d / %d", currentCheckpointIndex, totalCheckpoints)
				if statCheckpointCard then statCheckpointCard.Set(currentCheckpointText) end
				setFarmState(FARM_STATE.DRIVING_CHECKPOINT, nextDestinationName or "Next Stop")

			elseif eventName == "FinalDestination" then
				waitingForCheckpointCountdown = false
				isInCheckpointZone = true
				endTriggerPartName = eventData.endTriggerPartName
				currentCheckpointIndex = eventData.checkpointIndex or currentCheckpointIndex
				totalCheckpoints = eventData.totalCheckpoints or totalCheckpoints
				currentCheckpointText = string.format("%d / %d", currentCheckpointIndex, totalCheckpoints)
				if statCheckpointCard then statCheckpointCard.Set(currentCheckpointText) end
				setFarmState(FARM_STATE.DRIVING_FINAL, "Final Destination Trigger")

			elseif eventName == "JobSuccess" then
				currentJobActive = false
				waitingForCheckpointCountdown = false
				isInCheckpointZone = true
				totalRoutesDone = totalRoutesDone + 1
				if statRouteCard then statRouteCard.Set(tostring(totalRoutesDone)) end
				setFarmState(FARM_STATE.JOB_COMPLETED, "Route Completed!")
				UI.Notify("Route Completed", "Received bus route payout!", 3, "success")

				-- Discord Webhook notification
				if _G.HipHubSendWebhook and Config.autoNextJob then
					_G.HipHubSendWebhook("🚌 Bus Route Completed!", string.format("Completed **%s** successfully.", tostring(currentRouteId)), {
						{ name = "Route", value = tostring(currentRouteId), inline = true },
						{ name = "Total Routes Completed", value = tostring(totalRoutesDone), inline = true },
						{ name = "Status", value = "✅ Success", inline = true }
					}, 0x00E68C)
				end

			elseif eventName == "JobCancelled" then
				currentJobActive = false
				waitingForCheckpointCountdown = false
				isInCheckpointZone = true
				setFarmState(FARM_STATE.IDLE, "Job Cancelled")
			end
		end)
	end

	-- Helper: robust checkpoint/trigger part finder across all workspace folders
	local function findTargetPart(partName, preferredFolder)
		if not partName then return nil end
		if preferredFolder and workspace:FindFirstChild(preferredFolder) then
			local p = workspace[preferredFolder]:FindFirstChild(partName, true)
			if p and p:IsA("BasePart") then return p end
		end
		for _, fName in ipairs({ "Checkpoints", "BusJobTriggers", "BusJobEndTriggers" }) do
			local f = workspace:FindFirstChild(fName)
			if f then
				local p = f:FindFirstChild(partName, true)
				if p and p:IsA("BasePart") then return p end
			end
		end
		local direct = workspace:FindFirstChild(partName, true)
		if direct and direct:IsA("BasePart") then return direct end
		return nil
	end

	-- Execute one full bus route loop
	local function executeBusRouteLoop()
		-- 🔄 Reset all persistent job state from previous run to avoid stale triggers
		waitingForCheckpointCountdown = false
		isInCheckpointZone = true
		nextCheckpointPartName = nil
		nextDestinationName = nil
		endTriggerPartName = nil
		releaseCheckpointHold()

		-- 1. Ensure Bus and Driver Seat
		local bus, seat = ensureBusAndSeat()
		if not (bus and seat) then
			task.wait(2)
			return
		end

		-- 2. Fast-travel back to terminal only if stranded in another city (> 3000 studs)
		local termPart = findTargetPart(currentTerminalId, "BusJobTriggers")
		local terminalTriggerPos = termPart and termPart.Position or Vector3.new(22771.8, 294.87, -39584.0)
		local seatPos = seat.Position
		local distToTerm = (Vector3.new(seatPos.X - terminalTriggerPos.X, 0, seatPos.Z - terminalTriggerPos.Z)).Magnitude

		if distToTerm > 3000 then
			setFarmState(FARM_STATE.STARTING_JOB, "Fast-Traveling to Terminal")
			respawnToStart()
			bus, seat = ensureBusAndSeat()
			if not (bus and seat) then return end
			seatPos = seat.Position
		end

		-- Auto-clear lingering zombie job if server reports already in job
		if player:GetAttribute("BusJobActive") then
			pcall(function() Remotes.CancelBusJob:FireServer() end)
			task.wait(1.0)
		end

		-- 3. Start Bus Job immediately from driver seat (Official Server Handshake)
		setFarmState(FARM_STATE.STARTING_JOB, string.format("Memulai Job: %s", currentRouteId))
		local startRes = nil
		pcall(function()
			startRes = Remotes.StartBusJob:InvokeServer(currentRouteId, currentTerminalId)
		end)

		if startRes == "You are already in a job." then
			pcall(function() Remotes.CancelBusJob:FireServer() end)
			task.wait(1.5)
			pcall(function()
				startRes = Remotes.StartBusJob:InvokeServer(currentRouteId, currentTerminalId)
			end)
		elseif startRes == "Too many requests." then
			task.wait(2.5)
			pcall(function()
				startRes = Remotes.StartBusJob:InvokeServer(currentRouteId, currentTerminalId)
			end)
		elseif startRes == "You must be inside a valid bus vehicle." then
			-- Re-seat humanoid and retry once
			bus, seat = ensureBusAndSeat()
			task.wait(0.5)
			pcall(function()
				startRes = Remotes.StartBusJob:InvokeServer(currentRouteId, currentTerminalId)
			end)
		end

		-- 4. Verify Job Activation & Target Checkpoint 1 (Peron Penumpang Terminal)
		local jobStartTime = os.clock()
		if type(startRes) == "table" and startRes.success then
			currentJobActive = true
			jobStartTime = os.clock()
			currentCheckpointIndex = startRes.checkpointIndex or 1
			totalCheckpoints = startRes.totalCheckpoints or 9
			nextCheckpointPartName = startRes.nextCheckpointPartName
			nextDestinationName = startRes.nextDestinationName
			currentCheckpointText = string.format("%d / %d", currentCheckpointIndex, totalCheckpoints)
			if statCheckpointCard then statCheckpointCard.Set(currentCheckpointText) end
			setFarmState(FARM_STATE.DRIVING_CHECKPOINT, string.format("CP 1: %s", nextDestinationName or nextCheckpointPartName))
		else
			setFarmState(FARM_STATE.IDLE, "Gagal Ambil Job: " .. tostring(startRes))
			task.wait(2.5)
			return
		end

		-- 5. Route Navigation Loop (Checkpoint to Checkpoint)
		local lastHandledCheckpoint = nil
		local legStartTime = os.clock()
		local lastLegStartPos = seat and seat.Position or terminalTriggerPos

		while currentJobActive and isFarmRunning do
			-- Fallback: auto-detect active checkpoint or end trigger from BillboardGui
			if (not nextCheckpointPartName or nextCheckpointPartName == lastHandledCheckpoint) and not endTriggerPartName then
				for _, cp in ipairs(workspace.Checkpoints:GetChildren()) do
					if cp:FindFirstChildWhichIsA("BillboardGui") and cp.Name ~= lastHandledCheckpoint then
						nextCheckpointPartName = cp.Name
						break
					end
				end
			end
			if not endTriggerPartName then
				for _, tr in ipairs(workspace.BusJobEndTriggers:GetChildren()) do
					if tr:FindFirstChildWhichIsA("BillboardGui") then
						endTriggerPartName = tr.Name
						break
					end
				end
			end

			-- A. Driving to next checkpoint
			if nextCheckpointPartName and nextCheckpointPartName ~= lastHandledCheckpoint then
				local cpPart = findTargetPart(nextCheckpointPartName, "Checkpoints")
				if cpPart and cpPart:IsA("BasePart") then
					local currentLegPartName = cpPart.Name
					lastHandledCheckpoint = currentLegPartName
					setFarmState(FARM_STATE.DRIVING_CHECKPOINT, nextDestinationName or nextCheckpointPartName)

					-- 1. Calculate Leg Distance & Dynamic Safe Time (80 studs/s = ~75 km/h)
					local curSeatPos = seat and seat.Position or lastLegStartPos
					local flatApproach = Vector3.new(cpPart.Position.X - curSeatPos.X, 0, cpPart.Position.Z - curSeatPos.Z)
					local legDist = flatApproach.Magnitude
					local safeSpeed = math.clamp(tonumber(Config.targetSpeed) or 80, 60, 95)
					local minLegTime = math.max(legDist / safeSpeed, 4.0)

					-- Horizontal Flat Direction (Strictly Zero Pitch & Zero Roll - Flat On Asphalt)
					local lookVec = seat and seat.CFrame.LookVector or Vector3.new(0, 0, 1)
					local approachDir = legDist > 1.0 and flatApproach.Unit or Vector3.new(lookVec.X, 0, lookVec.Z).Unit
					local flatRotCF = CFrame.lookAt(Vector3.zero, approachDir)

					-- 2. Check if Leg is Long-Distance (Intercity) or Local Gate (CP 1 / Terminal Pick)
					if legDist > 80 then
						-- 🛣️ Road-Following Navigation: Drive along asphalt corridor (Zero Fly Detection)
						setFarmState(FARM_STATE.DRIVING_CHECKPOINT, nextDestinationName or "Menuju Checkpoint")
						requestStreamAsync(cpPart.Position)

						-- Navigate using highway backbone curves to checkpoint proximity
						navigateToDestination(cpPart.Position, safeSpeed, 22)

						-- 🛡️ SMART ROAD ASPHALT PACING GUARD: Wait remaining trip time on solid ground
						if Config.tripPacing ~= false then
							holdCheckpointPosition()
							local legElapsed = os.clock() - legStartTime
							while legElapsed < minLegTime and isFarmRunning and currentJobActive do
								local remainingSec = math.ceil(minLegTime - legElapsed)
								setFarmState(FARM_STATE.PACING, string.format("%s (Sisa %ds...)", nextDestinationName or "Pacing", remainingSec))
								task.wait(0.5)
								legElapsed = os.clock() - legStartTime
							end
							releaseCheckpointHold()
						end
					end

					-- 3. Enter Checkpoint Zone (Pure Physics Docking)
					setFarmState(FARM_STATE.DRIVING_CHECKPOINT, "Docking Checkpoint...")
					requestStreamAsync(cpPart.Position)
					dockAtCheckpointPhysically(cpPart, 14)

					-- 6. Wait for Server to Initiate Passenger Countdown
					local cpWaitStart = os.clock()
					local lastHealTime = os.clock()

					while not waitingForCheckpointCountdown and isFarmRunning and currentJobActive and (os.clock() - cpWaitStart) < 22 do
						local now = os.clock()
						if not waitingForCheckpointCountdown and (now - cpWaitStart) > 4.0 and (now - lastHealTime) >= 3.0 then
							lastHealTime = now
							-- Pure physics gentle crawl forward to touch trigger if not yet registered
							pcall(function()
								local curBus = getMyBus()
								local curSeat = getDriverSeat(curBus)
								if curSeat then
									setHandbrake(false)
									curSeat.Throttle = 1
									curSeat.AssemblyLinearVelocity = curSeat.CFrame.LookVector * 12
									task.wait(0.5)
									curSeat.Throttle = 0
									holdCheckpointPosition()
								end
							end)
						end
						task.wait(0.2)
					end

					-- 7. Waiting inside Checkpoint Zone for passenger countdown
					if waitingForCheckpointCountdown and isFarmRunning and currentJobActive then
						setFarmState(FARM_STATE.WAITING_PASSENGERS, "Passenger Loading")
						local waitTimeout = os.clock()
						holdCheckpointPosition()

						while waitingForCheckpointCountdown and isFarmRunning and currentJobActive and (os.clock() - waitTimeout) < 30 do
							task.wait(0.25)
						end
					end

					-- Release checkpoint hold and reset leg timer for next leg
					releaseCheckpointHold()
					legStartTime = os.clock()
					lastLegStartPos = cpPart.Position
				end
			end

			-- C. Driving to Final Destination with Smart Pacing Guard
			if endTriggerPartName and currentJobActive then
				local endTrigger = findTargetPart(endTriggerPartName, "BusJobEndTriggers")
				if endTrigger and endTrigger:IsA("BasePart") then
					local curSeatPos = seat and seat.Position or lastLegStartPos
					local flatApproach = Vector3.new(endTrigger.Position.X - curSeatPos.X, 0, endTrigger.Position.Z - curSeatPos.Z)
					local legDist = flatApproach.Magnitude
					local safeSpeed = math.clamp(tonumber(Config.targetSpeed) or 80, 60, 95)
					local minLegTime = math.max(legDist / safeSpeed, 4.0)

					local lookVec = seat and seat.CFrame.LookVector or Vector3.new(0, 0, 1)
					local approachDir = legDist > 1.0 and flatApproach.Unit or Vector3.new(lookVec.X, 0, lookVec.Z).Unit
					local flatRotCF = CFrame.lookAt(Vector3.zero, approachDir)

					if legDist > 80 then
						-- 🛣️ Road Navigation to Final Stop Corridor
						setFarmState(FARM_STATE.DRIVING_FINAL, "Menuju Terminal Akhir")
						requestStreamAsync(endTrigger.Position)
						navigateToDestination(endTrigger.Position, safeSpeed, 22)

						-- 🛡️ Smart Road Pacing for final stop
						if Config.tripPacing ~= false then
							holdCheckpointPosition()
							local legElapsed = os.clock() - legStartTime
							while legElapsed < minLegTime and isFarmRunning and currentJobActive do
								local remainingSec = math.ceil(minLegTime - legElapsed)
								setFarmState(FARM_STATE.PACING, string.format("Terminal Akhir: Sisa %ds...", remainingSec))
								task.wait(0.5)
								legElapsed = os.clock() - legStartTime
							end
							releaseCheckpointHold()
						end
					end

					setFarmState(FARM_STATE.DRIVING_FINAL, "Docking Final Stop...")
					requestStreamAsync(endTrigger.Position)
					task.wait(0.2)
					local curBus, curSeat = ensureBusAndSeat()
					if curBus and curSeat then
						-- Pure physics drive directly into the end trigger bounding box at 18 studs/s
						driveToDestination(endTrigger.Position, 20, 8)
						holdCheckpointPosition()
					end
				end
				task.wait(2)
				break
			end

			task.wait(0.3)
		end

		task.wait(1)
	end

	------------------------------------------------
	-- 🎁 AUTO DAILY QUESTS & SPIN BOX
	------------------------------------------------
	local function checkAndClaimQuests()
		if not Config.autoClaimQuests then return end
		pcall(function()
			local questData = Remotes.GetQuestData:InvokeServer()
			local questDefs = Remotes.GetQuestDefinitions:InvokeServer()
			if questData and questData.Quests and questDefs then
				for qId, qInfo in pairs(questData.Quests) do
					local def = questDefs[qId]
					if def and qInfo.Progress >= def.Target and not qInfo.Claimed then
						local successClaim = Remotes.ClaimQuestReward:InvokeServer(qId)
						if successClaim then
							UI.Notify("Quest Claimed", "Claimed reward for: " .. def.Title, 3, "success")
							if _G.HipHubSendWebhook then
								_G.HipHubSendWebhook("🎁 Daily Quest Claimed!", "Successfully claimed daily quest reward.", {
									{ name = "Quest", value = def.Title, inline = true },
									{ name = "Reward", value = formatRp(def.Reward), inline = true }
								}, 0xFFD700)
							end
						end
					end
				end
			end
		end)
	end

	local function checkAndSpinBox()
		if not Config.autoSpinBox then return end
		pcall(function()
			local spinData = Remotes.SpinBox_GetData:InvokeServer()
			if spinData and spinData.Boxes then
				local boxName = Config.selectedBox or "Event"
				local boxInfo = spinData.Boxes[boxName]
				if boxInfo and spinData.Points >= boxInfo.Cost and not spinData.GarageFull then
					local spinRes = Remotes.SpinBox_RequestSpin:InvokeServer(boxName)
					if spinRes and spinRes.success then
						Remotes.SpinBox_AnimationDone:FireServer()
						local rewardName = spinRes.reward and spinRes.reward.DisplayName or "Reward"
						UI.Notify("Spin Box Won!", "Obtained: " .. rewardName, 3, "gold")
					end
				end
			end
		end)
	end

	------------------------------------------------
	-- 🔁 MASTER AUTO FARM THREAD
	------------------------------------------------
	local function respawnToStart()
		setFarmState(FARM_STATE.IDLE, "Preparing Next Route Loop")
		pcall(function()
			if Remotes:FindFirstChild("DespawnCar") then
				Remotes.DespawnCar:FireServer()
			end
		end)
		task.wait(1.5)

		-- 🛡️ Safe Official Server Teleport to Terminal (Built-in Fast Travel)
		local targetLocKey = getTeleportLocationKey(currentTerminalId)
		local teleportSuccess = false
		if Remotes:FindFirstChild("RequestTeleport") then
			pcall(function()
				local res = Remotes.RequestTeleport:InvokeServer(targetLocKey)
				if res == true then
					teleportSuccess = true
				end
			end)
		end

		if teleportSuccess then
			task.wait(1.8)
		else
			-- Fallback repositioning only if remote failed
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local termPart = findTargetPart(currentTerminalId, "BusJobTriggers")
			if hrp and termPart then
				local dist = (Vector3.new(hrp.Position.X - termPart.Position.X, 0, hrp.Position.Z - termPart.Position.Z)).Magnitude
				if dist > 35 then
					local termRoadY = getPartGroundY(termPart) or (termPart.Position.Y - (termPart.Size.Y / 2))
					hrp.CFrame = CFrame.new(termPart.Position.X, termRoadY + 3.5, termPart.Position.Z)
				end
			end
			task.wait(1.5)
		end
	end

	task.spawn(function()
		while true do
			task.wait(1)
			if isFarmRunning then
				pcall(checkAndClaimQuests)
				pcall(checkAndSpinBox)
				local loopSuccess, loopErr = pcall(executeBusRouteLoop)
				if not loopSuccess then
					warn("[HipHub BXI Farm Error]:", loopErr)
				end

				-- Only trigger cooldown & fast respawn if a route was actually completed
				if currentFarmState == FARM_STATE.JOB_COMPLETED and isFarmRunning then
					if Config.autoNextJob then
						local cd = Config.jobCooldown or 3
						setFarmState(FARM_STATE.IDLE, string.format("Cooldown (%ds)", cd))
						task.wait(cd)

						if Config.autoRespawnLoop ~= false and isFarmRunning then
							respawnToStart()
						end
					else
						isFarmRunning = false
						setFarmState(FARM_STATE.IDLE, "Single Route Done")
					end
				else
					task.wait(1.5)
				end
			end
		end
	end)

	-- Track Money & Update Stats
	pcall(function()
		local PlayerData = player:WaitForChild("PlayerData", 5)
		if PlayerData and PlayerData:FindFirstChild("Uang") then
			local uangVal = PlayerData.Uang
			local lastUang = uangVal.Value
			uangVal.Changed:Connect(function(newVal)
				if newVal > lastUang then
					local diff = newVal - lastUang
					totalEarnings = totalEarnings + diff
					if statEarnCard then statEarnCard.Set(formatRp(totalEarnings)) end
				end
				lastUang = newVal
			end)
		end
	end)

	-- Update Uptime Counter
	RunService.Heartbeat:Connect(function()
		if isFarmRunning and statUptimeCard then
			local elapsed = math.floor(os.clock() - farmStartTime)
			local hrs = math.floor(elapsed / 3600)
			local mins = math.floor((elapsed % 3600) / 60)
			local secs = elapsed % 60
			statUptimeCard.Set(string.format("%02d:%02d:%02d", hrs, mins, secs))
		end
	end)

	------------------------------------------------
	-- 💰 AUTO FARM UI BUILDER
	------------------------------------------------

	-- 1. Live Stats Dashboard
	UI.AddSection(tab, "Live Auto Farm Metrics")

	local statsRow1 = Instance.new("Frame")
	statsRow1.Size = UDim2.new(1, 0, 0, 56)
	statsRow1.BackgroundTransparency = 1
	statsRow1.Parent = tab
	local sLayout1 = Instance.new("UIListLayout")
	sLayout1.FillDirection = Enum.FillDirection.Horizontal
	sLayout1.Padding = UDim.new(0, 8)
	sLayout1.Parent = statsRow1

	statEarnCard = UI.AddStatsCard(statsRow1, "Total Earned", "Rp 0", "💰")
	statRouteCard = UI.AddStatsCard(statsRow1, "Routes Done", "0", "🛣️")

	local statsRow2 = Instance.new("Frame")
	statsRow2.Size = UDim2.new(1, 0, 0, 56)
	statsRow2.BackgroundTransparency = 1
	statsRow2.Parent = tab
	local sLayout2 = Instance.new("UIListLayout")
	sLayout2.FillDirection = Enum.FillDirection.Horizontal
	sLayout2.Padding = UDim.new(0, 8)
	sLayout2.Parent = statsRow2

	statCheckpointCard = UI.AddStatsCard(statsRow2, "Checkpoint", "0 / 0", "🚩")
	statUptimeCard = UI.AddStatsCard(statsRow2, "Farm Uptime", "00:00:00", "⏱️")

	activityLabel = UI.AddLabel(tab, "📍 Status: Idle", "cyan")

	-- 2. Master Toggle & Route Selection
	UI.AddSection(tab, "Auto Farm Controller")

	local farmToggle = UI.AddToggle(tab, "Start Auto Bus Farm (Pure Physics Driving)", isFarmRunning, function(state)
		isFarmRunning = state
		Config.autoBusJob = state
		if state then
			farmStartTime = os.clock()
			setFarmState(FARM_STATE.PREPARING_BUS, "Starting Farm Engine")
			UI.Notify("Auto Farm Started", "Pure physics driving activated (Zero PivotTo, Unanchored)!", 3, "success")
		else
			isDrivingActive = false
			currentJobActive = false
			releaseCheckpointHold()
			setFarmState(FARM_STATE.IDLE, "Stopped")
			UI.Notify("Auto Farm Stopped", "Farm paused.", 2, "warning")
		end
	end)

	UI.AddToggle(tab, "Bus Smart Pacing (Anti-425 Ban Guard)", Config.tripPacing ~= false, function(state)
		Config.tripPacing = state
	end)

	local AVAILABLE_ROUTES = {
		"Baranangsiang_ke_Rambutan",
		"Baranangsiang_ke_Cirebon4",
		"Baranangsiang_ke_Cirebon3",
		"Baranangsiang_ke_Cirebon",
		"Baranangsiang_ke_Cirebon1",
		"Baranangsiang_ke_Cirebon2"
	}

	UI.AddDropdown(tab, "Target Route", AVAILABLE_ROUTES, currentRouteId, function(chosen)
		currentRouteId = chosen
		Config.selectedRoute = chosen
	end)

	UI.AddSlider(tab, "Driving Cruise Speed", 60, 180, Config.targetSpeed or 95, function(val)
		Config.targetSpeed = val
	end, "km/h")

	UI.AddSlider(tab, "Safe Route Delay (Anti-Ban)", 40, 120, Config.arriveDelay or 65, function(val)
		Config.arriveDelay = val
	end, "sec")

	UI.AddSlider(tab, "Cooldown Between Jobs", 1, 10, Config.jobCooldown or 3, function(val)
		Config.jobCooldown = val
	end, "sec")

	UI.AddToggle(tab, "Continuous Loop (Auto Start Next Job)", Config.autoNextJob, function(state)
		Config.autoNextJob = state
	end)

	UI.AddToggle(tab, "Fast Respawn Loop (Instant Reset to Garage)", Config.autoRespawnLoop ~= false, function(state)
		Config.autoRespawnLoop = state
	end)

	UI.AddToggle(tab, "Follow Road Curves (Follow Asphalt Path)", Config.followRoadCurves ~= false, function(state)
		Config.followRoadCurves = state
		if state then
			UI.Notify("Road Curves Active", "Bus will steer along asphalt highway curves!", 3, "success")
		end
	end)

	-- 3. Road Curve Recorder
	UI.AddSection(tab, "Road Curve Recorder (GPS Waypoints)")

	recordStatusLabel = UI.AddLabel(tab, "Route Recorder: Idle", "yellow")

	local recordToggle = UI.AddToggle(tab, "Record Route Waypoints (Live Drive Tracker)", false, function(state)
		if state then
			startRecordingRoute()
			UI.Notify("Recording Started", "Drive your bus! Points are recorded along curves.", 3, "success")
		else
			stopAndSaveRecording(currentRouteId)
		end
	end)

	UI.AddButton(tab, "Clear Custom Route Waypoints", function()
		pcall(function()
			local filePath = ROUTES_DIR .. "/" .. currentRouteId .. ".json"
			if isfile and isfile(filePath) and delfile then
				delfile(filePath)
				UI.Notify("Route Cleared", "Reset to highway backbone curves.", 2, "warning")
			end
		end)
	end)

	-- 3. Automation Modules
	UI.AddSection(tab, "Rewards & Extra Automation")

	UI.AddToggle(tab, "Auto Claim Daily Quests (Rp 150M+)", Config.autoClaimQuests, function(state)
		Config.autoClaimQuests = state
		if state then checkAndClaimQuests() end
	end)

	UI.AddToggle(tab, "Auto Spin Box Roller", Config.autoSpinBox, function(state)
		Config.autoSpinBox = state
		if state then checkAndSpinBox() end
	end)

	UI.AddDropdown(tab, "Spin Box Type", { "Event", "Silver", "Gold" }, Config.selectedBox or "Event", function(chosen)
		Config.selectedBox = chosen
	end)
end)

if not success then
	warn("[HipHub BXI Auto Farm Error]:", err)
end
