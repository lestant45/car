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
		targetSpeed = 95,
		arriveDelay = 180,
		jobCooldown = 5,
		autoNextJob = true,
		autoClaimQuests = true,
		autoSpinBox = false,
		selectedBox = "Event",
		targetEarn = 0
	}

	------------------------------------------------
	-- 📊 AUTO FARM STATE & METRICS
	------------------------------------------------
	local FARM_STATE = {
		IDLE = "Idle",
		PREPARING_BUS = "PreparingBus",
		STARTING_JOB = "StartingJob",
		DRIVING_CHECKPOINT = "DrivingToCheckpoint",
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
		if currentFarmState ~= newState then
			currentFarmState = newState
			currentActivityText = tostring(newState) .. (reason and (" (" .. reason .. ")") or "")
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
	local BUS_SEAT_GROUND_OFFSET = 6.72 -- Measured exact height of Jetbus DriveSeat above road asphalt

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

	local function holdCheckpointPosition(targetCF)
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

			-- Anti-roll guard: if vehicle rolls/slips downhill by > 0.6 studs, lock it back immediately
			if targetCF and (curSeat.Position - targetCF.Position).Magnitude > 0.6 then
				curBus:PivotTo(targetCF)
				curSeat.AssemblyLinearVelocity = Vector3.zero
				curSeat.AssemblyAngularVelocity = Vector3.zero
			end
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

		-- Safe downwards-only probe: ray starts just 0.5 stud above target to ensure it never hits overhead roofs/ceilings
		local rayOrigin = Vector3.new(pos.X, pos.Y + 0.5, pos.Z)
		local rayDir = Vector3.new(0, -35, 0)
		local hit = workspace:Raycast(rayOrigin, rayDir, rayParams)

		if hit then
			return hit.Position.Y
		end
		return fallbackY
	end

	-- Drive from current location to target destination using AssemblyLinearVelocity
	local function driveToDestination(destPos, targetCruiseSpeed, arrivalThreshold)
		targetCruiseSpeed = targetCruiseSpeed or (Config.targetSpeed or 95)
		arrivalThreshold = arrivalThreshold or 25

		local bus, seat = ensureBusAndSeat()
		if not (bus and seat) then return false end

		-- Release parking handbrake before driving
		setHandbrake(false)

		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")

		isDrivingActive = true
		local driveFinished = false

		-- Cache exact factory CanCollide state of all vehicle parts to restore later
		local originalCollides = {}
		for _, part in ipairs(bus:GetDescendants()) do
			if part:IsA("BasePart") then
				originalCollides[part] = part.CanCollide
			end
		end

		local startSeatPos = seat.Position
		local totalFlatDist = (Vector3.new(destPos.X - startSeatPos.X, 0, destPos.Z - startSeatPos.Z)).Magnitude
		local startSeatY = startSeatPos.Y

		-- Determine realistic road ground elevation at target destination
		local destGroundY = probeGround(destPos, startSeatY - BUS_SEAT_GROUND_OFFSET)
		local targetFinalSeatY = (destGroundY or (destPos.Y > -400 and destPos.Y or startSeatY)) + BUS_SEAT_GROUND_OFFSET

		local look = seat.CFrame.LookVector
		-- CFrame.Angles(0,Y,0) produces LookVector = (-sin Y, 0, -cos Y), so
		-- to preserve the current look direction we need atan2(-X, -Z)
		local curHeadingAngle = math.atan2(-look.X, -look.Z)

		local currentSmoothSpeed = 0
		local lastSeatY = startSeatY
		local lastStuckCheckTime = os.clock()
		local lastStuckCheckPos = seat.Position

		-- 🛡️ Anti-Stuck & Anti-Sink Translation Engine:
		-- Anchor bus & disable collisions during transit to eliminate fence/pole snagging & physics sinking
		seat.Anchored = true
		for _, part in ipairs(bus:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				part.Anchored = true
			end
		end

		-- Pre-load destination streaming
		requestStreamAsync(destPos)

		if currentDriveConn then
			currentDriveConn:Disconnect()
			currentDriveConn = nil
		end

		local driveStartTime = os.clock()
		local expectedSeconds = totalFlatDist / math.max(targetCruiseSpeed * 0.4, 25)
		local maxDriveTimeout = math.max(expectedSeconds * 2.0 + 20.0, 35.0)

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
			local destVector = Vector3.new(destPos.X - seatPos.X, 0, destPos.Z - seatPos.Z)
			local flatDist = destVector.Magnitude

			-- Check Arrival: arrived within threshold OR max timeout reached
			local thresh = arrivalThreshold or 6
			if flatDist <= thresh or (os.clock() - driveStartTime) >= maxDriveTimeout then
				driveFinished = true
				return
			end

			-- Speed Ramping (Smooth Acceleration & Deceleration near target)
			local maxSpeed = targetCruiseSpeed
			local decelDist = math.max(maxSpeed * 0.8, 80)
			if flatDist < decelDist then
				maxSpeed = math.max(35, (flatDist / decelDist) * targetCruiseSpeed)
			end

			if currentSmoothSpeed < maxSpeed then
				currentSmoothSpeed = math.min(maxSpeed, currentSmoothSpeed + (65 * dt))
			elseif currentSmoothSpeed > maxSpeed then
				currentSmoothSpeed = math.max(maxSpeed, currentSmoothSpeed - (80 * dt))
			end

			local moveDir = destVector.Magnitude > 0.01 and destVector.Unit or Vector3.zero

			-- 🛣️ 3D DIRECT TRAJECTORY with Anti-Sink Road Height Floor
			local progress = math.clamp(1 - (flatDist / math.max(totalFlatDist, 1)), 0, 1)
			local desiredSeatY = startSeatY + ((targetFinalSeatY - startSeatY) * progress)

			-- Probe ground under current prospective point to ensure bus never dips below asphalt
			local stepDist = currentSmoothSpeed * dt
			local newX = seatPos.X + (moveDir.X * stepDist)
			local newZ = seatPos.Z + (moveDir.Z * stepDist)
			local currentRoadY = probeGround(Vector3.new(newX, desiredSeatY, newZ), desiredSeatY - BUS_SEAT_GROUND_OFFSET)
			local floorSeatY = (currentRoadY or (desiredSeatY - BUS_SEAT_GROUND_OFFSET)) + BUS_SEAT_GROUND_OFFSET
			if desiredSeatY < floorSeatY then
				desiredSeatY = floorSeatY
			end

			-- Adaptive vertical interpolation
			local maxVertStep = math.max(150 * dt, 8)
			if lastSeatY < desiredSeatY then
				lastSeatY = math.min(desiredSeatY, lastSeatY + maxVertStep)
			elseif lastSeatY > desiredSeatY then
				lastSeatY = math.max(desiredSeatY, lastSeatY - maxVertStep)
			end

			-- Smooth Angular Steering
			if moveDir.Magnitude > 0.05 then
				local targetAngle = math.atan2(-moveDir.X, -moveDir.Z)
				local angleDiff = (targetAngle - curHeadingAngle + math.pi) % (2 * math.pi) - math.pi
				curHeadingAngle = curHeadingAngle + math.clamp(angleDiff, -10 * dt, 10 * dt)
			end

			local newSeatPos = Vector3.new(newX, lastSeatY, newZ)
			local currentRot = CFrame.Angles(0, curHeadingAngle, 0)
			local targetSeatCF = CFrame.new(newSeatPos) * currentRot

			pcall(function()
				curBus:PivotTo(targetSeatCF)

				if hum then
					hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
					hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
					hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
				end
			end)

			-- Anti-Stuck Detection (Check every 1.5s)
			local now = os.clock()
			if (now - lastStuckCheckTime) >= 1.5 then
				local movedDist = (seatPos - lastStuckCheckPos).Magnitude
				if movedDist < 6 and flatDist > arrivalThreshold then
					lastSeatY = desiredSeatY + 2
					curBus:PivotTo(CFrame.new(seatPos.X + moveDir.X * 8, desiredSeatY + 2, seatPos.Z + moveDir.Z * 8) * currentRot)
				end
				lastStuckCheckTime = now
				lastStuckCheckPos = seatPos
			end
		end)

		while not driveFinished and isDrivingActive and isFarmRunning do
			task.wait(0.05)
		end

		if currentDriveConn then
			currentDriveConn:Disconnect()
			currentDriveConn = nil
		end

		-- Natural stop at destination: restore exact original collisions, unanchor seat & settle on road
		pcall(function()
			local curBus = getMyBus()
			local curSeat = getDriverSeat(curBus)
			if curBus then
				for part, state in pairs(originalCollides) do
					if part and part.Parent then
						pcall(function()
							part.CanCollide = state
							part.Anchored = false
							part.AssemblyLinearVelocity = Vector3.zero
							part.AssemblyAngularVelocity = Vector3.zero
						end)
					end
				end
			end
			if curSeat then
				curSeat.AssemblyLinearVelocity = Vector3.new(0, -10, 0)
				curSeat.AssemblyAngularVelocity = Vector3.zero
				curSeat.Throttle = 0
				curSeat.Anchored = false
			end
			if hrp then
				hrp.AssemblyLinearVelocity = Vector3.new(0, -10, 0)
				hrp.AssemblyAngularVelocity = Vector3.zero
			end
		end)

		isDrivingActive = false
		return true
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

	-- Helper: Snap and align bus perfectly inside checkpoint zone oriented to cpPart CFrame
	local function snapBusToCheckpoint(cpPart, forwardOffset)
		if not (cpPart and cpPart:IsA("BasePart")) then return nil end
		local snapBus, snapSeat = ensureBusAndSeat()
		if not (snapBus and snapSeat) then return nil end

		-- 🛡️ Anti-Cheat Teleport Guard: only snap if already within proximity (<= 65 studs)
		local seatPos = snapSeat.Position
		local distToCp = (Vector3.new(seatPos.X - cpPart.Position.X, 0, seatPos.Z - cpPart.Position.Z)).Magnitude
		if distToCp > 65 then
			return nil
		end

		local targetCF = nil
		pcall(function()
			local cpCF = cpPart.CFrame
			local roadY = probeGround(cpPart.Position, cpPart.Position.Y - 2.0) or (cpPart.Position.Y - 2.0)
			local seatTargetY = roadY + BUS_SEAT_GROUND_OFFSET

			-- Align orientation along checkpoint slot axis (flip 180 deg if approach direction is reversed)
			local dot = snapSeat.CFrame.LookVector:Dot(cpCF.LookVector)
			local rotCF = dot < -0.2 and (cpCF * CFrame.Angles(0, math.pi, 0) - cpCF.Position) or (cpCF - cpCF.Position)
			local forwardDir = rotCF.LookVector

			-- DriveSeat is ~23 studs in front of bus center.
			-- To center the passenger door / cabin inside the checkpoint trigger zone,
			-- we position the DriveSeat forward by +14 studs along heading.
			local offset = forwardOffset or 14
			local targetX = cpPart.Position.X + (forwardDir.X * offset)
			local targetZ = cpPart.Position.Z + (forwardDir.Z * offset)

			targetCF = CFrame.new(targetX, seatTargetY, targetZ) * rotCF
			snapBus:PivotTo(targetCF)

			-- Unanchor all parts so physics replication to server registers presence in trigger zone
			for _, p in ipairs(snapBus:GetDescendants()) do
				if p:IsA("BasePart") then
					p.Anchored = false
				end
			end

			snapSeat.Anchored = false
			snapSeat.AssemblyLinearVelocity = Vector3.zero
			snapSeat.AssemblyAngularVelocity = Vector3.zero
			snapSeat.Throttle = 0
			snapSeat.Steer = 0
			setHandbrake(true)
		end)

		return targetCF
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

		-- 2. Ensure Bus is physically inside Terminal Zone before Invoking StartBusJob (Distance Anti-Exploit Check)
		local termPart = findTargetPart(currentTerminalId, "BusJobTriggers")
		local terminalTriggerPos = termPart and termPart.Position or Vector3.new(22771.8, 286.93, -39584.0)
		local seatPos = seat.Position
		local distToTerm = (Vector3.new(seatPos.X - terminalTriggerPos.X, 0, seatPos.Z - terminalTriggerPos.Z)).Magnitude

		if distToTerm > 30 then
			setFarmState(FARM_STATE.STARTING_JOB, "Navigating to Terminal")
			driveToDestination(terminalTriggerPos, Config.targetSpeed or 95, 20)
			task.wait(0.5)
		end

		-- Auto-clear lingering zombie job if server reports already in job
		if player:GetAttribute("BusJobActive") then
			pcall(function() Remotes.CancelBusJob:FireServer() end)
			task.wait(1.5)
		end

		-- 3. Start Bus Job
		setFarmState(FARM_STATE.STARTING_JOB, "Invoking StartBusJob")
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
		end

		-- 4. Verify Job Activation
		local jobStartTime = os.clock()
		if type(startRes) == "table" and startRes.success then
			currentJobActive = true
			jobStartTime = os.clock()
			currentCheckpointIndex = startRes.checkpointIndex or 1
			totalCheckpoints = startRes.totalCheckpoints or 8
			nextCheckpointPartName = startRes.nextCheckpointPartName
			nextDestinationName = startRes.nextDestinationName
			currentCheckpointText = string.format("%d / %d", currentCheckpointIndex, totalCheckpoints)
			if statCheckpointCard then statCheckpointCard.Set(currentCheckpointText) end
			setFarmState(FARM_STATE.DRIVING_CHECKPOINT, nextDestinationName)
		else
			task.wait(2.5)
			return
		end

		-- 5. Route Navigation Loop (Checkpoint to Checkpoint)
		local lastHandledCheckpoint = nil
		while currentJobActive and isFarmRunning do
			-- A. Driving to next checkpoint
			if nextCheckpointPartName and nextCheckpointPartName ~= lastHandledCheckpoint then
				local cpPart = findTargetPart(nextCheckpointPartName, "Checkpoints")
				if cpPart and cpPart:IsA("BasePart") then
					setFarmState(FARM_STATE.DRIVING_CHECKPOINT, nextDestinationName or nextCheckpointPartName)
					-- Drive directly to part center with tight 3-stud threshold
					driveToDestination(cpPart.Position, Config.targetSpeed or 95, 3)

					-- Precision align bus inside checkpoint zone oriented to cpPart CFrame
					local parkedCF = snapBusToCheckpoint(cpPart, 14)
					task.wait(0.2)
					parkedCF = snapBusToCheckpoint(cpPart, 14) or parkedCF
					holdCheckpointPosition(parkedCF)

					-- 🛡️ Natural Checkpoint Triggering: Never fire CheckpointHeartbeat (honeypot trap)
					-- Wait naturally for server zone trigger to initiate passenger countdown
					local cpWaitStart = os.clock()
					local lastHealTime = os.clock()
					local nudgeCount = 0

					while not waitingForCheckpointCountdown and isFarmRunning and currentJobActive and (os.clock() - cpWaitStart) < 22 do
						local now = os.clock()

						-- If server hasn't triggered countdown after 3.5s, gently adjust parking position inside zone
						if not waitingForCheckpointCountdown and (now - cpWaitStart) > 3.5 and (now - lastHealTime) >= 2.8 then
							lastHealTime = now
							nudgeCount = nudgeCount + 1
							local progressiveOffset = 14 + (nudgeCount * 2)
							if progressiveOffset > 22 then progressiveOffset = 12 end
							parkedCF = snapBusToCheckpoint(cpPart, progressiveOffset) or parkedCF
							holdCheckpointPosition(parkedCF)
						end

						task.wait(0.2)
					end

					-- B. Waiting inside Checkpoint Zone for passenger countdown
					if waitingForCheckpointCountdown and isFarmRunning and currentJobActive then
						setFarmState(FARM_STATE.WAITING_PASSENGERS, "Passenger Loading")
						local waitTimeout = os.clock()
						local lastWaitHealTime = os.clock()

						-- Ensure anti-roll position lock & handbrake stay strictly active
						holdCheckpointPosition(parkedCF)

						while waitingForCheckpointCountdown and isFarmRunning and currentJobActive and (os.clock() - waitTimeout) < 30 do
							local now = os.clock()
							-- If server fired CheckpointZoneExit while waiting, re-center immediately
							if not isInCheckpointZone and (now - lastWaitHealTime) >= 1.5 then
								lastWaitHealTime = now
								parkedCF = snapBusToCheckpoint(cpPart, 14) or parkedCF
								holdCheckpointPosition(parkedCF)
							end
							task.wait(0.25)
						end
						-- Only mark as completed once passenger loading actually started/finished
						lastHandledCheckpoint = nextCheckpointPartName
					end

					-- Release parking hold once passenger loading finishes
					releaseCheckpointHold()
				end
			end

			-- C. Driving to Final Destination with Safe Anti-Ban Delay
			if endTriggerPartName and currentJobActive then
				local endTrigger = findTargetPart(endTriggerPartName, "BusJobEndTriggers")
				if endTrigger and endTrigger:IsA("BasePart") then
					-- 🛡️ SAFE ANTI-BAN DELAY: Dynamically scaled based on checkpoints & distance
					local safeBaseTime = math.max((totalCheckpoints or 8) * 25 + 40, 180)
					local minDelay = math.max(safeBaseTime, Config.arriveDelay or 180)
					local elapsed = os.clock() - jobStartTime
					local remaining = minDelay - elapsed

					while remaining > 0 and isFarmRunning and currentJobActive do
						local secs = math.ceil(remaining)
						setFarmState(FARM_STATE.DRIVING_FINAL, string.format("Safe Delay Finish (%ds)", secs))
						task.wait(0.5)
						remaining = minDelay - (os.clock() - jobStartTime)
					end

					if isFarmRunning and currentJobActive then
						setFarmState(FARM_STATE.DRIVING_FINAL, "Approaching Final Stop")
						driveToDestination(endTrigger.Position, Config.targetSpeed or 95, 12)
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

		-- 🛡️ Safe Terminal Repositioning without character death (No hum.Health = 0)
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local termPart = findTargetPart(currentTerminalId, "BusJobTriggers")
		if hrp and termPart then
			local dist = (Vector3.new(hrp.Position.X - termPart.Position.X, 0, hrp.Position.Z - termPart.Position.Z)).Magnitude
			if dist > 35 then
				hrp.CFrame = termPart.CFrame + Vector3.new(0, 3, 0)
			end
		end
		task.wait(1.5)
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

	local farmToggle = UI.AddToggle(tab, "Start Auto Bus Farm (Assembly Linear Velocity)", isFarmRunning, function(state)
		isFarmRunning = state
		Config.autoBusJob = state
		if state then
			farmStartTime = os.clock()
			setFarmState(FARM_STATE.PREPARING_BUS, "Starting Farm Engine")
			UI.Notify("Auto Farm Started", "AssemblyLinearVelocity driving activated!", 3, "success")
		else
			isDrivingActive = false
			currentJobActive = false
			releaseCheckpointHold()
			setFarmState(FARM_STATE.IDLE, "Stopped")
			UI.Notify("Auto Farm Stopped", "Farm paused.", 2, "warning")
		end
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
