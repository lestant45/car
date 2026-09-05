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
		arriveDelay = 65,
		jobCooldown = 3,
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

		-- Below-only probe: shoot from just above current position so bridges/canopies above are never detected
		local rayOrigin = Vector3.new(pos.X, pos.Y + 5, pos.Z)
		local rayDir = Vector3.new(0, -145, 0)
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

		-- Anchor bus during smooth translation to eliminate physics solver vibration
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

			-- Check Arrival: both horizontal proximity & vertical alignment
			local vertDist = math.abs(seatPos.Y - targetFinalSeatY)
			if flatDist <= arrivalThreshold and vertDist <= 25 then
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

			-- 🛣️ 3D TRAJECTORY ELEVATION & ROAD TRACKING:
			local progress = math.clamp(1 - (flatDist / math.max(totalFlatDist, 1)), 0, 1)
			local expectedTrajectoryY = startSeatY + ((targetFinalSeatY - startSeatY) * progress)

			-- 🛣️ Ground tracking: below-only probes (safe under bridges) + forward slope detection
			local probeBase = expectedTrajectoryY - BUS_SEAT_GROUND_OFFSET
			local localGroundY    = probeGround(seatPos, probeBase)
			local nearAheadGroundY = probeGround(seatPos + (moveDir * 25), probeBase)
			local bestGroundY = math.max(localGroundY or -1000, nearAheadGroundY or -1000)

			-- Forward slope detection: horizontal ray finds slope faces ahead of the bus
			local slopeTargetY = nil
			do
				local srp = RaycastParams.new()
				srp.FilterType = Enum.RaycastFilterType.Exclude
				local sfl = {}
				if char then table.insert(sfl, char) end
				local spveh = workspace:FindFirstChild("SpawnedVehicles")
				if spveh then table.insert(sfl, spveh) end
				local scps = workspace:FindFirstChild("Checkpoints")
				if scps then table.insert(sfl, scps) end
				local sspl = workspace:FindFirstChild("__SafetyPlate")
				if sspl then table.insert(sfl, sspl) end
				srp.FilterDescendantsInstances = sfl

				local slopeHit = workspace:Raycast(
					Vector3.new(seatPos.X, lastSeatY, seatPos.Z),
					moveDir * 80,
					srp
				)
				if slopeHit then
					if math.abs(slopeHit.Normal.Y) < 0.5 then
						local topHit = workspace:Raycast(
							slopeHit.Position + Vector3.new(0, 100, 0),
							Vector3.new(0, -150, 0),
							srp
						)
						slopeTargetY = topHit and topHit.Position.Y
					else
						slopeTargetY = slopeHit.Position.Y
					end
				end
			end

			local desiredSeatY
			if bestGroundY > -400 then
				desiredSeatY = bestGroundY + BUS_SEAT_GROUND_OFFSET
				local maxSlopeTarget = (targetFinalSeatY - BUS_SEAT_GROUND_OFFSET) + 8
				if slopeTargetY and slopeTargetY > bestGroundY and slopeTargetY <= maxSlopeTarget then
					desiredSeatY = math.max(desiredSeatY, slopeTargetY + BUS_SEAT_GROUND_OFFSET)
				end
			else
				desiredSeatY = targetFinalSeatY
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

			local stepDist = currentSmoothSpeed * dt
			local newX = seatPos.X + (moveDir.X * stepDist)
			local newZ = seatPos.Z + (moveDir.Z * stepDist)
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
					lastSeatY = desiredSeatY
					curBus:PivotTo(CFrame.new(seatPos.X + moveDir.X * 8, desiredSeatY, seatPos.Z + moveDir.Z * 8) * currentRot)
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

		-- Natural stop at destination: restore exact original collisions & unanchor seat
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
				curSeat.AssemblyLinearVelocity = Vector3.zero
				curSeat.AssemblyAngularVelocity = Vector3.zero
				curSeat.Throttle = 0
				curSeat.Anchored = false
			end
			if hrp then
				hrp.AssemblyLinearVelocity = Vector3.zero
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
	local nextCheckpointPartName = nil
	local nextDestinationName = nil
	local endTriggerPartName = nil
	local currentCheckpointIndex = 0
	local totalCheckpoints = 0

	-- Listen for Server Job Updates
	if Remotes:FindFirstChild("BusJobUpdate") then
		Remotes.BusJobUpdate.OnClientEvent:Connect(function(eventName, eventData)
			if not isFarmRunning then return end

			if eventName == "StartCheckpointWait" then
				waitingForCheckpointCountdown = true
				currentCheckpointIndex = eventData.checkpointIndex or currentCheckpointIndex
				totalCheckpoints = eventData.totalCheckpoints or totalCheckpoints
				currentCheckpointText = string.format("%d / %d", currentCheckpointIndex, totalCheckpoints)
				if statCheckpointCard then statCheckpointCard.Set(currentCheckpointText) end
				setFarmState(FARM_STATE.WAITING_PASSENGERS, eventData.checkpointName or "Checkpoint Zone")

			elseif eventName == "WaitCompleted" then
				waitingForCheckpointCountdown = false
				setFarmState(FARM_STATE.DRIVING_CHECKPOINT, "Passenger Loading Complete")

			elseif eventName == "NextCheckpoint" then
				nextCheckpointPartName = eventData.nextCheckpointPartName
				nextDestinationName = eventData.nextDestinationName
				currentCheckpointIndex = eventData.checkpointIndex or currentCheckpointIndex
				totalCheckpoints = eventData.totalCheckpoints or totalCheckpoints
				currentCheckpointText = string.format("%d / %d", currentCheckpointIndex, totalCheckpoints)
				if statCheckpointCard then statCheckpointCard.Set(currentCheckpointText) end
				setFarmState(FARM_STATE.DRIVING_CHECKPOINT, nextDestinationName or "Next Stop")

			elseif eventName == "FinalDestination" then
				endTriggerPartName = eventData.endTriggerPartName
				currentCheckpointIndex = eventData.checkpointIndex or currentCheckpointIndex
				totalCheckpoints = eventData.totalCheckpoints or totalCheckpoints
				currentCheckpointText = string.format("%d / %d", currentCheckpointIndex, totalCheckpoints)
				if statCheckpointCard then statCheckpointCard.Set(currentCheckpointText) end
				setFarmState(FARM_STATE.DRIVING_FINAL, "Final Destination Trigger")

			elseif eventName == "JobSuccess" then
				currentJobActive = false
				waitingForCheckpointCountdown = false
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

					-- Precision align bus inside checkpoint zone settling firmly on the road asphalt
					task.wait(0.2)
					local snapBus, snapSeat = ensureBusAndSeat()
					if snapBus and snapSeat then
						pcall(function()
							local look = snapSeat.CFrame.LookVector
							local heading = math.atan2(-look.X, -look.Z)
							local roadY = probeGround(cpPart.Position, cpPart.Position.Y - BUS_SEAT_GROUND_OFFSET) or (cpPart.Position.Y - BUS_SEAT_GROUND_OFFSET)
							local seatTargetY = roadY + BUS_SEAT_GROUND_OFFSET
							snapBus:PivotTo(CFrame.new(cpPart.Position.X, seatTargetY, cpPart.Position.Z) * CFrame.Angles(0, heading, 0))
							snapSeat.AssemblyLinearVelocity = Vector3.zero
							snapSeat.AssemblyAngularVelocity = Vector3.zero
							snapSeat.Anchored = false
						end)
					end

					-- 💓 Send natural CheckpointHeartbeat and Auto-Nudge into Trigger Zone
					local hbRemote = Remotes:FindFirstChild("CheckpointHeartbeat")
					local hbTimer = 0
					local cpWaitStart = os.clock()
					local lastNudgeTime = os.clock()

					while not waitingForCheckpointCountdown and isFarmRunning and currentJobActive and (os.clock() - cpWaitStart) < 18 do
						local now = os.clock()
						if hbRemote and (now - hbTimer) >= 1.0 then
							pcall(function() hbRemote:FireServer() end)
							hbTimer = now
						end

						-- If countdown hasn't started after 3.5s, nudge forward into the "BERHENTI DI SINI" trigger zone
						if (now - cpWaitStart) > 3.5 and (now - lastNudgeTime) >= 3.0 then
							lastNudgeTime = now
							local b, s = ensureBusAndSeat()
							if b and s then
								pcall(function()
									local forward = s.CFrame.LookVector
									b:PivotTo(b:GetPivot() + (forward * 7))
									s.AssemblyLinearVelocity = Vector3.zero
									s.AssemblyAngularVelocity = Vector3.zero
								end)
							end
						end

						task.wait(0.2)
					end

					-- B. Waiting inside Checkpoint Zone for passenger countdown
					if waitingForCheckpointCountdown and isFarmRunning and currentJobActive then
						setFarmState(FARM_STATE.WAITING_PASSENGERS, "Passenger Loading")
						local waitTimeout = os.clock()
						local hbRemoteB = Remotes:FindFirstChild("CheckpointHeartbeat")
						local hbTimerB = 0
						while waitingForCheckpointCountdown and isFarmRunning and currentJobActive and (os.clock() - waitTimeout) < 25 do
							local b, s = ensureBusAndSeat()
							if s then
								s.AssemblyLinearVelocity = Vector3.zero
								s.AssemblyAngularVelocity = Vector3.zero
								s.Throttle = 0
							end
							local now = os.clock()
							if hbRemoteB and (now - hbTimerB) >= 1.0 then
								pcall(function() hbRemoteB:FireServer() end)
								hbTimerB = now
							end
							task.wait(0.2)
						end
						-- Only mark as completed once passenger loading actually started/finished
						lastHandledCheckpoint = nextCheckpointPartName
					end
				end
			end

			-- C. Driving to Final Destination with Safe Anti-Ban Delay
			if endTriggerPartName and currentJobActive then
				local endTrigger = findTargetPart(endTriggerPartName, "BusJobEndTriggers")
				if endTrigger and endTrigger:IsA("BasePart") then
					-- 🛡️ SAFE ANTI-BAN DELAY: Ensure minimum trip duration before touching final trigger
					local minDelay = Config.arriveDelay or 65
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
	task.spawn(function()
		while true do
			task.wait(1)
			if isFarmRunning then
				pcall(checkAndClaimQuests)
				pcall(checkAndSpinBox)
				pcall(executeBusRouteLoop)

				if Config.autoNextJob and isFarmRunning then
					local cd = Config.jobCooldown or 3
					setFarmState(FARM_STATE.IDLE, string.format("Cooldown (%ds)", cd))
					task.wait(cd)
				elseif not Config.autoNextJob then
					isFarmRunning = false
					setFarmState(FARM_STATE.IDLE, "Single Route Done")
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
